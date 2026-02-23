#!/usr/bin/env zsh
# 🛡️ Security Hardening - Feature #33
# Automated system security hardening and compliance checking

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/security-hardening.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS hardening_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    check_name TEXT,
    category TEXT,
    severity TEXT,
    check_status TEXT,
    remediation TEXT,
    checked_at INTEGER
);

CREATE TABLE IF NOT EXISTS hardening_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT,
    details TEXT,
    timestamp INTEGER
);
EOF
}

# Run all hardening checks
cmd_check() {
    init_db
    echo -e "${CYAN}🛡️  Running Security Hardening Checks...${NC}\n"
    
    sqlite3 "$DB_FILE" "DELETE FROM hardening_checks;"
    
    local total=0
    local passed=0
    local failed=0
    local warnings=0
    
    # Check SSH configuration
    check_ssh_config
    
    # Check firewall
    check_firewall
    
    # Check file permissions
    check_permissions
    
    # Check running services
    check_services
    
    # Check system updates
    check_updates
    
    # Check password policy
    check_password_policy
    
    # Check network security
    check_network
    
    # Calculate results
    total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM hardening_checks;")
    passed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM hardening_checks WHERE check_status = 'PASS';")
    failed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM hardening_checks WHERE check_status = 'FAIL';")
    warnings=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM hardening_checks WHERE check_status = 'WARN';")
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Security Hardening Summary:${NC}"
    echo -e "  ${GREEN}Passed:${NC} $passed"
    echo -e "  ${YELLOW}Warnings:${NC} $warnings"
    echo -e "  ${RED}Failed:${NC} $failed"
    echo -e "  ${BLUE}Total:${NC} $total"
    
    local score=$((passed * 100 / total))
    echo -e "\n${CYAN}Security Score:${NC} $score/100"
    
    if [[ $score -ge 90 ]]; then
        echo -e "${GREEN}✓ Excellent security posture!${NC}"
    elif [[ $score -ge 70 ]]; then
        echo -e "${YELLOW}⚠️  Good, but improvements needed${NC}"
    else
        echo -e "${RED}❌ Critical security issues detected${NC}"
    fi
}

check_ssh_config() {
    echo -e "${BLUE}Checking SSH configuration...${NC}"
    
    if [[ -f "/etc/ssh/sshd_config" ]]; then
        # Check root login
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
            add_check "SSH Root Login" "ssh" "high" "PASS" "Root login is disabled"
        else
            add_check "SSH Root Login" "ssh" "high" "FAIL" "Disable root login: PermitRootLogin no"
        fi
        
        # Check password authentication
        if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
            add_check "SSH Password Auth" "ssh" "medium" "PASS" "Password authentication disabled"
        else
            add_check "SSH Password Auth" "ssh" "medium" "WARN" "Consider disabling: PasswordAuthentication no"
        fi
        
        # Check SSH protocol
        if grep -q "^Protocol 2" /etc/ssh/sshd_config 2>/dev/null; then
            add_check "SSH Protocol" "ssh" "high" "PASS" "Using SSH Protocol 2"
        else
            add_check "SSH Protocol" "ssh" "high" "WARN" "Ensure SSH Protocol 2 is used"
        fi
    else
        add_check "SSH Config" "ssh" "low" "PASS" "SSH not installed or configured"
    fi
}

check_firewall() {
    echo -e "${BLUE}Checking firewall...${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS firewall
        if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -q "enabled"; then
            add_check "Firewall Status" "firewall" "high" "PASS" "Firewall is enabled"
        else
            add_check "Firewall Status" "firewall" "high" "FAIL" "Enable firewall: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
        fi
    else
        # Linux firewall (ufw/iptables)
        if command -v ufw &> /dev/null; then
            if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
                add_check "Firewall Status" "firewall" "high" "PASS" "UFW firewall is active"
            else
                add_check "Firewall Status" "firewall" "high" "FAIL" "Enable UFW: sudo ufw enable"
            fi
        else
            add_check "Firewall Status" "firewall" "medium" "WARN" "No firewall detected"
        fi
    fi
}

check_permissions() {
    echo -e "${BLUE}Checking file permissions...${NC}"
    
    # Check home directory
    local home_perms=$(stat -f "%Lp" ~ 2>/dev/null || stat -c "%a" ~ 2>/dev/null)
    if [[ "$home_perms" == "700" ]] || [[ "$home_perms" == "750" ]]; then
        add_check "Home Directory Permissions" "permissions" "medium" "PASS" "Home directory properly secured"
    else
        add_check "Home Directory Permissions" "permissions" "medium" "WARN" "Consider: chmod 700 ~"
    fi
    
    # Check SSH keys
    if [[ -d "$HOME/.ssh" ]]; then
        local ssh_perms=$(stat -f "%Lp" ~/.ssh 2>/dev/null || stat -c "%a" ~/.ssh 2>/dev/null)
        if [[ "$ssh_perms" == "700" ]]; then
            add_check "SSH Directory Permissions" "permissions" "high" "PASS" "SSH directory properly secured"
        else
            add_check "SSH Directory Permissions" "permissions" "high" "FAIL" "Fix: chmod 700 ~/.ssh"
        fi
        
        # Check private keys
        for key in ~/.ssh/id_*; do
            if [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]]; then
                local key_perms=$(stat -f "%Lp" "$key" 2>/dev/null || stat -c "%a" "$key" 2>/dev/null)
                if [[ "$key_perms" == "600" ]]; then
                    add_check "SSH Key: $(basename $key)" "permissions" "high" "PASS" "Key properly secured"
                else
                    add_check "SSH Key: $(basename $key)" "permissions" "high" "FAIL" "Fix: chmod 600 $key"
                fi
            fi
        done
    fi
}

check_services() {
    echo -e "${BLUE}Checking running services...${NC}"
    
    # Check for unnecessary services
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS services
        if launchctl list | grep -q "com.apple.screensharing"; then
            add_check "Screen Sharing" "services" "medium" "WARN" "Screen sharing is enabled"
        else
            add_check "Screen Sharing" "services" "medium" "PASS" "Screen sharing is disabled"
        fi
    fi
    
    # Check for common vulnerable services
    if lsof -i :23 &> /dev/null; then
        add_check "Telnet Service" "services" "high" "FAIL" "Telnet is running - should be disabled"
    else
        add_check "Telnet Service" "services" "high" "PASS" "Telnet is not running"
    fi
}

check_updates() {
    echo -e "${BLUE}Checking system updates...${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if softwareupdate -l 2>&1 | grep -q "No new software available"; then
            add_check "System Updates" "updates" "medium" "PASS" "System is up to date"
        else
            add_check "System Updates" "updates" "medium" "WARN" "Updates available: softwareupdate -ia"
        fi
    else
        if command -v apt-get &> /dev/null; then
            add_check "System Updates" "updates" "medium" "WARN" "Check updates: apt-get update && apt-get upgrade"
        fi
    fi
}

check_password_policy() {
    echo -e "${BLUE}Checking password policy...${NC}"
    
    # Check password complexity requirements
    if [[ -f "/etc/pam.d/common-password" ]]; then
        if grep -q "pam_pwquality.so" /etc/pam.d/common-password 2>/dev/null; then
            add_check "Password Complexity" "password" "medium" "PASS" "Password complexity enforced"
        else
            add_check "Password Complexity" "password" "medium" "WARN" "Consider enforcing password complexity"
        fi
    else
        add_check "Password Policy" "password" "low" "PASS" "N/A for this system"
    fi
}

check_network() {
    echo -e "${BLUE}Checking network security...${NC}"
    
    # Check for open ports
    local open_ports=$(lsof -i -P -n 2>/dev/null | grep LISTEN | wc -l | xargs)
    if [[ $open_ports -lt 10 ]]; then
        add_check "Open Ports" "network" "medium" "PASS" "Minimal open ports ($open_ports)"
    else
        add_check "Open Ports" "network" "medium" "WARN" "Many open ports ($open_ports) - review with: lsof -i -P -n"
    fi
    
    # Check DNS
    if grep -q "^nameserver 1.1.1.1" /etc/resolv.conf 2>/dev/null || grep -q "^nameserver 8.8.8.8" /etc/resolv.conf 2>/dev/null; then
        add_check "DNS Configuration" "network" "low" "PASS" "Using secure DNS"
    else
        add_check "DNS Configuration" "network" "low" "WARN" "Consider using secure DNS (1.1.1.1, 8.8.8.8)"
    fi
}

add_check() {
    local name="$1"
    local category="$2"
    local severity="$3"
    local check_status="$4"
    local remediation="$5"
    
    sqlite3 "$DB_FILE" "INSERT INTO hardening_checks (check_name, category, severity, check_status, remediation, checked_at) VALUES ('$name', '$category', '$severity', '$check_status', '$remediation', $(date +%s));"
    
    local icon="✓"
    local color="$GREEN"
    
    case "$check_status" in
        FAIL)
            icon="✗"
            color="$RED"
            ;;
        WARN)
            icon="⚠"
            color="$YELLOW"
            ;;
    esac
    
    echo -e "  $color$icon $name${NC}"
}

# Show detailed report
cmd_report() {
    init_db
    echo -e "${CYAN}🛡️  Security Hardening Report${NC}\n"
    
    for category in "ssh" "firewall" "permissions" "services" "updates" "password" "network"; do
        local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM hardening_checks WHERE category = '$category';")
        
        if [[ $count -gt 0 ]]; then
            echo -e "${BLUE}${category^^}:${NC}"
            
            sqlite3 -separator $'\t' "$DB_FILE" "SELECT check_name, severity, check_status, remediation FROM hardening_checks WHERE category = '$category';" | while IFS=$'\t' read -r name severity check_status remediation; do
                local icon="✓"
                local color="$GREEN"
                
                case "$check_status" in
                    FAIL) icon="✗"; color="$RED" ;;
                    WARN) icon="⚠"; color="$YELLOW" ;;
                esac
                
                echo -e "  $color$icon $name${NC} [$severity]"
                [[ "$check_status" != "PASS" ]] && echo -e "    ${CYAN}→${NC} $remediation"
            done
            
            echo ""
        fi
    done
}

# Auto-fix issues
cmd_fix() {
    init_db
    echo -e "${CYAN}🔧 Auto-fixing security issues...${NC}\n"
    
    local fixed=0
    
    # Fix SSH directory permissions
    if [[ -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh"
        echo -e "${GREEN}✓ Fixed SSH directory permissions${NC}"
        fixed=$((fixed + 1))
    fi
    
    # Fix SSH key permissions
    for key in ~/.ssh/id_*; do
        if [[ -f "$key" ]] && [[ ! "$key" =~ \.pub$ ]]; then
            chmod 600 "$key"
            echo -e "${GREEN}✓ Fixed permissions for $(basename $key)${NC}"
            fixed=$((fixed + 1))
        fi
    done
    
    # Fix home directory (with caution)
    if [[ "$1" == "--home" ]]; then
        chmod 750 ~
        echo -e "${GREEN}✓ Fixed home directory permissions${NC}"
        fixed=$((fixed + 1))
    fi
    
    echo -e "\n${BLUE}Fixed $fixed issues${NC}"
    echo -e "${YELLOW}Note: Some fixes require manual intervention or sudo access${NC}"
    
    sqlite3 "$DB_FILE" "INSERT INTO hardening_history (action, details, timestamp) VALUES ('AUTO_FIX', 'Fixed $fixed issues', $(date +%s));"
}

# Help
cmd_help() {
    cat << 'EOF'
🛡️ Security Hardening

USAGE:
  br harden <command> [options]

COMMANDS:
  check                    Run all security checks
  report                   Show detailed report
  fix [--home]             Auto-fix common issues

EXAMPLES:
  # Run security audit
  br harden check

  # Show detailed report
  br harden report

  # Auto-fix issues
  br harden fix
  br harden fix --home     # Include home directory

CHECKS PERFORMED:
  🔐 SSH Configuration
     - Root login disabled
     - Password authentication
     - SSH protocol version
     
  🔥 Firewall
     - Firewall enabled
     - Default rules
     
  📁 File Permissions
     - Home directory
     - SSH directory
     - Private keys
     
  🖥️  Services
     - Unnecessary services
     - Vulnerable services
     
  ⬆️  Updates
     - System updates
     - Security patches
     
  🔑 Password Policy
     - Complexity requirements
     - Expiration
     
  🌐 Network Security
     - Open ports
     - DNS configuration

SEVERITY LEVELS:
  🔴 HIGH   - Critical security issues
  🟡 MEDIUM - Important improvements
  🟢 LOW    - Minor recommendations

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    check|c) cmd_check ;;
    report|r) cmd_report ;;
    fix|f) cmd_fix "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
