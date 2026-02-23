#!/bin/zsh
# Sync Pi fleet configs to git for version control
set -e

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

echo "${CYAN}📡 Syncing Pi fleet configs to git...${NC}"

mkdir -p infra/cloudflared infra/nginx

# Pull latest cloudflared config from alice
echo "  Pulling alice cloudflared config..."
sshpass -p alice ssh -o StrictHostKeyChecking=no alice@192.168.4.49 \
  "sudo cat /etc/cloudflared/config.yml" > infra/cloudflared/alice-config.yml 2>/dev/null || \
  echo "  ⚠ Could not pull alice config (SSH unavailable)"

# Pull nginx config if present
sshpass -p alice ssh -o StrictHostKeyChecking=no alice@192.168.4.49 \
  "cat /etc/nginx/sites-enabled/default 2>/dev/null || echo '# no nginx'" > infra/nginx/alice-nginx.conf 2>/dev/null || true

# Pull aria config
sshpass -p pi ssh -o StrictHostKeyChecking=no pi@192.168.4.38 \
  "sudo cat /etc/cloudflared/config.yml" > infra/cloudflared/aria-config.yml 2>/dev/null || \
  echo "  ⚠ Could not pull aria config"

echo "${GREEN}✓ Pi configs synced to infra/cloudflared/${NC}"
