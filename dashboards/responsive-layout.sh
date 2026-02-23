#!/bin/bash

# BlackRoad OS - Responsive Layout System
# Auto-adjust dashboard layout based on terminal size

source ~/blackroad-dashboards/themes.sh
load_theme

# Get terminal dimensions
get_terminal_size() {
    TERM_WIDTH=$(tput cols)
    TERM_HEIGHT=$(tput lines)
}

# Determine layout mode based on screen size
get_layout_mode() {
    get_terminal_size

    if [ "$TERM_WIDTH" -ge 160 ]; then
        echo "ultra-wide"  # 3-column layout
    elif [ "$TERM_WIDTH" -ge 120 ]; then
        echo "wide"        # 2-column layout
    elif [ "$TERM_WIDTH" -ge 80 ]; then
        echo "normal"      # Single column, full features
    elif [ "$TERM_WIDTH" -ge 60 ]; then
        echo "compact"     # Single column, condensed
    else
        echo "minimal"     # Bare minimum
    fi
}

# Render header based on layout
render_header() {
    local mode=$1

    case "$mode" in
        "ultra-wide"|"wide"|"normal")
            echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}📐${RESET} ${BOLD}RESPONSIVE LAYOUT${RESET} ${TEXT_MUTED}[$mode - ${TERM_WIDTH}x${TERM_HEIGHT}]${RESET}"
            echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
            ;;
        "compact")
            echo -e "${BOLD}${PURPLE}╔══════════════════════════════════════════════════════╗${RESET}"
            echo -e "${BOLD}${PURPLE}║${RESET} ${ORANGE}📐${RESET} ${BOLD}RESPONSIVE${RESET} ${TEXT_MUTED}[$mode]${RESET}"
            echo -e "${BOLD}${PURPLE}╚══════════════════════════════════════════════════════╝${RESET}"
            ;;
        "minimal")
            echo -e "${BOLD}${PURPLE}═══════════════════════════════════════${RESET}"
            echo -e "${ORANGE}📐${RESET} ${BOLD}RESPONSIVE${RESET} ${TEXT_MUTED}[min]${RESET}"
            echo -e "${BOLD}${PURPLE}═══════════════════════════════════════${RESET}"
            ;;
    esac
    echo ""
}

# Render dashboard in ultra-wide mode (3 columns)
render_ultra_wide() {
    echo -e "${TEXT_MUTED}╭─ COLUMN 1: OVERVIEW ────────╭─ COLUMN 2: METRICS ─────────╭─ COLUMN 3: ALERTS ──────────╮${RESET}"
    echo ""

    # Row 1
    printf "  %-28s  %-28s  %-28s\n" "${BOLD}${TEXT_PRIMARY}System Status${RESET}" "${BOLD}${TEXT_PRIMARY}CPU Usage${RESET}" "${BOLD}${TEXT_PRIMARY}Active Alerts${RESET}"
    printf "  %-28s  %-28s  %-28s\n" "${GREEN}● ONLINE${RESET}" "${ORANGE}42%${RESET} ${ORANGE}████████${RESET}" "${RED}● 2 CRITICAL${RESET}"
    echo ""

    # Row 2
    printf "  %-28s  %-28s  %-28s\n" "${BOLD}${TEXT_PRIMARY}Containers${RESET}" "${BOLD}${TEXT_PRIMARY}Memory${RESET}" "${BOLD}${TEXT_PRIMARY}Latest Alert${RESET}"
    printf "  %-28s  %-28s  %-28s\n" "${BOLD}${ORANGE}24${RESET} (22 running)" "${PINK}5.8 GB${RESET} ${PINK}████████${RESET}" "${YELLOW}API slow${RESET}"
    echo ""

    # Row 3
    printf "  %-28s  %-28s  %-28s\n" "${BOLD}${TEXT_PRIMARY}API Health${RESET}" "${BOLD}${TEXT_PRIMARY}Disk I/O${RESET}" "${BOLD}${TEXT_PRIMARY}Predictions${RESET}"
    printf "  %-28s  %-28s  %-28s\n" "${GREEN}98.7% uptime${RESET}" "${PURPLE}847 MB/s${RESET}" "${ORANGE}3 warnings${RESET}"
    echo ""
}

# Render dashboard in wide mode (2 columns)
render_wide() {
    echo -e "${TEXT_MUTED}╭─ OVERVIEW & METRICS ─────────────────────╭─ ALERTS & STATUS ───────────────────────╮${RESET}"
    echo ""

    printf "  %-43s  %-43s\n" "${BOLD}${TEXT_PRIMARY}System Status:${RESET} ${GREEN}ONLINE${RESET}" "${BOLD}${TEXT_PRIMARY}Active Alerts:${RESET} ${RED}2 CRITICAL${RESET}"
    printf "  %-43s  %-43s\n" "${BOLD}${TEXT_PRIMARY}Containers:${RESET} ${BOLD}${ORANGE}24${RESET} (22 up)" "${BOLD}${TEXT_PRIMARY}Latest:${RESET} ${YELLOW}API response slow${RESET}"
    echo ""

    printf "  %-43s  %-43s\n" "${ORANGE}CPU${RESET}   ${ORANGE}████████${RESET}    ${BOLD}42%${RESET}" "${BOLD}${TEXT_PRIMARY}Predictions:${RESET}"
    printf "  %-43s  %-43s\n" "${PINK}Memory${RESET} ${PINK}████████${RESET}    ${BOLD}5.8 GB${RESET}" "${ORANGE}●${RESET} Memory will hit 90% in 3.2h"
    printf "  %-43s  %-43s\n" "${PURPLE}Disk${RESET}   ${PURPLE}████${RESET}        ${BOLD}847 MB/s${RESET}" "${ORANGE}●${RESET} API will hit 500ms in 8min"
    echo ""
}

# Render dashboard in normal mode (single column, full)
render_normal() {
    echo -e "${TEXT_MUTED}╭─ SYSTEM OVERVIEW ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}System Status:${RESET}        ${GREEN}${BOLD}ONLINE${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Containers:${RESET}     ${BOLD}${ORANGE}24${RESET} ${TEXT_SECONDARY}(22 running, 2 stopped)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}API Health:${RESET}           ${GREEN}98.7% uptime${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ RESOURCE USAGE ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}CPU Usage${RESET}      ${ORANGE}████████████${RESET}                    ${BOLD}42%${RESET}"
    echo -e "  ${PINK}Memory${RESET}         ${PINK}████████████████${RESET}                ${BOLD}5.8 GB / 12 GB${RESET}"
    echo -e "  ${PURPLE}Disk I/O${RESET}       ${PURPLE}██████${RESET}                          ${BOLD}847 MB/s${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ACTIVE ALERTS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}🚨${RESET} ${BOLD}API Response Time Spike${RESET}"
    echo -e "     ${TEXT_SECONDARY}Current: ${RED}234ms${RESET} (baseline: ${GREEN}23ms${RESET})"
    echo ""
    echo -e "  ${YELLOW}⚠️${RESET}  ${BOLD}Memory Growth Pattern${RESET}"
    echo -e "     ${TEXT_SECONDARY}Growing at ${ORANGE}50MB/hour${RESET}"
    echo ""
}

# Render dashboard in compact mode (condensed)
render_compact() {
    echo -e "${TEXT_MUTED}╭─ OVERVIEW ────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${TEXT_PRIMARY}Status:${RESET} ${GREEN}ONLINE${RESET}  ${TEXT_PRIMARY}Containers:${RESET} ${ORANGE}24${RESET}"
    echo -e "  ${TEXT_PRIMARY}CPU:${RESET} ${BOLD}42%${RESET}  ${TEXT_PRIMARY}RAM:${RESET} ${BOLD}5.8GB${RESET}  ${TEXT_PRIMARY}Disk:${RESET} ${BOLD}847MB/s${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ALERTS ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${RED}●${RESET} API slow (234ms)"
    echo -e "  ${YELLOW}●${RESET} Memory growing (50MB/h)"
    echo ""
}

# Render dashboard in minimal mode (bare minimum)
render_minimal() {
    echo -e "${TEXT_PRIMARY}Status:${RESET} ${GREEN}OK${RESET}"
    echo -e "${TEXT_PRIMARY}CPU:${RESET} ${BOLD}42%${RESET}  ${TEXT_PRIMARY}RAM:${RESET} ${BOLD}5.8GB${RESET}"
    echo -e "${RED}Alerts:${RESET} ${BOLD}2${RESET}"
    echo ""
}

# Show layout comparison
show_layout_comparison() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${ORANGE}📐${RESET} ${BOLD}RESPONSIVE LAYOUT DEMONSTRATION${RESET}                                   ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}Current Terminal Size: ${BOLD}${TERM_WIDTH}x${TERM_HEIGHT}${RESET}"
    echo -e "${TEXT_MUTED}Current Layout Mode: ${BOLD}${CYAN}$(get_layout_mode)${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ LAYOUT BREAKPOINTS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Ultra-Wide${RESET}  ${TEXT_MUTED}(≥160 cols)${RESET}  3-column layout, maximum info"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Wide${RESET}        ${TEXT_MUTED}(≥120 cols)${RESET}  2-column layout, full features"
    echo -e "  ${CYAN}●${RESET} ${BOLD}Normal${RESET}      ${TEXT_MUTED}(≥80 cols)${RESET}   Single column, all features"
    echo -e "  ${YELLOW}●${RESET} ${BOLD}Compact${RESET}     ${TEXT_MUTED}(≥60 cols)${RESET}   Single column, condensed"
    echo -e "  ${ORANGE}●${RESET} ${BOLD}Minimal${RESET}     ${TEXT_MUTED}(<60 cols)${RESET}   Bare essentials only"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ADAPTIVE FEATURES ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} Auto-detect terminal size on every render"
    echo -e "  ${GREEN}✓${RESET} Responsive column layouts (1-3 columns)"
    echo -e "  ${GREEN}✓${RESET} Adaptive text length and detail level"
    echo -e "  ${GREEN}✓${RESET} Progressive disclosure (hide less important info)"
    echo -e "  ${GREEN}✓${RESET} Bar chart width scaling"
    echo -e "  ${GREEN}✓${RESET} Border style adjustment"
    echo -e "  ${GREEN}✓${RESET} Real-time layout switching on resize"
    echo ""

    echo -e "${TEXT_MUTED}╭─ CURRENT LAYOUT PREVIEW ──────────────────────────────────────────────╮${RESET}"
    echo ""
}

# Main demo
main() {
    while true; do
        get_terminal_size
        local mode=$(get_layout_mode)

        clear
        echo ""
        render_header "$mode"

        case "$mode" in
            "ultra-wide")
                render_ultra_wide
                ;;
            "wide")
                render_wide
                ;;
            "normal")
                render_normal
                ;;
            "compact")
                render_compact
                ;;
            "minimal")
                render_minimal
                ;;
        esac

        echo -e "${TEXT_MUTED}╭─ RESPONSIVE INFO ─────────────────────────────────────────────────────╮${RESET}"
        echo ""
        echo -e "  ${BOLD}${TEXT_PRIMARY}Terminal Size:${RESET}    ${BOLD}${CYAN}${TERM_WIDTH}x${TERM_HEIGHT}${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Layout Mode:${RESET}      ${BOLD}${PURPLE}$mode${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Columns:${RESET}          ${BOLD}${ORANGE}$([ "$mode" = "ultra-wide" ] && echo "3" || [ "$mode" = "wide" ] && echo "2" || echo "1")${RESET}"
        echo -e "  ${TEXT_SECONDARY}Resize your terminal to see different layouts!${RESET}"
        echo ""

        echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${TEXT_SECONDARY}[C]${RESET} Compare all  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[Q]${RESET} Quit"
        echo -e "  ${TEXT_MUTED}Auto-refresh in 5 seconds...${RESET}"
        echo ""

        read -n1 -t 5 key

        case "$key" in
            'c'|'C')
                show_layout_comparison
                case "$(get_layout_mode)" in
                    "ultra-wide") render_ultra_wide ;;
                    "wide") render_wide ;;
                    "normal") render_normal ;;
                    "compact") render_compact ;;
                    "minimal") render_minimal ;;
                esac
                echo ""
                echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
                read -n1
                ;;
            'r'|'R')
                continue
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
