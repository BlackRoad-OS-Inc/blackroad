#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${PURPLE}║  🌌 DARK MATTER DETECTOR${RESET}"
    echo ""
    echo "     ${TEXT_MUTED}Underground (1km depth)${RESET}"
    echo ""
    echo "        ${CYAN}◇${RESET}  ${PURPLE}◇${RESET}     ${PINK}◇${RESET}  ${TEXT_MUTED}WIMPs${RESET}"
    echo "          ${BLUE}◇${RESET}    ${PURPLE}◇${RESET}"
    echo "       ${CYAN}╔═══════════╗${RESET}"
    echo "       ${CYAN}║${RESET}${BLUE}▓▓▓▓▓▓▓▓▓${RESET}${CYAN}║${RESET} ${TEXT_MUTED}Xenon tank${RESET}"
    echo "       ${CYAN}╚═══════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}Detector:${RESET}       ${CYAN}LUX-ZEPLIN${RESET}"
    echo -e "  ${BOLD}Events/day:${RESET}     ${PURPLE}2.4${RESET}"
    echo -e "  ${BOLD}Background:${RESET}     ${GREEN}Minimal${RESET}"
    echo -e "  ${BOLD}Sensitivity:${RESET}    ${GOLD}10⁻⁴⁷ cm²${RESET}"
    echo -e "  ${BOLD}WIMP Mass:${RESET}      ${ORANGE}100 GeV/c²${RESET}"
    echo ""
    read -t 2 -n1 k && [ "$k" = "q" ] && exit 0
done
