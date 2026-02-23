#!/bin/zsh
# BR SSH - SSH shortcuts, fleet management, and remote commands

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

DB_FILE="$HOME/.blackroad/ssh.db"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS hosts (
  name TEXT PRIMARY KEY,
  host TEXT NOT NULL,
  user TEXT DEFAULT 'pi',
  port INTEGER DEFAULT 22,
  key_path TEXT,
  tags TEXT,
  notes TEXT,
  last_seen TEXT
);
CREATE TABLE IF NOT EXISTS cmd_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  host TEXT, command TEXT, exit_code INTEGER,
  ts TEXT DEFAULT (datetime('now'))
);
SQL

  # Seed BlackRoad fleet
  sqlite3 "$DB_FILE" <<'SQL'
INSERT OR IGNORE INTO hosts(name,host,user,tags,notes) VALUES
  ('lucidia','192.168.4.64','pi','pi,primary','Primary Pi — Cloudflare tunnel, Ollama'),
  ('aria64','192.168.4.38','pi','pi,secondary','Secondary Pi — 22,500 agent capacity'),
  ('alice','192.168.4.49','alice','pi,tertiary','Tertiary Pi'),
  ('lucidia-alt','192.168.4.99','lucidia','pi,alternate','Alternate Lucidia instance'),
  ('infinity','159.65.43.12','root','droplet,do','DigitalOcean blackroad-os-infinity');
SQL
}
init_db

cmd_list() {
  echo ""
  echo -e "${BOLD}${CYAN}SSH Fleet:${NC}"
  echo ""
  printf "  %-15s %-18s %-10s %-10s  %s\n" "NAME" "HOST" "USER" "TAGS" "NOTES"
  echo "  ─────────────────────────────────────────────────────────────────"
  sqlite3 "$DB_FILE" "SELECT name, host, user, tags, notes FROM hosts ORDER BY name;" 2>/dev/null | \
    while IFS='|' read name host user tags notes; do
      printf "  %-15s %-18s %-10s %-10s  %s\n" "$name" "$host" "$user" "${tags:0:10}" "${notes:0:35}"
    done
  echo ""
}

cmd_connect() {
  local target="$1"; shift
  local extra_args=("$@")

  # lookup by name
  local host user port key_path
  read host user port key_path < <(sqlite3 "$DB_FILE" \
    "SELECT host, user, port, COALESCE(key_path,'') FROM hosts WHERE name='$target' OR host='$target' LIMIT 1;" 2>/dev/null | \
    python3 -c "import sys; line=sys.stdin.read().strip(); parts=line.split('|') if line else []; print(' '.join(parts) if parts else '')" 2>/dev/null)

  if [[ -z "$host" ]]; then
    # treat as direct host
    echo -e "${YELLOW}Host '$target' not in fleet, connecting directly...${NC}"
    ssh "$target" "${extra_args[@]}"
    return
  fi

  local ssh_args=("-p" "$port" "${extra_args[@]}")
  [[ -n "$key_path" && -f "$key_path" ]] && ssh_args=("-i" "$key_path" "${ssh_args[@]}")

  echo -e "${CYAN}→ Connecting to ${BOLD}${target}${NC}${CYAN} (${user}@${host}:${port})${NC}"
  sqlite3 "$DB_FILE" "UPDATE hosts SET last_seen=datetime('now') WHERE name='$target';"
  ssh "${ssh_args[@]}" "${user}@${host}"
}

cmd_run() {
  local target="$1"; shift
  local cmd="$*"
  [[ -z "$target" || -z "$cmd" ]] && { echo "Usage: br ssh run <host> <command>"; return 1; }

  local host user port key_path
  read host user port key_path < <(sqlite3 "$DB_FILE" \
    "SELECT host, user, port, COALESCE(key_path,'') FROM hosts WHERE name='$target' OR host='$target' LIMIT 1;" 2>/dev/null | \
    python3 -c "import sys; line=sys.stdin.read().strip(); parts=line.split('|') if line else []; print(' '.join(parts) if parts else '')" 2>/dev/null)

  [[ -z "$host" ]] && host="$target" && user="pi" && port=22

  local ssh_args=("-p" "$port" "-o" "ConnectTimeout=5" "-o" "BatchMode=yes")
  [[ -n "$key_path" && -f "$key_path" ]] && ssh_args=("-i" "$key_path" "${ssh_args[@]}")

  echo -e "${CYAN}→ ${target}: ${cmd}${NC}"
  local output exit_code
  output=$(ssh "${ssh_args[@]}" "${user}@${host}" "$cmd" 2>&1)
  exit_code=$?

  echo "$output"
  sqlite3 "$DB_FILE" "INSERT INTO cmd_history(host,command,exit_code) VALUES('$target',$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$cmd"),'$exit_code');"
  return $exit_code
}

cmd_ping_all() {
  echo ""
  echo -e "${BOLD}${CYAN}Fleet reachability:${NC}"
  echo ""
  sqlite3 "$DB_FILE" "SELECT name, host FROM hosts ORDER BY name;" 2>/dev/null | \
    while IFS='|' read name host; do
      local result
      result=$(ping -c 1 -W 1 "$host" 2>/dev/null | grep "1 packets transmitted")
      if echo "$result" | grep -q "1 received"; then
        echo -e "  ${GREEN}●${NC} ${name:15}  ${host}"
      else
        echo -e "  ${RED}○${NC} ${name:15}  ${host}  ${YELLOW}(unreachable)${NC}"
      fi
    done
  echo ""
}

cmd_run_all() {
  local cmd="$*"
  [[ -z "$cmd" ]] && { echo "Usage: br ssh run-all <command>"; return 1; }
  echo ""
  echo -e "${BOLD}${CYAN}Running on all fleet hosts: ${cmd}${NC}"
  echo ""
  sqlite3 "$DB_FILE" "SELECT name, host, user, port FROM hosts ORDER BY name;" 2>/dev/null | \
    while IFS='|' read name host user port; do
      echo -e "${CYAN}▸ ${name} (${host}):${NC}"
      ssh -p "$port" -o ConnectTimeout=3 -o BatchMode=yes "${user}@${host}" "$cmd" 2>&1 | \
        while IFS= read -r line; do echo "  $line"; done
      echo ""
    done
}

cmd_add() {
  local name="$1" host="$2" user="${3:-pi}" port="${4:-22}"
  [[ -z "$name" || -z "$host" ]] && { echo "Usage: br ssh add <name> <host> [user] [port]"; return 1; }
  sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO hosts(name,host,user,port) VALUES('$name','$host','$user','$port');"
  echo -e "${GREEN}✓ Added: ${name} → ${user}@${host}:${port}${NC}"
}

cmd_remove() {
  local name="$1"
  [[ -z "$name" ]] && { echo "Usage: br ssh remove <name>"; return 1; }
  sqlite3 "$DB_FILE" "DELETE FROM hosts WHERE name='$name';"
  echo -e "${GREEN}✓ Removed: ${name}${NC}"
}

cmd_history() {
  echo ""
  echo -e "${BOLD}${CYAN}SSH command history:${NC}"
  sqlite3 "$DB_FILE" "SELECT ts, host, exit_code, command FROM cmd_history ORDER BY id DESC LIMIT 20;" 2>/dev/null | \
    while IFS='|' read ts host code cmd; do
      local color="${GREEN}"; [[ "$code" != "0" ]] && color="${RED}"
      echo -e "  ${CYAN}${ts}${NC}  ${color}[${code}]${NC}  ${host:10}  ${cmd:0:60}"
    done
  echo ""
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br ssh${NC} — SSH fleet manager"
  echo ""
  echo "  ${CYAN}br ssh list${NC}                  List all fleet hosts"
  echo "  ${CYAN}br ssh <name>${NC}                Connect to host by name"
  echo "  ${CYAN}br ssh run <host> <cmd>${NC}      Run command on one host"
  echo "  ${CYAN}br ssh run-all <cmd>${NC}         Run command on all hosts"
  echo "  ${CYAN}br ssh ping${NC}                  Ping all fleet hosts"
  echo "  ${CYAN}br ssh add <name> <host>${NC}     Add host to fleet"
  echo "  ${CYAN}br ssh remove <name>${NC}         Remove host"
  echo "  ${CYAN}br ssh history${NC}               Command history"
  echo ""
  echo "  Pre-loaded: lucidia, aria64, alice, lucidia-alt, infinity"
  echo ""
}

case "${1:-list}" in
  list)       cmd_list ;;
  run-all)    shift; cmd_run_all "$@" ;;
  run)        shift; cmd_run "$@" ;;
  ping|ping-all) cmd_ping_all ;;
  add)        shift; cmd_add "$@" ;;
  remove|rm)  shift; cmd_remove "$@" ;;
  history)    cmd_history ;;
  help|-h)    cmd_help ;;
  *)          cmd_connect "$@" ;;
esac
