#!/usr/bin/env bash
#
# deploy-autonomous-workflows.sh
# Deploy autonomous workflows to all BlackRoad repositories
#
# Usage:
#   ./scripts/deploy-autonomous-workflows.sh [options]
#
# Options:
#   --org <org>       Target specific organization (default: all)
#   --repo <repo>     Target specific repo (format: org/repo)
#   --dry-run         Preview changes without applying
#   --force           Skip confirmation prompts
#   --workflows       Only deploy workflow files
#   --all             Deploy to all repos (default: core repos)
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLACKROAD_DIR="$(dirname "$SCRIPT_DIR")"
WORKFLOWS_DIR="$BLACKROAD_DIR/.github/workflows-autonomous"
TEMP_DIR="/tmp/blackroad-workflow-deploy"

# Organizations
ORGS=(
  "BlackRoad-OS"
  "blackboxprogramming"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Security"
  "Blackbox-Enterprises"
)

# Core repos that always get updated
CORE_REPOS=(
  "BlackRoad-OS/blackroad-os-web"
  "BlackRoad-OS/blackroad-os-docs"
  "BlackRoad-OS/blackroad-cli"
  "BlackRoad-OS/blackroad-agents"
  "BlackRoad-OS/blackroad-os-mesh"
  "BlackRoad-OS/blackroad-os-helper"
  "BlackRoad-OS/blackroad-os-core"
  "BlackRoad-OS/blackroad-os-deploy"
  "BlackRoad-OS/blackroad-os-container"
  "BlackRoad-OS/blackroad-os-prism-console"
  "BlackRoad-OS/lucidia-core"
  "BlackRoad-OS/blackroad-ecosystem-dashboard"
  "blackboxprogramming/blackroad"
  "blackboxprogramming/blackroad-io"
)

# Parse arguments
DRY_RUN=false
FORCE=false
TARGET_ORG=""
TARGET_REPO=""
DEPLOY_ALL=false
WORKFLOWS_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; shift ;;
    --org) TARGET_ORG="$2"; shift 2 ;;
    --repo) TARGET_REPO="$2"; shift 2 ;;
    --all) DEPLOY_ALL=true; shift ;;
    --workflows) WORKFLOWS_ONLY=true; shift ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
  esac
done

# Logging
log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC} $1"; }

# Verify gh CLI
if ! command -v gh &> /dev/null; then
  error "GitHub CLI (gh) not found. Install with: brew install gh"
  exit 1
fi

# Verify authentication
if ! gh auth status &> /dev/null; then
  error "Not authenticated with GitHub. Run: gh auth login"
  exit 1
fi

# Get list of repos to update
get_repos() {
  if [ -n "$TARGET_REPO" ]; then
    echo "$TARGET_REPO"
    return
  fi

  if [ -n "$TARGET_ORG" ]; then
    gh repo list "$TARGET_ORG" --limit 500 --json nameWithOwner -q '.[].nameWithOwner'
    return
  fi

  if [ "$DEPLOY_ALL" = true ]; then
    for org in "${ORGS[@]}"; do
      gh repo list "$org" --limit 500 --json nameWithOwner -q '.[].nameWithOwner' 2>/dev/null || true
    done
    return
  fi

  # Default: core repos only
  printf '%s\n' "${CORE_REPOS[@]}"
}

# Deploy workflows to a single repo
deploy_to_repo() {
  local repo="$1"
  local org=$(echo "$repo" | cut -d'/' -f1)
  local name=$(echo "$repo" | cut -d'/' -f2)

  info "Processing: $repo"

  # Clone repo to temp dir
  local repo_dir="$TEMP_DIR/$org/$name"
  rm -rf "$repo_dir"
  mkdir -p "$(dirname "$repo_dir")"

  if ! gh repo clone "$repo" "$repo_dir" -- --depth 1 2>/dev/null; then
    warn "Failed to clone $repo - skipping"
    return 1
  fi

  # Create .github/workflows directory
  mkdir -p "$repo_dir/.github/workflows"

  # Copy workflow files
  local changed=false
  for workflow in "$WORKFLOWS_DIR"/*.yml; do
    if [ -f "$workflow" ]; then
      local filename=$(basename "$workflow")
      local target="$repo_dir/.github/workflows/$filename"

      # Check if different
      if [ -f "$target" ]; then
        if ! diff -q "$workflow" "$target" > /dev/null 2>&1; then
          cp "$workflow" "$target"
          changed=true
          log "Updated: $filename"
        fi
      else
        cp "$workflow" "$target"
        changed=true
        log "Added: $filename"
      fi
    fi
  done

  if [ "$changed" = false ]; then
    info "No changes needed for $repo"
    return 0
  fi

  if [ "$DRY_RUN" = true ]; then
    warn "DRY RUN: Would commit and push to $repo"
    return 0
  fi

  # Commit and push
  cd "$repo_dir"
  git config user.name "BlackRoad Automation"
  git config user.email "automation@blackroad.ai"

  git add .github/workflows/
  git commit -m "chore(workflows): Deploy autonomous workflow system

Deployed workflows:
- autonomous-orchestrator.yml
- autonomous-self-healer.yml
- autonomous-cross-repo.yml
- autonomous-dependency-manager.yml
- autonomous-issue-manager.yml

These workflows enable:
- Autonomous testing and building
- Self-healing on failures
- AI-powered code review
- Intelligent dependency updates
- Smart issue triage and management
- Cross-repo coordination

Co-Authored-By: BlackRoad Bot <bot@blackroad.ai>" || {
    info "No changes to commit"
    return 0
  }

  if gh repo view "$repo" --json isArchived -q '.isArchived' | grep -q true; then
    warn "Repo $repo is archived - skipping push"
    return 0
  fi

  git push origin HEAD 2>/dev/null || {
    warn "Failed to push to $repo - may need PR"

    # Create a branch and PR instead
    local branch="automation/deploy-autonomous-workflows"
    git checkout -b "$branch"
    git push -u origin "$branch" 2>/dev/null || {
      error "Failed to push branch to $repo"
      return 1
    }

    gh pr create \
      --repo "$repo" \
      --title "chore(workflows): Deploy autonomous workflow system" \
      --body "## Autonomous Workflow Deployment

This PR deploys the enhanced autonomous workflow system.

### Workflows Added/Updated
- **autonomous-orchestrator.yml** - Master coordinator
- **autonomous-self-healer.yml** - Auto-fixes failures
- **autonomous-cross-repo.yml** - Cross-repo sync
- **autonomous-dependency-manager.yml** - Smart dep updates
- **autonomous-issue-manager.yml** - Issue triage and management

### Features
- AI-powered code review
- Automatic test and build
- Self-healing on failures
- Intelligent issue triage
- Cross-repo coordination

---
*Deployed by BlackRoad Automation*" \
      --label "automated,infrastructure" 2>/dev/null || warn "PR may already exist"
  }

  log "Deployed to $repo"
}

# Main execution
main() {
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║     BlackRoad Autonomous Workflow Deployment             ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"

  # Verify workflows exist
  if [ ! -d "$WORKFLOWS_DIR" ]; then
    error "Workflows directory not found: $WORKFLOWS_DIR"
    exit 1
  fi

  local workflow_count=$(ls -1 "$WORKFLOWS_DIR"/*.yml 2>/dev/null | wc -l)
  info "Found $workflow_count workflow files to deploy"

  # Get repos
  info "Gathering target repositories..."
  local repos=($(get_repos))
  local repo_count=${#repos[@]}

  info "Found $repo_count repositories to update"

  if [ "$DRY_RUN" = true ]; then
    warn "DRY RUN MODE - No changes will be made"
  fi

  if [ "$FORCE" != true ] && [ "$DRY_RUN" != true ]; then
    echo ""
    echo -e "${YELLOW}This will deploy workflows to $repo_count repositories.${NC}"
    read -p "Continue? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      info "Aborted"
      exit 0
    fi
  fi

  # Create temp directory
  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"

  # Deploy to each repo
  local success=0
  local failed=0

  for repo in "${repos[@]}"; do
    if deploy_to_repo "$repo"; then
      ((success++))
    else
      ((failed++))
    fi
  done

  # Cleanup
  rm -rf "$TEMP_DIR"

  # Summary
  echo ""
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}Deployment Complete${NC}"
  echo -e "  Success: ${GREEN}$success${NC}"
  echo -e "  Failed:  ${RED}$failed${NC}"
  echo -e "  Total:   $repo_count"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

main "$@"
