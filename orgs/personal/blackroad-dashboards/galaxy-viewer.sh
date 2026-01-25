#!/bin/bash

# BlackRoad OS - Galaxy Cluster Viewer
# Explore galaxies and galaxy clusters

source ~/blackroad-dashboards/themes.sh
load_theme

CURRENT_GALAXY="Milky Way"
REDSHIFT=0

# Show galaxy viewer
show_galaxy_viewer() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${PINK}🌌${RESET} ${BOLD}GALAXY CLUSTER VIEWER${RESET}                                           ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Current galaxy visualization
    echo -e "${TEXT_MUTED}╭─ VIEWING: $CURRENT_GALAXY ────────────────────────────────────────────────╮${RESET}"
    echo ""

    case "$CURRENT_GALAXY" in
        "Milky Way")
            # Spiral galaxy (edge-on view)
            echo "                        ${GOLD}◇${RESET} ${TEXT_MUTED}Galactic Center${RESET}"
            echo "                      ${GOLD}╱${RESET} ${GOLD}│${RESET} ${GOLD}╲${RESET}"
            echo "                    ${CYAN}●${RESET} ${GOLD}╱${RESET}  ${GOLD}│${RESET}  ${GOLD}╲${RESET} ${CYAN}●${RESET}"
            echo "                  ${CYAN}●${RESET}   ${GOLD}╱${RESET}   ${GOLD}│${RESET}   ${GOLD}╲${RESET}   ${CYAN}●${RESET}"
            echo "                ${CYAN}●${RESET}     ${GOLD}╱${RESET}    ${GOLD}│${RESET}    ${GOLD}╲${RESET}     ${CYAN}●${RESET}"
            echo "     ${TEXT_MUTED}You are here${RESET} ${GREEN}☉${RESET}${CYAN}●${RESET}  ${GOLD}━━━━━┼━━━━━${RESET}  ${CYAN}●${RESET}${CYAN}●${RESET}"
            echo "                ${CYAN}●${RESET}     ${GOLD}╲${RESET}    ${GOLD}│${RESET}    ${GOLD}╱${RESET}     ${CYAN}●${RESET}"
            echo "                  ${CYAN}●${RESET}   ${GOLD}╲${RESET}   ${GOLD}│${RESET}   ${GOLD}╱${RESET}   ${CYAN}●${RESET}"
            echo "                    ${CYAN}●${RESET} ${GOLD}╲${RESET}  ${GOLD}│${RESET}  ${GOLD}╱${RESET} ${CYAN}●${RESET}"
            echo "                      ${GOLD}╲${RESET} ${GOLD}│${RESET} ${GOLD}╱${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Type:${RESET}                ${CYAN}Barred Spiral (SBbc)${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${ORANGE}100,000 light-years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Stars:${RESET}               ${PURPLE}200-400 billion${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Age:${RESET}                 ${PINK}13.6 billion years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Rotation Period:${RESET}     ${GREEN}225 million years${RESET}"
            ;;
        "Andromeda")
            # Spiral galaxy (face-on)
            echo "                      ${CYAN}●${RESET}   ${CYAN}●${RESET}   ${CYAN}●${RESET}"
            echo "                    ${CYAN}●${RESET}   ${PURPLE}●${RESET}   ${PURPLE}●${RESET}   ${CYAN}●${RESET}"
            echo "                  ${CYAN}●${RESET}   ${PURPLE}●${RESET}  ${GOLD}◉${RESET}  ${PURPLE}●${RESET}   ${CYAN}●${RESET}"
            echo "                ${CYAN}●${RESET}   ${PURPLE}●${RESET}  ${GOLD}╱${RESET} ${GOLD}│${RESET} ${GOLD}╲${RESET}  ${PURPLE}●${RESET}   ${CYAN}●${RESET}"
            echo "                  ${CYAN}●${RESET}   ${PURPLE}●${RESET}  ${GOLD}◉${RESET}  ${PURPLE}●${RESET}   ${CYAN}●${RESET}"
            echo "                    ${CYAN}●${RESET}   ${PURPLE}●${RESET}   ${PURPLE}●${RESET}   ${CYAN}●${RESET}"
            echo "                      ${CYAN}●${RESET}   ${CYAN}●${RESET}   ${CYAN}●${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Type:${RESET}                ${CYAN}Spiral (SA(s)b)${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Distance:${RESET}            ${ORANGE}2.5 million light-years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${PURPLE}220,000 light-years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Stars:${RESET}               ${PINK}1 trillion${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Collision:${RESET}           ${RED}Will merge with Milky Way in 4.5 billion years${RESET}"
            ;;
        "Whirlpool")
            echo "                       ${CYAN}●${RESET}${CYAN}●${RESET}${CYAN}●${RESET}"
            echo "                     ${CYAN}●${RESET}${PURPLE}●${RESET}${PURPLE}●${RESET}${PURPLE}●${RESET}${CYAN}●${RESET}"
            echo "                   ${CYAN}●${RESET}${PURPLE}●${RESET}${GOLD}◉${RESET}${GOLD}◉${RESET}${PURPLE}●${RESET}${CYAN}●${RESET}     ${BLUE}●${RESET}"
            echo "                     ${CYAN}●${RESET}${PURPLE}●${RESET}${PURPLE}●${RESET}${PURPLE}●${RESET}${CYAN}●${RESET}   ${BLUE}●${RESET}${BLUE}●${RESET}"
            echo "                       ${CYAN}●${RESET}${CYAN}●${RESET}${CYAN}●${RESET}  ${BLUE}●${RESET}${PINK}◉${RESET}${BLUE}●${RESET}"
            echo "                            ${BLUE}●${RESET}${BLUE}●${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Type:${RESET}                ${CYAN}Grand Design Spiral${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Distance:${RESET}            ${ORANGE}23 million light-years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${PURPLE}76,000 light-years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Companion:${RESET}           ${BLUE}NGC 5195${RESET} ${TEXT_MUTED}(interacting)${RESET}"
            ;;
    esac
    echo ""

    # Local Group
    echo -e "${TEXT_MUTED}╭─ LOCAL GROUP (NEARBY GALAXIES) ───────────────────────────────────────╮${RESET}"
    echo ""

    echo "                    ${TEXT_MUTED}2.5 Mly${RESET}"
    echo "                       ${CYAN}◉${RESET}"
    echo "       ${PINK}Triangulum${RESET}    ${TEXT_MUTED}╱${RESET}   ${CYAN}Andromeda${RESET}"
    echo "            ${PINK}◉${RESET}       ${TEXT_MUTED}╱${RESET}"
    echo "                   ${TEXT_MUTED}╱${RESET}"
    echo "           ${GREEN}☉${RESET} ${GREEN}Milky Way${RESET}"
    echo "              ${TEXT_MUTED}│${RESET}"
    echo "              ${TEXT_MUTED}│${RESET}    ${ORANGE}Large${RESET}"
    echo "         ${PURPLE}●${RESET}${PURPLE}●${RESET}${PURPLE}●${RESET}${TEXT_MUTED}│${RESET}${PURPLE}●${RESET}  ${ORANGE}Magellanic${RESET}"
    echo "              ${TEXT_MUTED}│${RESET}    ${ORANGE}Cloud${RESET}"
    echo "          ${TEXT_MUTED}Satellite${RESET}"
    echo "          ${TEXT_MUTED}galaxies${RESET}"
    echo ""

    # Deep space objects
    echo -e "${TEXT_MUTED}╭─ DEEP SPACE OBJECTS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}Galaxies:${RESET}"
    echo -e "    ${CYAN}●${RESET} ${BOLD}Sombrero Galaxy${RESET}     ${TEXT_MUTED}28 Mly${RESET}   ${CYAN}Spiral${RESET}"
    echo -e "    ${PURPLE}●${RESET} ${BOLD}Pinwheel Galaxy${RESET}     ${TEXT_MUTED}21 Mly${RESET}   ${PURPLE}Spiral${RESET}"
    echo -e "    ${ORANGE}●${RESET} ${BOLD}Centaurus A${RESET}         ${TEXT_MUTED}13 Mly${RESET}   ${ORANGE}Elliptical${RESET}"
    echo ""

    echo -e "  ${BOLD}Galaxy Clusters:${RESET}"
    echo -e "    ${PINK}●${RESET} ${BOLD}Virgo Cluster${RESET}       ${TEXT_MUTED}54 Mly${RESET}   ${PINK}1,300 galaxies${RESET}"
    echo -e "    ${BLUE}●${RESET} ${BOLD}Coma Cluster${RESET}        ${TEXT_MUTED}320 Mly${RESET}  ${BLUE}1,000+ galaxies${RESET}"
    echo ""

    # Hubble classification
    echo -e "${TEXT_MUTED}╭─ HUBBLE GALAXY CLASSIFICATION ────────────────────────────────────────╮${RESET}"
    echo ""

    echo "     ${ORANGE}Elliptical${RESET}           ${CYAN}Spiral${RESET}           ${PURPLE}Irregular${RESET}"
    echo ""
    echo "        ${ORANGE}◉${RESET}               ${CYAN}╱${RESET}${CYAN}─${RESET}${CYAN}○${RESET}${CYAN}─${RESET}${CYAN}╲${RESET}             ${PURPLE}◇${RESET}${PURPLE}◇${RESET}"
    echo "       ${ORANGE}◉${RESET}${ORANGE}◉${RESET}             ${CYAN}╱${RESET}   ${CYAN}│${RESET}   ${CYAN}╲${RESET}           ${PURPLE}◇${RESET}  ${PURPLE}◇${RESET}"
    echo "      ${ORANGE}◉${RESET}${ORANGE}◉${RESET}${ORANGE}◉${RESET}           ${CYAN}│${RESET}    ${CYAN}│${RESET}    ${CYAN}│${RESET}          ${PURPLE}◇${RESET}"
    echo "       ${ORANGE}E0${RESET}              ${CYAN}S0${RESET}  ${CYAN}Sa${RESET}  ${CYAN}Sc${RESET}           ${PURPLE}Irr${RESET}"
    echo ""

    # Cosmic web
    echo -e "${TEXT_MUTED}╭─ COSMIC WEB STRUCTURE ────────────────────────────────────────────────╮${RESET}"
    echo ""

    for ((i=0; i<8; i++)); do
        echo -n "  "
        for ((j=0; j<60; j++)); do
            local density=$((RANDOM % 100))
            if [ $density -gt 95 ]; then
                echo -n "${GOLD}◉${RESET}"
            elif [ $density -gt 85 ]; then
                echo -n "${CYAN}●${RESET}"
            elif [ $density -gt 75 ]; then
                echo -n "${PURPLE}·${RESET}"
            else
                echo -n " "
            fi
        done
        echo ""
    done
    echo ""
    echo "  ${GOLD}Galaxy clusters${RESET}  ${CYAN}Galaxies${RESET}  ${PURPLE}Filaments${RESET}  ${TEXT_MUTED}Voids${RESET}"
    echo ""

    # Observable universe statistics
    echo -e "${TEXT_MUTED}╭─ OBSERVABLE UNIVERSE ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${CYAN}93 billion light-years${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Galaxies:${RESET}            ${PURPLE}2 trillion${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Stars:${RESET}               ${ORANGE}10²⁴${RESET} ${TEXT_MUTED}(1 septillion)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Age:${RESET}                 ${PINK}13.8 billion years${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Expansion Rate:${RESET}      ${GREEN}73 km/s/Mpc${RESET} ${TEXT_MUTED}(Hubble constant)${RESET}"
    echo ""

    # Redshift visualization
    echo -e "${TEXT_MUTED}╭─ DISTANCE & REDSHIFT ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "  ${TEXT_MUTED}z=0${RESET}    ${GREEN}●${RESET}  ${TEXT_MUTED}Local Universe${RESET}"
    echo "  ${TEXT_MUTED}z=1${RESET}       ${CYAN}●${RESET}  ${TEXT_MUTED}~8 billion ly${RESET}"
    echo "  ${TEXT_MUTED}z=2${RESET}          ${BLUE}●${RESET}  ${TEXT_MUTED}~10.5 billion ly${RESET}"
    echo "  ${TEXT_MUTED}z=5${RESET}             ${PURPLE}●${RESET}  ${TEXT_MUTED}~12.5 billion ly${RESET}"
    echo "  ${TEXT_MUTED}z=10${RESET}               ${PINK}●${RESET}  ${TEXT_MUTED}~13.2 billion ly (early universe)${RESET}"
    echo ""

    # Active research
    echo -e "${TEXT_MUTED}╭─ ACTIVE TELESCOPES ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}James Webb${RESET}          ${TEXT_MUTED}Infrared${RESET}       ${GREEN}✓ ACTIVE${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Hubble${RESET}              ${TEXT_MUTED}Optical/UV${RESET}     ${GREEN}✓ ACTIVE${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Chandra${RESET}             ${TEXT_MUTED}X-ray${RESET}          ${GREEN}✓ ACTIVE${RESET}"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}VLA${RESET}                 ${TEXT_MUTED}Radio${RESET}          ${GREEN}✓ ACTIVE${RESET}"
    echo ""

    # Dark matter/energy
    echo -e "${TEXT_MUTED}╭─ UNIVERSE COMPOSITION ────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -n "  ${BOLD}Dark Energy${RESET}  "
    echo -e "${PURPLE}██████████████${TEXT_MUTED}░░░░░░${RESET}  ${BOLD}68%${RESET}"

    echo -n "  ${BOLD}Dark Matter${RESET}  "
    echo -e "${BLUE}█████${TEXT_MUTED}░░░░░░░░░░░░░░░${RESET}  ${BOLD}27%${RESET}"

    echo -n "  ${BOLD}Normal Matter${RESET}"
    echo -e "${GREEN}█${TEXT_MUTED}░░░░░░░░░░░░░░░░░░░${RESET}  ${BOLD}5%${RESET}"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-3]${RESET} Galaxy  ${TEXT_SECONDARY}[C]${RESET} Clusters  ${TEXT_SECONDARY}[D]${RESET} Deep Space  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_galaxy_viewer

        read -n1 key

        case "$key" in
            '1')
                CURRENT_GALAXY="Milky Way"
                ;;
            '2')
                CURRENT_GALAXY="Andromeda"
                ;;
            '3')
                CURRENT_GALAXY="Whirlpool"
                ;;
            'c'|'C')
                echo -e "\n${PURPLE}Loading galaxy clusters...${RESET}"
                sleep 1
                ;;
            'd'|'D')
                echo -e "\n${CYAN}Scanning deep space...${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Returning to the Milky Way...${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
