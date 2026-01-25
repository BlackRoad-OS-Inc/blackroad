#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${CYAN}║  ❄️  CRYOGENIC STASIS CHAMBER${RESET}"
    echo ""
    echo "        ${CYAN}╔═══════╗${RESET}"
    echo "        ${CYAN}║${RESET} ${BLUE}●${RESET} ${BLUE}●${RESET} ${BLUE}●${RESET} ${CYAN}║${RESET} ${TEXT_MUTED}Occupied pods${RESET}"
    echo "        ${CYAN}╚═══════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}Pod 1:${RESET}          ${BLUE}●${RESET} ${GREEN}STABLE${RESET}  ${CYAN}-196°C${RESET}"
    echo -e "  ${BOLD}Vitals:${RESET}         ${GREEN}Suspended${RESET}"
    echo -e "  ${BOLD}Duration:${RESET}       ${PURPLE}2,847 days${RESET}"
    echo -e "  ${BOLD}Cellular:${RESET}       ${GREEN}No degradation${RESET}"
    echo -e "  ${BOLD}Revival Ready:${RESET}  ${GOLD}98.7%${RESET}"
    echo ""
    read -t 2 -n1 k && [ "$k" = "q" ] && exit 0
done
