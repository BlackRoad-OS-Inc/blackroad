#!/usr/bin/env zsh
# BR Health — BlackRoad OS System Health Diagnostic
# br health [all|pis|gateway|ollama|workers|git|disk|quick]

AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
BLUE='\033[38;5;69m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0; FAIL=0; WARN=0

_ms() { python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo 0; }

_chk() {
    local label="$1" st="$2" msg="$3" ms="${4:-}"
    local icon
    case "$st" in
        ok)   icon="${GREEN}✅${NC}"; (( PASS++ )) ;;
        warn) icon="${YELLOW}⚠️ ${NC}"; (( WARN++ )) ;;
        fail) icon="${RED}❌${NC}";  (( FAIL++ )) ;;
    esac
    local timing=""
    [[ -n "$ms" && "$ms" != "0" ]] && timing="${DIM}  ${ms}ms${NC}"
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
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
}

_header() {
    echo ""
    echo -e "  ${AMBER}${BOLD}BLACKROAD OS${NC}  ${WHITE}HEALTH${NC}${BOLD} — $1${NC}  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "  ${DIM}═══════════════════════════════════════════════${NC}"
}

_summary() {
    echo ""
    echo -e "  ${DIM}═══════════════════════════════════════════════${NC}"
    local total=$(( PASS + FAIL + WARN ))
    if (( FAIL == 0 && WARN == 0 )); then
        echo -e "  ${GREEN}${BOLD}ALL SYSTEMS GO${NC}  ${DIM}${PASS}/${total} healthy${NC}"
    elif (( FAIL == 0 )); then
        echo -e "  ${YELLOW}${BOLD}HEALTHY WITH WARNINGS${NC}  ${DIM}${PASS}/${total} passed · ${WARN} warnings${NC}"
    else
        echo -e "  ${RED}${BOLD}DEGRADED${NC}  ${DIM}${PASS}/${total} passed · ${WARN} warnings · ${FAIL} failures${NC}"
    fi
    echo ""
}

# ── pis ───────────────────────────────────────────────────────────────────────
cmd_pis() {
    _header "RASPBERRY PI FLEET"
    _section "PI NODES" "192.168.4.x network"

    local pi_list=("blackroad-pi:192.168.4.64" "aria64:192.168.4.38" "alice-pi:192.168.4.49")
    for entry in "${pi_list[@]}"; do
        local pname="${entry%%:*}" pip="${entry#*:}"
        local t0 ms
        t0=$(_ms)
        if ping -c 1 -W 1 "$pip" &>/dev/null 2>&1; then
            ms=$(( $(_ms) - t0 ))
            # Try SSH reachability
            local ssh_ok="no SSH"
            if nc -z -w 2 "$pip" 22 &>/dev/null; then
                ssh_ok="${GREEN}SSH open${NC}"
            else
                ssh_ok="${DIM}SSH closed${NC}"
            fi
            _chk "$pname ($pip)" "ok" "${GREEN}online${NC} · $ssh_ok" "$ms"
        else
            _chk "$pname ($pip)" "warn" "${YELLOW}unreachable${NC}"
        fi
    done

    _summary
}

# ── gateway ───────────────────────────────────────────────────────────────────
cmd_gateway() {
    _header "GATEWAY"
    _section "LOCAL GATEWAY" "127.0.0.1"

    local r st ms detail
    r=$(_ping_port 127.0.0.1 8787 3); st="${r%%:*}"; ms="${r#*:}"
    if [[ "$st" == "ok" ]]; then
        detail=$(curl -s --max-time 2 http://127.0.0.1:8787/health 2>/dev/null \
            | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','up'))" 2>/dev/null \
            || echo "up")
        _chk "Gateway :8787" "ok" "${GREEN}${detail}${NC}" "$ms"
    else
        _chk "Gateway :8787" "fail" "${RED}offline — br gateway start${NC}"
    fi

    r=$(_ping_port 127.0.0.1 8080 3); st="${r%%:*}"; ms="${r#*:}"
    if [[ "$st" == "ok" ]]; then
        _chk "Alt gateway :8080" "ok" "${GREEN}online${NC}" "$ms"
    else
        _chk "Alt gateway :8080" "warn" "${DIM}not running${NC}"
    fi

    r=$(_ping_port 127.0.0.1 8420 2); st="${r%%:*}"; ms="${r#*:}"
    if [[ "$st" == "ok" ]]; then
        _chk "MCP Bridge :8420" "ok" "${GREEN}online${NC}" "$ms"
    else
        _chk "MCP Bridge :8420" "warn" "${YELLOW}offline — cd mcp-bridge && ./start.sh${NC}"
    fi

    _summary
}

# ── ollama ────────────────────────────────────────────────────────────────────
cmd_ollama() {
    _header "OLLAMA"
    _section "OLLAMA INFERENCE" "localhost:11434"

    local r st ms
    r=$(_ping_port localhost 11434 3); st="${r%%:*}"; ms="${r#*:}"
    if [[ "$st" == "ok" ]]; then
        local model_json model_count model_names
        model_json=$(curl -s --max-time 3 http://localhost:11434/api/tags 2>/dev/null)
        model_count=$(echo "$model_json" | python3 -c \
            "import sys,json; d=json.load(sys.stdin); print(len(d.get('models',[])))" 2>/dev/null || echo "?")
        _chk "Ollama daemon" "ok" "${GREEN}running · ${model_count} models${NC}" "$ms"

        # List models
        echo ""
        echo -e "  ${DIM}Models:${NC}"
        echo "$model_json" | python3 -c \
            "import sys,json; d=json.load(sys.stdin)
[print('    • ' + m['name']) for m in d.get('models',[])]" 2>/dev/null \
            || echo "    (none loaded)"
    else
        _chk "Ollama daemon" "fail" "${RED}not running — ollama serve${NC}"
    fi

    _summary
}

# ── workers ───────────────────────────────────────────────────────────────────
cmd_workers() {
    _header "CLOUDFLARE WORKERS"
    _section "CF WORKERS" "blackroad.workers.dev"

    local workers=(
        "verify:https://blackroad-verify.blackroad.workers.dev"
        "worlds:https://blackroad-worlds.blackroad.workers.dev"
        "studio:https://blackroad-studio.blackroad.workers.dev"
        "docs:https://blackroad-docs.blackroad.workers.dev"
        "agents-status:https://blackroad-agents.blackroad.workers.dev"
    )

    for entry in "${workers[@]}"; do
        local name="${entry%%:*}" url="${entry#*:}"
        local r st ms
        r=$(_ping_http "$url" 4); st="${r%%:*}"; ms="${r#*:}"
        if [[ "$st" == "ok" ]]; then
            _chk "$name" "ok" "${GREEN}reachable${NC}" "$ms"
        elif [[ "$st" == "warn" ]]; then
            _chk "$name" "warn" "${YELLOW}non-2xx response${NC}" "$ms"
        else
            _chk "$name" "fail" "${RED}unreachable${NC}"
        fi
    done

    _summary
}

# ── git ───────────────────────────────────────────────────────────────────────
cmd_git() {
    _header "GIT REPO STATUS"
    _section "GIT" "/Users/alexa/blackroad"

    local repo="/Users/alexa/blackroad"
    cd "$repo" 2>/dev/null || { _chk "blackroad repo" "fail" "${RED}not found${NC}"; _summary; return; }

    local branch last_commit dirty_count remote_url
    branch=$(git branch --show-current 2>/dev/null || echo "?")
    last_commit=$(git --no-pager log -1 --format="%h %s (%ar)" 2>/dev/null || echo "unknown")
    dirty_count=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    remote_url=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||' || echo "?")

    if [[ "$dirty_count" -eq 0 ]]; then
        _chk "Working tree" "ok" "${GREEN}clean${NC}"
    else
        _chk "Working tree" "warn" "${YELLOW}${dirty_count} dirty files${NC}"
    fi

    _chk "Branch" "ok" "${CYAN}${branch}${NC}"
    _chk "Last commit" "ok" "${DIM}${last_commit}${NC}"
    _chk "Remote" "ok" "${DIM}${remote_url}${NC}"

    local ahead behind
    ahead=$(git --no-pager log @{u}.. --oneline 2>/dev/null | wc -l | tr -d ' ')
    behind=$(git --no-pager log ..@{u} --oneline 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$ahead" -gt 0 ]]; then
        _chk "Sync status" "warn" "${YELLOW}${ahead} commits ahead${NC}"
    elif [[ "$behind" -gt 0 ]]; then
        _chk "Sync status" "warn" "${YELLOW}${behind} commits behind${NC}"
    else
        _chk "Sync status" "ok" "${GREEN}in sync with remote${NC}"
    fi

    if [[ "$dirty_count" -gt 0 ]]; then
        echo ""
        echo -e "  ${DIM}Dirty files:${NC}"
        git status --short 2>/dev/null | head -10 | while read line; do
            echo "    ${YELLOW}$line${NC}"
        done
    fi

    _summary
}

# ── disk ─────────────────────────────────────────────────────────────────────
cmd_disk() {
    _header "DISK USAGE"
    _section "DISK" "key directories"

    local paths=("/:/" "~/blackroad:$HOME/blackroad" "~/.blackroad:$HOME/.blackroad")
    for entry in "${paths[@]}"; do
        local label="${entry%%:*}" path="${entry#*:}"
        if [[ -e "$path" ]]; then
            local used avail pct
            if [[ "$path" == "/" ]]; then
                pct=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
                used=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}')
                avail=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}')
            else
                used=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
                avail=$(df -h "$path" 2>/dev/null | awk 'NR==2 {print $4}')
                pct=$(df -h "$path" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
            fi
            pct=${pct:-0}
            local disk_st="ok"
            (( pct > 85 )) && disk_st="warn"
            (( pct > 95 )) && disk_st="fail"
            _chk "$label" "$disk_st" "${GREEN}used: ${used}  avail: ${avail}  (${pct}%)${NC}"
        else
            _chk "$label" "warn" "${DIM}path not found${NC}"
        fi
    done

    _summary
}

# ── quick ─────────────────────────────────────────────────────────────────────
cmd_quick() {
    _header "QUICK CHECK (5s)"
    _section "CRITICAL SERVICES" "fast path"

    # Ollama
    local r st ms
    r=$(_ping_port localhost 11434 2); st="${r%%:*}"; ms="${r#*:}"
    [[ "$st" == "ok" ]] \
        && _chk "Ollama :11434" "ok" "${GREEN}up${NC}" "$ms" \
        || _chk "Ollama :11434" "fail" "${RED}down${NC}"

    # Gateway
    r=$(_ping_port 127.0.0.1 8787 2); st="${r%%:*}"; ms="${r#*:}"
    [[ "$st" == "ok" ]] \
        && _chk "Gateway :8787" "ok" "${GREEN}up${NC}" "$ms" \
        || _chk "Gateway :8787" "warn" "${YELLOW}offline${NC}"

    # GitHub
    r=$(_ping_http "https://github.com" 2); st="${r%%:*}"; ms="${r#*:}"
    [[ "$st" == "ok" ]] \
        && _chk "GitHub" "ok" "${GREEN}reachable${NC}" "$ms" \
        || _chk "GitHub" "fail" "${RED}unreachable${NC}"

    # Disk
    local disk_pct
    disk_pct=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    disk_pct=${disk_pct:-0}
    (( disk_pct < 85 )) \
        && _chk "Disk (/)" "ok" "${GREEN}${disk_pct}% used${NC}" \
        || _chk "Disk (/)" "warn" "${YELLOW}${disk_pct}% used${NC}"

    # Pi primary
    local t0
    t0=$(_ms)
    if ping -c 1 -W 1 192.168.4.64 &>/dev/null 2>&1; then
        ms=$(( $(_ms) - t0 ))
        _chk "Pi primary (192.168.4.64)" "ok" "${GREEN}online${NC}" "$ms"
    else
        _chk "Pi primary (192.168.4.64)" "warn" "${YELLOW}unreachable${NC}"
    fi

    _summary
}

# ── all (full diagnostic) ─────────────────────────────────────────────────────
cmd_all() {
    clear
    _header "FULL DIAGNOSTIC"

    _section "LOCAL SERVICES" "runtime dependencies"

    local r st ms

    r=$(_ping_port localhost 11434 3); st="${r%%:*}"; ms="${r#*:}"
    if [[ "$st" == "ok" ]]; then
        local models
        models=$(curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null \
            | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('models',[])), 'models')" \
            2>/dev/null || echo "running")
        _chk "Ollama inference" "ok" "${GREEN}${models}${NC}" "$ms"
    else
        _chk "Ollama inference" "fail" "${RED}not running — ollama serve${NC}"
    fi

    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        local running total
        running=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
        total=$(docker ps -a -q 2>/dev/null | wc -l | tr -d ' ')
        _chk "Docker daemon" "ok" "${GREEN}${running}/${total} containers${NC}"
    else
        _chk "Docker daemon" "warn" "${YELLOW}not running${NC}"
    fi

    r=$(_ping_port 127.0.0.1 8787 3); st="${r%%:*}"; ms="${r#*:}"
    [[ "$st" == "ok" ]] \
        && _chk "BR Gateway :8787" "ok" "${GREEN}online${NC}" "$ms" \
        || _chk "BR Gateway :8787" "warn" "${YELLOW}offline — br gateway start${NC}"

    r=$(_ping_port 127.0.0.1 8420 2); st="${r%%:*}"; ms="${r#*:}"
    [[ "$st" == "ok" ]] \
        && _chk "MCP Bridge :8420" "ok" "${GREEN}online${NC}" "$ms" \
        || _chk "MCP Bridge :8420" "warn" "${YELLOW}offline${NC}"

    _section "CLOUD PLATFORMS" "external connectivity"

    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
        local orgs
        orgs=$(gh api user/orgs --jq 'length' 2>/dev/null || echo "?")
        _chk "GitHub (gh auth)" "ok" "${GREEN}authenticated · ${orgs} orgs${NC}"
    else
        _chk "GitHub (gh auth)" "fail" "${RED}not authenticated — gh auth login${NC}"
    fi

    for svc in "Cloudflare:https://cloudflare.com" "Railway:https://railway.app" "Vercel:https://vercel.com"; do
        local name="${svc%%:*}" url="${svc#*:}"
        r=$(_ping_http "$url" 4); st="${r%%:*}"; ms="${r#*:}"
        [[ "$st" == "ok" ]] \
            && _chk "$name" "ok" "${GREEN}reachable${NC}" "$ms" \
            || _chk "$name" "fail" "${RED}unreachable${NC}"
    done

    _section "RASPBERRY PI FLEET" "192.168.4.x"

    for pi in "blackroad-pi:192.168.4.64" "aria64:192.168.4.38" "alice-pi:192.168.4.49"; do
        local pname="${pi%%:*}" pip="${pi#*:}"
        local t0
        t0=$(_ms)
        if ping -c 1 -W 1 "$pip" &>/dev/null 2>&1; then
            ms=$(( $(_ms) - t0 ))
            _chk "$pname ($pip)" "ok" "${GREEN}online${NC}" "$ms"
        else
            _chk "$pname ($pip)" "warn" "${YELLOW}unreachable${NC}"
        fi
    done

    _section "DATA STORES" "local SQLite & journals"

    local cece_db="$HOME/.blackroad/cece-identity.db"
    if [[ -f "$cece_db" ]]; then
        local rels
        rels=$(sqlite3 "$cece_db" "SELECT COUNT(*) FROM relationships;" 2>/dev/null || echo 0)
        _chk "CECE identity DB" "ok" "${GREEN}${rels} relationships${NC}"
    else
        _chk "CECE identity DB" "warn" "${YELLOW}not found — br cece init${NC}"
    fi

    local mem_journal="$HOME/.blackroad/memory/journals/master-journal.jsonl"
    if [[ -f "$mem_journal" ]]; then
        local entries
        entries=$(wc -l < "$mem_journal" 2>/dev/null | tr -d ' ')
        _chk "PS-SHA journal" "ok" "${GREEN}${entries} entries${NC}"
    else
        _chk "PS-SHA journal" "warn" "${YELLOW}not initialized${NC}"
    fi

    _section "SYSTEM RESOURCES" "hardware vitals"

    local cpu
    cpu=$(top -l 1 -n 0 -s 0 2>/dev/null | awk '/CPU usage:/ {gsub(/%/,""); print int($3+$5)}' 2>/dev/null || echo 0)
    cpu=${cpu:-0}
    local cpu_st="ok"
    (( cpu > 85 )) && cpu_st="warn"
    (( cpu > 95 )) && cpu_st="fail"
    _chk "CPU usage" "$cpu_st" "${GREEN}${cpu}%${NC}"

    local disk_pct
    disk_pct=$(df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
    disk_pct=${disk_pct:-0}
    local disk_st="ok"
    (( disk_pct > 85 )) && disk_st="warn"
    (( disk_pct > 95 )) && disk_st="fail"
    _chk "Disk usage (/)" "$disk_st" "${GREEN}${disk_pct}%${NC}"

    r=$(_ping_http "https://github.com" 3); st="${r%%:*}"; ms="${r#*:}"
    [[ "$st" == "ok" ]] \
        && _chk "Network (github.com)" "ok" "${GREEN}online${NC}" "$ms" \
        || _chk "Network (github.com)" "fail" "${RED}offline${NC}"

    _summary
}

show_help() {
    echo ""
    echo -e "  ${AMBER}${BOLD}BR HEALTH${NC} — BlackRoad OS system health diagnostic"
    echo ""
    echo -e "  ${CYAN}br health${NC}               Full health check (all services)"
    echo -e "  ${CYAN}br health all${NC}            Full health check"
    echo -e "  ${CYAN}br health pis${NC}            Ping all 3 Raspberry Pis"
    echo -e "  ${CYAN}br health gateway${NC}        Check local gateway at 127.0.0.1:8787"
    echo -e "  ${CYAN}br health ollama${NC}         Check Ollama at localhost:11434"
    echo -e "  ${CYAN}br health workers${NC}        Check Cloudflare workers"
    echo -e "  ${CYAN}br health git${NC}            Git status of ~/blackroad repo"
    echo -e "  ${CYAN}br health disk${NC}           Disk usage of key directories"
    echo -e "  ${CYAN}br health quick${NC}          5-second fast check of critical services"
    echo ""
}

case "${1:-all}" in
    all|"")      cmd_all ;;
    pis|pi)      cmd_pis ;;
    gateway|gw)  cmd_gateway ;;
    ollama|llm)  cmd_ollama ;;
    workers|wk)  cmd_workers ;;
    git)         cmd_git ;;
    disk|du)     cmd_disk ;;
    quick|q)     cmd_quick ;;
    help|--help|-h) show_help ;;
    *)           cmd_all ;;
esac
