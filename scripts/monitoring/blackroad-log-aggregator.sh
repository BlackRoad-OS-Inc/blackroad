#!/bin/bash
# BlackRoad Log Aggregator
# Centralized log collection and analysis for the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

LOG_DIR="$HOME/.blackroad/logs"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Log sources on each node
declare -A LOG_SOURCES=(
    ["system"]="/var/log/syslog"
    ["docker"]="/var/log/docker.log"
    ["ollama"]="/var/log/ollama.log"
    ["auth"]="/var/log/auth.log"
    ["nginx"]="/var/log/nginx/access.log"
)

# Initialize
init() {
    mkdir -p "$LOG_DIR"/{collected,analyzed,alerts}
    echo -e "${GREEN}Log aggregator initialized${RESET}"
}

# Collect logs from a node
collect_node() {
    local node="$1"
    local source="${2:-system}"
    local lines="${3:-100}"

    if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
        echo "offline"
        return 1
    fi

    local log_path="${LOG_SOURCES[$source]}"
    [ -z "$log_path" ] && log_path="$source"

    ssh "$node" "sudo tail -n $lines $log_path 2>/dev/null" | while read -r line; do
        echo "$(date -Iseconds) [$node] $line"
    done
}

# Collect logs from all nodes
collect_all() {
    local source="${1:-system}"
    local lines="${2:-50}"
    local output_file="$LOG_DIR/collected/cluster_${source}_$(date +%Y%m%d_%H%M%S).log"

    echo -e "${PINK}=== COLLECTING LOGS ===${RESET}"
    echo "Source: $source"
    echo "Lines per node: $lines"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "
        local logs=$(collect_node "$node" "$source" "$lines")
        if [ "$logs" = "offline" ]; then
            echo -e "${YELLOW}offline${RESET}"
        else
            echo "$logs" >> "$output_file"
            local count=$(echo "$logs" | wc -l)
            echo -e "${GREEN}$count lines${RESET}"
        fi
    done

    echo
    echo -e "${GREEN}Saved: $output_file${RESET}"
}

# Stream logs in real-time
stream() {
    local source="${1:-system}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           📋 LIVE LOG STREAM - $source                       ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Streaming from ${#ALL_NODES[@]} nodes. Press Ctrl+C to stop."
    echo

    local log_path="${LOG_SOURCES[$source]}"
    [ -z "$log_path" ] && log_path="$source"

    # Stream from all nodes in parallel
    for node in "${ALL_NODES[@]}"; do
        (
            ssh "$node" "sudo tail -f $log_path 2>/dev/null" | while read -r line; do
                local color
                case $node in
                    lucidia) color=$CYAN ;;
                    cecilia) color=$GREEN ;;
                    octavia) color=$BLUE ;;
                    aria) color=$YELLOW ;;
                    alice) color=$PINK ;;
                    *) color=$RESET ;;
                esac
                echo -e "${color}[$node]${RESET} $line"
            done
        ) &
    done

    wait
}

# Search across all logs
search() {
    local pattern="$1"
    local source="${2:-system}"
    local context="${3:-0}"

    echo -e "${PINK}=== LOG SEARCH ===${RESET}"
    echo "Pattern: $pattern"
    echo "Source: $source"
    echo

    local log_path="${LOG_SOURCES[$source]}"
    [ -z "$log_path" ] && log_path="$source"

    for node in "${ALL_NODES[@]}"; do
        echo -e "${BLUE}--- $node ---${RESET}"

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        local matches=$(ssh "$node" "sudo grep -C $context -i '$pattern' $log_path 2>/dev/null" | head -20)
        if [ -n "$matches" ]; then
            echo "$matches"
        else
            echo "No matches"
        fi
        echo
    done
}

# Analyze logs for errors
analyze_errors() {
    local hours="${1:-1}"

    echo -e "${PINK}=== ERROR ANALYSIS ===${RESET}"
    echo "Last $hours hour(s)"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -e "${BLUE}$node:${RESET}"

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "  ${YELLOW}offline${RESET}"
            continue
        fi

        # Count errors by type
        local errors=$(ssh "$node" "
            since=\$(date -d '-${hours} hours' '+%b %d %H:%M' 2>/dev/null || echo '')
            sudo grep -i 'error\\|fail\\|critical' /var/log/syslog 2>/dev/null | tail -50 | \
            awk '{for(i=1;i<=NF;i++) if(\$i ~ /error|fail|critical/i) count[\$i]++} END {for(k in count) print count[k], k}' | \
            sort -rn | head -5
        " 2>/dev/null)

        if [ -n "$errors" ]; then
            echo "$errors" | while read -r count word; do
                local color=$YELLOW
                [ "$count" -gt 10 ] && color=$RED
                echo -e "  ${color}$count${RESET} $word"
            done
        else
            echo -e "  ${GREEN}No errors${RESET}"
        fi
    done
}

# Generate log report
report() {
    local hours="${1:-24}"
    local report_file="$LOG_DIR/analyzed/report_$(date +%Y%m%d_%H%M%S).md"

    echo -e "${PINK}=== GENERATING REPORT ===${RESET}"
    echo "Period: Last $hours hours"
    echo

    cat > "$report_file" << EOF
# BlackRoad Cluster Log Report
Generated: $(date)
Period: Last $hours hours

## Node Status
EOF

    for node in "${ALL_NODES[@]}"; do
        echo -n "  Analyzing $node... "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo "### $node: OFFLINE" >> "$report_file"
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        local stats=$(ssh "$node" "
            errors=\$(sudo grep -ci 'error' /var/log/syslog 2>/dev/null || echo 0)
            warnings=\$(sudo grep -ci 'warning' /var/log/syslog 2>/dev/null || echo 0)
            docker_restarts=\$(docker events --since '${hours}h' --until 'now' 2>/dev/null | grep -c 'restart' || echo 0)
            echo \"\$errors \$warnings \$docker_restarts\"
        " 2>/dev/null)

        local errors=$(echo "$stats" | awk '{print $1}')
        local warnings=$(echo "$stats" | awk '{print $2}')
        local restarts=$(echo "$stats" | awk '{print $3}')

        cat >> "$report_file" << EOF

### $node
- Errors: $errors
- Warnings: $warnings
- Container restarts: $restarts
EOF

        echo -e "${GREEN}done${RESET}"
    done

    # Top errors section
    cat >> "$report_file" << EOF

## Top Errors Across Cluster
EOF

    for node in "${ALL_NODES[@]}"; do
        if ssh -o ConnectTimeout=2 "$node" "echo ok" >/dev/null 2>&1; then
            echo "### $node" >> "$report_file"
            ssh "$node" "sudo grep -i error /var/log/syslog 2>/dev/null | tail -5" >> "$report_file" 2>/dev/null
        fi
    done

    echo
    echo -e "${GREEN}Report saved: $report_file${RESET}"
}

# Alert on log patterns
alert() {
    local pattern="$1"
    local action="${2:-echo}"

    echo -e "${PINK}=== LOG ALERT MONITOR ===${RESET}"
    echo "Pattern: $pattern"
    echo "Action: $action"
    echo
    echo "Monitoring... Press Ctrl+C to stop"

    for node in "${ALL_NODES[@]}"; do
        (
            ssh "$node" "sudo tail -f /var/log/syslog 2>/dev/null" | while read -r line; do
                if echo "$line" | grep -qi "$pattern"; then
                    local alert_msg="[ALERT] $node: $line"
                    echo -e "${RED}$alert_msg${RESET}"

                    # Save alert
                    echo "$(date -Iseconds) $alert_msg" >> "$LOG_DIR/alerts/alerts.log"

                    # Execute action
                    case "$action" in
                        echo) ;;
                        notify)
                            # Could integrate with notification system
                            ;;
                        webhook:*)
                            local url="${action#webhook:}"
                            curl -s -X POST "$url" -d "{\"alert\":\"$alert_msg\"}" >/dev/null
                            ;;
                    esac
                fi
            done
        ) &
    done

    wait
}

# Tail specific node log
tail_node() {
    local node="$1"
    local source="${2:-system}"
    local lines="${3:-50}"

    local log_path="${LOG_SOURCES[$source]}"
    [ -z "$log_path" ] && log_path="$source"

    echo -e "${PINK}=== $node - $source ===${RESET}"
    echo

    ssh "$node" "sudo tail -n $lines $log_path" 2>/dev/null
}

# Stats summary
stats() {
    echo -e "${PINK}=== LOG STATISTICS ===${RESET}"
    echo

    printf "%-12s %-10s %-10s %-10s %-10s\n" "NODE" "ERRORS" "WARNINGS" "SIZE" "STATUS"
    echo "────────────────────────────────────────────────────────────"

    for node in "${ALL_NODES[@]}"; do
        if ! ssh -o ConnectTimeout=2 "$node" "echo ok" >/dev/null 2>&1; then
            printf "%-12s ${YELLOW}%-10s${RESET}\n" "$node" "OFFLINE"
            continue
        fi

        local stats=$(ssh "$node" "
            errors=\$(sudo grep -ci 'error' /var/log/syslog 2>/dev/null || echo 0)
            warnings=\$(sudo grep -ci 'warning' /var/log/syslog 2>/dev/null || echo 0)
            size=\$(du -sh /var/log/syslog 2>/dev/null | cut -f1 || echo '?')
            echo \"\$errors \$warnings \$size\"
        " 2>/dev/null)

        local errors=$(echo "$stats" | awk '{print $1}')
        local warnings=$(echo "$stats" | awk '{print $2}')
        local size=$(echo "$stats" | awk '{print $3}')

        local status="${GREEN}OK${RESET}"
        [ "$errors" -gt 100 ] && status="${YELLOW}WARN${RESET}"
        [ "$errors" -gt 500 ] && status="${RED}HIGH${RESET}"

        printf "%-12s %-10s %-10s %-10s %-10b\n" "$node" "$errors" "$warnings" "$size" "$status"
    done
}

# Help
help() {
    echo -e "${PINK}BlackRoad Log Aggregator${RESET}"
    echo
    echo "Centralized log collection and analysis"
    echo
    echo "Commands:"
    echo "  collect [source] [lines]  Collect logs from all nodes"
    echo "  stream [source]           Stream logs in real-time"
    echo "  search <pattern> [src]    Search logs"
    echo "  errors [hours]            Analyze errors"
    echo "  report [hours]            Generate log report"
    echo "  alert <pattern> [action]  Monitor for pattern"
    echo "  tail <node> [source]      Tail specific node"
    echo "  stats                     Log statistics"
    echo
    echo "Log sources: ${!LOG_SOURCES[*]}"
    echo
    echo "Examples:"
    echo "  $0 stream system"
    echo "  $0 search 'error' docker"
    echo "  $0 alert 'out of memory'"
    echo "  $0 report 24"
}

# Ensure initialized
[ -d "$LOG_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    collect)
        collect_all "$2" "$3"
        ;;
    stream|follow)
        stream "$2"
        ;;
    search|grep)
        search "$2" "$3" "$4"
        ;;
    errors|analyze)
        analyze_errors "$2"
        ;;
    report)
        report "$2"
        ;;
    alert|monitor)
        alert "$2" "$3"
        ;;
    tail)
        tail_node "$2" "$3" "$4"
        ;;
    stats)
        stats
        ;;
    *)
        help
        ;;
esac
