#!/bin/zsh
# BR Perf - Performance Monitor
PERF_HOME="/Users/alexa/blackroad/tools/perf-monitor"
PERF_DB="${PERF_HOME}/perf.db"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$PERF_HOME"
[[ ! -f "$PERF_DB" ]] && sqlite3 "$PERF_DB" "CREATE TABLE timings (cmd TEXT, duration REAL, timestamp INTEGER);"

time_command() {
    local cmd="$*"
    echo -e "${CYAN}⏱️  Timing: ${cmd}${NC}\n"
    local start=$(date +%s.%N)
    eval $cmd
    local end=$(date +%s.%N)
    local duration=$(echo "$end - $start" | bc)
    echo -e "\n${GREEN}✓ Completed in ${duration}s${NC}"
    sqlite3 "$PERF_DB" "INSERT INTO timings VALUES ('$cmd', $duration, $(date +%s));"
}

show_stats() {
    echo -e "${CYAN}📊 Performance Stats:${NC}\n"
    sqlite3 "$PERF_DB" "SELECT cmd, AVG(duration), COUNT(*) FROM timings GROUP BY cmd ORDER BY AVG(duration) DESC LIMIT 10;" | \
        while IFS='|' read cmd avg count; do
            echo -e "${YELLOW}${avg}s${NC} - $cmd (${count}x)"
        done
}

case ${1:-stats} in
    time|t) shift; time_command "$@" ;;
    stats|s) show_stats ;;
    *) show_stats ;;
esac
