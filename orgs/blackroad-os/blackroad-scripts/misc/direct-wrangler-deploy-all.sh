#!/bin/bash
# Direct deployment approach - deploy from GitHub to Cloudflare

set -e

GITHUB_ORG="BlackRoad-OS"
WORK_DIR="/tmp/cf-mass-deploy-$$"
mkdir -p "$WORK_DIR"

echo "🚀 Mass Deployment to Cloudflare Pages"
echo "======================================"
echo ""

# Projects to deploy
declare -A PROJECTS=(
    ["blackroad-monitoring"]="blackroad-monitoring"
    ["blackroad-hello"]="blackroad-hello"
    ["lucidia-earth"]="lucidia-platform"
    ["blackroad-os-demo"]="blackroad-os-demo"
    ["blackroad-os-home"]="blackroad-os-home"
)

deploy_project() {
    local page_project=$1
    local repo=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Deploying: $page_project"
    echo "   From: $GITHUB_ORG/$repo"
    echo ""
    
    cd "$WORK_DIR"
    
    # Clone repo
    echo "  📥 Cloning repository..."
    if gh repo clone "$GITHUB_ORG/$repo" "$repo" 2>/dev/null; then
        cd "$repo"
        
        # Check what's in the repo
        echo "  📋 Repository contents:"
        ls -la | head -10
        echo ""
        
        # Determine deployment directory
        if [ -f "dist/index.html" ]; then
            DEPLOY_DIR="dist"
        elif [ -f "build/index.html" ]; then
            DEPLOY_DIR="build"
        elif [ -f "index.html" ]; then
            DEPLOY_DIR="."
        else
            echo "  ⚠️  No obvious build output, deploying root directory"
            DEPLOY_DIR="."
        fi
        
        echo "  🎯 Deploy directory: $DEPLOY_DIR"
        echo "  ☁️  Deploying to Cloudflare Pages..."
        
        if wrangler pages deploy "$DEPLOY_DIR" --project-name="$page_project" --branch=main 2>&1 | tee /tmp/deploy-log.txt; then
            DEPLOY_URL=$(grep -o 'https://[^/]*.pages.dev' /tmp/deploy-log.txt | head -1)
            echo ""
            echo "  ✅ SUCCESS! Deployed to:"
            echo "  🔗 $DEPLOY_URL"
            echo ""
        else
            echo "  ❌ Deployment failed"
            echo ""
        fi
        
        cd "$WORK_DIR"
        rm -rf "$repo"
    else
        echo "  ❌ Failed to clone $GITHUB_ORG/$repo"
        echo ""
    fi
}

# Deploy first project
echo "Starting with blackroad-monitoring..."
echo ""
deploy_project "blackroad-monitoring" "blackroad-monitoring"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Deployment attempt complete!"
echo ""
echo "Next projects ready:"
echo "  - blackroad-hello"
echo "  - lucidia-earth"
echo "  - blackroad-os-demo"
echo "  - blackroad-os-home"
echo ""

# Cleanup
rm -rf "$WORK_DIR"

