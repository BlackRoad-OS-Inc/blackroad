#!/bin/zsh
# BR Scan - Local Network Scanner
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BLUE='\033[0;34m'; BOLD='\033[1m'

PI_NODES=("192.168.4.38:aria64" "192.168.4.49:alice" "192.168.4.64:blackroad-pi" "192.168.4.89:cecilia")
COMMON_PORTS=(22 80 443 3000 8080 8787 11434 5000 4000 9090 2222)

scan_host() {
  local ip=$1
  local alive=false
  if ping -c 1 -W 1 "$ip" &>/dev/null 2>&1; then alive=true; fi
  echo "$alive"
}

scan_ports() {
  local ip=$1
  local open_ports=()
  for port in "${COMMON_PORTS[@]}"; do
    if nc -z -w 1 "$ip" "$port" 2>/dev/null; then
      open_ports+=("$port")
    fi
  done
  echo "${open_ports[*]}"
}

cmd_pis() {
  echo -e "${CYAN}${BOLD}╔══════════════════════════════════════╗${NC}"
  echo -e "${CYAN}${BOLD}║     BR SCAN — Pi Fleet Scanner       ║${NC}"
  echo -e "${CYAN}${BOLD}╚══════════════════════════════════════╝${NC}\n"
  for entry in "${PI_NODES[@]}"; do
    local ip="${entry%%:*}"
    local name="${entry##*:}"
    printf "Scanning %-15s (%s)… " "$ip" "$name"
    local alive
    alive=$(scan_host "$ip")
    if [[ "$alive" == "true" ]]; then
      echo -e "${GREEN}● ONLINE${NC}"
      local ports
      ports=$(scan_ports "$ip")
      if [[ -n "$ports" ]]; then
        for p in $=ports; do
          local svc=""
          case $p in
            22) svc="SSH" ;; 80) svc="HTTP" ;; 443) svc="HTTPS" ;; 3000) svc="Node/Next" ;;
            8080) svc="Alt HTTP" ;; 11434) svc="Ollama" ;; 8787) svc="Gateway" ;;
            5000) svc="Flask" ;; 4000) svc="Dev" ;; 9090) svc="Prometheus" ;; 2222) svc="SSH-alt" ;;
          esac
          echo -e "  ${GREEN}✓${NC} Port ${CYAN}$p${NC} ${svc:+(${svc})}"
        done
      fi
    else
      echo -e "${RED}● OFFLINE${NC}"
    fi
  done
}

cmd_sweep() {
  local subnet="${1:-192.168.4}"
  echo -e "${CYAN}Sweeping ${subnet}.1-254…${NC}"
  local found=0
  for i in $(seq 1 254); do
    local ip="${subnet}.${i}"
    if ping -c 1 -W 1 "$ip" &>/dev/null 2>&1; then
      local hostname
      hostname=$(host "$ip" 2>/dev/null | awk '{print $NF}' | sed 's/\.$//')
      echo -e "  ${GREEN}●${NC} ${ip} ${CYAN}${hostname}${NC}"
      ((found++))
    fi
  done
  echo -e "\n${GREEN}Found ${found} hosts${NC}"
}

cmd_port() {
  local ip=$1 port=$2
  if [[ -z "$ip" || -z "$port" ]]; then
    echo -e "${RED}Usage: br scan port <ip> <port>${NC}"; exit 1
  fi
  if nc -z -w 2 "$ip" "$port" 2>/dev/null; then
    echo -e "${GREEN}✓ ${ip}:${port} is OPEN${NC}"
  else
    echo -e "${RED}✗ ${ip}:${port} is CLOSED${NC}"
  fi
}

show_help() {
  echo -e "${CYAN}${BOLD}BR Scan — Network Scanner${NC}\n"
  echo -e "  ${GREEN}br scan pis${NC}        Scan all Pi nodes + open ports"
  echo -e "  ${GREEN}br scan sweep${NC}       Ping sweep 192.168.4.0/24"
  echo -e "  ${GREEN}br scan sweep <net>${NC} Ping sweep custom subnet"
  echo -e "  ${GREEN}br scan port <ip> <p>${NC} Check single port"
}

case "${1:-help}" in
  pis|fleet) cmd_pis ;;
  sweep) cmd_sweep "$2" ;;
  port) cmd_port "$2" "$3" ;;
  *) show_help ;;
esac
