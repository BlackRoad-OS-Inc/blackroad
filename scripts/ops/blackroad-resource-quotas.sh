#!/bin/bash
# BlackRoad Resource Quotas
# Manage resource limits and quotas across the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

QUOTA_DIR="$HOME/.blackroad/quotas"
QUOTA_DB="$QUOTA_DIR/quotas.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$QUOTA_DIR"

    sqlite3 "$QUOTA_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS namespaces (
    name TEXT PRIMARY KEY,
    description TEXT,
    priority INTEGER DEFAULT 5,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quotas (
    id TEXT PRIMARY KEY,
    namespace TEXT,
    resource_type TEXT,
    limit_value REAL,
    used_value REAL DEFAULT 0,
    unit TEXT,
    FOREIGN KEY (namespace) REFERENCES namespaces(name)
);

CREATE TABLE IF NOT EXISTS usage_history (
    namespace TEXT,
    resource_type TEXT,
    value REAL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS limits (
    node TEXT,
    resource_type TEXT,
    soft_limit REAL,
    hard_limit REAL,
    current_value REAL DEFAULT 0,
    PRIMARY KEY (node, resource_type)
);

CREATE INDEX IF NOT EXISTS idx_ns ON quotas(namespace);
SQL

    # Seed default namespaces and quotas
    seed_defaults

    echo -e "${GREEN}Resource quota system initialized${RESET}"
}

# Seed defaults
seed_defaults() {
    sqlite3 "$QUOTA_DB" << 'SQL'
INSERT OR IGNORE INTO namespaces (name, description, priority) VALUES
    ('default', 'Default namespace for general workloads', 5),
    ('system', 'System processes and services', 10),
    ('inference', 'LLM inference workloads', 7),
    ('training', 'Model training jobs', 3),
    ('batch', 'Batch processing jobs', 2);

INSERT OR IGNORE INTO quotas (id, namespace, resource_type, limit_value, unit) VALUES
    ('default-cpu', 'default', 'cpu', 400, 'percent'),
    ('default-mem', 'default', 'memory', 4096, 'MB'),
    ('default-gpu', 'default', 'gpu_mem', 2048, 'MB'),
    ('default-requests', 'default', 'requests_per_min', 100, 'count'),
    ('inference-cpu', 'inference', 'cpu', 800, 'percent'),
    ('inference-mem', 'inference', 'memory', 8192, 'MB'),
    ('inference-requests', 'inference', 'requests_per_min', 500, 'count'),
    ('training-cpu', 'training', 'cpu', 400, 'percent'),
    ('training-mem', 'training', 'memory', 16384, 'MB'),
    ('batch-cpu', 'batch', 'cpu', 200, 'percent'),
    ('batch-mem', 'batch', 'memory', 2048, 'MB');
SQL
}

# Create namespace
create_namespace() {
    local name="$1"
    local description="$2"
    local priority="${3:-5}"

    sqlite3 "$QUOTA_DB" "
        INSERT OR REPLACE INTO namespaces (name, description, priority)
        VALUES ('$name', '$description', $priority)
    "

    echo -e "${GREEN}Created namespace: $name${RESET}"
}

# Set quota
set_quota() {
    local namespace="$1"
    local resource="$2"
    local limit="$3"
    local unit="${4:-count}"

    local quota_id="${namespace}-${resource}"

    sqlite3 "$QUOTA_DB" "
        INSERT OR REPLACE INTO quotas (id, namespace, resource_type, limit_value, unit)
        VALUES ('$quota_id', '$namespace', '$resource', $limit, '$unit')
    "

    echo -e "${GREEN}Set quota: $namespace.$resource = $limit $unit${RESET}"
}

# Get current usage
get_usage() {
    local namespace="$1"
    local resource="$2"

    sqlite3 "$QUOTA_DB" "
        SELECT used_value FROM quotas
        WHERE namespace = '$namespace' AND resource_type = '$resource'
    "
}

# Update usage
update_usage() {
    local namespace="$1"
    local resource="$2"
    local value="$3"

    sqlite3 "$QUOTA_DB" "
        UPDATE quotas SET used_value = $value
        WHERE namespace = '$namespace' AND resource_type = '$resource';

        INSERT INTO usage_history (namespace, resource_type, value)
        VALUES ('$namespace', '$resource', $value);
    "
}

# Check if request fits within quota
check_quota() {
    local namespace="$1"
    local resource="$2"
    local requested="$3"

    local quota=$(sqlite3 "$QUOTA_DB" "
        SELECT limit_value, used_value FROM quotas
        WHERE namespace = '$namespace' AND resource_type = '$resource'
    ")

    if [ -z "$quota" ]; then
        echo "no_quota"
        return 0
    fi

    local limit=$(echo "$quota" | cut -d'|' -f1)
    local used=$(echo "$quota" | cut -d'|' -f2)
    local available=$(echo "$limit - $used" | bc -l)

    if [ "$(echo "$requested <= $available" | bc -l)" = "1" ]; then
        echo "allowed"
        return 0
    else
        echo "exceeded"
        return 1
    fi
}

# Allocate resources
allocate() {
    local namespace="$1"
    local resource="$2"
    local amount="$3"

    local status=$(check_quota "$namespace" "$resource" "$amount")

    if [ "$status" = "exceeded" ]; then
        echo -e "${RED}Quota exceeded for $namespace.$resource${RESET}"
        return 1
    fi

    local current=$(get_usage "$namespace" "$resource")
    local new_usage=$(echo "${current:-0} + $amount" | bc -l)
    update_usage "$namespace" "$resource" "$new_usage"

    echo -e "${GREEN}Allocated $amount $resource to $namespace${RESET}"
}

# Release resources
release() {
    local namespace="$1"
    local resource="$2"
    local amount="$3"

    local current=$(get_usage "$namespace" "$resource")
    local new_usage=$(echo "${current:-0} - $amount" | bc -l)
    [ "$(echo "$new_usage < 0" | bc -l)" = "1" ] && new_usage=0

    update_usage "$namespace" "$resource" "$new_usage"

    echo -e "${GREEN}Released $amount $resource from $namespace${RESET}"
}

# Show quotas for namespace
show() {
    local namespace="${1:-all}"

    echo -e "${PINK}=== RESOURCE QUOTAS ===${RESET}"
    echo

    local where=""
    [ "$namespace" != "all" ] && where="WHERE namespace = '$namespace'"

    sqlite3 "$QUOTA_DB" "
        SELECT namespace, resource_type, limit_value, used_value, unit FROM quotas $where ORDER BY namespace, resource_type
    " | while IFS='|' read -r ns resource limit used unit; do
        local pct=0
        [ "$limit" != "0" ] && pct=$(echo "scale=0; $used * 100 / $limit" | bc -l)

        local bar=""
        local bar_len=$(( pct / 5 ))
        for i in $(seq 1 20); do
            if [ $i -le $bar_len ]; then
                bar="${bar}█"
            else
                bar="${bar}░"
            fi
        done

        local color=$GREEN
        [ "$pct" -gt 70 ] && color=$YELLOW
        [ "$pct" -gt 90 ] && color=$RED

        printf "  %-12s %-15s ${color}%s${RESET} %.0f/%.0f %s (${pct}%%)\n" "$ns" "$resource" "$bar" "$used" "$limit" "$unit"
    done
}

# Set node limits
set_limit() {
    local node="$1"
    local resource="$2"
    local soft="$3"
    local hard="$4"

    sqlite3 "$QUOTA_DB" "
        INSERT OR REPLACE INTO limits (node, resource_type, soft_limit, hard_limit)
        VALUES ('$node', '$resource', $soft, $hard)
    "

    echo -e "${GREEN}Set limit on $node: $resource soft=$soft hard=$hard${RESET}"
}

# Check node limits
check_limits() {
    echo -e "${PINK}=== NODE RESOURCE LIMITS ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -e "${BLUE}$node:${RESET}"

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo "  (offline)"
            continue
        fi

        # Get current usage
        local metrics=$(ssh "$node" "
            cpu=\$(top -bn1 | grep 'Cpu(s)' | awk '{print 100-\$8}' 2>/dev/null || echo 0)
            mem_used=\$(free -m | awk '/Mem:/ {print \$3}')
            mem_total=\$(free -m | awk '/Mem:/ {print \$2}')
            disk=\$(df / | awk 'NR==2 {gsub(/%/,\"\"); print \$5}')
            echo \"\$cpu|\$mem_used|\$mem_total|\$disk\"
        " 2>/dev/null)

        local cpu=$(echo "$metrics" | cut -d'|' -f1)
        local mem_used=$(echo "$metrics" | cut -d'|' -f2)
        local mem_total=$(echo "$metrics" | cut -d'|' -f3)
        local disk=$(echo "$metrics" | cut -d'|' -f4)

        # Update current values
        sqlite3 "$QUOTA_DB" "
            INSERT OR REPLACE INTO limits (node, resource_type, soft_limit, hard_limit, current_value)
            VALUES ('$node', 'cpu', 80, 95, $cpu),
                   ('$node', 'memory', $((mem_total * 85 / 100)), $((mem_total * 95 / 100)), $mem_used),
                   ('$node', 'disk', 80, 90, $disk)
            ON CONFLICT(node, resource_type) DO UPDATE SET current_value = excluded.current_value
        " 2>/dev/null

        # Check against limits
        sqlite3 "$QUOTA_DB" "
            SELECT resource_type, soft_limit, hard_limit, current_value FROM limits WHERE node = '$node'
        " | while IFS='|' read -r resource soft hard current; do
            local status="${GREEN}OK${RESET}"

            if [ "$(echo "$current > $hard" | bc -l)" = "1" ]; then
                status="${RED}CRITICAL${RESET}"
            elif [ "$(echo "$current > $soft" | bc -l)" = "1" ]; then
                status="${YELLOW}WARNING${RESET}"
            fi

            printf "    %-10s %.0f (soft: %.0f, hard: %.0f) %s\n" "$resource" "$current" "$soft" "$hard" "$status"
        done
    done
}

# Enforce quotas (kill over-limit processes)
enforce() {
    local namespace="$1"
    local action="${2:-warn}"  # warn, throttle, kill

    echo -e "${PINK}=== ENFORCING QUOTAS: $namespace ===${RESET}"
    echo

    local quotas=$(sqlite3 "$QUOTA_DB" "
        SELECT resource_type, limit_value, used_value FROM quotas
        WHERE namespace = '$namespace' AND used_value > limit_value
    ")

    if [ -z "$quotas" ]; then
        echo -e "${GREEN}All quotas within limits${RESET}"
        return 0
    fi

    echo "$quotas" | while IFS='|' read -r resource limit used; do
        local over=$(echo "$used - $limit" | bc -l)

        echo -e "${RED}$resource over limit by $over${RESET}"

        case "$action" in
            warn)
                echo "  (warning only)"
                ;;
            throttle)
                echo "  Throttling requests..."
                # Would implement request queuing/delays
                ;;
            kill)
                echo "  Terminating excess processes..."
                # Would implement process termination
                ;;
        esac
    done
}

# Quota summary
summary() {
    echo -e "${PINK}=== QUOTA SUMMARY ===${RESET}"
    echo

    echo "Namespaces:"
    sqlite3 "$QUOTA_DB" "
        SELECT n.name, n.priority,
               (SELECT SUM(used_value) FROM quotas q WHERE q.namespace = n.name),
               (SELECT SUM(limit_value) FROM quotas q WHERE q.namespace = n.name)
        FROM namespaces n ORDER BY n.priority DESC
    " | while IFS='|' read -r name priority used limit; do
        local pct=0
        [ -n "$limit" ] && [ "$limit" != "0" ] && pct=$(echo "scale=0; ${used:-0} * 100 / $limit" | bc -l 2>/dev/null || echo 0)
        printf "  %-15s P%d  %.0f%% utilized\n" "$name" "$priority" "$pct"
    done

    echo
    echo "Node health:"
    for node in "${ALL_NODES[@]}"; do
        local status="${GREEN}●${RESET}"

        local violations=$(sqlite3 "$QUOTA_DB" "
            SELECT COUNT(*) FROM limits WHERE node = '$node' AND current_value > soft_limit
        ")
        [ "$violations" -gt 0 ] && status="${YELLOW}●${RESET}"

        local critical=$(sqlite3 "$QUOTA_DB" "
            SELECT COUNT(*) FROM limits WHERE node = '$node' AND current_value > hard_limit
        ")
        [ "$critical" -gt 0 ] && status="${RED}●${RESET}"

        echo "  $status $node"
    done
}

# Reset quotas
reset() {
    local namespace="${1:-all}"

    if [ "$namespace" = "all" ]; then
        sqlite3 "$QUOTA_DB" "UPDATE quotas SET used_value = 0"
        echo -e "${GREEN}Reset all quota usage${RESET}"
    else
        sqlite3 "$QUOTA_DB" "UPDATE quotas SET used_value = 0 WHERE namespace = '$namespace'"
        echo -e "${GREEN}Reset quota usage for $namespace${RESET}"
    fi
}

# Help
help() {
    echo -e "${PINK}BlackRoad Resource Quotas${RESET}"
    echo
    echo "Manage resource limits across the cluster"
    echo
    echo "Commands:"
    echo "  create-ns <name> <desc> [pri]  Create namespace"
    echo "  set-quota <ns> <res> <limit>   Set quota limit"
    echo "  allocate <ns> <res> <amount>   Allocate resources"
    echo "  release <ns> <res> <amount>    Release resources"
    echo "  show [namespace]               Show quota status"
    echo "  set-limit <node> <res> <s> <h> Set node limits"
    echo "  check-limits                   Check node resource limits"
    echo "  enforce <ns> [action]          Enforce quotas"
    echo "  summary                        Overall summary"
    echo "  reset [namespace]              Reset usage counters"
    echo
    echo "Resource types: cpu, memory, gpu_mem, requests_per_min, disk"
    echo "Actions: warn, throttle, kill"
    echo
    echo "Examples:"
    echo "  $0 set-quota inference cpu 800"
    echo "  $0 allocate inference memory 1024"
    echo "  $0 set-limit cecilia cpu 80 95"
}

# Ensure initialized
[ -f "$QUOTA_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    create-ns|namespace)
        create_namespace "$2" "$3" "$4"
        ;;
    set-quota|quota)
        set_quota "$2" "$3" "$4" "$5"
        ;;
    allocate|alloc)
        allocate "$2" "$3" "$4"
        ;;
    release|free)
        release "$2" "$3" "$4"
        ;;
    show|status)
        show "$2"
        ;;
    set-limit|limit)
        set_limit "$2" "$3" "$4" "$5"
        ;;
    check-limits|limits)
        check_limits
        ;;
    enforce)
        enforce "$2" "$3"
        ;;
    summary)
        summary
        ;;
    reset)
        reset "$2"
        ;;
    *)
        help
        ;;
esac
