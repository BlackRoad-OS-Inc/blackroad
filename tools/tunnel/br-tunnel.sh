#!/bin/zsh
# BR TUNNEL — Cloudflare Tunnel manager for Pi fleet
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

CONFIG="$HOME/.cloudflared/config.yml"
TUNNEL_ID="8ae67ab0-71fb-4461-befc-a91302369a7e"

cmd_status() {
  echo -e "\n${CYAN}${BOLD}  CLOUDFLARE TUNNEL STATUS${NC}\n"
  printf "  %-20s %s\n" "Tunnel:" "$TUNNEL_ID"
  local pid; pid=$(pgrep -f "cloudflared" 2>/dev/null | head -1)
  if [[ -n "$pid" ]]; then
    echo -e "  ${GREEN}● cloudflared running${NC} (PID $pid)"
  else
    echo -e "  ${RED}● cloudflared NOT running${NC}  →  run: cloudflared tunnel run"
  fi
  echo -e "\n  ${BOLD}Routes:${NC}"
  grep "hostname:" "$CONFIG" 2>/dev/null | sed 's/.*hostname: //' | while read -r h; do
    printf "  ${GREEN}→${NC} %s\n" "$h"
  done
  echo ""
}

cmd_routes() {
  echo -e "\n${CYAN}${BOLD}  TUNNEL ROUTES${NC}\n"
  /usr/bin/python3 - "$CONFIG" << 'PYEOF'
import sys
pi = ''
with open(sys.argv[1]) as f:
    for line in f:
        s = line.strip()
        if s.startswith('# ') and 'Catch' not in s:
            pi = s[2:]
        elif s.startswith('- hostname:'):
            host = s.split('- hostname:')[1].strip()
            print(f'  \033[0;32m→\033[0m {host:<44} \033[0;37m{pi}\033[0m')
PYEOF
  echo ""
}

cmd_dns() {
  echo -e "\n${CYAN}${BOLD}  DNS WIRING COMMANDS${NC}\n"
  echo -e "  ${GRAY}Run these to register all hostnames with the tunnel:${NC}\n"
  /usr/bin/python3 - "$TUNNEL_ID" "$CONFIG" << 'PYEOF'
import sys
tid, path = sys.argv[1], sys.argv[2]
with open(path) as f:
    for line in f:
        s = line.strip()
        if s.startswith('- hostname:'):
            host = s.split('- hostname:')[1].strip()
            print(f'  cloudflared tunnel route dns {tid} {host}')
PYEOF
  echo ""
}

cmd_add() {
  local hostname="$1" service="$2" label="${3:-}"
  [[ -z "$hostname" || -z "$service" ]] && {
    echo -e "  ${RED}Usage: br tunnel add <hostname> <service> [label]${NC}"
    return 1
  }
  /usr/bin/python3 - "$CONFIG" "$hostname" "$service" "$label" << 'PYEOF'
import sys
path, hostname, service, label = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(path) as f:
    content = f.read()
entry = (f'  # {label}\n' if label else '') + f'  - hostname: {hostname}\n    service: {service}\n    originRequest:\n      noTLSVerify: true\n'
content = content.replace('  # Catch-all\n', entry + '\n  # Catch-all\n')
with open(path, 'w') as f:
    f.write(content)
print(f'Added: {hostname} → {service}')
PYEOF
  echo -e "  ${GREEN}✓ Reload tunnel to apply${NC}"
}

show_help() {
  echo -e "\n${BOLD}  BR TUNNEL${NC}  Cloudflare Tunnel → Pi Fleet\n"
  echo -e "  ${CYAN}br tunnel status${NC}   Tunnel health + route count"
  echo -e "  ${CYAN}br tunnel routes${NC}   All routes with Pi labels"
  echo -e "  ${CYAN}br tunnel dns${NC}      Print cloudflared route dns commands"
  echo -e "  ${CYAN}br tunnel add <host> <svc> [label]${NC}   Add route"
  echo ""
  echo -e "  ${GRAY}Pi fleet:${NC}"
  echo -e "  ${GRAY}  aria64     192.168.4.38  (22,500 slots)${NC}"
  echo -e "  ${GRAY}  blackroad  192.168.4.64  (7,500 slots)${NC}"
  echo -e "  ${GRAY}  alice      192.168.4.49  (Pi 4)${NC}"
  echo -e "  ${GRAY}  cecilia    192.168.4.89  (Pi 5)${NC}"
  echo ""
}

case "$1" in
  status|"")   cmd_status ;;
  routes|list) cmd_routes ;;
  dns)         cmd_dns ;;
  add)         shift; cmd_add "$@" ;;
  *)           show_help ;;
esac
