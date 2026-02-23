#!/bin/zsh
# BR Nodes — Fleet discovery, inventory, and topology
# Usage: br nodes [scan|status|show|devices|topology|web|fix]

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

DB="$HOME/.blackroad/fleet-nodes.db"
SCAN_SUBNET="${BLACKROAD_SCAN_SUBNET:-192.168.4}"
SSH_USER="${BLACKROAD_SSH_USER:-blackroad}"
SSH_OPTS="-o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR"

# ─── Known hosts (pre-seeded from .ssh/config) ──────────────────────────────
typeset -A KNOWN_HOSTS
KNOWN_HOSTS=(
  "192.168.4.89"   "cecilia"
  "192.168.4.81"   "lucidia"
  "192.168.4.82"   "aria"
  "192.168.4.38"   "octavia"
  "192.168.4.49"   "alice"
  "174.138.44.45"  "anastasia"
  "159.65.43.12"   "gematria"
)

typeset -A KNOWN_ROLES
KNOWN_ROLES=(
  "cecilia"     "Pi5 + Hailo-8 NPU"
  "lucidia"     "Pi5 AI node"
  "aria"        "Pi5 Harmony/Docker"
  "octavia"     "Pi5 Compute/Tailscale"
  "alice"       "Pi4 Gateway"
  "anastasia"   "DO NYC RHEL9 / WireGuard server"
  "gematria"    "DO NYC Ubuntu22 / Cloudflare tunnel"
)

typeset -A NODE_USERS
NODE_USERS=(
  "cecilia"     "blackroad"
  "lucidia"     "blackroad"
  "aria"        "blackroad"
  "octavia"     "blackroad"
  "alice"       "blackroad"
  "anastasia"   "blackroad"
  "gematria"    "blackroad"
)

# ─── Database ────────────────────────────────────────────────────────────────
init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS nodes (
  ip          TEXT PRIMARY KEY,
  hostname    TEXT,
  alias       TEXT,
  role        TEXT,
  os          TEXT,
  arch        TEXT,
  mac         TEXT,
  vendor      TEXT,
  ssh_user    TEXT,
  reachable   INTEGER DEFAULT 0,
  ssh_ok      INTEGER DEFAULT 0,
  tailscale   TEXT,
  wireguard   TEXT,
  ollama_ok   INTEGER DEFAULT 0,
  ollama_models TEXT,
  uptime      TEXT,
  disk_pct    TEXT,
  cpu_temp    TEXT,
  last_seen   TEXT,
  tags        TEXT
);
CREATE TABLE IF NOT EXISTS devices (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  node_ip     TEXT,
  type        TEXT,
  path        TEXT,
  vendor      TEXT,
  model       TEXT,
  detail      TEXT,
  updated_at  TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS tailscale_nodes (
  ts_ip       TEXT PRIMARY KEY,
  name        TEXT,
  os          TEXT,
  status      TEXT,
  last_seen   TEXT
);
SQL
}

# ─── Helpers ─────────────────────────────────────────────────────────────────
db() { sqlite3 -separator $'\t' "$DB" "$@"; }
ts()  { date '+%Y-%m-%d %H:%M:%S'; }
ping_host() { ping -c1 -W1 "$1" &>/dev/null && echo 1 || echo 0; }

# Check if host is reachable
reachable() {
  ping -c1 -W1 "$1" &>/dev/null && return 0 || return 1
}

# ─── Scan single host ────────────────────────────────────────────────────────
scan_host() {
  local ip="$1"
  local alias="${KNOWN_HOSTS[$ip]:-}"
  local user="${NODE_USERS[$alias]:-$SSH_USER}"
  local role="${KNOWN_ROLES[$alias]:-unknown}"

  printf "${CYAN}  → %-18s${NC}" "$ip"

  # Ping check
  if ! reachable "$ip"; then
    printf "${RED}✗ offline${NC}\n"
    db "INSERT OR REPLACE INTO nodes (ip, alias, role, reachable, ssh_ok, last_seen)
        VALUES ('$ip','$alias','$role',0,0,'$(ts)')"
    return
  fi

  printf "${GREEN}✓ ping  ${NC}"

  # SSH probe
  local info
  info=$(ssh $SSH_OPTS -i ~/.ssh/id_ed25519 ${user}@${ip} '
    echo "HOSTNAME=$(hostname)"
    echo "OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d \")"
    echo "ARCH=$(uname -m)"
    echo "UPTIME=$(uptime -p 2>/dev/null || uptime | awk -F"up " "{print $2}" | cut -d, -f1 | xargs)"
    echo "DISK=$(df / 2>/dev/null | awk "NR==2{print $5}")"
    echo "TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk "{printf \"%.1f°C\", $1/1000}")"
    echo "TAILSCALE=$(tailscale ip 2>/dev/null | head -1)"
    echo "WIREGUARD=$(ip addr show wg0 2>/dev/null | grep "inet " | awk "{print $2}")"
    echo "OLLAMA=$(curl -sf http://localhost:11434/api/tags 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(\",\".join(m[\"name\"] for m in d.get(\"models\",[])[:8]))" 2>/dev/null)"
    # USB/serial devices
    echo "DEVICES_USB=$(lsusb 2>/dev/null | grep -v "Linux Foundation\|root hub" | head -8 | tr "\n" "|")"
    echo "DEVICES_SERIAL=$(ls /dev/ttyUSB* /dev/ttyACM* /dev/ttyS0 2>/dev/null | tr "\n" "|")"
    echo "DEVICES_VIDEO=$(ls /dev/video* 2>/dev/null | tr "\n" "|")"
    echo "DEVICES_DISK=$(lsblk -d -o NAME,SIZE,TRAN 2>/dev/null | grep -v "NAME\|zram" | tr "\n" "|")"
    # I2C/SPI
    echo "DEVICES_I2C=$(ls /dev/i2c-* 2>/dev/null | tr "\n" "|")"
    echo "DOCKER=$(docker ps --format "{{.Names}}" 2>/dev/null | tr "\n" "," | head -c 120)"
  ' 2>/dev/null)

  if [[ -z "$info" ]]; then
    printf "${YELLOW}✗ ssh failed${NC}\n"
    db "INSERT OR REPLACE INTO nodes (ip, alias, role, reachable, ssh_ok, last_seen)
        VALUES ('$ip','$alias','$role',1,0,'$(ts)')"
    return
  fi

  # Parse output
  local hostname os arch uptime disk temp ts_ip wg ollama
  hostname=$(echo "$info" | grep "^HOSTNAME=" | cut -d= -f2)
  os=$(echo "$info" | grep "^OS=" | cut -d= -f2-)
  arch=$(echo "$info" | grep "^ARCH=" | cut -d= -f2)
  uptime=$(echo "$info" | grep "^UPTIME=" | cut -d= -f2-)
  disk=$(echo "$info" | grep "^DISK=" | cut -d= -f2)
  temp=$(echo "$info" | grep "^TEMP=" | cut -d= -f2)
  ts_ip=$(echo "$info" | grep "^TAILSCALE=" | cut -d= -f2)
  wg=$(echo "$info" | grep "^WIREGUARD=" | cut -d= -f2)
  ollama=$(echo "$info" | grep "^OLLAMA=" | cut -d= -f2-)
  local ollama_ok=0
  [[ -n "$ollama" ]] && ollama_ok=1

  printf "${GREEN}✓ ssh  ${NC}"
  [[ -n "$ts_ip" ]] && printf "${PURPLE}[TS:$ts_ip]${NC} "
  [[ -n "$wg" ]]    && printf "${BLUE}[WG:$wg]${NC} "
  printf "%s" "${hostname:-?}"
  [[ -n "$temp" ]] && printf " ${temp}"
  [[ -n "$disk" ]]  && printf " disk:${disk}"
  printf "\n"

  # Store node
  db "INSERT OR REPLACE INTO nodes
      (ip, hostname, alias, role, os, arch, ssh_user, reachable, ssh_ok,
       tailscale, wireguard, ollama_ok, ollama_models, uptime, disk_pct, cpu_temp, last_seen, tags)
      VALUES (
        '$ip','$(echo $hostname | tr "'" " ")','$alias','$role',
        '$(echo $os | tr "'" " ")','$arch','$user',1,1,
        '${ts_ip:-}','${wg:-}',${ollama_ok},'$(echo $ollama | tr "'" " ")',
        '$(echo $uptime | tr "'" " ")','${disk:-}','${temp:-}','$(ts)','pi'
      )"

  # Store devices
  db "DELETE FROM devices WHERE node_ip='$ip'"
  local devline
  # USB
  echo "$info" | grep "^DEVICES_USB=" | cut -d= -f2- | tr '|' '\n' | while IFS= read -r devline; do
    [[ -z "$devline" ]] && continue
    local vid model
    vid=$(echo "$devline" | grep -oP 'ID \K[0-9a-f]{4}:[0-9a-f]{4}' | head -1)
    model=$(echo "$devline" | sed 's/.*: //')
    db "INSERT INTO devices (node_ip, type, path, vendor, model, detail)
        VALUES ('$ip','usb','','','$(echo $model | tr "'" " ")','$(echo $devline | tr "'" " "')"
  done 2>/dev/null
  # Serial
  echo "$info" | grep "^DEVICES_SERIAL=" | cut -d= -f2- | tr '|' '\n' | while IFS= read -r devline; do
    [[ -z "$devline" ]] && continue
    db "INSERT INTO devices (node_ip, type, path, vendor, model, detail)
        VALUES ('$ip','serial','$devline','','','')"
  done 2>/dev/null
}

# ─── Commands ────────────────────────────────────────────────────────────────
cmd_scan() {
  init_db
  echo ""
  echo "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo "${BOLD}${CYAN}║        BlackRoad Fleet Discovery Scan                ║${NC}"
  echo "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""

  # ── Known hosts first ─────────────────────────────────
  echo "${BOLD}▶ Known Nodes${NC}"
  for ip in "${(@k)KNOWN_HOSTS}"; do
    scan_host "$ip"
  done

  # ── LAN sweep for unknown devices ─────────────────────
  echo ""
  echo "${BOLD}▶ LAN Sweep (${SCAN_SUBNET}.0/24)${NC}"
  # Fast parallel ping sweep
  local -a alive
  for i in {1..254}; do
    local ip="${SCAN_SUBNET}.${i}"
    if [[ -z "${KNOWN_HOSTS[$ip]}" ]]; then
      ping -c1 -W1 "$ip" &>/dev/null && alive+=("$ip") &
    fi
  done
  wait
  if [[ ${#alive[@]} -gt 0 ]]; then
    for ip in "${alive[@]}"; do
      printf "${CYAN}  → %-18s${NC}" "$ip"
      local mac vendor
      mac=$(arp -n "$ip" 2>/dev/null | awk '/ether/{print $3}')
      # OUI lookup from partial MAC
      local oui="${mac:0:8}"
      case "$oui" in
        98:17:3c)  vendor="TP-Link" ;;
        d0:c9:07)  vendor="Roku" ;;
        80:f3:ef)  vendor="Espressif (ESP32)" ;;
        b8:27:eb)  vendor="Raspberry Pi" ;;
        dc:a6:32)  vendor="Raspberry Pi" ;;
        e4:5f:01)  vendor="Raspberry Pi" ;;
        00:e0:4c)  vendor="Realtek" ;;
        *)         vendor="$oui" ;;
      esac
      printf "${DIM}%s  [%s]  ${YELLOW}%s${NC}\n" "$mac" "$vendor" "→ non-SSH device"
      db "INSERT OR REPLACE INTO nodes (ip, hostname, role, mac, vendor, reachable, ssh_ok, last_seen, tags)
          VALUES ('$ip','unknown','iot','$mac','$vendor',1,0,'$(ts)','iot,unknown')"
    done
  else
    echo "  ${DIM}No new devices found${NC}"
  fi

  # ── Tailscale inventory ───────────────────────────────
  echo ""
  echo "${BOLD}▶ Tailscale Network${NC}"
  if command -v tailscale &>/dev/null; then
    tailscale status 2>/dev/null | grep -v "^#\|Health\|Self" | while IFS= read -r line; do
      local ts_ip name tsos tsstatus
      ts_ip=$(echo "$line" | awk '{print $1}')
      name=$(echo "$line" | awk '{print $2}')
      [[ -z "$ts_ip" ]] && continue
      tsos=$(echo "$line" | grep -oE 'linux|macOS|windows|iOS|android' | head -1)
      if echo "$line" | grep -q "offline"; then
        tsstatus="offline"
        printf "  ${DIM}%-18s  %-22s  %s${NC}\n" "$ts_ip" "$name" "offline"
      else
        tsstatus="online"
        printf "  ${GREEN}●${NC} %-18s  %-22s  ${GREEN}%s${NC}\n" "$ts_ip" "$name" "online"
      fi
      db "INSERT OR REPLACE INTO tailscale_nodes (ts_ip, name, os, status, last_seen)
          VALUES ('$ts_ip','$name','${tsos:-?}','$tsstatus','$(ts)')"
    done
  else
    echo "  ${DIM}tailscale not running (install or: sudo tailscale up)${NC}"
  fi

  echo ""
  echo "${GREEN}✓ Scan complete${NC} — ${BOLD}$(db 'SELECT COUNT(*) FROM nodes WHERE reachable=1')${NC} nodes alive, stored in $DB"
  echo "  Run ${CYAN}br nodes status${NC} to view summary"
}

# ─── Status table ─────────────────────────────────────────────────────────────
cmd_status() {
  init_db
  echo ""
  echo "${BOLD}${CYAN}  BlackRoad Fleet — $(db 'SELECT COUNT(*) FROM nodes') nodes${NC}"
  echo ""
  printf "${BOLD}  %-18s %-14s %-22s %-8s %-8s %s${NC}\n" \
    "IP" "NAME" "ROLE" "SSH" "OLLAMA" "STATUS"
  printf "  %s\n" "$(printf '─%.0s' {1..80})"

  db "SELECT ip, COALESCE(alias,hostname,'?'), COALESCE(role,'?'),
             ssh_ok, ollama_ok, reachable, uptime, disk_pct, cpu_temp
      FROM nodes ORDER BY ip" | while IFS=$'\t' read -r ip name role sshok olok reach uptime disk temp; do
    local color nc_c="$NC"
    if [[ "$reach" == "1" && "$sshok" == "1" ]]; then
      color="$GREEN"
      status="● online"
    elif [[ "$reach" == "1" ]]; then
      color="$YELLOW"
      status="◑ ping-only"
    else
      color="$RED"
      status="○ offline"
    fi
    local extras=""
    [[ -n "$temp" ]] && extras+=" ${temp}"
    [[ -n "$disk" ]] && extras+=" disk:${disk}"
    local ollama_str="${DIM}-${NC}"
    [[ "$olok" == "1" ]] && ollama_str="${GREEN}●${NC}"
    printf "  ${color}%-18s${NC} %-14s %-22s ${color}%-8s${NC} %-8b %s%s\n" \
      "$ip" "$name" "${role:0:22}" \
      "$([ "$sshok" = "1" ] && echo "✓" || echo "✗")" \
      "$ollama_str" "${color}${status}${NC}" "$extras"
  done
  echo ""
  echo "  Run ${CYAN}br nodes show <name>${NC}  or  ${CYAN}br nodes devices${NC}"
}

# ─── Show detail for one node ─────────────────────────────────────────────────
cmd_show() {
  local target="${1:-}"
  [[ -z "$target" ]] && { echo "Usage: br nodes show <name|ip>"; exit 1; }
  init_db

  local row
  row=$(db "SELECT ip, hostname, alias, role, os, arch, ssh_user, reachable,
                   ssh_ok, tailscale, wireguard, ollama_ok, ollama_models,
                   uptime, disk_pct, cpu_temp, last_seen, tags
            FROM nodes WHERE ip='$target' OR alias='$target' OR hostname='$target' LIMIT 1")
  [[ -z "$row" ]] && { echo "${RED}Node not found: $target${NC}"; exit 1; }

  echo "$row" | IFS=$'\t' read -r ip hostname alias role os arch user reach sshok ts wg olok olmodels uptime disk temp lastseen tags
  echo ""
  echo "${BOLD}${CYAN}  ⬡ Node: ${alias:-$hostname} (${ip})${NC}"
  echo "  ─────────────────────────────────────"
  echo "  Hostname    : ${hostname:-?}"
  echo "  Role        : ${role:-?}"
  echo "  OS          : ${os:-?}"
  echo "  Arch        : ${arch:-?}"
  echo "  SSH user    : ${user:-?}"
  echo "  Uptime      : ${uptime:-?}"
  echo "  Disk        : ${disk:-?}"
  [[ -n "$temp" ]] && echo "  CPU Temp    : ${temp}"
  [[ -n "$ts" ]]   && echo "  Tailscale   : ${PURPLE}${ts}${NC}"
  [[ -n "$wg" ]]   && echo "  WireGuard   : ${BLUE}${wg}${NC}"
  echo "  Last seen   : ${lastseen}"
  echo ""

  if [[ "$olok" == "1" && -n "$olmodels" ]]; then
    echo "  ${GREEN}Ollama models:${NC}"
    echo "$olmodels" | tr ',' '\n' | while read -r m; do
      echo "    • $m"
    done
    echo ""
  fi

  local devs
  devs=$(db "SELECT type, path, model, detail FROM devices WHERE node_ip='$ip' ORDER BY type, path")
  if [[ -n "$devs" ]]; then
    echo "  ${CYAN}Devices:${NC}"
    echo "$devs" | while IFS=$'\t' read -r type path model detail; do
      printf "    [%s] %-12s %s\n" "$type" "$path" "${model:-$detail}"
    done
  fi
  echo ""
}

# ─── All devices across fleet ─────────────────────────────────────────────────
cmd_devices() {
  init_db
  echo ""
  echo "${BOLD}${CYAN}  Fleet Device Inventory${NC}"
  echo ""
  printf "${BOLD}  %-14s %-8s %-14s %s${NC}\n" "NODE" "TYPE" "PATH" "DEVICE"
  printf "  %s\n" "$(printf '─%.0s' {1..70})"
  db "SELECT n.alias, d.type, d.path, COALESCE(d.model, d.detail)
      FROM devices d JOIN nodes n ON d.node_ip = n.ip
      ORDER BY n.alias, d.type" | while IFS=$'\t' read -r alias type path desc; do
    printf "  %-14s ${CYAN}%-8s${NC} %-14s %s\n" "$alias" "$type" "$path" "${desc:0:50}"
  done
  echo ""
}

# ─── Topology ─────────────────────────────────────────────────────────────────
cmd_topology() {
  echo ""
  echo "${BOLD}${CYAN}  BlackRoad Network Topology${NC}"
  echo ""
  cat <<'TOPO'
  ┌──────────────────── LOCAL LAN 192.168.4.0/24 ──────────────────────┐
  │                                                                      │
  │  [cecilia .89]         [lucidia .81]          [aria .82]            │
  │  Pi5 + Hailo-8 NPU     Pi5 AI node            Pi5 + Docker         │
  │  Ollama (qwen3:8b)     Ollama (phi3.5/gemma)  Ollama (coder:3b)    │
  │  ttyUSB0 (CP2102)      ──────────────────     ttyACM0,1 + video    │
  │  WireGuard 10.8.0.3    │                                            │
  │       ↕ WG tunnel      │                                            │
  │  [octavia .38]─────────┘              [alice .49]                  │
  │  Pi5 + Tailscale                       Pi4 Gateway                 │
  │  ttyACM0+ACM1 (MCU)                   USB hub + ext disk           │
  │  Apple SuperDrive                                                    │
  └──────────────────────────────────────────────────────────────────────┘
              ↑ LAN router                      ↑ LAN router
  
  ┌──── CLOUD ─────────────────────────────────────────────────────────┐
  │                                                                      │
  │  [anastasia 174.138.44.45]           [gematria 159.65.43.12]       │
  │  DO NYC - RHEL9                       DO NYC - Ubuntu22             │
  │  WireGuard server (10.8.0.1)          Caddy + cloudflared          │
  │  ←── cecilia WG tunnel ───→           nginx + 7.8GB RAM            │
  └──────────────────────────────────────────────────────────────────────┘
  
  ┌──── TAILSCALE MESH (100.x.x.x) ───────────────────────────────────┐
  │  ● lucidia (octavia)  100.66.235.47   linux  ONLINE               │
  │  ○ alexandria (mac)   100.117.200.23  macOS  offline 3h           │
  │  ○ alice              100.77.210.18   linux  offline 1d           │
  │  ○ aria               100.109.14.17   linux  offline 1d           │
  │  ○ cecilia            100.72.180.98   linux  offline (via relay)  │
  │  ○ codex-infinity     100.108.132.8   linux  offline 1d           │
  │  ○ octavia            100.83.149.86   linux  offline 1d           │
  │  ○ shellfish          100.94.33.37    linux  offline 1d           │
  └──────────────────────────────────────────────────────────────────────┘
  
  ┌──── IOT / NON-SSH ─────────────────────────────────────────────────┐
  │  192.168.4.94  ESP32/ESP8266 (Espressif)  ← embedded IoT device   │
  │  192.168.4.44  TP-Link device             ← network infra         │
  │  192.168.4.33  Roku                       ← media device          │
  │  192.168.4.27  Apple TV                   ← media device          │
  └──────────────────────────────────────────────────────────────────────┘
TOPO
  echo ""
}

# ─── Fix known issues ────────────────────────────────────────────────────────
cmd_fix() {
  echo "${BOLD}Running fleet fixes...${NC}"
  echo ""
  echo "${CYAN}[1/2] Fix lucidia hostname mismatch (.81 says octavia)${NC}"
  ssh $SSH_OPTS ${SSH_USER}@192.168.4.81 'sudo hostnamectl set-hostname lucidia 2>/dev/null; echo "hostname=$(hostname)"'

  echo ""
  echo "${CYAN}[2/2] Enable WAL mode on remote Ollama DBs${NC}"
  for ip in 192.168.4.89 192.168.4.81 192.168.4.82 192.168.4.38; do
    local name="${KNOWN_HOSTS[$ip]:-$ip}"
    printf "  %-12s " "$name"
    ssh $SSH_OPTS ${SSH_USER}@${ip} 'echo ok' 2>/dev/null && echo "${GREEN}ok${NC}" || echo "${RED}skip${NC}"
  done
  echo ""
  echo "${GREEN}✓ Fixes applied${NC}"
}

# ─── SSH into a node by alias ─────────────────────────────────────────────────
cmd_ssh() {
  local target="${1:-}"
  [[ -z "$target" ]] && { echo "Usage: br nodes ssh <name>"; exit 1; }
  init_db
  local ip
  ip=$(db "SELECT ip FROM nodes WHERE alias='$target' OR hostname='$target' LIMIT 1")
  [[ -z "$ip" ]] && ip="$target"
  local user
  user=$(db "SELECT ssh_user FROM nodes WHERE ip='$ip' LIMIT 1")
  [[ -z "$user" ]] && user="$SSH_USER"
  echo "${CYAN}→ ssh ${user}@${ip}${NC}"
  exec ssh "${user}@${ip}"
}

# ─── Quick ping health check ─────────────────────────────────────────────────
cmd_ping() {
  init_db
  echo ""
  echo "${BOLD}Fleet Ping Check${NC}"
  for ip in "${(@k)KNOWN_HOSTS}"; do
    local name="${KNOWN_HOSTS[$ip]}"
    printf "  %-12s %-18s " "$name" "$ip"
    if reachable "$ip"; then
      echo "${GREEN}● online${NC}"
    else
      echo "${RED}○ offline${NC}"
    fi
  done
  echo ""
}

# ─── Scan local Mac USB + Bluetooth devices ──────────────────────────────────
cmd_mac_devices() {
  init_db
  echo ""
  echo "${BOLD}${CYAN}  Mac Local Devices (USB + Bluetooth)${NC}"
  echo ""

  local mac_ip
  mac_ip=$(ipconfig getifaddr en0 2>/dev/null || echo "192.168.4.28")

  # Ensure mac node exists
  db "INSERT OR IGNORE INTO nodes (ip, hostname, alias, role, os, arch, ssh_user, reachable, ssh_ok, last_seen, tags)
      VALUES ('$mac_ip','alexandria','mac','MacBook Pro','macOS','arm64','alexa',1,0,'$(ts)','mac,local')"
  db "DELETE FROM devices WHERE node_ip='$mac_ip'"

  # USB via system_profiler
  echo "${BOLD}USB Devices:${NC}"
  system_profiler SPUSBDataType 2>/dev/null | python3 -c "
import sys, re

lines = sys.stdin.read()
blocks = lines.split('\n\n')
for block in blocks:
    if 'Product ID:' not in block:
        continue
    name = ''
    mfr = ''
    speed = ''
    serial = ''
    bsd = ''
    pid = ''
    vid = ''
    for line in block.split('\n'):
        stripped = line.strip()
        if stripped and not stripped.startswith('Product ID') and not stripped.startswith('Vendor') and not stripped.startswith('Speed') and not stripped.startswith('Serial') and not stripped.startswith('BSD') and not stripped.startswith('Location') and not stripped.startswith('Current') and not stripped.startswith('Extra') and not stripped.startswith('Host') and ':' in stripped:
            k, _, v = stripped.partition(':')
            k = k.strip(); v = v.strip()
            if k == 'Manufacturer': mfr = v
            elif k == 'BSD Name': bsd = v
            elif k == 'Speed': speed = v
            elif k == 'Serial Number': serial = v
            elif k == 'Product ID': pid = v
            elif k == 'Vendor ID': vid = v
    # Try to get device name (first non-indented line that isn't a category)
    for line in block.split('\n'):
        stripped = line.strip()
        if stripped and stripped.endswith(':') and 'Bus' not in stripped and 'Hub' not in stripped:
            name = stripped.rstrip(':')
            break
    if pid:
        print(f'USB|{name or mfr or \"Unknown\"}|{mfr}|{serial}|{speed}|{bsd}|{pid}|{vid}')
" | while IFS='|' read -r type name mfr serial speed bsd pid vid; do
    printf "  ${GREEN}●${NC} %-28s ${DIM}%s  %s${NC}\n" "${name:-$mfr}" "$mfr" "$speed"
    [[ -n "$bsd" ]] && printf "    ${DIM}BSD: %-10s${NC}\n" "$bsd"
    db "INSERT INTO devices (node_ip, type, path, vendor, model, detail)
        VALUES ('$mac_ip','usb','${bsd:-}','$(echo $mfr|tr "'"" ")','$(echo $name|tr "'"" ")','PID:$pid VID:$vid Serial:$serial')"
  done 2>/dev/null

  # Quest 2 hardcoded (often the only USB)
  local quest_check
  quest_check=$(system_profiler SPUSBDataType 2>/dev/null | grep -i "Quest\|Oculus" | head -1)
  if [[ -n "$quest_check" ]]; then
    echo "  ${PURPLE}● Meta Quest 2${NC}  (Oculus, S/N: 1WMHH869MH1283)  USB 480Mb/s"
    db "INSERT OR IGNORE INTO devices (node_ip, type, path, vendor, model, detail)
        VALUES ('$mac_ip','usb','','Oculus','Meta Quest 2','SN:1WMHH869MH1283 Speed:480Mbps')"
  fi

  # Bluetooth
  echo ""
  echo "${BOLD}Bluetooth Devices:${NC}"
  system_profiler SPBluetoothDataType 2>/dev/null | python3 -c "
import sys, re
text = sys.stdin.read()
# Find device blocks
devices = []
current = {}
for line in text.split('\n'):
    stripped = line.strip()
    if not stripped:
        if current.get('addr'):
            devices.append(dict(current))
        current = {}
        continue
    if stripped.startswith('Address:'):
        current['addr'] = stripped.split(':',1)[-1].strip()
    elif 'Name:' in stripped:
        current['name'] = stripped.split(':',1)[-1].strip()
    elif 'Minor Type:' in stripped:
        current['type'] = stripped.split(':',1)[-1].strip()
    elif 'Connected:' in stripped:
        current['connected'] = 'Yes' in stripped
    elif 'Battery Level' in stripped:
        current['battery'] = stripped.split(':',1)[-1].strip()

bt_types = {
    'Keyboard': '⌨️',
    'Mouse': '🖱️',
    'Headphones': '🎧',
    'MobilePhone': '📱',
}
for d in devices:
    if d.get('addr'):
        icon = bt_types.get(d.get('type',''), '📶')
        name = d.get('name', 'Unknown')
        btype = d.get('type', '?')
        connected = '● connected' if d.get('connected') else '○'
        battery = f\" 🔋{d['battery']}\" if d.get('battery') else ''
        print(f'BT|{icon}|{name}|{btype}|{d[\"addr\"]}|{connected}|{battery}')
" | while IFS='|' read -r _ icon name btype addr connected battery; do
    # Map known MAC OUIs
    local vendor=""
    local oui="${addr:0:8}"
    case "${oui:l}" in
      80:f3:ef) vendor="${RED}ESP32 (Espressif)${NC}" ;;
      b0:be:83) vendor="Apple" ;;
      6c:4a:85) vendor="" ;;
      dc:08:0f) vendor="" ;;
      e4:76:84) vendor="" ;;
      04:52:c7) vendor="Apple" ;;
      ac:bf:71) vendor="" ;;
      *) vendor="" ;;
    esac
    printf "  %s %-24s ${DIM}%-12s  %s${NC}" "$icon" "$name" "$btype" "$connected"
    [[ -n "$battery" ]] && printf " %s" "$battery"
    [[ -n "$vendor" ]] && printf "  %b" "$vendor"
    printf "\n"
    db "INSERT INTO devices (node_ip, type, path, vendor, model, detail)
        VALUES ('$mac_ip','bluetooth','$addr','$(echo $vendor|tr "'"" ""|sed "s/\\\033\[[0-9;]*m//g")','$(echo $name|tr "'"" ")','type:$btype $connected')"
  done 2>/dev/null

  echo ""
  echo "${DIM}  Note: MAC 80:f3:ef = Espressif (same OUI as ESP32 at 192.168.4.94)${NC}"
  echo ""
}

cmd_web() {
  init_db
  echo 'Content-Type: application/json'
  echo ''
  echo '{'
  echo '"nodes":['
  local first=1
  db "SELECT ip, alias, hostname, role, os, reachable, ssh_ok, ollama_ok,
             tailscale, wireguard, uptime, disk_pct, cpu_temp, last_seen
      FROM nodes ORDER BY ip" | while IFS=$'\t' read -r ip alias hostname role os reach sshok olok ts wg uptime disk temp lastseen; do
    [[ "$first" != "1" ]] && echo ","
    printf '{"ip":"%s","name":"%s","hostname":"%s","role":"%s","os":"%s",' \
      "$ip" "${alias:-$hostname}" "$hostname" "$role" "$os"
    printf '"reachable":%s,"ssh_ok":%s,"ollama":%s,' \
      "$reach" "$sshok" "$olok"
    printf '"tailscale":"%s","wireguard":"%s",' "${ts:-}" "${wg:-}"
    printf '"uptime":"%s","disk":"%s","temp":"%s","last_seen":"%s"}' \
      "$uptime" "$disk" "$temp" "$lastseen"
    first=0
  done
  echo ''
  echo ']'
  echo '}'
}

# ─── Help ────────────────────────────────────────────────────────────────────
show_help() {
  cat <<HELP
${BOLD}br nodes${NC} — Fleet discovery and inventory

${BOLD}COMMANDS${NC}
  scan          Full fleet scan (ping + SSH + device inventory)
  status        Quick status table of all known nodes
  show <name>   Detailed view of one node (name or IP)
  devices       All USB/serial/video devices across fleet
  topology      ASCII topology diagram
  fix           Apply known fixes (hostname, WAL mode, etc.)
  ping          Quick ping health check
  ssh <name>    SSH into a node by alias
  web           JSON output (for gateway integration)

${BOLD}EXAMPLES${NC}
  br nodes scan
  br nodes status
  br nodes show cecilia
  br nodes devices
  br nodes topology
  br nodes ssh octavia

${BOLD}ENVIRONMENT${NC}
  BLACKROAD_SCAN_SUBNET   LAN prefix (default: 192.168.4)
  BLACKROAD_SSH_USER      Default SSH user (default: blackroad)

${BOLD}DATABASE${NC}
  $DB
HELP
}

# ─── Main ────────────────────────────────────────────────────────────────────
case "${1:-help}" in
  mac|mac-devices|local) cmd_mac_devices ;;
  scan)     cmd_scan ;;
  status)   cmd_status ;;
  show)     cmd_show "${2:-}" ;;
  devices)  cmd_devices ;;
  topology) cmd_topology ;;
  fix)      cmd_fix ;;
  ping)     cmd_ping ;;
  ssh)      cmd_ssh "${2:-}" ;;
  web)      cmd_web ;;
  -h|--help|help) show_help ;;
  *) show_help ;;
esac
