#!/bin/bash

# BlackRoad OS - Progress Animations
# Beautiful animated progress indicators

source ~/blackroad-dashboards/themes.sh
load_theme

# Animation characters
SPINNER_CHARS="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
DOTS_CHARS="⠁⠂⠄⡀⢀⠠⠐⠈"
BLOCKS_CHARS="▏▎▍▌▋▊▉█"
ARROWS_CHARS="←↖↑↗→↘↓↙"
BOUNCE_CHARS="⠁⠂⠄⡀⢀⠠⠐⠈⠐⠠⢀⡀⠄⠂"

# Spinner animation
spinner_animation() {
    local duration=${1:-10}
    local message=${2:-"Processing"}

    for ((i=0; i<duration*10; i++)); do
        local idx=$((i % 10))
        echo -ne "\r  ${CYAN}${SPINNER_CHARS:$idx:1}${RESET} ${message}...   "
        sleep 0.1
    done
    echo -e "\r  ${GREEN}✓${RESET} ${message}... ${GREEN}${BOLD}Done!${RESET}     "
}

# Progress bar with percentage
progress_bar() {
    local total=${1:-100}
    local width=50
    local message=${2:-"Loading"}

    for ((i=0; i<=total; i++)); do
        local filled=$((i * width / total))
        local percent=$((i * 100 / total))

        # Build progress bar
        local bar=""
        for ((j=0; j<width; j++)); do
            if [ "$j" -lt "$filled" ]; then
                # Color gradient based on progress
                if [ "$percent" -ge 80 ]; then
                    bar="${bar}${GREEN}█${RESET}"
                elif [ "$percent" -ge 50 ]; then
                    bar="${bar}${YELLOW}█${RESET}"
                elif [ "$percent" -ge 30 ]; then
                    bar="${bar}${ORANGE}█${RESET}"
                else
                    bar="${bar}${CYAN}█${RESET}"
                fi
            else
                bar="${bar}${TEXT_MUTED}░${RESET}"
            fi
        done

        echo -ne "\r  ${message}: [$bar] ${BOLD}${percent}%${RESET}  "
        sleep 0.03
    done
    echo ""
}

# Multi-bar progress (parallel tasks)
multi_progress() {
    local iterations=50

    for ((i=0; i<=iterations; i++)); do
        clear
        echo ""
        echo -e "${BOLD}${PURPLE}Parallel Task Progress${RESET}"
        echo ""

        # Task 1: Fast
        local p1=$((i * 2))
        [ "$p1" -gt 100 ] && p1=100
        local f1=$((p1 / 2))
        local bar1=""
        for ((j=0; j<50; j++)); do
            [ "$j" -lt "$f1" ] && bar1="${bar1}${GREEN}█${RESET}" || bar1="${bar1}${TEXT_MUTED}░${RESET}"
        done
        echo -e "  Task 1: [$bar1] ${BOLD}$p1%${RESET}"

        # Task 2: Medium
        local p2=$((i * 150 / 100))
        [ "$p2" -gt 100 ] && p2=100
        local f2=$((p2 / 2))
        local bar2=""
        for ((j=0; j<50; j++)); do
            [ "$j" -lt "$f2" ] && bar2="${bar2}${YELLOW}█${RESET}" || bar2="${bar2}${TEXT_MUTED}░${RESET}"
        done
        echo -e "  Task 2: [$bar2] ${BOLD}$p2%${RESET}"

        # Task 3: Slow
        local p3=$((i * 80 / 100))
        local f3=$((p3 / 2))
        local bar3=""
        for ((j=0; j<50; j++)); do
            [ "$j" -lt "$f3" ] && bar3="${bar3}${ORANGE}█${RESET}" || bar3="${bar3}${TEXT_MUTED}░${RESET}"
        done
        echo -e "  Task 3: [$bar3] ${BOLD}$p3%${RESET}"

        # Task 4: Variable
        local p4=$((i + (i % 10) * 5))
        [ "$p4" -gt 100 ] && p4=100
        local f4=$((p4 / 2))
        local bar4=""
        for ((j=0; j<50; j++)); do
            [ "$j" -lt "$f4" ] && bar4="${bar4}${PINK}█${RESET}" || bar4="${bar4}${TEXT_MUTED}░${RESET}"
        done
        echo -e "  Task 4: [$bar4] ${BOLD}$p4%${RESET}"

        echo ""
        sleep 0.1
    done

    echo -e "${GREEN}${BOLD}All tasks complete!${RESET}"
    sleep 2
}

# Circular progress
circular_progress() {
    local chars="◜◝◞◟"
    local duration=${1:-10}

    for ((i=0; i<duration*4; i++)); do
        local idx=$((i % 4))
        local percent=$((i * 100 / (duration * 4)))
        echo -ne "\r  ${PURPLE}${chars:$idx:1}${RESET} Loading... ${BOLD}${percent}%${RESET}  "
        sleep 0.25
    done
    echo -e "\r  ${GREEN}✓${RESET} Loading... ${GREEN}${BOLD}100%${RESET}     "
}

# Wave animation
wave_animation() {
    local iterations=20
    local width=50

    for ((i=0; i<iterations; i++)); do
        echo -ne "\r  "
        for ((j=0; j<width; j++)); do
            local wave=$(echo "scale=2; s(($i + $j) * 3.14159 / 10)" | bc -l)
            local height=$(echo "scale=0; ($wave + 1) * 4 / 1" | bc)

            case "$height" in
                0|1) echo -ne "${CYAN}▁${RESET}" ;;
                2) echo -ne "${CYAN}▃${RESET}" ;;
                3) echo -ne "${CYAN}▅${RESET}" ;;
                4|5) echo -ne "${CYAN}▇${RESET}" ;;
                *) echo -ne "${CYAN}█${RESET}" ;;
            esac
        done
        echo -ne "  "
        sleep 0.1
    done
    echo ""
}

# Pulsing dots
pulsing_dots() {
    local iterations=30
    local dots=(0 0 0 0 0)

    for ((i=0; i<iterations; i++)); do
        echo -ne "\r  "
        for ((j=0; j<5; j++)); do
            local offset=$((( i + j * 3 ) % 10))
            local intensity=$((offset < 5 ? offset : 10 - offset))

            case "$intensity" in
                0|1) echo -ne "${TEXT_MUTED}·${RESET} " ;;
                2|3) echo -ne "${ORANGE}●${RESET} " ;;
                *) echo -ne "${BOLD}${ORANGE}●${RESET} " ;;
            esac
        done
        echo -ne " Processing  "
        sleep 0.1
    done
    echo -e "\r  ${GREEN}✓ ✓ ✓ ✓ ✓${RESET} Processing... ${GREEN}${BOLD}Done!${RESET}     "
}

# Download simulation
download_simulation() {
    local total_mb=847
    local speed_mbps=42

    echo -e "\n  ${CYAN}Downloading blackroad-os-v2.0.tar.gz${RESET}"
    echo ""

    for ((mb=0; mb<=total_mb; mb+=speed_mbps)); do
        [ "$mb" -gt "$total_mb" ] && mb=$total_mb
        local percent=$((mb * 100 / total_mb))
        local filled=$((mb * 50 / total_mb))

        # Speed indicator
        local speed=$((RANDOM % 10 + 38))

        # Build bar
        local bar=""
        for ((j=0; j<50; j++)); do
            if [ "$j" -lt "$filled" ]; then
                bar="${bar}${GREEN}█${RESET}"
            else
                bar="${bar}${TEXT_MUTED}░${RESET}"
            fi
        done

        echo -ne "\r  [$bar] ${BOLD}${percent}%${RESET}  ${CYAN}${speed} MB/s${RESET}  "
        sleep 0.1
    done

    echo -e "\n\n  ${GREEN}✓${RESET} Download complete! ${TEXT_MUTED}(847 MB in 20s)${RESET}\n"
}

# Installation progress
installation_progress() {
    local steps=(
        "Extracting files"
        "Installing dependencies"
        "Configuring services"
        "Setting up database"
        "Running migrations"
        "Building assets"
        "Optimizing cache"
        "Starting services"
    )

    echo -e "\n  ${BOLD}${PURPLE}Installing BlackRoad OS...${RESET}\n"

    for step in "${steps[@]}"; do
        echo -ne "  ${CYAN}⋯${RESET} ${step}...   "

        # Random duration
        local duration=$((RANDOM % 20 + 10))
        for ((i=0; i<duration; i++)); do
            local idx=$((i % 10))
            echo -ne "\b\b\b\b${CYAN}${SPINNER_CHARS:$idx:1}${RESET}   "
            sleep 0.05
        done

        echo -e "\b\b\b\b${GREEN}✓${RESET}   "
    done

    echo -e "\n  ${GREEN}${BOLD}Installation complete!${RESET}\n"
}

# Show all animations
show_animations_demo() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${PURPLE}⚡${RESET} ${BOLD}PROGRESS ANIMATIONS SHOWCASE${RESET}                                     ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ANIMATIONS MENU ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo "  ${ORANGE}1)${RESET} Spinner Animation"
    echo "  ${PINK}2)${RESET} Progress Bar"
    echo "  ${PURPLE}3)${RESET} Multi-Task Progress"
    echo "  ${CYAN}4)${RESET} Circular Progress"
    echo "  ${BLUE}5)${RESET} Wave Animation"
    echo "  ${GREEN}6)${RESET} Pulsing Dots"
    echo "  ${YELLOW}7)${RESET} Download Simulation"
    echo "  ${GOLD}8)${RESET} Installation Progress"
    echo "  ${RED}9)${RESET} Show All (Sequential)"
    echo ""

    echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-9]${RESET} Select animation  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
    echo -ne "${TEXT_PRIMARY}Select option: ${RESET}"

    read -n1 choice
    echo ""
    echo ""

    case "$choice" in
        1)
            spinner_animation 3 "Processing data"
            echo ""
            sleep 1
            ;;
        2)
            progress_bar 100 "Loading dashboard"
            echo ""
            sleep 1
            ;;
        3)
            multi_progress
            ;;
        4)
            circular_progress 5
            echo ""
            sleep 1
            ;;
        5)
            echo -e "  ${BOLD}${CYAN}Wave Animation${RESET}\n"
            wave_animation
            echo ""
            sleep 1
            ;;
        6)
            pulsing_dots
            echo ""
            sleep 1
            ;;
        7)
            download_simulation
            sleep 2
            ;;
        8)
            installation_progress
            sleep 2
            ;;
        9)
            echo -e "${BOLD}${PURPLE}Running all animations...${RESET}\n"
            spinner_animation 2 "Spinner"
            echo ""
            progress_bar 50 "Progress Bar"
            echo ""
            circular_progress 2
            echo ""
            echo -e "  ${BOLD}${CYAN}Wave:${RESET}"
            wave_animation
            echo ""
            pulsing_dots
            echo ""
            download_simulation
            installation_progress
            ;;
        q|Q)
            echo -e "${CYAN}Goodbye!${RESET}\n"
            exit 0
            ;;
    esac

    echo -ne "${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# Main loop
main() {
    while true; do
        show_animations_demo
    done
}

# Run
main
