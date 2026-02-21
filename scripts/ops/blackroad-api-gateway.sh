#!/bin/bash
# BlackRoad API Gateway
# Unified API entry point with auth, rate limiting, and routing
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

GATEWAY_DIR="$HOME/.blackroad/gateway"
GATEWAY_DB="$GATEWAY_DIR/gateway.db"
GATEWAY_PORT="${GATEWAY_PORT:-8080}"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$GATEWAY_DIR"/{logs,keys}

    sqlite3 "$GATEWAY_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS api_keys (
    id TEXT PRIMARY KEY,
    name TEXT,
    key_hash TEXT,
    rate_limit INTEGER DEFAULT 100,
    quota_daily INTEGER DEFAULT 10000,
    permissions TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used DATETIME,
    enabled INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS routes (
    id TEXT PRIMARY KEY,
    path TEXT UNIQUE,
    upstream TEXT,
    method TEXT DEFAULT 'ALL',
    auth_required INTEGER DEFAULT 1,
    rate_limit INTEGER,
    cache_ttl INTEGER DEFAULT 0,
    transform TEXT
);

CREATE TABLE IF NOT EXISTS usage (
    api_key TEXT,
    endpoint TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    latency_ms INTEGER,
    status_code INTEGER,
    FOREIGN KEY (api_key) REFERENCES api_keys(id)
);

CREATE INDEX IF NOT EXISTS idx_usage_key ON usage(api_key);
CREATE INDEX IF NOT EXISTS idx_usage_time ON usage(timestamp);
SQL

    # Seed default routes
    seed_routes

    echo -e "${GREEN}API Gateway initialized${RESET}"
    echo "  Port: $GATEWAY_PORT"
    echo "  DB: $GATEWAY_DB"
}

# Seed default API routes
seed_routes() {
    sqlite3 "$GATEWAY_DB" "SELECT COUNT(*) FROM routes" | grep -q '^0$' || return

    sqlite3 "$GATEWAY_DB" << 'SQL'
INSERT OR IGNORE INTO routes (id, path, upstream, method, auth_required, cache_ttl) VALUES
    ('llm-generate', '/api/generate', 'cecilia:11434/api/generate', 'POST', 1, 0),
    ('llm-chat', '/api/chat', 'cecilia:11434/api/chat', 'POST', 1, 0),
    ('llm-models', '/api/models', 'cecilia:11434/api/tags', 'GET', 0, 60),
    ('vision', '/api/vision', 'cecilia:5000/analyze', 'POST', 1, 0),
    ('health', '/health', 'LOCAL', 'GET', 0, 0),
    ('metrics', '/metrics', 'LOCAL', 'GET', 1, 0);
SQL
}

# Generate API key
generate_key() {
    local name="$1"
    local rate_limit="${2:-100}"
    local quota="${3:-10000}"
    local permissions="${4:-read,write}"

    local key="br_$(openssl rand -hex 24)"
    local key_hash=$(echo -n "$key" | sha256sum | cut -d' ' -f1)
    local key_id="key_$(openssl rand -hex 8)"

    sqlite3 "$GATEWAY_DB" "
        INSERT INTO api_keys (id, name, key_hash, rate_limit, quota_daily, permissions)
        VALUES ('$key_id', '$name', '$key_hash', $rate_limit, $quota, '$permissions')
    "

    echo -e "${GREEN}API Key Generated${RESET}"
    echo "  Name: $name"
    echo "  Key ID: $key_id"
    echo -e "  ${YELLOW}Key: $key${RESET}"
    echo "  Rate Limit: $rate_limit req/min"
    echo "  Daily Quota: $quota"
    echo
    echo -e "${RED}Save this key - it cannot be retrieved later!${RESET}"

    # Save to file
    echo "$key" > "$GATEWAY_DIR/keys/${key_id}.key"
    chmod 600 "$GATEWAY_DIR/keys/${key_id}.key"
}

# Validate API key
validate_key() {
    local key="$1"
    local key_hash=$(echo -n "$key" | sha256sum | cut -d' ' -f1)

    local result=$(sqlite3 "$GATEWAY_DB" "
        SELECT id, name, rate_limit, quota_daily, permissions, enabled
        FROM api_keys WHERE key_hash = '$key_hash'
    ")

    if [ -z "$result" ]; then
        echo ""
        return 1
    fi

    local enabled=$(echo "$result" | cut -d'|' -f6)
    if [ "$enabled" != "1" ]; then
        echo ""
        return 1
    fi

    # Update last used
    local key_id=$(echo "$result" | cut -d'|' -f1)
    sqlite3 "$GATEWAY_DB" "UPDATE api_keys SET last_used = datetime('now') WHERE id = '$key_id'"

    echo "$result"
}

# Check rate limit
check_rate_limit() {
    local key_id="$1"
    local limit="$2"

    local count=$(sqlite3 "$GATEWAY_DB" "
        SELECT COUNT(*) FROM usage
        WHERE api_key = '$key_id'
        AND datetime(timestamp, '+1 minute') > datetime('now')
    ")

    [ "$count" -lt "$limit" ]
}

# Check daily quota
check_quota() {
    local key_id="$1"
    local quota="$2"

    local count=$(sqlite3 "$GATEWAY_DB" "
        SELECT COUNT(*) FROM usage
        WHERE api_key = '$key_id'
        AND date(timestamp) = date('now')
    ")

    [ "$count" -lt "$quota" ]
}

# Get route for path
get_route() {
    local path="$1"
    local method="$2"

    sqlite3 "$GATEWAY_DB" "
        SELECT upstream, auth_required, rate_limit, cache_ttl
        FROM routes
        WHERE path = '$path'
        AND (method = '$method' OR method = 'ALL')
        LIMIT 1
    "
}

# Add route
add_route() {
    local path="$1"
    local upstream="$2"
    local method="${3:-ALL}"
    local auth="${4:-1}"
    local cache="${5:-0}"

    local route_id="route_$(echo "$path" | md5sum | head -c 8)"

    sqlite3 "$GATEWAY_DB" "
        INSERT OR REPLACE INTO routes (id, path, upstream, method, auth_required, cache_ttl)
        VALUES ('$route_id', '$path', '$upstream', '$method', $auth, $cache)
    "

    echo -e "${GREEN}Route added: $path -> $upstream${RESET}"
}

# List routes
list_routes() {
    echo -e "${PINK}=== API ROUTES ===${RESET}"
    echo

    sqlite3 "$GATEWAY_DB" "
        SELECT path, upstream, method, auth_required, cache_ttl FROM routes ORDER BY path
    " | while IFS='|' read -r path upstream method auth cache; do
        local auth_icon="🔓"
        [ "$auth" = "1" ] && auth_icon="🔒"

        local cache_info=""
        [ "$cache" -gt 0 ] && cache_info=" [cache:${cache}s]"

        printf "  %s %-6s %-20s -> %s%s\n" "$auth_icon" "[$method]" "$path" "$upstream" "$cache_info"
    done
}

# List API keys
list_keys() {
    echo -e "${PINK}=== API KEYS ===${RESET}"
    echo

    sqlite3 "$GATEWAY_DB" "
        SELECT id, name, rate_limit, quota_daily, enabled, last_used FROM api_keys ORDER BY name
    " | while IFS='|' read -r id name limit quota enabled last_used; do
        local status="${GREEN}active${RESET}"
        [ "$enabled" != "1" ] && status="${RED}disabled${RESET}"

        printf "  %-15s %-20s %s (rate:%d quota:%d) last:%s\n" "$id" "$name" "$status" "$limit" "$quota" "${last_used:-never}"
    done
}

# Revoke API key
revoke_key() {
    local key_id="$1"

    sqlite3 "$GATEWAY_DB" "UPDATE api_keys SET enabled = 0 WHERE id = '$key_id'"
    echo -e "${GREEN}Revoked key: $key_id${RESET}"
}

# Handle request (simulated)
handle_request() {
    local method="$1"
    local path="$2"
    local api_key="$3"
    local body="$4"

    local start_time=$(date +%s%N)

    # Get route
    local route=$(get_route "$path" "$method")

    if [ -z "$route" ]; then
        echo '{"error": "Not Found", "code": 404}'
        return
    fi

    local upstream=$(echo "$route" | cut -d'|' -f1)
    local auth_required=$(echo "$route" | cut -d'|' -f2)
    local rate_limit=$(echo "$route" | cut -d'|' -f3)
    local cache_ttl=$(echo "$route" | cut -d'|' -f4)

    # Check auth if required
    local key_id=""
    if [ "$auth_required" = "1" ]; then
        if [ -z "$api_key" ]; then
            echo '{"error": "API key required", "code": 401}'
            return
        fi

        local key_info=$(validate_key "$api_key")
        if [ -z "$key_info" ]; then
            echo '{"error": "Invalid API key", "code": 401}'
            return
        fi

        key_id=$(echo "$key_info" | cut -d'|' -f1)
        local key_rate=$(echo "$key_info" | cut -d'|' -f3)
        local key_quota=$(echo "$key_info" | cut -d'|' -f4)

        # Use route-specific or key-specific rate limit
        [ -z "$rate_limit" ] && rate_limit=$key_rate

        # Check rate limit
        if ! check_rate_limit "$key_id" "$rate_limit"; then
            echo '{"error": "Rate limit exceeded", "code": 429}'
            return
        fi

        # Check quota
        if ! check_quota "$key_id" "$key_quota"; then
            echo '{"error": "Daily quota exceeded", "code": 429}'
            return
        fi
    fi

    # Handle local endpoints
    if [ "$upstream" = "LOCAL" ]; then
        case "$path" in
            /health)
                echo '{"status": "healthy", "gateway": "blackroad"}'
                ;;
            /metrics)
                get_metrics
                ;;
        esac
        return
    fi

    # Proxy to upstream
    local node=$(echo "$upstream" | cut -d':' -f1)
    local target="http://${upstream}"

    local response
    local status_code

    if [ "$method" = "GET" ]; then
        response=$(ssh -o ConnectTimeout=10 "$node" "curl -s -w '\n%{http_code}' '$target'" 2>/dev/null)
    else
        response=$(ssh -o ConnectTimeout=10 "$node" "curl -s -w '\n%{http_code}' -X $method -d '$body' '$target'" 2>/dev/null)
    fi

    status_code=$(echo "$response" | tail -1)
    response=$(echo "$response" | sed '$d')

    # Calculate latency
    local end_time=$(date +%s%N)
    local latency=$(( (end_time - start_time) / 1000000 ))

    # Log usage
    if [ -n "$key_id" ]; then
        sqlite3 "$GATEWAY_DB" "
            INSERT INTO usage (api_key, endpoint, latency_ms, status_code)
            VALUES ('$key_id', '$path', $latency, $status_code)
        "
    fi

    echo "$response"
}

# Get metrics
get_metrics() {
    local total=$(sqlite3 "$GATEWAY_DB" "SELECT COUNT(*) FROM usage")
    local today=$(sqlite3 "$GATEWAY_DB" "SELECT COUNT(*) FROM usage WHERE date(timestamp) = date('now')")
    local avg_latency=$(sqlite3 "$GATEWAY_DB" "SELECT AVG(latency_ms) FROM usage WHERE date(timestamp) = date('now')")
    local active_keys=$(sqlite3 "$GATEWAY_DB" "SELECT COUNT(*) FROM api_keys WHERE enabled = 1")

    cat << EOF
{
    "requests_total": $total,
    "requests_today": $today,
    "avg_latency_ms": ${avg_latency:-0},
    "active_api_keys": $active_keys,
    "timestamp": "$(date -Iseconds)"
}
EOF
}

# Usage stats
stats() {
    echo -e "${PINK}=== GATEWAY STATISTICS ===${RESET}"
    echo

    echo "Today's usage:"
    sqlite3 "$GATEWAY_DB" "
        SELECT endpoint, COUNT(*), AVG(latency_ms)
        FROM usage
        WHERE date(timestamp) = date('now')
        GROUP BY endpoint
        ORDER BY COUNT(*) DESC
    " | while IFS='|' read -r endpoint count avg_lat; do
        printf "  %-25s %d requests (avg: %.0fms)\n" "$endpoint" "$count" "$avg_lat"
    done

    echo
    echo "By API key:"
    sqlite3 "$GATEWAY_DB" "
        SELECT k.name, COUNT(u.api_key), AVG(u.latency_ms)
        FROM api_keys k
        LEFT JOIN usage u ON k.id = u.api_key AND date(u.timestamp) = date('now')
        GROUP BY k.id
        ORDER BY COUNT(u.api_key) DESC
    " | while IFS='|' read -r name count avg_lat; do
        printf "  %-20s %d requests\n" "$name" "$count"
    done

    echo
    echo "Error rates (last hour):"
    sqlite3 "$GATEWAY_DB" "
        SELECT
            COUNT(CASE WHEN status_code >= 400 THEN 1 END) * 100.0 / COUNT(*),
            COUNT(CASE WHEN status_code >= 500 THEN 1 END) * 100.0 / COUNT(*)
        FROM usage
        WHERE datetime(timestamp, '+1 hour') > datetime('now')
    " | while IFS='|' read -r client_err server_err; do
        printf "  4xx: %.2f%%  5xx: %.2f%%\n" "$client_err" "$server_err"
    done
}

# Test endpoint
test_endpoint() {
    local path="$1"
    local api_key="$2"

    echo -e "${BLUE}Testing: $path${RESET}"

    if [ -n "$api_key" ]; then
        echo "  With API key: ${api_key:0:10}..."
    fi

    handle_request "GET" "$path" "$api_key" ""
}

# Start gateway server (simple HTTP)
serve() {
    local port="${1:-$GATEWAY_PORT}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🌐 BLACKROAD API GATEWAY                           ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Listening on port $port"
    echo "Press Ctrl+C to stop"
    echo

    # Simple netcat server (for demo - production would use proper HTTP server)
    while true; do
        echo -e "${CYAN}[$(date '+%H:%M:%S')] Waiting for requests...${RESET}"

        # Read request
        { read -r request_line; } < <(nc -l -p "$port" -q 1)

        if [ -n "$request_line" ]; then
            local method=$(echo "$request_line" | awk '{print $1}')
            local path=$(echo "$request_line" | awk '{print $2}')

            echo "  $method $path"
            handle_request "$method" "$path" "" "" | nc -l -p "$port" -q 1
        fi
    done
}

# Help
help() {
    echo -e "${PINK}BlackRoad API Gateway${RESET}"
    echo
    echo "Unified API entry point with auth and rate limiting"
    echo
    echo "Commands:"
    echo "  generate-key <name> [rate] [quota]  Generate API key"
    echo "  revoke-key <id>                     Revoke API key"
    echo "  list-keys                           List API keys"
    echo "  add-route <path> <upstream>         Add route"
    echo "  list-routes                         List routes"
    echo "  test <path> [key]                   Test endpoint"
    echo "  stats                               Usage statistics"
    echo "  serve [port]                        Start gateway"
    echo
    echo "Examples:"
    echo "  $0 generate-key myapp 100 5000"
    echo "  $0 add-route /api/embed 'cecilia:11434/api/embeddings'"
    echo "  $0 test /api/models"
}

# Ensure initialized
[ -f "$GATEWAY_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    generate-key|gen-key)
        generate_key "$2" "$3" "$4" "$5"
        ;;
    revoke-key|revoke)
        revoke_key "$2"
        ;;
    list-keys|keys)
        list_keys
        ;;
    add-route|route)
        add_route "$2" "$3" "$4" "$5" "$6"
        ;;
    list-routes|routes)
        list_routes
        ;;
    test)
        test_endpoint "$2" "$3"
        ;;
    stats)
        stats
        ;;
    serve|start)
        serve "$2"
        ;;
    *)
        help
        ;;
esac
