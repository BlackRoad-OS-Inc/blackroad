#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  ▓▓▓▓  PIXEL WORLD INTERACTIVE  ▓▓▓▓                        │
# │  Walk around the BlackRoad terminal metaverse               │
# ╰──────────────────────────────────────────────────────────────╯

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# COLORS
# ═══════════════════════════════════════════════════════════════
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
GREEN='\033[38;5;82m'
GRAY='\033[38;5;240m'
WHITE='\033[1;37m'
RESET='\033[0m'
DIM='\033[2m'
BOLD='\033[1m'

# ═══════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════
LOCATION="spawn"
PLAYER_X=5
PLAYER_Y=3
INVENTORY=()

# ═══════════════════════════════════════════════════════════════
# MINI MAP
# ═══════════════════════════════════════════════════════════════
render_minimap() {
    local px=$PLAYER_X
    local py=$PLAYER_Y

    echo -e "
${GRAY}╭─────────────────────────────────────────────────────────────────────────────╮${RESET}
${GRAY}│${RESET}                          ${WHITE}▓▓ PIXEL WORLD ▓▓${RESET}                              ${GRAY}│${RESET}
${GRAY}├─────────────────────────────────────────────────────────────────────────────┤${RESET}
${GRAY}│${RESET}                                                                           ${GRAY}│${RESET}"

    # Simple 7x5 map
    for y in {0..4}; do
        echo -n -e "${GRAY}│${RESET}  "
        for x in {0..10}; do
            if [[ $x -eq $px && $y -eq $py ]]; then
                echo -n -e "${PINK}▣_▣${RESET} "  # Player
            else
                case "$y-$x" in
                    "0-0"|"0-1"|"0-10") echo -n -e "${GREEN}▲${RESET}   " ;;       # Trees
                    "1-0"|"1-1"|"1-10") echo -n -e "${GREEN}▲${RESET}   " ;;
                    "2-5") echo -n -e "${AMBER}▲${RESET}   " ;;                     # House roof
                    "3-5") echo -n -e "${GRAY}▣${RESET}   " ;;                      # House
                    "0-8"|"1-8") echo -n -e "${BLUE}◈${RESET}   " ;;               # Server
                    "4-"*) echo -n -e "${AMBER}═${RESET}   " ;;                     # Road
                    *) echo -n -e "${DIM}·${RESET}   " ;;                          # Empty
                esac
            fi
        done
        echo -e "     ${GRAY}│${RESET}"
    done

    echo -e "${GRAY}│${RESET}                                                                           ${GRAY}│${RESET}
${GRAY}├─────────────────────────────────────────────────────────────────────────────┤${RESET}
${GRAY}│${RESET}  ${GREEN}▲${RESET} forest   ${AMBER}▲${RESET} home   ${BLUE}◈${RESET} server   ${PINK}▣_▣${RESET} you   ${AMBER}═${RESET} road                   ${GRAY}│${RESET}
${GRAY}╰─────────────────────────────────────────────────────────────────────────────╯${RESET}"
}

# ═══════════════════════════════════════════════════════════════
# PLAYER SPRITE
# ═══════════════════════════════════════════════════════════════
show_player() {
    echo -e "
    ${PINK}╭───╮${RESET}
    ${PINK}│${WHITE}▣_▣${PINK}│${RESET}  ${WHITE}< ${1:-Hello world!}${RESET}
    ${PINK}╰─┬─╯${RESET}
     ${VIOLET}╱│╲${RESET}
    ${VIOLET}╱ │ ╲${RESET}
"
}

# ═══════════════════════════════════════════════════════════════
# NPCs
# ═══════════════════════════════════════════════════════════════
NPC_LUCIDIA() {
    echo -e "
  ${PINK}╭─────╮${RESET}
  ${PINK}│${WHITE} ▣ ▣ ${PINK}│${RESET}  ${DIM}\"Welcome to the forest, traveler!\"${RESET}
  ${PINK}│${AMBER}  ◡  ${PINK}│${RESET}
  ${PINK}╰──┬──╯${RESET}
    ${VIOLET}│${RESET}
   ${VIOLET}╱│╲${RESET}
"
}

NPC_EREBUS() {
    echo -e "
  ${VIOLET}╭─────╮${RESET}
  ${VIOLET}│${WHITE} ● ● ${VIOLET}│${RESET}  ${DIM}\"The darkness holds many secrets...\"${RESET}
  ${VIOLET}│${GRAY}  ─  ${VIOLET}│${RESET}
  ${VIOLET}╰──┬──╯${RESET}
    ${GRAY}║${RESET}
   ${GRAY}╔╩╗${RESET}
"
}

NPC_CECILIA() {
    echo -e "
  ${GREEN}╭─────╮${RESET}
  ${GREEN}│${WHITE} ◈ ◈ ${GREEN}│${RESET}  ${DIM}\"Processing at 26 TOPS...\"${RESET}
  ${GREEN}│${AMBER}  ∀  ${GREEN}│${RESET}
  ${GREEN}╰──┬──╯${RESET}
   ${PINK}╔╧╗${RESET}
   ${PINK}║█║${RESET}
"
}

# ═══════════════════════════════════════════════════════════════
# SCENES
# ═══════════════════════════════════════════════════════════════
scene_spawn() {
    clear
    echo -e "
${PINK}╔═══════════════════════════════════════════════════════════════════════════════╗${RESET}
${PINK}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ SPAWN POINT ▓▓▓▓${RESET}                                                    ${PINK}║${RESET}
${PINK}╚═══════════════════════════════════════════════════════════════════════════════╝${RESET}
"
    render_minimap
    show_player "Ready to explore!"
    echo -e "${WHITE}Move:${RESET} ${GREEN}w${RESET}(up) ${GREEN}a${RESET}(left) ${GREEN}s${RESET}(down) ${GREEN}d${RESET}(right) | ${AMBER}look${RESET} | ${VIOLET}talk${RESET} | ${PINK}q${RESET}(quit)"
}

scene_forest() {
    clear
    echo -e "
${GREEN}╔═══════════════════════════════════════════════════════════════════════════════╗${RESET}
${GREEN}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ THE FOREST ▓▓▓▓${RESET}                                                     ${GREEN}║${RESET}
${GREEN}╚═══════════════════════════════════════════════════════════════════════════════╝${RESET}

${GREEN}  ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲   ▲▲▲${RESET}
${GREEN} ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲ ▲▲▲▲▲${RESET}
${AMBER}   ║     ║     ║     ║     ║     ║     ║     ║     ║     ║     ║${RESET}

${DIM}The trees whisper ancient code...${RESET}
"
    NPC_LUCIDIA
    render_minimap
}

scene_home() {
    clear
    echo -e "
${AMBER}╔═══════════════════════════════════════════════════════════════════════════════╗${RESET}
${AMBER}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ HOME ▓▓▓▓${RESET}                                                           ${AMBER}║${RESET}
${AMBER}╚═══════════════════════════════════════════════════════════════════════════════╝${RESET}

                         ${AMBER}▲▲▲▲▲▲▲▲▲▲▲▲▲${RESET}
                        ${AMBER}╱             ╲${RESET}
                       ${AMBER}╱               ╲${RESET}
                 ${GRAY}┌────────────────────────────┐${RESET}
                 ${GRAY}│${RESET}   ${PINK}▣${RESET}    ${WHITE}BLACKROAD${RESET}    ${PINK}▣${RESET}   ${GRAY}│${RESET}
                 ${GRAY}│${RESET}         ${WHITE}OS${RESET}  ${GREEN}●${RESET}         ${GRAY}│${RESET}
                 ${GRAY}└──────────┬───┬───────────┘${RESET}
                            ${GRAY}│${AMBER}▣${GRAY}│${RESET}

${DIM}Home sweet home. All systems online.${RESET}
"
    render_minimap
}

scene_server() {
    clear
    echo -e "
${BLUE}╔═══════════════════════════════════════════════════════════════════════════════╗${RESET}
${BLUE}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ SERVER ROOM ▓▓▓▓${RESET}                                                    ${BLUE}║${RESET}
${BLUE}╚═══════════════════════════════════════════════════════════════════════════════╝${RESET}

${BLUE}  ╔═══╗ ╔═══╗ ╔═══╗ ╔═══╗ ╔═══╗ ╔═══╗ ╔═══╗ ╔═══╗${RESET}
${BLUE}  ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${AMBER}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║${RESET}
${BLUE}  ╠═══╣ ╠═══╣ ╠═══╣ ╠═══╣ ╠═══╣ ╠═══╣ ╠═══╣ ╠═══╣${RESET}
${BLUE}  ║${GREEN}●●●${BLUE}║ ║${AMBER}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${AMBER}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║ ║${GREEN}●●●${BLUE}║${RESET}
${BLUE}  ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝ ╚═══╝${RESET}

${DIM}8 devices humming. 52 TOPS of compute power.${RESET}
"
    NPC_CECILIA
    render_minimap
}

# ═══════════════════════════════════════════════════════════════
# GAME LOOP
# ═══════════════════════════════════════════════════════════════
update_scene() {
    # Determine scene based on position
    if [[ $PLAYER_X -le 1 && $PLAYER_Y -le 2 ]]; then
        LOCATION="forest"
        scene_forest
    elif [[ $PLAYER_X -eq 5 && $PLAYER_Y -le 3 ]]; then
        LOCATION="home"
        scene_home
    elif [[ $PLAYER_X -ge 7 && $PLAYER_Y -le 2 ]]; then
        LOCATION="server"
        scene_server
    else
        LOCATION="spawn"
        scene_spawn
    fi
}

move_player() {
    local dir="$1"
    case "$dir" in
        w|W|up)    [[ $PLAYER_Y -gt 0 ]] && ((PLAYER_Y--)) ;;
        s|S|down)  [[ $PLAYER_Y -lt 4 ]] && ((PLAYER_Y++)) ;;
        a|A|left)  [[ $PLAYER_X -gt 0 ]] && ((PLAYER_X--)) ;;
        d|D|right) [[ $PLAYER_X -lt 10 ]] && ((PLAYER_X++)) ;;
    esac
    update_scene
}

game_loop() {
    update_scene

    while true; do
        echo -n -e "\n${PINK}>${RESET} "
        read -r cmd

        case "${cmd,,}" in
            w|a|s|d|up|down|left|right)
                move_player "$cmd"
                ;;
            look)
                echo -e "${DIM}You look around at ${WHITE}$LOCATION${DIM}...${RESET}"
                ;;
            talk)
                case "$LOCATION" in
                    forest) NPC_LUCIDIA ;;
                    server) NPC_CECILIA ;;
                    home) echo -e "${DIM}There's no one here but the hum of computers...${RESET}" ;;
                    *) echo -e "${DIM}No one to talk to here.${RESET}" ;;
                esac
                ;;
            stats)
                echo -e "${WHITE}Location:${RESET} $LOCATION | ${WHITE}Position:${RESET} ($PLAYER_X, $PLAYER_Y)"
                ;;
            help)
                echo -e "${WHITE}Commands:${RESET} w/a/s/d (move) | look | talk | stats | quit"
                ;;
            q|quit|exit)
                echo -e "${PINK}Goodbye, traveler! ▣_▣${RESET}"
                exit 0
                ;;
            "")
                update_scene
                ;;
            *)
                echo -e "${GRAY}Unknown command. Try 'help'${RESET}"
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
main() {
    clear
    echo -e "
${PINK}   ██████╗ ██╗██╗  ██╗███████╗██╗         ${VIOLET}██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗${RESET}
${PINK}   ██╔══██╗██║╚██╗██╔╝██╔════╝██║         ${VIOLET}██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗${RESET}
${PINK}   ██████╔╝██║ ╚███╔╝ █████╗  ██║         ${VIOLET}██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║${RESET}
${PINK}   ██╔═══╝ ██║ ██╔██╗ ██╔══╝  ██║         ${VIOLET}██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║${RESET}
${PINK}   ██║     ██║██╔╝ ██╗███████╗███████╗    ${VIOLET}╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝${RESET}
${PINK}   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ${VIOLET} ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝${RESET}

${DIM}                        Walk around the BlackRoad terminal metaverse${RESET}
${DIM}                              Use WASD to move, 'q' to quit${RESET}

${WHITE}Press ENTER to begin your journey...${RESET}
"
    read -r
    game_loop
}

main "$@"
