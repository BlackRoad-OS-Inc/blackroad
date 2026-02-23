#!/bin/zsh
# BR Schedule — Workflow Scheduler (cron-style)
# Schedule br flows and commands to run automatically

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'

SCHED_DB="$HOME/.blackroad/schedule.db"
SCHED_LOG="$HOME/.blackroad/schedule.log"
SCHED_PID="$HOME/.blackroad/schedule.pid"

init_db() {
  mkdir -p "$(dirname "$SCHED_DB")"
  sqlite3 "$SCHED_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS schedules (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  command TEXT NOT NULL,
  schedule TEXT NOT NULL,
  enabled INTEGER DEFAULT 1,
  last_run INTEGER,
  next_run INTEGER,
  run_count INTEGER DEFAULT 0,
  last_status TEXT,
  created_at INTEGER DEFAULT (strftime('%s','now'))
);
CREATE TABLE IF NOT EXISTS schedule_runs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  schedule_id TEXT,
  started_at INTEGER,
  ended_at INTEGER,
  status TEXT,
  output TEXT
);
SQL
  # Seed default schedules
  local count
  count=$(sqlite3 "$SCHED_DB" "SELECT COUNT(*) FROM schedules;")
  if [[ "$count" == "0" ]]; then
    sqlite3 "$SCHED_DB" <<'SQL'
INSERT OR IGNORE INTO schedules (id, name, command, schedule, enabled) VALUES
  ('morning-flow',   'Morning Flow',      'br flow run morning',          'daily@08:00', 0),
  ('security-sweep', 'Security Sweep',    'br flow run security-sweep',   'daily@02:00', 0),
  ('chain-check',    'Chain Integrity',   'br chain verify 10',           'hourly',      0),
  ('relay-watch',    'Relay Heartbeat',   'br relay send all "heartbeat"', 'every:30m',  0),
  ('deploy-check',   'Deploy Health',     'br flow run deploy-check',     'daily@09:00', 0);
SQL
    echo -e "${GREEN}✓${NC} Seeded 5 default schedules"
  fi
}

# Parse schedule string and return next run epoch
next_run_epoch() {
  local sched="$1"
  python3 - "$sched" <<'PY'
import sys, time, re
from datetime import datetime, timedelta

sched = sys.argv[1]
now = datetime.now()

def next_epoch(dt):
    return int(dt.timestamp())

if sched == 'hourly':
    # Next top of the hour
    nxt = now.replace(minute=0, second=0, microsecond=0) + timedelta(hours=1)
    print(next_epoch(nxt))

elif sched.startswith('daily@'):
    # daily@HH:MM
    m = re.match(r'daily@(\d{2}):(\d{2})', sched)
    if m:
        h, mn = int(m.group(1)), int(m.group(2))
        nxt = now.replace(hour=h, minute=mn, second=0, microsecond=0)
        if nxt <= now:
            nxt += timedelta(days=1)
        print(next_epoch(nxt))
    else:
        print(int(time.time()) + 86400)

elif sched.startswith('every:'):
    # every:30m, every:2h, every:1d
    m = re.match(r'every:(\d+)([mhd])', sched)
    if m:
        n, unit = int(m.group(1)), m.group(2)
        delta = {'m': timedelta(minutes=n), 'h': timedelta(hours=n), 'd': timedelta(days=n)}[unit]
        print(next_epoch(now + delta))
    else:
        print(int(time.time()) + 3600)

elif sched.startswith('weekly@'):
    # weekly@MON@08:00
    m = re.match(r'weekly@(\w+)@(\d{2}):(\d{2})', sched)
    if m:
        days = {'MON':0,'TUE':1,'WED':2,'THU':3,'FRI':4,'SAT':5,'SUN':6}
        target_day = days.get(m.group(1).upper(), 0)
        h, mn = int(m.group(2)), int(m.group(3))
        days_ahead = target_day - now.weekday()
        if days_ahead <= 0:
            days_ahead += 7
        nxt = now + timedelta(days=days_ahead)
        nxt = nxt.replace(hour=h, minute=mn, second=0, microsecond=0)
        print(next_epoch(nxt))
    else:
        print(int(time.time()) + 604800)
else:
    # Default: 1 hour from now
    print(int(time.time()) + 3600)
PY
}

cmd_list() {
  echo -e "\n${BOLD}${CYAN}⏰ Scheduled Jobs${NC}\n"
  python3 - "$SCHED_DB" <<'PY'
import sqlite3, sys, time
db = sys.argv[1]
conn = sqlite3.connect(db)
rows = conn.execute("SELECT id, name, command, schedule, enabled, last_run, next_run, run_count, last_status FROM schedules ORDER BY enabled DESC, id").fetchall()

if not rows:
    print("  No schedules. Add with: br schedule add <id> <cmd> <schedule>")
else:
    print(f"  {'ID':<20} {'NAME':<22} {'SCHEDULE':<15} {'NEXT':<16} {'RUNS':<6} ST")
    print(f"  {'─'*20} {'─'*22} {'─'*15} {'─'*16} {'─'*6} ──")
    for id_, name, cmd, sched, enabled, last_run, next_run, runs, lstatus in rows:
        status_icon = '\033[32m●\033[0m' if enabled else '\033[90m○\033[0m'
        next_str = time.strftime('%m/%d %H:%M', time.localtime(next_run)) if next_run else '—'
        status_str = lstatus or '—'
        st_color = '\033[32m' if status_str == 'ok' else '\033[31m' if status_str == 'error' else '\033[90m'
        print(f"  {id_:<20} {name:<22} {sched:<15} {next_str:<16} {runs:<6} {status_icon} {st_color}{status_str}\033[0m")
print()
conn.close()
PY
}

cmd_add() {
  local sid="$1" cmd="$2" sched="${3:-hourly}" name="${4:-$1}"
  [[ -z "$sid" || -z "$cmd" ]] && {
    echo -e "${CYAN}Usage: br schedule add <id> <command> [schedule] [name]${NC}"
    echo -e "\nSchedule formats:"
    echo -e "  ${YELLOW}hourly${NC}           every hour"
    echo -e "  ${YELLOW}daily@08:00${NC}      daily at 8am"
    echo -e "  ${YELLOW}every:30m${NC}        every 30 minutes"
    echo -e "  ${YELLOW}every:2h${NC}         every 2 hours"
    echo -e "  ${YELLOW}weekly@MON@09:00${NC} every Monday at 9am"
    return 1
  }
  
  local nxt
  nxt=$(next_run_epoch "$sched")
  sqlite3 "$SCHED_DB" "INSERT OR REPLACE INTO schedules (id, name, command, schedule, next_run, enabled) VALUES ('$sid','$name','$cmd','$sched',$nxt,1);"
  echo -e "${GREEN}✓${NC} Scheduled: ${BOLD}$sid${NC}  →  $cmd  [$sched]"
  local next_fmt
  next_fmt=$(python3 -c "import time; print(time.strftime('%Y-%m-%d %H:%M', time.localtime($nxt)))")
  echo -e "  Next run: ${CYAN}$next_fmt${NC}"
}

cmd_enable() {
  local sid="$1"; local action="${2:-1}"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br schedule enable/disable <id>"; return 1; }
  sqlite3 "$SCHED_DB" "UPDATE schedules SET enabled=$action WHERE id='$sid';"
  local word; [[ "$action" == "1" ]] && word="enabled" || word="disabled"
  echo -e "${GREEN}✓${NC} $sid: $word"
}

cmd_run() {
  # Manually run a schedule now
  local sid="$1"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br schedule run <id>"; return 1; }
  
  local cmd
  cmd=$(sqlite3 "$SCHED_DB" "SELECT command FROM schedules WHERE id='$sid';")
  [[ -z "$cmd" ]] && { echo -e "${RED}✗${NC} Not found: $sid"; return 1; }
  
  echo -e "${CYAN}▶ Running:${NC} $cmd"
  local start output status_str
  start=$(date +%s)
  output=$(eval "$cmd" 2>&1)
  local ec=$?
  local end=$(date +%s)
  
  [[ $ec -eq 0 ]] && status_str="ok" || status_str="error"
  
  sqlite3 "$SCHED_DB" "UPDATE schedules SET last_run=$start, run_count=run_count+1, last_status='$status_str' WHERE id='$sid';"
  sqlite3 "$SCHED_DB" "INSERT INTO schedule_runs (schedule_id, started_at, ended_at, status, output) VALUES ('$sid',$start,$end,'$status_str','$(echo "$output" | head -50 | sed "s/'/''/g")');"
  
  echo "$output"
  local dur=$(( end - start ))
  echo -e "\n${GREEN}✓${NC} Done in ${dur}s  [$status_str]"
}

cmd_daemon() {
  # Simple scheduler daemon — checks every minute
  echo -e "${CYAN}⏰ Starting scheduler daemon (PID: $$)${NC}"
  echo "$$" > "$SCHED_PID"
  
  while true; do
    local now
    now=$(date +%s)
    
    # Find due schedules
    local due
    due=$(sqlite3 "$SCHED_DB" "SELECT id, command, schedule FROM schedules WHERE enabled=1 AND next_run <= $now;")
    
    if [[ -n "$due" ]]; then
      while IFS='|' read -r sid cmd sched; do
        [[ -z "$sid" ]] && continue
        echo "[$(date '+%H:%M:%S')] Running: $sid → $cmd" >> "$SCHED_LOG"
        local output
        output=$(eval "$cmd" 2>&1)
        local ec=$?
        local status_str; [[ $ec -eq 0 ]] && status_str="ok" || status_str="error"
        
        local nxt
        nxt=$(next_run_epoch "$sched")
        local ts=$(date +%s)
        sqlite3 "$SCHED_DB" "UPDATE schedules SET last_run=$ts, run_count=run_count+1, last_status='$status_str', next_run=$nxt WHERE id='$sid';"
        echo "[$(date '+%H:%M:%S')] Done: $sid [$status_str]" >> "$SCHED_LOG"
      done <<< "$due"
    fi
    
    sleep 60  # Check every minute
  done
}

cmd_start() {
  if [[ -f "$SCHED_PID" ]]; then
    local pid=$(cat "$SCHED_PID")
    if kill -0 "$pid" 2>/dev/null; then
      echo -e "${YELLOW}⚠${NC} Daemon already running (PID $pid)"
      return
    fi
  fi
  echo -e "${CYAN}Starting scheduler daemon in background...${NC}"
  nohup zsh -c "source $0; cmd_daemon" >> "$SCHED_LOG" 2>&1 &
  echo $! > "$SCHED_PID"
  echo -e "${GREEN}✓${NC} Scheduler daemon started (PID $!)"
  echo -e "  Log: $SCHED_LOG"
}

cmd_stop() {
  if [[ -f "$SCHED_PID" ]]; then
    local pid=$(cat "$SCHED_PID")
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid"
      rm -f "$SCHED_PID"
      echo -e "${GREEN}✓${NC} Scheduler stopped (PID $pid)"
    else
      echo -e "${YELLOW}⚠${NC} No running daemon found"
      rm -f "$SCHED_PID"
    fi
  else
    echo -e "${YELLOW}⚠${NC} No PID file found"
  fi
}

cmd_history() {
  local sid="$1"
  local filter=""; [[ -n "$sid" ]] && filter="WHERE schedule_id='$sid'"
  echo -e "\n${BOLD}${CYAN}📜 Schedule History${NC}\n"
  python3 - "$SCHED_DB" "$filter" <<'PY'
import sqlite3, sys, time
db, filt = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
rows = conn.execute(f"SELECT schedule_id, started_at, ended_at, status, output FROM schedule_runs {filt} ORDER BY started_at DESC LIMIT 20").fetchall()
for sid, start, end, status, output in rows:
    dt = time.strftime('%m/%d %H:%M', time.localtime(start)) if start else '?'
    dur = f"{end-start}s" if start and end else '?'
    st_color = '\033[32m' if status=='ok' else '\033[31m'
    print(f"  \033[90m{dt}\033[0m  {sid:<20}  {st_color}{status}\033[0m  {dur}")
    if output:
        for line in output.split('\n')[:2]:
            print(f"    \033[90m{line}\033[0m")
conn.close()
print()
PY
}

cmd_delete() {
  local sid="$1"
  [[ -z "$sid" ]] && { echo -e "${RED}✗${NC} Usage: br schedule delete <id>"; return 1; }
  sqlite3 "$SCHED_DB" "DELETE FROM schedules WHERE id='$sid';"
  echo -e "${GREEN}✓${NC} Deleted: $sid"
}

show_help() {
  echo -e "\n${BOLD}${CYAN}⏰ BR Schedule — Workflow Scheduler${NC}\n"
  echo -e "  ${CYAN}br schedule list${NC}                     — list all schedules"
  echo -e "  ${CYAN}br schedule add <id> <cmd> <sched>${NC}   — add new schedule"
  echo -e "  ${CYAN}br schedule run <id>${NC}                 — run now manually"
  echo -e "  ${CYAN}br schedule enable|disable <id>${NC}      — toggle schedule"
  echo -e "  ${CYAN}br schedule start${NC}                    — start daemon"
  echo -e "  ${CYAN}br schedule stop${NC}                     — stop daemon"
  echo -e "  ${CYAN}br schedule history [id]${NC}             — view run history"
  echo -e "  ${CYAN}br schedule delete <id>${NC}              — delete schedule"
  echo -e "\n  ${YELLOW}Schedules:${NC} hourly | daily@08:00 | every:30m | weekly@MON@09:00\n"
}

init_db
case "${1:-help}" in
  list|ls)            cmd_list ;;
  add|new|create)     cmd_add "$2" "$3" "$4" "$5" ;;
  run|exec|trigger)   cmd_run "$2" ;;
  enable)             cmd_enable "$2" 1 ;;
  disable)            cmd_enable "$2" 0 ;;
  start|daemon)       cmd_start ;;
  stop|kill)          cmd_stop ;;
  history|log|runs)   cmd_history "$2" ;;
  delete|rm|remove)   cmd_delete "$2" ;;
  help|--help|-h)     show_help ;;
  *) show_help ;;
esac
