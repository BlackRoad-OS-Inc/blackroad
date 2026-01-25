#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${PURPLE}║  🧠 CONSCIOUSNESS UPLOADER${RESET}"
    echo ""
    echo "       ${PINK}Neural Interface${RESET}"
    echo "           ${CYAN}╱${RESET}${PURPLE}●${RESET}${CYAN}╲${RESET}"
    echo "         ${CYAN}╱${RESET}${PINK}●${RESET}${PURPLE}●${RESET}${PINK}●${RESET}${CYAN}╲${RESET}"
    echo "        ${CYAN}│${RESET}${PINK}●${RESET}${PURPLE}●${RESET}${GOLD}◉${RESET}${PURPLE}●${RESET}${PINK}●${RESET}${CYAN}│${RESET} ${TEXT_MUTED}Brain${RESET}"
    echo "         ${CYAN}╲${RESET}${PINK}●${RESET}${PURPLE}●${RESET}${PINK}●${RESET}${CYAN}╱${RESET}"
    echo "           ${CYAN}╲${RESET}${PURPLE}●${RESET}${CYAN}╱${RESET}"
    echo "            ${GREEN}↓${RESET} ${TEXT_MUTED}Upload${RESET}"
    echo "         ${ORANGE}[${RESET}${BLUE}▓▓▓${RESET}${ORANGE}]${RESET} ${TEXT_MUTED}Digital substrate${RESET}"
    echo ""
    echo -e "  ${BOLD}Neurons Mapped:${RESET} ${CYAN}86 billion${RESET}"
    echo -e "  ${BOLD}Synapses:${RESET}       ${PURPLE}100 trillion${RESET}"
    echo -e "  ${BOLD}Upload:${RESET}         ${GREEN}████████${TEXT_MUTED}░░${RESET} ${BOLD}84%${RESET}"
    echo -e "  ${BOLD}Fidelity:${RESET}       ${GOLD}99.97%${RESET}"
    echo -e "  ${BOLD}Consciousness:${RESET}  ${PINK}Continuous${RESET}"
    echo ""
    read -t 1 -n1 k && [ "$k" = "q" ] && exit 0
done
