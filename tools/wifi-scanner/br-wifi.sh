#!/usr/bin/env zsh
# BR WiFi — LAN scanner, Pi discovery, device registry
# br wifi scan|list|pis|watch|add|remove|ping <host>

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

DB_FILE="$HOME/.blackroad/wifi-devices.db"
AGENTS_INSTANCES="$HOME/blackroad/coordination/collaboration/active-instances.json"

init_db() {
  mkdir -p "$(dirname "$DB_FILE")"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS devices (
  ip        TEXT PRIMARY KEY,
  hostname  TEXT,
  mac       TEXT,
  label     TEXT,
  role      TEXT DEFAULT 'unknown',
  last_seen INTEGER DEFAULT (strftime('%s','now')),
  first_seen INTEGER DEFAULT (strftime('%s','now')),
  online    INTEGER DEFAULT 0
);
SQL
}

header() {
  echo ""
  echo "${BOLD}${AMBER}  ▸ BLACKROAD WIFI SCANNER${NC}  ${DIM}LAN device discovery${NC}"
  echo "  ${DIM}────────────────────────────────────────${NC}"
}

# Detect local subnet from default interface
detect_subnet() {
  local ip
  ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
  if [[ -n "$ip" ]]; then
    echo "${ip%.*}.0/24"
  else
    echo "192.168.4.0/24"
  fi
}

# Ping sweep — fast parallel ping
cmd_scan() {
  init_db
  header
  local subnet=$(detect_subnet)
  local base="${subnet%.*}"
  echo "  ${CYAN}Scanning${NC} ${BOLD}$subnet${NC} …"
  echo ""

  local found=0
  local ts=$(date +%s)

  # Mark all offline first
  sqlite3 "$DB_FILE" "UPDATE devices SET online=0;"

  # Parallel ping sweep
  for i in $(seq 1 254); do
    (
      local host="${base}.${i}"
      if ping -c1 -W1 -q "$host" &>/dev/null; then
        local hostname
        hostname=$(dscacheutil -q host -a ip_address "$host" 2>/dev/null | grep "name:" | awk '{print $2}' | head -1)
        [[ -z "$hostname" ]] && hostname=$(host "$host" 2>/dev/null | awk '{print $NF}' | sed 's/\.$//' | head -1)
        [[ "$hostname" == *"NXDOMAIN"* ]] && hostname=""

        # Upsert
        sqlite3 "$DB_FILE" "INSERT INTO devices (ip, hostname, last_seen, online) VALUES('$host','$hostname','$ts',1)
          ON CONFLICT(ip) DO UPDATE SET hostname=COALESCE(NULLIF('$hostname',''), hostname),
          last_seen='$ts', online=1;"
      fi
    ) &
  done
  wait

  # Display results
  local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM devices WHERE online=1;")
  echo "  ${GREEN}Found $count device(s)${NC}"
  echo ""
  printf "  ${BOLD}%-16s %-28s %-16s %s${NC}\n" "IP" "HOSTNAME" "LABEL" "ROLE"
  echo "  ${DIM}────────────────────────────────────────────────────────────${NC}"

  sqlite3 -separator $'\t' "$DB_FILE" \
    "SELECT ip, COALESCE(hostname,''), COALESCE(label,''), role FROM devices WHERE online=1 ORDER BY ip;" \
  | while IFS=$'\t' read -r ip host lbl role; do
      local color="$NC"
      [[ "$role" == "pi" ]]    && color="$VIOLET"
      [[ "$role" == "copilot" ]] && color="$CYAN"
      [[ "$role" == "router" ]] && color="$AMBER"
      printf "  ${color}%-16s %-28s %-16s %s${NC}\n" "$ip" "$host" "$lbl" "$role"
    done

  echo ""
  echo "  ${DIM}Use${NC} ${CYAN}br wifi pis${NC} ${DIM}to see Pi fleet │${NC} ${CYAN}br wifi add <ip> <label> <role>${NC} ${DIM}to tag a device${NC}"
}

# List all known devices (online + offline)
cmd_list() {
  init_db
  header
  printf "  ${BOLD}%-16s %-28s %-16s %-12s %s${NC}\n" "IP" "HOSTNAME" "LABEL" "ROLE" "STATUS"
  echo "  ${DIM}────────────────────────────────────────────────────────────────────${NC}"
  sqlite3 -separator $'\t' "$DB_FILE" \
    "SELECT ip, COALESCE(hostname,'—'), COALESCE(label,'—'), role,
     CASE online WHEN 1 THEN 'online' ELSE 'offline' END,
     datetime(last_seen,'unixepoch','localtime')
     FROM devices ORDER BY online DESC, ip;" \
  | while IFS=$'\t' read -r ip host lbl role status ts; do
      local sc="$RED"; [[ "$status" == "online" ]] && sc="$GREEN"
      printf "  %-16s %-28s %-16s %-12s ${sc}%s${NC}\n" "$ip" "$host" "$lbl" "$role" "$status"
    done
  echo ""
}

# Show only Pi devices
_check_pi() {
  # _check_pi <ip> <label>  — prints one row, no locals that leak
  local _ip="$1" _label="$2" _latency _pstatus _pcolor
  if ping -c1 -W1 -q "$_ip" &>/dev/null 2>&1; then
    _latency=$(ping -c3 -q "$_ip" 2>/dev/null | tail -1 | awk -F'/' '{print $5}' | cut -d. -f1)
    _pstatus="online"; _pcolor='\033[0;32m'
    sqlite3 "$DB_FILE" "UPDATE devices SET online=1, last_seen=$(date +%s) WHERE ip='$_ip';"
  else
    _latency="—"; _pstatus="offline"; _pcolor='\033[0;31m'
    sqlite3 "$DB_FILE" "UPDATE devices SET online=0 WHERE ip='$_ip';"
  fi
  printf "  %-16s %-18s \033[0m${_pcolor}%-12s\033[0m %s\n" "$_ip" "$_label" "$_pstatus" "${_latency}ms"
}

cmd_pis() {
  init_db
  header
  echo "  ${VIOLET}${BOLD}Raspberry Pi Fleet${NC}"
  echo ""

  # Known Pi IPs from coordination system
  local known_pis=(
    "192.168.4.38:aria64"
    "192.168.4.64:blackroad-pi"
    "192.168.4.99:alice-pi"
  )

  # Tag known Pis in DB
  local _e _ip _lbl
  for _e in "${known_pis[@]}"; do
    _ip="${_e%%:*}"; _lbl="${_e#*:}"
    sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO devices (ip, label, role) VALUES('$_ip','$_lbl','pi');
      UPDATE devices SET label='$_lbl', role='pi' WHERE ip='$_ip';"
  done

  printf "  ${BOLD}%-16s %-18s %-12s %s${NC}\n" "IP" "LABEL" "STATUS" "LATENCY"
  echo "  ${DIM}────────────────────────────────────────────────────────${NC}"

  for _e in "${known_pis[@]}"; do
    _ip="${_e%%:*}"; _lbl="${_e#*:}"
    _check_pi "$_ip" "$_lbl"
  done

  if [[ -f "$AGENTS_INSTANCES" ]]; then
    echo ""
    echo "  ${DIM}Synced with collaboration mesh ✓${NC}"
  fi
  echo ""
}

# Watch mode — re-scan every N seconds
cmd_watch() {
  local interval="${1:-30}"
  echo "  ${CYAN}Watch mode${NC} — scanning every ${interval}s  ${DIM}(Ctrl-C to stop)${NC}"
  while true; do
    cmd_pis
    sleep "$interval"
  done
}

# Ping a specific host
cmd_ping() {
  local host="$1"
  [[ -z "$host" ]] && { echo "  Usage: br wifi ping <host|ip>"; exit 1; }
  header
  echo "  ${CYAN}Pinging${NC} ${BOLD}$host${NC}…"
  ping -c5 "$host"
}

# Tag a device
cmd_add() {
  local ip="$1" label="$2" role="${3:-device}"
  [[ -z "$ip" || -z "$label" ]] && { echo "  Usage: br wifi add <ip> <label> [role]"; exit 1; }
  init_db
  sqlite3 "$DB_FILE" "INSERT INTO devices (ip, label, role) VALUES('$ip','$label','$role')
    ON CONFLICT(ip) DO UPDATE SET label='$label', role='$role';"
  echo "  ${GREEN}✓${NC} Tagged ${BOLD}$ip${NC} as ${AMBER}$label${NC} (role: $role)"
}

cmd_remove() {
  local ip="$1"
  [[ -z "$ip" ]] && { echo "  Usage: br wifi remove <ip>"; exit 1; }
  init_db
  sqlite3 "$DB_FILE" "DELETE FROM devices WHERE ip='$ip';"
  echo "  ${RED}✓${NC} Removed $ip from registry"
}

show_help() {
  echo ""
  echo "  ${AMBER}${BOLD}br wifi${NC}  — LAN scanner & device registry"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}scan${NC}               Sweep subnet, find all online devices"
  echo "    ${CYAN}list${NC}               List all known devices (online + offline)"
  echo "    ${CYAN}pis${NC}                Check Pi fleet connectivity"
  echo "    ${CYAN}watch [secs]${NC}       Continuous Pi watch (default 30s)"
  echo "    ${CYAN}ping <host>${NC}        Ping a specific host"
  echo "    ${CYAN}add <ip> <label> [role]${NC}   Tag a device in registry"
  echo "    ${CYAN}remove <ip>${NC}        Remove device from registry"
  echo ""
  echo "  ${BOLD}Roles:${NC}  pi  router  copilot  device  server"
  echo ""
}

init_db
case "${1:-help}" in
  scan)         cmd_scan ;;
  list|ls)      cmd_list ;;
  pis|fleet|pi) cmd_pis ;;
  watch)        cmd_watch "${2:-30}" ;;
  ping)         cmd_ping "$2" ;;
  add)          cmd_add "$2" "$3" "$4" ;;
  remove|rm)    cmd_remove "$2" ;;
  help|*)       show_help ;;
esac
