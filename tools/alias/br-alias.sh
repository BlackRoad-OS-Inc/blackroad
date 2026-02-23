#!/bin/zsh
# BR Alias — Custom Command Alias Manager
# Save, manage, and run multi-step br command sequences

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'; BOLD='\033[1m'

ALIAS_DB="$HOME/.blackroad/aliases.db"
ALIAS_RC="$HOME/.blackroad/br-aliases.sh"

init_db() {
  mkdir -p "$(dirname "$ALIAS_DB")"
  sqlite3 "$ALIAS_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS aliases (
  name TEXT PRIMARY KEY,
  command TEXT NOT NULL,
  description TEXT,
  tags TEXT DEFAULT '',
  use_count INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
SQL

  local count
  count=$(sqlite3 "$ALIAS_DB" "SELECT COUNT(*) FROM aliases;")
  if [[ "$count" == "0" ]]; then
    sqlite3 "$ALIAS_DB" <<'SQL'
INSERT OR IGNORE INTO aliases VALUES
  ('status',   'br health && br chain tip && br relay inbox all',   'Full system status check', 'system',  0, strftime('%s','now')),
  ('morning',  'br flow run morning',                               'Run morning workflow',     'flow',    0, strftime('%s','now')),
  ('push',     'br git smart-commit && git push origin HEAD',       'Smart commit + push',      'git',     0, strftime('%s','now')),
  ('sweep',    'br harden scan && br comply scan',                  'Security + compliance scan','security',0,strftime('%s','now')),
  ('models',   'br llm models && br cost models',                   'List LLM models + pricing','llm',     0, strftime('%s','now')),
  ('mesh',     'br relay send all "ping" && br relay inbox all',    'Ping all instances',       'collab',  0, strftime('%s','now')),
  ('watchts',  'br watch add ts-check . "*.ts" "npx tsc --noEmit"', 'Watch TypeScript changes', 'dev',     0, strftime('%s','now')),
  ('newbr',    'br gen create br-tool name=$1 Name=$2 description="$3"', 'Scaffold a new br tool', 'dev',  0, strftime('%s','now'));
SQL
    echo -e "${GREEN}✓${NC} Seeded 8 default aliases"
  fi
}

cmd_list() {
  local tag="$1"
  echo -e "\n${BOLD}${CYAN}⚡ BR Aliases${NC}\n"
  python3 - "$ALIAS_DB" "${tag:-}" <<'PY'
import sqlite3, sys
db, tag = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
filt = f"WHERE tags LIKE '%{tag}%'" if tag else ""
rows = conn.execute(f"SELECT name, command, description, tags, use_count FROM aliases {filt} ORDER BY use_count DESC, name").fetchall()

if not rows:
    print("  No aliases found.")
else:
    # Group by tag
    from collections import defaultdict
    by_tag = defaultdict(list)
    for name, cmd, desc, tags, uses in rows:
        first_tag = (tags.split(',')[0] if tags else 'general').strip()
        by_tag[first_tag].append((name, cmd, desc, uses))
    
    for tag_name, items in sorted(by_tag.items()):
        print(f"\n  \033[36m{tag_name.upper()}\033[0m")
        for name, cmd, desc, uses in items:
            print(f"    \033[1m{name:<18}\033[0m  \033[90m{desc or cmd[:50]}\033[0m  \033[90m×{uses}\033[0m")

print()
conn.close()
PY
}

cmd_show() {
  local name="$1"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br alias show <name>"; return 1; }
  python3 - "$ALIAS_DB" "$name" <<'PY'
import sqlite3, sys
db, name = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
row = conn.execute("SELECT name, command, description, tags, use_count FROM aliases WHERE name=?", (name,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Not found: {name}")
    sys.exit(1)
aname, cmd, desc, tags, uses = row
print(f"\n\033[1m\033[36m{aname}\033[0m  \033[90m[{tags}] ×{uses}\033[0m")
print(f"  {desc or ''}")
print(f"\n  \033[33mCommand:\033[0m {cmd}\n")
conn.close()
PY
}

cmd_add() {
  local name="$1" cmd="$2" desc="${3:-}" tags="${4:-general}"
  [[ -z "$name" || -z "$cmd" ]] && {
    echo -e "${CYAN}Usage: br alias add <name> <command> [description] [tags]${NC}"
    echo -e "Example: br alias add mycheck 'br health && br chain tip' 'Daily check' system"
    return 1
  }
  sqlite3 "$ALIAS_DB" "INSERT OR REPLACE INTO aliases (name, command, description, tags) VALUES ('$name','$(echo "$cmd" | sed "s/'/''/g")','$(echo "$desc" | sed "s/'/''/g")','$tags');"
  echo -e "${GREEN}✓${NC} Alias saved: ${BOLD}$name${NC}"
  echo -e "  Run: br alias run $name"
  echo -e "  Or:  br $name   (after sourcing br-aliases.sh)"
}

cmd_run() {
  local name="$1"
  shift
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br alias run <name> [args...]"; return 1; }

  local cmd
  cmd=$(sqlite3 "$ALIAS_DB" "SELECT command FROM aliases WHERE name='$name';")
  [[ -z "$cmd" ]] && { echo -e "${RED}✗${NC} Alias not found: $name"; return 1; }

  # Substitute positional args $1 $2 etc.
  local i=1
  for arg in "$@"; do
    cmd="${cmd//\$$i/$arg}"
    (( i++ ))
  done

  echo -e "${CYAN}▶ $name:${NC} $cmd\n"
  sqlite3 "$ALIAS_DB" "UPDATE aliases SET use_count=use_count+1 WHERE name='$name';" 2>/dev/null
  eval "$cmd"
}

cmd_delete() {
  local name="$1"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br alias delete <name>"; return 1; }
  sqlite3 "$ALIAS_DB" "DELETE FROM aliases WHERE name='$name';"
  echo -e "${GREEN}✓${NC} Deleted: $name"
}

cmd_export() {
  # Write shell aliases to a source-able file
  echo -e "${CYAN}Exporting aliases to $ALIAS_RC${NC}"

  python3 - "$ALIAS_DB" "$ALIAS_RC" <<'PY'
import sqlite3, sys
db, rc = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute("SELECT name, command FROM aliases ORDER BY name").fetchall()

with open(rc, 'w') as f:
    f.write("# BR Aliases — auto-generated by br alias export\n")
    f.write("# Source this file in your .zshrc: source ~/.blackroad/br-aliases.sh\n\n")
    for name, cmd in rows:
        # Simple aliases (no args)
        if '$1' not in cmd and '$2' not in cmd:
            escaped = cmd.replace("'", "'\\''")
            f.write(f"alias br-{name}='{escaped}'\n")
        else:
            # Functions for aliases with args
            f.write(f"br-{name}() {{ br alias run {name} \"$@\"; }}\n")

print(f"Wrote {len(rows)} aliases to {rc}")
conn.close()
PY

  echo -e "${GREEN}✓${NC} Done. Add to .zshrc:"
  echo -e "  ${YELLOW}source $ALIAS_RC${NC}"
}

cmd_search() {
  local query="$1"
  [[ -z "$query" ]] && { echo -e "${RED}✗${NC} Usage: br alias search <query>"; return 1; }
  echo -e "\n${BOLD}${CYAN}Search: \"$query\"${NC}\n"
  python3 - "$ALIAS_DB" "$query" <<'PY'
import sqlite3, sys
db, q = sys.argv[1], sys.argv[2].lower()
conn = sqlite3.connect(db)
rows = conn.execute("SELECT name, command, description, tags FROM aliases").fetchall()
for name, cmd, desc, tags in rows:
    if q in name.lower() or q in (cmd or '').lower() or q in (desc or '').lower() or q in (tags or '').lower():
        print(f"  \033[1m{name:<18}\033[0m  \033[36m{(tags or '')}\033[0m")
        print(f"    {cmd[:70]}\033[0m")
        if desc:
            print(f"    \033[90m{desc}\033[0m")
        print()
conn.close()
PY
}

cmd_import_from_git() {
  # Import useful git aliases from git config
  echo -e "${CYAN}Importing from git aliases...${NC}"
  git config --get-regexp '^alias\.' 2>/dev/null | while read -r key val; do
    local aname="${key#alias.}"
    sqlite3 "$ALIAS_DB" "INSERT OR IGNORE INTO aliases (name, command, description, tags) VALUES ('git-$aname','git $val','Git alias: $aname','git');" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} git-$aname → git $val"
  done
}

show_help() {
  echo -e "\n${BOLD}${CYAN}⚡ BR Alias — Command Alias Manager${NC}\n"
  echo -e "  ${CYAN}br alias list [tag]${NC}              — list all aliases"
  echo -e "  ${CYAN}br alias show <name>${NC}             — show alias details"
  echo -e "  ${CYAN}br alias add <name> <cmd> [desc]${NC} — add new alias"
  echo -e "  ${CYAN}br alias run <name> [args...]${NC}    — run alias"
  echo -e "  ${CYAN}br alias search <query>${NC}          — search aliases"
  echo -e "  ${CYAN}br alias export${NC}                  — write shell alias file"
  echo -e "  ${CYAN}br alias delete <name>${NC}           — delete alias"
  echo -e "\n  ${YELLOW}Built-in aliases:${NC} status, morning, push, sweep, models, mesh"
  echo -e "  ${YELLOW}Shortcut:${NC} br alias run status  ≡  br status (via br-aliases.sh)\n"
}

init_db
case "${1:-help}" in
  list|ls)          cmd_list "$2" ;;
  show|view|get)    cmd_show "$2" ;;
  add|new|save)     cmd_add "$2" "$3" "$4" "$5" ;;
  run|exec|do)      cmd_run "$2" "${@:3}" ;;
  delete|rm)        cmd_delete "$2" ;;
  search|find)      cmd_search "$2" ;;
  export|source)    cmd_export ;;
  import-git)       cmd_import_from_git ;;
  help|--help|-h)   show_help ;;
  *) show_help ;;
esac
