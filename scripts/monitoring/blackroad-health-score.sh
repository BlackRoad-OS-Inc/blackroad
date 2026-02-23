#!/bin/bash
# BlackRoad Health Score
# Comprehensive cluster health scoring and reporting
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

HEALTH_DIR="$HOME/.blackroad/health"
HEALTH_DB="$HEALTH_DIR/health.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Weights for health components
WEIGHT_AVAILABILITY=25
WEIGHT_PERFORMANCE=25
WEIGHT_RESOURCES=20
WEIGHT_SERVICES=20
WEIGHT_ERRORS=10

# Initialize
init() {
    mkdir -p "$HEALTH_DIR"/{reports,history}

    sqlite3 "$HEALTH_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS health_scores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    overall INTEGER,
    availability INTEGER,
    performance INTEGER,
    resources INTEGER,
    services INTEGER,
    errors INTEGER,
    details TEXT
);

CREATE TABLE IF NOT EXISTS node_health (
    node TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    score INTEGER,
    cpu REAL,
    memory REAL,
    disk REAL,
    temperature REAL,
    uptime INTEGER,
    PRIMARY KEY (node, timestamp)
);

CREATE TABLE IF NOT EXISTS service_health (
    service TEXT,
    node TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    healthy INTEGER,
    latency_ms INTEGER,
    PRIMARY KEY (service, node, timestamp)
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity TEXT,
    component TEXT,
    message TEXT,
    resolved INTEGER DEFAULT 0
);
SQL

    echo -e "${GREEN}Health scoring system initialized${RESET}"
}

# Check node availability
check_availability() {
    local available=0
    local total=${#ALL_NODES[@]}

    for node in "${ALL_NODES[@]}"; do
        if ssh -o ConnectTimeout=3 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
            ((available++))
        fi
    done

    echo $((available * 100 / total))
}

# Check performance metrics
check_performance() {
    local total_score=0
    local node_count=0

    for node in "${ALL_NODES[@]}"; do
        local metrics=$(ssh -o ConnectTimeout=5 "$node" "
            load=\$(cat /proc/loadavg | awk '{print \$1}')
            cores=\$(nproc)
            load_pct=\$(echo \"scale=0; \$load * 100 / \$cores\" | bc)
            echo \$load_pct
        " 2>/dev/null)

        if [ -n "$metrics" ]; then
            # Lower load = higher score
            local score=$((100 - metrics))
            [ "$score" -lt 0 ] && score=0
            total_score=$((total_score + score))
            ((node_count++))
        fi
    done

    [ "$node_count" -eq 0 ] && echo 0 && return

    echo $((total_score / node_count))
}

# Check resource utilization
check_resources() {
    local total_score=0
    local node_count=0

    for node in "${ALL_NODES[@]}"; do
        local metrics=$(ssh -o ConnectTimeout=5 "$node" "
            mem=\$(free | awk '/Mem:/ {printf \"%.0f\", \$3/\$2*100}')
            disk=\$(df / | awk 'NR==2 {gsub(/%/,\"\"); print \$5}')
            echo \"\$mem|\$disk\"
        " 2>/dev/null)

        if [ -n "$metrics" ]; then
            local mem=$(echo "$metrics" | cut -d'|' -f1)
            local disk=$(echo "$metrics" | cut -d'|' -f2)

            # Calculate resource score (lower usage = higher score)
            local mem_score=$((100 - mem))
            local disk_score=$((100 - disk))
            local node_score=$(( (mem_score + disk_score) / 2 ))

            total_score=$((total_score + node_score))
            ((node_count++))

            # Store node health
            sqlite3 "$HEALTH_DB" "
                INSERT INTO node_health (node, score, memory, disk)
                VALUES ('$node', $node_score, $mem, $disk)
            " 2>/dev/null
        fi
    done

    [ "$node_count" -eq 0 ] && echo 0 && return

    echo $((total_score / node_count))
}

# Check service health
check_services() {
    local total_score=0
    local service_count=0

    # Check Ollama on each node
    for node in "${ALL_NODES[@]}"; do
        local start=$(date +%s%N)
        local response=$(ssh -o ConnectTimeout=10 "$node" "curl -s -o /dev/null -w '%{http_code}' http://localhost:11434/api/tags" 2>/dev/null)
        local end=$(date +%s%N)
        local latency=$(( (end - start) / 1000000 ))

        local healthy=0
        [ "$response" = "200" ] && healthy=1

        sqlite3 "$HEALTH_DB" "
            INSERT INTO service_health (service, node, healthy, latency_ms)
            VALUES ('ollama', '$node', $healthy, $latency)
        " 2>/dev/null

        if [ "$healthy" = "1" ]; then
            # Score based on latency (faster = better)
            local latency_score=100
            [ "$latency" -gt 500 ] && latency_score=80
            [ "$latency" -gt 1000 ] && latency_score=60
            [ "$latency" -gt 2000 ] && latency_score=40
            [ "$latency" -gt 5000 ] && latency_score=20

            total_score=$((total_score + latency_score))
        fi

        ((service_count++))
    done

    [ "$service_count" -eq 0 ] && echo 0 && return

    echo $((total_score / service_count))
}

# Check error rates
check_errors() {
    local recent_errors=$(sqlite3 "$HEALTH_DB" "
        SELECT COUNT(*) FROM alerts
        WHERE datetime(timestamp, '+1 hour') > datetime('now')
        AND resolved = 0
    " 2>/dev/null || echo 0)

    # Fewer errors = higher score
    local score=100
    [ "$recent_errors" -gt 0 ] && score=80
    [ "$recent_errors" -gt 5 ] && score=60
    [ "$recent_errors" -gt 10 ] && score=40
    [ "$recent_errors" -gt 20 ] && score=20

    echo "$score"
}

# Calculate overall health score
calculate() {
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🏥 CLUSTER HEALTH CHECK                            ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    echo -n "Checking availability... "
    local availability=$(check_availability)
    echo "${availability}%"

    echo -n "Checking performance... "
    local performance=$(check_performance)
    echo "${performance}%"

    echo -n "Checking resources... "
    local resources=$(check_resources)
    echo "${resources}%"

    echo -n "Checking services... "
    local services=$(check_services)
    echo "${services}%"

    echo -n "Checking errors... "
    local errors=$(check_errors)
    echo "${errors}%"

    # Calculate weighted score
    local overall=$(( \
        (availability * WEIGHT_AVAILABILITY + \
         performance * WEIGHT_PERFORMANCE + \
         resources * WEIGHT_RESOURCES + \
         services * WEIGHT_SERVICES + \
         errors * WEIGHT_ERRORS) / 100 \
    ))

    # Store score
    sqlite3 "$HEALTH_DB" "
        INSERT INTO health_scores (overall, availability, performance, resources, services, errors)
        VALUES ($overall, $availability, $performance, $resources, $services, $errors)
    "

    echo
    echo "┌────────────────────────────────────────────────────────────────┐"
    echo "│ Component          │ Score │ Weight │ Contribution            │"
    echo "├────────────────────┼───────┼────────┼─────────────────────────┤"
    printf "│ Availability       │ %3d%%  │  %2d%%  │ %3d                     │\n" "$availability" "$WEIGHT_AVAILABILITY" "$((availability * WEIGHT_AVAILABILITY / 100))"
    printf "│ Performance        │ %3d%%  │  %2d%%  │ %3d                     │\n" "$performance" "$WEIGHT_PERFORMANCE" "$((performance * WEIGHT_PERFORMANCE / 100))"
    printf "│ Resources          │ %3d%%  │  %2d%%  │ %3d                     │\n" "$resources" "$WEIGHT_RESOURCES" "$((resources * WEIGHT_RESOURCES / 100))"
    printf "│ Services           │ %3d%%  │  %2d%%  │ %3d                     │\n" "$services" "$WEIGHT_SERVICES" "$((services * WEIGHT_SERVICES / 100))"
    printf "│ Error Rate         │ %3d%%  │  %2d%%  │ %3d                     │\n" "$errors" "$WEIGHT_ERRORS" "$((errors * WEIGHT_ERRORS / 100))"
    echo "└────────────────────┴───────┴────────┴─────────────────────────┘"
    echo

    # Display overall score with color
    local color=$GREEN
    [ "$overall" -lt 80 ] && color=$YELLOW
    [ "$overall" -lt 60 ] && color=$RED

    echo -e "                    ${color}╔═══════════════════════╗${RESET}"
    echo -e "                    ${color}║   HEALTH SCORE: ${overall}%   ║${RESET}"
    echo -e "                    ${color}╚═══════════════════════╝${RESET}"

    # Generate alerts for low scores
    if [ "$availability" -lt 80 ]; then
        add_alert "warning" "availability" "Availability at ${availability}%"
    fi
    if [ "$resources" -lt 50 ]; then
        add_alert "warning" "resources" "Resource utilization high"
    fi
    if [ "$services" -lt 60 ]; then
        add_alert "warning" "services" "Service health degraded at ${services}%"
    fi

    echo "$overall"
}

# Add alert
add_alert() {
    local severity="$1"
    local component="$2"
    local message="$3"

    sqlite3 "$HEALTH_DB" "
        INSERT INTO alerts (severity, component, message)
        VALUES ('$severity', '$component', '$message')
    "
}

# Quick score (just the number)
quick() {
    local availability=$(check_availability)
    local performance=$(check_performance)
    local resources=$(check_resources)
    local services=$(check_services)
    local errors=$(check_errors)

    local overall=$(( \
        (availability * WEIGHT_AVAILABILITY + \
         performance * WEIGHT_PERFORMANCE + \
         resources * WEIGHT_RESOURCES + \
         services * WEIGHT_SERVICES + \
         errors * WEIGHT_ERRORS) / 100 \
    ))

    echo "$overall"
}

# Show history
history() {
    local limit="${1:-10}"

    echo -e "${PINK}=== HEALTH HISTORY ===${RESET}"
    echo

    sqlite3 "$HEALTH_DB" "
        SELECT timestamp, overall, availability, performance, resources, services
        FROM health_scores ORDER BY timestamp DESC LIMIT $limit
    " | while IFS='|' read -r ts overall avail perf res svc; do
        local color=$GREEN
        [ "$overall" -lt 80 ] && color=$YELLOW
        [ "$overall" -lt 60 ] && color=$RED

        printf "  %s  ${color}%3d%%${RESET}  (A:%d P:%d R:%d S:%d)\n" "$ts" "$overall" "$avail" "$perf" "$res" "$svc"
    done
}

# Trend analysis
trend() {
    echo -e "${PINK}=== HEALTH TREND ===${RESET}"
    echo

    local current=$(sqlite3 "$HEALTH_DB" "SELECT overall FROM health_scores ORDER BY timestamp DESC LIMIT 1")
    local hour_ago=$(sqlite3 "$HEALTH_DB" "SELECT AVG(overall) FROM health_scores WHERE datetime(timestamp, '+1 hour') > datetime('now')")
    local day_ago=$(sqlite3 "$HEALTH_DB" "SELECT AVG(overall) FROM health_scores WHERE datetime(timestamp, '+1 day') > datetime('now')")

    echo "Current:   ${current:-N/A}%"
    printf "Last hour: %.0f%%\n" "${hour_ago:-0}"
    printf "Last day:  %.0f%%\n" "${day_ago:-0}"

    if [ -n "$current" ] && [ -n "$hour_ago" ]; then
        local diff=$(echo "$current - $hour_ago" | bc 2>/dev/null || echo 0)
        if [ "$(echo "$diff > 5" | bc -l)" = "1" ]; then
            echo -e "\nTrend: ${GREEN}↑ Improving${RESET}"
        elif [ "$(echo "$diff < -5" | bc -l)" = "1" ]; then
            echo -e "\nTrend: ${RED}↓ Degrading${RESET}"
        else
            echo -e "\nTrend: ${YELLOW}→ Stable${RESET}"
        fi
    fi
}

# Node breakdown
nodes() {
    echo -e "${PINK}=== NODE HEALTH ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        local health=$(sqlite3 "$HEALTH_DB" "
            SELECT score, memory, disk FROM node_health
            WHERE node = '$node' ORDER BY timestamp DESC LIMIT 1
        ")

        if [ -z "$health" ]; then
            echo -e "  $node: ${YELLOW}No data${RESET}"
            continue
        fi

        local score=$(echo "$health" | cut -d'|' -f1)
        local mem=$(echo "$health" | cut -d'|' -f2)
        local disk=$(echo "$health" | cut -d'|' -f3)

        local color=$GREEN
        [ "$score" -lt 70 ] && color=$YELLOW
        [ "$score" -lt 50 ] && color=$RED

        printf "  %-10s ${color}%3d%%${RESET}  (mem: %.0f%%, disk: %.0f%%)\n" "$node" "$score" "$mem" "$disk"
    done
}

# Alerts
alerts() {
    local filter="${1:-unresolved}"

    echo -e "${PINK}=== ALERTS ===${RESET}"
    echo

    local where="WHERE resolved = 0"
    [ "$filter" = "all" ] && where=""

    sqlite3 "$HEALTH_DB" "
        SELECT id, severity, component, message, timestamp FROM alerts $where ORDER BY timestamp DESC LIMIT 20
    " | while IFS='|' read -r id sev comp msg ts; do
        local color=$RESET
        [ "$sev" = "warning" ] && color=$YELLOW
        [ "$sev" = "error" ] && color=$RED
        [ "$sev" = "critical" ] && color="${RED}\033[1m"

        printf "  ${color}#%-4d [%-8s] %-12s %s${RESET}\n" "$id" "$sev" "$comp" "$msg"
    done
}

# Resolve alert
resolve() {
    local id="$1"

    sqlite3 "$HEALTH_DB" "UPDATE alerts SET resolved = 1 WHERE id = $id"
    echo -e "${GREEN}Resolved alert #$id${RESET}"
}

# Dashboard
dashboard() {
    clear
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           📊 CLUSTER HEALTH DASHBOARD                        ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    local score=$(quick)

    local color=$GREEN
    [ "$score" -lt 80 ] && color=$YELLOW
    [ "$score" -lt 60 ] && color=$RED

    echo -e "                    Overall Health: ${color}${score}%${RESET}"
    echo
    echo "─────────────────────────────────────────────────────────────────"
    nodes
    echo "─────────────────────────────────────────────────────────────────"
    echo
    alerts
}

# Help
help() {
    echo -e "${PINK}BlackRoad Health Score${RESET}"
    echo
    echo "Comprehensive cluster health monitoring"
    echo
    echo "Commands:"
    echo "  calculate           Full health check with details"
    echo "  quick               Just the score number"
    echo "  history [limit]     Historical scores"
    echo "  trend               Score trend analysis"
    echo "  nodes               Per-node breakdown"
    echo "  alerts [all]        View alerts"
    echo "  resolve <id>        Resolve alert"
    echo "  dashboard           Live dashboard"
    echo
    echo "Examples:"
    echo "  $0 calculate"
    echo "  $0 history 20"
    echo "  $0 resolve 5"
}

# Ensure initialized
[ -f "$HEALTH_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    calculate|check|score)
        calculate
        ;;
    quick)
        quick
        ;;
    history)
        history "$2"
        ;;
    trend)
        trend
        ;;
    nodes)
        nodes
        ;;
    alerts)
        alerts "$2"
        ;;
    resolve)
        resolve "$2"
        ;;
    dashboard|dash)
        dashboard
        ;;
    *)
        help
        ;;
esac
