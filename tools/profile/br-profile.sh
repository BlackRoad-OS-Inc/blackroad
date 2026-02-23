#!/bin/zsh
# BR Profile — Environment Profile Manager
# Switch between dev/staging/prod configs with one command

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

PROFILE_DB="$HOME/.blackroad/profiles.db"
PROFILE_DIR="$HOME/.blackroad/profiles"
ACTIVE_FILE="$HOME/.blackroad/active-profile"

init_db() {
  mkdir -p "$(dirname "$PROFILE_DB")" "$PROFILE_DIR"
  sqlite3 "$PROFILE_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS profiles (
  name        TEXT PRIMARY KEY,
  description TEXT,
  env_type    TEXT DEFAULT 'development',
  vars        TEXT DEFAULT '{}',
  scripts     TEXT DEFAULT '{}',
  active      INTEGER DEFAULT 0,
  use_count   INTEGER DEFAULT 0,
  created_at  INTEGER DEFAULT (strftime('%s','now'))
);
SQL

  local count
  count=$(sqlite3 "$PROFILE_DB" "SELECT COUNT(*) FROM profiles;")
  if [[ "$count" == "0" ]]; then
    python3 - "$PROFILE_DB" <<'PY'
import sqlite3, sys, json
conn = sqlite3.connect(sys.argv[1])

profiles = [
    ("dev", "Local development", "development",
     json.dumps({"NODE_ENV": "development", "LOG_LEVEL": "debug", "API_URL": "http://localhost:3000", "DB_URL": "sqlite:///dev.db"}),
     json.dumps({"on_activate": "echo 'Dev mode on'"})),
    ("staging", "Staging environment", "staging",
     json.dumps({"NODE_ENV": "staging", "LOG_LEVEL": "info", "API_URL": "https://staging.api.blackroad.io"}),
     json.dumps({"on_activate": "echo 'Staging mode'"})),
    ("prod", "Production (read-only vars)", "production",
     json.dumps({"NODE_ENV": "production", "LOG_LEVEL": "warn", "API_URL": "https://api.blackroad.io"}),
     json.dumps({"on_activate": "echo 'Production mode — be careful!'"})),
    ("ollama", "Local Ollama AI setup", "development",
     json.dumps({"OLLAMA_URL": "http://localhost:11434", "DEFAULT_MODEL": "qwen2.5:3b", "BLACKROAD_GATEWAY_URL": "http://127.0.0.1:8787"}),
     json.dumps({})),
]

for name, desc, env_type, vars_json, scripts_json in profiles:
    conn.execute("INSERT OR IGNORE INTO profiles (name, description, env_type, vars, scripts) VALUES (?,?,?,?,?)",
                 (name, desc, env_type, vars_json, scripts_json))
conn.commit()
conn.close()
print("Seeded 4 profiles")
PY
  fi

  # Set dev as default active if none set
  if [[ ! -f "$ACTIVE_FILE" ]]; then
    echo "dev" > "$ACTIVE_FILE"
    sqlite3 "$PROFILE_DB" "UPDATE profiles SET active=1 WHERE name='dev';"
  fi
}

cmd_list() {
  local active
  active=$(cat "$ACTIVE_FILE" 2>/dev/null || echo "")
  echo -e "\n${BOLD}${CYAN}🎛  Environment Profiles${NC}\n"
  python3 - "$PROFILE_DB" "${active:-}" <<'PY'
import sqlite3, sys
db, active = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute("SELECT name, description, env_type, active, use_count FROM profiles ORDER BY env_type, name").fetchall()
for name, desc, etype, is_active, uses in rows:
    marker = " \033[32m◀ ACTIVE\033[0m" if name == active else ""
    type_colors = {"development": "\033[36m", "staging": "\033[33m", "production": "\033[31m"}
    tc = type_colors.get(etype, "\033[0m")
    print(f"  {tc}{'●' if name==active else '○'}\033[0m  \033[1m{name:<18}\033[0m  {tc}{etype:<14}\033[0m  \033[90m{desc or ''}\033[0m{marker}")
print()
conn.close()
PY
}

cmd_show() {
  local name="${1:-$(cat "$ACTIVE_FILE" 2>/dev/null)}"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} No profile specified and none active"; return 1; }
  echo -e "\n${BOLD}${CYAN}🎛  Profile: $name${NC}\n"
  python3 - "$PROFILE_DB" "$name" <<'PY'
import sqlite3, sys, json
db, name = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
row = conn.execute("SELECT name,description,env_type,vars,scripts,use_count FROM profiles WHERE name=?", (name,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Not found: {name}")
    sys.exit(1)
pname, desc, etype, vars_json, scripts_json, uses = row
print(f"  Description: {desc}")
print(f"  Type:        {etype}  |  Used: {uses}x\n")
vars_dict = json.loads(vars_json or '{}')
if vars_dict:
    print("  \033[33mVariables:\033[0m")
    for k, v in sorted(vars_dict.items()):
        # Mask sensitive values
        display = "***" if any(s in k.upper() for s in ['SECRET','KEY','TOKEN','PASS','PWD']) else v
        print(f"    {k:<30} = {display}")
print()
conn.close()
PY
}

cmd_activate() {
  local name="$1"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br profile use <name>"; return 1; }
  local exists
  exists=$(sqlite3 "$PROFILE_DB" "SELECT name FROM profiles WHERE name='$name';")
  [[ -z "$exists" ]] && { echo -e "${RED}✗${NC} Profile not found: $name"; return 1; }

  # Update DB
  sqlite3 "$PROFILE_DB" "UPDATE profiles SET active=0;"
  sqlite3 "$PROFILE_DB" "UPDATE profiles SET active=1, use_count=use_count+1 WHERE name='$name';"
  echo "$name" > "$ACTIVE_FILE"

  # Write .env file for the profile
  python3 - "$PROFILE_DB" "$name" "$PROFILE_DIR/$name.env" <<'PY'
import sqlite3, sys, json
db, name, env_file = sys.argv[1], sys.argv[2], sys.argv[3]
conn = sqlite3.connect(db)
row = conn.execute("SELECT vars, scripts FROM profiles WHERE name=?", (name,)).fetchone()
if not row: sys.exit(1)
vars_dict = json.loads(row[0] or '{}')
scripts = json.loads(row[1] or '{}')
with open(env_file, 'w') as f:
    f.write(f"# Profile: {name} — generated by br profile\n")
    for k, v in sorted(vars_dict.items()):
        f.write(f"export {k}={repr(v) if ' ' in str(v) else v}\n")
print(env_file)
# Run on_activate script if present
if scripts.get('on_activate'):
    print(f"  Running: {scripts['on_activate']}")
    import subprocess
    subprocess.run(scripts['on_activate'], shell=True)
conn.close()
PY

  echo -e "${GREEN}✓${NC} Profile activated: ${BOLD}$name${NC}"
  echo -e "  Source: ${YELLOW}source $PROFILE_DIR/$name.env${NC}"
  echo -e "  Or add to shell: ${YELLOW}br profile shell${NC}"
}

cmd_add_var() {
  local profile="$1" key="$2" val="$3"
  [[ -z "$profile" || -z "$key" ]] && {
    echo -e "${CYAN}Usage: br profile set <profile> <KEY> <value>${NC}"; return 1
  }
  python3 - "$PROFILE_DB" "$profile" "$key" "$val" <<'PY'
import sqlite3, sys, json
db, profile, key, val = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
conn = sqlite3.connect(db)
row = conn.execute("SELECT vars FROM profiles WHERE name=?", (profile,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Profile not found: {profile}")
    sys.exit(1)
d = json.loads(row[0] or '{}')
d[key] = val
conn.execute("UPDATE profiles SET vars=? WHERE name=?", (json.dumps(d), profile))
conn.commit()
print(f"\033[32m✓\033[0m {profile}.{key} = {val}")
conn.close()
PY
}

cmd_create() {
  local name="$1" desc="${2:-}" env_type="${3:-development}"
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} Usage: br profile create <name> [desc] [env_type]"; return 1; }
  sqlite3 "$PROFILE_DB" "INSERT OR IGNORE INTO profiles (name, description, env_type) VALUES ('$name','$desc','$env_type');"
  echo -e "${GREEN}✓${NC} Created profile: ${BOLD}$name${NC}  type=$env_type"
  echo -e "  Add vars: br profile set $name KEY value"
  echo -e "  Activate: br profile use $name"
}

cmd_shell() {
  local name
  name=$(cat "$ACTIVE_FILE" 2>/dev/null)
  [[ -z "$name" ]] && { echo -e "${RED}✗${NC} No active profile"; return 1; }
  local env_file="$PROFILE_DIR/$name.env"
  [[ ! -f "$env_file" ]] && cmd_activate "$name" >/dev/null

  echo -e "${CYAN}# Activate '$name' profile in current shell:${NC}"
  echo -e "${YELLOW}source $env_file${NC}"
  echo ""
  echo -e "${CYAN}# Or add to ~/.zshrc for auto-loading:${NC}"
  echo -e "${YELLOW}[ -f ~/.blackroad/profiles/$name.env ] && source ~/.blackroad/profiles/$name.env${NC}"
}

show_help() {
  echo -e "\n${BOLD}${CYAN}🎛  BR Profile — Environment Profile Manager${NC}\n"
  echo -e "  ${CYAN}br profile list${NC}                       — list profiles"
  echo -e "  ${CYAN}br profile show [name]${NC}                — show profile vars"
  echo -e "  ${CYAN}br profile use <name>${NC}                 — activate profile"
  echo -e "  ${CYAN}br profile set <name> <KEY> <val>${NC}     — set variable"
  echo -e "  ${CYAN}br profile create <name> [desc]${NC}       — new profile"
  echo -e "  ${CYAN}br profile shell${NC}                      — print source command\n"
  echo -e "  ${YELLOW}Built-in profiles:${NC} dev, staging, prod, ollama\n"
}

init_db
case "${1:-help}" in
  list|ls)          cmd_list ;;
  show|view|get)    cmd_show "$2" ;;
  use|activate|switch|set-active) cmd_activate "$2" ;;
  set|var|add-var)  cmd_add_var "$2" "$3" "$4" ;;
  create|new|add)   cmd_create "$2" "$3" "$4" ;;
  shell|source)     cmd_shell ;;
  active)           cat "$ACTIVE_FILE" 2>/dev/null || echo "none" ;;
  help|--help)      show_help ;;
  *) show_help ;;
esac
