#!/bin/zsh
# BR LOGS-CF — Tail Cloudflare Worker logs live
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

cmd_tail() {
  local worker="${1:-}"
  if [[ -z "$worker" ]]; then
    echo -e "\n  ${RED}Usage: br logs <worker-name>${NC}"
    echo -e "  ${GRAY}Example: br logs blackroad-status${NC}\n"
    return 1
  fi
  echo -e "\n${CYAN}${BOLD}  TAILING:${NC} $worker\n"
  wrangler tail "$worker" --format=pretty 2>&1
}

cmd_list() {
  echo -e "\n${CYAN}${BOLD}  YOUR CF WORKERS${NC}\n"
  local tf="$HOME/.blackroad/kv_token"
  [[ ! -f "$tf" ]] && { echo -e "  ${RED}No token at $tf${NC}"; return 1; }
  local tok; IFS= read -r tok < "$tf"
  /usr/bin/curl -s \
    -H "Authorization: Bearer $tok" \
    "https://api.cloudflare.com/client/v4/accounts/848cf0b18d51e0170e0d1537aec3505a/workers/scripts?per_page=100" | \
    /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
workers = d.get('result') or []
for w in workers[:50]:
    print(f'  \033[0;36m→\033[0m {w[\"id\"]}')
print(f'\n  Total: {len(workers)} (showing 50)')
" 2>/dev/null
  echo ""
}

cmd_errors() {
  local worker="${1:-}"
  [[ -z "$worker" ]] && { echo -e "  ${RED}Usage: br logs errors <worker>${NC}"; return 1; }
  echo -e "\n${CYAN}  Tailing errors for:${NC} $worker\n"
  wrangler tail "$worker" --format=pretty --status=error 2>&1
}

show_help() {
  echo -e "\n${BOLD}  BR LOGS${NC}  Cloudflare Worker log tailing\n"
  echo -e "  ${CYAN}br logs <worker>${NC}          Live tail (all events)"
  echo -e "  ${CYAN}br logs errors <worker>${NC}   Tail errors only"
  echo -e "  ${CYAN}br logs list${NC}              List all your workers"
  echo ""
  echo -e "  ${GRAY}Common workers:${NC}"
  echo -e "  ${GRAY}  blackroad-status · blackroad-auth · blackroad-email${NC}"
  echo ""
}

case "$1" in
  list|ls)      cmd_list ;;
  errors|err)   shift; cmd_errors "$@" ;;
  help|-h)      show_help ;;
  "")           show_help ;;
  *)            cmd_tail "$@" ;;
esac
