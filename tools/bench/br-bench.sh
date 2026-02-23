#!/bin/zsh
# BR Bench — Command Benchmarking Suite
# Compare performance of multiple commands, statistical analysis

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

BENCH_DB="$HOME/.blackroad/bench.db"

init_db() {
  mkdir -p "$(dirname "$BENCH_DB")"
  sqlite3 "$BENCH_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS benchmarks (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT,
  command     TEXT NOT NULL,
  runs        INTEGER DEFAULT 1,
  mean_ms     REAL,
  min_ms      REAL,
  max_ms      REAL,
  stddev_ms   REAL,
  exit_codes  TEXT DEFAULT '[]',
  tags        TEXT DEFAULT '',
  ts          INTEGER DEFAULT (strftime('%s','now'))
);
SQL
}

cmd_run() {
  # br bench run <command> [--runs N] [--name label] [--warmup N]
  local cmd="" runs=5 name="" warmup=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --runs|-r|-n)   runs="$2";   shift 2 ;;
      --name|-l)      name="$2";   shift 2 ;;
      --warmup|-w)    warmup="$2"; shift 2 ;;
      *) cmd="$cmd $1"; shift ;;
    esac
  done
  cmd="${cmd## }"

  [[ -z "$cmd" ]] && {
    echo -e "${CYAN}Usage: br bench run <command> [--runs 5] [--name label] [--warmup 1]${NC}"
    echo -e "Example: br bench run 'ls -la' --runs 10 --name 'ls speed'"
    return 1
  }

  [[ -z "$name" ]] && name="$cmd"
  echo -e "\n${BOLD}${CYAN}⏱ Benchmarking: ${name}${NC}"
  echo -e "  Runs: $runs  Warmup: $warmup\n"

  # Warmup
  if [[ $warmup -gt 0 ]]; then
    echo -e "  ${YELLOW}Warming up...${NC}"
    for i in $(seq 1 $warmup); do
      eval "$cmd" &>/dev/null
    done
  fi

  # Collect timings
  python3 - "$cmd" "$runs" "$name" "$BENCH_DB" <<'PY'
import subprocess, sys, time, json, math, sqlite3

cmd, runs, name, db_path = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]

timings = []
exit_codes = []

print(f"  Running {runs} iterations...")
for i in range(runs):
    start = time.perf_counter()
    result = subprocess.run(cmd, shell=True, capture_output=True)
    elapsed = (time.perf_counter() - start) * 1000
    timings.append(elapsed)
    exit_codes.append(result.returncode)
    bar = '█' * (i + 1) + '░' * (runs - i - 1)
    print(f"\r  [{bar}] {i+1}/{runs}  {elapsed:.1f}ms", end='', flush=True)

print()

mean = sum(timings) / len(timings)
mn = min(timings)
mx = max(timings)
variance = sum((x - mean) ** 2 for x in timings) / len(timings)
stddev = math.sqrt(variance)

# Determine color based on speed
if mean < 50: speed_color = "\033[32m"       # green — fast
elif mean < 500: speed_color = "\033[33m"    # yellow — moderate
else: speed_color = "\033[31m"               # red — slow

print(f"\n  {speed_color}mean:   {mean:.1f}ms\033[0m")
print(f"  min:    {mn:.1f}ms")
print(f"  max:    {mx:.1f}ms")
print(f"  stddev: {stddev:.1f}ms")

# Check success rate
success = sum(1 for c in exit_codes if c == 0)
if success < runs:
    print(f"  \033[31mFailed: {runs-success}/{runs} runs\033[0m")
else:
    print(f"  \033[32mSuccess: {success}/{runs}\033[0m")

# Save to DB
conn = sqlite3.connect(db_path)
conn.execute("INSERT INTO benchmarks (name, command, runs, mean_ms, min_ms, max_ms, stddev_ms, exit_codes) VALUES (?,?,?,?,?,?,?,?)",
             (name, cmd, runs, mean, mn, mx, stddev, json.dumps(exit_codes)))
conn.commit()
conn.close()
print()
PY
}

cmd_compare() {
  # br bench compare "cmd1" "cmd2" [--runs N]
  local runs=5 cmds=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --runs|-r|-n) runs="$2"; shift 2 ;;
      *) cmds+=("$1"); shift ;;
    esac
  done

  [[ ${#cmds[@]} -lt 2 ]] && {
    echo -e "${CYAN}Usage: br bench compare \"cmd1\" \"cmd2\" [--runs N]${NC}"
    return 1
  }

  echo -e "\n${BOLD}${CYAN}⚡ Benchmark Comparison${NC}  (${runs} runs each)\n"

  python3 - "$runs" "${cmds[@]}" <<'PY'
import subprocess, sys, time, math

runs = int(sys.argv[1])
cmds = sys.argv[2:]
results = []

for cmd in cmds:
    timings = []
    print(f"  \033[36m▶\033[0m {cmd[:50]}")
    for i in range(runs):
        start = time.perf_counter()
        subprocess.run(cmd, shell=True, capture_output=True)
        timings.append((time.perf_counter() - start) * 1000)
    mean = sum(timings) / len(timings)
    mn, mx = min(timings), max(timings)
    variance = sum((x - mean)**2 for x in timings) / len(timings)
    stddev = math.sqrt(variance)
    results.append((cmd, mean, mn, mx, stddev))
    print(f"  mean={mean:.1f}ms  min={mn:.1f}ms  max={mx:.1f}ms  σ={stddev:.1f}ms\n")

# Winner
results.sort(key=lambda x: x[1])
winner = results[0]
print(f"  {'─'*60}")
print(f"  \033[32m🏆 Fastest:\033[0m {winner[0][:50]}")
if len(results) > 1:
    slowest = results[-1]
    speedup = slowest[1] / winner[1] if winner[1] > 0 else 1
    print(f"  \033[32m   {speedup:.1f}x faster\033[0m than slowest ({slowest[1]:.1f}ms vs {winner[1]:.1f}ms)")
print()
PY
}

cmd_list() {
  echo -e "\n${BOLD}${CYAN}📊 Benchmark History${NC}\n"
  python3 - "$BENCH_DB" <<'PY'
import sqlite3, sys, time
conn = sqlite3.connect(sys.argv[1])
rows = conn.execute("SELECT name, command, runs, mean_ms, min_ms, max_ms, ts FROM benchmarks ORDER BY ts DESC LIMIT 20").fetchall()
if not rows:
    print("  No benchmarks recorded yet.")
    print("  Run: br bench run 'your command'")
else:
    for name, cmd, runs, mean, mn, mx, ts in rows:
        t = time.strftime('%m/%d %H:%M', time.localtime(ts))
        if mean < 50: mc = "\033[32m"
        elif mean < 500: mc = "\033[33m"
        else: mc = "\033[31m"
        label = name[:30] if name != cmd else cmd[:30]
        print(f"  \033[36m{t}\033[0m  \033[1m{label:<32}\033[0m  {mc}{mean:.1f}ms\033[0m  min={mn:.1f}  max={mx:.1f}  ×{runs}")
print()
conn.close()
PY
}

cmd_profile_file() {
  # br bench profile <script> — line-by-line timing
  local script="$1"
  [[ -z "$script" || ! -f "$script" ]] && {
    echo -e "${RED}✗${NC} Usage: br bench profile <script.sh>"
    return 1
  }
  echo -e "\n${BOLD}${CYAN}🔬 Profiling: $script${NC}\n"

  # Use time -p on each line group (approximate)
  local start
  start=$(python3 -c "import time; print(time.perf_counter())")
  bash -x "$script" 2>&1 | while IFS= read -r line; do
    local ts
    ts=$(python3 -c "import time; print(f'{time.perf_counter():.4f}')")
    echo "  $ts  $line"
  done
}

show_help() {
  echo -e "\n${BOLD}${CYAN}⏱ BR Bench — Benchmarking Suite${NC}\n"
  echo -e "  ${CYAN}br bench run <cmd> [--runs N] [--name label]${NC}  — benchmark a command"
  echo -e "  ${CYAN}br bench compare \"cmd1\" \"cmd2\" [--runs N]${NC}   — compare commands"
  echo -e "  ${CYAN}br bench list${NC}                                  — benchmark history"
  echo -e "  ${CYAN}br bench profile <script.sh>${NC}                   — profile a script\n"
  echo -e "  ${YELLOW}Examples:${NC}"
  echo -e "    br bench run 'curl -s https://api.example.com' --runs 10"
  echo -e "    br bench compare 'grep -r foo .' 'rg foo .' --runs 5\n"
}

init_db
case "${1:-help}" in
  run|time|measure)     shift; cmd_run "$@" ;;
  compare|vs|cmp)       shift; cmd_compare "$@" ;;
  list|ls|history)      cmd_list ;;
  profile)              cmd_profile_file "$2" ;;
  help|--help)          show_help ;;
  # Shortcut: br bench <cmd>
  *) cmd_run "$@" ;;
esac
