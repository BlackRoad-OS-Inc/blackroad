#!/bin/zsh
# BR Org Sync — pull/push across all GitHub orgs
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

BLACKROAD_ROOT="/Users/alexa/blackroad"
ORGS_DIR="$BLACKROAD_ROOT/orgs"

print_header() {
  echo "\n${BLUE}╔═══════════════════════════════════════╗${NC}"
  echo "${BLUE}║  ${CYAN}BR Org Sync — Cross-Org Git Manager${NC}  ${BLUE}║${NC}"
  echo "${BLUE}╚═══════════════════════════════════════╝${NC}\n"
}

sync_org_repos() {
  local org_dir="$1" org_name="$2"
  echo "${CYAN}📦 Syncing $org_name...${NC}"
  local ok=0 fail=0

  for dir in "$org_dir"/*/; do
    local name=$(basename "$dir")
    if [ ! -d "$dir/.git" ]; then continue; fi

    local remote=$(cd "$dir" && git remote get-url origin 2>/dev/null)
    if [[ "$remote" == *"BlackRoad-OS-Inc/blackroad.git"* ]]; then
      echo "  ${YELLOW}⚠ $name — wrong remote (monorepo), skipping${NC}"
      continue
    fi

    cd "$dir"
    if git fetch origin --quiet 2>/dev/null; then
      local behind=$(git rev-list HEAD..origin/$(git branch --show-current 2>/dev/null || echo main) --count 2>/dev/null || echo "0")
      if [ "$behind" -gt 0 ] 2>/dev/null; then
        echo "  ${YELLOW}↓ $name — $behind commits behind${NC}"
        git pull --rebase --quiet 2>/dev/null && echo "  ${GREEN}✓ $name pulled${NC}" || echo "  ${RED}✗ $name pull failed${NC}"
      else
        echo "  ${GREEN}✓ $name — up to date${NC}"
      fi
      ((ok++))
    else
      echo "  ${RED}✗ $name — fetch failed${NC}"
      ((fail++))
    fi
  done

  echo "  ${GREEN}$ok ok${NC} | ${RED}$fail failed${NC}\n"
}

push_all() {
  echo "${CYAN}🚀 Pushing all orgs with uncommitted changes...${NC}"
  for dir in "$ORGS_DIR"/*/*/; do
    [ -d "$dir/.git" ] || continue
    cd "$dir"
    local name=$(basename "$dir")
    local changes=$(git status --short | wc -l | tr -d ' ')
    if [ "$changes" -gt 0 ]; then
      echo "  ${YELLOW}↑ $name has $changes changes${NC}"
    fi
  done
}

status_all() {
  echo "${CYAN}📊 Org Status Overview:${NC}\n"

  echo "${BLUE}▶ BlackRoad-OS-Inc (20 repos)${NC}"
  gh api orgs/BlackRoad-OS-Inc/repos --jq '.[] | "  \(.name) [\(.visibility)] — \(.pushed_at[:10])"' 2>/dev/null | head -10

  echo "\n${BLUE}▶ BlackRoad-OS (1229 repos)${NC}"
  gh api orgs/BlackRoad-OS/repos --jq '.[] | "  \(.name) [\(.visibility)]"' 2>/dev/null | head -5
  echo "  ... (use 'br org-sync list BlackRoad-OS' for full list)"

  echo "\n${BLUE}▶ blackboxprogramming (30 repos)${NC}"
  gh api users/blackboxprogramming/repos --jq '.[] | "  \(.name) — \(.pushed_at[:10])"' 2>/dev/null | head -10
}

case "$1" in
  pull|sync)
    print_header
    sync_org_repos "$ORGS_DIR/core" "core"
    sync_org_repos "$ORGS_DIR/ai" "ai"
    sync_org_repos "$ORGS_DIR/enterprise" "enterprise"
    sync_org_repos "$ORGS_DIR/personal" "personal"
    ;;
  push)
    print_header
    push_all
    ;;
  status)
    print_header
    status_all
    ;;
  list)
    ORG="${2:-BlackRoad-OS-Inc}"
    echo "${CYAN}Repos in $ORG:${NC}"
    gh api orgs/$ORG/repos --paginate --jq '.[] | "\(.name) [\(.visibility)] \(.pushed_at[:10])"' 2>/dev/null | sort
    ;;
  fix-remotes)
    print_header
    echo "${CYAN}🔧 Fixing wrong remotes...${NC}"
    "$BLACKROAD_ROOT/scripts/fix-orgs-remotes.sh" 2>/dev/null || echo "Run: scripts/fix-orgs-remotes.sh"
    ;;
  *)
    print_header
    echo "  ${CYAN}br org-sync${NC} [command]"
    echo ""
    echo "  pull          Pull latest for all org repos"
    echo "  push          Show repos with uncommitted changes"
    echo "  status        Show all org overview"
    echo "  list [org]    List repos in an org"
    echo "  fix-remotes   Fix incorrect git remotes"
    echo ""
    echo "  Orgs: BlackRoad-OS-Inc | BlackRoad-OS | blackboxprogramming | Blackbox-Enterprises"
    ;;
esac
