#!/bin/bash
# Rapid BlackRoad Empire Licensing Deployment
# Applies MIT licenses to all 199 BlackRoad repositories

WORKSPACE="$HOME/blackroad-licensing-workspace"
GUARDIAN="$HOME/blackroad-license-guardian.sh"

echo "🚀 BlackRoad Empire Licensing - RAPID MODE"
echo ""

# Initialize License Guardian
echo "Initializing License Guardian..."
$GUARDIAN init

# Create workspace
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

# BlackRoad organizations
ORGS="BlackRoad-OS BlackRoad-AI BlackRoad-Cloud BlackRoad-Security BlackRoad-Foundation BlackRoad-Media BlackRoad-Labs BlackRoad-Education BlackRoad-Hardware BlackRoad-Interactive BlackRoad-Ventures BlackRoad-Studio BlackRoad-Archive BlackRoad-Gov Blackbox-Enterprises"

# Clone all repos (with progress)
echo ""
echo "📥 Cloning all BlackRoad repositories..."
total_repos=0
for org in $ORGS; do
  echo "  Cloning $org..."
  gh repo list $org --limit 1000 --json name --jq '.[].name' 2>/dev/null | while read repo; do
    gh repo clone "$org/$repo" "$org-$repo" 2>/dev/null && total_repos=$((total_repos + 1))
  done
done

echo "✅ Cloned $total_repos repositories"

# Scan all repos
echo ""
echo "🔍 Scanning for license compliance..."
$GUARDIAN scan-all "$WORKSPACE"

# Generate initial report
echo ""
echo "📊 Initial Compliance Report:"
$GUARDIAN report

# Fix all non-compliant repos
echo ""
echo "🔧 Fixing non-compliant repositories..."
$GUARDIAN fix-all

# Commit and push changes
echo ""
echo "📤 Committing and pushing changes..."
fixed_count=0
for repo_dir in */; do
  cd "$repo_dir"
  
  if git status --porcelain 2>/dev/null | grep -q "LICENSE"; then
    git add LICENSE
    git commit -m "Add BlackRoad OS, Inc. MIT License

✅ License compliance update
- Added proper MIT license
- Copyright © 2026 BlackRoad OS, Inc.
- Automated by License Guardian

🤖 Generated with License Guardian
https://github.com/BlackRoad-OS

Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null

    # Push to main or master
    if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
      fixed_count=$((fixed_count + 1))
      echo "  ✅ $(basename $repo_dir)"
    fi
  fi
  
  cd "$WORKSPACE"
done

echo ""
echo "✅ Fixed and pushed $fixed_count repositories"

# Final compliance check
echo ""
echo "🎉 FINAL COMPLIANCE REPORT:"
$GUARDIAN scan-all "$WORKSPACE"
$GUARDIAN report

echo ""
echo "🖤🛣️ BlackRoad Empire Licensing Complete!"

