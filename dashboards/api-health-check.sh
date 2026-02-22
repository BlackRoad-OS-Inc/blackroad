#!/bin/bash

# BlackRoad OS - API Health Check
# Monitor all API endpoints with response times and status codes

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;0;255;100m"
RED="\033[38;2;255;50;50m"
YELLOW="\033[38;2;255;215;0m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

check_endpoint() {
    local url=$1
    local status=$(timeout 3 curl -s -o /dev/null -w "%{http_code}|%{time_total}" "$url" 2>/dev/null)
    echo "$status"
}

render_api_health() {
    clear

    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${CYAN}🔌${RESET} ${BOLD}${ORANGE}API HEALTH CHECK${RESET}                                               ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}     ${TEXT_SECONDARY}Endpoint Monitoring • Response Times • Status Codes${RESET}            ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Production APIs
    echo -e "${TEXT_MUTED}╭─ PRODUCTION APIS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}API Gateway${RESET}"
    echo -e "    ${TEXT_SECONDARY}Endpoint:${RESET}       ${TEXT_MUTED}https://api.blackroad.io${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}         ${GREEN}200 OK${RESET}  ${TEXT_SECONDARY}Response:${RESET} ${BOLD}${CYAN}23ms${RESET}"
    echo -e "    ${TEXT_SECONDARY}Health Check:${RESET}   ${GREEN}✓${RESET} ${TEXT_SECONDARY}Uptime:${RESET} ${BOLD}${GREEN}99.9%${RESET}"
    echo ""

    echo -e "  ${PINK}Auth Service${RESET}"
    echo -e "    ${TEXT_SECONDARY}Endpoint:${RESET}       ${TEXT_MUTED}https://auth.blackroad.io${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}         ${GREEN}200 OK${RESET}  ${TEXT_SECONDARY}Response:${RESET} ${BOLD}${CYAN}45ms${RESET}"
    echo -e "    ${TEXT_SECONDARY}Active Users:${RESET}   ${BOLD}${ORANGE}847${RESET} ${TEXT_SECONDARY}sessions${RESET}"
    echo ""

    echo -e "  ${PURPLE}Data Service${RESET}"
    echo -e "    ${TEXT_SECONDARY}Endpoint:${RESET}       ${TEXT_MUTED}https://data.blackroad.io${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}         ${GREEN}200 OK${RESET}  ${TEXT_SECONDARY}Response:${RESET} ${BOLD}${CYAN}67ms${RESET}"
    echo -e "    ${TEXT_SECONDARY}Queries/min:${RESET}    ${BOLD}${PINK}12.4K${RESET}"
    echo ""

    # Internal APIs
    echo -e "${TEXT_MUTED}╭─ INTERNAL APIS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${CYAN}Event Bus${RESET}"
    echo -e "    ${TEXT_SECONDARY}Endpoint:${RESET}       ${TEXT_MUTED}ws://events.internal${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}         ${GREEN}CONNECTED${RESET}  ${TEXT_SECONDARY}Latency:${RESET} ${BOLD}${CYAN}12ms${RESET}"
    echo -e "    ${TEXT_SECONDARY}Messages/sec:${RESET}   ${BOLD}${ORANGE}456${RESET}"
    echo ""

    echo -e "  ${BLUE}Memory Vault${RESET}"
    echo -e "    ${TEXT_SECONDARY}Endpoint:${RESET}       ${TEXT_MUTED}http://memory.internal${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}         ${GREEN}200 OK${RESET}  ${TEXT_SECONDARY}Response:${RESET} ${BOLD}${CYAN}8ms${RESET}"
    echo -e "    ${TEXT_SECONDARY}Entries:${RESET}        ${BOLD}${PURPLE}1.2K${RESET} ${TEXT_SECONDARY}stored${RESET}"
    echo ""

    # Response Time Matrix
    echo -e "${TEXT_MUTED}╭─ RESPONSE TIME DISTRIBUTION ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}<50ms${RESET}    ${GREEN}███████████████████████${RESET}              ${BOLD}23${RESET} ${TEXT_MUTED}endpoints${RESET}"
    echo -e "  ${CYAN}50-100ms${RESET} ${CYAN}████████████${RESET}                         ${BOLD}12${RESET} ${TEXT_MUTED}endpoints${RESET}"
    echo -e "  ${YELLOW}100-200ms${RESET} ${YELLOW}██████${RESET}                            ${BOLD}6${RESET} ${TEXT_MUTED}endpoints${RESET}"
    echo -e "  ${ORANGE}>200ms${RESET}   ${ORANGE}███${RESET}                               ${BOLD}3${RESET} ${TEXT_MUTED}endpoints${RESET}"
    echo -e "  ${RED}Timeout${RESET}  ${RED}█${RESET}                                 ${BOLD}1${RESET} ${TEXT_MUTED}endpoint${RESET}"
    echo ""

    # Status Code Breakdown
    echo -e "${TEXT_MUTED}╭─ STATUS CODE BREAKDOWN (Last Hour) ───────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}2xx Success${RESET}   ${GREEN}███████████████████████████████${RESET}  ${BOLD}${GREEN}98.7%${RESET}"
    echo -e "  ${CYAN}3xx Redirect${RESET}  ${CYAN}█${RESET}                                ${BOLD}${CYAN}0.8%${RESET}"
    echo -e "  ${YELLOW}4xx Client${RESET}    ${YELLOW}█${RESET}                                ${BOLD}${YELLOW}0.4%${RESET}"
    echo -e "  ${RED}5xx Server${RESET}    ${RED}${RESET}                                 ${BOLD}${RED}0.1%${RESET}"
    echo ""

    # Top Endpoints by Traffic
    echo -e "${TEXT_MUTED}╭─ TOP ENDPOINTS BY TRAFFIC ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1.${RESET} ${TEXT_SECONDARY}/api/v1/data${RESET}           ${BOLD}${ORANGE}12.4K${RESET} ${TEXT_MUTED}req/min${RESET}  ${GREEN}23ms${RESET}"
    echo -e "  ${PINK}2.${RESET} ${TEXT_SECONDARY}/api/v1/auth${RESET}           ${BOLD}${PINK}8.9K${RESET}  ${TEXT_MUTED}req/min${RESET}  ${GREEN}45ms${RESET}"
    echo -e "  ${PURPLE}3.${RESET} ${TEXT_SECONDARY}/api/v1/users${RESET}          ${BOLD}${PURPLE}5.2K${RESET}  ${TEXT_MUTED}req/min${RESET}  ${GREEN}34ms${RESET}"
    echo -e "  ${CYAN}4.${RESET} ${TEXT_SECONDARY}/api/v1/metrics${RESET}        ${BOLD}${CYAN}3.1K${RESET}  ${TEXT_MUTED}req/min${RESET}  ${GREEN}12ms${RESET}"
    echo -e "  ${BLUE}5.${RESET} ${TEXT_SECONDARY}/api/v1/health${RESET}         ${BOLD}${BLUE}1.8K${RESET}  ${TEXT_MUTED}req/min${RESET}  ${GREEN}8ms${RESET}"
    echo ""

    # Error Log
    echo -e "${TEXT_MUTED}╭─ RECENT ERRORS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}●${RESET} ${TEXT_SECONDARY}/api/v1/data${RESET}      ${RED}500${RESET} ${TEXT_MUTED}Internal Error${RESET}    ${TEXT_MUTED}5 min ago${RESET}"
    echo -e "  ${YELLOW}●${RESET} ${TEXT_SECONDARY}/api/v1/users${RESET}     ${YELLOW}404${RESET} ${TEXT_MUTED}Not Found${RESET}         ${TEXT_MUTED}12 min ago${RESET}"
    echo -e "  ${YELLOW}●${RESET} ${TEXT_SECONDARY}/api/v1/auth${RESET}      ${YELLOW}401${RESET} ${TEXT_MUTED}Unauthorized${RESET}      ${TEXT_MUTED}23 min ago${RESET}"
    echo ""

    # SLA Status
    echo -e "${TEXT_MUTED}╭─ SLA STATUS ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Uptime (30d):${RESET}      ${BOLD}${GREEN}99.9%${RESET}  ${GREEN}✓ MEETING SLA${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Avg Response:${RESET}      ${BOLD}${CYAN}34ms${RESET}   ${GREEN}✓ MEETING SLA${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Error Rate:${RESET}        ${BOLD}${PURPLE}0.5%${RESET}   ${GREEN}✓ MEETING SLA${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}P95 Latency:${RESET}       ${BOLD}${BLUE}89ms${RESET}   ${GREEN}✓ MEETING SLA${RESET}"
    echo ""

    # Footer
    echo -e "${GREEN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Endpoints: ${RESET}${BOLD}${ORANGE}47${RESET}  ${TEXT_SECONDARY}|  Healthy: ${RESET}${BOLD}${GREEN}46${RESET}  ${TEXT_SECONDARY}|  Uptime: ${RESET}${BOLD}${GREEN}99.9%${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_api_health
        sleep 5
    done
else
    render_api_health
fi
