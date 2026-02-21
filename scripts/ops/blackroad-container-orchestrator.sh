#!/bin/bash
# BlackRoad Container Orchestrator
# Manage Docker containers across the Pi cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

ORCH_DIR="$HOME/.blackroad/containers"
ORCH_DB="$ORCH_DIR/containers.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$ORCH_DIR"/{manifests,logs}

    sqlite3 "$ORCH_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS containers (
    id TEXT PRIMARY KEY,
    name TEXT,
    image TEXT,
    node TEXT,
    status TEXT DEFAULT 'created',
    ports TEXT,
    volumes TEXT,
    env TEXT,
    replicas INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS services (
    name TEXT PRIMARY KEY,
    image TEXT,
    replicas INTEGER DEFAULT 1,
    ports TEXT,
    env TEXT,
    placement TEXT,
    health_check TEXT,
    status TEXT DEFAULT 'stopped'
);

CREATE TABLE IF NOT EXISTS deployments (
    id TEXT PRIMARY KEY,
    service TEXT,
    strategy TEXT DEFAULT 'rolling',
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME
);

CREATE INDEX IF NOT EXISTS idx_node ON containers(node);
CREATE INDEX IF NOT EXISTS idx_status ON containers(status);
SQL

    echo -e "${GREEN}Container orchestrator initialized${RESET}"
}

# Check Docker on node
check_docker() {
    local node="$1"
    ssh -o ConnectTimeout=3 "$node" "docker info" >/dev/null 2>&1
}

# Run container on node
run() {
    local name="$1"
    local image="$2"
    local node="${3:-auto}"
    local ports="${4:-}"
    local env="${5:-}"

    # Auto-select node
    if [ "$node" = "auto" ]; then
        for n in "${ALL_NODES[@]}"; do
            if check_docker "$n"; then
                node="$n"
                break
            fi
        done
    fi

    if [ -z "$node" ]; then
        echo -e "${RED}No Docker nodes available${RESET}"
        return 1
    fi

    echo -e "${BLUE}Deploying $name to $node...${RESET}"

    # Build docker run command
    local cmd="docker run -d --name $name"

    # Add ports
    if [ -n "$ports" ]; then
        for p in $(echo "$ports" | tr ',' ' '); do
            cmd="$cmd -p $p"
        done
    fi

    # Add env vars
    if [ -n "$env" ]; then
        for e in $(echo "$env" | tr ',' ' '); do
            cmd="$cmd -e $e"
        done
    fi

    cmd="$cmd --restart unless-stopped $image"

    # Run on node
    local container_id=$(ssh "$node" "$cmd" 2>&1)

    if [ $? -eq 0 ]; then
        sqlite3 "$ORCH_DB" "
            INSERT INTO containers (id, name, image, node, status, ports, env)
            VALUES ('${container_id:0:12}', '$name', '$image', '$node', 'running', '$ports', '$env')
        "

        echo -e "${GREEN}Container started: ${container_id:0:12}${RESET}"
        echo "  Name: $name"
        echo "  Node: $node"
        echo "  Image: $image"
    else
        echo -e "${RED}Failed to start container: $container_id${RESET}"
        return 1
    fi
}

# Stop container
stop() {
    local name="$1"

    local container=$(sqlite3 "$ORCH_DB" "SELECT id, node FROM containers WHERE name = '$name' AND status = 'running'")

    if [ -z "$container" ]; then
        echo -e "${YELLOW}Container not found or not running: $name${RESET}"
        return 1
    fi

    local id=$(echo "$container" | cut -d'|' -f1)
    local node=$(echo "$container" | cut -d'|' -f2)

    ssh "$node" "docker stop $id" >/dev/null 2>&1

    sqlite3 "$ORCH_DB" "UPDATE containers SET status = 'stopped' WHERE name = '$name'"

    echo -e "${GREEN}Stopped: $name${RESET}"
}

# Remove container
remove() {
    local name="$1"

    local container=$(sqlite3 "$ORCH_DB" "SELECT id, node FROM containers WHERE name = '$name'")

    if [ -z "$container" ]; then
        echo -e "${YELLOW}Container not found: $name${RESET}"
        return 1
    fi

    local id=$(echo "$container" | cut -d'|' -f1)
    local node=$(echo "$container" | cut -d'|' -f2)

    ssh "$node" "docker rm -f $id" >/dev/null 2>&1

    sqlite3 "$ORCH_DB" "DELETE FROM containers WHERE name = '$name'"

    echo -e "${GREEN}Removed: $name${RESET}"
}

# List containers
list() {
    local filter="${1:-all}"

    echo -e "${PINK}=== CONTAINERS ===${RESET}"
    echo

    local where=""
    [ "$filter" = "running" ] && where="WHERE status = 'running'"
    [ "$filter" = "stopped" ] && where="WHERE status = 'stopped'"

    sqlite3 "$ORCH_DB" "
        SELECT id, name, image, node, status FROM containers $where ORDER BY node, name
    " | while IFS='|' read -r id name image node status; do
        local status_color=$RESET
        [ "$status" = "running" ] && status_color=$GREEN
        [ "$status" = "stopped" ] && status_color=$YELLOW

        printf "  %-12s %-20s %-10s ${status_color}%-10s${RESET} %s\n" "$id" "$name" "$node" "$status" "$image"
    done
}

# List containers across all nodes (live)
ps() {
    echo -e "${PINK}=== LIVE CONTAINERS ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -e "${BLUE}$node:${RESET}"

        if ! check_docker "$node"; then
            echo "  (no docker)"
            continue
        fi

        local containers=$(ssh "$node" "docker ps --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}'" 2>/dev/null)

        if [ -z "$containers" ]; then
            echo "  (no containers)"
        else
            echo "$containers" | while IFS='|' read -r id name image status; do
                printf "  %-12s %-25s %-30s %s\n" "$id" "$name" "${image:0:30}" "$status"
            done
        fi
        echo
    done
}

# Get container logs
logs() {
    local name="$1"
    local lines="${2:-50}"

    local container=$(sqlite3 "$ORCH_DB" "SELECT id, node FROM containers WHERE name = '$name'")

    if [ -z "$container" ]; then
        echo -e "${RED}Container not found: $name${RESET}"
        return 1
    fi

    local id=$(echo "$container" | cut -d'|' -f1)
    local node=$(echo "$container" | cut -d'|' -f2)

    echo -e "${PINK}=== LOGS: $name ($node) ===${RESET}"
    echo

    ssh "$node" "docker logs --tail $lines $id"
}

# Execute command in container
exec_cmd() {
    local name="$1"
    shift
    local cmd="$*"

    local container=$(sqlite3 "$ORCH_DB" "SELECT id, node FROM containers WHERE name = '$name' AND status = 'running'")

    if [ -z "$container" ]; then
        echo -e "${RED}Container not running: $name${RESET}"
        return 1
    fi

    local id=$(echo "$container" | cut -d'|' -f1)
    local node=$(echo "$container" | cut -d'|' -f2)

    ssh -t "$node" "docker exec -it $id $cmd"
}

# Create service (multi-replica)
service_create() {
    local name="$1"
    local image="$2"
    local replicas="${3:-1}"
    local ports="${4:-}"

    sqlite3 "$ORCH_DB" "
        INSERT OR REPLACE INTO services (name, image, replicas, ports)
        VALUES ('$name', '$image', $replicas, '$ports')
    "

    echo -e "${GREEN}Service created: $name${RESET}"
    echo "  Image: $image"
    echo "  Replicas: $replicas"
}

# Scale service
scale() {
    local name="$1"
    local replicas="$2"

    local service=$(sqlite3 "$ORCH_DB" "SELECT image, ports FROM services WHERE name = '$name'")

    if [ -z "$service" ]; then
        echo -e "${RED}Service not found: $name${RESET}"
        return 1
    fi

    local image=$(echo "$service" | cut -d'|' -f1)
    local ports=$(echo "$service" | cut -d'|' -f2)

    echo -e "${PINK}=== SCALING $name to $replicas ===${RESET}"
    echo

    # Get current containers
    local current=$(sqlite3 "$ORCH_DB" "SELECT COUNT(*) FROM containers WHERE name LIKE '${name}_%' AND status = 'running'")

    if [ "$replicas" -gt "$current" ]; then
        # Scale up
        local to_add=$((replicas - current))
        echo "Adding $to_add replicas..."

        for i in $(seq 1 $to_add); do
            local idx=$((current + i))
            local node_idx=$(( (idx - 1) % ${#ALL_NODES[@]} ))
            local node="${ALL_NODES[$node_idx]}"

            run "${name}_${idx}" "$image" "$node" "$ports" >/dev/null
            echo "  Started ${name}_${idx} on $node"
        done
    elif [ "$replicas" -lt "$current" ]; then
        # Scale down
        local to_remove=$((current - replicas))
        echo "Removing $to_remove replicas..."

        sqlite3 "$ORCH_DB" "
            SELECT name FROM containers
            WHERE name LIKE '${name}_%' AND status = 'running'
            ORDER BY created_at DESC LIMIT $to_remove
        " | while read -r container_name; do
            remove "$container_name" >/dev/null
            echo "  Removed $container_name"
        done
    fi

    sqlite3 "$ORCH_DB" "UPDATE services SET replicas = $replicas WHERE name = '$name'"

    echo -e "\n${GREEN}Scaled to $replicas replicas${RESET}"
}

# Deploy service
deploy() {
    local name="$1"
    local strategy="${2:-rolling}"

    local service=$(sqlite3 "$ORCH_DB" "SELECT image, replicas, ports FROM services WHERE name = '$name'")

    if [ -z "$service" ]; then
        echo -e "${RED}Service not found: $name${RESET}"
        return 1
    fi

    local image=$(echo "$service" | cut -d'|' -f1)
    local replicas=$(echo "$service" | cut -d'|' -f2)
    local ports=$(echo "$service" | cut -d'|' -f3)

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🚀 DEPLOYING: $name${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Strategy: $strategy"
    echo "Replicas: $replicas"
    echo

    local deploy_id="deploy_$(date +%s)"
    sqlite3 "$ORCH_DB" "INSERT INTO deployments (id, service, strategy) VALUES ('$deploy_id', '$name', '$strategy')"

    case "$strategy" in
        rolling)
            # One at a time
            for i in $(seq 1 $replicas); do
                local node_idx=$(( (i - 1) % ${#ALL_NODES[@]} ))
                local node="${ALL_NODES[$node_idx]}"

                # Remove old if exists
                remove "${name}_${i}" 2>/dev/null

                # Start new
                echo "  Deploying replica $i to $node..."
                run "${name}_${i}" "$image" "$node" "$ports" >/dev/null
                sleep 2
            done
            ;;
        parallel)
            # All at once
            for i in $(seq 1 $replicas); do
                local node_idx=$(( (i - 1) % ${#ALL_NODES[@]} ))
                local node="${ALL_NODES[$node_idx]}"

                remove "${name}_${i}" 2>/dev/null
                run "${name}_${i}" "$image" "$node" "$ports" >/dev/null &
            done
            wait
            ;;
    esac

    sqlite3 "$ORCH_DB" "
        UPDATE deployments SET status = 'completed', completed_at = datetime('now') WHERE id = '$deploy_id';
        UPDATE services SET status = 'running' WHERE name = '$name';
    "

    echo -e "\n${GREEN}Deployment complete${RESET}"
}

# Pull image on all nodes
pull() {
    local image="$1"

    echo -e "${PINK}=== PULLING IMAGE: $image ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "

        if ! check_docker "$node"; then
            echo "(no docker)"
            continue
        fi

        ssh "$node" "docker pull $image" >/dev/null 2>&1 &
        echo "pulling..."
    done

    wait
    echo -e "\n${GREEN}Pull complete${RESET}"
}

# Cluster-wide stats
stats() {
    echo -e "${PINK}=== CLUSTER CONTAINER STATS ===${RESET}"
    echo

    local total_containers=0
    local total_running=0

    for node in "${ALL_NODES[@]}"; do
        if ! check_docker "$node"; then
            continue
        fi

        local node_stats=$(ssh "$node" "docker stats --no-stream --format '{{.Container}}|{{.CPUPerc}}|{{.MemUsage}}'" 2>/dev/null)

        if [ -n "$node_stats" ]; then
            echo -e "${BLUE}$node:${RESET}"
            echo "$node_stats" | while IFS='|' read -r container cpu mem; do
                printf "    %-15s CPU: %-8s MEM: %s\n" "$container" "$cpu" "$mem"
                ((total_running++))
            done
            echo
        fi
    done

    local db_total=$(sqlite3 "$ORCH_DB" "SELECT COUNT(*) FROM containers WHERE status = 'running'")
    echo "Tracked containers: $db_total running"
}

# Prune unused resources
prune() {
    echo -e "${PINK}=== PRUNING CLUSTER ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "

        if ! check_docker "$node"; then
            echo "(no docker)"
            continue
        fi

        ssh "$node" "docker system prune -f" >/dev/null 2>&1
        echo "pruned"
    done
}

# Help
help() {
    echo -e "${PINK}BlackRoad Container Orchestrator${RESET}"
    echo
    echo "Manage Docker containers across the cluster"
    echo
    echo "Commands:"
    echo "  run <name> <image> [node] [ports]  Run container"
    echo "  stop <name>                        Stop container"
    echo "  remove <name>                      Remove container"
    echo "  list [filter]                      List containers"
    echo "  ps                                 Live container status"
    echo "  logs <name> [lines]                View logs"
    echo "  exec <name> <cmd>                  Execute in container"
    echo "  service-create <n> <img> [rep]     Create service"
    echo "  scale <name> <replicas>            Scale service"
    echo "  deploy <name> [strategy]           Deploy service"
    echo "  pull <image>                       Pull on all nodes"
    echo "  stats                              Cluster stats"
    echo "  prune                              Cleanup unused"
    echo
    echo "Examples:"
    echo "  $0 run redis redis:alpine auto 6379:6379"
    echo "  $0 service-create api myapp:latest 3"
    echo "  $0 scale api 5"
}

# Ensure initialized
[ -f "$ORCH_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    run|start)
        run "$2" "$3" "$4" "$5" "$6"
        ;;
    stop)
        stop "$2"
        ;;
    remove|rm)
        remove "$2"
        ;;
    list|ls)
        list "$2"
        ;;
    ps)
        ps
        ;;
    logs)
        logs "$2" "$3"
        ;;
    exec)
        shift
        exec_cmd "$@"
        ;;
    service-create|service)
        service_create "$2" "$3" "$4" "$5"
        ;;
    scale)
        scale "$2" "$3"
        ;;
    deploy)
        deploy "$2" "$3"
        ;;
    pull)
        pull "$2"
        ;;
    stats)
        stats
        ;;
    prune|clean)
        prune
        ;;
    *)
        help
        ;;
esac
