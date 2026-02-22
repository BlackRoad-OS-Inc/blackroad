#!/bin/bash

# BlackRoad OS - Split Screen Dashboard Viewer
# View two dashboards side-by-side!

# Source theme
source ~/blackroad-dashboards/themes.sh
load_theme

# Get terminal size
COLS=$(tput cols)
ROWS=$(tput lines)
HALF_COLS=$((COLS / 2))

# Dashboard scripts
LEFT_DASH=$1
RIGHT_DASH=$2

if [ -z "$LEFT_DASH" ] || [ -z "$RIGHT_DASH" ]; then
    echo "Usage: $0 <left-dashboard> <right-dashboard>"
    echo ""
    echo "Example: $0 docker-fleet.sh security-dashboard.sh"
    exit 1
fi

# Create temp files for dashboard outputs
LEFT_OUTPUT=/tmp/blackroad_left.txt
RIGHT_OUTPUT=/tmp/blackroad_right.txt

# Cleanup on exit
cleanup() {
    rm -f "$LEFT_OUTPUT" "$RIGHT_OUTPUT"
    tput cnorm
    clear
}
trap cleanup EXIT INT TERM

# Hide cursor
tput civis

# Capture dashboard output (simplified - just shows dashboard names)
capture_left() {
    while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║  LEFT: $LEFT_DASH"
        echo "╚════════════════════════════════════════╝"
        echo ""
        echo "  Dashboard running..."
        echo "  (Press Q to quit split screen)"
        sleep 5
    done > "$LEFT_OUTPUT"
}

capture_right() {
    while true; do
        clear
        echo "╔════════════════════════════════════════╗"
        echo "║  RIGHT: $RIGHT_DASH"
        echo "╚════════════════════════════════════════╝"
        echo ""
        echo "  Dashboard running..."
        echo "  (Press S to swap sides)"
        sleep 5
    done > "$RIGHT_OUTPUT"
}

# Render split screen
render_split() {
    clear
    tput cup 0 0

    # Header
    echo -e "${BOLD}${PURPLE}╔═══════════════════════════════════════╦═══════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET} ${BOLD}LEFT: $LEFT_DASH${RESET}                    ${BOLD}${PURPLE}║${RESET} ${BOLD}RIGHT: $RIGHT_DASH${RESET}                   ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╠═══════════════════════════════════════╬═══════════════════════════════════════╣${RESET}"

    # Read last few lines from each dashboard
    local left_lines=$(tail -10 "$LEFT_OUTPUT" 2>/dev/null | head -20)
    local right_lines=$(tail -10 "$RIGHT_OUTPUT" 2>/dev/null | head -20)

    # Display side by side (simplified version)
    for i in {1..20}; do
        local left_line=$(echo "$left_lines" | sed -n "${i}p" | cut -c1-38)
        local right_line=$(echo "$right_lines" | sed -n "${i}p" | cut -c1-38)

        printf "${PURPLE}║${RESET} %-38s ${PURPLE}║${RESET} %-38s ${PURPLE}║${RESET}\n" "$left_line" "$right_line"
    done

    echo -e "${BOLD}${PURPLE}╚═══════════════════════════════════════╩═══════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_SECONDARY}[Q]${RESET} Quit  ${TEXT_SECONDARY}[S]${RESET} Swap  ${TEXT_SECONDARY}[L]${RESET} Focus Left  ${TEXT_SECONDARY}[R]${RESET} Focus Right  ${TEXT_SECONDARY}[E]${RESET} Exit Split"
}

# Main loop
main() {
    # Start dashboard captures in background
    capture_left &
    LEFT_PID=$!

    capture_right &
    RIGHT_PID=$!

    # Main render loop
    while true; do
        render_split

        # Check for key input
        read -rsn1 -t 0.5 key

        case "$key" in
            'q'|'Q')
                kill $LEFT_PID $RIGHT_PID 2>/dev/null
                echo -e "\n${CYAN}Exited split screen${RESET}\n"
                exit 0
                ;;
            's'|'S')
                # Swap dashboards
                local tmp=$LEFT_DASH
                LEFT_DASH=$RIGHT_DASH
                RIGHT_DASH=$tmp
                ;;
            'l'|'L')
                # Focus left (full screen)
                kill $LEFT_PID $RIGHT_PID 2>/dev/null
                ~/blackroad-dashboards/$LEFT_DASH --watch
                exit 0
                ;;
            'r'|'R')
                # Focus right (full screen)
                kill $LEFT_PID $RIGHT_PID 2>/dev/null
                ~/blackroad-dashboards/$RIGHT_DASH --watch
                exit 0
                ;;
            'e'|'E')
                # Exit to launcher
                kill $LEFT_PID $RIGHT_PID 2>/dev/null
                ~/blackroad-dashboards/br-dashboards-ultra.sh
                exit 0
                ;;
        esac
    done
}

main
