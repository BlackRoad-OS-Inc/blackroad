#!/usr/bin/env bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# BlackRoad Live Infrastructure Dashboard
# Real-time monitoring of entire fleet using terminal GUI
# ============================================================================

set -e

# Color functions
c_pink()   { printf '\033[38;5;205m'; }
c_blue()   { printf '\033[38;5;75m'; }
c_green()  { printf '\033[38;5;82m'; }
c_yellow() { printf '\033[38;5;226m'; }
c_red()    { printf '\033[38;5;196m'; }
c_purple() { printf '\033[38;5;141m'; }
c_orange() { printf '\033[38;5;208m'; }
c_gray()   { printf '\033[38;5;240m'; }
c_reset()  { printf '\033[0m'; }
c_clear()  { printf '\033[2J\033[H'; }
c_bold()   { printf '\033[1m'; }

# Fleet configuration
FLEET_DEVICES=(
    "cecilia:192.168.4.36:Hailo-8 AI Core"
    "alice:192.168.4.38:Pi 4 Worker"
    "aria:192.168.4.40:Pi 5 Titan"
    "octavia:192.168.4.38:Jetson Quantum"
    "lucidia:192.168.4.42:Pi 5 Pironman"
)

# ==================
# DATA COLLECTORS
# ==================

get_device_status() {
    local host="$1"
    local ip="$2"
    
    # Try ping first (fast)
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        echo "online"
    else
        echo "offline"
    fi
}

get_cpu_usage() {
    local host="$1"
    
    # Local
    if [[ "$host" == "localhost" || "$host" == "$(hostname)" ]]; then
        top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%'
    else
        # Remote (if SSH available)
        ssh -o ConnectTimeout=2 "$host" "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | tr -d '%'" 2>/dev/null || echo "N/A"
    fi
}

get_memory_usage() {
    local host="$1"
    
    if [[ "$host" == "localhost" || "$host" == "$(hostname)" ]]; then
        vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages free:\s+(\d+)/ and printf("%.0f", $1 * $size / 1073741824); /Pages active:\s+(\d+)/ and printf("%.0f", $1 * $size / 1073741824)'
    else
        ssh -o ConnectTimeout=2 "$host" "free -m | awk '/Mem:/ {printf \"%.0f\", \$3/1024}'" 2>/dev/null || echo "N/A"
    fi
}

get_uptime() {
    local host="$1"
    
    if [[ "$host" == "localhost" || "$host" == "$(hostname)" ]]; then
        uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}' | xargs
    else
        ssh -o ConnectTimeout=2 "$host" "uptime | awk -F'up ' '{print \$2}' | awk -F',' '{print \$1}'" 2>/dev/null | xargs || echo "N/A"
    fi
}

get_quantum_status() {
    # Check if quantum stack is available
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import qiskit" 2>/dev/null; then
            echo "ready"
        else
            echo "unavailable"
        fi
    else
        echo "unavailable"
    fi
}

# ==================
# DISPLAY COMPONENTS
# ==================

draw_header() {
    c_clear
    c_pink; c_bold
    printf "╔════════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║                                                                                ║\n"
    printf "║                   BLACKROAD OS - LIVE INFRASTRUCTURE DASHBOARD                 ║\n"
    printf "║                                                                                ║\n"
    printf "╚════════════════════════════════════════════════════════════════════════════════╝\n"
    c_reset
    printf "\n"
}

draw_device_status() {
    local name="$1"
    local ip="$2"
    local desc="$3"
    local status="$4"
    
    if [[ "$status" == "online" ]]; then
        c_green; printf "●"; c_reset
    else
        c_red; printf "●"; c_reset
    fi
    
    printf " "
    c_blue; c_bold; printf "%-12s" "$name"; c_reset
    printf " "
    c_gray; printf "%-15s" "$ip"; c_reset
    printf " "
    printf "%-25s" "$desc"
    printf "\n"
}

draw_metrics() {
    local cpu="$1"
    local mem="$2"
    local uptime="$3"
    
    printf "    "
    c_purple; printf "CPU: "; c_reset
    
    if [[ "$cpu" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        if (( $(echo "$cpu > 80" | bc -l) )); then
            c_red; printf "%5s%%" "$cpu"; c_reset
        elif (( $(echo "$cpu > 50" | bc -l) )); then
            c_yellow; printf "%5s%%" "$cpu"; c_reset
        else
            c_green; printf "%5s%%" "$cpu"; c_reset
        fi
    else
        c_gray; printf "%5s" "$cpu"; c_reset
    fi
    
    printf "  "
    c_purple; printf "MEM: "; c_reset
    c_blue; printf "%4s GB" "$mem"; c_reset
    
    printf "  "
    c_purple; printf "UPTIME: "; c_reset
    c_gray; printf "%s" "$uptime"; c_reset
    
    printf "\n"
}

draw_quantum_status() {
    local status="$1"
    
    printf "\n"
    c_orange; c_bold
    printf "╔════════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║ QUANTUM COMPUTING STATUS                                                       ║\n"
    printf "╚════════════════════════════════════════════════════════════════════════════════╝\n"
    c_reset
    
    printf "\n"
    printf "  "
    
    if [[ "$status" == "ready" ]]; then
        c_green; printf "● OPERATIONAL"; c_reset
        printf " - Qiskit available, ready for quantum circuits\n"
    else
        c_gray; printf "○ UNAVAILABLE"; c_reset
        printf " - Quantum frameworks not installed\n"
    fi
    
    printf "\n"
}

draw_summary() {
    local online="$1"
    local total="$2"
    
    printf "\n"
    c_blue; c_bold
    printf "╔════════════════════════════════════════════════════════════════════════════════╗\n"
    printf "║ FLEET SUMMARY                                                                  ║\n"
    printf "╚════════════════════════════════════════════════════════════════════════════════╝\n"
    c_reset
    
    printf "\n"
    printf "  "
    c_purple; printf "Total Devices: "; c_reset
    printf "%d\n" "$total"
    
    printf "  "
    c_purple; printf "Online: "; c_reset
    c_green; printf "%d"; c_reset
    
    printf "  "
    c_purple; printf "Offline: "; c_reset
    c_red; printf "%d"; c_reset
    
    local uptime_pct=$((online * 100 / total))
    printf "  "
    c_purple; printf "Uptime: "; c_reset
    
    if (( uptime_pct >= 90 )); then
        c_green; printf "%d%%" "$uptime_pct"; c_reset
    elif (( uptime_pct >= 70 )); then
        c_yellow; printf "%d%%" "$uptime_pct"; c_reset
    else
        c_red; printf "%d%%" "$uptime_pct"; c_reset
    fi
    
    printf "\n\n"
}

draw_footer() {
    local timestamp="$1"
    
    printf "\n"
    c_gray
    printf "═══════════════════════════════════════════════════════════════════════════════\n"
    printf "Last updated: %s  |  Press Ctrl+C to exit  |  Refresh: 5s\n" "$timestamp"
    c_reset
}

# ==================
# MAIN DASHBOARD
# ==================

run_dashboard() {
    local refresh_interval="${1:-5}"
    
    while true; do
        draw_header
        
        # Fleet status section
        c_blue; c_bold
        printf "╔════════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║ DEVICE FLEET                                                                   ║\n"
        printf "╚════════════════════════════════════════════════════════════════════════════════╝\n"
        c_reset
        printf "\n"
        
        local online_count=0
        local total_count=${#FLEET_DEVICES[@]}
        
        for device in "${FLEET_DEVICES[@]}"; do
            IFS=':' read -r name ip desc <<< "$device"
            
            # Get status
            local status=$(get_device_status "$name" "$ip")
            
            # Draw device line
            draw_device_status "$name" "$ip" "$desc" "$status"
            
            # Get metrics if online
            if [[ "$status" == "online" ]]; then
                ((online_count++))
                
                local cpu=$(get_cpu_usage "$name")
                local mem=$(get_memory_usage "$name")
                local uptime=$(get_uptime "$name")
                
                draw_metrics "$cpu" "$mem" "$uptime"
            else
                c_gray
                printf "    Offline - no metrics available\n"
                c_reset
            fi
            
            printf "\n"
        done
        
        # Quantum status
        local quantum_status=$(get_quantum_status)
        draw_quantum_status "$quantum_status"
        
        # Fleet summary
        draw_summary "$online_count" "$total_count"
        
        # Footer
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        draw_footer "$timestamp"
        
        # Wait before refresh
        sleep "$refresh_interval"
    done
}

# ==================
# CLI INTERFACE
# ==================

show_help() {
    cat <<'HELP'
BlackRoad Live Infrastructure Dashboard

USAGE:
  blackroad-live-dashboard.sh [OPTIONS]

OPTIONS:
  --interval N    Refresh interval in seconds (default: 5)
  --once          Run once and exit (no loop)
  --help          Show this help

EXAMPLES:
  blackroad-live-dashboard.sh                    # Live dashboard (5s refresh)
  blackroad-live-dashboard.sh --interval 10      # 10 second refresh
  blackroad-live-dashboard.sh --once             # Single snapshot

MONITORED DEVICES:
  • cecilia  - Hailo-8 AI Core
  • alice    - Pi 4 Worker
  • aria     - Pi 5 Titan  
  • octavia  - Jetson Quantum
  • lucidia  - Pi 5 Pironman

METRICS:
  • Device online/offline status
  • CPU usage (%)
  • Memory usage (GB)
  • System uptime
  • Quantum computing availability

Press Ctrl+C to exit live mode.
HELP
}

# ==================
# MAIN
# ==================

main() {
    local mode="live"
    local interval=5
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interval)
                interval="$2"
                shift 2
                ;;
            --once)
                mode="once"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Run dashboard
    if [[ "$mode" == "once" ]]; then
        # Single run
        draw_header
        
        c_blue; c_bold
        printf "╔════════════════════════════════════════════════════════════════════════════════╗\n"
        printf "║ DEVICE FLEET                                                                   ║\n"
        printf "╚════════════════════════════════════════════════════════════════════════════════╝\n"
        c_reset
        printf "\n"
        
        local online_count=0
        local total_count=${#FLEET_DEVICES[@]}
        
        for device in "${FLEET_DEVICES[@]}"; do
            IFS=':' read -r name ip desc <<< "$device"
            local status=$(get_device_status "$name" "$ip")
            draw_device_status "$name" "$ip" "$desc" "$status"
            
            if [[ "$status" == "online" ]]; then
                ((online_count++))
                echo "    (Metrics available via live mode)"
            fi
            printf "\n"
        done
        
        local quantum_status=$(get_quantum_status)
        draw_quantum_status "$quantum_status"
        
        draw_summary "$online_count" "$total_count"
        
        c_gray
        printf "Run without --once for live monitoring\n"
        c_reset
    else
        # Live monitoring
        run_dashboard "$interval"
    fi
}

main "$@"
