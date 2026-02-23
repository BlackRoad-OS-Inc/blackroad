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
# BlackRoad Brand Violation Reporter
# Monitors deployments and sends alerts for non-compliant projects

set -euo pipefail

WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
EMAIL="${ALERT_EMAIL:-blackroad.systems@gmail.com}"
MIN_SCORE=90
VIOLATION_LOG="/Users/alexa/.brand-violations.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🚨 BlackRoad Brand Violation Reporter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for violations in audit results
check_violations() {
    local results_dir="/Users/alexa/brand-audit-results"

    if [ ! -d "$results_dir" ]; then
        echo "⚠️  No audit results found. Run visual audit first."
        return
    fi

    echo "🔍 Scanning audit results for violations..."
    echo ""

    local violations=0
    local total=0

    for result_file in "$results_dir"/*.json; do
        if [ ! -f "$result_file" ]; then
            continue
        fi

        ((total++))

        # Extract project name and score using basic tools
        project=$(basename "$result_file" .json)
        score=$(grep '"score"' "$result_file" | head -n 1 | awk -F': ' '{print $2}' | tr -d ',' || echo "0")

        if [ "$score" -lt "$MIN_SCORE" ]; then
            ((violations++))

            echo -e "${RED}❌ VIOLATION DETECTED${NC}"
            echo "   Project: $project"
            echo "   Score: $score%"
            echo "   Required: ${MIN_SCORE}%"
            echo ""

            # Log violation
            echo "[$(date)] VIOLATION: $project scored $score% (required $MIN_SCORE%)" >> "$VIOLATION_LOG"

            # Send alert
            send_alert "$project" "$score"
        else
            echo -e "${GREEN}✓${NC} $project: $score%"
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Summary:"
    echo "   Total projects audited: $total"
    echo "   Violations found: $violations"
    echo "   Compliance rate: $(( (total - violations) * 100 / total ))%"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ $violations -gt 0 ]; then
        echo -e "${RED}⚠️  VIOLATIONS DETECTED${NC}"
        echo "   Review required for $violations project(s)"
        echo "   Violation log: $VIOLATION_LOG"
    else
        echo -e "${GREEN}✅ All projects compliant!${NC}"
    fi
}

# Send alert via multiple channels
send_alert() {
    local project=$1
    local score=$2

    local message="🚨 BRAND VIOLATION ALERT

Project: $project
Compliance Score: $score%
Required Score: ${MIN_SCORE}%
Status: NON-COMPLIANT

Action required:
1. Review brand compliance issues
2. Update project with official brand system
3. Re-deploy after fixes

Dashboard: file:///Users/alexa/blackroad-brand-dashboard.html
Audit results: ~/brand-audit-results/$project.json"

    # Slack webhook (if configured)
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$WEBHOOK_URL" 2>/dev/null || true
    fi

    # Terminal notification (macOS)
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"$project scored $score% (required ${MIN_SCORE}%)\" with title \"Brand Violation Detected\" sound name \"Basso\"" 2>/dev/null || true
    fi

    # Log to file
    echo "$message" >> "$VIOLATION_LOG"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$VIOLATION_LOG"
}

# Watch mode - continuous monitoring
watch_mode() {
    echo "👁️  Starting continuous monitoring..."
    echo "   Checking every 5 minutes"
    echo "   Press Ctrl+C to stop"
    echo ""

    while true; do
        check_violations
        echo ""
        echo "💤 Sleeping for 5 minutes..."
        sleep 300
    done
}

# Main
case "${1:-check}" in
    check)
        check_violations
        ;;
    watch)
        watch_mode
        ;;
    clear)
        echo "🗑️  Clearing violation log..."
        > "$VIOLATION_LOG"
        echo "✅ Log cleared"
        ;;
    *)
        echo "Usage: brand-violation-reporter.sh [check|watch|clear]"
        echo ""
        echo "Commands:"
        echo "  check  - Check for violations once (default)"
        echo "  watch  - Continuous monitoring (every 5 minutes)"
        echo "  clear  - Clear violation log"
        echo ""
        echo "Environment variables:"
        echo "  SLACK_WEBHOOK_URL  - Slack webhook for alerts"
        echo "  ALERT_EMAIL        - Email for alerts (default: blackroad.systems@gmail.com)"
        exit 1
        ;;
esac
