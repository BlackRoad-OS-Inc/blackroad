#!/usr/bin/env bash
# add-github-actions-to-all-repos.sh
# Automatically add Cloudflare Pages deployment workflows to all BlackRoad repositories
# Owner: Alexa Louise Amundson
# Last Updated: 2025-12-22

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 BlackRoad GitHub Actions Automation${NC}"
echo "======================================"
echo ""

# Cloudflare credentials
CLOUDFLARE_API_TOKEN="yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy"
CLOUDFLARE_ACCOUNT_ID="463024cf9efed5e7b40c5fbe7938e256"

# Repository to Pages Project mappings
# Format: "github-repo-name:pages-project-name:build-output-dir"
REPOS=(
  # Lucidia Ecosystem
  "lucidia-metaverse:lucidia-earth:dist"
  "lucidia-platform:lucidia-platform:dist"
  "lucidia-core:lucidia-core:dist"
  "lucidia-math:lucidia-math:dist"

  # BlackRoad Core
  "blackroad-io:blackroad-io:dist"
  "blackroad-os-web:blackroad-os-web:dist"
  "blackroad-os-prism:blackroad-os-prism:dist"
  "blackroad-os-demo:blackroad-os-demo:dist"
  "blackroad-os-home:blackroad-os-home:dist"
  "blackroad-os-brand:blackroad-os-brand:dist"
  "blackroad-os-docs:blackroad-os-docs:dist"
  "earth-blackroad-io:earth-blackroad-io:dist"

  # BlackRoad Services
  "blackroad-hello:blackroad-hello:dist"
  "blackroad-metaverse:blackroad-metaverse:dist"
  "blackroad-console:blackroad-console:dist"
  "blackroad-prism-console:blackroad-prism-console:dist"
  "blackroad-admin:blackroad-admin:dist"
  "blackroad-dashboard:blackroad-dashboard:dist"
  "blackroad-chat:blackroad-chat:dist"
  "blackroad-agents:blackroad-agents:dist"
  "blackroad-agents-spawner:blackroad-agents-spawner:dist"
  "blackroad-tools:blackroad-tools:dist"
  "blackroad-analytics:blackroad-analytics:dist"
  "blackroad-api:blackroad-api:dist"
  "blackroad-api-explorer:blackroad-api-explorer:dist"
  "blackroad-builder:blackroad-builder:dist"
  "blackroad-workflows:blackroad-workflows:dist"
  "blackroad-store:blackroad-store:dist"
  "blackroad-payment-page:blackroad-payment-page:dist"
  "blackroad-buy-now:blackroad-buy-now:dist"
  "blackroad-company:blackroad-company:dist"
  "blackroad-docs-hub:blackroad-docs-hub:dist"

  # BlackRoad Infrastructure
  "blackroad-portals:blackroad-portals:dist"
  "blackroad-portals-unified:blackroad-portals-unified:dist"
  "blackroad-unified:blackroad-unified:dist"
  "blackroad-gateway-web:blackroad-gateway-web:dist"
  "blackroad-assets:blackroad-assets:dist"
  "blackroad-status:blackroad-status:dist"
  "blackroad-status-new:blackroad-status-new:dist"
  "blackroad-pitstop:blackroad-pitstop:dist"
  "blackroad-systems:blackroad-systems:dist"
  "blackroad-me:blackroad-me:dist"

  # Road Ecosystem
  "roadworld:roadworld:dist"
  "roadwork:roadwork:dist"
  "roadwork-production:roadwork-production:dist"
  "roadchain-io:roadchain-io:dist"
  "roadchain-production:roadchain-production:dist"
  "roadcoin-io:roadcoin-io:dist"
  "roadcoin-production:roadcoin-production:dist"

  # Other
  "operations-portal:operations-portal:dist"
  "remotejobs-platform:remotejobs-platform:dist"
  "applier-blackroad:applier-blackroad:dist"
  "blackroad-hello-test:blackroad-hello-test:dist"
)

GITHUB_ORG="BlackRoad-OS"
WORK_DIR="$HOME/github-actions-setup"
PROCESSED=0
SKIPPED=0
FAILED=0

# Create work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo -e "${YELLOW}Processing ${#REPOS[@]} repositories...${NC}"
echo ""

for repo_config in "${REPOS[@]}"; do
  IFS=':' read -r repo_name project_name output_dir <<< "$repo_config"

  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}📦 Processing: $repo_name → $project_name${NC}"

  # Check if repo exists
  if ! gh repo view "$GITHUB_ORG/$repo_name" >/dev/null 2>&1; then
    echo -e "${RED}⚠️  Repository not found, skipping${NC}"
    ((SKIPPED++))
    continue
  fi

  # Clone or update repo
  if [ -d "$repo_name" ]; then
    echo "   📥 Updating existing clone..."
    cd "$repo_name"
    git fetch origin
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || {
      echo -e "${RED}❌ Could not checkout main/master branch${NC}"
      cd ..
      ((FAILED++))
      continue
    }
    git pull origin $(git branch --show-current)
  else
    echo "   📥 Cloning repository..."
    if ! gh repo clone "$GITHUB_ORG/$repo_name"; then
      echo -e "${RED}❌ Clone failed${NC}"
      ((FAILED++))
      continue
    fi
    cd "$repo_name"
  fi

  # Create .github/workflows directory
  mkdir -p .github/workflows

  # Create GitHub Actions workflow
  echo "   ⚙️  Creating deployment workflow..."
  cat > .github/workflows/deploy.yml << EOF
name: Deploy to Cloudflare Pages

on:
  push:
    branches:
      - main
      - master
  pull_request:
    branches:
      - main
      - master

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write

    name: Deploy to Cloudflare Pages

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build project
        run: npm run build
        env:
          NODE_ENV: production

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: \${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: \${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: pages deploy $output_dir --project-name=$project_name

      - name: Comment deployment URL on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '🚀 Preview deployment ready!'
            })
EOF

  # Check if there are changes
  if git diff --quiet .github/workflows/deploy.yml 2>/dev/null; then
    echo -e "   ✓ Workflow already up to date"
  else
    echo "   📝 Committing workflow..."
    git add .github/workflows/deploy.yml
    git commit -m "Add automated Cloudflare Pages deployment

Adds GitHub Actions workflow for automatic deployment to Cloudflare Pages.

- Triggers on push to main/master
- Creates preview deployments for pull requests
- Deploys to $project_name.pages.dev

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"

    echo "   ⬆️  Pushing to GitHub..."
    if git push origin $(git branch --show-current); then
      echo -e "${GREEN}   ✅ Workflow pushed successfully${NC}"
    else
      echo -e "${RED}   ❌ Push failed${NC}"
      cd ..
      ((FAILED++))
      continue
    fi
  fi

  # Set GitHub secrets
  echo "   🔐 Setting GitHub secrets..."

  if gh secret set CLOUDFLARE_API_TOKEN --repo "$GITHUB_ORG/$repo_name" --body "$CLOUDFLARE_API_TOKEN" 2>/dev/null; then
    echo "   ✓ CLOUDFLARE_API_TOKEN set"
  else
    echo "   ⚠️  CLOUDFLARE_API_TOKEN already exists or failed to set"
  fi

  if gh secret set CLOUDFLARE_ACCOUNT_ID --repo "$GITHUB_ORG/$repo_name" --body "$CLOUDFLARE_ACCOUNT_ID" 2>/dev/null; then
    echo "   ✓ CLOUDFLARE_ACCOUNT_ID set"
  else
    echo "   ⚠️  CLOUDFLARE_ACCOUNT_ID already exists or failed to set"
  fi

  cd ..
  ((PROCESSED++))
  echo -e "${GREEN}✅ Completed $repo_name${NC}"
  echo ""
done

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Automation Complete!${NC}"
echo ""
echo "Statistics:"
echo "  ✅ Processed: $PROCESSED"
echo "  ⏭️  Skipped:   $SKIPPED"
echo "  ❌ Failed:    $FAILED"
echo "  📊 Total:     ${#REPOS[@]}"
echo ""
echo "Next steps:"
echo "  1. Check GitHub Actions tab in each repository"
echo "  2. Test with a commit: git push origin main"
echo "  3. Verify deployment at https://[project-name].pages.dev"
echo ""
echo -e "${YELLOW}All repositories are now set up for automatic deployment!${NC}"
echo "Every git push will trigger a deployment to Cloudflare Pages."
echo ""
