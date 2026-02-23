#!/bin/bash
# BlackRoad Pi Self-Hosted GitHub Runner Setup
# Run on each Pi: bash <(curl -s https://raw.githubusercontent.com/BlackRoad-OS/blackroad/master/scripts/setup-pi-runner.sh)

set -e
PI_NAME="${1:-octavia-pi}"
REPO="${2:-BlackRoad-OS/blackroad}"
RUNNER_VERSION="2.321.0"
ARCH="arm64"

echo "🍓 Setting up GitHub Actions self-hosted runner on $PI_NAME"
echo "   Repo: $REPO"
echo "   This makes GitHub Actions cost = \$0"
echo ""

# Install prereqs
sudo apt-get update -qq && sudo apt-get install -y -qq curl jq libicu-dev

# Create runner directory
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download runner
echo "📥 Downloading GitHub Actions runner v${RUNNER_VERSION}..."
curl -sL -o runner.tar.gz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz"
tar xzf runner.tar.gz
rm runner.tar.gz

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT: Get a registration token from:"
echo "   https://github.com/${REPO}/settings/actions/runners/new"
echo ""
echo "Then run:"
echo "   ./config.sh --url https://github.com/${REPO} \\"
echo "     --token YOUR_TOKEN \\"
echo "     --name ${PI_NAME} \\"
echo "     --labels 'self-hosted,pi,blackroad,arm64' \\"
echo "     --unattended"
echo "   sudo ./svc.sh install && sudo ./svc.sh start"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Runner files ready in ~/actions-runner/"
