#!/bin/bash
# 🎯 PR Monitor - Track 100 Visual Docs Bot Pull Requests
# Agent: claude-pegasus-1766972309

set -e

SCRIPT_NAME="PR Monitoring System"
AGENT_ID="${MY_CLAUDE:-claude-pegasus-1766972309}"

echo "════════════════════════════════════════════════════════════"
echo "🎯 $SCRIPT_NAME"
echo "════════════════════════════════════════════════════════════"
echo "Agent: $AGENT_ID"
echo ""

# Get all BlackRoad-OS repos
REPOS=$(gh repo list BlackRoad-OS --limit 100 --json name,url --jq '.[] | "\(.name)|\(.url)"')
TOTAL_REPOS=$(echo "$REPOS" | wc -l | tr -d ' ')

echo "📊 Checking PRs across $TOTAL_REPOS repositories..."
echo ""

# Counters
OPEN_PRS=0
MERGED_PRS=0
CLOSED_PRS=0
CI_PASSING=0
CI_FAILING=0
CI_PENDING=0
NEEDS_REVIEW=0

# Results file
RESULTS_FILE=~/pr-monitoring-results.json
echo "{\"repos\": [" > "$RESULTS_FILE"

FIRST=true

while IFS='|' read -r repo_name repo_url; do
    # Get PR status for visual-docs-bot-integration branch
    PR_DATA=$(gh pr list --repo "$repo_url" --head visual-docs-bot-integration --json number,state,title,mergeable,statusCheckRollup 2>/dev/null || echo "[]")

    if [ "$PR_DATA" != "[]" ]; then
        PR_NUMBER=$(echo "$PR_DATA" | jq -r '.[0].number // empty')
        PR_STATE=$(echo "$PR_DATA" | jq -r '.[0].state // empty')
        PR_MERGEABLE=$(echo "$PR_DATA" | jq -r '.[0].mergeable // "UNKNOWN"')

        if [ -n "$PR_NUMBER" ]; then
            # Update counters
            if [ "$PR_STATE" = "OPEN" ]; then
                ((OPEN_PRS++))

                # Check CI status
                CI_STATUS=$(echo "$PR_DATA" | jq -r '.[0].statusCheckRollup // [] | if length == 0 then "PENDING" else (map(.conclusion) | if any(. == "FAILURE") then "FAILURE" elif all(. == "SUCCESS") then "SUCCESS" else "PENDING" end) end')

                case "$CI_STATUS" in
                    SUCCESS) ((CI_PASSING++)) ;;
                    FAILURE) ((CI_FAILING++)) ;;
                    *) ((CI_PENDING++)) ;;
                esac

                if [ "$PR_MERGEABLE" = "MERGEABLE" ] && [ "$CI_STATUS" = "SUCCESS" ]; then
                    ((NEEDS_REVIEW++))
                fi
            elif [ "$PR_STATE" = "MERGED" ]; then
                ((MERGED_PRS++))
            else
                ((CLOSED_PRS++))
            fi

            # Add to JSON
            if [ "$FIRST" = false ]; then
                echo "," >> "$RESULTS_FILE"
            fi
            FIRST=false

            cat >> "$RESULTS_FILE" << EOF
    {
      "repo": "$repo_name",
      "pr_number": $PR_NUMBER,
      "state": "$PR_STATE",
      "mergeable": "$PR_MERGEABLE",
      "ci_status": "$CI_STATUS",
      "url": "https://github.com/BlackRoad-OS/$repo_name/pull/$PR_NUMBER"
    }
EOF
        fi
    fi
done <<< "$REPOS"

echo "]}" >> "$RESULTS_FILE"

# Display results
echo "════════════════════════════════════════════════════════════"
echo "📊 PR STATUS SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Total Repositories Checked: $TOTAL_REPOS"
echo ""
echo "Pull Request Status:"
echo "  ✅ Merged:        $MERGED_PRS"
echo "  🟢 Open:          $OPEN_PRS"
echo "  ⚫ Closed:        $CLOSED_PRS"
echo ""
echo "CI/CD Status (Open PRs):"
echo "  ✅ Passing:       $CI_PASSING"
echo "  ❌ Failing:       $CI_FAILING"
echo "  ⏳ Pending:       $CI_PENDING"
echo ""
echo "Ready to Merge:"
echo "  🎯 Needs Review:  $NEEDS_REVIEW"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📄 Detailed results saved to: $RESULTS_FILE"
echo ""

# Log to memory
~/memory-system.sh log updated "[PEGASUS] PR Monitoring" \
    "Monitored 100 Visual Docs Bot PRs: $MERGED_PRS merged, $OPEN_PRS open ($CI_PASSING passing, $CI_FAILING failing, $CI_PENDING pending), $NEEDS_REVIEW ready for review" \
    "monitoring,prs,visual-docs,automation" 2>/dev/null || true

exit 0
