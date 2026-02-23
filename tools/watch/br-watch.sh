#!/bin/zsh
# BR Watch — File Watcher with Triggers
# Watch files/dirs and run commands on change

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

WATCH_DB="$HOME/.blackroad/watch.db"

init_db() {
  mkdir -p "$(dirname "$WATCH_DB")"
  sqlite3 "$WATCH_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS watchers (
  id TEXT PRIMARY KEY,
  path TEXT NOT NULL,
  pattern TEXT DEFAULT '*',
  command TEXT NOT NULL,
  events TEXT DEFAULT 'modified,created,deleted',
  enabled INTEGER DEFAULT 1,
  debounce_ms INTEGER DEFAULT 500,
  run_count INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS watch_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  watcher_id TEXT,
  file_path TEXT,
  event_type TEXT,
  command_output TEXT,
  exit_code INTEGER,
  triggered_at INTEGER DEFAULT (strftime('%s','now'))
);
SQL

  local count
  count=$(sqlite3 "$WATCH_DB" "SELECT COUNT(*) FROM watchers;")
  [[ "$count" == "0" ]] && sqlite3 "$WATCH_DB" <<'SQL'
INSERT OR IGNORE INTO watchers VALUES
  ('git-status',  '.', '*.{js,ts,py,sh,go}', 'git --no-pager diff --stat', 'modified', 1, 1000, 0, strftime('%s','now')),
  ('test-runner', 'src', '*.test.{js,ts}',    'npm test --passWithNoTests 2>&1 | tail -10', 'modified,created', 1, 2000, 0, strftime('%s','now')),
  ('hook-emit',   '.', '*.{sh,py,js,ts}',    'br hook emit file.changed', 'modified', 0, 500, 0, strftime('%s','now'));
SQL
}

cmd_list() {
  echo -e "\n${BOLD}${CYAN}👁 File Watchers${NC}\n"
  python3 - "$WATCH_DB" <<'PY'
import sqlite3, sys
db = sys.argv[1]
conn = sqlite3.connect(db)
rows = conn.execute("SELECT id, path, pattern, command, events, enabled, run_count FROM watchers ORDER BY id").fetchall()
if not rows:
    print("  No watchers. Add: br watch add <id> <path> <pattern> <command>")
else:
    for id_, path, pattern, cmd, events, enabled, runs in rows:
        st = '\033[32m●\033[0m' if enabled else '\033[90m○\033[0m'
        print(f"  {st} \033[1m{id_:<18}\033[0m  \033[36m{path}/{pattern}\033[0m")
        print(f"    cmd: {cmd[:60]}  \033[90m×{runs}\033[0m\n")
conn.close()
PY
}

cmd_add() {
  local id="$1" path="${2:-.}" pattern="${3:-*}" cmd="$4" events="${5:-modified}"
  [[ -z "$id" || -z "$cmd" ]] && {
    echo -e "${CYAN}Usage: br watch add <id> <path> <pattern> <command> [events]${NC}"
    echo -e "  events: modified|created|deleted|renamed (comma-separated)"
    echo -e "Example: br watch add lint src '*.ts' 'npx tsc --noEmit' modified"
    return 1
  }
  sqlite3 "$WATCH_DB" "INSERT OR REPLACE INTO watchers (id, path, pattern, command, events) VALUES ('$id','$path','$pattern','$(echo "$cmd" | sed "s/'/''/g")','$events');"
  echo -e "${GREEN}✓${NC} Watcher added: ${BOLD}$id${NC}  →  $path/$pattern  →  $cmd"
}

cmd_start() {
  local wid="$1"

  # Check for fswatch
  if ! command -v fswatch &>/dev/null; then
    echo -e "${YELLOW}⚠${NC} fswatch not found. Install: brew install fswatch"
    echo -e "  Falling back to polling mode (5s interval)"
    cmd_start_poll "$wid"
    return
  fi

  local filter=""
  [[ -n "$wid" ]] && filter="WHERE id='$wid' AND enabled=1" || filter="WHERE enabled=1"

  python3 - "$WATCH_DB" "$filter" <<'PY'
import sqlite3, sys
db, filt = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute(f"SELECT id, path, pattern, command FROM watchers {filt}").fetchall()
conn.close()
for row in rows:
    print('|'.join(str(x) for x in row))
PY

  local watchers
  watchers=$(python3 - "$WATCH_DB" "$filter" <<'PY'
import sqlite3, sys
db, filt = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute(f"SELECT id, path, pattern, command FROM watchers {filt}").fetchall()
conn.close()
for row in rows:
    print('|'.join(str(x) for x in row))
PY
)

  if [[ -z "$watchers" ]]; then
    echo -e "${YELLOW}⚠${NC} No enabled watchers found"
    return
  fi

  echo -e "${CYAN}▶ Starting file watchers${NC} (Ctrl+C to stop)\n"

  # Build paths to watch
  local paths=()
  while IFS='|' read -r id_ path pattern cmd; do
    [[ -z "$id_" ]] && continue
    paths+=("$path")
    echo -e "  ${GREEN}●${NC} ${BOLD}$id_${NC}  $path/$pattern"
  done <<< "$watchers"

  echo ""

  # Watch all paths with fswatch
  local unique_paths
  unique_paths=$(echo "${paths[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')

  fswatch -0 -r $unique_paths 2>/dev/null | while IFS= read -r -d $'\0' file; do
    local ts
    ts=$(date '+%H:%M:%S')

    while IFS='|' read -r id_ path pattern cmd; do
      [[ -z "$id_" ]] && continue
      # Check if file matches this watcher's path and pattern
      if [[ "$file" == $path* ]]; then
        local fname
        fname=$(basename "$file")
        # Simple pattern match (glob)
        if [[ "$fname" == $~pattern || "$pattern" == "*" ]]; then
          echo -e "${CYAN}[$ts]${NC} ${BOLD}$id_${NC}: $fname changed"
          local output
          output=$(eval "$cmd" 2>&1)
          local ec=$?
          [[ -n "$output" ]] && echo "$output" | head -20 | sed 's/^/  /'
          sqlite3 "$WATCH_DB" "UPDATE watchers SET run_count=run_count+1 WHERE id='$id_';" 2>/dev/null
          sqlite3 "$WATCH_DB" "INSERT INTO watch_events (watcher_id, file_path, event_type, command_output, exit_code) VALUES ('$id_','$file','modified','$(echo "$output" | head -5 | sed "s/'/''/g")',$ec);" 2>/dev/null
        fi
      fi
    done <<< "$watchers"
  done
}

cmd_start_poll() {
  # Fallback polling-based watcher
  local wid="$1"
  local filter=""
  [[ -n "$wid" ]] && filter="WHERE id='$wid' AND enabled=1" || filter="WHERE enabled=1"

  echo -e "${CYAN}▶ Polling mode (5s)${NC} (Ctrl+C to stop)"

  local prev_state=""
  while true; do
    local curr_state
    curr_state=$(find . -newer /tmp/br-watch-marker 2>/dev/null | head -20 | sort | md5 2>/dev/null || echo "")
    if [[ "$curr_state" != "$prev_state" && -n "$curr_state" ]]; then
      local ts=$(date '+%H:%M:%S')
      local changed
      changed=$(find . -newer /tmp/br-watch-marker 2>/dev/null | head -10)
      echo -e "${CYAN}[$ts]${NC} Changes detected:"
      echo "$changed" | head -5 | sed 's/^/  /'

      # Run enabled watchers
      while IFS='|' read -r id_ path pattern cmd; do
        [[ -z "$id_" ]] && continue
        echo -e "  → $id_: $cmd"
        eval "$cmd" 2>&1 | head -10 | sed 's/^/    /'
      done < <(sqlite3 "$WATCH_DB" "SELECT id, path, pattern, command FROM watchers $filter;")

      prev_state="$curr_state"
    fi
    touch /tmp/br-watch-marker 2>/dev/null
    sleep 5
  done
}

cmd_enable() {
  local wid="$1" val="${2:-1}"
  [[ -z "$wid" ]] && { echo -e "${RED}✗${NC} Usage: br watch enable/disable <id>"; return 1; }
  sqlite3 "$WATCH_DB" "UPDATE watchers SET enabled=$val WHERE id='$wid';"
  local word; [[ "$val" == "1" ]] && word="${GREEN}enabled${NC}" || word="${YELLOW}disabled${NC}"
  echo -e "  $wid: $word"
}

cmd_events() {
  local wid="$1"
  local filter=""; [[ -n "$wid" ]] && filter="WHERE watcher_id='$wid'"
  echo -e "\n${BOLD}${CYAN}📋 Watch Events${NC}\n"
  python3 - "$WATCH_DB" "$filter" <<'PY'
import sqlite3, sys, time
db, filt = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute(f"SELECT watcher_id, file_path, event_type, exit_code, triggered_at FROM watch_events {filt} ORDER BY triggered_at DESC LIMIT 20").fetchall()
for wid, fpath, etype, ec, ts in rows:
    dt = time.strftime('%m/%d %H:%M', time.localtime(ts)) if ts else '?'
    st = '\033[32mok\033[0m' if ec == 0 else '\033[31merr\033[0m'
    fname = fpath.split('/')[-1] if fpath else '?'
    print(f"  \033[90m{dt}\033[0m  {wid:<18}  {fname:<30}  {st}")
conn.close()
print()
PY
}

cmd_delete() {
  local wid="$1"
  [[ -z "$wid" ]] && { echo -e "${RED}✗${NC} Usage: br watch delete <id>"; return 1; }
  sqlite3 "$WATCH_DB" "DELETE FROM watchers WHERE id='$wid';"
  echo -e "${GREEN}✓${NC} Deleted: $wid"
}

show_help() {
  echo -e "\n${BOLD}${CYAN}👁 BR Watch — File Watcher${NC}\n"
  echo -e "  ${CYAN}br watch list${NC}                        — list watchers"
  echo -e "  ${CYAN}br watch add <id> <path> <pat> <cmd>${NC} — add watcher"
  echo -e "  ${CYAN}br watch start [id]${NC}                  — start watching"
  echo -e "  ${CYAN}br watch enable|disable <id>${NC}         — toggle watcher"
  echo -e "  ${CYAN}br watch events [id]${NC}                 — view trigger history"
  echo -e "  ${CYAN}br watch delete <id>${NC}                 — delete watcher"
  echo -e "\n  ${YELLOW}Requires:${NC} fswatch (brew install fswatch) or uses polling fallback"
  echo -e "  ${YELLOW}Example:${NC} br watch add lint . '*.ts' 'npx tsc --noEmit'\n"
}

init_db
case "${1:-help}" in
  list|ls)           cmd_list ;;
  add|new)           cmd_add "$2" "$3" "$4" "$5" "$6" ;;
  start|run|watch)   cmd_start "$2" ;;
  enable)            cmd_enable "$2" 1 ;;
  disable)           cmd_enable "$2" 0 ;;
  events|log|hist)   cmd_events "$2" ;;
  delete|rm)         cmd_delete "$2" ;;
  help|--help|-h)    show_help ;;
  *) show_help ;;
esac
