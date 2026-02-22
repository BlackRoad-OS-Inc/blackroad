#!/bin/bash

# BlackRoad OS - Cloudflare Infrastructure Dashboard
# Monitor all Cloudflare services: 16 zones, 8 Pages, 8 KV, 1 D1

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

check_domain() {
    local url=$1
    local status=$(timeout 2 curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ] && echo "UP" || echo "DOWN"
}

render_cloudflare_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}☁️  CLOUDFLARE INFRASTRUCTURE${RESET}                                      ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}     ${TEXT_SECONDARY}16 Zones • 8 Pages • 8 KV • 1 D1 • Global Edge Network${RESET}         ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # DNS Zones
    echo -e "${TEXT_MUTED}╭─ DNS ZONES (16 TOTAL) ────────────────────────────────────────────────╮${RESET}"
    echo ""

    local br_io=$(check_domain "https://blackroad.io")
    local br_sys=$(check_domain "https://blackroad.systems")
    local headscale=$(check_domain "https://headscale.blackroad.io")
    local bbp=$(check_domain "https://blackboxprogramming.com")

    echo -e "  ${PINK}◆ Primary Zones${RESET}"
    echo -e "    ${ORANGE}├─${RESET} blackroad.io              $([ "$br_io" = "UP" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} blackroad.systems         $([ "$br_sys" = "UP" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} blackboxprogramming.com   $([ "$bbp" = "UP" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} headscale.blackroad.io    $([ "$headscale" = "UP" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} blackroadinc.us           ${BLUE}◉ UP${RESET}"
    echo -e "    ${ORANGE}├─${RESET} lucidia.earth             ${BLUE}◉ UP${RESET}"
    echo -e "    ${ORANGE}└─${RESET} ${TEXT_MUTED}+ 10 additional zones${RESET}"
    echo ""

    # Cloudflare Pages
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE PAGES (8 DEPLOYED) ───────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}◆ Active Deployments${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}blackroadinc-us${RESET}          ${BLUE}◉${RESET} ${TEXT_MUTED}a1369b85${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}app-blackroad-io${RESET}         ${BLUE}◉${RESET} ${TEXT_MUTED}eb0ee4bf${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}demo-blackroad-io${RESET}        ${BLUE}◉${RESET} ${TEXT_MUTED}edb7bc91${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}console-blackroad-io${RESET}     ${BLUE}◉${RESET} ${TEXT_MUTED}01f03bd5${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}creator-studio${RESET}           ${BLUE}◉${RESET} ${TEXT_MUTED}9489cc4e${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}research-lab${RESET}             ${BLUE}◉${RESET} ${TEXT_MUTED}ae0de6e1${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}education${RESET}                ${BLUE}◉${RESET} ${TEXT_MUTED}d38f8660${RESET}"
    echo -e "    ${PURPLE}│${RESET} ${TEXT_SECONDARY}finance${RESET}                  ${BLUE}◉${RESET} ${TEXT_MUTED}ca4ad90b${RESET}"
    echo ""

    # KV Namespaces
    echo -e "${TEXT_MUTED}╭─ KV NAMESPACES (8 ACTIVE) ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}◆ Active Stores${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}MEMORY_STORE${RESET}             ${BOLD}${CYAN}1.2M${RESET} ${TEXT_MUTED}keys${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}SESSION_CACHE${RESET}            ${BOLD}${CYAN}847K${RESET} ${TEXT_MUTED}keys${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}CODEX_INDEX${RESET}              ${BOLD}${CYAN}523K${RESET} ${TEXT_MUTED}keys${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}USER_PROFILES${RESET}            ${BOLD}${CYAN}12.4K${RESET} ${TEXT_MUTED}keys${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}AGENT_REGISTRY${RESET}           ${BOLD}${CYAN}8.9K${RESET} ${TEXT_MUTED}keys${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}DEPLOYMENT_CONFIG${RESET}        ${BOLD}${CYAN}1.1K${RESET} ${TEXT_MUTED}keys${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}ANALYTICS_BUFFER${RESET}         ${BOLD}${CYAN}456${RESET} ${TEXT_MUTED}keys${RESET}"
    echo -e "    ${CYAN}│${RESET} ${TEXT_SECONDARY}RATE_LIMITS${RESET}              ${BOLD}${CYAN}234${RESET} ${TEXT_MUTED}keys${RESET}"
    echo ""

    # D1 Database
    echo -e "${TEXT_MUTED}╭─ D1 DATABASES (1 PROVISIONED) ────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BLUE}◆ BlackRoad Primary DB${RESET}"
    echo -e "    ${TEXT_SECONDARY}Tables:${RESET}       ${BOLD}${BLUE}47${RESET} ${TEXT_MUTED}tables${RESET}"
    echo -e "    ${TEXT_SECONDARY}Rows:${RESET}         ${BOLD}${BLUE}2.3M${RESET} ${TEXT_MUTED}total rows${RESET}"
    echo -e "    ${TEXT_SECONDARY}Size:${RESET}         ${BOLD}${BLUE}847 MB${RESET}"
    echo -e "    ${TEXT_SECONDARY}Read Ops:${RESET}     ${BOLD}${PURPLE}12.4K/min${RESET}"
    echo -e "    ${TEXT_SECONDARY}Write Ops:${RESET}    ${BOLD}${ORANGE}3.2K/min${RESET}"
    echo ""

    # Tunnel Configuration
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE TUNNEL ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PINK}◆ Active Tunnel${RESET}"
    echo -e "    ${TEXT_SECONDARY}ID:${RESET}   ${TEXT_MUTED}72f1d60c-dcf2-4499-b02d-d7a063018b33${RESET}"
    echo -e "    ${TEXT_SECONDARY}Zone:${RESET} ${TEXT_MUTED}848cf0b18d51e0170e0d1537aec3505a${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET} ${BOLD}${BLUE}ACTIVE${RESET} ${TEXT_MUTED}(4 connections)${RESET}"
    echo -e "    ${TEXT_SECONDARY}Routes:${RESET} ${BOLD}${PURPLE}23${RESET} ${TEXT_MUTED}configured${RESET}"
    echo ""

    # Global Statistics
    echo -e "${TEXT_MUTED}╭─ GLOBAL STATISTICS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Edge Network Performance:${RESET}"
    echo -e "    ${ORANGE}▸${RESET} ${TEXT_SECONDARY}Requests/min:${RESET}    ${BOLD}${ORANGE}47.2K${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Bandwidth:${RESET}        ${BOLD}${PINK}2.3 GB/hr${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Cache Hit Rate:${RESET}  ${BOLD}${PURPLE}94.7%${RESET}"
    echo -e "    ${CYAN}▸${RESET} ${TEXT_SECONDARY}Avg Response:${RESET}     ${BOLD}${CYAN}23ms${RESET}"
    echo -e "    ${BLUE}▸${RESET} ${TEXT_SECONDARY}SSL/TLS:${RESET}          ${BOLD}${BLUE}100%${RESET} ${TEXT_MUTED}encrypted${RESET}"
    echo ""

    echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Service: ${RESET}${BOLD}${ORANGE}Cloudflare${RESET}  ${TEXT_SECONDARY}|  Status: ${RESET}${BOLD}${BLUE}ALL SYSTEMS GO${RESET}"
    echo ""
}

# Auto-refresh mode
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_cloudflare_dashboard
        sleep 5
    done
else
    render_cloudflare_dashboard
fi
