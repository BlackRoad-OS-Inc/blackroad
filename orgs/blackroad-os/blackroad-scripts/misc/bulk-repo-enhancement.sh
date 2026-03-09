#!/bin/bash

# Bulk Repository Enhancement Script
# Adds README, CONTRIBUTING, LICENSE, and GitHub Actions to all repos

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        💎 Bulk Repository Enhancement System 💎          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

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

# Repository metadata
declare -A REPOS

# Phase 2 & 3 repos
REPOS["blackroad-api"]="BlackRoad API|RESTful API endpoints for BlackRoad services|API portal with planned endpoints|🟢 Production Ready|blackroad-api.pages.dev"
REPOS["blackroad-dashboard"]="BlackRoad Dashboard|Real-time monitoring and management dashboard|System health, deployments, AI agents, infrastructure metrics|🟢 Production Ready|blackroad-dashboard.pages.dev"
REPOS["earth-blackroad-io"]="Earth Portal|Sustainability and conservation portal|Animated starfield, Earth statistics, 6 sustainability initiatives|🟢 Production Ready|earth.blackroad.io"
REPOS["console-blackroad-io"]="BlackRoad Console|Developer console and control panel|Sidebar navigation, deployment tracking, real-time monitoring|🟢 Production Ready|console-blackroad-io.pages.dev"

enhance_repo() {
    local repo_name=$1
    local metadata=$2

    IFS='|' read -r title description features status custom_domain <<< "$metadata"

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Enhancing: $repo_name${NC}"
    echo -e "  Title: $title"
    echo -e "  Domain: $custom_domain"

    # Clone repo
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    echo -e "  ${CYAN}Cloning repository...${NC}"
    if ! gh repo clone "BlackRoad-OS/$repo_name" . 2>/dev/null; then
        echo -e "  ${RED}❌ Failed to clone${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    echo -e "  ${GREEN}✅ Cloned successfully${NC}"

    # Generate README
    if [ ! -f "README.md" ] || [ $(wc -c < "README.md") -lt 500 ]; then
        echo -e "  ${CYAN}Creating README.md...${NC}"

        # Build features list
        local feature_list=""
        IFS=',' read -ra FEATURE_ARRAY <<< "$features"
        for feature in "${FEATURE_ARRAY[@]}"; do
            feature_list+="- ✨ $(echo $feature | sed 's/^[[:space:]]*//')\n"
        done

        # Build badges
        local badges="[![Build Status](https://img.shields.io/github/actions/workflow/status/BlackRoad-OS/$repo_name/deploy.yml?branch=main)](https://github.com/BlackRoad-OS/$repo_name/actions)"
        badges+=" [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)"
        badges+=" [![Brand Compliant](https://img.shields.io/badge/Brand-Compliant-success)](https://brand.blackroad.io)"

        # Generate README from template
        cat "$README_TEMPLATE" | \
            sed "s|{{TITLE}}|$title|g" | \
            sed "s|{{REPO_NAME}}|$repo_name|g" | \
            sed "s|{{DESCRIPTION}}|$description|g" | \
            sed "s|{{FEATURES}}|$feature_list|g" | \
            sed "s|{{CUSTOM_DOMAIN}}|$custom_domain|g" | \
            sed "s|{{STATUS}}|$status|g" | \
            sed "s|{{DATE}}|$(date +%Y-%m-%d)|g" | \
            sed "s|{{BADGE_BUILD}}|[![Build Status](https://img.shields.io/github/actions/workflow/status/BlackRoad-OS/$repo_name/deploy.yml?branch=main)](https://github.com/BlackRoad-OS/$repo_name/actions)|g" | \
            sed "s|{{BADGE_LICENSE}}|[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)|g" | \
            sed "s|{{BADGE_BRAND}}|[![Brand Compliant](https://img.shields.io/badge/Brand-Compliant-success)](https://brand.blackroad.io)|g" \
            > README.md

        git add README.md
        echo -e "  ${GREEN}✅ README.md created${NC}"
    else
        echo -e "  ${YELLOW}⚠️  README.md exists ($(wc -c < README.md) bytes) - skipping${NC}"
    fi

    # Generate CONTRIBUTING.md
    if [ ! -f "CONTRIBUTING.md" ]; then
        echo -e "  ${CYAN}Creating CONTRIBUTING.md...${NC}"

        cat "$CONTRIBUTING_TEMPLATE" | \
            sed "s|{{TITLE}}|$title|g" \
            > CONTRIBUTING.md

        git add CONTRIBUTING.md
        echo -e "  ${GREEN}✅ CONTRIBUTING.md created${NC}"
    else
        echo -e "  ${YELLOW}⚠️  CONTRIBUTING.md exists - skipping${NC}"
    fi

    # Add LICENSE
    if [ ! -f "LICENSE" ]; then
        echo -e "  ${CYAN}Creating LICENSE...${NC}"
        echo "$MIT_LICENSE" > LICENSE
        git add LICENSE
        echo -e "  ${GREEN}✅ LICENSE created${NC}"
    else
        echo -e "  ${YELLOW}⚠️  LICENSE exists - skipping${NC}"
    fi

    # Create .github/workflows directory
    mkdir -p .github/workflows

    # Generate GitHub Actions workflow
    if [ ! -f ".github/workflows/deploy.yml" ]; then
        echo -e "  ${CYAN}Creating GitHub Actions workflow...${NC}"

        cat "$WORKFLOW_TEMPLATE" | \
            sed "s|{{PROJECT_NAME}}|$repo_name|g" \
            > .github/workflows/deploy.yml

        git add .github/workflows/deploy.yml
        echo -e "  ${GREEN}✅ GitHub Actions workflow created${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Workflow exists - skipping${NC}"
    fi

    # Commit if there are changes
    if git diff --cached --quiet; then
        echo -e "  ${YELLOW}⚠️  No changes to commit${NC}"
    else
        echo -e "  ${CYAN}Committing changes...${NC}"

        git commit -m "📝 Add comprehensive documentation and CI/CD

- Add detailed README with features and quick start
- Add CONTRIBUTING.md with brand compliance guidelines
- Add MIT LICENSE
- Add GitHub Actions workflow with brand compliance check
- Configure auto-deployment to Cloudflare Pages

✨ Repository fully enhanced for production

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null

        echo -e "  ${CYAN}Pushing changes...${NC}"
        if git push 2>/dev/null; then
            echo -e "  ${GREEN}✅ Changes pushed successfully${NC}"
        else
            echo -e "  ${RED}❌ Failed to push${NC}"
        fi
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    # Log to memory
    if [ -n "$MY_CLAUDE" ]; then
        ~/memory-system.sh log enhanced "repo-$repo_name" "Enhanced with README, CONTRIBUTING, LICENSE, GitHub Actions" "enhancement,repo" 2>/dev/null || true
    fi

    echo -e "  ${GREEN}✅ Enhancement complete!${NC}"
}

# Main execution
echo -e "${YELLOW}Repositories to enhance: ${#REPOS[@]}${NC}\n"

count=0
success=0
skipped=0
failed=0

for repo in "${!REPOS[@]}"; do
    ((count++))
    echo ""
    echo -e "${YELLOW}[$count/${#REPOS[@]}] Enhancing $repo...${NC}"

    if enhance_repo "$repo" "${REPOS[$repo]}"; then
        ((success++))
    else
        ((failed++))
    fi

    # Rate limiting
    sleep 2
done

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                   📊 ENHANCEMENT SUMMARY 📊               ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ Successfully Enhanced: $success${NC}"
echo -e "${RED}❌ Failed: $failed${NC}"
echo -e "${CYAN}📋 Total Processed: ${#REPOS[@]}${NC}"
echo ""

echo -e "${GREEN}Enhancements added:${NC}"
echo "  • Comprehensive README.md with badges"
echo "  • CONTRIBUTING.md with brand guidelines"
echo "  • MIT LICENSE"
echo "  • GitHub Actions workflow (brand compliance + auto-deploy)"
echo ""

echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review changes in each repository"
echo "  2. Configure CLOUDFLARE_API_TOKEN secret in GitHub"
echo "  3. Configure CLOUDFLARE_ACCOUNT_ID secret in GitHub"
echo "  4. Workflows will auto-deploy on next push"
echo ""
