#!/bin/zsh
# BR VERCEL — Vercel Deployments Manager
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='[0;32m'; RED='[0;31m'; YELLOW='[1;33m'; CYAN='[0;36m'
GRAY='[0;37m'; BOLD='[1m'; NC='[0m'

get_token() {
  local tf="$HOME/.blackroad/vercel_token"
  local tok=""
  [[ -f "$tf" ]] && IFS= read -r tok < "$tf"
  [[ -z "$tok" ]] && tok="${VERCEL_TOKEN:-}"
  printf '%s' "$tok"
}

v_api() {
  local path="$1"; shift
  local token; token=$(get_token)
  [[ -z "$token" ]] && { echo -e "${RED}x${NC} No Vercel token. Run: br vercel auth <token>" >&2; return 1; }
  /usr/bin/curl -s -H "Authorization: Bearer $token" -H "Content-Type: application/json" "$@" "https://api.vercel.com$path"
}

cmd_auth() {
  [[ -z "$1" ]] && { echo -e "${RED}x${NC} Usage: br vercel auth <token>"; exit 1; }
  printf '%s' "$1" > "$HOME/.blackroad/vercel_token"
  chmod 600 "$HOME/.blackroad/vercel_token"
  echo -e "${GREEN}  ✓ Vercel token saved${NC}"
}

cmd_projects() {
  echo -e "
${CYAN}${BOLD}  VERCEL PROJECTS${NC}
"
  v_api "/v9/projects?limit=50" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
projects=d.get('projects',[])
print(f'  {len(projects)} projects\n')
for p in projects:
    name=p.get('name','?')
    fwk=p.get('framework') or 'static'
    latest=p.get('latestDeployments',[{}])
    state=(latest[0] if latest else {}).get('readyState','?')
    color='\033[0;32m' if state=='READY' else '\033[0;31m' if state=='ERROR' else '\033[1;33m'
    print(f'  {color}●\033[0m {name:<40} {fwk:<12} {state}')
" 2>/dev/null
  echo ""
}

cmd_deployments() {
  echo -e "
${CYAN}${BOLD}  DEPLOYMENTS${NC}
"
  local path="/v6/deployments?limit=20"
  [[ -n "$1" ]] && path="/v6/deployments?limit=20&projectId=$1"
  v_api "$path" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
deps=d.get('deployments',[])
for dep in deps:
    name=dep.get('name','?')
    state=dep.get('state','?')
    url=dep.get('url','?')
    color='\033[0;32m' if state=='READY' else '\033[0;31m' if state in ('ERROR','CANCELED') else '\033[1;33m'
    print(f'  {color}●\033[0m {name:<35} {state:<10} https://{url}')
print(f'\n  {len(deps)} deployments')
" 2>/dev/null
  echo ""
}

cmd_env() {
  local project="$1"
  [[ -z "$project" ]] && { echo -e "${RED}x${NC} Usage: br vercel env <project>"; exit 1; }
  v_api "/v9/projects/$project/env" | /usr/bin/python3 -c "
import sys,json
d=json.load(sys.stdin)
envs=d.get('envs',[])
for e in envs:
    key=e.get('key','?')
    target=','.join(e.get('target',[]))
    print(f'  {key:<40} [{target}]')
print(f'\n  {len(envs)} vars')
" 2>/dev/null
}

show_help() {
  echo -e "
${BOLD}  BR VERCEL${NC}  Deployment Manager
"
  echo -e "  ${CYAN}br vercel auth <token>${NC}         Save Vercel token"
  echo -e "  ${CYAN}br vercel projects${NC}             List all projects"
  echo -e "  ${CYAN}br vercel deployments [proj]${NC}   Recent deployments"
  echo -e "  ${CYAN}br vercel env <project>${NC}        List env vars"
  echo ""
}

case "$1" in
  auth)          cmd_auth "$2" ;;
  projects|ls)   cmd_projects ;;
  deployments|d) cmd_deployments "$2" ;;
  env)           cmd_env "$2" ;;
  *)             show_help ;;
esac
