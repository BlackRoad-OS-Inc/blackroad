#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${BLUE}║  ⏰ TIME LOOP DETECTOR${RESET}"
    echo ""
    echo "      ${CYAN}●${RESET}${TEXT_MUTED}───→${RESET}${PURPLE}●${RESET}${TEXT_MUTED}───→${RESET}${ORANGE}●${RESET}${TEXT_MUTED}───→${RESET}${PINK}●${RESET}"
    echo "      ${CYAN}↑${RESET}                   ${PINK}│${RESET}"
    echo "      ${CYAN}│${RESET}    ${RED}LOOP!${RESET}        ${PINK}│${RESET}"
    echo "      ${CYAN}│${RESET}                   ${PINK}↓${RESET}"
    echo "      ${CYAN}●${RESET}${TEXT_MUTED}←───${RESET}${GREEN}●${RESET}${TEXT_MUTED}←───${RESET}${GOLD}●${RESET}${TEXT_MUTED}←───${RESET}${PINK}●${RESET}"
    echo ""
    echo -e "  ${BOLD}Current Loop:${RESET}   ${ORANGE}#847${RESET}"
    echo -e "  ${BOLD}Duration:${RESET}       ${CYAN}24 hours${RESET}"
    echo -e "  ${BOLD}Iterations:${RESET}     ${PURPLE}8,470${RESET}"
    echo -e "  ${BOLD}Déjà vu:${RESET}        ${YELLOW}Constant${RESET}"
    echo -e "  ${BOLD}Exit Found:${RESET}     ${RED}No${RESET}"
    echo -e "  ${BOLD}Awareness:${RESET}      ${GREEN}You remember${RESET}"
    echo ""
    read -t 1 -n1 k && [ "$k" = "q" ] && exit 0
done
