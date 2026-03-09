#!/bin/bash

# 🚀 GitHub Stats Monitor
# Auto-tracks stars, forks, watchers across all Pi AI repos
# Sends notifications when milestones are hit

set -e

# Configuration
REPOS=(
    "BlackRoad-OS/pi-cost-calculator"
    "BlackRoad-OS/pi-ai-starter-kit"
    "BlackRoad-OS/pi-ai-registry"
    "BlackRoad-OS/pi-ai-hub"
    "BlackRoad-OS/pi-launch-dashboard"
)

STATE_FILE="${HOME}/.pi-monitor-state.json"
WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"  # Set via env var

# Colors
AMBER='\033[38;5;214m'
PINK='\033[38;5;198m'
BLUE='\033[38;5;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${AMBER}🚀 Pi AI GitHub Stats Monitor${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "{}" > "$STATE_FILE"
fi

# Function to get repo stats
get_repo_stats() {
    local repo=$1
    local response=$(gh api repos/$repo 2>/dev/null || echo "{}")

    local stars=$(echo "$response" | jq -r '.stargazers_count // 0')
    local forks=$(echo "$response" | jq -r '.forks_count // 0')
    local watchers=$(echo "$response" | jq -r '.subscribers_count // 0')
    local open_issues=$(echo "$response" | jq -r '.open_issues_count // 0')

    echo "$stars|$forks|$watchers|$open_issues"
}

# Function to send Discord notification
send_notification() {
    local message=$1

    if [ -n "$WEBHOOK_URL" ]; then
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" > /dev/null
    fi
}

# Load previous state
previous_state=$(cat "$STATE_FILE")

# Track totals
total_stars=0
total_forks=0
total_watchers=0
total_issues=0

# Track changes
changes_detected=0

echo -e "${PINK}Checking repositories...${RESET}"
echo ""

# Check each repo
for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo")

    # Get current stats
    stats=$(get_repo_stats "$repo")
    IFS='|' read -r stars forks watchers issues <<< "$stats"

    # Get previous stats
    prev_stars=$(echo "$previous_state" | jq -r ".\"$repo\".stars // 0")
    prev_forks=$(echo "$previous_state" | jq -r ".\"$repo\".forks // 0")
    prev_watchers=$(echo "$previous_state" | jq -r ".\"$repo\".watchers // 0")

    # Calculate changes
    star_change=$((stars - prev_stars))
    fork_change=$((forks - prev_forks))
    watch_change=$((watchers - prev_watchers))

    # Update totals
    total_stars=$((total_stars + stars))
    total_forks=$((total_forks + forks))
    total_watchers=$((total_watchers + watchers))
    total_issues=$((total_issues + issues))

    # Display repo stats
    echo -e "${BLUE}📦 $repo_name${RESET}"
    echo -e "   ⭐ Stars: $stars"

    if [ $star_change -gt 0 ]; then
        echo -e "      ${GREEN}+$star_change new!${RESET}"
        changes_detected=1

        # Check milestones
        if [ $stars -ge 100 ] && [ $prev_stars -lt 100 ]; then
            send_notification "🎉 $repo_name just hit 100 stars! 🌟"
        elif [ $stars -ge 50 ] && [ $prev_stars -lt 50 ]; then
            send_notification "🎯 $repo_name reached 50 stars!"
        elif [ $stars -ge 10 ] && [ $prev_stars -lt 10 ]; then
            send_notification "✨ $repo_name got 10 stars!"
        fi
    fi

    echo -e "   🔱 Forks: $forks"
    if [ $fork_change -gt 0 ]; then
        echo -e "      ${GREEN}+$fork_change new!${RESET}"
        changes_detected=1
    fi

    echo -e "   👀 Watchers: $watchers"
    if [ $watch_change -gt 0 ]; then
        echo -e "      ${GREEN}+$watch_change new!${RESET}"
        changes_detected=1
    fi

    echo -e "   🐛 Issues: $issues"
    echo ""

    # Update state
    previous_state=$(echo "$previous_state" | jq ".\"$repo\" = {\"stars\": $stars, \"forks\": $forks, \"watchers\": $watchers}")
done

# Save updated state
echo "$previous_state" > "$STATE_FILE"

# Display totals
echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${PINK}Total Across All Repos:${RESET}"
echo -e "   ⭐ Total Stars: ${GREEN}$total_stars${RESET}"
echo -e "   🔱 Total Forks: ${GREEN}$total_forks${RESET}"
echo -e "   👀 Total Watchers: ${GREEN}$total_watchers${RESET}"
echo -e "   🐛 Total Issues: ${GREEN}$total_issues${RESET}"
echo ""

# Check combined milestones
if [ $total_stars -ge 1000 ]; then
    echo -e "${GREEN}🏆 MILESTONE: 1,000+ total stars!${RESET}"
elif [ $total_stars -ge 500 ]; then
    echo -e "${GREEN}🎯 MILESTONE: 500+ total stars!${RESET}"
elif [ $total_stars -ge 100 ]; then
    echo -e "${GREEN}✨ MILESTONE: 100+ total stars!${RESET}"
fi

if [ $changes_detected -eq 1 ]; then
    echo -e "${GREEN}✅ Changes detected since last check${RESET}"
else
    echo -e "${BLUE}📊 No changes since last check${RESET}"
fi

echo ""
echo -e "${AMBER}Last checked: $(date)${RESET}"

# Export stats for dashboard updates
cat > /tmp/pi-github-stats.json << EOF
{
    "total_stars": $total_stars,
    "total_forks": $total_forks,
    "total_watchers": $total_watchers,
    "total_issues": $total_issues,
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "repos": $(echo "$previous_state" | jq -c .)
}
EOF

echo -e "${BLUE}Stats exported to: /tmp/pi-github-stats.json${RESET}"
