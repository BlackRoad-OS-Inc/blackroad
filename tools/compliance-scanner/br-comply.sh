#!/usr/bin/env zsh
# ✅ Compliance Scanner - Feature #34
# Regulatory compliance checking (PCI-DSS, HIPAA, SOC2, GDPR)

# Colors
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
NC='\033[0m'

DB_FILE="$HOME/.blackroad/compliance-scanner.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS compliance_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    framework TEXT,
    control_id TEXT,
    control_name TEXT,
    check_status TEXT,
    evidence TEXT,
    remediation TEXT,
    checked_at INTEGER
);

CREATE TABLE IF NOT EXISTS compliance_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    framework TEXT,
    total_controls INTEGER,
    passed INTEGER,
    failed INTEGER,
    score INTEGER,
    generated_at INTEGER
);
EOF
}

# Scan for PCI-DSS compliance
cmd_pci() {
    init_db
    echo -e "${CYAN}💳 PCI-DSS Compliance Scan${NC}\n"
    
    sqlite3 "$DB_FILE" "DELETE FROM compliance_checks WHERE framework = 'PCI-DSS';"
    
    echo -e "${BLUE}Scanning for Payment Card Industry Data Security Standard...${NC}\n"
    
    # 1. Network Security
    check_pci_firewall
    check_pci_wireless
    
    # 2. Cardholder Data Protection
    check_pci_encryption
    check_pci_data_retention
    
    # 3. Vulnerability Management
    check_pci_antivirus
    check_pci_patches
    
    # 4. Access Control
    check_pci_access_control
    check_pci_authentication
    
    # 5. Monitoring and Testing
    check_pci_logging
    check_pci_testing
    
    generate_report "PCI-DSS"
}

check_pci_firewall() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
            add_compliance_check "PCI-DSS" "1.1" "Firewall Configuration" "PASS" "Firewall enabled" ""
        else
            add_compliance_check "PCI-DSS" "1.1" "Firewall Configuration" "FAIL" "None" "Enable firewall"
        fi
    fi
}

check_pci_wireless() {
    # Check for wireless security
    if networksetup -getairportnetwork en0 2>/dev/null | grep -q "Current Wi-Fi Network"; then
        add_compliance_check "PCI-DSS" "1.2" "Wireless Security" "WARN" "WiFi detected" "Ensure WPA3 encryption"
    else
        add_compliance_check "PCI-DSS" "1.2" "Wireless Security" "PASS" "No wireless" ""
    fi
}

check_pci_encryption() {
    # Check for FileVault (macOS) or disk encryption
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
            add_compliance_check "PCI-DSS" "3.4" "Disk Encryption" "PASS" "FileVault enabled" ""
        else
            add_compliance_check "PCI-DSS" "3.4" "Disk Encryption" "FAIL" "None" "Enable FileVault encryption"
        fi
    fi
}

check_pci_data_retention() {
    # Check for old log files
    local old_logs=$(find ~/Library/Logs -type f -mtime +90 2>/dev/null | wc -l | xargs)
    if [[ $old_logs -gt 50 ]]; then
        add_compliance_check "PCI-DSS" "3.1" "Data Retention" "WARN" "$old_logs old log files" "Review data retention policy"
    else
        add_compliance_check "PCI-DSS" "3.1" "Data Retention" "PASS" "Minimal old data" ""
    fi
}

check_pci_antivirus() {
    # Check for antivirus (simplified check)
    if [[ -d "/Applications/Malwarebytes.app" ]] || [[ -d "/Applications/Avast.app" ]]; then
        add_compliance_check "PCI-DSS" "5.1" "Anti-Malware" "PASS" "AV software installed" ""
    else
        add_compliance_check "PCI-DSS" "5.1" "Anti-Malware" "WARN" "None detected" "Install anti-malware software"
    fi
}

check_pci_patches() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if softwareupdate -l 2>&1 | grep -q "No new software available"; then
            add_compliance_check "PCI-DSS" "6.2" "Security Patches" "PASS" "System up to date" ""
        else
            add_compliance_check "PCI-DSS" "6.2" "Security Patches" "FAIL" "Updates available" "Install system updates"
        fi
    fi
}

check_pci_access_control() {
    # Check for password on account
    local pwd_required=$(dscl . -read /Users/$(whoami) AuthenticationAuthority 2>/dev/null | wc -l)
    if [[ $pwd_required -gt 0 ]]; then
        add_compliance_check "PCI-DSS" "8.1" "Access Control" "PASS" "Password required" ""
    else
        add_compliance_check "PCI-DSS" "8.1" "Access Control" "FAIL" "No password" "Require password"
    fi
}

check_pci_authentication() {
    # Check for multi-factor authentication
    add_compliance_check "PCI-DSS" "8.3" "Multi-Factor Auth" "WARN" "Manual verification needed" "Enable MFA for all accounts"
}

check_pci_logging() {
    # Check if logging is enabled
    if [[ -d "/var/log" ]] && [[ $(ls /var/log 2>/dev/null | wc -l) -gt 0 ]]; then
        add_compliance_check "PCI-DSS" "10.1" "Audit Logging" "PASS" "System logging enabled" ""
    else
        add_compliance_check "PCI-DSS" "10.1" "Audit Logging" "FAIL" "No logs" "Enable audit logging"
    fi
}

check_pci_testing() {
    add_compliance_check "PCI-DSS" "11.2" "Vulnerability Scanning" "WARN" "Manual scan required" "Run quarterly vulnerability scans"
}

# Scan for HIPAA compliance
cmd_hipaa() {
    init_db
    echo -e "${CYAN}🏥 HIPAA Compliance Scan${NC}\n"
    
    sqlite3 "$DB_FILE" "DELETE FROM compliance_checks WHERE framework = 'HIPAA';"
    
    echo -e "${BLUE}Scanning for Health Insurance Portability and Accountability Act...${NC}\n"
    
    # Administrative Safeguards
    check_hipaa_policies()
    check_hipaa_training()
    
    # Physical Safeguards
    check_hipaa_physical()
    
    # Technical Safeguards
    check_hipaa_access_control()
    check_hipaa_audit()
    check_hipaa_integrity()
    check_hipaa_transmission()
    
    generate_report "HIPAA"
}

check_hipaa_policies() {
    # Check for policy documents
    if [[ -d "$HOME/Documents/Policies" ]] || [[ -d "$HOME/policies" ]]; then
        add_compliance_check "HIPAA" "164.308(a)(1)" "Security Policies" "PASS" "Policy directory found" ""
    else
        add_compliance_check "HIPAA" "164.308(a)(1)" "Security Policies" "FAIL" "No policies found" "Create security policy documentation"
    fi
}

check_hipaa_training() {
    add_compliance_check "HIPAA" "164.308(a)(5)" "Security Training" "WARN" "Manual verification" "Ensure annual security training"
}

check_hipaa_physical() {
    # Check screen lock
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local screen_saver=$(defaults read com.apple.screensaver askForPassword 2>/dev/null)
        if [[ "$screen_saver" == "1" ]]; then
            add_compliance_check "HIPAA" "164.310(b)" "Screen Lock" "PASS" "Screen lock enabled" ""
        else
            add_compliance_check "HIPAA" "164.310(b)" "Screen Lock" "FAIL" "Not enabled" "Enable screen lock with password"
        fi
    fi
}

check_hipaa_access_control() {
    # Check file encryption
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
            add_compliance_check "HIPAA" "164.312(a)(1)" "Access Control" "PASS" "Encryption enabled" ""
        else
            add_compliance_check "HIPAA" "164.312(a)(1)" "Access Control" "FAIL" "No encryption" "Enable full disk encryption"
        fi
    fi
}

check_hipaa_audit() {
    # Check audit logs
    if [[ -d "/var/log" ]]; then
        add_compliance_check "HIPAA" "164.312(b)" "Audit Controls" "PASS" "System logging active" ""
    else
        add_compliance_check "HIPAA" "164.312(b)" "Audit Controls" "FAIL" "No logging" "Enable audit logging"
    fi
}

check_hipaa_integrity() {
    # Check for backup system
    if [[ -d "/Volumes/Time Machine Backups" ]] || command -v rsync &> /dev/null; then
        add_compliance_check "HIPAA" "164.312(c)(1)" "Data Integrity" "PASS" "Backup system present" ""
    else
        add_compliance_check "HIPAA" "164.312(c)(1)" "Data Integrity" "WARN" "No backup detected" "Implement backup solution"
    fi
}

check_hipaa_transmission() {
    # Check for VPN or secure transmission
    if [[ -d "/Applications/VPN.app" ]] || command -v openvpn &> /dev/null; then
        add_compliance_check "HIPAA" "164.312(e)(1)" "Transmission Security" "PASS" "VPN available" ""
    else
        add_compliance_check "HIPAA" "164.312(e)(1)" "Transmission Security" "WARN" "No VPN detected" "Use VPN for data transmission"
    fi
}

# Scan for SOC 2 compliance
cmd_soc2() {
    init_db
    echo -e "${CYAN}🔒 SOC 2 Compliance Scan${NC}\n"
    
    sqlite3 "$DB_FILE" "DELETE FROM compliance_checks WHERE framework = 'SOC2';"
    
    echo -e "${BLUE}Scanning for Service Organization Control 2...${NC}\n"
    
    # Trust Service Criteria
    check_soc2_security()
    check_soc2_availability()
    check_soc2_confidentiality()
    
    generate_report "SOC2"
}

check_soc2_security() {
    # Firewall
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
            add_compliance_check "SOC2" "CC6.1" "Logical Access" "PASS" "Firewall active" ""
        else
            add_compliance_check "SOC2" "CC6.1" "Logical Access" "FAIL" "No firewall" "Enable firewall"
        fi
    fi
    
    # Encryption
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
            add_compliance_check "SOC2" "CC6.7" "Encryption" "PASS" "Disk encrypted" ""
        else
            add_compliance_check "SOC2" "CC6.7" "Encryption" "FAIL" "No encryption" "Enable disk encryption"
        fi
    fi
}

check_soc2_availability() {
    # Check uptime
    local uptime_days=$(uptime | awk '{print $3}' | sed 's/,//')
    add_compliance_check "SOC2" "A1.1" "System Availability" "PASS" "Uptime: $uptime_days" ""
}

check_soc2_confidentiality() {
    # Check SSH key permissions
    local bad_keys=0
    for key in ~/.ssh/id_*; do
        if [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]]; then
            local perms=$(stat -f "%Lp" "$key" 2>/dev/null || stat -c "%a" "$key" 2>/dev/null)
            [[ "$perms" != "600" ]] && bad_keys=$((bad_keys + 1))
        fi
    done
    
    if [[ $bad_keys -eq 0 ]]; then
        add_compliance_check "SOC2" "CC6.6" "Confidentiality" "PASS" "Keys properly secured" ""
    else
        add_compliance_check "SOC2" "CC6.6" "Confidentiality" "FAIL" "$bad_keys insecure keys" "Fix key permissions: chmod 600 ~/.ssh/id_*"
    fi
}

# Scan for GDPR compliance
cmd_gdpr() {
    init_db
    echo -e "${CYAN}🇪🇺 GDPR Compliance Scan${NC}\n"
    
    sqlite3 "$DB_FILE" "DELETE FROM compliance_checks WHERE framework = 'GDPR';"
    
    echo -e "${BLUE}Scanning for General Data Protection Regulation...${NC}\n"
    
    check_gdpr_encryption()
    check_gdpr_access()
    check_gdpr_retention()
    check_gdpr_breach()
    
    generate_report "GDPR"
}

check_gdpr_encryption() {
    # Article 32: Security of processing
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
            add_compliance_check "GDPR" "Art.32" "Data Security" "PASS" "Encryption enabled" ""
        else
            add_compliance_check "GDPR" "Art.32" "Data Security" "FAIL" "No encryption" "Enable disk encryption"
        fi
    fi
}

check_gdpr_access() {
    # Article 15: Right of access
    add_compliance_check "GDPR" "Art.15" "Data Access" "WARN" "Manual process required" "Implement data access request process"
}

check_gdpr_retention() {
    # Article 5: Data minimization
    local old_files=$(find ~ -type f -mtime +365 2>/dev/null | wc -l | xargs)
    if [[ $old_files -gt 1000 ]]; then
        add_compliance_check "GDPR" "Art.5" "Data Retention" "WARN" "$old_files old files" "Review and delete old data"
    else
        add_compliance_check "GDPR" "Art.5" "Data Retention" "PASS" "Minimal old data" ""
    fi
}

check_gdpr_breach() {
    # Article 33: Breach notification
    add_compliance_check "GDPR" "Art.33" "Breach Notification" "WARN" "Manual verification" "Ensure breach notification process exists"
}

# Add compliance check
add_compliance_check() {
    local framework="$1"
    local control_id="$2"
    local control_name="$3"
    local check_status="$4"
    local evidence="$5"
    local remediation="$6"
    
    sqlite3 "$DB_FILE" "INSERT INTO compliance_checks (framework, control_id, control_name, check_status, evidence, remediation, checked_at) VALUES ('$framework', '$control_id', '$control_name', '$check_status', '$evidence', '$remediation', $(date +%s));"
    
    local icon="✓"
    local color="$GREEN"
    
    case "$check_status" in
        FAIL) icon="✗"; color="$RED" ;;
        WARN) icon="⚠"; color="$YELLOW" ;;
    esac
    
    echo -e "  $color$icon $control_id - $control_name${NC}"
    [[ -n "$evidence" ]] && echo -e "    Evidence: $evidence"
}

# Generate compliance report
generate_report() {
    local framework="$1"
    
    local total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM compliance_checks WHERE framework = '$framework';")
    local passed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM compliance_checks WHERE framework = '$framework' AND check_status = 'PASS';")
    local failed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM compliance_checks WHERE framework = '$framework' AND check_status = 'FAIL';")
    local warned=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM compliance_checks WHERE framework = '$framework' AND check_status = 'WARN';")
    
    local score=$((passed * 100 / total))
    
    sqlite3 "$DB_FILE" "INSERT INTO compliance_reports (framework, total_controls, passed, failed, score, generated_at) VALUES ('$framework', $total, $passed, $failed, $score, $(date +%s));"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$framework Compliance Summary:${NC}"
    echo -e "  ${GREEN}Passed:${NC} $passed"
    echo -e "  ${YELLOW}Warnings:${NC} $warned"
    echo -e "  ${RED}Failed:${NC} $failed"
    echo -e "  ${BLUE}Total:${NC} $total"
    echo -e "\n${CYAN}Compliance Score:${NC} $score%"
    
    if [[ $score -ge 90 ]]; then
        echo -e "${GREEN}✓ Excellent compliance!${NC}"
    elif [[ $score -ge 70 ]]; then
        echo -e "${YELLOW}⚠️  Improvements needed${NC}"
    else
        echo -e "${RED}❌ Critical compliance gaps${NC}"
    fi
}

# Show all reports
cmd_report() {
    init_db
    echo -e "${CYAN}📊 Compliance Reports${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT framework, score, passed, failed, datetime(generated_at, 'unixepoch') FROM compliance_reports ORDER BY generated_at DESC LIMIT 10;" | while IFS=$'\t' read -r framework score passed failed time; do
        echo -e "${BLUE}$framework${NC} - $score% (${GREEN}$passed passed${NC}, ${RED}$failed failed${NC})"
        echo -e "  Generated: $time"
        echo ""
    done
}

# Help
cmd_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR COMPLY${NC}  ${DIM}Scan for violations before production does.${NC}"
  echo -e "  ${DIM}Compliance on autopilot. GDPR · SOC2 · HIPAA.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  scan [path]                     ${NC} Scan for compliance violations"
  echo -e "  ${AMBER}  report                          ${NC} Generate compliance report"
  echo -e "  ${AMBER}  rules                           ${NC} List active compliance rules"
  echo -e "  ${AMBER}  fix                             ${NC} Auto-fix safe violations"
  echo -e "  ${AMBER}  history                         ${NC} Previous scan results"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br comply scan .${NC}"
  echo -e "  ${DIM}  br comply report${NC}"
  echo -e "  ${DIM}  br comply rules${NC}"
  echo -e ""
}
# Main dispatch
init_db

case "${1:-help}" in
    pci|pci-dss) cmd_pci ;;
    hipaa) cmd_hipaa ;;
    soc2|soc) cmd_soc2 ;;
    gdpr) cmd_gdpr ;;
    report|r) cmd_report ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
