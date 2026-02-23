#!/bin/bash
# Set up GitHub org webhooks to notify Pi fleet on any push
set -euo pipefail
CYAN='\033[0;36m'; GREEN='\033[0;32m'; NC='\033[0m'

# Webhook endpoint (cloudflare tunnel → cecilia → port 4010)
WEBHOOK_URL="https://agents.blackroad.io/webhooks/github"
SECRET="blackroad-webhook-$(date +%s)"

ORGS=(
  "BlackRoad-OS-Inc"
  "BlackRoad-OS"
  "blackboxprogramming"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Security"
)

echo -e "${CYAN}🔗 Setting up org webhooks → ${WEBHOOK_URL}${NC}"
for ORG in "${ORGS[@]}"; do
  echo -n "  $ORG... "
  gh api --method POST "/orgs/$ORG/hooks" \
    -f "config[url]=$WEBHOOK_URL" \
    -f "config[content_type]=json" \
    -f "config[secret]=$SECRET" \
    -f "events[]=push" \
    -f "events[]=pull_request" \
    -f "events[]=workflow_run" \
    -F "active=true" 2>&1 | grep -q '"id"' && echo -e "${GREEN}✅${NC}" || echo "⚠️ (check permissions)"
done
echo "Webhook secret: $SECRET"
echo -e "${GREEN}✅ Org webhooks configured${NC}"
