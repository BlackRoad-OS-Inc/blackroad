#!/bin/bash
# Point all blackroad.io subdomains to Pi cluster via Cloudflare tunnel
# Run after Pis are online and tunnel is configured

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

CF_TOKEN="${CF_API_TOKEN:-$1}"
ZONE_ID="${CF_ZONE_ID:-$2}"
TUNNEL_ID="${CF_TUNNEL_ID:-52915859-da18-4aa6-add5-7bd9fcac2e0b}"

[ -z "$CF_TOKEN" ] && { echo "Usage: CF_API_TOKEN=xxx CF_ZONE_ID=xxx $0"; exit 1; }

echo -e "${CYAN}🌐 Configuring Cloudflare DNS for Pi cluster...${NC}"

# Core domains to point to Cloudflare tunnel (Pi cluster)
DOMAINS=(
  "api.blackroad.io"
  "agents.blackroad.io"
  "dashboard.blackroad.io"
  "ops.blackroad.io"
  "console.blackroad.io"
  "alice.blackroad.io"
  "octavia.blackroad.io"
  "aria.blackroad.io"
  "lucidia.blackroad.io"
  "cecilia.blackroad.io"
  "gematria.blackroad.io"
)

for DOMAIN in "${DOMAINS[@]}"; do
  SUBDOMAIN="${DOMAIN%.blackroad.io}"
  
  # Create CNAME to Cloudflare tunnel
  RESULT=$(curl -s -X POST \
    "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"CNAME\",
      \"name\": \"${SUBDOMAIN}\",
      \"content\": \"${TUNNEL_ID}.cfargotunnel.com\",
      \"proxied\": true,
      \"comment\": \"Pi cluster via tunnel - BlackRoad bot\"
    }" 2>/dev/null)
  
  SUCCESS=$(echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d.get('success') else d.get('errors',[{}])[0].get('message','fail'))" 2>/dev/null)
  echo -e "${GREEN}  ${DOMAIN} → tunnel${NC} [${SUCCESS}]"
done

echo -e "${GREEN}✅ DNS configured. Domains pointing to Pi cluster tunnel.${NC}"
echo -e "${CYAN}Fallback chain: Pi → gematria (DO) → CF Pages → GitHub Pages → Railway${NC}"
