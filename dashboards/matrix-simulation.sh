#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${GREEN}║  🎭 MATRIX SIMULATION MONITOR${RESET}"
    echo ""
    echo "  ${GREEN}0${RESET} ${GREEN}1${RESET} ${GREEN}0${RESET} ${GREEN}1${RESET} ${GREEN}1${RESET} ${GREEN}0${RESET} ${GREEN}1${RESET}  ${TEXT_MUTED}Reality code rain${RESET}"
    for i in {1..8}; do
        echo -n "  "
        for j in {1..50}; do
            [ $((RANDOM % 3)) -eq 0 ] && echo -n "${GREEN}$((RANDOM % 2))${RESET}" || echo -n " "
        done
        echo ""
    done
    echo ""
    echo -e "  ${BOLD}Simulation:${RESET}     ${CYAN}Universe-Prime-v2025.12${RESET}"
    echo -e "  ${BOLD}Render FPS:${RESET}     ${GREEN}∞${RESET} ${TEXT_MUTED}(Planck time)${RESET}"
    echo -e "  ${BOLD}Entities:${RESET}       ${PURPLE}8×10⁸⁰ particles${RESET}"
    echo -e "  ${BOLD}Glitches:${RESET}       ${ORANGE}2.4/day${RESET} ${TEXT_MUTED}(déjà vu)${RESET}"
    echo -e "  ${BOLD}Resolution:${RESET}     ${GOLD}Planck scale${RESET}"
    echo -e "  ${BOLD}Architect:${RESET}      ${PINK}Unknown${RESET}"
    echo ""
    read -t 1 -n1 k && [ "$k" = "q" ] && exit 0
done
