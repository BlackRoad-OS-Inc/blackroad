#!/bin/zsh
# BR Feat — Feature Flag Manager
# Toggle features on/off across environments with rollout percentages

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

FEAT_DB="$HOME/.blackroad/features.db"

init_db() {
  mkdir -p "$(dirname "$FEAT_DB")"
  sqlite3 "$FEAT_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS flags (
  name        TEXT PRIMARY KEY,
  enabled     INTEGER DEFAULT 0,
  env         TEXT DEFAULT 'all',
  rollout_pct INTEGER DEFAULT 100,
  description TEXT,
  owner       TEXT,
  tags        TEXT DEFAULT '',
  kill_switch INTEGER DEFAULT 0,
  created_at  INTEGER DEFAULT (strftime('%s','now')),
  updated_at  INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS flag_history (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  flag      TEXT,
  action    TEXT,
  old_val   TEXT,
  new_val   TEXT,
  by_user   TEXT DEFAULT 'local',
  ts        INTEGER DEFAULT (strftime('%s','now'))
);
SQL

  local count
  count=$(sqlite3 "$FEAT_DB" "SELECT COUNT(*) FROM flags;")
  if [[ "$count" == "0" ]]; then
    sqlite3 "$FEAT_DB" <<'SQL'
INSERT INTO flags VALUES
  ('dark-mode',       1, 'all',        100, 'Dark mode UI',                'ui-team',   'ui,ux',      0, strftime('%s','now'), strftime('%s','now')),
  ('ai-autocomplete', 1, 'production', 80,  'AI code autocomplete',        'ai-team',   'ai,editor',  0, strftime('%s','now'), strftime('%s','now')),
  ('new-dashboard',   0, 'staging',    100, 'Redesigned dashboard',        'product',   'ui,beta',    0, strftime('%s','now'), strftime('%s','now')),
  ('beta-api-v3',     0, 'staging',    50,  'API v3 endpoints (beta)',      'backend',   'api,beta',   0, strftime('%s','now'), strftime('%s','now')),
  ('collab-mesh',     1, 'all',        100, 'Collaboration mesh enabled',   'platform',  'collab',     0, strftime('%s','now'), strftime('%s','now')),
  ('cost-tracking',   1, 'all',        100, 'AI cost tracking',             'platform',  'cost,ai',    0, strftime('%s','now'), strftime('%s','now')),
  ('debug-mode',      0, 'development',100, 'Verbose debug output',        'eng',       'debug',      1, strftime('%s','now'), strftime('%s','now')),
  ('experimental-llm',0, 'development',10,  '10% rollout new LLM backend', 'ai-team',   'ai,exp',     0, strftime('%s','now'), strftime('%s','now'));
SQL
    echo -e "${GREEN}✓${NC} Seeded 8 feature flags"
  fi
}

cmd_list() {
  local env="${1:-}" tag="${2:-}"
  echo -e "\n${BOLD}${CYAN}⛳ Feature Flags${NC}\n"
  python3 - "$FEAT_DB" "${env:-}" "${tag:-}" <<'PY'
import sqlite3, sys
db, env, tag = sys.argv[1], sys.argv[2], sys.argv[3]
conn = sqlite3.connect(db)
q = "SELECT name, enabled, env, rollout_pct, description, owner, tags, kill_switch FROM flags"
conds = []
if env: conds.append(f"(env='{env}' OR env='all')")
if tag: conds.append(f"tags LIKE '%{tag}%'")
if conds: q += " WHERE " + " AND ".join(conds)
q += " ORDER BY enabled DESC, name"
rows = conn.execute(q).fetchall()
if not rows:
    print("  No flags found.")
    sys.exit(0)
for name, enabled, fenv, pct, desc, owner, tags, kill in rows:
    status = "\033[32m● ON \033[0m" if enabled else "\033[90m○ off\033[0m"
    ks = " \033[31m[KILL]\033[0m" if kill else ""
    pct_str = f" {pct}%" if pct < 100 else ""
    env_str = f" \033[33m[{fenv}]\033[0m" if fenv != 'all' else ""
    print(f"  {status}{ks} \033[1m{name:<28}\033[0m{env_str}{pct_str}")
    if desc:
        print(f"       \033[90m{desc}  [{owner or ''}] {tags}\033[0m")
print()
conn.close()
PY
}

cmd_check() {
  local name="$1" env="${2:-production}"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br feat check <flag> [env]"; return 1; }
  python3 - "$FEAT_DB" "$name" "$env" <<'PY'
import sqlite3, sys, hashlib
db, name, env = sys.argv[1], sys.argv[2], sys.argv[3]
conn = sqlite3.connect(db)
row = conn.execute("SELECT enabled, rollout_pct, kill_switch, env FROM flags WHERE name=?", (name,)).fetchone()
if not row:
    print("UNDEFINED"); sys.exit(0)
enabled, pct, kill, flag_env = row
if kill:
    print("KILL_SWITCH"); sys.exit(0)
if flag_env != 'all' and flag_env != env:
    print("DISABLED_ENV"); sys.exit(0)
if not enabled:
    print("DISABLED"); sys.exit(0)
if pct == 100:
    print("ENABLED")
else:
    h = int(hashlib.md5(f"{name}-{env}".encode()).hexdigest(), 16) % 100
    print("ENABLED" if h < pct else f"ROLLOUT_{pct}pct")
conn.close()
PY
}

cmd_set() {
  local name="$1" state="$2"
  [[ -z "$name" || -z "$state" ]] && {
    echo -e "${CYAN}Usage: br feat set <flag> <on|off|toggle>${NC}"; return 1
  }
  local current
  current=$(sqlite3 "$FEAT_DB" "SELECT enabled FROM flags WHERE name='$name';")
  [[ -z "$current" ]] && { echo -e "${RED}✗${NC} Flag not found: $name"; return 1; }
  local new_val
  case "$state" in
    on|enable|1)     new_val=1 ;;
    off|disable|0)   new_val=0 ;;
    toggle)          new_val=$((1 - current)) ;;
    *) echo -e "${RED}✗${NC} State: on/off/toggle"; return 1 ;;
  esac
  sqlite3 "$FEAT_DB" "UPDATE flags SET enabled=$new_val, updated_at=strftime('%s','now') WHERE name='$name';"
  sqlite3 "$FEAT_DB" "INSERT INTO flag_history (flag,action,old_val,new_val) VALUES ('$name','set','$current','$new_val');"
  local label="ON"; [[ "$new_val" == "0" ]] && label="OFF"
  local color="$GREEN"; [[ "$new_val" == "0" ]] && color="$YELLOW"
  echo -e "${color}●${NC} $name → ${BOLD}$label${NC}"
}

cmd_create() {
  local name="$1" desc="${2:-}" env="${3:-all}" pct="${4:-100}"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br feat create <name> [desc] [env] [pct]"; return 1; }
  sqlite3 "$FEAT_DB" "INSERT OR IGNORE INTO flags (name, description, env, rollout_pct) VALUES ('$name','$desc','$env',$pct);"
  echo -e "${GREEN}✓${NC} Created: ${BOLD}$name${NC}  env=$env rollout=$pct% status=OFF"
  echo -e "  ${YELLOW}br feat set $name on${NC}"
}

cmd_delete() {
  local name="$1"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br feat delete <name>"; return 1; }
  sqlite3 "$FEAT_DB" "DELETE FROM flags WHERE name='$name';"
  echo -e "${GREEN}✓${NC} Deleted: $name"
}

cmd_history() {
  local name="${1:-}"
  echo -e "\n${BOLD}${CYAN}📜 Flag History${NC}\n"
  python3 - "$FEAT_DB" "${name:-}" <<'PY'
import sqlite3, sys, time
db, name = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
if name:
    rows = conn.execute("SELECT flag,action,old_val,new_val,by_user,ts FROM flag_history WHERE flag=? ORDER BY ts DESC LIMIT 20",(name,)).fetchall()
else:
    rows = conn.execute("SELECT flag,action,old_val,new_val,by_user,ts FROM flag_history ORDER BY ts DESC LIMIT 30").fetchall()
for flag, action, old, new, user, ts in rows:
    t = time.strftime('%m/%d %H:%M', time.localtime(ts))
    vals = f"  \033[90m{old}→{new}\033[0m" if old != new else ""
    print(f"  \033[36m{t}\033[0m  \033[1m{flag:<28}\033[0m  {action}{vals}  \033[90m{user}\033[0m")
if not rows: print("  No history.")
print()
conn.close()
PY
}

cmd_export_json() {
  python3 - "$FEAT_DB" <<'PY'
import sqlite3, sys, json
conn = sqlite3.connect(sys.argv[1])
rows = conn.execute("SELECT name,enabled,env,rollout_pct,description,tags FROM flags").fetchall()
flags = {n: {"enabled": bool(e), "env": ev, "rollout_pct": p, "description": d, "tags": t.split(',')} for n,e,ev,p,d,t in rows}
print(json.dumps({"feature_flags": flags, "_version": 1}, indent=2))
conn.close()
PY
}

show_help() {
  echo -e "\n${BOLD}${CYAN}⛳ BR Feat — Feature Flag Manager${NC}\n"
  echo -e "  ${CYAN}br feat list [env] [tag]${NC}             — list flags"
  echo -e "  ${CYAN}br feat check <name> [env]${NC}           — check flag state"
  echo -e "  ${CYAN}br feat set <name> <on|off|toggle>${NC}   — flip a flag"
  echo -e "  ${CYAN}br feat create <name> [desc] [env]${NC}   — new flag"
  echo -e "  ${CYAN}br feat delete <name>${NC}                — remove flag"
  echo -e "  ${CYAN}br feat history [name]${NC}               — change history"
  echo -e "  ${CYAN}br feat export${NC}                       — dump as JSON\n"
}

init_db
case "${1:-help}" in
  list|ls)       cmd_list "$2" "$3" ;;
  check|is)      cmd_check "$2" "$3" ;;
  set)           cmd_set "$2" "$3" ;;
  on)            cmd_set "$2" on ;;
  off)           cmd_set "$2" off ;;
  toggle)        cmd_set "$2" toggle ;;
  create|add)    cmd_create "$2" "$3" "$4" "$5" ;;
  delete|rm)     cmd_delete "$2" ;;
  history|log)   cmd_history "$2" ;;
  export|json)   cmd_export_json ;;
  help|--help)   show_help ;;
  *) show_help ;;
esac
