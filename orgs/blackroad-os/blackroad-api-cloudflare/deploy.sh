#!/usr/bin/env bash
# Deploy BLACKROAD API to Cloudflare Workers
# Author: ARES (claude-ares-1766972574)

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🚀 DEPLOYING BLACKROAD API TO CLOUDFLARE WORKERS 🚀   ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if in correct directory
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}Changing to API directory...${NC}"
    cd ~/blackroad-api-cloudflare
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${GREEN}Installing dependencies...${NC}"
    npm install
fi

# Check authentication
echo -e "${GREEN}Checking Cloudflare authentication...${NC}"
if ! wrangler whoami &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in. Running: wrangler login${NC}"
    wrangler login
fi

# Ask for environment
echo -e "${CYAN}Select deployment environment:${NC}"
echo "  1) Staging (workers.dev)"
echo "  2) Production (api.blackroad.io)"
echo ""
read -p "Choice [1-2]: " choice

case $choice in
    1)
        ENV="staging"
        echo -e "${GREEN}Deploying to STAGING...${NC}"
        ;;
    2)
        ENV="production"
        echo -e "${GREEN}Deploying to PRODUCTION...${NC}"
        ;;
    *)
        echo -e "${YELLOW}Invalid choice. Deploying to staging by default.${NC}"
        ENV="staging"
        ;;
esac

# Deploy
echo ""
echo -e "${GREEN}Deploying API worker...${NC}"
wrangler deploy --env $ENV

# Get deployment URL
if [ "$ENV" = "production" ]; then
    API_URL="https://api.blackroad.io"
else
    API_URL=$(wrangler deployments list --name blackroad-api 2>/dev/null | grep -oE 'https://[a-z0-9-]+\.workers\.dev' | head -1 || echo "https://blackroad-api.workers.dev")
fi

echo ""
echo -e "${GREEN}✅ API deployed successfully!${NC}"
echo ""
echo -e "${CYAN}API Endpoints:${NC}"
echo -e "  ${GREEN}Stats:${NC}       $API_URL/api/stats"
echo -e "  ${GREEN}Agents:${NC}      $API_URL/api/agents"
echo -e "  ${GREEN}Leaderboard:${NC} $API_URL/api/leaderboard"
echo -e "  ${GREEN}Activity:${NC}    $API_URL/api/activity"
echo -e "  ${GREEN}Namespaces:${NC}  $API_URL/api/namespaces"
echo -e "  ${GREEN}Bots:${NC}        $API_URL/api/bots"
echo -e "  ${GREEN}Tasks:${NC}       $API_URL/api/tasks"
echo -e "  ${GREEN}Health:${NC}      $API_URL/health"
echo ""
echo -e "${YELLOW}Test:${NC} curl $API_URL/health"
echo ""

# Log to memory
if [ -f ~/memory-system.sh ]; then
    ~/memory-system.sh log deployed "blackroad-api" "Deployed to Cloudflare Workers ($ENV): $API_URL" "ares" 2>/dev/null || true
fi
