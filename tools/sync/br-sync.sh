#!/usr/bin/env zsh
# BR Sync — sync all blackroad-* sub-repos to their remotes in one pass
# br sync [status|push|pull|dirty|all]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"

# Find all git repos inside BR_ROOT (one level deep sub-repos only)
find_subrepos() {
  for d in "$BR_ROOT"/blackroad-*/; do
    [[ -d "$d/.git" ]] && echo "$d"
  done
}

# Status of a single repo
repo_status() {
  local dir="$1"
  local name=$(basename "$dir")
  local branch dirty ahead behind remote_url

  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  dirty=$(git -C "$dir" status --short 2>/dev/null | grep -v "^?" | wc -l | tr -d ' ')
  ahead=$(git -C "$dir" rev-list HEAD..@{u} --count 2>/dev/null || echo "?")
  behind=$(git -C "$dir" rev-list @{u}..HEAD --count 2>/dev/null || echo "?")
  remote_url=$(git -C "$dir" remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')

  local dcol="${DIM}"; [[ "$dirty" -gt 0 ]] && dcol="${AMBER}"
  local acol="${DIM}"; [[ "$ahead" -gt 0 ]] 2>/dev/null && acol="${VIOLET}"
  printf "  ${BOLD}%-30s${NC} branch ${CYAN}%-12s${NC} dirty ${dcol}%s${NC} ahead ${acol}%s${NC}  ${DIM}%s${NC}\n" \
    "$name" "${branch:-?}" "$dirty" "$ahead" "$remote_url"
}

cmd_status() {
  echo ""
  echo "  ${PINK}${BOLD}◈ SUBREPO STATUS${NC}"
  echo "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
  echo ""
  local count=0
  for dir in $(find_subrepos); do
    repo_status "$dir"
    ((count++))
  done
  [[ "$count" -eq 0 ]] && echo "  ${DIM}No blackroad-* sub-repos found in $BR_ROOT${NC}"
  echo ""
  echo "  ${DIM}$count repos checked${NC}"
  echo ""
}

cmd_dirty() {
  echo ""
  echo "  ${PINK}${BOLD}◈ DIRTY REPOS${NC}"
  echo ""
  local found=0
  for dir in $(find_subrepos); do
    local name=$(basename "$dir")
    local dirty=$(git -C "$dir" status --short 2>/dev/null | grep -v "^?" | wc -l | tr -d ' ')
    if [[ "$dirty" -gt 0 ]]; then
      echo "  ${AMBER}●${NC} ${BOLD}$name${NC}  ${AMBER}$dirty unstaged${NC}"
      git -C "$dir" status --short 2>/dev/null | grep -v "^?" | head -5 | sed 's/^/    /'
      echo ""
      ((found++))
    fi
  done
  [[ "$found" -eq 0 ]] && echo "  ${GREEN}✓ All repos clean${NC}"
  echo ""
}

_push_one() {
  local dir="$1"
  local name=$(basename "$dir")
  local branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  local dirty=$(git -C "$dir" status --short 2>/dev/null | grep -v "^?" | wc -l | tr -d ' ')

  printf "  %-30s " "$name"

  if [[ "$dirty" -gt 0 ]]; then
    git -C "$dir" add -A 2>/dev/null
    git -C "$dir" commit -m "chore: sync from blackroad monorepo [auto]

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" --quiet 2>/dev/null
  fi

  local ahead=$(git -C "$dir" rev-list HEAD..@{u} --count 2>/dev/null || echo "0")
  if [[ "$ahead" -gt 0 ]] 2>/dev/null; then
    if git -C "$dir" push --quiet 2>/dev/null; then
      echo "${GREEN}✓ pushed${NC} ($ahead commits)"
    else
      echo "${RED}✗ push failed${NC}"
    fi
  else
    echo "${DIM}up to date${NC}"
  fi
}

cmd_push() {
  local filter="${1:-all}"
  echo ""
  echo "  ${PINK}${BOLD}◈ SYNCING REPOS → REMOTE${NC}"
  echo ""
  for dir in $(find_subrepos); do
    local name=$(basename "$dir")
    [[ "$filter" != "all" && "$name" != *"$filter"* ]] && continue
    # Skip repos with no remote
    git -C "$dir" remote get-url origin &>/dev/null || continue
    _push_one "$dir"
  done
  echo ""
  echo "  ${GREEN}✓ Sync complete${NC}"
  echo ""
}

cmd_pull() {
  echo ""
  echo "  ${PINK}${BOLD}◈ PULLING ALL REPOS${NC}"
  echo ""
  for dir in $(find_subrepos); do
    local name=$(basename "$dir")
    printf "  %-30s " "$name"
    git -C "$dir" remote get-url origin &>/dev/null || { echo "${DIM}no remote${NC}"; continue; }
    if git -C "$dir" pull --quiet --ff-only 2>/dev/null; then
      echo "${GREEN}✓${NC}"
    else
      echo "${YELLOW}conflict or non-ff${NC}"
    fi
  done
  echo ""
}

# Sync just the main blackroad repo to operator
cmd_operator() {
  echo ""
  echo "  ${PINK}${BOLD}◈ SYNC MAIN → OPERATOR${NC}"
  echo ""
  cd "$BR_ROOT" || exit 1
  local dirty=$(git status --short | grep -v "^?" | wc -l | tr -d ' ')
  if [[ "$dirty" -gt 0 ]]; then
    echo "  ${AMBER}$dirty dirty files — committing…${NC}"
    git add -A
    git commit -m "chore: auto-sync dirty files

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" --quiet
  fi
  local ahead=$(git rev-list HEAD..operator/master --count 2>/dev/null || echo "0")
  echo "  ${CYAN}$ahead commits ahead of operator/master${NC}"
  if [[ "$ahead" -gt 0 ]]; then
    echo "  Pushing to operator/master…"
    git push operator master 2>&1 | tail -2 | sed 's/^/  /'
    echo "  Merging to main via API…"
    local sha
    sha=$(gh api repos/BlackRoad-OS-Inc/blackroad-operator/merges \
      -X POST -f base=main -f head=master \
      -f commit_message="Merge master: auto-sync" 2>/dev/null \
      | python3 -c "import json,sys; print(json.load(sys.stdin).get('sha','?')[:12])" 2>/dev/null)
    [[ -n "$sha" ]] && echo "  ${GREEN}✓ Merged → main@$sha${NC}" || echo "  ${DIM}Already up to date${NC}"
  else
    echo "  ${DIM}Nothing to push${NC}"
  fi
  echo ""
}

cmd_gdrive() {
  local subcmd="${1:-status}"
  local RCLONE_REMOTE="${BLACKROAD_GDRIVE_REMOTE:-gdrive}"
  local GDRIVE_PATH="$RCLONE_REMOTE:blackroad"
  local LOCAL_PATH="$BR_ROOT"
  local EXCLUDE="--exclude .git/** --exclude node_modules/** --exclude .DS_Store --exclude __pycache__/**"

  if ! command -v rclone &>/dev/null; then
    echo "  ${RED}✗ rclone not installed${NC}"
    echo "  Install: brew install rclone  (mac) or curl https://rclone.org/install.sh | sudo bash"
    echo "  Config:  rclone config  (select Google Drive, name it '$RCLONE_REMOTE')"
    return 1
  fi

  case "$subcmd" in
    status|ls)
      echo ""
      echo "  ${PINK}${BOLD}◈ GOOGLE DRIVE SYNC STATUS${NC}"
      echo ""
      rclone lsd "$GDRIVE_PATH" 2>/dev/null && echo "" || echo "  ${DIM}Not yet synced to $GDRIVE_PATH${NC}"
      ;;
    push|up|upload)
      echo "  ${CYAN}↑ Pushing to Google Drive ($GDRIVE_PATH)...${NC}"
      rclone sync "$LOCAL_PATH" "$GDRIVE_PATH" $=EXCLUDE \
        --progress --stats-one-line --transfers 8 \
        --log-level INFO 2>&1 | tail -5
      echo "  ${GREEN}✓ Pushed to Google Drive${NC}"
      ;;
    pull|down|download)
      echo "  ${CYAN}↓ Pulling from Google Drive ($GDRIVE_PATH)...${NC}"
      rclone sync "$GDRIVE_PATH" "$LOCAL_PATH" $=EXCLUDE \
        --progress --stats-one-line --transfers 8 \
        --log-level INFO 2>&1 | tail -5
      echo "  ${GREEN}✓ Pulled from Google Drive${NC}"
      ;;
    bi|bisync|both)
      echo "  ${CYAN}⇅ Bidirectional sync with Google Drive...${NC}"
      rclone bisync "$LOCAL_PATH" "$GDRIVE_PATH" $=EXCLUDE \
        --progress --resilient --recover 2>&1 | tail -10
      echo "  ${GREEN}✓ Bisync complete${NC}"
      ;;
    setup)
      echo ""
      echo "  ${BOLD}Setup Google Drive sync:${NC}"
      echo ""
      echo "  1. Install rclone:   ${CYAN}brew install rclone${NC}"
      echo "  2. Configure:        ${CYAN}rclone config${NC}"
      echo "     → Select: New remote → n → gdrive → Google Drive → OAuth flow"
      echo "     → Name it: ${CYAN}gdrive${NC}"
      echo "  3. Test:             ${CYAN}rclone lsd gdrive:${NC}"
      echo "  4. First sync:       ${CYAN}br sync gdrive up${NC}"
      echo ""
      echo "  Env var (optional):  ${DIM}BLACKROAD_GDRIVE_REMOTE=gdrive${NC}"
      echo ""
      ;;
    *)
      echo "  Usage: br sync gdrive [status|push|pull|bi|setup]"
      ;;
  esac
}

show_help() {
  echo ""
  echo "  ${PINK}${BOLD}br sync${NC}  — sync all sub-repos + Google Drive"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}status${NC}          Show all repo states (branch/dirty/ahead)"
  echo "    ${CYAN}dirty${NC}           Show only repos with uncommitted changes"
  echo "    ${CYAN}push [filter]${NC}   Commit+push all dirty repos (opt: name filter)"
  echo "    ${CYAN}pull${NC}            Pull all repos from remote"
  echo "    ${CYAN}operator${NC}        Sync main blackroad repo → operator/master + merge to main"
  echo "    ${CYAN}gdrive [push|pull|bi|setup]${NC}  Sync to/from Google Drive via rclone"
  echo ""
}

case "${1:-status}" in
  status|ls|list) cmd_status ;;
  dirty|changed)  cmd_dirty ;;
  push|sync|all)  cmd_push "$2" ;;
  pull|fetch)     cmd_pull ;;
  operator|op)    cmd_operator ;;
  gdrive|drive|google) cmd_gdrive "${2:-status}" ;;
  help|*)         show_help ;;
esac
