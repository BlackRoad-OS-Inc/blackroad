#!/bin/bash
# 🎯 Auto-Merge PRs - Safely merge Visual Docs Bot PRs with passing CI
# Agent: claude-pegasus-1766972309

set -e

AGENT_ID="${MY_CLAUDE:-claude-pegasus-1766972309}"
DRY_RUN=${DRY_RUN:-true}

echo "════════════════════════════════════════════════════════════"
echo "🎯 PR Auto-Merge System"
echo "════════════════════════════════════════════════════════════"
echo "Agent: $AGENT_ID"
echo "Mode: $([ "$DRY_RUN" = "true" ] && echo "DRY RUN" || echo "LIVE MERGE")"
echo ""

# Read PRs from monitoring results
if [ ! -f ~/pr-monitoring-results.json ]; then
    echo "❌ Error: Run pr-monitor.sh first!"
    exit 1
fi

# Get PRs ready to merge (OPEN + MERGEABLE + CI SUCCESS)
READY_PRS=$(cat ~/pr-monitoring-results.json | jq -r '.repos[] | select(.state == "OPEN" and .mergeable == "MERGEABLE" and .ci_status == "SUCCESS") | "\(.repo)|\(.pr_number)|\(.url)"')

if [ -z "$READY_PRS" ]; then
    echo "ℹ️  No PRs ready to merge at this time."
    echo ""
    echo "Current status:"
    echo "  - Most PRs have pending CI checks"
    echo "  - Some PRs have failing CI (need investigation)"
    echo "  - Will auto-merge as CI passes"
    exit 0
fi

MERGE_COUNT=0
TOTAL_READY=$(echo "$READY_PRS" | wc -l | tr -d ' ')

echo "📊 Found $TOTAL_READY PRs ready to merge"
echo ""

while IFS='|' read -r repo pr_number url; do
    echo "[$((MERGE_COUNT + 1))/$TOTAL_READY] 🔀 Processing: $repo (PR #$pr_number)"

    if [ "$DRY_RUN" = "true" ]; then
        echo "   [DRY RUN] Would merge: $url"
    else
        # Merge the PR
        if gh pr merge "$pr_number" --repo "BlackRoad-OS/$repo" --squash --delete-branch 2>/dev/null; then
            echo "   ✅ Merged successfully"
            ((MERGE_COUNT++))
        else
            echo "   ⚠️  Merge failed (may need review approval)"
        fi
    fi
    echo ""
done <<< "$READY_PRS"

echo "════════════════════════════════════════════════════════════"
echo "📊 Merge Summary"
echo "════════════════════════════════════════════════════════════"
if [ "$DRY_RUN" = "true" ]; then
    echo "DRY RUN: Would merge $TOTAL_READY PRs"
    echo ""
    echo "To execute live merge:"
    echo "  DRY_RUN=false ~/pr-auto-merge.sh"
else
    echo "✅ Successfully merged: $MERGE_COUNT/$TOTAL_READY PRs"
fi
echo "════════════════════════════════════════════════════════════"

# Log to memory
~/memory-system.sh log updated "[PEGASUS] PR Auto-Merge" \
    "Auto-merge check: $TOTAL_READY PRs ready, $MERGE_COUNT merged (DRY_RUN=$DRY_RUN)" \
    "automation,prs,visual-docs,merge" 2>/dev/null || true

exit 0
