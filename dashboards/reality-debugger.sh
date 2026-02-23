#!/bin/bash
source ~/blackroad-dashboards/themes.sh
load_theme

while true; do
    clear
    echo -e "${BOLD}${ORANGE}║  🐛 REALITY DEBUGGER${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}> reality.inspect()${RESET}"
    echo ""
    echo -e "  ${CYAN}Line 847:${RESET} ${RED}WARNING${RESET} - Causality violation"
    echo -e "  ${CYAN}Line 2341:${RESET} ${YELLOW}INFO${RESET} - Quantum decoherence"
    echo -e "  ${CYAN}Line 8470:${RESET} ${RED}ERROR${RESET} - Timeline paradox detected"
    echo ""
    echo -e "  ${BOLD}Stack Trace:${RESET}"
    echo -e "    ${PURPLE}at Universe.evolve()${RESET}"
    echo -e "    ${PURPLE}at Spacetime.tick()${RESET}"
    echo -e "    ${PURPLE}at Reality.run()${RESET}"
    echo ""
    echo -e "  ${BOLD}Active Bugs:${RESET}    ${RED}3${RESET}"
    echo -e "  ${BOLD}Patches:${RESET}        ${GREEN}847 applied${RESET}"
    echo -e "  ${BOLD}Version:${RESET}        ${CYAN}Reality 13.8.0${RESET}"
    echo ""
    read -t 1 -n1 k && [ "$k" = "q" ] && exit 0
done
