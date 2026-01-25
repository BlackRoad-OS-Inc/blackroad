#!/bin/bash

# BlackRoad OS - Ocean Current Visualizer
# Map and analyze global ocean currents

source ~/blackroad-dashboards/themes.sh
load_theme

CURRENT_DEPTH=0
TEMP_LAYER="surface"
ANIMATION_FRAME=0

# Show ocean currents dashboard
show_ocean_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${CYAN}🌊${RESET} ${BOLD}OCEAN CURRENT VISUALIZER${RESET}                                        ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Global ocean currents map
    echo -e "${TEXT_MUTED}╭─ GLOBAL OCEAN CURRENTS ───────────────────────────────────────────────╮${RESET}"
    echo ""

    # Animated current flow
    local frame=$((ANIMATION_FRAME % 4))

    echo "                         ${TEXT_MUTED}North${RESET}"
    echo "                    ${TEXT_MUTED}──────────────${RESET}"
    echo ""

    # Pacific Ocean
    echo "     ${TEXT_MUTED}Pacific${RESET}         ${CYAN}→${RESET}${CYAN}→${RESET}${CYAN}→${RESET}"
    echo "                      ${CYAN}↓${RESET}    ${CYAN}↓${RESET}"
    echo "       ${ORANGE}●${RESET}           ${CYAN}←${RESET}${CYAN}←${RESET}${CYAN}←${RESET}${CYAN}↓${RESET}"
    echo "                   ${CYAN}↑${RESET}      ${CYAN}↓${RESET}"

    # Atlantic Ocean
    echo "     ${TEXT_MUTED}Atlantic${RESET}     ${PURPLE}→${RESET}${PURPLE}→${RESET}  ${CYAN}↑${RESET}${CYAN}←${RESET}${CYAN}←${RESET}"
    echo "                   ${PURPLE}↓${RESET}  ${PURPLE}↓${RESET}"
    echo "       ${GREEN}●${RESET}         ${PURPLE}←${RESET}${PURPLE}←${RESET}${PURPLE}←${RESET}"
    echo ""

    echo "  ${CYAN}→${RESET} Warm currents   ${PURPLE}→${RESET} Cold currents   ${ORANGE}●${RESET} Pacific   ${GREEN}●${RESET} Atlantic"
    echo ""

    # Major currents
    echo -e "${TEXT_MUTED}╭─ MAJOR CURRENTS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${CYAN}Warm Currents:${RESET}"
    echo -e "    ${ORANGE}●${RESET} ${BOLD}Gulf Stream${RESET}        ${TEXT_MUTED}2.5 m/s  |  24°C  |  Atlantic${RESET}"
    echo -e "    ${ORANGE}●${RESET} ${BOLD}Kuroshio${RESET}           ${TEXT_MUTED}1.8 m/s  |  22°C  |  Pacific${RESET}"
    echo -e "    ${ORANGE}●${RESET} ${BOLD}Brazil Current${RESET}     ${TEXT_MUTED}0.8 m/s  |  23°C  |  Atlantic${RESET}"
    echo ""

    echo -e "  ${PURPLE}Cold Currents:${RESET}"
    echo -e "    ${CYAN}●${RESET} ${BOLD}Labrador${RESET}           ${TEXT_MUTED}0.6 m/s  |  4°C   |  Atlantic${RESET}"
    echo -e "    ${CYAN}●${RESET} ${BOLD}California${RESET}         ${TEXT_MUTED}0.5 m/s  |  12°C  |  Pacific${RESET}"
    echo -e "    ${CYAN}●${RESET} ${BOLD}Canary${RESET}             ${TEXT_MUTED}0.7 m/s  |  18°C  |  Atlantic${RESET}"
    echo ""

    # Ocean temperature layers
    echo -e "${TEXT_MUTED}╭─ TEMPERATURE BY DEPTH ────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "   ${TEXT_MUTED}Depth${RESET}"
    echo "     ${TEXT_MUTED}0m${RESET}  ${RED}████████████████████${RESET}              ${BOLD}24°C${RESET}  ${TEXT_MUTED}Surface${RESET}"
    echo "   ${TEXT_MUTED}100m${RESET}  ${ORANGE}████████████████${TEXT_MUTED}░░░░${RESET}              ${BOLD}18°C${RESET}  ${TEXT_MUTED}Thermocline${RESET}"
    echo "   ${TEXT_MUTED}500m${RESET}  ${YELLOW}████████${TEXT_MUTED}░░░░░░░░░░░░${RESET}              ${BOLD}8°C${RESET}"
    echo "  ${TEXT_MUTED}1000m${RESET}  ${GREEN}████${TEXT_MUTED}░░░░░░░░░░░░░░░░${RESET}              ${BOLD}4°C${RESET}   ${TEXT_MUTED}Deep ocean${RESET}"
    echo "  ${TEXT_MUTED}4000m${RESET}  ${CYAN}██${TEXT_MUTED}░░░░░░░░░░░░░░░░░░${RESET}              ${BOLD}2°C${RESET}   ${TEXT_MUTED}Abyssal${RESET}"
    echo ""

    # 3D ocean visualization
    echo -e "${TEXT_MUTED}╭─ 3D OCEAN VISUALIZATION ──────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${CYAN}~~~~~~~~~${RESET} ${TEXT_MUTED}Surface${RESET}"
    echo "                  ${CYAN}~~~~~~~~~~~${RESET}"
    echo "       ${ORANGE}→${RESET}${ORANGE}→${RESET}     ${BLUE}▒▒▒▒▒▒▒▒▒▒▒${RESET}     ${TEXT_MUTED}Thermocline${RESET}"
    echo "              ${PURPLE}▓▓▓▓▓▓▓▓▓▓▓▓▓${RESET}"
    echo "       ${PURPLE}←${RESET}${PURPLE}←${RESET}    ${GREEN}████████████████${RESET}   ${TEXT_MUTED}Deep currents${RESET}"
    echo "           ${TEXT_MUTED}╱${RESET}${BLUE}██████████████████${RESET}${TEXT_MUTED}╲${RESET}"
    echo "          ${TEXT_MUTED}╱${RESET}${CYAN}████████████████████${RESET}${TEXT_MUTED}╲${RESET} ${TEXT_MUTED}Ocean floor${RESET}"
    echo "         ${TEXT_MUTED}╱▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔╲${RESET}"
    echo ""

    # Salinity map
    echo -e "${TEXT_MUTED}╭─ SALINITY DISTRIBUTION ───────────────────────────────────────────────╮${RESET}"
    echo ""

    for ((i=0; i<6; i++)); do
        echo -n "  "
        for ((j=0; j<50; j++)); do
            local salt=$((RANDOM % 100))
            if [ $salt -gt 80 ]; then
                echo -n "${RED}█${RESET}"
            elif [ $salt -gt 60 ]; then
                echo -n "${ORANGE}▓${RESET}"
            elif [ $salt -gt 40 ]; then
                echo -n "${YELLOW}▒${RESET}"
            else
                echo -n "${BLUE}░${RESET}"
            fi
        done
        echo ""
    done
    echo ""
    echo "  ${BLUE}Low (32 ppt)${RESET}  ${YELLOW}Medium (35 ppt)${RESET}  ${ORANGE}High (37 ppt)${RESET}  ${RED}Very High (40+ ppt)${RESET}"
    echo ""

    # Ocean conveyor belt
    echo -e "${TEXT_MUTED}╭─ THERMOHALINE CIRCULATION (GLOBAL CONVEYOR BELT) ─────────────────────╮${RESET}"
    echo ""

    echo "                    ${ORANGE}Warm${RESET}      ${CYAN}Cold${RESET}"
    echo "                    ${ORANGE}Surface${RESET}   ${CYAN}Deep${RESET}"
    echo ""
    echo "     ${TEXT_MUTED}Arctic${RESET}        ${CYAN}⬇${RESET}        ${CYAN}↓${RESET}"
    echo "                    ${CYAN}│${RESET}        ${CYAN}│${RESET}"
    echo "   ${TEXT_MUTED}Atlantic${RESET}       ${ORANGE}↑${RESET}        ${CYAN}│${RESET}"
    echo "                    ${ORANGE}│${RESET}   ${CYAN}←${RESET}${CYAN}←${RESET}${CYAN}←${RESET}${CYAN}┘${RESET}"
    echo "    ${TEXT_MUTED}Pacific${RESET}       ${ORANGE}│${RESET}"
    echo "                    ${ORANGE}└${RESET}${ORANGE}→${RESET}${ORANGE}→${RESET}${ORANGE}→${RESET}"
    echo ""
    echo "    ${TEXT_MUTED}~1000 year circulation cycle${RESET}"
    echo ""

    # Current statistics
    echo -e "${TEXT_MUTED}╭─ CURRENT STATISTICS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Monitoring Depth:${RESET}    ${CYAN}${CURRENT_DEPTH}m${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Current Velocity:${RESET}    ${ORANGE}1.2 m/s${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Direction:${RESET}           ${PURPLE}NE (045°)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Temperature:${RESET}         ${RED}22.4°C${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Salinity:${RESET}            ${BLUE}35.2 ppt${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Pressure:${RESET}            ${GREEN}1.2 MPa${RESET}"
    echo ""

    # Marine data
    echo -e "${TEXT_MUTED}╭─ MARINE OBSERVATIONS ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Wave Height:${RESET}         ${CYAN}2.4 meters${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Tidal Range:${RESET}         ${BLUE}1.8 meters${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}pH Level:${RESET}            ${GREEN}8.1${RESET} ${TEXT_MUTED}(Normal)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Dissolved O₂:${RESET}        ${ORANGE}6.8 mg/L${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Chlorophyll:${RESET}         ${PURPLE}0.42 mg/m³${RESET}"
    echo ""

    # El Niño / La Niña
    echo -e "${TEXT_MUTED}╭─ ENSO STATUS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Current Phase:${RESET}       ${BLUE}La Niña${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}SST Anomaly:${RESET}         ${CYAN}-1.2°C${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}SOI Index:${RESET}           ${PURPLE}+12.4${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Forecast:${RESET}            ${ORANGE}Transitioning to Neutral${RESET}"
    echo ""

    # Buoy network
    echo -e "${TEXT_MUTED}╭─ MONITORING BUOY NETWORK ─────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}Buoy 847-A${RESET}    ${TEXT_SECONDARY}23.4°N, 158.2°W${RESET}   ${GREEN}✓ ACTIVE${RESET}   ${TEXT_MUTED}Last: 2min${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Buoy 847-B${RESET}    ${TEXT_SECONDARY}18.7°N, 142.8°W${RESET}   ${GREEN}✓ ACTIVE${RESET}   ${TEXT_MUTED}Last: 1min${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Buoy 847-C${RESET}    ${TEXT_SECONDARY}31.2°N, 165.4°W${RESET}   ${ORANGE}⚠ WARNING${RESET}  ${TEXT_MUTED}Last: 15min${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Buoy 847-D${RESET}    ${TEXT_SECONDARY}12.1°N, 135.6°W${RESET}   ${GREEN}✓ ACTIVE${RESET}   ${TEXT_MUTED}Last: 3min${RESET}"
    echo ""

    # Climate impact
    echo -e "${TEXT_MUTED}╭─ CLIMATE IMPACT ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Heat Transport:${RESET}      ${ORANGE}1.5 PW${RESET} ${TEXT_MUTED}(Petawatts)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}CO₂ Absorption:${RESET}      ${GREEN}2.4 Gt/year${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Sea Level Rise:${RESET}      ${RED}+3.4 mm/year${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Ocean Warming:${RESET}       ${ORANGE}+0.13°C/decade${RESET}"
    echo ""

    echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[↑/↓]${RESET} Depth  ${TEXT_SECONDARY}[T]${RESET} Temperature  ${TEXT_SECONDARY}[S]${RESET} Salinity  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_ocean_dashboard

        ANIMATION_FRAME=$((ANIMATION_FRAME + 1))

        read -t 1 -rsn1 key

        # Handle escape sequences
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
        fi

        case "$key" in
            '[A')  # Up arrow
                CURRENT_DEPTH=$((CURRENT_DEPTH + 100))
                [ $CURRENT_DEPTH -gt 4000 ] && CURRENT_DEPTH=4000
                ;;
            '[B')  # Down arrow
                CURRENT_DEPTH=$((CURRENT_DEPTH - 100))
                [ $CURRENT_DEPTH -lt 0 ] && CURRENT_DEPTH=0
                ;;
            't'|'T')
                echo -e "\n${ORANGE}Loading temperature data...${RESET}"
                sleep 1
                ;;
            's'|'S')
                echo -e "\n${BLUE}Loading salinity data...${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Ocean monitoring ended${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
