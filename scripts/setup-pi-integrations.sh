#!/bin/bash
# BLACKROAD PI INTEGRATION SETUP
# Installs: wrangler, railway, gh, sfdx, rclone, huggingface-hub on all Pis
# Run: bash scripts/setup-pi-integrations.sh [all|cecilia|alice|aria|octavia]

set -e

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

PIES=(cecilia alice aria octavia)
TARGET="${1:-all}"

log()   { echo -e "${GREEN}✅${NC} $1"; }
info()  { echo -e "${CYAN}ℹ️ ${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠️ ${NC} $1"; }
err()   { echo -e "${RED}❌${NC} $1"; }

PI_SETUP_SCRIPT='#!/bin/bash
set -e
echo "🚀 Setting up BlackRoad integrations on $(hostname)..."

# ── Node.js + npm (required for wrangler, railway) ──────────────────────
if ! command -v node &>/dev/null; then
  echo "Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
  sudo apt-get install -y nodejs
fi
echo "✅ Node: $(node --version)"

# ── Wrangler (Cloudflare) ────────────────────────────────────────────────
if ! command -v wrangler &>/dev/null; then
  sudo npm install -g wrangler@latest
fi
echo "✅ Wrangler: $(wrangler --version 2>/dev/null | head -1)"

# ── Railway CLI ──────────────────────────────────────────────────────────
if ! command -v railway &>/dev/null; then
  bash <(curl -fsSL https://railway.com/install.sh)
fi
echo "✅ Railway: $(railway --version 2>/dev/null)"

# ── GitHub CLI ──────────────────────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
  sudo apt update && sudo apt install gh -y
fi
echo "✅ GH CLI: $(gh --version | head -1)"

# ── Salesforce CLI (sfdx) ───────────────────────────────────────────────
if ! command -v sf &>/dev/null && ! command -v sfdx &>/dev/null; then
  sudo npm install -g @salesforce/cli
fi
echo "✅ SF CLI: $(sf version 2>/dev/null | head -1 || sfdx version 2>/dev/null | head -1 || echo "installed")"

# ── rclone (Google Drive sync) ──────────────────────────────────────────
if ! command -v rclone &>/dev/null; then
  curl https://rclone.org/install.sh | sudo bash
fi
echo "✅ rclone: $(rclone --version | head -1)"

# ── HuggingFace Hub CLI ─────────────────────────────────────────────────
if ! command -v huggingface-cli &>/dev/null; then
  pip3 install -q huggingface_hub[cli] 2>/dev/null || python3 -m pip install -q huggingface_hub[cli]
fi
echo "✅ HuggingFace: $(huggingface-cli version 2>/dev/null || echo "installed")"

# ── Set up blackroad bin dir ─────────────────────────────────────────────
mkdir -p ~/bin
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
  echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
fi

echo ""
echo "🎉 $(hostname) integration setup complete!"
echo "   Node: $(node --version)"
echo "   Wrangler: $(wrangler --version 2>/dev/null | head -1)"
echo "   Railway: $(railway --version 2>/dev/null || echo ok)"
echo "   GH CLI: $(gh --version | head -1)"
echo "   rclone: $(rclone --version | head -1)"
'

setup_pi() {
  local host="$1"
  info "Setting up $host..."
  ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "bash -s" <<< "$PI_SETUP_SCRIPT" 2>&1 | \
    sed "s/^/  [$host] /" && log "$host setup complete" || err "$host setup failed"
}

if [[ "$TARGET" == "all" ]]; then
  for pi in "${PIES[@]}"; do
    setup_pi "$pi" &
  done
  wait
  log "All Pis configured!"
else
  setup_pi "$TARGET"
fi
