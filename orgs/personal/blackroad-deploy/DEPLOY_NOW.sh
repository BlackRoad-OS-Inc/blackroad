#!/bin/bash

# BlackRoad Deploy - One-Command Deployment Script
# Run this on your DigitalOcean droplet or Raspberry Pi

set -e

echo "🚀 BlackRoad Deploy - Automated Setup"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root: sudo ./DEPLOY_NOW.sh${NC}"
  exit 1
fi

# Detect if this is a Pi
IS_PI=false
if [[ $(uname -m) == "aarch64" ]] || [[ $(uname -m) == "armv7l" ]]; then
  IS_PI=true
  echo -e "${GREEN}Detected Raspberry Pi${NC}"
else
  echo -e "${GREEN}Detected x86_64 server${NC}"
fi

# 1. Install Docker
echo ""
echo "📦 Installing Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  systemctl enable docker
  systemctl start docker
  echo -e "${GREEN}✅ Docker installed${NC}"
else
  echo -e "${GREEN}✅ Docker already installed${NC}"
fi

# 2. Install Docker Compose
echo ""
echo "📦 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
  apt-get update
  apt-get install -y docker-compose
  echo -e "${GREEN}✅ Docker Compose installed${NC}"
else
  echo -e "${GREEN}✅ Docker Compose already installed${NC}"
fi

# 3. Clone repository
echo ""
echo "📥 Cloning BlackRoad Deploy..."
cd /opt
if [ -d "blackroad-deploy" ]; then
  echo -e "${YELLOW}Directory exists, pulling latest...${NC}"
  cd blackroad-deploy
  git pull
else
  git clone https://github.com/blackboxprogramming/blackroad-deploy.git
  cd blackroad-deploy
fi

# 4. Set up environment
echo ""
echo "⚙️ Configuring environment..."
if [ ! -f .env ]; then
  cp .env.example .env

  # Generate random database password
  DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

  # Update .env file
  sed -i "s/your_secure_password_here/$DB_PASSWORD/" .env
  sed -i "s/your_cloudflare_api_token/yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy/" .env

  echo -e "${GREEN}✅ Environment configured${NC}"
  echo -e "${YELLOW}Database password: $DB_PASSWORD${NC}"
else
  echo -e "${YELLOW}⚠️ .env already exists, skipping...${NC}"
fi

# 5. Start services
echo ""
echo "🚀 Starting services..."
docker-compose down 2>/dev/null || true
docker-compose up -d

# Wait for services to be healthy
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service status
echo ""
echo "📊 Service Status:"
docker-compose ps

# 6. Install cloudflared
echo ""
echo "☁️ Installing cloudflared..."
if ! command -v cloudflared &> /dev/null; then
  if [ "$IS_PI" = true ]; then
    if [[ $(uname -m) == "aarch64" ]]; then
      curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /tmp/cloudflared
    else
      curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o /tmp/cloudflared
    fi
  else
    curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /tmp/cloudflared
  fi

  chmod +x /tmp/cloudflared
  mv /tmp/cloudflared /usr/local/bin/cloudflared
  echo -e "${GREEN}✅ cloudflared installed${NC}"
else
  echo -e "${GREEN}✅ cloudflared already installed${NC}"
fi

# 7. Set up Cloudflare Tunnel config
echo ""
echo "☁️ Setting up Cloudflare Tunnel..."
mkdir -p /root/.cloudflared

cat > /root/.cloudflared/config.yml <<EOF
tunnel: 72f1d60c-dcf2-4499-b02d-d7a063018b33
credentials-file: /root/.cloudflared/72f1d60c-dcf2-4499-b02d-d7a063018b33.json

ingress:
  - hostname: deploy-api.blackroad.systems
    service: http://localhost:3000
  - hostname: "*.blackroad.systems"
    service: http://localhost:8080
  - service: http_status:404
EOF

echo -e "${GREEN}✅ Tunnel config created${NC}"

# 8. Show next steps
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}🎉 BlackRoad Deploy Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Set up Cloudflare Tunnel credentials:"
echo "   ${YELLOW}cloudflared tunnel login${NC}"
echo "   (This will open a browser - follow the prompts)"
echo ""
echo "2. Route DNS:"
echo "   ${YELLOW}cloudflared tunnel route dns 72f1d60c-dcf2-4499-b02d-d7a063018b33 deploy-api.blackroad.systems${NC}"
echo "   ${YELLOW}cloudflared tunnel route dns 72f1d60c-dcf2-4499-b02d-d7a063018b33 \"*.blackroad.systems\"${NC}"
echo ""
echo "3. Start the tunnel:"
echo "   ${YELLOW}cloudflared service install${NC}"
echo "   ${YELLOW}systemctl start cloudflared${NC}"
echo "   ${YELLOW}systemctl enable cloudflared${NC}"
echo ""
echo "4. Create your first user:"
echo "   ${YELLOW}curl -X POST https://deploy-api.blackroad.systems/api/auth/register \\${NC}"
echo "   ${YELLOW}  -H \"Content-Type: application/json\" \\${NC}"
echo "   ${YELLOW}  -d '{\"email\": \"amundsonalexa@gmail.com\", \"password\": \"your_password\"}'${NC}"
echo ""
echo "5. Install CLI on your local machine:"
echo "   ${YELLOW}cd ~/blackroad-deploy/cli${NC}"
echo "   ${YELLOW}npm install && npm run build && npm link${NC}"
echo ""
echo "Repository: ${GREEN}https://github.com/blackboxprogramming/blackroad-deploy${NC}"
echo ""
