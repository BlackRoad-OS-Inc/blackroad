#!/bin/zsh
# BR Context Radar — watch project files and surface AI suggestions

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

DB="$HOME/.blackroad/context-radar.db"
WATCH_DIR="${2:-$PWD}"

init_db() {
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS suggestions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file TEXT, type TEXT, suggestion TEXT, ts REAL,
    dismissed INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS watches (
    path TEXT PRIMARY KEY, last_seen REAL
);
SQL
}

cmd_scan() {
    init_db
    echo -e "${CYAN}🔭 Context Radar — scanning ${WATCH_DIR}${NC}\n"
    local count=0
    while IFS= read -r -d '' file; do
        local ext="${file##*.}"
        local lines=$(wc -l < "$file" 2>/dev/null || echo 0)
        local suggestion=""
        case "$ext" in
            py)
                grep -q "^def \|^class " "$file" 2>/dev/null && ! grep -q "def test_\|unittest\|pytest" "$file" 2>/dev/null && \
                    suggestion="Missing tests for Python module"
                ;;
            js|ts|tsx)
                grep -q "console\.log" "$file" 2>/dev/null && \
                    suggestion="console.log found — consider removing for production"
                ;;
            sh|zsh)
                ! head -3 "$file" 2>/dev/null | grep -q "set -e\|errexit" && [[ $lines -gt 50 ]] && \
                    suggestion="Large shell script missing 'set -e' safety flag"
                ;;
            toml)
                basename "$file" | grep -q "wrangler" && ! grep -q "compatibility_date" "$file" 2>/dev/null && \
                    suggestion="Wrangler config missing compatibility_date"
                ;;
        esac
        if [[ -n "$suggestion" ]]; then
            sqlite3 "$DB" "INSERT INTO suggestions(file,type,suggestion,ts) VALUES('$file','$ext','$suggestion',$(date +%s));" 2>/dev/null
            echo -e "  ${YELLOW}⚡${NC} ${file##$WATCH_DIR/}  →  $suggestion"
            ((count++))
        fi
    done < <(find "$WATCH_DIR" -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.sh" -o -name "*.zsh" -o -name "wrangler.toml" \) -not -path "*/node_modules/*" -not -path "*/.git/*" -print0 2>/dev/null | head -200)
    echo -e "\n  ${GREEN}✓${NC} Scanned — $count suggestions"
}

cmd_list() {
    init_db
    echo -e "${CYAN}💡 Recent Suggestions${NC}\n"
    sqlite3 "$DB" "SELECT file, suggestion FROM suggestions WHERE dismissed=0 ORDER BY ts DESC LIMIT 20;" | \
        while IFS='|' read file sug; do
            echo -e "  ${YELLOW}•${NC} ${file##*/}: $sug"
        done
}

cmd_clear() {
    sqlite3 "$DB" "UPDATE suggestions SET dismissed=1;" 2>/dev/null
    echo -e "${GREEN}✓ Cleared${NC}"
}

show_help() {
    echo -e "${CYAN}BR Context Radar${NC}"
    echo "  br radar scan [dir]   Scan directory for suggestions"
    echo "  br radar list         Show recent suggestions"
    echo "  br radar clear        Dismiss all suggestions"
}

case "${1:-scan}" in
    scan)  cmd_scan ;;
    list)  cmd_list ;;
    clear) cmd_clear ;;
    *)     show_help ;;
esac
