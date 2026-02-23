#!/bin/zsh
# ◆ BR MAIL — Agent Email System
# BlackRoad OS — Every agent has a voice. Every inbox, a purpose.

AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
EMAILS_CONFIG="$BR_ROOT/agents/emails/agent-emails.json"
INBOX_DIR="$HOME/.blackroad/agent-inboxes"
DB_FILE="$HOME/.blackroad/mail.db"

#──────────────────────────────────────────────────────────────────────────────
# Init
#──────────────────────────────────────────────────────────────────────────────
init_db() {
  mkdir -p "$INBOX_DIR" "$(dirname "$DB_FILE")"
  sqlite3 "$DB_FILE" << 'SQL'
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  agent_id TEXT NOT NULL,
  from_addr TEXT,
  to_addr TEXT,
  subject TEXT,
  body TEXT,
  direction TEXT DEFAULT 'inbound',
  status TEXT DEFAULT 'unread',
  received_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS drafts (
  id TEXT PRIMARY KEY,
  agent_id TEXT NOT NULL,
  to_addr TEXT,
  subject TEXT,
  body TEXT,
  created_at TEXT DEFAULT (datetime('now'))
);
SQL
}

#──────────────────────────────────────────────────────────────────────────────
# Agent list from config
#──────────────────────────────────────────────────────────────────────────────
_agents() {
  python3 -c "
import json, sys
with open('$EMAILS_CONFIG') as f:
    d = json.load(f)
for a in d['agents']:
    print(f\"{a['id']}\t{a['email']}\t{a['role']}\t{a.get('emoji','◆')}\")
" 2>/dev/null
}

_agent_email() {
  local id="$1"
  python3 -c "
import json
with open('$EMAILS_CONFIG') as f:
    d = json.load(f)
for a in d['agents']:
    if a['id'] == '$id':
        print(a['email'])
        break
" 2>/dev/null
}

_agent_sig() {
  local id="$1"
  python3 -c "
import json
with open('$EMAILS_CONFIG') as f:
    d = json.load(f)
for a in d['agents']:
    if a['id'] == '$id':
        print(a.get('signature',''))
        break
" 2>/dev/null
}

#──────────────────────────────────────────────────────────────────────────────
# List agents + their addresses
#──────────────────────────────────────────────────────────────────────────────
cmd_list() {
  echo -e "\n  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}Agent Email Directory · @blackroad.io${NC}\n"
  echo -e "  ${DIM}$(printf '%.0s─' {1..60})${NC}"
  printf "  ${BOLD}%-10s  %-30s  %s${NC}\n" "AGENT" "EMAIL" "ROLE"
  echo -e "  ${DIM}$(printf '%.0s─' {1..60})${NC}"
  _agents | while IFS=$'\t' read -r id email role emoji; do
    printf "  ${AMBER}%-10s${NC}  ${DIM}%-30s${NC}  %s\n" "$emoji $id" "$email" "${role%%—*}"
  done
  echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Show inbox for agent
#──────────────────────────────────────────────────────────────────────────────
cmd_inbox() {
  local agent="${1:-cece}"
  local email; email=$(_agent_email "$agent")
  [[ -z "$email" ]] && echo -e "  ${RED}✗ Unknown agent: $agent${NC}" && return 1

  echo -e "\n  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}Inbox: ${email}${NC}\n"

  # Try Cloudflare worker API if configured
  local cf_url="${BLACKROAD_EMAIL_WORKER_URL:-}"
  if [[ -n "$cf_url" ]]; then
    local result; result=$(curl -sf --max-time 5 "${cf_url}/inbox/${agent}" 2>/dev/null)
    if [[ -n "$result" ]]; then
      echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
msgs = d.get('messages', [])
if not msgs:
    print('  \033[2m(no messages)\033[0m')
else:
    for m in msgs:
        ts = m.get('received_at','?')[:16].replace('T',' ')
        frm = m.get('from','?')[:30]
        subj = m.get('subject','(no subject)')[:45]
        print(f'  \033[2m{ts}\033[0m  \033[38;5;214m{frm:<30}\033[0m  {subj}')
"
      echo ""
      return
    fi
  fi

  # Local DB fallback
  local count; count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM messages WHERE agent_id='$agent'" 2>/dev/null || echo 0)
  if (( count == 0 )); then
    echo -e "  ${DIM}(inbox empty — messages logged here when received)${NC}"
    echo -e "  ${DIM}Send email to ${email} to see it appear here.${NC}"
  else
    sqlite3 "$DB_FILE" -separator $'\t' \
      "SELECT received_at, from_addr, subject, status FROM messages WHERE agent_id='$agent' ORDER BY received_at DESC LIMIT 20" \
      2>/dev/null | while IFS=$'\t' read -r ts from subj status; do
      local mark=""; [[ "$status" == "unread" ]] && mark="${BOLD}●${NC} " || mark="  "
      printf "  %b${DIM}%-16s${NC}  ${AMBER}%-28s${NC}  %s\n" "$mark" "$ts" "${from:0:27}" "${subj:0:45}"
    done
  fi
  echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Compose — write email AS an agent
#──────────────────────────────────────────────────────────────────────────────
cmd_compose() {
  local agent="${1:-cece}"
  local to="${2:-}"
  local subject="${3:-}"

  local email; email=$(_agent_email "$agent")
  [[ -z "$email" ]] && echo -e "  ${RED}✗ Unknown agent: $agent${NC}" && return 1

  echo -e "\n  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}Compose as ${email}${NC}\n"

  # Prompt for missing fields
  if [[ -z "$to" ]]; then
    printf "  ${AMBER}To:${NC} "; read -r to
  fi
  if [[ -z "$subject" ]]; then
    printf "  ${AMBER}Subject:${NC} "; read -r subject
  fi

  echo -e "  ${AMBER}Body${NC} ${DIM}(type message, end with a line containing just '.')${NC}"
  local body="" line
  while IFS= read -r line; do
    [[ "$line" == "." ]] && break
    body="${body}${line}\n"
  done

  # Append agent signature
  local sig; sig=$(_agent_sig "$agent")
  local full_body="${body}\n—\n${sig}"

  # Preview
  echo -e "\n  ${DIM}$(printf '%.0s─' {1..50})${NC}"
  echo -e "  ${BOLD}From:${NC}    $email"
  echo -e "  ${BOLD}To:${NC}      $to"
  echo -e "  ${BOLD}Subject:${NC} $subject"
  echo -e "  ${DIM}$(printf '%.0s─' {1..50})${NC}"
  echo -e "${body}" | head -8
  echo -e "  ${DIM}[signature appended]${NC}"
  echo ""

  printf "  ${AMBER}Send?${NC} [y/N] "
  read -r confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Save to DB
    local id; id="msg_$(date +%s)_${RANDOM}"
    sqlite3 "$DB_FILE" << SQL
INSERT INTO messages (id, agent_id, from_addr, to_addr, subject, body, direction, status)
VALUES ('$id', '$agent', '$email', '$to', '$subject', '$(echo "$full_body" | sed "s/'/''/g")', 'outbound', 'sent');
SQL
    echo -e "  ${GREEN}✅ Saved to outbox${NC}  ${DIM}(id: ${id})${NC}"
    echo -e "  ${DIM}→ To actually send: configure SMTP or use Gmail API${NC}\n"
  else
    echo -e "  ${DIM}Cancelled.${NC}\n"
  fi
}

#──────────────────────────────────────────────────────────────────────────────
# DNS check — verify @blackroad.io MX records
#──────────────────────────────────────────────────────────────────────────────
cmd_dns() {
  echo -e "\n  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}DNS Check · blackroad.io${NC}\n"

  # MX
  echo -e "  ${BOLD}MX Records${NC}"
  local mx; mx=$(dig +short MX blackroad.io 2>/dev/null || nslookup -type=MX blackroad.io 2>/dev/null | grep "mail exchanger")
  if echo "$mx" | grep -qi "cloudflare\|route[12]\.mx"; then
    echo -e "  ${GREEN}●${NC} MX → Cloudflare  ${DIM}(Email Routing ready)${NC}"
    echo -e "  ${DIM}  ${mx}${NC}"
  elif echo "$mx" | grep -qi "google\|aspmx"; then
    echo -e "  ${YELLOW}◌${NC} MX → Google Workspace"
    echo -e "  ${DIM}  ${mx}${NC}"
    echo -e "\n  ${BOLD}To enable Cloudflare Email Routing, replace MX records:${NC}"
    echo -e "  ${DIM}  Remove:  *.google.com MX records${NC}"
    echo -e "  ${DIM}  Add:     MX  10  route1.mx.cloudflare.net${NC}"
    echo -e "  ${DIM}           MX  20  route2.mx.cloudflare.net${NC}"
    echo -e "  ${DIM}  Note: this will stop Google Workspace mail — use forwarding if needed${NC}"
  elif [[ -z "$mx" ]]; then
    echo -e "  ${RED}○${NC} No MX records found"
    echo -e "  ${DIM}  Add to Cloudflare DNS:${NC}"
    echo -e "  ${DIM}    MX  10  route1.mx.cloudflare.net${NC}"
    echo -e "  ${DIM}    MX  20  route2.mx.cloudflare.net${NC}"
  else
    echo -e "  ${YELLOW}◌${NC} MX found (not Cloudflare): ${DIM}${mx}${NC}"
  fi

  # SPF
  echo -e "\n  ${BOLD}SPF Record${NC}"
  local spf; spf=$(dig +short TXT blackroad.io 2>/dev/null | grep spf)
  if [[ -n "$spf" ]]; then
    echo -e "  ${GREEN}●${NC} SPF  ${DIM}${spf}${NC}"
  else
    echo -e "  ${RED}○${NC} No SPF record"
    echo -e "  ${DIM}  Add TXT: v=spf1 include:_spf.mx.cloudflare.net ~all${NC}"
  fi

  echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Deploy — print deployment instructions
#──────────────────────────────────────────────────────────────────────────────
cmd_deploy() {
  echo -e "\n  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}Deploy Email Router${NC}\n"
  echo -e "  ${BOLD}1. Deploy Cloudflare Worker${NC}"
  echo -e "  ${DIM}  cd blackroad-os/workers/email-router${NC}"
  echo -e "  ${DIM}  wrangler deploy${NC}\n"
  echo -e "  ${BOLD}2. Create KV namespace${NC}"
  echo -e "  ${DIM}  wrangler kv:namespace create AGENT_INBOXES${NC}"
  echo -e "  ${DIM}  → update wrangler.toml with returned id${NC}\n"
  echo -e "  ${BOLD}3. Auto-configure via API${NC}"
  echo -e "  ${DIM}  export CLOUDFLARE_API_TOKEN=<token>${NC}"
  echo -e "  ${DIM}  br mail setup${NC}\n"
  echo -e "  ${BOLD}4. Check status${NC}"
  echo -e "  ${DIM}  br mail status${NC}\n"
}

#──────────────────────────────────────────────────────────────────────────────
# Setup — auto-configure Cloudflare Email Routing via API
#──────────────────────────────────────────────────────────────────────────────
cmd_setup() {
  local TOKEN="${CLOUDFLARE_API_TOKEN:-}"
  local ACCOUNT="848cf0b18d51e0170e0d1537aec3505a"
  local DOMAIN="blackroad.io"
  local WORKER="blackroad-email"
  local DEST="alexa@blackroad.io"
  local BASE="https://api.cloudflare.com/client/v4"

  echo -e "\n  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}Auto-configure Email Routing${NC}\n"

  if [[ -z "$TOKEN" ]]; then
    echo -e "  ${RED}✗ CLOUDFLARE_API_TOKEN not set${NC}"
    echo -e "  ${DIM}  export CLOUDFLARE_API_TOKEN=your_token${NC}\n"
    exit 1
  fi

  _cf() { curl -sf -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }
  _ok() { python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d.get('success') else str(d.get('errors',d)))" 2>/dev/null; }

  # Validate token first
  local whoami; whoami=$(_cf "${BASE}/user/tokens/verify" 2>/dev/null)
  if ! echo "$whoami" | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
    echo -e "  ${RED}✗ Invalid API token${NC}"
    echo -e "  ${DIM}  Get one at: https://dash.cloudflare.com/profile/api-tokens${NC}"
    echo -e "  ${DIM}  Needs: Zone:Email Routing:Edit + Account:Email Routing Addresses:Edit${NC}\n"
    exit 1
  fi
  echo -e "  ${GREEN}✓${NC} Token valid"

  # 1. Get zone ID — search by name only (no account filter)
  echo -e "  ${BOLD}→ Zone lookup${NC}"
  local zone_raw; zone_raw=$(_cf "${BASE}/zones?name=${DOMAIN}&per_page=5")
  local zone_id
  zone_id=$(echo "$zone_raw" | python3 -c "import sys,json; z=json.load(sys.stdin).get('result',[]); print(z[0]['id'] if z else '')" 2>/dev/null)
  if [[ -z "$zone_id" ]]; then
    echo -e "  ${RED}✗ Zone not found for ${DOMAIN}${NC}"
    echo -e "  ${DIM}  Make sure blackroad.io is active in your Cloudflare account${NC}"
    echo -e "  ${DIM}  Raw: $(echo "$zone_raw" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors', d.get('result','')))" 2>/dev/null)${NC}\n"
    exit 1
  fi
  echo -e "  ${GREEN}✓${NC} zone: ${DIM}${zone_id}${NC}"

  # 2. Enable email routing
  echo -e "  ${BOLD}→ Enabling Email Routing${NC}"
  local r; r=$(_cf -X POST "${BASE}/zones/${zone_id}/email/routing/enable" | _ok)
  [[ "$r" == "ok" ]] && echo -e "  ${GREEN}✓${NC} Email Routing enabled" \
    || echo -e "  ${YELLOW}◌${NC} ${DIM}${r} (may already be on)${NC}"

  # 3. Add destination address
  echo -e "  ${BOLD}→ Adding destination: ${DEST}${NC}"
  r=$(_cf -X POST "${BASE}/accounts/${ACCOUNT}/email/routing/addresses" \
    -d "{\"email\":\"${DEST}\"}" | _ok)
  [[ "$r" == "ok" ]] && echo -e "  ${GREEN}✓${NC} Destination added ${DIM}(check email to verify)${NC}" \
    || echo -e "  ${YELLOW}◌${NC} ${DIM}${r} (may already be verified)${NC}"

  # 4. Create catch-all → worker
  echo -e "  ${BOLD}→ Creating catch-all rule → ${WORKER}${NC}"
  local payload; payload=$(python3 -c "
import json; print(json.dumps({
  'actions': [{'type': 'worker', 'value': ['${WORKER}']}],
  'enabled': True,
  'matchers': [{'field': 'to', 'type': 'all'}],
  'name': 'BlackRoad catch-all',
  'priority': 0
}))")
  r=$(_cf -X POST "${BASE}/zones/${zone_id}/email/routing/rules/catch_all" \
    -d "$payload" | _ok)
  [[ "$r" == "ok" ]] && echo -e "  ${GREEN}✓${NC} Catch-all rule created" \
    || echo -e "  ${YELLOW}◌${NC} ${DIM}${r}${NC}"

  echo -e "\n  ${GREEN}${BOLD}✓ Done${NC}  all *@${DOMAIN} → ${WORKER} → forwarded to ${DEST}"
  echo -e "  ${DIM}  Test: br mail status · then send to lucidia@blackroad.io${NC}\n"
}

#──────────────────────────────────────────────────────────────────────────────
# Status — show Cloudflare Email Routing state
#──────────────────────────────────────────────────────────────────────────────
cmd_status() {
  local TOKEN="${CLOUDFLARE_API_TOKEN:-}"
  local ACCOUNT="848cf0b18d51e0170e0d1537aec3505a"
  local DOMAIN="blackroad.io"
  local BASE="https://api.cloudflare.com/client/v4"

  echo -e "\n  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}Email Routing Status · ${DOMAIN}${NC}\n"

  if [[ -z "$TOKEN" ]]; then
    echo -e "  ${RED}✗ CLOUDFLARE_API_TOKEN not set${NC}\n"; exit 1
  fi

  _cf() { curl -sf -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }

  # Token check
  if ! _cf "${BASE}/user/tokens/verify" 2>/dev/null | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
    echo -e "  ${RED}✗ Invalid API token — set CLOUDFLARE_API_TOKEN${NC}\n"; exit 1
  fi

  local zone_id
  zone_id=$(_cf "${BASE}/zones?name=${DOMAIN}&per_page=5" | \
    python3 -c "import sys,json; z=json.load(sys.stdin).get('result',[]); print(z[0]['id'] if z else '')" 2>/dev/null)
  [[ -z "$zone_id" ]] && { echo -e "  ${RED}✗ Zone ${DOMAIN} not found in this CF account${NC}\n"; exit 1; }

  # Routing enabled?
  _cf "${BASE}/zones/${zone_id}/email/routing" 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin).get('result',{})
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; D='\033[2m'; NC='\033[0m'; B='\033[1m'
en=d.get('enabled',False); st=d.get('status','unknown')
sym = G+'✓' if en else R+'✗'
print(f'  {sym} Email Routing:{NC} {st}')
" 2>/dev/null

  # Catch-all rule
  _cf "${BASE}/zones/${zone_id}/email/routing/rules/catch_all" 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin).get('result',{})
G='\033[0;32m'; Y='\033[1;33m'; D='\033[2m'; NC='\033[0m'
actions=d.get('actions',[])
if actions:
    a=actions[0]; vals=', '.join(a.get('value',[]))
    print(f'  {G}✓{NC} Catch-all: {a[\"type\"]} → {D}{vals}{NC}')
else:
    print(f'  {Y}◌{NC} No catch-all rule  {D}(run: br mail setup){NC}')
" 2>/dev/null

  # DNS check
  echo ""
  local mx; mx=$(dig +short MX blackroad.io 2>/dev/null)
  [[ -n "$mx" ]] \
    && echo -e "  ${GREEN}✓${NC} MX  ${DIM}${mx}${NC}" \
    || echo -e "  ${YELLOW}◌${NC} No MX records  ${DIM}(run: br mail dns)${NC}"

  echo ""
}


#──────────────────────────────────────────────────────────────────────────────
# Help
#──────────────────────────────────────────────────────────────────────────────
show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR MAIL${NC}  ${DIM}Agent email at @blackroad.io. Every agent has a voice.${NC}"
  echo -e "  ${DIM}Lucidia. Alice. Octavia. Aria. Cipher. CECE. All reachable.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br mail ${DIM}<command> [agent]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  list                    ${NC} All agent email addresses"
  echo -e "  ${AMBER}  inbox [agent]           ${NC} View inbox (default: cece)"
  echo -e "  ${AMBER}  compose <agent> [to]    ${NC} Compose email as an agent"
  echo -e "  ${AMBER}  dns                     ${NC} Check @blackroad.io MX/SPF records"
  echo -e "  ${AMBER}  setup                   ${NC} Auto-configure Cloudflare Email Routing (needs API token)"
  echo -e "  ${AMBER}  status                  ${NC} Show routing + catch-all rule status"
  echo -e "  ${AMBER}  deploy                  ${NC} Show manual deployment instructions"
  echo -e ""
  echo -e "  ${BOLD}AGENT ADDRESSES${NC}"
  _agents | while IFS=$'\t' read -r id email role emoji; do
    printf "  ${DIM}  %-8s  %s${NC}\n" "$emoji" "$email"
  done
  echo ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br mail list${NC}"
  echo -e "  ${DIM}  br mail inbox cece${NC}"
  echo -e "  ${DIM}  br mail compose lucidia hello@example.com${NC}"
  echo -e "  ${DIM}  br mail dns${NC}"
  echo -e "  ${DIM}  br mail deploy${NC}"
  echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Dispatch
#──────────────────────────────────────────────────────────────────────────────
init_db

case "${1:-list}" in
  list|ls|agents)       cmd_list ;;
  inbox|in|read)        cmd_inbox "${2:-cece}" ;;
  compose|write|c)      cmd_compose "${2:-cece}" "${3:-}" "${4:-}" ;;
  dns|check)            cmd_dns ;;
  setup)                cmd_setup ;;
  status)               cmd_status ;;
  deploy|instructions)  cmd_deploy ;;
  help|-h|--help)       show_help ;;
  *)
    # br mail <agent> → show inbox for that agent
    if _agent_email "$1" &>/dev/null 2>&1; then
      cmd_inbox "$1"
    else
      show_help
    fi
    ;;
esac
