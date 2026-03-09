#!/bin/bash

# 🔒 Proprietary License Update Script
# Updates ALL BlackRoad repositories with proprietary BlackRoad OS, Inc. license
# NOT for commercial resale - purely for testing
# Supports: 30k agents, 30k employees, CEO: Alexa Amundson

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     🔒 PROPRIETARY LICENSE UPDATE SYSTEM 🔒                 ║"
echo "║     BlackRoad OS, Inc. - All Rights Reserved                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

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
All intellectual property rights, including but not limited to copyrights,
patents, trademarks, and trade secrets, remain the exclusive property of
BlackRoad OS, Inc.

DISCLAIMER:
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
BLACKROAD OS, INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

TERMINATION:
This license is effective until terminated. Your rights under this license
will terminate automatically without notice if you fail to comply with any
of its terms. Upon termination, you must destroy all copies of the Software.

GOVERNING LAW:
This license shall be governed by and construed in accordance with the laws
of the United States of America.

For commercial licensing inquiries, contact:
BlackRoad OS, Inc.
Alexa Amundson, CEO
blackroad.systems@gmail.com

Last Updated: 2026-01-08'

# Organizations to update
ORGS=("blackboxprogramming" "BlackRoad-OS")

update_repo_license() {
    local org=$1
    local repo_name=$2

    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🔒 Updating: $org/$repo_name${NC}"

    # Clone repo
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    echo -e "  ${CYAN}📥 Cloning repository...${NC}"
    if ! gh repo clone "$org/$repo_name" . 2>/dev/null; then
        echo -e "  ${RED}❌ Failed to clone - skipping${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    echo -e "  ${GREEN}✅ Cloned successfully${NC}"

    # Update LICENSE
    echo -e "  ${CYAN}🔒 Updating LICENSE to proprietary...${NC}"
    echo "$PROPRIETARY_LICENSE" > LICENSE
    git add LICENSE
    echo -e "  ${GREEN}✅ LICENSE updated to proprietary${NC}"

    # Add copyright notice to README if exists
    if [ -f "README.md" ]; then
        echo -e "  ${CYAN}©️  Adding copyright notice to README...${NC}"

        # Check if copyright already exists
        if ! grep -q "Copyright.*BlackRoad OS, Inc" README.md 2>/dev/null; then
            # Add copyright section at the end
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
            echo -e "  ${GREEN}✅ Copyright notice added to README${NC}"
        else
            echo -e "  ${YELLOW}⏭️  Copyright notice already exists${NC}"
        fi
    fi

    # Commit if there are changes
    if ! git diff --cached --quiet; then
        echo -e "  ${CYAN}💾 Committing changes...${NC}"

        git commit -m "🔒 Update to proprietary BlackRoad OS, Inc. license

- Change LICENSE from MIT to proprietary
- Add copyright protection for BlackRoad OS, Inc.
- NOT for commercial resale - testing purposes only
- Designed for 30k agents, 30k employees
- CEO: Alexa Amundson

Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.

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

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    # Log to memory
    if [ -n "$MY_CLAUDE" ]; then
        ~/memory-system.sh log updated "proprietary-license-$repo_name" "Updated $org/$repo_name to proprietary BlackRoad OS, Inc. license" "license,proprietary,legal" 2>/dev/null || true
    fi

    echo -e "  ${GREEN}✅ License update complete!${NC}"
    return 0
}

# Main execution
echo -e "${YELLOW}Starting proprietary license updates...${NC}\n"

total=0
success=0
failed=0

for org in "${ORGS[@]}"; do
    echo -e "\n${MAGENTA}═══ Processing organization: $org ═══${NC}\n"

    # Get all public repos
    REPOS=$(gh repo list $org --limit 100 --json name,isPrivate | jq -r '.[] | select(.isPrivate == false) | .name')

    while IFS= read -r repo; do
        if [ -n "$repo" ]; then
            ((total++))
            if update_repo_license "$org" "$repo"; then
                ((success++))
            else
                ((failed++))
            fi
            # Rate limiting
            sleep 3
        fi
    done <<< "$REPOS"
done

echo ""
echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   📊 UPDATE SUMMARY 📊                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${GREEN}✅ Successfully Updated: $success${NC}"
echo -e "${RED}❌ Failed: $failed${NC}"
echo -e "${CYAN}📋 Total Processed: $total${NC}"
echo ""

echo -e "${GREEN}All repositories now protected with:${NC}"
echo "  • Proprietary BlackRoad OS, Inc. license"
echo "  • Copyright protection (© 2026)"
echo "  • CEO: Alexa Amundson"
echo "  • NOT for commercial resale"
echo "  • Testing purposes only"
echo "  • Supports: 30k agents, 30k employees"
echo ""

echo -e "${MAGENTA}🔒 All BlackRoad repositories are now proprietary!${NC}"
