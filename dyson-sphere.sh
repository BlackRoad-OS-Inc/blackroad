#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${GOLD}║  ☀️  DYSON SPHERE BUILDER${RESET}"
    echo ""
    echo "           ${GOLD}☀${RESET} ${TEXT_MUTED}Sun${RESET}"
    echo "         ${CYAN}╱${RESET}${CYAN}─${RESET}${GOLD}│${RESET}${CYAN}─${RESET}${CYAN}╲${RESET}"
    echo "       ${CYAN}╱${RESET}   ${GOLD}│${RESET}   ${CYAN}╲${RESET}"
    echo "     ${CYAN}●${RESET}     ${GOLD}│${RESET}     ${CYAN}●${RESET} ${TEXT_MUTED}Collectors${RESET}"
    echo "       ${CYAN}╲${RESET}   ${GOLD}│${RESET}   ${CYAN}╱${RESET}"
    echo "         ${CYAN}╲${RESET}${CYAN}─${RESET}${GOLD}│${RESET}${CYAN}─${RESET}${CYAN}╱${RESET}"
    echo ""
    echo -e "  ${BOLD}Radius:${RESET}         ${CYAN}1 AU (150M km)${RESET}"
    echo -e "  ${BOLD}Collectors:${RESET}     ${PURPLE}8.47 million${RESET}"
    echo -e "  ${BOLD}Coverage:${RESET}       ${ORANGE}█${TEXT_MUTED}░░░░${RESET} ${BOLD}23%${RESET}"
    echo -e "  ${BOLD}Power Output:${RESET}   ${GOLD}3.8×10²⁶ W${RESET}"
    echo -e "  ${BOLD}Construction:${RESET}   ${GREEN}847 years remaining${RESET}"
    echo -e "  ${BOLD}Resources:${RESET}      ${PINK}Mercury being mined${RESET}"
    echo ""
    read -t 2 -n1 k && [ "$k" = "q" ] && exit 0
done
