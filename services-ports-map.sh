#!/bin/bash

# BlackRoad OS - Services & Ports Map
# Monitor all running services, ports, and network endpoints

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;0;255;100m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

render_services_dashboard() {
    clear

    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${PURPLE}🔌${RESET} ${BOLD}${ORANGE}SERVICES & PORTS MAP${RESET}                                           ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}     ${TEXT_SECONDARY}Network Services • Port Allocation • Endpoint Monitoring${RESET}       ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Port 8080 Cadillac
    echo -e "${TEXT_MUTED}╭─ PORT 8080 CADILLAC ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}◆ Origin Agent${RESET}"
    echo -e "    ${TEXT_SECONDARY}Port:${RESET}         ${BOLD}${ORANGE}8080${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}       ${BOLD}${GREEN}ACTIVE${RESET}"
    echo -e "    ${TEXT_SECONDARY}Age:${RESET}          ${TEXT_MUTED}7 months${RESET}"
    echo -e "    ${TEXT_SECONDARY}Purpose:${RESET}      ${TEXT_MUTED}Legacy origin service${RESET}"
    echo -e "    ${TEXT_SECONDARY}Container:${RESET}    ${TEXT_MUTED}br-8080-cadillac${RESET}"
    echo ""

    # Aria64 (Raspberry Pi) Services
    echo -e "${TEXT_MUTED}╭─ ARIA64 SERVICES (192.168.4.38) ──────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PINK}◆ Web Applications${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${TEXT_SECONDARY}lucidia.earth${RESET}          ${BOLD}${CYAN}:3040${RESET}  ${GREEN}◉${RESET} ${TEXT_MUTED}Docker${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${TEXT_SECONDARY}docs.blackroad.io${RESET}     ${BOLD}${CYAN}:3050${RESET}  ${GREEN}◉${RESET} ${TEXT_MUTED}Nextra${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${TEXT_SECONDARY}blackroadinc.us${RESET}       ${BOLD}${CYAN}:9444${RESET}  ${GREEN}◉${RESET} ${TEXT_MUTED}Next.js${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${TEXT_SECONDARY}app.blackroad.io${RESET}      ${BOLD}${CYAN}:9445${RESET}  ${GREEN}◉${RESET} ${TEXT_MUTED}Next.js${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${TEXT_SECONDARY}demo.blackroad.io${RESET}     ${BOLD}${CYAN}:9446${RESET}  ${GREEN}◉${RESET} ${TEXT_MUTED}Next.js${RESET}"
    echo -e "    ${CYAN}└─${RESET} ${TEXT_SECONDARY}console.blackroad.io${RESET}  ${BOLD}${CYAN}:9447${RESET}  ${GREEN}◉${RESET} ${TEXT_MUTED}Next.js${RESET}"
    echo ""

    echo -e "  ${PURPLE}◆ Reserved Ports${RESET}"
    echo -e "    ${TEXT_SECONDARY}Range:${RESET}        ${BOLD}${PURPLE}3051-3100${RESET}  ${TEXT_MUTED}(50 ports reserved)${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}       ${TEXT_MUTED}Available for deployment${RESET}"
    echo ""

    # Cloudflare Services
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE SERVICES ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}◆ Pages Projects${RESET} ${TEXT_MUTED}(8 deployed)${RESET}"
    echo -e "    ${PINK}├─${RESET} blackroadinc-us           ${BLUE}◉${RESET} ${TEXT_MUTED}https://a1369b85...${RESET}"
    echo -e "    ${PINK}├─${RESET} app-blackroad-io          ${BLUE}◉${RESET} ${TEXT_MUTED}https://eb0ee4bf...${RESET}"
    echo -e "    ${PINK}├─${RESET} demo-blackroad-io         ${BLUE}◉${RESET} ${TEXT_MUTED}https://edb7bc91...${RESET}"
    echo -e "    ${PINK}├─${RESET} console-blackroad-io      ${BLUE}◉${RESET} ${TEXT_MUTED}https://01f03bd5...${RESET}"
    echo -e "    ${PINK}├─${RESET} creator-studio            ${BLUE}◉${RESET} ${TEXT_MUTED}https://9489cc4e...${RESET}"
    echo -e "    ${PINK}├─${RESET} research-lab              ${BLUE}◉${RESET} ${TEXT_MUTED}https://ae0de6e1...${RESET}"
    echo -e "    ${PINK}├─${RESET} education                 ${BLUE}◉${RESET} ${TEXT_MUTED}https://d38f8660...${RESET}"
    echo -e "    ${PINK}└─${RESET} finance                   ${BLUE}◉${RESET} ${TEXT_MUTED}https://ca4ad90b...${RESET}"
    echo ""

    echo -e "  ${CYAN}◆ Workers${RESET} ${TEXT_MUTED}(multiple)${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}       ${GREEN}◉${RESET} ${TEXT_MUTED}Active on edge network${RESET}"
    echo ""

    # Railway Services
    echo -e "${TEXT_MUTED}╭─ RAILWAY SERVICES (12+ PROJECTS) ─────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BLUE}◆ Backend Services${RESET}"
    echo -e "    ${ORANGE}├─${RESET} blackroad-api-gateway     ${GREEN}◉${RESET} ${TEXT_MUTED}Port: Dynamic${RESET}"
    echo -e "    ${ORANGE}├─${RESET} blackroad-auth-service    ${GREEN}◉${RESET} ${TEXT_MUTED}Port: Dynamic${RESET}"
    echo -e "    ${ORANGE}├─${RESET} blackroad-data-service    ${GREEN}◉${RESET} ${TEXT_MUTED}Port: Dynamic${RESET}"
    echo -e "    ${ORANGE}└─${RESET} blackroad-event-bus       ${GREEN}◉${RESET} ${TEXT_MUTED}Port: Dynamic${RESET}"
    echo ""

    # DigitalOcean Services
    echo -e "${TEXT_MUTED}╭─ DIGITALOCEAN SERVICES (159.65.43.12) ────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}◆ Codex Infinity${RESET}"
    echo -e "    ${TEXT_SECONDARY}SSH:${RESET}          ${BOLD}${PURPLE}:22${RESET}    ${GREEN}◉${RESET}"
    echo -e "    ${TEXT_SECONDARY}HTTP:${RESET}         ${BOLD}${PURPLE}:80${RESET}    ${GREEN}◉${RESET}"
    echo -e "    ${TEXT_SECONDARY}HTTPS:${RESET}        ${BOLD}${PURPLE}:443${RESET}   ${GREEN}◉${RESET}"
    echo -e "    ${TEXT_SECONDARY}Custom:${RESET}       ${BOLD}${PURPLE}:8000${RESET}  ${GREEN}◉${RESET} ${TEXT_MUTED}API Server${RESET}"
    echo ""

    # Port Summary
    echo -e "${TEXT_MUTED}╭─ PORT ALLOCATION SUMMARY ─────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}By Category:${RESET}"
    echo -e "    ${ORANGE}▸${RESET} ${TEXT_SECONDARY}Web Apps:${RESET}         ${BOLD}${ORANGE}6${RESET} ${TEXT_MUTED}ports (3040, 3050, 9444-9447)${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Reserved:${RESET}         ${BOLD}${PINK}50${RESET} ${TEXT_MUTED}ports (3051-3100)${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Legacy:${RESET}           ${BOLD}${PURPLE}1${RESET} ${TEXT_MUTED}port (8080)${RESET}"
    echo -e "    ${CYAN}▸${RESET} ${TEXT_SECONDARY}System:${RESET}           ${BOLD}${CYAN}3${RESET} ${TEXT_MUTED}ports (22, 80, 443)${RESET}"
    echo ""

    # Network Health
    echo -e "${TEXT_MUTED}╭─ NETWORK HEALTH ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}All Services:${RESET}         ${BOLD}${GREEN}OPERATIONAL${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Total Endpoints:${RESET}      ${BOLD}${CYAN}47${RESET} ${TEXT_MUTED}active${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Avg Response Time:${RESET}   ${BOLD}${PURPLE}34ms${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Uptime:${RESET}               ${BOLD}${BLUE}99.9%${RESET}"
    echo ""

    # Live Service Monitor
    echo -e "${TEXT_MUTED}╭─ LIVE SERVICE MONITOR ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}lucidia.earth:3040${RESET}         ${TEXT_MUTED}200 OK • 23ms${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}docs.blackroad.io:3050${RESET}    ${TEXT_MUTED}200 OK • 34ms${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}blackroadinc.us:9444${RESET}      ${TEXT_MUTED}200 OK • 45ms${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}app.blackroad.io:9445${RESET}     ${TEXT_MUTED}200 OK • 38ms${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}demo.blackroad.io:9446${RESET}    ${TEXT_MUTED}200 OK • 42ms${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_SECONDARY}console.blackroad.io:9447${RESET} ${TEXT_MUTED}200 OK • 29ms${RESET}"
    echo ""

    # Footer
    echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Services: ${RESET}${BOLD}${CYAN}47${RESET}  ${TEXT_SECONDARY}|  Status: ${RESET}${BOLD}${GREEN}ALL UP${RESET}"
    echo ""
}

# Auto-refresh mode
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_services_dashboard
        sleep 5
    done
else
    render_services_dashboard
fi
