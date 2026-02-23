#!/usr/bin/env bash
# setup-email-routing.sh — Configure Cloudflare Email Routing for agent addresses
# Usage: ./setup-email-routing.sh <cloudflare_zone_id> <destination_email>
# Requires: CLOUDFLARE_API_TOKEN env var

set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; DIM='\033[2m'; NC='\033[0m'

ZONE_ID="${1:-}"
DEST="${2:-alexa@blackroad.io}"
CF_TOKEN="${CLOUDFLARE_API_TOKEN:-}"

[[ -z "$ZONE_ID" ]] && echo -e "${RED}Usage: $0 <zone_id> [destination_email]${NC}" && exit 1
[[ -z "$CF_TOKEN" ]] && echo -e "${RED}Set CLOUDFLARE_API_TOKEN${NC}" && exit 1

CF_API="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/email/routing/rules"

declare -a ADDRESSES=(
  "lucidia@blackroad.io"
  "alice@blackroad.io"
  "octavia@blackroad.io"
  "prism@blackroad.io"
  "echo@blackroad.io"
  "cipher@blackroad.io"
  "aria@blackroad.io"
  "shellfish@blackroad.io"
  "cece@blackroad.io"
  "agents@blackroad.io"
  "security@blackroad.io"
  "ops@blackroad.io"
  "hello@blackroad.io"
  "identity@blackroad.io"
  "l@blackroad.io"
  "dreamer@blackroad.io"
  "vault@blackroad.io"
  "pentest@blackroad.io"
  "red@blackroad.io"
  "data@blackroad.io"
  "memory@blackroad.io"
  "archive@blackroad.io"
  "design@blackroad.io"
  "ux@blackroad.io"
  "compute@blackroad.io"
  "arch@blackroad.io"
  "analytics@blackroad.io"
)

echo -e "\n${CYAN}Setting up Cloudflare Email Routing → ${DEST}${NC}\n"

ok=0; fail=0
for addr in "${ADDRESSES[@]}"; do
  payload=$(python3 -c "
import json,sys
addr,dest=sys.argv[1],sys.argv[2]
rule={
  'actions':[{'type':'forward','value':[dest]}],
  'enabled':True,
  'matchers':[{'field':'to','type':'literal','value':addr}],
  'name':f'Route {addr}'
}
print(json.dumps(rule))" "$addr" "$DEST")

  resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$CF_API" \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")

  if [[ "$resp" == "200" || "$resp" == "201" ]]; then
    echo -e "  ${GREEN}✓${NC} ${addr} → ${DEST}"
    (( ok++ ))
  else
    echo -e "  ${RED}✗${NC} ${addr}  (HTTP ${resp})"
    (( fail++ ))
  fi
done

echo -e "\n${DIM}Done: ${ok} created, ${fail} failed${NC}"
