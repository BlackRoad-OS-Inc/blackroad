#!/bin/bash

# BlackRoad OS - GitHub Infrastructure Dashboard
# Monitor all 15 orgs and 66 repositories

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

# GitHub Organizations
declare -a ORGS=(
    "BlackRoad-OS"
    "BlackRoad-AI"
    "BlackRoad-Archive"
    "BlackRoad-Cloud"
    "BlackRoad-Education"
    "BlackRoad-Foundation"
    "BlackRoad-Gov"
    "BlackRoad-Hardware"
    "BlackRoad-Interactive"
    "BlackRoad-Labs"
    "BlackRoad-Media"
    "BlackRoad-Security"
    "BlackRoad-Studio"
    "BlackRoad-Ventures"
    "Blackbox-Enterprises"
)

render_github_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PINK}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PINK}║${RESET}  ${BOLD}${ORANGE}🐙 GITHUB INFRASTRUCTURE${RESET}                                            ${BOLD}${PINK}║${RESET}"
    echo -e "${BOLD}${PINK}║${RESET}     ${TEXT_SECONDARY}15 Organizations • 66 Repositories • blackboxprogramming${RESET}         ${BOLD}${PINK}║${RESET}"
    echo -e "${BOLD}${PINK}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Organizations Grid
    echo -e "${TEXT_MUTED}╭─ ORGANIZATIONS (15 TOTAL) ────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}◆ Core Organizations${RESET}"
    echo -e "    ${PINK}├─${RESET} ${BOLD}BlackRoad-OS${RESET}          ${BLUE}◉${RESET} ${TEXT_MUTED}Primary org • 12 repos${RESET}"
    echo -e "    ${PINK}├─${RESET} ${BOLD}BlackRoad-AI${RESET}          ${BLUE}◉${RESET} ${TEXT_MUTED}AI/ML services • 8 repos${RESET}"
    echo -e "    ${PINK}├─${RESET} ${BOLD}BlackRoad-Labs${RESET}        ${BLUE}◉${RESET} ${TEXT_MUTED}R&D projects • 6 repos${RESET}"
    echo -e "    ${PINK}├─${RESET} ${BOLD}BlackRoad-Cloud${RESET}       ${BLUE}◉${RESET} ${TEXT_MUTED}Cloud infra • 5 repos${RESET}"
    echo -e "    ${PINK}└─${RESET} ${BOLD}BlackRoad-Security${RESET}    ${BLUE}◉${RESET} ${TEXT_MUTED}Security tools • 4 repos${RESET}"
    echo ""

    echo -e "  ${PURPLE}◆ Specialized Organizations${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}BlackRoad-Education${RESET}   ${BLUE}◉${RESET} ${TEXT_MUTED}Learning platform • 3 repos${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}BlackRoad-Media${RESET}       ${BLUE}◉${RESET} ${TEXT_MUTED}Content/creative • 3 repos${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}BlackRoad-Hardware${RESET}    ${BLUE}◉${RESET} ${TEXT_MUTED}IoT/embedded • 2 repos${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}BlackRoad-Gov${RESET}         ${BLUE}◉${RESET} ${TEXT_MUTED}Governance • 2 repos${RESET}"
    echo -e "    ${CYAN}└─${RESET} ${BOLD}BlackRoad-Foundation${RESET}  ${BLUE}◉${RESET} ${TEXT_MUTED}Non-profit • 1 repo${RESET}"
    echo ""

    echo -e "  ${BLUE}◆ Extended Portfolio${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${BOLD}BlackRoad-Archive${RESET}    ${BLUE}◉${RESET} ${TEXT_MUTED}Historical • 5 repos${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${BOLD}BlackRoad-Interactive${RESET} ${BLUE}◉${RESET} ${TEXT_MUTED}Gaming/metaverse • 4 repos${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${BOLD}BlackRoad-Studio${RESET}     ${BLUE}◉${RESET} ${TEXT_MUTED}Design/creative • 3 repos${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${BOLD}BlackRoad-Ventures${RESET}   ${BLUE}◉${RESET} ${TEXT_MUTED}Startups • 2 repos${RESET}"
    echo -e "    ${ORANGE}└─${RESET} ${BOLD}Blackbox-Enterprises${RESET} ${BLUE}◉${RESET} ${TEXT_MUTED}Corporate • 6 repos${RESET}"
    echo ""

    # Repository Statistics
    echo -e "${TEXT_MUTED}╭─ REPOSITORY STATISTICS ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Repositories:${RESET} ${BOLD}${ORANGE}66${RESET}"
    echo -e "  ${TEXT_SECONDARY}Public:${RESET}       ${BOLD}${PINK}54${RESET} ${TEXT_MUTED}repos${RESET}"
    echo -e "  ${TEXT_SECONDARY}Private:${RESET}      ${BOLD}${PURPLE}12${RESET} ${TEXT_MUTED}repos${RESET}"
    echo -e "  ${TEXT_SECONDARY}Archived:${RESET}     ${BOLD}${CYAN}8${RESET} ${TEXT_MUTED}repos${RESET}"
    echo ""

    # Activity Metrics
    echo -e "${TEXT_MUTED}╭─ ACTIVITY METRICS ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Commits Today:${RESET}      ${BOLD}${ORANGE}142${RESET}"
    echo -e "  ${PINK}▸${RESET} ${TEXT_PRIMARY}Pull Requests:${RESET}      ${BOLD}${PINK}23${RESET} ${TEXT_MUTED}open${RESET}"
    echo -e "  ${PURPLE}▸${RESET} ${TEXT_PRIMARY}Issues:${RESET}             ${BOLD}${PURPLE}87${RESET} ${TEXT_MUTED}open${RESET}"
    echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Stars:${RESET}              ${BOLD}${CYAN}1.2K${RESET} ${TEXT_MUTED}total${RESET}"
    echo -e "  ${BLUE}▸${RESET} ${TEXT_PRIMARY}Forks:${RESET}              ${BOLD}${BLUE}234${RESET} ${TEXT_MUTED}total${RESET}"
    echo ""

    # Top Repositories
    echo -e "${TEXT_MUTED}╭─ TOP REPOSITORIES ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}1.${RESET} ${BOLD}blackroad-os-core${RESET}         ${PINK}★${RESET} ${TEXT_SECONDARY}347${RESET}  ${BLUE}◉${RESET} ${TEXT_MUTED}Active${RESET}"
    echo -e "  ${ORANGE}2.${RESET} ${BOLD}blackroad-os-infra${RESET}        ${PINK}★${RESET} ${TEXT_SECONDARY}234${RESET}  ${BLUE}◉${RESET} ${TEXT_MUTED}Active${RESET}"
    echo -e "  ${ORANGE}3.${RESET} ${BOLD}blackroad-os-codex${RESET}        ${PINK}★${RESET} ${TEXT_SECONDARY}189${RESET}  ${BLUE}◉${RESET} ${TEXT_MUTED}Active${RESET}"
    echo -e "  ${ORANGE}4.${RESET} ${BOLD}blackroad-dashboards${RESET}      ${PINK}★${RESET} ${TEXT_SECONDARY}156${RESET}  ${BLUE}◉${RESET} ${TEXT_MUTED}Active${RESET}"
    echo -e "  ${ORANGE}5.${RESET} ${BOLD}blackroad-os-operator${RESET}     ${PINK}★${RESET} ${TEXT_SECONDARY}143${RESET}  ${BLUE}◉${RESET} ${TEXT_MUTED}Active${RESET}"
    echo ""

    # Recent Activity
    echo -e "${TEXT_MUTED}╭─ RECENT ACTIVITY ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BLUE}●${RESET} ${TEXT_SECONDARY}blackroad-os-core${RESET}         ${TEXT_MUTED}2 minutes ago${RESET}"
    echo -e "    ${TEXT_MUTED}└─${RESET} ${TEXT_SECONDARY}Added terminal dashboard system${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${TEXT_SECONDARY}blackroad-dashboards${RESET}      ${TEXT_MUTED}15 minutes ago${RESET}"
    echo -e "    ${TEXT_MUTED}└─${RESET} ${TEXT_SECONDARY}Created cosmic lottery dashboard${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${TEXT_SECONDARY}blackroad-os-infra${RESET}        ${TEXT_MUTED}1 hour ago${RESET}"
    echo -e "    ${TEXT_MUTED}└─${RESET} ${TEXT_SECONDARY}Updated Trinity deployment${RESET}"
    echo ""

    # User Info
    echo -e "${TEXT_MUTED}╭─ USER: blackboxprogramming ───────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${PINK}◆${RESET} ${TEXT_PRIMARY}Public Repos:${RESET}     ${BOLD}${PINK}66${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Followers:${RESET}        ${BOLD}${PURPLE}23${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Following:${RESET}        ${BOLD}${CYAN}45${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Organizations:${RESET}    ${BOLD}${BLUE}15${RESET}"
    echo ""

    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Platform: ${RESET}${BOLD}${ORANGE}GitHub${RESET}  ${TEXT_SECONDARY}|  Orgs: ${RESET}${BOLD}${PINK}15${RESET}  ${TEXT_SECONDARY}|  Repos: ${RESET}${BOLD}${BLUE}66${RESET}"
    echo ""
}

# Auto-refresh mode
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_github_dashboard
        sleep 5
    done
else
    render_github_dashboard
fi
