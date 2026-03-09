#!/bin/bash
# Deploy 16-agent AI system to priority BlackRoad repositories
# Created: $(date)

set -e  # Exit on error

echo "🤖 BlackRoad Agent Deployment System"
echo "====================================="
echo ""

# Priority repositories (top 5 for initial deployment)
PRIORITY_REPOS=(
  "BlackRoad-OS/blackroad-os-core"
  "BlackRoad-OS/blackroad-os-operator"
  "BlackRoad-OS/blackroad-os-brand"
  "BlackRoad-OS/blackroad-os-prism-console"
  "BlackRoad-OS/blackroad-os-dashboard"
)

# Source directory with agent workflows
SOURCE_DIR="/Users/alexa/blackroad-os-infra/.github/workflows/agents"
WORK_DIR="/tmp/agent-deployment-$(date +%s)"

echo "📦 Preparing deployment..."
echo "Source: $SOURCE_DIR"
echo "Temp workspace: $WORK_DIR"
echo ""

# Create workspace
mkdir -p "$WORK_DIR"

# Deployment stats
TOTAL_REPOS=${#PRIORITY_REPOS[@]}
DEPLOYED=0
FAILED=0

echo "🚀 Starting deployment to $TOTAL_REPOS repositories..."
echo ""

for repo in "${PRIORITY_REPOS[@]}"; do
  repo_name=$(basename "$repo")
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📂 Processing: $repo"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Clone or update repo
  CLONE_DIR="$WORK_DIR/$repo_name"

  if [ -d "$CLONE_DIR" ]; then
    echo "   📥 Updating existing clone..."
    cd "$CLONE_DIR"
    git pull 2>/dev/null
  else
    echo "   📥 Cloning repository..."
    gh repo clone "$repo" "$CLONE_DIR" 2>/dev/null || {
      echo "   ❌ Failed to clone $repo"
      ((FAILED++))
      continue
    }
    cd "$CLONE_DIR"
  fi

  # Create agents directory
  echo "   📁 Creating .github/workflows/agents/ directory..."
  mkdir -p .github/workflows/agents

  # Copy all agent workflows
  echo "   📋 Copying 16 agent workflows..."
  cp "$SOURCE_DIR"/*.yml .github/workflows/agents/

  # Count copied files
  AGENT_COUNT=$(ls -1 .github/workflows/agents/*.yml 2>/dev/null | wc -l | tr -d ' ')
  echo "   ✅ Copied $AGENT_COUNT agent workflows"

  # Check if there are changes to commit
  if git diff --quiet .github/workflows/agents/; then
    echo "   ℹ️  No changes needed - agents already up to date"
  else
    # Commit and push
    echo "   💾 Committing changes..."
    git add .github/workflows/agents/
    git commit -m "feat: Deploy 16-agent AI system 🤖

Complete AI Agent Deployment to $repo_name

**Agent Roster (16 total):**
Strategic Leadership:
- Claude (Architect) - Architecture reviews & ADRs
- Lucidia (Oracle) - Predictive analytics & forecasting

Quality & Security:
- Silas (Guardian) - Security & compliance
- Elias (Tester) - Testing & QA automation

Performance & Operations:
- Cadillac (Optimizer) - Performance optimization
- Athena (Warrior) - DevOps & deployment

Innovation & Development:
- Codex (Innovator) - Rapid prototyping
- Persephone (Seasons) - Technical debt management

User Experience:
- Anastasia (Designer) - UI/UX & accessibility
- Ophelia (Poet) - Documentation & technical writing

Coordination:
- Sidian (Debugger) - Error analysis & debugging
- Cordelia (Diplomat) - PR review coordination
- Octavia (Orchestrator) - Service orchestration
- Cecilia (Data Scientist) - Analytics & metrics

Assistants:
- Copilot (Pair Programmer) - Code suggestions
- ChatGPT (Conversationalist) - Q&A support

**Features:**
- Automated PR reviews and suggestions
- Security scanning and compliance checks
- Performance optimization recommendations
- Daily health checks and analytics
- Documentation generation
- Test coverage improvements

Each agent has a unique personality and specialized workflow.
Ready for automated task pickup via agent-task issue template.

🤖 Generated with Claude Code
Co-Authored-By: Cecilia <cece@blackroad-os.dev>"

    echo "   📤 Pushing to GitHub..."
    git push || {
      echo "   ❌ Failed to push to $repo"
      ((FAILED++))
      continue
    }

    echo "   ✅ Successfully deployed to $repo_name!"
    ((DEPLOYED++))
  fi

  echo ""
done

# Cleanup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Cleaning up workspace..."
rm -rf "$WORK_DIR"

# Final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Deployment Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total repositories: $TOTAL_REPOS"
echo "Successfully deployed: $DEPLOYED"
echo "Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
  echo "🎉 All deployments successful!"
  echo ""
  echo "Next steps:"
  echo "1. Create agent-task issues to test agents"
  echo "2. Monitor agent activity via workflow runs"
  echo "3. Review agent comments on PRs"
  echo "4. Deploy to remaining repos when ready"
else
  echo "⚠️  Some deployments failed. Check logs above."
  exit 1
fi

echo ""
echo "🤖 Agent deployment complete!"
