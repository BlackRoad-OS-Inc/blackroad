#!/bin/bash
# Deploy batch 3: Next 20 projects

GITHUB_ORG="BlackRoad-OS"

deploy() {
    local page=$1
    local repo=${2:-$page}
    
    printf "%-40s" "$page"
    TEMP="/tmp/deploy-$$"
    rm -rf "$TEMP" && mkdir -p "$TEMP" && cd "$TEMP"
    
    if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
        cd "$repo"
        DIR=$([ -d "dist" ] && echo "dist" || [ -d "build" ] && echo "build" || echo ".")
        URL=$(wrangler pages deploy "$DIR" --project-name="$page" --branch=main 2>&1 | grep -o 'https://[^/]*.pages.dev' | head -1)
        if [ -n "$URL" ]; then
            echo "✅ $URL"
        else
            echo "⚠️  Deploy attempted"
        fi
    else
        echo "⚠️  Repo not found"
    fi
    rm -rf "$TEMP"
}

echo "🚀 Batch 3: Deploying 20 More Projects"
echo "=========================================="
echo ""

# Subdomain apps
deploy "app-blackroad-io" "blackroad-os-app"
deploy "content-blackroad-io" "blackroad-os-content"
deploy "customer-success-blackroad-io" "blackroad-os-pack-customer-success"
deploy "design-blackroad-io" "blackroad-os-design"
deploy "hr-blackroad-io" "blackroad-os-pack-hr"
deploy "operations-blackroad-io" "blackroad-os-pack-operations"
deploy "product-blackroad-io" "blackroad-os-product"
deploy "sales-blackroad-io" "blackroad-os-pack-sales"
deploy "support-blackroad-io" "blackroad-os-support"

# Brand domains
deploy "blackroad-io" "blackroad-os-web"
deploy "blackroadinc-us" "blackroad-os-web"
deploy "earth-blackroad-io" "blackroad-os-earth"

# Utility projects
deploy "blackroad-assets" "blackroad-os-assets"
deploy "blackroad-cece" "blackroad-os-cece"
deploy "blackroad-gateway-web" "blackroad-os-gateway-web"
deploy "blackroad-pitstop" "blackroad-os-pitstop"
deploy "blackroad-metaverse" "blackroad-os-metaverse"
deploy "blackroad-portals" "blackroad-os-portals"
deploy "blackroad-status" "blackroad-os-status"
deploy "blackroad-unified" "blackroad-os-unified"

echo ""
echo "✅ Batch 3 complete!"

