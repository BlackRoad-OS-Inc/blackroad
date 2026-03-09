#!/bin/bash

# BlackRoad Brand Compliance Checker
# Checks Cloudflare Pages projects for brand compliance

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       🎨 BlackRoad Brand Compliance Checker 🎨            ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Official brand colors (from BLACKROAD_BRAND_SYSTEM.md)
OFFICIAL_COLORS=(
    "#F5A623"  # Amber
    "#FF1D6C"  # Hot Pink (Primary)
    "#2979FF"  # Electric Blue
    "#9C27B0"  # Violet
    "#000000"  # Black (background)
    "#FFFFFF"  # White (text)
)

# Forbidden colors (old system)
FORBIDDEN_COLORS=(
    "#FF9D00"
    "#FF6B00"
    "#FF0066"
    "#FF006B"
    "#D600AA"
    "#7700FF"
    "#0066FF"
)

check_project() {
    local project_name=$1
    echo -e "\n${YELLOW}Checking: $project_name${NC}"

    # Check if GitHub repo exists
    local repo_exists=false
    for org in BlackRoad-OS BlackRoad-AI BlackRoad-Cloud; do
        if gh repo view "$org/$project_name" &>/dev/null; then
            repo_exists=true
            local repo="$org/$project_name"
            break
        fi
    done

    if [ "$repo_exists" = false ]; then
        echo -e "${RED}❌ No GitHub repo found${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ GitHub repo: $repo${NC}"

    # Clone repo to temp directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    gh repo clone "$repo" . &>/dev/null || {
        echo -e "${RED}❌ Failed to clone repo${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    }

    # Check for HTML/CSS files
    local html_files=$(find . -name "*.html" -o -name "*.css" 2>/dev/null | head -5)

    if [ -z "$html_files" ]; then
        echo -e "${YELLOW}⚠️  No HTML/CSS files found${NC}"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 0
    fi

    echo -e "${CYAN}Analyzing files...${NC}"

    # Check for official colors
    local official_found=0
    for color in "${OFFICIAL_COLORS[@]}"; do
        if grep -ri "$color" . &>/dev/null; then
            ((official_found++))
        fi
    done

    # Check for forbidden colors
    local forbidden_found=0
    for color in "${FORBIDDEN_COLORS[@]}"; do
        if grep -ri "$color" . &>/dev/null; then
            ((forbidden_found++))
            echo -e "${RED}❌ Found forbidden color: $color${NC}"
        fi
    done

    # Check for golden ratio
    if grep -ri "1.618\|phi" . &>/dev/null; then
        echo -e "${GREEN}✅ Uses golden ratio${NC}"
    else
        echo -e "${YELLOW}⚠️  No golden ratio found${NC}"
    fi

    # Check for SF Pro Display
    if grep -ri "SF Pro Display" . &>/dev/null; then
        echo -e "${GREEN}✅ Uses SF Pro Display${NC}"
    else
        echo -e "${YELLOW}⚠️  No SF Pro Display font${NC}"
    fi

    # Overall compliance score
    local score=0
    if [ $official_found -ge 3 ]; then
        echo -e "${GREEN}✅ Uses official brand colors ($official_found colors found)${NC}"
        ((score += 40))
    elif [ $official_found -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Partial brand colors ($official_found colors found)${NC}"
        ((score += 20))
    else
        echo -e "${RED}❌ No official brand colors found${NC}"
    fi

    if [ $forbidden_found -eq 0 ]; then
        echo -e "${GREEN}✅ No forbidden colors${NC}"
        ((score += 30))
    else
        echo -e "${RED}❌ Uses $forbidden_found forbidden colors${NC}"
    fi

    # Report score
    echo -e "\n${CYAN}Compliance Score: $score/100${NC}"
    if [ $score -ge 70 ]; then
        echo -e "${GREEN}✅ COMPLIANT${NC}"
    elif [ $score -ge 40 ]; then
        echo -e "${YELLOW}⚠️  PARTIAL${NC}"
    else
        echo -e "${RED}❌ NON-COMPLIANT${NC}"
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
}

# Main execution
echo -e "${CYAN}Checking GitHub-connected projects...${NC}\n"

PROJECTS=(
    "blackroad-os-web"
    "blackroad-os-docs"
    "blackroad-os-brand"
    "blackroad-os-prism"
    "blackroad-api"
    "blackroad-dashboard"
    "earth-blackroad-io"
)

total=0
compliant=0
partial=0
non_compliant=0

for project in "${PROJECTS[@]}"; do
    check_project "$project"
    echo ""
done

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    AUDIT COMPLETE                          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Checked ${#PROJECTS[@]} projects"
echo -e "${GREEN}Next step: Review ~/BLACKROAD_BRAND_SYSTEM.md${NC}"
echo -e "${CYAN}Update non-compliant projects to use official brand colors${NC}"
