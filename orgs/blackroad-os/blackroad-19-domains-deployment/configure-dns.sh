#!/bin/bash

# BlackRoad 19 Domains - Cloudflare DNS Configuration
# Configures A records for all 19 domains pointing to lucidia
# Requires: Cloudflare API token with DNS edit permissions

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
LUCIDIA_IP="192.168.4.38"
CF_API_TOKEN="${CLOUDFLARE_API_TOKEN:-}"

# Check for API token
if [ -z "$CF_API_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  Cloudflare API token not set${NC}"
    echo "Export CLOUDFLARE_API_TOKEN before running this script:"
    echo "  export CLOUDFLARE_API_TOKEN='your_token_here'"
    echo ""
    echo "Or run in manual mode to get configuration commands"
    read -p "Continue in manual mode? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    MANUAL_MODE=true
fi

echo -e "${MAGENTA}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║        🌐 BlackRoad DNS Configuration 🌐                      ║"
echo "║                                                                ║"
echo "║     Cloudflare → lucidia (192.168.4.38)                       ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Domain list
declare -a DOMAINS=(
    "blackboxprogramming.io"
    "blackroad.company"
    "blackroad.io"
    "blackroad.me"
    "blackroad.network"
    "blackroad.systems"
    "blackroadai.com"
    "blackroadinc.us"
    "blackroadqi.com"
    "blackroadquantum.com"
    "blackroadquantum.info"
    "blackroadquantum.net"
    "blackroadquantum.shop"
    "blackroadquantum.store"
    "lucidia.earth"
    "lucidia.studio"
    "lucidiaqi.com"
    "roadchain.io"
    "roadcoin.io"
)

if [ "$MANUAL_MODE" = true ]; then
    echo -e "${CYAN}📋 Manual DNS Configuration Commands:${NC}"
    echo ""
    echo "Log into Cloudflare Dashboard and add these A records:"
    echo ""

    for domain in "${DOMAINS[@]}"; do
        echo -e "${YELLOW}Domain: $domain${NC}"
        echo "  Type: A"
        echo "  Name: @"
        echo "  Content: $LUCIDIA_IP"
        echo "  TTL: Auto"
        echo "  Proxy: Off (DNS only)"
        echo ""
        echo "  Type: CNAME"
        echo "  Name: www"
        echo "  Content: $domain"
        echo "  TTL: Auto"
        echo "  Proxy: Off (DNS only)"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    done

    echo ""
    echo -e "${GREEN}✅ Manual configuration guide generated${NC}"
    echo ""
    echo "After configuring DNS, verify with:"
    echo "  dig @8.8.8.8 blackroad.io +short"

else
    echo -e "${CYAN}🔧 Configuring DNS via Cloudflare API...${NC}"
    echo ""

    for domain in "${DOMAINS[@]}"; do
        echo -e "${YELLOW}→ Configuring $domain...${NC}"

        # Get zone ID
        zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" | jq -r '.result[0].id')

        if [ "$zone_id" = "null" ] || [ -z "$zone_id" ]; then
            echo -e "${YELLOW}  ⚠️  Zone not found (may not be in Cloudflare yet)${NC}"
            continue
        fi

        # Create/update A record for @
        curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"@\",\"content\":\"$LUCIDIA_IP\",\"ttl\":1,\"proxied\":false}" \
            > /dev/null

        # Create/update CNAME for www
        curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"CNAME\",\"name\":\"www\",\"content\":\"$domain\",\"ttl\":1,\"proxied\":false}" \
            > /dev/null

        echo -e "${GREEN}  ✓ Configured${NC}"
    done

    echo ""
    echo -e "${GREEN}✅ DNS configuration complete!${NC}"
fi

echo ""
echo -e "${CYAN}📊 Configuration Summary:${NC}"
echo "  Total domains: ${#DOMAINS[@]}"
echo "  Target IP: $LUCIDIA_IP (lucidia)"
echo "  Name servers: jade.ns.cloudflare.com, chad.ns.cloudflare.com"
echo ""
echo -e "${YELLOW}⏳ DNS propagation may take 5-30 minutes${NC}"
echo ""
echo "Test with:"
echo "  ./test-all-domains.sh"
echo ""
