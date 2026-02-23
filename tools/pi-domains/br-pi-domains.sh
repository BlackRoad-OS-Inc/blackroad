#!/usr/bin/env zsh
# BR Pi Domains — route Cloudflare domains to Raspberry Pis via tunnel

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'

DB="$HOME/.blackroad/pi-domains.db"
CF_TUNNEL_ID="${BLACKROAD_TUNNEL_ID:-52915859-da18-4aa6-add5-7bd9fcac2e0b}"
CF_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-848cf0b18d51e0170e0d1537aec3505a}"
CF_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
CF_ZONE="${CLOUDFLARE_ZONE:-blackroad.ai}"

# Pi registry
typeset -A PI_IPS PI_ROLES PI_PORTS
PI_IPS=(
  blackroad-pi  "192.168.4.64"
  lucidia       "192.168.4.38"
  alice         "192.168.4.49"
  alt           "192.168.4.99"
)
PI_ROLES=(
  blackroad-pi  "primary — Cloudflare tunnel host"
  lucidia       "secondary — 22500 agent capacity"
  alice         "tertiary — ops node"
  alt           "alternate — backup"
)
PI_PORTS=(
  blackroad-pi  "8080"
  lucidia       "8080"
  alice         "8080"
  alt           "8080"
)

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS routes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  domain TEXT UNIQUE NOT NULL,
  pi TEXT NOT NULL,
  local_port INTEGER DEFAULT 8080,
  service TEXT DEFAULT 'http',
  description TEXT DEFAULT '',
  tunnel_id TEXT DEFAULT '',
  cf_dns_record_id TEXT DEFAULT '',
  active INTEGER DEFAULT 1,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS deploy_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  domain TEXT NOT NULL,
  action TEXT NOT NULL,
  result TEXT DEFAULT '',
  exit_code INTEGER DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
INSERT OR IGNORE INTO routes (domain, pi, local_port, service, description) VALUES
  ('agent.blackroad.ai',      'blackroad-pi', 8080, 'http', 'Agent API'),
  ('api.blackroad.ai',        'blackroad-pi', 3000, 'http', 'Main API'),
  ('lucidia.blackroad.ai',    'lucidia',      8080, 'http', 'Lucidia agent'),
  ('dashboard.blackroad.ai',  'blackroad-pi', 3001, 'http', 'Dashboard'),
  ('ollama.blackroad.ai',     'lucidia',      11434, 'http', 'Ollama inference'),
  ('mesh.blackroad.ai',       'blackroad-pi', 8787, 'http', 'Agent mesh'),
  ('ssh.blackroad.ai',        'blackroad-pi', 22,   'ssh',  'SSH access');
SQL
}

_cf_api() {
  local method="$1" path="$2" data="${3:-}"
  [[ -z "$CF_API_TOKEN" ]] && { echo -e "${RED}✗ CLOUDFLARE_API_TOKEN not set${NC}" >&2; return 1; }
  local args=(-s -X "$method" "https://api.cloudflare.com/client/v4${path}" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json")
  [[ -n "$data" ]] && args+=(-d "$data")
  curl "${args[@]}"
}

_tunnel_route_add() {
  local domain="$1" pi="$2" port="$3" svc="${4:-http}"
  local hostname="$domain"
  local service="${svc}://localhost:${port}"
  # Add ingress rule to tunnel via Cloudflare API
  local resp
  resp=$(_cf_api PUT "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${CF_TUNNEL_ID}/configurations" \
    "{\"config\":{\"ingress\":[{\"hostname\":\"${hostname}\",\"service\":\"${service}\"},{\"service\":\"http_status:404\"}]}}")
  if echo "$resp" | grep -q '"success":true'; then
    echo -e "${GREEN}✓ Tunnel route: $domain → $service${NC}"
    return 0
  else
    echo -e "${YELLOW}⚠ API call result:${NC}"
    echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); [print('  ',e) for e in d.get('errors',[])]" 2>/dev/null || echo "$resp" | head -3
    return 1
  fi
}

_dns_cname_add() {
  local domain="$1"
  # Create CNAME pointing to tunnel
  local tunnel_hostname="${CF_TUNNEL_ID}.cfargotunnel.com"
  # Get zone ID
  local zone_id
  zone_id=$(_cf_api GET "/zones?name=${CF_ZONE}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result'][0]['id'] if d.get('result') else '')" 2>/dev/null)
  [[ -z "$zone_id" ]] && { echo -e "${YELLOW}⚠ Could not get zone ID for ${CF_ZONE}${NC}"; return 1; }
  local subdomain="${domain%.${CF_ZONE}}"
  local resp
  resp=$(_cf_api POST "/zones/${zone_id}/dns_records" \
    "{\"type\":\"CNAME\",\"name\":\"${subdomain}\",\"content\":\"${tunnel_hostname}\",\"ttl\":1,\"proxied\":true}")
  if echo "$resp" | grep -q '"success":true'; then
    local rec_id
    rec_id=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['result']['id'])" 2>/dev/null)
    echo -e "${GREEN}✓ DNS CNAME: $domain → $tunnel_hostname${NC}"
    [[ -n "$rec_id" ]] && sqlite3 "$DB" "UPDATE routes SET cf_dns_record_id='$rec_id' WHERE domain='$domain';"
    return 0
  else
    echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); [print('  ',e) for e in d.get('errors',[])]" 2>/dev/null
    return 1
  fi
}

# Status dashboard
cmd_status() {
  echo ""
  echo -e "${PURPLE}${BOLD}┌────────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${PURPLE}${BOLD}│  🍓 BlackRoad Pi Domain Router                                 │${NC}"
  echo -e "${PURPLE}${BOLD}└────────────────────────────────────────────────────────────────┘${NC}"
  echo ""
  # Pi health
  echo -e "  ${CYAN}${BOLD}Pi Fleet:${NC}"
  for pi in blackroad-pi lucidia alice alt; do
    local ip="${PI_IPS[$pi]}"
    local role="${PI_ROLES[$pi]}"
    local alive
    alive=$(ping -c 1 -W 1 "$ip" &>/dev/null && echo "online" || echo "offline")
    local color="$GREEN"; [[ "$alive" == "offline" ]] && color="$RED"
    printf "  ${color}%-14s${NC}  %-15s  %-8s  %s\n" "$pi" "$ip" "$alive" "$role"
  done
  echo ""
  # Tunnel status
  echo -e "  ${CYAN}${BOLD}Cloudflare Tunnel:${NC}"
  local tunnel_status="unknown"
  if [[ -n "$CF_API_TOKEN" ]]; then
    tunnel_status=$(_cf_api GET "/accounts/${CF_ACCOUNT_ID}/cfd_tunnel/${CF_TUNNEL_ID}" 2>/dev/null | \
      python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('result',{}).get('status','unknown'))" 2>/dev/null)
  fi
  local tcolor="$GREEN"; [[ "$tunnel_status" != "healthy" && "$tunnel_status" != "active" ]] && tcolor="$YELLOW"
  echo -e "  ID:     ${BOLD}${CF_TUNNEL_ID:0:20}...${NC}"
  echo -e "  Status: ${tcolor}${tunnel_status}${NC}"
  echo ""
  # Routes table
  echo -e "  ${CYAN}${BOLD}Domain Routes:${NC}"
  printf "  ${BOLD}%-35s %-14s %6s %-6s %-6s %s${NC}\n" "Domain" "Pi" "Port" "Svc" "Active" "Description"
  printf "  %-35s %-14s %6s %-6s %-6s %s\n" "─────────────────────────────────" "────────────" "──────" "────" "──────" "───────────"
  sqlite3 -separator "|" "$DB" "SELECT domain, pi, local_port, service, active, description FROM routes ORDER BY pi, domain;" | while IFS="|" read -r domain pi port svc act desc; do
    local color="$GREEN"; [[ "$act" -eq 0 ]] && color="$RED"
    local actstr="✓"; [[ "$act" -eq 0 ]] && actstr="✗"
    printf "  ${color}%-35s %-14s %6s %-6s %-6s %s${NC}\n" "$domain" "$pi" "$port" "$svc" "$actstr" "$desc"
  done
  echo ""
}

# Add a domain route
cmd_add() {
  local domain="$1" pi="$2" port="${3:-8080}" svc="${4:-http}" desc="${5:-}"
  [[ -z "$domain" || -z "$pi" ]] && { echo "Usage: br pi-domains add <domain> <pi> [port] [svc] [description]"; exit 1; }
  # Validate pi
  [[ -z "${PI_IPS[$pi]}" ]] && { echo -e "${RED}✗ Unknown pi: $pi${NC}  Available: ${(k)PI_IPS}"; exit 1; }
  sqlite3 "$DB" "INSERT OR REPLACE INTO routes (domain, pi, local_port, service, description, updated_at) VALUES ('$domain', '$pi', $port, '$svc', '$desc', datetime('now'));"
  echo -e "${GREEN}✓ Route added: $domain → $pi:$port ($svc)${NC}"
  echo -e "  ${YELLOW}Run 'br pi-domains deploy $domain' to push to Cloudflare${NC}"
}

# Deploy a route to Cloudflare
cmd_deploy() {
  local domain="${1:-all}"
  echo ""
  echo -e "${CYAN}${BOLD}🚀 Deploying domain routes to Cloudflare${NC}"
  echo ""
  local where=""
  [[ "$domain" != "all" ]] && where="WHERE domain='$domain'"
  sqlite3 -separator "|" "$DB" "SELECT domain, pi, local_port, service FROM routes WHERE active=1 $where;" | while IFS="|" read -r dom pi port svc; do
    echo -e "  ${BOLD}$dom${NC} → ${pi}:${port}"
    local tunnel_ok=0 dns_ok=0
    if _tunnel_route_add "$dom" "$pi" "$port" "$svc"; then
      tunnel_ok=1
    fi
    if _dns_cname_add "$dom"; then
      dns_ok=1
    fi
    if [[ $tunnel_ok -eq 1 || $dns_ok -eq 1 ]]; then
      sqlite3 "$DB" "INSERT INTO deploy_log (domain, action, result, exit_code) VALUES ('$dom', 'deploy', 'tunnel=$tunnel_ok dns=$dns_ok', 0);"
    else
      sqlite3 "$DB" "INSERT INTO deploy_log (domain, action, result, exit_code) VALUES ('$dom', 'deploy', 'failed', 1);"
    fi
    echo ""
  done
}

# Update tunnel config file on Pi directly (via SSH)
cmd_push_config() {
  local pi="${1:-blackroad-pi}"
  local ip="${PI_IPS[$pi]}"
  [[ -z "$ip" ]] && { echo -e "${RED}✗ Unknown pi: $pi${NC}"; exit 1; }
  echo ""
  echo -e "${CYAN}${BOLD}📡 Pushing tunnel config to $pi ($ip)${NC}"
  echo ""
  # Build ingress rules from DB
  local ingress_json
  ingress_json=$(sqlite3 -separator "|" "$DB" "SELECT domain, local_port, service FROM routes WHERE active=1 ORDER BY domain;" | python3 -c "
import sys, json
rules = []
for line in sys.stdin:
    domain, port, svc = line.strip().split('|')
    rules.append({'hostname': domain, 'service': f'{svc}://localhost:{port}'})
rules.append({'service': 'http_status:404'})
print(json.dumps({'ingress': rules}, indent=2))
")
  # Write config file
  local config_file="/tmp/blackroad-tunnel-config-$$.yml"
  cat > "$config_file" <<YAML
tunnel: ${CF_TUNNEL_ID}
credentials-file: /root/.cloudflared/${CF_TUNNEL_ID}.json
ingress:
$(echo "$ingress_json" | python3 -c "
import json, sys
rules = json.load(sys.stdin)['ingress']
for r in rules:
    if 'hostname' in r:
        print(f'  - hostname: {r[\"hostname\"]}')
        print(f'    service: {r[\"service\"]}')
    else:
        print(f'  - service: {r[\"service\"]}')
")
YAML
  echo -e "  Config preview:"
  cat "$config_file" | head -20 | while read -r line; do echo "    $line"; done
  echo ""
  # SCP to Pi
  if scp "$config_file" "pi@${ip}:/tmp/tunnel-config.yml" 2>/dev/null; then
    ssh "pi@${ip}" "sudo cp /tmp/tunnel-config.yml /etc/cloudflared/config.yml && sudo systemctl restart cloudflared && echo OK" 2>/dev/null
    echo -e "${GREEN}✓ Tunnel config deployed to $pi and restarted${NC}"
    sqlite3 "$DB" "INSERT INTO deploy_log (domain, action, result, exit_code) VALUES ('all', 'push_config', 'pi=$pi', 0);"
  else
    echo -e "${YELLOW}⚠ SSH to $pi failed — saving config locally: $config_file${NC}"
    echo -e "  Manual: scp $config_file pi@${ip}:/etc/cloudflared/config.yml"
    echo -e "  Then:   ssh pi@${ip} 'sudo systemctl restart cloudflared'"
  fi
  rm -f "$config_file"
}

# Generate cloudflared config.yml
cmd_config_gen() {
  local pi="${1:-blackroad-pi}"
  echo ""
  echo -e "${CYAN}${BOLD}⚙ cloudflared config.yml for $pi${NC}"
  echo ""
  echo "tunnel: ${CF_TUNNEL_ID}"
  echo "credentials-file: /root/.cloudflared/${CF_TUNNEL_ID}.json"
  echo "ingress:"
  sqlite3 -separator "|" "$DB" "SELECT domain, local_port, service FROM routes WHERE active=1 ORDER BY domain;" | while IFS="|" read -r domain port svc; do
    echo "  - hostname: $domain"
    echo "    service: ${svc}://localhost:${port}"
  done
  echo "  - service: http_status:404"
  echo ""
}

# Show cloudflared install script for a Pi
cmd_install_script() {
  local pi="${1:-blackroad-pi}"
  local ip="${PI_IPS[$pi]}"
  echo ""
  echo -e "${CYAN}${BOLD}📜 cloudflared install script for $pi ($ip)${NC}"
  echo ""
  cat <<SCRIPT
#!/bin/bash
# Run on $pi ($ip) to set up Cloudflare tunnel

# Install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared.deb
rm cloudflared.deb

# Authenticate (opens browser — run on desktop or copy cert)
# cloudflared tunnel login

# Create tunnel (already created: ${CF_TUNNEL_ID})
# cloudflared tunnel create blackroad

# Write config
sudo mkdir -p /etc/cloudflared
sudo tee /etc/cloudflared/config.yml > /dev/null <<'CONFIG'
tunnel: ${CF_TUNNEL_ID}
credentials-file: /root/.cloudflared/${CF_TUNNEL_ID}.json
ingress:
SCRIPT
  sqlite3 -separator "|" "$DB" "SELECT domain, local_port, service FROM routes WHERE active=1;" | while IFS="|" read -r domain port svc; do
    echo "  - hostname: $domain"
    echo "    service: ${svc}://localhost:${port}"
  done
  echo "  - service: http_status:404"
  echo "CONFIG"
  echo ""
  echo "# Install as system service"
  echo "sudo cloudflared service install"
  echo "sudo systemctl enable cloudflared"
  echo "sudo systemctl start cloudflared"
  echo "sudo systemctl status cloudflared"
  echo ""
  echo "# Verify tunnel is healthy"
  echo "cloudflared tunnel info ${CF_TUNNEL_ID}"
}

# SSH to a Pi
cmd_ssh() {
  local pi="${1:-blackroad-pi}"
  shift
  local ip="${PI_IPS[$pi]}"
  [[ -z "$ip" ]] && { echo -e "${RED}✗ Unknown pi: $pi${NC}  Available: ${(k)PI_IPS}"; exit 1; }
  echo -e "${CYAN}Connecting to $pi ($ip)...${NC}"
  ssh "pi@${ip}" "$@"
}

# Ping all Pis
cmd_ping() {
  echo ""
  echo -e "${CYAN}${BOLD}🍓 Pi Fleet Ping${NC}"
  echo ""
  for pi in blackroad-pi lucidia alice alt; do
    local ip="${PI_IPS[$pi]}"
    if ping -c 1 -W 2 "$ip" &>/dev/null; then
      local latency
      latency=$(ping -c 3 -W 1 "$ip" 2>/dev/null | tail -1 | awk -F'/' '{print $5}' || echo "?")
      echo -e "  ${GREEN}✓ %-14s${NC}  %-15s  ${CYAN}${latency}ms${NC}" "$pi" "$ip"
    else
      echo -e "  ${RED}✗ %-14s${NC}  %-15s  unreachable" "$pi" "$ip"
    fi
  done
  echo ""
}

# Deploy log
cmd_log() {
  echo ""
  echo -e "${CYAN}📋 Deploy Log${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT ts, domain, action, result, exit_code FROM deploy_log ORDER BY ts DESC LIMIT 30;" | while IFS="|" read -r ts dom act res ec; do
    local color="$GREEN"; [[ "$ec" -ne 0 ]] && color="$RED"
    printf "  ${color}%s${NC}  %-20s  %-12s  %s\n" "${ts:0:16}" "$dom" "$act" "$res"
  done
  echo ""
}

# Remove a route
cmd_remove() {
  local domain="$1"
  [[ -z "$domain" ]] && { echo "Usage: br pi-domains remove <domain>"; exit 1; }
  sqlite3 "$DB" "DELETE FROM routes WHERE domain='$domain';"
  echo -e "${GREEN}✓ Route removed: $domain${NC}"
}

# Toggle active/inactive
cmd_toggle() {
  local domain="$1"
  [[ -z "$domain" ]] && { echo "Usage: br pi-domains toggle <domain>"; exit 1; }
  sqlite3 "$DB" "UPDATE routes SET active = CASE WHEN active=1 THEN 0 ELSE 1 END WHERE domain='$domain';"
  local state
  state=$(sqlite3 "$DB" "SELECT CASE WHEN active=1 THEN 'enabled' ELSE 'disabled' END FROM routes WHERE domain='$domain';")
  echo -e "${CYAN}↺ $domain is now ${state}${NC}"
}

show_help() {
  echo ""
  echo -e "${PURPLE}${BOLD}br pi-domains${NC} — route Cloudflare domains to Raspberry Pis"
  echo ""
  echo -e "  ${GREEN}br pi-domains${NC}                     Dashboard — Pi status + routes"
  echo -e "  ${GREEN}br pi-domains ping${NC}                Ping all Pis"
  echo -e "  ${GREEN}br pi-domains add <domain> <pi> [port] [svc] [desc]${NC}"
  echo -e "                                   Add a domain route"
  echo -e "  ${GREEN}br pi-domains deploy [domain|all]${NC} Push routes to Cloudflare API"
  echo -e "  ${GREEN}br pi-domains push-config [pi]${NC}    SCP tunnel config to Pi & restart"
  echo -e "  ${GREEN}br pi-domains config-gen [pi]${NC}     Print cloudflared config.yml"
  echo -e "  ${GREEN}br pi-domains install-script [pi]${NC} Print Pi setup script"
  echo -e "  ${GREEN}br pi-domains ssh <pi> [cmd]${NC}      SSH into a Pi"
  echo -e "  ${GREEN}br pi-domains remove <domain>${NC}     Remove a route"
  echo -e "  ${GREEN}br pi-domains toggle <domain>${NC}     Enable/disable a route"
  echo -e "  ${GREEN}br pi-domains log${NC}                 Deploy history"
  echo ""
  echo -e "  ${YELLOW}Pi hosts:${NC}"
  for pi in blackroad-pi lucidia alice alt; do
    printf "    ${CYAN}%-14s${NC}  %s  %s\n" "$pi" "${PI_IPS[$pi]}" "${PI_ROLES[$pi]}"
  done
  echo ""
  echo -e "  ${YELLOW}Env vars:${NC} CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, BLACKROAD_TUNNEL_ID, CLOUDFLARE_ZONE"
  echo ""
}

init_db
case "${1:-status}" in
  status|s|"")     cmd_status ;;
  ping)            cmd_ping ;;
  add)             shift; cmd_add "$@" ;;
  deploy|push)     shift; cmd_deploy "${1:-all}" ;;
  push-config|scp) shift; cmd_push_config "${1:-blackroad-pi}" ;;
  config-gen|conf) shift; cmd_config_gen "${1:-blackroad-pi}" ;;
  install-script|install) shift; cmd_install_script "${1:-blackroad-pi}" ;;
  ssh)             shift; cmd_ssh "$@" ;;
  remove|rm|del)   shift; cmd_remove "$@" ;;
  toggle)          shift; cmd_toggle "$@" ;;
  log|history)     cmd_log ;;
  help|-h|--help)  show_help ;;
  *)               show_help ;;
esac
