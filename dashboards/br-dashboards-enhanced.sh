#!/bin/bash

# BlackRoad OS - Enhanced Dashboard Launcher
# Arrow key navigation, live preview, search, favorites!

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GOLD="\033[38;2;255;215;0m"
GREEN="\033[38;2;0;255;100m"
RED="\033[38;2;255;50;50m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;253m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Dashboard data: name|emoji|description|script|category
DASHBOARDS=(
    "Master Control|⚡|ALL systems unified • Interactive|blackroad-master-control.sh|specialized"
    "Cosmic Lottery|∞|Quantum probability engine|blackroad-cosmic-lottery.sh|specialized"
    "Pi Fleet|🥧|4 Raspberry Pi devices|device-raspberry-pi.sh|specialized"
    "Cloudflare|☁️|16 zones • 8 Pages • 8 KV • 1 D1|device-cloudflare.sh|specialized"
    "GitHub|🐙|15 orgs • 66 repos|device-github.sh|specialized"
    "Railway|🚂|12+ deployments|device-railway.sh|specialized"
    "Crypto Portfolio|₿Ξ◎|Live BTC/ETH/SOL tracking|crypto-portfolio-live.sh|specialized"
    "Memory System|∞|PS-SHA∞ hash chains|memory-system-viz.sh|specialized"
    "Agent Network|🤖|104 AI agents map|agent-network-map.sh|specialized"
    "Services/Ports|🔌|47 endpoints & ports|services-ports-map.sh|specialized"
    "System Metrics|📊|Real-time performance|system-metrics-live.sh|specialized"
    "Network Topology|🌐|3D network visualization|network-topology-3d.sh|infrastructure"
    "Deployment Timeline|📅|Gantt chart • 847 deploys|deployment-timeline.sh|infrastructure"
    "Database Monitor|💾|D1 + KV stores • 8.2GB|database-monitor.sh|infrastructure"
    "API Health|🔌|47 endpoints • 99.9% uptime|api-health-check.sh|infrastructure"
    "Docker Fleet|🐳|24 containers • 4 devices|docker-fleet.sh|infrastructure"
    "SSL Certificates|🔒|16 certs • Auto-renew|ssl-cert-tracker.sh|infrastructure"
    "DNS Records|🌐|247 records • 16 zones|dns-record-viewer.sh|infrastructure"
    "Log Aggregator|📋|18K logs/hr • Multi-device|log-aggregator.sh|infrastructure"
    "Backup Status|💾|847GB • 24 backup sets|backup-status.sh|infrastructure"
    "Security|🔐|Threats • Vulns • Score: 98|security-dashboard.sh|infrastructure"
    "Build Pipeline|⚙️|CI/CD • 98.7% success|build-pipeline.sh|infrastructure"
    "Basic Dashboard|📊|Simple, clean view|blackroad-dashboard.sh|classic"
    "Live Monitor|📡|Comprehensive real-time|blackroad-live-dashboard.sh|classic"
    "Full System|🖥️|Enhanced with progress bars|blackroad-full-system.sh|classic"
    "ULTIMATE|🚀|SSH + APIs + Sound|blackroad-ultimate.sh|classic"
    "Windows 95|🪟|Retro UI experience|blackroad-os95.sh|classic"
    "Agent Detail|🔍|Deep agent inspection|agent-detail.sh|classic"
)

# State
SELECTED=0
SEARCH_MODE=0
SEARCH_QUERY=""
FAVORITES_FILE=~/blackroad-dashboards/.favorites
RECENTS_FILE=~/blackroad-dashboards/.recents

# Create files if not exist
touch "$FAVORITES_FILE" "$RECENTS_FILE"

# Get favorites
get_favorites() {
    if [ -f "$FAVORITES_FILE" ]; then
        cat "$FAVORITES_FILE"
    fi
}

# Get recents
get_recents() {
    if [ -f "$RECENTS_FILE" ]; then
        head -5 "$RECENTS_FILE"
    fi
}

# Toggle favorite
toggle_favorite() {
    local idx=$1
    local dash="${DASHBOARDS[$idx]}"
    local name=$(echo "$dash" | cut -d'|' -f1)

    if grep -q "^$idx$" "$FAVORITES_FILE" 2>/dev/null; then
        # Remove from favorites
        grep -v "^$idx$" "$FAVORITES_FILE" > "${FAVORITES_FILE}.tmp"
        mv "${FAVORITES_FILE}.tmp" "$FAVORITES_FILE"
    else
        # Add to favorites
        echo "$idx" >> "$FAVORITES_FILE"
    fi
}

# Add to recents
add_to_recents() {
    local idx=$1
    # Remove if exists, then add to top
    grep -v "^$idx$" "$RECENTS_FILE" > "${RECENTS_FILE}.tmp" 2>/dev/null || touch "${RECENTS_FILE}.tmp"
    echo "$idx" > "$RECENTS_FILE"
    head -4 "${RECENTS_FILE}.tmp" >> "$RECENTS_FILE"
    rm "${RECENTS_FILE}.tmp"
}

# Filter dashboards by search
filter_dashboards() {
    local query="$1"
    local -a filtered=()

    if [ -z "$query" ]; then
        echo "${!DASHBOARDS[@]}"
        return
    fi

    for i in "${!DASHBOARDS[@]}"; do
        local dash="${DASHBOARDS[$i]}"
        local name=$(echo "$dash" | cut -d'|' -f1)
        local desc=$(echo "$dash" | cut -d'|' -f3)

        if [[ "${name,,}" == *"${query,,}"* ]] || [[ "${desc,,}" == *"${query,,}"* ]]; then
            filtered+=($i)
        fi
    done

    echo "${filtered[@]}"
}

# Draw the launcher
draw_launcher() {
    clear

    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${GOLD}⚡${RESET} ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D ${ORANGE}D${PINK}A${PURPLE}S${BLUE}H${CYAN}B${ORANGE}O${PINK}A${PURPLE}R${BLUE}D${CYAN}S${RESET} ${GOLD}⚡${RESET}  ${GOLD}ENHANCED${RESET}                         ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}     ${TEXT_SECONDARY}28 Dashboards • ↑↓ Navigate • ⭐ Favorite • / Search${RESET}             ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Search bar
    if [ $SEARCH_MODE -eq 1 ]; then
        echo -e "${CYAN}╭─ 🔍 SEARCH ───────────────────────────────────────────────────────────╮${RESET}"
        echo -e "${CYAN}│${RESET} ${BOLD}${TEXT_PRIMARY}Search: ${ORANGE}${SEARCH_QUERY}█${RESET}"
        echo -e "${CYAN}╰───────────────────────────────────────────────────────────────────────╯${RESET}"
        echo ""
    fi

    # Favorites section
    local favs=$(get_favorites)
    if [ -n "$favs" ] && [ $SEARCH_MODE -eq 0 ]; then
        echo -e "${TEXT_MUTED}╭─ ⭐ FAVORITES ────────────────────────────────────────────────────────╮${RESET}"
        echo ""
        while read -r fav_idx; do
            if [ -n "$fav_idx" ]; then
                local dash="${DASHBOARDS[$fav_idx]}"
                local name=$(echo "$dash" | cut -d'|' -f1)
                local emoji=$(echo "$dash" | cut -d'|' -f2)
                local desc=$(echo "$dash" | cut -d'|' -f3)
                echo -e "  ${GOLD}★${RESET} ${BOLD}$name${RESET} $emoji  ${TEXT_MUTED}$desc${RESET}"
            fi
        done <<< "$favs"
        echo ""
    fi

    # Recent section
    local recents=$(get_recents)
    if [ -n "$recents" ] && [ $SEARCH_MODE -eq 0 ]; then
        echo -e "${TEXT_MUTED}╭─ 🕐 RECENT ───────────────────────────────────────────────────────────╮${RESET}"
        echo ""
        while read -r rec_idx; do
            if [ -n "$rec_idx" ]; then
                local dash="${DASHBOARDS[$rec_idx]}"
                local name=$(echo "$dash" | cut -d'|' -f1)
                local emoji=$(echo "$dash" | cut -d'|' -f2)
                echo -e "  ${CYAN}●${RESET} ${BOLD}$name${RESET} $emoji"
            fi
        done <<< "$recents"
        echo ""
    fi

    # Main dashboard list
    local -a indices=($(filter_dashboards "$SEARCH_QUERY"))
    local current_category=""
    local list_idx=0

    for idx in "${indices[@]}"; do
        local dash="${DASHBOARDS[$idx]}"
        local name=$(echo "$dash" | cut -d'|' -f1)
        local emoji=$(echo "$dash" | cut -d'|' -f2)
        local desc=$(echo "$dash" | cut -d'|' -f3)
        local category=$(echo "$dash" | cut -d'|' -f5)

        # Category header
        if [ "$category" != "$current_category" ]; then
            current_category="$category"
            echo ""
            case $category in
                specialized)
                    echo -e "${TEXT_MUTED}╭─ 🆕 SPECIALIZED DASHBOARDS ───────────────────────────────────────╮${RESET}"
                    ;;
                infrastructure)
                    echo -e "${TEXT_MUTED}╭─ 🔥 INFRASTRUCTURE DASHBOARDS ────────────────────────────────────╮${RESET}"
                    ;;
                classic)
                    echo -e "${TEXT_MUTED}╭─ 📚 CLASSIC DASHBOARDS ───────────────────────────────────────────╮${RESET}"
                    ;;
            esac
            echo ""
        fi

        # Is this a favorite?
        local is_fav=""
        if grep -q "^$idx$" "$FAVORITES_FILE" 2>/dev/null; then
            is_fav="${GOLD}★${RESET} "
        else
            is_fav="${TEXT_MUTED}☆${RESET} "
        fi

        # Is this selected?
        if [ $list_idx -eq $SELECTED ]; then
            echo -e "  ${GREEN}▶${RESET} $is_fav${BOLD}${GREEN}$name${RESET} $emoji  ${CYAN}$desc${RESET}"
        else
            echo -e "    $is_fav${BOLD}$name${RESET} $emoji  ${TEXT_MUTED}$desc${RESET}"
        fi

        list_idx=$((list_idx + 1))
    done

    echo ""
    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}↑↓${RESET} Navigate  ${TEXT_SECONDARY}ENTER${RESET} Launch  ${TEXT_SECONDARY}F${RESET} Favorite  ${TEXT_SECONDARY}/${RESET} Search  ${TEXT_SECONDARY}Q${RESET} Quit"
    echo ""
}

# Main loop
main() {
    # Hide cursor
    tput civis
    trap 'tput cnorm; exit' INT TERM

    while true; do
        draw_launcher

        # Read single key
        read -rsn1 key

        # Handle search mode
        if [ $SEARCH_MODE -eq 1 ]; then
            case "$key" in
                $'\x1b')  # ESC - exit search
                    read -rsn2 -t 0.001 rest
                    if [ -z "$rest" ]; then
                        SEARCH_MODE=0
                        SEARCH_QUERY=""
                        SELECTED=0
                    fi
                    ;;
                $'\x7f'|$'\x08')  # Backspace
                    SEARCH_QUERY="${SEARCH_QUERY%?}"
                    ;;
                '')  # Enter - exit search
                    SEARCH_MODE=0
                    ;;
                *)
                    if [[ "$key" =~ [a-zA-Z0-9\ ] ]]; then
                        SEARCH_QUERY="${SEARCH_QUERY}${key}"
                    fi
                    ;;
            esac
            continue
        fi

        # Handle navigation
        case "$key" in
            $'\x1b')  # Arrow keys
                read -rsn2 rest
                case "$rest" in
                    '[A')  # Up
                        SELECTED=$((SELECTED - 1))
                        [ $SELECTED -lt 0 ] && SELECTED=$((${#DASHBOARDS[@]} - 1))
                        ;;
                    '[B')  # Down
                        SELECTED=$((SELECTED + 1))
                        [ $SELECTED -ge ${#DASHBOARDS[@]} ] && SELECTED=0
                        ;;
                esac
                ;;
            '')  # Enter - launch dashboard
                local -a indices=($(filter_dashboards "$SEARCH_QUERY"))
                local idx=${indices[$SELECTED]}
                local dash="${DASHBOARDS[$idx]}"
                local script=$(echo "$dash" | cut -d'|' -f4)

                # Add to recents
                add_to_recents $idx

                # Launch dashboard
                tput cnorm
                ~/blackroad-dashboards/$script --watch
                tput civis
                ;;
            'f'|'F')  # Toggle favorite
                local -a indices=($(filter_dashboards "$SEARCH_QUERY"))
                local idx=${indices[$SELECTED]}
                toggle_favorite $idx
                ;;
            '/')  # Search mode
                SEARCH_MODE=1
                SEARCH_QUERY=""
                ;;
            'q'|'Q')  # Quit
                tput cnorm
                echo -e "\n${CYAN}See you later! 👋${RESET}\n"
                exit 0
                ;;
        esac
    done
}

main
