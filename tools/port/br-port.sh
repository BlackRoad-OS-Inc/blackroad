#!/bin/zsh
# BR PORT - Port scanner, process finder, and port manager

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
RED='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'

DB_FILE="$HOME/.blackroad/port.db"

init_db() {
  mkdir -p "$(dirname $DB_FILE)"
  sqlite3 "$DB_FILE" <<'SQL'
CREATE TABLE IF NOT EXISTS watched_ports (
  port INTEGER PRIMARY KEY, name TEXT, expected_pid TEXT, notes TEXT
);
CREATE TABLE IF NOT EXISTS port_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  port INTEGER, pid TEXT, process TEXT, action TEXT,
  ts TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

# BlackRoad well-known ports
_KNOWN_PORTS=(
  "3000:Next.js dev"
  "3001:Storybook"
  "4000:Docusaurus"
  "5432:PostgreSQL"
  "6379:Redis"
  "8000:FastAPI/Django"
  "8080:Gateway (br-gateway)"
  "8787:Gateway alt"
  "8888:Jupyter"
  "11434:Ollama"
  "27017:MongoDB"
  "5000:Flask"
  "4200:Angular"
  "5173:Vite"
)

_port_name() {
  local p="$1"
  for entry in "${_KNOWN_PORTS[@]}"; do
    local port="${entry%%:*}"
    local name="${entry##*:}"
    [[ "$port" == "$p" ]] && echo "$name" && return
  done
  echo "—"
}

cmd_list() {
  echo ""
  echo -e "${BOLD}${CYAN}🔌 Active listening ports:${NC}"
  echo ""
  printf "  %-8s %-8s %-30s %-20s\n" "PORT" "PID" "PROCESS" "KNOWN AS"
  echo "  ────────────────────────────────────────────────────────────────"
  lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1 {print $9, $2, $1}' | sort -t: -k2 -n | \
    while read addr pid proc; do
      local port="${addr##*:}"
      local name
      name=$(_port_name "$port")
      printf "  %-8s %-8s %-30s %-20s\n" "$port" "$pid" "$proc" "$name"
    done
  echo ""
}

cmd_check() {
  local port="$1"
  [[ -z "$port" ]] && { echo "Usage: br port check <port>"; return 1; }

  local result
  result=$(lsof -iTCP:"$port" -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1 {print $2, $1, $9}' | head -1)

  if [[ -z "$result" ]]; then
    echo -e "  ${YELLOW}Port ${port}:${NC} ${GREEN}free${NC}"
  else
    local pid proc addr
    pid=$(echo "$result" | awk '{print $1}')
    proc=$(echo "$result" | awk '{print $2}')
    addr=$(echo "$result" | awk '{print $3}')
    local name=$(_port_name "$port")
    echo -e "  ${RED}Port ${port}:${NC} in use by ${BOLD}${proc}${NC} (PID ${pid})  ${addr}"
    [[ "$name" != "—" ]] && echo -e "  ${CYAN}Known as:${NC} ${name}"
  fi
}

cmd_kill() {
  local port="$1"
  [[ -z "$port" ]] && { echo "Usage: br port kill <port>"; return 1; }

  local pid
  pid=$(lsof -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -1)

  if [[ -z "$pid" ]]; then
    echo -e "  ${YELLOW}Nothing on port ${port}${NC}"; return
  fi

  local proc=$(ps -p "$pid" -o comm= 2>/dev/null)
  echo -ne "  ${YELLOW}Kill ${proc} (PID ${pid}) on port ${port}? [y/N]: ${NC}"
  local choice; read -r choice
  if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    kill "$pid" 2>/dev/null && echo -e "  ${GREEN}✓ Sent TERM to PID ${pid}${NC}" || echo -e "  ${RED}✗ Could not send signal${NC}"
    sqlite3 "$DB_FILE" "INSERT INTO port_history(port,pid,process,action) VALUES('$port','$pid','$proc','kill');"
  else
    echo -e "  ${YELLOW}Cancelled${NC}"
  fi
}

cmd_find() {
  local query="$1"
  [[ -z "$query" ]] && { echo "Usage: br port find <name|pid>"; return 1; }

  echo ""
  echo -e "${BOLD}${CYAN}Ports matching '${query}':${NC}"
  echo ""
  lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1' | grep -i "$query" | \
    while read line; do
      local proc=$(echo "$line" | awk '{print $1}')
      local pid=$(echo "$line" | awk '{print $2}')
      local addr=$(echo "$line" | awk '{print $9}')
      local port="${addr##*:}"
      echo -e "  ${CYAN}:${port}${NC}  pid=${pid}  ${proc}"
    done
  echo ""
}

cmd_blackroad() {
  # show status of all blackroad-known ports
  echo ""
  echo -e "${BOLD}${CYAN}BlackRoad service ports:${NC}"
  echo ""
  local pid proc
  for entry in "${_KNOWN_PORTS[@]}"; do
    local port="${entry%%:*}"
    local name="${entry##*:}"
    pid=$(lsof -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -1)
    if [[ -n "$pid" ]]; then
      proc=$(ps -p "$pid" -o comm= 2>/dev/null)
      echo -e "  ${GREEN}●${NC} :${port}  ${BOLD}${name}${NC}  (pid=${pid} ${proc})"
    else
      echo -e "  ${YELLOW}○${NC} :${port}  ${name}"
    fi
  done
  echo ""
}

cmd_watch() {
  local interval="${1:-5}"
  echo -e "${CYAN}Watching ports every ${interval}s — Ctrl+C to stop${NC}"
  while true; do
    clear
    cmd_blackroad
    sleep "$interval"
  done
}

cmd_help() {
  echo ""
  echo -e "${BOLD}br port${NC} — port scanner and process manager"
  echo ""
  echo "  ${CYAN}br port list${NC}             All listening ports + processes"
  echo "  ${CYAN}br port check <port>${NC}     Is this port in use?"
  echo "  ${CYAN}br port find <name>${NC}      Find ports by process name"
  echo "  ${CYAN}br port kill <port>${NC}      Stop process on port (interactive)"
  echo "  ${CYAN}br port services${NC}         BlackRoad service ports status"
  echo "  ${CYAN}br port watch [N]${NC}        Refresh every N seconds"
  echo ""
}

case "${1:-services}" in
  list)         cmd_list ;;
  check)        shift; cmd_check "$@" ;;
  find)         shift; cmd_find "$@" ;;
  kill)         shift; cmd_kill "$@" ;;
  services|br)  cmd_blackroad ;;
  watch)        shift; cmd_watch "$@" ;;
  help|-h)      cmd_help ;;
  *) cmd_check "$1" ;;
esac
