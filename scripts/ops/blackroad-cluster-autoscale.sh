#!/bin/bash
# BlackRoad Cluster Autoscaler
# Dynamically scale workloads across Pi nodes based on load
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# All nodes in the cluster
ALL_NODES=("alice" "aria" "lucidia" "octavia" "cecilia" "codex-infinity" "shellfish")
LLM_NODES=("lucidia" "cecilia" "octavia" "aria")

# Autoscale configuration
CONFIG_DIR="$HOME/.blackroad/autoscale"
STATE_FILE="$CONFIG_DIR/state.json"
METRICS_FILE="$CONFIG_DIR/metrics.jsonl"

# Thresholds
SCALE_UP_LOAD=5.0       # Scale up if load > this
SCALE_DOWN_LOAD=1.0     # Scale down if load < this
SCALE_UP_MEM=80         # Scale up if memory% > this
SCALE_DOWN_MEM=30       # Scale down if memory% < this
COOLDOWN_SECONDS=60     # Wait between scaling actions

# Initialize
init() {
    mkdir -p "$CONFIG_DIR"

    [ -f "$STATE_FILE" ] || cat > "$STATE_FILE" << 'EOF'
{
    "active_nodes": ["lucidia", "cecilia"],
    "standby_nodes": ["octavia", "aria"],
    "last_scale_action": null,
    "scale_history": []
}
EOF

    echo -e "${GREEN}Autoscaler initialized${RESET}"
    echo "  Config: $CONFIG_DIR"
    echo "  State: $STATE_FILE"
}

# Get node metrics
get_metrics() {
    local node="$1"

    if ! ssh -o ConnectTimeout=2 -o BatchMode=yes "$node" "echo ok" >/dev/null 2>&1; then
        echo "offline:0:0:0"
        return
    fi

    ssh -o ConnectTimeout=5 "$node" "
        load=\$(cat /proc/loadavg | awk '{print \$1}')
        mem=\$(free | awk '/Mem:/ {printf \"%.0f\", \$3/\$2*100}')
        containers=\$(docker ps -q 2>/dev/null | wc -l)
        echo \"online:\$load:\$mem:\$containers\"
    " 2>/dev/null || echo "error:0:0:0"
}

# Analyze cluster and decide scaling action
analyze() {
    echo -e "${PINK}=== CLUSTER ANALYSIS ===${RESET}"
    echo

    local total_load=0
    local total_mem=0
    local online_count=0
    local active_nodes=$(jq -r '.active_nodes[]' "$STATE_FILE" 2>/dev/null)

    printf "%-12s %-8s %-8s %-8s %-12s\n" "NODE" "STATUS" "LOAD" "MEM%" "CONTAINERS"
    echo "────────────────────────────────────────────────────────"

    for node in "${LLM_NODES[@]}"; do
        local metrics=$(get_metrics "$node")
        local status=$(echo "$metrics" | cut -d: -f1)
        local load=$(echo "$metrics" | cut -d: -f2)
        local mem=$(echo "$metrics" | cut -d: -f3)
        local containers=$(echo "$metrics" | cut -d: -f4)

        local is_active="standby"
        if echo "$active_nodes" | grep -q "$node"; then
            is_active="active"
        fi

        if [ "$status" = "online" ]; then
            total_load=$(echo "$total_load + $load" | bc)
            total_mem=$((total_mem + mem))
            ((online_count++))

            local color=$GREEN
            [ "$(echo "$load > $SCALE_UP_LOAD" | bc -l)" = "1" ] && color=$YELLOW
            [ "$mem" -gt "$SCALE_UP_MEM" ] && color=$RED

            printf "%-12s ${color}%-8s${RESET} %-8s %-8s %-12s [%s]\n" \
                "$node" "$status" "$load" "${mem}%" "$containers" "$is_active"
        else
            printf "%-12s ${RED}%-8s${RESET} %-8s %-8s %-12s [%s]\n" \
                "$node" "$status" "-" "-" "-" "$is_active"
        fi

        # Log metrics
        echo "{\"node\":\"$node\",\"status\":\"$status\",\"load\":$load,\"mem\":$mem,\"containers\":$containers,\"timestamp\":\"$(date -Iseconds)\"}" >> "$METRICS_FILE"
    done

    echo
    local avg_load=$(echo "scale=2; $total_load / $online_count" | bc 2>/dev/null || echo 0)
    local avg_mem=$((total_mem / (online_count > 0 ? online_count : 1)))
    local active_count=$(echo "$active_nodes" | wc -w)

    echo "Summary:"
    echo "  Active nodes: $active_count"
    echo "  Online nodes: $online_count"
    echo "  Average load: $avg_load"
    echo "  Average memory: ${avg_mem}%"
    echo

    # Scaling recommendation
    echo "Recommendation:"
    if [ "$(echo "$avg_load > $SCALE_UP_LOAD" | bc -l)" = "1" ] || [ "$avg_mem" -gt "$SCALE_UP_MEM" ]; then
        echo -e "  ${YELLOW}SCALE UP${RESET} - High load/memory detected"
    elif [ "$(echo "$avg_load < $SCALE_DOWN_LOAD" | bc -l)" = "1" ] && [ "$avg_mem" -lt "$SCALE_DOWN_MEM" ]; then
        echo -e "  ${BLUE}SCALE DOWN${RESET} - Low utilization"
    else
        echo -e "  ${GREEN}STABLE${RESET} - No action needed"
    fi
}

# Scale up - activate a standby node
scale_up() {
    local reason="${1:-manual}"

    echo -e "${PINK}=== SCALE UP ===${RESET}"
    echo "Reason: $reason"
    echo

    # Get current state
    local standby=$(jq -r '.standby_nodes[0] // empty' "$STATE_FILE")

    if [ -z "$standby" ]; then
        echo -e "${YELLOW}No standby nodes available${RESET}"
        return 1
    fi

    echo "Activating: $standby"

    # Check if node is online
    if ! ssh -o ConnectTimeout=3 "$standby" "echo ok" >/dev/null 2>&1; then
        echo -e "${RED}Node $standby is offline, cannot activate${RESET}"
        return 1
    fi

    # Start Ollama on the node
    echo "  Starting Ollama..."
    ssh "$standby" "ollama serve &>/dev/null &" 2>/dev/null

    # Update state
    jq --arg node "$standby" \
       --arg reason "$reason" \
       --arg time "$(date -Iseconds)" \
       '.active_nodes += [$node] |
        .standby_nodes = [.standby_nodes[] | select(. != $node)] |
        .last_scale_action = $time |
        .scale_history += [{"action":"up","node":$node,"reason":$reason,"time":$time}]' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo -e "${GREEN}Scaled up: $standby is now active${RESET}"

    # Log to memory system
    ~/memory-system.sh log scaled_up "$standby" "Autoscaler activated node: $reason" "autoscale,cluster" 2>/dev/null
}

# Scale down - deactivate an active node
scale_down() {
    local reason="${1:-manual}"

    echo -e "${PINK}=== SCALE DOWN ===${RESET}"
    echo "Reason: $reason"
    echo

    # Get current state (keep at least 2 active)
    local active_count=$(jq '.active_nodes | length' "$STATE_FILE")
    if [ "$active_count" -le 2 ]; then
        echo -e "${YELLOW}Cannot scale down: minimum 2 active nodes required${RESET}"
        return 1
    fi

    # Find least loaded active node
    local best_node=""
    local best_load=999

    for node in $(jq -r '.active_nodes[]' "$STATE_FILE"); do
        local metrics=$(get_metrics "$node")
        local load=$(echo "$metrics" | cut -d: -f2)

        if [ "$(echo "$load < $best_load" | bc -l)" = "1" ]; then
            best_load=$load
            best_node=$node
        fi
    done

    if [ -z "$best_node" ]; then
        echo -e "${RED}Could not find node to deactivate${RESET}"
        return 1
    fi

    echo "Deactivating: $best_node (load: $best_load)"

    # Stop LLM service on the node (keep node alive)
    echo "  Stopping LLM service..."
    ssh "$best_node" "pkill -f ollama 2>/dev/null" 2>/dev/null

    # Update state
    jq --arg node "$best_node" \
       --arg reason "$reason" \
       --arg time "$(date -Iseconds)" \
       '.standby_nodes += [$node] |
        .active_nodes = [.active_nodes[] | select(. != $node)] |
        .last_scale_action = $time |
        .scale_history += [{"action":"down","node":$node,"reason":$reason,"time":$time}]' \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo -e "${GREEN}Scaled down: $best_node is now standby${RESET}"

    ~/memory-system.sh log scaled_down "$best_node" "Autoscaler deactivated node: $reason" "autoscale,cluster" 2>/dev/null
}

# Auto mode - continuously monitor and scale
auto() {
    local interval="${1:-30}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔄 AUTOSCALER DAEMON 🔄                            ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Check interval: ${interval}s"
    echo "Cooldown: ${COOLDOWN_SECONDS}s"
    echo "Thresholds: Load ${SCALE_DOWN_LOAD}-${SCALE_UP_LOAD}, Mem ${SCALE_DOWN_MEM}-${SCALE_UP_MEM}%"
    echo
    echo "Press Ctrl+C to stop"
    echo

    while true; do
        local timestamp=$(date '+%H:%M:%S')
        echo "[$timestamp] Checking cluster..."

        # Get metrics
        local total_load=0
        local total_mem=0
        local count=0

        for node in $(jq -r '.active_nodes[]' "$STATE_FILE" 2>/dev/null); do
            local metrics=$(get_metrics "$node")
            local status=$(echo "$metrics" | cut -d: -f1)

            if [ "$status" = "online" ]; then
                local load=$(echo "$metrics" | cut -d: -f2)
                local mem=$(echo "$metrics" | cut -d: -f3)
                total_load=$(echo "$total_load + $load" | bc)
                total_mem=$((total_mem + mem))
                ((count++))
            fi
        done

        if [ "$count" -gt 0 ]; then
            local avg_load=$(echo "scale=2; $total_load / $count" | bc)
            local avg_mem=$((total_mem / count))

            echo "  Avg load: $avg_load, Avg mem: ${avg_mem}%"

            # Check cooldown
            local last_action=$(jq -r '.last_scale_action // empty' "$STATE_FILE")
            local can_scale=true

            if [ -n "$last_action" ]; then
                local last_ts=$(date -d "$last_action" +%s 2>/dev/null || echo 0)
                local now_ts=$(date +%s)
                local diff=$((now_ts - last_ts))

                if [ "$diff" -lt "$COOLDOWN_SECONDS" ]; then
                    can_scale=false
                    echo "  Cooldown: $((COOLDOWN_SECONDS - diff))s remaining"
                fi
            fi

            # Make scaling decision
            if [ "$can_scale" = "true" ]; then
                if [ "$(echo "$avg_load > $SCALE_UP_LOAD" | bc -l)" = "1" ]; then
                    echo -e "  ${YELLOW}Scaling UP (load: $avg_load)${RESET}"
                    scale_up "high_load" >/dev/null
                elif [ "$avg_mem" -gt "$SCALE_UP_MEM" ]; then
                    echo -e "  ${YELLOW}Scaling UP (mem: ${avg_mem}%)${RESET}"
                    scale_up "high_memory" >/dev/null
                elif [ "$(echo "$avg_load < $SCALE_DOWN_LOAD" | bc -l)" = "1" ] && [ "$avg_mem" -lt "$SCALE_DOWN_MEM" ]; then
                    echo -e "  ${BLUE}Scaling DOWN (low util)${RESET}"
                    scale_down "low_utilization" >/dev/null
                else
                    echo -e "  ${GREEN}Stable${RESET}"
                fi
            fi
        else
            echo -e "  ${RED}No active nodes responding!${RESET}"
        fi

        sleep "$interval"
    done
}

# Show current state
status() {
    echo -e "${PINK}=== AUTOSCALER STATUS ===${RESET}"
    echo

    local active=$(jq -r '.active_nodes | join(", ")' "$STATE_FILE" 2>/dev/null)
    local standby=$(jq -r '.standby_nodes | join(", ")' "$STATE_FILE" 2>/dev/null)
    local last=$(jq -r '.last_scale_action // "never"' "$STATE_FILE" 2>/dev/null)
    local history_count=$(jq '.scale_history | length' "$STATE_FILE" 2>/dev/null)

    echo "Active nodes: $active"
    echo "Standby nodes: $standby"
    echo "Last scale action: $last"
    echo "Total scale events: $history_count"
    echo

    echo "Recent history:"
    jq -r '.scale_history[-5:][] | "  \(.time): \(.action) \(.node) (\(.reason))"' "$STATE_FILE" 2>/dev/null
}

# Manual set nodes
set_active() {
    local nodes="$*"

    jq --argjson active "$(echo "$nodes" | jq -R 'split(" ")')" \
       '.active_nodes = $active' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo -e "${GREEN}Set active nodes: $nodes${RESET}"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Cluster Autoscaler${RESET}"
    echo
    echo "Dynamically scale LLM workloads across Pi nodes"
    echo
    echo "Commands:"
    echo "  analyze             Analyze cluster and recommend action"
    echo "  up [reason]         Scale up (activate standby node)"
    echo "  down [reason]       Scale down (deactivate node)"
    echo "  auto [interval]     Run autoscaler daemon (default 30s)"
    echo "  status              Show autoscaler status"
    echo "  set <node1> [...]   Manually set active nodes"
    echo
    echo "Thresholds:"
    echo "  Scale up:   Load > $SCALE_UP_LOAD or Mem > ${SCALE_UP_MEM}%"
    echo "  Scale down: Load < $SCALE_DOWN_LOAD and Mem < ${SCALE_DOWN_MEM}%"
    echo "  Cooldown:   ${COOLDOWN_SECONDS}s between actions"
}

# Ensure initialized
[ -d "$CONFIG_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    analyze|check)
        analyze
        ;;
    up|scale-up)
        scale_up "$2"
        ;;
    down|scale-down)
        scale_down "$2"
        ;;
    auto|daemon)
        auto "$2"
        ;;
    status)
        status
        ;;
    set)
        shift
        set_active "$@"
        ;;
    *)
        help
        ;;
esac
