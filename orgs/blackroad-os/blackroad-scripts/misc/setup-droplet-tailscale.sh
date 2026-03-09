#!/bin/bash
# Setup Tailscale on droplet (shellfish) to accept routes from Mac
# Run this ON THE DROPLET: ssh root@174.138.44.45 'bash -s' < setup-droplet-tailscale.sh

set -euo pipefail

if [[ -z "${HEADSCALE_AUTHKEY:-}" ]]; then
    echo "❌ Error: HEADSCALE_AUTHKEY not set"
    echo "Usage: HEADSCALE_AUTHKEY=key bash setup-droplet-tailscale.sh"
    exit 1
fi

HEADSCALE_URL="https://headscale.blackroad.io"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setting up Tailscale on Droplet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo "📦 Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "✅ Tailscale already installed"
fi

# Configure Tailscale to accept routes
echo "🔧 Configuring Tailscale..."
sudo tailscale up \
    --login-server="$HEADSCALE_URL" \
    --authkey="$HEADSCALE_AUTHKEY" \
    --accept-routes

echo ""
echo "✅ Tailscale configured!"
echo ""
echo "📊 Status:"
tailscale status

echo ""
echo "🔍 Checking routes:"
ip route | grep -E "192.168.4|100\." || echo "No routes found yet"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next steps:"
echo "  1. Enable subnet route in Headscale"
echo "  2. Test: ping 100.95.120.67 (Mac)"
echo "  3. Test: ping 192.168.4.38 (Lucidia)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
