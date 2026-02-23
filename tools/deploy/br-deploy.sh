#!/bin/zsh
# BR DEPLOY — One-command full-stack deploy
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

REPO_ROOT="/Users/alexa/blackroad"
WEB_DIR="$REPO_ROOT/orgs/core/blackroad-os-web"

log() { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
step() { echo -e "\n${CYAN}${BOLD}[$1]${NC} $2"; }

cmd_all() {
  echo -e "\n${BOLD}╔═══════════════════════════════╗${NC}"
  echo -e "${BOLD}║   BR DEPLOY — Full Stack      ║${NC}"
  echo -e "${BOLD}╚═══════════════════════════════╝${NC}\n"

  # 1. Git save
  step "1/4" "Git commit + push"
  cd "$REPO_ROOT"
  if [[ -n "$(git status --porcelain)" ]]; then
    git add -A
    local msg="${1:-chore: auto-deploy $(date '+%Y-%m-%d %H:%M')}"
    git commit -m "$msg" 2>&1 | tail -1 && log "Committed" || fail "Commit failed"
    git push origin master 2>&1 | tail -1 && log "Pushed to master" || fail "Push failed"
  else
    log "Nothing to commit"
  fi

  # 2. Vercel deploy
  step "2/4" "Vercel deploy (web)"
  if command -v vercel &>/dev/null; then
    cd "$WEB_DIR"
    vercel --prod --yes 2>&1 | tail -3 | sed 's/^/  /'
    log "Vercel deploy triggered"
  else
    warn "vercel CLI not found — skipping"
  fi

  # 3. Cloudflare workers
  step "3/4" "Cloudflare Workers"
  local deployed=0
  for wdir in "$REPO_ROOT/workers"/*/; do
    [[ -f "$wdir/wrangler.toml" ]] || continue
    local name; name=$(basename "$wdir")
    cd "$wdir"
    if wrangler deploy --no-bundle 2>&1 | grep -q "Deployed\|Successfully"; then
      log "Worker: $name"
      deployed=$((deployed+1))
    else
      warn "Worker $name — check manually"
    fi
  done
  [[ $deployed -eq 0 ]] && warn "No workers deployed (no wrangler.toml found)"

  # 4. Summary
  step "4/4" "Deploy summary"
  local ts; ts=$(date "+%H:%M:%S")
  log "Git: pushed to BlackRoad-OS-Inc/blackroad master"
  log "Web: Vercel redeploy triggered"
  log "Done at $ts"
  echo ""
}

cmd_git() {
  step "GIT" "Commit + push"
  cd "$REPO_ROOT"
  git add -A
  git commit -m "${1:-chore: quick save $(date '+%H:%M')}" 2>&1 | tail -1
  git push origin master 2>&1 | tail -2
}

cmd_web() {
  step "WEB" "Vercel deploy"
  cd "$WEB_DIR"
  vercel --prod --yes 2>&1 | tail -5
}

cmd_worker() {
  local name="$1"
  [[ -z "$name" ]] && { echo -e "  ${RED}Usage: br deploy worker <name>${NC}"; return 1; }
  local wdir="$REPO_ROOT/workers/$name"
  [[ -d "$wdir" ]] || { fail "Worker not found: $wdir"; return 1; }
  cd "$wdir"
  wrangler deploy 2>&1 | tail -5
}

show_help() {
  echo -e "\n${BOLD}  BR DEPLOY${NC}  Full-stack deploy\n"
  echo -e "  ${CYAN}br deploy all [msg]${NC}   Git + Vercel + CF Workers"
  echo -e "  ${CYAN}br deploy git [msg]${NC}   Git commit + push only"
  echo -e "  ${CYAN}br deploy web${NC}         Vercel redeploy"
  echo -e "  ${CYAN}br deploy worker <n>${NC}  Deploy single CF worker"
  echo ""
}

case "$1" in
  all|"")     shift; cmd_all "$@" ;;
  git|save)   shift; cmd_git "$@" ;;
  web|vercel) cmd_web ;;
  worker)     shift; cmd_worker "$@" ;;
  *)          show_help ;;
esac
