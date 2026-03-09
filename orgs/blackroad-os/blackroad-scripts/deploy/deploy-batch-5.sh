#!/bin/bash
# Deploy batch 5: More existing repos

GITHUB_ORG="BlackRoad-OS"

deploy() {
    local page=$1
    local repo=$2

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 $page"
    TEMP="/tmp/deploy-$$-$(date +%s)"
    mkdir -p "$TEMP" && cd "$TEMP"

    if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
        cd "$repo"

        # Find deploy directory
        if [ -d "dist" ]; then DIR="dist"
        elif [ -d "build" ]; then DIR="build"
        elif [ -d ".next" ]; then DIR=".next"
        elif [ -d "public" ]; then DIR="public"
        else DIR="."; fi

        URL=$(wrangler pages deploy "$DIR" --project-name="$page" --branch=main 2>&1 | grep -o 'https://[^/]*.pages.dev' | head -1)
        if [ -n "$URL" ]; then
            echo "  ✅ $URL"
        else
            echo "  ⚠️  Deployed (check wrangler output)"
        fi
    else
        echo "  ❌ Repo not found: $repo"
    fi

    rm -rf "$TEMP"
}

echo "🚀 Batch 5: Deploying More Repos"
echo "================================"
echo ""

# Documentation & Deployment
deploy "blackroad-deployment-docs" "blackroad-deployment-docs"
deploy "blackroad-docs" "blackroad-docs"
deploy "blackroad-domains" "blackroad-domains"

# Raspberry Pi & IoT
deploy "blackroad-pi-holo" "blackroad-pi-holo"
deploy "blackroad-pi-ops" "blackroad-pi-ops"

# Tools & Infrastructure
deploy "blackroad-tools" "blackroad-tools"
deploy "blackroad-os-ideas" "blackroad-os-ideas"
deploy "blackroad-os-infra" "blackroad-os-infra"
deploy "blackroad-os-disaster-recovery" "blackroad-os-disaster-recovery"

# Prism Projects
deploy "blackroad-os-prism-enterprise" "blackroad-os-prism-enterprise"

# Claude & Collaboration
deploy "claude-collaboration-system" "claude-collaboration-system"

# Templates
deploy "chanfana-openapi-template" "chanfana-openapi-template"
deploy "containers-template" "containers-template"

# Metaverse
deploy "earth-metaverse" "earth-metaverse"

# Apps
deploy "app-blackroad-io" "app-blackroad-io"
deploy "blackroad-io-app" "blackroad-io-app"
deploy "demo-blackroad-io" "demo-blackroad-io"

# Models
deploy "blackroad-models" "blackroad-models"

# Core BlackRoad
deploy "blackroad" "blackroad"
deploy "blackroad-os" "blackroad-os"

echo ""
echo "✅ Batch 5 deployment complete!"
echo "================================"
