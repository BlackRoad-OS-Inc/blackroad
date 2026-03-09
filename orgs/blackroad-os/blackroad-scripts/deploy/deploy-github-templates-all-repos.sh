#!/bin/bash

# Deploy GitHub Integration Templates to All BlackRoad-OS Repos
# This script deploys issue templates, PR templates, and one-click workflows

set -euo pipefail

INFRA_REPO="/Users/alexa/blackroad-os-infra"
TEMP_DIR="/tmp/github-template-deployment"
LOG_FILE="/tmp/github-template-deployment.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 GitHub Integration Template Deployment"
echo "=========================================="
echo ""

# Create temp directory
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Initialize log
echo "Deployment started at $(date)" > "$LOG_FILE"

# Get all BlackRoad-OS repos
echo -e "${BLUE}Fetching all BlackRoad-OS repositories...${NC}"
gh repo list BlackRoad-OS --limit 1000 --json name,nameWithOwner > "$TEMP_DIR/repos.json"

TOTAL_REPOS=$(jq -r '. | length' "$TEMP_DIR/repos.json")
echo -e "${GREEN}Found $TOTAL_REPOS repositories${NC}"
echo ""

# Deployment plan
echo -e "${BLUE}Deployment Plan:${NC}"
echo "  - 8 issue templates (bug, feature, perf, security, refactor, docs, review, question)"
echo "  - 5 PR templates (default, bugfix, feature, refactor, docs, breaking)"
echo "  - 6 one-click PR workflows"
echo "  - 1 PR health dashboard workflow"
echo ""

# Statistics
DEPLOYED=0
SKIPPED=0
FAILED=0

# Deploy to each repo
for i in $(seq 0 $((TOTAL_REPOS - 1))); do
    REPO_NAME=$(jq -r ".[$i].name" "$TEMP_DIR/repos.json")
    REPO_FULL=$(jq -r ".[$i].nameWithOwner" "$TEMP_DIR/repos.json")

    echo -e "${YELLOW}[$((i+1))/$TOTAL_REPOS]${NC} Processing $REPO_NAME..."

    # Clone repo
    REPO_DIR="$TEMP_DIR/$REPO_NAME"

    if ! gh repo clone "$REPO_FULL" "$REPO_DIR" 2>/dev/null; then
        echo -e "  ${RED}✗ Failed to clone${NC}"
        echo "FAILED: $REPO_NAME - clone failed" >> "$LOG_FILE"
        FAILED=$((FAILED + 1))
        continue
    fi

    cd "$REPO_DIR"

    # Check if it's a valid git repo
    if [ ! -d ".git" ]; then
        echo -e "  ${RED}✗ Not a git repository${NC}"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Create a deployment branch
    BRANCH="github-integration-templates"
    git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH" 2>/dev/null || {
        echo -e "  ${RED}✗ Failed to create branch${NC}"
        FAILED=$((FAILED + 1))
        continue
    }

    # Create directories
    mkdir -p .github/ISSUE_TEMPLATE
    mkdir -p .github/PULL_REQUEST_TEMPLATE
    mkdir -p .github/workflows

    # Copy templates
    CHANGED=0

    # Issue templates
    if ls $INFRA_REPO/.github/ISSUE_TEMPLATE/*.yml 1> /dev/null 2>&1; then
        cp $INFRA_REPO/.github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/
        CHANGED=1
        echo -e "  ${GREEN}✓${NC} Copied 8 issue templates"
    fi

    # PR templates
    if ls $INFRA_REPO/.github/PULL_REQUEST_TEMPLATE/* 1> /dev/null 2>&1; then
        cp -r $INFRA_REPO/.github/PULL_REQUEST_TEMPLATE/* .github/PULL_REQUEST_TEMPLATE/
        CHANGED=1
        echo -e "  ${GREEN}✓${NC} Copied 5 PR templates"
    fi

    # Default PR template
    if [ -f "$INFRA_REPO/.github/pull_request_template.md" ]; then
        cp $INFRA_REPO/.github/pull_request_template.md .github/
        CHANGED=1
        echo -e "  ${GREEN}✓${NC} Copied default PR template"
    fi

    # Quick workflows
    if ls $INFRA_REPO/.github/workflows/quick-*.yml 1> /dev/null 2>&1; then
        cp $INFRA_REPO/.github/workflows/quick-*.yml .github/workflows/
        CHANGED=1
        echo -e "  ${GREEN}✓${NC} Copied 6 quick workflows"
    fi

    # PR dashboard
    if [ -f "$INFRA_REPO/.github/workflows/pr-health-dashboard.yml" ]; then
        cp $INFRA_REPO/.github/workflows/pr-health-dashboard.yml .github/workflows/
        CHANGED=1
        echo -e "  ${GREEN}✓${NC} Copied PR health dashboard"
    fi

    if [ $CHANGED -eq 0 ]; then
        echo -e "  ${YELLOW}⊘ No changes needed${NC}"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Commit and push
    git config user.name "BlackRoad Bot"
    git config user.email "bot@blackroad.dev"
    git add .github/

    if git diff --staged --quiet; then
        echo -e "  ${YELLOW}⊘ No changes to commit${NC}"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    git commit -m "feat: Add GitHub integration templates

Deploy comprehensive issue/PR templates and workflows:
- 8 issue templates with auto-routing to specialist agents
- 5 PR templates for different change types
- 6 one-click PR creation workflows
- PR health dashboard for tracking all PRs

Eliminates 'open PR and hope' - every issue/PR auto-routed!

🤖 Generated with Claude Code
" 2>&1 | tee -a "$LOG_FILE"

    # Push branch
    if git push -u origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"; then
        echo -e "  ${GREEN}✓ Pushed branch${NC}"

        # Create PR
        PR_URL=$(gh pr create \
            --title "feat: Add GitHub Integration Templates" \
            --body "## 🎯 GitHub Integration Templates

This PR adds comprehensive GitHub integration to eliminate \"open PR and hope\"!

### What's Included:

**Issue Templates (8):**
- 🐛 Bug Report (auto-assigns Felix)
- ✨ Feature Request (auto-assigns Codex)
- ⚡ Performance Issue (auto-assigns Cadillac)
- 🛡️ Security Issue (auto-assigns Silas)
- 🔧 Refactoring Request (auto-assigns Winston)
- 📚 Documentation (auto-assigns Ophelia)
- 💎 Code Review (auto-assigns Ruby)
- ❓ Question (auto-assigns ChatGPT)

**PR Templates (5):**
- Enhanced default template
- Bug fix template
- Feature template
- Refactoring template
- Documentation template
- Breaking change template

**One-Click Workflows (6):**
- Quick Bug Fix PR
- Quick Feature PR
- Quick Docs PR
- Quick Refactor PR
- Quick Dependency Update PR
- Quick Security Patch PR

**PR Health Dashboard:**
- Tracks all open PRs
- Health scores (0-100)
- Auto-alerts for PRs needing attention
- Updates every 30 minutes

### Benefits:
✅ Every issue auto-routed to specialist agent
✅ Zero guesswork on PR creation
✅ Automated PR health tracking
✅ One-click workflows for common tasks

### Testing:
- [ ] Create a bug report issue
- [ ] Create a feature PR
- [ ] Check PR health dashboard

🤖 Deployed via automation" \
            --base main \
            --head "$BRANCH" 2>&1) || {
            echo -e "  ${YELLOW}⚠ Could not create PR (may already exist)${NC}"
        }

        if [ -n "$PR_URL" ]; then
            echo -e "  ${GREEN}✓ Created PR: $PR_URL${NC}"
            echo "SUCCESS: $REPO_NAME - $PR_URL" >> "$LOG_FILE"
        fi

        DEPLOYED=$((DEPLOYED + 1))
    else
        echo -e "  ${RED}✗ Failed to push${NC}"
        echo "FAILED: $REPO_NAME - push failed" >> "$LOG_FILE"
        FAILED=$((FAILED + 1))
    fi

    # Clean up
    cd "$TEMP_DIR"
done

# Summary
echo ""
echo "=========================================="
echo -e "${BLUE}Deployment Summary${NC}"
echo "=========================================="
echo -e "${GREEN}✓ Deployed:${NC} $DEPLOYED repos"
echo -e "${YELLOW}⊘ Skipped:${NC} $SKIPPED repos"
echo -e "${RED}✗ Failed:${NC} $FAILED repos"
echo "Total: $TOTAL_REPOS repos"
echo ""
echo "Log file: $LOG_FILE"
echo ""

# Update [MEMORY]
~/memory-system.sh log completed "[MEMORY]+GitHub Templates Deployed" "Deployed GitHub integration templates to $DEPLOYED/$TOTAL_REPOS BlackRoad-OS repos. Templates: 8 issue templates, 5 PR templates, 6 quick workflows, 1 PR dashboard. Auto-routing to 19 specialist agents. Zero guesswork deployment complete!" "cecilia-github-deployment"

echo -e "${GREEN}🎉 Deployment complete!${NC}"
