#!/bin/zsh
# BR Worlds — view and manage world artifacts

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'

WORLDS_API="https://worlds.blackroad.io"

cmd_stats() {
  local data=$(curl -sf "$WORLDS_API/stats" 2>/dev/null)
  if [[ -z "$data" ]]; then echo -e "${RED}✗ worlds API unreachable${NC}"; return 1; fi
  echo -e "${CYAN}╔══════════════════════════════════╗${NC}"
  echo -e "${CYAN}║      🌍 WORLD STATS              ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════╝${NC}"
  echo "$data" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'  Total worlds: {d[\"total\"]}')
types=d.get('by_type',{})
for t,n in types.items():
    print(f'  {t}: {n}')
nodes=d.get('by_node',{})
print('  ---')
for node,n in nodes.items():
    print(f'  {node}: {n} worlds')
"
}

cmd_list() {
  local n="${2:-10}"
  local filter="${3:-}"
  local data=$(curl -sf "$WORLDS_API/worlds?limit=${n}" 2>/dev/null || \
               curl -sf "$WORLDS_API/" 2>/dev/null)
  if [[ -z "$data" ]]; then echo -e "${RED}✗ worlds API unreachable${NC}"; return 1; fi
  echo -e "${CYAN}Latest ${n} worlds:${NC}\n"
  echo "$data" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  worlds = d.get('worlds', d) if isinstance(d, dict) else d
  for w in list(worlds)[:int('$n')]:
    title = w.get('title', w.get('name','Untitled'))[:50]
    type_ = w.get('type','world')
    node  = w.get('node','?')
    ts    = w.get('created_at','')[:10]
    print(f'  [{type_:6}] {title:<50} {node} {ts}')
except Exception as e:
  print(f'  (raw): {sys.stdin.read()[:200]}')
" 2>/dev/null || echo -e "  ${YELLOW}(world listing not available via API)${NC}"
}

cmd_live() {
  # Show Pi fleet world counts
  echo -e "${CYAN}🍓 Pi World Engine Status:${NC}\n"
  local aria=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no alexa@192.168.4.38 \
    "ls ~/.blackroad/worlds/ 2>/dev/null | wc -l | tr -d ' '; ps aux | grep world-engine | grep -v grep | awk '{print \$2}'" 2>/dev/null)
  local alice=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no blackroad@192.168.4.49 \
    "ls ~/.blackroad/worlds/ 2>/dev/null | wc -l | tr -d ' '; ps aux | grep world-engine | grep -v grep | awk '{print \$2}'" 2>/dev/null)
  echo -e "  ${GREEN}aria64${NC}  (192.168.4.38): $(echo $aria | awk '{print $1}') local worlds, PID $(echo $aria | awk '{print $2}')"
  echo -e "  ${YELLOW}alice${NC}   (192.168.4.49): $(echo $alice | awk '{print $1}') local worlds, PID $(echo $alice | awk '{print $2}')"
  echo ""
  cmd_stats
}

cmd_generate() {
  local type="${2:-world}"
  echo -e "${CYAN}Triggering world generation (type: $type)...${NC}"
  # Kick off via aria64's engine
  local result=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no alexa@192.168.4.38 \
    "python3 -c \"import asyncio,sys; sys.path.insert(0,'/home/alexa'); from world_engine import WorldEngine; e=WorldEngine(); asyncio.run(e.generate_world('$type'))\" 2>/dev/null && echo ok" 2>/dev/null)
  if [[ "$result" == *"ok"* ]]; then
    echo -e "${GREEN}✓ World generated${NC}"
  else
    echo -e "${YELLOW}~ Generation triggered (check Pi logs)${NC}"
  fi
}

show_help() {
  echo -e "${CYAN}BR Worlds${NC}"
  echo "  br worlds             Show world stats"
  echo "  br worlds list [n]    List recent worlds"
  echo "  br worlds live        Pi fleet + stats"
  echo "  br worlds generate    Trigger new world"
  echo "  br worlds stats       Show detailed stats"
}

case "${1:-stats}" in
  stats|"")    cmd_stats ;;
  list)        cmd_list "$@" ;;
  live)        cmd_live ;;
  generate|gen) cmd_generate "$@" ;;
  help|--help)  show_help ;;
  *)            show_help ;;
esac
