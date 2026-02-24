#!/bin/zsh
# deploy-all-workers.sh — Deploy all BlackRoad domain workers to Cloudflare
# Run from: /Users/alexa/blackroad
# Requires: CLOUDFLARE_API_TOKEN env var with workers:write permission

set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'

WORKERS_DIR="/Users/alexa/blackroad/workers"
SUCCESS=0; FAILED=0; SKIPPED=0

echo -e "\n${CYAN}${BOLD}◆ BlackRoad Workers — Mass Deploy${NC}"
echo -e "${CYAN}Account: 848cf0b18d51e0170e0d1537aec3505a${NC}\n"

if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo -e "${RED}✗ CLOUDFLARE_API_TOKEN not set${NC}"
  echo -e "${YELLOW}  export CLOUDFLARE_API_TOKEN=<your-workers-api-token>${NC}"
  echo -e "${YELLOW}  Get from: https://dash.cloudflare.com/profile/api-tokens${NC}"
  echo -e "${YELLOW}  Required permissions: Workers Scripts Edit, Workers Routes Edit, Zone Read${NC}"
  exit 1
fi

export CLOUDFLARE_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

# Deploy targets: "dir|priority"
declare -a TARGETS=(
  "blackroad-io|1-primary"
  "blackroad-ai|1-primary"
  "blackroad-network|1-primary"
  "blackroad-systems|1-primary"
  "agents-blackroadio|2-key"
  "dashboard-blackroadio|2-key"
  "api-blackroadio|2-key"
  "docs-blackroadio|2-key"
  "console-blackroadio|2-key"
  "ai-blackroadio|2-key"
  "analytics-blackroadio|2-key"
  "status-blackroadio|2-key"
  "about-blackroadio|3-sub"
  "admin-blackroadio|3-sub"
  "algorithms-blackroadio|3-sub"
  "alice-blackroadio|3-sub"
  "asia-blackroadio|3-sub"
  "blockchain-blackroadio|3-sub"
  "blocks-blackroadio|3-sub"
  "blog-blackroadio|3-sub"
  "cdn-blackroadio|3-sub"
  "chain-blackroadio|3-sub"
  "circuits-blackroadio|3-sub"
  "cli-blackroadio|3-sub"
  "compliance-blackroadio|3-sub"
  "compute-blackroadio|3-sub"
  "control-blackroadio|3-sub"
  "data-blackroadio|3-sub"
  "demo-blackroadio|3-sub"
  "design-blackroadio|3-sub"
  "dev-blackroadio|3-sub"
  "edge-blackroadio|3-sub"
  "editor-blackroadio|3-sub"
  "engineering-blackroadio|3-sub"
  "eu-blackroadio|3-sub"
  "events-blackroadio|3-sub"
  "explorer-blackroadio|3-sub"
  "features-blackroadio|3-sub"
  "finance-blackroadio|3-sub"
  "global-blackroadio|3-sub"
  "guide-blackroadio|3-sub"
  "hardware-blackroadio|3-sub"
  "help-blackroadio|3-sub"
  "hr-blackroadio|3-sub"
  "ide-blackroadio|3-sub"
  "network-blackroadio|3-sub"
)

for entry in "${TARGETS[@]}"; do
  IFS='|' read -r DIR PRIORITY <<< "$entry"
  WORKER_DIR="$WORKERS_DIR/$DIR"
  
  if [[ ! -f "$WORKER_DIR/wrangler.toml" ]]; then
    echo -e "${YELLOW}⏭ Skip (no wrangler.toml): $DIR${NC}"
    ((SKIPPED++))
    continue
  fi
  
  echo -ne "${CYAN}→${NC} Deploying ${BOLD}$DIR${NC}... "
  
  cd "$WORKER_DIR"
  
  # Install deps if needed
  if [[ ! -d "node_modules" ]]; then
    npm install --silent 2>/dev/null
  fi
  
  # Deploy
  OUTPUT=$(CLOUDFLARE_API_TOKEN="$CLOUDFLARE_API_TOKEN" npx wrangler deploy 2>&1)
  
  if echo "$OUTPUT" | grep -q "Deployed\|Published\|uploaded"; then
    echo -e "${GREEN}✓ DEPLOYED${NC}"
    ((SUCCESS++))
  else
    echo -e "${RED}✗ FAILED${NC}"
    echo "$OUTPUT" | grep -E "ERROR|error" | head -3 | sed 's/^/    /'
    ((FAILED++))
  fi
  
  cd "$WORKERS_DIR"
done

echo ""
echo -e "${CYAN}${BOLD}═══ Deploy Summary ═══${NC}"
echo -e "${GREEN}  ✓ Success: $SUCCESS${NC}"
echo -e "${RED}  ✗ Failed:  $FAILED${NC}"
echo -e "${YELLOW}  ⏭ Skipped: $SKIPPED${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All workers deployed! 🚀${NC}"
  echo ""
  echo -e "${CYAN}Live domains:${NC}"
  echo "  https://blackroad.io"
  echo "  https://agents.blackroad.io"
  echo "  https://dashboard.blackroad.io"
  echo "  https://api.blackroad.io"
  echo "  https://status.blackroad.io"
  echo "  https://blackroad.ai"
fi
