#!/bin/bash
# BlackRoad Railway → Pi Gateway Integration
# Sets BLACKROAD_GATEWAY_URL on all Railway projects

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

GATEWAY_URL="https://api.blackroad.io"
PI_DIRECT="http://192.168.4.38:4010"
AGENT_MESH="https://agents.blackroad.io"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚂 BlackRoad Railway Integration"
echo "  Host: $(hostname)"
echo "  Gateway: $GATEWAY_URL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! railway whoami &>/dev/null; then
  echo "⚠️  Not authenticated — run: railway login"
  exit 1
fi

echo -e "${CYAN}Setting up Railway integration...${NC}"

# Get list of all projects
PROJECTS=$(railway list 2>/dev/null | grep -v "^Alexa\|^\s*$" | tr -d ' ')

SUCCESS=0; FAIL=0
while IFS= read -r project; do
  [[ -z "$project" ]] && continue
  
  # Link project
  if railway link --project "$project" &>/dev/null; then
    # Set gateway vars (no-deploy to avoid charges)
    if railway variables \
      --set "BLACKROAD_GATEWAY_URL=$GATEWAY_URL" \
      --set "BLACKROAD_PI_GATEWAY=$PI_DIRECT" \
      --set "BLACKROAD_AGENT_MESH=$AGENT_MESH" \
      --set "NODE_OCTAVIA=192.168.4.38" \
      --set "NODE_GEMATRIA=159.65.43.12" \
      --skip-deploys &>/dev/null; then
      echo -e "  ${GREEN}✅${NC} $project"
      SUCCESS=$((SUCCESS+1))
    else
      echo -e "  ${YELLOW}⚠️${NC}  $project (no service)"
      FAIL=$((FAIL+1))
    fi
  fi
done <<< "$PROJECTS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}✅ $SUCCESS${NC} projects configured"
[[ $FAIL -gt 0 ]] && echo -e "  ${YELLOW}⚠️  $FAIL${NC} skipped (no service)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
