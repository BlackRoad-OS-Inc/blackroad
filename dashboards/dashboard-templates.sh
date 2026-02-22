#!/bin/bash

# BlackRoad OS - Dashboard Templates System
# Pre-built templates for common use cases

source ~/blackroad-dashboards/themes.sh
load_theme

TEMPLATES_DIR=~/blackroad-dashboards/templates
USER_DASHBOARDS_DIR=~/blackroad-dashboards/custom

mkdir -p "$TEMPLATES_DIR" "$USER_DASHBOARDS_DIR"

# Template library
declare -A TEMPLATES=(
    ["devops"]="DevOps Monitoring|Full CI/CD pipeline + infrastructure monitoring"
    ["security"]="Security Dashboard|Security events, threats, vulnerabilities"
    ["performance"]="Performance Tracker|App performance metrics and profiling"
    ["analytics"]="Analytics Dashboard|Traffic, conversions, user behavior"
    ["database"]="Database Monitor|DB performance, queries, connections"
    ["api"]="API Dashboard|API health, endpoints, rate limits"
    ["containers"]="Container Fleet|Docker/K8s container management"
    ["logs"]="Log Aggregator|Centralized logging and search"
    ["errors"]="Error Tracking|Error rates, stack traces, alerts"
    ["costs"]="Cost Monitor|Cloud costs and budget tracking"
)

# Show template library
show_template_library() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}📋${RESET} ${BOLD}DASHBOARD TEMPLATES${RESET}                                               ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ AVAILABLE TEMPLATES ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    local idx=1
    for template_id in "${!TEMPLATES[@]}"; do
        local info="${TEMPLATES[$template_id]}"
        local name=$(echo "$info" | cut -d'|' -f1)
        local desc=$(echo "$info" | cut -d'|' -f2)

        # Color based on category
        local color
        case "$template_id" in
            devops|containers) color="${ORANGE}" ;;
            security|errors) color="${RED}" ;;
            performance|database) color="${PURPLE}" ;;
            analytics|api) color="${CYAN}" ;;
            logs|costs) color="${BLUE}" ;;
            *) color="${GREEN}" ;;
        esac

        echo -e "  ${color}${idx})${RESET} ${BOLD}${name}${RESET}"
        echo -e "     ${TEXT_MUTED}${desc}${RESET}"
        echo ""

        ((idx++))
    done
}

# Preview template
preview_template() {
    local template_id=$1
    local info="${TEMPLATES[$template_id]}"
    local name=$(echo "$info" | cut -d'|' -f1)

    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${PURPLE}👁${RESET}  ${BOLD}TEMPLATE PREVIEW: ${name}${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    case "$template_id" in
        "devops")
            echo -e "${TEXT_MUTED}╭─ CI/CD PIPELINE ──────────────────────────────────────────────────────╮${RESET}"
            echo ""
            echo -e "  ${GREEN}✓${RESET} Build    ${TEXT_MUTED}2m 34s${RESET}   ${GREEN}██████████${RESET}           100%"
            echo -e "  ${GREEN}✓${RESET} Test     ${TEXT_MUTED}1m 12s${RESET}   ${GREEN}██████████${RESET}           100%"
            echo -e "  ${ORANGE}●${RESET} Deploy   ${TEXT_MUTED}0m 45s${RESET}   ${ORANGE}███████${RESET}               70%"
            echo ""
            echo -e "${TEXT_MUTED}╭─ INFRASTRUCTURE ──────────────────────────────────────────────────────╮${RESET}"
            echo ""
            echo -e "  ${GREEN}●${RESET} ${BOLD}24${RESET} Containers   ${GREEN}22 running${RESET}, 2 stopped"
            echo -e "  ${GREEN}●${RESET} ${BOLD}5${RESET} Services     All healthy"
            echo -e "  ${GREEN}●${RESET} ${BOLD}12${RESET} Deployments  Last 24h"
            ;;
        "security")
            echo -e "${TEXT_MUTED}╭─ THREAT DETECTION ────────────────────────────────────────────────────╮${RESET}"
            echo ""
            echo -e "  ${GREEN}●${RESET} ${BOLD}0${RESET} Active Threats"
            echo -e "  ${YELLOW}●${RESET} ${BOLD}3${RESET} Suspicious IPs blocked"
            echo -e "  ${RED}●${RESET} ${BOLD}2${RESET} Critical vulnerabilities"
            echo ""
            echo -e "${TEXT_MUTED}╭─ SECURITY SCORE ──────────────────────────────────────────────────────╮${RESET}"
            echo ""
            echo -e "  ${GREEN}████████████████████${RESET}              ${BOLD}${GREEN}98/100${RESET}"
            ;;
        "performance")
            echo -e "${TEXT_MUTED}╭─ RESPONSE TIMES ──────────────────────────────────────────────────────╮${RESET}"
            echo ""
            echo -e "  ${CYAN}API${RESET}      ${GREEN}▁▂▃▄▅▆▇█${RESET}  ${BOLD}23ms${RESET}  ${GREEN}↓ 2ms${RESET}"
            echo -e "  ${PINK}Database${RESET} ${GREEN}▁▂▃▄▅▆▇█${RESET}  ${BOLD}12ms${RESET}  ${GREEN}↓ 1ms${RESET}"
            echo -e "  ${ORANGE}Cache${RESET}    ${GREEN}▁▂▃▄▅▆▇█${RESET}  ${BOLD}2ms${RESET}   ${GREEN}↓ 0ms${RESET}"
            ;;
        "analytics")
            echo -e "${TEXT_MUTED}╭─ TRAFFIC OVERVIEW ────────────────────────────────────────────────────╮${RESET}"
            echo ""
            echo -e "  ${BOLD}${TEXT_PRIMARY}Page Views:${RESET}       ${BOLD}${CYAN}47,234${RESET} ${GREEN}↑ 12%${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Unique Visitors:${RESET}  ${BOLD}${PURPLE}12,847${RESET} ${GREEN}↑ 8%${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Conversion Rate:${RESET}  ${BOLD}${ORANGE}3.42%${RESET} ${RED}↓ 0.3%${RESET}"
            ;;
        *)
            echo -e "${TEXT_MUTED}Preview for $name${RESET}"
            echo ""
            echo -e "  ${GREEN}●${RESET} Sample metric 1"
            echo -e "  ${CYAN}●${RESET} Sample metric 2"
            echo -e "  ${PURPLE}●${RESET} Sample metric 3"
            ;;
    esac

    echo ""
    echo -e "${TEXT_MUTED}╭─ TEMPLATE INFO ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Sections:${RESET}         ${ORANGE}4-6 sections${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Refresh Rate:${RESET}     ${CYAN}2 seconds${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Customizable:${RESET}     ${GREEN}Yes${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Data Sources:${RESET}     ${PURPLE}API, Files, DB${RESET}"
    echo ""

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Create dashboard from template
create_from_template() {
    local template_id=$1
    local custom_name=$2

    if [ -z "$custom_name" ]; then
        custom_name="${template_id}-dashboard-$(date +%Y%m%d_%H%M%S)"
    fi

    local output_file="${USER_DASHBOARDS_DIR}/${custom_name}.sh"

    echo -e "\n${CYAN}Creating dashboard from template...${RESET}\n"

    cat > "$output_file" <<'EOF'
#!/bin/bash

# Custom Dashboard (Generated from Template)
# Created: $(date)

source ~/blackroad-dashboards/themes.sh
load_theme

show_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${ORANGE}📊${RESET} ${BOLD}CUSTOM DASHBOARD${RESET}                                                 ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Add your sections here
    echo -e "${TEXT_MUTED}╭─ SECTION 1 ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} Sample data"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

while true; do
    show_dashboard
    read -n1 -t 5 key
    case "$key" in
        q|Q) exit 0 ;;
    esac
done
EOF

    chmod +x "$output_file"

    echo -e "  ${GREEN}✓${RESET} Dashboard created: ${CYAN}$custom_name${RESET}"
    echo -e "  ${TEXT_MUTED}Location: $output_file${RESET}"
    echo ""
    echo -e "${GREEN}You can now customize the dashboard by editing the file!${RESET}"
    sleep 3
}

# Show user dashboards
show_user_dashboards() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}MY CUSTOM DASHBOARDS${RESET}"
    echo ""

    if ls "$USER_DASHBOARDS_DIR"/*.sh >/dev/null 2>&1; then
        local idx=1
        for dashboard in "$USER_DASHBOARDS_DIR"/*.sh; do
            local name=$(basename "$dashboard" .sh)
            local size=$(du -h "$dashboard" | cut -f1)
            local date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$dashboard" 2>/dev/null || stat -c "%y" "$dashboard" 2>/dev/null | cut -d'.' -f1)

            echo -e "  ${PURPLE}${idx})${RESET} ${BOLD}${name}${RESET}"
            echo -e "     ${TEXT_MUTED}Created: $date  Size: $size${RESET}"
            echo ""

            ((idx++))
        done
    else
        echo -e "  ${TEXT_MUTED}No custom dashboards yet${RESET}"
        echo -e "  ${TEXT_SECONDARY}Create one from a template!${RESET}"
        echo ""
    fi

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Main interface
main() {
    while true; do
        show_template_library

        echo -e "${TEXT_MUTED}╭─ MY DASHBOARDS ───────────────────────────────────────────────────────╮${RESET}"
        echo ""
        local custom_count=$(ls "$USER_DASHBOARDS_DIR"/*.sh 2>/dev/null | wc -l | xargs)
        echo -e "  ${BOLD}${TEXT_PRIMARY}Custom Dashboards:${RESET}  ${BOLD}${ORANGE}${custom_count}${RESET}"
        echo ""

        echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${TEXT_SECONDARY}[1-9]${RESET} Preview  ${TEXT_SECONDARY}[C]${RESET} Create  ${TEXT_SECONDARY}[M]${RESET} My Dashboards  ${TEXT_SECONDARY}[Q]${RESET} Quit"
        echo ""
        echo -ne "${TEXT_PRIMARY}Select option: ${RESET}"

        read -n1 key
        echo ""

        case "$key" in
            1) preview_template "devops" ;;
            2) preview_template "security" ;;
            3) preview_template "performance" ;;
            4) preview_template "analytics" ;;
            5) preview_template "database" ;;
            'c'|'C')
                echo ""
                echo -ne "${TEXT_PRIMARY}Select template (1-5): ${RESET}"
                read -n1 template_num
                echo ""
                echo -ne "${TEXT_PRIMARY}Dashboard name (or press Enter for auto): ${RESET}"
                read custom_name

                case "$template_num" in
                    1) create_from_template "devops" "$custom_name" ;;
                    2) create_from_template "security" "$custom_name" ;;
                    3) create_from_template "performance" "$custom_name" ;;
                    *) echo -e "${YELLOW}Invalid template${RESET}"; sleep 1 ;;
                esac
                ;;
            'm'|'M')
                show_user_dashboards
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
