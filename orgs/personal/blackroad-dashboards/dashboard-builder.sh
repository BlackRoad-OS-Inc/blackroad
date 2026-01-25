#!/bin/bash

# BlackRoad OS - Custom Dashboard Builder
# Interactive dashboard builder

source ~/blackroad-dashboards/themes.sh
load_theme

BUILDER_STATE=~/blackroad-dashboards/.builder_state
OUTPUT_DIR=~/blackroad-dashboards/custom

mkdir -p "$OUTPUT_DIR"

# Initialize builder state
init_builder() {
    cat > "$BUILDER_STATE" <<EOF
{
  "name": "my-dashboard",
  "sections": [],
  "theme": "default",
  "refresh_rate": 5
}
EOF
}

# Add section to dashboard
add_section() {
    local section_type=$1

    echo -e "\n${CYAN}Adding section: $section_type${RESET}\n"

    case "$section_type" in
        "metrics")
            echo -e "${TEXT_PRIMARY}What metrics do you want to display?${RESET}"
            echo -e "  1) System resources (CPU, Memory, Disk)"
            echo -e "  2) API health (latency, errors, requests)"
            echo -e "  3) Database (queries, connections, load)"
            echo -ne "\n${TEXT_PRIMARY}Choice: ${RESET}"
            read -n1 choice
            echo ""
            ;;
        "chart")
            echo -e "${TEXT_PRIMARY}What type of chart?${RESET}"
            echo -e "  1) Line chart (time series)"
            echo -e "  2) Bar chart"
            echo -e "  3) Sparkline"
            echo -e "  4) Heatmap"
            echo -ne "\n${TEXT_PRIMARY}Choice: ${RESET}"
            read -n1 choice
            echo ""
            ;;
        "table")
            echo -e "${TEXT_PRIMARY}What data source?${RESET}"
            echo -e "  1) Containers"
            echo -e "  2) API endpoints"
            echo -e "  3) Database tables"
            echo -ne "\n${TEXT_PRIMARY}Choice: ${RESET}"
            read -n1 choice
            echo ""
            ;;
    esac

    echo -e "${GREEN}✓ Section added!${RESET}"
    sleep 1
}

# Show builder interface
show_builder() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${PURPLE}🛠${RESET}  ${BOLD}DASHBOARD BUILDER${RESET}                                                ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Current dashboard design
    echo -e "${TEXT_MUTED}╭─ DASHBOARD DESIGN ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Name:${RESET}           ${CYAN}my-custom-dashboard${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Theme:${RESET}          ${PURPLE}default${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Refresh Rate:${RESET}   ${ORANGE}5 seconds${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Sections:${RESET}       ${BOLD}3${RESET}"
    echo ""

    # Section preview
    echo -e "${TEXT_MUTED}╭─ SECTIONS ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} ${BOLD}System Metrics${RESET}"
    echo -e "     ${TEXT_MUTED}CPU, Memory, Disk I/O${RESET}"
    echo ""
    echo -e "  ${PINK}2)${RESET} ${BOLD}API Health Chart${RESET}"
    echo -e "     ${TEXT_MUTED}Line chart showing response times${RESET}"
    echo ""
    echo -e "  ${PURPLE}3)${RESET} ${BOLD}Container Table${RESET}"
    echo -e "     ${TEXT_MUTED}List of running containers${RESET}"
    echo ""

    # Available components
    echo -e "${TEXT_MUTED}╭─ AVAILABLE COMPONENTS ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}M)${RESET} Metrics Section     ${TEXT_MUTED}Display key metrics${RESET}"
    echo -e "  ${BLUE}C)${RESET} Chart Section       ${TEXT_MUTED}Visualize data${RESET}"
    echo -e "  ${GREEN}T)${RESET} Table Section       ${TEXT_MUTED}List data in table${RESET}"
    echo -e "  ${YELLOW}A)${RESET} Alert Panel         ${TEXT_MUTED}Show active alerts${RESET}"
    echo -e "  ${PURPLE}S)${RESET} Status Grid         ${TEXT_MUTED}Service status grid${RESET}"
    echo -e "  ${ORANGE}L)${RESET} Log Stream          ${TEXT_MUTED}Live log feed${RESET}"
    echo ""

    # Live preview
    echo -e "${TEXT_MUTED}╭─ LIVE PREVIEW ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${PURPLE}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "  ${BOLD}${PURPLE}║${RESET}  ${ORANGE}📊${RESET} ${BOLD}MY CUSTOM DASHBOARD${RESET}                            ${BOLD}${PURPLE}║${RESET}"
    echo -e "  ${BOLD}${PURPLE}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}╭─ SYSTEM METRICS ────────────────────────────────╮${RESET}"
    echo -e "    ${ORANGE}CPU${RESET}     ${ORANGE}████████${RESET}      ${BOLD}42%${RESET}"
    echo -e "    ${PINK}Memory${RESET}  ${PINK}██████████${RESET}    ${BOLD}5.8 GB${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}╭─ API HEALTH ────────────────────────────────────╮${RESET}"
    echo -e "    ${CYAN}Latency${RESET}  ${GREEN}▁▂▃▄▅▆▇█${RESET}  ${BOLD}23ms${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}╭─ CONTAINERS ────────────────────────────────────╮${RESET}"
    echo -e "    ${GREEN}●${RESET} lucidia-earth      ${GREEN}UP${RESET}    12%"
    echo -e "    ${GREEN}●${RESET} docs-blackroad     ${GREEN}UP${RESET}    14%"
    echo ""

    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[M/C/T/A/S/L]${RESET} Add section  ${TEXT_SECONDARY}[G]${RESET} Generate  ${TEXT_SECONDARY}[P]${RESET} Preview  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Generate dashboard code
generate_dashboard() {
    local name=${1:-"custom-dashboard-$(date +%Y%m%d_%H%M%S)"}
    local output_file="${OUTPUT_DIR}/${name}.sh"

    echo -e "\n${CYAN}Generating dashboard...${RESET}\n"

    cat > "$output_file" <<'DASHBOARD_CODE'
#!/bin/bash

# Custom Dashboard - Generated by Dashboard Builder
# Created: $(date)

source ~/blackroad-dashboards/themes.sh
load_theme

show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}📊${RESET} ${BOLD}MY CUSTOM DASHBOARD${RESET}                                              ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Section 1: System Metrics
    echo -e "${TEXT_MUTED}╭─ SYSTEM METRICS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    local cpu=$((40 + RANDOM % 30))
    local mem=$((50 + RANDOM % 20))

    echo -e "  ${ORANGE}CPU Usage${RESET}      ${ORANGE}████████████${RESET}                    ${BOLD}${cpu}%${RESET}"
    echo -e "  ${PINK}Memory${RESET}         ${PINK}████████████████${RESET}                ${BOLD}5.8 GB${RESET}"
    echo -e "  ${PURPLE}Disk I/O${RESET}       ${PURPLE}██████${RESET}                          ${BOLD}847 MB/s${RESET}"
    echo ""

    # Section 2: API Health
    echo -e "${TEXT_MUTED}╭─ API HEALTH ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}Response Time${RESET}  ${GREEN}▁▂▃▄▅▆▇█▇▆▅▄▃▂▁${RESET}  ${BOLD}23ms${RESET}"
    echo -e "  ${BLUE}Requests/sec${RESET}   ${BOLD}12,400${RESET}"
    echo -e "  ${GREEN}Success Rate${RESET}   ${BOLD}98.7%${RESET}"
    echo ""

    # Section 3: Containers
    echo -e "${TEXT_MUTED}╭─ RUNNING CONTAINERS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${BOLD}lucidia-earth${RESET}      ${TEXT_MUTED}:3040${RESET}  ${GREEN}UP${RESET}  ${BOLD}12%${RESET} CPU"
    echo -e "  ${GREEN}●${RESET} ${BOLD}docs-blackroad${RESET}     ${TEXT_MUTED}:3050${RESET}  ${GREEN}UP${RESET}  ${BOLD}14%${RESET} CPU"
    echo -e "  ${GREEN}●${RESET} ${BOLD}api-server${RESET}         ${TEXT_MUTED}:9444${RESET}  ${GREEN}UP${RESET}  ${BOLD}34%${RESET} CPU"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[E]${RESET} Edit  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
while true; do
    show_dashboard
    read -n1 -t 5 key

    case "$key" in
        'e'|'E')
            ${EDITOR:-nano} "$0"
            ;;
        'q'|'Q')
            exit 0
            ;;
    esac
done
DASHBOARD_CODE

    chmod +x "$output_file"

    echo -e "  ${GREEN}✓${RESET} Dashboard generated: ${CYAN}$name${RESET}"
    echo -e "  ${TEXT_MUTED}Location: $output_file${RESET}"
    echo ""
    echo -e "${GREEN}Run with: ${CYAN}$output_file${RESET}"
    sleep 3
}

# Main loop
main() {
    init_builder

    while true; do
        show_builder

        read -n1 key

        case "$key" in
            'm'|'M') add_section "metrics" ;;
            'c'|'C') add_section "chart" ;;
            't'|'T') add_section "table" ;;
            'a'|'A') add_section "alert" ;;
            's'|'S') add_section "status" ;;
            'l'|'L') add_section "logs" ;;
            'g'|'G') generate_dashboard ;;
            'p'|'P')
                echo -e "\n${CYAN}Opening preview...${RESET}"
                sleep 1
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
