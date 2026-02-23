#!/bin/bash
# deploy-5-workers.sh — Deploy 5 Cloudflare Workers for blackroad.io subdomains
# Run from the /Users/alexa/blackroad directory
# Usage: bash deploy-5-workers.sh

set -e

CF_TOKEN="PqoOJCg2XDlLCTvp6qBQe9ODWER7Y-O5zCehQeboYZY.BrtLn6-pb0fhGsMub8pMgM0Due2KAnSlOtuaGTWtDus"
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"
ZONE_ID="d6566eba4500b460ffec6650d3b4baf6"
SCRIPT_DIR="/tmp"

NAMES=(gateway-blackroadio cli-blackroadio learn-blackroadio api-v2-blackroadio agents-blackroadio)
SUBS=(gateway cli learn api-v2 agents)

echo "Fetching existing routes..."
ALL_ROUTES=$(curl -s --max-time 30 \
  "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/workers/routes" \
  -H "Authorization: Bearer ${CF_TOKEN}")

declare -A DEPLOY_R DNS_R ROUTE_R HEALTH_R

for i in "${!NAMES[@]}"; do
  W="${NAMES[$i]}"
  SUB="${SUBS[$i]}"
  JS_FILE="${SCRIPT_DIR}/${W}.js"

  echo ""
  echo "════════════════════════════════════════"
  echo "  [$((i+1))/5] $W → $SUB.blackroad.io"
  echo "════════════════════════════════════════"

  # Step 1: Deploy worker
  RESP=$(curl -s --max-time 30 -X PUT \
    "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/workers/scripts/${W}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/javascript" \
    --data-binary "@${JS_FILE}")
  if echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('success') else 1)" 2>/dev/null; then
    DEPLOY_R[$W]="✅ success"
    echo "  Deploy : ✅ success"
  else
    DEPLOY_R[$W]="❌ failed"
    echo "  Deploy : ❌ failed"
    echo "  Error  : $(echo "$RESP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('errors',d))" 2>/dev/null)"
  fi

  # Step 2: DNS AAAA record
  DNS_RESP=$(curl -s --max-time 30 \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${SUB}.blackroad.io&type=AAAA" \
    -H "Authorization: Bearer ${CF_TOKEN}")
  COUNT=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('result_info',{}).get('count',len(d.get('result',[]))))" "$DNS_RESP" 2>/dev/null || echo 0)
  if [[ "$COUNT" -gt 0 ]]; then
    DNS_R[$W]="⚡ existing ($COUNT)"
    echo "  DNS    : ⚡ existing ($COUNT record(s))"
  else
    CR=$(curl -s --max-time 30 -X POST \
      "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"AAAA\",\"name\":\"${SUB}.blackroad.io\",\"content\":\"100::\",\"proxied\":true,\"ttl\":1}")
    if echo "$CR" | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
      DNS_R[$W]="✅ created"
      echo "  DNS    : ✅ created"
    else
      DNS_R[$W]="❌ failed"
      echo "  DNS    : ❌ failed — $(echo "$CR" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('errors',d))" 2>/dev/null)"
    fi
  fi

  # Step 3: Worker route
  REXISTS=$(python3 -c "
import json, sys
routes = json.loads(sys.argv[1]).get('result', [])
found = any('${SUB}.blackroad.io' in r.get('pattern','') for r in routes)
print('true' if found else 'false')
" "$ALL_ROUTES" 2>/dev/null || echo false)
  if [[ "$REXISTS" == "true" ]]; then
    ROUTE_R[$W]="⚡ existing"
    echo "  Route  : ⚡ existing"
  else
    RR=$(curl -s --max-time 30 -X POST \
      "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/workers/routes" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"pattern\":\"${SUB}.blackroad.io/*\",\"script\":\"${W}\"}")
    if echo "$RR" | python3 -c "import sys,json; sys.exit(0 if json.load(sys.stdin).get('success') else 1)" 2>/dev/null; then
      ROUTE_R[$W]="✅ created"
      echo "  Route  : ✅ created"
    else
      ROUTE_R[$W]="❌ failed"
      echo "  Route  : ❌ failed — $(echo "$RR" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('errors',d))" 2>/dev/null)"
    fi
  fi
done

# Health checks
echo ""
echo "⏳ Waiting 10s for propagation..."
sleep 10

for i in "${!NAMES[@]}"; do
  W="${NAMES[$i]}"
  SUB="${SUBS[$i]}"
  CODE=$(curl -s --max-time 15 -o /dev/null -w "%{http_code}" "https://${SUB}.blackroad.io/health" 2>/dev/null || echo "ERR")
  BODY=$(curl -s --max-time 15 "https://${SUB}.blackroad.io/health" 2>/dev/null || echo "{}")
  HEALTH_R[$W]="HTTP $CODE — $BODY"
done

# Results table
echo ""
echo "╔══════════════════════════╦════════════════╦════════════════╦════════════════╦═══════════════════════════════════════════════╗"
echo "║ Worker                   ║ Deploy         ║ DNS            ║ Route          ║ Health Check                                  ║"
echo "╠══════════════════════════╬════════════════╬════════════════╬════════════════╬═══════════════════════════════════════════════╣"
for W in "${NAMES[@]}"; do
  printf "║ %-24s ║ %-14s ║ %-14s ║ %-14s ║ %-45s ║\n" \
    "$W" "${DEPLOY_R[$W]}" "${DNS_R[$W]}" "${ROUTE_R[$W]}" "${HEALTH_R[$W]}"
done
echo "╚══════════════════════════╩════════════════╩════════════════╩════════════════╩═══════════════════════════════════════════════╝"
