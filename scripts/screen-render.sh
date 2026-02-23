#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════════════════════
# BLACKROAD SCREEN RENDERER
# Renders ASCII/Unicode computer screens in terminal windows
# ═══════════════════════════════════════════════════════════════════════════════

# Colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;240m'
DARK='\033[38;5;236m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
CYAN='\033[38;5;51m'
RESET='\033[0m'

# Background colors
BG_DARK='\033[48;5;234m'
BG_BLUE='\033[48;5;17m'
BG_BLACK='\033[48;5;16m'
BG_GRAY='\033[48;5;238m'

# ═══════════════════════════════════════════════════════════════════════════════
# Screen Templates
# ═══════════════════════════════════════════════════════════════════════════════

render_monitor_frame() {
    local width="${1:-60}"
    local title="${2:-BLACKROAD OS}"
    local style="${3:-modern}"

    # Top bezel
    echo -e "${GRAY}╭$( printf '─%.0s' $(seq 1 $((width-2))) )╮${RESET}"

    # Camera dot
    local padding=$(( (width - 4) / 2 ))
    echo -e "${GRAY}│$( printf ' %.0s' $(seq 1 $padding) )${GREEN}◉${GRAY}$( printf ' %.0s' $(seq 1 $((width - padding - 3))) )│${RESET}"

    # Screen border top
    echo -e "${GRAY}│${RESET} ${DARK}┌$( printf '─%.0s' $(seq 1 $((width-6))) )┐${RESET} ${GRAY}│${RESET}"
}

render_monitor_bottom() {
    local width="${1:-60}"

    # Screen border bottom
    echo -e "${GRAY}│${RESET} ${DARK}└$( printf '─%.0s' $(seq 1 $((width-6))) )┘${RESET} ${GRAY}│${RESET}"

    # Bottom bezel
    echo -e "${GRAY}│$( printf ' %.0s' $(seq 1 $((width-2))) )│${RESET}"
    echo -e "${GRAY}╰$( printf '─%.0s' $(seq 1 $((width-2))) )╯${RESET}"

    # Stand
    local stand_pad=$(( (width - 10) / 2 ))
    echo -e "$( printf ' %.0s' $(seq 1 $stand_pad) )${GRAY}╱────────╲${RESET}"
    echo -e "$( printf ' %.0s' $(seq 1 $((stand_pad - 2))) )${GRAY}╱────────────╲${RESET}"
}

render_screen_line() {
    local width="${1:-60}"
    local content="${2:-}"
    local bg="${3:-$BG_DARK}"

    local content_len=${#content}
    local inner_width=$((width - 6))
    local padding=$((inner_width - content_len))

    if [[ $padding -lt 0 ]]; then
        content="${content:0:$inner_width}"
        padding=0
    fi

    echo -e "${GRAY}│${RESET} ${DARK}│${bg}${content}$( printf ' %.0s' $(seq 1 $padding) )${RESET}${DARK}│${RESET} ${GRAY}│${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Pre-built Screens
# ═══════════════════════════════════════════════════════════════════════════════

render_boot_screen() {
    local width="${1:-60}"
    local agent="${2:-CLAUDE}"

    clear
    render_monitor_frame "$width" "BLACKROAD OS"

    render_screen_line "$width" ""
    render_screen_line "$width" "${WHITE}  ▒▔.▔▒ BLACKROAD OS v3.0 ▒▔.▔▒${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${AMBER}  Booting autonomous agent: ${WHITE}${agent}${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${BLUE}  [████████████████████████] 100%${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${GREEN}  ✓ Memory system loaded${RESET}"
    render_screen_line "$width" "${GREEN}  ✓ Neural pathways active${RESET}"
    render_screen_line "$width" "${GREEN}  ✓ Hash identity verified${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${PINK}  Ready for input...${RESET}"
    render_screen_line "$width" ""

    render_monitor_bottom "$width"
}

render_dashboard_screen() {
    local width="${1:-60}"
    local agent="${2:-ZEUS}"
    local hash="${3:-a1b2c3d4}"
    local agent_status="${4:-ACTIVE}"

    clear
    render_monitor_frame "$width" "AGENT DASHBOARD"

    render_screen_line "$width" ""
    render_screen_line "$width" "${PINK}╔════════════════════════════════════════════════════╗${RESET}"
    render_screen_line "$width" "${PINK}║${WHITE}  BLACKROAD AGENT MONITOR                          ${PINK}║${RESET}"
    render_screen_line "$width" "${PINK}╚════════════════════════════════════════════════════╝${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${AMBER}  Agent:  ${WHITE}${agent}${RESET}"
    render_screen_line "$width" "${AMBER}  Hash:   ${VIOLET}${hash}${RESET}"
    render_screen_line "$width" "${AMBER}  Status: ${GREEN}● ${agent_status}${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${BLUE}  ┌─ CPU ──────────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BLUE}  │ ${GREEN}████████████░░░░░░░░${RESET}${BLUE} 62%              │${RESET}"
    render_screen_line "$width" "${BLUE}  └──────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${BLUE}  ┌─ MEM ──────────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BLUE}  │ ${AMBER}██████████████░░░░░░${RESET}${BLUE} 78%              │${RESET}"
    render_screen_line "$width" "${BLUE}  └──────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" ""

    render_monitor_bottom "$width"
}

render_terminal_screen() {
    local width="${1:-60}"
    local agent="${2:-claude}"

    clear
    render_monitor_frame "$width" "TERMINAL"

    render_screen_line "$width" "${BG_BLACK}${GREEN}                                                    ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${WHITE}  Last login: $(date '+%a %b %d %H:%M:%S')              ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GREEN}                                                    ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${PINK}  ▒▔.▔▒${WHITE} BLACKROAD OS ${PINK}▒▔.▔▒${RESET}${BG_BLACK}                          ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GREEN}                                                    ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${CYAN}  ${agent}@blackroad${WHITE}:${BLUE}~${WHITE}\$ ${GREEN}_${RESET}${BG_BLACK}                           ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GREEN}                                                    ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GRAY}  # Autonomous agent ready                         ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GRAY}  # Type 'claude' to start AI session              ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GREEN}                                                    ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GREEN}                                                    ${RESET}"
    render_screen_line "$width" "${BG_BLACK}${GREEN}                                                    ${RESET}"

    render_monitor_bottom "$width"
}

render_matrix_screen() {
    local width="${1:-60}"

    clear
    render_monitor_frame "$width" "MATRIX"

    # Generate random matrix rain
    local chars="ｱｲｳｴｵｶｷｸｹｺ01█▓░▒"
    local inner=$((width - 6))

    for row in {1..12}; do
        local line=""
        for col in $(seq 1 $inner); do
            if (( RANDOM % 3 == 0 )); then
                local idx=$((RANDOM % ${#chars}))
                line+="${GREEN}${chars:$idx:1}${RESET}"
            else
                line+=" "
            fi
        done
        render_screen_line "$width" "${BG_BLACK}${line}${RESET}"
    done

    render_monitor_bottom "$width"
}

render_code_screen() {
    local width="${1:-60}"
    local file="${2:-agent.py}"

    clear
    render_monitor_frame "$width" "CODE EDITOR"

    render_screen_line "$width" "${BG_DARK}${GRAY}  ─── ${WHITE}${file}${GRAY} ─────────────────────────────────────${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  1 │${VIOLET}class${WHITE} BlackRoadAgent:                        ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  2 │    ${VIOLET}def${WHITE} __init__(${AMBER}self${WHITE}):                       ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  3 │        ${AMBER}self${WHITE}.hash = generate_hash()            ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  4 │        ${AMBER}self${WHITE}.status = ${GREEN}\"active\"${WHITE}                 ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  5 │                                                ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  6 │    ${VIOLET}async def${WHITE} process(${AMBER}self${WHITE}, task):            ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  7 │        ${PINK}\"\"\"Execute autonomous task\"\"\"${WHITE}           ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  8 │        ${VIOLET}await${WHITE} ${AMBER}self${WHITE}.think(task)                 ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  9 │        ${VIOLET}return${WHITE} ${AMBER}self${WHITE}.respond()                  ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY} 10 │                                                ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}────┴────────────────────────────────────────────────${RESET}"

    render_monitor_bottom "$width"
}

render_chat_screen() {
    local width="${1:-60}"
    local agent="${2:-ATHENA}"

    clear
    render_monitor_frame "$width" "AI CHAT"

    render_screen_line "$width" "${BG_DARK}${PINK}  ▒▔.▔▒ ${WHITE}${agent}${PINK} ▒▔.▔▒${RESET}${BG_DARK}                               ${RESET}"
    render_screen_line "$width" "${BG_DARK}                                                    ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  ┌─────────────────────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  │${BLUE} USER: ${WHITE}What's the status of the swarm?     ${GRAY}│${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  └─────────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" "${BG_DARK}                                                    ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  ┌─────────────────────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  │${PINK} ${agent}: ${WHITE}All 4 agents operational.       ${GRAY}│${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  │${WHITE}   Zeus: coordinating                       ${GRAY}│${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  │${WHITE}   Athena: analyzing                        ${GRAY}│${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  │${WHITE}   Prometheus: building                     ${GRAY}│${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  │${WHITE}   Hermes: deploying                        ${GRAY}│${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  └─────────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" "${BG_DARK}                                                    ${RESET}"
    render_screen_line "$width" "${BG_DARK}${GRAY}  > ${GREEN}_${RESET}${BG_DARK}                                          ${RESET}"

    render_monitor_bottom "$width"
}

render_stats_screen() {
    local width="${1:-60}"

    clear
    render_monitor_frame "$width" "SYSTEM STATS"

    render_screen_line "$width" ""
    render_screen_line "$width" "${PINK}  ╔═══════════════════════════════════════════════╗${RESET}"
    render_screen_line "$width" "${PINK}  ║${WHITE}        BLACKROAD SWARM STATISTICS            ${PINK}║${RESET}"
    render_screen_line "$width" "${PINK}  ╚═══════════════════════════════════════════════╝${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${AMBER}  Agents Online:    ${WHITE}4${RESET}"
    render_screen_line "$width" "${AMBER}  Tasks Completed:  ${WHITE}2,298${RESET}"
    render_screen_line "$width" "${AMBER}  Memory Entries:   ${WHITE}156,804${RESET}"
    render_screen_line "$width" "${AMBER}  Uptime:           ${WHITE}99.97%${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${BLUE}  ┌─ Network ─────────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BLUE}  │  ${GREEN}▲${WHITE} 12.4 MB/s   ${RED}▼${WHITE} 8.2 MB/s              ${BLUE}│${RESET}"
    render_screen_line "$width" "${BLUE}  └────────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" ""

    render_monitor_bottom "$width"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Animated Screens
# ═══════════════════════════════════════════════════════════════════════════════

render_loading_animation() {
    local width="${1:-60}"
    local duration="${2:-5}"
    local message="${3:-Loading...}"

    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local end_time=$((SECONDS + duration))
    local i=0

    while [[ $SECONDS -lt $end_time ]]; do
        clear
        render_monitor_frame "$width" "LOADING"

        render_screen_line "$width" ""
        render_screen_line "$width" ""
        render_screen_line "$width" ""
        render_screen_line "$width" "${WHITE}              ${frames[$i]} ${message}${RESET}"
        render_screen_line "$width" ""
        render_screen_line "$width" ""
        render_screen_line "$width" ""

        render_monitor_bottom "$width"

        sleep 0.1
        i=$(( (i + 1) % ${#frames[@]} ))
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLI Interface
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
    echo -e "${PINK}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${WHITE}BLACKROAD SCREEN RENDERER${RESET}"
    echo -e "${PINK}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "Usage: $0 <screen_type> [width] [options...]"
    echo ""
    echo "Screen Types:"
    echo "  boot [width] [agent]           Boot sequence screen"
    echo "  dashboard [width] [agent]      Agent dashboard"
    echo "  terminal [width] [agent]       Terminal emulator"
    echo "  matrix [width]                 Matrix rain effect"
    echo "  code [width] [filename]        Code editor"
    echo "  chat [width] [agent]           AI chat interface"
    echo "  stats [width]                  System statistics"
    echo "  loading [width] [duration]     Loading animation"
    echo "  demo                           Show all screens"
    echo ""
    echo "Examples:"
    echo "  $0 boot 60 ZEUS"
    echo "  $0 dashboard 70 ATHENA a1b2c3d4 ACTIVE"
    echo "  $0 matrix 80"
    echo ""
}

demo_all() {
    local width="${1:-60}"

    echo -e "${PINK}Demonstrating all screen types...${RESET}"
    echo ""

    for screen in boot dashboard terminal code chat stats; do
        echo -e "${AMBER}>>> $screen screen${RESET}"
        sleep 1
        case $screen in
            boot) render_boot_screen "$width" "DEMO" ;;
            dashboard) render_dashboard_screen "$width" "ZEUS" "a1b2c3d4" "ACTIVE" ;;
            terminal) render_terminal_screen "$width" "claude" ;;
            code) render_code_screen "$width" "agent.py" ;;
            chat) render_chat_screen "$width" "ATHENA" ;;
            stats) render_stats_screen "$width" ;;
        esac
        sleep 2
    done
}

# Main CLI handler
case "${1:-help}" in
    boot)
        render_boot_screen "${2:-60}" "${3:-CLAUDE}"
        ;;
    dashboard)
        render_dashboard_screen "${2:-60}" "${3:-ZEUS}" "${4:-a1b2c3d4}" "${5:-ACTIVE}"
        ;;
    terminal)
        render_terminal_screen "${2:-60}" "${3:-claude}"
        ;;
    matrix)
        render_matrix_screen "${2:-60}"
        ;;
    code)
        render_code_screen "${2:-60}" "${3:-agent.py}"
        ;;
    chat)
        render_chat_screen "${2:-60}" "${3:-ATHENA}"
        ;;
    stats)
        render_stats_screen "${2:-60}"
        ;;
    loading)
        render_loading_animation "${2:-60}" "${3:-5}" "${4:-Loading...}"
        ;;
    demo)
        demo_all "${2:-60}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac
