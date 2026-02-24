#!/bin/zsh
# install-blackboxprogramming-webhook.sh
# Installs the @blackboxprogramming webhook on ALL 17 BlackRoad orgs
# Usage: ./install-blackboxprogramming-webhook.sh

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

WEBHOOK_URL="https://blackboxprogramming.blackroad.workers.dev/webhook"
EVENTS='["issues","issue_comment","pull_request","pull_request_review_comment","discussion","discussion_comment","push","create"]'

ORGS=(
  "BlackRoad-OS-Inc"
  "BlackRoad-OS"
  "blackboxprogramming"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Security"
  "BlackRoad-Media"
  "BlackRoad-Foundation"
  "BlackRoad-Interactive"
  "BlackRoad-Hardware"
  "BlackRoad-Labs"
  "BlackRoad-Studio"
  "BlackRoad-Ventures"
  "BlackRoad-Education"
  "BlackRoad-Gov"
  "Blackbox-Enterprises"
  "BlackRoad-Archive"
)

# Check for GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
  GITHUB_TOKEN=$(gh auth token 2>/dev/null)
fi
if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${RED}❌ GITHUB_TOKEN not set. Run: gh auth login${NC}"
  exit 1
fi

# Get or generate webhook secret
if [ -z "$WEBHOOK_SECRET" ]; then
  WEBHOOK_SECRET=$(openssl rand -hex 32)
  echo -e "${YELLOW}⚠️  Generated webhook secret — save this!${NC}"
  echo -e "${CYAN}   WEBHOOK_SECRET=$WEBHOOK_SECRET${NC}"
  echo ""
  echo "   Set it in Cloudflare: wrangler secret put GITHUB_WEBHOOK_SECRET"
  echo "   Value: $WEBHOOK_SECRET"
  echo ""
fi

echo -e "${CYAN}🔧 Installing @blackboxprogramming webhook on all 17 orgs${NC}"
echo -e "   Target: ${WEBHOOK_URL}"
echo ""

SUCCESS=0
FAILED=0

for ORG in "${ORGS[@]}"; do
  echo -n "  📡 $ORG ... "

  # Check if webhook already exists
  EXISTING=$(gh api "orgs/$ORG/hooks" --jq ".[] | select(.config.url == \"$WEBHOOK_URL\") | .id" 2>/dev/null | head -1)

  if [ -n "$EXISTING" ]; then
    echo -e "${YELLOW}already installed (id=$EXISTING)${NC}"
    SUCCESS=$((SUCCESS + 1))
    continue
  fi

  # Install webhook
  RESULT=$(gh api "orgs/$ORG/hooks" \
    --method POST \
    --field "name=web" \
    --field "active=true" \
    --field "config[url]=$WEBHOOK_URL" \
    --field "config[content_type]=json" \
    --field "config[secret]=$WEBHOOK_SECRET" \
    --field "config[insecure_ssl]=0" \
    --raw-field "events[]=${(j:,:)${=EVENTS//[\[\]\"]/}}" \
    2>&1)

  if echo "$RESULT" | grep -q '"id"'; then
    HOOK_ID=$(echo "$RESULT" | python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('id','?'))" 2>/dev/null)
    echo -e "${GREEN}✅ installed (id=$HOOK_ID)${NC}"
    SUCCESS=$((SUCCESS + 1))
  else
    ERROR=$(echo "$RESULT" | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('message','unknown'))" 2>/dev/null || echo "$RESULT" | head -1)
    echo -e "${RED}❌ failed: $ERROR${NC}"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo -e "${GREEN}✅ Done: $SUCCESS installed, $FAILED failed${NC}"
echo ""
echo -e "${CYAN}Test the webhook:${NC}"
echo "  curl -X POST https://blackboxprogramming.blackroad.workers.dev/dispatch \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"request\": \"scan all repos for security issues\", \"actor\": \"test\"}'"
