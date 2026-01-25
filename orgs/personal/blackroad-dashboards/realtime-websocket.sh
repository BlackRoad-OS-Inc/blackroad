#!/bin/bash

# BlackRoad OS - Real-Time WebSocket Dashboard
# Live streaming data updates

source ~/blackroad-dashboards/themes.sh
load_theme

WEBSOCKET_PORT=8765
DATA_FILE=~/blackroad-dashboards/.realtime_data
CONNECTIONS_FILE=~/blackroad-dashboards/.ws_connections

touch "$DATA_FILE" "$CONNECTIONS_FILE"

# Simulate WebSocket data stream
generate_realtime_data() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu=$((40 + RANDOM % 30))
    local memory=$((50 + RANDOM % 20))
    local requests=$((1000 + RANDOM % 5000))
    local latency=$((20 + RANDOM % 50))
    local errors=$((RANDOM % 10))

    cat > "$DATA_FILE" <<EOF
{
  "timestamp": "$timestamp",
  "metrics": {
    "cpu": $cpu,
    "memory": $memory,
    "requests_per_sec": $requests,
    "avg_latency_ms": $latency,
    "errors_per_min": $errors
  },
  "status": "online",
  "connections": $(wc -l < "$CONNECTIONS_FILE" 2>/dev/null || echo 0)
}
EOF
}

# Show real-time streaming dashboard
show_realtime_dashboard() {
    local iteration=0

    while true; do
        clear
        echo ""
        echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${PURPLE}📡${RESET} ${BOLD}REAL-TIME WEBSOCKET DASHBOARD${RESET}                                    ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""

        # Generate new data
        generate_realtime_data

        # Parse current data
        local timestamp=$(grep '"timestamp"' "$DATA_FILE" | cut -d'"' -f4)
        local cpu=$(grep '"cpu"' "$DATA_FILE" | grep -o '[0-9]\+' | head -1)
        local memory=$(grep '"memory"' "$DATA_FILE" | grep -o '[0-9]\+' | head -1)
        local requests=$(grep '"requests_per_sec"' "$DATA_FILE" | grep -o '[0-9]\+' | head -1)
        local latency=$(grep '"avg_latency_ms"' "$DATA_FILE" | grep -o '[0-9]\+' | head -1)
        local errors=$(grep '"errors_per_min"' "$DATA_FILE" | grep -o '[0-9]\+' | tail -1)
        local connections=$(grep '"connections"' "$DATA_FILE" | grep -o '[0-9]\+' | tail -1)

        # WebSocket status
        echo -e "${TEXT_MUTED}╭─ WEBSOCKET SERVER ────────────────────────────────────────────────────╮${RESET}"
        echo ""
        echo -e "  ${BOLD}${TEXT_PRIMARY}Server Status:${RESET}        ${GREEN}${BOLD}● STREAMING${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Port:${RESET}                 ${CYAN}ws://localhost:${WEBSOCKET_PORT}${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Active Connections:${RESET}   ${BOLD}${PURPLE}${connections}${RESET} ${TEXT_MUTED}clients${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Update Rate:${RESET}          ${ORANGE}500ms${RESET} ${TEXT_MUTED}(2 Hz)${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Last Update:${RESET}          ${TEXT_MUTED}${timestamp}${RESET}"
        echo ""

        # Live metrics
        echo -e "${TEXT_MUTED}╭─ LIVE METRICS (streaming) ────────────────────────────────────────────╮${RESET}"
        echo ""

        # CPU with animated indicator
        local cpu_bar=""
        local cpu_filled=$((cpu / 2))
        for ((i=0; i<50; i++)); do
            if [ "$i" -lt "$cpu_filled" ]; then
                if [ "$cpu" -ge 70 ]; then
                    cpu_bar="${cpu_bar}${RED}█${RESET}"
                elif [ "$cpu" -ge 50 ]; then
                    cpu_bar="${cpu_bar}${ORANGE}█${RESET}"
                else
                    cpu_bar="${cpu_bar}${GREEN}█${RESET}"
                fi
            else
                cpu_bar="${cpu_bar}${TEXT_MUTED}░${RESET}"
            fi
        done

        # Streaming indicator
        local stream_chars="◐◓◑◒"
        local stream_idx=$((iteration % 4))
        local stream_icon="${CYAN}${stream_chars:$stream_idx:1}${RESET}"

        echo -e "  ${stream_icon} ${ORANGE}CPU${RESET}           [$cpu_bar] ${BOLD}${cpu}%${RESET}"

        # Memory
        local mem_bar=""
        local mem_filled=$((memory / 2))
        for ((i=0; i<50; i++)); do
            [ "$i" -lt "$mem_filled" ] && mem_bar="${mem_bar}${PINK}█${RESET}" || mem_bar="${mem_bar}${TEXT_MUTED}░${RESET}"
        done
        echo -e "  ${stream_icon} ${PINK}Memory${RESET}        [$mem_bar] ${BOLD}${memory}%${RESET}"

        # Requests
        echo -e "  ${stream_icon} ${PURPLE}Requests/sec${RESET}  ${BOLD}${requests}${RESET} ${TEXT_MUTED}req/s${RESET}"

        # Latency
        local latency_color
        if [ "$latency" -ge 50 ]; then
            latency_color="${RED}"
        elif [ "$latency" -ge 30 ]; then
            latency_color="${ORANGE}"
        else
            latency_color="${GREEN}"
        fi
        echo -e "  ${stream_icon} ${CYAN}Avg Latency${RESET}   ${BOLD}${latency_color}${latency}ms${RESET}"

        # Errors
        local error_color
        [ "$errors" -gt 5 ] && error_color="${RED}" || error_color="${GREEN}"
        echo -e "  ${stream_icon} ${YELLOW}Errors/min${RESET}    ${BOLD}${error_color}${errors}${RESET}"
        echo ""

        # Live event stream
        echo -e "${TEXT_MUTED}╭─ EVENT STREAM ────────────────────────────────────────────────────────╮${RESET}"
        echo ""

        # Generate random events
        local events=(
            "New connection from 192.168.4.38"
            "Metrics updated: CPU=${cpu}% Memory=${memory}%"
            "API request processed in ${latency}ms"
            "Database query completed"
            "Cache hit ratio: 94.2%"
            "WebSocket ping/pong OK"
            "Health check passed"
            "Deployment event detected"
        )

        # Show last 5 events
        for ((i=0; i<5; i++)); do
            local event_idx=$((( iteration + i ) % ${#events[@]}))
            local event="${events[$event_idx]}"
            local event_time=$(date -d "-${i} seconds" '+%H:%M:%S' 2>/dev/null || date -v "-${i}S" '+%H:%M:%S' 2>/dev/null || date '+%H:%M:%S')

            echo -e "  ${TEXT_MUTED}[$event_time]${RESET} ${GREEN}●${RESET} $event"
        done
        echo ""

        # Connected clients
        echo -e "${TEXT_MUTED}╭─ CONNECTED CLIENTS ───────────────────────────────────────────────────╮${RESET}"
        echo ""

        if [ "$connections" -gt 0 ]; then
            for ((i=1; i<=connections && i<=5; i++)); do
                local client_ip="192.168.4.$((20 + i))"
                local duration=$((RANDOM % 300 + 10))
                local msgs=$((RANDOM % 1000 + 100))

                echo -e "  ${GREEN}●${RESET} ${BOLD}Client #${i}${RESET}"
                echo -e "     ${TEXT_SECONDARY}IP:${RESET} ${CYAN}${client_ip}${RESET}  ${TEXT_SECONDARY}Duration:${RESET} ${duration}s  ${TEXT_SECONDARY}Messages:${RESET} ${msgs}"
            done

            [ "$connections" -gt 5 ] && echo -e "  ${TEXT_MUTED}+ $((connections - 5)) more clients...${RESET}"
        else
            echo -e "  ${TEXT_MUTED}No clients connected${RESET}"
        fi
        echo ""

        # Data throughput
        echo -e "${TEXT_MUTED}╭─ DATA THROUGHPUT ─────────────────────────────────────────────────────╮${RESET}"
        echo ""
        local throughput=$((connections * 2))  # 2 KB/s per client
        local total_msgs=$((iteration * connections))

        echo -e "  ${BOLD}${TEXT_PRIMARY}Messages Sent:${RESET}        ${BOLD}${ORANGE}${total_msgs}${RESET} ${TEXT_MUTED}total${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Data Rate:${RESET}            ${BOLD}${CYAN}${throughput} KB/s${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Compression:${RESET}          ${BOLD}${GREEN}gzip${RESET} ${TEXT_MUTED}(~60% reduction)${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Protocol:${RESET}             ${PURPLE}WebSocket (RFC 6455)${RESET}"
        echo ""

        # Performance stats
        echo -e "${TEXT_MUTED}╭─ PERFORMANCE ─────────────────────────────────────────────────────────╮${RESET}"
        echo ""
        local cpu_usage=$((5 + connections * 2))
        local mem_usage=$((10 + connections * 5))

        echo -e "  ${BOLD}${TEXT_PRIMARY}Server CPU:${RESET}           ${BOLD}${cpu_usage}%${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Server Memory:${RESET}        ${BOLD}${mem_usage} MB${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Msg Latency:${RESET}      ${BOLD}${GREEN}< 5ms${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Dropped Messages:${RESET}     ${BOLD}${GREEN}0${RESET}"
        echo ""

        echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${TEXT_SECONDARY}[+]${RESET} Add client  ${TEXT_SECONDARY}[-]${RESET} Remove client  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[Q]${RESET} Quit"
        echo -e "  ${TEXT_MUTED}${stream_icon} Live streaming... (updates every 500ms)${RESET}"
        echo ""

        # Check for input
        read -n1 -t 0.5 key

        case "$key" in
            '+')
                echo "client-$((connections + 1))" >> "$CONNECTIONS_FILE"
                ;;
            '-')
                [ "$connections" -gt 0 ] && sed -i '' '$d' "$CONNECTIONS_FILE" 2>/dev/null
                ;;
            'r'|'R')
                iteration=0
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Stopping WebSocket server...${RESET}\n"
                exit 0
                ;;
        esac

        ((iteration++))
    done
}

# Main
main() {
    # Initialize with 3 clients
    echo "client-1" > "$CONNECTIONS_FILE"
    echo "client-2" >> "$CONNECTIONS_FILE"
    echo "client-3" >> "$CONNECTIONS_FILE"

    show_realtime_dashboard
}

# Run
main
