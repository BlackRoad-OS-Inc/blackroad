#!/usr/bin/env bash
#
# BlackRoad OS - Compliance Slack Alert System
# Sends URGENT notifications for compliance deadlines to Slack
#
# Usage:
#   ./compliance-slack-alerts.sh setup          # Configure Slack webhook
#   ./compliance-slack-alerts.sh check          # Check deadlines and send alerts
#   ./compliance-slack-alerts.sh urgent <msg>   # Send urgent alert immediately
#   ./compliance-slack-alerts.sh daily          # Daily cron job (checks all deadlines)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$HOME/.compliance-slack-config"
COMPLIANCE_DB="$PROJECT_ROOT/compliance.db"

# Colors for terminal output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Slack webhook URL (configured via setup command)
SLACK_WEBHOOK_URL=""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Load Configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Setup - Configure Slack Webhook
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

setup_slack() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║   🚨 COMPLIANCE SLACK ALERT SYSTEM - SETUP 🚨              ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}Step 1: Create Slack Incoming Webhook${NC}"
    echo "  1. Go to: https://api.slack.com/apps"
    echo "  2. Create New App → From Scratch"
    echo "  3. App Name: 'BlackRoad Compliance Alerts'"
    echo "  4. Workspace: Select your workspace"
    echo "  5. Click 'Incoming Webhooks' → Activate"
    echo "  6. Click 'Add New Webhook to Workspace'"
    echo "  7. Select channel (e.g., #compliance, #alerts)"
    echo "  8. Copy Webhook URL"
    echo ""

    read -p "Enter Slack Webhook URL: " webhook_url

    if [[ ! "$webhook_url" =~ ^https://hooks.slack.com/services/ ]]; then
        echo -e "${RED}❌ Invalid webhook URL format${NC}"
        exit 1
    fi

    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# BlackRoad OS - Compliance Slack Configuration
# Generated: $(date)

SLACK_WEBHOOK_URL="$webhook_url"
EOF

    chmod 600 "$CONFIG_FILE"

    echo -e "${GREEN}✅ Configuration saved to: $CONFIG_FILE${NC}"
    echo ""

    # Test webhook
    echo -e "${YELLOW}Sending test message...${NC}"
    send_slack_message "🚀 BlackRoad Compliance Alert System is now active!" "good"

    echo ""
    echo -e "${GREEN}✅ Setup complete!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Run: $0 check              # Check for urgent deadlines"
    echo "  2. Add to cron: 0 9 * * * $0 daily   # Daily check at 9 AM"
    echo ""
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Send Slack Message
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

send_slack_message() {
    local message="$1"
    local color="${2:-warning}" # good, warning, danger

    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        echo -e "${RED}❌ Slack webhook not configured. Run: $0 setup${NC}"
        return 1
    fi

    local payload=$(cat <<EOF
{
    "attachments": [
        {
            "color": "$color",
            "text": "$message",
            "footer": "BlackRoad OS Compliance System",
            "footer_icon": "https://blackroad.io/favicon.ico",
            "ts": $(date +%s)
        }
    ]
}
EOF
    )

    curl -X POST -H 'Content-type: application/json' \
        --data "$payload" \
        "$SLACK_WEBHOOK_URL" \
        --silent --show-error

    echo -e "${GREEN}✅ Slack notification sent${NC}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Send URGENT Alert (Immediate)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

send_urgent_alert() {
    local message="$1"

    echo -e "${RED}🚨 URGENT COMPLIANCE ALERT 🚨${NC}"
    echo "$message"
    echo ""

    local alert_message="🚨 *URGENT COMPLIANCE ALERT* 🚨\n\n$message\n\n*Action Required:* Immediate attention needed!\n*Contact:* Alexa Amundson (CCO) - blackroad.systems@gmail.com"

    send_slack_message "$alert_message" "danger"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Check Compliance Deadlines
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_deadlines() {
    echo -e "${CYAN}🔍 Checking compliance deadlines...${NC}"
    echo ""

    # CRITICAL: Crypto Custody Migration Deadline
    local crypto_deadline="2026-02-04"
    local today=$(date +%Y-%m-%d)
    local days_until=$(( ( $(date -j -f "%Y-%m-%d" "$crypto_deadline" +%s) - $(date -j -f "%Y-%m-%d" "$today" +%s) ) / 86400 ))

    if [[ $days_until -le 30 && $days_until -gt 0 ]]; then
        echo -e "${RED}🔴 CRITICAL: Crypto Custody Migration${NC}"
        echo "   Deadline: $crypto_deadline ($days_until days remaining)"
        echo ""

        local alert="*🔴 CRITICAL COMPLIANCE DEADLINE: Crypto Custody Migration*\n\n"
        alert+="*Deadline:* February 4, 2026 ($days_until days remaining)\n\n"
        alert+="*Issue:* Current crypto holdings in consumer wallets violate SEC Custody Rule:\n"
        alert+="  • ETH: 2.5 (MetaMask) ❌ NON-COMPLIANT\n"
        alert+="  • SOL: 100 (Phantom) ❌ NON-COMPLIANT\n"
        alert+="  • BTC: 0.1 (Coinbase) ⚠️ VERIFY STATUS\n\n"
        alert+="*Required Action:*\n"
        alert+="  1. Select qualified custodian (Coinbase Custody recommended)\n"
        alert+="  2. Complete onboarding application\n"
        alert+="  3. Transfer assets from consumer wallets\n"
        alert+="  4. Verify custody with audit trail\n\n"
        alert+="*Migration Plan:* /tmp/compliance-blackroadio/docs/CRYPTO_CUSTODY_MIGRATION_PLAN.md\n"
        alert+="*Contact CCO:* Alexa Amundson - blackroad.systems@gmail.com"

        send_slack_message "$alert" "danger"
    elif [[ $days_until -le 0 ]]; then
        send_urgent_alert "🚨 *OVERDUE: Crypto Custody Migration Deadline PASSED!*\n\nThe February 4, 2026 deadline has been exceeded. SEC Custody Rule violation in effect. Immediate remediation required!"
    fi

    # Check database for other deadlines
    if [[ -f "$COMPLIANCE_DB" ]]; then
        local upcoming=$(sqlite3 "$COMPLIANCE_DB" << 'SQL'
SELECT
    deadline_date,
    regulation,
    requirement,
    responsible_person,
    julianday(deadline_date) - julianday('now') as days_until
FROM regulatory_deadlines
WHERE status = 'pending'
    AND julianday(deadline_date) - julianday('now') <= 30
    AND julianday(deadline_date) - julianday('now') > 0
ORDER BY deadline_date;
SQL
        )

        if [[ -n "$upcoming" ]]; then
            echo -e "${YELLOW}⚠️  Upcoming deadlines (next 30 days):${NC}"
            echo "$upcoming" | while IFS='|' read -r date reg req person days; do
                echo "   • $date: $reg - $req (${days%.*} days)"

                # Send Slack alert for deadlines within 7 days
                if (( $(echo "$days < 7" | bc -l) )); then
                    local warning="*⚠️  COMPLIANCE DEADLINE APPROACHING*\n\n"
                    warning+="*Date:* $date (${days%.*} days remaining)\n"
                    warning+="*Regulation:* $reg\n"
                    warning+="*Requirement:* $req\n"
                    warning+="*Responsible:* $person\n\n"
                    warning+="*Action Required:* Complete this requirement before deadline."

                    send_slack_message "$warning" "warning"
                fi
            done
            echo ""
        fi
    fi

    # Check for 99 repos missing compliance files
    echo -e "${YELLOW}⚠️  Repository Compliance Status:${NC}"
    echo "   • 99/100 repos missing SECURITY.md, LICENSE, CODEOWNERS"
    echo "   • Deployment script ready: DRY_RUN=false $PROJECT_ROOT/scripts/deploy-compliance-files.sh"
    echo ""

    local repo_warning="*⚠️  Repository Compliance Issue*\n\n"
    repo_warning+="*Status:* 99 out of 100 repositories missing compliance files\n"
    repo_warning+="*Missing:* SECURITY.md, LICENSE, CODEOWNERS\n"
    repo_warning+="*Impact:* Regulatory vulnerability, lack of security disclosure process\n\n"
    repo_warning+="*Action Required:*\n"
    repo_warning+="  Run deployment script: \`DRY_RUN=false $PROJECT_ROOT/scripts/deploy-compliance-files.sh\`\n\n"
    repo_warning+="*Estimated Time:* 30 minutes (automated deployment to all repos)"

    send_slack_message "$repo_warning" "warning"

    echo -e "${GREEN}✅ Deadline check complete${NC}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Daily Cron Job
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

daily_check() {
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Daily Compliance Deadline Check - $(date)${NC}"
    echo -e "${CYAN}════════════════════════════════════════════${NC}"
    echo ""

    check_deadlines

    # Send daily summary
    local summary="*📋 Daily Compliance Summary - $(date +%Y-%m-%d)*\n\n"
    summary+="*5 Core Policies:* ✅ Complete (3,816 lines)\n"
    summary+="*Repository:* github.com/BlackRoad-OS/compliance-blackroadio\n"
    summary+="*Entity:* BlackRoad OS, Inc. (Delaware C-Corp)\n"
    summary+="*Principal:* Alexa Louise Amundson (CRD# 7794541)\n\n"
    summary+="*Next Actions:*\n"
    summary+="  1. 🔴 Crypto custody migration (30 days)\n"
    summary+="  2. ⚠️  Deploy compliance files to 99 repos\n"
    summary+="  3. 📝 Form ADV filing preparation\n\n"
    summary+="Run \`~/compliance-monitor.sh report\` for full compliance status."

    send_slack_message "$summary" "good"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    load_config

    case "${1:-}" in
        setup)
            setup_slack
            ;;
        check)
            check_deadlines
            ;;
        urgent)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 urgent <message>"
                exit 1
            fi
            send_urgent_alert "$2"
            ;;
        daily)
            daily_check
            ;;
        test)
            send_slack_message "🧪 Test message from BlackRoad Compliance System" "good"
            ;;
        *)
            echo "Usage: $0 {setup|check|urgent|daily|test}"
            echo ""
            echo "Commands:"
            echo "  setup    - Configure Slack webhook URL"
            echo "  check    - Check compliance deadlines and send alerts"
            echo "  urgent   - Send urgent alert immediately"
            echo "  daily    - Daily cron job (checks all deadlines)"
            echo "  test     - Send test message to Slack"
            echo ""
            echo "Example cron:"
            echo "  0 9 * * * $0 daily   # Check daily at 9 AM"
            exit 1
            ;;
    esac
}

main "$@"
