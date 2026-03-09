#!/bin/bash

# Pi AI Execution Playbook - Setup Verification
# Verifies all systems are ready to launch

set -e

echo "🥧🍎 Pi AI Execution Playbook - Verifying Setup 🥧🍎"
echo "====================================================="
echo ""

ERRORS=0

# Check required commands
echo "Checking required tools..."
echo ""

REQUIRED_COMMANDS=("git" "gh" "jq" "node" "python3")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo "✓ $cmd installed"
    else
        echo "❌ $cmd NOT installed"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""

# Check GitHub authentication
echo "Checking GitHub authentication..."
if gh auth status &> /dev/null; then
    echo "✓ GitHub CLI authenticated"
else
    echo "❌ GitHub CLI NOT authenticated"
    echo "   Run: gh auth login"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Check .env file
echo "Checking configuration..."
if [ -f ".env" ]; then
    echo "✓ .env file exists"

    # Check for required variables
    REQUIRED_VARS=("GITHUB_ORG" "TWITTER_HANDLE" "EMAIL")

    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^$var=" .env && ! grep -q "^$var=$" .env; then
            echo "  ✓ $var configured"
        else
            echo "  ⚠️  $var not configured (optional but recommended)"
        fi
    done
else
    echo "❌ .env file NOT found"
    echo "   Run: cp .env.example .env"
    echo "   Then edit .env with your information"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Check repository access
echo "Checking GitHub repository access..."

REPOS=(
    "pi-ai-hub"
    "pi-node-registry"
    "pi-hardware-requirements"
    "pi-deployment-automation"
    "pi-success-stories"
    "pi-monitoring-dashboard"
    "pi-community-hub"
    "pi-vs-nvidia"
    "pi-viral-launch"
    "pi-viral-hub"
    "pi-viral-megapack"
    "pi-ecosystem-domination"
)

REPO_ORG=$(grep "^GITHUB_ORG=" .env 2>/dev/null | cut -d'=' -f2 || echo "BlackRoad-OS")

echo "Checking repos in organization: $REPO_ORG"
echo ""

ACCESSIBLE=0
for repo in "${REPOS[@]}"; do
    if gh repo view "$REPO_ORG/$repo" &> /dev/null; then
        echo "✓ $repo accessible"
        ACCESSIBLE=$((ACCESSIBLE + 1))
    else
        echo "⚠️  $repo not accessible (might not be created yet)"
    fi
done

echo ""
echo "Found $ACCESSIBLE/${#REPOS[@]} repositories"

echo ""

# Check website accessibility
echo "Checking GitHub Pages deployment..."
echo ""

LIVE_SITES=0
for repo in "${REPOS[@]}"; do
    URL="https://$REPO_ORG.github.io/$repo/"
    if curl -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "200"; then
        echo "✓ $repo live"
        LIVE_SITES=$((LIVE_SITES + 1))
    else
        echo "⚠️  $repo not live yet"
    fi
done

echo ""
echo "Found $LIVE_SITES/${#REPOS[@]} live sites"

echo ""

# Summary
echo "====================================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ ALL CHECKS PASSED!"
    echo ""
    echo "You are ready to launch! 🚀"
    echo ""
    echo "Next steps:"
    echo "  1. Review Day 0 preparation in master-execution-timeline.md"
    echo "  2. When ready for Day 1, run: ./scripts/launch-viral-content.sh"
    echo ""
else
    echo "❌ SETUP INCOMPLETE ($ERRORS errors)"
    echo ""
    echo "Please fix the errors above before launching."
    echo ""
fi

echo "🥧🍎 Same Energy • 1% Cost • 100% Sovereignty 🥧🍎"
