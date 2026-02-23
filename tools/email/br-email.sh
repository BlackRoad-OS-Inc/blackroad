#!/bin/zsh
# BR EMAIL — BlackRoad OS agent email registry
# All agents have @blackroad.io addresses. This tool manages them.
#
# Usage:
#   br email                  → list all agent emails
#   br email <agent>          → show agent card
#   br email cloudflare       → print Cloudflare routing rules
#   br email forward <agent>  → show forward target
#   br email me               → show alexa@blackroad.io card

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BLUE=$'\033[0;34m'
PURPLE=$'\033[0;35m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

REGISTRY="${BR_TOOLS_DIR:-$(dirname "$0")/..}/../../agents/registry.json"
# normalize to absolute path
REGISTRY=$(cd "$(dirname "$REGISTRY")" 2>/dev/null && pwd)/$(basename "$REGISTRY")
# second fallback: search from script location
if [[ ! -f "$REGISTRY" ]]; then
  REGISTRY="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/agents/registry.json"
fi

if [[ ! -f "$REGISTRY" ]]; then
  echo "${RED}✗ registry not found: $REGISTRY${NC}"; exit 1
fi

# ─── List all emails ──────────────────────────────────────────────────────────
cmd_list() {
  echo ""
  echo "${BOLD}  BlackRoad OS  —  @blackroad.io${NC}"
  echo ""

  # Owner
  local owner_name owner_email
  owner_name=$(python3 -c "import json; r=json.load(open('$REGISTRY')); print(r['humans']['alexa']['name'])")
  owner_email=$(python3 -c "import json; r=json.load(open('$REGISTRY')); print(r['humans']['alexa']['email'])")
  printf "  ${YELLOW}★${NC}  ${BOLD}%-28s${NC} ${YELLOW}%s${NC}\n" "$owner_name" "$owner_email"
  echo ""

  # Agents
  python3 - "$REGISTRY" <<'PY'
import json, sys

r = json.load(open(sys.argv[1]))
agents = r["agents"]

colors = {
  "purple":  "\033[0;35m",
  "cyan":    "\033[0;36m",
  "green":   "\033[0;32m",
  "blue":    "\033[0;34m",
  "yellow":  "\033[1;33m",
  "red":     "\033[0;31m",
  "magenta": "\033[0;35m",
  "dim":     "\033[2m",
  "bold":    "\033[1m",
}
NC   = "\033[0m"
DIM  = "\033[2m"
BOLD = "\033[1m"

for name, a in agents.items():
  c = colors.get(a.get("color",""), "")
  role = a.get("role","")
  email = a.get("email","")
  host = a.get("host") or ""
  host_str = f"  {DIM}{host}{NC}" if host else ""
  print(f"  {c}●{NC}  {c}{BOLD}{email:<30}{NC}  {DIM}{role:<24}{NC}{host_str}")

PY

  echo ""
  local domain
  domain=$(python3 -c "import json; r=json.load(open('$REGISTRY')); print(r['_meta']['domain'])")
  local fwd
  fwd=$(python3 -c "import json; r=json.load(open('$REGISTRY')); print(r['routing']['forward_all_to'])")
  echo "  ${DIM}domain: ${domain}   all mail → ${fwd}${NC}"
  echo ""
}

# ─── Show agent card ──────────────────────────────────────────────────────────
cmd_show() {
  local name="${1:-}"
  [[ -z "$name" ]] && { cmd_list; return; }

  [[ "$name" == "me" || "$name" == "alexa" ]] && {
    echo ""
    echo "  ${YELLOW}${BOLD}Alexa Amundson${NC}"
    echo "  ${YELLOW}alexa@blackroad.io${NC}"
    echo "  ${DIM}Founder / OS Architect${NC}"
    echo "  ${DIM}github: blackboxprogramming${NC}"
    echo ""
    return
  }

  python3 - "$REGISTRY" "$name" <<'PY'
import json, sys

r = json.load(open(sys.argv[1]))
name = sys.argv[2].lower()

agents = r["agents"]
if name not in agents:
    print(f"\033[0;31m✗ Unknown agent: {name}\033[0m")
    print(f"  Known: {', '.join(agents.keys())}")
    sys.exit(1)

a = agents[name]
colors = {
  "purple": "\033[0;35m", "cyan": "\033[0;36m", "green": "\033[0;32m",
  "blue":   "\033[0;34m", "yellow": "\033[1;33m", "red": "\033[0;31m",
  "magenta":"\033[0;35m", "dim": "\033[2m", "bold": "\033[1m",
}
c = colors.get(a.get("color",""), "")
NC = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"

print()
print(f"  {c}{BOLD}{a['full_name']}{NC}")
print(f"  {c}{a['email']}{NC}")
print(f"  {DIM}{a['role']}{NC}")
print()
print(f"  {DIM}type:   {a.get('type','')}{NC}")
if a.get('host'):
    print(f"  {DIM}host:   {a['host']}{NC}")
if a.get('model'):
    print(f"  {DIM}model:  {a['model']}{NC}")
print(f"  {DIM}{a.get('description','')}{NC}")
print()
PY
}

# ─── Cloudflare email routing rules ──────────────────────────────────────────
cmd_cloudflare() {
  echo ""
  echo "${BOLD}  Cloudflare Email Routing — blackroad.io${NC}"
  echo "  ${DIM}wrangler mail or dashboard.cloudflare.com → Email → Routing Rules${NC}"
  echo ""

  local fwd
  fwd=$(python3 -c "import json; r=json.load(open('$REGISTRY')); print(r['routing']['forward_all_to'])")

  python3 - "$REGISTRY" "$fwd" <<'PY'
import json, sys

r = json.load(open(sys.argv[1]))
forward_to = sys.argv[2]
BOLD = "\033[1m"
DIM  = "\033[2m"
CYAN = "\033[0;36m"
NC   = "\033[0m"

# Owner
alexa = r["humans"]["alexa"]
print(f"  {BOLD}{'ADDRESS':<35} {'ACTION':<12} DESTINATION{NC}")
print(f"  {'─'*70}")
print(f"  {CYAN}{alexa['email']:<35}{NC} {'forward':<12} {alexa['email']}")

# All agents
for name, a in r["agents"].items():
    email = a["email"]
    print(f"  {CYAN}{email:<35}{NC} {'forward':<12} {DIM}{forward_to}{NC}")

# Catch-all
catch = r["routing"]["catch_all"]
print(f"\n  {DIM}{'*@blackroad.io':<35} catch-all      {forward_to}{NC}")
print()
print(f"  {DIM}To apply via Cloudflare API:{NC}")
print(f"  {DIM}wrangler email routing rules list --zone blackroad.io{NC}")
PY
}

# ─── Help ─────────────────────────────────────────────────────────────────────
show_help() {
  echo ""
  echo "${BOLD}br email${NC} — BlackRoad OS agent email registry"
  echo ""
  echo "  ${CYAN}br email${NC}               list all @blackroad.io addresses"
  echo "  ${CYAN}br email <agent>${NC}        show agent card"
  echo "  ${CYAN}br email me${NC}             show alexa@blackroad.io"
  echo "  ${CYAN}br email cloudflare${NC}     print Cloudflare routing rules"
  echo "  ${CYAN}br email setup${NC}          configure Cloudflare Email Routing via API"
  echo "  ${CYAN}br email status${NC}         check routing + catch-all rule status"
  echo "  ${CYAN}br email deploy${NC}         deploy the Cloudflare Email Worker"
  echo "  ${CYAN}br email api [agent]${NC}    query worker inbox API"
  echo ""
  echo "  ${DIM}Agents: lucidia alice octavia aria cecilia cipher${NC}"
  echo "  ${DIM}        prism echo oracle atlas shellfish gematria anastasia${NC}"
  echo ""
}

# ─── Deploy worker ────────────────────────────────────────────────────────────
cmd_deploy() {
  local worker_dir
  worker_dir="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/workers/email"
  if [[ ! -d "$worker_dir" ]]; then
    echo "${RED}✗ Worker not found: $worker_dir${NC}"; exit 1
  fi
  echo "${CYAN}→ deploying blackroad-email worker${NC}"
  echo "  ${DIM}${worker_dir}${NC}"
  echo ""
  cd "$worker_dir" && wrangler deploy
}

# ─── Query worker API ─────────────────────────────────────────────────────────
cmd_api() {
  local agent="${1:-}"
  local base="https://blackroad-email.amundsonalexa.workers.dev"
  local url="${agent:+${base}/inbox/${agent}}"
  url="${url:-${base}/inbox}"
  echo "${CYAN}GET ${url}${NC}"
  curl -s "$url" | python3 -m json.tool 2>/dev/null || curl -s "$url"
  echo ""
}

# ─── Setup Cloudflare Email Routing via API ───────────────────────────────────
cmd_setup() {
  local TOKEN="${CLOUDFLARE_API_TOKEN:-}"
  local ACCOUNT="848cf0b18d51e0170e0d1537aec3505a"
  local DOMAIN="blackroad.io"
  local WORKER="blackroad-email"
  local DEST="alexa@blackroad.io"
  local BASE="https://api.cloudflare.com/client/v4"

  if [[ -z "$TOKEN" ]]; then
    echo "${RED}✗ CLOUDFLARE_API_TOKEN not set${NC}"
    echo "  ${DIM}export CLOUDFLARE_API_TOKEN=your_token${NC}"
    exit 1
  fi

  _cf() { curl -sf -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }

  echo "${BOLD}${CYAN}━━ BlackRoad Email Routing Setup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # 1. Get zone ID
  echo "${CYAN}→ Looking up zone for ${DOMAIN}…${NC}"
  local zone_id
  zone_id=$(_cf "${BASE}/zones?name=${DOMAIN}&account.id=${ACCOUNT}" | python3 -c "import sys,json; z=json.load(sys.stdin)['result']; print(z[0]['id'] if z else '')" 2>/dev/null)
  if [[ -z "$zone_id" ]]; then
    echo "${RED}✗ Zone not found for ${DOMAIN}${NC}"; exit 1
  fi
  echo "  ${GREEN}✓ zone_id: ${zone_id}${NC}"

  # 2. Enable email routing
  echo "${CYAN}→ Enabling Email Routing…${NC}"
  local enable_out
  enable_out=$(_cf -X POST "${BASE}/zones/${zone_id}/email/routing/enable" 2>&1)
  if echo "$enable_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d.get('success') else 'fail')" 2>/dev/null | grep -q ok; then
    echo "  ${GREEN}✓ Email Routing enabled${NC}"
  else
    echo "  ${YELLOW}⚠ Enable returned: $(echo "$enable_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('errors',d))" 2>/dev/null || echo "$enable_out")${NC}"
    echo "  ${DIM}(may already be enabled — continuing)${NC}"
  fi

  # 3. Add alexa@blackroad.io as verified destination
  echo "${CYAN}→ Adding destination: ${DEST}…${NC}"
  local dest_out
  dest_out=$(_cf -X POST "${BASE}/accounts/${ACCOUNT}/email/routing/addresses" \
    -d "{\"email\":\"${DEST}\"}" 2>&1)
  local dest_status
  dest_status=$(echo "$dest_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d.get('success') else d.get('errors',d))" 2>/dev/null)
  if [[ "$dest_status" == "ok" ]]; then
    echo "  ${GREEN}✓ Destination added (check email to verify)${NC}"
  else
    echo "  ${YELLOW}⚠ Destination: ${dest_status}${NC}"
    echo "  ${DIM}(may already be verified — continuing)${NC}"
  fi

  # 4. Create catch-all rule → Worker
  echo "${CYAN}→ Creating catch-all rule → worker ${WORKER}…${NC}"
  local rule_payload
  rule_payload=$(python3 -c "
import json
print(json.dumps({
  'actions': [{'type': 'worker', 'value': ['${WORKER}']}],
  'enabled': True,
  'matchers': [{'field': 'to', 'type': 'all'}],
  'name': 'BlackRoad catch-all → ${WORKER}',
  'priority': 0
}))
")
  local rule_out
  rule_out=$(_cf -X POST "${BASE}/zones/${zone_id}/email/routing/rules/catch_all" \
    -d "$rule_payload" 2>&1)
  local rule_status
  rule_status=$(echo "$rule_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d.get('success') else d.get('errors',d))" 2>/dev/null)
  if [[ "$rule_status" == "ok" ]]; then
    echo "  ${GREEN}✓ Catch-all rule created${NC}"
  else
    echo "  ${YELLOW}⚠ Rule: ${rule_status}${NC}"
    echo "  ${DIM}(may already exist — run 'br email status' to check)${NC}"
  fi

  echo ""
  echo "${BOLD}${GREEN}━━ Done ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "  All *@blackroad.io → ${WORKER} worker → forwarded to ${DEST}"
  echo ""
  echo "  ${DIM}Test: send an email to lucidia@blackroad.io${NC}"
  echo "  ${DIM}Check: br email api lucidia${NC}"
}

# ─── Check Email Routing status ───────────────────────────────────────────────
cmd_status() {
  local TOKEN="${CLOUDFLARE_API_TOKEN:-}"
  local ACCOUNT="848cf0b18d51e0170e0d1537aec3505a"
  local DOMAIN="blackroad.io"
  local BASE="https://api.cloudflare.com/client/v4"

  if [[ -z "$TOKEN" ]]; then
    echo "${RED}✗ CLOUDFLARE_API_TOKEN not set${NC}"; exit 1
  fi

  _cf() { curl -sf -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" "$@"; }

  echo "${BOLD}${CYAN}━━ Email Routing Status: ${DOMAIN} ━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  # zone
  local zone_id
  zone_id=$(_cf "${BASE}/zones?name=${DOMAIN}&account.id=${ACCOUNT}" | python3 -c "import sys,json; z=json.load(sys.stdin)['result']; print(z[0]['id'] if z else '')" 2>/dev/null)
  if [[ -z "$zone_id" ]]; then
    echo "${RED}✗ Zone not found${NC}"; exit 1
  fi

  # routing status
  local routing
  routing=$(_cf "${BASE}/zones/${zone_id}/email/routing" 2>/dev/null)
  echo "$routing" | python3 -c "
import sys, json
d = json.load(sys.stdin).get('result', {})
enabled = d.get('enabled', False)
status  = d.get('status', 'unknown')
GREEN  = '\033[0;32m'; YELLOW = '\033[1;33m'; NC = '\033[0m'; DIM = '\033[2m'
sym = (GREEN + '✓') if enabled else (YELLOW + '⚠')
print(f'  {sym} Email Routing: {status}{NC}')
print(f'  {DIM}  enabled: {enabled}{NC}')
" 2>/dev/null

  # catch-all rule
  local catchall
  catchall=$(_cf "${BASE}/zones/${zone_id}/email/routing/rules/catch_all" 2>/dev/null)
  echo "$catchall" | python3 -c "
import sys, json
d = json.load(sys.stdin).get('result', {})
actions = d.get('actions', [])
GREEN  = '\033[0;32m'; YELLOW = '\033[1;33m'; NC = '\033[0m'; DIM = '\033[2m'
if actions:
    a = actions[0]
    print(f\"  {GREEN}✓ Catch-all: {a.get('type')} → {a.get('value', [])}{NC}\")
else:
    print(f'  {YELLOW}⚠ No catch-all rule set{NC}')
    print(f'  {DIM}  run: br email setup{NC}')
" 2>/dev/null

  echo ""
}

case "${1:-list}" in
  list|ls|"")             cmd_list ;;
  cloudflare|cf|routing)  cmd_cloudflare ;;
  setup)                  cmd_setup ;;
  status|check)           cmd_status ;;
  deploy)                 cmd_deploy ;;
  api|inbox)              cmd_api "${2:-}" ;;
  help|--help|-h)         show_help ;;
  *)                      cmd_show "$1" ;;
esac
