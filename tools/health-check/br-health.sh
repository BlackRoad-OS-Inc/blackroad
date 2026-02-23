#!/usr/bin/env zsh
# BR Health -- BlackRoad OS All-Systems Diagnostic
# Real checks, latency timings, scored summary

AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
BLUE='\033[38;5;69m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0; FAIL=0; WARN=0

# ms timestamp (macOS compat -- no date +%N)
_ms() { python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo 0; }

_chk() {
    local label="$1" chk_st="$2" msg="$3" ms="${4:-}"
    local icon
    case "$chk_st" in
        ok)   icon="${GREEN}v${NC}"; (( PASS++ )) ;;
        warn) icon="${AMBER}~${NC}"; (( WARN++ )) ;;
        fail) icon="${RED}x${NC}";  (( FAIL++ )) ;;
    esac
    local timing=""; [[ -n "$ms" && "$ms" != "0" ]] && timing="${DIM}  ${ms}ms${NC}"
    printf "  %b  %-36s %b%b\n" "$icon" "$label" "$msg" "$timing"
}

_ping_http() {
    local url="$1" timeout="${2:-3}" t0 t1 ms http_code
    t0=$(_ms)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null)
    t1=$(_ms); ms=$(( t1 - t0 ))
    if [[ "$http_code" =~ ^[23] ]]; then echo "ok:${ms}"
    elif [[ -n "$http_code" && "$http_code" != "000" ]]; then echo "warn:${ms}"
    else echo "fail:0"; fi
}

_ping_port() {
    local host="$1" port="$2" timeout="${3:-2}" t0 t1 ms
    t0=$(_ms)
    if nc -z -w "$timeout" "$host" "$port" 2>/dev/null; then
        t1=$(_ms); ms=$(( t1 - t0 ))
        echo "ok:${ms}"
    else echo "fail:0"; fi
}

_section() {
    echo ""
    echo -e "  ${AMBER}${BOLD}$1${NC}  ${DIM}$2${NC}"
    echo -e "  ${DIM}--------------------------------------------${NC}"
}

# Header
clear
echo ""
echo -e "  ${AMBER}${BOLD}BLACKROAD OS${NC}  ${WHITE}HEALTH CHECK${NC}  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "  ${DIM}=============================================${NC}"

# LOCAL SERVICES
_section "LOCAL SERVICES" "runtime dependencies"

r=$(_ping_port localhost 11434); st="${r%%:*}"; ms="${r#*:}"
if [[ "$st" == "ok" ]]; then
    models=$(curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('models',[])), 'models')" 2>/dev/null || echo "running")
    _chk "Ollama inference" "ok" "${GREEN}${models}${NC}" "$ms"
else
    _chk "Ollama inference" "fail" "${RED}not running -- ollama serve${NC}"
fi

if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    running=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    total=$(docker ps -a -q 2>/dev/null | wc -l | tr -d ' ')
    _chk "Docker daemon" "ok" "${GREEN}${running}/${total} containers${NC}"
else
    _chk "Docker daemon" "warn" "${AMBER}not running -- br docker ps${NC}"
fi

r=$(_ping_port localhost 8787); st="${r%%:*}"; ms="${r#*:}"
[[ "$st" == "ok" ]] \
    && _chk "BR Gateway :8787" "ok" "${GREEN}online${NC}" "$ms" \
    || _chk "BR Gateway :8787" "warn" "${AMBER}offline -- tokenless gateway${NC}"

r=$(_ping_port 127.0.0.1 8420); st="${r%%:*}"; ms="${r#*:}"
[[ "$st" == "ok" ]] \
    && _chk "MCP Bridge :8420" "ok" "${GREEN}online${NC}" "$ms" \
    || _chk "MCP Bridge :8420" "warn" "${AMBER}offline -- cd mcp-bridge && ./start.sh${NC}"

# CLOUD PLATFORMS
_section "CLOUD PLATFORMS" "external connectivity"

if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    orgs=$(gh api user/orgs --jq 'length' 2>/dev/null || echo "?")
    _chk "GitHub (gh auth)" "ok" "${GREEN}authenticated -- ${orgs} orgs${NC}"
else
    _chk "GitHub (gh auth)" "fail" "${RED}not authenticated -- gh auth login${NC}"
fi

for svc in "Cloudflare:https://cloudflare.com" "Railway:https://railway.app" "Vercel:https://vercel.com"; do
    name="${svc%%:*}"; url="${svc#*:}"
    r=$(_ping_http "$url" 4); st="${r%%:*}"; ms="${r#*:}"
    [[ "$st" == "ok" ]] \
        && _chk "$name" "ok" "${GREEN}reachable${NC}" "$ms" \
        || _chk "$name" "fail" "${RED}unreachable${NC}"
done

# RASPBERRY PI FLEET
_section "RASPBERRY PI FLEET" "local network"

for pi in "blackroad-pi:192.168.4.64" "aria64:192.168.4.38" "alice-pi:192.168.4.99"; do
    pname="${pi%%:*}"; pip="${pi#*:}"
    t0=$(_ms)
    if ping -c 1 -W 1 "$pip" &>/dev/null 2>&1; then
        ms=$(( $(_ms) - t0 ))
        _chk "$pname ($pip)" "ok" "${GREEN}online${NC}" "$ms"
    else
        _chk "$pname ($pip)" "warn" "${AMBER}unreachable${NC}"
    fi
done

# BLACKROAD TOOLS
_section "BLACKROAD TOOLS" "local data stores"

cece_db="$HOME/.blackroad/cece-identity.db"
if [[ -f "$cece_db" ]]; then
    ver=$(sqlite3 "$cece_db" "SELECT version FROM identity_core LIMIT 1;" 2>/dev/null || echo "?")
    rels=$(sqlite3 "$cece_db" "SELECT COUNT(*) FROM relationships;" 2>/dev/null || echo 0)
    _chk "CECE identity DB" "ok" "${GREEN}v${ver} -- ${rels} relationships${NC}"
else
    _chk "CECE identity DB" "warn" "${AMBER}not found -- br cece init${NC}"
fi

vault_db="$HOME/.blackroad/secrets-vault.db"
if [[ -f "$vault_db" ]]; then
    secrets=$(sqlite3 "$vault_db" "SELECT COUNT(*) FROM secrets;" 2>/dev/null || echo 0)
    _chk "Secrets vault" "ok" "${GREEN}${secrets} secrets${NC}"
else
    _chk "Secrets vault" "warn" "${AMBER}not found -- br vault set <n> <v>${NC}"
fi

mem_journal="$HOME/.blackroad/memory/journals/master-journal.jsonl"
if [[ -f "$mem_journal" ]]; then
    entries=$(wc -l < "$mem_journal" 2>/dev/null | tr -d ' ')
    _chk "PS-SHA journal" "ok" "${GREEN}${entries} entries${NC}"
else
    _chk "PS-SHA journal" "warn" "${AMBER}not initialized${NC}"
fi

br_bin="$HOME/blackroad/br"
[[ ! -f "$br_bin" ]] && br_bin=$(command -v br 2>/dev/null)
if [[ -n "$br_bin" && -x "$br_bin" ]]; then
    _chk "br CLI" "ok" "${GREEN}${br_bin}${NC}"
else
    _chk "br CLI" "fail" "${RED}not found${NC}"
fi

# SYSTEM RESOURCES
_section "SYSTEM RESOURCES" "hardware vitals"

if [[ "$(uname)" == "Darwin" ]]; then
    cpu=$(top -l 1 -n 0 -s 0 2>/dev/null | awk '/CPU usage:/ {gsub(/%/,""); print int($3+$5)}')
else
    cpu=$(awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print int(100*(total-idle)/total)}' /proc/stat 2>/dev/null)
fi
cpu=${cpu:-0}
cpu_st="ok"; (( cpu > 85 )) && cpu_st="warn"; (( cpu > 95 )) && cpu_st="fail"
_chk "CPU usage" "$cpu_st" "${GREEN}${cpu}%${NC}"

if [[ "$(uname)" == "Darwin" ]]; then
    mem_pct=$(vm_stat 2>/dev/null | awk '
        /Pages free/      { free=$3 }
        /Pages active/    { active=$3 }
        /Pages inactive/  { inactive=$3 }
        /Pages wired/     { wired=$4 }
        END { total=free+active+inactive+wired; used=active+wired;
              if(total>0) printf "%d", int(100*used/total) }')
else
    mem_pct=$(free 2>/dev/null | awk '/Mem:/{printf "%d", int(100*$3/$2)}')
fi
mem_pct=${mem_pct:-0}
mem_st="ok"; (( mem_pct > 85 )) && mem_st="warn"; (( mem_pct > 95 )) && mem_st="fail"
_chk "Memory usage" "$mem_st" "${GREEN}${mem_pct}%${NC}"

disk_pct=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
disk_pct=${disk_pct:-0}
disk_st="ok"; (( disk_pct > 85 )) && disk_st="warn"; (( disk_pct > 95 )) && disk_st="fail"
_chk "Disk usage (/)" "$disk_st" "${GREEN}${disk_pct}%${NC}"

r=$(_ping_http "https://github.com" 3); st="${r%%:*}"; ms="${r#*:}"
[[ "$st" == "ok" ]] \
    && _chk "Network (github.com)" "ok" "${GREEN}online${NC}" "$ms" \
    || _chk "Network (github.com)" "fail" "${RED}offline${NC}"

# SUMMARY
echo ""
echo -e "  ${DIM}=============================================${NC}"
TOTAL=$(( PASS + FAIL + WARN ))
if (( FAIL == 0 && WARN == 0 )); then
    echo -e "  ${GREEN}${BOLD}ALL SYSTEMS GO${NC}  ${DIM}${PASS}/${TOTAL} checks passed${NC}"
elif (( FAIL == 0 )); then
    echo -e "  ${AMBER}${BOLD}HEALTHY WITH WARNINGS${NC}  ${DIM}${PASS}/${TOTAL} passed -- ${WARN} warnings${NC}"
else
    echo -e "  ${RED}${BOLD}DEGRADED${NC}  ${DIM}${PASS}/${TOTAL} passed -- ${WARN} warnings -- ${FAIL} failures${NC}"
fi
echo ""
