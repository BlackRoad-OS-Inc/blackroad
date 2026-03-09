#!/bin/bash
# Test 5 more GitHub repos for Cloudflare integration

REPOS=(
    "blackroad-hello"
    "lucidia-platform"
    "blackroad-os-demo"
    "blackroad-os-home"
    "blackroad-os-pack-creator-studio"
)

echo "🧪 Testing 5 More Repos for Cloudflare Integration"
echo "=================================================="
echo ""

for repo in "${REPOS[@]}"; do
    echo "📦 Testing: $repo"
    
    # Check if repo exists
    if gh repo view "BlackRoad-OS/$repo" &>/dev/null; then
        echo "  ✅ Repo exists"
        
        # Get latest commit
        COMMIT=$(gh api "repos/BlackRoad-OS/$repo/commits/main" -q '.sha' 2>/dev/null | head -c 7)
        if [ -n "$COMMIT" ]; then
            echo "  📝 Latest commit: $COMMIT"
        fi
        
        # Check for workflows
        WORKFLOW_COUNT=$(gh api "repos/BlackRoad-OS/$repo/actions/workflows" -q '.total_count' 2>/dev/null || echo "0")
        echo "  🔧 Workflows: $WORKFLOW_COUNT"
        
        # Check for package.json or build config
        if gh api "repos/BlackRoad-OS/$repo/contents/package.json" &>/dev/null; then
            echo "  📄 Has package.json"
        fi
        
        if gh api "repos/BlackRoad-OS/$repo/contents/wrangler.toml" &>/dev/null; then
            echo "  ☁️ Has wrangler.toml"
        fi
        
    else
        echo "  ❌ Repo not found"
    fi
    
    echo ""
done

echo "=================================================="
echo "✅ Test complete"
