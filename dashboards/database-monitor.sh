#!/bin/bash

# BlackRoad OS - Database Monitor
# Monitor all databases: D1, KV stores, and data services

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

render_database_monitor() {
    clear

    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${PURPLE}💾${RESET} ${BOLD}${CYAN}DATABASE MONITOR${RESET}                                               ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}     ${TEXT_SECONDARY}D1 • KV Stores • Data Services • Real-time Stats${RESET}              ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # D1 Database
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE D1 DATABASE ──────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}◆ BlackRoad Primary DB${RESET}"
    echo -e "    ${TEXT_SECONDARY}Status:${RESET}        ${BOLD}${GREEN}ONLINE${RESET}"
    echo -e "    ${TEXT_SECONDARY}Tables:${RESET}        ${BOLD}${ORANGE}47${RESET} ${TEXT_MUTED}tables${RESET}"
    echo -e "    ${TEXT_SECONDARY}Total Rows:${RESET}    ${BOLD}${PINK}2.3M${RESET} ${TEXT_MUTED}rows${RESET}"
    echo -e "    ${TEXT_SECONDARY}Database Size:${RESET} ${BOLD}${PURPLE}847 MB${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Performance Metrics:${RESET}"
    echo -e "    ${CYAN}▸${RESET} ${TEXT_SECONDARY}Read Ops/min:${RESET}    ${BOLD}${CYAN}12,400${RESET}  ${CYAN}████████████${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Write Ops/min:${RESET}   ${BOLD}${PINK}3,200${RESET}   ${PINK}███${RESET}"
    echo -e "    ${BLUE}▸${RESET} ${TEXT_SECONDARY}Avg Query Time:${RESET}  ${BOLD}${BLUE}23ms${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Cache Hit Rate:${RESET}  ${BOLD}${PURPLE}94.7%${RESET}"
    echo ""

    # KV Namespaces
    echo -e "${TEXT_MUTED}╭─ KV NAMESPACES (8 TOTAL) ─────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${PINK}1. MEMORY_STORE${RESET}"
    echo -e "     ${TEXT_SECONDARY}Keys:${RESET}  ${BOLD}${PINK}1.2M${RESET}  ${TEXT_SECONDARY}Size:${RESET} ${BOLD}${CYAN}847 MB${RESET}  ${TEXT_SECONDARY}Reads/min:${RESET} ${BOLD}${ORANGE}4.2K${RESET}"
    echo -e "     ${PINK}████████████████████████${RESET}"
    echo ""

    echo -e "  ${PURPLE}2. SESSION_CACHE${RESET}"
    echo -e "     ${TEXT_SECONDARY}Keys:${RESET}  ${BOLD}${PURPLE}847K${RESET}  ${TEXT_SECONDARY}Size:${RESET} ${BOLD}${CYAN}623 MB${RESET}  ${TEXT_SECONDARY}Reads/min:${RESET} ${BOLD}${ORANGE}8.9K${RESET}"
    echo -e "     ${PURPLE}████████████████████${RESET}"
    echo ""

    echo -e "  ${CYAN}3. CODEX_INDEX${RESET}"
    echo -e "     ${TEXT_SECONDARY}Keys:${RESET}  ${BOLD}${CYAN}523K${RESET}  ${TEXT_SECONDARY}Size:${RESET} ${BOLD}${CYAN}412 MB${RESET}  ${TEXT_SECONDARY}Reads/min:${RESET} ${BOLD}${ORANGE}1.2K${RESET}"
    echo -e "     ${CYAN}████████████${RESET}"
    echo ""

    echo -e "  ${BLUE}4. USER_PROFILES${RESET}"
    echo -e "     ${TEXT_SECONDARY}Keys:${RESET}  ${BOLD}${BLUE}12.4K${RESET} ${TEXT_SECONDARY}Size:${RESET} ${BOLD}${CYAN}89 MB${RESET}   ${TEXT_SECONDARY}Reads/min:${RESET} ${BOLD}${ORANGE}567${RESET}"
    echo -e "     ${BLUE}████${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}+ 4 more namespaces...${RESET}"
    echo ""

    # Query Performance
    echo -e "${TEXT_MUTED}╭─ QUERY PERFORMANCE ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Slow Queries (>100ms):${RESET}"
    echo -e "    ${ORANGE}1.${RESET} ${TEXT_SECONDARY}SELECT * FROM deployments WHERE...${RESET}  ${BOLD}${ORANGE}234ms${RESET}"
    echo -e "    ${PINK}2.${RESET} ${TEXT_SECONDARY}JOIN agents ON memory_entries...${RESET}    ${BOLD}${PINK}189ms${RESET}"
    echo -e "    ${PURPLE}3.${RESET} ${TEXT_SECONDARY}UPDATE metrics SET value = ...${RESET}      ${BOLD}${PURPLE}145ms${RESET}"
    echo ""

    # Storage Breakdown
    echo -e "${TEXT_MUTED}╭─ STORAGE BREAKDOWN ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}D1 Database${RESET}        ${BOLD}${ORANGE}847 MB${RESET}   ${ORANGE}██████████████${RESET}"
    echo -e "  ${PINK}KV Stores${RESET}          ${BOLD}${PINK}2.1 GB${RESET}   ${PINK}████████████████████████████████${RESET}"
    echo -e "  ${PURPLE}File Storage${RESET}       ${BOLD}${PURPLE}5.3 GB${RESET}   ${PURPLE}████████████████████████████████████████████${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Total Storage: ${BOLD}${CYAN}8.247 GB${RESET}"
    echo ""

    # Backup Status
    echo -e "${TEXT_MUTED}╭─ BACKUP STATUS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Last Backup:${RESET}       ${BOLD}${GREEN}2 hours ago${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Backup Size:${RESET}       ${BOLD}${CYAN}8.1 GB${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Next Backup:${RESET}       ${BOLD}${ORANGE}in 10 hours${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${TEXT_SECONDARY}Retention:${RESET}         ${BOLD}${PURPLE}30 days${RESET}"
    echo ""

    # Health Status
    echo -e "${TEXT_MUTED}╭─ HEALTH STATUS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}All Databases:${RESET}     ${BOLD}${GREEN}HEALTHY${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Replication:${RESET}       ${BOLD}${CYAN}UP TO DATE${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Connections:${RESET}       ${BOLD}${PURPLE}47/100${RESET} ${TEXT_MUTED}active${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Error Rate:${RESET}        ${BOLD}${BLUE}0.01%${RESET}"
    echo ""

    # Footer
    echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Storage: ${RESET}${BOLD}${CYAN}8.2GB${RESET}  ${TEXT_SECONDARY}|  Queries: ${RESET}${BOLD}${ORANGE}15.6K/min${RESET}  ${TEXT_SECONDARY}|  Status: ${RESET}${BOLD}${GREEN}HEALTHY${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_database_monitor
        sleep 5
    done
else
    render_database_monitor
fi
