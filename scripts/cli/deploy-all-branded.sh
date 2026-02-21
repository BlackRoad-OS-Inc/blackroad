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
# Deploy All Brand-Updated Projects to Cloudflare Pages
# WARNING: This will deploy to production!

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
PINK='\033[38;5;205m'
NC='\033[0m'

echo -e "${MAGENTA}🚀 BlackRoad Brand System - Mass Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Safety check
echo -e "${RED}⚠️  WARNING: This will deploy to ALL Cloudflare Pages projects!${NC}"
echo ""
read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirm

if [ "$confirm" != "YES" ]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${PINK}Starting deployment...${NC}"
echo ""

DEPLOY_LOG="/Users/alexa/.brand-deploy-$(date +%Y%m%d-%H%M%S).log"

# Find all prepared projects
temp_dirs=$(find /tmp -maxdepth 1 -name "brand-update-*" -type d 2>/dev/null || echo "")

if [ -z "$temp_dirs" ]; then
    echo -e "${RED}❌ No prepared projects found${NC}"
    echo -e "${YELLOW}Run ~/bin/mass-update-brand-system.sh first${NC}"
    exit 1
fi

total=$(echo "$temp_dirs" | wc -l | tr -d ' ')
index=1
success=0
failed=0

while IFS= read -r temp_dir; do
    project=$(basename "$temp_dir" | sed 's/brand-update-//')

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PINK}[$index/$total] Deploying: ${YELLOW}$project${NC}"
    echo ""

    if wrangler pages deploy "$temp_dir" --project-name="$project" 2>&1 | tee -a "$DEPLOY_LOG"; then
        echo -e "  ${GREEN}✅ SUCCESS${NC}"
        ((success++))
        echo "$project,success,$(date)" >> "$DEPLOY_LOG"
    else
        echo -e "  ${RED}❌ FAILED${NC}"
        ((failed++))
        echo "$project,failed,$(date)" >> "$DEPLOY_LOG"
    fi

    echo ""
    ((index++))

    # Rate limiting - wait 2 seconds between deployments
    if [ $index -le $total ]; then
        sleep 2
    fi
done <<< "$temp_dirs"

echo ""
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}📊 DEPLOYMENT SUMMARY${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Total deployments: ${BLUE}$total${NC}"
echo -e "  Successful: ${GREEN}$success${NC}"
echo -e "  Failed: ${RED}$failed${NC}"
echo ""
echo -e "  Deployment log: ${PINK}$DEPLOY_LOG${NC}"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}🎉 All deployments completed successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Some deployments failed - check log for details${NC}"
fi

# Run compliance audit on deployed projects
echo ""
echo -e "${PINK}Running compliance audit...${NC}"
~/bin/audit-brand-compliance.sh
