#!/bin/zsh
# BR LOG-TAIL - Smart log viewer with filters, highlights, and parsing

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

DB_FILE="$HOME/.blackroad/log-tail.db"
LOG_DIR="$HOME/.blackroad/logs"

init_db() {
  mkdir -p "$LOG_DIR" "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS watched_files (
  path TEXT PRIMARY KEY, label TEXT, added TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS log_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT, errors INTEGER, warnings INTEGER, lines INTEGER,
  ts TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

# Colorize a log line
_colorize() {
  local line="$1"
  local lower="${line:l}"
  if [[ "$lower" == *"error"* || "$lower" == *"fatal"* || "$lower" == *"exception"* || "$lower" == *"critical"* ]]; then
    echo -e "${RED}${line}${NC}"
  elif [[ "$lower" == *"warn"* || "$lower" == *"warning"* ]]; then
    echo -e "${YELLOW}${line}${NC}"
  elif [[ "$lower" == *"success"* || "$lower" == *"started"* || "$lower" == *"ready"* || "$lower" == *" ok"* ]]; then
    echo -e "${GREEN}${line}${NC}"
  elif [[ "$lower" == *"info"* || "$lower" == *"debug"* ]]; then
    echo -e "${CYAN}${line}${NC}"
  else
    echo "$line"
  fi
}

cmd_tail() {
  local file="$1"
  local lines="${2:-50}"

  # auto-detect if no file given
  if [[ -z "$file" ]]; then
    # try common log locations
    for candidate in \
      "$HOME/.blackroad/memory/journals/master-journal.jsonl" \
      "$HOME/.pm2/logs/app-out.log" \
      "/tmp/blackroad.log" \
      "logs/app.log" \
      "app.log"; do
      [[ -f "$candidate" ]] && file="$candidate" && break
    done
  fi

  [[ -z "$file" || ! -f "$file" ]] && { echo -e "${RED}No log file found. Usage: br log-tail <file> [lines]${NC}"; return 1; }

  echo -e "${CYAN}▸ ${file} (last ${lines} lines)${NC}"
  echo ""
  tail -n "$lines" "$file" | while IFS= read -r line; do
    _colorize "$line"
  done
}

cmd_watch() {
  local file="$1"
  [[ -z "$file" ]] && {
    for candidate in \
      "$HOME/.blackroad/memory/journals/master-journal.jsonl" \
      "/tmp/blackroad.log" "logs/app.log" "app.log"; do
      [[ -f "$candidate" ]] && file="$candidate" && break
    done
  }
  [[ -z "$file" || ! -f "$file" ]] && { echo -e "${RED}No log file. Usage: br log-tail watch <file>${NC}"; return 1; }

  echo -e "${CYAN}Watching ${file} — Ctrl+C to stop${NC}"
  tail -f "$file" | while IFS= read -r line; do
    _colorize "$line"
  done
}

cmd_grep() {
  local pattern="$1"
  local file="${2:-}"
  [[ -z "$pattern" ]] && { echo "Usage: br log-tail grep <pattern> [file]"; return 1; }

  if [[ -z "$file" ]]; then
    # search all watched files
    sqlite3 "$DB_FILE" "SELECT path FROM watched_files;" 2>/dev/null | while read p; do
      [[ -f "$p" ]] && echo -e "${CYAN}▸ $p${NC}" && grep -i "$pattern" "$p" | tail -20 | while IFS= read -r line; do _colorize "$line"; done
    done
  else
    [[ -f "$file" ]] || { echo -e "${RED}Not found: $file${NC}"; return 1; }
    grep -i "$pattern" "$file" | tail -40 | while IFS= read -r line; do _colorize "$line"; done
  fi
}

cmd_errors() {
  local file="${1:-}"
  local since="${2:-1 hour ago}"

  echo ""
  echo -e "${BOLD}${RED}Error summary:${NC}"
  echo ""

  local files=()
  if [[ -n "$file" && -f "$file" ]]; then
    files=("$file")
  else
    while IFS= read -r p; do [[ -f "$p" ]] && files+=("$p"); done < <(sqlite3 "$DB_FILE" "SELECT path FROM watched_files;" 2>/dev/null)
    # also check common paths
    for f in logs/*.log app.log /tmp/blackroad.log; do
      [[ -f "$f" ]] && files+=("$f")
    done
  fi

  [[ ${#files[@]} -eq 0 ]] && { echo -e "  ${YELLOW}No log files configured. Use: br log-tail add <file>${NC}"; return; }

  local total_errs=0
  for f in "${files[@]}"; do
    local count
    count=$(grep -ciE "error|fatal|exception|critical" "$f" 2>/dev/null || echo 0)
    total_errs=$((total_errs+count))
    [[ "$count" -gt 0 ]] && echo -e "  ${RED}${count}${NC} errors  ${f}"
    # show last 5 errors
    grep -iE "error|fatal|exception|critical" "$f" 2>/dev/null | tail -5 | while IFS= read -r line; do
      echo -e "    ${RED}▸${NC} ${line:0:100}"
    done
  done

  echo ""
  echo -e "  ${BOLD}Total: ${total_errs} error(s)${NC}"
  echo ""
}

cmd_add() {
  local file="$1"
  local label="${2:-$(basename $file)}"
  [[ -z "$file" || ! -f "$file" ]] && { echo -e "${RED}File not found: $file${NC}"; return 1; }
  sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO watched_files(path,label) VALUES('$file','$label');"
  echo -e "${GREEN}✓ Watching: $file  (label: $label)${NC}"
}

cmd_list() {
  echo ""
  echo -e "${BOLD}${CYAN}Watched log files:${NC}"
  sqlite3 "$DB_FILE" "SELECT label, path, added FROM watched_files;" 2>/dev/null | \
    while IFS='|' read label path added; do
      local exists="${RED}✗${NC}"
      [[ -f "$path" ]] && exists="${GREEN}✓${NC}"
      local lines=0
      [[ -f "$path" ]] && lines=$(wc -l < "$path" | tr -d ' ')
      echo -e "  $exists  ${BOLD}${label}${NC}  ${path}  (${lines} lines)  added ${added}"
    done
  echo ""
}

cmd_journal() {
  # tail the BlackRoad memory journal
  local n="${1:-20}"
  local file="$HOME/.blackroad/memory/journals/master-journal.jsonl"
  [[ ! -f "$file" ]] && { echo "Journal not found"; return 1; }
  echo -e "${CYAN}▸ Memory journal (last ${n} entries)${NC}"
  echo ""
  tail -n "$n" "$file" | python3 -c "
import json, sys
for line in sys.stdin:
    try:
        d = json.loads(line)
        ts = d.get('timestamp','')[:19]
        action = d.get('action','')
        entity = d.get('entity','')
        details = d.get('details','')[:60]
        print(f'  \033[0;36m{ts}\033[0m  {action:15}  {entity:20}  {details}')
    except:
        print(f'  {line.strip()[:100]}')
"
  echo ""
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br log-tail${NC} — smart log viewer"
  echo ""
  echo "  ${CYAN}br log-tail [file] [N]${NC}      Tail last N lines (default 50)"
  echo "  ${CYAN}br log-tail watch [file]${NC}     Live tail (follow)"
  echo "  ${CYAN}br log-tail grep <pat> [f]${NC}   Search for pattern"
  echo "  ${CYAN}br log-tail errors [file]${NC}    Show error summary"
  echo "  ${CYAN}br log-tail journal [N]${NC}      Tail memory journal"
  echo "  ${CYAN}br log-tail add <file>${NC}       Add file to watchlist"
  echo "  ${CYAN}br log-tail list${NC}             List watched files"
  echo ""
}

case "${1:-help}" in
  watch)    shift; cmd_watch "$@" ;;
  grep)     shift; cmd_grep "$@" ;;
  errors)   shift; cmd_errors "$@" ;;
  journal)  shift; cmd_journal "$@" ;;
  add)      shift; cmd_add "$@" ;;
  list)     cmd_list ;;
  help|-h)  cmd_help ;;
  *)        cmd_tail "$1" "${2:-50}" ;;
esac
