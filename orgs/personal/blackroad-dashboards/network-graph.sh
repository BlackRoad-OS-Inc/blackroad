#!/bin/bash

# BlackRoad OS - Network Graph Visualizer
# Show service relationships and dependencies

source ~/blackroad-dashboards/themes.sh
load_theme

# Service status
declare -A SERVICE_STATUS=(
    ["cloudflare"]="online"
    ["api"]="online"
    ["database"]="online"
    ["redis"]="online"
    ["worker"]="online"
    ["cdn"]="online"
    ["monitoring"]="warning"
    ["backup"]="error"
)

# Connection health (0-100)
declare -A CONNECTION_HEALTH=(
    ["cloudflare->api"]="98"
    ["api->database"]="95"
    ["api->redis"]="99"
    ["api->worker"]="87"
    ["worker->database"]="92"
    ["cdn->cloudflare"]="100"
    ["monitoring->api"]="45"
    ["backup->database"]="12"
)

# Get status color
get_status_color() {
    case "$1" in
        "online") echo "${GREEN}" ;;
        "warning") echo "${YELLOW}" ;;
        "error") echo "${RED}" ;;
        *) echo "${TEXT_MUTED}" ;;
    esac
}

# Get status icon
get_status_icon() {
    case "$1" in
        "online") echo "●" ;;
        "warning") echo "◐" ;;
        "error") echo "○" ;;
        *) echo "·" ;;
    esac
}

# Get connection line based on health
get_connection_line() {
    local health=$1
    if [ "$health" -ge 90 ]; then
        echo "${GREEN}━━━${RESET}"
    elif [ "$health" -ge 70 ]; then
        echo "${YELLOW}━━━${RESET}"
    elif [ "$health" -ge 40 ]; then
        echo "${ORANGE}┄┄┄${RESET}"
    else
        echo "${RED}╌╌╌${RESET}"
    fi
}

# Render network graph
render_network_graph() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${PURPLE}🕸️${RESET}  ${BOLD}NETWORK GRAPH${RESET}                                                    ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SERVICE TOPOLOGY ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Layer 1: External
    echo -e "  ${TEXT_MUTED}[Layer 1: External]${RESET}"
    echo ""
    local cdn_color=$(get_status_color "${SERVICE_STATUS[cdn]}")
    local cdn_icon=$(get_status_icon "${SERVICE_STATUS[cdn]}")
    echo -e "                           ${cdn_color}${cdn_icon}${RESET} ${BOLD}CDN${RESET} ${TEXT_MUTED}(Cloudflare Edge)${RESET}"
    echo -e "                                ${TEXT_MUTED}│${RESET}"
    local cdn_cf_health="${CONNECTION_HEALTH[cdn->cloudflare]}"
    local cdn_cf_line=$(get_connection_line "$cdn_cf_health")
    echo -e "                                $cdn_cf_line ${TEXT_MUTED}$cdn_cf_health%${RESET}"
    echo -e "                                ${TEXT_MUTED}│${RESET}"
    echo -e "                                ${TEXT_MUTED}▼${RESET}"
    echo ""

    # Layer 2: Edge
    echo -e "  ${TEXT_MUTED}[Layer 2: Edge]${RESET}"
    echo ""
    local cf_color=$(get_status_color "${SERVICE_STATUS[cloudflare]}")
    local cf_icon=$(get_status_icon "${SERVICE_STATUS[cloudflare]}")
    echo -e "                       ${cf_color}${cf_icon}${RESET} ${BOLD}Cloudflare${RESET} ${TEXT_MUTED}(Load Balancer)${RESET}"
    echo -e "                                ${TEXT_MUTED}│${RESET}"
    local cf_api_health="${CONNECTION_HEALTH[cloudflare->api]}"
    local cf_api_line=$(get_connection_line "$cf_api_health")
    echo -e "                                $cf_api_line ${TEXT_MUTED}$cf_api_health%${RESET}"
    echo -e "                                ${TEXT_MUTED}│${RESET}"
    echo -e "                                ${TEXT_MUTED}▼${RESET}"
    echo ""

    # Layer 3: Application
    echo -e "  ${TEXT_MUTED}[Layer 3: Application]${RESET}"
    echo ""
    local api_color=$(get_status_color "${SERVICE_STATUS[api]}")
    local api_icon=$(get_status_icon "${SERVICE_STATUS[api]}")
    echo -e "                          ${api_color}${api_icon}${RESET} ${BOLD}API Server${RESET}"
    echo -e "                    ${TEXT_MUTED}┌─────────┼─────────┐${RESET}"
    echo -e "                    ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}"

    local api_db_health="${CONNECTION_HEALTH[api->database]}"
    local api_db_line=$(get_connection_line "$api_db_health")
    local api_redis_health="${CONNECTION_HEALTH[api->redis]}"
    local api_redis_line=$(get_connection_line "$api_redis_health")
    local api_worker_health="${CONNECTION_HEALTH[api->worker]}"
    local api_worker_line=$(get_connection_line "$api_worker_health")

    echo -e "              $api_db_line${TEXT_MUTED}$api_db_health%${RESET}  $api_redis_line${TEXT_MUTED}$api_redis_health%${RESET}  $api_worker_line${TEXT_MUTED}$api_worker_health%${RESET}"
    echo -e "                    ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}"
    echo -e "                    ${TEXT_MUTED}▼${RESET}         ${TEXT_MUTED}▼${RESET}         ${TEXT_MUTED}▼${RESET}"
    echo ""

    # Layer 4: Data & Services
    echo -e "  ${TEXT_MUTED}[Layer 4: Data & Services]${RESET}"
    echo ""
    local db_color=$(get_status_color "${SERVICE_STATUS[database]}")
    local db_icon=$(get_status_icon "${SERVICE_STATUS[database]}")
    local redis_color=$(get_status_color "${SERVICE_STATUS[redis]}")
    local redis_icon=$(get_status_icon "${SERVICE_STATUS[redis]}")
    local worker_color=$(get_status_color "${SERVICE_STATUS[worker]}")
    local worker_icon=$(get_status_icon "${SERVICE_STATUS[worker]}")

    echo -e "            ${db_color}${db_icon}${RESET} ${BOLD}PostgreSQL${RESET}  ${redis_color}${redis_icon}${RESET} ${BOLD}Redis${RESET}      ${worker_color}${worker_icon}${RESET} ${BOLD}Worker${RESET}"
    echo -e "                    ${TEXT_MUTED}│${RESET}                     ${TEXT_MUTED}│${RESET}"

    local worker_db_health="${CONNECTION_HEALTH[worker->database]}"
    local worker_db_line=$(get_connection_line "$worker_db_health")

    echo -e "                    ${TEXT_MUTED}│${RESET}         $worker_db_line${TEXT_MUTED}$worker_db_health%${RESET}"
    echo -e "                    ${TEXT_MUTED}│${RESET}         ${TEXT_MUTED}│${RESET}"
    echo -e "                    ${TEXT_MUTED}└─────────┘${RESET}"
    echo ""

    # Monitoring & Backup (side services)
    echo -e "  ${TEXT_MUTED}[Side Services]${RESET}"
    echo ""
    local mon_color=$(get_status_color "${SERVICE_STATUS[monitoring]}")
    local mon_icon=$(get_status_icon "${SERVICE_STATUS[monitoring]}")
    local backup_color=$(get_status_color "${SERVICE_STATUS[backup]}")
    local backup_icon=$(get_status_icon "${SERVICE_STATUS[backup]}")

    local mon_api_health="${CONNECTION_HEALTH[monitoring->api]}"
    local mon_api_line=$(get_connection_line "$mon_api_health")
    local backup_db_health="${CONNECTION_HEALTH[backup->database]}"
    local backup_db_line=$(get_connection_line "$backup_db_health")

    echo -e "  ${mon_color}${mon_icon}${RESET} ${BOLD}Monitoring${RESET} $mon_api_line${TEXT_MUTED}$mon_api_health%${RESET}${TEXT_MUTED}→ API${RESET}"
    echo -e "  ${backup_color}${backup_icon}${RESET} ${BOLD}Backup${RESET}     $backup_db_line${TEXT_MUTED}$backup_db_health%${RESET}${TEXT_MUTED}→ DB${RESET}"
    echo ""
}

# Show connection details
show_connection_details() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}CONNECTION HEALTH DETAILS${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ALL CONNECTIONS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    for conn in "${!CONNECTION_HEALTH[@]}"; do
        local health="${CONNECTION_HEALTH[$conn]}"
        local from=$(echo "$conn" | cut -d'>' -f1)
        local to=$(echo "$conn" | cut -d'>' -f2)
        local line=$(get_connection_line "$health")

        local status
        if [ "$health" -ge 90 ]; then
            status="${GREEN}${BOLD}EXCELLENT${RESET}"
        elif [ "$health" -ge 70 ]; then
            status="${YELLOW}${BOLD}GOOD${RESET}"
        elif [ "$health" -ge 40 ]; then
            status="${ORANGE}${BOLD}DEGRADED${RESET}"
        else
            status="${RED}${BOLD}CRITICAL${RESET}"
        fi

        echo -e "  ${BOLD}$from${RESET} $line ${BOLD}$to${RESET}"
        echo -e "     Health: ${BOLD}$health%${RESET}  Status: $status"
        echo ""
    done

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Show service details
show_service_details() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}SERVICE STATUS DETAILS${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ALL SERVICES ────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    for service in "${!SERVICE_STATUS[@]}"; do
        local status="${SERVICE_STATUS[$service]}"
        local color=$(get_status_color "$status")
        local icon=$(get_status_icon "$status")

        echo -e "  $color$icon${RESET} ${BOLD}$service${RESET}"
        echo -e "     Status: $color${BOLD}${status^^}${RESET}"

        # Show connected services
        local connections=0
        for conn in "${!CONNECTION_HEALTH[@]}"; do
            if [[ "$conn" =~ ^$service\-\> ]]; then
                local to=$(echo "$conn" | cut -d'>' -f2)
                local health="${CONNECTION_HEALTH[$conn]}"
                echo -e "     ${TEXT_MUTED}→ $to ($health%)${RESET}"
                ((connections++))
            fi
        done

        [ "$connections" -eq 0 ] && echo -e "     ${TEXT_MUTED}No outgoing connections${RESET}"
        echo ""
    done

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Show metrics
show_metrics() {
    echo -e "${TEXT_MUTED}╭─ NETWORK METRICS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Calculate metrics
    local total_services=${#SERVICE_STATUS[@]}
    local online_count=0
    local warning_count=0
    local error_count=0

    for status in "${SERVICE_STATUS[@]}"; do
        case "$status" in
            "online") ((online_count++)) ;;
            "warning") ((warning_count++)) ;;
            "error") ((error_count++)) ;;
        esac
    done

    local total_connections=${#CONNECTION_HEALTH[@]}
    local healthy_connections=0
    local degraded_connections=0
    local critical_connections=0

    for health in "${CONNECTION_HEALTH[@]}"; do
        if [ "$health" -ge 70 ]; then
            ((healthy_connections++))
        elif [ "$health" -ge 40 ]; then
            ((degraded_connections++))
        else
            ((critical_connections++))
        fi
    done

    echo -e "  ${BOLD}${TEXT_PRIMARY}Services:${RESET}"
    echo -e "    ${GREEN}●${RESET} Online:  ${BOLD}${GREEN}$online_count${RESET} / $total_services"
    echo -e "    ${YELLOW}◐${RESET} Warning: ${BOLD}${YELLOW}$warning_count${RESET} / $total_services"
    echo -e "    ${RED}○${RESET} Error:   ${BOLD}${RED}$error_count${RESET} / $total_services"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Connections:${RESET}"
    echo -e "    ${GREEN}━━━${RESET} Healthy:  ${BOLD}${GREEN}$healthy_connections${RESET} / $total_connections"
    echo -e "    ${ORANGE}┄┄┄${RESET} Degraded: ${BOLD}${ORANGE}$degraded_connections${RESET} / $total_connections"
    echo -e "    ${RED}╌╌╌${RESET} Critical: ${BOLD}${RED}$critical_connections${RESET} / $total_connections"
    echo ""

    # Overall health score
    local health_score=$(( (online_count * 100 / total_services + healthy_connections * 100 / total_connections) / 2 ))
    echo -e "  ${BOLD}${TEXT_PRIMARY}Overall Health Score:${RESET} ${BOLD}"
    if [ "$health_score" -ge 80 ]; then
        echo -e "${GREEN}$health_score/100${RESET}"
    elif [ "$health_score" -ge 60 ]; then
        echo -e "${YELLOW}$health_score/100${RESET}"
    else
        echo -e "${RED}$health_score/100${RESET}"
    fi
    echo ""
}

# Main dashboard
main() {
    while true; do
        render_network_graph
        show_metrics

        echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${TEXT_SECONDARY}[C]${RESET} Connections  ${TEXT_SECONDARY}[S]${RESET} Services  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[Q]${RESET} Quit"
        echo ""

        read -n1 key

        case "$key" in
            'c'|'C')
                show_connection_details
                ;;
            's'|'S')
                show_service_details
                ;;
            'r'|'R')
                continue
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
