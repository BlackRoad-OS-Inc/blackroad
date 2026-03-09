#!/bin/bash

# Find all BlackRoad-OS repos that haven't been enhanced yet

echo "🔍 Finding unenhanced repositories..."
echo ""

# Get all non-fork repos
ALL_REPOS=$(gh repo list BlackRoad-OS --limit 200 --json name,isFork | jq -r '.[] | select(.isFork == false) | .name')

ENHANCED_COUNT=0
UNENHANCED_COUNT=0
UNENHANCED_REPOS=()

for repo in $ALL_REPOS; do
    # Check if repo has .github/workflows directory
    if gh api "repos/BlackRoad-OS/$repo/contents/.github/workflows" >/dev/null 2>&1; then
        ((ENHANCED_COUNT++))
    else
        ((UNENHANCED_COUNT++))
        UNENHANCED_REPOS+=("$repo")
        echo "❌ $repo - needs enhancement"
    fi
done

echo ""
echo "═══════════════════════════════════════════"
echo "📊 SUMMARY"
echo "═══════════════════════════════════════════"
echo "✅ Enhanced: $ENHANCED_COUNT"
echo "❌ Unenhanced: $UNENHANCED_COUNT"
echo ""

if [ ${#UNENHANCED_REPOS[@]} -gt 0 ]; then
    echo "📋 Repos needing enhancement:"
    for repo in "${UNENHANCED_REPOS[@]}"; do
        echo "  - $repo"
    done
fi
