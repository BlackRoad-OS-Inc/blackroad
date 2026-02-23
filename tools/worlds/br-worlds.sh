#!/bin/zsh
# BR Worlds — World artifact management

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

PI_ARIA="alexa@192.168.4.38"
PI_ALICE="blackroad@192.168.4.49"
ARIA_WORLDS="/home/alexa/blackroad-repos/blackroad-agents/worlds"
ALICE_WORLDS="/home/blackroad/.blackroad/worlds"
GITHUB_REPO="BlackRoad-OS-Inc/blackroad-agents"

show_help() {
  echo "${CYAN}${BOLD}BR Worlds — World Artifact System${NC}"
  echo ""
  echo "${BOLD}Commands:${NC}"
  echo "  ${GREEN}count${NC}         Show world counts per node"
  echo "  ${GREEN}list${NC}          List recent worlds (last 10)"
  echo "  ${GREEN}latest${NC}        Show latest world artifact"
  echo "  ${GREEN}stats${NC}         Full stats from worlds.blackroad.io"
  echo "  ${GREEN}push${NC}          Manually push worlds to GitHub"
  echo "  ${GREEN}types${NC}         Show world type distribution"
  echo "  ${GREEN}watch${NC}         Live terminal feed of new worlds (Ctrl-C to stop)"
}

cmd_count() {
  echo "${CYAN}${BOLD}🌍 World Counts${NC}"
  local aria_count=$(ssh -o ConnectTimeout=4 "$PI_ARIA" "ls $ARIA_WORLDS/ 2>/dev/null | grep '\.md$' | wc -l" 2>/dev/null | tr -d ' ')
  local alice_count=$(ssh -o ConnectTimeout=4 "$PI_ALICE" "ls $ALICE_WORLDS/ 2>/dev/null | grep '\.md$' | wc -l" 2>/dev/null | tr -d ' ')
  local total=$((${aria_count:-0} + ${alice_count:-0}))
  echo "  ${PURPLE}aria64${NC}   (192.168.4.38)  ${GREEN}${aria_count:-?}${NC} worlds"
  echo "  ${BLUE}alice${NC}    (192.168.4.49)  ${GREEN}${alice_count:-?}${NC} worlds"
  echo "  ─────────────────────────────"
  echo "  ${BOLD}Total:${NC} ${GREEN}${total}${NC} worlds"
}

cmd_list() {
  echo "${CYAN}${BOLD}Recent Worlds${NC}"
  echo ""
  echo "${PURPLE}aria64:${NC}"
  ssh -o ConnectTimeout=4 "$PI_ARIA" "ls $ARIA_WORLDS/*.md 2>/dev/null | sort | tail -5 | xargs -I{} basename {}" 2>/dev/null | while read f; do
    echo "  🌍 $f"
  done
  echo ""
  echo "${BLUE}alice:${NC}"
  ssh -o ConnectTimeout=4 "$PI_ALICE" "ls $ALICE_WORLDS/*.md 2>/dev/null | sort | tail -5 | xargs -I{} basename {}" 2>/dev/null | while read f; do
    echo "  🌍 $f"
  done
}

cmd_latest() {
  echo "${CYAN}${BOLD}Latest World Artifact${NC}"
  ssh -o ConnectTimeout=4 "$PI_ARIA" "ls $ARIA_WORLDS/*.md 2>/dev/null | sort | tail -1 | xargs cat 2>/dev/null" 2>/dev/null | head -40
}

cmd_stats() {
  echo "${CYAN}${BOLD}World Stats${NC}"
  local data=$(curl -sf "https://worlds.blackroad.io/stats" 2>/dev/null)
  if [ -n "$data" ]; then
    echo "$data" | python3 -c "
import json,sys
d=json.load(sys.stdin)
worlds=d.get('worlds',d)
print(f'  Total: {worlds.get(\"total\",\"?\")}')
by_node=worlds.get('by_node',{})
for node,count in by_node.items():
    print(f'  {node}: {count}')
" 2>/dev/null
  else
    cmd_count
  fi
}

cmd_types() {
  echo "${CYAN}${BOLD}World Types${NC}"
  ssh -o ConnectTimeout=4 "$PI_ARIA" "ls $ARIA_WORLDS/*.md 2>/dev/null | xargs -I{} basename {} | sed 's/[0-9_]*//g' | sort | uniq -c | sort -rn" 2>/dev/null | head -10
}

cmd_push() {
  echo "${CYAN}Pushing worlds to GitHub...${NC}"
  ssh -o ConnectTimeout=4 "$PI_ARIA" "
    cd /home/alexa/blackroad-repos/blackroad-agents 2>/dev/null || exit 1
    git add worlds/ 2>/dev/null
    COUNT=\$(git status --short worlds/ 2>/dev/null | wc -l | tr -d ' ')
    if [ \"\$COUNT\" -gt 0 ]; then
      git commit -m \"feat: add \$COUNT world artifacts\" && git push origin main
      echo \"Pushed \$COUNT new worlds\"
    else
      echo \"No new worlds to push\"
    fi
  " 2>/dev/null || echo "${YELLOW}aria64 push failed${NC}"
}

case "${1:-count}" in
  count)   cmd_count ;;
  list)    cmd_list ;;
  latest)  cmd_latest ;;
  stats)   cmd_stats ;;
  push)    cmd_push ;;
  types)   cmd_types ;;
  watch)   exec "$(dirname "$0")/br-worlds-watch.sh" "${@:2}" ;;
  *)       show_help ;;
esac
