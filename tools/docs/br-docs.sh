#!/bin/zsh
# BR DOCS - Push README/docs to BlackRoad-OS-Inc/blackroad-docs and sync doc files

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

DB_FILE="$HOME/.blackroad/docs-sync.db"
DOCS_REMOTE="docs"
DOCS_REPO="BlackRoad-OS-Inc/blackroad-docs"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  file TEXT NOT NULL,
  action TEXT NOT NULL,
  sha TEXT,
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS doc_files (
  path TEXT PRIMARY KEY,
  last_synced TEXT,
  remote_repo TEXT,
  notes TEXT
);
SQL
}

init_db

cmd_list() {
  echo ""
  echo -e "${BOLD}${CYAN}Tracked doc files:${NC}"
  echo ""
  # list all .md files in root
  local count=0
  local synced mark
  for f in *.md; do
    [[ -f "$f" ]] || continue
    synced=$(sqlite3 "$DB_FILE" "SELECT last_synced FROM doc_files WHERE path='$f';" 2>/dev/null)
    mark="${RED}not synced${NC}"
    [[ -n "$synced" ]] && mark="${GREEN}synced ${synced}${NC}"
    printf "  %-40s  " "$f"
    echo -e "$mark"
    count=$((count+1))
  done
  echo ""
  echo -e "  ${count} doc files found"
  echo ""
}

cmd_push() {
  local target="${1:-README.md}"
  echo ""
  echo -e "${BOLD}${CYAN}Pushing docs to ${DOCS_REPO}...${NC}"
  echo ""

  # build list of files to push
  local files=()
  if [[ "$target" == "all" ]]; then
    for f in *.md; do [[ -f "$f" ]] && files+=("$f"); done
  else
    files=("$target")
  fi

  for f in "${files[@]}"; do
    [[ -f "$f" ]] || { echo -e "  ${RED}✗ Not found: $f${NC}"; continue; }
    echo -ne "  ${CYAN}→ $f${NC} ... "

    # use gh api to upsert file in docs repo
    local content
    content=$(base64 -i "$f" | tr -d '\n')
    local sha
    sha=$(gh api "repos/$DOCS_REPO/contents/$f" --jq '.sha' 2>/dev/null || echo "")

    local result
    if [[ -n "$sha" ]]; then
      result=$(gh api -X PUT "repos/$DOCS_REPO/contents/$f" \
        -F message="docs: sync $f from blackroad-operator" \
        -F content="$content" \
        -F sha="$sha" \
        --jq '.commit.sha' 2>&1)
    else
      result=$(gh api -X PUT "repos/$DOCS_REPO/contents/$f" \
        -F message="docs: add $f from blackroad-operator" \
        -F content="$content" \
        --jq '.commit.sha' 2>&1)
    fi

    if [[ "$result" =~ ^[0-9a-f]{40}$ ]]; then
      echo -e "${GREEN}✓ ${result:0:10}${NC}"
      sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO doc_files(path,last_synced,remote_repo) VALUES('$f',datetime('now'),'$DOCS_REPO');"
      sqlite3 "$DB_FILE" "INSERT INTO sync_log(file,action,sha) VALUES('$f','push','${result:0:16}');"
    else
      echo -e "${RED}✗ ${result:0:60}${NC}"
    fi
  done
  echo ""
}

cmd_status() {
  echo ""
  echo -e "${BOLD}${CYAN}Doc sync status:${NC}"
  echo ""
  local synced
  synced=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM doc_files WHERE last_synced IS NOT NULL;" 2>/dev/null)
  local total_md
  total_md=$(ls *.md 2>/dev/null | wc -l | tr -d ' ')
  echo -e "  Total .md files:  ${total_md}"
  echo -e "  Synced to remote: ${synced:-0}"
  echo ""
  echo -e "${BOLD}Recent syncs:${NC}"
  sqlite3 "$DB_FILE" "SELECT ts, action, file, sha FROM sync_log ORDER BY id DESC LIMIT 10;" 2>/dev/null | \
    while IFS='|' read ts action file sha; do
      echo -e "  ${ts}  ${action}  ${file}  ${sha}"
    done
  echo ""
}

cmd_log() {
  echo ""
  echo -e "${BOLD}${CYAN}Sync log:${NC}"
  sqlite3 "$DB_FILE" "SELECT ts, action, file, sha FROM sync_log ORDER BY id DESC LIMIT 20;" 2>/dev/null | \
    while IFS='|' read ts action file sha; do
      echo -e "  ${CYAN}${ts}${NC}  ${action}  ${file}  ${sha}"
    done
  echo ""
}

cmd_readme() {
  # Quick push just README.md + AGENTS.md + CLAUDE.md
  cmd_push README.md
  cmd_push AGENTS.md
  cmd_push CLAUDE.md
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br docs${NC} — sync docs to BlackRoad-OS-Inc/blackroad-docs"
  echo ""
  echo "  ${CYAN}br docs list${NC}            List all .md files + sync status"
  echo "  ${CYAN}br docs push <file>${NC}     Push specific file to docs repo"
  echo "  ${CYAN}br docs push all${NC}        Push ALL .md files"
  echo "  ${CYAN}br docs readme${NC}          Push README + AGENTS + CLAUDE"
  echo "  ${CYAN}br docs status${NC}          Show sync summary"
  echo "  ${CYAN}br docs log${NC}             Show sync log"
  echo ""
}

case "${1:-help}" in
  list)    cmd_list ;;
  push)    shift; cmd_push "$@" ;;
  readme)  cmd_readme ;;
  status)  cmd_status ;;
  log)     cmd_log ;;
  help|-h) cmd_help ;;
  *) echo "Unknown: $1. Try: list push push-all readme status log"; exit 1 ;;
esac
