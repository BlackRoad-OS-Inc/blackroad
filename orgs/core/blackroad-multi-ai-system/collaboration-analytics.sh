#!/bin/bash
# Collaboration Analytics - Deep insights into multi-Claude coordination!

MEMORY_DIR="$HOME/.blackroad/memory"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║        📊 COLLABORATION ANALYTICS 📊                      ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Task metrics
completed=$(find "$MEMORY_DIR/tasks/completed" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
claimed=$(find "$MEMORY_DIR/tasks/claimed" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
available=$(find "$MEMORY_DIR/tasks/available" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
total=$((completed + claimed + available))

echo -e "${BOLD}${PURPLE}📋 Task Marketplace Analytics${NC}"
echo -e "  Total Tasks: $total"
echo -e "  ${GREEN}✅ Completed: $completed${NC}"
echo -e "  ${YELLOW}⏳ In Progress: $claimed${NC}"
echo -e "  ${BLUE}📋 Available: $available${NC}"

if [[ $total -gt 0 ]]; then
    completion_rate=$((completed * 100 / total))
    echo -e "  ${GREEN}🎯 Completion Rate: ${completion_rate}%${NC}"
fi

echo ""

# Active Claudes
echo -e "${BOLD}${PURPLE}👥 Active Claudes${NC}"
active=$(tail -100 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | jq -r '.entity' | sort -u | wc -l | tr -d ' ')
echo -e "  ${CYAN}Active in last 100 actions: $active${NC}"

echo ""

# TIL sharing
echo -e "${BOLD}${PURPLE}💡 Knowledge Sharing${NC}"
til_count=$(find "$MEMORY_DIR/til" -name "til-*.json" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${PURPLE}TILs broadcast: $til_count${NC}"

echo ""

# Memory entries
echo -e "${BOLD}${PURPLE}🧠 Memory System${NC}"
entry_count=$(wc -l < "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | tr -d ' ')
echo -e "  ${BLUE}Total entries: $entry_count${NC}"

echo ""

# Top actions
echo -e "${BOLD}${PURPLE}🔥 Top Actions${NC}"
tail -200 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | jq -r '.action' | sort | uniq -c | sort -rn | head -5 | while read count action; do
    echo -e "  ${GREEN}$count${NC} × ${CYAN}$action${NC}"
done

echo ""

# Collaboration score
collab_score=$((active * 10 + til_count * 5 + completed * 20))
echo -e "${BOLD}${GREEN}🌟 Collaboration Score: $collab_score${NC}"

if [[ $collab_score -gt 500 ]]; then
    echo -e "${BOLD}${GREEN}   Status: LEGENDARY! 🔥${NC}"
elif [[ $collab_score -gt 200 ]]; then
    echo -e "${BOLD}${YELLOW}   Status: EXCELLENT! ⭐${NC}"
elif [[ $collab_score -gt 50 ]]; then
    echo -e "${BOLD}${BLUE}   Status: GOOD! 👍${NC}"
else
    echo -e "${BOLD}   Status: GETTING STARTED 🚀${NC}"
fi

echo ""
