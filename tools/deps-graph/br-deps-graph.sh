#!/usr/bin/env zsh
# BR Deps Graph — visualize project dependency graphs

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'

DB="$HOME/.blackroad/deps-graph.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS scans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT NOT NULL,
  type TEXT NOT NULL,
  pkg_count INTEGER DEFAULT 0,
  dep_count INTEGER DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS packages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  scan_id INTEGER,
  name TEXT NOT NULL,
  version TEXT DEFAULT '',
  is_dev INTEGER DEFAULT 0,
  is_peer INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS dep_edges (
  scan_id INTEGER,
  from_pkg TEXT NOT NULL,
  to_pkg TEXT NOT NULL,
  dep_type TEXT DEFAULT 'runtime'
);
SQL
}

# Detect project type and scan
cmd_scan() {
  local path="${1:-.}"
  path="$(realpath "$path")"
  [[ ! -d "$path" ]] && { echo -e "${RED}✗ Directory not found: $path${NC}"; exit 1; }
  echo ""
  echo -e "${CYAN}${BOLD}🔍 Scanning: $path${NC}"
  # Detect type
  local ptype="unknown"
  [[ -f "$path/package.json" ]] && ptype="node"
  [[ -f "$path/requirements.txt" || -f "$path/pyproject.toml" || -f "$path/setup.py" ]] && ptype="python"
  [[ -f "$path/go.mod" ]] && ptype="go"
  [[ -f "$path/Cargo.toml" ]] && ptype="rust"
  [[ -f "$path/Gemfile" ]] && ptype="ruby"
  echo -e "  Type:     ${BOLD}$ptype${NC}"
  case "$ptype" in
    node)    _scan_node "$path" ;;
    python)  _scan_python "$path" ;;
    go)      _scan_go "$path" ;;
    rust)    _scan_rust "$path" ;;
    ruby)    _scan_ruby "$path" ;;
    *)
      echo -e "${YELLOW}⚠ No recognized package manager found${NC}"
      echo -e "  Supported: package.json, requirements.txt, go.mod, Cargo.toml, Gemfile"
      ;;
  esac
}

_scan_node() {
  local path="$1"
  local scan_id
  scan_id=$(sqlite3 "$DB" "INSERT INTO scans (path, type) VALUES ('$path', 'node'); SELECT last_insert_rowid();")
  python3 - "$path" "$DB" "$scan_id" <<'PY'
import json, sys, sqlite3, os

path, db_path, scan_id = sys.argv[1], sys.argv[2], int(sys.argv[3])
pkg_file = os.path.join(path, 'package.json')
try:
    with open(pkg_file) as f:
        pkg = json.load(f)
except Exception as e:
    print(f"  Error reading package.json: {e}")
    sys.exit(1)

db = sqlite3.connect(db_path)
name = pkg.get('name', 'unknown')
version = pkg.get('version', '0.0.0')
print(f"  Package:  {name}@{version}")

deps = pkg.get('dependencies', {})
dev_deps = pkg.get('devDependencies', {})
peer_deps = pkg.get('peerDependencies', {})
all_deps = [(n, v, 0, 0) for n, v in deps.items()] + \
           [(n, v, 1, 0) for n, v in dev_deps.items()] + \
           [(n, v, 0, 1) for n, v in peer_deps.items()]

for n, v, is_dev, is_peer in all_deps:
    db.execute("INSERT INTO packages (scan_id, name, version, is_dev, is_peer) VALUES (?, ?, ?, ?, ?)",
               (scan_id, n, v, is_dev, is_peer))
    db.execute("INSERT INTO dep_edges (scan_id, from_pkg, to_pkg, dep_type) VALUES (?, ?, ?, ?)",
               (scan_id, name, n, 'dev' if is_dev else 'peer' if is_peer else 'runtime'))

db.execute("UPDATE scans SET pkg_count=1, dep_count=? WHERE id=?", (len(all_deps), scan_id))
db.commit()
print(f"  Deps:     {len(deps)} runtime, {len(dev_deps)} dev, {len(peer_deps)} peer")
print(f"  Total:    {len(all_deps)}")
PY
  _show_graph "$scan_id" "node"
}

_scan_python() {
  local path="$1"
  local scan_id
  scan_id=$(sqlite3 "$DB" "INSERT INTO scans (path, type) VALUES ('$path', 'python'); SELECT last_insert_rowid();")
  python3 - "$path" "$DB" "$scan_id" <<'PY'
import sys, sqlite3, os, re

path, db_path, scan_id = sys.argv[1], sys.argv[2], int(sys.argv[3])
db = sqlite3.connect(db_path)

deps = []
# Try requirements.txt first
req_file = os.path.join(path, 'requirements.txt')
if os.path.exists(req_file):
    with open(req_file) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and not line.startswith('-'):
                m = re.match(r'([a-zA-Z0-9_\-\.]+)(.*)', line)
                if m:
                    deps.append((m.group(1), m.group(2).strip(), 0))

# Try pyproject.toml
pyproj = os.path.join(path, 'pyproject.toml')
if os.path.exists(pyproj) and not deps:
    with open(pyproj) as f:
        content = f.read()
    for m in re.finditer(r'"([a-zA-Z0-9_\-\.]+)\s*([>=<^~!][^"]*)"', content):
        deps.append((m.group(1), m.group(2), 0))

proj_name = os.path.basename(path)
print(f"  Package:  {proj_name}")
for name, ver, is_dev in deps:
    db.execute("INSERT INTO packages (scan_id, name, version, is_dev) VALUES (?, ?, ?, ?)",
               (scan_id, name, ver, is_dev))
    db.execute("INSERT INTO dep_edges (scan_id, from_pkg, to_pkg) VALUES (?, ?, ?)",
               (scan_id, proj_name, name))

db.execute("UPDATE scans SET pkg_count=1, dep_count=? WHERE id=?", (len(deps), scan_id))
db.commit()
print(f"  Deps:     {len(deps)}")
PY
  _show_graph "$scan_id" "python"
}

_scan_go() {
  local path="$1"
  local scan_id
  scan_id=$(sqlite3 "$DB" "INSERT INTO scans (path, type) VALUES ('$path', 'go'); SELECT last_insert_rowid();")
  python3 - "$path" "$DB" "$scan_id" <<'PY'
import sys, sqlite3, os, re

path, db_path, scan_id = sys.argv[1], sys.argv[2], int(sys.argv[3])
db = sqlite3.connect(db_path)

go_mod = os.path.join(path, 'go.mod')
mod_name, deps, indirect = '', [], []
with open(go_mod) as f:
    in_require = False
    for line in f:
        line = line.strip()
        if line.startswith('module '):
            mod_name = line.split()[1]
        elif line == 'require (':
            in_require = True
        elif in_require and line == ')':
            in_require = False
        elif in_require or line.startswith('require '):
            parts = line.replace('require ', '').split()
            if len(parts) >= 2:
                is_indirect = '// indirect' in line
                deps.append((parts[0], parts[1], is_indirect))

print(f"  Module:   {mod_name}")
for name, ver, indirect in deps:
    db.execute("INSERT INTO packages (scan_id, name, version) VALUES (?, ?, ?)", (scan_id, name, ver))
    db.execute("INSERT INTO dep_edges (scan_id, from_pkg, to_pkg, dep_type) VALUES (?, ?, ?, ?)",
               (scan_id, mod_name, name, 'indirect' if indirect else 'runtime'))

direct = sum(1 for _, _, i in deps if not i)
indir = sum(1 for _, _, i in deps if i)
db.execute("UPDATE scans SET pkg_count=1, dep_count=? WHERE id=?", (len(deps), scan_id))
db.commit()
print(f"  Deps:     {direct} direct, {indir} indirect")
PY
  _show_graph "$scan_id" "go"
}

_scan_rust() {
  local path="$1"
  local scan_id
  scan_id=$(sqlite3 "$DB" "INSERT INTO scans (path, type) VALUES ('$path', 'rust'); SELECT last_insert_rowid();")
  python3 - "$path" "$DB" "$scan_id" <<'PY'
import sys, sqlite3, os, re

path, db_path, scan_id = sys.argv[1], sys.argv[2], int(sys.argv[3])
db = sqlite3.connect(db_path)

cargo = os.path.join(path, 'Cargo.toml')
pkg_name, deps = 'unknown', []
with open(cargo) as f:
    content = f.read()

m = re.search(r'\[package\].*?name\s*=\s*"([^"]+)"', content, re.DOTALL)
if m:
    pkg_name = m.group(1)

# Find [dependencies] section
dep_sec = re.search(r'\[dependencies\](.*?)(?=\[|\Z)', content, re.DOTALL)
if dep_sec:
    for m in re.finditer(r'^(\w[\w\-]+)\s*=\s*"([^"]+)"', dep_sec.group(1), re.MULTILINE):
        deps.append((m.group(1), m.group(2), 0))
    for m in re.finditer(r'^(\w[\w\-]+)\s*=\s*\{[^}]*version\s*=\s*"([^"]+)"', dep_sec.group(1), re.MULTILINE):
        deps.append((m.group(1), m.group(2), 0))

# dev-dependencies
dev_sec = re.search(r'\[dev-dependencies\](.*?)(?=\[|\Z)', content, re.DOTALL)
if dev_sec:
    for m in re.finditer(r'^(\w[\w\-]+)\s*=\s*"([^"]+)"', dev_sec.group(1), re.MULTILINE):
        deps.append((m.group(1), m.group(2), 1))

print(f"  Package:  {pkg_name}")
for name, ver, is_dev in deps:
    db.execute("INSERT INTO packages (scan_id, name, version, is_dev) VALUES (?, ?, ?, ?)",
               (scan_id, name, ver, is_dev))
    db.execute("INSERT INTO dep_edges (scan_id, from_pkg, to_pkg, dep_type) VALUES (?, ?, ?, ?)",
               (scan_id, pkg_name, name, 'dev' if is_dev else 'runtime'))

db.execute("UPDATE scans SET pkg_count=1, dep_count=? WHERE id=?", (len(deps), scan_id))
db.commit()
print(f"  Deps:     {len(deps)}")
PY
  _show_graph "$scan_id" "rust"
}

_show_graph() {
  local scan_id="$1" ptype="$2"
  echo ""
  echo -e "${CYAN}📦 Dependency Graph${NC}"
  echo ""
  # Get root package
  local root
  root=$(sqlite3 "$DB" "SELECT from_pkg FROM dep_edges WHERE scan_id=$scan_id LIMIT 1;")
  [[ -z "$root" ]] && { echo "  No dependencies found."; return; }
  echo -e "  ${BOLD}$root${NC}"
  # Runtime deps
  sqlite3 "$DB" "SELECT to_pkg, dep_type FROM dep_edges WHERE scan_id=$scan_id AND dep_type IN ('runtime','') ORDER BY dep_type, to_pkg LIMIT 40;" | while IFS="|" read -r dep dtype; do
    echo -e "  ${GREEN}├── $dep${NC}"
  done
  # Dev deps
  local dev_count
  dev_count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM dep_edges WHERE scan_id=$scan_id AND dep_type='dev';")
  if [[ "$dev_count" -gt 0 ]]; then
    echo -e "  ${BLUE}├── [devDependencies]${NC}"
    sqlite3 "$DB" "SELECT to_pkg FROM dep_edges WHERE scan_id=$scan_id AND dep_type='dev' ORDER BY to_pkg LIMIT 20;" | while read -r dep; do
      echo -e "  ${BLUE}│   ├── $dep${NC}"
    done
  fi
  # Indirect/peer
  local other_count
  other_count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM dep_edges WHERE scan_id=$scan_id AND dep_type NOT IN ('runtime','dev','');")
  [[ "$other_count" -gt 0 ]] && echo -e "  ${YELLOW}└── [+ $other_count indirect/peer]${NC}"
  echo ""
  # Stats
  local total runtime dev_ct
  total=$(sqlite3 "$DB" "SELECT dep_count FROM scans WHERE id=$scan_id;")
  runtime=$(sqlite3 "$DB" "SELECT COUNT(*) FROM dep_edges WHERE scan_id=$scan_id AND dep_type='runtime';")
  dev_ct=$(sqlite3 "$DB" "SELECT COUNT(*) FROM dep_edges WHERE scan_id=$scan_id AND dep_type='dev';")
  echo -e "  ${BOLD}Total: $total${NC}  Runtime: ${GREEN}$runtime${NC}  Dev: ${BLUE}$dev_ct${NC}"
  echo ""
}

# List past scans
cmd_history() {
  echo ""
  echo -e "${CYAN}📋 Scan History${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT id, type, dep_count, path, ts FROM scans ORDER BY ts DESC LIMIT 20;" | while IFS="|" read -r id typ cnt path ts; do
    printf "  ${BOLD}#%-4s${NC}  %-8s  %4s deps  %s  %s\n" "$id" "$typ" "$cnt" "${ts:0:16}" "$path"
  done
  echo ""
}

# Compare two scans
cmd_diff() {
  local id1="$1" id2="$2"
  [[ -z "$id1" || -z "$id2" ]] && { echo "Usage: br deps diff <scan_id1> <scan_id2>"; exit 1; }
  echo ""
  echo -e "${CYAN}📊 Diff: scan #$id1 → #$id2${NC}"
  echo ""
  echo -e "  ${GREEN}+ Added:${NC}"
  sqlite3 "$DB" "SELECT to_pkg FROM dep_edges WHERE scan_id=$id2 AND to_pkg NOT IN (SELECT to_pkg FROM dep_edges WHERE scan_id=$id1);" | while read -r pkg; do
    echo -e "    ${GREEN}+ $pkg${NC}"
  done
  echo ""
  echo -e "  ${RED}− Removed:${NC}"
  sqlite3 "$DB" "SELECT to_pkg FROM dep_edges WHERE scan_id=$id1 AND to_pkg NOT IN (SELECT to_pkg FROM dep_edges WHERE scan_id=$id2);" | while read -r pkg; do
    echo -e "    ${RED}- $pkg${NC}"
  done
  echo ""
}

# Check for duplicate packages
cmd_dupes() {
  local scan_id="${1:-}"
  [[ -z "$scan_id" ]] && scan_id=$(sqlite3 "$DB" "SELECT MAX(id) FROM scans;")
  echo ""
  echo -e "${CYAN}🔍 Duplicate Check (scan #$scan_id)${NC}"
  echo ""
  sqlite3 "$DB" "SELECT name, COUNT(*) as cnt FROM packages WHERE scan_id=$scan_id GROUP BY name HAVING cnt > 1 ORDER BY cnt DESC;" | while IFS="|" read -r pkg cnt; do
    echo -e "  ${YELLOW}⚠ $pkg${NC} appears $cnt times"
  done | { read -r line; if [[ -z "$line" ]]; then echo -e "  ${GREEN}✓ No duplicates${NC}"; else echo "$line"; fi; }
  echo ""
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br deps${NC} — dependency graph visualizer"
  echo ""
  echo -e "  ${GREEN}br deps [path]${NC}            Scan & visualize (auto-detect type)"
  echo -e "  ${GREEN}br deps scan [path]${NC}       Explicit scan"
  echo -e "  ${GREEN}br deps history${NC}           Show past scans"
  echo -e "  ${GREEN}br deps diff <id1> <id2>${NC}  Compare two scans"
  echo -e "  ${GREEN}br deps dupes [scan_id]${NC}   Find duplicate packages"
  echo ""
  echo -e "  ${YELLOW}Supported:${NC} package.json (node), requirements.txt (python), go.mod, Cargo.toml, Gemfile"
  echo ""
}

init_db
case "${1:-scan}" in
  scan|.)          shift; cmd_scan "${1:-.}" ;;
  history|log)     cmd_history ;;
  diff)            shift; cmd_diff "$@" ;;
  dupes|dupe)      shift; cmd_dupes "$@" ;;
  help|-h|--help)  show_help ;;
  *)
    # If first arg looks like a path, scan it
    if [[ -d "${1:-.}" ]] || [[ "$1" == "." ]]; then
      cmd_scan "${1:-.}"
    else
      show_help
    fi
    ;;
esac
