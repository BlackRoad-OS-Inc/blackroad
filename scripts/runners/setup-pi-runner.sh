#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# BlackRoad Pi — GitHub Actions Self-Hosted Runner Setup
# Registers a Pi as a GitHub Actions runner (free — $0 cost)
# Usage: bash setup-pi-runner.sh <node_name> [org_url]
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

NODE="${1:-cecilia}"
ORG_URL="${2:-https://github.com/BlackRoad-OS-Inc}"
REPO_URL="${3:-https://github.com/BlackRoad-OS-Inc/blackroad}"
RUNNER_VERSION="2.322.0"
ARCH="arm64"

# Node → labels map
declare -A NODE_LABELS=(
  [cecilia]="self-hosted,linux,arm64,pi5,hailo,nvme,cecilia"
  [aria]="self-hosted,linux,arm64,pi5,aria"
  [octavia]="self-hosted,linux,arm64,pi5,octavia"
  [alice]="self-hosted,linux,arm64,pi4,alice"
  [lucidia]="self-hosted,linux,arm64,pi5,hailo,nvme,lucidia"
  [gematria]="self-hosted,linux,amd64,digitalocean,gematria"
  [anastasia]="self-hosted,linux,amd64,digitalocean,anastasia"
)

LABELS="${NODE_LABELS[$NODE]:-self-hosted,linux,arm64,pi}"

echo -e "${CYAN}🏃 Setting up GitHub Actions runner: ${NODE}${NC}"
echo -e "   Labels: ${LABELS}"
echo -e "   Repo:   ${REPO_URL}"

# Determine arch for gematria/anastasia (amd64 DO droplets)
if [[ "$NODE" == "gematria" || "$NODE" == "anastasia" ]]; then
  ARCH="x64"
fi

RUNNER_PKG="actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PKG}"

cat > /tmp/install-runner-${NODE}.sh << REMOTE
#!/bin/bash
set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p ~/actions-runner && cd ~/actions-runner

if [ ! -f "config.sh" ]; then
    echo -e "\${CYAN}Downloading runner v${RUNNER_VERSION}...\${NC}"
    curl -sL "${RUNNER_URL}" | tar xz
fi

# Get registration token via GH CLI (requires gh auth)
TOKEN=\$(gh api --method POST \
    /repos/BlackRoad-OS-Inc/blackroad/actions/runners/registration-token \
    --jq '.token' 2>/dev/null || echo "\${GH_RUNNER_TOKEN:-}")

if [[ -z "\$TOKEN" ]]; then
  echo "ERROR: Need GH_RUNNER_TOKEN env var or gh CLI auth"
  exit 1
fi

# Configure runner
./config.sh \\
    --url "${REPO_URL}" \\
    --token "\$TOKEN" \\
    --name "${NODE}" \\
    --labels "${LABELS}" \\
    --work "_work" \\
    --unattended \\
    --replace 2>&1 | tail -5

# Install as systemd service
sudo ./svc.sh install blackroad 2>/dev/null || true
sudo ./svc.sh start blackroad 2>/dev/null || true

# Also register at org level
echo -e "\${GREEN}✅ Runner ${NODE} registered and running\${NC}"
sudo ./svc.sh status blackroad 2>/dev/null | head -3 || true
REMOTE

echo -e "${YELLOW}Deploying to ${NODE}...${NC}"

# Determine SSH host
SSH_HOST="$NODE"
SSH_USER="blackroad"
if [[ "$NODE" == "gematria" ]]; then SSH_HOST="gematria"; fi
if [[ "$NODE" == "anastasia" ]]; then SSH_HOST="anastasia"; fi

scp -q /tmp/install-runner-${NODE}.sh ${SSH_USER}@${SSH_HOST}:/tmp/install-runner.sh
ssh ${SSH_USER}@${SSH_HOST} "bash /tmp/install-runner.sh"

echo -e "${GREEN}✅ ${NODE} runner setup complete${NC}"
