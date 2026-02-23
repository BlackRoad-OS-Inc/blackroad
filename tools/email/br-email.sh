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
  echo ""
  echo "  ${DIM}Agents: lucidia alice octavia aria cecilia cipher${NC}"
  echo "  ${DIM}        prism echo oracle atlas shellfish gematria anastasia${NC}"
  echo ""
}

case "${1:-list}" in
  list|ls|"")   cmd_list ;;
  cloudflare|cf|routing) cmd_cloudflare ;;
  help|--help|-h) show_help ;;
  *)            cmd_show "$1" ;;
esac
