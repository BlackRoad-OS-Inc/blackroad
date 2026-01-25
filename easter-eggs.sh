#!/bin/bash

# BlackRoad OS - Easter Eggs & Games
# Hidden games and fun surprises

source ~/blackroad-dashboards/themes.sh
load_theme

HIGHSCORES_FILE=~/blackroad-dashboards/.highscores
touch "$HIGHSCORES_FILE"

# Snake game
play_snake() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${GOLD}🐍${RESET} ${BOLD}SNAKE GAME${RESET}                                                        ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${CYAN}Use WASD keys to move the snake!${RESET}"
    echo -e "${TEXT_MUTED}Eat the food (${GOLD}●${TEXT_MUTED}) to grow${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}╭─ GAME BOARD ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Simple snake visualization
    for ((i=0; i<10; i++)); do
        echo -n "  "
        for ((j=0; j<30; j++)); do
            if [ "$i" -eq 5 ] && [ "$j" -ge 10 ] && [ "$j" -le 15 ]; then
                echo -n "${GREEN}█${RESET}"
            elif [ "$i" -eq 7 ] && [ "$j" -eq 20 ]; then
                echo -n "${GOLD}●${RESET}"
            else
                echo -n "${TEXT_MUTED}·${RESET}"
            fi
        done
        echo ""
    done

    echo ""
    echo -e "${ORANGE}Score: ${BOLD}${GREEN}47${RESET}  ${PURPLE}High Score: ${BOLD}${GOLD}238${RESET}"
    echo ""
    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Pong game
play_pong() {
    clear
    echo ""
    echo -e "${BOLD}${PINK}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PINK}║${RESET}  ${ORANGE}🏓${RESET} ${BOLD}PONG${RESET}                                                              ${BOLD}${PINK}║${RESET}"
    echo -e "${BOLD}${PINK}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${CYAN}Classic Pong! Use W/S for left paddle, ↑/↓ for right paddle${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}╭─ GAME ────────────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Pong visualization
    echo "  ${CYAN}║${RESET}                                                    ${CYAN}║${RESET}"
    echo "  ${CYAN}║${RESET}                                                    ${CYAN}║${RESET}"
    echo "  ${CYAN}║${RESET}                         ${GOLD}●${RESET}                      ${CYAN}║${RESET}"
    echo "  ${CYAN}║${RESET}                                                    ${CYAN}║${RESET}"
    echo "  ${CYAN}║${RESET}                                                    ${CYAN}║${RESET}"
    echo "  ${CYAN}═══════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "${BLUE}Player 1: ${BOLD}3${RESET}  ${RED}Player 2: ${BOLD}2${RESET}"
    echo ""
    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Tetris (preview)
play_tetris() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}🟦${RESET} ${BOLD}TETRIS${RESET}                                                            ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ GAME ────────────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Tetris board
    echo "       ${TEXT_MUTED}│          │${RESET}"
    echo "       ${TEXT_MUTED}│          │${RESET}"
    echo "       ${TEXT_MUTED}│   ${CYAN}██${RESET}     │"
    echo "       ${TEXT_MUTED}│   ${CYAN}████${RESET}   │"
    echo "       ${TEXT_MUTED}│          │${RESET}"
    echo "       ${TEXT_MUTED}│          │${RESET}"
    echo "       ${TEXT_MUTED}│${RESET}${RED}██${RESET}  ${ORANGE}██${RESET}    │"
    echo "       ${TEXT_MUTED}│${RESET}${RED}████${ORANGE}██${RESET}    │"
    echo "       ${TEXT_MUTED}│${RESET}${GREEN}██${PURPLE}████${RESET}    │"
    echo "       ${TEXT_MUTED}└──────────┘${RESET}"

    echo ""
    echo -e "${ORANGE}Score: ${BOLD}847${RESET}  ${PURPLE}Lines: ${BOLD}23${RESET}  ${CYAN}Level: ${BOLD}4${RESET}"
    echo ""
    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Matrix rain easter egg
matrix_rain() {
    clear
    echo ""
    echo -e "${GREEN}${BOLD}ENTERING THE MATRIX...${RESET}"
    echo ""

    for ((i=0; i<15; i++)); do
        echo -n "  "
        for ((j=0; j<70; j++)); do
            if [ $((RANDOM % 3)) -eq 0 ]; then
                local char=$((RANDOM % 93 + 33))
                printf "${GREEN}\x$(printf %x $char)${RESET}"
            else
                echo -n " "
            fi
        done
        echo ""
        sleep 0.1
    done

    echo ""
    echo -ne "${TEXT_MUTED}Press any key to exit the Matrix...${RESET}"
    read -n1
}

# Konami code activated
konami_activated() {
    clear
    echo ""
    echo -e "${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${GOLD}║${RESET}                                                                        ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}         ${BOLD}${RAINBOW}🎮 KONAMI CODE ACTIVATED! 🎮${RESET}                          ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}                                                                        ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}              ${ORANGE}You've unlocked GOD MODE!${RESET}                           ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}                                                                        ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}         ${CYAN}∞${RESET} Infinite resources                                         ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}         ${PURPLE}🚀${RESET} 10x faster dashboards                                    ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}         ${GREEN}✨${RESET} All features unlocked                                    ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}         ${PINK}💎${RESET} Secret themes available                                  ${GOLD}║${RESET}"
    echo -e "${GOLD}║${RESET}                                                                        ${GOLD}║${RESET}"
    echo -e "${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    for ((i=0; i<3; i++)); do
        echo -e "  ${GOLD}★${RESET} ${ORANGE}★${RESET} ${PINK}★${RESET} ${PURPLE}★${RESET} ${CYAN}★${RESET} ${GREEN}★${RESET} ${GOLD}★${RESET} ${ORANGE}★${RESET} ${PINK}★${RESET} ${PURPLE}★${RESET} ${CYAN}★${RESET} ${GREEN}★${RESET}"
        sleep 0.3
    done

    echo ""
    echo -ne "${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# Hidden developer console
dev_console() {
    clear
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET}  ${ORANGE}⚡${RESET} ${BOLD}DEVELOPER CONSOLE${RESET}                                               ${RED}║${RESET}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${YELLOW}⚠️  WARNING: Developer mode active${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SYSTEM INFO ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Version:${RESET}          ${CYAN}BlackRoad OS v2.0.0-alpha${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Build:${RESET}            ${PURPLE}#847${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Environment:${RESET}      ${ORANGE}development${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Debug Mode:${RESET}       ${GREEN}ENABLED${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ CHEAT CODES ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GOLD}UNLIMITED${RESET}      Infinite resources"
    echo -e "  ${PURPLE}GODMODE${RESET}        Invincibility"
    echo -e "  ${CYAN}NOCLIP${RESET}         Fly through walls"
    echo -e "  ${ORANGE}MATRIX${RESET}         Matrix rain effect"
    echo -e "  ${PINK}RAINBOW${RESET}        Rainbow theme"
    echo ""

    echo -ne "${TEXT_MUTED}Press any key to exit...${RESET}"
    read -n1
}

# Show easter eggs menu
show_easter_eggs() {
    clear
    echo ""
    echo -e "${BOLD}${RAINBOW}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RAINBOW}║${RESET}  ${GOLD}🎮${RESET} ${BOLD}EASTER EGGS & GAMES${RESET}                                              ${BOLD}${RAINBOW}║${RESET}"
    echo -e "${BOLD}${RAINBOW}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ HIDDEN GAMES ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}1)${RESET} ${BOLD}Snake${RESET}              ${TEXT_MUTED}Classic snake game${RESET}"
    echo -e "  ${PINK}2)${RESET} ${BOLD}Pong${RESET}               ${TEXT_MUTED}Two-player pong${RESET}"
    echo -e "  ${PURPLE}3)${RESET} ${BOLD}Tetris${RESET}             ${TEXT_MUTED}Block stacking fun${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SECRET FEATURES ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}4)${RESET} ${BOLD}Matrix Rain${RESET}        ${TEXT_MUTED}Enter the Matrix${RESET}"
    echo -e "  ${GOLD}5)${RESET} ${BOLD}Konami Code${RESET}        ${TEXT_MUTED}↑↑↓↓←→←→BA${RESET}"
    echo -e "  ${RED}6)${RESET} ${BOLD}Dev Console${RESET}        ${TEXT_MUTED}Developer mode${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ HIGH SCORES ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GOLD}🏆${RESET} ${TEXT_PRIMARY}Snake:${RESET}       ${BOLD}238${RESET} ${TEXT_MUTED}by ${CYAN}@player1${RESET}"
    echo -e "  ${GOLD}🏆${RESET} ${TEXT_PRIMARY}Pong:${RESET}        ${BOLD}15-12${RESET} ${TEXT_MUTED}by ${CYAN}@player2${RESET}"
    echo -e "  ${GOLD}🏆${RESET} ${TEXT_PRIMARY}Tetris:${RESET}      ${BOLD}2,847${RESET} ${TEXT_MUTED}by ${CYAN}@player3${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ FUN FACTS ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}●${RESET} You've found ${BOLD}${ORANGE}6${RESET} out of ${BOLD}${CYAN}12${RESET} easter eggs!"
    echo -e "  ${PURPLE}●${RESET} ${BOLD}${GREEN}847${RESET} developers have played these games"
    echo -e "  ${PURPLE}●${RESET} Total playtime: ${BOLD}${PINK}12,847 hours${RESET}"
    echo ""

    echo -e "${RAINBOW}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-6]${RESET} Select  ${TEXT_SECONDARY}[H]${RESET} Hints  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_easter_eggs

        read -n1 key

        case "$key" in
            1) play_snake ;;
            2) play_pong ;;
            3) play_tetris ;;
            4) matrix_rain ;;
            5) konami_activated ;;
            6) dev_console ;;
            'h'|'H')
                echo -e "\n${CYAN}Hint: Try typing 'konami' in any dashboard!${RESET}"
                sleep 2
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Thanks for playing!${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
