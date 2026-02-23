#!/bin/bash
# BR SELF-HOSTED RUNNER SETUP
# Registers a Pi as a GitHub Actions self-hosted runner for BlackRoad-OS-Inc/blackroad
# Usage: ./setup-self-hosted-runner.sh <runner-name> <reg-token> [labels]
# Example: ./setup-self-hosted-runner.sh alice-pi3 AXXXTOKEN pi,alice,blackroad-fleet

set -euo pipefail

RUNNER_NAME="${1:?Usage: $0 <name> <token> [labels]}"
REG_TOKEN="${2:?Missing registration token}"
EXTRA_LABELS="${3:-pi,blackroad-fleet}"
REPO_URL="https://github.com/BlackRoad-OS-Inc/blackroad"
RUNNER_DIR="$HOME/actions-runner"
ARCH=$(uname -m)

# Map arch to GitHub runner arch
case "$ARCH" in
  aarch64|arm64) RUNNER_ARCH="arm64" ;;
  x86_64)        RUNNER_ARCH="x64" ;;
  armv7l)        RUNNER_ARCH="arm" ;;
  *) echo "Unknown arch: $ARCH"; exit 1 ;;
esac

RUNNER_VERSION="2.331.0"
RUNNER_PKG="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PKG}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

info "Setting up self-hosted runner: $RUNNER_NAME ($ARCH → $RUNNER_ARCH)"

# Install dependencies
if command -v apt-get &>/dev/null; then
  sudo apt-get install -y --no-install-recommends curl tar jq git libicu-dev 2>/dev/null || true
fi

# Download runner if not present or wrong version
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [[ ! -f "run.sh" ]]; then
  info "Downloading runner $RUNNER_VERSION..."
  curl -fsSL "$RUNNER_URL" -o "$RUNNER_PKG"
  tar xzf "$RUNNER_PKG"
  rm -f "$RUNNER_PKG"
  log "Runner downloaded"
fi

# Configure
ALL_LABELS="${RUNNER_NAME},${EXTRA_LABELS},Linux,${RUNNER_ARCH/x64/X64},ARM64"
[[ "$RUNNER_ARCH" == "x64" ]] && ALL_LABELS="${RUNNER_NAME},${EXTRA_LABELS},Linux,X64"
[[ "$RUNNER_ARCH" == "arm64" ]] && ALL_LABELS="${RUNNER_NAME},${EXTRA_LABELS},Linux,ARM64,blackroad-fleet,pi"

info "Configuring runner with labels: $ALL_LABELS"
./config.sh \
  --url "$REPO_URL" \
  --token "$REG_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$ALL_LABELS" \
  --work "_work" \
  --unattended \
  --replace

log "Runner configured: $RUNNER_NAME"

# Install and start as systemd service
if command -v systemctl &>/dev/null; then
  sudo ./svc.sh install || true
  sudo ./svc.sh start
  sudo ./svc.sh status
  log "Runner service started (systemd)"
else
  # Fallback: background process with nohup
  nohup ./run.sh > ~/runner.log 2>&1 &
  echo $! > ~/runner.pid
  log "Runner started (nohup PID: $(cat ~/runner.pid))"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  RUNNER READY: $RUNNER_NAME${NC}"
echo -e "${GREEN}  REPO: $REPO_URL${NC}"
echo -e "${GREEN}  LABELS: $ALL_LABELS${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
