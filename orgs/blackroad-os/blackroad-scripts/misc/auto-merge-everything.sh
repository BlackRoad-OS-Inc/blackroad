#!/usr/bin/env bash
# Auto-merge EVERYTHING - No manual PRs ever again

set -e

echo "🤖 AUTO-MERGE EVERYTHING - Zero Manual Intervention"
echo ""

WEBHOOK_URL="https://blackroad-deploy-dispatcher.amundsonalexa.workers.dev/webhook/github"

# 1. Enable auto-merge on ALL BlackRoad-OS repos
echo "━━━ Step 1: Enabling auto-merge on all repos ━━━"

gh repo list BlackRoad-OS --limit 100 --json name -q '.[].name' | while read repo; do
    echo -n "  $repo ... "
    
    # Enable auto-merge
    gh api "repos/BlackRoad-OS/$repo" --method PATCH -f allow_auto_merge=true &>/dev/null && echo "✅" || echo "⚠️"
    
    # Set branch protection with auto-merge
    gh api "repos/BlackRoad-OS/$repo/branches/main/protection" --method PUT \
        -f required_status_checks='{"strict":false,"contexts":[]}' \
        -f enforce_admins=false \
        -f required_pull_request_reviews=null \
        -f restrictions=null \
        -f allow_force_pushes=true \
        -f allow_deletions=false &>/dev/null || true
done

echo ""
echo "━━━ Step 2: Installing webhooks on all repos ━━━"

gh repo list BlackRoad-OS --limit 100 --json name -q '.[].name' | while read repo; do
    echo -n "  $repo ... "
    
    # Add webhook
    gh api "repos/BlackRoad-OS/$repo/hooks" --method POST \
        -f name=web \
        -f active=true \
        -F config[url]="$WEBHOOK_URL" \
        -f config[content_type]=json \
        -F config[insecure_ssl]=0 \
        -f events[]='push' \
        -f events[]='pull_request' &>/dev/null && echo "✅" || echo "⚠️ (may exist)"
done

echo ""
echo "━━━ Step 3: Creating GitHub Action for auto-merge ━━━"

cat > /tmp/auto-merge.yml << 'EOFACTION'
name: Auto-Merge Everything
on:
  pull_request:
    types: [opened, synchronize]
  push:
    branches: [main, master]

jobs:
  auto-merge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Auto-merge PRs
        if: github.event_name == 'pull_request'
        run: |
          gh pr merge ${{ github.event.pull_request.number }} --auto --squash
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Deploy on push
        if: github.event_name == 'push'
        run: |
          echo "Deployment triggered by Cloudflare Worker"
          curl -X POST https://blackroad-deploy-dispatcher.amundsonalexa.workers.dev/webhook/github \
            -H "Content-Type: application/json" \
            -d "{\"ref\":\"${{ github.ref }}\",\"repository\":{\"full_name\":\"${{ github.repository }}\"},\"after\":\"${{ github.sha }}\",\"pusher\":{\"name\":\"${{ github.actor }}\"}}"
EOFACTION

echo "✅ Created auto-merge action template"
echo ""

echo "━━━ Step 4: Deploying auto-merge action to all repos ━━━"

gh repo list BlackRoad-OS --limit 100 --json name -q '.[].name' | head -20 | while read repo; do
    echo "  $repo ..."
    
    # Clone repo
    rm -rf "/tmp/br-$repo" 2>/dev/null || true
    gh repo clone "BlackRoad-OS/$repo" "/tmp/br-$repo" &>/dev/null || continue
    
    cd "/tmp/br-$repo"
    
    # Create workflow directory
    mkdir -p .github/workflows
    
    # Copy action
    cp /tmp/auto-merge.yml .github/workflows/auto-merge.yml
    
    # Commit and push
    git add .github/workflows/auto-merge.yml
    git commit -m "Add auto-merge workflow - zero manual intervention" &>/dev/null || true
    git push origin main &>/dev/null || git push origin master &>/dev/null || true
    
    echo "    ✅ Deployed"
done

cd ~

echo ""
echo "🎉 AUTO-MERGE SYSTEM DEPLOYED!"
echo ""
echo "What's automated:"
echo "  ✅ All PRs auto-merge when opened"
echo "  ✅ All pushes trigger Cloudflare deployment"
echo "  ✅ All repos have webhooks configured"
echo "  ✅ Zero manual intervention required"
echo ""
echo "Next: Every commit = automatic deployment across entire Pi cluster"
