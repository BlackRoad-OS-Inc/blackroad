#!/bin/bash

# BlackRoad OS - Zoom System
# Zoom in/out of dashboard sections

source ~/blackroad-dashboards/themes.sh
load_theme

# Zoom state
ZOOM_LEVEL=1.0
ZOOM_SECTION="overview"

# Zoom levels
zoom_in() {
    ZOOM_LEVEL=$(echo "$ZOOM_LEVEL + 0.2" | bc)
    if (( $(echo "$ZOOM_LEVEL > 2.0" | bc -l) )); then
        ZOOM_LEVEL=2.0
    fi
}

zoom_out() {
    ZOOM_LEVEL=$(echo "$ZOOM_LEVEL - 0.2" | bc)
    if (( $(echo "$ZOOM_LEVEL < 0.6" | bc -l) )); then
        ZOOM_LEVEL=0.6
    fi
}

reset_zoom() {
    ZOOM_LEVEL=1.0
}

# Get scaled width based on zoom
get_scaled_width() {
    local base_width=$1
    echo "$(echo "$base_width * $ZOOM_LEVEL" | bc | cut -d. -f1)"
}

# Render zoomed content
render_zoomed_section() {
    local section=$1
    local zoom=$ZOOM_LEVEL

    # Calculate scaling
    local scale_int=$(echo "$zoom * 10" | bc | cut -d. -f1)
    local is_zoomed_in=$((scale_int > 10))
    local is_zoomed_out=$((scale_int < 10))

    clear
    echo ""

    # Header with zoom indicator
    local zoom_indicator=""
    if [ $is_zoomed_in -eq 1 ]; then
        zoom_indicator="${GREEN}[${zoom}x ZOOMED IN]${RESET}"
    elif [ $is_zoomed_out -eq 1 ]; then
        zoom_indicator="${YELLOW}[${zoom}x ZOOMED OUT]${RESET}"
    else
        zoom_indicator="${CYAN}[${zoom}x NORMAL]${RESET}"
    fi

    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}🔍${RESET} ${BOLD}ZOOM SYSTEM${RESET} $zoom_indicator                                     ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    case "$section" in
        "overview")
            render_overview_section "$zoom"
            ;;
        "metrics")
            render_metrics_section "$zoom"
            ;;
        "containers")
            render_containers_section "$zoom"
            ;;
        "chart")
            render_chart_section "$zoom"
            ;;
    esac

    # Controls
    echo ""
    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[+]${RESET} Zoom In  ${TEXT_SECONDARY}[-]${RESET} Zoom Out  ${TEXT_SECONDARY}[0]${RESET} Reset  ${TEXT_SECONDARY}[1-4]${RESET} Sections  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo -e "  ${TEXT_MUTED}Current: ${BOLD}${zoom}x${RESET}${TEXT_MUTED} • Section: ${BOLD}$section${RESET}"
    echo ""
}

# Overview section (scales text)
render_overview_section() {
    local zoom=$1
    local scale_int=$(echo "$zoom * 10" | bc | cut -d. -f1)

    echo -e "${TEXT_MUTED}╭─ OVERVIEW (Zoom: ${zoom}x) ────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ $scale_int -ge 14 ]; then
        # Zoomed in - show more details
        echo -e "  ${BOLD}${TEXT_PRIMARY}━━━ DETAILED VIEW ━━━${RESET}"
        echo ""
        echo -e "  ${ORANGE}▸▸▸ Total Containers:${RESET}       ${BOLD}${ORANGE}24${RESET} ${TEXT_MUTED}containers${RESET}"
        echo -e "      ${TEXT_MUTED}├─ Running:${RESET}             ${BOLD}${GREEN}22${RESET}"
        echo -e "      ${TEXT_MUTED}├─ Stopped:${RESET}             ${BOLD}${YELLOW}2${RESET}"
        echo -e "      ${TEXT_MUTED}└─ Paused:${RESET}              ${BOLD}${CYAN}0${RESET}"
        echo ""
        echo -e "  ${PINK}▸▸▸ Resource Usage:${RESET}"
        echo -e "      ${TEXT_MUTED}├─ CPU Total:${RESET}           ${BOLD}${ORANGE}42%${RESET} ${ORANGE}████████████${RESET}"
        echo -e "      ${TEXT_MUTED}├─ Memory Total:${RESET}        ${BOLD}${PINK}5.8 GB${RESET} ${PINK}████████████████${RESET}"
        echo -e "      ${TEXT_MUTED}├─ Memory Limit:${RESET}        ${BOLD}${CYAN}12 GB${RESET}"
        echo -e "      ${TEXT_MUTED}└─ Disk I/O:${RESET}            ${BOLD}${PURPLE}847 MB/s${RESET}"
        echo ""
        echo -e "  ${PURPLE}▸▸▸ Network:${RESET}"
        echo -e "      ${TEXT_MUTED}├─ Inbound:${RESET}             ${BOLD}${GREEN}1.2 GB/s${RESET}"
        echo -e "      ${TEXT_MUTED}└─ Outbound:${RESET}            ${BOLD}${ORANGE}847 MB/s${RESET}"
        echo ""
    elif [ $scale_int -le 8 ]; then
        # Zoomed out - compact view
        echo -e "  ${ORANGE}Containers:${RESET} ${BOLD}24${RESET} ${TEXT_MUTED}(22 up)${RESET}  ${PINK}CPU:${RESET} ${BOLD}42%${RESET}  ${PURPLE}RAM:${RESET} ${BOLD}5.8GB${RESET}"
        echo ""
    else
        # Normal view
        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Containers:${RESET}     ${BOLD}${ORANGE}24${RESET} ${TEXT_SECONDARY}containers${RESET}"
        echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Running:${RESET}             ${BOLD}${GREEN}22${RESET}"
        echo -e "  ${YELLOW}◉${RESET} ${TEXT_PRIMARY}Stopped:${RESET}             ${BOLD}${YELLOW}2${RESET}"
        echo ""
        echo -e "  ${BOLD}${TEXT_PRIMARY}Resources:${RESET}"
        echo -e "    ${ORANGE}CPU:${RESET}    ${BOLD}42%${RESET}   ${ORANGE}████████████${RESET}"
        echo -e "    ${PINK}Memory:${RESET} ${BOLD}5.8 GB${RESET} ${PINK}████████████████${RESET}"
        echo ""
    fi
}

# Metrics section (scales bars)
render_metrics_section() {
    local zoom=$1
    local bar_width=$(get_scaled_width 30)

    echo -e "${TEXT_MUTED}╭─ METRICS (Zoom: ${zoom}x) ─────────────────────────────────────────────╮${RESET}"
    echo ""

    # Generate bar based on zoom
    local cpu_bar=""
    local mem_bar=""
    local disk_bar=""

    local cpu_filled=$(echo "$bar_width * 0.42" | bc | cut -d. -f1)
    local mem_filled=$(echo "$bar_width * 0.58" | bc | cut -d. -f1)
    local disk_filled=$(echo "$bar_width * 0.23" | bc | cut -d. -f1)

    for ((i=0; i<cpu_filled; i++)); do cpu_bar="${cpu_bar}█"; done
    for ((i=0; i<mem_filled; i++)); do mem_bar="${mem_bar}█"; done
    for ((i=0; i<disk_filled; i++)); do disk_bar="${disk_bar}█"; done

    echo -e "  ${ORANGE}CPU Usage${RESET}"
    echo -e "    ${ORANGE}${cpu_bar}${RESET}  ${BOLD}42%${RESET}"
    echo ""
    echo -e "  ${PINK}Memory Usage${RESET}"
    echo -e "    ${PINK}${mem_bar}${RESET}  ${BOLD}5.8 GB / 12 GB${RESET}"
    echo ""
    echo -e "  ${PURPLE}Disk I/O${RESET}"
    echo -e "    ${PURPLE}${disk_bar}${RESET}  ${BOLD}847 MB/s${RESET}"
    echo ""
}

# Containers section (shows more/less based on zoom)
render_containers_section() {
    local zoom=$1
    local scale_int=$(echo "$zoom * 10" | bc | cut -d. -f1)

    echo -e "${TEXT_MUTED}╭─ CONTAINERS (Zoom: ${zoom}x) ──────────────────────────────────────────╮${RESET}"
    echo ""

    local containers=("lucidia-earth:3040" "docs-blackroad:3050" "blackroadinc-us:9444" "app-blackroad-io:9445" "postgres:5432" "redis:6379" "nginx:80" "mongodb:27017")
    local count=3

    if [ $scale_int -ge 14 ]; then
        count=8  # Show all
    elif [ $scale_int -le 8 ]; then
        count=2  # Show minimal
    fi

    for ((i=0; i<count && i<${#containers[@]}; i++)); do
        local container=${containers[$i]}
        local name=$(echo "$container" | cut -d: -f1)
        local port=$(echo "$container" | cut -d: -f2)

        if [ $scale_int -ge 14 ]; then
            echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET}"
            echo -e "     ${TEXT_MUTED}Port:${RESET} ${CYAN}$port${RESET}  ${TEXT_MUTED}Status:${RESET} ${GREEN}UP${RESET}  ${TEXT_MUTED}CPU:${RESET} ${BOLD}12%${RESET}  ${TEXT_MUTED}RAM:${RESET} ${BOLD}256MB${RESET}"
            echo ""
        elif [ $scale_int -le 8 ]; then
            echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET} ${TEXT_MUTED}:$port${RESET}"
        else
            echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET}  ${TEXT_MUTED}:$port${RESET}  ${GREEN}UP${RESET}  ${TEXT_SECONDARY}CPU: ${BOLD}12%${RESET}"
        fi
    done

    if [ $count -lt ${#containers[@]} ]; then
        local remaining=$((${#containers[@]} - count))
        echo -e "  ${TEXT_MUTED}+ $remaining more containers...${RESET}"
    fi
    echo ""
}

# Chart section (ASCII charts scale)
render_chart_section() {
    local zoom=$1
    local height=$(get_scaled_width 10)

    [ $height -lt 3 ] && height=3
    [ $height -gt 15 ] && height=15

    echo -e "${TEXT_MUTED}╭─ USAGE CHART (Zoom: ${zoom}x) ─────────────────────────────────────────╮${RESET}"
    echo ""

    local chars="▁▂▃▄▅▆▇█"
    local data=(3 5 4 6 8 7 9 8 6 5 7 8 9 7 6 4 5 6 8 9)

    echo -n "  ${CYAN}CPU:${RESET} "
    for val in "${data[@]}"; do
        local idx=$(echo "$val * $height / 10" | bc)
        [ $idx -ge 8 ] && idx=7
        echo -n "${CYAN}${chars:$idx:1}${RESET}"
    done
    echo ""

    echo -n "  ${PINK}MEM:${RESET} "
    for val in "${data[@]}"; do
        local idx=$(echo "($val + 1) * $height / 10" | bc)
        [ $idx -ge 8 ] && idx=7
        echo -n "${PINK}${chars:$idx:1}${RESET}"
    done
    echo ""
    echo ""
}

# Main demo loop
main() {
    while true; do
        render_zoomed_section "$ZOOM_SECTION"

        read -n1 key

        case "$key" in
            '+')
                zoom_in
                ;;
            '-')
                zoom_out
                ;;
            '0')
                reset_zoom
                ;;
            '1')
                ZOOM_SECTION="overview"
                ;;
            '2')
                ZOOM_SECTION="metrics"
                ;;
            '3')
                ZOOM_SECTION="containers"
                ;;
            '4')
                ZOOM_SECTION="chart"
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye!${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
