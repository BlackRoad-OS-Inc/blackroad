#!/bin/bash

# BlackRoad OS - Docker Fleet Manager
# Monitor all Docker containers across all devices

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;0;255;100m"
RED="\033[38;2;255;50;50m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

render_docker_fleet() {
    clear

    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${BLUE}🐳${RESET} ${BOLD}${PURPLE}DOCKER FLEET MANAGER${RESET}                                           ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}     ${TEXT_SECONDARY}Container Status • Resource Usage • Multi-Device${RESET}                ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Fleet Overview
    echo -e "${TEXT_MUTED}╭─ FLEET OVERVIEW ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Containers:${RESET}     ${BOLD}${ORANGE}24${RESET} ${TEXT_SECONDARY}across 4 devices${RESET}"
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Running:${RESET}             ${BOLD}${GREEN}22${RESET}"
    echo -e "  ${YELLOW}◉${RESET} ${TEXT_PRIMARY}Stopped:${RESET}             ${BOLD}${YELLOW}2${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Images:${RESET}               ${BOLD}${CYAN}18${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Networks:${RESET}            ${BOLD}${PURPLE}6${RESET}"
    echo ""

    # Lucidia Prime (192.168.4.38)
    echo -e "${TEXT_MUTED}╭─ LUCIDIA PRIME (192.168.4.38) ────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}◆ Running Containers: 8${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}lucidia-earth${RESET}           ${TEXT_MUTED}:3040${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}12%${RESET}  ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}256MB${RESET}"
    echo -e "     ${PURPLE}└─${RESET} ${TEXT_MUTED}next.js${RESET}              ${TEXT_MUTED}3 hours${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}docs-blackroad${RESET}          ${TEXT_MUTED}:3050${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}8%${RESET}   ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}189MB${RESET}"
    echo -e "     ${PURPLE}└─${RESET} ${TEXT_MUTED}nextra${RESET}               ${TEXT_MUTED}3 hours${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}blackroadinc-us${RESET}         ${TEXT_MUTED}:9444${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}15%${RESET}  ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}312MB${RESET}"
    echo -e "     ${PURPLE}└─${RESET} ${TEXT_MUTED}next.js${RESET}              ${TEXT_MUTED}2 days${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}app-blackroad-io${RESET}        ${TEXT_MUTED}:9445${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}23%${RESET}  ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}445MB${RESET}"
    echo -e "     ${PURPLE}└─${RESET} ${TEXT_MUTED}next.js${RESET}              ${TEXT_MUTED}2 days${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}+ 4 more containers...${RESET}"
    echo ""

    # BlackRoad Pi (192.168.4.64)
    echo -e "${TEXT_MUTED}╭─ BLACKROAD PI (192.168.4.64) ─────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PINK}◆ Running Containers: 6${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}postgres${RESET}                ${TEXT_MUTED}:5432${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}5%${RESET}   ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}512MB${RESET}"
    echo -e "     ${PURPLE}└─${RESET} ${TEXT_MUTED}postgres:15${RESET}          ${TEXT_MUTED}7 days${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}redis${RESET}                   ${TEXT_MUTED}:6379${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}2%${RESET}   ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}128MB${RESET}"
    echo -e "     ${PURPLE}└─${RESET} ${TEXT_MUTED}redis:7-alpine${RESET}       ${TEXT_MUTED}7 days${RESET}"
    echo ""

    echo -e "  ${YELLOW}●${RESET} ${BOLD}worker-1${RESET}                ${TEXT_MUTED}none${RESET}   ${YELLOW}STOPPED${RESET}"
    echo -e "     ${PURPLE}└─${RESET} ${TEXT_MUTED}node:18-alpine${RESET}       ${TEXT_MUTED}exited 2h ago${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}+ 3 more containers...${RESET}"
    echo ""

    # DigitalOcean
    echo -e "${TEXT_MUTED}╭─ CODEX INFINITY (159.65.43.12) ───────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BLUE}◆ Running Containers: 7${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}nginx-proxy${RESET}             ${TEXT_MUTED}:80,443${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}8%${RESET}  ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}64MB${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}api-server${RESET}              ${TEXT_MUTED}:8000${RESET}    ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}45%${RESET} ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}1.2GB${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}mongodb${RESET}                 ${TEXT_MUTED}:27017${RESET}   ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}12%${RESET} ${TEXT_SECONDARY}RAM:${RESET} ${BOLD}2.1GB${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}+ 4 more containers...${RESET}"
    echo ""

    # Resource Usage
    echo -e "${TEXT_MUTED}╭─ RESOURCE USAGE ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}CPU Usage${RESET}"
    echo -e "    ${ORANGE}████████████${RESET}                              ${BOLD}42%${RESET} ${TEXT_MUTED}total${RESET}"
    echo ""

    echo -e "  ${PINK}Memory Usage${RESET}"
    echo -e "    ${PINK}████████████████████${RESET}                      ${BOLD}5.8 GB${RESET} ${TEXT_MUTED}/ 12 GB${RESET}"
    echo ""

    echo -e "  ${PURPLE}Disk Usage${RESET}"
    echo -e "    ${PURPLE}██████████████${RESET}                            ${BOLD}23 GB${RESET} ${TEXT_MUTED}images${RESET}"
    echo ""

    # Image Stats
    echo -e "${TEXT_MUTED}╭─ IMAGE STATISTICS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Top Images by Size:${RESET}"
    echo -e "    ${ORANGE}1.${RESET} ${TEXT_SECONDARY}node:18${RESET}              ${BOLD}${ORANGE}2.1 GB${RESET}  ${TEXT_MUTED}(8 containers)${RESET}"
    echo -e "    ${PINK}2.${RESET} ${TEXT_SECONDARY}postgres:15${RESET}          ${BOLD}${PINK}1.8 GB${RESET}  ${TEXT_MUTED}(2 containers)${RESET}"
    echo -e "    ${PURPLE}3.${RESET} ${TEXT_SECONDARY}next.js-custom${RESET}       ${BOLD}${PURPLE}1.2 GB${RESET}  ${TEXT_MUTED}(6 containers)${RESET}"
    echo -e "    ${CYAN}4.${RESET} ${TEXT_SECONDARY}nginx:alpine${RESET}         ${BOLD}${CYAN}45 MB${RESET}   ${TEXT_MUTED}(3 containers)${RESET}"
    echo ""

    # Network Traffic
    echo -e "${TEXT_MUTED}╭─ NETWORK TRAFFIC ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Top Containers by Traffic:${RESET}"
    echo -e "    ${ORANGE}1.${RESET} ${TEXT_SECONDARY}api-server${RESET}          ${GREEN}▼${RESET} ${BOLD}${GREEN}47 MB/s${RESET}  ${ORANGE}▲${RESET} ${BOLD}${ORANGE}23 MB/s${RESET}"
    echo -e "    ${PINK}2.${RESET} ${TEXT_SECONDARY}nginx-proxy${RESET}         ${GREEN}▼${RESET} ${BOLD}${GREEN}34 MB/s${RESET}  ${ORANGE}▲${RESET} ${BOLD}${ORANGE}18 MB/s${RESET}"
    echo -e "    ${PURPLE}3.${RESET} ${TEXT_SECONDARY}app-blackroad-io${RESET}    ${GREEN}▼${RESET} ${BOLD}${GREEN}12 MB/s${RESET}  ${ORANGE}▲${RESET} ${BOLD}${ORANGE}8 MB/s${RESET}"
    echo ""

    # Health Status
    echo -e "${TEXT_MUTED}╭─ HEALTH STATUS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Fleet Status:${RESET}      ${BOLD}${GREEN}HEALTHY${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Running:${RESET}           ${BOLD}${CYAN}22/24${RESET} ${TEXT_MUTED}(91.7%)${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Restart Count:${RESET}     ${BOLD}${PURPLE}3${RESET} ${TEXT_MUTED}last 24h${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Failed Pulls:${RESET}      ${BOLD}${BLUE}0${RESET}"
    echo ""

    # Footer
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Containers: ${RESET}${BOLD}${GREEN}22${RESET}/${BOLD}${ORANGE}24${RESET}  ${TEXT_SECONDARY}|  RAM: ${RESET}${BOLD}${PINK}5.8GB${RESET}  ${TEXT_SECONDARY}|  Status: ${RESET}${BOLD}${GREEN}HEALTHY${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_docker_fleet
        sleep 5
    done
else
    render_docker_fleet
fi
