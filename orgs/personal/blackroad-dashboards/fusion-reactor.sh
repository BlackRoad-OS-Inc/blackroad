#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${ORANGE}║  ⚛️  FUSION REACTOR MONITOR${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}╭─ TOKAMAK STATUS${RESET}"
    echo "        ${ORANGE}◉${RESET} Plasma torus"
    echo "     ${CYAN}╱${RESET}${ORANGE}███${RESET}${CYAN}╲${RESET}"  
    echo "   ${CYAN}│${RESET}${ORANGE}█████${RESET}${CYAN}│${RESET} ${BOLD}150M°C${RESET}"
    echo "     ${CYAN}╲${RESET}${ORANGE}███${RESET}${CYAN}╱${RESET}"
    echo ""
    echo -e "  ${BOLD}Plasma Temp:${RESET}    ${RED}150 million °C${RESET}"
    echo -e "  ${BOLD}Confinement:${RESET}    ${GREEN}█████${RESET} ${BOLD}Q=10.2${RESET}"
    echo -e "  ${BOLD}Power Output:${RESET}   ${GOLD}500 MW${RESET}"
    echo -e "  ${BOLD}Efficiency:${RESET}     ${CYAN}147%${RESET} ${TEXT_MUTED}(net gain!)${RESET}"
    echo ""
    read -t 2 -n1 k && [ "$k" = "q" ] && exit 0
done
