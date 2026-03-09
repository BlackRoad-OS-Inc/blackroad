#!/bin/bash
# Setup Tailscale/Headscale subnet routing for BlackRoad network
# This makes: Termius (iPhone) → Droplet → MacBook → Pis work

set -euo pipefail

HEADSCALE_URL="https://headscale.blackroad.io"
SUBNET_CIDR="192.168.4.0/22"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  BlackRoad Subnet Routing Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will configure:"
echo "  MacBook → Subnet router for $SUBNET_CIDR"
echo "  Droplet → Accept routes from MacBook"
echo "  Result → SSH from anywhere to Pis via droplet"
echo ""

# Check if running on Mac
if [[ "$(uname)" != "Darwin" ]]; then
    echo "⚠️  This script should be run on your Mac"
    echo "   For droplet setup, see instructions below"
    exit 1
fi

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "📦 Installing Tailscale..."
    brew install tailscale
    sudo brew services start tailscale
fi

# Check for authkey
if [[ -z "${HEADSCALE_AUTHKEY:-}" ]]; then
    echo "❌ Error: HEADSCALE_AUTHKEY not set"
    echo ""
    echo "Get your authkey from Headscale:"
    echo "  1. SSH to your Headscale server"
    echo "  2. Run: headscale preauthkeys create --reusable --expiration 90d"
    echo "  3. Copy the key"
    echo ""
    echo "Usage: HEADSCALE_AUTHKEY=your_key ./setup-subnet-routing.sh"
    exit 1
fi

echo "🔧 Configuring MacBook as subnet router..."
sudo tailscale up \
  --login-server="$HEADSCALE_URL" \
  --authkey="$HEADSCALE_AUTHKEY" \
  --advertise-routes="$SUBNET_CIDR" \
  --accept-routes \
  --accept-dns=false

echo ""
echo "✅ MacBook configured as subnet router"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Next Steps:"
echo ""
echo "1. Approve the route in Headscale:"
echo "   SSH to your Headscale server and run:"
echo "   headscale routes list"
echo "   headscale routes enable -r <route-id>"
echo ""
echo "2. Set up the droplet:"
echo "   SSH to shellfish (174.138.44.45) and run:"
echo ""
echo "   curl -fsSL https://tailscale.com/install.sh | sh"
echo "   sudo tailscale up \\"
echo "     --login-server=$HEADSCALE_URL \\"
echo "     --authkey=$HEADSCALE_AUTHKEY \\"
echo "     --accept-routes"
echo ""
echo "3. Test from droplet:"
echo "   ping -c 1 192.168.4.38  # Lucidia"
echo "   ping -c 1 192.168.4.64  # Aria"
echo "   ping -c 1 192.168.4.49  # Alice"
echo ""
echo "4. Add SSH config to Termius:"
echo "   See: TERMIUS_SSH_CONFIG.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
