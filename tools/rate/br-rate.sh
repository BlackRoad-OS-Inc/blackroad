#!/usr/bin/env zsh
# BR Rate — API rate limit tracker

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'

DB="$HOME/.blackroad/rate.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS services (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  limit_per_min INTEGER DEFAULT 60,
  limit_per_hour INTEGER DEFAULT 1000,
  limit_per_day INTEGER DEFAULT 10000,
  warn_pct INTEGER DEFAULT 80,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS calls (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  service TEXT NOT NULL,
  endpoint TEXT DEFAULT '',
  method TEXT DEFAULT 'GET',
  status_code INTEGER DEFAULT 200,
  latency_ms REAL DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  service TEXT NOT NULL,
  window TEXT NOT NULL,
  usage INTEGER,
  limit_val INTEGER,
  pct REAL,
  ts TEXT DEFAULT (datetime('now'))
);
INSERT OR IGNORE INTO services (name, limit_per_min, limit_per_hour, limit_per_day, warn_pct) VALUES
  ('github', 10, 5000, 50000, 80),
  ('openai', 60, 3500, 90000, 85),
  ('anthropic', 50, 2000, 50000, 85),
  ('cloudflare', 1200, 6000, 100000, 90),
  ('vercel', 100, 6000, 100000, 80),
  ('railway', 60, 3600, 86400, 80),
  ('stripe', 100, 6000, 100000, 90),
  ('ollama', 0, 0, 0, 95);
SQL
}

_check_limits() {
  local svc="$1"
  local exists
  exists=$(sqlite3 "$DB" "SELECT COUNT(*) FROM services WHERE name='$svc';")
  [[ "$exists" -eq 0 ]] && return
  local lim_min lim_hr warn
  lim_min=$(sqlite3 "$DB" "SELECT limit_per_min FROM services WHERE name='$svc';")
  lim_hr=$(sqlite3 "$DB" "SELECT limit_per_hour FROM services WHERE name='$svc';")
  warn=$(sqlite3 "$DB" "SELECT warn_pct FROM services WHERE name='$svc';")
  local cnt_min cnt_hr
  cnt_min=$(sqlite3 "$DB" "SELECT COUNT(*) FROM calls WHERE service='$svc' AND ts >= datetime('now', '-1 minute');")
  cnt_hr=$(sqlite3 "$DB" "SELECT COUNT(*) FROM calls WHERE service='$svc' AND ts >= datetime('now', '-1 hour');")
  if [[ "$lim_min" -gt 0 ]]; then
    local pct=$(( cnt_min * 100 / lim_min ))
    if [[ $pct -ge $warn ]]; then
      echo -e "${YELLOW}⚠ Rate limit warning: $svc — ${pct}% of per-minute limit (${cnt_min}/${lim_min})${NC}"
      sqlite3 "$DB" "INSERT INTO alerts (service, window, usage, limit_val, pct) VALUES ('$svc', 'minute', $cnt_min, $lim_min, $pct);"
    fi
  fi
  if [[ "$lim_hr" -gt 0 ]]; then
    local pct=$(( cnt_hr * 100 / lim_hr ))
    if [[ $pct -ge $warn ]]; then
      echo -e "${YELLOW}⚠ Rate limit warning: $svc — ${pct}% of per-hour limit (${cnt_hr}/${lim_hr})${NC}"
    fi
  fi
}

cmd_track() {
  local service="$1" endpoint="${2:-/}" method="${3:-GET}" status="${4:-200}" latency="${5:-0}"
  [[ -z "$service" ]] && { echo "Usage: br rate track <service> [endpoint] [method] [status] [latency_ms]"; exit 1; }
  sqlite3 "$DB" "INSERT INTO calls (service, endpoint, method, status_code, latency_ms) VALUES ('$service', '$endpoint', '$method', $status, $latency);"
  echo -e "${GREEN}✓ Tracked: $service $method $endpoint ($status)${NC}"
  _check_limits "$service"
}

cmd_status() {
  echo ""
  echo -e "${BLUE}${BOLD}┌─────────────────────────────────────────────────────────┐${NC}"
  echo -e "${BLUE}${BOLD}│           📊 BR Rate Limit Tracker                      │${NC}"
  echo -e "${BLUE}${BOLD}└─────────────────────────────────────────────────────────┘${NC}"
  echo ""
  printf "  ${BOLD}%-14s %8s %8s %8s %7s %7s %8s${NC}\n" "Service" "/min" "/hr" "/day" "1m%" "1h%" "1d%"
  printf "  %-14s %8s %8s %8s %7s %7s %8s\n" "─────────────" "──────" "──────" "──────" "─────" "─────" "──────"
  sqlite3 -separator "|" "$DB" "SELECT name, limit_per_min, limit_per_hour, limit_per_day, warn_pct FROM services ORDER BY name;" | while IFS="|" read -r name lm lh ld warn; do
    local cm ch cd
    cm=$(sqlite3 "$DB" "SELECT COUNT(*) FROM calls WHERE service='$name' AND ts >= datetime('now', '-1 minute');")
    ch=$(sqlite3 "$DB" "SELECT COUNT(*) FROM calls WHERE service='$name' AND ts >= datetime('now', '-1 hour');")
    cd=$(sqlite3 "$DB" "SELECT COUNT(*) FROM calls WHERE service='$name' AND ts >= datetime('now', '-1 day');")
    local pm="-" ph="-" pd="-"
    [[ "$lm" -gt 0 ]] && pm="$(( cm * 100 / lm ))%"
    [[ "$lh" -gt 0 ]] && ph="$(( ch * 100 / lh ))%"
    [[ "$ld" -gt 0 ]] && pd="$(( cd * 100 / ld ))%"
    local color="$GREEN"
    [[ "$pm" != "-" ]] && [[ "${pm%\%}" -ge "$warn" ]] && color="$YELLOW"
    [[ "$pm" != "-" ]] && [[ "${pm%\%}" -ge 100 ]] && color="$RED"
    printf "  ${color}%-14s${NC} %8s %8s %8s %7s %7s %8s\n" "$name" "${lm:-∞}" "${lh:-∞}" "${ld:-∞}" "$pm" "$ph" "$pd"
  done
  echo ""
}

cmd_calls() {
  local service="${1:-}" n="${2:-20}"
  echo ""
  echo -e "${CYAN}📡 Recent API Calls${NC}"
  echo ""
  local where=""
  [[ -n "$service" ]] && where="WHERE service='$service'"
  sqlite3 -separator "|" "$DB" "SELECT service, method, endpoint, status_code, latency_ms, ts FROM calls $where ORDER BY ts DESC LIMIT $n;" | while IFS="|" read -r svc mth ep sc lat ts; do
    local color="$GREEN"
    [[ "$sc" -ge 400 ]] && color="$YELLOW"
    [[ "$sc" -ge 500 ]] && color="$RED"
    printf "  ${color}%-12s${NC}  %-5s  %-30s  %s  ${CYAN}%.0fms${NC}  %s\n" "$svc" "$mth" "${ep:0:30}" "$sc" "$lat" "${ts:11:8}"
  done
  echo ""
}

cmd_stats() {
  local service="${1:-}"
  echo ""
  echo -e "${CYAN}📈 Call Statistics${NC}"
  echo ""
  local where=""
  [[ -n "$service" ]] && where="WHERE service='$service'"
  sqlite3 -separator "|" "$DB" "SELECT service, COUNT(*) as total, AVG(latency_ms), MIN(latency_ms), MAX(latency_ms), SUM(CASE WHEN status_code >= 400 THEN 1 ELSE 0 END) FROM calls $where GROUP BY service ORDER BY total DESC;" | while IFS="|" read -r svc total avg min max errors; do
    local err_pct=0
    [[ "$total" -gt 0 ]] && err_pct=$(( errors * 100 / total ))
    local color="$GREEN"; [[ $err_pct -gt 5 ]] && color="$YELLOW"; [[ $err_pct -gt 20 ]] && color="$RED"
    echo -e "  ${BOLD}$svc${NC}  total=${total}  errors=${color}${errors} (${err_pct}%)${NC}  lat=${avg%.*}/${min%.*}/${max%.*}ms avg/min/max"
  done
  echo ""
}

cmd_alerts() {
  echo ""
  echo -e "${YELLOW}⚠  Rate Limit Alerts (last 50)${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT service, window, usage, limit_val, pct, ts FROM alerts ORDER BY ts DESC LIMIT 50;" | while IFS="|" read -r svc win use lim pct ts; do
    printf "  ${YELLOW}%-12s${NC}  %-8s  %s/%s  (%.0f%%)  %s\n" "$svc" "$win" "$use" "$lim" "$pct" "$ts"
  done
  echo ""
}

cmd_set() {
  local service="$1" lmin="${2:-60}" lhr="${3:-1000}" lday="${4:-10000}" warn="${5:-80}"
  [[ -z "$service" ]] && { echo "Usage: br rate set <service> [limit/min] [limit/hr] [limit/day] [warn%]"; exit 1; }
  sqlite3 "$DB" "INSERT OR REPLACE INTO services (name, limit_per_min, limit_per_hour, limit_per_day, warn_pct) VALUES ('$service', $lmin, $lhr, $lday, $warn);"
  echo -e "${GREEN}✓ Service '$service': ${lmin}/min ${lhr}/hr ${lday}/day warn@${warn}%${NC}"
}

cmd_reset() {
  local service="$1"
  [[ -z "$service" ]] && { echo "Usage: br rate reset <service|all>"; exit 1; }
  if [[ "$service" == "all" ]]; then
    sqlite3 "$DB" "DELETE FROM calls; DELETE FROM alerts;"
    echo -e "${GREEN}✓ All call history cleared${NC}"
  else
    sqlite3 "$DB" "DELETE FROM calls WHERE service='$service'; DELETE FROM alerts WHERE service='$service';"
    echo -e "${GREEN}✓ History cleared for '$service'${NC}"
  fi
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br rate${NC} — API rate limit tracker"
  echo ""
  echo -e "  ${GREEN}br rate status${NC}                     Rate limit dashboard"
  echo -e "  ${GREEN}br rate track <svc> [ep] [mth] [sc] [ms]${NC}  Track a call"
  echo -e "  ${GREEN}br rate calls [svc] [n]${NC}            Show recent calls"
  echo -e "  ${GREEN}br rate stats [svc]${NC}                Usage statistics"
  echo -e "  ${GREEN}br rate alerts${NC}                     Show triggered alerts"
  echo -e "  ${GREEN}br rate set <svc> [lm] [lh] [ld] [w%]${NC}  Configure limits"
  echo -e "  ${GREEN}br rate reset <svc|all>${NC}            Clear call history"
  echo ""
  echo -e "  ${YELLOW}Built-in:${NC} github, openai, anthropic, cloudflare, vercel, railway, stripe, ollama"
  echo ""
}

init_db
case "${1:-status}" in
  status|s)        cmd_status ;;
  track|t)         shift; cmd_track "$@" ;;
  calls|c)         shift; cmd_calls "$@" ;;
  stats)           shift; cmd_stats "$@" ;;
  alerts|warn)     cmd_alerts ;;
  set|config)      shift; cmd_set "$@" ;;
  reset|clear)     shift; cmd_reset "$@" ;;
  help|-h|--help)  show_help ;;
  *)               show_help ;;
esac
