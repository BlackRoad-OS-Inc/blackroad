#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${RED}║  🪐 TERRAFORMING SIMULATOR${RESET}"
    echo ""
    echo "  ${BOLD}Target: Mars${RESET}"
    echo ""
    echo "  ${RED}●${RESET} Current    ${GREEN}●${RESET} Target"
    echo ""
    echo -e "  ${BOLD}Atmosphere:${RESET}  ${RED}0.6%${RESET} → ${GREEN}100%${RESET} Earth"
    echo -e "  ${BOLD}Temperature:${RESET} ${CYAN}-63°C${RESET} → ${GREEN}15°C${RESET}"
    echo -e "  ${BOLD}Pressure:${RESET}    ${ORANGE}0.6 kPa${RESET} → ${GREEN}101 kPa${RESET}"
    echo -e "  ${BOLD}Water:${RESET}       ${BLUE}Ice${RESET} → ${CYAN}Liquid oceans${RESET}"
    echo ""
    echo -e "  ${BOLD}Progress:${RESET}    ${ORANGE}█${TEXT_MUTED}░░░░░░░░${RESET} ${BOLD}12%${RESET}"
    echo -e "  ${BOLD}ETA:${RESET}         ${PURPLE}847 years${RESET}"
    echo ""
    read -t 2 -n1 k && [ "$k" = "q" ] && exit 0
done
