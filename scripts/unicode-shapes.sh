#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
#
# BLACKROAD UNICODE SHAPES LIBRARY
# Official collection of Unicode art for terminal UI
#
# Rule: BLOCKS/SHAPES = COLOR, TEXT = WHITE (always)
# ============================================================================

# OFFICIAL BLACKROAD COLORS (ANSI 256)
BR_AMBER='\033[38;5;208m'    # #FF8700
BR_ORANGE='\033[38;5;202m'   # #FF5F00
BR_PINK='\033[38;5;198m'     # #FF0087
BR_MAGENTA='\033[38;5;163m'  # #D700AF
BR_BLUE='\033[38;5;33m'      # #0087FF
BR_WHITE='\033[1;37m'        # Always for text
BR_RESET='\033[0m'

# ============================================================================
# GRADIENT PATTERNS
# ============================================================================

br_gradient_bar() {
    echo -e "${BR_AMBER}████${BR_ORANGE}████${BR_PINK}████${BR_MAGENTA}████${BR_BLUE}████${BR_MAGENTA}████${BR_PINK}████${BR_ORANGE}████${BR_AMBER}████${BR_RESET}"
}

br_gradient_line() {
    echo -e "${BR_AMBER}━━━━${BR_ORANGE}━━━━${BR_PINK}━━━━${BR_MAGENTA}━━━━${BR_BLUE}━━━━${BR_RESET}"
}

br_gradient_dots() {
    echo -e "${BR_AMBER}●●${BR_ORANGE}●●${BR_PINK}●●${BR_MAGENTA}●●${BR_BLUE}●●${BR_RESET}"
}

br_gradient_wave() {
    echo -e "${BR_AMBER}∿∿∿${BR_ORANGE}∿∿∿${BR_PINK}∿∿∿${BR_MAGENTA}∿∿∿${BR_BLUE}∿∿∿${BR_RESET}"
}

br_gradient_blocks() {
    echo -e "${BR_AMBER}▓▓▓▓${BR_ORANGE}▓▓▓▓${BR_PINK}▓▓▓▓${BR_MAGENTA}▓▓▓▓${BR_BLUE}▓▓▓▓${BR_RESET}"
}

br_gradient_fade() {
    echo -e "${BR_AMBER}░▒▓█${BR_ORANGE}░▒▓█${BR_PINK}░▒▓█${BR_MAGENTA}░▒▓█${BR_BLUE}░▒▓█${BR_RESET}"
}

br_gradient_triangles() {
    echo -e "${BR_AMBER}◢◣${BR_ORANGE}◢◣${BR_PINK}◢◣${BR_MAGENTA}◢◣${BR_BLUE}◢◣${BR_MAGENTA}◢◣${BR_PINK}◢◣${BR_ORANGE}◢◣${BR_AMBER}◢◣${BR_RESET}"
}

# ============================================================================
# LOADING / PROGRESS INDICATORS
# ============================================================================

br_progress_bar() {
    local percent=$1
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    local bar=""

    for ((i=0; i<filled; i++)); do bar+="█"; done
    echo -ne "${BR_PINK}${bar}${BR_RESET}"
    for ((i=0; i<empty; i++)); do echo -n "░"; done
    echo -e " ${BR_WHITE}${percent}%${BR_RESET}"
}

br_spinner_chars() {
    echo -e "${BR_WHITE}Spinner chars:${BR_RESET} ${BR_AMBER}◐${BR_ORANGE}◓${BR_PINK}◑${BR_MAGENTA}◒${BR_RESET}"
}

br_loading_dots() {
    echo -e "${BR_AMBER}◦${BR_ORANGE}◦${BR_PINK}●${BR_MAGENTA}◦${BR_BLUE}◦${BR_RESET}"
}

# ============================================================================
# STATUS INDICATORS
# ============================================================================

br_status_online() {
    echo -e "${BR_PINK}●${BR_RESET} ${BR_WHITE}ONLINE${BR_RESET}"
}

br_status_offline() {
    echo -e "○ ${BR_WHITE}OFFLINE${BR_RESET}"
}

br_status_warning() {
    echo -e "${BR_AMBER}◆${BR_RESET} ${BR_WHITE}WARNING${BR_RESET}"
}

br_status_success() {
    echo -e "${BR_PINK}✓${BR_RESET} ${BR_WHITE}SUCCESS${BR_RESET}"
}

br_status_error() {
    echo -e "${BR_ORANGE}✗${BR_RESET} ${BR_WHITE}ERROR${BR_RESET}"
}

# ============================================================================
# DECORATIVE ELEMENTS
# ============================================================================

br_divider_solid() {
    echo -e "${BR_PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${BR_RESET}"
}

br_divider_double() {
    echo -e "${BR_AMBER}═══════════════════════════════════════════════════════════${BR_RESET}"
}

br_divider_stars() {
    echo -e "${BR_AMBER}✦${BR_ORANGE}✦${BR_PINK}✦${BR_MAGENTA}✦${BR_BLUE}✦${BR_MAGENTA}✦${BR_PINK}✦${BR_ORANGE}✦${BR_AMBER}✦${BR_ORANGE}✦${BR_PINK}✦${BR_MAGENTA}✦${BR_BLUE}✦${BR_MAGENTA}✦${BR_PINK}✦${BR_ORANGE}✦${BR_AMBER}✦${BR_RESET}"
}

br_sparkles() {
    echo -e "${BR_AMBER}✨${BR_PINK}✨${BR_BLUE}✨${BR_RESET}"
}

# ============================================================================
# SHAPES & ICONS
# ============================================================================

br_diamond() {
    echo -e "    ${BR_PINK}◆${BR_RESET}"
    echo -e "   ${BR_PINK}◆ ◆${BR_RESET}"
    echo -e "  ${BR_MAGENTA}◆   ◆${BR_RESET}"
    echo -e "   ${BR_BLUE}◆ ◆${BR_RESET}"
    echo -e "    ${BR_BLUE}◆${BR_RESET}"
}

br_pyramid() {
    echo -e "      ${BR_AMBER}▲${BR_RESET}"
    echo -e "     ${BR_AMBER}▲ ▲${BR_RESET}"
    echo -e "    ${BR_ORANGE}▲ ▲ ▲${BR_RESET}"
    echo -e "   ${BR_PINK}▲ ▲ ▲ ▲${BR_RESET}"
    echo -e "  ${BR_MAGENTA}▲ ▲ ▲ ▲ ▲${BR_RESET}"
}

br_heart() {
    echo -e "  ${BR_PINK}▄▄${BR_RESET}   ${BR_PINK}▄▄${BR_RESET}"
    echo -e "${BR_PINK}▄████▄████▄${BR_RESET}"
    echo -e "${BR_PINK}██████████${BR_RESET}"
    echo -e " ${BR_MAGENTA}████████${BR_RESET}"
    echo -e "  ${BR_MAGENTA}██████${BR_RESET}"
    echo -e "   ${BR_BLUE}████${BR_RESET}"
    echo -e "    ${BR_BLUE}██${BR_RESET}"
}

br_flame() {
    echo -e "      ${BR_AMBER}▲${BR_RESET}"
    echo -e "     ${BR_AMBER}▲▲▲${BR_RESET}"
    echo -e "    ${BR_ORANGE}▲${BR_AMBER}▲▲▲${BR_ORANGE}▲${BR_RESET}"
    echo -e "   ${BR_ORANGE}▲▲${BR_AMBER}▲▲▲${BR_ORANGE}▲▲${BR_RESET}"
    echo -e "  ${BR_PINK}▲${BR_ORANGE}▲▲${BR_AMBER}▲▲▲${BR_ORANGE}▲▲${BR_PINK}▲${BR_RESET}"
    echo -e " ${BR_PINK}▲▲${BR_ORANGE}▲▲${BR_AMBER}███${BR_ORANGE}▲▲${BR_PINK}▲▲${BR_RESET}"
}

br_crown() {
    echo -e "      ${BR_AMBER}◆${BR_RESET}     ${BR_PINK}◆${BR_RESET}     ${BR_BLUE}◆${BR_RESET}"
    echo -e "     ${BR_AMBER}╱ ╲${BR_RESET}   ${BR_PINK}╱ ╲${BR_RESET}   ${BR_BLUE}╱ ╲${BR_RESET}"
    echo -e "    ${BR_AMBER}╱${BR_RESET}   ${BR_AMBER}╲${BR_PINK}╱${BR_RESET}   ${BR_PINK}╲${BR_BLUE}╱${BR_RESET}   ${BR_BLUE}╲${BR_RESET}"
    echo -e "   ${BR_ORANGE}━━━━━━━━━━━━━━━━━━━━━${BR_RESET}"
    echo -e "   ${BR_ORANGE}┃${BR_RESET} ${BR_AMBER}◇${BR_RESET} ${BR_ORANGE}◇${BR_RESET} ${BR_PINK}◇${BR_RESET} ${BR_MAGENTA}◇${BR_RESET} ${BR_BLUE}◇${BR_RESET} ${BR_MAGENTA}◇${BR_RESET} ${BR_PINK}◇${BR_RESET} ${BR_ORANGE}◇${BR_RESET} ${BR_AMBER}◇${BR_RESET} ${BR_ORANGE}┃${BR_RESET}"
    echo -e "   ${BR_ORANGE}━━━━━━━━━━━━━━━━━━━━━${BR_RESET}"
}

br_starburst() {
    echo -e "       ${BR_AMBER}✦${BR_RESET}"
    echo -e "    ${BR_ORANGE}✦${BR_RESET}  ${BR_AMBER}│${BR_RESET}  ${BR_ORANGE}✦${BR_RESET}"
    echo -e " ${BR_PINK}✦${BR_RESET}   ${BR_ORANGE}╲${BR_RESET} ${BR_AMBER}│${BR_RESET} ${BR_ORANGE}╱${BR_RESET}   ${BR_PINK}✦${BR_RESET}"
    echo -e "${BR_MAGENTA}✦${BR_RESET}──────${BR_BLUE}◉${BR_RESET}──────${BR_MAGENTA}✦${BR_RESET}"
    echo -e " ${BR_PINK}✦${BR_RESET}   ${BR_ORANGE}╱${BR_RESET} ${BR_AMBER}│${BR_RESET} ${BR_ORANGE}╲${BR_RESET}   ${BR_PINK}✦${BR_RESET}"
    echo -e "    ${BR_ORANGE}✦${BR_RESET}  ${BR_AMBER}│${BR_RESET}  ${BR_ORANGE}✦${BR_RESET}"
    echo -e "       ${BR_AMBER}✦${BR_RESET}"
}

br_mandala() {
    echo -e "         ${BR_AMBER}◆${BR_RESET}"
    echo -e "      ${BR_ORANGE}◆${BR_RESET}  ${BR_AMBER}│${BR_RESET}  ${BR_ORANGE}◆${BR_RESET}"
    echo -e "   ${BR_PINK}◆${BR_RESET}   ${BR_ORANGE}◇${BR_RESET} ${BR_AMBER}│${BR_RESET} ${BR_ORANGE}◇${BR_RESET}   ${BR_PINK}◆${BR_RESET}"
    echo -e "${BR_MAGENTA}◆${BR_RESET}──${BR_PINK}◇${BR_RESET}──${BR_ORANGE}◇${BR_RESET}─${BR_BLUE}◉${BR_RESET}─${BR_ORANGE}◇${BR_RESET}──${BR_PINK}◇${BR_RESET}──${BR_MAGENTA}◆${BR_RESET}"
    echo -e "   ${BR_PINK}◆${BR_RESET}   ${BR_ORANGE}◇${BR_RESET} ${BR_AMBER}│${BR_RESET} ${BR_ORANGE}◇${BR_RESET}   ${BR_PINK}◆${BR_RESET}"
    echo -e "      ${BR_ORANGE}◆${BR_RESET}  ${BR_AMBER}│${BR_RESET}  ${BR_ORANGE}◆${BR_RESET}"
    echo -e "         ${BR_AMBER}◆${BR_RESET}"
}

# ============================================================================
# TECHNICAL / CIRCUIT
# ============================================================================

br_chip_8pin() {
    echo -e "          ${BR_WHITE}┌───────────────┐${BR_RESET}"
    echo -e "${BR_AMBER}VCC${BR_RESET} ━━${BR_PINK}●${BR_RESET}━━│${BR_MAGENTA}█${BR_RESET}  ${BR_WHITE}1      8${BR_RESET}  ${BR_MAGENTA}█${BR_RESET}│━━${BR_PINK}●${BR_RESET}━━ ${BR_ORANGE}CLK${BR_RESET}"
    echo -e "${BR_AMBER}IN1${BR_RESET} ━━${BR_PINK}●${BR_RESET}━━│${BR_MAGENTA}█${BR_RESET}  ${BR_WHITE}2      7${BR_RESET}  ${BR_MAGENTA}█${BR_RESET}│━━${BR_PINK}●${BR_RESET}━━ ${BR_ORANGE}OUT${BR_RESET}"
    echo -e "${BR_AMBER}IN2${BR_RESET} ━━${BR_PINK}●${BR_RESET}━━│${BR_MAGENTA}█${BR_RESET}  ${BR_WHITE}3      6${BR_RESET}  ${BR_MAGENTA}█${BR_RESET}│━━${BR_PINK}●${BR_RESET}━━ ${BR_ORANGE}EN${BR_RESET}"
    echo -e "${BR_AMBER}GND${BR_RESET} ━━${BR_PINK}●${BR_RESET}━━│${BR_MAGENTA}█${BR_RESET}  ${BR_WHITE}4      5${BR_RESET}  ${BR_MAGENTA}█${BR_RESET}│━━${BR_PINK}●${BR_RESET}━━ ${BR_ORANGE}NC${BR_RESET}"
    echo -e "          ${BR_WHITE}└───────────────┘${BR_RESET}"
}

br_waveform_clock() {
    echo -e "${BR_WHITE}CLK:${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET} ${BR_AMBER}┌─┐${BR_RESET}"
    echo -e "     ${BR_AMBER}┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └${BR_RESET}"
}

br_waveform_sine() {
    echo -e "${BR_WHITE}SIN:${BR_RESET} ${BR_PINK}╭╮${BR_RESET}  ${BR_PINK}╭╮${BR_RESET}  ${BR_PINK}╭╮${BR_RESET}  ${BR_PINK}╭╮${BR_RESET}"
    echo -e "     ${BR_PINK}╯╰╮╭╯╰╮╭╯╰╮╭╯╰${BR_RESET}"
}

br_7segment() {
    local digit=$1
    case $digit in
        0) echo -e " ${BR_AMBER}━━━${BR_RESET}"; echo -e "${BR_AMBER}┃${BR_RESET}   ${BR_AMBER}┃${BR_RESET}"; echo -e "${BR_AMBER}┃${BR_RESET}   ${BR_AMBER}┃${BR_RESET}"; echo -e " ${BR_AMBER}━━━${BR_RESET}" ;;
        1) echo -e "    ${BR_PINK}┃${BR_RESET}"; echo -e "    ${BR_PINK}┃${BR_RESET}"; echo -e "    ${BR_PINK}┃${BR_RESET}"; echo -e "    ${BR_PINK}┃${BR_RESET}" ;;
        *) echo -e " ${BR_BLUE}━━━${BR_RESET}"; echo -e "    ${BR_BLUE}┃${BR_RESET}"; echo -e " ${BR_BLUE}━━━${BR_RESET}"; echo -e "${BR_BLUE}┃${BR_RESET}"; echo -e " ${BR_BLUE}━━━${BR_RESET}" ;;
    esac
}

# ============================================================================
# AUDIO / VISUALIZER
# ============================================================================

br_audio_spectrum() {
    echo -e "  ${BR_AMBER}    ▁${BR_RESET}"
    echo -e "  ${BR_AMBER}▃   █${BR_RESET}   ${BR_ORANGE}▅${BR_RESET}"
    echo -e "  ${BR_AMBER}█ ▂ █${BR_RESET} ${BR_ORANGE}▃ █${BR_RESET}   ${BR_PINK}▄${BR_RESET}"
    echo -e "  ${BR_AMBER}█ █ █${BR_RESET} ${BR_ORANGE}█ █${BR_RESET} ${BR_PINK}▂ █${BR_RESET}   ${BR_MAGENTA}▃${BR_RESET}"
    echo -e "  ${BR_AMBER}█ █ █${BR_RESET} ${BR_ORANGE}█ █${BR_RESET} ${BR_PINK}█ █${BR_RESET} ${BR_MAGENTA}▂ █${BR_RESET}   ${BR_BLUE}▂${BR_RESET}"
    echo -e "  ${BR_AMBER}█ █ █${BR_RESET} ${BR_ORANGE}█ █${BR_RESET} ${BR_PINK}█ █${BR_RESET} ${BR_MAGENTA}█ █${BR_RESET} ${BR_BLUE}▁ █${BR_RESET}"
}

br_music_visualizer() {
    echo -e "  ${BR_AMBER}▁${BR_ORANGE}▂${BR_PINK}▃${BR_MAGENTA}▅${BR_BLUE}▇${BR_MAGENTA}█${BR_PINK}▇${BR_ORANGE}▅${BR_AMBER}▃${BR_ORANGE}▂${BR_PINK}▁${BR_MAGENTA}▂${BR_BLUE}▃${BR_MAGENTA}▅${BR_PINK}▇${BR_ORANGE}█${BR_AMBER}▇${BR_ORANGE}▅${BR_PINK}▃${BR_MAGENTA}▂${BR_BLUE}▁${BR_RESET}"
    echo -e "  ${BR_BLUE}▂${BR_MAGENTA}▃${BR_PINK}▅${BR_ORANGE}▇${BR_AMBER}█${BR_ORANGE}▇${BR_PINK}▅${BR_MAGENTA}▃${BR_BLUE}▂${BR_MAGENTA}▃${BR_PINK}▅${BR_ORANGE}▇${BR_AMBER}█${BR_ORANGE}▇${BR_PINK}▅${BR_MAGENTA}▃${BR_BLUE}▂${BR_MAGENTA}▃${BR_PINK}▅${BR_ORANGE}▇${BR_AMBER}█${BR_RESET}"
}

# ============================================================================
# LOGOS & BRANDING
# ============================================================================

br_logo_blocks() {
    echo -e "  ${BR_AMBER}██████${BR_RESET}  ${BR_ORANGE}██████${BR_RESET}"
    echo -e "  ${BR_AMBER}██${BR_RESET}  ${BR_AMBER}██${BR_RESET}  ${BR_ORANGE}██${BR_RESET}  ${BR_ORANGE}██${BR_RESET}"
    echo -e "  ${BR_PINK}██████${BR_RESET}  ${BR_PINK}██████${BR_RESET}"
    echo -e "  ${BR_MAGENTA}██${BR_RESET}  ${BR_MAGENTA}██${BR_RESET}  ${BR_MAGENTA}██${BR_RESET}  ${BR_MAGENTA}██${BR_RESET}"
    echo -e "  ${BR_BLUE}██████${BR_RESET}  ${BR_BLUE}██${BR_RESET}  ${BR_BLUE}██${BR_RESET}"
}

br_logo_small() {
    echo -e "${BR_PINK}█▀▄${BR_RESET}"
}

# ============================================================================
# NEURAL / AI
# ============================================================================

br_neural_network() {
    echo -e "${BR_AMBER}●${BR_RESET}━━━━━━━${BR_ORANGE}●${BR_RESET}━━━━━━━${BR_PINK}●${BR_RESET}"
    echo -e "${BR_AMBER}┃${BR_RESET}╲      ${BR_ORANGE}┃${BR_RESET}╲ ╱    ╱${BR_PINK}┃${BR_RESET}"
    echo -e "${BR_AMBER}┃${BR_RESET} ╲     ${BR_ORANGE}┃${BR_RESET} ╳    ╱ ${BR_PINK}┃${BR_RESET}"
    echo -e "${BR_AMBER}┃${BR_RESET}  ╲    ${BR_ORANGE}┃${BR_RESET}╱ ╲  ╱  ${BR_PINK}┃${BR_RESET}"
    echo -e "${BR_AMBER}●${BR_RESET}━━━╲━━━${BR_ORANGE}●${BR_RESET}━━━╲╱━━━${BR_PINK}●${BR_RESET}━━━━${BR_MAGENTA}●${BR_RESET}"
    echo -e "${BR_AMBER}┃${BR_RESET}    ╲  ${BR_ORANGE}┃${BR_RESET}  ╱╲    ${BR_PINK}┃${BR_RESET}   ╱${BR_MAGENTA}┃${BR_RESET}"
    echo -e "${BR_AMBER}┃${BR_RESET}     ╲ ${BR_ORANGE}┃${BR_RESET} ╱  ╲   ${BR_PINK}┃${BR_RESET}  ╱ ${BR_MAGENTA}┃${BR_RESET}"
    echo -e "${BR_AMBER}┃${BR_RESET}      ╲${BR_ORANGE}┃${BR_RESET}╱    ╲  ${BR_PINK}┃${BR_RESET} ╱  ${BR_MAGENTA}┃${BR_RESET}"
    echo -e "${BR_AMBER}●${BR_RESET}━━━━━━━${BR_ORANGE}●${BR_RESET}━━━━━━━${BR_PINK}●${BR_RESET}━━━━${BR_MAGENTA}●${BR_RESET}"
}

# ============================================================================
# ROCKET / SPACE
# ============================================================================

br_rocket() {
    echo -e "         ${BR_AMBER}▲${BR_RESET}"
    echo -e "        ${BR_AMBER}╱${BR_WHITE}█${BR_AMBER}╲${BR_RESET}"
    echo -e "       ${BR_ORANGE}╱${BR_WHITE}███${BR_ORANGE}╲${BR_RESET}"
    echo -e "      ${BR_ORANGE}│${BR_WHITE}█████${BR_ORANGE}│${BR_RESET}"
    echo -e "      ${BR_PINK}│${BR_WHITE}█████${BR_PINK}│${BR_RESET}"
    echo -e "      ${BR_PINK}│${BR_WHITE}█████${BR_PINK}│${BR_RESET}"
    echo -e "     ${BR_MAGENTA}╱${BR_WHITE}███████${BR_MAGENTA}╲${BR_RESET}"
    echo -e "    ${BR_MAGENTA}╱${BR_WHITE}█████████${BR_MAGENTA}╲${BR_RESET}"
    echo -e "   ${BR_BLUE}╱${BR_WHITE}███████████${BR_BLUE}╲${BR_RESET}"
    echo -e "  ${BR_BLUE}▕${BR_RESET}  ${BR_AMBER}▓${BR_ORANGE}▓${BR_PINK}█${BR_MAGENTA}█${BR_PINK}█${BR_ORANGE}▓${BR_AMBER}▓${BR_RESET}  ${BR_BLUE}▏${BR_RESET}"
    echo -e "     ${BR_AMBER}▓${BR_ORANGE}▒${BR_PINK}░${BR_RESET}   ${BR_PINK}░${BR_ORANGE}▒${BR_AMBER}▓${BR_RESET}"
    echo -e "      ${BR_ORANGE}▒${BR_PINK}░${BR_RESET}   ${BR_PINK}░${BR_ORANGE}▒${BR_RESET}"
    echo -e "       ${BR_PINK}░${BR_RESET}   ${BR_PINK}░${BR_RESET}"
}

# ============================================================================
# HEADER / BANNER GENERATORS
# ============================================================================

br_header() {
    local title=$1
    echo -e "${BR_AMBER}━━━━${BR_ORANGE}━━━━${BR_PINK}━━━━${BR_MAGENTA}━━━━${BR_BLUE}━━━━${BR_MAGENTA}━━━━${BR_PINK}━━━━${BR_ORANGE}━━━━${BR_AMBER}━━━━${BR_RESET}"
    echo -e "${BR_WHITE}  $title${BR_RESET}"
    echo -e "${BR_AMBER}━━━━${BR_ORANGE}━━━━${BR_PINK}━━━━${BR_MAGENTA}━━━━${BR_BLUE}━━━━${BR_MAGENTA}━━━━${BR_PINK}━━━━${BR_ORANGE}━━━━${BR_AMBER}━━━━${BR_RESET}"
}

br_banner() {
    local title=$1
    echo ""
    echo -e "${BR_AMBER}████${BR_ORANGE}████${BR_PINK}████${BR_MAGENTA}████${BR_BLUE}████${BR_MAGENTA}████${BR_PINK}████${BR_ORANGE}████${BR_AMBER}████${BR_RESET}"
    echo -e "${BR_WHITE}        $title${BR_RESET}"
    echo -e "${BR_AMBER}████${BR_ORANGE}████${BR_PINK}████${BR_MAGENTA}████${BR_BLUE}████${BR_MAGENTA}████${BR_PINK}████${BR_ORANGE}████${BR_AMBER}████${BR_RESET}"
    echo ""
}

# ============================================================================
# DEMO / SHOWCASE
# ============================================================================

br_demo_all() {
    echo -e "\n${BR_WHITE}═══════════════════════════════════════════════════════════════${BR_RESET}"
    echo -e "${BR_WHITE}              BLACKROAD UNICODE SHAPES LIBRARY                 ${BR_RESET}"
    echo -e "${BR_WHITE}═══════════════════════════════════════════════════════════════${BR_RESET}\n"

    echo -e "${BR_WHITE}▸ GRADIENT BAR:${BR_RESET}"
    br_gradient_bar
    echo ""

    echo -e "${BR_WHITE}▸ GRADIENT LINE:${BR_RESET}"
    br_gradient_line
    echo ""

    echo -e "${BR_WHITE}▸ GRADIENT BLOCKS:${BR_RESET}"
    br_gradient_blocks
    echo ""

    echo -e "${BR_WHITE}▸ GRADIENT FADE:${BR_RESET}"
    br_gradient_fade
    echo ""

    echo -e "${BR_WHITE}▸ STATUS INDICATORS:${BR_RESET}"
    br_status_online
    br_status_success
    br_status_warning
    echo ""

    echo -e "${BR_WHITE}▸ STARBURST:${BR_RESET}"
    br_starburst
    echo ""

    echo -e "${BR_WHITE}▸ MANDALA:${BR_RESET}"
    br_mandala
    echo ""

    echo -e "${BR_WHITE}▸ FLAME:${BR_RESET}"
    br_flame
    echo ""

    echo -e "${BR_WHITE}▸ MUSIC VISUALIZER:${BR_RESET}"
    br_music_visualizer
    echo ""

    echo -e "${BR_WHITE}▸ NEURAL NETWORK:${BR_RESET}"
    br_neural_network
    echo ""

    echo -e "${BR_WHITE}▸ BLACKROAD LOGO:${BR_RESET}"
    br_logo_blocks
    echo ""

    echo -e "${BR_WHITE}═══════════════════════════════════════════════════════════════${BR_RESET}"
    echo -e "${BR_WHITE}OFFICIAL COLORS:${BR_RESET}"
    echo -e "  ${BR_AMBER}208 AMBER${BR_RESET} | ${BR_ORANGE}202 ORANGE${BR_RESET} | ${BR_PINK}198 PINK${BR_RESET} | ${BR_MAGENTA}163 MAGENTA${BR_RESET} | ${BR_BLUE}33 BLUE${BR_RESET}"
    echo -e "  ${BR_WHITE}TEXT = WHITE (1;37m) | BLOCKS = COLOR${BR_RESET}"
    echo ""
}

# Run demo if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    br_demo_all
fi
