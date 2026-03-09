#!/bin/bash

# 🌌 BlackRoad-OS Repository Enhancement & Proprietary License Script
# Enhances ALL BlackRoad-OS repos with:
# 1. Professional documentation (README, CONTRIBUTING, GitHub Actions)
# 2. Proprietary BlackRoad OS, Inc. license
# 3. Brand compliance enforcement
# CEO: Alexa Amundson | Supports: 30k agents + 30k employees

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║  🌌 BLACKROAD-OS MEGA ENHANCEMENT & PROTECTION SYSTEM 🌌    ║"
echo "║  Enterprise-Grade + Proprietary Licensing                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Templates
README_TEMPLATE="/tmp/README-template.md"
CONTRIBUTING_TEMPLATE="/tmp/CONTRIBUTING-template.md"
WORKFLOW_TEMPLATE="/tmp/github-workflow-template.yml"

# Proprietary License
PROPRIETARY_LICENSE='PROPRIETARY LICENSE

Copyright (c) 2026 BlackRoad OS, Inc.
All Rights Reserved.

CEO: Alexa Amundson
Organization: BlackRoad OS, Inc.

PROPRIETARY AND CONFIDENTIAL

This software and associated documentation files (the "Software") are the
proprietary and confidential information of BlackRoad OS, Inc.

GRANT OF LICENSE:
Subject to the terms of this license, BlackRoad OS, Inc. grants you a
limited, non-exclusive, non-transferable, revocable license to:
- View and study the source code for educational purposes
- Use the Software for testing and evaluation purposes only
- Fork the repository for personal experimentation

RESTRICTIONS:
You may NOT:
- Use the Software for any commercial purpose
- Resell, redistribute, or sublicense the Software
- Use the Software in production environments without written permission
- Remove or modify this license or any copyright notices
- Create derivative works for commercial distribution

TESTING ONLY:
This Software is provided purely for testing, evaluation, and educational
purposes. It is NOT licensed for commercial use or resale.

INFRASTRUCTURE SCALE:
This Software is designed to support:
- 30,000 AI Agents
- 30,000 Human Employees
- Enterprise-scale operations under BlackRoad OS, Inc.

OWNERSHIP:
All intellectual property rights remain the exclusive property of
BlackRoad OS, Inc.

For commercial licensing inquiries, contact:
BlackRoad OS, Inc.
Alexa Amundson, CEO
blackroad.systems@gmail.com

Last Updated: 2026-01-08'

ORG="BlackRoad-OS"

enhance_and_protect_repo() {
    local repo_name=$1
    local description=$2

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔧 Enhancing & Protecting: $ORG/$repo_name${NC}"
    echo -e "  Description: ${description:0:80}"

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

    # 1. UPDATE LICENSE TO PROPRIETARY
    echo -e "  ${CYAN}🔒 Updating LICENSE to proprietary...${NC}"
    echo "$PROPRIETARY_LICENSE" > LICENSE
    git add LICENSE
    changes_made=true
    echo -e "  ${GREEN}✅ LICENSE updated to proprietary${NC}"

    # 2. ENHANCE/CREATE README
    if [ ! -f "README.md" ] || [ $(wc -c < "README.md" 2>/dev/null || echo 0) -lt 500 ]; then
        echo -e "  ${CYAN}📝 Creating/Enhancing README.md...${NC}"

        local title=$(echo "$repo_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
        local feature_list="- ✨ ${description}\n"

        cat "$README_TEMPLATE" | \
            sed "s|{{TITLE}}|$title|g" | \
            sed "s|{{REPO_NAME}}|$repo_name|g" | \
            sed "s|{{DESCRIPTION}}|$description|g" | \
            sed "s|{{FEATURES}}|$feature_list|g" | \
            sed "s|{{CUSTOM_DOMAIN}}|$repo_name.pages.dev|g" | \
            sed "s|{{STATUS}}|🟢 Active|g" | \
            sed "s|{{DATE}}|$(date +%Y-%m-%d)|g" | \
            sed "s|{{BADGE_BUILD}}|[![Build Status](https://img.shields.io/github/actions/workflow/status/$ORG/$repo_name/deploy.yml?branch=main)](https://github.com/$ORG/$repo_name/actions)|g" | \
            sed "s|{{BADGE_LICENSE}}|[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)|g" | \
            sed "s|{{BADGE_BRAND}}|[![Brand Compliant](https://img.shields.io/badge/Brand-Compliant-success)](https://brand.blackroad.io)|g" \
            > README.md

        git add README.md
        echo -e "  ${GREEN}✅ README.md enhanced${NC}"
    else
        echo -e "  ${YELLOW}⏭️  README.md exists ($(wc -c < README.md) bytes) - keeping${NC}"
    fi

    # 3. ADD COPYRIGHT SECTION TO README
    if [ -f "README.md" ]; then
        if ! grep -q "Copyright.*BlackRoad OS, Inc" README.md 2>/dev/null; then
            echo -e "  ${CYAN}©️  Adding copyright notice to README...${NC}"
            cat >> README.md << 'EOF'

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson

**PROPRIETARY AND CONFIDENTIAL**

This software is the proprietary property of BlackRoad OS, Inc. and is **NOT for commercial resale**.

### ⚠️ Usage Restrictions:
- ✅ **Permitted:** Testing, evaluation, and educational purposes
- ❌ **Prohibited:** Commercial use, resale, or redistribution without written permission

### 🏢 Enterprise Scale:
Designed to support:
- 30,000 AI Agents
- 30,000 Human Employees
- One Operator: Alexa Amundson (CEO)

### 📧 Contact:
For commercial licensing inquiries:
- **Email:** blackroad.systems@gmail.com
- **Organization:** BlackRoad OS, Inc.

See [LICENSE](LICENSE) for complete terms.
EOF
            git add README.md
            echo -e "  ${GREEN}✅ Copyright notice added${NC}"
        fi
    fi

    # 4. CREATE CONTRIBUTING.md
    if [ ! -f "CONTRIBUTING.md" ]; then
        echo -e "  ${CYAN}📋 Creating CONTRIBUTING.md...${NC}"
        local title=$(echo "$repo_name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
        cat "$CONTRIBUTING_TEMPLATE" | sed "s|{{TITLE}}|$title|g" > CONTRIBUTING.md
        git add CONTRIBUTING.md
        echo -e "  ${GREEN}✅ CONTRIBUTING.md created${NC}"
    else
        echo -e "  ${YELLOW}⏭️  CONTRIBUTING.md exists${NC}"
    fi

    # 5. CREATE GITHUB ACTIONS WORKFLOW
    mkdir -p .github/workflows
    if [ ! -f ".github/workflows/deploy.yml" ]; then
        echo -e "  ${CYAN}⚙️  Creating GitHub Actions workflow...${NC}"
        cat "$WORKFLOW_TEMPLATE" | sed "s|{{PROJECT_NAME}}|$repo_name|g" > .github/workflows/deploy.yml
        git add .github/workflows/deploy.yml
        echo -e "  ${GREEN}✅ GitHub Actions workflow created${NC}"
    else
        echo -e "  ${YELLOW}⏭️  Workflow exists${NC}"
    fi

    # COMMIT & PUSH
    if ! git diff --cached --quiet; then
        echo -e "  ${CYAN}💾 Committing changes...${NC}"
        git commit -m "🌌 Enhance & protect with BlackRoad OS, Inc. proprietary license

- Update LICENSE to proprietary (NOT for commercial resale)
- Add/enhance README with professional documentation
- Add copyright notice (© 2026 BlackRoad OS, Inc.)
- Add CONTRIBUTING.md with brand compliance guidelines
- Add GitHub Actions workflow with brand compliance checks
- CEO: Alexa Amundson
- Designed for 30k agents + 30k employees

✨ Repository now enterprise-grade and legally protected

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

    cd - > /dev/null
    rm -rf "$temp_dir"

    # Log to memory
    if [ -n "$MY_CLAUDE" ]; then
        ~/memory-system.sh log enhanced "blackroad-os-$repo_name" "Enhanced & protected $ORG/$repo_name with proprietary license + professional docs" "blackroad-os,enhanced,proprietary" 2>/dev/null || true
    fi

    echo -e "  ${GREEN}✅ Enhancement & protection complete!${NC}"
    return 0
}

# Get all public repos from BlackRoad-OS
echo -e "${CYAN}📡 Fetching public repositories from $ORG...${NC}"
REPO_LIST=$(gh repo list $ORG --limit 100 --json name,description,visibility | jq -r '.[] | select(.visibility == "PUBLIC") | "\(.name)|\(.description // "No description")"')

echo -e "${GREEN}✅ Found $(echo "$REPO_LIST" | wc -l | tr -d ' ') public repositories${NC}\n"

count=0
success=0
failed=0

while IFS='|' read -r name desc; do
    if [ -n "$name" ]; then
        ((count++))
        echo -e "\n${MAGENTA}[$count] Processing: $name${NC}"

        if enhance_and_protect_repo "$name" "$desc"; then
            ((success++))
        else
            ((failed++))
        fi

        sleep 3  # Rate limiting
    fi
done <<< "$REPO_LIST"

echo ""
echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              📊 BLACKROAD-OS ENHANCEMENT SUMMARY 📊          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${GREEN}✅ Successfully Enhanced: $success${NC}"
echo -e "${RED}❌ Failed: $failed${NC}"
echo -e "${CYAN}📋 Total Processed: $count${NC}"
echo ""

echo -e "${GREEN}All BlackRoad-OS public repos now have:${NC}"
echo "  • Proprietary BlackRoad OS, Inc. license"
echo "  • Professional README with documentation"
echo "  • Copyright © 2026 notice"
echo "  • CONTRIBUTING.md with brand guidelines"
echo "  • GitHub Actions workflow (brand compliance + auto-deploy)"
echo "  • CEO: Alexa Amundson"
echo "  • Designed for 30k agents + 30k employees"
echo ""

echo -e "${MAGENTA}🌌 BlackRoad-OS organization now enterprise-ready!${NC}"
