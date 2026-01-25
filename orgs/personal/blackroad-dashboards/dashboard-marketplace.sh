#!/bin/bash

# BlackRoad OS - Dashboard Marketplace
# Share and download community dashboards

source ~/blackroad-dashboards/themes.sh
load_theme

MARKETPLACE_DIR=~/blackroad-dashboards/marketplace
INSTALLED_DIR=~/blackroad-dashboards/installed
FAVORITES_FILE=~/blackroad-dashboards/.marketplace_favorites

mkdir -p "$MARKETPLACE_DIR" "$INSTALLED_DIR"
touch "$FAVORITES_FILE"

# Dashboard catalog
declare -A DASHBOARDS=(
    ["kubernetes-cluster"]="Kubernetes Cluster|Monitor K8s pods, deployments, services|DevOps|@kubernetes-team|4.8|12.4k|free"
    ["cost-optimizer"]="Cloud Cost Optimizer|Track and optimize cloud spending|Finance|@cloud-team|4.9|8.2k|free"
    ["ml-training"]="ML Training Monitor|Track model training progress|AI/ML|@ml-team|4.7|6.1k|free"
    ["blockchain-wallet"]="Crypto Wallet|Monitor blockchain wallets and transactions|Crypto|@crypto-team|4.6|4.8k|pro"
    ["social-media"]="Social Media Analytics|Track social media metrics|Marketing|@social-team|4.5|3.9k|free"
    ["iot-devices"]="IoT Device Manager|Monitor IoT devices and sensors|IoT|@iot-team|4.8|2.7k|free"
    ["game-server"]="Game Server Monitor|Monitor game server metrics|Gaming|@game-team|4.4|2.1k|free"
    ["stock-trader"]="Stock Trading Dashboard|Real-time stock market data|Finance|@trading-team|4.7|1.8k|pro"
)

# Show marketplace
show_marketplace() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${GOLD}🛍️${RESET}  ${BOLD}DASHBOARD MARKETPLACE${RESET}                                            ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Stats
    echo -e "${TEXT_MUTED}╭─ MARKETPLACE STATS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Dashboards:${RESET}   ${BOLD}${ORANGE}${#DASHBOARDS[@]}${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Downloads:${RESET}    ${BOLD}${CYAN}47.2k${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Rating:${RESET}         ${BOLD}${GOLD}4.7 ⭐${RESET}"
    echo ""

    # Featured dashboards
    echo -e "${TEXT_MUTED}╭─ FEATURED DASHBOARDS ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    local idx=1
    for dashboard_id in "${!DASHBOARDS[@]}"; do
        local info="${DASHBOARDS[$dashboard_id]}"
        IFS='|' read -r name desc category author rating downloads price <<< "$info"

        # Color by category
        local cat_color
        case "$category" in
            DevOps) cat_color="${ORANGE}" ;;
            Finance|Crypto) cat_color="${GOLD}" ;;
            AI/ML) cat_color="${PURPLE}" ;;
            Marketing) cat_color="${PINK}" ;;
            IoT) cat_color="${BLUE}" ;;
            Gaming) cat_color="${GREEN}" ;;
            *) cat_color="${CYAN}" ;;
        esac

        # Price badge
        local price_badge
        if [ "$price" = "free" ]; then
            price_badge="${GREEN}FREE${RESET}"
        else
            price_badge="${GOLD}PRO${RESET}"
        fi

        echo -e "  ${cat_color}${idx})${RESET} ${BOLD}$name${RESET}  $price_badge"
        echo -e "     ${TEXT_MUTED}$desc${RESET}"
        echo -e "     ${TEXT_SECONDARY}Category:${RESET} $category  ${TEXT_SECONDARY}By:${RESET} $author"
        echo -e "     ${GOLD}$rating ⭐${RESET}  ${TEXT_MUTED}$downloads downloads${RESET}"
        echo ""

        ((idx++))
    done
}

# Show dashboard details
show_dashboard_details() {
    local dashboard_id=$1
    local info="${DASHBOARDS[$dashboard_id]}"
    IFS='|' read -r name desc category author rating downloads price <<< "$info"

    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${PURPLE}📊${RESET} ${BOLD}${name}${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ OVERVIEW ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Description:${RESET}"
    echo -e "    $desc"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Category:${RESET}       $category"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Author:${RESET}         $author"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Rating:${RESET}         ${GOLD}$rating ⭐${RESET} ${TEXT_MUTED}(847 reviews)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Downloads:${RESET}      ${downloads}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Price:${RESET}          $([ "$price" = "free" ] && echo "${GREEN}FREE${RESET}" || echo "${GOLD}PRO - \$9.99/mo${RESET}")"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Version:${RESET}        ${CYAN}2.1.0${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Updated:${RESET}        ${TEXT_MUTED}2 days ago${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ FEATURES ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} Real-time data updates"
    echo -e "  ${GREEN}✓${RESET} Customizable themes"
    echo -e "  ${GREEN}✓${RESET} Export to CSV/JSON"
    echo -e "  ${GREEN}✓${RESET} Alert notifications"
    echo -e "  ${GREEN}✓${RESET} Mobile responsive"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SCREENSHOTS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮${RESET}  ${ORANGE}▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮${RESET}  ${CYAN}▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮${RESET}"
    echo -e "  ${PURPLE}▮ Dashboard   ▮${RESET}  ${ORANGE}▮ Charts      ▮${RESET}  ${CYAN}▮ Alerts     ▮${RESET}"
    echo -e "  ${PURPLE}▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮${RESET}  ${ORANGE}▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮${RESET}  ${CYAN}▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮▮${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ REVIEWS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GOLD}⭐⭐⭐⭐⭐${RESET} ${BOLD}Amazing dashboard!${RESET}"
    echo -e "  ${TEXT_MUTED}By @user123 • 1 week ago${RESET}"
    echo -e "  ${TEXT_SECONDARY}Perfect for monitoring my K8s cluster. Highly recommended!${RESET}"
    echo ""
    echo -e "  ${GOLD}⭐⭐⭐⭐☆${RESET} ${BOLD}Great but could use more features${RESET}"
    echo -e "  ${TEXT_MUTED}By @devops456 • 2 weeks ago${RESET}"
    echo -e "  ${TEXT_SECONDARY}Works well, would love to see cost predictions added.${RESET}"
    echo ""

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Install dashboard
install_dashboard() {
    local dashboard_id=$1
    local info="${DASHBOARDS[$dashboard_id]}"
    IFS='|' read -r name desc category author rating downloads price <<< "$info"

    echo -e "\n${CYAN}Installing dashboard: ${BOLD}$name${RESET}\n"

    # Simulate download
    for ((i=0; i<=100; i+=10)); do
        echo -ne "\r  ${ORANGE}Downloading...${RESET} "
        local filled=$((i / 2))
        for ((j=0; j<50; j++)); do
            [ "$j" -lt "$filled" ] && echo -ne "${GREEN}█${RESET}" || echo -ne "${TEXT_MUTED}░${RESET}"
        done
        echo -ne " ${BOLD}$i%${RESET}  "
        sleep 0.1
    done

    echo -e "\n\n  ${GREEN}✓${RESET} Dashboard installed successfully!"
    echo -e "  ${TEXT_MUTED}Location: $INSTALLED_DIR/${dashboard_id}.sh${RESET}"
    echo ""

    # Create simple placeholder
    cat > "$INSTALLED_DIR/${dashboard_id}.sh" <<EOF
#!/bin/bash
echo "Dashboard: $name"
echo "From: BlackRoad Marketplace"
EOF
    chmod +x "$INSTALLED_DIR/${dashboard_id}.sh"

    sleep 2
}

# Show installed dashboards
show_installed() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}INSTALLED DASHBOARDS${RESET}"
    echo ""

    if ls "$INSTALLED_DIR"/*.sh >/dev/null 2>&1; then
        local idx=1
        for dashboard in "$INSTALLED_DIR"/*.sh; do
            local name=$(basename "$dashboard" .sh)
            echo -e "  ${GREEN}${idx})${RESET} ${BOLD}$name${RESET}"
            ((idx++))
        done
    else
        echo -e "  ${TEXT_MUTED}No dashboards installed yet${RESET}"
    fi

    echo ""
    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Main loop
main() {
    while true; do
        show_marketplace

        echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${TEXT_SECONDARY}[1-8]${RESET} View details  ${TEXT_SECONDARY}[I]${RESET} Install  ${TEXT_SECONDARY}[M]${RESET} My Dashboards  ${TEXT_SECONDARY}[Q]${RESET} Quit"
        echo ""
        echo -ne "${TEXT_PRIMARY}Select option: ${RESET}"

        read -n1 key
        echo ""

        case "$key" in
            1) show_dashboard_details "kubernetes-cluster" ;;
            2) show_dashboard_details "cost-optimizer" ;;
            3) show_dashboard_details "ml-training" ;;
            'i'|'I')
                echo ""
                echo -ne "${TEXT_PRIMARY}Dashboard number to install (1-8): ${RESET}"
                read -n1 num
                case "$num" in
                    1) install_dashboard "kubernetes-cluster" ;;
                    2) install_dashboard "cost-optimizer" ;;
                    *) echo -e "\n${YELLOW}Invalid selection${RESET}"; sleep 1 ;;
                esac
                ;;
            'm'|'M')
                show_installed
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
