#!/bin/bash

# BlackRoad OS - Interactive Drill-Down System
# Click numbers to drill into stats and see detailed views

source ~/blackroad-dashboards/themes.sh
load_theme

# State
DRILL_LEVEL=0
DRILL_CONTEXT=""
DRILL_DATA=""

# Drill-down handler
handle_drilldown() {
    local selection=$1
    local context=$2

    case "$context" in
        "docker")
            case $selection in
                1) show_container_details "lucidia-earth" ;;
                2) show_container_details "docs-blackroad" ;;
                3) show_container_details "blackroadinc-us" ;;
                *) return ;;
            esac
            ;;
        "api")
            case $selection in
                1) show_endpoint_details "/api/v1/data" ;;
                2) show_endpoint_details "/api/v1/auth" ;;
                3) show_endpoint_details "/api/v1/users" ;;
                *) return ;;
            esac
            ;;
        "database")
            case $selection in
                1) show_table_details "deployments" ;;
                2) show_table_details "agents" ;;
                3) show_table_details "memory_entries" ;;
                *) return ;;
            esac
            ;;
    esac
}

# Container details drill-down
show_container_details() {
    local container=$1
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${BLUE}🐳${RESET} ${BOLD}CONTAINER DETAILS: $container${RESET}                                ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ OVERVIEW ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Container:${RESET}     ${ORANGE}$container${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}        ${GREEN}RUNNING${RESET} ${TEXT_MUTED}(3 hours)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Image:${RESET}         ${CYAN}next.js:latest${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Port:${RESET}          ${PURPLE}3040 → 3000${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RESOURCE USAGE ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}CPU Usage${RESET}"
    echo -e "    ${TEXT_MUTED}Current:${RESET}  ${ORANGE}████████████${RESET}                    ${BOLD}12%${RESET}"
    echo -e "    ${TEXT_MUTED}Average:${RESET}  ${ORANGE}██████${RESET}                          ${BOLD}8%${RESET}"
    echo -e "    ${TEXT_MUTED}Peak:${RESET}     ${ORANGE}████████████████${RESET}                ${BOLD}23%${RESET}"
    echo ""
    echo -e "  ${PINK}Memory Usage${RESET}"
    echo -e "    ${TEXT_MUTED}Current:${RESET}  ${PINK}████████████████${RESET}                ${BOLD}256 MB${RESET}"
    echo -e "    ${TEXT_MUTED}Limit:${RESET}    ${TEXT_MUTED}████████████████████████${RESET}    ${BOLD}512 MB${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ NETWORK TRAFFIC (Last Hour) ─────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}▼ Inbound${RESET}   ${GREEN}████████████████████${RESET}     ${BOLD}${GREEN}1.2 GB${RESET}"
    echo -e "  ${ORANGE}▲ Outbound${RESET}  ${ORANGE}████████████${RESET}             ${BOLD}${ORANGE}847 MB${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Requests/min:${RESET} ${BOLD}${CYAN}234${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ LOGS (Last 10 Lines) ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[14:23:12]${RESET} ${GREEN}INFO${RESET}  Request processed: GET /"
    echo -e "  ${TEXT_MUTED}[14:23:15]${RESET} ${GREEN}INFO${RESET}  Cache hit for route: /api/data"
    echo -e "  ${TEXT_MUTED}[14:23:18]${RESET} ${CYAN}DEBUG${RESET} Database query completed in 23ms"
    echo -e "  ${TEXT_MUTED}[14:23:21]${RESET} ${GREEN}INFO${RESET}  Static file served: /assets/logo.png"
    echo -e "  ${TEXT_MUTED}[14:23:24]${RESET} ${YELLOW}WARN${RESET}  Slow query detected (145ms)"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ACTIONS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} Restart container"
    echo -e "  ${PINK}2)${RESET} View full logs"
    echo -e "  ${PURPLE}3)${RESET} Shell access"
    echo -e "  ${CYAN}4)${RESET} Export metrics"
    echo ""
    echo -e "  ${TEXT_MUTED}ESC)${RESET} Back to overview"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -ne "${TEXT_PRIMARY}Select action [1-4, ESC]: ${RESET}"

    read -n1 choice
    case "$choice" in
        $'\x1b') return ;;
        1) restart_container "$container" ;;
        2) view_full_logs "$container" ;;
        3) shell_access "$container" ;;
        4) export_metrics "$container" ;;
    esac
}

# API Endpoint details drill-down
show_endpoint_details() {
    local endpoint=$1
    clear
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${ORANGE}🔌${RESET} ${BOLD}ENDPOINT DETAILS: $endpoint${RESET}                             ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ PERFORMANCE METRICS ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Requests/min:${RESET}      ${BOLD}${ORANGE}12,400${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Response:${RESET}      ${BOLD}${CYAN}23ms${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}P95 Latency:${RESET}       ${BOLD}${PURPLE}89ms${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Error Rate:${RESET}        ${BOLD}${GREEN}0.01%${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RESPONSE TIME DISTRIBUTION ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}<10ms${RESET}    ${GREEN}██████████${RESET}                      ${BOLD}45%${RESET}"
    echo -e "  ${CYAN}10-50ms${RESET}  ${CYAN}████████████████████${RESET}            ${BOLD}38%${RESET}"
    echo -e "  ${YELLOW}50-100ms${RESET} ${YELLOW}████████${RESET}                        ${BOLD}12%${RESET}"
    echo -e "  ${ORANGE}>100ms${RESET}   ${ORANGE}████${RESET}                            ${BOLD}5%${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ STATUS CODE BREAKDOWN ───────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}200 OK${RESET}           ${GREEN}████████████████████████████${RESET}  ${BOLD}98.5%${RESET}"
    echo -e "  ${CYAN}304 Not Modified${RESET} ${CYAN}██${RESET}                            ${BOLD}1.2%${RESET}"
    echo -e "  ${YELLOW}404 Not Found${RESET}    ${YELLOW}█${RESET}                             ${BOLD}0.2%${RESET}"
    echo -e "  ${RED}500 Error${RESET}        ${RED}${RESET}                              ${BOLD}0.1%${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RECENT ERRORS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}●${RESET} ${TEXT_MUTED}[14:15:23]${RESET} ${RED}500${RESET} Internal Error - Database timeout"
    echo -e "  ${YELLOW}●${RESET} ${TEXT_MUTED}[13:42:18]${RESET} ${YELLOW}404${RESET} Not Found - /api/v1/missing"
    echo -e "  ${YELLOW}●${RESET} ${TEXT_MUTED}[12:33:45]${RESET} ${YELLOW}401${RESET} Unauthorized - Invalid token"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ACTIONS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} View request timeline"
    echo -e "  ${PINK}2)${RESET} Export metrics"
    echo -e "  ${PURPLE}3)${RESET} Set up alert"
    echo ""
    echo -e "  ${TEXT_MUTED}ESC)${RESET} Back to overview"
    echo ""

    read -n1 choice
    case "$choice" in
        $'\x1b') return ;;
    esac
}

# Table details drill-down
show_table_details() {
    local table=$1
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}💾${RESET} ${BOLD}TABLE DETAILS: $table${RESET}                                       ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ TABLE INFO ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Rows:${RESET}        ${BOLD}${ORANGE}234,567${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Table Size:${RESET}        ${BOLD}${CYAN}89.4 MB${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Indexes:${RESET}           ${BOLD}${PURPLE}5${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Last Updated:${RESET}      ${BOLD}${GREEN}2 minutes ago${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ QUERY PERFORMANCE ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}Slow Queries (>100ms):${RESET}"
    echo -e "    ${PINK}1.${RESET} ${TEXT_SECONDARY}SELECT * WHERE created_at > ...${RESET}  ${BOLD}${ORANGE}234ms${RESET}"
    echo -e "    ${PINK}2.${RESET} ${TEXT_SECONDARY}JOIN memory_entries ON ...${RESET}       ${BOLD}${ORANGE}189ms${RESET}"
    echo ""
    echo -e "  ${GREEN}Fast Queries (<10ms):${RESET}"
    echo -e "    ${CYAN}●${RESET} ${TEXT_SECONDARY}SELECT * WHERE id = ...${RESET}          ${BOLD}${GREEN}3ms${RESET}"
    echo -e "    ${CYAN}●${RESET} ${TEXT_SECONDARY}COUNT(*) ...${RESET}                      ${BOLD}${GREEN}7ms${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RECENT ROWS (Last 5) ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}ID${RESET}      ${PINK}Name${RESET}                  ${PURPLE}Status${RESET}      ${CYAN}Created${RESET}"
    echo -e "  ${TEXT_MUTED}───────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}847${RESET}     Terminal Dashboards   ${GREEN}Active${RESET}      2m ago"
    echo -e "  ${BOLD}846${RESET}     Crypto Dashboard       ${GREEN}Active${RESET}      3m ago"
    echo -e "  ${BOLD}845${RESET}     Memory System          ${GREEN}Active${RESET}      4m ago"
    echo -e "  ${BOLD}844${RESET}     API Gateway            ${RED}Failed${RESET}      5m ago"
    echo -e "  ${BOLD}843${RESET}     Docker Fleet           ${GREEN}Active${RESET}      6m ago"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ACTIONS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} View schema"
    echo -e "  ${PINK}2)${RESET} Run custom query"
    echo -e "  ${PURPLE}3)${RESET} Export table"
    echo ""
    echo -e "  ${TEXT_MUTED}ESC)${RESET} Back to overview"
    echo ""

    read -n1 choice
    case "$choice" in
        $'\x1b') return ;;
    esac
}

# Helper actions
restart_container() {
    echo -e "\n${ORANGE}Restarting container...${RESET}"
    sleep 1
    echo -e "${GREEN}✓ Container restarted!${RESET}"
    sleep 2
}

view_full_logs() {
    echo -e "\n${CYAN}Opening full logs...${RESET}"
    sleep 2
}

shell_access() {
    echo -e "\n${PURPLE}Opening shell access...${RESET}"
    sleep 2
}

export_metrics() {
    local target=$1
    echo -e "\n${PINK}Exporting metrics for $target...${RESET}"
    sleep 1
    echo -e "${GREEN}✓ Exported to ~/blackroad-exports/$(date +%Y%m%d_%H%M%S)_${target}.json${RESET}"
    sleep 2
}

# Demo menu
show_demo_menu() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${PURPLE}🎯${RESET} ${BOLD}INTERACTIVE DRILL-DOWN DEMO${RESET}                                       ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "  ${TEXT_PRIMARY}Click on any number to drill into details:${RESET}"
    echo ""
    echo "  ${ORANGE}1)${RESET} Docker Container Details ${TEXT_MUTED}(lucidia-earth)${RESET}"
    echo "  ${PINK}2)${RESET} API Endpoint Details ${TEXT_MUTED}(/api/v1/data)${RESET}"
    echo "  ${PURPLE}3)${RESET} Database Table Details ${TEXT_MUTED}(deployments)${RESET}"
    echo ""
    echo "  ${TEXT_MUTED}0)${RESET} Exit"
    echo ""
    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -ne "${TEXT_PRIMARY}Select [1-3]: ${RESET}"

    read -n1 choice
    echo ""

    case "$choice" in
        1) show_container_details "lucidia-earth" ;;
        2) show_endpoint_details "/api/v1/data" ;;
        3) show_table_details "deployments" ;;
        0) exit 0 ;;
    esac

    show_demo_menu
}

# Run demo
show_demo_menu
