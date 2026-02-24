#!/bin/zsh
# BR PR - GitHub Pull Request Manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

show_help() {
  echo -e "${CYAN}${BOLD}BR PR${NC}"
  echo "  br pr list [repo]       List open PRs"
  echo "  br pr view <number>     View a PR"
  echo "  br pr create <title>    Create a PR"
  echo "  br pr merge <number>    Merge a PR"
  echo "  br pr close <number>    Close a PR"
  echo "  br pr review <number>   Open PR in browser"
  echo "  br pr status            Check PR CI status"
  echo ""
  echo -e "  ${YELLOW}Requires: gh CLI authenticated${NC}"
}

get_repo() {
  git remote get-url origin 2>/dev/null | \
    sed 's|https://github.com/||;s|git@github.com:||;s|\.git$||' | \
    head -1
}

cmd_list() {
  local REPO="${1:-$(get_repo)}"
  if [[ -z "$REPO" ]]; then
    echo -e "${RED}Not in a git repo or repo not set${NC}"
    return 1
  fi
  echo -e "${CYAN}Open PRs: $REPO${NC}\n"
  gh pr list --repo "$REPO" --limit 20 \
    --json number,title,author,createdAt,headRefName \
    2>/dev/null | python3 -c "
import json, sys
prs = json.load(sys.stdin)
if not prs:
    print('  No open PRs')
    sys.exit()
for pr in prs:
    print(f'  #{pr[\"number\"]} {pr[\"title\"]}')
    print(f'       by {pr[\"author\"][\"login\"]} on {pr[\"headRefName\"]}')
" 2>/dev/null || gh pr list --repo "$REPO" 2>/dev/null || \
  echo -e "${RED}gh CLI not authenticated${NC}"
}

cmd_view() {
  local NUMBER="$1"
  if [[ -z "$NUMBER" ]]; then
    echo -e "${RED}Usage: br pr view <number>${NC}"
    return 1
  fi
  local REPO=$(get_repo)
  gh pr view "$NUMBER" --repo "$REPO" 2>/dev/null || \
    echo -e "${RED}PR #$NUMBER not found or gh not authenticated${NC}"
}

cmd_create() {
  local TITLE="${*:-}"
  if [[ -z "$TITLE" ]]; then
    echo -e "${RED}Usage: br pr create <title>${NC}"
    return 1
  fi
  BRANCH=$(git branch --show-current 2>/dev/null)
  echo -e "${CYAN}Creating PR: \"$TITLE\"${NC}"
  echo -e "  Branch: $BRANCH"
  gh pr create --title "$TITLE" --body "Created via br pr" 2>/dev/null && \
    echo -e "${GREEN}✓ PR created${NC}" || \
    echo -e "${RED}Failed — ensure gh is authenticated and branch is pushed${NC}"
}

cmd_merge() {
  local NUMBER="$1"
  local REPO=$(get_repo)
  echo -e "${CYAN}Merging PR #$NUMBER${NC}"
  gh pr merge "$NUMBER" --repo "$REPO" --squash 2>/dev/null && \
    echo -e "${GREEN}✓ Merged${NC}" || \
    echo -e "${RED}Failed to merge PR #$NUMBER${NC}"
}

cmd_close() {
  local NUMBER="$1"
  local REPO=$(get_repo)
  echo -e "${YELLOW}Closing PR #$NUMBER${NC}"
  gh pr close "$NUMBER" --repo "$REPO" 2>/dev/null && \
    echo -e "${GREEN}✓ Closed${NC}" || \
    echo -e "${RED}Failed to close PR #$NUMBER${NC}"
}

cmd_review() {
  local NUMBER="$1"
  local REPO=$(get_repo)
  URL="https://github.com/$REPO/pull/$NUMBER"
  echo -e "${CYAN}Opening: $URL${NC}"
  open "$URL" 2>/dev/null || xdg-open "$URL" 2>/dev/null || echo "$URL"
}

cmd_status() {
  local REPO=$(get_repo)
  echo -e "${CYAN}PR CI Status: $REPO${NC}\n"
  gh pr list --repo "$REPO" --limit 5 \
    --json number,title,statusCheckRollup 2>/dev/null | python3 -c "
import json, sys
prs = json.load(sys.stdin)
for pr in prs:
    status = pr.get('statusCheckRollup') or []
    passed = sum(1 for s in status if s.get('conclusion') == 'SUCCESS')
    failed = sum(1 for s in status if s.get('conclusion') == 'FAILURE')
    print(f'  #{pr[\"number\"]} {pr[\"title\"]}')
    print(f'       checks: {passed} passed, {failed} failed')
" 2>/dev/null || echo -e "${YELLOW}Status unavailable${NC}"
}

case "${1:-help}" in
  list)   cmd_list "$2" ;;
  view)   cmd_view "$2" ;;
  create) cmd_create "${@:2}" ;;
  merge)  cmd_merge "$2" ;;
  close)  cmd_close "$2" ;;
  review) cmd_review "$2" ;;
  status) cmd_status ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    show_help ;;
esac
