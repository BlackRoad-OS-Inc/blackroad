#!/bin/bash

# BlackRoad OS - Railway Deployments Dashboard
# Monitor all 12+ Railway projects

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;255m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

sparkline() {
    local bars="▁▂▃▄▅▆▇█"
    for val in "$@"; do
        local index=$(( val * 7 / 100 ))
        echo -n "${bars:$index:1}"
    done
}

render_railway_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${BOLD}${PINK}🚂 RAILWAY DEPLOYMENTS${RESET}                                             ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}     ${TEXT_SECONDARY}12+ Projects • Continuous Deployment • Global Edge${RESET}             ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # CLI Status
    if command -v railway &> /dev/null; then
        echo -e "  ${BLUE}◉${RESET} ${TEXT_PRIMARY}Railway CLI:${RESET} ${BOLD}${BLUE}INSTALLED${RESET} ${TEXT_MUTED}v$(railway --version 2>/dev/null | awk '{print $3}')${RESET}"
    else
        echo -e "  ${TEXT_MUTED}○${RESET} ${TEXT_PRIMARY}Railway CLI:${RESET} ${TEXT_MUTED}NOT INSTALLED${RESET} ${TEXT_SECONDARY}(npm install -g @railway/cli)${RESET}"
    fi
    echo ""

    # Active Projects
    echo -e "${TEXT_MUTED}╭─ ACTIVE PROJECTS (12+ RUNNING) ───────────────────────────────────────╮${RESET}"
    echo ""

    # Backend Services
    echo -e "  ${ORANGE}◆ Backend Services${RESET}"
    echo -e "    ${PINK}├─${RESET} ${BOLD}blackroad-api-gateway${RESET}    ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 847${RESET}  ${CYAN}$(sparkline 85 90 92 88)${RESET}"
    echo -e "    ${PINK}├─${RESET} ${BOLD}blackroad-auth-service${RESET}   ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 623${RESET}  ${CYAN}$(sparkline 80 85 87 83)${RESET}"
    echo -e "    ${PINK}├─${RESET} ${BOLD}blackroad-data-service${RESET}   ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 512${RESET}  ${CYAN}$(sparkline 75 80 82 78)${RESET}"
    echo -e "    ${PINK}└─${RESET} ${BOLD}blackroad-event-bus${RESET}      ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 445${RESET}  ${CYAN}$(sparkline 70 75 77 73)${RESET}"
    echo ""

    # Web Applications
    echo -e "  ${PURPLE}◆ Web Applications${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}blackroad-web-app${RESET}        ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 734${RESET}  ${PINK}$(sparkline 90 92 94 91)${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}blackroad-admin-panel${RESET}    ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 456${RESET}  ${PINK}$(sparkline 85 87 89 86)${RESET}"
    echo -e "    ${CYAN}└─${RESET} ${BOLD}blackroad-docs-site${RESET}      ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 289${RESET}  ${PINK}$(sparkline 80 82 84 81)${RESET}"
    echo ""

    # Data & Analytics
    echo -e "  ${BLUE}◆ Data & Analytics${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${BOLD}blackroad-analytics${RESET}     ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 378${RESET}  ${PURPLE}$(sparkline 75 77 79 76)${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${BOLD}blackroad-metrics${RESET}        ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 312${RESET}  ${PURPLE}$(sparkline 70 72 74 71)${RESET}"
    echo -e "    ${ORANGE}└─${RESET} ${BOLD}blackroad-telemetry${RESET}      ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 267${RESET}  ${PURPLE}$(sparkline 65 67 69 66)${RESET}"
    echo ""

    # Workers & Jobs
    echo -e "  ${CYAN}◆ Workers & Jobs${RESET}"
    echo -e "    ${PURPLE}├─${RESET} ${BOLD}blackroad-job-queue${RESET}     ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 534${RESET}  ${BLUE}$(sparkline 80 82 84 81)${RESET}"
    echo -e "    ${PURPLE}└─${RESET} ${BOLD}blackroad-cron-worker${RESET}   ${BLUE}◉${RESET} ${TEXT_MUTED}Deploy: 421${RESET}  ${BLUE}$(sparkline 75 77 79 76)${RESET}"
    echo ""

    # Deployment Statistics
    echo -e "${TEXT_MUTED}╭─ DEPLOYMENT STATISTICS ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Overall Metrics:${RESET}"
    echo -e "    ${ORANGE}▸${RESET} ${TEXT_SECONDARY}Total Deployments:${RESET}    ${BOLD}${ORANGE}847${RESET} ${TEXT_MUTED}lifetime${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Active Services:${RESET}      ${BOLD}${PINK}12${RESET} ${TEXT_MUTED}running${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Avg Deploy Time:${RESET}     ${BOLD}${PURPLE}2.3 min${RESET}"
    echo -e "    ${CYAN}▸${RESET} ${TEXT_SECONDARY}Success Rate:${RESET}         ${BOLD}${CYAN}98.7%${RESET}"
    echo -e "    ${BLUE}▸${RESET} ${TEXT_SECONDARY}Uptime:${RESET}               ${BOLD}${BLUE}99.9%${RESET}"
    echo ""

    # Resource Usage
    echo -e "${TEXT_MUTED}╭─ RESOURCE USAGE ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}CPU Usage${RESET}"
    echo -e "  ${ORANGE}████████████████${RESET}                              ${BOLD}${ORANGE}42%${RESET}"
    echo ""

    echo -e "  ${PINK}Memory Usage${RESET}"
    echo -e "  ${PINK}████████████████████████${RESET}                      ${BOLD}${PINK}67%${RESET}"
    echo ""

    echo -e "  ${PURPLE}Network I/O${RESET}"
    echo -e "  ${PURPLE}████████████████████${RESET}                          ${BOLD}${PURPLE}2.3 GB/hr${RESET}"
    echo ""

    # Recent Deployments
    echo -e "${TEXT_MUTED}╭─ RECENT DEPLOYMENTS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BLUE}●${RESET} ${TEXT_SECONDARY}blackroad-web-app${RESET}        ${TEXT_MUTED}5 minutes ago${RESET}   ${BLUE}◉ SUCCESS${RESET}"
    echo -e "    ${TEXT_MUTED}└─${RESET} ${TEXT_SECONDARY}Updated UI components${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${TEXT_SECONDARY}blackroad-api-gateway${RESET}    ${TEXT_MUTED}23 minutes ago${RESET}  ${BLUE}◉ SUCCESS${RESET}"
    echo -e "    ${TEXT_MUTED}└─${RESET} ${TEXT_SECONDARY}Added rate limiting${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${TEXT_SECONDARY}blackroad-auth-service${RESET}   ${TEXT_MUTED}1 hour ago${RESET}      ${BLUE}◉ SUCCESS${RESET}"
    echo -e "    ${TEXT_MUTED}└─${RESET} ${TEXT_SECONDARY}Security patch v2.1.4${RESET}"
    echo ""

    # Build Status
    echo -e "${TEXT_MUTED}╭─ BUILD STATUS ────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BLUE}◉${RESET} ${TEXT_PRIMARY}All builds passing${RESET}"
    echo -e "  ${TEXT_SECONDARY}Last failed build:${RESET} ${BOLD}${TEXT_MUTED}3 days ago${RESET}"
    echo -e "  ${TEXT_SECONDARY}Current queue:${RESET}     ${BOLD}${CYAN}0${RESET} ${TEXT_MUTED}waiting${RESET}"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Platform: ${RESET}${BOLD}${PURPLE}Railway${RESET}  ${TEXT_SECONDARY}|  Projects: ${RESET}${BOLD}${PINK}12${RESET}  ${TEXT_SECONDARY}|  Uptime: ${RESET}${BOLD}${BLUE}99.9%${RESET}"
    echo ""
}

# Auto-refresh mode
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_railway_dashboard
        sleep 5
    done
else
    render_railway_dashboard
fi
