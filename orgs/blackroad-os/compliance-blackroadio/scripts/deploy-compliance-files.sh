#!/usr/bin/env bash
#
# Deploy compliance files to all BlackRoad repositories
# Devereux - Chief Compliance Officer
#
# This script automatically adds SECURITY.md, LICENSE, and CODEOWNERS
# to all BlackRoad repositories that are missing them.

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

TEMPLATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"
DRY_RUN="${DRY_RUN:-true}"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  📋 BLACKROAD COMPLIANCE FILE DEPLOYMENT SYSTEM 📋        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}"
    echo -e "${YELLOW}   Set DRY_RUN=false to apply changes${NC}"
    echo ""
fi

# Get all BlackRoad-OS repositories
repos=$(gh repo list BlackRoad-OS --json name --limit 200 | jq -r '.[].name')

total_repos=0
repos_updated=0
files_added=0

for repo in $repos; do
    total_repos=$((total_repos + 1))
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Repository: BlackRoad-OS/$repo${NC}"

    repo_updated=false

    # Check and add SECURITY.md
    if ! gh api "repos/BlackRoad-OS/$repo/contents/.github/SECURITY.md" &>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC}  Missing: .github/SECURITY.md"

        if [ "$DRY_RUN" = "false" ]; then
            # Clone repo
            temp_dir=$(mktemp -d)
            gh repo clone "BlackRoad-OS/$repo" "$temp_dir" &>/dev/null

            cd "$temp_dir"

            # Create .github directory if needed
            mkdir -p .github

            # Copy SECURITY.md
            cp "$TEMPLATES_DIR/SECURITY.md" .github/SECURITY.md

            # Commit and push
            git add .github/SECURITY.md
            git commit -m "Add SECURITY.md - Compliance requirement

Deployed by Devereux (Chief Compliance Officer)
Part of BlackRoad OS Master Compliance Framework

This file establishes security vulnerability reporting procedures
and compliance standards for this repository.

🤖 Generated with Claude Code"

            git push origin main || git push origin master

            cd - > /dev/null
            rm -rf "$temp_dir"

            echo -e "  ${GREEN}✓${NC}  Added: .github/SECURITY.md"
            files_added=$((files_added + 1))
            repo_updated=true
        else
            echo -e "  ${BLUE}ℹ${NC}  Would add: .github/SECURITY.md"
        fi
    else
        echo -e "  ${GREEN}✓${NC}  Present: .github/SECURITY.md"
    fi

    # Check and add LICENSE
    if ! gh api "repos/BlackRoad-OS/$repo/contents/LICENSE" &>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC}  Missing: LICENSE"

        if [ "$DRY_RUN" = "false" ]; then
            temp_dir=$(mktemp -d)
            gh repo clone "BlackRoad-OS/$repo" "$temp_dir" &>/dev/null

            cd "$temp_dir"

            cp "$TEMPLATES_DIR/LICENSE" LICENSE

            git add LICENSE
            git commit -m "Add proprietary LICENSE - Compliance requirement

Deployed by Devereux (Chief Compliance Officer)
Part of BlackRoad OS Master Compliance Framework

This repository contains proprietary software subject to
regulatory oversight (SEC, FINRA, FinCEN, CFPB).

Principal: Alexa Louise Amundson (CRD# 7794541)

🤖 Generated with Claude Code"

            git push origin main || git push origin master

            cd - > /dev/null
            rm -rf "$temp_dir"

            echo -e "  ${GREEN}✓${NC}  Added: LICENSE"
            files_added=$((files_added + 1))
            repo_updated=true
        else
            echo -e "  ${BLUE}ℹ${NC}  Would add: LICENSE"
        fi
    else
        echo -e "  ${GREEN}✓${NC}  Present: LICENSE"
    fi

    # Check and add CODEOWNERS
    if ! gh api "repos/BlackRoad-OS/$repo/contents/.github/CODEOWNERS" &>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC}  Missing: .github/CODEOWNERS"

        if [ "$DRY_RUN" = "false" ]; then
            temp_dir=$(mktemp -d)
            gh repo clone "BlackRoad-OS/$repo" "$temp_dir" &>/dev/null

            cd "$temp_dir"

            mkdir -p .github
            cp "$TEMPLATES_DIR/CODEOWNERS" .github/CODEOWNERS

            git add .github/CODEOWNERS
            git commit -m "Add CODEOWNERS - Compliance requirement

Deployed by Devereux (Chief Compliance Officer)
Part of BlackRoad OS Master Compliance Framework

Establishes code review requirements for compliance-critical
areas including security, infrastructure, and documentation.

🤖 Generated with Claude Code"

            git push origin main || git push origin master

            cd - > /dev/null
            rm -rf "$temp_dir"

            echo -e "  ${GREEN}✓${NC}  Added: .github/CODEOWNERS"
            files_added=$((files_added + 1))
            repo_updated=true
        else
            echo -e "  ${BLUE}ℹ${NC}  Would add: .github/CODEOWNERS"
        fi
    else
        echo -e "  ${GREEN}✓${NC}  Present: .github/CODEOWNERS"
    fi

    if [ "$repo_updated" = true ]; then
        repos_updated=$((repos_updated + 1))
    fi
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Deployment Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e ""
echo -e "  Total repositories scanned: ${total_repos}"
echo -e "  Repositories updated: ${repos_updated}"
echo -e "  Total files added: ${files_added}"
echo -e ""

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}⚠️  DRY RUN COMPLETE - No changes were made${NC}"
    echo -e "${YELLOW}   Run with: DRY_RUN=false $0${NC}"
else
    echo -e "${GREEN}✅ DEPLOYMENT COMPLETE${NC}"
    echo -e ""
    echo -e "Next steps:"
    echo -e "  1. Run compliance monitor: ~/compliance-monitor.sh run"
    echo -e "  2. Verify all repos now pass compliance checks"
    echo -e "  3. Update [MEMORY] system with completion status"
fi
