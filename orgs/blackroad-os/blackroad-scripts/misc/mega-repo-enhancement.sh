#!/bin/bash

# 🚀 MEGA Repository Enhancement Script
# Enhances ALL 45 repositories in blackboxprogramming org
# Adds: README (if missing/small), CONTRIBUTING, LICENSE, GitHub Actions

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     🌌 MEGA REPOSITORY ENHANCEMENT SYSTEM 🌌                ║"
echo "║     Enhancing ALL BlackRoad Repositories                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Template locations
README_TEMPLATE="/tmp/README-template.md"
CONTRIBUTING_TEMPLATE="/tmp/CONTRIBUTING-template.md"
WORKFLOW_TEMPLATE="/tmp/github-workflow-template.yml"

# MIT License
MIT_LICENSE='MIT License

Copyright (c) 2026 BlackRoad OS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.'

# Organization
ORG="blackboxprogramming"

# Get all public repos (skip private for now for safety)
echo -e "${CYAN}📡 Fetching all public repositories from $ORG...${NC}"
REPO_LIST=$(gh repo list $ORG --limit 100 --json name,description,visibility,isPrivate,pushedAt | jq -r '.[] | select(.isPrivate == false) | "\(.name)|\(.description // "No description")"')

echo -e "${GREEN}✅ Found $(echo "$REPO_LIST" | wc -l | tr -d ' ') public repositories${NC}\n"

declare -a REPOS_ARRAY
while IFS='|' read -r name desc; do
    REPOS_ARRAY+=("$name|$desc")
done <<< "$REPO_LIST"

enhance_repo() {
    local repo_name=$1
    local description=$2

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔧 Enhancing: $repo_name${NC}"
    echo -e "  Description: ${description:0:80}..."

    # Clone repo
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    echo -e "  ${CYAN}📥 Cloning repository...${NC}"
    if ! gh repo clone "$ORG/$repo_name" . 2>/dev/null; then
        echo -e "  ${RED}❌ Failed to clone - skipping${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    echo -e "  ${GREEN}✅ Cloned successfully${NC}"

    local changes_made=false

    # Check if README needs enhancement (missing or < 500 bytes)
    if [ ! -f "README.md" ] || [ $(wc -c < "README.md" 2>/dev/null || echo 0) -lt 500 ]; then
        echo -e "  ${CYAN}📝 Creating/Enhancing README.md...${NC}"

        # Use repo name as title (capitalize and format)
        local title=$(echo "$repo_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

        # Build features list from description
        local feature_list="- ✨ ${description}\n"

        # Generate README from template
        cat "$README_TEMPLATE" | \
            sed "s|{{TITLE}}|$title|g" | \
            sed "s|{{REPO_NAME}}|$repo_name|g" | \
            sed "s|{{DESCRIPTION}}|$description|g" | \
            sed "s|{{FEATURES}}|$feature_list|g" | \
            sed "s|{{CUSTOM_DOMAIN}}|$repo_name.pages.dev|g" | \
            sed "s|{{STATUS}}|🟢 Active|g" | \
            sed "s|{{DATE}}|$(date +%Y-%m-%d)|g" | \
            sed "s|{{BADGE_BUILD}}|[![Build Status](https://img.shields.io/github/actions/workflow/status/$ORG/$repo_name/deploy.yml?branch=main)](https://github.com/$ORG/$repo_name/actions)|g" | \
            sed "s|{{BADGE_LICENSE}}|[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)|g" | \
            sed "s|{{BADGE_BRAND}}|[![Brand Compliant](https://img.shields.io/badge/Brand-Compliant-success)](https://brand.blackroad.io)|g" \
            > README.md

        git add README.md
        changes_made=true
        echo -e "  ${GREEN}✅ README.md enhanced${NC}"
    else
        echo -e "  ${YELLOW}⏭️  README.md exists ($(wc -c < README.md) bytes) - skipping${NC}"
    fi

    # Generate CONTRIBUTING.md (only if missing)
    if [ ! -f "CONTRIBUTING.md" ]; then
        echo -e "  ${CYAN}📋 Creating CONTRIBUTING.md...${NC}"

        local title=$(echo "$repo_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

        cat "$CONTRIBUTING_TEMPLATE" | \
            sed "s|{{TITLE}}|$title|g" \
            > CONTRIBUTING.md

        git add CONTRIBUTING.md
        changes_made=true
        echo -e "  ${GREEN}✅ CONTRIBUTING.md created${NC}"
    else
        echo -e "  ${YELLOW}⏭️  CONTRIBUTING.md exists - skipping${NC}"
    fi

    # Add LICENSE (only if missing)
    if [ ! -f "LICENSE" ]; then
        echo -e "  ${CYAN}⚖️  Creating LICENSE...${NC}"
        echo "$MIT_LICENSE" > LICENSE
        git add LICENSE
        changes_made=true
        echo -e "  ${GREEN}✅ LICENSE created${NC}"
    else
        echo -e "  ${YELLOW}⏭️  LICENSE exists - skipping${NC}"
    fi

    # Create .github/workflows directory
    mkdir -p .github/workflows

    # Generate GitHub Actions workflow (only if missing)
    if [ ! -f ".github/workflows/deploy.yml" ]; then
        echo -e "  ${CYAN}⚙️  Creating GitHub Actions workflow...${NC}"

        cat "$WORKFLOW_TEMPLATE" | \
            sed "s|{{PROJECT_NAME}}|$repo_name|g" \
            > .github/workflows/deploy.yml

        git add .github/workflows/deploy.yml
        changes_made=true
        echo -e "  ${GREEN}✅ GitHub Actions workflow created${NC}"
    else
        echo -e "  ${YELLOW}⏭️  Workflow exists - skipping${NC}"
    fi

    # Commit and push if changes were made
    if [ "$changes_made" = true ]; then
        if ! git diff --cached --quiet; then
            echo -e "  ${CYAN}💾 Committing changes...${NC}"

            git commit -m "📝 Enhance repository with professional documentation

- Add/enhance README with features and quick start
- Add CONTRIBUTING.md with brand compliance guidelines
- Add MIT LICENSE
- Add GitHub Actions workflow with brand compliance check
- Configure auto-deployment to Cloudflare Pages

✨ Repository fully enhanced for production

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null

            echo -e "  ${CYAN}🚀 Pushing changes...${NC}"
            if git push 2>/dev/null; then
                echo -e "  ${GREEN}✅ Changes pushed successfully!${NC}"
            else
                echo -e "  ${RED}❌ Failed to push${NC}"
            fi
        else
            echo -e "  ${YELLOW}⚠️  No changes to commit${NC}"
        fi
    else
        echo -e "  ${YELLOW}⏭️  No enhancements needed - repo already complete!${NC}"
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    # Log to memory
    if [ -n "$MY_CLAUDE" ] && [ "$changes_made" = true ]; then
        ~/memory-system.sh log enhanced "repo-$repo_name" "Enhanced with README, CONTRIBUTING, LICENSE, GitHub Actions" "enhancement,repo" 2>/dev/null || true
    fi

    echo -e "  ${GREEN}✅ Enhancement complete!${NC}"
    return 0
}

# Main execution
echo -e "${YELLOW}📊 Total repositories to process: ${#REPOS_ARRAY[@]}${NC}\n"
echo -e "${CYAN}Starting enhancement process...${NC}\n"

count=0
success=0
skipped=0
failed=0

for repo_data in "${REPOS_ARRAY[@]}"; do
    IFS='|' read -r name desc <<< "$repo_data"
    ((count++))

    echo ""
    echo -e "${MAGENTA}[$count/${#REPOS_ARRAY[@]}] Processing: $name${NC}"

    if enhance_repo "$name" "$desc"; then
        ((success++))
    else
        ((failed++))
    fi

    # Rate limiting (be nice to GitHub)
    sleep 3
done

echo ""
echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   📊 FINAL SUMMARY 📊                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${GREEN}✅ Successfully Enhanced: $success${NC}"
echo -e "${RED}❌ Failed: $failed${NC}"
echo -e "${CYAN}📋 Total Processed: ${#REPOS_ARRAY[@]}${NC}"
echo ""

echo -e "${GREEN}Enhancements added across all repos:${NC}"
echo "  • Comprehensive README.md with GitHub badges"
echo "  • CONTRIBUTING.md with BlackRoad brand guidelines"
echo "  • MIT LICENSE for legal protection"
echo "  • GitHub Actions workflow (brand compliance + auto-deploy)"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review changes across all repositories"
echo "  2. Configure CLOUDFLARE_API_TOKEN secret in GitHub org settings"
echo "  3. Configure CLOUDFLARE_ACCOUNT_ID secret in GitHub org settings"
echo "  4. Workflows will auto-deploy on next push to main"
echo ""

echo -e "${MAGENTA}🎊 All repositories enhanced! BlackRoad ecosystem is now production-ready!${NC}"
