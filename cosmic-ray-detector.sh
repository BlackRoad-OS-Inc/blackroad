#!/bin/bash

# BlackRoad OS - Cosmic Ray Detector
# Detect and visualize cosmic radiation events

source ~/blackroad-dashboards/themes.sh
load_theme

DETECTOR_ACTIVE=1
COSMIC_EVENTS=0
TOTAL_PARTICLES=0

# Particle types
declare -A PARTICLES=(
    ["muon"]="μ"
    ["electron"]="e⁻"
    ["positron"]="e⁺"
    ["proton"]="p⁺"
    ["neutron"]="n"
    ["gamma"]="γ"
    ["neutrino"]="ν"
)

# Generate cosmic ray event
generate_cosmic_event() {
    local event_type=$((RANDOM % 7))

    case $event_type in
        0) echo "muon|${CYAN}|47.3" ;;
        1) echo "electron|${PURPLE}|12.8" ;;
        2) echo "positron|${PINK}|15.2" ;;
        3) echo "proton|${ORANGE}|98.7" ;;
        4) echo "neutron|${BLUE}|0.0" ;;
        5) echo "gamma|${GREEN}|234.5" ;;
        6) echo "neutrino|${GOLD}|0.001" ;;
    esac
}

# Show cosmic ray detector
show_cosmic_detector() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}  ${PURPLE}☄️${RESET}  ${BOLD}COSMIC RAY DETECTOR${RESET}                                             ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Detector status
    echo -e "${TEXT_MUTED}╭─ DETECTOR STATUS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ $DETECTOR_ACTIVE -eq 1 ]; then
        echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${BOLD}${GREEN}◉ ACTIVE${RESET}"
    else
        echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${BOLD}${ORANGE}◉ STANDBY${RESET}"
    fi

    echo -e "  ${BOLD}${TEXT_PRIMARY}Events Detected:${RESET}     ${BOLD}${CYAN}$COSMIC_EVENTS${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Particles:${RESET}     ${BOLD}${PURPLE}$TOTAL_PARTICLES${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Sensitivity:${RESET}         ${BOLD}${GREEN}99.87%${RESET}"
    echo ""

    # Live particle stream
    echo -e "${TEXT_MUTED}╭─ PARTICLE STREAM (LIVE) ──────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ $DETECTOR_ACTIVE -eq 1 ]; then
        # Simulate 8 particle detections
        for ((i=0; i<8; i++)); do
            if [ $((RANDOM % 3)) -eq 0 ]; then
                local event=$(generate_cosmic_event)
                local particle_name=$(echo "$event" | cut -d'|' -f1)
                local color=$(echo "$event" | cut -d'|' -f2)
                local energy=$(echo "$event" | cut -d'|' -f3)
                local symbol="${PARTICLES[$particle_name]}"

                echo -n "  ${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET} "
                echo -e "${BOLD}${color}${symbol}${RESET} ${TEXT_MUTED}${energy} GeV${RESET}"

                TOTAL_PARTICLES=$((TOTAL_PARTICLES + 1))
            else
                echo -e "  ${TEXT_MUTED}────────────────────────────────────────${RESET}"
            fi
        done

        COSMIC_EVENTS=$((COSMIC_EVENTS + 1))
    else
        for ((i=0; i<8; i++)); do
            echo -e "  ${TEXT_MUTED}────────────────────────────────────────${RESET}"
        done
    fi
    echo ""

    # Particle distribution
    echo -e "${TEXT_MUTED}╭─ PARTICLE DISTRIBUTION ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${CYAN}Muons (μ)${RESET}          ${CYAN}████████████████████${TEXT_MUTED}░░░░░${RESET}  ${BOLD}67.8%${RESET}"
    echo -e "  ${ORANGE}Protons (p⁺)${RESET}      ${ORANGE}████████${TEXT_MUTED}░░░░░░░░░░░░░░░░░${RESET}  ${BOLD}14.2%${RESET}"
    echo -e "  ${PURPLE}Electrons (e⁻)${RESET}    ${PURPLE}██████${TEXT_MUTED}░░░░░░░░░░░░░░░░░░░${RESET}  ${BOLD}9.7%${RESET}"
    echo -e "  ${GREEN}Gamma (γ)${RESET}          ${GREEN}████${TEXT_MUTED}░░░░░░░░░░░░░░░░░░░░░${RESET}  ${BOLD}5.4%${RESET}"
    echo -e "  ${PINK}Positrons (e⁺)${RESET}     ${PINK}██${TEXT_MUTED}░░░░░░░░░░░░░░░░░░░░░░░${RESET}  ${BOLD}2.1%${RESET}"
    echo -e "  ${BLUE}Neutrons (n)${RESET}       ${BLUE}█${TEXT_MUTED}░░░░░░░░░░░░░░░░░░░░░░░░${RESET}  ${BOLD}0.7%${RESET}"
    echo -e "  ${GOLD}Neutrinos (ν)${RESET}      ${GOLD}█${TEXT_MUTED}░░░░░░░░░░░░░░░░░░░░░░░░${RESET}  ${BOLD}0.1%${RESET}"
    echo ""

    # Energy spectrum
    echo -e "${TEXT_MUTED}╭─ ENERGY SPECTRUM ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "   ${TEXT_MUTED}GeV${RESET}"
    echo "  ${TEXT_MUTED}1000${RESET} ${RED}│${RESET}${RED}█${RESET}"
    echo "   ${TEXT_MUTED}500${RESET} ${ORANGE}│${RESET}${ORANGE}██${RESET}"
    echo "   ${TEXT_MUTED}100${RESET} ${YELLOW}│${RESET}${YELLOW}████${RESET}"
    echo "    ${TEXT_MUTED}50${RESET} ${GREEN}│${RESET}${GREEN}████████${RESET}"
    echo "    ${TEXT_MUTED}10${RESET} ${CYAN}│${RESET}${CYAN}████████████████${RESET}"
    echo "     ${TEXT_MUTED}1${RESET} ${BLUE}│${RESET}${BLUE}████████████████████████${RESET}"
    echo "   ${TEXT_MUTED}0.1${RESET} ${PURPLE}│${RESET}${PURPLE}████████████████████████████${RESET}"
    echo "     ${TEXT_MUTED}0${RESET} ${TEXT_MUTED}└─────────────────────────────────────────────→${RESET}"
    echo "        ${TEXT_MUTED}Frequency${RESET}"
    echo ""

    # 3D Detector visualization
    echo -e "${TEXT_MUTED}╭─ DETECTOR ARRAY (3D) ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${TEXT_MUTED}┌─────────────┐${RESET}"
    echo "                   ${TEXT_MUTED}╱${RESET}${GREEN}●${RESET}   ${CYAN}●${RESET}   ${PURPLE}●${RESET}${TEXT_MUTED}╱│${RESET}"
    echo "                  ${TEXT_MUTED}╱${RESET} ${ORANGE}●${RESET}   ${PINK}●${RESET}   ${BLUE}●${RESET}${TEXT_MUTED}╱ │${RESET}"
    echo "                 ${TEXT_MUTED}╱${RESET}${GOLD}●${RESET}   ${RED}●${RESET}   ${CYAN}●${RESET}${TEXT_MUTED}╱  │${RESET}  ${PURPLE}↓${RESET} Cosmic rays"
    echo "                ${TEXT_MUTED}┌─────────────┐${RESET}   ${TEXT_MUTED}│${RESET}"
    echo "                ${TEXT_MUTED}│${RESET}${GREEN}●${RESET}   ${CYAN}●${RESET}   ${PURPLE}●${RESET}${TEXT_MUTED}│${RESET}   ${TEXT_MUTED}│${RESET}"
    echo "                ${TEXT_MUTED}│${RESET} ${ORANGE}●${RESET}   ${PINK}●${RESET}   ${BLUE}●${RESET}${TEXT_MUTED}│${RESET}   ${TEXT_MUTED}│${RESET}"
    echo "                ${TEXT_MUTED}│${RESET}${GOLD}●${RESET}   ${RED}●${RESET}   ${CYAN}●${RESET}${TEXT_MUTED}│${RESET}   ${TEXT_MUTED}│${RESET}"
    echo "                ${TEXT_MUTED}└─────────────┘${RESET}   ${TEXT_MUTED}│${RESET}"
    echo "                 ${TEXT_MUTED}│${RESET}              ${TEXT_MUTED}│${RESET}"
    echo "                 ${TEXT_MUTED}└──────────────┘${RESET}"
    echo ""
    echo "                ${TEXT_MUTED}9×9×9 detector array${RESET}"
    echo ""

    # Shower visualization
    echo -e "${TEXT_MUTED}╭─ AIR SHOWER EVENTS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                         ${GOLD}★${RESET}  ${TEXT_MUTED}Primary particle${RESET}"
    echo "                         ${GOLD}│${RESET}"
    echo "                      ${ORANGE}╱${RESET}  ${GOLD}│${RESET}  ${ORANGE}╲${RESET}"
    echo "                   ${ORANGE}╱${RESET}     ${GOLD}│${RESET}     ${ORANGE}╲${RESET}"
    echo "                ${CYAN}●${RESET}       ${GOLD}│${RESET}       ${CYAN}●${RESET}"
    echo "               ${CYAN}╱ ╲${RESET}     ${GOLD}│${RESET}     ${CYAN}╱ ╲${RESET}"
    echo "             ${PURPLE}●${RESET}   ${PURPLE}●${RESET}   ${GOLD}│${RESET}   ${PURPLE}●${RESET}   ${PURPLE}●${RESET}"
    echo "            ${PURPLE}╱│╲${RESET} ${PURPLE}╱│╲${RESET} ${GOLD}│${RESET} ${PURPLE}╱│╲${RESET} ${PURPLE}╱│╲${RESET}"
    echo "          ${PINK}●${RESET} ${PINK}●${RESET} ${PINK}●${RESET} ${PINK}●${RESET} ${PINK}●${RESET} ${PINK}●${RESET} ${PINK}●${RESET} ${PINK}●${RESET}   ${TEXT_MUTED}Secondary shower${RESET}"
    echo "          ${TEXT_MUTED}━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "          ${GREEN}█${RESET}${GREEN}█${RESET}${GREEN}█${RESET}${TEXT_MUTED}░${RESET}${GREEN}█${RESET}${TEXT_MUTED}░${RESET}${GREEN}█${RESET}${GREEN}█${RESET}${TEXT_MUTED}░${RESET}   ${TEXT_MUTED}Detector hits${RESET}"
    echo ""

    # Source direction
    echo -e "${TEXT_MUTED}╭─ SOURCE DIRECTION (SKY MAP) ──────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                        ${TEXT_MUTED}North${RESET}"
    echo "                          ${TEXT_MUTED}↑${RESET}"
    echo "                    ${CYAN}●${RESET}     ${TEXT_MUTED}│${RESET}     ${PURPLE}●${RESET}"
    echo "                       ${PINK}●${RESET}  ${TEXT_MUTED}│${RESET}  ${ORANGE}●${RESET}"
    echo "         ${TEXT_MUTED}West${RESET} ${TEXT_MUTED}←──────●──────→${RESET} ${TEXT_MUTED}East${RESET}"
    echo "                    ${BLUE}●${RESET}     ${TEXT_MUTED}│${RESET}     ${GREEN}●${RESET}"
    echo "                       ${GOLD}●${RESET}  ${TEXT_MUTED}│${RESET}"
    echo "                          ${TEXT_MUTED}↓${RESET}"
    echo "                       ${TEXT_MUTED}South${RESET}"
    echo ""

    # Statistics
    echo -e "${TEXT_MUTED}╭─ DETECTION STATISTICS ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Detection Rate:${RESET}      ${BOLD}${GREEN}847 /min${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Energy:${RESET}          ${BOLD}${CYAN}47.3 GeV${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Peak Energy:${RESET}         ${BOLD}${ORANGE}1.2 TeV${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Shower Events:${RESET}       ${BOLD}${PURPLE}23${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Data Rate:${RESET}           ${BOLD}${PINK}2.4 GB/hour${RESET}"
    echo ""

    # Environmental conditions
    echo -e "${TEXT_MUTED}╭─ ENVIRONMENTAL CONDITIONS ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Geomagnetic Field:${RESET}   ${GREEN}48.7 μT${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Solar Activity:${RESET}      ${ORANGE}Moderate${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Atmospheric Depth:${RESET}   ${CYAN}1013 g/cm²${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Background Noise:${RESET}    ${GREEN}Low${RESET}"
    echo ""

    echo -e "${BLUE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[Space]${RESET} Pause  ${TEXT_SECONDARY}[C]${RESET} Calibrate  ${TEXT_SECONDARY}[E]${RESET} Export  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_cosmic_detector

        read -t 0.5 -n1 key

        case "$key" in
            ' ')
                if [ $DETECTOR_ACTIVE -eq 1 ]; then
                    DETECTOR_ACTIVE=0
                else
                    DETECTOR_ACTIVE=1
                fi
                ;;
            'c'|'C')
                echo -e "\n${PURPLE}Calibrating detector array...${RESET}"
                sleep 2
                echo -e "${GREEN}✓ Calibration complete${RESET}"
                sleep 1
                ;;
            'e'|'E')
                echo -e "\n${CYAN}Exporting data to cosmic_rays_$(date +%Y%m%d_%H%M%S).dat${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Detector shutdown${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
