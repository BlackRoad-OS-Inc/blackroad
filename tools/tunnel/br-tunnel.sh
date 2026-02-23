#!/bin/zsh
# BR TUNNEL — Cloudflare Tunnel manager for Pi fleet
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

CONFIG="$HOME/.cloudflared/config.yml"
TUNNEL_ID="8ae67ab0-71fb-4461-befc-a91302369a7e"

cmd_status() {
  echo -e "\n${CYAN}${BOLD}  CLOUDFLARE TUNNEL STATUS${NC}\n"
  printf "  %-35s %s\n" "Tunnel ID:" "$TUNNEL_ID"
  local pid; pid=$(pgrep -f "cloudflared" 2>/dev/null | head -1)
  if [[ -n "$pid" ]]; then
    echo -e "  ${GREEN}● cloudflared running${NC} (PID $pid)"
  else
    echo -e "  ${RED}● cloudflared NOT running${NC}"
    echo -e "  ${GRAY}  Start: cloudflared tunnel run${NC}"
  fi
  echo -e "\n  ${BOLD}Routes:${NC}"
  grep "hostname:" "$CONFIG" 2>/dev/null | while read -r line; do
    local host; host=$(echo "$line" | awk '{print $2}')
    printf "  ${GREEN}→${NC} %s\n" "$host"
  done
  echo ""
}

cmd_routes() {
  echo -e "\n${CYAN}${BOLD}  TUNNEL ROUTES${NC}\n"
  /usr/bin/python3 -c "
import sys
pi = ''
with open(sys.argv[1]) as f:
    for line in f:
        stripped = line.strip()
        if stripped.startswith('# ') and not stripped.startswith('# Catch'):
            pi = stripped[2:]
        elif stripped.startswith('- hostname:'):
            host = stripped.split('- hostname:')[1].strip()
            print(f'  \033[0;32m→\033[0m {host:<44} \033[0;37m{pi}\033[0m')
" "$CONFIG"
  echo ""
}

cmd_dns() {
  echo -e "\n${CYAN}${BOLD}  DNS WIRING COMMANDS${NC}\n"
  echo -e "  ${GRAY}Run these to register all hostnames with the tunnel:${NC}\n"
  /usr/bin/python3 -c "
import sys
tid = sys.argv[1]
with open(sys.argv[2]) as f:
    for line in f:
        line = line.strip()
        if line.startswith('- hostname:'):
            host = line.split('- hostname:')[1].strip()
            print(f'  cloudflared tunnel route dns {tid} {host}')
" "$TUNNEL_ID" "$CONFIG"
  echo ""
}

cmd_add() {
  local hostname="$1" service="$2" label="${3:-}"
  [[ -z "$hostname" || -z "$service" ]] && {
    echo -e "  ${RED}Usage: br tunnel add <hostname> <service> [label]${NC}"
    return 1
  }
  /usr/bin/python3 -c "
import sys
path = sys.argv[1]; hostname = sys.argv[2]; service = sys.argv[3]; label = sys.argv[4]
with open(path) as f:
    c = f.read()
entry = (('  # ' + label + '\n') if label else '') + '  - hostname: ' + hostname + '\n    service: ' + service + '\n    originRequest:\n      noTLSVerify: true\n'
c = c.replace('  # Catch-all\n', entry + '\n  # Catch-all\n')
with open(path, 'w') as f:
    f.write(c)
print('Added: ' + hostname + ' -> ' + service)
" "$CONFIG" "$hostname" "$service" "$label"
  echo -e "  ${GREEN}✓ Reload tunnel to apply${NC}"
}

show_help() {
  echo -e "\n${BOLD}  BR TUNNEL${NC}  Cloudflare Tunnel manager\n"
  echo -e "  ${CYAN}br tunnel status${NC}   Tunnel health + route list"
  echo -e "  ${CYAN}br tunnel routes${NC}   All routes with Pi labels"
  echo -e "  ${CYAN}br tunnel dns${NC}      Print cloudflared dns commands"
  echo -e "  ${CYAN}br tunnel add <host> <svc> [label]${NC}   Add route"
  echo ""
}

case "$1" in
  status|"")   cmd_status ;;
  routes|list) cmd_routes ;;
  dns)         cmd_dns ;;
  add)         shift; cmd_add "$@" ;;
  *)           show_help ;;
esac
