#!/bin/zsh
# BR RAILWAY — Railway Projects Manager
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='[0;32m'; RED='[0;31m'; YELLOW='[1;33m'; CYAN='[0;36m'
GRAY='[0;37m'; BOLD='[1m'; NC='[0m'

get_token() {
  local tf="$HOME/.blackroad/railway_token"
  local tok=""
  [[ -f "$tf" ]] && IFS= read -r tok < "$tf"
  [[ -z "$tok" ]] && tok="${RAILWAY_TOKEN:-}"
  printf '%s' "$tok"
}

cmd_auth() {
  [[ -z "$1" ]] && { echo -e "${RED}x${NC} Usage: br railway auth <token>"; exit 1; }
  printf '%s' "$1" > "$HOME/.blackroad/railway_token"
  chmod 600 "$HOME/.blackroad/railway_token"
  echo -e "${GREEN}  ✓ Railway token saved${NC}"
}

cmd_projects() {
  echo -e "
${CYAN}${BOLD}  RAILWAY PROJECTS${NC}
"
  local token; token=$(get_token)
  [[ -z "$token" ]] && { echo -e "${RED}x${NC} No token. Run: br railway auth <token>"; exit 1; }
  local gql='{"query":"{ projects { edges { node { id name environments { edges { node { name } } } } } } }"}'
  /usr/bin/curl -s -X POST "https://backboard.railway.app/graphql/v2"     -H "Authorization: Bearer $token" -H "Content-Type: application/json"     -d "$gql" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
projects=d.get('data',{}).get('projects',{}).get('edges',[])
print(f'  {len(projects)} projects\n')
for p in projects:
    n=p.get('node',{})
    name=n.get('name','?')
    pid=n.get('id','?')[:8]
    envs=[e.get('node',{}).get('name','') for e in n.get('environments',{}).get('edges',[])]
    print(f'  ● {name:<40} {pid}...  {" | ".join(envs)}')
" 2>/dev/null
  echo ""
}

cmd_status() {
  which railway &>/dev/null && railway status 2>&1 || echo -e "${GRAY}  railway CLI not installed. npm i -g @railway/cli${NC}"
}

cmd_logs() {
  which railway &>/dev/null && railway logs 2>&1 || echo -e "${GRAY}  railway CLI not installed${NC}"
}

cmd_deploy() {
  which railway &>/dev/null && railway up 2>&1 || echo -e "${GRAY}  railway CLI not installed${NC}"
}

show_help() {
  echo -e "
${BOLD}  BR RAILWAY${NC}  Railway Projects Manager
"
  echo -e "  ${CYAN}br railway auth <token>${NC}   Save Railway token"
  echo -e "  ${CYAN}br railway projects${NC}       List all 14 projects"
  echo -e "  ${CYAN}br railway status${NC}         Current service status"
  echo -e "  ${CYAN}br railway logs${NC}           Stream service logs"
  echo -e "  ${CYAN}br railway deploy${NC}         Deploy current project"
  echo ""
}

case "$1" in
  auth)       cmd_auth "$2" ;;
  projects|ls) cmd_projects ;;
  status|st)  cmd_status ;;
  logs)       cmd_logs ;;
  deploy|up)  cmd_deploy ;;
  *)          show_help ;;
esac
