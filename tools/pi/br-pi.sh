#!/bin/zsh
# BR Pi - Raspberry Pi Node Manager

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

ARIA64_IP="192.168.4.38"
ARIA64_USER="alexa"
ALICE_IP="192.168.4.49"
ALICE_USER="blackroad"

show_help() {
  echo -e "${PURPLE}${BOLD}BR Pi — Raspberry Pi Manager${NC}"
  echo ""
  echo "  ${CYAN}br pi status${NC}          Show all Pi nodes"
  echo "  ${CYAN}br pi worlds${NC}          Worlds count from both nodes"
  echo "  ${CYAN}br pi ssh aria64${NC}      SSH to aria64"
  echo "  ${CYAN}br pi ssh alice${NC}       SSH to alice"
  echo "  ${CYAN}br pi deploy aria64${NC}   Deploy latest to aria64"
  echo "  ${CYAN}br pi deploy alice${NC}    Deploy latest to alice"
  echo "  ${CYAN}br pi logs aria64${NC}     View aria64 service logs"
  echo "  ${CYAN}br pi logs alice${NC}      View alice service logs"
  echo "  ${CYAN}br pi restart aria64${NC}  Restart services on aria64"
  echo "  ${CYAN}br pi restart alice${NC}   Restart services on alice"
  echo "  ${CYAN}br pi tunnel${NC}          Show tunnel status"
}

cmd_status() {
  echo -e "${PURPLE}${BOLD}🍓 Pi Fleet Status${NC}\n"
  
  # aria64
  echo -e "${CYAN}aria64 (192.168.4.38)${NC}"
  if SSH_OUT=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no $ARIA64_USER@$ARIA64_IP "curl -s http://localhost:3000/health 2>/dev/null || echo '{}'" 2>/dev/null); then
    WORLDS=$(echo "$SSH_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('worlds_count','?'))" 2>/dev/null)
    echo -e "  ${GREEN}●${NC} Online | Worlds: ${YELLOW}${WORLDS}${NC} | Role: Primary"
  else
    echo -e "  ${RED}●${NC} Unreachable"
  fi
  
  # alice
  echo -e "\n${CYAN}alice (192.168.4.49)${NC}"
  if SSH_OUT=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no $ALICE_USER@$ALICE_IP "curl -s http://localhost:8011/health 2>/dev/null || curl -s http://localhost:8012/health 2>/dev/null || echo '{}'" 2>/dev/null); then
    WORLDS=$(echo "$SSH_OUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('worlds_count','?'))" 2>/dev/null)
    echo -e "  ${GREEN}●${NC} Online | Worlds: ${YELLOW}${WORLDS}${NC} | Role: Secondary"
  else
    echo -e "  ${RED}●${NC} Unreachable"
  fi
}

cmd_worlds() {
  echo -e "${PURPLE}${BOLD}🌍 World Counts${NC}\n"
  
  ARIA_WORLDS=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no $ARIA64_USER@$ARIA64_IP \
    "ls /home/alexa/blackroad-repos/blackroad-agents/worlds/*.json 2>/dev/null | wc -l | tr -d ' '" 2>/dev/null || echo "?")
  
  ALICE_WORLDS=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no $ALICE_USER@$ALICE_IP \
    "ls /home/blackroad/.blackroad/worlds/*.json 2>/dev/null | wc -l | tr -d ' '" 2>/dev/null || echo "?")
  
  echo -e "  aria64:  ${GREEN}${ARIA_WORLDS}${NC} worlds"
  echo -e "  alice:   ${GREEN}${ALICE_WORLDS}${NC} worlds"
  
  if [[ "$ARIA_WORLDS" != "?" && "$ALICE_WORLDS" != "?" ]]; then
    TOTAL=$((ARIA_WORLDS + ALICE_WORLDS))
    echo -e "\n  ${YELLOW}Total: ${TOTAL} worlds${NC}"
  fi
}

cmd_ssh() {
  local NODE="${1:-aria64}"
  case "$NODE" in
    aria64) ssh $ARIA64_USER@$ARIA64_IP ;;
    alice)  ssh $ALICE_USER@$ALICE_IP ;;
    *)      echo -e "${RED}Unknown node: $NODE${NC}" ;;
  esac
}

cmd_logs() {
  local NODE="${1:-aria64}"
  case "$NODE" in
    aria64)
      ssh -t -o ConnectTimeout=5 $ARIA64_USER@$ARIA64_IP \
        "sudo journalctl -u blackroad-api -f --no-pager -n 50 2>/dev/null || sudo journalctl -u cloudflared -f --no-pager -n 30" 2>/dev/null ;;
    alice)
      ssh -t -o ConnectTimeout=5 $ALICE_USER@$ALICE_IP \
        "sudo journalctl -u blackroad-ops -f --no-pager -n 50 2>/dev/null || tail -f /home/blackroad/world-engine.log" 2>/dev/null ;;
    *)
      echo -e "${RED}Unknown node: $NODE${NC}" ;;
  esac
}

cmd_restart() {
  local NODE="${1:-aria64}"
  case "$NODE" in
    aria64)
      echo -e "${CYAN}Restarting aria64 services...${NC}"
      ssh -o ConnectTimeout=5 $ARIA64_USER@$ARIA64_IP \
        "sudo systemctl restart blackroad-api cloudflared && echo 'Restarted'" 2>/dev/null || echo -e "${RED}Failed${NC}" ;;
    alice)
      echo -e "${CYAN}Restarting alice services...${NC}"
      ssh -o ConnectTimeout=5 $ALICE_USER@$ALICE_IP \
        "sudo systemctl restart blackroad-ops cloudflared && echo 'Restarted'" 2>/dev/null || echo -e "${RED}Failed${NC}" ;;
    *)
      echo -e "${RED}Unknown node: $NODE${NC}" ;;
  esac
}

cmd_tunnel() {
  echo -e "${PURPLE}${BOLD}🚇 Cloudflare Tunnel Status${NC}\n"
  
  echo -e "${CYAN}aria64 tunnel (0447556b...)${NC}"
  ssh -o ConnectTimeout=4 $ARIA64_USER@$ARIA64_IP \
    "sudo systemctl status cloudflared --no-pager | grep -E 'Active|ago' | head -2" 2>/dev/null || echo "  Unreachable"
  echo -e "  Domains: octavia.blackroad.io, agents.blackroad.io, nodes.blackroad.io"
  
  echo -e "\n${CYAN}alice tunnel (52915859...)${NC}"
  ssh -o ConnectTimeout=4 $ALICE_USER@$ALICE_IP \
    "sudo systemctl status cloudflared --no-pager | grep -E 'Active|ago' | head -2" 2>/dev/null || echo "  Unreachable"
  echo -e "  Domains: ops.blackroad.io, cluster.blackroad.io, alice.blackroad.io, fleet.blackroad.io"
}

cmd_deploy() {
  local NODE="${1:-aria64}"
  echo -e "${CYAN}Deploying latest to ${NODE}...${NC}"
  case "$NODE" in
    aria64)
      ssh $ARIA64_USER@$ARIA64_IP "
        cd /home/alexa/blackroad-repos/blackroad-agents && \
        git pull origin master --no-rebase 2>&1 | tail -3 && \
        echo 'Deploy complete'
      " ;;
    alice)
      ssh $ALICE_USER@$ALICE_IP "
        cd /home/blackroad && \
        git -C blackroad-worlds pull origin master --no-rebase 2>&1 | tail -3 && \
        echo 'Deploy complete'
      " ;;
  esac
}

case "${1:-help}" in
  status)  cmd_status ;;
  worlds)  cmd_worlds ;;
  ssh)     cmd_ssh "$2" ;;
  logs)    cmd_logs "$2" ;;
  restart) cmd_restart "$2" ;;
  tunnel)  cmd_tunnel ;;
  deploy)  cmd_deploy "$2" ;;
  *)       show_help ;;
esac
