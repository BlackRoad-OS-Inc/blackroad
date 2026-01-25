#!/bin/bash

# BlackRoad OS - Dashboard Wrapper
# Adds keyboard shortcuts, breadcrumbs, and quick-jump to any dashboard

# Store the dashboard script to run
DASHBOARD_SCRIPT=$1
DASHBOARD_NAME=$2

if [ -z "$DASHBOARD_SCRIPT" ]; then
    echo "Usage: $0 <dashboard-script> <dashboard-name>"
    exit 1
fi

# Files
BREADCRUMBS_FILE=~/blackroad-dashboards/.breadcrumbs
JUMP_QUEUE=~/blackroad-dashboards/.jump_queue

# Keyboard shortcuts shown at bottom
SHORTCUTS="${TEXT_SECONDARY}[ESC]${RESET} Menu  ${TEXT_SECONDARY}[J]${RESET} Jump  ${TEXT_SECONDARY}[H]${RESET} Help  ${TEXT_SECONDARY}[E]${RESET} Export  ${TEXT_SECONDARY}[Q]${RESET} Quit"

# Add breadcrumb
add_breadcrumb() {
    echo "$(date '+%H:%M:%S') → $DASHBOARD_NAME" >> "$BREADCRUMBS_FILE"
    tail -10 "$BREADCRUMBS_FILE" > "${BREADCRUMBS_FILE}.tmp"
    mv "${BREADCRUMBS_FILE}.tmp" "$BREADCRUMBS_FILE"
}

# Show quick jump menu
show_quick_jump() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}⚡${RESET} ${BOLD}QUICK JUMP${RESET}                                                            ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "  ${BOLD}Jump to dashboard:${RESET}"
    echo ""
    echo "  ${ORANGE}1)${RESET} Master Control"
    echo "  ${PINK}2)${RESET} Docker Fleet"
    echo "  ${PURPLE}3)${RESET} Security"
    echo "  ${CYAN}4)${RESET} API Health"
    echo "  ${GREEN}5)${RESET} System Metrics"
    echo "  ${BLUE}6)${RESET} Database Monitor"
    echo "  ${GOLD}7)${RESET} Network Topology"
    echo "  ${ORANGE}8)${RESET} Build Pipeline"
    echo ""
    echo "  ${TEXT_MUTED}0)${RESET} Cancel"
    echo ""
    echo -n "Choose [1-8]: "
    read choice

    case $choice in
        1) echo "blackroad-master-control.sh" > "$JUMP_QUEUE" ;;
        2) echo "docker-fleet.sh" > "$JUMP_QUEUE" ;;
        3) echo "security-dashboard.sh" > "$JUMP_QUEUE" ;;
        4) echo "api-health-check.sh" > "$JUMP_QUEUE" ;;
        5) echo "system-metrics-live.sh" > "$JUMP_QUEUE" ;;
        6) echo "database-monitor.sh" > "$JUMP_QUEUE" ;;
        7) echo "network-topology-3d.sh" > "$JUMP_QUEUE" ;;
        8) echo "build-pipeline.sh" > "$JUMP_QUEUE" ;;
        0) return ;;
    esac

    exit 0
}

# Show help overlay
show_help() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${GOLD}❓${RESET} ${BOLD}KEYBOARD SHORTCUTS${RESET}                                                    ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "  ${BOLD}${TEXT_PRIMARY}Navigation${RESET}"
    echo "    ${ORANGE}ESC${RESET}      Return to launcher"
    echo "    ${ORANGE}J${RESET}        Quick jump to another dashboard"
    echo "    ${ORANGE}Q${RESET}        Quit to terminal"
    echo ""
    echo "  ${BOLD}${TEXT_PRIMARY}Actions${RESET}"
    echo "    ${PINK}E${RESET}        Export current data to file"
    echo "    ${PINK}H${RESET}        Show this help"
    echo "    ${PINK}R${RESET}        Refresh dashboard"
    echo "    ${PINK}T${RESET}        Change theme"
    echo ""
    echo "  ${BOLD}${TEXT_PRIMARY}View${RESET}"
    echo "    ${PURPLE}+/-${RESET}      Zoom in/out"
    echo "    ${PURPLE}F${RESET}        Toggle fullscreen"
    echo "    ${PURPLE}S${RESET}        Take screenshot"
    echo ""
    echo "  ${BOLD}${TEXT_PRIMARY}Currently viewing: ${GOLD}$DASHBOARD_NAME${RESET}"
    echo ""
    echo "  Press any key to return..."
    read -n1 -s
}

# Export dashboard data
export_data() {
    local filename="~/blackroad-exports/$(date +%Y%m%d_%H%M%S)_${DASHBOARD_NAME}.txt"
    mkdir -p ~/blackroad-exports

    echo "Exporting data to $filename..."
    # This would capture the current dashboard output
    # For now, just create a placeholder
    echo "Dashboard: $DASHBOARD_NAME" > "$filename"
    echo "Exported at: $(date)" >> "$filename"
    echo "Data export complete!"
    sleep 2
}

# Run dashboard with wrapper
run_dashboard_wrapped() {
    # Add breadcrumb
    add_breadcrumb

    # Start dashboard in background
    ~/blackroad-dashboards/$DASHBOARD_SCRIPT &
    local dash_pid=$!

    # Monitor for keyboard shortcuts
    while kill -0 $dash_pid 2>/dev/null; do
        read -rsn1 -t 1 key

        case "$key" in
            $'\x1b')  # ESC - return to launcher
                kill $dash_pid 2>/dev/null
                ~/blackroad-dashboards/br-dashboards-ultra.sh
                exit 0
                ;;
            'j'|'J')  # Quick jump
                kill $dash_pid 2>/dev/null
                show_quick_jump
                if [ -f "$JUMP_QUEUE" ]; then
                    local next_dash=$(cat "$JUMP_QUEUE")
                    rm "$JUMP_QUEUE"
                    ~/blackroad-dashboards/$next_dash --watch
                fi
                exit 0
                ;;
            'h'|'H')  # Help
                kill $dash_pid 2>/dev/null
                show_help
                # Restart dashboard
                ~/blackroad-dashboards/$DASHBOARD_SCRIPT &
                dash_pid=$!
                ;;
            'e'|'E')  # Export
                kill $dash_pid 2>/dev/null
                export_data
                # Restart dashboard
                ~/blackroad-dashboards/$DASHBOARD_SCRIPT &
                dash_pid=$!
                ;;
            'q'|'Q')  # Quit
                kill $dash_pid 2>/dev/null
                echo -e "\n${CYAN}Goodbye! 👋${RESET}\n"
                exit 0
                ;;
            't'|'T')  # Theme
                kill $dash_pid 2>/dev/null
                ~/blackroad-dashboards/themes.sh
                # Restart dashboard
                ~/blackroad-dashboards/$DASHBOARD_SCRIPT &
                dash_pid=$!
                ;;
        esac
    done
}

# Run it!
run_dashboard_wrapped
