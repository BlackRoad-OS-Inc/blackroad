#!/usr/bin/env zsh

AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"

DB_FILE="$HOME/.blackroad/smart-search.db"
INDEX_DIR="$HOME/.blackroad/search-index"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    mkdir -p "$INDEX_DIR"
    
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS search_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT,
    results_count INTEGER,
    search_type TEXT,
    searched_at INTEGER
);

CREATE TABLE IF NOT EXISTS saved_searches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    query TEXT,
    filters TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS file_index (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filepath TEXT UNIQUE,
    filename TEXT,
    extension TEXT,
    size INTEGER,
    last_modified INTEGER,
    content_hash TEXT,
    indexed_at INTEGER
);

CREATE TABLE IF NOT EXISTS symbols (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filepath TEXT,
    symbol_name TEXT,
    symbol_type TEXT,
    line_number INTEGER,
    indexed_at INTEGER
);
EOF
}

cmd_quick() {
    local query="$*"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Usage: br search <query>${NC}"
        echo "Example: br search function handleClick"
        exit 1
    fi
    
    echo -e "${CYAN}🔍 Searching for: ${YELLOW}$query${NC}\n"
    
    local results=0
    
    # Use ripgrep if available, otherwise grep
    if command -v rg &> /dev/null; then
        rg --color always --heading --line-number -i "$query" . 2>/dev/null | head -100
        results=$(rg -l -i "$query" . 2>/dev/null | wc -l | tr -d ' ')
    elif command -v ag &> /dev/null; then
        ag --color -i "$query" . 2>/dev/null | head -100
        results=$(ag -l -i "$query" . 2>/dev/null | wc -l | tr -d ' ')
    else
        grep -r -n -i --color=always "$query" . 2>/dev/null | head -100
        results=$(grep -r -l -i "$query" . 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    echo -e "\n${BLUE}Found in $results file(s)${NC}"
    
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO search_history (query, results_count, search_type, searched_at) VALUES ('$(echo "$query" | sed "s/'/''/g")', $results, 'quick', $(date +%s));"
}

cmd_fuzzy() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Usage: br search fuzzy <query>${NC}"
        echo "Example: br search fuzzy hdlClck"
        exit 1
    fi
    
    echo -e "${CYAN}🎯 Fuzzy search for: ${YELLOW}$query${NC}\n"
    
    # Use fzf if available
    if command -v fzf &> /dev/null; then
        find . -type f -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | fzf --filter="$query" | head -20
    else
        # Fallback to approximate matching
        find . -type f -not -path "*/\.*" 2>/dev/null | grep -i "$query" | head -20
    fi
    
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO search_history (query, results_count, search_type, searched_at) VALUES ('$query', 0, 'fuzzy', $(date +%s));"
}

cmd_symbol() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Usage: br search symbol <name>${NC}"
        echo "Example: br search symbol handleClick"
        exit 1
    fi
    
    echo -e "${CYAN}🔎 Searching for symbol: ${YELLOW}$query${NC}\n"
    
    # Search for common symbol patterns
    echo -e "${BLUE}Functions:${NC}"
    if command -v rg &> /dev/null; then
        rg --color always "function\s+$query|const\s+$query\s*=|def\s+$query|fn\s+$query" . 2>/dev/null | head -10
    else
        grep -rn -E "function\s+$query|const\s+$query\s*=|def\s+$query|fn\s+$query" . 2>/dev/null | head -10
    fi
    
    echo -e "\n${BLUE}Classes:${NC}"
    if command -v rg &> /dev/null; then
        rg --color always "class\s+$query|interface\s+$query|struct\s+$query" . 2>/dev/null | head -10
    else
        grep -rn -E "class\s+$query|interface\s+$query|struct\s+$query" . 2>/dev/null | head -10
    fi
    
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO search_history (query, results_count, search_type, searched_at) VALUES ('$query', 0, 'symbol', $(date +%s));"
}

cmd_type() {
    local extension="$1"
    local query="$2"
    
    if [[ -z "$extension" || -z "$query" ]]; then
        echo -e "${RED}❌ Usage: br search type <ext> <query>${NC}"
        echo "Example: br search type js useState"
        exit 1
    fi
    
    echo -e "${CYAN}🔍 Searching in *.${extension} files for: ${YELLOW}$query${NC}\n"
    
    if command -v rg &> /dev/null; then
        rg --color always --heading --line-number -i -t "$extension" "$query" . 2>/dev/null | head -50
    else
        find . -type f -name "*.${extension}" -exec grep -n -i --color=always "$query" {} + 2>/dev/null | head -50
    fi
    
    init_db
    sqlite3 "$DB_FILE" "INSERT INTO search_history (query, results_count, search_type, searched_at) VALUES ('$query in .$extension', 0, 'type', $(date +%s));"
}

cmd_recent() {
    local days="${1:-7}"
    local query="$2"
    
    echo -e "${CYAN}📅 Files modified in last $days days${NC}"
    
    if [[ -n "$query" ]]; then
        echo -e "  ${YELLOW}containing: $query${NC}"
    fi
    echo ""
    
    find . -type f -mtime -"$days" -not -path "*/\.*" -not -path "*/node_modules/*" 2>/dev/null | while read -r file; do
        if [[ -n "$query" ]]; then
            if grep -q -i "$query" "$file" 2>/dev/null; then
                local mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
                echo -e "${GREEN}▸${NC} $file"
                echo -e "  Modified: $mod_time"
            fi
        else
            local mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            echo -e "${GREEN}▸${NC} $file"
            echo -e "  Modified: $mod_time"
        fi
    done | head -30
}

cmd_large() {
    local size="${1:-10}"
    local query="$2"
    
    echo -e "${CYAN}📊 Files larger than ${size}MB${NC}"
    
    if [[ -n "$query" ]]; then
        echo -e "  ${YELLOW}containing: $query${NC}"
    fi
    echo ""
    
    find . -type f -size +"${size}M" -not -path "*/\.*" 2>/dev/null | while read -r file; do
        if [[ -n "$query" ]]; then
            if grep -q -i "$query" "$file" 2>/dev/null; then
                local file_size=$(du -h "$file" | cut -f1)
                echo -e "${BLUE}▸${NC} $file (${file_size})"
            fi
        else
            local file_size=$(du -h "$file" | cut -f1)
            echo -e "${BLUE}▸${NC} $file (${file_size})"
        fi
    done | head -20
}

cmd_save() {
    init_db
    local name="$1"
    shift
    local query="$*"
    
    if [[ -z "$name" || -z "$query" ]]; then
        echo -e "${RED}❌ Usage: br search save <name> <query>${NC}"
        echo "Example: br search save react-hooks useState useEffect"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO saved_searches (name, query, created_at) VALUES ('$name', '$(echo "$query" | sed "s/'/''/g")', $(date +%s));"
    
    echo -e "${GREEN}✓ Saved search: $name${NC}"
    echo -e "  Query: $query"
    echo -e "\n${CYAN}Run with:${NC} br search run $name"
}

cmd_run() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br search run <name>${NC}"
        exit 1
    fi
    
    local query=$(sqlite3 "$DB_FILE" "SELECT query FROM saved_searches WHERE name='$name';")
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Saved search not found: $name${NC}"
        echo "Run: br search saved"
        exit 1
    fi
    
    echo -e "${CYAN}🔍 Running saved search: ${YELLOW}$name${NC}"
    echo -e "  Query: $query\n"
    
    cmd_quick "$query"
}

cmd_saved() {
    init_db
    echo -e "${CYAN}💾 Saved Searches:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, query FROM saved_searches ORDER BY created_at DESC;" | while IFS=$'\t' read -r name query; do
        echo -e "${BLUE}▸${NC} $name"
        echo -e "  $query"
        echo ""
    done
}

cmd_history() {
    init_db
    echo -e "${CYAN}📜 Search History:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT query, search_type, results_count, datetime(searched_at, 'unixepoch') FROM search_history ORDER BY searched_at DESC LIMIT 20;" | while IFS=$'\t' read -r query type count time; do
        echo -e "${BLUE}▸${NC} $query"
        echo -e "  Type: $type | Results: $count | Time: $time"
        echo ""
    done
}

cmd_index() {
    init_db
    local dir="${1:-.}"
    
    echo -e "${CYAN}📇 Indexing workspace: $dir${NC}\n"
    
    local count=0
    find "$dir" -type f -not -path "*/\.*" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | while read -r file; do
        local filename=$(basename "$file")
        local extension="${filename##*.}"
        local size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file" 2>/dev/null)
        local mod_time=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
        
        # Simple hash (modification time + size)
        local hash="${mod_time}-${size}"
        
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO file_index (filepath, filename, extension, size, last_modified, content_hash, indexed_at) VALUES ('$file', '$filename', '$extension', $size, $mod_time, '$hash', $(date +%s));"
        
        count=$((count + 1))
        if [[ $((count % 100)) -eq 0 ]]; then
            echo -e "${BLUE}Indexed $count files...${NC}"
        fi
    done
    
    echo -e "\n${GREEN}✓ Indexing complete${NC}"
    echo -e "  Total files: $count"
}

cmd_stats() {
    init_db
    echo -e "${CYAN}📊 Search Statistics:${NC}\n"
    
    local total_searches=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM search_history;")
    local total_indexed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM file_index;")
    local total_saved=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM saved_searches;")
    
    echo -e "${BLUE}Total searches:${NC} $total_searches"
    echo -e "${BLUE}Indexed files:${NC} $total_indexed"
    echo -e "${BLUE}Saved searches:${NC} $total_saved"
    
    echo -e "\n${CYAN}Most searched terms:${NC}"
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT query, COUNT(*) as cnt FROM search_history GROUP BY query ORDER BY cnt DESC LIMIT 5;" | while IFS=$'\t' read -r query count; do
        echo -e "  ${GREEN}$count${NC}x - $query"
    done
    
    echo -e "\n${CYAN}File types indexed:${NC}"
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT extension, COUNT(*) as cnt FROM file_index GROUP BY extension ORDER BY cnt DESC LIMIT 10;" | while IFS=$'\t' read -r ext count; do
        echo -e "  ${BLUE}.$ext${NC} - $count files"
    done
}

cmd_smart() {
    local query="$*"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Usage: br search smart <query>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🧠 Smart search for: ${YELLOW}$query${NC}\n"
    
    # Try multiple search strategies
    echo -e "${BLUE}1. Exact matches:${NC}"
    if command -v rg &> /dev/null; then
        rg --color always -w "$query" . 2>/dev/null | head -5
    fi
    
    echo -e "\n${BLUE}2. Case-insensitive:${NC}"
    if command -v rg &> /dev/null; then
        rg --color always -i "$query" . 2>/dev/null | head -5
    fi
    
    echo -e "\n${BLUE}3. Fuzzy matches:${NC}"
    find . -type f -name "*${query}*" -not -path "*/\.*" 2>/dev/null | head -5
    
    echo -e "\n${CYAN}💡 Suggestions:${NC}"
    echo "  Try: br search symbol $query"
    echo "  Try: br search type js $query"
}

cmd_help() {
    cat << 'EOF'
🔍 Smart Search Engine

USAGE:
  br search [query]             Quick search (default)
  br search <command> [options]

SEARCH TYPES:
  <query>                 Quick content search
  fuzzy <query>           Fuzzy filename matching
  symbol <name>           Find functions, classes, variables
  type <ext> <query>      Search specific file types
  smart <query>           Multi-strategy smart search

FILTERS:
  recent [days] [query]   Files modified recently (default: 7 days)
  large [size] [query]    Large files (default: 10MB)

SAVED SEARCHES:
  save <name> <query>     Save a search
  run <name>              Run saved search
  saved                   List saved searches

INDEXING:
  index [dir]             Index workspace for faster search
  stats                   Show search statistics

HISTORY:
  history                 Show search history

EXAMPLES:
  # Quick searches
  br search useState
  br search "API endpoint"

  # Advanced searches
  br search symbol handleClick
  br search type js useState
  br search fuzzy hdlClck
  br search smart authentication

  # Filters
  br search recent 3 "TODO"
  br search large 5 "config"

  # Save searches
  br search save react-hooks "useState useEffect"
  br search run react-hooks

  # Indexing
  br search index
  br search stats

NOTES:
  - Uses ripgrep (rg) if available for speed
  - Falls back to grep/find if needed
  - Fuzzy search requires fzf
  - Index workspace for faster searches

EOF
}

# Main dispatch
init_db

# Default to quick search if query provided directly
if [[ "$1" != "fuzzy" && "$1" != "symbol" && "$1" != "type" && "$1" != "recent" && "$1" != "large" && "$1" != "save" && "$1" != "run" && "$1" != "saved" && "$1" != "history" && "$1" != "index" && "$1" != "stats" && "$1" != "smart" && "$1" != "help" && "$1" != "--help" && "$1" != "-h" ]]; then
    if [[ -n "$1" ]]; then
        cmd_quick "$@"
        exit 0
    fi
fi

case "${1:-help}" in
    fuzzy|fuzz) cmd_fuzzy "${@:2}" ;;
    symbol|sym|func) cmd_symbol "${@:2}" ;;
    type|ext) cmd_type "${@:2}" ;;
    recent) cmd_recent "${@:2}" ;;
    large|big) cmd_large "${@:2}" ;;
    save) cmd_save "${@:2}" ;;
    run|exec) cmd_run "${@:2}" ;;
    saved|list) cmd_saved ;;
    history|hist) cmd_history ;;
    index) cmd_index "${@:2}" ;;
    stats) cmd_stats ;;
    smart|ai) cmd_smart "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        cmd_quick "$@"
        ;;
esac
