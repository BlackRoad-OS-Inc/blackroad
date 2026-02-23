#!/bin/bash

# BlackRoad OS - Sparklines Everywhere
# Add mini charts to every metric

source ~/blackroad-dashboards/themes.sh
load_theme

CHARS="▁▂▃▄▅▆▇█"

# Generate sparkline from data array
sparkline() {
    local data=("$@")
    local max=0
    local min=999999

    # Find min/max
    for val in "${data[@]}"; do
        [ "$val" -gt "$max" ] && max=$val
        [ "$val" -lt "$min" ] && min=$val
    done

    # Render sparkline
    local range=$((max - min))
    [ "$range" -eq 0 ] && range=1

    for val in "${data[@]}"; do
        local normalized=$((( val - min ) * 7 / range))
        [ "$normalized" -gt 7 ] && normalized=7
        echo -n "${CHARS:$normalized:1}"
    done
}

# Sparkline with color gradient
sparkline_color() {
    local color=$1
    shift
    local data=("$@")
    local max=0

    for val in "${data[@]}"; do
        [ "$val" -gt "$max" ] && max=$val
    done

    for val in "${data[@]}"; do
        local idx=$((val * 7 / max))
        [ "$idx" -gt 7 ] && idx=7

        # Color based on value
        if [ "$val" -ge $((max * 7 / 10)) ]; then
            echo -n "${RED}${CHARS:$idx:1}${RESET}"
        elif [ "$val" -ge $((max * 5 / 10)) ]; then
            echo -n "${ORANGE}${CHARS:$idx:1}${RESET}"
        else
            echo -n "${!color}${CHARS:$idx:1}${RESET}"
        fi
    done
}

# Show dashboard with sparklines everywhere
show_sparkline_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${ORANGE}📈${RESET} ${BOLD}SPARKLINES EVERYWHERE${RESET}                                             ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # System overview with sparklines
    echo -e "${TEXT_MUTED}╭─ SYSTEM OVERVIEW ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # CPU
    local cpu_data=(42 38 45 52 58 62 67 72 68 64 58 52 48 45 42 40 38 42 45 48)
    echo -ne "  ${ORANGE}●${RESET} ${BOLD}${TEXT_PRIMARY}CPU${RESET}            "
    sparkline_color "ORANGE" "${cpu_data[@]}"
    echo -e "  ${BOLD}${ORANGE}42%${RESET}  ${TEXT_MUTED}(avg: 50%)${RESET}"

    # Memory
    local mem_data=(45 46 47 48 49 50 51 52 54 56 58 60 62 64 66 68 67 66 65 64)
    echo -ne "  ${PINK}●${RESET} ${BOLD}${TEXT_PRIMARY}Memory${RESET}         "
    sparkline_color "PINK" "${mem_data[@]}"
    echo -e "  ${BOLD}${PINK}5.8 GB${RESET}  ${TEXT_MUTED}(growing)${RESET}"

    # Disk I/O
    local disk_data=(23 28 32 28 24 20 18 22 26 30 34 38 32 28 24 22 20 24 28 32)
    echo -ne "  ${PURPLE}●${RESET} ${BOLD}${TEXT_PRIMARY}Disk I/O${RESET}       "
    sparkline_color "PURPLE" "${disk_data[@]}"
    echo -e "  ${BOLD}${PURPLE}847 MB/s${RESET}"

    # Network In
    local net_in=(120 115 118 122 125 128 132 138 142 145 148 142 138 135 132 128 125 122 120 118)
    echo -ne "  ${GREEN}●${RESET} ${BOLD}${TEXT_PRIMARY}Network In${RESET}     "
    sparkline_color "GREEN" "${net_in[@]}"
    echo -e "  ${BOLD}${GREEN}1.2 GB/s${RESET}"

    # Network Out
    local net_out=(84 82 86 88 92 95 98 102 105 108 102 98 95 92 88 85 82 80 78 76)
    echo -ne "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}Network Out${RESET}    "
    sparkline_color "BLUE" "${net_out[@]}"
    echo -e "  ${BOLD}${BLUE}847 MB/s${RESET}"
    echo ""

    # Container stats with sparklines
    echo -e "${TEXT_MUTED}╭─ CONTAINERS (with sparklines) ────────────────────────────────────────╮${RESET}"
    echo ""

    # Container 1
    local c1_cpu=(12 14 18 22 28 32 28 24 20 18 16 14 12 10 12 14 16 18 20 22)
    echo -ne "  ${GREEN}●${RESET} ${BOLD}lucidia-earth${RESET}     "
    sparkline_color "CYAN" "${c1_cpu[@]}"
    echo -e "  ${BOLD}12%${RESET} CPU  ${TEXT_MUTED}256MB${RESET}"

    # Container 2
    local c2_cpu=(8 10 12 15 18 22 26 30 28 24 20 18 16 14 12 10 8 10 12 14)
    echo -ne "  ${GREEN}●${RESET} ${BOLD}docs-blackroad${RESET}   "
    sparkline_color "CYAN" "${c2_cpu[@]}"
    echo -e "  ${BOLD}14%${RESET} CPU  ${TEXT_MUTED}512MB${RESET}"

    # Container 3
    local c3_cpu=(18 22 28 34 42 48 52 48 42 38 34 30 26 22 20 18 22 26 30 34)
    echo -ne "  ${GREEN}●${RESET} ${BOLD}app-blackroad${RESET}    "
    sparkline_color "CYAN" "${c3_cpu[@]}"
    echo -e "  ${BOLD}34%${RESET} CPU  ${TEXT_MUTED}1.2GB${RESET}"

    # Container 4
    local c4_cpu=(5 6 7 8 9 10 11 12 11 10 9 8 7 6 5 6 7 8 9 10)
    echo -ne "  ${GREEN}●${RESET} ${BOLD}postgres${RESET}         "
    sparkline_color "CYAN" "${c4_cpu[@]}"
    echo -e "  ${BOLD}10%${RESET} CPU  ${TEXT_MUTED}768MB${RESET}"

    # Container 5
    local c5_cpu=(3 4 5 6 7 8 7 6 5 4 3 4 5 6 5 4 3 4 5 6)
    echo -ne "  ${GREEN}●${RESET} ${BOLD}redis${RESET}            "
    sparkline_color "CYAN" "${c5_cpu[@]}"
    echo -e "  ${BOLD}6%${RESET} CPU  ${TEXT_MUTED}128MB${RESET}"
    echo ""

    # API endpoints with sparklines
    echo -e "${TEXT_MUTED}╭─ API ENDPOINTS (response time) ───────────────────────────────────────╮${RESET}"
    echo ""

    # Endpoint 1
    local e1_latency=(23 24 22 25 28 32 34 32 28 26 24 23 22 24 26 28 30 28 26 24)
    echo -ne "  ${CYAN}GET${RESET}  ${TEXT_PRIMARY}/api/v1/data${RESET}        "
    sparkline_color "GREEN" "${e1_latency[@]}"
    echo -e "  ${BOLD}24ms${RESET}  ${GREEN}↓ 2ms${RESET}"

    # Endpoint 2 (problem!)
    local e2_latency=(23 24 25 28 45 87 134 187 234 198 156 112 78 54 38 32 28 26 24 23)
    echo -ne "  ${CYAN}GET${RESET}  ${TEXT_PRIMARY}/api/v1/users${RESET}       "
    sparkline_color "GREEN" "${e2_latency[@]}"
    echo -e "  ${BOLD}${RED}234ms${RESET}  ${RED}↑ 211ms${RESET} ${RED}⚠️${RESET}"

    # Endpoint 3
    local e3_latency=(18 20 22 24 26 28 30 28 26 24 22 20 18 20 22 24 26 24 22 20)
    echo -ne "  ${CYAN}POST${RESET} ${TEXT_PRIMARY}/api/v1/auth${RESET}        "
    sparkline_color "GREEN" "${e3_latency[@]}"
    echo -e "  ${BOLD}20ms${RESET}  ${GREEN}↓ 1ms${RESET}"

    # Endpoint 4
    local e4_latency=(12 14 16 18 20 22 24 22 20 18 16 14 12 14 16 18 20 18 16 14)
    echo -ne "  ${CYAN}GET${RESET}  ${TEXT_PRIMARY}/api/v1/health${RESET}      "
    sparkline_color "GREEN" "${e4_latency[@]}"
    echo -e "  ${BOLD}14ms${RESET}  ${GREEN}↓ 1ms${RESET}"
    echo ""

    # Database queries with sparklines
    echo -e "${TEXT_MUTED}╭─ DATABASE QUERIES (execution time) ───────────────────────────────────╮${RESET}"
    echo ""

    # Query 1
    local q1_time=(12 14 16 18 20 22 24 22 20 18 16 14 12 14 16 18 20 18 16 14)
    echo -ne "  ${PURPLE}●${RESET} ${TEXT_PRIMARY}SELECT users${RESET}          "
    sparkline_color "PURPLE" "${q1_time[@]}"
    echo -e "  ${BOLD}14ms${RESET}"

    # Query 2 (slow!)
    local q2_time=(23 28 45 67 89 112 156 187 234 198 167 134 98 76 54 42 34 28 24 23)
    echo -ne "  ${PURPLE}●${RESET} ${TEXT_PRIMARY}SELECT deployments${RESET}   "
    sparkline_color "PURPLE" "${q2_time[@]}"
    echo -e "  ${BOLD}${RED}234ms${RESET} ${YELLOW}Need index!${RESET}"

    # Query 3
    local q3_time=(8 10 12 14 16 18 16 14 12 10 8 10 12 14 12 10 8 10 12 14)
    echo -ne "  ${PURPLE}●${RESET} ${TEXT_PRIMARY}INSERT logs${RESET}          "
    sparkline_color "PURPLE" "${q3_time[@]}"
    echo -e "  ${BOLD}14ms${RESET}"
    echo ""

    # Error rates with sparklines
    echo -e "${TEXT_MUTED}╭─ ERROR RATES (per minute) ────────────────────────────────────────────╮${RESET}"
    echo ""

    # 4xx errors
    local err_4xx=(2 3 2 4 5 3 2 1 2 3 4 5 6 8 12 15 12 8 5 3)
    echo -ne "  ${YELLOW}●${RESET} ${TEXT_PRIMARY}4xx Errors${RESET}           "
    sparkline_color "YELLOW" "${err_4xx[@]}"
    echo -e "  ${BOLD}${YELLOW}3/min${RESET}"

    # 5xx errors
    local err_5xx=(0 0 1 0 1 2 3 5 8 12 15 12 8 5 3 2 1 0 1 0)
    echo -ne "  ${RED}●${RESET} ${TEXT_PRIMARY}5xx Errors${RESET}           "
    sparkline_color "RED" "${err_5xx[@]}"
    echo -e "  ${BOLD}${RED}0/min${RESET} ${GREEN}Recovered${RESET}"
    echo ""

    # Deployment stats with sparklines
    echo -e "${TEXT_MUTED}╭─ DEPLOYMENT STATS ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Deploy frequency
    local deploys=(2 3 5 4 6 8 10 12 14 16 18 20 22 24 22 20 18 16 14 12)
    echo -ne "  ${ORANGE}●${RESET} ${TEXT_PRIMARY}Deploys/day${RESET}          "
    sparkline_color "ORANGE" "${deploys[@]}"
    echo -e "  ${BOLD}${ORANGE}12/day${RESET}  ${TEXT_MUTED}(trending up)${RESET}"

    # Deploy duration
    local duration=(120 118 122 125 128 132 135 138 142 145 148 152 156 160 158 155 152 148 145 142)
    echo -ne "  ${PINK}●${RESET} ${TEXT_PRIMARY}Deploy time${RESET}          "
    sparkline_color "PINK" "${duration[@]}"
    echo -e "  ${BOLD}${PINK}2m 22s${RESET}  ${YELLOW}↑ 22s${RESET}"

    # Success rate
    local success=(98 98 97 98 99 98 97 96 95 94 93 92 94 96 97 98 99 98 97 98)
    echo -ne "  ${GREEN}●${RESET} ${TEXT_PRIMARY}Success rate${RESET}         "
    sparkline_color "GREEN" "${success[@]}"
    echo -e "  ${BOLD}${GREEN}98%${RESET}"
    echo ""

    # Traffic patterns
    echo -e "${TEXT_MUTED}╭─ TRAFFIC PATTERNS ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Hourly requests
    local hourly=(8 5 3 2 1 1 2 4 8 12 18 24 28 32 36 40 38 35 32 28)
    echo -ne "  ${CYAN}●${RESET} ${TEXT_PRIMARY}Requests (hourly)${RESET}    "
    sparkline_color "CYAN" "${hourly[@]}"
    echo -e "  ${BOLD}${CYAN}28K/hour${RESET}"

    # Unique visitors
    local visitors=(120 115 110 105 98 92 88 95 112 134 156 178 192 204 198 187 176 165 154 142)
    echo -ne "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Unique visitors${RESET}      "
    sparkline_color "BLUE" "${visitors[@]}"
    echo -e "  ${BOLD}${BLUE}142/hour${RESET}"

    # Bandwidth
    local bandwidth=(456 478 492 512 534 556 578 592 612 634 656 672 688 698 686 672 654 638 622 608)
    echo -ne "  ${PURPLE}●${RESET} ${TEXT_PRIMARY}Bandwidth${RESET}            "
    sparkline_color "PURPLE" "${bandwidth[@]}"
    echo -e "  ${BOLD}${PURPLE}608 MB/s${RESET}"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[T]${RESET} Time range  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo -e "  ${TEXT_MUTED}All sparklines show last 20 data points${RESET}"
    echo ""
}

# Main loop
main() {
    while true; do
        show_sparkline_dashboard

        read -n1 -t 5 key

        case "$key" in
            'r'|'R')
                continue
                ;;
            't'|'T')
                echo -e "\n${CYAN}Time range selection not yet implemented${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye!${RESET}\n"
                exit 0
                ;;
            *)
                # Auto-refresh
                continue
                ;;
        esac
    done
}

# Run
main
