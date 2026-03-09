#!/bin/bash
# Deploy all existing repos that have Pages projects

GITHUB_ORG="BlackRoad-OS"

deploy() {
    local page=$1
    local repo=${2:-$page}
    
    printf "%-45s" "$page"
    TEMP="/tmp/d-$$"
    rm -rf "$TEMP" && mkdir -p "$TEMP" && cd "$TEMP"
    
    if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
        cd "$repo"
        D=$([ -d "dist" ] && echo "dist" || [ -d "build" ] && echo "build" || [ -d ".next" ] && echo ".next" || echo ".")
        U=$(wrangler pages deploy "$D" --project-name="$page" --branch=main 2>&1 | grep -o 'https://[^/]*.pages.dev' | head -1)
        [ -n "$U" ] && echo "✅" || echo "⚠️"
    else
        echo "❌"
    fi
    rm -rf "$TEMP"
}

echo "🚀 Deploying All Repos with Existing Content"
echo "=============================================="

# All existing repos from BlackRoad-OS
gh repo list BlackRoad-OS --limit 100 --json name -q '.[].name' | while read repo; do
    # Try to find matching Pages project
    page=$(echo "$repo" | sed 's/blackroad-os-//')
    deploy "$page" "$repo"
done

echo ""
echo "✅ Mass deployment attempt complete!"

