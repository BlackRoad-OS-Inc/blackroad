#!/usr/bin/env zsh

# Colors
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
NC='\033[0m'

DB_FILE="$HOME/.blackroad/code-quality.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    check_type TEXT,
    files_checked INTEGER,
    issues_found INTEGER,
    score REAL,
    checked_at INTEGER
);

CREATE TABLE IF NOT EXISTS issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    check_id INTEGER,
    severity TEXT,
    file TEXT,
    line INTEGER,
    rule TEXT,
    message TEXT
);
EOF
}

cmd_lint() {
    init_db
    local files="${1:-.}"
    
    echo -e "${CYAN}🔍 Running linters...${NC}\n"
    
    local total_issues=0
    
    # JavaScript/TypeScript
    if [[ -f "package.json" ]]; then
        if command -v eslint &> /dev/null || [[ -f "node_modules/.bin/eslint" ]]; then
            echo -e "${BLUE}ESLint (JavaScript/TypeScript)${NC}"
            if [[ -f "node_modules/.bin/eslint" ]]; then
                npx eslint "$files" || true
            else
                eslint "$files" || true
            fi
            echo ""
        fi
    fi
    
    # Python
    if command -v ruff &> /dev/null; then
        echo -e "${BLUE}Ruff (Python)${NC}"
        ruff check "$files" || true
        echo ""
    elif command -v pylint &> /dev/null; then
        echo -e "${BLUE}Pylint (Python)${NC}"
        find "$files" -name "*.py" -exec pylint {} + 2>/dev/null || true
        echo ""
    fi
    
    # Go
    if [[ -f "go.mod" ]]; then
        echo -e "${BLUE}golangci-lint (Go)${NC}"
        if command -v golangci-lint &> /dev/null; then
            golangci-lint run "$files" || true
        else
            echo -e "${YELLOW}⚠️  Install: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest${NC}"
        fi
        echo ""
    fi
    
    # Rust
    if [[ -f "Cargo.toml" ]]; then
        echo -e "${BLUE}Clippy (Rust)${NC}"
        cargo clippy -- -D warnings || true
        echo ""
    fi
    
    # Shell scripts
    if command -v shellcheck &> /dev/null; then
        echo -e "${BLUE}ShellCheck (Shell)${NC}"
        find "$files" -name "*.sh" -exec shellcheck {} + 2>/dev/null || true
        echo ""
    fi
    
    echo -e "${GREEN}✓ Linting complete${NC}"
}

cmd_format() {
    init_db
    local check_only="${1}"
    
    echo -e "${CYAN}✨ Checking code formatting...${NC}\n"
    
    # JavaScript/TypeScript
    if [[ -f "package.json" ]]; then
        if command -v prettier &> /dev/null || [[ -f "node_modules/.bin/prettier" ]]; then
            echo -e "${BLUE}Prettier (JavaScript/TypeScript)${NC}"
            if [[ "$check_only" == "--check" ]]; then
                npx prettier --check . || true
            else
                npx prettier --write .
            fi
            echo ""
        fi
    fi
    
    # Python
    if command -v black &> /dev/null; then
        echo -e "${BLUE}Black (Python)${NC}"
        if [[ "$check_only" == "--check" ]]; then
            black --check . || true
        else
            black .
        fi
        echo ""
    fi
    
    # Go
    if [[ -f "go.mod" ]]; then
        echo -e "${BLUE}gofmt (Go)${NC}"
        if [[ "$check_only" == "--check" ]]; then
            gofmt -l . || true
        else
            gofmt -w .
        fi
        echo ""
    fi
    
    # Rust
    if [[ -f "Cargo.toml" ]]; then
        echo -e "${BLUE}rustfmt (Rust)${NC}"
        if [[ "$check_only" == "--check" ]]; then
            cargo fmt -- --check || true
        else
            cargo fmt
        fi
        echo ""
    fi
    
    echo -e "${GREEN}✓ Format check complete${NC}"
}

cmd_complexity() {
    init_db
    echo -e "${CYAN}📊 Analyzing code complexity...${NC}\n"
    
    # JavaScript/TypeScript
    if command -v npx &> /dev/null && [[ -f "package.json" ]]; then
        echo -e "${BLUE}JavaScript/TypeScript complexity:${NC}"
        npx complexity-report src/ 2>/dev/null || echo "Install: npm install -g complexity-report"
        echo ""
    fi
    
    # Python
    if command -v radon &> /dev/null; then
        echo -e "${BLUE}Python complexity:${NC}"
        radon cc . -a -nb
        echo ""
    fi
    
    # Go
    if [[ -f "go.mod" ]] && command -v gocyclo &> /dev/null; then
        echo -e "${BLUE}Go complexity:${NC}"
        gocyclo -over 10 .
        echo ""
    fi
    
    echo -e "${GREEN}✓ Complexity analysis complete${NC}"
}

cmd_smell() {
    init_db
    echo -e "${CYAN}👃 Detecting code smells...${NC}\n"
    
    local issues=0
    
    # Long functions (>50 lines)
    echo -e "${BLUE}Checking for long functions...${NC}"
    local long_funcs=$(grep -r "function\|def\|func" --include="*.{js,py,go}" . 2>/dev/null | wc -l)
    echo -e "Found $long_funcs function definitions"
    echo ""
    
    # Duplicated code
    echo -e "${BLUE}Checking for duplicates...${NC}"
    if command -v jscpd &> /dev/null; then
        jscpd . || true
    else
        echo -e "${YELLOW}⚠️  Install jscpd for duplicate detection: npm install -g jscpd${NC}"
    fi
    echo ""
    
    # Large files (>500 lines)
    echo -e "${BLUE}Checking for large files...${NC}"
    find . -name "*.{js,py,go,rs}" -type f 2>/dev/null | while read -r file; do
        local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        if [[ $lines -gt 500 ]]; then
            echo -e "${YELLOW}⚠${NC} $file: $lines lines"
            issues=$((issues + 1))
        fi
    done
    echo ""
    
    # TODO/FIXME comments
    echo -e "${BLUE}Checking for TODO/FIXME...${NC}"
    local todos=$(grep -r "TODO\|FIXME\|XXX\|HACK" --include="*.{js,py,go,rs,ts}" . 2>/dev/null | wc -l | tr -d ' ')
    echo -e "Found $todos TODOs/FIXMEs"
    echo ""
    
    echo -e "${GREEN}✓ Code smell detection complete${NC}"
}

cmd_score() {
    init_db
    echo -e "${CYAN}🎯 Calculating code quality score...${NC}\n"
    
    local score=100
    local deductions=""
    
    # Check for linter issues
    if [[ -f "package.json" ]] && command -v eslint &> /dev/null; then
        local eslint_errors=$(npx eslint . --format json 2>/dev/null | grep -o '"errorCount":[0-9]*' | cut -d: -f2 | awk '{s+=$1} END {print s}')
        if [[ -n "$eslint_errors" && "$eslint_errors" -gt 0 ]]; then
            score=$((score - eslint_errors / 10))
            deductions="${deductions}\n  -$((eslint_errors / 10)) for ESLint errors"
        fi
    fi
    
    # Check for TODOs
    local todos=$(grep -r "TODO\|FIXME" --include="*.{js,py,go}" . 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$todos" -gt 0 ]]; then
        local deduction=$((todos / 5))
        score=$((score - deduction))
        deductions="${deductions}\n  -$deduction for TODOs/FIXMEs"
    fi
    
    # Check test coverage (if available)
    if [[ -f "coverage/coverage-summary.json" ]]; then
        local coverage=$(grep -o '"total".*"pct":[0-9.]*' coverage/coverage-summary.json | head -1 | grep -o '[0-9.]*' | tail -1)
        if [[ -n "$coverage" ]]; then
            local coverage_int=$(echo "$coverage" | cut -d. -f1)
            if [[ $coverage_int -lt 80 ]]; then
                local deduction=$(((80 - coverage_int) / 2))
                score=$((score - deduction))
                deductions="${deductions}\n  -$deduction for low test coverage"
            fi
        fi
    fi
    
    # Ensure score doesn't go below 0
    if [[ $score -lt 0 ]]; then
        score=0
    fi
    
    echo -e "${BLUE}Code Quality Score:${NC} ${MAGENTA}$score/100${NC}"
    
    if [[ -n "$deductions" ]]; then
        echo -e "\n${YELLOW}Deductions:${NC}"
        echo -e "$deductions"
    fi
    
    echo ""
    
    if [[ $score -ge 90 ]]; then
        echo -e "${GREEN}🌟 Excellent! Keep up the great work!${NC}"
    elif [[ $score -ge 70 ]]; then
        echo -e "${CYAN}👍 Good! Some room for improvement.${NC}"
    elif [[ $score -ge 50 ]]; then
        echo -e "${YELLOW}⚠️  Fair. Consider addressing issues.${NC}"
    else
        echo -e "${RED}❌ Needs improvement. Run linters and fix issues.${NC}"
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO checks (check_type, score, checked_at) VALUES ('quality', $score, $(date +%s));"
}

cmd_report() {
    init_db
    echo -e "${CYAN}📊 Quality Check History:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT check_type, files_checked, issues_found, score, datetime(checked_at, 'unixepoch') FROM checks ORDER BY checked_at DESC LIMIT 10;" | while IFS=$'\t' read -r type files issues score time; do
        echo -e "${BLUE}$type${NC} - $time"
        if [[ -n "$score" ]]; then
            echo -e "  Score: ${MAGENTA}$score/100${NC}"
        fi
        if [[ -n "$issues" ]]; then
            echo -e "  Issues: $issues"
        fi
        echo ""
    done
}

cmd_help() {
    echo -e "  ${AMBER}${BOLD}◆ BR QUALITY${NC}  code quality checker\n"
    echo -e "  ${AMBER}br quality lint [path]${NC}      run linters"
    echo -e "  ${AMBER}br quality format [--check]${NC} format code"
    echo -e "  ${AMBER}br quality complexity${NC}       analyze complexity"
    echo -e "  ${AMBER}br quality smell${NC}             detect code smells"
    echo -e "  ${AMBER}br quality score${NC}             quality score"
    echo -e "  ${AMBER}br quality report${NC}            check history\n"
    echo -e "  ${DIM}JS: eslint prettier  ·  Python: pylint ruff black  ·  Go: golangci-lint${NC}"
}

# Main dispatch
init_db

case "${1:-help}" in
    lint|l) cmd_lint "${@:2}" ;;
    format|fmt|f) cmd_format "${@:2}" ;;
    complexity|complex|c) cmd_complexity ;;
    smell|smells|s) cmd_smell ;;
    score|grade) cmd_score ;;
    report|history) cmd_report ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
