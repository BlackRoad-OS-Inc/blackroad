#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${RAINBOW}║  🌈 PARALLEL REALITY SWITCHER${RESET}"
    echo ""
    echo "   ${CYAN}Reality A${RESET}  ${PURPLE}Reality B${RESET}  ${ORANGE}Reality C${RESET}"
    echo "       ${CYAN}│${RESET}          ${PURPLE}│${RESET}          ${ORANGE}│${RESET}"
    echo "       ${CYAN}●${RESET}          ${PURPLE}●${RESET}          ${ORANGE}●${RESET}"
    echo "       ${CYAN}│${RESET}          ${PURPLE}│${RESET}          ${ORANGE}│${RESET}"
    echo "       ${CYAN}└${RESET}${TEXT_MUTED}──────────${RESET}${GREEN}◉${RESET}${TEXT_MUTED}──────────${RESET}${ORANGE}┘${RESET} ${TEXT_MUTED}You${RESET}"
    echo ""
    echo -e "  ${BOLD}Current:${RESET}        ${GREEN}Reality B${RESET}"
    echo -e "  ${BOLD}Divergence:${RESET}     ${CYAN}0.0023%${RESET} ${TEXT_MUTED}from Prime${RESET}"
    echo -e "  ${BOLD}Stability:${RESET}      ${GREEN}97.4%${RESET}"
    echo -e "  ${BOLD}Accessible:${RESET}     ${PURPLE}∞ realities${RESET}"
    echo -e "  ${BOLD}Switches:${RESET}       ${ORANGE}847 today${RESET}"
    echo ""
    read -t 1 -n1 k && [ "$k" = "q" ] && exit 0
done
