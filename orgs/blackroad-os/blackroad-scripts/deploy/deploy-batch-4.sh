#!/bin/bash
# Deploy batch 4: Next 20 projects

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

echo "🚀 Batch 4: Deploying Next 20 Projects"
echo "======================================="
echo ""

# Operations & Management
deploy "operations-blackroad-io" "blackroad-os-pack-operations"
deploy "sales-blackroad-io" "blackroad-os-pack-sales"
deploy "support-blackroad-io" "blackroad-os-pack-support"
deploy "hr-blackroad-io" "blackroad-os-pack-hr"
deploy "compliance-blackroad-io" "blackroad-os-pack-compliance"

# Product & Development
deploy "products-blackroad-io" "blackroad-os-pack-products"
deploy "developers-blackroad-io" "blackroad-os-pack-developers"
deploy "apis-blackroad-io" "blackroad-os-pack-apis"
deploy "docs-blackroad-io" "blackroad-os-docs"
deploy "changelog-blackroad-io" "blackroad-os-pack-changelog"

# Community & Media
deploy "community-blackroad-io" "blackroad-os-pack-community"
deploy "blog-blackroad-io" "blackroad-os-pack-blog"
deploy "news-blackroad-io" "blackroad-os-pack-news"
deploy "events-blackroad-io" "blackroad-os-pack-events"
deploy "podcasts-blackroad-io" "blackroad-os-pack-podcasts"

# Specialized Services
deploy "quantum-blackroad-io" "blackroad-os-pack-quantum"
deploy "ai-blackroad-io" "blackroad-os-pack-ai"
deploy "blockchain-blackroad-io" "blackroad-os-pack-blockchain"
deploy "iot-blackroad-io" "blackroad-os-pack-iot"
deploy "security-blackroad-io" "blackroad-os-pack-security"

echo ""
echo "✅ Batch 4 deployment complete!"
echo "======================================="
