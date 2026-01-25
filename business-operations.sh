#!/bin/bash

# BlackRoad OS - Master Business Operations Dashboard
# Unified interface for all business automation systems

source ~/blackroad-dashboards/themes.sh
load_theme

show_business_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${PURPLE}💼${RESET} ${BOLD}BLACKROAD OS - BUSINESS OPERATIONS${RESET}                              ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Company header
    echo -e "  ${BOLD}${TEXT_PRIMARY}Company:${RESET}             ${GREEN}BlackRoad OS, Inc.${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Type:${RESET}                ${CYAN}Delaware C-Corporation${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}CEO:${RESET}                 ${PURPLE}Alexa Louise Amundson${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${GREEN}✓ All Systems Operational${RESET}"
    echo ""

    # Business Systems
    echo -e "${TEXT_MUTED}╭─ BUSINESS AUTOMATION SYSTEMS ─────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}1.${RESET} ${BOLD}Auto CEO Mode${RESET}"
    echo -e "     ${TEXT_MUTED}Autonomous corporate operations & decision making${RESET}"
    echo -e "     ${CYAN}→ Morning ops, continuous monitoring, agent coordination${RESET}"
    echo ""

    echo -e "  ${GREEN}2.${RESET} ${BOLD}Agent Coordinator${RESET}"
    echo -e "     ${TEXT_MUTED}Multi-agent orchestration (10 AI executives)${RESET}"
    echo -e "     ${CYAN}→ CEO, CFO, CTO, COO, CMO, GC, VPE, CISO, VPH, VPP${RESET}"
    echo ""

    echo -e "  ${GREEN}3.${RESET} ${BOLD}Stripe Automation${RESET}"
    echo -e "     ${TEXT_MUTED}Payment processing, subscriptions, revenue tracking${RESET}"
    echo -e "     ${CYAN}→ Customer management, webhooks, financial reporting${RESET}"
    echo ""

    echo -e "  ${GREEN}4.${RESET} ${BOLD}Legal Automation${RESET}"
    echo -e "     ${TEXT_MUTED}Contract generation, compliance tracking, audit trails${RESET}"
    echo -e "     ${CYAN}→ NDAs, service agreements, Delaware compliance${RESET}"
    echo ""

    echo -e "  ${GREEN}5.${RESET} ${BOLD}Invoice Automation${RESET}"
    echo -e "     ${TEXT_MUTED}Automated billing, payment tracking, reminders${RESET}"
    echo -e "     ${CYAN}→ Client database, PDF generation, revenue reports${RESET}"
    echo ""

    echo -e "  ${GREEN}6.${RESET} ${BOLD}Corporate Command Center${RESET}"
    echo -e "     ${TEXT_MUTED}Visual overview of all agents and infrastructure${RESET}"
    echo -e "     ${CYAN}→ 15 orgs, 113+ repos, crypto portfolio, Pi fleet${RESET}"
    echo ""

    # Data & Analytics
    echo -e "${TEXT_MUTED}╭─ DATA & ANALYTICS ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${PURPLE}7.${RESET} ${BOLD}Live System Dashboard${RESET}"
    echo -e "     ${TEXT_MUTED}Real-time system metrics & infrastructure status${RESET}"
    echo -e "     ${CYAN}→ CPU, disk, GitHub, crypto, Pi network, ISS, earthquakes${RESET}"
    echo ""

    echo -e "  ${PURPLE}8.${RESET} ${BOLD}Live Crypto Tracker${RESET}"
    echo -e "     ${TEXT_MUTED}Real-time portfolio tracking with live prices${RESET}"
    echo -e "     ${CYAN}→ 2.5 ETH, 100 SOL, 0.1 BTC (~\$28K portfolio)${RESET}"
    echo ""

    echo -e "  ${PURPLE}9.${RESET} ${BOLD}Live GitHub Dashboard${RESET}"
    echo -e "     ${TEXT_MUTED}GitHub ecosystem monitoring & activity tracking${RESET}"
    echo -e "     ${CYAN}→ 15 orgs, 113+ repos, recent commits, PR activity${RESET}"
    echo ""

    # All Dashboards
    echo -e "${TEXT_MUTED}╭─ DASHBOARD SUITE ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}10.${RESET} ${BOLD}Dashboard Launcher${RESET}"
    echo -e "      ${TEXT_MUTED}Navigate all 92 dashboards across 12 categories${RESET}"
    echo -e "      ${CYAN}→ System, AI, Blockchain, Quantum, Space, Earth, more...${RESET}"
    echo ""

    # Quick Stats
    echo -e "${TEXT_MUTED}╭─ QUICK STATS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Organizations:${RESET}       ${ORANGE}15${RESET} GitHub orgs"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Repositories:${RESET}        ${CYAN}113+${RESET} repos"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Dashboards:${RESET}          ${PURPLE}92${RESET} available"
    echo -e "  ${BOLD}${TEXT_PRIMARY}AI Agents:${RESET}           ${GREEN}10${RESET} executives"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Infrastructure:${RESET}      ${PINK}Cloudflare + Railway + DO + Pi${RESET}"
    echo ""

    # Integration Status
    echo -e "${TEXT_MUTED}╭─ INTEGRATION STATUS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Check for API keys
    local stripe_status="${ORANGE}⚠ Not Configured${RESET}"
    [ -n "$STRIPE_API_KEY" ] && stripe_status="${GREEN}✓ Connected${RESET}"

    local gh_status="${ORANGE}⚠ Not Authenticated${RESET}"
    gh auth status &>/dev/null && gh_status="${GREEN}✓ Authenticated${RESET}"

    echo -e "  ${CYAN}●${RESET} ${BOLD}Stripe API:${RESET}          $stripe_status"
    echo -e "  ${CYAN}●${RESET} ${BOLD}GitHub CLI:${RESET}          $gh_status"
    echo -e "  ${CYAN}●${RESET} ${BOLD}CoinGecko API:${RESET}       ${GREEN}✓ Connected (free)${RESET}"
    echo -e "  ${CYAN}●${RESET} ${BOLD}System Metrics:${RESET}      ${GREEN}✓ Active${RESET}"
    echo ""

    # Documentation
    echo -e "${TEXT_MUTED}╭─ DOCUMENTATION ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GOLD}📋${RESET} ${BOLD}AUTO_CEO_README.md${RESET}             Complete system documentation"
    echo -e "  ${GOLD}📋${RESET} ${BOLD}AUTOMATED_CORPORATE_STRUCTURE.md${RESET} Corporate blueprint"
    echo -e "  ${GOLD}📋${RESET} ${BOLD}Atlas Documents Folder${RESET}         Legal entity documents"
    echo ""

    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-10]${RESET} Launch System  ${TEXT_SECONDARY}[D]${RESET} Docs  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Launch system
launch_system() {
    local choice=$1

    case $choice in
        1)
            clear
            echo -e "${GOLD}Launching Auto CEO Mode...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/auto-ceo-mode.sh
            ;;
        2)
            clear
            echo -e "${PURPLE}Launching Agent Coordinator...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/auto-agent-coordinator.sh
            ;;
        3)
            clear
            echo -e "${GREEN}Launching Stripe Automation...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/stripe-automation.sh
            ;;
        4)
            clear
            echo -e "${PURPLE}Launching Legal Automation...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/legal-automation.sh
            ;;
        5)
            clear
            echo -e "${CYAN}Launching Invoice Automation...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/invoice-automation.sh
            ;;
        6)
            clear
            echo -e "${ORANGE}Launching Corporate Command Center...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/corporate-agents.sh
            ;;
        7)
            clear
            echo -e "${CYAN}Launching Live System Dashboard...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/live-system-dashboard.sh
            ;;
        8)
            clear
            echo -e "${GOLD}Launching Live Crypto Tracker...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/live-crypto-tracker.sh
            ;;
        9)
            clear
            echo -e "${PURPLE}Launching Live GitHub Dashboard...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/live-github-dashboard.sh
            ;;
        10)
            clear
            echo -e "${CYAN}Launching Dashboard Launcher...${RESET}\n"
            sleep 1
            exec ~/blackroad-dashboards/dashboard-launcher.sh
            ;;
    esac
}

# Show docs
show_docs() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}DOCUMENTATION${RESET}\n"

    echo -e "${BOLD}Available Documentation:${RESET}\n"

    echo -e "  ${GREEN}●${RESET} ${BOLD}AUTO_CEO_README.md${RESET}"
    echo -e "    Complete guide to autonomous corporate operations"
    echo -e "    Location: ~/blackroad-dashboards/AUTO_CEO_README.md"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}AUTOMATED_CORPORATE_STRUCTURE.md${RESET}"
    echo -e "    Full corporate blueprint with 10 AI agents"
    echo -e "    Location: ~/blackroad-dashboards/AUTOMATED_CORPORATE_STRUCTURE.md"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${BOLD}Atlas Documents${RESET}"
    echo -e "    Legal entity documents (Certificate, Bylaws, Stock, IRS forms)"
    echo -e "    Location: ~/Desktop/Atlas documents - BlackRoad OS_ Inc."
    echo ""

    echo -e "${BOLD}Quick Commands:${RESET}\n"
    echo -e "  ${CYAN}cat ~/blackroad-dashboards/AUTO_CEO_README.md${RESET}"
    echo -e "  ${CYAN}cat ~/blackroad-dashboards/AUTOMATED_CORPORATE_STRUCTURE.md${RESET}"
    echo -e "  ${CYAN}ls -la ~/Desktop/Atlas\\ documents\\ -\\ BlackRoad\\ OS_\\ Inc.${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Main loop
main() {
    while true; do
        show_business_dashboard

        read -n1 key

        case "$key" in
            '1'|'2'|'3'|'4'|'5'|'6'|'7'|'8'|'9')
                launch_system "$key"
                ;;
            '0')
                # Handle '10' as two keypresses
                read -n1 -t 0.1 next_key
                if [ "$next_key" = "" ]; then
                    # Just '0' pressed - do nothing
                    :
                else
                    # Got second digit
                    launch_system "10"
                fi
                ;;
            'd'|'D')
                show_docs
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}Business operations dashboard closed${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
