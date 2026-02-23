#!/usr/bin/env zsh
# BR Health — service health monitor with history and alerts

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'
DB="$HOME/.blackroad/health.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS checks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  type TEXT NOT NULL DEFAULT 'http',
  target TEXT NOT NULL,
  interval_sec INTEGER DEFAULT 60,
  timeout_sec INTEGER DEFAULT 10,
  expected_code INTEGER DEFAULT 200,
  expected_body TEXT DEFAULT '',
  alert_after INTEGER DEFAULT 3,
  enabled INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  check_name TEXT NOT NULL,
  ok INTEGER NOT NULL,
  latency_ms REAL DEFAULT 0,
  status_code INTEGER DEFAULT 0,
  error TEXT DEFAULT '',
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS incidents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  check_name TEXT NOT NULL,
  started_at TEXT DEFAULT (datetime('now')),
  resolved_at TEXT DEFAULT '',
  duration_sec INTEGER DEFAULT 0,
  open INTEGER DEFAULT 1
);
INSERT OR IGNORE INTO checks (name, type, target, interval_sec, expected_code) VALUES
  ('blackroad-gateway',  'http', 'http://127.0.0.1:8787/health',   30,  200),
  ('ollama',             'http', 'http://localhost:11434/api/tags', 60,  200),
  ('lucidia-pi',         'tcp',  '192.168.4.38:22',                60,  0),
  ('alice-pi',           'tcp',  '192.168.4.49:22',                60,  0),
  ('blackroad-ai',       'http', 'https://blackroad.ai',           300, 200),
  ('github-api',         'http', 'https://api.github.com',         300, 200),
  ('cloudflare-tunnel',  'http', 'https://agent.blackroad.ai',     120, 200);
SQL
}

_check_http() {
  local name="$1" url="$2" expected="${3:-200}" body_match="${4:-}" timeout="${5:-10}"
  local start sc resp lat ok=0 err=""
  start=$(python3 -c "import time; print(int(time.time()*1000))")
  resp=$(curl -s -o /tmp/br-health-body-$$ -w "%{http_code}" \
    --connect-timeout "$timeout" --max-time "$timeout" "$url" 2>/dev/null)
  lat=$(( $(python3 -c "import time; print(int(time.time()*1000))") - start ))
  sc="${resp:-0}"
  if [[ "$sc" -eq "$expected" ]]; then
    ok=1
    if [[ -n "$body_match" ]]; then
      grep -q "$body_match" /tmp/br-health-body-$$ 2>/dev/null || { ok=0; err="body mismatch"; }
    fi
  else
    err="HTTP $sc (expected $expected)"
  fi
  rm -f /tmp/br-health-body-$$
  echo "${ok}|${lat}|${sc}|${err}"
}

_check_tcp() {
  local host="$1" port="$2" timeout="${3:-5}"
  local start lat ok=0 err=""
  start=$(python3 -c "import time; print(int(time.time()*1000))")
  if python3 -c "
import socket, sys
try:
    s = socket.create_connection(('$host', $port), timeout=$timeout)
    s.close(); sys.exit(0)
except: sys.exit(1)
" 2>/dev/null; then
    ok=1
  else
    err="connection refused"
  fi
  lat=$(( $(python3 -c "import time; print(int(time.time()*1000))") - start ))
  echo "${ok}|${lat}|0|${err}"
}

_check_ping() {
  local host="$1"
  local start lat ok=0 err=""
  start=$(python3 -c "import time; print(int(time.time()*1000))")
  if ping -c 1 -W 2 "$host" &>/dev/null; then ok=1; else err="unreachable"; fi
  lat=$(( $(python3 -c "import time; print(int(time.time()*1000))") - start ))
  echo "${ok}|${lat}|0|${err}"
}

_run_check() {
  local name="$1"
  local row
  row=$(sqlite3 -separator "|" "$DB" "SELECT type, target, expected_code, expected_body, timeout_sec FROM checks WHERE name='$name' AND enabled=1;")
  [[ -z "$row" ]] && return
  local ctype ctarget cexp cbody ctimeout
  IFS="|" read -r ctype ctarget cexp cbody ctimeout <<< "$row"
  local result
  case "$ctype" in
    http|https) result=$(_check_http "$name" "$ctarget" "$cexp" "$cbody" "$ctimeout") ;;
    tcp)
      local chost="${ctarget%:*}" cport="${ctarget##*:}"
      result=$(_check_tcp "$chost" "$cport" "$ctimeout") ;;
    ping) result=$(_check_ping "${ctarget%:*}") ;;
    *) result="0|0|0|unknown type" ;;
  esac
  local ok lat sc err
  IFS="|" read -r ok lat sc err <<< "$result"
  sqlite3 "$DB" "INSERT INTO results (check_name, ok, latency_ms, status_code, error) VALUES ('$name', $ok, $lat, $sc, '${err//\'/}');"
  # Incident tracking
  local open_incident
  open_incident=$(sqlite3 "$DB" "SELECT COUNT(*) FROM incidents WHERE check_name='$name' AND open=1;")
  if [[ "$ok" -eq 0 && "$open_incident" -eq 0 ]]; then
    sqlite3 "$DB" "INSERT INTO incidents (check_name) VALUES ('$name');"
  elif [[ "$ok" -eq 1 && "$open_incident" -gt 0 ]]; then
    sqlite3 "$DB" "UPDATE incidents SET open=0, resolved_at=datetime('now'), duration_sec=CAST((julianday('now')-julianday(started_at))*86400 AS INTEGER) WHERE check_name='$name' AND open=1;"
  fi
  echo "${ok}|${lat}|${sc}|${err}"
}

cmd_check() {
  local target="${1:-all}"
  echo ""
  if [[ "$target" == "all" ]]; then
    sqlite3 "$DB" "SELECT name FROM checks WHERE enabled=1;" | while read -r name; do
      _run_single_display "$name"
    done
  else
    _run_single_display "$target"
  fi
  echo ""
}

_run_single_display() {
  local name="$1"
  local row
  row=$(sqlite3 -separator "|" "$DB" "SELECT type, target FROM checks WHERE name='$name';")
  local ctype ctarget
  IFS="|" read -r ctype ctarget <<< "$row"
  printf "  %-25s %-8s %-35s  " "$name" "$ctype" "${ctarget:0:35}"
  local result
  result=$(_run_check "$name")
  local ok lat sc err
  IFS="|" read -r ok lat sc err <<< "$result"
  if [[ "$ok" -eq 1 ]]; then
    echo -e "${GREEN}✓ UP${NC}  ${CYAN}${lat}ms${NC}"
  else
    echo -e "${RED}✗ DOWN${NC}  ${err}"
  fi
}

cmd_status() {
  echo ""
  echo -e "${BLUE}${BOLD}┌─────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${BLUE}${BOLD}│  💚 BR Health Monitor                                       │${NC}"
  echo -e "${BLUE}${BOLD}└─────────────────────────────────────────────────────────────┘${NC}"
  echo ""
  printf "  ${BOLD}%-25s %-8s %-8s %8s %8s %6s${NC}\n" "Service" "Type" "Status" "Latency" "Uptime%" "24h"
  printf "  %-25s %-8s %-8s %8s %8s %6s\n" "───────────────────────" "──────" "──────" "──────" "──────" "────"
  sqlite3 -separator "|" "$DB" "SELECT name, type, target FROM checks WHERE enabled=1 ORDER BY name;" | while IFS="|" read -r name ctype ctarget; do
    # Last result
    local last_ok last_lat
    last_ok=$(sqlite3 "$DB" "SELECT ok FROM results WHERE check_name='$name' ORDER BY ts DESC LIMIT 1;")
    last_lat=$(sqlite3 "$DB" "SELECT latency_ms FROM results WHERE check_name='$name' ORDER BY ts DESC LIMIT 1;")
    local uptime
    uptime=$(sqlite3 "$DB" "SELECT CASE WHEN COUNT(*)=0 THEN '?' ELSE round(SUM(ok)*100.0/COUNT(*),1) END FROM results WHERE check_name='$name' AND ts >= datetime('now','-24 hours');")
    local h24
    h24=$(sqlite3 "$DB" "SELECT COUNT(*) FROM results WHERE check_name='$name' AND ts >= datetime('now','-24 hours');")
    local color="$YELLOW" status="UNKNOWN"
    [[ "$last_ok" == "1" ]] && color="$GREEN" && status="UP"
    [[ "$last_ok" == "0" ]] && color="$RED" && status="DOWN"
    printf "  ${color}%-25s %-8s %-8s %8s %7s%% %6s${NC}\n" "$name" "$ctype" "$status" "${last_lat:-?}ms" "$uptime" "$h24"
  done
  echo ""
  # Open incidents
  local open_count
  open_count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM incidents WHERE open=1;")
  if [[ "$open_count" -gt 0 ]]; then
    echo -e "  ${RED}${BOLD}⚠ $open_count open incident(s):${NC}"
    sqlite3 -separator "|" "$DB" "SELECT check_name, started_at FROM incidents WHERE open=1;" | while IFS="|" read -r cn st; do
      echo -e "  ${RED}  ✗ $cn — down since $st${NC}"
    done
    echo ""
  fi
}

cmd_add() {
  local name="$1" ctype="${2:-http}" target="$3" interval="${4:-60}" expected="${5:-200}"
  [[ -z "$name" || -z "$target" ]] && { echo "Usage: br health add <name> <type> <target> [interval] [expected_code]"; exit 1; }
  sqlite3 "$DB" "INSERT OR REPLACE INTO checks (name, type, target, interval_sec, expected_code) VALUES ('$name', '$ctype', '$target', $interval, $expected);"
  echo -e "${GREEN}✓ Check '$name' added: $ctype $target${NC}"
}

cmd_history() {
  local name="${1:-}" n="${2:-20}"
  local where=""; [[ -n "$name" ]] && where="WHERE check_name='$name'"
  echo ""
  echo -e "${CYAN}📜 Health Check History${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT check_name, ok, latency_ms, status_code, error, ts FROM results $where ORDER BY ts DESC LIMIT $n;" | while IFS="|" read -r cn ok lat sc err ts; do
    local color="$GREEN"; [[ "$ok" -eq 0 ]] && color="$RED"
    local sym="✓"; [[ "$ok" -eq 0 ]] && sym="✗"
    printf "  ${color}%s${NC}  %-22s  %7.0fms  %s\n" "$sym" "$cn" "$lat" "${ts:0:16}"
    [[ -n "$err" ]] && echo -e "       ${RED}$err${NC}"
  done
  echo ""
}

cmd_incidents() {
  echo ""
  echo -e "${RED}🚨 Incidents${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT check_name, started_at, resolved_at, duration_sec, open FROM incidents ORDER BY started_at DESC LIMIT 20;" | while IFS="|" read -r cn st rs dur op; do
    local color="$RED" badge="OPEN"; [[ "$op" -eq 0 ]] && color="$GREEN" && badge="resolved"
    printf "  ${color}%-8s${NC}  %-22s  from %s" "$badge" "$cn" "${st:0:16}"
    [[ "$op" -eq 0 ]] && printf "  →  %s  (%ss)" "${rs:0:16}" "$dur"
    echo ""
  done
  echo ""
}

cmd_watch() {
  local interval="${1:-30}"
  echo -e "${CYAN}👁 Watching all checks every ${interval}s — Ctrl-C to stop${NC}"
  while true; do
    clear
    cmd_status
    echo -e "  ${YELLOW}Next check in ${interval}s — $(date)${NC}"
    sleep "$interval"
  done
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br health${NC} — service health monitor"
  echo ""
  echo -e "  ${GREEN}br health${NC}                      Status dashboard"
  echo -e "  ${GREEN}br health check [name|all]${NC}     Run checks now"
  echo -e "  ${GREEN}br health watch [interval]${NC}     Live watch mode"
  echo -e "  ${GREEN}br health history [name] [n]${NC}   Check history"
  echo -e "  ${GREEN}br health incidents${NC}            Incident log"
  echo -e "  ${GREEN}br health add <n> <type> <target>${NC}  Add check"
  echo ""
  echo -e "  ${YELLOW}Types:${NC} http, tcp, ping"
  echo -e "  ${YELLOW}Built-in:${NC} blackroad-gateway, ollama, lucidia-pi, alice-pi, github-api, cloudflare-tunnel"
  echo ""
}

init_db
case "${1:-status}" in
  status|s|"")     cmd_status ;;
  check|run)       shift; cmd_check "${1:-all}" ;;
  watch)           shift; cmd_watch "${1:-30}" ;;
  history|log)     shift; cmd_history "$@" ;;
  incidents|inc)   cmd_incidents ;;
  add)             shift; cmd_add "$@" ;;
  help|-h|--help)  show_help ;;
  *)               show_help ;;
esac
