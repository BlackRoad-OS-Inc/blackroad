#!/usr/bin/env zsh
# BR Test - Test Suite Manager  v2

# Brand palette
AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
# Compat aliases
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$VIOLET"; MAGENTA="$VIOLET"

DB_FILE="$HOME/.blackroad/test-suite.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS test_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT,
    framework TEXT,
    total_tests INTEGER,
    passed INTEGER,
    failed INTEGER,
    skipped INTEGER,
    duration REAL,
    coverage REAL,
    ran_at INTEGER
);
EOF
}

detect_framework() {
    if [[ -f "package.json" ]]; then
        if grep -q '"jest"' package.json; then
            echo "jest"
        elif grep -q '"mocha"' package.json; then
            echo "mocha"
        elif grep -q '"vitest"' package.json; then
            echo "vitest"
        else
            echo "npm"
        fi
    elif [[ -f "pytest.ini" ]] || [[ -f "setup.py" ]] || grep -q "pytest" requirements.txt 2>/dev/null; then
        echo "pytest"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "cargo"
    elif [[ -f "phpunit.xml" ]]; then
        echo "phpunit"
    else
        echo "unknown"
    fi
}

cmd_run() {
    init_db
    local pattern="${1:-}"
    
    echo -e "  ${AMBER}${BOLD}◆ BR TEST${NC}  ${DIM}detecting framework…${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    
    local framework; framework=$(detect_framework)
    local start_time; start_time=$(date +%s)
    echo -e "  ${VIOLET}framework${NC}  $framework"
    echo ""
    
    case "$framework" in
        jest)
            [[ -n "$pattern" ]] && npm test -- "$pattern" || npm test ;;
        vitest)
            [[ -n "$pattern" ]] && npx vitest run "$pattern" || npx vitest run ;;
        mocha)
            npm test ;;
        pytest)
            [[ -n "$pattern" ]] && pytest -v -k "$pattern" || pytest -v ;;
        go)
            [[ -n "$pattern" ]] && go test -v -run "$pattern" ./... || go test -v ./... ;;
        cargo)
            [[ -n "$pattern" ]] && cargo test "$pattern" || cargo test ;;
        phpunit)
            vendor/bin/phpunit ;;
        npm)
            npm test ;;
        *)
            echo -e "  ${RED}✗${NC} No test framework detected"
            echo -e "  ${DIM}Supported: Jest, Vitest, Mocha, Pytest, Go, Cargo, PHPUnit${NC}"
            exit 1 ;;
    esac
    
    local end_time; end_time=$(date +%s)
    local duration=$(( end_time - start_time ))
    
    echo -e "  ${GREEN}✓${NC} Tests completed in ${AMBER}${duration}s${NC}"
    
    sqlite3 "$DB_FILE" "INSERT INTO test_runs (project_name, framework, duration, ran_at) VALUES ('$(basename $(pwd))', '$framework', $duration, $(date +%s));"
}

cmd_coverage() {
    init_db
    echo -e "  ${AMBER}${BOLD}◆ BR TEST${NC}  ${DIM}coverage${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    local framework; framework=$(detect_framework)
    echo -e "  ${VIOLET}framework${NC}  $framework"
    echo ""
    case "$framework" in
        jest)   npm test -- --coverage ;;
        vitest) npx vitest run --coverage ;;
        pytest) pytest --cov=. --cov-report=html --cov-report=term
                echo -e "  ${DIM}→  htmlcov/index.html${NC}" ;;
        go)     go test -coverprofile=coverage.out ./...
                go tool cover -html=coverage.out -o coverage.html
                echo -e "  ${DIM}→  coverage.html${NC}" ;;
        cargo)  cargo test --no-fail-fast
                command -v cargo-tarpaulin &>/dev/null && cargo tarpaulin --out Html \
                  && echo -e "  ${DIM}→  tarpaulin-report.html${NC}" \
                  || echo -e "  ${PINK}⚠${NC}  install cargo-tarpaulin for coverage" ;;
        *)      echo -e "  ${RED}✗${NC} Coverage not supported for $framework"; exit 1 ;;
    esac
}

cmd_watch() {
    echo -e "  ${AMBER}${BOLD}◆ BR TEST${NC}  ${DIM}watch mode — Ctrl+C to stop${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    local framework; framework=$(detect_framework)
    case "$framework" in
        jest)   npm test -- --watch ;;
        vitest) npx vitest ;;
        pytest) command -v ptw &>/dev/null && ptw || pytest --looponfail ;;
        go)     command -v gotest &>/dev/null && gotest -v ./... || while true; do go test -v ./...; sleep 2; done ;;
        cargo)  cargo watch -x test ;;
        *)      echo -e "  ${RED}✗${NC} Watch not supported for $framework"; exit 1 ;;
    esac
}

cmd_benchmark() {
    echo -e "  ${AMBER}${BOLD}◆ BR TEST${NC}  ${DIM}benchmarks${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    local framework; framework=$(detect_framework)
    case "$framework" in
        go)     go test -bench=. -benchmem ./... ;;
        cargo)  cargo bench ;;
        pytest) pytest --benchmark-only ;;
        *)      echo -e "  ${PINK}⚠${NC}  benchmarks not available for $framework" ;;
    esac
}

cmd_report() {
    init_db
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR TEST${NC}  ${DIM}history${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    sqlite3 -separator $'\t' "$DB_FILE" \
      "SELECT framework, total_tests, passed, failed, duration, datetime(ran_at,'unixepoch') FROM test_runs ORDER BY ran_at DESC LIMIT 10;" \
    | while IFS=$'\t' read -r fw total pass fail dur time; do
        local icon="${GREEN}✓${NC}"; [[ -n "$fail" && "$fail" != "0" ]] && icon="${RED}✗${NC}"
        echo -e "  $icon  ${BOLD}$fw${NC}  ${DIM}$time${NC}"
        [[ -n "$total" ]] && echo -e "     ${DIM}$pass passed  $fail failed  ${dur}s${NC}" || echo -e "     ${DIM}${dur}s${NC}"
        echo ""
    done
}

cmd_stats() {
    init_db
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR TEST${NC}  ${DIM}statistics${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    local total_runs; total_runs=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM test_runs;")
    local avg_dur; avg_dur=$(sqlite3 "$DB_FILE" "SELECT AVG(duration) FROM test_runs;" | awk '{printf "%.1f", $1}')
    echo -e "  $(printf '%-16s' 'total runs')${AMBER}$total_runs${NC}"
    echo -e "  $(printf '%-16s' 'avg duration')${AMBER}${avg_dur}s${NC}"
    echo ""
    echo -e "  ${DIM}by framework:${NC}"
    sqlite3 -separator $'\t' "$DB_FILE" \
      "SELECT framework, COUNT(*) FROM test_runs GROUP BY framework ORDER BY COUNT(*) DESC;" \
    | while IFS=$'\t' read -r fw cnt; do
        echo -e "  ${VIOLET}$fw${NC}  $cnt"
    done
    echo ""
}

cmd_help() {
    echo ""
    echo -e "  ${AMBER}${BOLD}BR TEST${NC}  ${DIM}auto-detect & run tests${NC}"
    echo ""
    echo -e "  ${BOLD}br test run [pattern]${NC}    ${DIM}run tests (filter optional)${NC}"
    echo -e "  ${BOLD}br test coverage${NC}         ${DIM}run with coverage report${NC}"
    echo -e "  ${BOLD}br test watch${NC}            ${DIM}watch mode — rerun on change${NC}"
    echo -e "  ${BOLD}br test benchmark${NC}        ${DIM}run benchmarks${NC}"
    echo -e "  ${BOLD}br test report${NC}           ${DIM}test history${NC}"
    echo -e "  ${BOLD}br test stats${NC}            ${DIM}statistics${NC}"
    echo ""
    echo -e "  ${DIM}Frameworks: Jest · Vitest · Mocha · Pytest · Go · Cargo · PHPUnit${NC}"
    echo ""
}

# Main dispatch
init_db

case "${1:-help}" in
    run|r) cmd_run "${@:2}" ;;
    coverage|cov|c) cmd_coverage ;;
    watch|w) cmd_watch ;;
    benchmark|bench|b) cmd_benchmark ;;
    report|history) cmd_report ;;
    stats) cmd_stats ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "  ${RED}✗${NC} Unknown: $1"
        cmd_help; exit 1 ;;
esac
