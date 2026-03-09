#!/bin/bash
# Deploy 16-agent AI system to ALL BlackRoad-OS repositories
# End-to-end deployment and testing
# Created: $(date)

set -e  # Exit on error

echo "🤖 BlackRoad FULL DEPLOYMENT - All Repos"
echo "=========================================="
echo ""

# Get all repo names
echo "📋 Fetching repository list from GitHub..."
REPOS=($(gh repo list BlackRoad-OS --limit 100 --json name --jq '.[].name'))
TOTAL_REPOS=${#REPOS[@]}

echo "Found $TOTAL_REPOS repositories in BlackRoad-OS"
echo ""

# Source directory with agent workflows
SOURCE_DIR="/Users/alexa/blackroad-os-infra/.github/workflows/agents"
WORK_DIR="/tmp/agent-full-deployment-$(date +%s)"

echo "📦 Preparing deployment..."
echo "Source: $SOURCE_DIR"
echo "Temp workspace: $WORK_DIR"
echo ""

# Verify source directory exists and has agents
if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ Source directory not found: $SOURCE_DIR"
  exit 1
fi

AGENT_COUNT=$(ls -1 "$SOURCE_DIR"/*.yml 2>/dev/null | wc -l | tr -d ' ')
echo "📋 Found $AGENT_COUNT agent workflows to deploy"
echo ""

# Create workspace
mkdir -p "$WORK_DIR"

# Deployment stats
DEPLOYED=0
FAILED=0
SKIPPED=0
ALREADY_CURRENT=0

# Log file
LOG_FILE="$WORK_DIR/deployment.log"
echo "Starting deployment at $(date)" > "$LOG_FILE"

echo "🚀 Starting full deployment..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for repo_name in "${REPOS[@]}"; do
  repo="BlackRoad-OS/$repo_name"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📂 [$((DEPLOYED + FAILED + SKIPPED + ALREADY_CURRENT + 1))/$TOTAL_REPOS] Processing: $repo_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Clone or update repo
  CLONE_DIR="$WORK_DIR/$repo_name"

  if [ -d "$CLONE_DIR" ]; then
    echo "   📥 Updating existing clone..."
    cd "$CLONE_DIR"
    git pull 2>/dev/null || {
      echo "   ⚠️  Pull failed, re-cloning..."
      cd "$WORK_DIR"
      rm -rf "$CLONE_DIR"
      gh repo clone "$repo" "$CLONE_DIR" 2>/dev/null || {
        echo "   ❌ Failed to clone $repo"
        echo "FAILED: $repo" >> "$LOG_FILE"
        ((FAILED++))
        echo ""
        continue
      }
      cd "$CLONE_DIR"
    }
  else
    echo "   📥 Cloning repository..."
    gh repo clone "$repo" "$CLONE_DIR" 2>/dev/null || {
      echo "   ❌ Failed to clone $repo (might be private/archived)"
      echo "FAILED: $repo" >> "$LOG_FILE"
      ((FAILED++))
      echo ""
      continue
    }
    cd "$CLONE_DIR"
  fi

  # Check if repo has a main or master branch
  DEFAULT_BRANCH=$(git branch -r | grep -E 'origin/(main|master)' | head -1 | sed 's|origin/||' | tr -d ' ')

  if [ -z "$DEFAULT_BRANCH" ]; then
    echo "   ⚠️  No main/master branch found, skipping..."
    echo "SKIPPED: $repo (no default branch)" >> "$LOG_FILE"
    ((SKIPPED++))
    echo ""
    continue
  fi

  git checkout "$DEFAULT_BRANCH" 2>/dev/null || {
    echo "   ❌ Failed to checkout $DEFAULT_BRANCH"
    echo "FAILED: $repo (checkout failed)" >> "$LOG_FILE"
    ((FAILED++))
    echo ""
    continue
  }

  # Create agents directory
  echo "   📁 Creating .github/workflows/agents/ directory..."
  mkdir -p .github/workflows/agents

  # Copy all agent workflows
  echo "   📋 Copying $AGENT_COUNT agent workflows..."
  cp "$SOURCE_DIR"/*.yml .github/workflows/agents/ 2>/dev/null || {
    echo "   ❌ Failed to copy agent files"
    echo "FAILED: $repo (copy failed)" >> "$LOG_FILE"
    ((FAILED++))
    echo ""
    continue
  }

  # Count copied files
  COPIED_COUNT=$(ls -1 .github/workflows/agents/*.yml 2>/dev/null | wc -l | tr -d ' ')
  echo "   ✅ Copied $COPIED_COUNT agent workflows"

  # Check if there are changes to commit
  if git diff --quiet .github/workflows/agents/; then
    echo "   ℹ️  No changes needed - agents already up to date"
    echo "ALREADY_CURRENT: $repo" >> "$LOG_FILE"
    ((ALREADY_CURRENT++))
  else
    # Check for new files
    NEW_FILES=$(git status --porcelain .github/workflows/agents/ | grep "^??" | wc -l | tr -d ' ')
    MODIFIED_FILES=$(git status --porcelain .github/workflows/agents/ | grep "^ M" | wc -l | tr -d ' ')

    echo "   📊 Changes: $NEW_FILES new, $MODIFIED_FILES modified"

    # Commit and push
    echo "   💾 Committing changes..."
    git add .github/workflows/agents/
    git commit -m "feat: Deploy/update 16-agent AI system 🤖

Complete AI Agent Deployment to $repo_name

**Agent Roster (16 total):**
Strategic: Claude, Lucidia
Quality: Silas, Elias
Performance: Cadillac, Athena
Innovation: Codex, Persephone
UX: Anastasia, Ophelia
Coordination: Sidian, Cordelia, Octavia, Cecilia
Assistants: Copilot, ChatGPT

Changes: $NEW_FILES new agents, $MODIFIED_FILES updated

🤖 Generated with Claude Code
Co-Authored-By: Cecilia <cece@blackroad-os.dev>" 2>/dev/null || {
      echo "   ❌ Commit failed"
      echo "FAILED: $repo (commit failed)" >> "$LOG_FILE"
      ((FAILED++))
      echo ""
      continue
    }

    echo "   📤 Pushing to GitHub..."
    git push 2>/dev/null || {
      echo "   ❌ Failed to push (might need permissions)"
      echo "FAILED: $repo (push failed)" >> "$LOG_FILE"
      ((FAILED++))
      echo ""
      continue
    }

    echo "   ✅ Successfully deployed to $repo_name!"
    echo "DEPLOYED: $repo" >> "$LOG_FILE"
    ((DEPLOYED++))
  fi

  echo ""

  # Small delay to avoid rate limiting
  sleep 0.5
done

# Cleanup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Cleaning up workspace..."
# Keep log file, remove clones
find "$WORK_DIR" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +

# Final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 FULL DEPLOYMENT SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total repositories: $TOTAL_REPOS"
echo "Successfully deployed: $DEPLOYED"
echo "Already up to date: $ALREADY_CURRENT"
echo "Skipped: $SKIPPED"
echo "Failed: $FAILED"
echo ""
echo "Completion rate: $(( (DEPLOYED + ALREADY_CURRENT) * 100 / TOTAL_REPOS ))%"
echo ""

# Show log location
echo "📄 Full log: $LOG_FILE"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "🎉 Full deployment successful!"
  echo ""
  echo "Next steps:"
  echo "1. Verify workflows in GitHub Actions"
  echo "2. Create test agent-task issues"
  echo "3. Monitor agent activity"
  echo "4. Review agent comments and PRs"
else
  echo "⚠️  Deployment completed with some failures"
  echo "Check log file for details: $LOG_FILE"
  echo ""
fi

echo "🤖 Agent deployment complete!"
echo ""

# Save summary
cat > "$WORK_DIR/summary.txt" << EOF
BlackRoad Agent Deployment Summary
Generated: $(date)

Total Repositories: $TOTAL_REPOS
Deployed (new): $DEPLOYED
Already Current: $ALREADY_CURRENT
Skipped: $SKIPPED
Failed: $FAILED

Completion Rate: $(( (DEPLOYED + ALREADY_CURRENT) * 100 / TOTAL_REPOS ))%

Agents Deployed: $AGENT_COUNT workflows per repo
- Claude (Architect)
- Cadillac (Optimizer)
- Lucidia (Oracle)
- Silas (Guardian)
- Elias (Tester)
- Athena (Warrior)
- Codex (Innovator)
- Persephone (Seasons)
- Anastasia (Designer)
- Ophelia (Poet)
- Sidian (Debugger)
- Cordelia (Diplomat)
- Octavia (Orchestrator)
- Cecilia (Data Scientist)
- Copilot (Pair Programmer)
- ChatGPT (Conversationalist)

Log File: $LOG_FILE
Summary File: $WORK_DIR/summary.txt
EOF

echo "📄 Summary saved to: $WORK_DIR/summary.txt"
cat "$WORK_DIR/summary.txt"
