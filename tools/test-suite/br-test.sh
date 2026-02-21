#!/usr/bin/env zsh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

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
    
    echo -e "${CYAN}🧪 Detecting test framework...${NC}\n"
    
    local framework=$(detect_framework)
    local start_time=$(date +%s)
    
    case "$framework" in
        jest)
            echo -e "${BLUE}Framework:${NC} Jest"
            if [[ -n "$pattern" ]]; then
                npm test -- "$pattern"
            else
                npm test
            fi
            ;;
        vitest)
            echo -e "${BLUE}Framework:${NC} Vitest"
            if [[ -n "$pattern" ]]; then
                npx vitest run "$pattern"
            else
                npx vitest run
            fi
            ;;
        mocha)
            echo -e "${BLUE}Framework:${NC} Mocha"
            npm test
            ;;
        pytest)
            echo -e "${BLUE}Framework:${NC} Pytest"
            if [[ -n "$pattern" ]]; then
                pytest -v -k "$pattern"
            else
                pytest -v
            fi
            ;;
        go)
            echo -e "${BLUE}Framework:${NC} Go Test"
            if [[ -n "$pattern" ]]; then
                go test -v -run "$pattern" ./...
            else
                go test -v ./...
            fi
            ;;
        cargo)
            echo -e "${BLUE}Framework:${NC} Cargo Test"
            if [[ -n "$pattern" ]]; then
                cargo test "$pattern"
            else
                cargo test
            fi
            ;;
        phpunit)
            echo -e "${BLUE}Framework:${NC} PHPUnit"
            vendor/bin/phpunit
            ;;
        npm)
            echo -e "${BLUE}Framework:${NC} npm test"
            npm test
            ;;
        *)
            echo -e "${RED}❌ No test framework detected${NC}"
            echo "Supported: Jest, Vitest, Mocha, Pytest, Go, Cargo, PHPUnit"
            exit 1
            ;;
    esac
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo -e "\n${GREEN}✓ Tests completed in ${duration}s${NC}"
    
    sqlite3 "$DB_FILE" "INSERT INTO test_runs (project_name, framework, duration, ran_at) VALUES ('$(basename $(pwd))', '$framework', $duration, $(date +%s));"
}

cmd_coverage() {
    init_db
    echo -e "${CYAN}📊 Running tests with coverage...${NC}\n"
    
    local framework=$(detect_framework)
    
    case "$framework" in
        jest)
            npm test -- --coverage
            ;;
        vitest)
            npx vitest run --coverage
            ;;
        pytest)
            pytest --cov=. --cov-report=html --cov-report=term
            echo -e "\n${BLUE}Coverage report:${NC} htmlcov/index.html"
            ;;
        go)
            go test -coverprofile=coverage.out ./...
            go tool cover -html=coverage.out -o coverage.html
            echo -e "\n${BLUE}Coverage report:${NC} coverage.html"
            ;;
        cargo)
            cargo test --no-fail-fast
            if command -v cargo-tarpaulin &> /dev/null; then
                cargo tarpaulin --out Html
                echo -e "\n${BLUE}Coverage report:${NC} tarpaulin-report.html"
            else
                echo -e "\n${YELLOW}⚠️  Install cargo-tarpaulin for coverage${NC}"
            fi
            ;;
        *)
            echo -e "${RED}❌ Coverage not supported for this framework${NC}"
            exit 1
            ;;
    esac
}

cmd_watch() {
    echo -e "${CYAN}👁️  Starting test watcher...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    
    local framework=$(detect_framework)
    
    case "$framework" in
        jest)
            npm test -- --watch
            ;;
        vitest)
            npx vitest
            ;;
        pytest)
            if command -v pytest-watch &> /dev/null; then
                ptw
            else
                echo -e "${YELLOW}⚠️  Install pytest-watch: pip install pytest-watch${NC}"
                pytest --looponfail
            fi
            ;;
        go)
            if command -v gotest &> /dev/null; then
                gotest -v ./...
            else
                echo -e "${YELLOW}⚠️  Install gotest: go install github.com/rakyll/gotest@latest${NC}"
                while true; do
                    go test -v ./...
                    sleep 2
                done
            fi
            ;;
        cargo)
            cargo watch -x test
            ;;
        *)
            echo -e "${RED}❌ Watch mode not supported${NC}"
            exit 1
            ;;
    esac
}

cmd_benchmark() {
    echo -e "${CYAN}⚡ Running benchmarks...${NC}\n"
    
    local framework=$(detect_framework)
    
    case "$framework" in
        go)
            go test -bench=. -benchmem ./...
            ;;
        cargo)
            cargo bench
            ;;
        pytest)
            pytest --benchmark-only
            ;;
        *)
            echo -e "${YELLOW}⚠️  Benchmarks not available for this framework${NC}"
            ;;
    esac
}

cmd_report() {
    init_db
    echo -e "${CYAN}📈 Test History:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT framework, total_tests, passed, failed, duration, datetime(ran_at, 'unixepoch') FROM test_runs ORDER BY ran_at DESC LIMIT 10;" | while IFS=$'\t' read -r fw total pass fail dur time; do
        if [[ "$fail" == "0" ]] || [[ -z "$fail" ]]; then
            echo -e "${GREEN}✓${NC} $time - $fw"
        else
            echo -e "${RED}✗${NC} $time - $fw"
        fi
        if [[ -n "$total" ]]; then
            echo -e "  Tests: $pass passed, $fail failed (${dur}s)"
        else
            echo -e "  Duration: ${dur}s"
        fi
        echo ""
    done
}

cmd_stats() {
    init_db
    echo -e "${CYAN}📊 Test Statistics:${NC}\n"
    
    local total_runs=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM test_runs;")
    local avg_duration=$(sqlite3 "$DB_FILE" "SELECT AVG(duration) FROM test_runs;" | awk '{printf "%.1f", $1}')
    
    echo -e "${BLUE}Total test runs:${NC} $total_runs"
    echo -e "${BLUE}Average duration:${NC} ${avg_duration}s"
    
    echo -e "\n${CYAN}Runs by framework:${NC}"
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT framework, COUNT(*) as cnt FROM test_runs GROUP BY framework ORDER BY cnt DESC;" | while IFS=$'\t' read -r fw count; do
        echo -e "  ${GREEN}$fw${NC}: $count runs"
    done
}

cmd_help() {
    cat << 'EOF'
🧪 Test Suite Manager

USAGE:
  br test <command> [options]

RUNNING TESTS:
  run [pattern]          Run all tests (or filter by pattern)
  coverage               Run with coverage report
  watch                  Watch mode (auto-rerun on changes)
  benchmark              Run performance benchmarks

REPORTING:
  report                 Show test history
  stats                  Show test statistics

SUPPORTED FRAMEWORKS:
  JavaScript:  Jest, Vitest, Mocha
  Python:      Pytest
  Go:          go test
  Rust:        cargo test
  PHP:         PHPUnit

EXAMPLES:
  # Run all tests
  br test run

  # Run specific tests
  br test run UserService
  br test run "api.*"

  # Coverage
  br test coverage

  # Watch mode (auto-rerun)
  br test watch

  # Benchmarks
  br test benchmark

  # Reports
  br test report
  br test stats

NOTES:
  - Auto-detects test framework from project files
  - Tracks test history in database
  - Coverage reports saved to project directory
  - Install framework-specific tools for full features

EOF
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
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
