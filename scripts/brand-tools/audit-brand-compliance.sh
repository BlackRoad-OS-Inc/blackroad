#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# BlackRoad Brand Compliance Audit
# Checks all Cloudflare Pages projects against the official brand system

set -euo pipefail

BRAND_DOC="/Users/alexa/BLACKROAD_BRAND_SYSTEM.md"
AUDIT_LOG="/Users/alexa/.blackroad-audit-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}🌌 BlackRoad Brand Compliance Audit${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Required brand elements
declare -A REQUIRED_ELEMENTS=(
    ["--gradient-brand"]="Brand gradient variable"
    ["--hot-pink: #FF1D6C"]="Hot pink primary color"
    ["--amber: #F5A623"]="Amber color"
    ["--electric-blue: #2979FF"]="Electric blue color"
    ["--violet: #9C27B0"]="Violet color"
    ["--space-xs: 8px"]="Golden ratio spacing (xs)"
    ["--space-sm: 13px"]="Golden ratio spacing (sm)"
    ["--space-md: 21px"]="Golden ratio spacing (md)"
    ["--space-lg: 34px"]="Golden ratio spacing (lg)"
    ["--space-xl: 55px"]="Golden ratio spacing (xl)"
    ["line-height: 1.618"]="Golden ratio line height"
    ["-apple-system"]="SF Pro Display font stack"
    ["backdrop-filter"]="Glassmorphism nav"
)

# Animation checks
declare -A REQUIRED_ANIMATIONS=(
    ["logo-spin"]="Logo spin animation"
    ["grid-move"]="Grid movement animation"
    ["--ease-spring"]="Spring easing function"
)

# Function to check a single HTML file
check_file() {
    local file="$1"
    local score=0
    local max_score=${#REQUIRED_ELEMENTS[@]}
    local warnings=()
    local errors=()

    echo -e "${BLUE}📄 Checking: $file${NC}"

    # Check for required CSS variables and styles
    for pattern in "${!REQUIRED_ELEMENTS[@]}"; do
        if grep -q "$pattern" "$file"; then
            ((score++))
            echo -e "  ${GREEN}✓${NC} ${REQUIRED_ELEMENTS[$pattern]}"
        else
            errors+=("${REQUIRED_ELEMENTS[$pattern]}")
            echo -e "  ${RED}✗${NC} ${REQUIRED_ELEMENTS[$pattern]}"
        fi
    done

    # Check for animations
    for pattern in "${!REQUIRED_ANIMATIONS[@]}"; do
        if grep -q "$pattern" "$file"; then
            echo -e "  ${GREEN}✓${NC} ${REQUIRED_ANIMATIONS[$pattern]}"
        else
            warnings+=("${REQUIRED_ANIMATIONS[$pattern]}")
            echo -e "  ${YELLOW}⚠${NC} ${REQUIRED_ANIMATIONS[$pattern]}"
        fi
    done

    # Check for BlackRoad logo SVG
    if grep -q "viewBox=\"0 0 100 100\"" "$file" && grep -q "road-dashes" "$file"; then
        echo -e "  ${GREEN}✓${NC} BlackRoad logo present"
    else
        errors+=("BlackRoad logo SVG")
        echo -e "  ${RED}✗${NC} BlackRoad logo SVG"
    fi

    # Calculate percentage
    local percentage=$((score * 100 / max_score))

    echo ""
    echo -e "  Score: ${BLUE}${score}/${max_score}${NC} (${percentage}%)"

    if [ $percentage -ge 90 ]; then
        echo -e "  Status: ${GREEN}✅ COMPLIANT${NC}"
    elif [ $percentage -ge 70 ]; then
        echo -e "  Status: ${YELLOW}⚠️  NEEDS IMPROVEMENT${NC}"
    else
        echo -e "  Status: ${RED}❌ NON-COMPLIANT${NC}"
    fi

    if [ ${#errors[@]} -gt 0 ]; then
        echo -e "  ${RED}Errors:${NC}"
        for error in "${errors[@]}"; do
            echo -e "    - $error"
        done
    fi

    if [ ${#warnings[@]} -gt 0 ]; then
        echo -e "  ${YELLOW}Warnings:${NC}"
        for warning in "${warnings[@]}"; do
            echo -e "    - $warning"
        done
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Log results
    {
        echo "File: $file"
        echo "Score: $score/$max_score ($percentage%)"
        echo "Errors: ${#errors[@]}"
        echo "Warnings: ${#warnings[@]}"
        echo "---"
    } >> "$AUDIT_LOG"

    return $percentage
}

# Main audit function
main() {
    local total_files=0
    local compliant_files=0
    local total_score=0

    echo "Starting audit at $(date)"
    echo "Reference: $BRAND_DOC"
    echo ""

    # Find all HTML files in common locations
    local search_paths=(
        "/tmp/blackroad-*"
        "/tmp/*-dashboard"
        "$HOME/Desktop/*.html"
        "$HOME/Downloads/*.html"
        "$HOME/Downloads/files*/*.html"
    )

    local files=()
    for path_pattern in "${search_paths[@]}"; do
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find $path_pattern -maxdepth 2 -name "*.html" -type f 2>/dev/null -print0 || true)
    done

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No HTML files found to audit${NC}"
        echo ""
        echo "Searched in:"
        for path in "${search_paths[@]}"; do
            echo "  - $path"
        done
        exit 0
    fi

    # Check each file
    for file in "${files[@]}"; do
        ((total_files++))
        check_file "$file"
        local file_score=$?
        total_score=$((total_score + file_score))

        if [ $file_score -ge 90 ]; then
            ((compliant_files++))
        fi
    done

    # Summary
    echo -e "${MAGENTA}📊 AUDIT SUMMARY${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Total files audited: ${BLUE}$total_files${NC}"
    echo -e "  Compliant files (≥90%): ${GREEN}$compliant_files${NC}"
    echo -e "  Non-compliant files: ${RED}$((total_files - compliant_files))${NC}"

    if [ $total_files -gt 0 ]; then
        local avg_score=$((total_score / total_files))
        echo -e "  Average compliance: ${BLUE}${avg_score}%${NC}"
        echo ""

        if [ $avg_score -ge 90 ]; then
            echo -e "  ${GREEN}✅ Overall status: EXCELLENT${NC}"
        elif [ $avg_score -ge 70 ]; then
            echo -e "  ${YELLOW}⚠️  Overall status: NEEDS WORK${NC}"
        else
            echo -e "  ${RED}❌ Overall status: CRITICAL - IMMEDIATE ACTION REQUIRED${NC}"
        fi
    fi

    echo ""
    echo -e "  Full audit log: ${BLUE}$AUDIT_LOG${NC}"
    echo ""
}

# Run audit
main

# Also check current Cloudflare Pages projects
echo ""
echo -e "${MAGENTA}🔍 Checking deployed Cloudflare Pages projects...${NC}"
echo ""

if command -v wrangler &> /dev/null; then
    echo "Fetching Cloudflare Pages deployments..."
    wrangler pages project list 2>/dev/null || echo "Unable to fetch Cloudflare projects"
else
    echo -e "${YELLOW}⚠️  wrangler CLI not found - skipping Cloudflare check${NC}"
fi

echo ""
echo -e "${GREEN}✅ Audit complete!${NC}"
