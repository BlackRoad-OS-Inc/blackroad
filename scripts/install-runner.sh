#!/usr/bin/env bash
# ============================================================
# install-runner.sh — Install GitHub Actions self-hosted runner
# Run on each Pi/cloud node to register as a $0 runner
#
# Usage:
#   ./scripts/install-runner.sh <runner-name> <labels> <github-repo> <token>
#
# Examples:
#   ./scripts/install-runner.sh octavia-pi "self-hosted,pi,octavia,linux,arm64" blackboxprogramming/blackroad $TOKEN
#   ./scripts/install-runner.sh alice-pi "self-hosted,pi,alice,linux,arm64" blackboxprogramming/blackroad $TOKEN
#   ./scripts/install-runner.sh gematria "self-hosted,cloud,gematria,linux,arm64" blackboxprogramming/blackroad $TOKEN
# ============================================================
set -euo pipefail

RUNNER_NAME="${1:-$(hostname)}"
LABELS="${2:-self-hosted,pi,linux,arm64}"
REPO="${3:-blackboxprogramming/blackroad}"
REG_TOKEN="${4:-}"
RUNNER_VERSION="2.321.0"
INSTALL_DIR="$HOME/actions-runner"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

log()   { echo -e "${GREEN}✓${NC} $1"; }
info()  { echo -e "${CYAN}ℹ${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

# Detect arch
ARCH=$(uname -m)
case "$ARCH" in
  aarch64|arm64) RUNNER_ARCH="arm64" ;;
  x86_64)        RUNNER_ARCH="x64" ;;
  *)             error "Unsupported architecture: $ARCH" ;;
esac

RUNNER_PKG="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PKG}"

info "Installing GitHub Actions runner: $RUNNER_NAME"
info "Labels: $LABELS"
info "Repo: $REPO"
info "Arch: $RUNNER_ARCH"

# Create install dir
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Download runner if not already present
if [[ ! -f "run.sh" ]]; then
  info "Downloading runner v${RUNNER_VERSION}..."
  curl -sLo "$RUNNER_PKG" "$RUNNER_URL"
  tar xzf "$RUNNER_PKG"
  rm -f "$RUNNER_PKG"
  log "Runner downloaded and extracted"
else
  log "Runner already installed at $INSTALL_DIR"
fi

# Get registration token if not provided
if [[ -z "$REG_TOKEN" ]]; then
  warn "No registration token provided."
  echo ""
  echo "Get a token from:"
  echo "  https://github.com/$REPO/settings/actions/runners/new"
  echo ""
  echo "Or via API (requires admin PAT):"
  echo "  curl -s -X POST -H 'Authorization: Bearer \$GH_PAT' \\"
  echo "    https://api.github.com/repos/$REPO/actions/runners/registration-token \\"
  echo "    | jq -r '.token'"
  echo ""
  read -r -p "Enter registration token: " REG_TOKEN
fi

# Configure runner
info "Configuring runner..."
./config.sh \
  --url "https://github.com/$REPO" \
  --token "$REG_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$LABELS" \
  --work "_work" \
  --unattended \
  --replace

log "Runner configured: $RUNNER_NAME"

# Install as systemd service
if command -v systemctl &>/dev/null; then
  info "Installing systemd service..."
  sudo ./svc.sh install
  sudo ./svc.sh start
  log "Runner service started"
  sudo systemctl status "actions.runner.${REPO//\//.}.${RUNNER_NAME}.service" --no-pager 2>/dev/null || true
else
  warn "systemd not available — start manually with: cd $INSTALL_DIR && ./run.sh"
fi

echo ""
echo "  ${GREEN}✅ Runner ready: $RUNNER_NAME${NC}"
echo "  ${CYAN}Labels: $LABELS${NC}"
echo "  ${CYAN}Billing: \$0 (self-hosted)${NC}"
echo ""
echo "  Workflows using this runner:"
echo "    runs-on: [self-hosted, pi]      # any Pi"
echo "    runs-on: [self-hosted, $RUNNER_NAME]  # this specific runner"
