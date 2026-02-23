#!/bin/bash

# BlackRoad OS - Time Machine Dashboard
# Travel through your infrastructure's history

source ~/blackroad-dashboards/themes.sh
load_theme

HISTORY_FILE=~/blackroad-dashboards/.time_machine_history
CURRENT_TIME=$(date +%s)
TIME_POSITION=$CURRENT_TIME
PLAYBACK_SPEED=1

# Initialize history
touch "$HISTORY_FILE"

# Add historical events
init_history() {
    if [ ! -s "$HISTORY_FILE" ]; then
        local now=$(date +%s)

        # Generate 30 days of history
        for ((i=30; i>=0; i--)); do
            local timestamp=$((now - i * 86400))
            local cpu=$((30 + RANDOM % 40))
            local memory=$((4 + RANDOM % 3))
            local containers=$((20 + RANDOM % 8))

            echo "$timestamp|cpu:$cpu|memory:${memory}.${RANDOM:0:1}|containers:$containers|deployments:$((RANDOM % 5))" >> "$HISTORY_FILE"
        done
    fi
}

# Format timestamp
format_time() {
    local timestamp=$1
    date -r "$timestamp" "+%Y-%m-%d %H:%M:%S"
}

# Get data at specific time
get_historical_data() {
    local target_time=$1

    # Find closest historical record
    local closest_line=$(awk -F'|' -v target="$target_time" '
        BEGIN { min_diff=999999999; closest="" }
        {
            diff = ($1 > target) ? $1 - target : target - $1
            if (diff < min_diff) {
                min_diff = diff
                closest = $0
            }
        }
        END { print closest }
    ' "$HISTORY_FILE")

    echo "$closest_line"
}

# Show time machine dashboard
show_time_machine() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${PURPLE}⏰${RESET} ${BOLD}TIME MACHINE DASHBOARD${RESET}                                          ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    local current_data=$(get_historical_data "$TIME_POSITION")
    local time_str=$(format_time "$TIME_POSITION")

    # Time indicator
    echo -e "${TEXT_MUTED}╭─ TIME TRAVEL ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local time_diff=$((CURRENT_TIME - TIME_POSITION))
    local days_ago=$((time_diff / 86400))

    if [ $days_ago -eq 0 ]; then
        echo -e "  ${BOLD}${GREEN}◉ LIVE${RESET}  ${CYAN}$time_str${RESET}"
    else
        echo -e "  ${BOLD}${ORANGE}◉ $days_ago days ago${RESET}  ${CYAN}$time_str${RESET}"
    fi
    echo ""

    # Timeline
    echo -e "${TEXT_MUTED}╭─ TIMELINE ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local total_days=30
    local position_days=$(( (CURRENT_TIME - TIME_POSITION) / 86400 ))
    local bar_position=$((50 - position_days * 50 / total_days))

    echo -n "  ${TEXT_MUTED}30d ago${RESET}  "
    for ((i=0; i<50; i++)); do
        if [ $i -eq $bar_position ]; then
            echo -n "${GOLD}◆${RESET}"
        else
            echo -n "${TEXT_MUTED}─${RESET}"
        fi
    done
    echo " ${GREEN}NOW${RESET}"
    echo ""

    # Historical metrics
    echo -e "${TEXT_MUTED}╭─ METRICS AT THIS TIME ────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -n "$current_data" ]; then
        local cpu=$(echo "$current_data" | grep -o 'cpu:[0-9]*' | cut -d: -f2)
        local memory=$(echo "$current_data" | grep -o 'memory:[0-9.]*' | cut -d: -f2)
        local containers=$(echo "$current_data" | grep -o 'containers:[0-9]*' | cut -d: -f2)
        local deployments=$(echo "$current_data" | grep -o 'deployments:[0-9]*' | cut -d: -f2)

        echo -e "  ${BOLD}${TEXT_PRIMARY}CPU Usage:${RESET}"
        echo -n "    ${ORANGE}"
        for ((i=0; i<cpu/2; i++)); do echo -n "█"; done
        echo -e "${TEXT_MUTED}$(for ((i=cpu/2; i<50; i++)); do echo -n "░"; done)${RESET}  ${BOLD}${cpu}%${RESET}"
        echo ""

        echo -e "  ${BOLD}${TEXT_PRIMARY}Memory:${RESET}             ${BOLD}${PINK}${memory} GB${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Containers:${RESET}         ${BOLD}${CYAN}${containers}${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Deployments:${RESET}        ${BOLD}${GREEN}${deployments}${RESET}"
    else
        echo -e "  ${TEXT_MUTED}No data available at this time${RESET}"
    fi
    echo ""

    # Historical events
    echo -e "${TEXT_MUTED}╭─ EVENTS AT THIS TIME ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${TEXT_MUTED}[$(format_time $((TIME_POSITION - 3600)))]${RESET} Deployment: ${CYAN}api-v2.3.1${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${TEXT_MUTED}[$(format_time $((TIME_POSITION - 7200)))]${RESET} Alert: ${ORANGE}High CPU${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${TEXT_MUTED}[$(format_time $((TIME_POSITION - 10800)))]${RESET} Scaled: ${PURPLE}+3 containers${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_MUTED}[$(format_time $((TIME_POSITION - 14400)))]${RESET} Backup: ${BLUE}Completed${RESET}"
    echo ""

    # Comparison with now
    echo -e "${TEXT_MUTED}╭─ COMPARISON WITH NOW ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    local now_data=$(get_historical_data "$CURRENT_TIME")
    local now_cpu=$(echo "$now_data" | grep -o 'cpu:[0-9]*' | cut -d: -f2)
    local then_cpu=$(echo "$current_data" | grep -o 'cpu:[0-9]*' | cut -d: -f2)

    if [ -n "$then_cpu" ] && [ -n "$now_cpu" ]; then
        local cpu_diff=$((now_cpu - then_cpu))

        echo -e "  ${BOLD}${TEXT_PRIMARY}CPU Change:${RESET}"
        if [ $cpu_diff -gt 0 ]; then
            echo -e "    ${RED}↑ +${cpu_diff}%${RESET} ${TEXT_MUTED}(increased)${RESET}"
        elif [ $cpu_diff -lt 0 ]; then
            echo -e "    ${GREEN}↓ ${cpu_diff}%${RESET} ${TEXT_MUTED}(decreased)${RESET}"
        else
            echo -e "    ${CYAN}→ No change${RESET}"
        fi
    fi
    echo ""

    # Time travel controls
    echo -e "${TEXT_MUTED}╭─ TIME TRAVEL CONTROLS ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}←${RESET} ${BOLD}1 Hour Back${RESET}        ${PURPLE}→${RESET} ${BOLD}1 Hour Forward${RESET}"
    echo -e "  ${ORANGE}[${RESET} ${BOLD}1 Day Back${RESET}         ${PINK}]${RESET} ${BOLD}1 Day Forward${RESET}"
    echo -e "  ${GREEN}H${RESET} ${BOLD}Go to Start${RESET}        ${GOLD}N${RESET} ${BOLD}Go to Now${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Playback Speed:${RESET}      ${CYAN}${PLAYBACK_SPEED}x${RESET}"
    echo ""

    # Snapshots
    echo -e "${TEXT_MUTED}╭─ SAVED SNAPSHOTS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}📸${RESET} ${BOLD}Pre-Deployment${RESET}     ${TEXT_MUTED}2024-12-20 15:30${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${CYAN}📸${RESET} ${BOLD}After Scaling${RESET}      ${TEXT_MUTED}2024-12-18 09:15${RESET}  ${GREEN}✓${RESET}"
    echo -e "  ${ORANGE}📸${RESET} ${BOLD}Peak Traffic${RESET}       ${TEXT_MUTED}2024-12-15 14:45${RESET}  ${GREEN}✓${RESET}"
    echo ""

    # Historical chart
    echo -e "${TEXT_MUTED}╭─ CPU HISTORY (30 DAYS) ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "   ${TEXT_MUTED}%${RESET}"
    echo "  ${TEXT_MUTED}100${RESET} ${RED}│${RESET}"
    echo "   ${TEXT_MUTED}75${RESET} ${ORANGE}│${RESET}     ${ORANGE}▄█▄${RESET}"
    echo "   ${TEXT_MUTED}50${RESET} ${YELLOW}│${RESET}   ${YELLOW}▄█${RESET}${ORANGE}█${RESET}${YELLOW}█▄${RESET}  ${YELLOW}▄${RESET}        ${GOLD}◆${RESET} ${TEXT_MUTED}You are here${RESET}"
    echo "   ${TEXT_MUTED}25${RESET} ${GREEN}│${RESET}${GREEN}▄██${RESET}${YELLOW}█${RESET}   ${YELLOW}█${RESET}${GREEN}██▄${RESET}"
    echo "    ${TEXT_MUTED}0${RESET} ${TEXT_MUTED}└────────────────────────────────────────────────→${RESET}"
    echo "       ${TEXT_MUTED}30d   25d   20d   15d   10d   5d    NOW${RESET}"
    echo ""

    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[←/→]${RESET} Hours  ${TEXT_SECONDARY}[[/]]${RESET} Days  ${TEXT_SECONDARY}[H]${RESET} Start  ${TEXT_SECONDARY}[N]${RESET} Now  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    init_history

    while true; do
        show_time_machine

        read -rsn1 key

        # Handle escape sequences for arrow keys
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
        fi

        case "$key" in
            '[D'|'h'|'H')  # Left arrow or H
                if [ "$key" = "h" ] || [ "$key" = "H" ]; then
                    # Go to start
                    TIME_POSITION=$((CURRENT_TIME - 30 * 86400))
                else
                    # 1 hour back
                    TIME_POSITION=$((TIME_POSITION - 3600))
                fi
                ;;
            '[C'|'n'|'N')  # Right arrow or N
                if [ "$key" = "n" ] || [ "$key" = "N" ]; then
                    # Go to now
                    TIME_POSITION=$CURRENT_TIME
                else
                    # 1 hour forward
                    TIME_POSITION=$((TIME_POSITION + 3600))
                    [ $TIME_POSITION -gt $CURRENT_TIME ] && TIME_POSITION=$CURRENT_TIME
                fi
                ;;
            '[')
                # 1 day back
                TIME_POSITION=$((TIME_POSITION - 86400))
                ;;
            ']')
                # 1 day forward
                TIME_POSITION=$((TIME_POSITION + 86400))
                [ $TIME_POSITION -gt $CURRENT_TIME ] && TIME_POSITION=$CURRENT_TIME
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Time travel ended${RESET}\n"
                exit 0
                ;;
        esac

        # Keep within bounds
        local min_time=$((CURRENT_TIME - 30 * 86400))
        [ $TIME_POSITION -lt $min_time ] && TIME_POSITION=$min_time
    done
}

# Run
main
