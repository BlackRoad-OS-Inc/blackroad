#!/bin/zsh
# Setup deploy keys for Pi agents to push to GitHub repos
# Run this once on each Pi, then add the public key to GitHub

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

PI_NAME="${1:-alice}"
KEY_FILE="$HOME/.ssh/blackroad_deploy_ed25519"

echo "${CYAN}🔑 Setting up deploy key for $PI_NAME${NC}"

# Generate key if not exists
if [ ! -f "$KEY_FILE" ]; then
  ssh-keygen -t ed25519 -C "blackroad-deploy-$PI_NAME@$(hostname)" -f "$KEY_FILE" -N ""
  echo "${GREEN}✓ Generated new deploy key${NC}"
else
  echo "  Using existing key: $KEY_FILE"
fi

echo "\n${CYAN}📋 Add this public key to GitHub:${NC}"
echo "  Go to: https://github.com/BlackRoad-OS-Inc/blackroad/settings/keys/new"
echo "  Title: blackroad-deploy-$PI_NAME"
echo "  Allow write: YES"
echo "\n${CYAN}Public key:${NC}"
cat "$KEY_FILE.pub"

echo "\n${CYAN}📋 Then add to SSH config (~/.ssh/config):${NC}"
echo "  Host github.com"
echo "    IdentityFile $KEY_FILE"
echo "    StrictHostKeyChecking no"
