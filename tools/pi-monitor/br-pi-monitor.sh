#!/bin/zsh
# BR Pi Monitor — Pi Fleet Health Dashboard

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/pi-monitor.db"

# Fleet definition: "name user ip [fallback_ip]"
typeset -A PI_USERS PI_IPS PI_FALLBACK
PI_USERS=(alice alice  aria pi  octavia pi)
PI_IPS=(   alice 192.168.4.49  aria 192.168.4.38  octavia 192.168.4.99)
PI_FALLBACK=(octavia 192.168.4.64)
PI_ORDER=(alice aria octavia)

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<'EOF'
CREATE TABLE IF NOT EXISTS pi_checks (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    pi_name     TEXT NOT NULL,
    ip          TEXT NOT NULL,
    checked_at  TEXT NOT NULL,
    reachable   INTEGER NOT NULL DEFAULT 0,
    cpu_pct     REAL,
    mem_pct     REAL,
    disk_pct    REAL,
    uptime_sec  INTEGER,
    services    TEXT
);
CREATE TABLE IF NOT EXISTS pi_alerts (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    pi_name    TEXT NOT NULL,
    alert_msg  TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
EOF
}

# ── helpers ──────────────────────────────────────────────────────────────────

bar() {
    local pct=$1 width=20
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local color=$GREEN
    (( pct >= 80 )) && color=$RED
    (( pct >= 60 && pct < 80 )) && color=$YELLOW
    printf "${color}["
    printf '%0.s█' {1..$filled} 2>/dev/null || printf '%*s' "$filled" '' | tr ' ' '█'
    printf '%*s' "$empty" '' | tr ' ' '░'
    printf "]${NC}"
}

status_dot() {
    [[ $1 == "up" ]] && echo -e "${GREEN}●${NC}" || echo -e "${RED}●${NC}"
}

svc_status() {
    local s=$1
    [[ $s == "1" ]] && echo -e "${GREEN}✔${NC}" || echo -e "${RED}✘${NC}"
}

fmt_uptime() {
    local sec=$1
    local d=$(( sec / 86400 ))
    local h=$(( (sec % 86400) / 3600 ))
    local m=$(( (sec % 3600) / 60 ))
    [[ $d -gt 0 ]] && echo "${d}d ${h}h ${m}m" || echo "${h}h ${m}m"
}

# ── SSH probe ─────────────────────────────────────────────────────────────────

probe_pi() {
    local name=$1 user=$2 ip=$3
    # Returns: reachable cpu mem disk uptime nginx cloudflared ollama pm2
    ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes \
        "${user}@${ip}" 'bash -s' <<'REMOTE' 2>/dev/null
# cpu (1-sec sample)
cpu=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2+$4}' | cut -d. -f1)
[[ -z $cpu ]] && cpu=$(cat /proc/loadavg | awk '{printf "%d", $1*100/$(nproc)}')

# memory
mem_line=$(free | grep Mem)
mem_total=$(echo $mem_line | awk '{print $2}')
mem_used=$(echo $mem_line | awk '{print $3}')
mem_pct=$(echo "$mem_used $mem_total" | awk '{printf "%d", ($1/$2)*100}')

# disk (root)
disk_pct=$(df / | tail -1 | awk '{print $5}' | tr -d '%')

# uptime in seconds
uptime_sec=$(awk '{print int($1)}' /proc/uptime)

# services
nginx=0; cloudflared=0; ollama=0; pm2=0
systemctl is-active --quiet nginx        2>/dev/null && nginx=1
systemctl is-active --quiet cloudflared  2>/dev/null && cloudflared=1
systemctl is-active --quiet ollama       2>/dev/null && ollama=1
pgrep -x pm2 >/dev/null 2>&1             && pm2=1

echo "$cpu $mem_pct $disk_pct $uptime_sec $nginx $cloudflared $ollama $pm2"
REMOTE
}

# ── check a single pi ────────────────────────────────────────────────────────

check_pi() {
    local name=$1
    local user=${PI_USERS[$name]}
    local ip=${PI_IPS[$name]}
    local fallback=${PI_FALLBACK[$name]}
    local used_ip=$ip

    echo -e "\n${BOLD}${PURPLE}▶ ${name}${NC}  ${DIM}${user}@${ip}${NC}"
    echo -e "  ${DIM}$(printf '%.s─' {1..58})${NC}"

    # Try primary IP
    local result
    result=$(probe_pi "$name" "$user" "$ip")

    # Try fallback if primary fails and fallback exists
    if [[ -z $result && -n $fallback ]]; then
        echo -e "  ${YELLOW}⚡ primary unreachable, trying fallback ${fallback}${NC}"
        result=$(probe_pi "$name" "$user" "$fallback")
        used_ip=$fallback
    fi

    if [[ -z $result ]]; then
        echo -e "  $(status_dot down) ${RED}OFFLINE${NC} — cannot reach ${ip}${[[ -n $fallback ]] && echo " or $fallback"}"
        sqlite3 "$DB_FILE" \
            "INSERT INTO pi_checks(pi_name,ip,checked_at,reachable) VALUES('$name','$used_ip',datetime('now'),0);"
        sqlite3 "$DB_FILE" \
            "INSERT INTO pi_alerts(pi_name,alert_msg) VALUES('$name','Pi $name is offline ($used_ip)');"
        return
    fi

    read cpu mem disk uptime nginx cloudflared ollama pm2 <<< "$result"

    # Clamp values
    cpu=${cpu:-0}; mem=${mem:-0}; disk=${disk:-0}; uptime=${uptime:-0}

    # Reachable
    echo -e "  $(status_dot up) ${GREEN}ONLINE${NC}  ${DIM}${user}@${used_ip}${NC}  uptime: ${CYAN}$(fmt_uptime $uptime)${NC}"
    echo ""

    # Metrics
    local cpu_color=$GREEN
    (( cpu >= 80 )) && cpu_color=$RED
    (( cpu >= 60 && cpu < 80 )) && cpu_color=$YELLOW

    local mem_color=$GREEN
    (( mem >= 80 )) && mem_color=$RED
    (( mem >= 60 && mem < 80 )) && mem_color=$YELLOW

    local disk_color=$GREEN
    (( disk >= 85 )) && disk_color=$RED
    (( disk >= 70 && disk < 85 )) && disk_color=$YELLOW

    printf "  ${CYAN}CPU ${NC}  $(bar $cpu)  ${cpu_color}%3d%%${NC}\n" $cpu
    printf "  ${CYAN}MEM ${NC}  $(bar $mem)  ${mem_color}%3d%%${NC}\n" $mem
    printf "  ${CYAN}DISK${NC}  $(bar $disk)  ${disk_color}%3d%%${NC}\n" $disk
    echo ""

    # Services
    echo -e "  ${CYAN}Services:${NC}"
    printf "    nginx        %s\n" "$(svc_status $nginx)"
    printf "    cloudflared  %s\n" "$(svc_status $cloudflared)"
    printf "    ollama       %s\n" "$(svc_status $ollama)"
    printf "    pm2          %s\n" "$(svc_status $pm2)"

    # Alerts
    [[ $cpu  -ge 80 ]] && echo -e "\n  ${RED}⚠ HIGH CPU${NC}: ${cpu}%"
    [[ $mem  -ge 80 ]] && echo -e "  ${RED}⚠ HIGH MEMORY${NC}: ${mem}%"
    [[ $disk -ge 85 ]] && echo -e "  ${RED}⚠ HIGH DISK${NC}: ${disk}%"

    # Persist
    local svc_json="nginx=$nginx,cloudflared=$cloudflared,ollama=$ollama,pm2=$pm2"
    sqlite3 "$DB_FILE" \
        "INSERT INTO pi_checks(pi_name,ip,checked_at,reachable,cpu_pct,mem_pct,disk_pct,uptime_sec,services)
         VALUES('$name','$used_ip',datetime('now'),1,$cpu,$mem,$disk,$uptime,'$svc_json');"
}

# ── commands ─────────────────────────────────────────────────────────────────

cmd_status() {
    local target=${1:-all}
    echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║        BR Pi Fleet Health Dashboard                  ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"

    if [[ $target == "all" ]]; then
        for pi in $PI_ORDER; do
            check_pi "$pi"
        done
    elif [[ -n ${PI_IPS[$target]} ]]; then
        check_pi "$target"
    else
        echo -e "${RED}Unknown Pi: $target${NC}"
        echo "  Available: ${(k)PI_IPS}"
        exit 1
    fi
    echo ""
}

cmd_history() {
    local pi=${1:-""}
    echo -e "\n${CYAN}${BOLD}Recent Check History${NC}"
    local q="SELECT datetime(checked_at,'localtime') as ts, pi_name, ip, reachable,
                    cpu_pct, mem_pct, disk_pct
             FROM pi_checks"
    [[ -n $pi ]] && q+=" WHERE pi_name='$pi'"
    q+=" ORDER BY id DESC LIMIT 20"
    sqlite3 -column -header "$DB_FILE" "$q" 2>/dev/null || echo "  No history yet."
    echo ""
}

cmd_alerts() {
    echo -e "\n${CYAN}${BOLD}Recent Alerts${NC}"
    sqlite3 -column -header "$DB_FILE" \
        "SELECT datetime(created_at,'localtime') as ts, pi_name, alert_msg
         FROM pi_alerts ORDER BY id DESC LIMIT 20" 2>/dev/null || echo "  No alerts."
    echo ""
}

cmd_ssh() {
    local name=$1
    [[ -z $name ]] && { echo -e "${RED}Usage: br pi-monitor ssh <name>${NC}"; exit 1; }
    local user=${PI_USERS[$name]}
    local ip=${PI_IPS[$name]}
    [[ -z $user ]] && { echo -e "${RED}Unknown Pi: $name${NC}"; exit 1; }
    echo -e "${CYAN}Connecting to ${name} (${user}@${ip})…${NC}"
    ssh "${user}@${ip}"
}

show_help() {
    echo -e "\n${BOLD}${CYAN}BR Pi Monitor${NC} — Pi Fleet Health Dashboard"
    echo ""
    echo -e "  ${CYAN}br pi-monitor${NC}               Dashboard for all Pis"
    echo -e "  ${CYAN}br pi-monitor status${NC}         Same as above"
    echo -e "  ${CYAN}br pi-monitor status <pi>${NC}    Dashboard for one Pi (alice/aria/octavia)"
    echo -e "  ${CYAN}br pi-monitor history${NC}        Show check history"
    echo -e "  ${CYAN}br pi-monitor history <pi>${NC}   History for one Pi"
    echo -e "  ${CYAN}br pi-monitor alerts${NC}         Show recent alerts"
    echo -e "  ${CYAN}br pi-monitor ssh <pi>${NC}       SSH into a Pi"
    echo ""
    echo -e "  ${DIM}Fleet:${NC}"
    echo -e "    alice    alice@192.168.4.49"
    echo -e "    aria     pi@192.168.4.38"
    echo -e "    octavia  pi@192.168.4.99  (fallback: 192.168.4.64)"
    echo ""
}

# ── main ─────────────────────────────────────────────────────────────────────

init_db

case "${1:-status}" in
    status|health|check)  cmd_status "${2:-all}" ;;
    history|log)          cmd_history "$2" ;;
    alerts)               cmd_alerts ;;
    ssh)                  cmd_ssh "$2" ;;
    help|-h|--help)       show_help ;;
    # bare call with Pi name as first arg
    alice|aria|octavia)   cmd_status "$1" ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
