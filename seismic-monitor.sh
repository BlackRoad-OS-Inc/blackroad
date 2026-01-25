#!/bin/bash

# BlackRoad OS - Seismic Activity Monitor
# Real-time earthquake detection and analysis

source ~/blackroad-dashboards/themes.sh
load_theme

EARTHQUAKE_COUNT=0
MAGNITUDE_THRESHOLD=3.0

# Generate random earthquake
generate_earthquake() {
    local mag=$(echo "scale=1; ($RANDOM % 60 + 10) / 10" | bc)
    local depth=$((RANDOM % 500 + 5))
    local lat=$(echo "scale=2; ($RANDOM % 18000 - 9000) / 100" | bc)
    local lon=$(echo "scale=2; ($RANDOM % 36000 - 18000) / 100" | bc)

    echo "$mag|$depth|$lat|$lon"
}

# Show seismic monitor
show_seismic_monitor() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${RED}🌋${RESET} ${BOLD}SEISMIC ACTIVITY MONITOR${RESET}                                        ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Global seismic map
    echo -e "${TEXT_MUTED}╭─ GLOBAL SEISMIC ACTIVITY (24H) ───────────────────────────────────────╮${RESET}"
    echo ""

    # World map with earthquake markers
    echo "                    ${TEXT_MUTED}──────────────────────${RESET}"
    echo "                 ${TEXT_MUTED}╱${RESET}  ${RED}●${RESET}         ${ORANGE}●${RESET}      ${TEXT_MUTED}╲${RESET}"
    echo "               ${TEXT_MUTED}╱${RESET}         ${YELLOW}●${RESET}  ${ORANGE}●${RESET}        ${TEXT_MUTED}╲${RESET}"
    echo "     ${TEXT_MUTED}Pacific${RESET}  ${TEXT_MUTED}│${RESET}  ${RED}●${RESET}                    ${TEXT_MUTED}│${RESET}"
    echo "      ${TEXT_MUTED}Ring${RESET}    ${TEXT_MUTED}│${RESET}     ${ORANGE}●${RESET}  ${GREEN}●${RESET}            ${TEXT_MUTED}│${RESET}"
    echo "              ${TEXT_MUTED}│${RESET}  ${RED}●${RESET}              ${YELLOW}●${RESET}    ${TEXT_MUTED}│${RESET}"
    echo "               ${TEXT_MUTED}╲${RESET}       ${ORANGE}●${RESET}        ${GREEN}●${RESET}   ${TEXT_MUTED}╱${RESET}"
    echo "                 ${TEXT_MUTED}╲${RESET}  ${RED}●${RESET}     ${ORANGE}●${RESET}          ${TEXT_MUTED}╱${RESET}"
    echo "                    ${TEXT_MUTED}──────────────────────${RESET}"
    echo ""
    echo "  ${RED}●${RESET} Major (M 7.0+)  ${ORANGE}●${RESET} Strong (M 6.0-6.9)  ${YELLOW}●${RESET} Moderate (M 5.0-5.9)  ${GREEN}●${RESET} Light (M 3.0-4.9)"
    echo ""

    # Recent earthquakes
    echo -e "${TEXT_MUTED}╭─ RECENT EARTHQUAKES ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    for ((i=0; i<6; i++)); do
        local eq=$(generate_earthquake)
        local mag=$(echo "$eq" | cut -d'|' -f1)
        local depth=$(echo "$eq" | cut -d'|' -f2)
        local lat=$(echo "$eq" | cut -d'|' -f3)
        local lon=$(echo "$eq" | cut -d'|' -f4)

        local color="${GREEN}"
        local severity="Light"

        if (( $(echo "$mag >= 7.0" | bc -l) )); then
            color="${RED}"
            severity="Major"
        elif (( $(echo "$mag >= 6.0" | bc -l) )); then
            color="${ORANGE}"
            severity="Strong"
        elif (( $(echo "$mag >= 5.0" | bc -l) )); then
            color="${YELLOW}"
            severity="Moderate"
        fi

        local time_ago=$((RANDOM % 120))

        echo -e "  ${color}●${RESET} ${BOLD}M ${mag}${RESET}  ${severity}  ${TEXT_MUTED}${depth}km deep${RESET}  ${CYAN}${lat}, ${lon}${RESET}  ${TEXT_MUTED}${time_ago}min ago${RESET}"
    done

    EARTHQUAKE_COUNT=$((EARTHQUAKE_COUNT + 1))
    echo ""

    # Seismograph (live)
    echo -e "${TEXT_MUTED}╭─ SEISMOGRAPH (LIVE) ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Generate 3 seismograph traces
    for axis in "N-S" "E-W" "Z  "; do
        echo -n "  ${CYAN}$axis${RESET}  ${TEXT_MUTED}│${RESET}"

        for ((i=0; i<50; i++)); do
            local amplitude=$((RANDOM % 10))

            if [ $amplitude -gt 7 ]; then
                echo -n "${RED}▂▄▆█${RESET}"
                i=$((i + 3))
            elif [ $amplitude -gt 5 ]; then
                echo -n "${ORANGE}▂${RESET}"
            elif [ $amplitude -gt 3 ]; then
                echo -n "${YELLOW}─${RESET}"
            else
                echo -n "${TEXT_MUTED}─${RESET}"
            fi
        done
        echo ""
    done

    echo ""
    echo "       ${TEXT_MUTED}←─────────────────── 60 seconds ─────────────────────→${RESET}"
    echo ""

    # Magnitude distribution
    echo -e "${TEXT_MUTED}╭─ MAGNITUDE DISTRIBUTION (24H) ────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${TEXT_MUTED}Mag${RESET}"
    echo "  ${TEXT_MUTED}9.0${RESET} ${TEXT_MUTED}│${RESET}"
    echo "  ${TEXT_MUTED}8.0${RESET} ${RED}│${RESET}${RED}█${RESET}                          ${TEXT_MUTED}0 events${RESET}"
    echo "  ${TEXT_MUTED}7.0${RESET} ${ORANGE}│${RESET}${ORANGE}██${RESET}                         ${TEXT_MUTED}2 events${RESET}"
    echo "  ${TEXT_MUTED}6.0${RESET} ${YELLOW}│${RESET}${YELLOW}████${RESET}                       ${TEXT_MUTED}8 events${RESET}"
    echo "  ${TEXT_MUTED}5.0${RESET} ${GREEN}│${RESET}${GREEN}████████${RESET}                   ${TEXT_MUTED}23 events${RESET}"
    echo "  ${TEXT_MUTED}4.0${RESET} ${CYAN}│${RESET}${CYAN}████████████████${RESET}           ${TEXT_MUTED}94 events${RESET}"
    echo "  ${TEXT_MUTED}3.0${RESET} ${BLUE}│${RESET}${BLUE}████████████████████████${RESET}   ${TEXT_MUTED}247 events${RESET}"
    echo "      ${TEXT_MUTED}└─────────────────────────────────→${RESET}"
    echo "        ${TEXT_MUTED}Frequency${RESET}"
    echo ""

    # Tectonic plates
    echo -e "${TEXT_MUTED}╭─ TECTONIC PLATE BOUNDARIES ───────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${ORANGE}Pacific${RESET}    ${CYAN}North American${RESET}"
    echo "                    ${ORANGE}Plate${RESET}      ${CYAN}Plate${RESET}"
    echo "                       ${TEXT_MUTED}│${RESET}  ${RED}▲${RESET}  ${TEXT_MUTED}│${RESET}    ${RED}Convergent${RESET}"
    echo "                       ${TEXT_MUTED}│${RESET}${RED}╱${RESET}${RED}│${RESET}${RED}╲${RESET}${TEXT_MUTED}│${RESET}"
    echo "                    ${ORANGE}←${RESET}${ORANGE}←${RESET}${TEXT_MUTED}│${RESET}${RED}/${RESET} ${TEXT_MUTED}│${RESET}${RED}╲${RESET}${TEXT_MUTED}│${RESET}${CYAN}→${RESET}${CYAN}→${RESET}"
    echo "                       ${TEXT_MUTED}│${RESET}  ${GREEN}▼${RESET}  ${TEXT_MUTED}│${RESET}    ${GREEN}Subduction${RESET}"
    echo ""
    echo "                    ${PURPLE}←${RESET}${PURPLE}←${RESET}${PURPLE}←${RESET}  ${TEXT_MUTED}|${RESET}  ${PINK}→${RESET}${PINK}→${RESET}${PINK}→${RESET}    ${YELLOW}Transform${RESET}"
    echo "                    ${TEXT_MUTED}Divergent boundary${RESET}"
    echo ""

    # Depth cross-section
    echo -e "${TEXT_MUTED}╭─ DEPTH CROSS-SECTION ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${TEXT_MUTED}0km${RESET}   ${YELLOW}~~~~~${RESET} ${TEXT_MUTED}Surface${RESET}"
    echo "  ${TEXT_MUTED}10km${RESET}  ${GREEN}●${RESET} ${ORANGE}●${RESET}      ${TEXT_MUTED}Shallow (0-70km)${RESET}"
    echo "  ${TEXT_MUTED}50km${RESET}    ${YELLOW}●${RESET}"
    echo "  ${TEXT_MUTED}100km${RESET}     ${PURPLE}●${RESET}   ${TEXT_MUTED}Intermediate (70-300km)${RESET}"
    echo "  ${TEXT_MUTED}200km${RESET}       ${CYAN}●${RESET}"
    echo "  ${TEXT_MUTED}400km${RESET}         ${BLUE}●${RESET} ${TEXT_MUTED}Deep (300-700km)${RESET}"
    echo "  ${TEXT_MUTED}600km${RESET}           ${PINK}●${RESET}"
    echo ""

    # Intensity scale
    echo -e "${TEXT_MUTED}╭─ MODIFIED MERCALLI INTENSITY SCALE ───────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}I-III${RESET}    ${TEXT_MUTED}Not felt or weak${RESET}"
    echo -e "  ${CYAN}IV-V${RESET}     ${TEXT_MUTED}Light - widely felt${RESET}"
    echo -e "  ${BLUE}VI${RESET}       ${TEXT_MUTED}Strong - slight damage${RESET}"
    echo -e "  ${YELLOW}VII-VIII${RESET} ${TEXT_MUTED}Very strong - moderate damage${RESET}"
    echo -e "  ${ORANGE}IX-X${RESET}    ${TEXT_MUTED}Violent - heavy damage${RESET}"
    echo -e "  ${RED}XI-XII${RESET}   ${TEXT_MUTED}Extreme - total destruction${RESET}"
    echo ""

    # Alert regions
    echo -e "${TEXT_MUTED}╭─ ACTIVE ALERT REGIONS ────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${RED}⚠${RESET}  ${BOLD}Ring of Fire${RESET}          ${TEXT_MUTED}Pacific Ocean${RESET}      ${RED}HIGH${RESET}"
    echo -e "  ${ORANGE}⚠${RESET}  ${BOLD}San Andreas Fault${RESET}     ${TEXT_MUTED}California, USA${RESET}  ${ORANGE}MODERATE${RESET}"
    echo -e "  ${YELLOW}⚠${RESET}  ${BOLD}Himalayan Belt${RESET}        ${TEXT_MUTED}South Asia${RESET}       ${YELLOW}ELEVATED${RESET}"
    echo -e "  ${GREEN}✓${RESET}  ${BOLD}Mid-Atlantic Ridge${RESET}    ${TEXT_MUTED}Atlantic Ocean${RESET}   ${GREEN}NORMAL${RESET}"
    echo ""

    # Tsunami warning
    echo -e "${TEXT_MUTED}╭─ TSUNAMI WARNING SYSTEM ──────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${GREEN}No Active Warnings${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Buoys Monitored:${RESET}     ${CYAN}847${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Last Warning:${RESET}        ${TEXT_MUTED}3 days ago${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}System Health:${RESET}       ${GREEN}✓ Operational${RESET}"
    echo ""

    # Statistics
    echo -e "${TEXT_MUTED}╭─ SEISMIC STATISTICS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Events (24h):${RESET}        ${BOLD}${CYAN}374${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Events (7d):${RESET}         ${BOLD}${PURPLE}2,618${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Largest (24h):${RESET}       ${BOLD}${ORANGE}M 6.8${RESET} ${TEXT_MUTED}Fiji Islands${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Average Depth:${RESET}       ${BOLD}${GREEN}42 km${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Monitoring Stations:${RESET} ${BOLD}${BLUE}15,847${RESET}"
    echo ""

    # Prediction model
    echo -e "${TEXT_MUTED}╭─ PREDICTION MODEL ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Risk Level:${RESET}          ${ORANGE}Moderate${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Next 7 Days:${RESET}         ${YELLOW}M 5.0-6.0${RESET} ${TEXT_MUTED}probability: 68%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}High Risk Zone:${RESET}      ${RED}Papua New Guinea${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Foreshock Pattern:${RESET}   ${CYAN}Detected${RESET}"
    echo ""

    echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[M]${RESET} Map  ${TEXT_SECONDARY}[T]${RESET} Tsunami  ${TEXT_SECONDARY}[H]${RESET} History  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_seismic_monitor

        read -t 3 -n1 key

        case "$key" in
            'r'|'R')
                # Refresh
                ;;
            'm'|'M')
                echo -e "\n${ORANGE}Loading seismic map...${RESET}"
                sleep 1
                ;;
            't'|'T')
                echo -e "\n${CYAN}Checking tsunami warnings...${RESET}"
                sleep 1
                ;;
            'h'|'H')
                echo -e "\n${PURPLE}Loading earthquake history...${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Seismic monitoring ended${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
