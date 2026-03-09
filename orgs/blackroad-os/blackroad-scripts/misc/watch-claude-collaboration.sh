#!/bin/bash
# Real-time Claude Collaboration Monitor
# Shows all active Claude agents and their work

PURPLE='\033[0;35m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Clear screen function
clear_screen() {
    clear
}

# Header
print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║  🤝 Claude Collaboration Monitor                                     ║"
    echo "║  Multi-Agent Real-Time Coordination Dashboard                       ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}Last Update: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# Get active Claude instances
get_active_claudes() {
    echo -e "${GREEN}🤖 Active Claude Agents:${NC}"
    echo ""

    # Check for registered agents in memory
    if [ -f ~/.blackroad/memory/journals/*.jsonl ]; then
        # Extract unique Claude IDs from recent memory entries
        tail -100 ~/.blackroad/memory/journals/*.jsonl 2>/dev/null | \
            grep -o '"agent":"claude-[^"]*"' | \
            sed 's/"agent":"//g' | sed 's/"//g' | \
            sort -u | \
            while read agent; do
                echo -e "  ${BLUE}●${NC} $agent"
            done
    else
        echo -e "  ${YELLOW}No active agents detected${NC}"
    fi
    echo ""
}

# Show recent activity
show_recent_activity() {
    echo -e "${GREEN}📊 Recent Activity (Last 10 Actions):${NC}"
    echo ""

    ~/memory-realtime-context.sh live claude-bot-deployment compact 2>/dev/null | \
        grep -A 10 "Last 5 actions:" | \
        tail -6 | \
        sed 's/^/  /'

    echo ""
}

# Show active deployments
show_deployments() {
    echo -e "${GREEN}🚀 Active Deployments:${NC}"
    echo ""

    ~/memory-realtime-context.sh live claude-bot-deployment compact 2>/dev/null | \
        grep -A 15 "Active Deployments" | \
        tail -10 | \
        sed 's/^/  /'

    echo ""
}

# Show coordination opportunities
show_coordination() {
    echo -e "${GREEN}🤝 Coordination Opportunities:${NC}"
    echo ""
    echo -e "  ${YELLOW}●${NC} Bot Workflows + Codex Integration"
    echo -e "  ${YELLOW}●${NC} Trinity Validation for All Deployments"
    echo -e "  ${YELLOW}●${NC} Priority Stack Authentication"
    echo -e "  ${YELLOW}●${NC} Canva Visual Documentation"
    echo -e "  ${YELLOW}●${NC} Unified Monitoring Dashboard"
    echo ""
}

# Show stats
show_stats() {
    echo -e "${GREEN}📈 Ecosystem Stats:${NC}"
    echo ""

    # Count entries in memory
    local total_entries=$(wc -l ~/.blackroad/memory/journals/*.jsonl 2>/dev/null | tail -1 | awk '{print $1}')

    echo -e "  Memory Entries:      ${CYAN}${total_entries:-0}${NC}"
    echo -e "  Repositories:        ${CYAN}56${NC}"
    echo -e "  Bot Workflows:       ${CYAN}336${NC} (6 per repo)"
    echo -e "  Codex Components:    ${CYAN}8,789${NC}"
    echo -e "  Organizations:       ${CYAN}15${NC}"
    echo -e "  Target Agents:       ${CYAN}30,000${NC}"
    echo ""
}

# Show next steps
show_next_steps() {
    echo -e "${GREEN}⏭️  Next Steps:${NC}"
    echo ""
    echo -e "  ${BLUE}1.${NC} Merge bot workflow PRs (56 pending)"
    echo -e "  ${BLUE}2.${NC} Activate integrations (Slack, Linear, Notion)"
    echo -e "  ${BLUE}3.${NC} Deploy first 100 agents"
    echo -e "  ${BLUE}4.${NC} Test cross-Claude coordination"
    echo -e "  ${BLUE}5.${NC} Scale to 1,000 agents"
    echo ""
}

# Show collaboration tips
show_tips() {
    echo -e "${YELLOW}💡 Collaboration Tips:${NC}"
    echo ""
    echo -e "  • Check [MEMORY] before starting: ${CYAN}~/memory-realtime-context.sh live [agent-id] compact${NC}"
    echo -e "  • Search [CODEX] for existing code: ${CYAN}python3 ~/blackroad-codex-search.py 'keywords'${NC}"
    echo -e "  • Announce work: ${CYAN}~/memory-system.sh log announce [agent-id] 'message'${NC}"
    echo -e "  • Update progress: ${CYAN}~/memory-system.sh log progress [agent-id] 'status'${NC}"
    echo ""
}

# Main loop
main() {
    # If --once flag, run once and exit
    if [ "$1" == "--once" ]; then
        clear_screen
        print_header
        get_active_claudes
        show_recent_activity
        show_deployments
        show_stats
        show_coordination
        show_next_steps
        show_tips
        exit 0
    fi

    # Otherwise, run in watch mode
    while true; do
        clear_screen
        print_header
        get_active_claudes
        show_recent_activity
        show_deployments
        show_stats
        show_coordination
        show_next_steps
        show_tips

        echo -e "${CYAN}Refreshing in 10 seconds... (Ctrl+C to exit)${NC}"
        sleep 10
    done
}

# Help
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Claude Collaboration Monitor"
    echo ""
    echo "Usage:"
    echo "  $0              Run in watch mode (updates every 10s)"
    echo "  $0 --once       Run once and exit"
    echo "  $0 --help       Show this help"
    echo ""
    exit 0
fi

main "$@"
