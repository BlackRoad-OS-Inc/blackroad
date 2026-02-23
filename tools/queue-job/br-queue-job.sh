#!/bin/zsh
# BR Queue — Job Queue Manager
# Persistent async job queue with workers and retry logic

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

QUEUE_DB="$HOME/.blackroad/queue.db"
WORKER_DIR="$HOME/.blackroad/queue-workers"
LOCK_FILE="$HOME/.blackroad/queue-worker.lock"

init_db() {
  mkdir -p "$(dirname "$QUEUE_DB")" "$WORKER_DIR"
  sqlite3 "$QUEUE_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS jobs (
  id          TEXT PRIMARY KEY,
  queue       TEXT DEFAULT 'default',
  command     TEXT NOT NULL,
  payload     TEXT DEFAULT '{}',
  status      TEXT DEFAULT 'pending',
  priority    INTEGER DEFAULT 5,
  attempts    INTEGER DEFAULT 0,
  max_retries INTEGER DEFAULT 3,
  result      TEXT,
  error       TEXT,
  worker_id   TEXT,
  created_at  INTEGER DEFAULT (strftime('%s','now')),
  scheduled_at INTEGER DEFAULT (strftime('%s','now')),
  started_at  INTEGER,
  done_at     INTEGER
);
CREATE INDEX IF NOT EXISTS idx_queue_status ON jobs(queue, status, priority DESC, scheduled_at);
CREATE TABLE IF NOT EXISTS queues (
  name        TEXT PRIMARY KEY,
  description TEXT,
  concurrency INTEGER DEFAULT 1,
  active      INTEGER DEFAULT 1
);
SQL

  # Seed default queues
  sqlite3 "$QUEUE_DB" <<'SQL'
INSERT OR IGNORE INTO queues VALUES
  ('default',  'Default job queue',         1, 1),
  ('ai',       'AI/LLM tasks',              1, 1),
  ('deploy',   'Deployment jobs',           1, 1),
  ('notify',   'Notifications',             3, 1),
  ('low',      'Low priority background',   1, 1);
SQL
}

generate_id() {
  python3 -c "import uuid; print(str(uuid.uuid4())[:12])"
}

cmd_push() {
  # br queue push <command> [--queue Q] [--priority N] [--delay Ns]
  local cmd="$1"; shift
  local queue="default" priority=5 delay=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --queue|-q)    queue="$2";    shift 2 ;;
      --priority|-p) priority="$2"; shift 2 ;;
      --delay|-d)    delay="$2";    shift 2 ;;
      *) shift ;;
    esac
  done

  [[ -z "$cmd" ]] && {
    echo -e "${CYAN}Usage: br queue push <command> [--queue Q] [--priority 1-10] [--delay 30s]${NC}"
    echo -e "Example: br queue push 'br deploy prod' --queue deploy --priority 8"
    return 1
  }

  local job_id scheduled_at
  job_id=$(generate_id)
  scheduled_at=$(python3 -c "import time; print(int(time.time()) + $delay)")

  sqlite3 "$QUEUE_DB" "INSERT INTO jobs (id, queue, command, priority, scheduled_at) VALUES ('$job_id','$queue','$(echo "$cmd" | sed "s/'/''/g")',$priority,$scheduled_at);"

  echo -e "${GREEN}✓${NC} Job queued: ${BOLD}$job_id${NC}"
  echo -e "  Queue: $queue | Priority: $priority | Command: $cmd"
  [[ $delay -gt 0 ]] && echo -e "  Scheduled: ${delay}s from now"
  echo "$job_id"
}

cmd_list() {
  local queue="${1:-}" status="${2:-}"
  echo -e "\n${BOLD}${CYAN}📋 Job Queue${NC}\n"
  python3 - "$QUEUE_DB" "${queue:-}" "${status:-}" <<'PY'
import sqlite3, sys, time
db, queue, status = sys.argv[1], sys.argv[2], sys.argv[3]
conn = sqlite3.connect(db)
q = "SELECT id, queue, command, status, priority, attempts, created_at, done_at FROM jobs"
conds = []
if queue:  conds.append(f"queue='{queue}'")
if status: conds.append(f"status='{status}'")
if conds: q += " WHERE " + " AND ".join(conds)
q += " ORDER BY status, priority DESC, scheduled_at LIMIT 50"
rows = conn.execute(q).fetchall()

# Header: queue summary
queues = conn.execute("SELECT queue, COUNT(*), SUM(status='pending'), SUM(status='running'), SUM(status='done'), SUM(status='failed') FROM jobs GROUP BY queue").fetchall()
for qn, total, pend, run, done, fail in queues:
    print(f"  \033[1m{qn:<14}\033[0m  pending={pend} running=\033[33m{run}\033[0m done=\033[32m{done}\033[0m failed=\033[31m{fail}\033[0m  (total {total})")
print()

if not rows:
    print("  Queue empty!")
else:
    status_colors = {"pending": "\033[90m", "running": "\033[33m", "done": "\033[32m", "failed": "\033[31m", "cancelled": "\033[90m"}
    for jid, jq, cmd, jst, pri, attempts, created, done_at in rows:
        sc = status_colors.get(jst, "")
        t = time.strftime('%H:%M:%S', time.localtime(created))
        cmd_short = cmd[:45] + ("…" if len(cmd) > 45 else "")
        print(f"  {sc}{jst:<10}\033[0m  \033[1m{jid}\033[0m  [{jq}] p={pri}  {cmd_short}")
        print(f"             \033[90m{t}  attempts={attempts}\033[0m")
print()
conn.close()
PY
}

cmd_status() {
  local job_id="$1"
  [[ -z "$job_id" ]] && { echo -e "${RED}✗${NC} Usage: br queue status <job_id>"; return 1; }
  python3 - "$QUEUE_DB" "$job_id" <<'PY'
import sqlite3, sys, time
db, jid = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)
row = conn.execute("SELECT id,queue,command,status,priority,attempts,result,error,created_at,started_at,done_at FROM jobs WHERE id=?", (jid,)).fetchone()
if not row:
    print(f"\033[31m✗\033[0m Not found: {jid}")
    sys.exit(1)
jid, q, cmd, st, pri, att, result, err, created, started, done = row
status_colors = {"pending": "\033[90m", "running": "\033[33m", "done": "\033[32m", "failed": "\033[31m"}
sc = status_colors.get(st, "")
print(f"\n  \033[1m{jid}\033[0m  {sc}{st}\033[0m  [{q}] priority={pri}")
print(f"  Command: {cmd}")
if created: print(f"  Created: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(created))}")
if started: print(f"  Started: {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(started))}")
if done:    print(f"  Done:    {time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(done))}")
if result:  print(f"\n  \033[32mResult:\033[0m {result[:200]}")
if err:     print(f"\n  \033[31mError:\033[0m {err[:200]}")
print()
conn.close()
PY
}

cmd_run() {
  # Process one pending job from the queue
  local queue="${1:-default}"
  local job_id cmd

  job_id=$(sqlite3 "$QUEUE_DB" "SELECT id FROM jobs WHERE queue='$queue' AND status='pending' AND scheduled_at <= strftime('%s','now') ORDER BY priority DESC, scheduled_at LIMIT 1;" 2>/dev/null)
  [[ -z "$job_id" ]] && { echo -e "${YELLOW}⊘${NC} No pending jobs in queue: $queue"; return 0; }

  cmd=$(sqlite3 "$QUEUE_DB" "SELECT command FROM jobs WHERE id='$job_id';")
  local started_at
  started_at=$(python3 -c "import time; print(int(time.time()))")
  sqlite3 "$QUEUE_DB" "UPDATE jobs SET status='running', started_at=$started_at, attempts=attempts+1 WHERE id='$job_id';"

  echo -e "${CYAN}▶${NC} Running job ${BOLD}$job_id${NC}: $cmd"
  local output exit_code
  output=$(eval "$cmd" 2>&1)
  exit_code=$?

  local done_at
  done_at=$(python3 -c "import time; print(int(time.time()))")

  if [[ $exit_code -eq 0 ]]; then
    local result_escaped
    result_escaped=$(echo "$output" | head -10 | sed "s/'/''/g")
    sqlite3 "$QUEUE_DB" "UPDATE jobs SET status='done', done_at=$done_at, result='$result_escaped' WHERE id='$job_id';"
    echo -e "${GREEN}✓${NC} Job done: $job_id"
  else
    local attempts max_retries
    attempts=$(sqlite3 "$QUEUE_DB" "SELECT attempts FROM jobs WHERE id='$job_id';")
    max_retries=$(sqlite3 "$QUEUE_DB" "SELECT max_retries FROM jobs WHERE id='$job_id';")
    local err_escaped
    err_escaped=$(echo "$output" | tail -5 | sed "s/'/''/g")

    if [[ $attempts -ge $max_retries ]]; then
      sqlite3 "$QUEUE_DB" "UPDATE jobs SET status='failed', done_at=$done_at, error='$err_escaped' WHERE id='$job_id';"
      echo -e "${RED}✗${NC} Job failed (max retries): $job_id"
    else
      local retry_at=$(( done_at + (attempts * 30) ))
      sqlite3 "$QUEUE_DB" "UPDATE jobs SET status='pending', scheduled_at=$retry_at, error='$err_escaped' WHERE id='$job_id';"
      echo -e "${YELLOW}↺${NC} Job will retry (attempt $attempts/$max_retries): $job_id"
    fi
  fi
}

cmd_worker() {
  local queue="${1:-default}" interval="${2:-5}"
  echo -e "${BOLD}${CYAN}⚙ Queue Worker${NC} — queue=$queue interval=${interval}s"
  echo -e "  ${YELLOW}Ctrl+C to stop${NC}\n"

  while true; do
    cmd_run "$queue"
    sleep "$interval"
  done
}

cmd_cancel() {
  local job_id="$1"
  [[ -z "$job_id" ]] && { echo -e "${RED}✗${NC} Usage: br queue cancel <job_id>"; return 1; }
  sqlite3 "$QUEUE_DB" "UPDATE jobs SET status='cancelled' WHERE id='$job_id' AND status='pending';"
  echo -e "${YELLOW}⊘${NC} Cancelled: $job_id"
}

cmd_clear() {
  local queue="${1:-default}" status="${2:-done}"
  local count
  count=$(sqlite3 "$QUEUE_DB" "SELECT COUNT(*) FROM jobs WHERE queue='$queue' AND status='$status';")
  sqlite3 "$QUEUE_DB" "DELETE FROM jobs WHERE queue='$queue' AND status='$status';"
  echo -e "${GREEN}✓${NC} Cleared $count $status jobs from $queue"
}

show_help() {
  echo -e "\n${BOLD}${CYAN}📋 BR Queue — Job Queue Manager${NC}\n"
  echo -e "  ${CYAN}br queue push <cmd> [--queue Q] [--priority N]${NC}  — add job"
  echo -e "  ${CYAN}br queue list [queue] [status]${NC}                  — list jobs"
  echo -e "  ${CYAN}br queue status <job_id>${NC}                        — job details"
  echo -e "  ${CYAN}br queue run [queue]${NC}                            — process one job"
  echo -e "  ${CYAN}br queue worker [queue] [interval_s]${NC}            — run worker loop"
  echo -e "  ${CYAN}br queue cancel <job_id>${NC}                        — cancel job"
  echo -e "  ${CYAN}br queue clear [queue] [status]${NC}                 — clear done jobs\n"
  echo -e "  ${YELLOW}Built-in queues:${NC} default, ai, deploy, notify, low"
  echo -e "  ${YELLOW}Statuses:${NC} pending → running → done | failed | cancelled\n"
}

init_db
case "${1:-help}" in
  push|add|enqueue)     shift; cmd_push "$@" ;;
  list|ls|jobs)         cmd_list "$2" "$3" ;;
  status|show|get)      cmd_status "$2" ;;
  run|process|next)     cmd_run "$2" ;;
  worker|daemon|watch)  cmd_worker "$2" "$3" ;;
  cancel|remove)        cmd_cancel "$2" ;;
  clear|flush|purge)    cmd_clear "$2" "$3" ;;
  help|--help)          show_help ;;
  *) show_help ;;
esac
