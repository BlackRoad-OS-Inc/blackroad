#!/bin/zsh
# BR Perf — performance monitor + live sparklines  v2

PERF_HOME="${HOME}/.blackroad/perf"
PERF_DB="${PERF_HOME}/perf.db"
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"

mkdir -p "$PERF_HOME"
sqlite3 "$PERF_DB" "CREATE TABLE IF NOT EXISTS timings (cmd TEXT, duration REAL, ts INTEGER);" 2>/dev/null

# ── helpers ────────────────────────────────────────────────
_bar() {
  # _bar <value> <max> <width> <color>
  python3 -c "
v,m,w,c = $1,$2,$3,'$4'
NC = '\033[0m'
fill = int(round(v/m*w)) if m>0 else 0
fill = min(fill,w)
print(c + '█'*fill + '\033[2m' + '░'*(w-fill) + NC, end='')
"
}

_spark() {
  # _spark "val1 val2 ..." <max>
  python3 -c "
vals = list(map(float,'$1'.split()))
m = $2 if $2 > 0 else (max(vals) or 1)
chars = ' ▁▂▃▄▅▆▇█'
out = ''.join(chars[min(int(v/m*8),8)] for v in vals)
print(out, end='')
"
}

# ── cmd_time ───────────────────────────────────────────────
cmd_time() {
  local cmd="$*"
  [[ -z "$cmd" ]] && { echo -e "  ${RED}✗${NC} usage: br perf time <command>"; return 1; }
  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR PERF${NC}  ${DIM}timing: $cmd${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo ""
  local start; start=$(python3 -c "import time; print(time.time())")
  eval "$cmd"
  local dur; dur=$(python3 -c "import time; print(round(time.time()-$start,3))")
  echo ""
  echo -e "  ${GREEN}✓${NC}  ${AMBER}${BOLD}${dur}s${NC}"
  sqlite3 "$PERF_DB" "INSERT INTO timings VALUES ('$(echo "$cmd"|sed "s/'/''/g")', $dur, $(date +%s));"
  echo ""
}

# ── cmd_stats ──────────────────────────────────────────────
cmd_stats() {
  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR PERF${NC}  ${DIM}command timing history${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo ""
  local rows; rows=$(sqlite3 "$PERF_DB" "SELECT cmd, ROUND(AVG(duration),3), ROUND(MIN(duration),3), ROUND(MAX(duration),3), COUNT(*) FROM timings GROUP BY cmd ORDER BY AVG(duration) DESC LIMIT 15;")
  if [[ -z "$rows" ]]; then
    echo -e "  ${DIM}No timings yet.  br perf time <cmd>${NC}\n"; return
  fi
  printf "  ${BOLD}%-8s  %-8s  %-8s  %-5s  %s${NC}\n" "avg" "min" "max" "runs" "command"
  echo -e "  ${DIM}$(printf '%.0s─' {1..58})${NC}"
  echo "$rows" | while IFS='|' read -r cmd avg mn mx cnt; do
    printf "  ${AMBER}%-8s${NC}  ${DIM}%-8s  %-8s  %-5s${NC}  %s\n" "${avg}s" "${mn}s" "${mx}s" "${cnt}x" "$cmd"
  done
  echo ""
}

# ── cmd_live ──────────────────────────────────────────────
cmd_live() {
  local interval=${1:-2}
  local HIST_LEN=30
  local cpu_hist="" mem_hist="" net_hist=""

  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR PERF${NC}  ${DIM}live · every ${interval}s · Ctrl+C to exit${NC}"
  echo ""

  # Hide cursor
  tput civis 2>/dev/null
  trap 'tput cnorm 2>/dev/null; echo ""; exit 0' INT TERM

  local lines_drawn=0

  while true; do
    # ── gather metrics ──
    local cpu mem disk net_in net_out
    cpu=$(python3 -c "
import subprocess, re
try:
    out = subprocess.check_output(['top','-l','1','-n','0','-stats','cpu'], stderr=subprocess.DEVNULL).decode()
    m = re.search(r'(\d+\.\d+)%\s+user.*?(\d+\.\d+)%\s+sys', out)
    if m: print(round(float(m.group(1))+float(m.group(2)),1))
    else:
        m2 = re.search(r'CPU usage:\s+(\d+\.\d+)%\s+user,\s+(\d+\.\d+)%\s+sys', out)
        if m2: print(round(float(m2.group(1))+float(m2.group(2)),1))
        else: print(0)
except: print(0)
" 2>/dev/null)

    mem=$(python3 -c "
import subprocess, re
try:
    out = subprocess.check_output(['vm_stat'], stderr=subprocess.DEVNULL).decode()
    page = 4096
    active  = int(re.search(r'Pages active:\s+(\d+)', out).group(1)) * page
    wired   = int(re.search(r'Pages wired down:\s+(\d+)', out).group(1)) * page
    compressed = 0
    m = re.search(r'Pages occupied by compressor:\s+(\d+)', out)
    if m: compressed = int(m.group(1)) * page
    used = active + wired + compressed
    import os
    total = int(subprocess.check_output(['sysctl','-n','hw.memsize']).decode().strip())
    print(round(used/total*100, 1), round(used/1024**3,2), round(total/1024**3,1))
except Exception as e: print('0 0 16')
" 2>/dev/null)
    local mem_pct; mem_pct=$(echo "$mem" | awk '{print $1}')
    local mem_used; mem_used=$(echo "$mem" | awk '{print $2}')
    local mem_total; mem_total=$(echo "$mem" | awk '{print $3}')

    local disk_pct; disk_pct=$(df / | tail -1 | awk '{gsub(/%/,""); print $5}')

    # Top 5 processes by CPU
    local procs; procs=$(ps -eo pid,pcpu,pmem,comm -r 2>/dev/null | head -6 | tail -5)

    # Update history (space-separated strings)
    cpu_hist="$cpu_hist $cpu"
    mem_hist="$mem_hist $mem_pct"
    # Keep last HIST_LEN values
    cpu_hist=$(echo "$cpu_hist" | awk '{for(i=NF-'"$HIST_LEN"'+1;i<=NF;i++) printf $i" "; print ""}')
    mem_hist=$(echo "$mem_hist" | awk '{for(i=NF-'"$HIST_LEN"'+1;i<=NF;i++) printf $i" "; print ""}')

    # ── draw ──
    [[ $lines_drawn -gt 0 ]] && tput cuu $lines_drawn 2>/dev/null
    lines_drawn=0

    _line() { echo -e "$1"; lines_drawn=$((lines_drawn+1)); }

    _line ""
    _line "  ${AMBER}${BOLD}◆ BR PERF  LIVE${NC}  ${DIM}$(date '+%H:%M:%S')${NC}"
    _line "  ${DIM}────────────────────────────────────────────────────────${NC}"
    _line ""

    # CPU
    local cpu_color="$GREEN"
    (( $(echo "$cpu > 80" | bc -l 2>/dev/null || echo 0) )) && cpu_color="$RED"
    (( $(echo "$cpu > 60" | bc -l 2>/dev/null || echo 0) )) && [[ "$cpu_color" != "$RED" ]] && cpu_color="$PINK"
    printf "  ${BOLD}CPU${NC}   %5.1f%%  " "$cpu" 2>/dev/null || printf "  ${BOLD}CPU${NC}   %5s%%  " "$cpu"
    _bar "${cpu:-0}" "100" "28" "$cpu_color"
    printf "  ${DIM}spark: ${NC}"
    _spark "${cpu_hist:-0}" "100"
    echo ""; lines_drawn=$((lines_drawn+1))

    # MEM
    local mem_color="$GREEN"
    (( $(echo "${mem_pct:-0} > 80" | bc -l 2>/dev/null || echo 0) )) && mem_color="$RED"
    (( $(echo "${mem_pct:-0} > 60" | bc -l 2>/dev/null || echo 0) )) && [[ "$mem_color" != "$RED" ]] && mem_color="$PINK"
    printf "  ${BOLD}MEM${NC}   %5.1f%%  " "${mem_pct:-0}" 2>/dev/null || printf "  ${BOLD}MEM${NC}   %5s%%  " "${mem_pct:-0}"
    _bar "${mem_pct:-0}" "100" "28" "$mem_color"
    printf "  ${DIM}%sGB / %sGB${NC}" "$mem_used" "$mem_total"
    echo ""; lines_drawn=$((lines_drawn+1))

    # DISK
    local disk_color="$GREEN"
    (( ${disk_pct:-0} > 90 )) && disk_color="$RED"
    (( ${disk_pct:-0} > 75 )) && [[ "$disk_color" != "$RED" ]] && disk_color="$PINK"
    printf "  ${BOLD}DISK${NC}  %5s%%  " "${disk_pct:-0}"
    _bar "${disk_pct:-0}" "100" "28" "$disk_color"
    echo ""; lines_drawn=$((lines_drawn+1))

    _line ""
    _line "  ${DIM}$(printf '%-6s  %-6s  %-6s  %s' 'PID' '%CPU' '%MEM' 'PROCESS')${NC}"
    _line "  ${DIM}$(printf '%.0s─' {1..42})${NC}"

    echo "$procs" | while read -r pid pcpu pmem comm; do
      comm=$(basename "$comm" 2>/dev/null || echo "$comm")
      comm="${comm:0:28}"
      local pc_color="$NC"
      (( $(echo "${pcpu:-0} > 50" | bc -l 2>/dev/null || echo 0) )) && pc_color="$RED"
      (( $(echo "${pcpu:-0} > 20" | bc -l 2>/dev/null || echo 0) )) && [[ "$pc_color" != "$RED" ]] && pc_color="$AMBER"
      printf "  %-6s  ${pc_color}%-6s${NC}  ${DIM}%-6s${NC}  %s\n" "$pid" "$pcpu" "$pmem" "$comm"
      lines_drawn=$((lines_drawn+1))
    done

    _line ""
    _line "  ${DIM}refreshing every ${interval}s${NC}"
    _line ""

    sleep "$interval"
  done
}

# ── show_help ──────────────────────────────────────────────
show_help() {
  echo ""
  echo -e "  ${AMBER}${BOLD}◆ BR PERF${NC}  ${DIM}Time it. Watch it. Own it.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo ""
  echo -e "  ${AMBER}live${NC}   [interval]     full-screen CPU/MEM/DISK sparklines"
  echo -e "  ${AMBER}time${NC}   <command>      time any command, save to history"
  echo -e "  ${AMBER}stats${NC}                 command timing history"
  echo ""
  echo -e "  ${DIM}br perf live 1    # 1s refresh (default: 2s)${NC}"
  echo ""
}

case ${1:-live} in
  live|l|watch) cmd_live "${2:-2}" ;;
  time|t) shift; cmd_time "$@" ;;
  stats|s|history) cmd_stats ;;
  help|--help|-h) show_help ;;
  *) show_help ;;
esac
