#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${RED}║  💥 UNIVERSAL RESET BUTTON${RESET}"
    echo ""
    echo "        ${RED}╔═════════════╗${RESET}"
    echo "        ${RED}║${RESET}             ${RED}║${RESET}"
    echo "        ${RED}║${RESET}   ${GOLD}RESET${RESET}    ${RED}║${RESET}"
    echo "        ${RED}║${RESET}  ${GOLD}UNIVERSE${RESET}  ${RED}║${RESET}"
    echo "        ${RED}║${RESET}             ${RED}║${RESET}"
    echo "        ${RED}╚═════════════╝${RESET}"
    echo "            ${TEXT_MUTED}[DO NOT PRESS]${RESET}"
    echo ""
    echo -e "  ${RED}⚠ WARNING ⚠${RESET}"
    echo ""
    echo -e "  ${BOLD}Action:${RESET}         ${RED}Reset all existence${RESET}"
    echo -e "  ${BOLD}Affected:${RESET}       ${PURPLE}∞ universes${RESET}"
    echo -e "  ${BOLD}Recovery:${RESET}       ${RED}None${RESET}"
    echo -e "  ${BOLD}Backup:${RESET}         ${ORANGE}Last: 13.8B years ago${RESET}"
    echo -e "  ${BOLD}Confirmation:${RESET}   ${YELLOW}Required${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Press 'r' to reset everything...${RESET}"
    echo ""
    read -t 1 -n1 k
    if [ "$k" = "r" ]; then
        echo -e "\n${RED}⚠ ARE YOU ABSOLUTELY SURE? (y/n)${RESET}"
        read -n1 confirm
        [ "$confirm" = "y" ] && echo -e "\n${GOLD}Just kidding! That would be crazy! 😄${RESET}" && sleep 2
    fi
    [ "$k" = "q" ] && exit 0
done
