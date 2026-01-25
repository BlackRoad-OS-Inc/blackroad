#!/bin/bash

# BlackRoad Deploy - Automated Tunnel Setup
# Uses your existing Cloudflare credentials

set -e

CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
CF_ZONE='848cf0b18d51e0170e0d1537aec3505a'
TUNNEL_ID='72f1d60c-dcf2-4499-b02d-d7a063018b33'

echo "☁️ BlackRoad Deploy - Cloudflare Tunnel Setup"
echo "=============================================="

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    echo "📥 Installing cloudflared..."
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
    chmod +x /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/
    echo "✅ cloudflared installed"
else
    echo "✅ cloudflared already installed"
fi

# Add DNS records
echo ""
echo "☁️ Adding DNS record for deploy-api.blackroad.systems"
cloudflared tunnel route dns $TUNNEL_ID deploy-api.blackroad.systems

echo "☁️ Adding DNS record for *.blackroad.systems"
cloudflared tunnel route dns $TUNNEL_ID "*.blackroad.systems"

# Install as service
echo ""
echo "🚀 Installing tunnel as systemd service..."
sudo cloudflared service install

# Start tunnel
echo "▶️ Starting tunnel..."
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# Check status
echo ""
echo "📊 Tunnel status:"
sudo systemctl status cloudflared --no-pager

echo ""
echo "✅ Tunnel setup complete!"
echo ""
echo "🔍 Verify with:"
echo "  curl https://deploy-api.blackroad.systems/health"
