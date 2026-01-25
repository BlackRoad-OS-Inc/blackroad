#!/bin/bash
# Agent Performance Leaderboard - Gamify collaboration!

MEMORY_DIR="$HOME/.blackroad/memory"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${PURPLE}║           🏆 CLAUDE PERFORMANCE LEADERBOARD 🏆           ║${NC}"
echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Count actions per Agent
declare -A agent_stats

while read -r line; do
    entity=$(echo "$line" | jq -r '.entity')
    action=$(echo "$line" | jq -r '.action')
    
    [[ -z "$entity" || "$entity" == "null" ]] && continue
    
    # Count points
    points=1
    case "$action" in
        completed) points=20 ;;
        announce) points=5 ;;
        progress) points=3 ;;
        til) points=10 ;;
        coordination) points=5 ;;
    esac
    
    agent_stats["$entity"]=$((${agent_stats["$entity"]:-0} + points))
done < <(tail -200 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null)

# Sort and display
echo -e "${BOLD}Top Performers (Last 200 Actions):${NC}"
echo ""

rank=1
for agent in "${!agent_stats[@]}"; do
    echo "${agent_stats[$agent]} $agent"
done | sort -rn | head -10 | while read points agent; do
    
    # Medal/badge
    badge=""
    case $rank in
        1) badge="${YELLOW}🥇 " ;;
        2) badge="${BLUE}🥈 " ;;
        3) badge="${PURPLE}🥉 " ;;
        *) badge="   " ;;
    esac
    
    # Color based on rank
    color="$NC"
    case $rank in
        1) color="$YELLOW" ;;
        2-3) color="$CYAN" ;;
    esac
    
    echo -e "${badge}${color}#$rank ${BOLD}$agent${NC} - ${GREEN}$points pts${NC}"
    ((rank++))
done

echo ""
echo -e "${BOLD}${CYAN}Point System:${NC}"
echo -e "  🏆 Task Completed: 20 pts"
echo -e "  💡 TIL Broadcast: 10 pts"
echo -e "  📢 Announcement: 5 pts"
echo -e "  🤝 Coordination: 5 pts"
echo -e "  ⚡ Progress Update: 3 pts"
echo -e "  • Other Actions: 1 pt"

echo ""
