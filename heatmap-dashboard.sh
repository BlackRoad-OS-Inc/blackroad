#!/bin/bash

# BlackRoad OS - Heatmap Dashboard
# Visualize data density and patterns

source ~/blackroad-dashboards/themes.sh
load_theme

# Heatmap characters (intensity levels)
HEAT_CHARS=("  " "░░" "▒▒" "▓▓" "██")

# Color schemes
declare -A HEAT_COLORS_FIRE=(
    [0]="${TEXT_MUTED}"
    [1]="${YELLOW}"
    [2]="${ORANGE}"
    [3]="${RED}"
    [4]="${BOLD}${RED}"
)

declare -A HEAT_COLORS_OCEAN=(
    [0]="${TEXT_MUTED}"
    [1]="${CYAN}"
    [2]="${BLUE}"
    [3]="${PURPLE}"
    [4]="${BOLD}${PURPLE}"
)

declare -A HEAT_COLORS_GREEN=(
    [0]="${TEXT_MUTED}"
    [1]="${GREEN}"
    [2]="${CYAN}"
    [3]="${BLUE}"
    [4]="${BOLD}${BLUE}"
)

# Generate heatmap data
generate_cpu_heatmap() {
    # 24 hours × 7 days
    local data=(
        # Sunday
        "10 8 5 3 2 1 1 2 5 8 12 18 24 28 32 35 38 42 45 42 38 32 24 18"
        # Monday
        "12 10 8 5 3 2 2 4 8 15 25 35 45 55 65 72 78 75 68 58 48 38 28 20"
        # Tuesday
        "14 12 10 7 4 3 3 5 10 18 28 38 48 58 68 75 82 78 72 62 52 42 32 24"
        # Wednesday
        "15 13 11 8 5 4 4 6 12 20 32 42 52 62 72 82 88 85 78 68 58 48 38 28"
        # Thursday
        "16 14 12 9 6 5 5 8 14 24 36 48 58 68 78 85 92 88 82 72 62 52 42 32"
        # Friday
        "18 16 14 10 7 6 6 10 16 28 42 56 68 78 85 88 92 85 78 68 58 48 38 30"
        # Saturday
        "14 12 10 7 4 3 3 5 10 18 28 38 48 55 62 65 68 62 55 45 35 28 22 16"
    )
    echo "${data[@]}"
}

generate_api_heatmap() {
    # API endpoint activity by hour and day
    local data=(
        "5 3 2 1 1 1 2 4 8 12 18 24 28 32 35 38 42 38 32 24 18 12 8 5"
        "8 5 3 2 1 2 3 6 12 20 30 42 52 62 68 72 75 68 58 45 32 22 14 10"
        "10 7 4 3 2 3 4 8 15 25 38 52 65 75 82 85 88 82 72 58 42 28 18 12"
        "12 8 5 4 3 4 5 10 18 30 45 62 75 85 92 95 98 92 82 68 52 35 22 15"
        "14 10 7 5 4 5 6 12 22 38 56 72 85 92 96 98 98 92 85 72 58 42 28 18"
        "16 12 8 6 5 6 8 15 28 45 65 82 92 95 96 95 92 85 78 65 52 38 28 20"
        "10 7 5 3 2 3 4 8 14 24 36 48 58 65 68 68 65 58 48 38 28 20 14 10"
    )
    echo "${data[@]}"
}

generate_error_heatmap() {
    # Error density by hour and day
    local data=(
        "0 0 0 0 0 0 0 0 1 1 2 3 4 5 6 5 4 3 2 1 1 0 0 0"
        "0 0 0 0 0 0 1 1 2 3 5 8 12 15 18 15 12 8 5 3 2 1 0 0"
        "0 0 0 0 0 1 1 2 3 5 8 12 18 24 28 24 18 12 8 5 3 1 0 0"
        "0 0 0 0 1 1 2 3 5 8 14 22 32 42 48 42 32 22 14 8 5 2 1 0"
        "0 0 0 1 1 2 3 5 8 14 24 38 52 68 75 68 52 38 24 14 8 3 1 0"
        "0 0 1 1 2 3 4 6 10 18 32 48 65 82 92 82 65 48 32 18 10 4 1 0"
        "0 0 0 0 0 0 1 1 2 4 8 12 18 24 28 24 18 12 8 4 2 0 0 0"
    )
    echo "${data[@]}"
}

# Render heatmap
render_heatmap() {
    local title=$1
    local scheme=$2
    shift 2
    local data=("$@")
    local max_value=0

    # Find max value
    for row in "${data[@]}"; do
        for val in $row; do
            [ "$val" -gt "$max_value" ] && max_value=$val
        done
    done

    echo -e "${BOLD}${TEXT_PRIMARY}$title${RESET}"
    echo ""

    # Day labels
    echo -n "        "
    for hour in 0 2 4 6 8 10 12 14 16 18 20 22; do
        printf " %2d" "$hour"
    done
    echo ""

    # Render rows
    local days=("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")
    local row_idx=0

    for row in "${data[@]}"; do
        printf "  %-5s " "${days[$row_idx]}"

        local col_idx=0
        for val in $row; do
            # Skip odd columns to fit width
            if [ $((col_idx % 2)) -eq 0 ]; then
                # Normalize to 0-4
                local intensity=$((val * 4 / max_value))
                [ "$intensity" -gt 4 ] && intensity=4

                # Get color for scheme
                local color
                case "$scheme" in
                    "fire")
                        case "$intensity" in
                            0) color="${TEXT_MUTED}" ;;
                            1) color="${YELLOW}" ;;
                            2) color="${ORANGE}" ;;
                            3) color="${RED}" ;;
                            4) color="${BOLD}${RED}" ;;
                        esac
                        ;;
                    "ocean")
                        case "$intensity" in
                            0) color="${TEXT_MUTED}" ;;
                            1) color="${CYAN}" ;;
                            2) color="${BLUE}" ;;
                            3) color="${PURPLE}" ;;
                            4) color="${BOLD}${PURPLE}" ;;
                        esac
                        ;;
                    "green")
                        case "$intensity" in
                            0) color="${TEXT_MUTED}" ;;
                            1) color="${GREEN}" ;;
                            2) color="${CYAN}" ;;
                            3) color="${BLUE}" ;;
                            4) color="${BOLD}${BLUE}" ;;
                        esac
                        ;;
                esac

                echo -ne "${color}${HEAT_CHARS[$intensity]}${RESET}"
            fi
            ((col_idx++))
        done
        echo ""
        ((row_idx++))
    done
    echo ""

    # Legend
    echo -ne "  ${TEXT_MUTED}Legend:${RESET}  "
    for i in 0 1 2 3 4; do
        local color
        case "$scheme" in
            "fire")
                case "$i" in
                    0) color="${TEXT_MUTED}" ;;
                    1) color="${YELLOW}" ;;
                    2) color="${ORANGE}" ;;
                    3) color="${RED}" ;;
                    4) color="${BOLD}${RED}" ;;
                esac
                ;;
            "ocean")
                case "$i" in
                    0) color="${TEXT_MUTED}" ;;
                    1) color="${CYAN}" ;;
                    2) color="${BLUE}" ;;
                    3) color="${PURPLE}" ;;
                    4) color="${BOLD}${PURPLE}" ;;
                esac
                ;;
            "green")
                case "$i" in
                    0) color="${TEXT_MUTED}" ;;
                    1) color="${GREEN}" ;;
                    2) color="${CYAN}" ;;
                    3) color="${BLUE}" ;;
                    4) color="${BOLD}${BLUE}" ;;
                esac
                ;;
        esac
        echo -ne "${color}${HEAT_CHARS[$i]}${RESET} "
    done
    echo -e "${TEXT_MUTED}(low → high)${RESET}"
    echo ""
}

# Show all heatmaps
show_heatmaps() {
    clear
    echo ""
    echo -e "${BOLD}${RED}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║${RESET}  ${ORANGE}🔥${RESET} ${BOLD}HEATMAP DASHBOARD${RESET}                                                 ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ CPU USAGE HEATMAP (Last 7 Days) ────────────────────────────────────╮${RESET}"
    echo ""
    IFS=$'\n' read -d '' -r -a cpu_data <<< "$(generate_cpu_heatmap)"
    render_heatmap "CPU Usage by Hour and Day" "fire" "${cpu_data[@]}"

    echo -e "${TEXT_MUTED}╭─ API ACTIVITY HEATMAP (Last 7 Days) ──────────────────────────────────╮${RESET}"
    echo ""
    IFS=$'\n' read -d '' -r -a api_data <<< "$(generate_api_heatmap)"
    render_heatmap "API Request Volume" "ocean" "${api_data[@]}"

    echo -e "${TEXT_MUTED}╭─ ERROR DENSITY HEATMAP (Last 7 Days) ─────────────────────────────────╮${RESET}"
    echo ""
    IFS=$'\n' read -d '' -r -a error_data <<< "$(generate_error_heatmap)"
    render_heatmap "Error Rate Distribution" "fire" "${error_data[@]}"

    echo -e "${TEXT_MUTED}╭─ INSIGHTS ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Peak Hours:${RESET} Thursday-Friday 2-6 PM (highest CPU/API activity)"
    echo -e "  ${RED}●${RESET} ${BOLD}Error Spike:${RESET} Friday 2-4 PM correlates with peak traffic"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Low Activity:${RESET} Weekend mornings 12-6 AM (ideal maintenance window)"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Pattern:${RESET} Weekday ramp-up from Mon→Fri, weekend cooldown"
    echo ""

    echo -e "${RED}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[S]${RESET} Switch scheme  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_heatmaps

        read -n1 key

        case "$key" in
            'r'|'R')
                continue
                ;;
            's'|'S')
                echo -e "\n${CYAN}Color scheme rotation not yet implemented${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye!${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
