#!/bin/bash
#===============================================================================
# lib/system.sh — Real macOS/Linux system metrics (replaces all $RANDOM usage)
#===============================================================================

# Cache metrics for the current loop iteration to avoid redundant calls
_BR_CPU_CACHE=""
_BR_MEM_CACHE=""
_BR_DISK_CACHE=""
_BR_LOAD_CACHE=""
_BR_CACHE_TS=0

_br_refresh_cache() {
    local now
    now=$(date +%s)
    if (( now - _BR_CACHE_TS >= 1 )); then
        _BR_CPU_CACHE=""
        _BR_MEM_CACHE=""
        _BR_DISK_CACHE=""
        _BR_LOAD_CACHE=""
        _BR_CACHE_TS=$now
    fi
}

get_cpu_percent() {
    _br_refresh_cache
    if [[ -n "$_BR_CPU_CACHE" ]]; then
        echo "$_BR_CPU_CACHE"
        return
    fi
    local pct
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: parse top for CPU usage (user + sys)
        pct=$(top -l 1 -n 0 -s 0 2>/dev/null | awk '/CPU usage:/ {gsub(/%/,""); print int($3+$5)}')
    else
        # Linux: parse /proc/stat
        pct=$(awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print int(100*(total-idle)/total)}' /proc/stat 2>/dev/null)
    fi
    pct=${pct:-0}
    _BR_CPU_CACHE=$pct
    echo "$pct"
}

get_mem_percent() {
    _br_refresh_cache
    if [[ -n "$_BR_MEM_CACHE" ]]; then
        echo "$_BR_MEM_CACHE"
        return
    fi
    local pct
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS: compute from vm_stat pages
        local page_size
        page_size=$(vm_stat 2>/dev/null | awk '/page size of/ {print $8}')
        page_size=${page_size:-16384}
        local active wired compressed
        active=$(vm_stat 2>/dev/null | awk '/Pages active:/ {gsub(/\./,"",$3); print $3}')
        wired=$(vm_stat 2>/dev/null | awk '/Pages wired down:/ {gsub(/\./,"",$4); print $4}')
        compressed=$(vm_stat 2>/dev/null | awk '/Pages occupied by compressor:/ {gsub(/\./,"",$5); print $5}')
        active=${active:-0}; wired=${wired:-0}; compressed=${compressed:-0}
        local used_bytes=$(( (active + wired + compressed) * page_size ))
        local total_bytes
        total_bytes=$(sysctl -n hw.memsize 2>/dev/null)
        total_bytes=${total_bytes:-1}
        pct=$(( used_bytes * 100 / total_bytes ))
    else
        # Linux: parse /proc/meminfo
        pct=$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {print int(100*(t-a)/t)}' /proc/meminfo 2>/dev/null)
    fi
    pct=${pct:-0}
    _BR_MEM_CACHE=$pct
    echo "$pct"
}

get_disk_percent() {
    _br_refresh_cache
    if [[ -n "$_BR_DISK_CACHE" ]]; then
        echo "$_BR_DISK_CACHE"
        return
    fi
    local pct
    pct=$(df / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    pct=${pct:-0}
    # Handle df on macOS where capacity is in column 5
    if [[ "$pct" == "0" ]] && [[ "$(uname)" == "Darwin" ]]; then
        pct=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print int($5)}')
    fi
    _BR_DISK_CACHE=${pct:-0}
    echo "$_BR_DISK_CACHE"
}

get_load_avg() {
    _br_refresh_cache
    if [[ -n "$_BR_LOAD_CACHE" ]]; then
        echo "$_BR_LOAD_CACHE"
        return
    fi
    local load
    if [[ "$(uname)" == "Darwin" ]]; then
        load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
    else
        load=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    fi
    _BR_LOAD_CACHE=${load:-0.00}
    echo "$_BR_LOAD_CACHE"
}

get_uptime() {
    if [[ "$(uname)" == "Darwin" ]]; then
        local boot_time
        boot_time=$(sysctl -n kern.boottime 2>/dev/null | awk '{print $4}' | tr -d ',')
        if [[ -n "$boot_time" ]]; then
            local now
            now=$(date +%s)
            local secs=$(( now - boot_time ))
            local days=$(( secs / 86400 ))
            local hours=$(( (secs % 86400) / 3600 ))
            local mins=$(( (secs % 3600) / 60 ))
            if (( days > 0 )); then
                echo "${days}d ${hours}h ${mins}m"
            elif (( hours > 0 )); then
                echo "${hours}h ${mins}m"
            else
                echo "${mins}m"
            fi
            return
        fi
    fi
    uptime 2>/dev/null | sed 's/.*up //' | sed 's/,.*//' | xargs
}

get_process_count() {
    ps -e 2>/dev/null | wc -l | tr -d ' '
}

check_ollama() {
    # Returns 0 if Ollama is running, 1 otherwise
    curl -s --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1
}

check_port() {
    # Check if a port is listening
    local port=$1
    lsof -i ":${port}" -sTCP:LISTEN >/dev/null 2>&1
}

render_bar() {
    local pct=$1
    local width=${2:-20}
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    # Clamp
    (( filled > width )) && filled=$width
    (( filled < 0 )) && filled=0
    (( empty < 0 )) && empty=0

    # Color based on percentage
    local color
    if (( pct >= 90 )); then
        color='\033[1;31m'  # red
    elif (( pct >= 70 )); then
        color='\033[1;33m'  # yellow
    else
        color='\033[1;36m'  # cyan
    fi

    printf "${color}["
    for ((i=0; i<filled; i++)); do printf '█'; done
    for ((i=0; i<empty; i++)); do printf '░'; done
    printf ']'
    printf '\033[0m'
}

# Invalidate cache (call at top of each loop iteration)
br_refresh_metrics() {
    _BR_CPU_CACHE=""
    _BR_MEM_CACHE=""
    _BR_DISK_CACHE=""
    _BR_LOAD_CACHE=""
    _BR_CACHE_TS=0
}
