#!/bin/bash
# BlackRoad Deployment System - Quick Setup
# One-time setup script for all deployment infrastructure
# Version: 1.0.0

set -euo pipefail

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  BlackRoad Deployment System - Setup                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. Create environment file
# ============================================================================

echo "📝 Creating environment configuration..."

cat > ~/.blackroad-deploy-env <<'EOF'
# BlackRoad Deployment System Environment
export CF_TOKEN="yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"
export CLOUDFLARE_ACCOUNT_ID="463024cf9efed5e7b40c5fbe7938e256"
export GITHUB_ORG="BlackRoad-OS"
export PI_USER="pi"
export SSH_KEY="$HOME/.ssh/id_rsa"
EOF

echo "✅ Created ~/.blackroad-deploy-env"

# ============================================================================
# 2. Source environment
# ============================================================================

source ~/.blackroad-deploy-env

# ============================================================================
# 3. Configure SSH
# ============================================================================

echo ""
echo "🔑 Configuring SSH for Pi nodes..."

mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add SSH config if not exists
if ! grep -q "Host lucidia" ~/.ssh/config 2>/dev/null; then
    cat >> ~/.ssh/config <<'EOF'

# BlackRoad Pi Mesh
Host lucidia
    HostName 192.168.4.38
    User pi
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host blackroad-pi
    HostName 192.168.4.64
    User pi
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host lucidia-alt
    HostName 192.168.4.99
    User pi
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    echo "✅ Added Pi nodes to SSH config"
else
    echo "ℹ️  SSH config already contains Pi nodes"
fi

# ============================================================================
# 4. Test connections
# ============================================================================

echo ""
echo "🔌 Testing connections..."

# Test Cloudflare
echo -n "  Cloudflare API... "
if curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
    -H "Authorization: Bearer $CF_TOKEN" 2>/dev/null | grep -q '"success":true'; then
    echo "✅"
else
    echo "❌ (check CF_TOKEN)"
fi

# Test GitHub
echo -n "  GitHub API... "
if gh auth status >/dev/null 2>&1; then
    echo "✅"
else
    echo "❌ (run: gh auth login)"
fi

# Test Pi nodes
for pi in lucidia blackroad-pi lucidia-alt; do
    echo -n "  Pi node $pi... "
    if ssh -o ConnectTimeout=3 -o BatchMode=yes "$pi" "echo 'OK'" >/dev/null 2>&1; then
        echo "✅"
    else
        echo "❌ (check SSH keys)"
    fi
done

# ============================================================================
# 5. Make scripts executable
# ============================================================================

echo ""
echo "🔧 Setting up deployment scripts..."

chmod +x ~/blackroad-autodeploy-system.sh 2>/dev/null && echo "✅ blackroad-autodeploy-system.sh" || echo "❌ blackroad-autodeploy-system.sh not found"
chmod +x ~/shellfish-pi-deploy.sh 2>/dev/null && echo "✅ shellfish-pi-deploy.sh" || echo "❌ shellfish-pi-deploy.sh not found"
chmod +x ~/test-deployments.sh 2>/dev/null && echo "✅ test-deployments.sh" || echo "❌ test-deployments.sh not found"
chmod +x ~/status-dashboard.sh 2>/dev/null && echo "✅ status-dashboard.sh" || echo "❌ status-dashboard.sh not found"

# ============================================================================
# 6. Create shell aliases
# ============================================================================

echo ""
echo "⚡ Creating convenience aliases..."

# Add to shell rc file
SHELL_RC=""
if [ -n "${ZSH_VERSION:-}" ] || [ -f ~/.zshrc ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f ~/.bashrc ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "# BlackRoad Deployment Aliases" "$SHELL_RC" 2>/dev/null; then
        cat >> "$SHELL_RC" <<'EOF'

# BlackRoad Deployment Aliases
alias br-deploy='~/blackroad-autodeploy-system.sh'
alias br-pi='~/shellfish-pi-deploy.sh'
alias br-test='~/test-deployments.sh'
alias br-status='~/status-dashboard.sh'
alias br-env='source ~/.blackroad-deploy-env'
EOF
        echo "✅ Added aliases to $SHELL_RC"
        echo "   Run: source $SHELL_RC"
    else
        echo "ℹ️  Aliases already exist in $SHELL_RC"
    fi
fi

# ============================================================================
# 7. Quick health check
# ============================================================================

echo ""
echo "🏥 Running quick health check..."

if [ -x ~/status-dashboard.sh ]; then
    ~/status-dashboard.sh compact
else
    echo "❌ Status dashboard not available"
fi

# ============================================================================
# 8. Final instructions
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Setup Complete!                                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo ""
echo "1. Source environment variables:"
echo "   source ~/.blackroad-deploy-env"
echo ""
echo "2. Or reload your shell:"
echo "   source $SHELL_RC"
echo ""
echo "3. Test the system:"
echo "   br-status"
echo "   br-test smoke"
echo ""
echo "4. Deploy a domain:"
echo "   br-deploy deploy app.blackroad.io"
echo ""
echo "5. Deploy to Pi:"
echo "   br-pi quick-deploy blackroad-os-web"
echo ""
echo "📚 Full documentation: ~/DEPLOYMENT_SYSTEM_DOCS.md"
echo ""
echo "🛣️  The road is ready for deployment!"
echo ""
