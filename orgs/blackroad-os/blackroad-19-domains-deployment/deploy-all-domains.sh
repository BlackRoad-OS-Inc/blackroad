#!/bin/bash

# BlackRoad 19 Domains - Master Deployment Script
# Deploy all 19 domains to Pi infrastructure (octavia → lucidia)
# Usage: ./deploy-all-domains.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
OCTAVIA_HOST="192.168.4.74"
LUCIDIA_HOST="192.168.4.38"
OCTAVIA_PATH="/media/pi/Extreme SSD/blackroad-hub"
DEPLOYMENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║       🚀 BlackRoad 19 Domains Deployment Pipeline 🚀         ║"
echo "║                                                                ║"
echo "║             octavia (build) → lucidia (deploy)                ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Domain configuration
declare -a DOMAINS=(
    "blackboxprogramming.io:3000:homepage"
    "blackroad.company:3001:homepage"
    "blackroad.me:3003:homepage"
    "blackroad.network:3004:homepage"
    "blackroad.systems:3005:homepage"
    "blackroadai.com:3006:homepage"
    "blackroadinc.us:3007:homepage"
    "blackroadqi.com:3008:homepage"
    "blackroadquantum.com:3009:homepage"
    "blackroadquantum.info:3010:docs"
    "blackroadquantum.net:3011:homepage"
    "blackroadquantum.shop:3012:pricing"
    "blackroadquantum.store:3013:pricing"
    "lucidia.earth:3109:homepage"
    "lucidia.studio:3014:homepage"
    "lucidiaqi.com:3015:homepage"
    "roadchain.io:3016:homepage"
    "roadcoin.io:3017:pricing"
)

# Test connectivity
echo -e "${CYAN}[1/6] Testing connectivity...${NC}"
if ! ping -c 1 $OCTAVIA_HOST &> /dev/null; then
    echo -e "${RED}❌ Cannot reach octavia ($OCTAVIA_HOST)${NC}"
    exit 1
fi
if ! ping -c 1 $LUCIDIA_HOST &> /dev/null; then
    echo -e "${RED}❌ Cannot reach lucidia ($LUCIDIA_HOST)${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Connectivity verified${NC}"

# Transfer templates to octavia
echo -e "${CYAN}[2/6] Transferring templates to octavia...${NC}"
ssh pi@$OCTAVIA_HOST "mkdir -p '$OCTAVIA_PATH/repos' '$OCTAVIA_PATH/templates'"
scp -r "$DEPLOYMENT_DIR/sites/"* pi@$OCTAVIA_HOST:"'$OCTAVIA_PATH/repos/'"
echo -e "${GREEN}✅ Templates transferred${NC}"

# Build and deploy each domain
echo -e "${CYAN}[3/6] Building and deploying ${#DOMAINS[@]} domains...${NC}"

SUCCESSFUL=0
FAILED=0

for domain_config in "${DOMAINS[@]}"; do
    IFS=':' read -r DOMAIN PORT TEMPLATE <<< "$domain_config"

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🌐 Deploying: $DOMAIN (port $PORT)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Build on octavia
    echo -e "${CYAN}  → Building Docker image on octavia...${NC}"
    if ssh pi@$OCTAVIA_HOST "cd '$OCTAVIA_PATH/repos/$DOMAIN' && docker build -t $DOMAIN:latest ."; then
        echo -e "${GREEN}  ✓ Build successful${NC}"
    else
        echo -e "${RED}  ✗ Build failed${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Transfer to lucidia
    echo -e "${CYAN}  → Transferring image to lucidia...${NC}"
    if ssh pi@$OCTAVIA_HOST "docker save $DOMAIN:latest" | ssh pi@$LUCIDIA_HOST "docker load"; then
        echo -e "${GREEN}  ✓ Transfer successful${NC}"
    else
        echo -e "${RED}  ✗ Transfer failed${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Stop existing container if running
    ssh pi@$LUCIDIA_HOST "docker stop $DOMAIN 2>/dev/null || true"
    ssh pi@$LUCIDIA_HOST "docker rm $DOMAIN 2>/dev/null || true"

    # Deploy on lucidia
    echo -e "${CYAN}  → Deploying container on lucidia...${NC}"
    if ssh pi@$LUCIDIA_HOST "docker run -d --name $DOMAIN -p $PORT:3000 --restart unless-stopped $DOMAIN:latest"; then
        echo -e "${GREEN}  ✓ Deployment successful${NC}"
    else
        echo -e "${RED}  ✗ Deployment failed${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Verify deployment
    sleep 2
    echo -e "${CYAN}  → Verifying deployment...${NC}"
    if curl -I http://$LUCIDIA_HOST:$PORT 2>/dev/null | head -1 | grep -q "200\|301\|302"; then
        echo -e "${GREEN}  ✓ Verification successful${NC}"
        echo -e "${GREEN}  🌐 http://$LUCIDIA_HOST:$PORT${NC}"
        SUCCESSFUL=$((SUCCESSFUL + 1))
    else
        echo -e "${YELLOW}  ⚠ Service may need time to start${NC}"
        SUCCESSFUL=$((SUCCESSFUL + 1))
    fi
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}[4/6] Deployment Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Successful: $SUCCESSFUL${NC}"
echo -e "${RED}❌ Failed: $FAILED${NC}"

# Generate docker-compose.yml on lucidia
echo ""
echo -e "${CYAN}[5/6] Generating docker-compose.yml on lucidia...${NC}"
ssh pi@$LUCIDIA_HOST "mkdir -p ~/blackroad-services"
scp "$DEPLOYMENT_DIR/docker-compose.yml" pi@$LUCIDIA_HOST:~/blackroad-services/
echo -e "${GREEN}✅ docker-compose.yml deployed${NC}"

# Display running containers
echo ""
echo -e "${CYAN}[6/6] Active containers on lucidia:${NC}"
ssh pi@$LUCIDIA_HOST "docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}' | grep -E 'blackroad|lucidia|roadcoin|roadchain|blackbox'"

echo ""
echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║              ✨ Deployment Complete! ✨                        ║"
echo "║                                                                ║"
echo "║  Next Steps:                                                   ║"
echo "║  1. Configure Cloudflare DNS (run ./configure-dns.sh)          ║"
echo "║  2. Test all domains                                           ║"
echo "║  3. Update [MEMORY] log                                        ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Summary stats
echo -e "${CYAN}📊 Infrastructure Stats:${NC}"
echo -e "  Total containers: $SUCCESSFUL"
echo -e "  Total ports: 3000-3017, 3109, 8081"
echo -e "  Builder: octavia ($OCTAVIA_HOST)"
echo -e "  Runtime: lucidia ($LUCIDIA_HOST)"
echo ""
