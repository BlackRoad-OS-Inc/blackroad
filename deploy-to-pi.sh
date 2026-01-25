#!/usr/bin/env bash

# BlackRoad Priority Stack - Deploy to Raspberry Pi
# Deploys all services to a remote Pi via SSH

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

# Configuration
PI_HOST="${1:-192.168.4.38}"  # Default to lucidia
PI_USER="${2:-alexa}"
REMOTE_DIR="/home/$PI_USER/blackroad-priority-stack"

echo "======================================"
echo "  Deploy to Raspberry Pi             "
echo "======================================"
echo ""
echo "Target: $PI_USER@$PI_HOST"
echo "Remote directory: $REMOTE_DIR"
echo ""

# Test SSH connection
info "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 "$PI_USER@$PI_HOST" "echo 'Connected'" &>/dev/null; then
    error "Cannot connect to $PI_HOST"
    echo ""
    echo "Available Pis:"
    echo "  192.168.4.38 - lucidia (primary)"
    echo "  192.168.4.64 - blackroad-pi"
    echo "  192.168.4.99 - lucidia (alternate)"
    echo ""
    echo "Usage: $0 <pi-ip> <username>"
    exit 1
fi
success "Connected to $PI_HOST"
echo ""

# Copy files
info "Copying deployment files..."
ssh "$PI_USER@$PI_HOST" "mkdir -p $REMOTE_DIR"

# Copy each service directory
for service in headscale keycloak espocrm; do
    info "Copying $service..."
    rsync -avz --progress \
        ~/blackroad-priority-stack/$service/ \
        "$PI_USER@$PI_HOST:$REMOTE_DIR/$service/"
done

success "Files copied"
echo ""

# Deploy on remote
info "Deploying services on $PI_HOST..."
ssh "$PI_USER@$PI_HOST" bash <<'REMOTE_SCRIPT'
cd /home/alexa/blackroad-priority-stack

# Install docker if needed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed - you may need to log out and back in"
fi

# Deploy services
echo ""
echo "Deploying Headscale..."
cd headscale && docker compose up -d && cd ..

echo ""
echo "Deploying Keycloak..."
cd keycloak && docker compose up -d && cd ..

echo ""
echo "Deploying EspoCRM..."
cd espocrm && docker compose up -d && cd ..

echo ""
echo "Services deployed!"
docker ps | grep blackroad
REMOTE_SCRIPT

success "Deployment complete!"
echo ""

# Update Cloudflare Tunnel config
info "Updating Cloudflare Tunnel configuration..."
warn "You need to update the tunnel ingress to point to $PI_HOST"
echo ""
echo "Edit ~/.cloudflared/config.yml and change:"
echo "  service: http://localhost:8080"
echo "to:"
echo "  service: http://$PI_HOST:8080"
echo ""
echo "Then restart the tunnel:"
echo "  launchctl unload ~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist"
echo "  launchctl load ~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist"
echo ""

echo "======================================"
echo "  Deployment Complete                "
echo "======================================"
echo ""
echo "Services running on: $PI_HOST"
echo ""
echo "Test endpoints:"
echo "  curl http://$PI_HOST:8080/metrics  # Headscale"
echo "  curl http://$PI_HOST:8081          # Headscale UI"
echo "  curl http://$PI_HOST:8082          # Keycloak"
echo "  curl http://$PI_HOST:8085          # EspoCRM"
echo ""
