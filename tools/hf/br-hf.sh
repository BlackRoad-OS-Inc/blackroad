#!/usr/bin/env zsh
# BR HuggingFace — model & dataset management from Pi agents
# Usage: br hf [login|push|pull|list|search|space|status]
#
# Requires: pip3 install huggingface_hub[cli]
# Token:    br hf login <token>  OR  export HF_TOKEN=hf_...

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'
BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

TOKEN_FILE="$HOME/.blackroad/hf_token"
HF_CACHE="$HOME/.cache/huggingface"

_hf_token() {
  local tok=""
  [[ -f "$TOKEN_FILE" ]] && IFS= read -r tok < "$TOKEN_FILE"
  [[ -z "$tok" ]] && tok="${HF_TOKEN:-}"
  printf '%s' "$tok"
}

_check_hf() {
  python3 -c "import huggingface_hub" 2>/dev/null && return 0
  echo "  ${RED}✗ huggingface_hub not installed${NC}"
  echo "  Install: pip3 install 'huggingface_hub[cli]'"
  return 1
}

cmd_login() {
  local token="$1"
  [[ -z "$token" ]] && { echo "  Usage: br hf login <token>"; return 1; }
  mkdir -p "$(dirname "$TOKEN_FILE")"
  printf '%s' "$token" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  _check_hf || return 1
  python3 -c "
from huggingface_hub import HfApi
api = HfApi(token='$token')
u = api.whoami()
print(f'  Logged in as: {u[\"name\"]}')
print(f'  Orgs: {[\", \".join(o[\"name\"] for o in u.get(\"orgs\",[])[:3])]}')
" 2>/dev/null || echo "  ${YELLOW}⚠ Could not verify token${NC}"
  echo "  ${GREEN}✓ Token saved${NC}"
}

cmd_whoami() {
  local tok; tok=$(_hf_token)
  [[ -z "$tok" ]] && { echo "  ${RED}Not logged in${NC}. Run: br hf login <token>"; return 1; }
  _check_hf || return 1
  python3 -c "
from huggingface_hub import HfApi
api = HfApi(token='$tok')
u = api.whoami()
print()
print(f'  👤 {u[\"name\"]} ({u.get(\"email\",\"no email\")})')
print(f'  🏢 Orgs: {[\", \".join(o[\"name\"] for o in u.get(\"orgs\",[]))]}')
print()
" 2>/dev/null
}

cmd_list() {
  local tok; tok=$(_hf_token)
  _check_hf || return 1
  echo ""
  echo "  ${BOLD}${PINK}◈ YOUR MODELS${NC}"
  python3 -c "
from huggingface_hub import HfApi
api = HfApi(token='$tok')
models = list(api.list_models(author=api.whoami()['name'] if '$tok' else None, limit=20))
for m in models[:15]:
    lid = m.modelId
    updated = str(m.lastModified)[:10] if m.lastModified else '?'
    dl = getattr(m, 'downloads', 0) or 0
    print(f'  {lid:<50} {updated}  ↓{dl}')
if not models:
    print('  No models found')
print()
" 2>/dev/null
}

cmd_push() {
  local src="${1:-.}"
  local repo="$2"
  local tok; tok=$(_hf_token)
  [[ -z "$tok" ]] && { echo "  ${RED}Not logged in${NC}"; return 1; }
  [[ -z "$repo" ]] && { echo "  Usage: br hf push <local-path> <org/repo-name>"; return 1; }
  _check_hf || return 1
  echo "  ${CYAN}↑ Pushing $src → hf.co/$repo${NC}"
  python3 -c "
from huggingface_hub import HfApi
import os
api = HfApi(token='$tok')
api.create_repo('$repo', repo_type='model', exist_ok=True)
api.upload_folder(folder_path='$src', repo_id='$repo', repo_type='model', commit_message='Upload from BlackRoad Pi agent')
print('  ${GREEN}✓ Pushed to hf.co/$repo${NC}')
" 2>/dev/null && echo "  ${GREEN}✓ Done${NC}" || echo "  ${RED}✗ Push failed${NC}"
}

cmd_pull() {
  local repo="$1"
  local dst="${2:-.}"
  local tok; tok=$(_hf_token)
  [[ -z "$repo" ]] && { echo "  Usage: br hf pull <org/model> [local-path]"; return 1; }
  _check_hf || return 1
  echo "  ${CYAN}↓ Pulling hf.co/$repo → $dst${NC}"
  python3 -c "
from huggingface_hub import snapshot_download
path = snapshot_download(repo_id='$repo', local_dir='$dst', token='$tok' or None)
print(f'  Saved to: {path}')
" 2>/dev/null && echo "  ${GREEN}✓ Done${NC}" || echo "  ${RED}✗ Pull failed${NC}"
}

cmd_search() {
  local query="$1"
  [[ -z "$query" ]] && { echo "  Usage: br hf search <query>"; return 1; }
  _check_hf || return 1
  echo ""
  echo "  ${BOLD}${PINK}◈ SEARCH: $query${NC}"
  python3 -c "
from huggingface_hub import HfApi
api = HfApi()
models = list(api.list_models(search='$query', limit=10, sort='downloads', direction=-1))
for m in models[:10]:
    dl = getattr(m, 'downloads', 0) or 0
    print(f'  {m.modelId:<55} ↓{dl:,}')
print()
" 2>/dev/null
}

cmd_space() {
  local tok; tok=$(_hf_token)
  _check_hf || return 1
  echo ""
  echo "  ${BOLD}${PINK}◈ SPACES${NC}"
  python3 -c "
from huggingface_hub import HfApi
api = HfApi(token='$tok' or None)
spaces = list(api.list_spaces(limit=10))
for s in spaces[:10]:
    print(f'  {s.id:<50}  {getattr(s, \"sdk\", \"?\")}')
if not spaces:
    print('  No spaces found')
print()
" 2>/dev/null
}

cmd_status() {
  local tok; tok=$(_hf_token)
  echo ""
  echo "  ${BOLD}${PINK}◈ HUGGINGFACE STATUS${NC}"
  echo "  ${DIM}──────────────────────────────────${NC}"
  [[ -n "$tok" ]] && echo "  Token   : ${GREEN}✓ set ($(echo "$tok" | head -c 10)...)${NC}" || echo "  Token   : ${RED}✗ not set${NC}"
  _check_hf 2>/dev/null && echo "  Library : ${GREEN}✓ huggingface_hub installed${NC}" || echo "  Library : ${RED}✗ not installed${NC}"
  command -v huggingface-cli &>/dev/null && echo "  CLI     : ${GREEN}✓ $(huggingface-cli --version 2>/dev/null | head -1)${NC}" || echo "  CLI     : ${DIM}not in PATH (use python3 -m huggingface_hub)${NC}"
  [[ -d "$HF_CACHE" ]] && echo "  Cache   : ${DIM}$HF_CACHE${NC}" || echo "  Cache   : ${DIM}not yet created${NC}"
  echo ""
  [[ -z "$tok" ]] && echo "  Get token: ${CYAN}https://huggingface.co/settings/tokens${NC}"
  echo ""
}

cmd_deploy_token() {
  # Deploy HF token to all Pi nodes
  local tok="${1:-$(_hf_token)}"
  [[ -z "$tok" ]] && { echo "  Usage: br hf deploy-token <hf_token>"; return 1; }
  echo "  ${CYAN}Deploying HF token to Pi fleet...${NC}"
  for HOST in octavia alice aria gematria; do
    ssh -o ConnectTimeout=4 -o BatchMode=yes "$HOST" "
      mkdir -p ~/.blackroad
      printf '%s' '$tok' > ~/.blackroad/hf_token
      chmod 600 ~/.blackroad/hf_token
      echo 'export HF_TOKEN=\$(cat ~/.blackroad/hf_token)' >> ~/.bashrc 2>/dev/null
      echo \"\$(hostname): hf token set\"
    " 2>/dev/null && echo "  ${GREEN}✓ $HOST${NC}" || echo "  ${YELLOW}⚠ $HOST offline${NC}"
  done
}

show_help() {
  echo ""
  echo "  ${BOLD}${PINK}BR HuggingFace${NC}  ${DIM}model & dataset management from Pi agents${NC}"
  echo ""
  echo "  ${CYAN}br hf login <token>${NC}          Save HF token"
  echo "  ${CYAN}br hf status${NC}                 Show connection status"
  echo "  ${CYAN}br hf whoami${NC}                 Show logged-in user"
  echo "  ${CYAN}br hf list${NC}                   List your models"
  echo "  ${CYAN}br hf search <query>${NC}          Search models"
  echo "  ${CYAN}br hf push <path> <org/repo>${NC}  Upload model to HF"
  echo "  ${CYAN}br hf pull <org/repo> [path]${NC}  Download model from HF"
  echo "  ${CYAN}br hf space${NC}                  List your spaces"
  echo "  ${CYAN}br hf deploy-token <token>${NC}    Deploy token to all Pi nodes"
  echo ""
  echo "  Token: ${DIM}https://huggingface.co/settings/tokens${NC}"
  echo ""
}

case "${1:-status}" in
  login)         cmd_login "${2:-}" ;;
  whoami|me)     cmd_whoami ;;
  list|ls)       cmd_list ;;
  push|upload)   cmd_push "${2:-.}" "${3:-}" ;;
  pull|download) cmd_pull "${2:-}" "${3:-.}" ;;
  search|find)   cmd_search "${2:-}" ;;
  space|spaces)  cmd_space ;;
  status|info)   cmd_status ;;
  deploy-token)  cmd_deploy_token "${2:-}" ;;
  help|*)        show_help ;;
esac
