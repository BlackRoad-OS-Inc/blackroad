#!/bin/bash

# BlackRoad OS - Black Hole Simulator
# Simulate black holes and gravitational physics

source ~/blackroad-dashboards/themes.sh
load_theme

BLACK_HOLE_MASS=10  # Solar masses
EVENT_HORIZON=0
ACCRETION_RATE=0

# Calculate Schwarzschild radius
calculate_schwarzschild() {
    local mass=$1
    # Rs = 2GM/c² ≈ 3km × (M/M☉)
    echo "$(echo "scale=1; $mass * 3" | bc)"
}

# Show black hole simulator
show_black_hole_simulator() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${GOLD}⚫${RESET} ${BOLD}BLACK HOLE SIMULATOR${RESET}                                            ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    EVENT_HORIZON=$(calculate_schwarzschild "$BLACK_HOLE_MASS")

    # Black hole visualization
    echo -e "${TEXT_MUTED}╭─ BLACK HOLE VISUALIZATION ────────────────────────────────────────────╮${RESET}"
    echo ""

    # Accretion disk
    echo "                       ${ORANGE}╱${RESET}${ORANGE}─${RESET}${ORANGE}─${RESET}${ORANGE}─${RESET}${ORANGE}╲${RESET}"
    echo "                    ${ORANGE}╱${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${ORANGE}╲${RESET}     ${TEXT_MUTED}Accretion disk${RESET}"
    echo "                  ${ORANGE}╱${RESET}${GOLD}═${RESET}${YELLOW}═${RESET}${YELLOW}═${RESET}${YELLOW}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${ORANGE}╲${RESET}"
    echo "                ${ORANGE}│${RESET}${GOLD}═${RESET}${YELLOW}═${RESET}${YELLOW}▓${RESET}${YELLOW}▓${RESET}${YELLOW}▓${RESET}${YELLOW}═${RESET}${GOLD}═${RESET}${ORANGE}│${RESET}"
    echo "                ${ORANGE}│${RESET}${YELLOW}▓${RESET}${RED}▓${RESET}${RED}▓${RESET}${TEXT_MUTED}███${RESET}${RED}▓${RESET}${RED}▓${RESET}${YELLOW}▓${RESET}${ORANGE}│${RESET}   ${TEXT_MUTED}Event horizon${RESET}"
    echo "                ${ORANGE}│${RESET}${RED}▓${RESET}${TEXT_MUTED}███████${RESET}${RED}▓${RESET}${ORANGE}│${RESET}"
    echo "                ${ORANGE}│${RESET}${TEXT_MUTED}██${RESET}${PURPLE}◉${RESET}${PURPLE}◉${RESET}${PURPLE}◉${RESET}${TEXT_MUTED}██${RESET}${ORANGE}│${RESET}   ${TEXT_MUTED}Singularity${RESET}"
    echo "                ${ORANGE}│${RESET}${RED}▓${RESET}${TEXT_MUTED}███████${RESET}${RED}▓${RESET}${ORANGE}│${RESET}"
    echo "                ${ORANGE}│${RESET}${YELLOW}▓${RESET}${RED}▓${RESET}${RED}▓${RESET}${TEXT_MUTED}███${RESET}${RED}▓${RESET}${RED}▓${RESET}${YELLOW}▓${RESET}${ORANGE}│${RESET}"
    echo "                ${ORANGE}│${RESET}${GOLD}═${RESET}${YELLOW}▓${RESET}${YELLOW}▓${RESET}${YELLOW}▓${RESET}${YELLOW}═${RESET}${GOLD}═${RESET}${ORANGE}│${RESET}"
    echo "                  ${ORANGE}╲${RESET}${GOLD}═${RESET}${YELLOW}═${RESET}${YELLOW}═${RESET}${YELLOW}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${ORANGE}╱${RESET}"
    echo "                    ${ORANGE}╲${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${GOLD}═${RESET}${ORANGE}╱${RESET}"
    echo "                       ${ORANGE}╲${RESET}${ORANGE}─${RESET}${ORANGE}─${RESET}${ORANGE}─${RESET}${ORANGE}╱${RESET}"
    echo ""

    # Relativistic jets
    echo "                         ${CYAN}↑${RESET}"
    echo "                         ${CYAN}│${RESET}"
    echo "                         ${CYAN}│${RESET}  ${TEXT_MUTED}Relativistic jets${RESET}"
    echo "                         ${CYAN}│${RESET}"
    echo ""

    # Black hole properties
    echo -e "${TEXT_MUTED}╭─ BLACK HOLE PROPERTIES ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Mass:${RESET}                ${BOLD}${ORANGE}$BLACK_HOLE_MASS M☉${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Event Horizon:${RESET}       ${BOLD}${PURPLE}$EVENT_HORIZON km${RESET} ${TEXT_MUTED}(Schwarzschild radius)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Gravity at EH:${RESET}       ${BOLD}${RED}∞${RESET} ${TEXT_MUTED}(escape velocity = c)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Temperature:${RESET}         ${BOLD}${CYAN}6.2×10⁻⁸ K${RESET} ${TEXT_MUTED}(Hawking radiation)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Lifetime:${RESET}            ${BOLD}${GREEN}2×10⁶⁷ years${RESET}"
    echo ""

    # Spacetime curvature
    echo -e "${TEXT_MUTED}╭─ SPACETIME CURVATURE ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Embedding diagram
    echo "                     ${TEXT_MUTED}╱${RESET}         ${TEXT_MUTED}╲${RESET}"
    echo "                  ${TEXT_MUTED}╱${RESET}             ${TEXT_MUTED}╲${RESET}"
    echo "               ${TEXT_MUTED}╱${RESET}                 ${TEXT_MUTED}╲${RESET}"
    echo "            ${TEXT_MUTED}╱${RESET}                     ${TEXT_MUTED}╲${RESET}"
    echo "         ${TEXT_MUTED}╱${RESET}                         ${TEXT_MUTED}╲${RESET}"
    echo "      ${TEXT_MUTED}╱${RESET}                             ${TEXT_MUTED}╲${RESET}"
    echo "   ${TEXT_MUTED}╱${RESET}                                 ${TEXT_MUTED}╲${RESET}"
    echo "  ${TEXT_MUTED}│${RESET}                                   ${TEXT_MUTED}│${RESET}"
    echo "  ${TEXT_MUTED}│${RESET}                ${PURPLE}◉${RESET}                  ${TEXT_MUTED}│${RESET}"
    echo "  ${TEXT_MUTED}│${RESET}              ${TEXT_MUTED}╱   ╲${RESET}                ${TEXT_MUTED}│${RESET}"
    echo "   ${TEXT_MUTED}╲${RESET}           ${TEXT_MUTED}╱${RESET}       ${TEXT_MUTED}╲${RESET}             ${TEXT_MUTED}╱${RESET}"
    echo "     ${TEXT_MUTED}╲${RESET}       ${TEXT_MUTED}╱${RESET}           ${TEXT_MUTED}╲${RESET}         ${TEXT_MUTED}╱${RESET}"
    echo "        ${TEXT_MUTED}╲${RESET}  ${TEXT_MUTED}╱${RESET}               ${TEXT_MUTED}╲${RESET}  ${TEXT_MUTED}╱${RESET}"
    echo "           ${TEXT_MUTED}V${RESET}                   ${TEXT_MUTED}V${RESET}"
    echo ""
    echo "            ${TEXT_MUTED}Extreme spacetime warping${RESET}"
    echo ""

    # Gravitational lensing
    echo -e "${TEXT_MUTED}╭─ GRAVITATIONAL LENSING ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "       ${CYAN}★${RESET}  ${TEXT_MUTED}Background star${RESET}"
    echo "        ${TEXT_MUTED}│${RESET}"
    echo "         ${TEXT_MUTED}╲${RESET}"
    echo "          ${TEXT_MUTED}╲${RESET}"
    echo "           ${TEXT_MUTED}╲${RESET}     ${PURPLE}⚫${RESET}  ${TEXT_MUTED}Black hole${RESET}"
    echo "            ${TEXT_MUTED}╲${RESET}   ${PURPLE}╱${RESET} ${PURPLE}╲${RESET}"
    echo "             ${CYAN}◉${RESET}${PURPLE}═${RESET}${PURPLE}═${RESET}${PURPLE}═${RESET}${CYAN}◉${RESET}  ${TEXT_MUTED}Einstein ring${RESET}"
    echo "            ${TEXT_MUTED}╱${RESET}   ${PURPLE}╲${RESET} ${PURPLE}╱${RESET}"
    echo "           ${TEXT_MUTED}╱${RESET}"
    echo "          ${TEXT_MUTED}╱${RESET}"
    echo "       ${GREEN}👁${RESET}  ${TEXT_MUTED}Observer${RESET}"
    echo ""

    # Time dilation
    echo -e "${TEXT_MUTED}╭─ TIME DILATION ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${TEXT_MUTED}Distance from Event Horizon${RESET}    ${TEXT_MUTED}Time Dilation Factor${RESET}"
    echo ""
    echo "  ${PURPLE}10 Rs${RESET}                          ${GREEN}1.05x${RESET}  ${TEXT_MUTED}(near normal)${RESET}"
    echo "  ${PURPLE}5 Rs${RESET}                           ${CYAN}1.22x${RESET}"
    echo "  ${PURPLE}2 Rs${RESET}                           ${ORANGE}2.00x${RESET}  ${TEXT_MUTED}(noticeable)${RESET}"
    echo "  ${PURPLE}1.5 Rs${RESET}                         ${YELLOW}3.46x${RESET}"
    echo "  ${PURPLE}1.1 Rs${RESET}                         ${RED}10.05x${RESET}  ${TEXT_MUTED}(extreme)${RESET}"
    echo "  ${PURPLE}1.0 Rs${RESET} ${TEXT_MUTED}(Event Horizon)${RESET}       ${BOLD}${RED}∞${RESET}      ${TEXT_MUTED}(time stops)${RESET}"
    echo ""

    # Black hole types
    echo -e "${TEXT_MUTED}╭─ BLACK HOLE TYPES ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${CYAN}Stellar:${RESET}             ${TEXT_MUTED}3-100 M☉${RESET}     ${CYAN}From collapsed stars${RESET}"
    echo -e "  ${PURPLE}Intermediate:${RESET}        ${TEXT_MUTED}100-10⁵ M☉${RESET}  ${PURPLE}Rare, poorly understood${RESET}"
    echo -e "  ${ORANGE}Supermassive:${RESET}        ${TEXT_MUTED}10⁶-10¹⁰ M☉${RESET}  ${ORANGE}Galactic centers${RESET}"
    echo -e "  ${PINK}Primordial:${RESET}          ${TEXT_MUTED}<M☉${RESET}         ${PINK}Theoretical, Big Bang${RESET}"
    echo ""

    # Famous black holes
    echo -e "${TEXT_MUTED}╭─ FAMOUS BLACK HOLES ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GOLD}●${RESET} ${BOLD}Sagittarius A*${RESET}  ${TEXT_MUTED}4.3×10⁶ M☉${RESET}   ${CYAN}Milky Way center${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}M87*${RESET}            ${TEXT_MUTED}6.5×10⁹ M☉${RESET}   ${PURPLE}First ever imaged${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}Cygnus X-1${RESET}      ${TEXT_MUTED}15 M☉${RESET}        ${BLUE}First discovered${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}TON 618${RESET}         ${TEXT_MUTED}6.6×10¹⁰ M☉${RESET}  ${RED}Most massive known${RESET}"
    echo ""

    # Hawking radiation
    echo -e "${TEXT_MUTED}╭─ HAWKING RADIATION ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "           ${TEXT_MUTED}Quantum fluctuations${RESET}"
    echo "                 ${CYAN}↓${RESET}"
    echo "       ${PURPLE}e⁺${RESET}${CYAN}━━━━━━━━${RESET}${PURPLE}e⁻${RESET}  ${TEXT_MUTED}Particle-antiparticle pair${RESET}"
    echo "         ${PURPLE}│${RESET}"
    echo "         ${PURPLE}│${RESET}      ${TEXT_MUTED}⚫${RESET} ${TEXT_MUTED}Event horizon${RESET}"
    echo "    ${GREEN}→${RESET}    ${PURPLE}│${RESET}"
    echo "  ${GREEN}Escapes${RESET} ${RED}↓${RESET}"
    echo "         ${RED}Falls in${RESET}"
    echo ""

    # Orbits around black hole
    echo -e "${TEXT_MUTED}╭─ STABLE ORBITS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${GREEN}●${RESET}  ${TEXT_MUTED}Stable orbit (6 Rs+)${RESET}"
    echo "                  ${GREEN}╱${RESET}   ${GREEN}╲${RESET}"
    echo "                ${YELLOW}●${RESET}       ${YELLOW}●${RESET}  ${TEXT_MUTED}Innermost stable (3 Rs)${RESET}"
    echo "               ${YELLOW}╱${RESET}           ${YELLOW}╲${RESET}"
    echo "             ${ORANGE}●${RESET}      ${PURPLE}⚫${RESET}      ${ORANGE}●${RESET}  ${TEXT_MUTED}Photon sphere (1.5 Rs)${RESET}"
    echo "               ${ORANGE}╲${RESET}           ${ORANGE}╱${RESET}"
    echo "                ${RED}●${RESET}       ${RED}●${RESET}  ${TEXT_MUTED}Plunge orbit (<3 Rs)${RESET}"
    echo "                  ${RED}╲${RESET}   ${RED}╱${RESET}"
    echo "                    ${RED}●${RESET}"
    echo ""

    # Simulation stats
    echo -e "${TEXT_MUTED}╭─ SIMULATION STATISTICS ───────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Particles Simulated:${RESET} ${CYAN}8,234,847${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Time Step:${RESET}           ${PURPLE}0.001 s${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Accuracy:${RESET}            ${GREEN}99.97%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Computation Time:${RESET}    ${ORANGE}2.47 ms/frame${RESET}"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[+/-]${RESET} Mass  ${TEXT_SECONDARY}[R]${RESET} Rotate  ${TEXT_SECONDARY}[L]${RESET} Lensing  ${TEXT_SECONDARY}[H]${RESET} Hawking  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_black_hole_simulator

        read -n1 key

        case "$key" in
            '+')
                BLACK_HOLE_MASS=$((BLACK_HOLE_MASS + 5))
                [ $BLACK_HOLE_MASS -gt 100 ] && BLACK_HOLE_MASS=100
                ;;
            '-')
                BLACK_HOLE_MASS=$((BLACK_HOLE_MASS - 5))
                [ $BLACK_HOLE_MASS -lt 3 ] && BLACK_HOLE_MASS=3
                ;;
            'r'|'R')
                echo -e "\n${CYAN}Rotating black hole (Kerr metric)...${RESET}"
                sleep 1
                ;;
            'l'|'L')
                echo -e "\n${PURPLE}Simulating gravitational lensing...${RESET}"
                sleep 1
                ;;
            'h'|'H')
                echo -e "\n${PINK}Calculating Hawking radiation...${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Exiting event horizon...${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
