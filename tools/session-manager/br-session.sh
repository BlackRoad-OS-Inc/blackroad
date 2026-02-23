#!/bin/zsh
# BR Session — workspace snapshot manager  v3

AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"

SESSION_HOME="${HOME}/.blackroad/sessions"
mkdir -p "$SESSION_HOME"

# ──────────────────────────────────────────────────
_header() {
  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR SESSION${NC}  ${DIM}$1${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
}

_session_file() { echo "${SESSION_HOME}/${1}.session"; }

# ──────────────────────────────────────────────────
cmd_save() {
  local name=${1:-$(date +%Y%m%d-%H%M)}
  local sf; sf=$(_session_file "$name")
  local branch; branch=$(git branch --show-current 2>/dev/null || echo 'none')
  local changed; changed=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
  local files; files=$(git status --short 2>/dev/null | awk '{print $2}' | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().splitlines()))")
  local remotes; remotes=$(git remote -v 2>/dev/null | awk 'NR%2==1{print $2}' | python3 -c "import sys,json; print(json.dumps(list(set(sys.stdin.read().splitlines()))))")

  python3 - <<PYEOF
import json, os, time
data = {
  "name": "$name",
  "timestamp": int(time.time()),
  "dir": os.getcwd(),
  "branch": "$branch",
  "changed": int("$changed") if "$changed".isdigit() else 0,
  "changed_files": $files,
  "remotes": $remotes,
  "env": {k: v for k, v in os.environ.items() if k.startswith("BR_") or k in ["NODE_ENV","RAILS_ENV","PYTHON_ENV"]},
}
with open("$sf", "w") as f:
    json.dump(data, f, indent=2)
PYEOF

  _header "saved  ·  $name"
  echo -e "  ${BOLD}dir${NC}      $(pwd)"
  echo -e "  ${BOLD}branch${NC}   $branch"
  echo -e "  ${BOLD}changed${NC}  $changed file(s)"
  echo -e ""
  echo -e "  ${DIM}→  br session restore $name${NC}"
  echo ""
}

# ──────────────────────────────────────────────────
cmd_list() {
  _header "saved workspaces"
  echo ""
  local count=0
  for file in "$SESSION_HOME"/*.session(N); do
    count=$((count+1))
    python3 - "$file" <<'PYEOF'
import json, sys, time
f = sys.argv[1]
d = json.load(open(f))
n = d.get("name", "?")
di = d.get("dir", "?")
br = d.get("branch", "?")
ch = d.get("changed", 0)
age = int(time.time()) - d.get("timestamp", 0)
h, m = age // 3600, (age % 3600) // 60
ago = f"{h}h ago" if h else f"{m}m ago"
A = '\033[38;5;214m'; B = '\033[1m'; D = '\033[2m'; NC = '\033[0m'
print(f"  {A}{B}{n}{NC}  {D}{ago}{NC}")
print(f"  {D}{di}  [{br}]  {ch} changed{NC}")
print()
PYEOF
  done
  [[ $count -eq 0 ]] && echo -e "  ${DIM}No sessions yet.  br session save <name>${NC}\n" \
                      || echo -e "  ${DIM}total: $count${NC}\n"
}

# ──────────────────────────────────────────────────
cmd_restore() {
  local name=$1
  [[ -z "$name" ]] && { echo -e "  ${RED}✗${NC} usage: br session restore <name>"; return 1; }
  local sf; sf=$(_session_file "$name")
  [[ ! -f "$sf" ]] && { echo -e "  ${RED}✗${NC} session not found: $name"; return 1; }

  local dir; dir=$(python3 -c "import json; print(json.load(open('$sf'))['dir'])")
  local branch; branch=$(python3 -c "import json; print(json.load(open('$sf'))['branch'])")

  _header "restoring  ·  $name"
  if cd "$dir" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC}  cd $dir"
  else
    echo -e "  ${RED}✗${NC}  dir not found: $dir"
  fi
  if [[ "$branch" != "none" ]]; then
    git checkout "$branch" 2>/dev/null && echo -e "  ${GREEN}✓${NC}  branch $branch" || echo -e "  ${YELLOW}⚠${NC}  branch $branch not found"
  fi
  echo -e "  ${GREEN}✓${NC}  session restored"
  echo ""
}

# ──────────────────────────────────────────────────
cmd_export() {
  local name=$1
  local out=${2:-"${name:-session}-export.json"}
  [[ -z "$name" ]] && { echo -e "  ${RED}✗${NC} usage: br session export <name> [output.json]"; return 1; }
  local sf; sf=$(_session_file "$name")
  [[ ! -f "$sf" ]] && { echo -e "  ${RED}✗${NC} session not found: $name"; return 1; }

  # Enrich with live git state at export time
  python3 - <<PYEOF
import json, os, subprocess, time

with open("$sf") as f:
    data = json.load(f)

# Enrich
data["exported_at"] = int(time.time())
data["export_version"] = "1.0"

# Capture current git log (last 10)
try:
    log = subprocess.check_output(
        ["git","--no-pager","log","--oneline","-10"],
        cwd=data.get("dir", os.getcwd()),
        stderr=subprocess.DEVNULL
    ).decode().splitlines()
    data["recent_commits"] = log
except: data["recent_commits"] = []

# Open files (if tracked)
data["open_files"] = data.get("changed_files", [])

with open("$out", "w") as f:
    json.dump(data, f, indent=2)

print(f"exported to: $out")
print(f"keys: {', '.join(data.keys())}")
PYEOF
  _header "exported  ·  $name"
  echo -e "  ${GREEN}✓${NC}  written to ${BOLD}$out${NC}"
  echo ""
}

# ──────────────────────────────────────────────────
cmd_import() {
  local src=$1
  [[ -z "$src" ]] && { echo -e "  ${RED}✗${NC} usage: br session import <file.json>"; return 1; }
  [[ ! -f "$src" ]] && { echo -e "  ${RED}✗${NC} file not found: $src"; return 1; }

  python3 - <<PYEOF
import json, sys

with open("$src") as f:
    data = json.load(f)

name = data.get("name", "imported")
import os, time
data["imported_at"] = int(time.time())
dest = os.path.expanduser(f"~/.blackroad/sessions/{name}.session")
with open(dest, "w") as f:
    json.dump(data, f, indent=2)
print(name, dest)
PYEOF
  local name; name=$(python3 -c "import json; print(json.load(open('$src')).get('name','imported'))")
  _header "imported  ·  $name"
  echo -e "  ${GREEN}✓${NC}  session ${BOLD}$name${NC} ready"
  echo -e "  ${DIM}→  br session restore $name${NC}"
  echo ""
}

# ──────────────────────────────────────────────────
cmd_diff() {
  local a=$1 b=$2
  if [[ -z "$a" || -z "$b" ]]; then
    echo -e "  ${RED}✗${NC} usage: br session diff <session-a> <session-b>"; return 1
  fi
  local fa fb
  fa=$(_session_file "$a"); fb=$(_session_file "$b")
  [[ ! -f "$fa" ]] && { echo -e "  ${RED}✗${NC} not found: $a"; return 1; }
  [[ ! -f "$fb" ]] && { echo -e "  ${RED}✗${NC} not found: $b"; return 1; }

  _header "diff  ·  $a  vs  $b"
  echo ""
  python3 - <<PYEOF
import json, time

a = json.load(open("$fa"))
b = json.load(open("$fb"))

AMBER = '\033[38;5;214m'; PINK = '\033[38;5;205m'; BOLD = '\033[1m'
DIM   = '\033[2m';         GREEN = '\033[0;32m';    NC = '\033[0m'

fields = ["dir","branch","changed","remotes"]
for key in fields:
    va = a.get(key,"—"); vb = b.get(key,"—")
    if va != vb:
        print(f"  {BOLD}{key:<12}{NC}  {PINK}{va}{NC}  →  {GREEN}{vb}{NC}")
    else:
        print(f"  {DIM}{key:<12}  {va}  (same){NC}")

# Files diff
fa_files = set(a.get("changed_files",[]))
fb_files = set(b.get("changed_files",[]))
added = fb_files - fa_files
removed = fa_files - fb_files
if added or removed:
    print(f"\n  {BOLD}changed files{NC}")
    for f in sorted(added):   print(f"  {GREEN}+  {f}{NC}")
    for f in sorted(removed): print(f"  {PINK}-  {f}{NC}")

# Time delta
ta = a.get("timestamp",0); tb = b.get("timestamp",0)
delta = abs(tb - ta)
h, m = delta // 3600, (delta % 3600) // 60
print(f"\n  {DIM}time delta: {h}h {m}m{NC}")
PYEOF
  echo ""
}

# ──────────────────────────────────────────────────
cmd_delete() {
  local name=$1
  [[ -z "$name" ]] && { echo -e "  ${RED}✗${NC} usage: br session delete <name>"; return 1; }
  local sf; sf=$(_session_file "$name")
  [[ ! -f "$sf" ]] && { echo -e "  ${RED}✗${NC} not found: $name"; return 1; }
  rm "$sf"
  echo -e "  ${DIM}◆${NC} deleted: $name"
}

# ──────────────────────────────────────────────────
show_help() {
  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR SESSION${NC}  ${DIM}Snapshot your workspace. Restore it anywhere.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "  ${AMBER}save${NC}    [name]          snapshot dir · branch · changed files"
  echo -e "  ${AMBER}restore${NC} <name>          cd to dir, checkout branch"
  echo -e "  ${AMBER}list${NC}                    all saved sessions"
  echo -e "  ${AMBER}export${NC}  <name> [file]   dump session + git log to JSON"
  echo -e "  ${AMBER}import${NC}  <file.json>     load exported session"
  echo -e "  ${AMBER}diff${NC}    <a> <b>         compare two sessions side-by-side"
  echo -e "  ${AMBER}delete${NC}  <name>          remove a session"
  echo ""
  echo -e "  ${DIM}sessions live at ~/.blackroad/sessions/${NC}"
  echo ""
}

# ──────────────────────────────────────────────────
case "${1:-list}" in
  save|s)           cmd_save "${2:-}" ;;
  restore|r|load)   cmd_restore "${2:-}" ;;
  list|l|ls|"")     cmd_list ;;
  export|exp)       cmd_export "${2:-}" "${3:-}" ;;
  import|imp)       cmd_import "${2:-}" ;;
  diff|d)           cmd_diff "${2:-}" "${3:-}" ;;
  delete|del|rm)    cmd_delete "${2:-}" ;;
  help|-h|--help)   show_help ;;
  *)                show_help ;;
esac
