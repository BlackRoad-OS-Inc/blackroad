#!/bin/zsh
# BR load-test — HTTP load testing with concurrency, latency histograms, P99

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

DB="$HOME/.blackroad/load-test.db"

init_db() {
    mkdir -p "$(dirname "$DB")"
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT,
    method TEXT DEFAULT 'GET',
    requests INTEGER,
    concurrency INTEGER,
    total_ms REAL,
    rps REAL,
    p50 REAL, p90 REAL, p95 REAL, p99 REAL,
    min_ms REAL, max_ms REAL, mean_ms REAL,
    success INTEGER, errors INTEGER,
    ts TEXT DEFAULT (datetime('now'))
);
SQL
}

percentile() {
    # percentile <p> from sorted array passed as args
    local p="$1"; shift
    local arr=("$@")
    local n=${#arr[@]}
    [[ $n -eq 0 ]] && echo 0 && return
    local idx=$(( (p * n / 100) ))
    [[ $idx -ge $n ]] && idx=$((n-1))
    echo "${arr[$((idx+1))]}"
}

histogram() {
    local -a times=("$@")
    local n=${#times[@]}
    [[ $n -eq 0 ]] && return
    
    # Find min/max
    local min=${times[1]} max=${times[1]}
    for t in "${times[@]}"; do
        (( $(echo "$t < $min" | bc -l 2>/dev/null || echo 0) )) && min=$t
        (( $(echo "$t > $max" | bc -l 2>/dev/null || echo 0) )) && max=$t
    done

    local range=$(echo "$max - $min" | bc -l 2>/dev/null || echo 1)
    [[ "$range" == "0" || -z "$range" ]] && range=1
    local buckets=10
    local bucket_size=$(echo "$range / $buckets" | bc -l 2>/dev/null || echo 1)

    echo -e "\n  ${BOLD}Latency Histogram:${NC}"
    
    # Count per bucket
    local -a counts=()
    for i in $(seq 1 $buckets); do counts+=0; done

    for t in "${times[@]}"; do
        local b=$(echo "($t - $min) / $bucket_size" | bc 2>/dev/null || echo 0)
        [[ $b -ge $buckets ]] && b=$((buckets-1))
        counts[$((b+1))]=$((counts[$((b+1))]+1))
    done

    local max_count=1
    for c in "${counts[@]}"; do [[ $c -gt $max_count ]] && max_count=$c; done

    for i in $(seq 1 $buckets); do
        local lo=$(echo "$min + ($i-1) * $bucket_size" | bc -l 2>/dev/null || echo 0)
        local hi=$(echo "$min + $i * $bucket_size" | bc -l 2>/dev/null || echo 0)
        local c=${counts[$i]}
        local bw=$((c * 30 / max_count))
        local bar=$(printf '█%.0s' $(seq 1 $((bw > 0 ? bw : 0))))
        local lo_fmt=$(printf "%.0f" "$lo" 2>/dev/null || echo "$lo")
        local hi_fmt=$(printf "%.0f" "$hi" 2>/dev/null || echo "$hi")
        printf "  ${CYAN}%5s-%-5s ms${NC}  ${GREEN}%-31s${NC} ${BOLD}%d${NC}\n" \
            "$lo_fmt" "$hi_fmt" "$bar" "$c"
    done
}

cmd_run() {
    local url="$1"; shift
    [[ -z "$url" ]] && echo -e "${RED}✗ Usage: br load-test run <url> [opts]${NC}" && return 1

    local n=100 c=10 method="GET" data="" headers=() timeout=30
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--requests)    n="$2"; shift 2 ;;
            -c|--concurrency) c="$2"; shift 2 ;;
            -m|--method)      method="$2"; shift 2 ;;
            -d|--data)        data="$2"; shift 2 ;;
            -H|--header)      headers+=("-H" "$2"); shift 2 ;;
            -t|--timeout)     timeout="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    echo -e "${BOLD}${BLUE}⚡ Load Test${NC}: ${CYAN}$url${NC}"
    echo -e "  Requests: ${BOLD}$n${NC}  Concurrency: ${BOLD}$c${NC}  Method: ${BOLD}$method${NC}\n"

    # Use Python for actual concurrent requests
    local py_script=$(cat <<PYEOF
import urllib.request, urllib.error, time, sys, json
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

url = sys.argv[1]
n = int(sys.argv[2])
c = int(sys.argv[3])
method = sys.argv[4]
timeout = int(sys.argv[5])

results = []
errors = 0
lock = threading.Lock()
counter = [0]

def do_request(i):
    global errors
    try:
        req = urllib.request.Request(url, method=method)
        req.add_header('User-Agent', 'br-load-test/1.0')
        start = time.time()
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            resp.read()
            ms = (time.time() - start) * 1000
            status = resp.status
        with lock:
            results.append(ms)
            counter[0] += 1
            done = counter[0]
            if done % max(1, n//10) == 0:
                pct = done * 100 // n
                print(f"  ▶ {pct}% ({done}/{n})...", flush=True)
        return ms, status, None
    except Exception as e:
        with lock:
            errors += 1
        return None, 0, str(e)

start_total = time.time()
with ThreadPoolExecutor(max_workers=c) as pool:
    futures = [pool.submit(do_request, i) for i in range(n)]
    for f in as_completed(futures):
        pass
total_ms = (time.time() - start_total) * 1000

times = sorted(results)
m = len(times)
if m == 0:
    print(json.dumps({"error": "all requests failed", "errors": errors}))
    sys.exit(1)

def pct(p):
    idx = int(p * m / 100)
    return times[min(idx, m-1)]

mean = sum(times) / m
rps = m / (total_ms / 1000) if total_ms > 0 else 0

out = {
    "times": times,
    "total_ms": total_ms,
    "success": m,
    "errors": errors,
    "rps": round(rps, 2),
    "mean": round(mean, 2),
    "min": round(times[0], 2),
    "max": round(times[-1], 2),
    "p50": round(pct(50), 2),
    "p90": round(pct(90), 2),
    "p95": round(pct(95), 2),
    "p99": round(pct(99), 2),
}
print("RESULTS:" + json.dumps(out))
PYEOF
)

    local tmppy=$(mktemp /tmp/br-load-test-XXXXX.py)
    echo "$py_script" > "$tmppy"

    local raw
    raw=$(python3 "$tmppy" "$url" "$n" "$c" "$method" "$timeout" 2>&1)
    rm -f "$tmppy"

    local json_line=$(echo "$raw" | grep '^RESULTS:' | sed 's/^RESULTS://')
    local progress=$(echo "$raw" | grep -v '^RESULTS:')
    echo "$progress"

    if [[ -z "$json_line" ]]; then
        echo -e "\n${RED}✗ Load test failed${NC}"
        echo "$raw" | head -5
        return 1
    fi

    # Parse results
    local total_ms=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['total_ms'])")
    local rps=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['rps'])")
    local success=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['success'])")
    local errors=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['errors'])")
    local mean=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['mean'])")
    local min_t=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['min'])")
    local max_t=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['max'])")
    local p50=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['p50'])")
    local p90=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['p90'])")
    local p95=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['p95'])")
    local p99=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['p99'])")
    local times_arr=$(echo "$json_line" | python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join(str(t) for t in d['times']))")

    echo -e "\n  ${BOLD}Results:${NC}"
    echo -e "  ┌─────────────────────────────────────────"
    printf "  │  %-18s ${GREEN}%s${NC} req/s\n" "Throughput:" "$rps"
    printf "  │  %-18s %s ms\n" "Total time:" "$(printf '%.0f' "$total_ms")"
    printf "  │  %-18s ${GREEN}%d${NC} / ${RED}%d errors${NC}\n" "Success/Errors:" "$success" "$errors"
    echo -e "  ├─────────────────────────────────────────"
    printf "  │  %-18s %s ms\n" "Mean:" "$mean"
    printf "  │  %-18s %s ms\n" "Min:" "$min_t"
    printf "  │  %-18s %s ms\n" "Max:" "$max_t"
    echo -e "  ├─────────────────────────────────────────"
    printf "  │  %-18s %s ms\n" "P50 (median):" "$p50"
    printf "  │  %-18s %s ms\n" "P90:" "$p90"
    printf "  │  %-18s %s ms\n" "P95:" "$p95"
    printf "  │  %-18s ${BOLD}%s ms${NC}\n" "P99:" "$p99"
    echo -e "  └─────────────────────────────────────────"

    # Save to DB
    local total_s=$(printf '%.3f' "$(echo "$total_ms / 1000" | bc -l 2>/dev/null || echo 0)")
    sqlite3 "$DB" "INSERT INTO runs (url, method, requests, concurrency, total_ms, rps, p50, p90, p95, p99, min_ms, max_ms, mean_ms, success, errors)
        VALUES ('$url', '$method', $n, $c, $total_ms, $rps, $p50, $p90, $p95, $p99, $min_t, $max_t, $mean, $success, $errors);" 2>/dev/null

    echo ""
}

cmd_compare() {
    local url_a="$1" url_b="$2"
    [[ -z "$url_a" || -z "$url_b" ]] && echo -e "${RED}✗ Usage: br load-test compare <url-a> <url-b>${NC}" && return 1
    echo -e "${BOLD}${BLUE}⚡ A/B Load Test${NC}\n"
    echo -e "  ${CYAN}A:${NC} $url_a"
    cmd_run "$url_a" -n 50 -c 5
    echo -e "\n  ${CYAN}B:${NC} $url_b"
    cmd_run "$url_b" -n 50 -c 5
}

cmd_history() {
    echo -e "${BOLD}${BLUE}📜 Load Test History${NC}\n"
    printf "  %-35s %-6s %-6s %-8s %-8s %-6s %s\n" "URL" "Req" "Conc" "RPS" "P99" "Err" "Date"
    echo "  ─────────────────────────────────────────────────────────────────────"
    sqlite3 "$DB" "SELECT url, requests, concurrency, rps, p99, errors, ts FROM runs ORDER BY ts DESC LIMIT 20;" 2>/dev/null \
        | while IFS='|' read -r url req conc rps p99 err ts; do
            local color="$GREEN"; [[ "$err" -gt 0 ]] && color="$YELLOW"
            printf "  ${color}%-35s${NC} %-6s %-6s ${CYAN}%-8s${NC} %-8s ${color}%-6s${NC} %s\n" \
                "${url:0:34}" "$req" "$conc" "$rps" "${p99}ms" "$err" "${ts:0:16}"
        done
}

show_help() {
    echo -e "${BOLD}${BLUE}BR load-test${NC} — HTTP load testing\n"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}br load-test run <url> [opts]${NC}            — Run load test"
    echo -e "  ${CYAN}br load-test compare <url-a> <url-b>${NC}     — A/B comparison"
    echo -e "  ${CYAN}br load-test history${NC}                     — Past results\n"
    echo -e "${BOLD}Options:${NC}"
    echo -e "  -n, --requests <n>     Number of requests (default: 100)"
    echo -e "  -c, --concurrency <n>  Concurrent workers (default: 10)"
    echo -e "  -m, --method <m>       HTTP method (default: GET)"
    echo -e "  -t, --timeout <s>      Timeout in seconds (default: 30)\n"
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  br load-test run https://api.example.com/health"
    echo -e "  br load-test run https://api.example.com/users -n 500 -c 50"
    echo -e "  br load-test compare https://v1.api.com https://v2.api.com"
}

init_db
case "${1:-help}" in
    run|test|bench)        shift; cmd_run "$@" ;;
    compare|ab|a-b)        cmd_compare "$2" "$3" ;;
    history|results|hist)  cmd_history ;;
    help|--help|-h)        show_help ;;
    https://*|http://*)    cmd_run "$@" ;;
    *)                     show_help ;;
esac
