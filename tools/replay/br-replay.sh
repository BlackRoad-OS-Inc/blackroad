#!/usr/bin/env zsh
# BR Replay — Record and replay br command sequences

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'
DB="$HOME/.blackroad/replay.db"
REPLAY_DIR="$HOME/.blackroad/replays"

init_db() {
  mkdir -p "$REPLAY_DIR"
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS scripts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  commands TEXT NOT NULL,
  variables TEXT DEFAULT '{}',
  run_count INTEGER DEFAULT 0,
  last_run TEXT DEFAULT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  script_name TEXT NOT NULL,
  ok INTEGER NOT NULL,
  output TEXT DEFAULT '',
  duration_ms INTEGER DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS recordings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session TEXT NOT NULL,
  command TEXT NOT NULL,
  ts TEXT DEFAULT (datetime('now'))
);
SQL
}

RECORDING_FILE="$REPLAY_DIR/.recording"

cmd_record() {
  local session="${1:-session-$(date +%s)}"
  echo "$session" > "$RECORDING_FILE"
  sqlite3 "$DB" "DELETE FROM recordings WHERE session='$session';"
  echo ""
  echo -e "${GREEN}⏺  Recording started: $session${NC}"
  echo -e "  ${CYAN}Commands will be captured automatically${NC}"
  echo -e "  Run: ${YELLOW}br replay stop${NC} to finish recording"
  echo -e "  Run: ${YELLOW}br replay save $session <name>${NC} to save script"
  echo ""
  echo "  Tip: set up shell hook with:"
  echo -e "  ${BLUE}br replay hook${NC}"
  echo ""
}

cmd_stop() {
  [[ ! -f "$RECORDING_FILE" ]] && { echo -e "${YELLOW}⚠ Not recording${NC}"; return; }
  local session; session=$(cat "$RECORDING_FILE")
  rm -f "$RECORDING_FILE"
  local count; count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM recordings WHERE session='$session';")
  echo ""
  echo -e "${GREEN}⏹  Recording stopped: $session${NC}"
  echo -e "  $count command(s) captured"
  echo ""
  sqlite3 "$DB" "SELECT command FROM recordings WHERE session='$session' ORDER BY id;" | while IFS= read -r cmd; do
    echo -e "  ${CYAN}→ $cmd${NC}"
  done
  echo ""
  echo -e "  Save with: ${YELLOW}br replay save $session <name>${NC}"
  echo ""
}

cmd_capture() {
  # Called by shell hook — br replay capture "br <command>"
  local cmd="$1"
  [[ ! -f "$RECORDING_FILE" ]] && return
  local session; session=$(cat "$RECORDING_FILE")
  sqlite3 "$DB" "INSERT INTO recordings (session, command) VALUES ('$session', '$cmd');"
}

cmd_hook() {
  echo ""
  echo -e "${CYAN}${BOLD}Shell Hook Setup${NC}"
  echo ""
  echo "Add to your ~/.zshrc:"
  echo ""
  echo -e "${GREEN}# br replay hook${NC}"
  echo "preexec() { br replay capture \"\$1\" 2>/dev/null; }"
  echo ""
  echo -e "Then: ${YELLOW}source ~/.zshrc${NC}"
  echo ""
}

cmd_save() {
  local session="$1" name="$2" desc="${3:-}"
  [[ -z "$session" || -z "$name" ]] && { echo "Usage: br replay save <session> <name> [description]"; exit 1; }
  local commands
  commands=$(sqlite3 "$DB" "SELECT command FROM recordings WHERE session='$session' ORDER BY id;")
  [[ -z "$commands" ]] && { echo -e "${RED}✗ No recordings for session: $session${NC}"; exit 1; }
  commands_json=$(echo "$commands" | python3 -c "import json, sys; print(json.dumps([l for l in sys.stdin.read().splitlines() if l]))")
  sqlite3 "$DB" "INSERT OR REPLACE INTO scripts (name, description, commands) VALUES ('$name', '$desc', '$commands_json');"
  echo -e "${GREEN}✓ Script '$name' saved${NC}"
}

cmd_new() {
  local name="$1" desc="${2:-}"
  [[ -z "$name" ]] && { echo "Usage: br replay new <name> [description]"; exit 1; }
  local file="$REPLAY_DIR/$name.replay"
  cat > "$file" <<EOF
# Replay script: $name
# Description: $desc
# Variables: VAR=default
#
# Commands (one per line):
br status
EOF
  echo -e "${GREEN}✓ Created: $file${NC}"
  echo "  Edit it, then run: br replay run $name"
}

cmd_run() {
  local name="$1"; shift
  [[ -z "$name" ]] && { echo "Usage: br replay run <name> [VAR=value ...]"; exit 1; }
  local commands
  commands=$(sqlite3 "$DB" "SELECT commands FROM scripts WHERE name='$name';")
  # Also check file
  local file="$REPLAY_DIR/$name.replay"
  if [[ -z "$commands" && -f "$file" ]]; then
    # Read non-comment lines
    mapfile -t lines < <(grep -v '^#' "$file" | grep -v '^$')
    commands=$(python3 -c "import json; import sys; lines=[l.strip() for l in '''$(cat "$file")'''.splitlines() if l.strip() and not l.strip().startswith('#')]; print(json.dumps(lines))")
  fi
  [[ -z "$commands" ]] && { echo -e "${RED}✗ Script not found: $name${NC}"; exit 1; }
  # Apply variable substitutions
  local vars_str="" 
  for arg in "$@"; do vars_str+="$arg\n"; done
  echo ""
  echo -e "${CYAN}${BOLD}▶ Running: $name${NC}"
  echo ""
  local start; start=$(date +%s%3N)
  local ok=1 output=""
  # Extract and run each command
  echo "$commands" | python3 -c "
import json, sys
cmds = json.loads(sys.stdin.read())
for c in cmds:
    print(c)
" | while IFS= read -r cmd; do
    # Apply variable substitutions
    for arg in "$@"; do
      local var="${arg%%=*}" val="${arg#*=}"
      cmd="${cmd/\$$var/$val}"
    done
    echo -e "  ${GREEN}→${NC} $cmd"
    eval "$cmd" 2>&1 | sed 's/^/    /'
    echo ""
  done
  local end; end=$(date +%s%3N)
  local dur=$(( end - start ))
  sqlite3 "$DB" "UPDATE scripts SET run_count=run_count+1, last_run=datetime('now') WHERE name='$name';"
  sqlite3 "$DB" "INSERT INTO runs (script_name, ok, duration_ms) VALUES ('$name', 1, $dur);"
  echo -e "${GREEN}✓ Completed in ${dur}ms${NC}"
  echo ""
}

cmd_list() {
  echo ""
  echo -e "${CYAN}${BOLD}📼 Replay Scripts${NC}"
  echo ""
  # DB scripts
  local count; count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM scripts;")
  if [[ "$count" -gt 0 ]]; then
    echo -e "  ${BLUE}Saved scripts:${NC}"
    sqlite3 -separator "|" "$DB" "SELECT name, description, run_count, last_run FROM scripts ORDER BY last_run DESC;" | while IFS="|" read -r nm desc rc lr; do
      printf "  ${GREEN}%-20s${NC}  %-30s  runs=%-4s  %s\n" "$nm" "$desc" "$rc" "${lr:0:16}"
    done
    echo ""
  fi
  # File scripts
  if ls "$REPLAY_DIR"/*.replay &>/dev/null; then
    echo -e "  ${BLUE}File scripts ($REPLAY_DIR):${NC}"
    for f in "$REPLAY_DIR"/*.replay; do
      local nm; nm=$(basename "$f" .replay)
      local desc; desc=$(grep '^# Description:' "$f" | head -1 | sed 's/# Description: //')
      printf "  ${CYAN}%-20s${NC}  %s\n" "$nm" "$desc"
    done
    echo ""
  fi
  [[ "$count" -eq 0 ]] && ! ls "$REPLAY_DIR"/*.replay &>/dev/null && echo -e "  ${YELLOW}No scripts yet. Create with: br replay new <name>${NC}" && echo ""
}

cmd_show() {
  local name="$1"
  [[ -z "$name" ]] && { echo "Usage: br replay show <name>"; exit 1; }
  local commands
  commands=$(sqlite3 "$DB" "SELECT commands FROM scripts WHERE name='$name';")
  [[ -z "$commands" ]] && { echo -e "${RED}✗ Script not found: $name${NC}"; exit 1; }
  echo ""
  echo -e "${CYAN}${BOLD}📋 $name${NC}"
  echo ""
  echo "$commands" | python3 -c "
import json, sys
cmds = json.loads(sys.stdin.read())
for i, c in enumerate(cmds, 1):
    print(f'  {i}. {c}')
"
  local stats
  stats=$(sqlite3 -separator "|" "$DB" "SELECT run_count, last_run FROM scripts WHERE name='$name';")
  IFS="|" read -r rc lr <<< "$stats"
  echo ""
  echo -e "  Runs: $rc   Last: ${lr:-never}"
  echo ""
}

cmd_export() {
  local name="$1" out="${2:-$name.replay}"
  [[ -z "$name" ]] && { echo "Usage: br replay export <name> [file]"; exit 1; }
  local commands desc
  commands=$(sqlite3 "$DB" "SELECT commands FROM scripts WHERE name='$name';")
  desc=$(sqlite3 "$DB" "SELECT description FROM scripts WHERE name='$name';")
  [[ -z "$commands" ]] && { echo -e "${RED}✗ Script not found${NC}"; exit 1; }
  {
    echo "# Replay script: $name"
    echo "# Description: $desc"
    echo "# Exported: $(date)"
    echo ""
    echo "$commands" | python3 -c "import json, sys; [print(c) for c in json.loads(sys.stdin.read())]"
  } > "$out"
  echo -e "${GREEN}✓ Exported: $out${NC}"
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br replay${NC} — Record and replay br command sequences"
  echo ""
  echo -e "  ${GREEN}br replay record [session]${NC}          Start recording"
  echo -e "  ${GREEN}br replay stop${NC}                      Stop recording"
  echo -e "  ${GREEN}br replay save <session> <name>${NC}     Save recording as script"
  echo -e "  ${GREEN}br replay new <name> [desc]${NC}         Create script from scratch"
  echo -e "  ${GREEN}br replay run <name> [VAR=val]${NC}      Run a script"
  echo -e "  ${GREEN}br replay list${NC}                      List all scripts"
  echo -e "  ${GREEN}br replay show <name>${NC}               Show script contents"
  echo -e "  ${GREEN}br replay export <name> [file]${NC}      Export script to file"
  echo -e "  ${GREEN}br replay hook${NC}                      Show shell hook setup"
  echo -e "  ${GREEN}br replay capture <cmd>${NC}             (internal) capture command"
  echo ""
}

init_db
case "${1:-list}" in
  record)     shift; cmd_record "$@" ;;
  stop)       cmd_stop ;;
  capture)    shift; cmd_capture "$@" ;;
  hook)       cmd_hook ;;
  save)       shift; cmd_save "$@" ;;
  new|create) shift; cmd_new "$@" ;;
  run|play)   shift; cmd_run "$@" ;;
  list|ls)    cmd_list ;;
  show|view)  shift; cmd_show "$@" ;;
  export)     shift; cmd_export "$@" ;;
  help|-h)    show_help ;;
  *)          show_help ;;
esac
