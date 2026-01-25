#!/bin/bash

# BlackRoad OS - ULTRA Enhanced Dashboard Launcher
# Live preview, collapsible categories, animations, keyboard shortcuts, breadcrumbs, quick jump, split-screen!

# Source theme system
source ~/blackroad-dashboards/themes.sh
load_theme

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
PREVIEW_MODE=1
SPLIT_SCREEN_MODE=0
SPLIT_DASHBOARD=""
FAVORITES_FILE=~/blackroad-dashboards/.favorites
RECENTS_FILE=~/blackroad-dashboards/.recents
BREADCRUMBS_FILE=~/blackroad-dashboards/.breadcrumbs
COLLAPSED_CATEGORIES=()

# Animation frame counter
FRAME=0

# Create files if not exist
touch "$FAVORITES_FILE" "$RECENTS_FILE" "$BREADCRUMBS_FILE"

# Breadcrumb functions
add_breadcrumb() {
    local idx=$1
    local dash="${DASHBOARDS[$idx]}"
    local name=$(echo "$dash" | cut -d'|' -f1)
    echo "$(date '+%H:%M:%S') → $name" >> "$BREADCRUMBS_FILE"
    tail -10 "$BREADCRUMBS_FILE" > "${BREADCRUMBS_FILE}.tmp"
    mv "${BREADCRUMBS_FILE}.tmp" "$BREADCRUMBS_FILE"
}

get_breadcrumbs() {
    if [ -f "$BREADCRUMBS_FILE" ]; then
        tail -3 "$BREADCRUMBS_FILE"
    fi
}

# Category collapse functions
is_category_collapsed() {
    local cat=$1
    for c in "${COLLAPSED_CATEGORIES[@]}"; do
        [[ "$c" == "$cat" ]] && return 0
    done
    return 1
}

toggle_category() {
    local cat=$1
    local found=0
    local new_array=()

    for c in "${COLLAPSED_CATEGORIES[@]}"; do
        if [[ "$c" == "$cat" ]]; then
            found=1
        else
            new_array+=("$c")
        fi
    done

    if [ $found -eq 0 ]; then
        new_array+=("$cat")
    fi

    COLLAPSED_CATEGORIES=("${new_array[@]}")
}

# Favorites/Recents functions
get_favorites() {
    if [ -f "$FAVORITES_FILE" ]; then
        cat "$FAVORITES_FILE"
    fi
}

get_recents() {
    if [ -f "$RECENTS_FILE" ]; then
        head -5 "$RECENTS_FILE"
    fi
}

toggle_favorite() {
    local idx=$1
    if grep -q "^$idx$" "$FAVORITES_FILE" 2>/dev/null; then
        grep -v "^$idx$" "$FAVORITES_FILE" > "${FAVORITES_FILE}.tmp"
        mv "${FAVORITES_FILE}.tmp" "$FAVORITES_FILE"
    else
        echo "$idx" >> "$FAVORITES_FILE"
    fi
}

add_to_recents() {
    local idx=$1
    grep -v "^$idx$" "$RECENTS_FILE" > "${RECENTS_FILE}.tmp" 2>/dev/null || touch "${RECENTS_FILE}.tmp"
    echo "$idx" > "$RECENTS_FILE"
    head -4 "${RECENTS_FILE}.tmp" >> "$RECENTS_FILE"
    rm "${RECENTS_FILE}.tmp"
}

# Filter dashboards
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

# Animated loading bar
show_animation() {
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local idx=$((FRAME % 10))
    echo -e "${CYAN}${chars:$idx:1}${RESET}"
    FRAME=$((FRAME + 1))
}

# Live preview (mini dashboard preview)
show_preview() {
    local idx=$1
    local dash="${DASHBOARDS[$idx]}"
    local name=$(echo "$dash" | cut -d'|' -f1)
    local emoji=$(echo "$dash" | cut -d'|' -f2)
    local desc=$(echo "$dash" | cut -d'|' -f3)
    local category=$(echo "$dash" | cut -d'|' -f5)

    echo -e "${TEXT_MUTED}╭─ 👁️  LIVE PREVIEW ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${GOLD}$name${RESET} $emoji"
    echo -e "  ${TEXT_SECONDARY}$desc${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}Category:${RESET} ${PURPLE}$category${RESET}"
    echo -e "  ${TEXT_MUTED}Status:${RESET}   ${GREEN}Ready$(show_animation)${RESET}"

    # Show quick stats based on dashboard type
    case "$name" in
        "Master Control")
            echo -e "  ${TEXT_MUTED}Devices:${RESET}  ${ORANGE}5 online${RESET}"
            ;;
        "Docker Fleet")
            echo -e "  ${TEXT_MUTED}Containers:${RESET} ${CYAN}22/24 running${RESET}"
            ;;
        "Security")
            echo -e "  ${TEXT_MUTED}Score:${RESET}    ${GREEN}98/100${RESET}"
            ;;
        "API Health")
            echo -e "  ${TEXT_MUTED}Uptime:${RESET}   ${GREEN}99.9%${RESET}"
            ;;
        *)
            echo -e "  ${TEXT_MUTED}Press ${BOLD}ENTER${RESET}${TEXT_MUTED} to launch${RESET}"
            ;;
    esac

    echo ""
    echo -e "${TEXT_MUTED}╰───────────────────────────────────────────────────────────────────────╯${RESET}"
}

# Draw the launcher
draw_launcher() {
    clear

    # Animated header
    local pulse=$((FRAME % 2))
    local header_color=$([[ $pulse -eq 0 ]] && echo "$GOLD" || echo "$ORANGE")

    echo ""
    echo -e "${BOLD}${header_color}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${header_color}║${RESET}  ${GOLD}⚡${RESET} ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D ${ORANGE}D${PINK}A${PURPLE}S${BLUE}H${CYAN}B${ORANGE}O${PINK}A${PURPLE}R${BLUE}D${CYAN}S${RESET} ${GOLD}⚡${RESET}  ${RED}ULTRA${RESET}                       ${BOLD}${header_color}║${RESET}"
    echo -e "${BOLD}${header_color}║${RESET}     ${TEXT_SECONDARY}28 Dashboards • Enhanced UX • Live Preview • Split Screen${RESET}       ${BOLD}${header_color}║${RESET}"
    echo -e "${BOLD}${header_color}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Breadcrumbs
    local breadcrumbs=$(get_breadcrumbs)
    if [ -n "$breadcrumbs" ]; then
        echo -e "${TEXT_MUTED}📍 Recent: $(echo "$breadcrumbs" | tail -1 | cut -d'→' -f2 | xargs)${RESET}"
        echo ""
    fi

    # Search bar
    if [ $SEARCH_MODE -eq 1 ]; then
        echo -e "${CYAN}╭─ 🔍 SEARCH ───────────────────────────────────────────────────────────╮${RESET}"
        echo -e "${CYAN}│${RESET} ${BOLD}${TEXT_PRIMARY}Search: ${ORANGE}${SEARCH_QUERY}█${RESET}"
        echo -e "${CYAN}╰───────────────────────────────────────────────────────────────────────╯${RESET}"
        echo ""
    fi

    # Split screen indicator
    if [ $SPLIT_SCREEN_MODE -eq 1 ] && [ -n "$SPLIT_DASHBOARD" ]; then
        echo -e "${PURPLE}╭─ 📱 SPLIT SCREEN MODE ────────────────────────────────────────────────╮${RESET}"
        echo -e "${PURPLE}│${RESET} ${TEXT_PRIMARY}Active: ${BOLD}$SPLIT_DASHBOARD${RESET}"
        echo -e "${PURPLE}╰───────────────────────────────────────────────────────────────────────╯${RESET}"
        echo ""
    fi

    # Favorites section (collapsible)
    local favs=$(get_favorites)
    if [ -n "$favs" ] && [ $SEARCH_MODE -eq 0 ]; then
        if is_category_collapsed "favorites"; then
            echo -e "${TEXT_MUTED}╭─ ⭐ FAVORITES [COLLAPSED] ${DIM}(press C to expand)${RESET}${TEXT_MUTED} ──────────────╮${RESET}"
        else
            echo -e "${TEXT_MUTED}╭─ ⭐ FAVORITES ${DIM}(press C to collapse)${RESET}${TEXT_MUTED} ───────────────────────────╮${RESET}"
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
        fi
        echo ""
    fi

    # Main dashboard list with collapsible categories
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

            local collapsed_indicator=""
            if is_category_collapsed "$category"; then
                collapsed_indicator=" [COLLAPSED]"
            fi

            case $category in
                specialized)
                    echo -e "${TEXT_MUTED}╭─ 🆕 SPECIALIZED$collapsed_indicator ───────────────────────────────────────╮${RESET}"
                    ;;
                infrastructure)
                    echo -e "${TEXT_MUTED}╭─ 🔥 INFRASTRUCTURE$collapsed_indicator ────────────────────────────────────╮${RESET}"
                    ;;
                classic)
                    echo -e "${TEXT_MUTED}╭─ 📚 CLASSIC$collapsed_indicator ───────────────────────────────────────────╮${RESET}"
                    ;;
            esac
            echo ""

            # Skip items if category is collapsed
            if is_category_collapsed "$category"; then
                continue
            fi
        fi

        # Skip if category is collapsed
        if is_category_collapsed "$category"; then
            continue
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

    # Live preview (if enabled)
    if [ $PREVIEW_MODE -eq 1 ] && [ $SEARCH_MODE -eq 0 ]; then
        local -a indices=($(filter_dashboards "$SEARCH_QUERY"))
        # Find the actual displayed index (accounting for collapsed categories)
        local display_idx=0
        local actual_idx=""
        for idx in "${indices[@]}"; do
            local dash="${DASHBOARDS[$idx]}"
            local category=$(echo "$dash" | cut -d'|' -f5)
            if ! is_category_collapsed "$category"; then
                if [ $display_idx -eq $SELECTED ]; then
                    actual_idx=$idx
                    break
                fi
                display_idx=$((display_idx + 1))
            fi
        done

        if [ -n "$actual_idx" ]; then
            show_preview $actual_idx
        fi
    fi

    # Keyboard shortcuts help
    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}↑↓${RESET} Nav  ${TEXT_SECONDARY}ENTER${RESET} Launch  ${TEXT_SECONDARY}F${RESET} Fav  ${TEXT_SECONDARY}/${RESET} Search  ${TEXT_SECONDARY}P${RESET} Preview  ${TEXT_SECONDARY}C${RESET} Collapse  ${TEXT_SECONDARY}S${RESET} Split  ${TEXT_SECONDARY}T${RESET} Theme  ${TEXT_SECONDARY}Q${RESET} Quit"
    echo ""
}

# Main loop
main() {
    # Hide cursor
    tput civis
    trap 'tput cnorm; exit' INT TERM

    while true; do
        draw_launcher

        # Read single key with timeout for animations
        read -rsn1 -t 0.1 key

        # Continue animation even if no key pressed
        if [ -z "$key" ]; then
            continue
        fi

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
                # Find actual index accounting for collapsed categories
                local display_idx=0
                local actual_idx=""
                for idx in "${indices[@]}"; do
                    local dash="${DASHBOARDS[$idx]}"
                    local category=$(echo "$dash" | cut -d'|' -f5)
                    if ! is_category_collapsed "$category"; then
                        if [ $display_idx -eq $SELECTED ]; then
                            actual_idx=$idx
                            break
                        fi
                        display_idx=$((display_idx + 1))
                    fi
                done

                if [ -n "$actual_idx" ]; then
                    local dash="${DASHBOARDS[$actual_idx]}"
                    local script=$(echo "$dash" | cut -d'|' -f4)

                    # Add to recents and breadcrumbs
                    add_to_recents $actual_idx
                    add_breadcrumb $actual_idx

                    # Launch dashboard
                    tput cnorm
                    ~/blackroad-dashboards/$script --watch
                    tput civis
                fi
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
            'p'|'P')  # Toggle preview
                PREVIEW_MODE=$((1 - PREVIEW_MODE))
                ;;
            'c'|'C')  # Collapse/expand categories
                # Determine which category is selected
                local -a indices=($(filter_dashboards "$SEARCH_QUERY"))
                if [ ${#indices[@]} -gt 0 ]; then
                    local idx=${indices[0]}  # First visible item's category
                    local dash="${DASHBOARDS[$idx]}"
                    local category=$(echo "$dash" | cut -d'|' -f5)
                    toggle_category "$category"
                fi
                ;;
            's'|'S')  # Split screen toggle
                SPLIT_SCREEN_MODE=$((1 - SPLIT_SCREEN_MODE))
                ;;
            't'|'T')  # Theme selector
                tput cnorm
                ~/blackroad-dashboards/themes.sh
                load_theme
                tput civis
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
