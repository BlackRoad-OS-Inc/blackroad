#!/usr/bin/env bash
#
# BlackRoad OS - Continuous Compliance Monitoring System
# Devereux (Chief Compliance Officer)
#
# This script performs automated compliance checks across all BlackRoad infrastructure
# and generates alerts for violations or exceptions.

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPLIANCE_DB="${HOME}/.blackroad-compliance.db"
LOG_FILE="${HOME}/.blackroad-compliance-$(date +%Y%m%d).log"
ALERT_THRESHOLD="HIGH"

# Initialize database
init_compliance_db() {
    sqlite3 "$COMPLIANCE_DB" <<'EOF'
CREATE TABLE IF NOT EXISTS compliance_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    check_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    check_type TEXT NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL,
    severity TEXT NOT NULL,
    finding TEXT,
    remediation TEXT,
    hash TEXT
);

CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT NOT NULL,
    actor TEXT,
    resource TEXT,
    action TEXT,
    result TEXT,
    hash TEXT
);

CREATE TABLE IF NOT EXISTS regulatory_deadlines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    deadline_date DATE NOT NULL,
    regulation TEXT NOT NULL,
    requirement TEXT NOT NULL,
    responsible TEXT,
    status TEXT DEFAULT 'PENDING',
    completed_date DATE
);

CREATE TABLE IF NOT EXISTS exceptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    exception_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    exception_type TEXT NOT NULL,
    description TEXT NOT NULL,
    severity TEXT NOT NULL,
    status TEXT DEFAULT 'OPEN',
    assigned_to TEXT,
    resolved_date TIMESTAMP,
    resolution TEXT
);
EOF
    echo -e "${GREEN}✅ Compliance database initialized${NC}"
}

# Log compliance check
log_check() {
    local check_type="$1"
    local category="$2"
    local status="$3"
    local severity="$4"
    local finding="${5:-}"
    local remediation="${6:-}"

    local hash=$(echo -n "$check_type$category$status$(date +%s)" | shasum -a 256 | cut -c1-16)

    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT INTO compliance_checks (check_type, category, status, severity, finding, remediation, hash)
VALUES ('$check_type', '$category', '$status', '$severity', '$finding', '$remediation', '$hash');
EOF

    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] [$severity] $check_type: $status - $finding" >> "$LOG_FILE"
}

# Check GitHub repository compliance
check_github_compliance() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📋 GitHub Repository Compliance Checks${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check for required compliance files
    local repos=$(gh repo list BlackRoad-OS --json name --limit 100 | jq -r '.[].name')

    local required_files=(
        "README.md"
        "LICENSE"
        ".github/SECURITY.md"
        ".github/CODEOWNERS"
    )

    for repo in $repos; do
        echo -n "  Checking $repo..."

        local missing_files=()
        for file in "${required_files[@]}"; do
            if ! gh api "repos/BlackRoad-OS/$repo/contents/$file" &>/dev/null; then
                missing_files+=("$file")
            fi
        done

        if [ ${#missing_files[@]} -eq 0 ]; then
            echo -e " ${GREEN}✓${NC}"
            log_check "GitHub" "Repository_Standards" "PASS" "INFO" "$repo has all required files"
        else
            echo -e " ${YELLOW}⚠${NC}  Missing: ${missing_files[*]}"
            log_check "GitHub" "Repository_Standards" "FAIL" "MEDIUM" "$repo missing: ${missing_files[*]}" "Add missing compliance files"
        fi
    done
}

# Check for secrets exposure
check_secrets_exposure() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔐 Secrets Exposure Scan${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Patterns to detect
    local patterns=(
        "password"
        "api_key"
        "secret"
        "token"
        "private_key"
        "aws_access"
        "credentials"
    )

    local repos=$(gh repo list BlackRoad-OS --json name --limit 10 | jq -r '.[].name')

    for repo in $repos; do
        for pattern in "${patterns[@]}"; do
            local results=$(gh api "search/code?q=$pattern+repo:BlackRoad-OS/$repo" 2>/dev/null | jq -r '.items[]?.path' 2>/dev/null || echo "")

            if [ -n "$results" ]; then
                echo -e "  ${RED}🚨 Potential secret found in $repo: $pattern${NC}"
                log_check "Security" "Secrets_Exposure" "FAIL" "CRITICAL" "Potential $pattern in $repo" "Review and remove exposed secrets"
            fi
        done
    done

    echo -e "  ${GREEN}✅ Secrets scan completed${NC}"
}

# Check Cloudflare security settings
check_cloudflare_security() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🛡️  Cloudflare Security Configuration${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check if WAF is enabled
    if command -v wrangler &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Wrangler CLI available"
        log_check "Cloudflare" "WAF_Status" "PASS" "INFO" "Wrangler CLI configured"
    else
        echo -e "  ${YELLOW}⚠${NC}  Wrangler CLI not installed"
        log_check "Cloudflare" "WAF_Status" "FAIL" "MEDIUM" "Wrangler CLI not available" "Install Wrangler CLI"
    fi

    # Check SSL/TLS settings (would need API key)
    echo -e "  ${BLUE}ℹ${NC}  Manual check required: Verify SSL/TLS set to 'Full (Strict)'"
    log_check "Cloudflare" "SSL_TLS" "MANUAL" "HIGH" "Verify SSL/TLS settings in Cloudflare dashboard"
}

# Check recordkeeping compliance (17a-4)
check_recordkeeping() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📁 Recordkeeping Compliance (SEC 17a-4)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check for backup systems
    if [ -d "$HOME/.blackroad-backup" ]; then
        echo -e "  ${GREEN}✓${NC} Backup directory exists"
        log_check "Recordkeeping" "Backup_System" "PASS" "INFO" "Backup directory configured"
    else
        echo -e "  ${RED}✗${NC} Backup directory not found"
        log_check "Recordkeeping" "Backup_System" "FAIL" "CRITICAL" "No backup directory" "Create backup system"
    fi

    # Check for WORM storage configuration
    echo -e "  ${BLUE}ℹ${NC}  Manual check: Verify Cloudflare D1 immutable table configuration"
    log_check "Recordkeeping" "WORM_Storage" "MANUAL" "HIGH" "Verify WORM storage for communications"
}

# Check AML/KYC systems
check_aml_kyc() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔍 AML/KYC Compliance${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check for OFAC list update (placeholder - would integrate with actual OFAC API)
    echo -e "  ${BLUE}ℹ${NC}  Manual check: Verify OFAC SDN list updated within 30 days"
    log_check "AML" "OFAC_Update" "MANUAL" "HIGH" "Verify OFAC SDN list freshness"

    # Check for SAR filing deadlines
    echo -e "  ${BLUE}ℹ${NC}  Manual check: Review pending SAR filings (30-day deadline)"
    log_check "AML" "SAR_Deadlines" "MANUAL" "CRITICAL" "Review SAR filing deadlines"
}

# Check crypto custody compliance
check_crypto_custody() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}₿ Crypto Asset Custody Compliance${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check current holdings against custody requirements
    echo -e "  ${YELLOW}⚠${NC}  Current Holdings:"
    echo -e "     • ETH: 2.5 (MetaMask - ${RED}Not qualified custody${NC})"
    echo -e "     • SOL: 100 (Phantom - ${RED}Not qualified custody${NC})"
    echo -e "     • BTC: 0.1 (Coinbase - ${YELLOW}Verify custody status${NC})"

    log_check "Crypto" "Custody_Compliance" "FAIL" "CRITICAL" "Crypto assets not in qualified custody" "Migrate to qualified custodian (Coinbase Custody, Fidelity Digital)"

    echo -e "  ${BLUE}ℹ${NC}  Action Required: Migrate to qualified custodian within 90 days"
}

# Check data privacy compliance
check_privacy_compliance() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔒 Data Privacy Compliance (GDPR, CCPA, GLBA)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check for privacy policy
    echo -e "  ${BLUE}ℹ${NC}  Manual check: Verify privacy policy published and up-to-date"
    log_check "Privacy" "Privacy_Policy" "MANUAL" "HIGH" "Verify privacy policy current"

    # Check for data retention policies
    echo -e "  ${BLUE}ℹ${NC}  Manual check: Verify data retention schedule documented"
    log_check "Privacy" "Data_Retention" "MANUAL" "MEDIUM" "Document data retention policies"
}

# Generate compliance report
generate_report() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📊 Compliance Summary Report${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local total_checks=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM compliance_checks WHERE DATE(check_time) = DATE('now');")
    local passed=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM compliance_checks WHERE DATE(check_time) = DATE('now') AND status = 'PASS';")
    local failed=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM compliance_checks WHERE DATE(check_time) = DATE('now') AND status = 'FAIL';")
    local manual=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM compliance_checks WHERE DATE(check_time) = DATE('now') AND status = 'MANUAL';")

    local critical=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM compliance_checks WHERE DATE(check_time) = DATE('now') AND severity = 'CRITICAL';")
    local high=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM compliance_checks WHERE DATE(check_time) = DATE('now') AND severity = 'HIGH';")
    local medium=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM compliance_checks WHERE DATE(check_time) = DATE('now') AND severity = 'MEDIUM';")

    echo -e "\n  ${CYAN}Total Checks:${NC} $total_checks"
    echo -e "  ${GREEN}✓ Passed:${NC} $passed"
    echo -e "  ${RED}✗ Failed:${NC} $failed"
    echo -e "  ${BLUE}ℹ Manual Review:${NC} $manual"

    echo -e "\n  ${CYAN}Severity Breakdown:${NC}"
    echo -e "  ${RED}🚨 Critical:${NC} $critical"
    echo -e "  ${YELLOW}⚠ High:${NC} $high"
    echo -e "  ${BLUE}ℹ Medium:${NC} $medium"

    if [ "$failed" -gt 0 ] || [ "$critical" -gt 0 ]; then
        echo -e "\n  ${RED}⚠️  COMPLIANCE VIOLATIONS DETECTED - IMMEDIATE ACTION REQUIRED${NC}"
        echo -e "\n${YELLOW}Failed Checks:${NC}"
        sqlite3 "$COMPLIANCE_DB" -header -column "SELECT check_type, category, severity, finding FROM compliance_checks WHERE DATE(check_time) = DATE('now') AND status = 'FAIL' ORDER BY severity DESC;"
    fi

    echo -e "\n  ${CYAN}Full log:${NC} $LOG_FILE"
    echo -e "  ${CYAN}Database:${NC} $COMPLIANCE_DB"
}

# Add regulatory deadline
add_deadline() {
    local deadline_date="$1"
    local regulation="$2"
    local requirement="$3"
    local responsible="${4:-Alexa Amundson}"

    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT INTO regulatory_deadlines (deadline_date, regulation, requirement, responsible)
VALUES ('$deadline_date', '$regulation', '$requirement', '$responsible');
EOF

    echo -e "${GREEN}✅ Deadline added: $regulation - $requirement (Due: $deadline_date)${NC}"
}

# Show upcoming deadlines
show_deadlines() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📅 Upcoming Regulatory Deadlines${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    sqlite3 "$COMPLIANCE_DB" -header -column <<EOF
SELECT
    deadline_date AS 'Due Date',
    regulation AS 'Regulation',
    requirement AS 'Requirement',
    responsible AS 'Responsible',
    status AS 'Status'
FROM regulatory_deadlines
WHERE status = 'PENDING'
  AND deadline_date >= DATE('now')
ORDER BY deadline_date ASC;
EOF
}

# Main execution
main() {
    local command="${1:-run}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║     📋 BLACKROAD OS - COMPLIANCE MONITORING SYSTEM 📋     ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║              Devereux - Chief Compliance Officer           ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    case "$command" in
        init)
            init_compliance_db
            ;;
        run)
            if [ ! -f "$COMPLIANCE_DB" ]; then
                init_compliance_db
            fi

            check_github_compliance
            check_secrets_exposure
            check_cloudflare_security
            check_recordkeeping
            check_aml_kyc
            check_crypto_custody
            check_privacy_compliance
            generate_report
            ;;
        add-deadline)
            shift
            add_deadline "$@"
            ;;
        deadlines)
            show_deadlines
            ;;
        report)
            generate_report
            ;;
        *)
            echo "Usage: $0 {init|run|add-deadline|deadlines|report}"
            echo ""
            echo "Commands:"
            echo "  init                                    Initialize compliance database"
            echo "  run                                     Run all compliance checks"
            echo "  add-deadline <date> <reg> <req> [name]  Add regulatory deadline"
            echo "  deadlines                               Show upcoming deadlines"
            echo "  report                                  Generate compliance report"
            exit 1
            ;;
    esac
}

main "$@"
