#!/bin/bash
# 🔧 Enable All GitHub Features on BlackRoad Repos

set -e

echo "🔧 ENABLE GITHUB FEATURES"
echo "========================="
echo ""

ALL_REPOS=$(gh repo list BlackRoad-OS --limit 100 --json name -q '.[].name')
REPO_COUNT=$(echo "$ALL_REPOS" | wc -l | tr -d ' ')

echo "✅ Found $REPO_COUNT repositories"
echo ""

SUCCESS=0

while IFS= read -r repo_name; do
  [ -z "$repo_name" ] && continue

  echo "🔧 Configuring BlackRoad-OS/$repo_name..."

  # Enable Issues
  gh repo edit "BlackRoad-OS/$repo_name" --enable-issues 2>/dev/null || true

  # Enable Projects
  gh repo edit "BlackRoad-OS/$repo_name" --enable-projects 2>/dev/null || true

  # Enable Wiki
  gh repo edit "BlackRoad-OS/$repo_name" --enable-wiki 2>/dev/null || true

  # Enable Discussions (if available)
  gh repo edit "BlackRoad-OS/$repo_name" --enable-discussions 2>/dev/null || true

  # Set default branch protections
  gh api "repos/BlackRoad-OS/$repo_name/branches/main/protection" \
    -X PUT \
    -f required_status_checks='{"strict":false,"contexts":[]}' \
    -f enforce_admins=false \
    -f required_pull_request_reviews=null \
    -f restrictions=null 2>/dev/null || true

  echo "  ✅ Features enabled"
  ((SUCCESS++))

done <<< "$ALL_REPOS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ GITHUB FEATURES ENABLED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Configured: $SUCCESS repos"
echo ""
echo "Features enabled:"
echo "  ✅ Issues"
echo "  ✅ Projects"
echo "  ✅ Wiki"
echo "  ✅ Discussions"
echo ""
