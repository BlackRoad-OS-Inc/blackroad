#!/bin/zsh
# BR WORKERS — Cloudflare Workers Manager
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

CF_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

get_token() {
  local tf="$HOME/.blackroad/kv_token"
  local tok=""
  [[ -f "$tf" ]] && IFS= read -r tok < "$tf"
  [[ -z "$tok" ]] && tok="${CLOUDFLARE_API_TOKEN:-}"
  printf '%s' "$tok"
}

cf_api() {
  local path="$1"; shift
  local token; token=$(get_token)
  if [[ -z "$token" ]]; then
    echo -e "${RED}x${NC} No CF API token. Run: br kv auth <token>" >&2
    return 1
  fi
  /usr/bin/curl -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@" \
    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID$path"
}

cmd_list() {
  echo -e "\n${CYAN}${BOLD}  WORKERS${NC}\n"
  local result; result=$(cf_api "/workers/scripts?per_page=100") || return 1
  echo "$result" | /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
scripts = d.get('result', [])
if not scripts:
    print('  No workers found.')
    sys.exit(0)
print(f'  {len(scripts)} workers\n')
for s in scripts:
    name = s.get('id', '?')
    modified = s.get('modified_on', '')[:10]
    size = s.get('size', 0)
    print(f'  {name:<40} {modified}  {size:>6} bytes')
" 2>/dev/null || echo -e "${RED}x${NC} Failed to parse response."
  echo ""
}

cmd_get() {
  local name="$1"
  if [[ -z "$name" ]]; then echo -e "${RED}x${NC} Usage: br workers get <name>"; exit 1; fi
  echo -e "\n${CYAN}${BOLD}  WORKER: $name${NC}\n"
  local result; result=$(cf_api "/workers/scripts/$name") || return 1
  # Get script source (returns text)
  local token; token=$(get_token)
  local source; source=$(/usr/bin/curl -s -H "Authorization: Bearer $token" \
    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts/$name")
  echo "$source" | head -30
  echo ""
}

cmd_delete() {
  local name="$1"
  if [[ -z "$name" ]]; then echo -e "${RED}x${NC} Usage: br workers delete <name>"; exit 1; fi
  echo -e "${YELLOW}?${NC} Delete worker '${BOLD}$name${NC}'? [y/N] "
  read -r confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo -e "${GRAY}Cancelled.${NC}"; exit 0
  fi
  local result; result=$(cf_api "/workers/scripts/$name" -X DELETE) || return 1
  if echo "$result" | /usr/bin/python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('success',False))" 2>/dev/null | grep -q True; then
    echo -e "${GREEN}Deleted: $name${NC}"
  else
    echo -e "${RED}x Failed${NC}"
  fi
}

cmd_tail() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo -e "${RED}x${NC} Usage: br workers tail <name>"
    echo -e "${GRAY}Tip: use wrangler tail <name> for live streaming${NC}"
    exit 1
  fi
  echo -e "${CYAN}  Tailing ${BOLD}$name${NC}${CYAN} (via wrangler)...${NC}"
  wrangler tail "$name" 2>&1
}

cmd_deploy() {
  local dir="${1:-.}"
  echo -e "${CYAN}  Deploying from ${BOLD}$dir${NC}..."
  cd "$dir" && wrangler deploy
}

cmd_routes() {
  local name="$1"
  if [[ -z "$name" ]]; then
    # List all routes across all zones
    echo -e "\n${CYAN}${BOLD}  WORKER ROUTES${NC}\n"
    local result; result=$(cf_api "/workers/routes") || return 1
    echo "$result" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
routes=d.get('result',[])
for r in routes:
    print(f\"  {r.get('pattern','?'):<50}  {r.get('script','none')}\")
print(f\"\n  {len(routes)} routes\")
" 2>/dev/null
    echo ""
  fi
}

cmd_usage() {
  local name="$1"
  if [[ -z "$name" ]]; then echo -e "${RED}x${NC} Usage: br workers usage <name>"; exit 1; fi
  local result; result=$(cf_api "/workers/scripts/$name/usage-model") || return 1
  echo "$result" | /usr/bin/python3 -c "import sys,json;d=json.load(sys.stdin);print(json.dumps(d.get('result',{}),indent=2))" 2>/dev/null
}

show_help() {
  echo -e "\n${BOLD}  BR WORKERS${NC}  Cloudflare Workers Manager\n"
  echo -e "  ${CYAN}br workers list${NC}               List all workers"
  echo -e "  ${CYAN}br workers get <name>${NC}          Show worker source"
  echo -e "  ${CYAN}br workers delete <name>${NC}       Delete a worker"
  echo -e "  ${CYAN}br workers tail <name>${NC}         Tail worker logs (via wrangler)"
  echo -e "  ${CYAN}br workers deploy [dir]${NC}        Deploy worker from directory"
  echo -e "  ${CYAN}br workers routes${NC}              List all worker routes"
  echo -e "  ${CYAN}br workers usage <name>${NC}        Worker usage model"
  echo ""
}

case "$1" in
  list|ls)      cmd_list ;;
  get|show)     cmd_get "$2" ;;
  delete|rm)    cmd_delete "$2" ;;
  tail|logs)    cmd_tail "$2" ;;
  deploy)       cmd_deploy "$2" ;;
  routes)       cmd_routes "$2" ;;
  usage)        cmd_usage "$2" ;;
  *)            show_help ;;
esac
