#!/bin/bash

# BlackRoad OS - Particle Physics Simulator
# Simulate particle collisions and interactions

source ~/blackroad-dashboards/themes.sh
load_theme

COLLISION_ENERGY=13  # TeV
COLLISIONS_COUNT=0
AUTO_RUN=0

# Particle types
declare -A PARTICLES=(
    ["electron"]="e⁻"
    ["positron"]="e⁺"
    ["proton"]="p"
    ["antiproton"]="p̄"
    ["neutron"]="n"
    ["muon"]="μ⁻"
    ["tau"]="τ⁻"
    ["photon"]="γ"
    ["gluon"]="g"
    ["W+"]="W⁺"
    ["W-"]="W⁻"
    ["Z"]="Z⁰"
    ["higgs"]="H"
    ["quark_up"]="u"
    ["quark_down"]="d"
    ["quark_strange"]="s"
    ["quark_charm"]="c"
    ["quark_bottom"]="b"
    ["quark_top"]="t"
)

# Simulate particle collision
simulate_collision() {
    local energy=$1

    # Generate random collision products
    local products=()
    local num_products=$((RANDOM % 8 + 3))

    for ((i=0; i<num_products; i++)); do
        local particle_keys=("${!PARTICLES[@]}")
        local random_key="${particle_keys[$((RANDOM % ${#particle_keys[@]}))]}"
        products+=("$random_key")
    done

    echo "${products[@]}"
}

# Show particle physics simulator
show_particle_physics() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}⚛️${RESET}  ${BOLD}PARTICLE PHYSICS SIMULATOR${RESET}                                      ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Collider status
    echo -e "${TEXT_MUTED}╭─ COLLIDER STATUS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Beam Energy:${RESET}         ${BOLD}${ORANGE}${COLLISION_ENERGY} TeV${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Collisions:${RESET}          ${BOLD}${CYAN}${COLLISIONS_COUNT}${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Luminosity:${RESET}          ${BOLD}${GREEN}2.1×10³⁴ cm⁻²s⁻¹${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Beam Status:${RESET}         ${BOLD}${GREEN}◉ STABLE${RESET}"
    echo ""

    # Particle accelerator ring
    echo -e "${TEXT_MUTED}╭─ ACCELERATOR RING (27 km) ────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                         ${CYAN}Beam 1 →${RESET}"
    echo "                    ${TEXT_MUTED}┌─────────────┐${RESET}"
    echo "                   ${TEXT_MUTED}╱${RESET}${CYAN}●${RESET}             ${TEXT_MUTED}╲${RESET}"
    echo "       ${PURPLE}ATLAS${RESET}      ${TEXT_MUTED}│${RESET}               ${TEXT_MUTED}│${RESET}      ${ORANGE}CMS${RESET}"
    echo "         ${PURPLE}◉${RESET}        ${TEXT_MUTED}│${RESET}               ${TEXT_MUTED}│${RESET}        ${ORANGE}◉${RESET}"
    echo "                  ${TEXT_MUTED}│${RESET}   ${GOLD}★${RESET}           ${TEXT_MUTED}│${RESET}   ${TEXT_MUTED}Collision point${RESET}"
    echo "                  ${TEXT_MUTED}│${RESET}               ${TEXT_MUTED}│${RESET}"
    echo "     ${PINK}ALICE${RESET}        ${TEXT_MUTED}│${RESET}               ${TEXT_MUTED}│${RESET}      ${GREEN}LHCb${RESET}"
    echo "       ${PINK}◉${RESET}          ${TEXT_MUTED}╲${RESET}               ${TEXT_MUTED}╱${RESET}        ${GREEN}◉${RESET}"
    echo "                   ${TEXT_MUTED}╲${RESET}${RED}●${RESET}             ${TEXT_MUTED}╱${RESET}"
    echo "                    ${TEXT_MUTED}└─────────────┘${RESET}"
    echo "                         ${RED}← Beam 2${RESET}"
    echo ""

    # Collision event display
    echo -e "${TEXT_MUTED}╭─ COLLISION EVENT DISPLAY ─────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                         ${GOLD}★${RESET}  ${TEXT_MUTED}Collision${RESET}"
    echo "                    ${CYAN}━━━━${GOLD}┼${RESET}${RED}━━━━${RESET}"
    echo "                  ${PURPLE}╱${RESET}      ${GOLD}│${RESET}      ${PURPLE}╲${RESET}"
    echo "               ${PURPLE}━━${RESET}        ${GOLD}│${RESET}        ${PURPLE}━━${RESET}"
    echo "             ${PINK}╱${RESET}            ${GOLD}│${RESET}            ${PINK}╲${RESET}"
    echo "          ${PINK}━━${RESET}              ${GOLD}│${RESET}              ${PINK}━━${RESET}"
    echo "        ${ORANGE}╱${RESET}                ${GOLD}│${RESET}                ${ORANGE}╲${RESET}"
    echo "     ${ORANGE}━━${RESET}                  ${GOLD}│${RESET}                  ${ORANGE}━━${RESET}"
    echo "   ${GREEN}╱${RESET}                     ${GOLD}│${RESET}                     ${GREEN}╲${RESET}"
    echo " ${GREEN}━━${RESET}                       ${GOLD}│${RESET}                       ${GREEN}━━${RESET}"
    echo ""
    echo "  ${TEXT_MUTED}Particle tracks detected by calorimeter & tracker${RESET}"
    echo ""

    # Detected particles
    local collision_products=$(simulate_collision "$COLLISION_ENERGY")

    echo -e "${TEXT_MUTED}╭─ DETECTED PARTICLES ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -n "  "
    local count=0
    for particle in $collision_products; do
        local symbol="${PARTICLES[$particle]}"
        local colors=("${CYAN}" "${PURPLE}" "${PINK}" "${ORANGE}" "${GREEN}" "${BLUE}" "${GOLD}")
        local color="${colors[$((RANDOM % 7))]}"

        echo -n "${color}${symbol}${RESET}  "

        count=$((count + 1))
        if [ $((count % 8)) -eq 0 ]; then
            echo ""
            echo -n "  "
        fi
    done
    echo ""
    echo ""

    # Particle tracks
    echo -e "${TEXT_MUTED}╭─ TRACKING CHAMBER ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Simulate curved tracks in magnetic field
    for ((i=0; i<6; i++)); do
        echo -n "  "
        for ((j=0; j<60; j++)); do
            local rand=$((RANDOM % 30))
            if [ $rand -eq 0 ]; then
                echo -n "${CYAN}●${RESET}"
            elif [ $rand -eq 1 ]; then
                echo -n "${PURPLE}●${RESET}"
            elif [ $rand -eq 2 ]; then
                echo -n "${PINK}●${RESET}"
            else
                echo -n "${TEXT_MUTED}·${RESET}"
            fi
        done
        echo ""
    done
    echo ""

    # Energy distribution
    echo -e "${TEXT_MUTED}╭─ ENERGY DISTRIBUTION ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "   ${TEXT_MUTED}TeV${RESET}"
    echo "    ${TEXT_MUTED}13${RESET} ${RED}│${RESET}${RED}█${RESET}                              ${TEXT_MUTED}Initial collision${RESET}"
    echo "    ${TEXT_MUTED}10${RESET} ${ORANGE}│${RESET}${ORANGE}██${RESET}"
    echo "     ${TEXT_MUTED}5${RESET} ${YELLOW}│${RESET}${YELLOW}████${RESET}                         ${TEXT_MUTED}Decay products${RESET}"
    echo "     ${TEXT_MUTED}1${RESET} ${GREEN}│${RESET}${GREEN}████████${RESET}"
    echo "   ${TEXT_MUTED}0.1${RESET} ${CYAN}│${RESET}${CYAN}████████████${RESET}"
    echo "  ${TEXT_MUTED}0.01${RESET} ${PURPLE}│${RESET}${PURPLE}████████████████${RESET}"
    echo "     ${TEXT_MUTED}0${RESET} ${TEXT_MUTED}└─────────────────────────────────────────────→${RESET}"
    echo "        ${TEXT_MUTED}Number of particles${RESET}"
    echo ""

    # Feynman diagram
    echo -e "${TEXT_MUTED}╭─ FEYNMAN DIAGRAM ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "         ${CYAN}e⁻${RESET}                    ${CYAN}e⁻${RESET}"
    echo "          ${CYAN}╲${RESET}                    ${CYAN}╱${RESET}"
    echo "           ${CYAN}╲${RESET}                  ${CYAN}╱${RESET}"
    echo "            ${CYAN}╲${RESET}                ${CYAN}╱${RESET}"
    echo "             ${CYAN}╲${RESET}      ${GOLD}γ${RESET}      ${CYAN}╱${RESET}       ${TEXT_MUTED}Photon${RESET}"
    echo "              ${CYAN}●${RESET}${GOLD}━━━━━━━━${RESET}${CYAN}●${RESET}        ${TEXT_MUTED}exchange${RESET}"
    echo "             ${RED}╱${RESET}              ${RED}╲${RESET}"
    echo "            ${RED}╱${RESET}                ${RED}╲${RESET}"
    echo "           ${RED}╱${RESET}                  ${RED}╲${RESET}"
    echo "          ${RED}╱${RESET}                    ${RED}╲${RESET}"
    echo "         ${RED}e⁺${RESET}                    ${RED}e⁺${RESET}"
    echo ""
    echo "              ${TEXT_MUTED}e⁺e⁻ → γ → e⁺e⁻${RESET}"
    echo ""

    # Standard Model particles
    echo -e "${TEXT_MUTED}╭─ STANDARD MODEL PARTICLES ────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "   ${BOLD}Quarks${RESET}              ${BOLD}Leptons${RESET}            ${BOLD}Bosons${RESET}"
    echo ""
    echo "   ${CYAN}u${RESET} ${CYAN}c${RESET} ${CYAN}t${RESET}               ${PURPLE}e${RESET} ${PURPLE}μ${RESET} ${PURPLE}τ${RESET}              ${GOLD}γ${RESET} ${ORANGE}g${RESET}"
    echo "   ${PINK}d${RESET} ${PINK}s${RESET} ${PINK}b${RESET}               ${BLUE}νₑ${RESET} ${BLUE}νμ${RESET} ${BLUE}ντ${RESET}           ${GREEN}W⁺${RESET} ${GREEN}W⁻${RESET} ${GREEN}Z⁰${RESET}"
    echo ""
    echo "                                            ${GOLD}H${RESET} ${TEXT_MUTED}Higgs${RESET}"
    echo ""

    # Discovery statistics
    echo -e "${TEXT_MUTED}╭─ DISCOVERY STATISTICS ────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Higgs Events:${RESET}        ${BOLD}${GOLD}847${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Top Quark Pairs:${RESET}     ${BOLD}${CYAN}2,341${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}W/Z Bosons:${RESET}          ${BOLD}${GREEN}14,723${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Jet Events:${RESET}          ${BOLD}${ORANGE}847,234${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Signal/Noise:${RESET}        ${BOLD}${PURPLE}5.2σ${RESET}"
    echo ""

    # Detector systems
    echo -e "${TEXT_MUTED}╭─ DETECTOR SYSTEMS ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}Inner Tracker${RESET}      ${TEXT_MUTED}Resolution:${RESET} ${GREEN}15 μm${RESET}     ${GREEN}✓ OK${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Calorimeter${RESET}        ${TEXT_MUTED}Energy res:${RESET} ${CYAN}2.3%${RESET}      ${GREEN}✓ OK${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Muon Chambers${RESET}     ${TEXT_MUTED}Efficiency:${RESET} ${PURPLE}98.7%${RESET}    ${GREEN}✓ OK${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Trigger System${RESET}    ${TEXT_MUTED}Rate:${RESET} ${ORANGE}100 kHz${RESET}        ${GREEN}✓ OK${RESET}"
    echo ""

    # Recent discoveries
    echo -e "${TEXT_MUTED}╭─ RECENT DISCOVERIES ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GOLD}★${RESET} ${BOLD}Higgs Boson${RESET}        ${TEXT_MUTED}Mass: 125.1 GeV${RESET}     ${TEXT_MUTED}2012${RESET}"
    echo -e "  ${CYAN}★${RESET} ${BOLD}Top Quark${RESET}          ${TEXT_MUTED}Mass: 173.1 GeV${RESET}     ${TEXT_MUTED}1995${RESET}"
    echo -e "  ${PURPLE}★${RESET} ${BOLD}W/Z Bosons${RESET}        ${TEXT_MUTED}Weak force${RESET}          ${TEXT_MUTED}1983${RESET}"
    echo ""

    # Physics beyond SM
    echo -e "${TEXT_MUTED}╭─ BEYOND STANDARD MODEL SEARCH ────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${PINK}●${RESET} ${BOLD}Supersymmetry${RESET}      ${TEXT_MUTED}Status:${RESET} ${ORANGE}Searching...${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Dark Matter${RESET}        ${TEXT_MUTED}Status:${RESET} ${ORANGE}Searching...${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Extra Dimensions${RESET}  ${TEXT_MUTED}Status:${RESET} ${ORANGE}Searching...${RESET}"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[Space]${RESET} Collide  ${TEXT_SECONDARY}[+/-]${RESET} Energy  ${TEXT_SECONDARY}[A]${RESET} Auto  ${TEXT_SECONDARY}[R]${RESET} Reset  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_particle_physics

        if [ $AUTO_RUN -eq 1 ]; then
            sleep 0.5
            COLLISIONS_COUNT=$((COLLISIONS_COUNT + 1))
        fi

        read -t 0.1 -n1 key

        case "$key" in
            ' ')
                COLLISIONS_COUNT=$((COLLISIONS_COUNT + 1))
                ;;
            '+')
                COLLISION_ENERGY=$((COLLISION_ENERGY + 1))
                [ $COLLISION_ENERGY -gt 20 ] && COLLISION_ENERGY=20
                ;;
            '-')
                COLLISION_ENERGY=$((COLLISION_ENERGY - 1))
                [ $COLLISION_ENERGY -lt 1 ] && COLLISION_ENERGY=1
                ;;
            'a'|'A')
                if [ $AUTO_RUN -eq 1 ]; then
                    AUTO_RUN=0
                else
                    AUTO_RUN=1
                fi
                ;;
            'r'|'R')
                COLLISIONS_COUNT=0
                COLLISION_ENERGY=13
                AUTO_RUN=0
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Collider shutdown${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
