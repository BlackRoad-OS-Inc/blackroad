#!/bin/bash
# BlackRoad Codex Verification Suite
# CLI wrapper for codex verification, search, and statistics

CODEX_PATH="$HOME/blackroad-codex"
CODEX_DB="$CODEX_PATH/index/components.db"
PINK='\033[38;5;205m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

check_codex() {
    if [[ ! -f "$CODEX_DB" ]]; then
        echo -e "${RED}Error: Codex database not found at $CODEX_DB${NC}"
        echo -e "${YELLOW}Run the codex indexer first to build the database.${NC}"
        return 1
    fi
    return 0
}

show_help() {
    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}   ${WHITE}📚 BLACKROAD CODEX VERIFICATION SUITE 📚${NC}   ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Usage:${NC} $0 <command> [args]"
    echo ""
    echo -e "${WHITE}Commands:${NC}"
    echo -e "  ${GREEN}stats${NC}               Show codex statistics"
    echo -e "  ${GREEN}summary${NC}             Overview of codex contents"
    echo -e "  ${GREEN}search${NC} <term>       Search components by name/description"
    echo -e "  ${GREEN}verify${NC}              Run verification checks"
    echo -e "  ${GREEN}components${NC} [limit]  List components (default: 20)"
    echo -e "  ${GREEN}repos${NC}               List indexed repositories"
    echo -e "  ${GREEN}equations${NC}           Show discovered equations"
    echo -e "  ${GREEN}help${NC}                Show this help"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo -e "  $0 stats"
    echo -e "  $0 search authentication"
    echo -e "  $0 components 50"
}

show_stats() {
    check_codex || return 1

    local total=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM components;" 2>/dev/null || echo "0")
    local repos=$(sqlite3 "$CODEX_DB" "SELECT COUNT(DISTINCT repo_name) FROM components;" 2>/dev/null || echo "0")
    local functions=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM components WHERE type='function';" 2>/dev/null || echo "0")
    local classes=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM components WHERE type='class';" 2>/dev/null || echo "0")
    local modules=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM components WHERE type='module';" 2>/dev/null || echo "0")

    # Check for verification tables
    local verified=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM verifications WHERE passed=1;" 2>/dev/null || echo "0")
    local calculations=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM calculations;" 2>/dev/null || echo "0")
    local equations=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM calculations WHERE calc_type='equation';" 2>/dev/null || echo "0")

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}        ${WHITE}📊 CODEX VERIFICATION STATISTICS 📊${NC}        ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}Component Inventory:${NC}"
    echo -e "  ${CYAN}Total Components:${NC}  ${GREEN}$total${NC}"
    echo -e "  ${CYAN}Repositories:${NC}      ${GREEN}$repos${NC}"
    echo -e "  ${CYAN}Functions:${NC}         ${GREEN}$functions${NC}"
    echo -e "  ${CYAN}Classes:${NC}           ${GREEN}$classes${NC}"
    echo -e "  ${CYAN}Modules:${NC}           ${GREEN}$modules${NC}"
    echo ""
    echo -e "${WHITE}Verification Status:${NC}"
    echo -e "  ${CYAN}Verified Checks:${NC}   ${GREEN}$verified${NC}"
    echo -e "  ${CYAN}Calculations:${NC}      ${GREEN}$calculations${NC}"
    echo -e "  ${CYAN}Equations:${NC}         ${GREEN}$equations${NC}"
    echo ""

    # Top repos by component count
    echo -e "${WHITE}Top Repositories:${NC}"
    sqlite3 "$CODEX_DB" "SELECT repo_name, COUNT(*) as cnt FROM components GROUP BY repo_name ORDER BY cnt DESC LIMIT 5;" 2>/dev/null | while IFS='|' read -r repo count; do
        echo -e "  ${CYAN}•${NC} $repo: ${GREEN}$count${NC} components"
    done
}

show_summary() {
    check_codex || return 1
    show_stats
}

search_components() {
    local term="$1"
    check_codex || return 1

    if [[ -z "$term" ]]; then
        echo -e "${RED}Error: Please provide a search term${NC}"
        echo -e "Usage: $0 search <term>"
        return 1
    fi

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}      ${WHITE}🔍 CODEX SEARCH: \"$term\" 🔍${NC}      ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local results=$(sqlite3 "$CODEX_DB" "SELECT name, type, repo_name, file_path FROM components WHERE name LIKE '%$term%' OR description LIKE '%$term%' LIMIT 30;" 2>/dev/null)

    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No components found matching '$term'${NC}"
        return
    fi

    local count=$(echo "$results" | wc -l | tr -d ' ')
    echo -e "${GREEN}Found $count matching components:${NC}"
    echo ""

    echo "$results" | while IFS='|' read -r name type repo filepath; do
        echo -e "  ${WHITE}$name${NC} [${CYAN}$type${NC}]"
        echo -e "    ${BLUE}Repo:${NC} $repo"
        echo -e "    ${BLUE}Path:${NC} $filepath"
        echo ""
    done
}

run_verify() {
    check_codex || return 1

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}      ${WHITE}🔬 RUNNING VERIFICATION SUITE 🔬${NC}      ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if command -v python3 &>/dev/null && [[ -f "$HOME/blackroad-codex-verification.py" ]]; then
        python3 "$HOME/blackroad-codex-verification.py" 2>/dev/null
        echo -e "${GREEN}✅ Verification complete${NC}"
    else
        echo -e "${YELLOW}⚠️  Python verification framework not available${NC}"
        echo -e "Running basic integrity checks..."

        # Basic DB integrity check
        local integrity=$(sqlite3 "$CODEX_DB" "PRAGMA integrity_check;" 2>/dev/null)
        if [[ "$integrity" == "ok" ]]; then
            echo -e "  ${GREEN}✅ Database integrity: OK${NC}"
        else
            echo -e "  ${RED}❌ Database integrity: FAILED${NC}"
        fi

        # Check component count
        local count=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM components;" 2>/dev/null)
        echo -e "  ${GREEN}✅ Components indexed: $count${NC}"
    fi
}

list_components() {
    local limit="${1:-20}"
    check_codex || return 1

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}        ${WHITE}📦 CODEX COMPONENTS (Top $limit) 📦${NC}        ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    sqlite3 "$CODEX_DB" "SELECT name, type, repo_name FROM components LIMIT $limit;" 2>/dev/null | while IFS='|' read -r name type repo; do
        echo -e "  ${WHITE}$name${NC} [${CYAN}$type${NC}] - $repo"
    done
}

list_repos() {
    check_codex || return 1

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}        ${WHITE}📁 INDEXED REPOSITORIES 📁${NC}        ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    sqlite3 "$CODEX_DB" "SELECT repo_name, COUNT(*) as cnt FROM components GROUP BY repo_name ORDER BY cnt DESC;" 2>/dev/null | while IFS='|' read -r repo count; do
        echo -e "  ${WHITE}$repo${NC}: ${GREEN}$count${NC} components"
    done
}

show_equations() {
    check_codex || return 1

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}      ${WHITE}🧮 DISCOVERED EQUATIONS 🧮${NC}      ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local count=$(sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM calculations WHERE calc_type='equation';" 2>/dev/null || echo "0")

    if [[ "$count" == "0" ]]; then
        echo -e "${YELLOW}No equations discovered yet.${NC}"
        echo -e "Run: python3 ~/blackroad-codex-verification.py to extract calculations"
        return
    fi

    echo -e "${GREEN}Found $count equations:${NC}"
    echo ""

    sqlite3 "$CODEX_DB" "SELECT expression, domain, component_id FROM calculations WHERE calc_type='equation' LIMIT 20;" 2>/dev/null | while IFS='|' read -r expr domain comp; do
        echo -e "  ${CYAN}$expr${NC}"
        echo -e "    ${BLUE}Domain:${NC} ${domain:-unknown} | ${BLUE}Component:${NC} $comp"
        echo ""
    done
}

# Initialization check
init() {
    if [[ ! -d "$CODEX_PATH" ]]; then
        mkdir -p "$CODEX_PATH/index"
        echo -e "${GREEN}✅ Codex directory created at $CODEX_PATH${NC}"
    fi

    if [[ ! -f "$CODEX_DB" ]]; then
        echo -e "${YELLOW}⚠️  Codex database not found. Creating empty database...${NC}"
        sqlite3 "$CODEX_DB" <<EOF
CREATE TABLE IF NOT EXISTS components (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT,
    repo_name TEXT,
    file_path TEXT,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_name ON components(name);
CREATE INDEX IF NOT EXISTS idx_type ON components(type);
CREATE INDEX IF NOT EXISTS idx_repo ON components(repo_name);
EOF
        echo -e "${GREEN}✅ Empty codex database initialized${NC}"
    fi
}

# Main command router
case "${1:-help}" in
    init) init ;;
    stats) show_stats ;;
    summary) show_summary ;;
    search) search_components "$2" ;;
    verify) run_verify ;;
    components) list_components "$2" ;;
    repos) list_repos ;;
    equations) show_equations ;;
    help|--help|-h) show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
