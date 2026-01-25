#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${GOLD}║  ⚡ ANTIMATTER CONTAINMENT${RESET}"
    echo ""
    echo "     ${PURPLE}Magnetic bottle${RESET}"
    echo "        ${BLUE}╱${RESET}${CYAN}───${RESET}${BLUE}╲${RESET}"
    echo "       ${BLUE}│${RESET} ${GOLD}⚛${RESET} ${GOLD}⚛${RESET} ${BLUE}│${RESET} ${TEXT_MUTED}Positrons${RESET}"
    echo "        ${BLUE}╲${RESET}${CYAN}───${RESET}${BLUE}╱${RESET}"
    echo "     ${ORANGE}═══╬═══${RESET} ${TEXT_MUTED}EM field${RESET}"
    echo ""
    echo -e "  ${BOLD}Contained:${RESET}      ${GOLD}1.2 mg antihydrogen${RESET}"
    echo -e "  ${BOLD}Field Strength:${RESET} ${CYAN}8.4 Tesla${RESET}"
    echo -e "  ${BOLD}Vacuum:${RESET}         ${GREEN}10⁻¹⁵ torr${RESET}"
    echo -e "  ${BOLD}Temperature:${RESET}    ${BLUE}4 Kelvin${RESET}"
    echo -e "  ${BOLD}Stability:${RESET}      ${GREEN}99.97%${RESET}"
    echo -e "  ${BOLD}Energy:${RESET}         ${ORANGE}25 GJ potential${RESET}"
    echo ""
    read -t 2 -n1 k && [ "$k" = "q" ] && exit 0
done
