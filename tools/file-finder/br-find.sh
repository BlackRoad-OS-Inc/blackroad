#!/usr/bin/env zsh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/file-finder.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS searches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT,
    pattern TEXT,
    path TEXT,
    results_count INTEGER,
    executed_at INTEGER
);

CREATE TABLE IF NOT EXISTS bookmarks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    path TEXT,
    created_at INTEGER
);
EOF
}

cmd_search() {
    init_db
    local query="$1"
    local path="${2:-.}"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Specify search query${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🔍 Searching for: $query${NC}\n"
    
    local count=0
    find "$path" -type f -iname "*${query}*" 2>/dev/null | while IFS= read -r file; do
        echo -e "${GREEN}▸${NC} $file"
        count=$((count + 1))
        [[ $count -ge 100 ]] && break
    done
    
    echo -e "\n${BLUE}Search complete${NC}"
}

cmd_content() {
    init_db
    local query="$1"
    local path="${2:-.}"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}❌ Specify search query${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🔍 Searching content for: $query${NC}\n"
    
    if command -v rg &> /dev/null; then
        rg --color always --heading --line-number "$query" "$path" 2>/dev/null | /usr/bin/head -100
    elif command -v ag &> /dev/null; then
        ag --color "$query" "$path" 2>/dev/null | /usr/bin/head -100
    else
        grep -r -n --color=always "$query" "$path" 2>/dev/null | /usr/bin/head -100
    fi
    
    echo -e "\n${BLUE}Search complete${NC}"
}

cmd_type() {
    local ext="$1"
    local path="${2:-.}"
    
    if [[ -z "$ext" ]]; then
        echo -e "${RED}❌ Specify file extension${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📁 Finding .$ext files in $path:${NC}\n"
    
    find "$path" -type f -name "*.${ext}" 2>/dev/null | while read -r file; do
        local size=$(du -h "$file" 2>/dev/null | cut -f1)
        echo -e "${GREEN}▸${NC} $file ${BLUE}($size)${NC}"
    done
}

cmd_size() {
    local operator="$1"
    local size="$2"
    local path="${3:-.}"
    
    if [[ -z "$operator" || -z "$size" ]]; then
        echo -e "${RED}❌ Usage: br find size <+/-> <size> [path]${NC}"
        echo "Example: br find size + 10M ."
        exit 1
    fi
    
    echo -e "${CYAN}📊 Finding files $operator${size}:${NC}\n"
    
    find "$path" -type f -size "${operator}${size}" 2>/dev/null | while read -r file; do
        local filesize=$(du -h "$file" 2>/dev/null | cut -f1)
        echo -e "${GREEN}▸${NC} $file ${BLUE}($filesize)${NC}"
    done
}

cmd_recent() {
    local count="${1:-20}"
    local path="${2:-.}"
    
    echo -e "${CYAN}⏱️  Most recently modified files:${NC}\n"
    
    find "$path" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -"$count" | while read -r timestamp file; do
        local reltime=$(date -r "${timestamp%.*}" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "")
        echo -e "${GREEN}▸${NC} $file ${BLUE}($reltime)${NC}"
    done
}

cmd_duplicate() {
    local path="${1:-.}"
    
    echo -e "${CYAN}🔄 Finding duplicate files by name:${NC}\n"
    
    find "$path" -type f -printf '%f\n' 2>/dev/null | sort | uniq -d | while read -r filename; do
        echo -e "${YELLOW}⚠️  Duplicate: $filename${NC}"
        find "$path" -type f -name "$filename" 2>/dev/null | while read -r file; do
            echo -e "   ${GREEN}▸${NC} $file"
        done
        echo ""
    done
}

cmd_empty() {
    local path="${1:-.}"
    
    echo -e "${CYAN}📭 Finding empty files and directories:${NC}\n"
    
    echo -e "${BLUE}Empty files:${NC}"
    find "$path" -type f -empty 2>/dev/null | while read -r file; do
        echo -e "${YELLOW}▸${NC} $file"
    done
    
    echo -e "\n${BLUE}Empty directories:${NC}"
    find "$path" -type d -empty 2>/dev/null | while read -r dir; do
        echo -e "${YELLOW}▸${NC} $dir"
    done
}

cmd_bookmark() {
    init_db
    local action="$1"
    
    case "$action" in
        add)
            local name="$2"
            local path="${3:-$(pwd)}"
            
            if [[ -z "$name" ]]; then
                echo -e "${RED}❌ Specify bookmark name${NC}"
                exit 1
            fi
            
            local abs_path=$(realpath "$path")
            sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO bookmarks (name, path, created_at) VALUES ('$name', '$abs_path', $(date +%s));"
            echo -e "${GREEN}✓ Bookmarked $abs_path as '$name'${NC}"
            ;;
        list)
            echo -e "${CYAN}📌 Bookmarks:${NC}\n"
            sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, path FROM bookmarks ORDER BY created_at DESC;" | while IFS=$'\t' read -r name path; do
                echo -e "${BLUE}▸${NC} $name"
                echo -e "  $path"
                echo ""
            done
            ;;
        rm)
            local name="$2"
            if [[ -z "$name" ]]; then
                echo -e "${RED}❌ Specify bookmark name${NC}"
                exit 1
            fi
            sqlite3 "$DB_FILE" "DELETE FROM bookmarks WHERE name='$name';"
            echo -e "${GREEN}✓ Removed bookmark '$name'${NC}"
            ;;
        goto)
            local name="$2"
            if [[ -z "$name" ]]; then
                echo -e "${RED}❌ Specify bookmark name${NC}"
                exit 1
            fi
            local path=$(sqlite3 "$DB_FILE" "SELECT path FROM bookmarks WHERE name='$name';")
            if [[ -z "$path" ]]; then
                echo -e "${RED}❌ Bookmark '$name' not found${NC}"
                exit 1
            fi
            echo "$path"
            ;;
        *)
            echo -e "${RED}❌ Unknown bookmark action: $action${NC}"
            echo "Use: add, list, rm, goto"
            ;;
    esac
}

cmd_history() {
    init_db
    echo -e "${CYAN}📜 Search History:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT query, pattern, results_count, datetime(executed_at, 'unixepoch') FROM searches ORDER BY executed_at DESC LIMIT 20;" | while IFS=$'\t' read -r query pattern count time; do
        echo -e "${BLUE}▸${NC} $query ($pattern) - $count results"
        echo "  $time"
        echo ""
    done
}

cmd_help() {
    cat << 'EOF'
🔍 Advanced File Finder

USAGE:
  br find <command> [options]

SEARCH COMMANDS:
  search <query> [path]    Find files by name
  content <query> [path]   Search file contents
  type <ext> [path]        Find by file extension
  size <+/-> <size> [path] Find by size (e.g., +10M, -1K)
  recent [count] [path]    Recently modified files
  
FILE ANALYSIS:
  duplicate [path]         Find duplicate filenames
  empty [path]             Find empty files/directories
  
BOOKMARKS:
  bookmark add <name> [path]    Bookmark a directory
  bookmark list                 List bookmarks
  bookmark rm <name>            Remove bookmark
  bookmark goto <name>          Get bookmark path
  
HISTORY:
  history                  Show search history

EXAMPLES:
  br find search config.json
  br find content "TODO" src/
  br find type js src/
  br find size + 10M .
  br find recent 50
  br find duplicate
  br find bookmark add home ~/projects
  br find bookmark goto home

NOTES:
  - Uses ripgrep/ag if available for faster content search
  - Size units: K (KB), M (MB), G (GB)
  - Use + for larger than, - for smaller than

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    search|s) cmd_search "${@:2}" ;;
    content|grep|c) cmd_content "${@:2}" ;;
    type|ext) cmd_type "${@:2}" ;;
    size) cmd_size "${@:2}" ;;
    recent|r) cmd_recent "${@:2}" ;;
    duplicate|dup) cmd_duplicate "${@:2}" ;;
    empty) cmd_empty "${@:2}" ;;
    bookmark|bm) cmd_bookmark "${@:2}" ;;
    history|hist) cmd_history ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
