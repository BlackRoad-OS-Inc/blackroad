#!/usr/bin/env bash
# setup-pi-agent.sh — Full Pi agent setup (run with: bash setup-pi-agent.sh <node-name>)
# Installs: nginx, gh CLI, huggingface-hub, runner
# Usage: ssh octavia "bash -s" < scripts/setup-pi-agent.sh octavia
set -euo pipefail

NODE="${1:-$(hostname)}"
RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

info "Setting up Pi agent: $NODE"

# 1. nginx
if ! command -v nginx &>/dev/null; then
  info "Installing nginx..."
  sudo apt-get update -qq && sudo apt-get install -y nginx 2>/dev/null
  log "nginx installed"
else
  log "nginx already installed: $(nginx -v 2>&1)"
fi

# 2. gh CLI
if ! command -v gh &>/dev/null; then
  info "Installing gh CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq && sudo apt-get install -y gh
  log "gh CLI installed: $(gh --version | head -1)"
else
  log "gh already installed: $(gh --version | head -1)"
fi

# 3. HuggingFace CLI
if ! python3 -c "import huggingface_hub" 2>/dev/null; then
  info "Installing huggingface-hub..."
  pip3 install --user --quiet "huggingface_hub[cli]"
  log "huggingface-hub installed"
else
  log "huggingface-hub already installed"
fi

# 4. rclone (for gdrive sync)
if ! command -v rclone &>/dev/null; then
  info "Installing rclone..."
  curl -s https://rclone.org/install.sh | sudo bash -s stable 2>/dev/null
  log "rclone installed: $(rclone version --check 2>/dev/null | head -1)"
else
  log "rclone already installed"
fi

# 5. Setup ~/.blackroad config dirs
mkdir -p ~/.blackroad/logs ~/.blackroad/memory/journals ~/.blackroad/memory/sessions

# 6. Write node identity
cat > ~/.blackroad/node-identity.json << IDENTITY
{
  "node": "$NODE",
  "hostname": "$(hostname)",
  "ip": "$(hostname -I | awk '{print $1}')",
  "arch": "$(uname -m)",
  "setup_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "services": ["nginx", "gh", "huggingface-hub", "rclone", "ollama"]
}
IDENTITY
log "Node identity written"

# 7. Enable nginx service
sudo systemctl enable nginx 2>/dev/null && sudo systemctl start nginx 2>/dev/null && log "nginx service started" || warn "nginx service start (may need manual start)"

echo ""
echo -e "  ${GREEN}✅ $NODE fully configured${NC}"
echo "  Run runner setup: bash ~/install-runner.sh $NODE 'self-hosted,pi,$NODE,linux,arm64' blackboxprogramming/blackroad <TOKEN>"
