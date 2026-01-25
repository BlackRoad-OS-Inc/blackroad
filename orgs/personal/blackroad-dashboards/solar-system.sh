#!/bin/bash

# BlackRoad OS - Solar System Explorer
# Explore planets, moons, and celestial bodies

source ~/blackroad-dashboards/themes.sh
load_theme

SELECTED_PLANET="Earth"
ZOOM_LEVEL=1

# Show solar system explorer
show_solar_system() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${ORANGE}🪐${RESET} ${BOLD}SOLAR SYSTEM EXPLORER${RESET}                                           ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Solar system overview
    echo -e "${TEXT_MUTED}╭─ SOLAR SYSTEM MAP ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                            ${GOLD}☀${RESET} ${TEXT_MUTED}Sun${RESET}"
    echo ""
    echo "      ${TEXT_MUTED}Mercury${RESET}  ${ORANGE}●${RESET}"
    echo "       ${TEXT_MUTED}Venus${RESET}     ${YELLOW}●${RESET}"
    echo "       ${TEXT_MUTED}Earth${RESET}       ${BLUE}●${RESET} ${TEXT_MUTED}${RESET}"
    echo "        ${TEXT_MUTED}Mars${RESET}         ${RED}●${RESET}"
    echo "     ${TEXT_MUTED}Jupiter${RESET}              ${ORANGE}◉${RESET}"
    echo "      ${TEXT_MUTED}Saturn${RESET}                  ${GOLD}◉${RESET}"
    echo "      ${TEXT_MUTED}Uranus${RESET}                      ${CYAN}●${RESET}"
    echo "     ${TEXT_MUTED}Neptune${RESET}                          ${BLUE}●${RESET}"
    echo ""

    # Selected planet details
    echo -e "${TEXT_MUTED}╭─ SELECTED: $SELECTED_PLANET ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    case "$SELECTED_PLANET" in
        "Mercury")
            echo "                      ${ORANGE}◉${RESET}"
            echo "                    ${ORANGE}╱   ╲${RESET}"
            echo "                   ${ORANGE}│     │${RESET}"
            echo "                    ${ORANGE}╲   ╱${RESET}"
            echo "                      ${ORANGE}◉${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${CYAN}4,879 km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Distance from Sun:${RESET}   ${ORANGE}57.9 million km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Orbital Period:${RESET}      ${PURPLE}88 Earth days${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Day Length:${RESET}          ${PINK}59 Earth days${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Moons:${RESET}               ${TEXT_MUTED}0${RESET}"
            ;;
        "Earth")
            echo "                      ${BLUE}◉${RESET}"
            echo "                    ${BLUE}╱${RESET} ${GREEN}▓${RESET} ${BLUE}╲${RESET}"
            echo "                   ${BLUE}│${RESET}${GREEN}▓${RESET}${BLUE}▒${RESET}${GREEN}▓${RESET}${BLUE}│${RESET}  ${TEXT_MUTED}🌙${RESET}"
            echo "                    ${BLUE}╲${RESET} ${GREEN}▓${RESET} ${BLUE}╱${RESET}"
            echo "                      ${BLUE}◉${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${CYAN}12,742 km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Distance from Sun:${RESET}   ${ORANGE}149.6 million km${RESET} ${TEXT_MUTED}(1 AU)${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Orbital Period:${RESET}      ${PURPLE}365.25 days${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Day Length:${RESET}          ${PINK}24 hours${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Moons:${RESET}               ${GREEN}1${RESET} ${TEXT_MUTED}(The Moon)${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Atmosphere:${RESET}          ${BLUE}N₂ (78%), O₂ (21%)${RESET}"
            ;;
        "Mars")
            echo "                      ${RED}◉${RESET}"
            echo "                    ${RED}╱${RESET} ${ORANGE}░${RESET} ${RED}╲${RESET}"
            echo "                   ${RED}│${RESET}${ORANGE}░${RESET}${RED}▒${RESET}${ORANGE}░${RESET}${RED}│${RESET}"
            echo "                    ${RED}╲${RESET} ${ORANGE}░${RESET} ${RED}╱${RESET}"
            echo "                      ${RED}◉${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${CYAN}6,779 km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Distance from Sun:${RESET}   ${ORANGE}227.9 million km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Orbital Period:${RESET}      ${PURPLE}687 Earth days${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Day Length:${RESET}          ${PINK}24.6 hours${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Moons:${RESET}               ${GREEN}2${RESET} ${TEXT_MUTED}(Phobos, Deimos)${RESET}"
            ;;
        "Jupiter")
            echo "                       ${ORANGE}◉◉◉${RESET}"
            echo "                     ${ORANGE}╱${RESET}${YELLOW}═══${RESET}${ORANGE}╲${RESET}"
            echo "                    ${ORANGE}│${RESET}${YELLOW}═════${RESET}${ORANGE}│${RESET}"
            echo "                    ${ORANGE}│${RESET}${ORANGE}▓▓▓▓▓${RESET}${ORANGE}│${RESET}"
            echo "                     ${ORANGE}╲${RESET}${YELLOW}═══${RESET}${ORANGE}╱${RESET}"
            echo "                       ${ORANGE}◉◉◉${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${CYAN}139,820 km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Distance from Sun:${RESET}   ${ORANGE}778.5 million km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Orbital Period:${RESET}      ${PURPLE}11.86 Earth years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Day Length:${RESET}          ${PINK}9.9 hours${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Moons:${RESET}               ${GREEN}95${RESET} ${TEXT_MUTED}(Io, Europa, Ganymede, Callisto...)${RESET}"
            ;;
        "Saturn")
            echo "                   ${TEXT_MUTED}═════════${RESET}"
            echo "                     ${GOLD}◉◉${RESET}"
            echo "                    ${GOLD}╱${RESET}${YELLOW}══${RESET}${GOLD}╲${RESET}"
            echo "              ${TEXT_MUTED}════${RESET}${GOLD}│${RESET}${YELLOW}════${RESET}${GOLD}│${RESET}${TEXT_MUTED}════${RESET}"
            echo "                    ${GOLD}╲${RESET}${YELLOW}══${RESET}${GOLD}╱${RESET}"
            echo "                     ${GOLD}◉◉${RESET}"
            echo "                   ${TEXT_MUTED}═════════${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Diameter:${RESET}            ${CYAN}116,460 km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Distance from Sun:${RESET}   ${ORANGE}1.43 billion km${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Orbital Period:${RESET}      ${PURPLE}29.46 Earth years${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Day Length:${RESET}          ${PINK}10.7 hours${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Moons:${RESET}               ${GREEN}146${RESET} ${TEXT_MUTED}(Titan, Enceladus...)${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Rings:${RESET}               ${GOLD}Spectacular!${RESET}"
            ;;
    esac
    echo ""

    # Orbital positions (current)
    echo -e "${TEXT_MUTED}╭─ ORBITAL POSITIONS (TODAY) ───────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                         ${GOLD}☀${RESET}"
    echo "                       ${GOLD}╱ │ ╲${RESET}"
    echo "       ${ORANGE}Mercury${RESET}    ${ORANGE}●${RESET}  ${GOLD}│${RESET}"
    echo "                     ${YELLOW}●${RESET}  ${GOLD}│${RESET}  ${RED}●${RESET}  ${RED}Mars${RESET}"
    echo "        ${YELLOW}Venus${RESET}      ${GOLD}│${RESET}  ${BLUE}●${RESET}  ${BLUE}Earth${RESET}"
    echo "                       ${GOLD}╲ │ ╱${RESET}"
    echo "                         ${GOLD}│${RESET}"
    echo "                    ${ORANGE}◉${RESET}   ${GOLD}│${RESET}   ${GOLD}◉${RESET}"
    echo "                 ${ORANGE}Jupiter${RESET}  ${GOLD}│${RESET}  ${GOLD}Saturn${RESET}"
    echo ""

    # Interesting facts
    echo -e "${TEXT_MUTED}╭─ DID YOU KNOW? ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    case "$SELECTED_PLANET" in
        "Mercury")
            echo -e "  ${PURPLE}●${RESET} Mercury has the most eccentric orbit of all planets"
            echo -e "  ${PURPLE}●${RESET} Surface temperature ranges from -173°C to 427°C"
            ;;
        "Earth")
            echo -e "  ${PURPLE}●${RESET} Earth is the only known planet with liquid water"
            echo -e "  ${PURPLE}●${RESET} The Moon is slowly drifting away at 3.8cm per year"
            ;;
        "Mars")
            echo -e "  ${PURPLE}●${RESET} Mars has the largest volcano: Olympus Mons (25km high)"
            echo -e "  ${PURPLE}●${RESET} Evidence suggests Mars once had liquid water"
            ;;
        "Jupiter")
            echo -e "  ${PURPLE}●${RESET} The Great Red Spot is a storm larger than Earth"
            echo -e "  ${PURPLE}●${RESET} Europa may have a subsurface ocean with twice Earth's water"
            ;;
        "Saturn")
            echo -e "  ${PURPLE}●${RESET} Saturn's rings are made of ice and rock particles"
            echo -e "  ${PURPLE}●${RESET} Titan has lakes of liquid methane and ethane"
            ;;
    esac
    echo ""

    # Missions
    echo -e "${TEXT_MUTED}╭─ ACTIVE MISSIONS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}Parker Solar Probe${RESET}  ${TEXT_MUTED}Studying the Sun${RESET}      ${GREEN}✓ ACTIVE${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Perseverance${RESET}        ${TEXT_MUTED}Mars rover${RESET}            ${GREEN}✓ ACTIVE${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Juno${RESET}                ${TEXT_MUTED}Orbiting Jupiter${RESET}      ${GREEN}✓ ACTIVE${RESET}"
    echo -e "  ${GREEN}●${RESET} ${BOLD}Cassini Legacy${RESET}      ${TEXT_MUTED}Saturn data${RESET}           ${CYAN}COMPLETE${RESET}"
    echo ""

    # Astronomical events
    echo -e "${TEXT_MUTED}╭─ UPCOMING EVENTS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${YELLOW}●${RESET} ${BOLD}Mars Opposition${RESET}     ${TEXT_MUTED}Jan 15, 2025${RESET}   ${ORANGE}Closest approach${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Lunar Eclipse${RESET}       ${TEXT_MUTED}Mar 14, 2025${RESET}   ${PURPLE}Total${RESET}"
    echo -e "  ${PINK}●${RESET} ${BOLD}Venus at Max${RESET}        ${TEXT_MUTED}Apr 22, 2025${RESET}   ${YELLOW}Evening star${RESET}"
    echo ""

    # Statistics
    echo -e "${TEXT_MUTED}╭─ SOLAR SYSTEM STATS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Age:${RESET}                 ${CYAN}4.6 billion years${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Planets:${RESET}             ${ORANGE}8${RESET} ${TEXT_MUTED}(+ 5 dwarf planets)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Known Moons:${RESET}         ${PURPLE}290+${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Asteroids:${RESET}           ${GREEN}1.1 million+${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Comets:${RESET}              ${BLUE}3,700+${RESET}"
    echo ""

    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-5]${RESET} Select Planet  ${TEXT_SECONDARY}[M]${RESET} Moons  ${TEXT_SECONDARY}[A]${RESET} Asteroids  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_solar_system

        read -n1 key

        case "$key" in
            '1')
                SELECTED_PLANET="Mercury"
                ;;
            '2')
                SELECTED_PLANET="Earth"
                ;;
            '3')
                SELECTED_PLANET="Mars"
                ;;
            '4')
                SELECTED_PLANET="Jupiter"
                ;;
            '5')
                SELECTED_PLANET="Saturn"
                ;;
            'm'|'M')
                echo -e "\n${CYAN}Loading moon data...${RESET}"
                sleep 1
                ;;
            'a'|'A')
                echo -e "\n${ORANGE}Loading asteroid belt...${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Returning to Earth...${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
