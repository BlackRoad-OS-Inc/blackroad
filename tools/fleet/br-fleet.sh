#!/bin/zsh
# BR Fleet - BlackRoad Fleet Dashboard
# Shows combined status of Pi nodes + CF workers

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'
NC='\033[0m'; BOLD='\033[1m'

show_help() {
  echo -e "${PURPLE}${BOLD}BR Fleet — BlackRoad Fleet Dashboard${NC}"
  echo ""
  echo "  br fleet status       Full fleet overview"
  echo "  br fleet workers      CF worker health"
  echo "  br fleet nodes        Pi node health"
  echo "  br fleet worlds       World generation stats"
}

WORKERS=(
  "worlds.blackroad.io"
  "verify.blackroad.io"
  "studio.blackroad.io"
  "docs.blackroad.io"
  "blog.blackroad.io"
  "api.blackroad.io"
  "analytics.blackroad.io"
  "search.blackroad.io"
  "nodes.blackroad.io"
)

cmd_workers() {
  echo -e "${CYAN}${BOLD}☁ CF Workers${NC}"
  for W in "${WORKERS[@]}"; do
    RESULT=$(curl -s -m 5 "https://$W/health" 2>/dev/null)
    if [[ -n "$RESULT" ]]; then
      echo -e "  ${GREEN}●${NC} $W"
    else
      echo -e "  ${RED}●${NC} $W"
    fi
  done
}

cmd_nodes() {
  echo -e "${CYAN}${BOLD}🍓 Pi Nodes${NC}"
  for DOMAIN in "octavia.blackroad.io" "ops.blackroad.io"; do
    RESULT=$(curl -s -m 5 "https://$DOMAIN/health" 2>/dev/null)
    if [[ -n "$RESULT" ]]; then
      WORLDS=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('worlds_count','?'))" 2>/dev/null)
      echo -e "  ${GREEN}●${NC} $DOMAIN — worlds: $WORLDS"
    else
      echo -e "  ${RED}●${NC} $DOMAIN — offline"
    fi
  done
}

cmd_worlds() {
  echo -e "${CYAN}${BOLD}🌍 World Generation${NC}"
  WORLDS_DATA=$(curl -s -m 5 "https://worlds.blackroad.io/health" 2>/dev/null)
  if [[ -n "$WORLDS_DATA" ]]; then
    echo "$WORLDS_DATA" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f\"  Total worlds: {d.get('total_worlds', d.get('count','?'))}\")
print(f\"  Status: generating\")
" 2>/dev/null
  else
    echo -e "  ${RED}worlds.blackroad.io offline${NC}"
  fi
}

cmd_status() {
  echo -e "${PURPLE}${BOLD}╔══════════════════════════════╗${NC}"
  echo -e "${PURPLE}${BOLD}║   BlackRoad Fleet Dashboard   ║${NC}"
  echo -e "${PURPLE}${BOLD}╚══════════════════════════════╝${NC}\n"
  
  cmd_nodes
  echo ""
  cmd_workers
  echo ""
  cmd_worlds
  
  echo -e "\n${CYAN}Domains: 9 workers + 2 Pi tunnels | 30,000 agent capacity${NC}"
}

case "${1:-help}" in
  status)  cmd_status ;;
  workers) cmd_workers ;;
  nodes)   cmd_nodes ;;
  worlds)  cmd_worlds ;;
  *)       show_help ;;
esac
