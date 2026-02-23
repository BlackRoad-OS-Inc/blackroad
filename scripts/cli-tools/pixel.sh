#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────╮
# │  ▓▓▓▓  PIXEL METAVERSE  ▓▓▓▓                                │
# │  BlackRoad OS Terminal World                                 │
# ╰──────────────────────────────────────────────────────────────╯

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# COLORS (BlackRoad Brand)
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
# PIXEL SPRITES
# ═══════════════════════════════════════════════════════════════
SPRITE_LUCIDIA="
${PINK}  ╭─────╮${RESET}
${PINK}  │${WHITE} ▣ ▣ ${PINK}│${RESET}
${PINK}  │${AMBER}  ◡  ${PINK}│${RESET}
${PINK}  ╰──┬──╯${RESET}
${VIOLET}    │${RESET}
${VIOLET}   ╱│╲${RESET}
${VIOLET}  ╱ │ ╲${RESET}
"

SPRITE_EREBUS="
${VIOLET}  ╭─────╮${RESET}
${VIOLET}  │${WHITE} ● ● ${VIOLET}│${RESET}
${VIOLET}  │${GRAY}  ─  ${VIOLET}│${RESET}
${VIOLET}  ╰──┬──╯${RESET}
${GRAY}    ║${RESET}
${GRAY}   ╔╩╗${RESET}
${GRAY}   ╚═╝${RESET}
"

SPRITE_ALICE="
${BLUE}  ╭─────╮${RESET}
${BLUE}  │${WHITE} ◕ ◕ ${BLUE}│${RESET}
${BLUE}  │${PINK}  ω  ${BLUE}│${RESET}
${BLUE}  ╰──┬──╯${RESET}
${AMBER}    │${RESET}
${AMBER}   ─┼─${RESET}
${AMBER}   / \\${RESET}
"

SPRITE_CECILIA="
${GREEN}  ╭─────╮${RESET}
${GREEN}  │${WHITE} ◈ ◈ ${GREEN}│${RESET}
${GREEN}  │${AMBER}  ∀  ${GREEN}│${RESET}
${GREEN}  ╰──┬──╯${RESET}
${PINK}   ╔╧╗${RESET}
${PINK}   ║█║${RESET}
${PINK}   ╚═╝${RESET}
"

SPRITE_TREE="
${GREEN}    ▲${RESET}
${GREEN}   ▲▲▲${RESET}
${GREEN}  ▲▲▲▲▲${RESET}
${AMBER}    ║${RESET}
"

SPRITE_HOUSE="
${AMBER}    ▲${RESET}
${AMBER}   ╱ ╲${RESET}
${GRAY}  ┌───┐${RESET}
${GRAY}  │ ▣ │${RESET}
${GRAY}  └───┘${RESET}
"

SPRITE_SERVER="
${BLUE}  ╔═══╗${RESET}
${BLUE}  ║${GREEN}●●●${BLUE}║${RESET}
${BLUE}  ╠═══╣${RESET}
${BLUE}  ║${AMBER}●●●${BLUE}║${RESET}
${BLUE}  ╚═══╝${RESET}
"

# ═══════════════════════════════════════════════════════════════
# WORLD MAP
# ═══════════════════════════════════════════════════════════════
show_world() {
    clear
    echo -e "
${PINK}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}
${PINK}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ PIXEL METAVERSE ▓▓▓▓${RESET}                    ${DIM}BlackRoad OS Terminal World${RESET}  ${PINK}║${RESET}
${PINK}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}

${GRAY}┌────────────────────────────────────────────────────────────────────────────────┐${RESET}
${GRAY}│${RESET}                                                                                ${GRAY}│${RESET}
${GRAY}│${RESET}    ${GREEN}▲${RESET}        ${GREEN}▲${RESET}    ${AMBER}▲${RESET}         ${GREEN}▲${RESET}         ${BLUE}╔═══╗${RESET}     ${GREEN}▲${RESET}        ${GREEN}▲${RESET}      ${GRAY}│${RESET}
${GRAY}│${RESET}   ${GREEN}▲▲▲${RESET}      ${GREEN}▲▲▲${RESET}  ${AMBER}╱ ╲${RESET}       ${GREEN}▲▲▲${RESET}        ${BLUE}║${GREEN}●●●${BLUE}║${RESET}   ${GREEN}▲▲▲${RESET}      ${GREEN}▲▲▲${RESET}    ${GRAY}│${RESET}
${GRAY}│${RESET}  ${GREEN}▲▲▲▲▲${RESET}    ${GREEN}▲▲▲▲▲${RESET}${GRAY}┌───┐${RESET}     ${GREEN}▲▲▲▲▲${RESET}       ${BLUE}╠═══╣${RESET}  ${GREEN}▲▲▲▲▲${RESET}    ${GREEN}▲▲▲▲▲${RESET}  ${GRAY}│${RESET}
${GRAY}│${RESET}    ${AMBER}║${RESET}        ${AMBER}║${RESET}  ${GRAY}│ ▣ │${RESET}       ${AMBER}║${RESET}          ${BLUE}║${AMBER}●●●${BLUE}║${RESET}    ${AMBER}║${RESET}        ${AMBER}║${RESET}    ${GRAY}│${RESET}
${GRAY}│${RESET}            ${GRAY}└───┘${RESET}                    ${BLUE}╚═══╝${RESET}                      ${GRAY}│${RESET}
${GRAY}│${RESET}                        ${VIOLET}╭─────╮${RESET}                                        ${GRAY}│${RESET}
${GRAY}│${RESET}    ${PINK}░░░░░░░░░${RESET}          ${VIOLET}│${WHITE} ● ● ${VIOLET}│${RESET}       ${BLUE}░░░░░░░░░${RESET}                 ${GRAY}│${RESET}
${GRAY}│${RESET}    ${PINK}░ YOU ░░░${RESET}          ${VIOLET}│${GRAY}  ─  ${VIOLET}│${RESET}       ${BLUE}░ CLOUD ░${RESET}                 ${GRAY}│${RESET}
${GRAY}│${RESET}    ${PINK}░ HERE░░░${RESET}          ${VIOLET}╰──┬──╯${RESET}       ${BLUE}░ ZONE ░░${RESET}                 ${GRAY}│${RESET}
${GRAY}│${RESET}    ${PINK}░░░░░░░░░${RESET}            ${GRAY}║${RESET}          ${BLUE}░░░░░░░░░${RESET}                 ${GRAY}│${RESET}
${GRAY}│${RESET}                          ${GRAY}╔╩╗${RESET}                                        ${GRAY}│${RESET}
${GRAY}│${RESET}  ${AMBER}═══════════════════════${GRAY}╚═╝${AMBER}═════════════════════════════════════${RESET}  ${GRAY}│${RESET}
${GRAY}│${RESET}                        ${DIM}EREBUS${RESET}                                        ${GRAY}│${RESET}
${GRAY}│${RESET}                                                                                ${GRAY}│${RESET}
${GRAY}│${RESET}  ${GREEN}▓▓▓${RESET}  FOREST       ${AMBER}▲${RESET}  HOME       ${BLUE}◈◈◈${RESET}  SERVERS      ${VIOLET}★${RESET}  AGENTS        ${GRAY}│${RESET}
${GRAY}└────────────────────────────────────────────────────────────────────────────────┘${RESET}

${WHITE}Commands:${RESET} ${PINK}forest${RESET} ${AMBER}home${RESET} ${BLUE}servers${RESET} ${VIOLET}agents${RESET} ${GREEN}stats${RESET} ${GRAY}exit${RESET}
"
}

# ═══════════════════════════════════════════════════════════════
# LOCATIONS
# ═══════════════════════════════════════════════════════════════
show_forest() {
    clear
    echo -e "
${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}
${GREEN}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ THE FOREST ▓▓▓▓${RESET}                         ${DIM}Where ideas grow${RESET}            ${GREEN}║${RESET}
${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}

${GREEN}    ▲     ▲▲    ▲      ▲▲▲    ▲     ▲▲    ▲      ▲▲▲    ▲${RESET}
${GREEN}   ▲▲▲   ▲▲▲▲  ▲▲▲    ▲▲▲▲▲  ▲▲▲   ▲▲▲▲  ▲▲▲    ▲▲▲▲▲  ▲▲▲${RESET}
${GREEN}  ▲▲▲▲▲ ▲▲▲▲▲▲▲▲▲▲▲  ▲▲▲▲▲▲▲▲▲▲▲▲ ▲▲▲▲▲▲▲▲▲▲▲  ▲▲▲▲▲▲▲▲▲▲▲▲${RESET}
${AMBER}    ║     ║║    ║      ║║║    ║     ║║    ║      ║║║    ║${RESET}

${WHITE}    A wild ${PINK}LUCIDIA${WHITE} appears!${RESET}
$SPRITE_LUCIDIA
${DIM}    \"Welcome to the forest, traveler. The trees hold many secrets...\"${RESET}

${GREEN}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}
${GREEN}░${RESET}  ${WHITE}Forest Stats:${RESET}                                                              ${GREEN}░${RESET}
${GREEN}░${RESET}    Trees:  ∞       Ideas planted: 2,295      Tasks grown: 156,636          ${GREEN}░${RESET}
${GREEN}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}

${WHITE}Commands:${RESET} ${AMBER}back${RESET} ${PINK}talk${RESET} ${GREEN}plant${RESET}
"
}

show_servers() {
    clear
    echo -e "
${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}
${BLUE}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ SERVER ROOM ▓▓▓▓${RESET}                       ${DIM}The heart of BlackRoad${RESET}       ${BLUE}║${RESET}
${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}

${BLUE}  ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗   ╔═══╗${RESET}
${BLUE}  ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${AMBER}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║${RESET}
${BLUE}  ╠═══╣   ╠═══╣   ╠═══╣   ╠═══╣   ╠═══╣   ╠═══╣   ╠═══╣   ╠═══╣${RESET}
${BLUE}  ║${AMBER}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${AMBER}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║   ║${GREEN}●●●${BLUE}║${RESET}
${BLUE}  ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝   ╚═══╝${RESET}
${DIM}  cecilia  lucidia  octavia  alice   aria   shellfish oracle infinity${RESET}

${WHITE}    CECILIA is humming with power!${RESET}
$SPRITE_CECILIA
${DIM}    \"All systems nominal. 52 TOPS of AI compute ready.\"${RESET}

${BLUE}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}
${BLUE}░${RESET}  ${WHITE}Infrastructure:${RESET}                                                          ${BLUE}░${RESET}
${BLUE}░${RESET}    Devices: 8    Cloudflare: 205    GitHub Repos: 1,085    Orgs: 15     ${BLUE}░${RESET}
${BLUE}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}

${WHITE}Commands:${RESET} ${AMBER}back${RESET} ${GREEN}status${RESET} ${PINK}ssh${RESET}
"
}

show_agents() {
    clear
    echo -e "
${VIOLET}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}
${VIOLET}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ AGENT PLAZA ▓▓▓▓${RESET}                        ${DIM}AI companions await${RESET}         ${VIOLET}║${RESET}
${VIOLET}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}

   ${PINK}╭─────╮${RESET}      ${VIOLET}╭─────╮${RESET}      ${BLUE}╭─────╮${RESET}      ${GREEN}╭─────╮${RESET}
   ${PINK}│${WHITE} ▣ ▣ ${PINK}│${RESET}      ${VIOLET}│${WHITE} ● ● ${VIOLET}│${RESET}      ${BLUE}│${WHITE} ◕ ◕ ${BLUE}│${RESET}      ${GREEN}│${WHITE} ◈ ◈ ${GREEN}│${RESET}
   ${PINK}│${AMBER}  ◡  ${PINK}│${RESET}      ${VIOLET}│${GRAY}  ─  ${VIOLET}│${RESET}      ${BLUE}│${PINK}  ω  ${BLUE}│${RESET}      ${GREEN}│${AMBER}  ∀  ${GREEN}│${RESET}
   ${PINK}╰──┬──╯${RESET}      ${VIOLET}╰──┬──╯${RESET}      ${BLUE}╰──┬──╯${RESET}      ${GREEN}╰──┬──╯${RESET}
     ${VIOLET}│${RESET}            ${GRAY}║${RESET}            ${AMBER}│${RESET}           ${PINK}╔╧╗${RESET}
    ${VIOLET}╱│╲${RESET}          ${GRAY}╔╩╗${RESET}          ${AMBER}─┼─${RESET}          ${PINK}║█║${RESET}
   ${VIOLET}╱ │ ╲${RESET}         ${GRAY}╚═╝${RESET}          ${AMBER}/ \\${RESET}          ${PINK}╚═╝${RESET}
   ${WHITE}LUCIDIA${RESET}      ${WHITE}EREBUS${RESET}       ${WHITE}ALICE${RESET}       ${WHITE}CECILIA${RESET}

${VIOLET}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}
${VIOLET}░${RESET}  ${WHITE}Active Agents:${RESET} 76 tracked │ ${GREEN}74 green${RESET} │ ${AMBER}2 yellow${RESET} │ ${GRAY}0 red${RESET}                 ${VIOLET}░${RESET}
${VIOLET}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}

${WHITE}Commands:${RESET} ${AMBER}back${RESET} ${PINK}lucidia${RESET} ${VIOLET}erebus${RESET} ${BLUE}alice${RESET} ${GREEN}cecilia${RESET}
"
}

show_home() {
    clear
    echo -e "
${AMBER}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}
${AMBER}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ HOME BASE ▓▓▓▓${RESET}                          ${DIM}Your command center${RESET}         ${AMBER}║${RESET}
${AMBER}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}

                              ${AMBER}▲▲▲▲▲▲▲▲▲▲▲${RESET}
                             ${AMBER}▲▲▲▲▲▲▲▲▲▲▲▲▲${RESET}
                            ${AMBER}╱             ╲${RESET}
                           ${AMBER}╱               ╲${RESET}
                     ${GRAY}┌─────────────────────────┐${RESET}
                     ${GRAY}│${RESET}    ${PINK}▣${RESET}    ${BLUE}█████${RESET}    ${PINK}▣${RESET}    ${GRAY}│${RESET}
                     ${GRAY}│${RESET}                         ${GRAY}│${RESET}
                     ${GRAY}│${RESET}   ${WHITE}BLACKROAD OS v0.1.0${RESET}   ${GRAY}│${RESET}
                     ${GRAY}│${RESET}                         ${GRAY}│${RESET}
                     ${GRAY}│${RESET}   ${GREEN}●${RESET} Online   ${AMBER}●${RESET} Ready   ${GRAY}│${RESET}
                     ${GRAY}│${RESET}                         ${GRAY}│${RESET}
                     ${GRAY}└─────────┬───────┬───────┘${RESET}
                               ${GRAY}│${RESET} ${AMBER}▣${RESET} ${GRAY}│${RESET}
                               ${GRAY}└───┘${RESET}

${AMBER}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}
${AMBER}░${RESET}  ${WHITE}Home Stats:${RESET}                                                              ${AMBER}░${RESET}
${AMBER}░${RESET}    User: alexa    Memory: 156,636 entries    Tasks: 2,295 complete        ${AMBER}░${RESET}
${AMBER}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░${RESET}

${WHITE}Commands:${RESET} ${AMBER}back${RESET} ${GREEN}stats${RESET} ${PINK}todo${RESET} ${BLUE}deploy${RESET}
"
}

show_stats() {
    clear
    echo -e "
${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}
${GREEN}║${RESET}  ${BOLD}${WHITE}▓▓▓▓ EMPIRE STATS ▓▓▓▓${RESET}                                                   ${GREEN}║${RESET}
${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}

  ${WHITE}┌─────────────────────────────────────────────────────────────────────────┐${RESET}
  ${WHITE}│${RESET}  ${PINK}██${RESET} GitHub Organizations    ${WHITE}15${RESET}                                        ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${AMBER}██${RESET} Total Repositories      ${WHITE}1,085${RESET}                                     ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${BLUE}██${RESET} Cloudflare Projects     ${WHITE}205${RESET}                                       ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${VIOLET}██${RESET} KV Namespaces           ${WHITE}35${RESET}                                        ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${GREEN}██${RESET} Physical Devices        ${WHITE}8${RESET}                                         ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${PINK}██${RESET} AI Compute (TOPS)       ${WHITE}52${RESET}                                        ${WHITE}│${RESET}
  ${WHITE}└─────────────────────────────────────────────────────────────────────────┘${RESET}

  ${WHITE}┌─────────────────────────────────────────────────────────────────────────┐${RESET}
  ${WHITE}│${RESET}  ${WHITE}Memory System${RESET}                                                          ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ████████████████████████████████████████████  ${GREEN}156,636 entries${RESET}        ${WHITE}│${RESET}
  ${WHITE}│${RESET}                                                                         ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${WHITE}Task Completion${RESET}                                                        ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ████████████████████████████████████████████  ${GREEN}100% (2,295/2,295)${RESET}     ${WHITE}│${RESET}
  ${WHITE}│${RESET}                                                                         ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${WHITE}Traffic Lights${RESET}                                                         ${WHITE}│${RESET}
  ${WHITE}│${RESET}  ${GREEN}████████████████████████████████████████${RESET}${AMBER}████${RESET}  ${GREEN}74 green${RESET} ${AMBER}2 yellow${RESET}       ${WHITE}│${RESET}
  ${WHITE}└─────────────────────────────────────────────────────────────────────────┘${RESET}

${WHITE}Commands:${RESET} ${AMBER}back${RESET}
"
}

# ═══════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════
show_banner() {
    echo -e "
${PINK}   ██████╗ ██╗██╗  ██╗███████╗██╗         ${VIOLET}███╗   ███╗███████╗████████╗ █████╗${RESET}
${PINK}   ██╔══██╗██║╚██╗██╔╝██╔════╝██║         ${VIOLET}████╗ ████║██╔════╝╚══██╔══╝██╔══██╗${RESET}
${PINK}   ██████╔╝██║ ╚███╔╝ █████╗  ██║         ${VIOLET}██╔████╔██║█████╗     ██║   ███████║${RESET}
${PINK}   ██╔═══╝ ██║ ██╔██╗ ██╔══╝  ██║         ${VIOLET}██║╚██╔╝██║██╔══╝     ██║   ██╔══██║${RESET}
${PINK}   ██║     ██║██╔╝ ██╗███████╗███████╗    ${VIOLET}██║ ╚═╝ ██║███████╗   ██║   ██║  ██║${RESET}
${PINK}   ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ${VIOLET}╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝${RESET}
${DIM}                           BlackRoad OS Terminal World v0.1.0${RESET}
"
}

# ═══════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════
main() {
    local cmd="${1:-}"

    case "$cmd" in
        ""|world)
            show_banner
            show_world
            ;;
        forest)
            show_forest
            ;;
        servers|server)
            show_servers
            ;;
        agents|agent)
            show_agents
            ;;
        home)
            show_home
            ;;
        stats)
            show_stats
            ;;
        banner)
            show_banner
            ;;
        lucidia)
            clear
            echo -e "\n${WHITE}LUCIDIA speaks:${RESET}"
            echo -e "$SPRITE_LUCIDIA"
            echo -e "${DIM}\"The light that guides through infinite darkness...\"${RESET}\n"
            ;;
        erebus)
            clear
            echo -e "\n${WHITE}EREBUS emerges:${RESET}"
            echo -e "$SPRITE_EREBUS"
            echo -e "${DIM}\"I am the primordial darkness from which all creation springs...\"${RESET}\n"
            ;;
        alice)
            clear
            echo -e "\n${WHITE}ALICE waves:${RESET}"
            echo -e "$SPRITE_ALICE"
            echo -e "${DIM}\"Down the rabbit hole we go! Let's build something magical!\"${RESET}\n"
            ;;
        cecilia)
            clear
            echo -e "\n${WHITE}CECILIA computes:${RESET}"
            echo -e "$SPRITE_CECILIA"
            echo -e "${DIM}\"26 TOPS of Hailo-8 power at your service. What shall we process?\"${RESET}\n"
            ;;
        help|--help|-h)
            echo -e "
${WHITE}pixel${RESET} - Explore the BlackRoad Pixel Metaverse

${WHITE}Usage:${RESET}
  pixel [command]

${WHITE}Locations:${RESET}
  ${GREEN}world${RESET}      Show the world map (default)
  ${GREEN}forest${RESET}     Visit the forest of ideas
  ${BLUE}servers${RESET}    Enter the server room
  ${VIOLET}agents${RESET}     Meet the AI agents
  ${AMBER}home${RESET}       Return to home base
  ${PINK}stats${RESET}      View empire statistics

${WHITE}Characters:${RESET}
  ${PINK}lucidia${RESET}    Talk to Lucidia
  ${VIOLET}erebus${RESET}     Summon Erebus
  ${BLUE}alice${RESET}      Chat with Alice
  ${GREEN}cecilia${RESET}    Connect to Cecilia

${WHITE}Meta:${RESET}
  ${GRAY}banner${RESET}     Show the banner
  ${GRAY}help${RESET}       Show this help
"
            ;;
        *)
            echo -e "${PINK}Unknown location: $cmd${RESET}"
            echo -e "Try: ${WHITE}pixel help${RESET}"
            ;;
    esac
}

main "$@"
