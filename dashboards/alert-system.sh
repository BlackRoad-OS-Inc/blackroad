#!/bin/bash

# BlackRoad OS - Real-Time Alert System
# Monitor conditions and send notifications

source ~/blackroad-dashboards/themes.sh
load_theme

ALERTS_FILE=~/blackroad-dashboards/.alerts
ALERT_LOG=~/blackroad-dashboards/.alert_log
ALERT_RULES=~/blackroad-dashboards/.alert_rules

# Create files
touch "$ALERTS_FILE" "$ALERT_LOG" "$ALERT_RULES"

# Initialize default rules if empty
if [ ! -s "$ALERT_RULES" ]; then
    cat > "$ALERT_RULES" <<EOF
cpu_high:CPU > 80%:warning
memory_high:Memory > 90%:critical
api_error:API errors > 10/min:critical
container_down:Container stopped:critical
ssl_expiring:SSL cert < 7 days:warning
deployment_failed:Deploy failed:critical
EOF
fi

# Alert types
alert_sound() {
    local type=$1
    case "$type" in
        critical) echo -e "\a\a\a" ;;  # Triple beep
        warning)  echo -e "\a" ;;       # Single beep
        info)     : ;;                  # No sound
    esac
}

# Send alert
send_alert() {
    local title=$1
    local message=$2
    local type=$3  # critical, warning, info
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log alert
    echo "$timestamp|$type|$title|$message" >> "$ALERT_LOG"

    # Add to active alerts
    echo "$timestamp|$type|$title|$message" >> "$ALERTS_FILE"

    # Play sound
    alert_sound "$type"

    # Show notification (macOS)
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"$message\" with title \"BlackRoad Alert: $title\""
    fi

    # Terminal notification (fallback)
    case "$type" in
        critical)
            echo -e "${RED}${BOLD}🚨 CRITICAL ALERT: $title${RESET}"
            echo -e "${RED}   $message${RESET}"
            ;;
        warning)
            echo -e "${YELLOW}${BOLD}⚠️  WARNING: $title${RESET}"
            echo -e "${YELLOW}   $message${RESET}"
            ;;
        info)
            echo -e "${CYAN}${BOLD}ℹ️  INFO: $title${RESET}"
            echo -e "${CYAN}   $message${RESET}"
            ;;
    esac
}

# Clear alert
clear_alert() {
    local id=$1
    sed -i.bak "${id}d" "$ALERTS_FILE"
}

# Alert monitor (runs in background)
monitor_alerts() {
    while true; do
        # Check CPU
        local cpu=$(ps aux | awk '{sum+=$3} END {print int(sum)}')
        if [ $cpu -gt 80 ]; then
            send_alert "High CPU Usage" "CPU at ${cpu}% (threshold: 80%)" "warning"
        fi

        # Check memory
        local mem=$(ps aux | awk '{sum+=$4} END {print int(sum)}')
        if [ $mem -gt 90 ]; then
            send_alert "High Memory Usage" "Memory at ${mem}% (threshold: 90%)" "critical"
        fi

        # Check Docker containers (simulate)
        local containers_down=$(( RANDOM % 5 ))
        if [ $containers_down -gt 0 ]; then
            send_alert "Container Stopped" "$containers_down container(s) stopped unexpectedly" "critical"
        fi

        # Check API health (simulate)
        local api_errors=$(( RANDOM % 20 ))
        if [ $api_errors -gt 10 ]; then
            send_alert "API Errors" "$api_errors errors/min detected (threshold: 10)" "critical"
        fi

        # Check SSL certificates (simulate)
        local days_to_expire=$(( RANDOM % 30 ))
        if [ $days_to_expire -lt 7 ]; then
            send_alert "SSL Expiring Soon" "Certificate expires in $days_to_expire days" "warning"
        fi

        sleep 30  # Check every 30 seconds
    done
}

# Alert dashboard
show_alerts() {
    clear
    echo ""
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║${RESET}  ${YELLOW}🚨${RESET} ${BOLD}REAL-TIME ALERT SYSTEM${RESET}                                            ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Active alerts
    echo -e "${TEXT_MUTED}╭─ ACTIVE ALERTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local count=0
    if [ -f "$ALERTS_FILE" ] && [ -s "$ALERTS_FILE" ]; then
        while IFS='|' read -r timestamp type title message; do
            count=$((count + 1))
            local icon color
            case "$type" in
                critical) icon="🚨" color="$RED" ;;
                warning)  icon="⚠️"  color="$YELLOW" ;;
                info)     icon="ℹ️"  color="$CYAN" ;;
            esac

            echo -e "  ${color}${icon} ${BOLD}$title${RESET}"
            echo -e "     ${TEXT_SECONDARY}$message${RESET}"
            echo -e "     ${TEXT_MUTED}$timestamp • ${type}${RESET}"
            echo -e "     ${TEXT_MUTED}[Press $count to acknowledge]${RESET}"
            echo ""
        done < "$ALERTS_FILE"
    else
        echo -e "  ${GREEN}✓ No active alerts${RESET}"
        echo ""
    fi

    # Alert rules
    echo -e "${TEXT_MUTED}╭─ ALERT RULES ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local rule_num=1
    while IFS=':' read -r name condition severity; do
        local color
        case "$severity" in
            critical) color="$RED" ;;
            warning)  color="$YELLOW" ;;
            *)        color="$CYAN" ;;
        esac

        echo -e "  ${color}●${RESET} ${BOLD}$name${RESET}"
        echo -e "     ${TEXT_SECONDARY}Condition: $condition${RESET}"
        echo -e "     ${TEXT_SECONDARY}Severity: $severity${RESET}"
        echo ""
        rule_num=$((rule_num + 1))
    done < "$ALERT_RULES"

    # Recent alerts log
    echo -e "${TEXT_MUTED}╭─ RECENT ALERTS (Last 5) ──────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$ALERT_LOG" ] && [ -s "$ALERT_LOG" ]; then
        tail -5 "$ALERT_LOG" | while IFS='|' read -r timestamp type title message; do
            local icon
            case "$type" in
                critical) icon="${RED}🚨${RESET}" ;;
                warning)  icon="${YELLOW}⚠️${RESET}" ;;
                info)     icon="${CYAN}ℹ️${RESET}" ;;
            esac

            echo -e "  ${icon} ${TEXT_SECONDARY}[$timestamp]${RESET} ${TEXT_PRIMARY}$title${RESET}"
        done
    else
        echo -e "  ${TEXT_MUTED}No recent alerts${RESET}"
    fi
    echo ""

    # Statistics
    echo -e "${TEXT_MUTED}╭─ STATISTICS (Last 24h) ───────────────────────────────────────────────╮${RESET}"
    echo ""

    local total=$(wc -l < "$ALERT_LOG" 2>/dev/null || echo 0)
    local critical=$(grep -c "critical" "$ALERT_LOG" 2>/dev/null || echo 0)
    local warnings=$(grep -c "warning" "$ALERT_LOG" 2>/dev/null || echo 0)
    local info=$(grep -c "info" "$ALERT_LOG" 2>/dev/null || echo 0)

    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Alerts:${RESET}      ${BOLD}${ORANGE}$total${RESET}"
    echo -e "  ${RED}🚨${RESET} ${TEXT_PRIMARY}Critical:${RESET}         ${BOLD}${RED}$critical${RESET}"
    echo -e "  ${YELLOW}⚠️${RESET}  ${TEXT_PRIMARY}Warnings:${RESET}         ${BOLD}${YELLOW}$warnings${RESET}"
    echo -e "  ${CYAN}ℹ️${RESET}  ${TEXT_PRIMARY}Info:${RESET}             ${BOLD}${CYAN}$info${RESET}"
    echo ""

    # Actions
    echo -e "${RED}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-9]${RESET} Acknowledge  ${TEXT_SECONDARY}[A]${RESET} Acknowledge All  ${TEXT_SECONDARY}[M]${RESET} Monitor  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    # Start monitor in background
    monitor_alerts &
    MONITOR_PID=$!

    trap "kill $MONITOR_PID 2>/dev/null; exit" INT TERM

    while true; do
        show_alerts

        read -n1 -t 5 key

        case "$key" in
            [1-9])
                clear_alert "$key"
                send_alert "Alert Acknowledged" "Alert #$key has been acknowledged" "info"
                ;;
            'a'|'A')
                > "$ALERTS_FILE"
                send_alert "All Alerts Cleared" "All active alerts acknowledged" "info"
                ;;
            'm'|'M')
                echo -e "\n${CYAN}Monitor mode: Watching for alerts...${RESET}"
                sleep 2
                ;;
            'q'|'Q')
                kill $MONITOR_PID 2>/dev/null
                echo -e "\n${CYAN}Alert system stopped${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# If run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
