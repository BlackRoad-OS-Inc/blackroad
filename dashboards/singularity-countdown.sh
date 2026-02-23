#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${RED}║  🤖 SINGULARITY COUNTDOWN${RESET}"
    echo ""
    echo "      ${ORANGE}●${RESET} ${TEXT_MUTED}AI Capability${RESET}"
    echo "      ${ORANGE}│${RESET}${ORANGE}▲${RESET}"
    echo "      ${ORANGE}│${RESET} ${ORANGE}│${RESET}${ORANGE}▲${RESET}"
    echo "      ${ORANGE}│${RESET} ${ORANGE}│${RESET} ${ORANGE}│${RESET}${RED}▲${RESET}"
    echo "      ${ORANGE}│${RESET} ${ORANGE}│${RESET} ${ORANGE}│${RESET} ${RED}│${RESET}${RED}█${RESET} ${TEXT_MUTED}Exponential!${RESET}"
    echo "      ${GREEN}●${RESET}${ORANGE}─${RESET}${ORANGE}●${RESET}${ORANGE}─${RESET}${ORANGE}●${RESET}${RED}─${RESET}${RED}●${RESET}"
    echo "      ${TEXT_MUTED}└──────→ Time${RESET}"
    echo ""
    echo -e "  ${BOLD}ETA:${RESET}            ${RED}2.3 years${RESET}"
    echo -e "  ${BOLD}AI Progress:${RESET}    ${ORANGE}████████${TEXT_MUTED}░░${RESET} ${BOLD}87%${RESET}"
    echo -e "  ${BOLD}Moore's Law:${RESET}    ${GREEN}Active${RESET}"
    echo -e "  ${BOLD}Recursion:${RESET}      ${PURPLE}Self-improving${RESET}"
    echo -e "  ${BOLD}Human Control:${RESET}  ${YELLOW}Decreasing${RESET}"
    echo -e "  ${BOLD}Outcome:${RESET}        ${RAINBOW}Unknown${RESET}"
    echo ""
    read -t 1 -n1 k && [ "$k" = "q" ] && exit 0
done
