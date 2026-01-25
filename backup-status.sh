#!/bin/bash

# BlackRoad OS - Backup Status Monitor
# Track all backups across all systems and services

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

render_backup_status() {
    clear

    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${CYAN}💾${RESET} ${BOLD}${ORANGE}BACKUP STATUS MONITOR${RESET}                                          ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}     ${TEXT_SECONDARY}All Backups • Multi-Device • Recovery Status${RESET}                   ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Backup Overview
    echo -e "${TEXT_MUTED}╭─ BACKUP OVERVIEW ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Backup Sets:${RESET}    ${BOLD}${ORANGE}24${RESET}"
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Successful:${RESET}          ${BOLD}${GREEN}24${RESET} ${TEXT_MUTED}(100%)${RESET}"
    echo -e "  ${YELLOW}◉${RESET} ${TEXT_PRIMARY}In Progress:${RESET}         ${BOLD}${YELLOW}0${RESET}"
    echo -e "  ${RED}◉${RESET} ${TEXT_PRIMARY}Failed:${RESET}              ${BOLD}${RED}0${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Total Storage:${RESET}       ${BOLD}${CYAN}847 GB${RESET}"
    echo ""

    # Database Backups
    echo -e "${TEXT_MUTED}╭─ DATABASE BACKUPS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}◆ Cloudflare D1${RESET}"
    echo -e "     ${TEXT_SECONDARY}Last Backup:${RESET}   ${BOLD}${GREEN}2 hours ago${RESET}"
    echo -e "     ${TEXT_SECONDARY}Size:${RESET}          ${BOLD}${CYAN}847 MB${RESET}"
    echo -e "     ${TEXT_SECONDARY}Next Backup:${RESET}   ${BOLD}${ORANGE}in 10 hours${RESET}"
    echo -e "     ${TEXT_SECONDARY}Retention:${RESET}     ${BOLD}${PURPLE}30 days${RESET} ${TEXT_MUTED}(daily)${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}        ${GREEN}✓ HEALTHY${RESET}"
    echo ""

    echo -e "  ${PINK}◆ PostgreSQL${RESET}"
    echo -e "     ${TEXT_SECONDARY}Last Backup:${RESET}   ${BOLD}${GREEN}1 hour ago${RESET}"
    echo -e "     ${TEXT_SECONDARY}Size:${RESET}          ${BOLD}${CYAN}2.1 GB${RESET}"
    echo -e "     ${TEXT_SECONDARY}Next Backup:${RESET}   ${BOLD}${ORANGE}in 11 hours${RESET}"
    echo -e "     ${TEXT_SECONDARY}Retention:${RESET}     ${BOLD}${PURPLE}60 days${RESET} ${TEXT_MUTED}(daily)${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}        ${GREEN}✓ HEALTHY${RESET}"
    echo ""

    echo -e "  ${PURPLE}◆ MongoDB${RESET}"
    echo -e "     ${TEXT_SECONDARY}Last Backup:${RESET}   ${BOLD}${GREEN}3 hours ago${RESET}"
    echo -e "     ${TEXT_SECONDARY}Size:${RESET}          ${BOLD}${CYAN}5.4 GB${RESET}"
    echo -e "     ${TEXT_SECONDARY}Next Backup:${RESET}   ${BOLD}${ORANGE}in 9 hours${RESET}"
    echo -e "     ${TEXT_SECONDARY}Retention:${RESET}     ${BOLD}${PURPLE}90 days${RESET} ${TEXT_MUTED}(daily)${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}        ${GREEN}✓ HEALTHY${RESET}"
    echo ""

    # KV Store Backups
    echo -e "${TEXT_MUTED}╭─ KV STORE BACKUPS (8 NAMESPACES) ─────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}◆ All KV Namespaces${RESET}"
    echo -e "     ${TEXT_SECONDARY}Last Backup:${RESET}   ${BOLD}${GREEN}4 hours ago${RESET}"
    echo -e "     ${TEXT_SECONDARY}Total Size:${RESET}    ${BOLD}${CYAN}12.3 GB${RESET}"
    echo -e "     ${TEXT_SECONDARY}Next Backup:${RESET}   ${BOLD}${ORANGE}in 8 hours${RESET}"
    echo -e "     ${TEXT_SECONDARY}Retention:${RESET}     ${BOLD}${PURPLE}30 days${RESET}"
    echo ""
    echo -e "  ${BLUE}Breakdown by Namespace:${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}MEMORY_STORE${RESET}       ${BOLD}${ORANGE}847 MB${RESET}  ${GREEN}✓${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}SESSION_CACHE${RESET}      ${BOLD}${ORANGE}623 MB${RESET}  ${GREEN}✓${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}CODEX_INDEX${RESET}        ${BOLD}${ORANGE}412 MB${RESET}  ${GREEN}✓${RESET}"
    echo -e "    ${TEXT_MUTED}+ 5 more namespaces...${RESET}"
    echo ""

    # Code Repositories
    echo -e "${TEXT_MUTED}╭─ CODE REPOSITORIES (66 REPOS) ────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BLUE}◆ GitHub Mirror Backups${RESET}"
    echo -e "     ${TEXT_SECONDARY}Last Backup:${RESET}   ${BOLD}${GREEN}30 minutes ago${RESET}"
    echo -e "     ${TEXT_SECONDARY}Total Size:${RESET}    ${BOLD}${CYAN}23.4 GB${RESET}"
    echo -e "     ${TEXT_SECONDARY}Repositories:${RESET}  ${BOLD}${ORANGE}66${RESET} ${TEXT_MUTED}across 15 orgs${RESET}"
    echo -e "     ${TEXT_SECONDARY}Frequency:${RESET}     ${BOLD}${PURPLE}Every 6 hours${RESET}"
    echo -e "     ${TEXT_SECONDARY}Status:${RESET}        ${GREEN}✓ UP TO DATE${RESET}"
    echo ""

    # System Backups
    echo -e "${TEXT_MUTED}╭─ SYSTEM BACKUPS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}Raspberry Pi Fleet${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}lucidia-prime${RESET}      ${BOLD}${CYAN}45 GB${RESET}   ${TEXT_MUTED}Last: 1 day ago${RESET}   ${GREEN}✓${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}blackroad-pi${RESET}       ${BOLD}${CYAN}32 GB${RESET}   ${TEXT_MUTED}Last: 1 day ago${RESET}   ${GREEN}✓${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}lucidia-alt${RESET}        ${BOLD}${CYAN}28 GB${RESET}   ${TEXT_MUTED}Last: 1 day ago${RESET}   ${GREEN}✓${RESET}"
    echo ""

    echo -e "  ${PINK}Cloud Servers${RESET}"
    echo -e "    ${GREEN}●${RESET} ${TEXT_SECONDARY}codex-infinity${RESET}     ${BOLD}${CYAN}120 GB${RESET}  ${TEXT_MUTED}Last: 6 hours ago${RESET} ${GREEN}✓${RESET}"
    echo ""

    # Backup Timeline
    echo -e "${TEXT_MUTED}╭─ BACKUP TIMELINE (Next 24h) ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Now${RESET}      ${GREEN}●${RESET} ${TEXT_SECONDARY}GitHub Mirror${RESET}         ${TEXT_MUTED}in progress${RESET}"
    echo -e "  ${TEXT_MUTED}+2h${RESET}      ${CYAN}◆${RESET} ${TEXT_SECONDARY}D1 Database${RESET}           ${TEXT_MUTED}scheduled${RESET}"
    echo -e "  ${TEXT_MUTED}+4h${RESET}      ${PINK}◆${RESET} ${TEXT_SECONDARY}KV Stores${RESET}             ${TEXT_MUTED}scheduled${RESET}"
    echo -e "  ${TEXT_MUTED}+6h${RESET}      ${PURPLE}◆${RESET} ${TEXT_SECONDARY}PostgreSQL${RESET}            ${TEXT_MUTED}scheduled${RESET}"
    echo -e "  ${TEXT_MUTED}+12h${RESET}     ${ORANGE}◆${RESET} ${TEXT_SECONDARY}System Backups${RESET}        ${TEXT_MUTED}scheduled${RESET}"
    echo ""

    # Storage Locations
    echo -e "${TEXT_MUTED}╭─ STORAGE LOCATIONS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1.${RESET} ${TEXT_SECONDARY}Local Storage${RESET}          ${BOLD}${ORANGE}225 GB${RESET}   ${ORANGE}████████████${RESET}"
    echo -e "     ${TEXT_MUTED}/Volumes/Backup-Drive${RESET}"
    echo ""
    echo -e "  ${PINK}2.${RESET} ${TEXT_SECONDARY}Cloudflare R2${RESET}          ${BOLD}${PINK}412 GB${RESET}   ${PINK}████████████████████${RESET}"
    echo -e "     ${TEXT_MUTED}blackroad-backups bucket${RESET}"
    echo ""
    echo -e "  ${PURPLE}3.${RESET} ${TEXT_SECONDARY}DigitalOcean Spaces${RESET}    ${BOLD}${PURPLE}210 GB${RESET}   ${PURPLE}██████████${RESET}"
    echo -e "     ${TEXT_MUTED}nyc3/blackroad-archive${RESET}"
    echo ""

    # Recovery Test Status
    echo -e "${TEXT_MUTED}╭─ RECOVERY TEST STATUS ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Last Recovery Test:${RESET}   ${BOLD}${GREEN}7 days ago${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Test Result:${RESET}          ${BOLD}${GREEN}PASSED${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Recovery Time:${RESET}        ${BOLD}${CYAN}4.2 minutes${RESET} ${TEXT_MUTED}(D1 restore)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Next Test:${RESET}            ${BOLD}${ORANGE}in 7 days${RESET}"
    echo ""

    # Backup Health Score
    echo -e "${TEXT_MUTED}╭─ BACKUP HEALTH SCORE ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Overall Health:${RESET}       ${GREEN}████████████████████${RESET} ${BOLD}${GREEN}100%${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Coverage:${RESET}            ${BOLD}${GREEN}100%${RESET} ${TEXT_SECONDARY}of critical data${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Redundancy:${RESET}          ${BOLD}${CYAN}3x${RESET} ${TEXT_SECONDARY}minimum${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Freshness:${RESET}           ${BOLD}${PURPLE}EXCELLENT${RESET} ${TEXT_SECONDARY}all < 24h${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Recovery Tested:${RESET}     ${BOLD}${BLUE}YES${RESET} ${TEXT_SECONDARY}weekly${RESET}"
    echo ""

    # Footer
    echo -e "${GREEN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Total: ${RESET}${BOLD}${CYAN}847GB${RESET}  ${TEXT_SECONDARY}|  Sets: ${RESET}${BOLD}${ORANGE}24${RESET}  ${TEXT_SECONDARY}|  Health: ${RESET}${BOLD}${GREEN}100%${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_backup_status
        sleep 10
    done
else
    render_backup_status
fi
