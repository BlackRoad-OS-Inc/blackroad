#!/bin/zsh
# BR GIT — Smart Git operations with AI assistance
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

GIT="/usr/bin/git"

# Generate a smart commit message from diff
smart_message() {
  local diff; diff=$($GIT --no-pager diff --cached --stat 2>/dev/null)
  [[ -z "$diff" ]] && diff=$($GIT --no-pager diff --stat 2>/dev/null)
  local files; files=$($GIT --no-pager diff --cached --name-only 2>/dev/null)
  [[ -z "$files" ]] && files=$($GIT --no-pager diff --name-only 2>/dev/null)

  # Detect type from files changed
  local type="chore"
  echo "$files" | grep -qE "\.(tsx?|jsx?)$" && type="feat"
  echo "$files" | grep -qE "test|spec" && type="test"
  echo "$files" | grep -qE "fix|bug" && type="fix"
  echo "$files" | grep -qE "\.sh$" && type="build"
  echo "$files" | grep -qE "route\.ts|api/" && type="feat(api)"
  echo "$files" | grep -qE "README|\.md$" && type="docs"
  echo "$files" | grep -qE "package\.json|requirements" && type="build(deps)"

  # Count files
  local nf; nf=$(echo "$files" | grep -c . 2>/dev/null || echo "0")

  # Pick key file for scope
  local scope; scope=$(echo "$files" | head -1 | xargs basename 2>/dev/null | sed 's/\..*//')

  # Build message
  local msg="${type}(${scope}): update ${nf} file$([ "$nf" -ne 1 ] && echo 's' || true)"

  # Check for specific patterns
  echo "$files" | grep -q "br-" && msg="build: add $(echo "$files" | grep 'br-' | head -1 | xargs basename | sed 's/\.sh//')"
  echo "$files" | grep -q "route.ts" && msg="feat(api): update $(echo "$files" | grep 'route' | head -1 | sed 's|.*/api/||' | sed 's|/.*||') endpoint"
  echo "$files" | grep -q "page.tsx" && msg="feat(ui): update $(echo "$files" | grep 'page.tsx' | head -1 | sed 's|.*/\(app\)/||' | sed 's|/.*||') page"

  printf '%s' "$msg"
}

cmd_status() {
  echo -e "\n${CYAN}${BOLD}  GIT STATUS${NC}\n"
  $GIT --no-pager status --short
  echo ""
  local branch; branch=$($GIT --no-pager rev-parse --abbrev-ref HEAD 2>/dev/null)
  local ahead; ahead=$($GIT --no-pager rev-list @{u}..HEAD --count 2>/dev/null || echo "0")
  echo -e "  ${GRAY}Branch:${NC} ${BOLD}$branch${NC}  ${GRAY}ahead by${NC} $ahead"
  echo ""
}

cmd_commit() {
  local staged; staged=$($GIT --no-pager diff --cached --name-only 2>/dev/null)
  if [[ -z "$staged" ]]; then
    echo -e "${YELLOW}  No staged files. Staging all changes...${NC}"
    $GIT add -A
  fi

  local msg
  if [[ -n "$1" ]]; then
    msg="$*"
  else
    msg=$(smart_message)
    echo -e "\n${CYAN}  Suggested:${NC} ${BOLD}${msg}${NC}"
    echo -e "${GRAY}  Press enter to use, or type a new message:${NC} "
    read -r custom
    [[ -n "$custom" ]] && msg="$custom"
  fi

  msg="${msg}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

  $GIT commit -m "$msg"
  echo -e "\n${GREEN}  ✓ Committed${NC}"
}

cmd_push() {
  local branch; branch=$($GIT --no-pager rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo -e "${CYAN}  Pushing ${BOLD}$branch${NC}${CYAN}...${NC}"
  $GIT push origin "$branch" 2>&1
}

cmd_save() {
  # Stage + smart commit + push in one shot
  $GIT add -A
  local msg=$(smart_message)
  echo -e "${CYAN}  → ${BOLD}$msg${NC}"
  local full_msg="${msg}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
  $GIT commit -m "$full_msg" && $GIT push origin "$($GIT --no-pager rev-parse --abbrev-ref HEAD)" 2>&1 | tail -3
  echo -e "${GREEN}  ✓ Saved & pushed${NC}"
}

cmd_log() {
  echo -e "\n${CYAN}${BOLD}  RECENT COMMITS${NC}\n"
  $GIT --no-pager log --oneline --color -${1:-15} | sed 's/^/  /'
  echo ""
}

cmd_branch() {
  case "$1" in
    list|ls|"")
      echo -e "\n${CYAN}${BOLD}  BRANCHES${NC}\n"
      $GIT --no-pager branch -a --color | sed 's/^/  /'
      echo "" ;;
    new|create)
      [[ -z "$2" ]] && { echo -e "${RED}x${NC} Usage: br git branch new <name>"; exit 1; }
      $GIT checkout -b "$2" && echo -e "${GREEN}  ✓ Created & switched to $2${NC}" ;;
    switch|checkout)
      $GIT checkout "$2" 2>&1 ;;
    delete)
      $GIT branch -d "$2" 2>&1 ;;
  esac
}

cmd_pr() {
  local branch; branch=$($GIT --no-pager rev-parse --abbrev-ref HEAD 2>/dev/null)
  local title="${1:-$(smart_message)}"
  echo -e "${CYAN}  Creating PR: ${BOLD}$title${NC}"
  gh pr create --title "$title" --body "Auto-generated PR from br git pr" --base master 2>&1
}

cmd_diff() {
  echo -e "\n${CYAN}${BOLD}  DIFF${NC}\n"
  $GIT --no-pager diff --color "$@" | head -100
  echo ""
}

cmd_undo() {
  $GIT reset HEAD~1 --soft 2>&1 && echo -e "${GREEN}  ✓ Last commit undone (changes kept staged)${NC}"
}

cmd_suggest() {
  local msg=$(smart_message)
  echo -e "\n${CYAN}  Smart commit message:${NC}\n"
  echo -e "  ${BOLD}${msg}${NC}\n"
}

show_help() {
  echo -e "\n${BOLD}  BR GIT${NC}  Smart Git operations\n"
  echo -e "  ${CYAN}br git status${NC}              Short status + branch info"
  echo -e "  ${CYAN}br git commit [msg]${NC}        Smart commit (suggests message if none)"
  echo -e "  ${CYAN}br git push${NC}                Push current branch"
  echo -e "  ${CYAN}br git save${NC}                Stage + commit + push in one shot ⚡"
  echo -e "  ${CYAN}br git log [n]${NC}             Last N commits (default 15)"
  echo -e "  ${CYAN}br git diff${NC}                Show current diff"
  echo -e "  ${CYAN}br git branch [list|new|switch|delete]${NC}"
  echo -e "  ${CYAN}br git pr [title]${NC}          Create GitHub PR"
  echo -e "  ${CYAN}br git undo${NC}                Undo last commit (keep changes)"
  echo -e "  ${CYAN}br git suggest${NC}             Show AI-suggested commit message"
  echo ""
}

case "$1" in
  status|st)      cmd_status ;;
  commit|ci)      shift; cmd_commit "$@" ;;
  push)           cmd_push ;;
  save|sync)      cmd_save ;;
  log|history)    cmd_log "$2" ;;
  branch|br)      shift; cmd_branch "$@" ;;
  pr)             shift; cmd_pr "$@" ;;
  diff)           shift; cmd_diff "$@" ;;
  undo)           cmd_undo ;;
  suggest|msg)    cmd_suggest ;;
  *)              show_help ;;
esac
