#!/bin/zsh
# BR Trace — Distributed Request Tracing
# Track spans, latencies, and request flows across services

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

TRACE_DB="$HOME/.blackroad/traces.db"

init_db() {
  mkdir -p "$(dirname "$TRACE_DB")"
  sqlite3 "$TRACE_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS traces (
  trace_id    TEXT NOT NULL,
  span_id     TEXT NOT NULL,
  parent_id   TEXT,
  name        TEXT NOT NULL,
  service     TEXT DEFAULT 'local',
  status      TEXT DEFAULT 'ok',
  start_ms    INTEGER NOT NULL,
  duration_ms INTEGER,
  tags        TEXT DEFAULT '{}',
  error       TEXT,
  PRIMARY KEY (trace_id, span_id)
);
CREATE INDEX IF NOT EXISTS idx_trace ON traces(trace_id);
CREATE INDEX IF NOT EXISTS idx_service ON traces(service);
CREATE TABLE IF NOT EXISTS trace_meta (
  trace_id    TEXT PRIMARY KEY,
  name        TEXT,
  service     TEXT,
  total_ms    INTEGER,
  span_count  INTEGER DEFAULT 0,
  has_error   INTEGER DEFAULT 0,
  created_at  INTEGER DEFAULT (strftime('%s','now'))
);
SQL
}

generate_id() {
  python3 -c "import uuid; print(str(uuid.uuid4())[:16].replace('-',''))"
}

cmd_start() {
  # br trace start <name> [service] [parent_trace_id]
  local name="${1:-unnamed}" service="${2:-local}" parent="${3:-}"
  local trace_id span_id start_ms
  trace_id=$(generate_id)
  span_id=$(generate_id)
  start_ms=$(python3 -c "import time; print(int(time.time()*1000))")

  if [[ -n "$parent" ]]; then
    trace_id="$parent"
  fi

  sqlite3 "$TRACE_DB" "INSERT OR IGNORE INTO trace_meta (trace_id, name, service) VALUES ('$trace_id','$name','$service');"
  sqlite3 "$TRACE_DB" "INSERT INTO traces (trace_id, span_id, parent_id, name, service, start_ms) VALUES ('$trace_id','$span_id','$parent','$name','$service',$start_ms);"
  sqlite3 "$TRACE_DB" "UPDATE trace_meta SET span_count=span_count+1 WHERE trace_id='$trace_id';"

  echo "${trace_id}:${span_id}"
  echo -e "${CYAN}▶${NC} Span started: ${BOLD}$name${NC}  [${service}]  span=${span_id}" >&2
}

cmd_end() {
  # br trace end <trace_id:span_id> [status] [error]
  local ref="$1" status="${2:-ok}" error="${3:-}"
  [[ -z "$ref" ]] && { echo -e "${RED}✗${NC} Usage: br trace end <trace:span>"; return 1; }

  local trace_id="${ref%%:*}" span_id="${ref##*:}"
  local end_ms start_ms duration_ms

  end_ms=$(python3 -c "import time; print(int(time.time()*1000))")
  start_ms=$(sqlite3 "$TRACE_DB" "SELECT start_ms FROM traces WHERE trace_id='$trace_id' AND span_id='$span_id';")
  duration_ms=$((end_ms - start_ms))

  sqlite3 "$TRACE_DB" "UPDATE traces SET duration_ms=$duration_ms, status='$status', error='$error' WHERE trace_id='$trace_id' AND span_id='$span_id';"

  if [[ "$status" != "ok" ]]; then
    sqlite3 "$TRACE_DB" "UPDATE trace_meta SET has_error=1 WHERE trace_id='$trace_id';"
  fi

  # Update total time in meta
  local total
  total=$(sqlite3 "$TRACE_DB" "SELECT COALESCE(MAX(start_ms+duration_ms)-MIN(start_ms),0) FROM traces WHERE trace_id='$trace_id' AND duration_ms IS NOT NULL;")
  sqlite3 "$TRACE_DB" "UPDATE trace_meta SET total_ms=$total WHERE trace_id='$trace_id';"

  local color="$GREEN"; [[ "$status" != "ok" ]] && color="$RED"
  echo -e "${color}■${NC} Span done: ${duration_ms}ms  status=$status" >&2
}

cmd_show() {
  # br trace show <trace_id>
  local trace_id="$1"
  [[ -z "$trace_id" ]] && { echo -e "${RED}✗${NC} Usage: br trace show <trace_id>"; return 1; }
  echo -e "\n${BOLD}${CYAN}🔍 Trace: $trace_id${NC}\n"
  python3 - "$TRACE_DB" "$trace_id" <<'PY'
import sqlite3, sys
db, tid = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(db)

meta = conn.execute("SELECT name, service, total_ms, span_count, has_error FROM trace_meta WHERE trace_id=?", (tid,)).fetchone()
if meta:
    name, svc, total, spans, has_err = meta
    err_str = " \033[31m[ERROR]\033[0m" if has_err else ""
    print(f"  \033[1m{name}\033[0m  service={svc}  total={total}ms  spans={spans}{err_str}\n")

spans = conn.execute(
    "SELECT span_id, parent_id, name, service, start_ms, duration_ms, status, error FROM traces WHERE trace_id=? ORDER BY start_ms",
    (tid,)
).fetchall()

if not spans:
    print("  No spans found.")
    sys.exit(0)

base_ms = spans[0][4]
for span_id, parent, name, svc, start, dur, status, error in spans:
    indent = "  " if parent else ""
    offset = start - base_ms
    dur_str = f"{dur}ms" if dur else "..."
    st_color = "\033[32m" if status == 'ok' else "\033[31m"
    print(f"  {indent}├─ \033[1m{name:<30}\033[0m  +{offset}ms  {st_color}{dur_str}\033[0m  [{svc}]")
    if error:
        print(f"  {indent}│  \033[31mERROR: {error}\033[0m")

print()
conn.close()
PY
}

cmd_list() {
  local service="${1:-}" limit="${2:-20}"
  echo -e "\n${BOLD}${CYAN}📡 Recent Traces${NC}\n"
  python3 - "$TRACE_DB" "${service:-}" "$limit" <<'PY'
import sqlite3, sys, time
db, service, limit = sys.argv[1], sys.argv[2], int(sys.argv[3])
conn = sqlite3.connect(db)
q = "SELECT trace_id, name, service, total_ms, span_count, has_error, created_at FROM trace_meta"
if service: q += f" WHERE service='{service}'"
q += f" ORDER BY created_at DESC LIMIT {limit}"
rows = conn.execute(q).fetchall()
if not rows:
    print("  No traces recorded yet.")
    print("  Start one: br trace start 'my-request' myservice")
else:
    for tid, name, svc, total, spans, has_err, ts in rows:
        err = " \033[31m[ERR]\033[0m" if has_err else ""
        t = time.strftime('%H:%M:%S', time.localtime(ts))
        total_str = f"{total}ms" if total else "?"
        print(f"  \033[36m{t}\033[0m  \033[1m{name:<28}\033[0m  {total_str:<8}  {spans} spans  [{svc}]{err}")
        print(f"         \033[90m{tid}\033[0m")
print()
conn.close()
PY
}

cmd_bench() {
  # br trace bench <command...> — trace a command's execution time
  [[ -z "$1" ]] && { echo -e "${RED}✗${NC} Usage: br trace bench <command>"; return 1; }
  local cmd="$*"
  local trace_id span_id ref

  ref=$(cmd_start "bench: $cmd" "local" 2>/dev/null)
  trace_id="${ref%%:*}"; span_id="${ref##*:}"
  local combined="${trace_id}:${span_id}"

  local start_ms
  start_ms=$(python3 -c "import time; print(int(time.time()*1000))")

  echo -e "${CYAN}▶ Running:${NC} $cmd"
  eval "$cmd"
  local exit_code=$?
  local job_status="ok"; [[ $exit_code -ne 0 ]] && job_status="error:$exit_code"

  local end_ms duration
  end_ms=$(python3 -c "import time; print(int(time.time()*1000))")
  duration=$((end_ms - start_ms))

  cmd_end "$combined" "$job_status" 2>/dev/null
  echo -e "\n${BLUE}⏱${NC}  ${BOLD}${duration}ms${NC}  exit=$exit_code"
  echo -e "   trace: ${PURPLE}$trace_id${NC}"
}

cmd_stats() {
  echo -e "\n${BOLD}${CYAN}📊 Trace Statistics${NC}\n"
  python3 - "$TRACE_DB" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
# Per-service stats
rows = conn.execute("""
    SELECT service, COUNT(*) as cnt,
           AVG(duration_ms) as avg_ms,
           MIN(duration_ms) as min_ms,
           MAX(duration_ms) as max_ms,
           SUM(CASE WHEN status != 'ok' THEN 1 ELSE 0 END) as errors
    FROM traces WHERE duration_ms IS NOT NULL
    GROUP BY service ORDER BY cnt DESC
""").fetchall()
if not rows:
    print("  No trace data yet.")
else:
    print(f"  {'SERVICE':<20} {'COUNT':>6} {'AVG':>8} {'MIN':>8} {'MAX':>8} {'ERRORS':>7}")
    print(f"  {'-'*65}")
    for svc, cnt, avg, mn, mx, errs in rows:
        err_str = f"\033[31m{errs}\033[0m" if errs else "0"
        print(f"  {svc:<20} {cnt:>6} {avg:>7.0f}ms {mn:>7.0f}ms {mx:>7.0f}ms {err_str:>7}")
print()
conn.close()
PY
}

show_help() {
  echo -e "\n${BOLD}${CYAN}📡 BR Trace — Distributed Request Tracing${NC}\n"
  echo -e "  ${CYAN}br trace start <name> [service]${NC}   — start a span → returns trace:span"
  echo -e "  ${CYAN}br trace end <trace:span> [status]${NC} — end span (status: ok|error)"
  echo -e "  ${CYAN}br trace show <trace_id>${NC}          — visualize trace tree"
  echo -e "  ${CYAN}br trace list [service]${NC}           — list recent traces"
  echo -e "  ${CYAN}br trace bench <command>${NC}          — benchmark a command"
  echo -e "  ${CYAN}br trace stats${NC}                    — latency stats by service\n"
  echo -e "  ${YELLOW}Workflow:${NC}"
  echo -e "    REF=\$(br trace start 'api-call' my-service)"
  echo -e "    curl https://api.example.com"
  echo -e "    br trace end \"\$REF\"\n"
}

init_db
case "${1:-help}" in
  start)        cmd_start "$2" "$3" "$4" ;;
  end|stop|fin) cmd_end "$2" "$3" "$4" ;;
  show|view)    cmd_show "$2" ;;
  list|ls)      cmd_list "$2" "$3" ;;
  bench|time)   shift; cmd_bench "$@" ;;
  stats|stat)   cmd_stats ;;
  help|--help)  show_help ;;
  *) show_help ;;
esac
