#!/bin/zsh
# BR pr-check — Pull Request checks & review helper
# Analyzes diffs, checks conventions, surfaces issues before merge

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

DB="$HOME/.blackroad/pr-check.db"

init_db() {
    mkdir -p "$(dirname "$DB")"
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    branch TEXT,
    base TEXT DEFAULT 'main',
    result TEXT,
    score INTEGER,
    findings TEXT,
    ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    pattern TEXT,
    severity TEXT DEFAULT 'warn',
    message TEXT,
    enabled INTEGER DEFAULT 1
);
SQL
    # Seed default rules if empty
    local count=$(sqlite3 "$DB" "SELECT COUNT(*) FROM rules;")
    if [[ "$count" -eq 0 ]]; then
        sqlite3 "$DB" <<'SQL'
INSERT INTO rules (name, pattern, severity, message) VALUES
    ('no-console-log',   'console\.log\(',    'warn',  'Remove console.log before merging'),
    ('no-debugger',      'debugger;',         'error', 'Remove debugger statement'),
    ('no-todo-fixme',    'TODO|FIXME|HACK',   'warn',  'Unresolved TODO/FIXME comment'),
    ('no-hardcoded-key', 'api_key|apikey|API_KEY|secret.*=.*["\x27][a-zA-Z0-9]{20,}', 'error', 'Possible hardcoded secret'),
    ('no-password-plain','password.*=.*["\x27]', 'error', 'Possible plaintext password'),
    ('large-file',       '',                  'warn',  'File over 500 lines'),
    ('missing-tests',    '',                  'info',  'No test file for changed code');
SQL
    fi
}

run_rule_check() {
    local file="$1"
    local findings=()

    # Check rule patterns against file
    while IFS='|' read -r rname pattern severity msg; do
        [[ -z "$pattern" ]] && continue
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            local lines=$(grep -nE "$pattern" "$file" 2>/dev/null | head -3 | tr '\n' ';')
            findings+=("${severity}|${rname}|${msg}|${lines}")
        fi
    done < <(sqlite3 "$DB" "SELECT name, pattern, severity, message FROM rules WHERE enabled=1 AND pattern != '';" 2>/dev/null)

    echo "${findings[@]}"
}

print_finding() {
    local severity="$1"
    local rule="$2"
    local msg="$3"
    local location="$4"

    local icon="●" color="$YELLOW"
    case "$severity" in
        error) icon="✗"; color="$RED" ;;
        warn)  icon="⚠"; color="$YELLOW" ;;
        info)  icon="ℹ"; color="$CYAN" ;;
    esac
    echo -e "    ${color}${icon}${NC} ${BOLD}${rule}${NC}: $msg"
    [[ -n "$location" ]] && echo -e "      ${CYAN}→ ${location%;}${NC}"
}

cmd_check() {
    local base="${1:-main}"
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ -z "$branch" ]] && echo -e "${RED}✗ Not a git repo${NC}" && return 1

    echo -e "${BOLD}${BLUE}🔍 PR Check${NC}: ${CYAN}$branch${NC} → ${CYAN}$base${NC}\n"

    # Get changed files
    local changed_files
    changed_files=$(git diff --name-only "$base"..."$branch" 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null)
    local files_count=$(echo "$changed_files" | grep -c '.' || echo 0)

    echo -e "  ${BOLD}Changed files:${NC} $files_count"
    echo "$changed_files" | while read -r f; do
        [[ -z "$f" ]] && continue
        echo -e "    ${CYAN}+${NC} $f"
    done
    echo ""

    # Diff stats
    local stats
    stats=$(git diff --stat "$base"..."$branch" 2>/dev/null | tail -1)
    [[ -n "$stats" ]] && echo -e "  ${BOLD}Diff stats:${NC} $stats\n"

    # Run checks
    local total_errors=0 total_warns=0 total_info=0
    local all_findings=""

    echo -e "  ${BOLD}Checks:${NC}"
    echo "$changed_files" | while read -r file; do
        [[ -z "$file" || ! -f "$file" ]] && continue

        local file_findings=()
        # Line count check
        local lc=$(wc -l < "$file" 2>/dev/null || echo 0)
        [[ $lc -gt 500 ]] && file_findings+=("warn|large-file|File has $lc lines (>500)|line $lc")

        # Pattern checks
        while IFS='|' read -r rname pattern severity msg; do
            [[ -z "$pattern" ]] && continue
            if grep -qE "$pattern" "$file" 2>/dev/null; then
                local lines=$(grep -nE "$pattern" "$file" 2>/dev/null | head -2 | awk -F: '{print "L"$1}' | tr '\n' ',' | sed 's/,$//')
                file_findings+=("${severity}|${rname}|${msg}|$lines")
            fi
        done < <(sqlite3 "$DB" "SELECT name, pattern, severity, message FROM rules WHERE enabled=1 AND pattern != '';" 2>/dev/null)

        if [[ ${#file_findings[@]} -gt 0 ]]; then
            echo -e "\n  ${BOLD}$file${NC}"
            for f in "${file_findings[@]}"; do
                IFS='|' read -r sev rname msg loc <<< "$f"
                print_finding "$sev" "$rname" "$msg" "$loc"
                case "$sev" in
                    error) ((total_errors++)) ;;
                    warn)  ((total_warns++)) ;;
                    info)  ((total_info++)) ;;
                esac
            done
        fi
    done 2>/dev/null

    echo ""

    # Commit message check
    local last_commit_msg
    last_commit_msg=$(git log --oneline -1 2>/dev/null | cut -d' ' -f2-)
    echo -e "  ${BOLD}Last commit:${NC} $last_commit_msg"
    if echo "$last_commit_msg" | grep -qE '^(feat|fix|chore|docs|test|refactor|perf|style|ci)\(?'; then
        echo -e "    ${GREEN}✓${NC} Conventional commit format"
    else
        echo -e "    ${YELLOW}⚠${NC} Not conventional commit format (feat:/fix:/chore: etc.)"
    fi

    # Branch name check
    if echo "$branch" | grep -qE '^(feat|fix|chore|docs|test|hotfix)/'; then
        echo -e "    ${GREEN}✓${NC} Branch name follows convention"
    else
        echo -e "    ${YELLOW}⚠${NC} Branch name: consider feat/fix/chore/ prefix"
    fi

    echo ""

    # Score
    local score=100
    ((score -= total_errors * 20))
    ((score -= total_warns * 5))
    [[ $score -lt 0 ]] && score=0

    local grade_color="$GREEN"
    [[ $score -lt 80 ]] && grade_color="$YELLOW"
    [[ $score -lt 60 ]] && grade_color="$RED"

    echo -e "  ${BOLD}Score: ${grade_color}${score}/100${NC}"
    echo -e "  Errors: ${RED}${total_errors}${NC}  Warnings: ${YELLOW}${total_warns}${NC}  Info: ${CYAN}${total_info}${NC}"
    echo ""

    if [[ $total_errors -eq 0 ]]; then
        echo -e "  ${GREEN}✓ Ready to merge${NC}"
    else
        echo -e "  ${RED}✗ Fix $total_errors error(s) before merging${NC}"
    fi

    # Save result
    sqlite3 "$DB" "INSERT INTO checks (branch, base, result, score, findings) VALUES ('$branch', '$base', '$([ $total_errors -eq 0 ] && echo pass || echo fail)', $score, '${total_errors}e ${total_warns}w ${total_info}i');" 2>/dev/null
}

cmd_diff() {
    local base="${1:-main}"
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    echo -e "${BOLD}${BLUE}📄 Diff Summary${NC}: ${CYAN}$branch${NC} → ${CYAN}$base${NC}\n"
    git diff --stat "$base"..."$branch" 2>/dev/null || git diff --stat HEAD~1 2>/dev/null
}

cmd_commits() {
    local base="${1:-main}"
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    echo -e "${BOLD}${BLUE}📝 Commits${NC}: ${CYAN}$branch${NC} → ${CYAN}$base${NC}\n"
    git log --oneline --no-merges "$base"..."$branch" 2>/dev/null || git log --oneline -10 2>/dev/null
}

cmd_rules() {
    echo -e "${BOLD}${BLUE}📋 PR Check Rules${NC}\n"
    printf "  %-25s %-8s %s\n" "Name" "Severity" "Message"
    echo "  ──────────────────────────────────────────────────"
    sqlite3 "$DB" "SELECT name, severity, message, enabled FROM rules;" 2>/dev/null \
        | while IFS='|' read -r name sev msg enabled; do
            local color="$YELLOW" icon="○"
            [[ "$sev" == "error" ]] && color="$RED"
            [[ "$sev" == "info" ]]  && color="$CYAN"
            [[ "$enabled" == "0" ]] && icon="—" && color="$NC"
            printf "  ${color}${icon}${NC} %-23s ${color}%-8s${NC} %s\n" "$name" "$sev" "$msg"
        done
    echo ""
    echo -e "  Enable/disable: ${CYAN}br pr-check rule enable <name>${NC}"
}

cmd_rule_toggle() {
    local action="$1" name="$2"
    local val=1; [[ "$action" == "disable" ]] && val=0
    sqlite3 "$DB" "UPDATE rules SET enabled=$val WHERE name='$name';"
    echo -e "${GREEN}✓${NC} Rule '${BOLD}$name${NC}' ${action}d"
}

cmd_history() {
    echo -e "${BOLD}${BLUE}📜 PR Check History${NC}\n"
    printf "  %-8s %-25s %-8s %-6s %s\n" "Score" "Branch" "Result" "Base" "Date"
    echo "  ─────────────────────────────────────────────────"
    sqlite3 "$DB" "SELECT score, branch, result, base, ts FROM checks ORDER BY ts DESC LIMIT 20;" 2>/dev/null \
        | while IFS='|' read -r score branch result base ts; do
            local color="$GREEN"; [[ "$result" == "fail" ]] && color="$RED"
            printf "  ${color}%-8s${NC} %-25s ${color}%-8s${NC} %-6s %s\n" \
                "$score" "${branch:0:24}" "$result" "$base" "$ts"
        done
}

show_help() {
    echo -e "${BOLD}${BLUE}BR pr-check${NC} — Pull request analysis\n"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}br pr-check [base]${NC}                — Run all checks (default base: main)"
    echo -e "  ${CYAN}br pr-check diff [base]${NC}           — Show diff stats"
    echo -e "  ${CYAN}br pr-check commits [base]${NC}        — List commits in PR"
    echo -e "  ${CYAN}br pr-check rules${NC}                 — List all rules"
    echo -e "  ${CYAN}br pr-check rule enable <name>${NC}    — Enable a rule"
    echo -e "  ${CYAN}br pr-check rule disable <name>${NC}   — Disable a rule"
    echo -e "  ${CYAN}br pr-check history${NC}               — Past check results\n"
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  br pr-check                    # Check against main"
    echo -e "  br pr-check develop            # Check against develop"
    echo -e "  br pr-check diff main"
}

init_db
case "${1:-check}" in
    check|run|''|main|master|develop|dev) cmd_check "${1:-main}" ;;
    diff|stat|stats) cmd_diff "${2:-main}" ;;
    commits|log) cmd_commits "${2:-main}" ;;
    rules|list-rules) cmd_rules ;;
    rule) cmd_rule_toggle "$2" "$3" ;;
    history|hist) cmd_history ;;
    help|--help|-h) show_help ;;
    *) cmd_check "$1" ;;
esac
