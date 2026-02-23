#!/bin/zsh
# BR Nodes - BlackRoad Node Registry

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

show_help() {
  echo -e "${CYAN}${BOLD}BR Nodes — Node Registry${NC}"
  echo ""
  echo "  br nodes list         List all registered nodes"
  echo "  br nodes health       Health check all nodes"
  echo "  br nodes ping <node>  Ping specific node"
  echo "  br nodes info <node>  Node details"
}

NODES_JSON='{
  "aria64": {"ip": "192.168.4.38", "user": "alexa", "role": "primary", "capacity": 22500, "tunnel_domain": "octavia.blackroad.io"},
  "alice":  {"ip": "192.168.4.49", "user": "blackroad", "role": "secondary", "capacity": 7500, "tunnel_domain": "ops.blackroad.io"}
}'

cmd_list() {
  echo -e "${CYAN}${BOLD}BlackRoad Node Registry${NC}\n"
  echo "$NODES_JSON" | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
for name, n in nodes.items():
    print(f\"  \033[0;36m{name:<12}\033[0m {n['ip']:<16} {n['role']:<12} capacity={n['capacity']:,}\")
"
  echo ""
  echo -e "  Total capacity: ${YELLOW}30,000 agents${NC}"
}

cmd_health() {
  echo -e "${CYAN}${BOLD}Node Health Check${NC}\n"
  for NODE in aria64 alice; do
    DOMAIN=$(echo "$NODES_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['$NODE']['tunnel_domain'])")
    RESULT=$(curl -s -m 5 "https://$DOMAIN/health" 2>/dev/null)
    if [[ -n "$RESULT" ]]; then
      WORLDS=$(echo "$RESULT" | python3 -c "import json,sys; print(json.load(sys.stdin).get('worlds_count','?'))" 2>/dev/null)
      echo -e "  ${GREEN}● $NODE${NC} — ${DOMAIN} — worlds: ${WORLDS}"
    else
      echo -e "  ${RED}● $NODE${NC} — ${DOMAIN} — offline"
    fi
  done
}

cmd_ping() {
  local NODE="${1:-aria64}"
  DOMAIN=$(echo "$NODES_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('$NODE', {}).get('tunnel_domain', ''))" 2>/dev/null)
  if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}Unknown node: $NODE${NC}"
    exit 1
  fi
  echo -e "Pinging ${CYAN}$NODE${NC} at ${DOMAIN}..."
  curl -s -m 5 "https://$DOMAIN/health" | python3 -m json.tool 2>/dev/null || echo "No response"
}

case "${1:-help}" in
  list)    cmd_list ;;
  health)  cmd_health ;;
  ping)    cmd_ping "$2" ;;
  info)    cmd_ping "$2" ;;
  *)       show_help ;;
esac
