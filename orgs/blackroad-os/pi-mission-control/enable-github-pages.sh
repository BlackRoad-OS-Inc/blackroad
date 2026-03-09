#!/bin/bash

# 🚀 Enable GitHub Pages for All Pi AI Repositories

set -e

AMBER='\033[38;5;214m'
PINK='\033[38;5;198m'
BLUE='\033[38;5;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${AMBER}🚀 Enabling GitHub Pages for Pi AI Ecosystem${RESET}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Repositories that need GitHub Pages enabled
REPOS=(
    "BlackRoad-OS/pi-cost-calculator"
    "BlackRoad-OS/pi-ai-registry"
    "BlackRoad-OS/pi-ai-hub"
    "BlackRoad-OS/pi-launch-dashboard"
)

echo -e "${PINK}This script will enable GitHub Pages for:${RESET}"
for repo in "${REPOS[@]}"; do
    echo "  • $repo"
done
echo ""

# Function to enable GitHub Pages
enable_pages() {
    local repo=$1
    local repo_name=$(basename "$repo")

    echo -e "${BLUE}Enabling Pages for $repo_name...${RESET}"

    # Try to enable via API
    result=$(gh api -X POST "/repos/$repo/pages" \
        -f source[branch]=master \
        -f source[path]='/' \
        2>&1 || echo "FAILED")

    if echo "$result" | grep -q "FAILED" || echo "$result" | grep -q "error"; then
        echo -e "${RED}❌ Could not auto-enable (may need manual setup)${RESET}"
        echo -e "${AMBER}   Manual steps:${RESET}"
        echo "   1. Go to: https://github.com/$repo/settings/pages"
        echo "   2. Source: Deploy from branch"
        echo "   3. Branch: master (or main)"
        echo "   4. Path: / (root)"
        echo "   5. Click Save"
        echo ""
        return 1
    else
        echo -e "${GREEN}✅ GitHub Pages enabled!${RESET}"
        echo -e "${GREEN}   URL: https://$(echo $repo | sed 's/\//.github.io\//')${RESET}"
        echo ""
        return 0
    fi
}

# Try to enable for each repo
success_count=0
failed_count=0

for repo in "${REPOS[@]}"; do
    if enable_pages "$repo"; then
        ((success_count++))
    else
        ((failed_count++))
    fi
done

# Summary
echo -e "${AMBER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}✅ Success: $success_count${RESET}"
echo -e "${RED}❌ Failed: $failed_count${RESET}"
echo ""

if [ $failed_count -gt 0 ]; then
    echo -e "${AMBER}⚠️  Some repositories need manual setup${RESET}"
    echo ""
    echo "For each failed repo:"
    echo "1. Visit the repository Settings → Pages"
    echo "2. Select 'Deploy from a branch'"
    echo "3. Choose 'master' (or 'main') branch"
    echo "4. Select '/ (root)' path"
    echo "5. Click 'Save'"
    echo ""
fi

echo -e "${BLUE}📊 Expected URLs once enabled:${RESET}"
echo "  • Calculator: https://blackroad-os.github.io/pi-cost-calculator"
echo "  • Registry: https://blackroad-os.github.io/pi-ai-registry"
echo "  • Hub: https://blackroad-os.github.io/pi-ai-hub"
echo "  • Dashboard: https://blackroad-os.github.io/pi-launch-dashboard"
echo ""

echo -e "${GREEN}🖤🛣️ BlackRoad${RESET}"
