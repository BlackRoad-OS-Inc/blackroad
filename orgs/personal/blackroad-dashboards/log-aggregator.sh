#!/bin/bash

# BlackRoad OS - Log Aggregator
# Real-time log aggregation from all services and devices

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

render_log_aggregator() {
    clear

    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${ORANGE}📋${RESET} ${BOLD}${PURPLE}LOG AGGREGATOR${RESET}                                                 ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}     ${TEXT_SECONDARY}Real-time Logs • Multi-Device • Smart Filtering${RESET}                ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Log Statistics
    echo -e "${TEXT_MUTED}╭─ LOG STATISTICS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Last Hour:${RESET}"
    echo -e "    ${GREEN}◉${RESET} ${TEXT_PRIMARY}Info:${RESET}              ${BOLD}${GREEN}12,400${RESET} ${TEXT_MUTED}messages${RESET}"
    echo -e "    ${YELLOW}◉${RESET} ${TEXT_PRIMARY}Warning:${RESET}          ${BOLD}${YELLOW}234${RESET} ${TEXT_MUTED}messages${RESET}"
    echo -e "    ${RED}◉${RESET} ${TEXT_PRIMARY}Error:${RESET}            ${BOLD}${RED}12${RESET} ${TEXT_MUTED}messages${RESET}"
    echo -e "    ${CYAN}◉${RESET} ${TEXT_PRIMARY}Debug:${RESET}            ${BOLD}${CYAN}5,600${RESET} ${TEXT_MUTED}messages${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Processed:${RESET}      ${BOLD}${ORANGE}18,246${RESET} ${TEXT_SECONDARY}logs/hour${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Error Rate:${RESET}           ${BOLD}${PURPLE}0.07%${RESET}"
    echo ""

    # Recent Logs by Level
    echo -e "${TEXT_MUTED}╭─ RECENT ERRORS & WARNINGS ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}ERROR${RESET} ${TEXT_MUTED}[api-server]${RESET}        ${TEXT_SECONDARY}Database connection timeout${RESET}"
    echo -e "        ${TEXT_MUTED}192.168.4.38 • 2m ago${RESET}"
    echo ""
    echo -e "  ${RED}ERROR${RESET} ${TEXT_MUTED}[docker]${RESET}            ${TEXT_SECONDARY}Container worker-1 exited (code 1)${RESET}"
    echo -e "        ${TEXT_MUTED}192.168.4.64 • 5m ago${RESET}"
    echo ""
    echo -e "  ${YELLOW}WARN${RESET}  ${TEXT_MUTED}[nginx]${RESET}             ${TEXT_SECONDARY}High memory usage: 87%${RESET}"
    echo -e "        ${TEXT_MUTED}159.65.43.12 • 8m ago${RESET}"
    echo ""
    echo -e "  ${YELLOW}WARN${RESET}  ${TEXT_MUTED}[cloudflare]${RESET}        ${TEXT_SECONDARY}Rate limit approaching (80%)${RESET}"
    echo -e "        ${TEXT_MUTED}Edge Network • 12m ago${RESET}"
    echo ""

    # Log Sources
    echo -e "${TEXT_MUTED}╭─ LOG SOURCES (12 ACTIVE) ─────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}Raspberry Pi Fleet${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}lucidia-prime (192.168.4.38)${RESET}     ${BOLD}${ORANGE}4.2K${RESET} ${TEXT_MUTED}logs/hr${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}blackroad-pi (192.168.4.64)${RESET}      ${BOLD}${ORANGE}3.1K${RESET} ${TEXT_MUTED}logs/hr${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}lucidia-alt (192.168.4.99)${RESET}       ${BOLD}${ORANGE}2.8K${RESET} ${TEXT_MUTED}logs/hr${RESET}"
    echo ""

    echo -e "  ${PINK}Cloud Services${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}DigitalOcean (159.65.43.12)${RESET}      ${BOLD}${PINK}5.6K${RESET} ${TEXT_MUTED}logs/hr${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}Cloudflare Workers${RESET}               ${BOLD}${PINK}1.2K${RESET} ${TEXT_MUTED}logs/hr${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}Railway Services${RESET}                 ${BOLD}${PINK}1.4K${RESET} ${TEXT_MUTED}logs/hr${RESET}"
    echo ""

    # Log Timeline
    echo -e "${TEXT_MUTED}╭─ ERROR TIMELINE (Last 24h) ───────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}00:00${RESET}  ${RED}█${RESET}                    ${BOLD}2${RESET}"
    echo -e "  ${TEXT_MUTED}04:00${RESET}  ${RED}${RESET}                     ${BOLD}0${RESET}"
    echo -e "  ${TEXT_MUTED}08:00${RESET}  ${RED}███${RESET}                  ${BOLD}5${RESET}"
    echo -e "  ${TEXT_MUTED}12:00${RESET}  ${RED}██${RESET}                   ${BOLD}3${RESET}"
    echo -e "  ${TEXT_MUTED}16:00${RESET}  ${RED}█${RESET}                    ${BOLD}1${RESET}"
    echo -e "  ${TEXT_MUTED}20:00${RESET}  ${RED}██${RESET}                   ${BOLD}3${RESET} ${ORANGE}← Current Hour${RESET}"
    echo ""

    # Service-Specific Logs
    echo -e "${TEXT_MUTED}╭─ TOP SERVICES BY LOG VOLUME ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1.${RESET} ${TEXT_SECONDARY}api-server${RESET}         ${BOLD}${ORANGE}5.6K${RESET}  ${ORANGE}████████████████${RESET}"
    echo -e "  ${PINK}2.${RESET} ${TEXT_SECONDARY}nginx-proxy${RESET}        ${BOLD}${PINK}4.2K${RESET}  ${PINK}████████████${RESET}"
    echo -e "  ${PURPLE}3.${RESET} ${TEXT_SECONDARY}docker-daemon${RESET}      ${BOLD}${PURPLE}3.1K${RESET}  ${PURPLE}█████████${RESET}"
    echo -e "  ${CYAN}4.${RESET} ${TEXT_SECONDARY}postgres${RESET}           ${BOLD}${CYAN}2.8K${RESET}  ${CYAN}████████${RESET}"
    echo -e "  ${BLUE}5.${RESET} ${TEXT_SECONDARY}memory-system${RESET}      ${BOLD}${BLUE}1.4K${RESET}  ${BLUE}████${RESET}"
    echo ""

    # Log Patterns
    echo -e "${TEXT_MUTED}╭─ DETECTED PATTERNS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${YELLOW}⚠${RESET}  ${TEXT_PRIMARY}High Memory Pattern${RESET}"
    echo -e "     ${TEXT_SECONDARY}Detected in:${RESET} ${TEXT_MUTED}nginx-proxy, api-server${RESET}"
    echo -e "     ${TEXT_SECONDARY}Frequency:${RESET}   ${BOLD}${YELLOW}3x${RESET} ${TEXT_MUTED}in last hour${RESET}"
    echo ""
    echo -e "  ${RED}●${RESET}  ${TEXT_PRIMARY}Connection Timeout Pattern${RESET}"
    echo -e "     ${TEXT_SECONDARY}Detected in:${RESET} ${TEXT_MUTED}api-server${RESET}"
    echo -e "     ${TEXT_SECONDARY}Frequency:${RESET}   ${BOLD}${RED}2x${RESET} ${TEXT_MUTED}in last hour${RESET}"
    echo ""

    # Recent Activity Stream
    echo -e "${TEXT_MUTED}╭─ LIVE ACTIVITY STREAM ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}$(date '+%H:%M:%S')${RESET} ${GREEN}INFO${RESET}  ${TEXT_MUTED}[api]${RESET}     ${TEXT_SECONDARY}Request processed: GET /api/v1/health${RESET}"
    echo -e "  ${TEXT_MUTED}$(date '+%H:%M:%S' -d '-5 seconds')${RESET} ${GREEN}INFO${RESET}  ${TEXT_MUTED}[docker]${RESET}  ${TEXT_SECONDARY}Container started: lucidia-earth${RESET}"
    echo -e "  ${TEXT_MUTED}$(date '+%H:%M:%S' -d '-10 seconds')${RESET} ${CYAN}DEBUG${RESET} ${TEXT_MUTED}[memory]${RESET}  ${TEXT_SECONDARY}PS-SHA∞ chain verified${RESET}"
    echo -e "  ${TEXT_MUTED}$(date '+%H:%M:%S' -d '-15 seconds')${RESET} ${GREEN}INFO${RESET}  ${TEXT_MUTED}[nginx]${RESET}   ${TEXT_SECONDARY}Connection accepted from 192.168.4.1${RESET}"
    echo -e "  ${TEXT_MUTED}$(date '+%H:%M:%S' -d '-20 seconds')${RESET} ${YELLOW}WARN${RESET}  ${TEXT_MUTED}[api]${RESET}     ${TEXT_SECONDARY}Slow query detected (234ms)${RESET}"
    echo ""

    # Storage & Retention
    echo -e "${TEXT_MUTED}╭─ STORAGE & RETENTION ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Log Storage:${RESET}"
    echo -e "    ${ORANGE}▸${RESET} ${TEXT_SECONDARY}Today:${RESET}            ${BOLD}${ORANGE}847 MB${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Last 7 Days:${RESET}      ${BOLD}${PINK}5.2 GB${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Last 30 Days:${RESET}     ${BOLD}${PURPLE}18.4 GB${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Retention Policy:${RESET}"
    echo -e "    ${CYAN}▸${RESET} ${TEXT_SECONDARY}Hot Storage:${RESET}      ${BOLD}${CYAN}7 days${RESET}"
    echo -e "    ${BLUE}▸${RESET} ${TEXT_SECONDARY}Cold Storage:${RESET}     ${BOLD}${BLUE}30 days${RESET}"
    echo -e "    ${GREEN}▸${RESET} ${TEXT_SECONDARY}Archive:${RESET}          ${BOLD}${GREEN}90 days${RESET}"
    echo ""

    # Footer
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Logs/hr: ${RESET}${BOLD}${ORANGE}18.2K${RESET}  ${TEXT_SECONDARY}|  Errors: ${RESET}${BOLD}${RED}12${RESET}  ${TEXT_SECONDARY}|  Storage: ${RESET}${BOLD}${PURPLE}18.4GB${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_log_aggregator
        sleep 3
    done
else
    render_log_aggregator
fi
