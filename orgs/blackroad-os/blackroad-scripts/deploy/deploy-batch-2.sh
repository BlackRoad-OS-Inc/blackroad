#!/bin/bash
# Deploy batch 2: Next 10 projects

GITHUB_ORG="BlackRoad-OS"

deploy() {
    local page=$1
    local repo=$2
    
    echo "📦 $page"
    TEMP="/tmp/deploy-$$"
    mkdir -p "$TEMP" && cd "$TEMP"
    
    if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
        cd "$repo"
        DIR=$([ -d "dist" ] && echo "dist" || echo ".")
        URL=$(wrangler pages deploy "$DIR" --project-name="$page" --branch=main 2>&1 | grep -o 'https://[^/]*.pages.dev' | head -1)
        echo "  ✅ $URL"
    else
        echo "  ⚠️  Repo not found, creating..."
        gh repo create "$GITHUB_ORG/$repo" --private --description "BlackRoad OS - $page" 2>/dev/null
        echo "  📝 Repo created, needs content"
    fi
    
    rm -rf "$TEMP"
}

echo "🚀 Batch 2: Deploying 10 More Projects"
echo "======================================"

deploy "blackroad-console" "blackroad-os-console"
deploy "analytics-blackroad-io" "blackroad-os-analytics"
deploy "creator-studio-blackroad-io" "blackroad-os-pack-creator-studio"
deploy "research-lab-blackroad-io" "blackroad-os-pack-research-lab"
deploy "finance-blackroad-io" "blackroad-os-pack-finance"
deploy "legal-blackroad-io" "blackroad-os-pack-legal"
deploy "education-blackroad-io" "blackroad-os-pack-education"
deploy "engineering-blackroad-io" "blackroad-os-pack-engineering"
deploy "healthcare-blackroad-io" "blackroad-os-pack-healthcare"
deploy "marketing-blackroad-io" "blackroad-os-pack-marketing"

echo ""
echo "✅ Batch 2 complete!"

