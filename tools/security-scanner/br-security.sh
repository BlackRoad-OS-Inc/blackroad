#!/usr/bin/env zsh

# Colors
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
NC='\033[0m'

DB_FILE="$HOME/.blackroad/security-scanner.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS scans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_type TEXT,
    issues_found INTEGER,
    critical INTEGER,
    high INTEGER,
    medium INTEGER,
    low INTEGER,
    scanned_at INTEGER
);

CREATE TABLE IF NOT EXISTS issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scan_id INTEGER,
    severity TEXT,
    type TEXT,
    file TEXT,
    line INTEGER,
    description TEXT,
    found_at INTEGER
);
EOF
}

cmd_secrets() {
    init_db
    echo -e "${CYAN}🔐 Scanning for secrets and API keys...${NC}\n"
    
    local issues=0
    
    # Patterns for common secrets
    local patterns=(
        "api[_-]?key"
        "apikey"
        "password"
        "passwd"
        "secret"
        "token"
        "private[_-]?key"
        "aws[_-]?access"
        "aws[_-]?secret"
        "stripe"
        "paypal"
        "bearer"
    )
    
    for pattern in "${patterns[@]}"; do
        if command -v rg &> /dev/null; then
            local results=$(rg -i "$pattern" --ignore-case -g "!*.{md,txt,log}" -g "!node_modules" -g "!.git" . 2>/dev/null)
        else
            local results=$(grep -r -i "$pattern" --exclude-dir={node_modules,.git,dist,build} --exclude="*.{md,txt,log}" . 2>/dev/null)
        fi
        
        if [[ -n "$results" ]]; then
            echo -e "${YELLOW}⚠️  Found potential secret: $pattern${NC}"
            echo "$results" | head -5
            echo ""
            issues=$((issues + 1))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✓ No secrets detected${NC}"
    else
        echo -e "\n${RED}⚠️  Found $issues potential secret(s)${NC}"
        echo -e "${YELLOW}Review and remove any exposed credentials${NC}"
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, issues_found, high, scanned_at) VALUES ('secrets', $issues, $issues, $(date +%s));"
}

cmd_dependencies() {
    init_db
    echo -e "${CYAN}📦 Scanning dependencies for vulnerabilities...${NC}\n"
    
    local issues=0
    
    if [[ -f "package.json" ]]; then
        echo -e "${BLUE}Checking npm packages...${NC}"
        if command -v npm &> /dev/null; then
            npm audit --json > /tmp/npm-audit.json 2>/dev/null
            
            if [[ -f /tmp/npm-audit.json ]]; then
                local vulns=$(cat /tmp/npm-audit.json | grep -o '"vulnerabilities":{[^}]*}' | grep -o '"total":[0-9]*' | cut -d: -f2)
                if [[ -n "$vulns" && "$vulns" -gt 0 ]]; then
                    issues=$vulns
                    npm audit
                fi
                rm /tmp/npm-audit.json
            fi
        fi
    fi
    
    if [[ -f "requirements.txt" ]] || [[ -f "Pipfile" ]]; then
        echo -e "${BLUE}Checking Python packages...${NC}"
        if command -v safety &> /dev/null; then
            safety check
        else
            echo -e "${YELLOW}⚠️  Install safety: pip install safety${NC}"
        fi
    fi
    
    if [[ -f "Cargo.toml" ]]; then
        echo -e "${BLUE}Checking Rust packages...${NC}"
        if command -v cargo-audit &> /dev/null; then
            cargo audit
        else
            echo -e "${YELLOW}⚠️  Install cargo-audit: cargo install cargo-audit${NC}"
        fi
    fi
    
    if [[ -f "go.mod" ]]; then
        echo -e "${BLUE}Checking Go modules...${NC}"
        if command -v govulncheck &> /dev/null; then
            govulncheck ./...
        else
            echo -e "${YELLOW}⚠️  Install govulncheck: go install golang.org/x/vuln/cmd/govulncheck@latest${NC}"
        fi
    fi
    
    if [[ $issues -eq 0 ]]; then
        echo -e "\n${GREEN}✓ No known vulnerabilities${NC}"
    else
        echo -e "\n${YELLOW}⚠️  Found $issues vulnerabilities${NC}"
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, issues_found, scanned_at) VALUES ('dependencies', $issues, $(date +%s));"
}

cmd_code() {
    init_db
    echo -e "${CYAN}🔍 Scanning code for security issues...${NC}\n"
    
    local issues=0
    
    # Check for common security issues
    echo -e "${BLUE}Checking for insecure patterns...${NC}\n"
    
    # SQL injection patterns
    if grep -r "execute.*input\|query.*params" --include="*.{js,py,php}" . 2>/dev/null | grep -v "parameterized\|prepared" > /dev/null; then
        echo -e "${YELLOW}⚠️  Potential SQL injection vulnerability${NC}"
        issues=$((issues + 1))
    fi
    
    # Eval usage
    if grep -r "eval(" --include="*.{js,py,php}" . 2>/dev/null > /dev/null; then
        echo -e "${YELLOW}⚠️  eval() usage detected (dangerous)${NC}"
        grep -r "eval(" --include="*.{js,py,php}" . 2>/dev/null | head -3
        issues=$((issues + 1))
        echo ""
    fi
    
    # Hardcoded credentials in code
    if grep -r "password.*=.*['\"]" --include="*.{js,py,go,rs}" . 2>/dev/null > /dev/null; then
        echo -e "${YELLOW}⚠️  Hardcoded passwords detected${NC}"
        issues=$((issues + 1))
    fi
    
    # Insecure random
    if grep -r "Math.random()" --include="*.js" . 2>/dev/null > /dev/null; then
        echo -e "${YELLOW}⚠️  Math.random() is not cryptographically secure${NC}"
        issues=$((issues + 1))
    fi
    
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✓ No obvious security issues detected${NC}"
    else
        echo -e "\n${YELLOW}⚠️  Found $issues potential issue(s)${NC}"
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO scans (scan_type, issues_found, medium, scanned_at) VALUES ('code', $issues, $issues, $(date +%s));"
}

cmd_licenses() {
    init_db
    echo -e "${CYAN}📜 Checking licenses...${NC}\n"
    
    if [[ -f "package.json" ]]; then
        echo -e "${BLUE}JavaScript packages:${NC}"
        if command -v npx &> /dev/null; then
            npx license-checker --summary 2>/dev/null || echo "Install license-checker: npm install -g license-checker"
        fi
    fi
    
    if [[ -f "requirements.txt" ]]; then
        echo -e "${BLUE}Python packages:${NC}"
        if command -v pip-licenses &> /dev/null; then
            pip-licenses
        else
            echo -e "${YELLOW}⚠️  Install pip-licenses: pip install pip-licenses${NC}"
        fi
    fi
    
    if [[ -f "Cargo.toml" ]]; then
        echo -e "${BLUE}Rust packages:${NC}"
        if command -v cargo-license &> /dev/null; then
            cargo license
        else
            echo -e "${YELLOW}⚠️  Install cargo-license: cargo install cargo-license${NC}"
        fi
    fi
}

cmd_scan_all() {
    echo -e "${CYAN}🔒 Running full security scan...${NC}\n"
    
    cmd_secrets
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    cmd_dependencies
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    cmd_code
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${GREEN}✓ Full scan complete${NC}"
}

cmd_report() {
    init_db
    echo -e "${CYAN}📊 Security Scan History:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT scan_type, issues_found, datetime(scanned_at, 'unixepoch') FROM scans ORDER BY scanned_at DESC LIMIT 15;" | while IFS=$'\t' read -r type issues time; do
        if [[ "$issues" -eq 0 ]]; then
            echo -e "${GREEN}✓${NC} $type - $time - No issues"
        else
            echo -e "${YELLOW}⚠${NC} $type - $time - $issues issues"
        fi
    done
}

cmd_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR SECURITY${NC}  ${DIM}Vulnerability scanning that never sleeps.${NC}"
  echo -e "  ${DIM}Know your risk. Patch before they find it.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  scan [path]                     ${NC} Full security scan"
  echo -e "  ${AMBER}  secrets                         ${NC} Scan for exposed secrets"
  echo -e "  ${AMBER}  deps                            ${NC} Dependency vulnerability check"
  echo -e "  ${AMBER}  ports                           ${NC} Open port scan"
  echo -e "  ${AMBER}  report                          ${NC} Security report"
  echo -e "  ${AMBER}  watch                           ${NC} Continuous security monitoring"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br security scan .${NC}"
  echo -e "  ${DIM}  br security secrets${NC}"
  echo -e "  ${DIM}  br security ports${NC}"
  echo -e "  ${DIM}  br security report${NC}"
  echo -e ""
}
# Main dispatch
init_db

case "${1:-help}" in
    secrets|secret|keys) cmd_secrets ;;
    dependencies|deps|vuln) cmd_dependencies ;;
    code|scan) cmd_code ;;
    licenses|license) cmd_licenses ;;
    all|full) cmd_scan_all ;;
    report|history) cmd_report ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
