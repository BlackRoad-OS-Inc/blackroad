#!/bin/bash
# BlackRoad Cluster Monitor
# Real-time monitoring with alerts
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

ALL_NODES=("alice" "aria" "lucidia" "octavia" "cecilia" "codex-infinity" "shellfish")
LLM_NODES=("lucidia" "cecilia" "octavia" "aria")
HAILO_NODES=("cecilia" "lucidia")

ALERT_TEMP=70  # Celsius
ALERT_LOAD=10  # Load average

# Check single node
check_node() {
    local node="$1"
    local result=""

    if ! ssh -o ConnectTimeout=2 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
        echo "offline"
        return
    fi

    # Get metrics
    local metrics=$(ssh -o ConnectTimeout=5 "$node" "
        echo -n 'load:'; cat /proc/loadavg | awk '{print \$1}';
        echo -n 'mem:'; free | awk '/Mem:/ {printf \"%.0f\", \$3/\$2*100}';
        echo -n 'temp:'; vcgencmd measure_temp 2>/dev/null | grep -oP '[\d.]+' || echo 0;
        echo -n 'containers:'; docker ps -q 2>/dev/null | wc -l;
    " 2>/dev/null)

    echo "$metrics"
}

# Full cluster status
cluster_status() {
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           📊 BLACKROAD CLUSTER MONITOR 📊                    ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo

    printf "%-12s %-8s %-6s %-6s %-6s %-10s\n" "NODE" "STATUS" "LOAD" "MEM%" "TEMP" "CONTAINERS"
    echo "────────────────────────────────────────────────────────────"

    local online=0
    local total=${#ALL_NODES[@]}
    local alerts=()

    for node in "${ALL_NODES[@]}"; do
        local metrics=$(check_node "$node")

        if [ "$metrics" = "offline" ]; then
            printf "%-12s ${RED}%-8s${RESET}\n" "$node" "OFFLINE"
            alerts+=("$node is OFFLINE")
        else
            local load=$(echo "$metrics" | grep -oP 'load:\K[\d.]+')
            local mem=$(echo "$metrics" | grep -oP 'mem:\K\d+')
            local temp=$(echo "$metrics" | grep -oP 'temp:\K[\d.]+')
            local containers=$(echo "$metrics" | grep -oP 'containers:\K\d+')

            local status="${GREEN}ONLINE${RESET}"

            # Check for alerts
            if (( $(echo "$load > $ALERT_LOAD" | bc -l) )); then
                status="${YELLOW}HIGH LOAD${RESET}"
                alerts+=("$node load is $load")
            fi
            if (( $(echo "$temp > $ALERT_TEMP" | bc -l) )); then
                status="${RED}HOT${RESET}"
                alerts+=("$node temp is ${temp}°C")
            fi

            printf "%-12s %-18s %-6s %-6s %-6s %-10s\n" "$node" "$status" "$load" "${mem}%" "${temp}°C" "$containers"
            ((online++))
        fi
    done

    echo
    echo -e "${GREEN}Online: $online/$total nodes${RESET}"

    # Show alerts
    if [ ${#alerts[@]} -gt 0 ]; then
        echo
        echo -e "${RED}⚠️  ALERTS:${RESET}"
        for alert in "${alerts[@]}"; do
            echo -e "  ${YELLOW}• $alert${RESET}"
        done
    fi
}

# LLM status
llm_status() {
    echo -e "${PINK}=== LLM CLUSTER STATUS ===${RESET}"
    echo

    for node in "${LLM_NODES[@]}"; do
        echo -n "  $node: "
        if ssh -o ConnectTimeout=2 "$node" "curl -s http://localhost:11434/api/tags" >/dev/null 2>&1; then
            local models=$(ssh "$node" "curl -s http://localhost:11434/api/tags" 2>/dev/null | jq -r '.models | length')
            echo -e "${GREEN}ONLINE${RESET} ($models models)"
        else
            echo -e "${YELLOW}OFFLINE${RESET}"
        fi
    done
}

# Hailo status
hailo_status() {
    echo -e "${PINK}=== HAILO-8 STATUS ===${RESET}"
    echo

    for node in "${HAILO_NODES[@]}"; do
        echo -n "  $node: "
        local hailo=$(ssh -o ConnectTimeout=5 "$node" "hailortcli fw-control identify 2>&1 | grep -E 'Serial|Board'" 2>/dev/null)
        if [ -n "$hailo" ]; then
            echo -e "${GREEN}ACTIVE${RESET} (26 TOPS)"
        else
            echo -e "${YELLOW}NOT DETECTED${RESET}"
        fi
    done
}

# Watch mode (live updates)
watch_mode() {
    local interval="${1:-5}"

    while true; do
        clear
        cluster_status
        echo
        llm_status
        echo
        hailo_status
        echo
        echo -e "${BLUE}Refreshing every ${interval}s... Press Ctrl+C to stop${RESET}"
        sleep "$interval"
    done
}

# Quick health check (for scripts)
health_check() {
    local healthy=0
    local total=${#ALL_NODES[@]}

    for node in "${ALL_NODES[@]}"; do
        if ssh -o ConnectTimeout=2 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
            ((healthy++))
        fi
    done

    if [ $healthy -eq $total ]; then
        echo "healthy"
        return 0
    elif [ $healthy -gt 0 ]; then
        echo "degraded"
        return 1
    else
        echo "down"
        return 2
    fi
}

# Export metrics as JSON
metrics_json() {
    echo "{"
    echo '  "timestamp": "'$(date -Iseconds)'",'
    echo '  "nodes": {'

    local first=true
    for node in "${ALL_NODES[@]}"; do
        [ "$first" = true ] || echo ","
        first=false

        echo -n "    \"$node\": "
        local metrics=$(check_node "$node")

        if [ "$metrics" = "offline" ]; then
            echo -n '{"status": "offline"}'
        else
            local load=$(echo "$metrics" | grep -oP 'load:\K[\d.]+')
            local mem=$(echo "$metrics" | grep -oP 'mem:\K\d+')
            local temp=$(echo "$metrics" | grep -oP 'temp:\K[\d.]+')
            local containers=$(echo "$metrics" | grep -oP 'containers:\K\d+')
            echo -n "{\"status\": \"online\", \"load\": $load, \"mem_percent\": $mem, \"temp_c\": $temp, \"containers\": $containers}"
        fi
    done

    echo
    echo "  }"
    echo "}"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Cluster Monitor${RESET}"
    echo
    echo "Commands:"
    echo "  status          Full cluster status"
    echo "  llm             LLM cluster status"
    echo "  hailo           Hailo-8 accelerator status"
    echo "  watch [sec]     Live monitoring (default 5s)"
    echo "  health          Quick health check (for scripts)"
    echo "  json            Export metrics as JSON"
    echo
    echo "Alert thresholds:"
    echo "  Temperature: ${ALERT_TEMP}°C"
    echo "  Load average: $ALERT_LOAD"
}

case "${1:-status}" in
    status)
        cluster_status
        ;;
    llm)
        llm_status
        ;;
    hailo)
        hailo_status
        ;;
    watch)
        watch_mode "$2"
        ;;
    health)
        health_check
        ;;
    json)
        metrics_json
        ;;
    *)
        help
        ;;
esac
