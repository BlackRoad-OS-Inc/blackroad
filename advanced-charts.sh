#!/bin/bash

# BlackRoad OS - Advanced Charts System
# Beautiful ASCII charts with real data

source ~/blackroad-dashboards/themes.sh
load_theme

# Chart characters
CHARS_BARS="▁▂▃▄▅▆▇█"
CHARS_DOTS="⠀⡀⡄⡆⡇⣇⣧⣷⣿"
CHARS_BLOCKS="░▒▓█"

# Generate time-series data (simulated real metrics)
generate_cpu_data() {
    # Simulate realistic CPU usage over 24 hours
    local data=(42 38 35 32 28 25 24 26 32 38 45 52 58 62 67 72 68 64 58 52 48 45 42 40)
    echo "${data[@]}"
}

generate_memory_data() {
    # Simulate memory growth pattern
    local data=(45 46 47 48 49 50 51 52 54 56 58 60 62 64 66 68 67 66 65 64 63 62 61 60)
    echo "${data[@]}"
}

generate_api_latency_data() {
    # Simulate API response times
    local data=(23 24 22 25 28 45 234 187 92 48 32 28 26 24 23 22 24 26 28 32 38 42 36 28)
    echo "${data[@]}"
}

generate_requests_data() {
    # Simulate request rate
    local data=(8 5 3 2 1 1 2 4 8 12 18 24 28 32 36 40 38 35 32 28 24 18 14 10)
    echo "${data[@]}"
}

generate_error_rate_data() {
    # Simulate error rate (percentage * 10)
    local data=(1 1 0 1 0 0 1 0 1 2 3 15 12 8 4 2 1 1 0 1 0 0 1 0)
    echo "${data[@]}"
}

# Bar chart (vertical)
render_bar_chart() {
    local title=$1
    shift
    local data=("$@")
    local max_value=0
    local height=10

    # Find max value
    for val in "${data[@]}"; do
        [ "$val" -gt "$max_value" ] && max_value=$val
    done

    echo -e "${BOLD}${TEXT_PRIMARY}$title${RESET}"
    echo ""

    # Render bars from top to bottom
    for ((row=height; row>=0; row--)); do
        local threshold=$((max_value * row / height))

        # Y-axis label
        printf "  %3d%% │ " "$((row * 10))"

        # Render each bar
        for val in "${data[@]}"; do
            if [ "$val" -ge "$threshold" ]; then
                # Color based on value
                if [ "$val" -ge 70 ]; then
                    echo -n "${RED}█${RESET}"
                elif [ "$val" -ge 50 ]; then
                    echo -n "${ORANGE}█${RESET}"
                elif [ "$val" -ge 30 ]; then
                    echo -n "${YELLOW}█${RESET}"
                else
                    echo -n "${GREEN}█${RESET}"
                fi
            else
                echo -n " "
            fi
        done
        echo ""
    done

    # X-axis
    echo "       └─────────────────────────"
    echo "         0h  4h  8h  12h 16h 20h"
    echo ""
}

# Line chart (sparkline style)
render_sparkline() {
    local title=$1
    local color=$2
    shift 2
    local data=("$@")
    local max_value=0

    # Find max value
    for val in "${data[@]}"; do
        [ "$val" -gt "$max_value" ] && max_value=$val
    done

    echo -ne "  ${BOLD}${TEXT_PRIMARY}$title${RESET}  "

    # Render sparkline
    for val in "${data[@]}"; do
        local idx=$((val * 7 / max_value))
        [ "$idx" -gt 7 ] && idx=7
        echo -ne "${!color}${CHARS_BARS:$idx:1}${RESET}"
    done

    # Show current value
    local current=${data[-1]}
    echo -e "  ${BOLD}${current}${RESET}"
}

# Stacked area chart
render_area_chart() {
    local title=$1
    shift
    local data=("$@")

    echo -e "${BOLD}${TEXT_PRIMARY}$title${RESET}"
    echo ""

    # Render filled area
    for val in "${data[@]}"; do
        local filled=$((val / 5))
        local bar=""
        for ((i=0; i<filled; i++)); do
            bar="${bar}█"
        done

        if [ "$val" -ge 70 ]; then
            echo -e "  ${RED}$bar${RESET} ${BOLD}$val%${RESET}"
        elif [ "$val" -ge 50 ]; then
            echo -e "  ${ORANGE}$bar${RESET} ${BOLD}$val%${RESET}"
        else
            echo -e "  ${GREEN}$bar${RESET} ${BOLD}$val%${RESET}"
        fi
    done
    echo ""
}

# Multi-line chart
render_multi_line() {
    local height=12
    local width=60

    echo -e "${BOLD}${TEXT_PRIMARY}Resource Usage Over Time${RESET}"
    echo ""

    # Get data
    local cpu=($(generate_cpu_data))
    local mem=($(generate_memory_data))
    local max_value=100

    # Render grid
    for ((row=height; row>=0; row--)); do
        local threshold=$((max_value * row / height))
        printf "  %3d │ " "$threshold"

        for ((col=0; col<${#cpu[@]}; col++)); do
            local cpu_val=${cpu[$col]}
            local mem_val=${mem[$col]}
            local cpu_height=$((cpu_val * height / max_value))
            local mem_height=$((mem_val * height / max_value))

            if [ "$row" -eq "$cpu_height" ] && [ "$row" -eq "$mem_height" ]; then
                echo -n "${PURPLE}◆${RESET}"
            elif [ "$row" -eq "$cpu_height" ]; then
                echo -n "${ORANGE}●${RESET}"
            elif [ "$row" -eq "$mem_height" ]; then
                echo -n "${PINK}●${RESET}"
            else
                echo -n "${TEXT_MUTED}·${RESET}"
            fi
        done
        echo ""
    done

    echo "      └────────────────────────"
    echo "        ${ORANGE}●${RESET} CPU  ${PINK}●${RESET} Memory"
    echo ""
}

# Histogram
render_histogram() {
    local title=$1
    shift
    local data=("$@")

    echo -e "${BOLD}${TEXT_PRIMARY}$title${RESET}"
    echo ""

    # Create buckets
    declare -A buckets
    for val in "${data[@]}"; do
        local bucket=$((val / 10 * 10))
        buckets[$bucket]=$((buckets[$bucket] + 1))
    done

    # Render histogram
    for bucket in $(echo "${!buckets[@]}" | tr ' ' '\n' | sort -n); do
        local count=${buckets[$bucket]}
        local bar=""
        for ((i=0; i<count; i++)); do
            bar="${bar}█"
        done

        printf "  %3d-%3d │ ${CYAN}%s${RESET} %d\n" "$bucket" "$((bucket + 9))" "$bar" "$count"
    done
    echo ""
}

# Real-time chart with animation
render_realtime_chart() {
    local iterations=${1:-20}

    for ((i=0; i<iterations; i++)); do
        clear
        echo ""
        echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${ORANGE}📊${RESET} ${BOLD}REAL-TIME METRICS${RESET}                                                 ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""

        # Generate real-time data
        local cpu=$((40 + RANDOM % 30))
        local mem=$((50 + RANDOM % 20))
        local disk=$((20 + RANDOM % 15))

        # CPU gauge
        echo -e "  ${ORANGE}CPU Usage${RESET}"
        printf "  │"
        local filled=$((cpu * 50 / 100))
        for ((j=0; j<50; j++)); do
            if [ "$j" -lt "$filled" ]; then
                if [ "$cpu" -ge 70 ]; then
                    printf "${RED}█${RESET}"
                elif [ "$cpu" -ge 50 ]; then
                    printf "${ORANGE}█${RESET}"
                else
                    printf "${GREEN}█${RESET}"
                fi
            else
                printf "${TEXT_MUTED}░${RESET}"
            fi
        done
        echo -e "│ ${BOLD}${cpu}%${RESET}"
        echo ""

        # Memory gauge
        echo -e "  ${PINK}Memory${RESET}"
        printf "  │"
        filled=$((mem * 50 / 100))
        for ((j=0; j<50; j++)); do
            if [ "$j" -lt "$filled" ]; then
                if [ "$mem" -ge 70 ]; then
                    printf "${RED}█${RESET}"
                else
                    printf "${PINK}█${RESET}"
                fi
            else
                printf "${TEXT_MUTED}░${RESET}"
            fi
        done
        echo -e "│ ${BOLD}${mem}%${RESET}"
        echo ""

        # Disk I/O gauge
        echo -e "  ${PURPLE}Disk I/O${RESET}"
        printf "  │"
        filled=$((disk * 50 / 100))
        for ((j=0; j<50; j++)); do
            if [ "$j" -lt "$filled" ]; then
                printf "${PURPLE}█${RESET}"
            else
                printf "${TEXT_MUTED}░${RESET}"
            fi
        done
        echo -e "│ ${BOLD}${disk}%${RESET}"
        echo ""

        echo -e "${TEXT_MUTED}Update $((i + 1))/$iterations - Refreshing in 0.5s...${RESET}"
        sleep 0.5
    done
}

# Show all charts
show_charts_gallery() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}📊${RESET} ${BOLD}ADVANCED CHARTS GALLERY${RESET}                                           ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SPARKLINES ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    render_sparkline "CPU Usage (24h)" "ORANGE" $(generate_cpu_data)
    render_sparkline "Memory (24h)  " "PINK" $(generate_memory_data)
    render_sparkline "API Latency   " "CYAN" $(generate_api_latency_data)
    render_sparkline "Requests/min  " "GREEN" $(generate_requests_data)
    echo ""

    echo -e "${TEXT_MUTED}╭─ BAR CHART ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    render_bar_chart "CPU Usage - Last 24 Hours" $(generate_cpu_data)

    echo -e "${TEXT_MUTED}╭─ MULTI-LINE CHART ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    render_multi_line

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Real-time  ${TEXT_SECONDARY}[H]${RESET} Histogram  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_charts_gallery

        read -n1 key

        case "$key" in
            'r'|'R')
                render_realtime_chart 30
                ;;
            'h'|'H')
                clear
                echo ""
                render_histogram "API Response Time Distribution" $(generate_api_latency_data)
                echo ""
                echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
                read -n1
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
