#!/bin/bash

# BlackRoad OS - Wormhole Navigator
# Navigate through wormholes and exotic spacetime

source ~/blackroad-dashboards/themes.sh
load_theme

WORMHOLE_STABILITY=75
CURRENT_LOCATION="Milky Way"
DESTINATION="Andromeda"

# Show wormhole navigator
show_wormhole_navigator() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${PURPLE}🌀${RESET} ${BOLD}WORMHOLE NAVIGATOR${RESET}                                              ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Wormhole visualization
    echo -e "${TEXT_MUTED}╭─ WORMHOLE STRUCTURE ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "          ${CYAN}Origin${RESET}                       ${PURPLE}Destination${RESET}"
    echo "       ${CYAN}(Milky Way)${RESET}                    ${PURPLE}(Andromeda)${RESET}"
    echo ""
    echo "           ${CYAN}●${RESET}${CYAN}●${RESET}${CYAN}●${RESET}                            ${PURPLE}●${RESET}${PURPLE}●${RESET}${PURPLE}●${RESET}"
    echo "         ${CYAN}●${RESET}     ${CYAN}●${RESET}                        ${PURPLE}●${RESET}     ${PURPLE}●${RESET}"
    echo "       ${CYAN}●${RESET}         ${CYAN}●${RESET}                    ${PURPLE}●${RESET}         ${PURPLE}●${RESET}"
    echo "      ${CYAN}●${RESET}           ${BLUE}╲${RESET}                  ${PINK}╱${RESET}           ${PURPLE}●${RESET}"
    echo "     ${CYAN}●${RESET}             ${BLUE}╲${RESET}                ${PINK}╱${RESET}             ${PURPLE}●${RESET}"
    echo "     ${CYAN}●${RESET}              ${BLUE}╲${RESET}              ${PINK}╱${RESET}              ${PURPLE}●${RESET}"
    echo "     ${CYAN}●${RESET}               ${BLUE}╲${RESET}            ${PINK}╱${RESET}               ${PURPLE}●${RESET}"
    echo "      ${CYAN}●${RESET}              ${BLUE}╲${RESET}          ${PINK}╱${RESET}                ${PURPLE}●${RESET}"
    echo "       ${CYAN}●${RESET}              ${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}                 ${PURPLE}●${RESET}"
    echo "        ${CYAN}●${RESET}            ${GOLD}╱${RESET}${ORANGE}▓${RESET}${ORANGE}▓${RESET}${ORANGE}▓${RESET}${ORANGE}▓${RESET}${GOLD}╲${RESET}               ${PURPLE}●${RESET}"
    echo "         ${CYAN}●${RESET}          ${GOLD}│${RESET}${ORANGE}▓${RESET}${RED}████${RESET}${ORANGE}▓${RESET}${GOLD}│${RESET}              ${PURPLE}●${RESET}"
    echo "           ${CYAN}●${RESET}${CYAN}●${RESET}${CYAN}●${RESET}     ${GOLD}│${RESET}${RED}██${RESET}${BOLD}${TEXT_MUTED}◉◉${RESET}${RED}██${RESET}${GOLD}│${RESET}     ${PURPLE}●${RESET}${PURPLE}●${RESET}${PURPLE}●${RESET}  ${TEXT_MUTED}Throat${RESET}"
    echo "                     ${GOLD}│${RESET}${ORANGE}▓${RESET}${RED}████${RESET}${ORANGE}▓${RESET}${GOLD}│${RESET}"
    echo "                      ${GOLD}╲${RESET}${ORANGE}▓${RESET}${ORANGE}▓${RESET}${ORANGE}▓${RESET}${ORANGE}▓${RESET}${GOLD}╱${RESET}"
    echo "                       ${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}${GOLD}━${RESET}"
    echo ""
    echo "        ${TEXT_MUTED}2.5 million light-years in normal space${RESET}"
    echo "        ${BOLD}${GREEN}~0 seconds through wormhole${RESET}"
    echo ""

    # Navigation status
    echo -e "${TEXT_MUTED}╭─ NAVIGATION STATUS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Current Location:${RESET}    ${BOLD}${CYAN}$CURRENT_LOCATION${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Destination:${RESET}         ${BOLD}${PURPLE}$DESTINATION${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Distance:${RESET}            ${ORANGE}2.5 Mly${RESET} ${TEXT_MUTED}(conventional)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Through Wormhole:${RESET}    ${GREEN}0.00 ly${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Transit Time:${RESET}        ${BOLD}${GREEN}Instantaneous${RESET}"
    echo ""

    # Wormhole stability
    echo -e "${TEXT_MUTED}╭─ WORMHOLE STABILITY ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    local stability_color="${ORANGE}"
    [ $WORMHOLE_STABILITY -gt 80 ] && stability_color="${GREEN}"
    [ $WORMHOLE_STABILITY -lt 50 ] && stability_color="${RED}"

    echo -n "  ${BOLD}${TEXT_PRIMARY}Stability:${RESET}      "
    local bars=$((WORMHOLE_STABILITY / 5))
    for ((i=0; i<bars; i++)); do echo -n "${stability_color}█${RESET}"; done
    for ((i=bars; i<20; i++)); do echo -n "${TEXT_MUTED}░${RESET}"; done
    echo -e "  ${BOLD}${stability_color}${WORMHOLE_STABILITY}%${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Exotic Matter:${RESET}       ${CYAN}Sufficient${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Throat Radius:${RESET}       ${PURPLE}10 km${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Negative Energy:${RESET}     ${GREEN}Active${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Tidal Forces:${RESET}        ${YELLOW}Moderate${RESET}"
    echo ""

    # Casimir effect generator
    echo -e "${TEXT_MUTED}╭─ EXOTIC MATTER GENERATOR (CASIMIR EFFECT) ────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${CYAN}║${RESET}         ${CYAN}║${RESET}"
    echo "                    ${CYAN}║${RESET}  ${PURPLE}◉◉◉${RESET}  ${CYAN}║${RESET}  ${TEXT_MUTED}Parallel plates${RESET}"
    echo "                    ${CYAN}║${RESET}         ${CYAN}║${RESET}"
    echo "                     ${BLUE}╲${RESET}       ${BLUE}╱${RESET}"
    echo "                      ${BLUE}╲${RESET}     ${BLUE}╱${RESET}"
    echo "                       ${BLUE}╲${RESET}   ${BLUE}╱${RESET}    ${TEXT_MUTED}Negative${RESET}"
    echo "                        ${BLUE}╲${RESET} ${BLUE}╱${RESET}     ${TEXT_MUTED}energy${RESET}"
    echo "                    ${GREEN}━━━${RESET}${GOLD}●${RESET}${GREEN}━━━${RESET}  ${TEXT_MUTED}Extraction${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Energy Output:${RESET}       ${GREEN}-847 J/m³${RESET} ${TEXT_MUTED}(negative)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Plate Separation:${RESET}    ${CYAN}1 nm${RESET}"
    echo ""

    # Morris-Thorne metric
    echo -e "${TEXT_MUTED}╭─ MORRIS-THORNE WORMHOLE METRIC ───────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}ds² =${RESET} ${CYAN}-dt²${RESET} ${ORANGE}+ dr²${RESET} ${PURPLE}+ (r² + b²)(dθ² + sin²θ dφ²)${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}where:${RESET}"
    echo -e "    ${CYAN}b${RESET} = throat radius = ${BOLD}10 km${RESET}"
    echo -e "    ${ORANGE}r${RESET} = proper radial coordinate"
    echo -e "    ${PURPLE}No event horizon${RESET} ${TEXT_MUTED}(traversable!)${RESET}"
    echo ""

    # Network map
    echo -e "${TEXT_MUTED}╭─ WORMHOLE NETWORK ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${CYAN}Milky Way${RESET}"
    echo "                        ${CYAN}●${RESET}"
    echo "                      ${GOLD}╱${RESET} ${GOLD}│${RESET} ${GOLD}╲${RESET}"
    echo "                    ${GOLD}╱${RESET}   ${GOLD}│${RESET}   ${GOLD}╲${RESET}"
    echo "                  ${GOLD}╱${RESET}     ${GOLD}│${RESET}     ${GOLD}╲${RESET}"
    echo "      ${PURPLE}Andromeda${RESET}    ${GOLD}╱${RESET}       ${GOLD}│${RESET}       ${GOLD}╲${RESET}   ${PINK}Triangulum${RESET}"
    echo "          ${PURPLE}●${RESET}${GOLD}━━━━━━━━${RESET}        ${GOLD}━━━━━━━━${RESET}${PINK}●${RESET}"
    echo "                            ${GOLD}│${RESET}"
    echo "                            ${GOLD}│${RESET}"
    echo "                        ${ORANGE}Sombrero${RESET}"
    echo "                            ${ORANGE}●${RESET}"
    echo ""
    echo "  ${TEXT_MUTED}4 active wormholes in local group${RESET}"
    echo ""

    # Energy requirements
    echo -e "${TEXT_MUTED}╭─ ENERGY REQUIREMENTS ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}To Open:${RESET}             ${ORANGE}10⁴⁰ Joules${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}To Maintain:${RESET}         ${PURPLE}10³⁸ J/s${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Power Source:${RESET}        ${CYAN}Zero-point energy${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Efficiency:${RESET}          ${GREEN}94.7%${RESET}"
    echo ""

    # Spacetime diagram
    echo -e "${TEXT_MUTED}╭─ SPACETIME DIAGRAM ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "     ${TEXT_MUTED}Time${RESET}     ${GREEN}●${RESET} ${TEXT_MUTED}Light path (through wormhole)${RESET}"
    echo "      ${TEXT_MUTED}↑${RESET}       ${GREEN}│${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}      ${GREEN}╱${RESET} ${GREEN}╲${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}     ${GREEN}╱${RESET}   ${GREEN}╲${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}    ${GREEN}╱${RESET}     ${GREEN}╲${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}   ${GREEN}│${RESET}  ${GOLD}━${RESET}  ${GREEN}│${RESET}    ${ORANGE}●${RESET} ${TEXT_MUTED}Light path (normal space)${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}   ${GREEN}│${RESET} ${GOLD}╱${RESET} ${GOLD}╲${RESET} ${GREEN}│${RESET}   ${ORANGE}╱${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}   ${GREEN}│${RESET}${GOLD}│${RESET}${RED}◉${RESET}${GOLD}│${RESET}${GREEN}│${RESET}  ${ORANGE}╱${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}   ${GREEN}│${RESET} ${GOLD}╲${RESET} ${GOLD}╱${RESET} ${GREEN}│${RESET} ${ORANGE}╱${RESET}"
    echo "      ${TEXT_MUTED}│${RESET}   ${GREEN}│${RESET}  ${GOLD}━${RESET}  ${GREEN}│${RESET}${ORANGE}╱${RESET}"
    echo "      ${CYAN}●${RESET}   ${GREEN}╲${RESET}     ${GREEN}╱${RESET}${ORANGE}╱${RESET}   ${ORANGE}●${RESET}"
    echo "    ${TEXT_MUTED}Origin${RESET}   ${GREEN}╲${RESET}   ${GREEN}╱${RESET}  ${TEXT_MUTED}Destination${RESET}"
    echo "               ${GREEN}╲${RESET} ${GREEN}╱${RESET}"
    echo "                ${GREEN}●${RESET}"
    echo "      ${TEXT_MUTED}└────────────────→ Space${RESET}"
    echo ""

    # Safety warnings
    echo -e "${TEXT_MUTED}╭─ SAFETY WARNINGS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ $WORMHOLE_STABILITY -lt 50 ]; then
        echo -e "  ${RED}⚠${RESET}  ${BOLD}${RED}CRITICAL: Wormhole unstable!${RESET}"
        echo -e "  ${RED}⚠${RESET}  ${RED}Risk of collapse${RESET}"
    elif [ $WORMHOLE_STABILITY -lt 75 ]; then
        echo -e "  ${ORANGE}⚠${RESET}  ${BOLD}${ORANGE}WARNING: Stability below recommended${RESET}"
    else
        echo -e "  ${GREEN}✓${RESET}  ${GREEN}All systems nominal${RESET}"
    fi
    echo ""

    # Transit log
    echo -e "${TEXT_MUTED}╭─ RECENT TRANSITS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}✓${RESET} ${BOLD}Explorer-1${RESET}       ${TEXT_MUTED}2 hours ago${RESET}     ${CYAN}MW → Andromeda${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${BOLD}Science Vessel${RESET}   ${TEXT_MUTED}1 day ago${RESET}       ${PURPLE}Andromeda → MW${RESET}"
    echo -e "  ${GREEN}✓${RESET} ${BOLD}Cargo Ship${RESET}       ${TEXT_MUTED}3 days ago${RESET}      ${PINK}MW → Triangulum${RESET}"
    echo ""

    # Theoretical basis
    echo -e "${TEXT_MUTED}╭─ THEORETICAL BASIS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${PURPLE}●${RESET} Based on Einstein-Rosen bridge (1935)"
    echo -e "  ${CYAN}●${RESET} Morris-Thorne traversable wormhole (1988)"
    echo -e "  ${ORANGE}●${RESET} Requires exotic matter with negative energy density"
    echo -e "  ${PINK}●${RESET} Violations of null energy condition necessary"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[E]${RESET} Engage  ${TEXT_SECONDARY}[S]${RESET} Stabilize  ${TEXT_SECONDARY}[D]${RESET} Destination  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_wormhole_navigator

        # Fluctuate stability
        WORMHOLE_STABILITY=$((WORMHOLE_STABILITY + (RANDOM % 11 - 5)))
        [ $WORMHOLE_STABILITY -gt 100 ] && WORMHOLE_STABILITY=100
        [ $WORMHOLE_STABILITY -lt 30 ] && WORMHOLE_STABILITY=30

        read -t 2 -n1 key

        case "$key" in
            'e'|'E')
                if [ $WORMHOLE_STABILITY -gt 50 ]; then
                    echo -e "\n${GREEN}Engaging wormhole drive...${RESET}"
                    echo -e "${CYAN}Entering throat...${RESET}"
                    sleep 1
                    echo -e "${PURPLE}Traversing...${RESET}"
                    sleep 1
                    echo -e "${GREEN}✓ Arrived at $DESTINATION!${RESET}"
                    CURRENT_LOCATION=$DESTINATION
                    sleep 2
                else
                    echo -e "\n${RED}⚠ Wormhole too unstable to traverse!${RESET}"
                    sleep 2
                fi
                ;;
            's'|'S')
                echo -e "\n${CYAN}Injecting exotic matter...${RESET}"
                sleep 1
                WORMHOLE_STABILITY=$((WORMHOLE_STABILITY + 15))
                [ $WORMHOLE_STABILITY -gt 100 ] && WORMHOLE_STABILITY=100
                echo -e "${GREEN}✓ Stability increased to ${WORMHOLE_STABILITY}%${RESET}"
                sleep 1
                ;;
            'd'|'D')
                if [ "$DESTINATION" = "Andromeda" ]; then
                    DESTINATION="Triangulum"
                else
                    DESTINATION="Andromeda"
                fi
                echo -e "\n${PURPLE}Destination set to: $DESTINATION${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Wormhole navigation ended${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
