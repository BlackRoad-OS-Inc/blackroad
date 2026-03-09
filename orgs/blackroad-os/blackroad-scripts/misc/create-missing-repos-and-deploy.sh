#!/bin/bash
# Create missing GitHub repos and deploy initial content

set -e

echo "🚀 BlackRoad OS - Mass Repo Creation & Deployment"
echo "=================================================="
echo ""

GITHUB_ORG="BlackRoad-OS"
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

# List of repos to create/verify
REPOS=(
    "blackroad-os-analytics:Analytics Dashboard"
    "blackroad-os-console:System Console"
    "blackroad-os-pack-engineering:Engineering Pack"
)

echo "📦 Creating/Verifying GitHub Repositories..."
echo ""

for repo_desc in "${REPOS[@]}"; do
    IFS=':' read -r repo description <<< "$repo_desc"
    
    echo "Checking: $repo"
    
    if gh repo view "$GITHUB_ORG/$repo" &>/dev/null; then
        echo "  ✅ Repo exists: $repo"
    else
        echo "  📝 Creating repo: $repo"
        if gh repo create "$GITHUB_ORG/$repo" --private --description "BlackRoad OS - $description"; then
            echo "  ✅ Created: https://github.com/$GITHUB_ORG/$repo"
        else
            echo "  ❌ Failed to create $repo"
        fi
    fi
    echo ""
done

echo "=================================================="
echo "✅ Repository setup complete"
echo ""
echo "📊 Summary:"
gh repo list "$GITHUB_ORG" --limit 100 | wc -l | xargs echo "Total repos:"
echo ""

