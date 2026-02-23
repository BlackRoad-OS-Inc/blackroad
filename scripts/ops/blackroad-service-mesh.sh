#!/bin/bash
# BlackRoad Service Mesh
# Service discovery, routing, and load balancing for the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

MESH_DIR="$HOME/.blackroad/mesh"
MESH_DB="$MESH_DIR/mesh.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$MESH_DIR"/{routes,health}

    sqlite3 "$MESH_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS services (
    id TEXT PRIMARY KEY,
    name TEXT,
    node TEXT,
    port INTEGER,
    health_endpoint TEXT,
    status TEXT DEFAULT 'unknown',
    last_check DATETIME,
    metadata TEXT
);

CREATE TABLE IF NOT EXISTS routes (
    id TEXT PRIMARY KEY,
    path TEXT,
    service TEXT,
    method TEXT DEFAULT 'ALL',
    weight INTEGER DEFAULT 100,
    enabled INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS health_checks (
    service_id TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT,
    latency_ms INTEGER,
    FOREIGN KEY (service_id) REFERENCES services(id)
);

CREATE INDEX IF NOT EXISTS idx_service_status ON services(status);
CREATE INDEX IF NOT EXISTS idx_route_path ON routes(path);
SQL

    echo -e "${GREEN}Service mesh initialized${RESET}"
}

# Register a service
register() {
    local name="$1"
    local node="$2"
    local port="$3"
    local health="${4:-/health}"
    local metadata="${5:-{}}"

    local service_id="${name}_${node}_${port}"

    sqlite3 "$MESH_DB" "
        INSERT OR REPLACE INTO services (id, name, node, port, health_endpoint, metadata)
        VALUES ('$service_id', '$name', '$node', $port, '$health', '$metadata')
    "

    echo -e "${GREEN}Registered: $service_id${RESET}"
    echo "  Node: $node:$port"
    echo "  Health: $health"
}

# Deregister a service
deregister() {
    local service_id="$1"

    sqlite3 "$MESH_DB" "DELETE FROM services WHERE id = '$service_id'"
    echo -e "${GREEN}Deregistered: $service_id${RESET}"
}

# Discover services
discover() {
    local name="${1:-}"

    echo -e "${PINK}=== SERVICE DISCOVERY ===${RESET}"
    echo

    local where=""
    [ -n "$name" ] && where="WHERE name = '$name'"

    sqlite3 "$MESH_DB" "
        SELECT id, name, node, port, status, last_check FROM services $where
    " | while IFS='|' read -r id name node port status last_check; do
        local color=$RESET
        case $status in
            healthy) color=$GREEN ;;
            unhealthy) color=$RED ;;
            unknown) color=$YELLOW ;;
        esac

        printf "  %-30s %-10s ${color}%-10s${RESET} %s:%d\n" "$id" "$name" "$status" "$node" "$port"
    done
}

# Health check services
healthcheck() {
    echo -e "${PINK}=== HEALTH CHECKS ===${RESET}"
    echo

    sqlite3 "$MESH_DB" "SELECT id, name, node, port, health_endpoint FROM services" | while IFS='|' read -r id name node port health; do
        echo -n "  $id: "

        if ! ssh -o ConnectTimeout=2 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${RED}node offline${RESET}"
            sqlite3 "$MESH_DB" "UPDATE services SET status = 'unhealthy', last_check = datetime('now') WHERE id = '$id'"
            continue
        fi

        local start=$(date +%s%N)
        local response=$(ssh "$node" "curl -s -o /dev/null -w '%{http_code}' http://localhost:$port$health" 2>/dev/null)
        local end=$(date +%s%N)
        local latency=$(( (end - start) / 1000000 ))

        local status="unhealthy"
        [ "$response" = "200" ] && status="healthy"

        sqlite3 "$MESH_DB" "
            UPDATE services SET status = '$status', last_check = datetime('now') WHERE id = '$id';
            INSERT INTO health_checks (service_id, status, latency_ms) VALUES ('$id', '$status', $latency);
        "

        if [ "$status" = "healthy" ]; then
            echo -e "${GREEN}healthy${RESET} (${latency}ms)"
        else
            echo -e "${RED}unhealthy${RESET} (HTTP $response)"
        fi
    done
}

# Add route
route() {
    local path="$1"
    local service="$2"
    local method="${3:-ALL}"
    local weight="${4:-100}"

    local route_id="route_$(echo "$path" | md5sum | head -c 8)"

    sqlite3 "$MESH_DB" "
        INSERT OR REPLACE INTO routes (id, path, service, method, weight)
        VALUES ('$route_id', '$path', '$service', '$method', $weight)
    "

    echo -e "${GREEN}Route added: $path -> $service${RESET}"
}

# List routes
routes() {
    echo -e "${PINK}=== ROUTES ===${RESET}"
    echo

    sqlite3 "$MESH_DB" "
        SELECT r.path, r.service, r.method, r.weight, r.enabled, s.status
        FROM routes r
        LEFT JOIN services s ON r.service = s.name
        ORDER BY r.path
    " | while IFS='|' read -r path service method weight enabled status; do
        local route_status="${GREEN}✓${RESET}"
        [ "$enabled" = "0" ] && route_status="${YELLOW}○${RESET}"
        [ "$status" = "unhealthy" ] && route_status="${RED}✗${RESET}"

        printf "  %s %-20s -> %-20s [%s] (w:%d)\n" "$route_status" "$path" "$service" "$method" "$weight"
    done
}

# Get endpoint for service (with load balancing)
endpoint() {
    local name="$1"
    local strategy="${2:-round-robin}"

    # Get healthy instances
    local instances=$(sqlite3 "$MESH_DB" "
        SELECT node, port FROM services
        WHERE name = '$name' AND status = 'healthy'
    ")

    if [ -z "$instances" ]; then
        echo ""
        return 1
    fi

    case "$strategy" in
        round-robin)
            # Simple: return first healthy
            echo "$instances" | head -1 | awk -F'|' '{print $1":"$2}'
            ;;
        random)
            echo "$instances" | shuf | head -1 | awk -F'|' '{print $1":"$2}'
            ;;
        least-conn)
            # Would need connection tracking
            echo "$instances" | head -1 | awk -F'|' '{print $1":"$2}'
            ;;
    esac
}

# Proxy request to service
proxy() {
    local path="$1"
    shift

    # Find route
    local service=$(sqlite3 "$MESH_DB" "
        SELECT service FROM routes
        WHERE path = '$path' OR '$path' LIKE path || '%'
        AND enabled = 1
        LIMIT 1
    ")

    if [ -z "$service" ]; then
        echo -e "${RED}No route for: $path${RESET}"
        return 1
    fi

    local ep=$(endpoint "$service")

    if [ -z "$ep" ]; then
        echo -e "${RED}No healthy instances for: $service${RESET}"
        return 1
    fi

    echo -e "${BLUE}Proxying to $service ($ep)${RESET}"
    curl -s "http://$ep$path" "$@"
}

# Auto-discover services on nodes
autodiscover() {
    echo -e "${PINK}=== AUTO-DISCOVERY ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -e "${BLUE}Scanning $node...${RESET}"

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo "  (offline)"
            continue
        fi

        # Check common ports
        for port in 11434 8080 3000 5000 80 443; do
            local open=$(ssh "$node" "curl -s -o /dev/null -w '%{http_code}' http://localhost:$port/ 2>/dev/null | grep -E '200|301|302'" 2>/dev/null)

            if [ -n "$open" ]; then
                local service_name="service_$port"
                [ "$port" = "11434" ] && service_name="ollama"
                [ "$port" = "8080" ] && service_name="http"
                [ "$port" = "3000" ] && service_name="app"

                echo "  Found: $service_name on port $port"
                register "$service_name" "$node" "$port" "/" >/dev/null
            fi
        done
    done

    echo
    discover
}

# Service stats
stats() {
    echo -e "${PINK}=== MESH STATISTICS ===${RESET}"
    echo

    local total=$(sqlite3 "$MESH_DB" "SELECT COUNT(*) FROM services")
    local healthy=$(sqlite3 "$MESH_DB" "SELECT COUNT(*) FROM services WHERE status = 'healthy'")
    local routes=$(sqlite3 "$MESH_DB" "SELECT COUNT(*) FROM routes WHERE enabled = 1")

    echo "Services: $total ($healthy healthy)"
    echo "Routes: $routes"
    echo

    echo "By node:"
    sqlite3 "$MESH_DB" "
        SELECT node, COUNT(*), SUM(CASE WHEN status = 'healthy' THEN 1 ELSE 0 END)
        FROM services GROUP BY node
    " | while IFS='|' read -r node total healthy; do
        echo "  $node: $total services ($healthy healthy)"
    done

    echo
    echo "Health history (last hour):"
    sqlite3 "$MESH_DB" "
        SELECT service_id, AVG(latency_ms), COUNT(CASE WHEN status = 'healthy' THEN 1 END) * 100.0 / COUNT(*)
        FROM health_checks
        WHERE timestamp > datetime('now', '-1 hour')
        GROUP BY service_id
    " | while IFS='|' read -r service avg_lat uptime; do
        printf "  %-30s avg:%dms uptime:%.1f%%\n" "$service" "$avg_lat" "$uptime"
    done
}

# Watch mesh status
watch_mesh() {
    local interval="${1:-10}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔗 SERVICE MESH MONITOR                            ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Refresh: ${interval}s | Press Ctrl+C to stop"
    echo

    while true; do
        clear
        echo "[$(date '+%H:%M:%S')] Service Mesh Status"
        echo
        healthcheck
        echo
        routes
        sleep "$interval"
    done
}

# Export mesh config
export_mesh() {
    echo "{\"services\":$(sqlite3 "$MESH_DB" -json "SELECT * FROM services"),\"routes\":$(sqlite3 "$MESH_DB" -json "SELECT * FROM routes")}"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Service Mesh${RESET}"
    echo
    echo "Service discovery, routing, and load balancing"
    echo
    echo "Commands:"
    echo "  register <name> <node> <port> [health]  Register service"
    echo "  deregister <id>                         Remove service"
    echo "  discover [name]                         List services"
    echo "  healthcheck                             Check all services"
    echo "  route <path> <service> [method]         Add route"
    echo "  routes                                  List routes"
    echo "  endpoint <name> [strategy]              Get healthy endpoint"
    echo "  proxy <path>                            Proxy request"
    echo "  autodiscover                            Scan nodes for services"
    echo "  stats                                   Mesh statistics"
    echo "  watch [interval]                        Monitor mesh"
    echo "  export                                  Export config"
    echo
    echo "Examples:"
    echo "  $0 register ollama cecilia 11434 /api/tags"
    echo "  $0 route /api/chat ollama"
    echo "  $0 proxy /api/chat"
    echo "  $0 autodiscover"
}

# Ensure initialized
[ -f "$MESH_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    register|reg)
        register "$2" "$3" "$4" "$5" "$6"
        ;;
    deregister|dereg)
        deregister "$2"
        ;;
    discover|list|ls)
        discover "$2"
        ;;
    healthcheck|health)
        healthcheck
        ;;
    route)
        route "$2" "$3" "$4" "$5"
        ;;
    routes)
        routes
        ;;
    endpoint|ep)
        endpoint "$2" "$3"
        ;;
    proxy)
        shift
        proxy "$@"
        ;;
    autodiscover|scan)
        autodiscover
        ;;
    stats)
        stats
        ;;
    watch|monitor)
        watch_mesh "$2"
        ;;
    export)
        export_mesh
        ;;
    *)
        help
        ;;
esac
