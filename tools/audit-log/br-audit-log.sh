#!/usr/bin/env zsh
# BR Audit Log — track all br commands with timestamps

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'

DB="$HOME/.blackroad/audit.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tool TEXT NOT NULL,
  subcommand TEXT DEFAULT '',
  args TEXT DEFAULT '',
  exit_code INTEGER DEFAULT 0,
  duration_ms REAL DEFAULT 0,
  user TEXT DEFAULT '',
  cwd TEXT DEFAULT '',
  host TEXT DEFAULT '',
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS tool_stats (
  tool TEXT PRIMARY KEY,
  count INTEGER DEFAULT 0,
  errors INTEGER DEFAULT 0,
  last_used TEXT
);
SQL
}

# Record a command run (called from br dispatcher wrapper)
cmd_record() {
  local tool="$1" subcmd="${2:-}" args="${3:-}" exit_code="${4:-0}" dur="${5:-0}"
  local user cwd host
  user="$(whoami 2>/dev/null || echo 'unknown')"
  cwd="$(pwd)"
  host="$(hostname -s 2>/dev/null || echo 'local')"
  # Escape single quotes
  args="${args//\'/''}"
  subcmd="${subcmd//\'/''}"
  sqlite3 "$DB" "INSERT INTO audit_log (tool, subcommand, args, exit_code, duration_ms, user, cwd, host) VALUES ('$tool', '$subcmd', '$args', $exit_code, $dur, '$user', '$cwd', '$host');"
  # Update stats
  sqlite3 "$DB" "INSERT OR REPLACE INTO tool_stats (tool, count, errors, last_used) VALUES ('$tool', COALESCE((SELECT count+1 FROM tool_stats WHERE tool='$tool'), 1), COALESCE((SELECT errors + CASE WHEN $exit_code != 0 THEN 1 ELSE 0 END FROM tool_stats WHERE tool='$tool'), CASE WHEN $exit_code != 0 THEN 1 ELSE 0 END), datetime('now'));"
}

# Show recent log
cmd_show() {
  local n="${1:-50}" tool="${2:-}"
  echo ""
  echo -e "${BLUE}${BOLD}┌─────────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${BLUE}${BOLD}│  📋 BR Audit Log                                                 │${NC}"
  echo -e "${BLUE}${BOLD}└─────────────────────────────────────────────────────────────────┘${NC}"
  echo ""
  printf "  ${BOLD}%-5s %-12s %-12s %-20s %4s %8s  %8s${NC}\n" "ID" "Tool" "Subcmd" "Args" "Exit" "ms" "Time"
  printf "  %-5s %-12s %-12s %-20s %4s %8s  %8s\n" "─────" "──────────" "──────────" "──────────────────" "────" "──────" "────────"
  local where=""
  [[ -n "$tool" ]] && where="WHERE tool='$tool'"
  sqlite3 -separator "|" "$DB" "SELECT id, tool, subcommand, args, exit_code, duration_ms, ts FROM audit_log $where ORDER BY ts DESC LIMIT $n;" | while IFS="|" read -r id tool sub args ec dur ts; do
    local color="$GREEN"
    [[ "$ec" -ne 0 ]] && color="$RED"
    printf "  ${color}%-5s %-12s %-12s %-20s %4s %8.0f  %8s${NC}\n" "$id" "$tool" "${sub:0:12}" "${args:0:20}" "$ec" "$dur" "${ts:11:8}"
  done
  echo ""
}

# Summary / top tools
cmd_summary() {
  echo ""
  echo -e "${CYAN}📊 Usage Summary${NC}"
  echo ""
  echo -e "  ${BOLD}Top commands used:${NC}"
  sqlite3 -separator "|" "$DB" "SELECT tool, count, errors, last_used FROM tool_stats ORDER BY count DESC LIMIT 20;" | while IFS="|" read -r tool cnt err last; do
    local color="$GREEN"
    [[ "$err" -gt 0 ]] && color="$YELLOW"
    printf "  ${color}%-20s${NC}  %5s runs  %3s errors  last: %s\n" "$tool" "$cnt" "$err" "${last:0:16}"
  done
  echo ""
  echo -e "  ${BOLD}Error rate by tool:${NC}"
  sqlite3 -separator "|" "$DB" "SELECT tool, count, errors, CASE WHEN count>0 THEN round(errors*100.0/count,1) ELSE 0 END as err_pct FROM tool_stats WHERE errors > 0 ORDER BY err_pct DESC LIMIT 10;" | while IFS="|" read -r tool cnt err pct; do
    local color="$YELLOW"; [[ "${pct%.*}" -ge 50 ]] && color="$RED"
    printf "  ${color}%-20s${NC}  ${pct}%% errors (%s/%s)\n" "$tool" "$err" "$cnt"
  done
  echo ""
  local total today
  total=$(sqlite3 "$DB" "SELECT COUNT(*) FROM audit_log;")
  today=$(sqlite3 "$DB" "SELECT COUNT(*) FROM audit_log WHERE ts >= date('now');")
  echo -e "  Total commands: ${BOLD}$total${NC}  Today: ${BOLD}$today${NC}"
  echo ""
}

# Show commands by time
cmd_timeline() {
  local hours="${1:-24}"
  echo ""
  echo -e "${CYAN}⏱ Command Timeline (last ${hours}h)${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT strftime('%H:00', ts) as hr, COUNT(*) as cnt FROM audit_log WHERE ts >= datetime('now', '-${hours} hours') GROUP BY hr ORDER BY hr;" | while IFS="|" read -r hr cnt; do
    local bar=""
    local i=0
    while [[ $i -lt $cnt && $i -lt 40 ]]; do
      bar="${bar}█"
      i=$(( i + 1 ))
    done
    printf "  %s  ${CYAN}%-40s${NC}  %s\n" "$hr" "$bar" "$cnt"
  done
  echo ""
}

# Search log
cmd_search() {
  local query="$1"
  [[ -z "$query" ]] && { echo "Usage: br audit search <query>"; exit 1; }
  echo ""
  echo -e "${CYAN}🔍 Search: '$query'${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT id, tool, subcommand, args, exit_code, ts FROM audit_log WHERE tool LIKE '%$query%' OR subcommand LIKE '%$query%' OR args LIKE '%$query%' ORDER BY ts DESC LIMIT 30;" | while IFS="|" read -r id tool sub args ec ts; do
    local color="$GREEN"; [[ "$ec" -ne 0 ]] && color="$RED"
    printf "  ${color}[%s]${NC} %-12s %-12s %s\n" "$ts" "$tool" "$sub" "$args"
  done
  echo ""
}

# Export to CSV or JSON
cmd_export() {
  local fmt="${1:-csv}" out="${2:-audit-$(date +%Y%m%d).${1:-csv}}"
  case "$fmt" in
    csv)
      echo "id,tool,subcommand,args,exit_code,duration_ms,user,cwd,host,ts" > "$out"
      sqlite3 -separator "," "$DB" "SELECT id,tool,subcommand,args,exit_code,duration_ms,user,cwd,host,ts FROM audit_log;" >> "$out"
      echo -e "${GREEN}✓ Exported to $out${NC}"
      ;;
    json)
      python3 - "$DB" "$out" <<'PY'
import sqlite3, json, sys
db = sqlite3.connect(sys.argv[1])
db.row_factory = sqlite3.Row
rows = [dict(r) for r in db.execute("SELECT * FROM audit_log ORDER BY ts DESC")]
with open(sys.argv[2], 'w') as f:
    json.dump(rows, f, indent=2)
print(f"Exported {len(rows)} entries to {sys.argv[2]}")
PY
      ;;
    *)
      echo "Formats: csv, json"; exit 1 ;;
  esac
}

# Clear old entries
cmd_prune() {
  local days="${1:-30}"
  local n
  n=$(sqlite3 "$DB" "SELECT COUNT(*) FROM audit_log WHERE ts < datetime('now', '-${days} days');")
  sqlite3 "$DB" "DELETE FROM audit_log WHERE ts < datetime('now', '-${days} days');"
  echo -e "${GREEN}✓ Pruned $n entries older than ${days} days${NC}"
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br audit${NC} — command audit log"
  echo ""
  echo -e "  ${GREEN}br audit${NC}                  Show recent commands"
  echo -e "  ${GREEN}br audit [n] [tool]${NC}       Show last n commands (filter by tool)"
  echo -e "  ${GREEN}br audit summary${NC}          Usage stats, top tools, error rates"
  echo -e "  ${GREEN}br audit timeline [h]${NC}     Hourly activity chart (default 24h)"
  echo -e "  ${GREEN}br audit search <q>${NC}       Search log entries"
  echo -e "  ${GREEN}br audit export [csv|json]${NC} Export full log"
  echo -e "  ${GREEN}br audit record <tool> ...${NC} Record a command (internal)"
  echo -e "  ${GREEN}br audit prune [days]${NC}     Prune entries older than N days"
  echo ""
  echo -e "  Auto-records every ${YELLOW}br${NC} command when enabled in dispatcher."
  echo ""
}

init_db
case "${1:-show}" in
  show|log|ls|"")  [[ $# -gt 0 ]] && shift; cmd_show "$@" ;;
  summary|stats)   cmd_summary ;;
  timeline)        shift; cmd_timeline "$@" ;;
  search)          shift; cmd_search "$@" ;;
  export)          shift; cmd_export "$@" ;;
  record)          shift; cmd_record "$@" ;;
  prune|clean)     shift; cmd_prune "$@" ;;
  help|-h|--help)  show_help ;;
  [0-9]*)          cmd_show "$@" ;;
  *)               show_help ;;
esac
