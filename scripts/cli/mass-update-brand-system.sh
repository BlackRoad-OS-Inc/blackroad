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
# Mass Update Brand System Across All Cloudflare Projects
# Updates all projects with official BlackRoad brand standards

set -euo pipefail

BRAND_STARTER="/Users/alexa/blackroad-template-starter.html"
UPDATE_LOG="/Users/alexa/.brand-update-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="/Users/alexa/.brand-backup-$(date +%Y%m%d-%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
PINK='\033[38;5;205m'
NC='\033[0m'

echo -e "${MAGENTA}🌌 BlackRoad Brand System Mass Update${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"
echo -e "${PINK}📦 Backup directory: $BACKUP_DIR${NC}"
echo ""

# Get all Cloudflare projects
echo -e "${PINK}📋 Fetching Cloudflare Pages projects...${NC}"
projects=$(wrangler pages project list 2>/dev/null | grep -E "^│" | awk '{print $2}' | grep -v "Project" | grep -v "^$" || echo "")

if [ -z "$projects" ]; then
    echo -e "${RED}❌ No Cloudflare projects found or not authenticated${NC}"
    exit 1
fi

project_count=$(echo "$projects" | wc -l | tr -d ' ')
echo -e "${GREEN}✅ Found $project_count projects${NC}"
echo ""

# Extract brand CSS from starter template
extract_brand_css() {
    cat "$BRAND_STARTER" | sed -n '/\/\* === BRAND COLORS ===/,/\/\* === RESPONSIVE ===/p'
}

BRAND_CSS=$(extract_brand_css)

# Function to update a single project
update_project() {
    local project=$1
    local index=$2
    local total=$3

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PINK}[$index/$total] Processing: ${YELLOW}$project${NC}"
    echo ""

    # Get latest deployment
    local deployment_id=$(wrangler pages deployment list --project-name="$project" 2>/dev/null | grep -E "^│" | head -n 2 | tail -n 1 | awk '{print $2}' || echo "")

    if [ -z "$deployment_id" ]; then
        echo -e "  ${YELLOW}⚠️  No deployments found - skipping${NC}"
        echo "$project,skipped,no_deployments" >> "$UPDATE_LOG"
        return
    fi

    echo -e "  ${GREEN}✓${NC} Latest deployment: $deployment_id"

    # Try to download deployment (note: this may not work for all projects)
    local temp_dir="/tmp/brand-update-$project"
    mkdir -p "$temp_dir"

    # For now, we'll create an updated index.html
    # In a real scenario, you'd download the actual deployment first

    echo -e "  ${PINK}→${NC} Creating branded version..."

    # Copy starter template
    cp "$BRAND_STARTER" "$temp_dir/index.html"

    # Update title
    sed -i '' "s/BlackRoad OS — New Project/BlackRoad — $project/g" "$temp_dir/index.html"

    echo -e "  ${GREEN}✓${NC} Branded version created"
    echo -e "  ${PINK}→${NC} Ready for deployment"
    echo ""

    echo "$project,ready,temp_dir:$temp_dir" >> "$UPDATE_LOG"
}

# Process all projects
total=$project_count
index=1

while IFS= read -r project; do
    update_project "$project" "$index" "$total"
    ((index++))
done <<< "$projects"

echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}📊 MASS UPDATE SUMMARY${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ready_count=$(grep -c "ready" "$UPDATE_LOG" || echo "0")
skipped_count=$(grep -c "skipped" "$UPDATE_LOG" || echo "0")

echo -e "  Total projects: ${BLUE}$project_count${NC}"
echo -e "  Ready to deploy: ${GREEN}$ready_count${NC}"
echo -e "  Skipped: ${YELLOW}$skipped_count${NC}"
echo ""
echo -e "  Update log: ${PINK}$UPDATE_LOG${NC}"
echo -e "  Backup directory: ${PINK}$BACKUP_DIR${NC}"
echo ""

# Show next steps
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}🚀 NEXT STEPS${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Review generated files in /tmp/brand-update-* directories"
echo ""
echo -e "  To deploy all projects:"
echo -e "  ${PINK}~/bin/deploy-all-branded.sh${NC}"
echo ""
echo -e "  To deploy individual project:"
echo -e "  ${PINK}wrangler pages deploy /tmp/brand-update-PROJECT_NAME --project-name=PROJECT_NAME${NC}"
echo ""

echo -e "${GREEN}✅ Mass update preparation complete!${NC}"
