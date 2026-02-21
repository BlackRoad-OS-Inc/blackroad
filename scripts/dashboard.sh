#!/usr/bin/env bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# ═══════════════════════════════════════════════════════════════════════════════
#  BLACKROAD MONITORING DASHBOARD v1.0
#  Real-time system health, agents, deployments & infrastructure
# ═══════════════════════════════════════════════════════════════════════════════

# ── Brand Colors ──
PINK=$'\033[38;5;205m'
AMBER=$'\033[38;5;214m'
BLUE=$'\033[38;5;69m'
VIOLET=$'\033[38;5;135m'
GREEN=$'\033[38;5;82m'
RED=$'\033[38;5;196m'
PINK=$'\033[38;5;45m'
DIM=$'\033[38;5;245m'
BOLD=$'\033[1m'
RST=$'\033[0m'

# ── Paths ──
MEMORY_DIR="$HOME/.blackroad/memory"
AGENTS_DIR="$MEMORY_DIR/active-agents"
JOURNAL="$MEMORY_DIR/journals/pixel-agents.jsonl"
MASTER_JOURNAL="$MEMORY_DIR/journals/master-journal.jsonl"

# ── Helper Functions ──

bar() {
    local percent=$1
    local width=${2:-20}
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    local color="$GREEN"
    [[ $percent -gt 70 ]] && color="$AMBER"
    [[ $percent -gt 90 ]] && color="$RED"

    printf "${color}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${DIM}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "${RST}"
}

spark() {
    local val=$1
    local chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
    local idx=$((val * 7 / 100))
    [[ $idx -gt 7 ]] && idx=7
    echo "${chars[$idx]}"
}

# ── Dashboard Panels ──

panel_header() {
    local title="$1"
    local width=${2:-30}
    printf "${PINK}┌"
    for ((i=0; i<width-2; i++)); do printf "─"; done
    printf "┐${RST}\n"
    printf "${PINK}│${RST} ${BOLD}${AMBER}%-$((width-4))s${RST} ${PINK}│${RST}\n" "$title"
    printf "${PINK}├"
    for ((i=0; i<width-2; i++)); do printf "─"; done
    printf "┤${RST}\n"
}

panel_row() {
    local label="$1"
    local value="$2"
    local width=${3:-30}
    local content_width=$((width - 4))
    printf "${PINK}│${RST} %-12s %*s ${PINK}│${RST}\n" "$label" "$((content_width - 13))" "$value"
}

panel_footer() {
    local width=${1:-30}
    printf "${PINK}└"
    for ((i=0; i<width-2; i++)); do printf "─"; done
    printf "┘${RST}\n"
}

# ── Data Collection ──

get_cpu() {
    if [[ "$(uname)" == "Darwin" ]]; then
        top -l 1 -n 0 2>/dev/null | awk '/CPU usage/ {print int($3)}' || echo "0"
    else
        grep 'cpu ' /proc/stat | awk '{print int(($2+$4)*100/($2+$4+$5))}' 2>/dev/null || echo "0"
    fi
}

get_memory() {
    if [[ "$(uname)" == "Darwin" ]]; then
        local pages=$(vm_stat 2>/dev/null | awk '/Pages active/ {print $3}' | tr -d '.')
        local total=$(sysctl -n hw.memsize 2>/dev/null)
        if [[ -n "$pages" && -n "$total" ]]; then
            echo $((pages * 4096 * 100 / total))
        else
            echo "0"
        fi
    else
        free 2>/dev/null | awk '/Mem:/ {print int($3/$2 * 100)}' || echo "0"
    fi
}

get_disk() {
    df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,""); print $5}' || echo "0"
}

# ── Dashboard Views ──

view_system() {
    local cpu=$(get_cpu)
    local mem=$(get_memory)
    local disk=$(get_disk)

    panel_header "SYSTEM" 35
    printf "${PINK}│${RST} CPU    $(bar $cpu 15) %3d%% ${PINK}│${RST}\n" "$cpu"
    printf "${PINK}│${RST} Memory $(bar $mem 15) %3d%% ${PINK}│${RST}\n" "$mem"
    printf "${PINK}│${RST} Disk   $(bar $disk 15) %3d%% ${PINK}│${RST}\n" "$disk"
    panel_footer 35
}

view_fleet() {
    panel_header "PI FLEET" 35

    local devices=(
        "cecilia|192.168.4.89|👩‍💻"
        "lucidia|192.168.4.81|🎨"
        "alice|192.168.4.49|📚"
        "aria|192.168.4.82|🧠"
        "octavia|192.168.4.38|🐙"
    )

    for device in "${devices[@]}"; do
        IFS='|' read -r name ip sprite <<< "$device"
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            printf "${PINK}│${RST} %s %-8s ${GREEN}●${RST} %-12s ${PINK}│${RST}\n" "$sprite" "$name" "$ip"
        else
            printf "${PINK}│${RST} %s %-8s ${RED}○${RST} offline      ${PINK}│${RST}\n" "$sprite" "$name"
        fi
    done

    panel_footer 35
}

view_agents() {
    panel_header "AGENTS" 35

    local pixel=$(ls -1 "$AGENTS_DIR"/pixel-*.json 2>/dev/null | wc -l | tr -d ' ')
    local pi=$(ls -1 "$AGENTS_DIR"/pi-*.json 2>/dev/null | wc -l | tr -d ' ')
    local device=$(ls -1 "$AGENTS_DIR"/device-*.json 2>/dev/null | wc -l | tr -d ' ')
    local claude=$(ls -1 "$AGENTS_DIR"/claude-*.json 2>/dev/null | wc -l | tr -d ' ')
    local total=$((pixel + pi + device + claude))

    printf "${PINK}│${RST} 🤖 Pixel      ${GREEN}%6d${RST}         ${PINK}│${RST}\n" "$pixel"
    printf "${PINK}│${RST} 🍓 Real Pis   ${BLUE}%6d${RST}         ${PINK}│${RST}\n" "$pi"
    printf "${PINK}│${RST} 💻 Devices    ${VIOLET}%6d${RST}         ${PINK}│${RST}\n" "$device"
    printf "${PINK}│${RST} 🧠 Claude     ${PINK}%6d${RST}         ${PINK}│${RST}\n" "$claude"
    printf "${PINK}│${RST} ─────────────────────────────── ${PINK}│${RST}\n"
    printf "${PINK}│${RST} ${BOLD}Total${RST}         ${BOLD}%6d${RST}         ${PINK}│${RST}\n" "$total"

    panel_footer 35
}

view_memory() {
    panel_header "MEMORY SYSTEM" 35

    local entries=$(wc -l < "$MASTER_JOURNAL" 2>/dev/null | tr -d ' ' || echo "0")
    local pixel_events=$(wc -l < "$JOURNAL" 2>/dev/null | tr -d ' ' || echo "0")
    local tasks=$(ls -1 "$MEMORY_DIR/tasks/"*.json 2>/dev/null | wc -l | tr -d ' ' || echo "0")

    printf "${PINK}│${RST} Journal      ${AMBER}%8d${RST}       ${PINK}│${RST}\n" "$entries"
    printf "${PINK}│${RST} Pixel Events ${VIOLET}%8d${RST}       ${PINK}│${RST}\n" "$pixel_events"
    printf "${PINK}│${RST} Tasks        ${BLUE}%8d${RST}       ${PINK}│${RST}\n" "$tasks"

    panel_footer 35
}

view_security() {
    panel_header "SECURITY" 35

    # Firewall
    local fw="○"
    local fw_color="$RED"
    if [[ "$(uname)" == "Darwin" ]]; then
        if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
            fw="●"
            fw_color="$GREEN"
        fi
    fi

    # Open ports
    local ports=$(lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | wc -l | tr -d ' ')

    # SSH sessions
    local ssh=$(who | grep -c "pts" 2>/dev/null || echo "0")

    printf "${PINK}│${RST} Firewall     ${fw_color}${fw}${RST} %-14s ${PINK}│${RST}\n" ""
    printf "${PINK}│${RST} Open Ports   ${AMBER}%-3d${RST}              ${PINK}│${RST}\n" "$ports"
    printf "${PINK}│${RST} SSH Sessions ${PINK}%-3d${RST}              ${PINK}│${RST}\n" "$ssh"

    panel_footer 35
}

view_services() {
    panel_header "SERVICES" 35

    # Ollama
    local ollama="○"
    local ollama_color="$RED"
    if pgrep -x "ollama" &>/dev/null; then
        ollama="●"
        ollama_color="$GREEN"
    fi

    # Docker
    local docker="○"
    local docker_color="$RED"
    local containers=0
    if command -v docker &>/dev/null && docker info &>/dev/null; then
        docker="●"
        docker_color="$GREEN"
        containers=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    fi

    # pixelhq
    local pixelhq="○"
    local pixelhq_color="$RED"
    if lsof -i:8765 &>/dev/null; then
        pixelhq="●"
        pixelhq_color="$GREEN"
    fi

    printf "${PINK}│${RST} Ollama       ${ollama_color}${ollama}${RST} running        ${PINK}│${RST}\n"
    printf "${PINK}│${RST} Docker       ${docker_color}${docker}${RST} %d containers  ${PINK}│${RST}\n" "$containers"
    printf "${PINK}│${RST} PixelHQ      ${pixelhq_color}${pixelhq}${RST} ws://8765      ${PINK}│${RST}\n"

    panel_footer 35
}

view_activity() {
    panel_header "RECENT ACTIVITY" 72

    tail -5 "$MASTER_JOURNAL" 2>/dev/null | while read -r line; do
        local ts=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('timestamp','?')[11:19])" 2>/dev/null || echo "?")
        local action=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('action','?')[:15])" 2>/dev/null || echo "?")
        local entity=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('entity','?')[:30])" 2>/dev/null || echo "?")
        printf "${PINK}│${RST} ${DIM}%s${RST} ${AMBER}%-15s${RST} → %-30s         ${PINK}│${RST}\n" "$ts" "$action" "$entity"
    done

    panel_footer 72
}

view_deployments() {
    panel_header "CLOUDFLARE PAGES" 35

    # Get recent deployments
    if command -v wrangler &>/dev/null; then
        wrangler pages project list 2>/dev/null | head -5 | while read -r line; do
            local name=$(echo "$line" | awk '{print $1}' | head -c 20)
            [[ -n "$name" ]] && printf "${PINK}│${RST} ${BLUE}%-31s${RST} ${PINK}│${RST}\n" "$name"
        done 2>/dev/null || printf "${PINK}│${RST} ${DIM}Unable to fetch${RST}               ${PINK}│${RST}\n"
    else
        printf "${PINK}│${RST} ${DIM}wrangler not installed${RST}        ${PINK}│${RST}\n"
    fi

    panel_footer 35
}

# ── Main Dashboard ──

dashboard_full() {
    clear

    # Header
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════════════════╗${RST}"
    echo -e "${PINK}║${RST}  ${AMBER}█▀▀▄ █    █▀▀█ █▀▀  █  █ █▀▀▄ █▀▀█ █▀▀█ █▀▀▄${RST}  ${DIM}DASHBOARD${RST}             ${PINK}║${RST}"
    echo -e "${PINK}║${RST}  ${AMBER}█▀▀▄ █    █▄▄█ █    █▀▄  █▄▄▀ █  █ █▄▄█ █  █${RST}  $(date '+%H:%M:%S')               ${PINK}║${RST}"
    echo -e "${PINK}║${RST}  ${AMBER}▀▀▀  ▀▀▀  ▀  ▀ ▀▀▀  ▀ ▀  ▀ ▀▀ ▀▀▀▀ ▀  ▀ ▀▀▀ ${RST}  ${DIM}$(date '+%Y-%m-%d')${RST}          ${PINK}║${RST}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════════════════╝${RST}"
    echo ""

    # Row 1: System | Fleet | Agents
    paste <(view_system) <(view_fleet) <(view_agents) 2>/dev/null | sed 's/\t/ /g'
    echo ""

    # Row 2: Memory | Security | Services
    paste <(view_memory) <(view_security) <(view_services) 2>/dev/null | sed 's/\t/ /g'
    echo ""

    # Activity
    view_activity
    echo ""
}

dashboard_compact() {
    echo -e "${PINK}─── ${AMBER}BLACKROAD DASHBOARD${RST} ${PINK}───${RST} $(date '+%H:%M:%S')"
    echo ""

    local cpu=$(get_cpu)
    local mem=$(get_memory)
    local disk=$(get_disk)

    # System
    printf "  ${BOLD}System${RST}   CPU $(bar $cpu 10) %3d%%  MEM $(bar $mem 10) %3d%%  DISK $(bar $disk 10) %3d%%\n" "$cpu" "$mem" "$disk"

    # Fleet
    local online=0
    for ip in 192.168.4.89 192.168.4.81 192.168.4.49 192.168.4.82 192.168.4.38; do
        ping -c 1 -W 1 "$ip" &>/dev/null && ((online++))
    done
    printf "  ${BOLD}Fleet${RST}    ${GREEN}$online${RST}/5 online"

    # Agents
    local agents=$(ls -1 "$AGENTS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    printf "    ${BOLD}Agents${RST}  ${AMBER}$agents${RST} active"

    # Memory
    local entries=$(wc -l < "$MASTER_JOURNAL" 2>/dev/null | tr -d ' ' || echo "0")
    printf "    ${BOLD}Memory${RST}  ${VIOLET}$entries${RST} entries\n"
    echo ""
}

dashboard_watch() {
    local interval="${1:-5}"

    while true; do
        dashboard_full
        echo -e "${DIM}Refreshing in ${interval}s... (Ctrl+C to exit)${RST}"
        sleep "$interval"
    done
}

dashboard_mini() {
    local cpu=$(get_cpu)
    local mem=$(get_memory)
    local online=0
    for ip in 192.168.4.89 192.168.4.81 192.168.4.49 192.168.4.82 192.168.4.38; do
        ping -c 1 -W 1 "$ip" &>/dev/null && ((online++))
    done
    local agents=$(ls -1 "$AGENTS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

    echo -e "${PINK}BR${RST} CPU:${cpu}% MEM:${mem}% Fleet:${online}/5 Agents:${agents}"
}

# ── Help ──

cmd_help() {
    echo -e "${PINK}─── ${AMBER}BLACKROAD DASHBOARD${RST} ${PINK}───${RST}"
    echo ""
    echo -e "  ${GREEN}dashboard${RST}           Full dashboard (once)"
    echo -e "  ${GREEN}dashboard watch${RST}     Live updating dashboard"
    echo -e "  ${GREEN}dashboard compact${RST}   Single-line summary"
    echo -e "  ${GREEN}dashboard mini${RST}      Minimal one-liner"
    echo ""
    echo -e "  ${GREEN}dashboard system${RST}    System panel only"
    echo -e "  ${GREEN}dashboard fleet${RST}     Pi fleet panel only"
    echo -e "  ${GREEN}dashboard agents${RST}    Agents panel only"
    echo -e "  ${GREEN}dashboard memory${RST}    Memory panel only"
    echo -e "  ${GREEN}dashboard security${RST}  Security panel only"
    echo -e "  ${GREEN}dashboard services${RST}  Services panel only"
    echo ""
}

# ── Main ──

case "${1:-full}" in
    full|f|"")      dashboard_full ;;
    watch|w)        shift; dashboard_watch "$@" ;;
    compact|c)      dashboard_compact ;;
    mini|m)         dashboard_mini ;;
    system|sys)     view_system ;;
    fleet|pi)       view_fleet ;;
    agents|a)       view_agents ;;
    memory|mem)     view_memory ;;
    security|sec)   view_security ;;
    services|svc)   view_services ;;
    activity|act)   view_activity ;;
    help|h|--help)  cmd_help ;;
    *)
        echo -e "${RED}Unknown:${RST} $1"
        cmd_help
        ;;
esac
