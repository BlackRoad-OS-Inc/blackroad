#!/bin/bash
# Deploy next 4 projects

GITHUB_ORG="BlackRoad-OS"
WORK_DIR="/tmp/cf-deploy"

deploy() {
    local page=$1
    local repo=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Deploying: $page → $repo"
    
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
        cd "$repo"
        
        # Find deploy directory
        if [ -d "dist" ]; then DIR="dist"
        elif [ -d "build" ]; then DIR="build"
        elif [ -d ".next" ]; then DIR=".next"
        else DIR="."; fi
        
        echo "  🎯 Deploying from: $DIR"
        
        if wrangler pages deploy "$DIR" --project-name="$page" --branch=main 2>&1 | grep -o 'https://[^/]*.pages.dev' | head -1; then
            echo "  ✅ SUCCESS!"
        else
            echo "  ⚠️  Check output above"
        fi
    else
        echo "  ❌ Clone failed"
    fi
    
    echo ""
}

echo "🚀 Deploying Next 4 Projects"
echo "=============================="
echo ""

deploy "blackroad-hello" "blackroad-hello"
deploy "lucidia-earth" "lucidia-platform"  
deploy "blackroad-os-demo" "blackroad-os-demo"
deploy "blackroad-os-home" "blackroad-os-home"

echo "✅ Batch deployment complete!"
rm -rf "$WORK_DIR"

