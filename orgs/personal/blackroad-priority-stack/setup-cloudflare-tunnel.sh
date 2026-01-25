#!/usr/bin/env bash

# BlackRoad Priority Stack - Cloudflare Tunnel Setup
# Creates and configures public access to all services

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }
info() { echo -e "${BLUE}ℹ${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUNNEL_NAME="blackroad-priority-stack"

echo "======================================"
echo "  Cloudflare Tunnel Setup            "
echo "======================================"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    error "cloudflared is not installed"
    echo ""
    echo "Install with:"
    echo "  brew install cloudflared"
    echo "  # or"
    echo "  curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64 -o /usr/local/bin/cloudflared"
    echo "  chmod +x /usr/local/bin/cloudflared"
    exit 1
fi

success "cloudflared installed: $(cloudflared --version | head -1)"
echo ""

# Check if already logged in
info "Checking Cloudflare authentication..."
if cloudflared tunnel list &> /dev/null; then
    success "Already authenticated with Cloudflare"
else
    warn "Not authenticated with Cloudflare"
    echo ""
    echo "Please log in to Cloudflare:"
    cloudflared tunnel login
fi
echo ""

# Check if tunnel already exists
info "Checking for existing tunnel..."
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
    success "Tunnel '$TUNNEL_NAME' already exists"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
else
    info "Creating new tunnel: $TUNNEL_NAME"
    cloudflared tunnel create "$TUNNEL_NAME"
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    success "Tunnel created: $TUNNEL_ID"
fi
echo ""

# Update config file with tunnel ID
info "Updating tunnel configuration..."
sed -i.bak "s/TUNNEL_ID_PLACEHOLDER/$TUNNEL_ID/g" "$SCRIPT_DIR/cloudflare-tunnel-config.yml"
success "Configuration updated"
echo ""

# Copy config to cloudflared directory
info "Installing configuration..."
mkdir -p ~/.cloudflared
cp "$SCRIPT_DIR/cloudflare-tunnel-config.yml" ~/.cloudflared/config.yml
success "Configuration installed to ~/.cloudflared/config.yml"
echo ""

# Configure DNS routes
info "Configuring DNS routes..."
echo ""

ROUTES=(
    "mesh.blackroad.io"
    "mesh-ui.blackroad.io"
    "identity.blackroad.io"
    "ai.blackroad.io"
    "ai-cpu.blackroad.io"
    "crm.blackroad.io"
)

for route in "${ROUTES[@]}"; do
    if cloudflared tunnel route dns "$TUNNEL_NAME" "$route" 2>&1 | grep -q "already exists\|created"; then
        success "DNS route: $route → $TUNNEL_NAME"
    else
        warn "DNS route failed: $route (may already exist)"
    fi
done
echo ""

# Show tunnel info
info "Tunnel information:"
cloudflared tunnel info "$TUNNEL_NAME"
echo ""

# Create systemd/launchd service
create_service() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - create launchd plist
        PLIST_FILE="$HOME/Library/LaunchAgents/com.cloudflare.cloudflared.$TUNNEL_NAME.plist"

        cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cloudflare.cloudflared.$TUNNEL_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/cloudflared</string>
        <string>tunnel</string>
        <string>--config</string>
        <string>$HOME/.cloudflared/config.yml</string>
        <string>run</string>
        <string>$TUNNEL_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/cloudflared-$TUNNEL_NAME.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/cloudflared-$TUNNEL_NAME-error.log</string>
</dict>
</plist>
EOF

        success "LaunchAgent created: $PLIST_FILE"

        # Load the service
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        launchctl load "$PLIST_FILE"

        success "LaunchAgent loaded (tunnel will auto-start on boot)"
    else
        # Linux - create systemd service
        warn "Linux systemd service creation not implemented"
        echo "Manually create /etc/systemd/system/cloudflared-$TUNNEL_NAME.service"
    fi
}

read -p "Create auto-start service? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    create_service
fi
echo ""

# Summary
echo "======================================"
echo "  Tunnel Setup Complete              "
echo "======================================"
echo ""
echo "Public URLs:"
echo "  • Headscale API:    https://mesh.blackroad.io"
echo "  • Headscale UI:     https://mesh-ui.blackroad.io"
echo "  • Keycloak:         https://identity.blackroad.io"
echo "  • vLLM (GPU):       https://ai.blackroad.io"
echo "  • vLLM (CPU):       https://ai-cpu.blackroad.io"
echo "  • EspoCRM:          https://crm.blackroad.io"
echo ""
echo "Tunnel Status:"
cloudflared tunnel list | grep "$TUNNEL_NAME" || true
echo ""
echo "Commands:"
echo "  Start tunnel:  cloudflared tunnel run $TUNNEL_NAME"
echo "  Stop tunnel:   launchctl unload ~/Library/LaunchAgents/com.cloudflare.cloudflared.$TUNNEL_NAME.plist"
echo "  View logs:     tail -f ~/Library/Logs/cloudflared-$TUNNEL_NAME.log"
echo ""
echo "The tunnel is now running and will auto-start on boot!"
echo ""
