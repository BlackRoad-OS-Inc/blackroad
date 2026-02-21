#!/bin/bash
# BlackRoad Cloudflare DNS Configuration
# Points all 19 domains to Pi cluster and DO droplets

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🖤 BLACKROAD CLOUDFLARE DNS SETUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Target IPs
ALICE_IP="192.168.4.49"
LUCIDIA_IP="192.168.4.38"
CODEX_IP="159.65.43.12"
SHELLFISH_IP="174.138.44.45"

# Cloudflare Account ID
CF_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

# Domains to configure
DOMAINS=(
  "aliceqi.com"
  "blackboxprogramming.io"
  "blackroadai.com"
  "blackroad.company"
  "blackroadinc.us"
  "blackroad.io"
  "blackroad.me"
  "blackroad.network"
  "blackroadqi.com"
  "blackroadquantum.com"
  "blackroadquantum.info"
  "blackroadquantum.net"
  "blackroadquantum.shop"
  "blackroadquantum.store"
  "blackroad.systems"
  "lucidiaqi.com"
  "lucidia.studio"
  "roadchain.io"
  "roadcoin.io"
)

echo "📋 Configuration Strategy:"
echo ""
echo "  Primary (Public): $CODEX_IP (codex-infinity)"
echo "  Secondary: $SHELLFISH_IP (shellfish)"
echo "  Pi Cluster: $ALICE_IP, $LUCIDIA_IP (local network)"
echo ""
echo "We'll use Cloudflare Tunnel OR direct IP configuration"
echo ""

# Check if we have CF API access
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler not found. Install with: npm install -g wrangler"
    exit 1
fi

echo "🔍 Checking Cloudflare authentication..."
wrangler whoami 2>&1 | head -5

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "DNS Update Options:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Option 1: Point to Public DigitalOcean Droplets"
echo "  • Immediate access"
echo "  • Use $CODEX_IP or $SHELLFISH_IP"
echo ""
echo "Option 2: Use Cloudflare Tunnel (Recommended for Pi)"
echo "  • Secure zero-trust access"
echo "  • No port forwarding needed"
echo "  • Encrypts traffic"
echo ""
echo "Option 3: Manual DNS via Cloudflare Dashboard"
echo "  • Visit: dash.cloudflare.com"
echo "  • Add A records pointing to IPs"
echo ""

# Generate wrangler commands for DNS updates
echo "🔧 Generated Commands:"
echo ""
echo "# To point domains to codex-infinity (public):"
for domain in "${DOMAINS[@]}"; do
  echo "wrangler dns create $domain A @ --content $CODEX_IP --proxied false"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
