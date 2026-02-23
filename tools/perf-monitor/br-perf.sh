#!/bin/zsh
# BR Perf - Performance Monitor
PERF_HOME="/Users/alexa/blackroad/tools/perf-monitor"
PERF_DB="${PERF_HOME}/perf.db"
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"

mkdir -p "$PERF_HOME"
[[ ! -f "$PERF_DB" ]] && sqlite3 "$PERF_DB" "CREATE TABLE timings (cmd TEXT, duration REAL, timestamp INTEGER);"

time_command() {
    local cmd="$*"
    echo -e "  ${AMBER}${BOLD}◆ BR PERF${NC}  ${DIM}timing${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}"
    echo -e "  ${DIM}$ $cmd${NC}\n"
    local start=$(python3 -c "import time; print(time.time())")
    eval $cmd
    local dur=$(python3 -c "import time; print(round(time.time()-$start,3))")
    echo -e "\n  ${GREEN}✓${NC} ${AMBER}${dur}s${NC}"
    sqlite3 "$PERF_DB" "INSERT INTO timings VALUES ('$(echo "$cmd"|sed "s/'/''/g")', $dur, $(date +%s));"
}

show_stats() {
    echo -e "  ${AMBER}${BOLD}◆ BR PERF${NC}  ${DIM}stats${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    sqlite3 "$PERF_DB" "SELECT cmd, ROUND(AVG(duration),3), COUNT(*) FROM timings GROUP BY cmd ORDER BY AVG(duration) DESC LIMIT 10;" | \
        while IFS='|' read cmd avg count; do
            printf "  ${AMBER}%-8s${NC}  ${DIM}%sx${NC}  %s\n" "${avg}s" "$count" "$cmd"
        done
}

show_help() {
    echo -e "  ${AMBER}${BOLD}◆ BR PERF${NC}  performance monitor\n"
    echo -e "  ${AMBER}br perf time <cmd>${NC}   time a command"
    echo -e "  ${AMBER}br perf stats${NC}        show timing stats"
}

case ${1:-stats} in
    time|t) shift; time_command "$@" ;;
    stats|s|"") show_stats ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
