#!/bin/zsh
# BR Analytics - Platform analytics dashboard

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; PURPLE='\033[0;35m'; BLUE='\033[0;34m'; NC='\033[0m'

show_help() {
  echo "${CYAN}BR Analytics${NC}"
  echo "  br analytics summary    - Platform overview"
  echo "  br analytics worlds     - World generation stats"
  echo "  br analytics workers    - CF worker status"
  echo "  br analytics orgs       - Org repo counts"
  echo "  br analytics memory     - Gateway memory stats"
}

cmd_summary() {
  echo "${PURPLE}━━━ BlackRoad Platform Analytics ━━━${NC}"
  echo "${CYAN}Organizations:${NC} 17"
  echo "${CYAN}Repositories:${NC}  1,825+"
  echo "${CYAN}AI Agents:${NC}     30,000"
  echo "${CYAN}CF Workers:${NC}    75+"
  
  echo ""
  echo "${YELLOW}Live Stats:${NC}"
  
  local worlds=$(curl -s --max-time 5 "https://worlds.blackroad.io/stats" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total','?'))" 2>/dev/null || echo "?")
  echo "  🌍 Worlds Generated: ${GREEN}${worlds}${NC}"
  
  local gw=$(curl -s --max-time 5 "http://127.0.0.1:8787/v1/memory" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('total_entries','?'))" 2>/dev/null || echo "offline")
  echo "  🧠 Memory Entries:   ${GREEN}${gw}${NC}"
}

cmd_worlds() {
  echo "${PURPLE}━━━ Worlds Analytics ━━━${NC}"
  local data=$(curl -s --max-time 5 "https://worlds.blackroad.io/stats" 2>/dev/null)
  if [[ -z "$data" ]]; then
    echo "${RED}worlds.blackroad.io unreachable${NC}"; return
  fi
  echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"Total: {d.get('total', 0)}\")
print('By Type:')
for k,v in sorted(d.get('by_type',{}).items(), key=lambda x: -x[1]):
    bar = '█' * min(20, v)
    print(f'  {k:<20} {bar} {v}')
print('By Node:')
for k,v in d.get('by_node',{}).items():
    print(f'  {k}: {v}')
"
}

cmd_workers() {
  echo "${PURPLE}━━━ CF Workers Health ━━━${NC}"
  local workers=("worlds.blackroad.io" "analytics.blackroad.io" "verify.blackroad.io" "studio.blackroad.io" "docs.blackroad.io" "blog.blackroad.io" "api.blackroad.io" "search.blackroad.io")
  for w in "${workers[@]}"; do
    local status=$(curl -s --max-time 5 "https://${w}/health" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','?'))" 2>/dev/null || echo "error")
    if [[ "$status" == "ok" ]]; then
      echo "  ${GREEN}✓${NC} ${w}"
    else
      echo "  ${RED}✗${NC} ${w} (${status})"
    fi
  done
}

cmd_orgs() {
  echo "${PURPLE}━━━ GitHub Organizations ━━━${NC}"
  local orgs=("BlackRoad-OS-Inc:7" "BlackRoad-OS:1332" "blackboxprogramming:68" "BlackRoad-AI:52" "BlackRoad-Cloud:30" "BlackRoad-Security:30" "BlackRoad-Foundation:30" "BlackRoad-Hardware:30" "BlackRoad-Media:29" "BlackRoad-Interactive:29" "BlackRoad-Education:24" "BlackRoad-Gov:23" "Blackbox-Enterprises:21" "BlackRoad-Archive:21" "BlackRoad-Labs:20" "BlackRoad-Studio:19" "BlackRoad-Ventures:17")
  local total=0
  for entry in "${orgs[@]}"; do
    local name="${entry%%:*}"
    local count="${entry##*:}"
    total=$((total + count))
    printf "  ${CYAN}%-30s${NC} %s repos\n" "$name" "$count"
  done
  echo "  ─────────────────────────────────────"
  echo "  ${YELLOW}Total: ${total}+ repos${NC}"
}

cmd_memory() {
  echo "${PURPLE}━━━ Gateway Memory ━━━${NC}"
  local data=$(curl -s --max-time 5 "http://127.0.0.1:8787/v1/memory" 2>/dev/null)
  if [[ -z "$data" ]]; then
    echo "${RED}Gateway offline${NC}"; return
  fi
  echo "$data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"Total entries: {d.get('total_entries', 0)}\")
print(f\"Session calls: {d.get('session_calls', 0)}\")
"
}

case "$1" in
  summary|"")   cmd_summary ;;
  worlds)        cmd_worlds ;;
  workers)       cmd_workers ;;
  orgs)          cmd_orgs ;;
  memory)        cmd_memory ;;
  help|--help)   show_help ;;
  *)             show_help ;;
esac
