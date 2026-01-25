#!/bin/bash

# BlackRoad Deploy - Raspberry Pi Tunnel Setup
# Run this on your Raspberry Pi (192.168.4.49)

set -e

echo "🥧 BlackRoad Deploy - Raspberry Pi Setup"
echo "=========================================="

# Detect architecture
ARCH=$(uname -m)
echo "Architecture: $ARCH"

# Install cloudflared
if ! command -v cloudflared &> /dev/null; then
    echo "📥 Installing cloudflared..."

    if [ "$ARCH" = "aarch64" ]; then
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /tmp/cloudflared
    elif [ "$ARCH" = "armv7l" ]; then
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o /tmp/cloudflared
    else
        echo "❌ Unsupported architecture: $ARCH"
        exit 1
    fi

    chmod +x /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/
    echo "✅ cloudflared installed"
else
    echo "✅ cloudflared already installed"
fi

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo usermod -aG docker $USER
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "📦 Installing Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Log in to Cloudflare: cloudflared tunnel login"
echo "  2. Create tunnel: cloudflared tunnel create blackroad-pi"
echo "  3. Configure tunnel (see TUNNEL_SETUP.md)"
echo "  4. Start tunnel: sudo systemctl start cloudflared"
