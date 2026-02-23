#!/bin/zsh
#===============================================================================
# BR Snippet - Code Snippet Manager  v2
# Save, retrieve, and manage code snippets
#===============================================================================

SNIPPET_HOME="/Users/alexa/blackroad/tools/snippet-manager"
SNIPPET_DB="${SNIPPET_HOME}/snippets.db"

# Brand palette
AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
# Compat aliases
BLUE="$BBLUE"; CYAN="$AMBER"; YELLOW="$PINK"; PURPLE="$VIOLET"

# Initialize database
init_db() {
    if [[ -f "$SNIPPET_DB" ]]; then
        return 0
    fi
    
    mkdir -p "$SNIPPET_HOME"
    
    sqlite3 "$SNIPPET_DB" <<EOF
CREATE TABLE snippets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    code TEXT NOT NULL,
    language TEXT,
    description TEXT,
    tags TEXT,
    created_at INTEGER NOT NULL,
    last_used INTEGER NOT NULL,
    use_count INTEGER DEFAULT 0
);

CREATE INDEX idx_name ON snippets(name);
CREATE INDEX idx_language ON snippets(language);
CREATE INDEX idx_tags ON snippets(tags);

CREATE TABLE snippet_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    snippet_id INTEGER,
    action TEXT,
    timestamp INTEGER,
    FOREIGN KEY(snippet_id) REFERENCES snippets(id)
);

INSERT INTO snippets (name, code, language, description, tags, created_at, last_used, use_count)
VALUES 
    ('hello-world', 'echo "Hello, World!"', 'bash', 'Simple hello world', 'demo,basic', $(date +%s), $(date +%s), 0),
    ('for-loop', 'for i in {1..10}; do\n  echo \$i\ndone', 'bash', 'Basic for loop', 'loop,iteration', $(date +%s), $(date +%s), 0);
EOF
    
    echo -e "${GREEN}✓ Snippet database initialized${NC}"
}

# Save snippet
save_snippet() {
    local name=$1
    local code=""
    local description=""
    local language=""
    local tags=""
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Snippet name required${NC}"
        echo "Usage: br snippet save <name>"
        return 1
    fi
    
    echo -e "  ${AMBER}${BOLD}◆ BR SNIPPET${NC}  ${DIM}save${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    
    # Get code from stdin or prompt
    if [[ -p /dev/stdin ]]; then
        code=$(cat)
    else
        echo -e "${CYAN}Paste your code (Ctrl+D when done):${NC}"
        code=$(cat)
    fi
    
    if [[ -z "$code" ]]; then
        echo -e "${RED}Error: No code provided${NC}"
        return 1
    fi
    
    # Detect language
    if [[ "$code" =~ "function\s+\w+\s*\(" ]] || [[ "$code" =~ "=>\s*\{" ]]; then
        language="javascript"
    elif [[ "$code" =~ "def\s+\w+\s*\(" ]]; then
        language="python"
    elif [[ "$code" =~ "#!/bin/(bash|zsh)" ]] || [[ "$code" =~ "for\s+\w+\s+in" ]]; then
        language="bash"
    elif [[ "$code" =~ "func\s+\w+" ]]; then
        language="go"
    else
        language="text"
    fi
    
    echo ""
    echo -e "${CYAN}Detected language:${NC} ${language}"
    echo -ne "${YELLOW}Description (optional):${NC} "
    read -r description
    echo -ne "${YELLOW}Tags (comma-separated, optional):${NC} "
    read -r tags
    
    # Save to database
    local timestamp=$(date +%s)
    local escaped_code=$(echo "$code" | sed "s/'/''/g")
    local escaped_desc=$(echo "$description" | sed "s/'/''/g")
    
    sqlite3 "$SNIPPET_DB" <<EOF
INSERT INTO snippets (name, code, language, description, tags, created_at, last_used)
VALUES ('$name', '$escaped_code', '$language', '$escaped_desc', '$tags', $timestamp, $timestamp)
ON CONFLICT(name) DO UPDATE SET
    code = '$escaped_code',
    language = '$language',
    description = '$escaped_desc',
    tags = '$tags',
    last_used = $timestamp;
EOF
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓ Snippet '$name' saved!${NC}"
        echo ""
        echo -e "${CYAN}Retrieve with:${NC} br snippet get $name"
    else
        echo -e "${RED}✗ Failed to save snippet${NC}"
        return 1
    fi
}

# Get snippet
get_snippet() {
    local name=$1
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Snippet name required${NC}"
        echo "Usage: br snippet get <name>"
        return 1
    fi
    
    local result=$(sqlite3 "$SNIPPET_DB" -separator $'\t' \
        "SELECT code, language, description FROM snippets WHERE name='$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${YELLOW}Snippet '$name' not found${NC}"
        echo ""
        echo "Search for snippets with: br snippet search"
        return 1
    fi
    
    local code=$(echo "$result" | cut -f1)
    local language=$(echo "$result" | cut -f2)
    local description=$(echo "$result" | cut -f3)
    
    echo -e "  ${AMBER}${BOLD}◆ BR SNIPPET${NC}  ${DIM}$name${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    
    if [[ -n "$description" ]]; then
        echo -e "  ${DIM}$description${NC}"
        echo ""
    fi
    
    echo -e "  ${VIOLET}lang${NC}  ${DIM}$language${NC}"
    echo ""
    echo "$code"
    echo ""
    
    # Update usage stats
    sqlite3 "$SNIPPET_DB" "UPDATE snippets SET use_count = use_count + 1, last_used = $(date +%s) WHERE name='$name';"
    
    echo -e "  ${DIM}→  br snippet get $name | pbcopy${NC}"
}

# List snippets
list_snippets() {
    local filter=${1:-""}
    
    echo -e "  ${AMBER}${BOLD}◆ BR SNIPPET${NC}  ${DIM}library${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    
    local query="SELECT name, language, description, use_count FROM snippets"
    if [[ -n "$filter" ]]; then
        query="$query WHERE language='$filter' OR tags LIKE '%$filter%' OR name LIKE '%$filter%'"
    fi
    query="$query ORDER BY use_count DESC, last_used DESC;"
    
    local results=$(sqlite3 "$SNIPPET_DB" -separator $'\t' "$query")
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No snippets found${NC}"
        return 0
    fi
    
    local count=0
    while IFS=$'\t' read -r name language description use_count; do
        ((count++))
        echo -e "  ${GREEN}${BOLD}${count}. ${name}${NC}  ${VIOLET}${language}${NC}"
        [[ -n "$description" ]] && echo -e "     ${DIM}$description${NC}"
        echo -e "     ${DIM}uses: $use_count${NC}"
        echo ""
    done <<< "$results"
    
    echo -e "  ${DIM}total: ${count} snippet(s)${NC}"
}

# Search snippets
search_snippets() {
    local query=$1
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}Error: Search query required${NC}"
        echo "Usage: br snippet search <query>"
        return 1
    fi
    
    echo -e "  ${AMBER}${BOLD}◆ BR SNIPPET${NC}  ${DIM}search: $query${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    
    local results=$(sqlite3 "$SNIPPET_DB" -separator $'\t' \
        "SELECT name, language, description, code FROM snippets 
         WHERE name LIKE '%$query%' 
            OR description LIKE '%$query%' 
            OR tags LIKE '%$query%'
            OR code LIKE '%$query%'
         ORDER BY use_count DESC;")
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No matches found${NC}"
        return 0
    fi
    
    local count=0
    while IFS=$'\t' read -r name language description code; do
        ((count++))
        echo -e "  ${GREEN}${BOLD}${count}. ${name}${NC}  ${VIOLET}${language}${NC}"
        [[ -n "$description" ]] && echo -e "     ${DIM}$description${NC}"
        local match; match=$(echo "$code" | grep -i "$query" | head -1 | cut -c1-60)
        [[ -n "$match" ]] && echo -e "     ${DIM}…${match}…${NC}"
        echo ""
    done <<< "$results"
    
    echo -e "  ${DIM}found: ${count} match(es)${NC}"
}

# Delete snippet
delete_snippet() {
    local name=$1
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Snippet name required${NC}"
        echo "Usage: br snippet delete <name>"
        return 1
    fi
    
    # Check if exists
    local exists=$(sqlite3 "$SNIPPET_DB" "SELECT COUNT(*) FROM snippets WHERE name='$name';")
    
    if [[ "$exists" == "0" ]]; then
        echo -e "${YELLOW}Snippet '$name' not found${NC}"
        return 1
    fi
    
    echo -ne "${RED}Delete snippet '$name'? [y/N]:${NC} "
    read -r confirm
    
    if [[ ${confirm:l} == "y" ]]; then
        sqlite3 "$SNIPPET_DB" "DELETE FROM snippets WHERE name='$name';"
        echo -e "${GREEN}✓ Snippet deleted${NC}"
    else
        echo -e "${YELLOW}Cancelled${NC}"
    fi
}

# Suggest snippets based on context
suggest_snippets() {
    echo -e "  ${AMBER}${BOLD}◆ BR SNIPPET${NC}  ${DIM}suggest${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    
    # Detect current context
    local current_file=$(pwd)
    local language="bash"
    
    # Detect from file extensions in current dir
    if ls *.js *.jsx *.ts *.tsx &>/dev/null; then
        language="javascript"
    elif ls *.py &>/dev/null; then
        language="python"
    elif ls *.go &>/dev/null; then
        language="go"
    elif ls *.sh &>/dev/null; then
        language="bash"
    fi
    
    echo -e "${CYAN}Context:${NC} ${language} project"
    echo ""
    echo -e "${GREEN}Suggested snippets:${NC}"
    echo ""
    
    local results=$(sqlite3 "$SNIPPET_DB" -separator '|||' \
        "SELECT name, description FROM snippets 
         WHERE language='$language' 
         ORDER BY use_count DESC 
         LIMIT 5;")
    
    if [[ -z "$results" ]]; then
        echo -e "  ${DIM}No $language snippets yet.  br snippet save <name>${NC}"
        return 0
    fi
    
    local count=0
    while IFS='|||' read -r name description; do
        ((count++))
        echo -e "  ${GREEN}${BOLD}${count}. ${name}${NC}"
        [[ -n "$description" ]] && echo -e "     ${DIM}${description}${NC}"
    done <<< "$results"
    
    echo ""
    echo -e "  ${DIM}→  br snippet get <name>${NC}"
}

# Show help
show_help() {
    echo ""
    echo -e "  ${AMBER}${BOLD}BR SNIPPET${NC}  ${DIM}code snippet manager${NC}"
    echo ""
    echo -e "  ${BOLD}br snippet${NC}             ${DIM}list all (default)${NC}"
    echo -e "  ${BOLD}br snippet save <name>${NC} ${DIM}save from stdin${NC}"
    echo -e "  ${BOLD}br snippet get <name>${NC}  ${DIM}retrieve snippet${NC}"
    echo -e "  ${BOLD}br snippet search <q>${NC}  ${DIM}search by name/content/tags${NC}"
    echo -e "  ${BOLD}br snippet suggest${NC}     ${DIM}suggest for current dir context${NC}"
    echo -e "  ${BOLD}br snippet del <name>${NC}  ${DIM}delete snippet${NC}"
    echo ""
    echo -e "  ${DIM}echo 'ls -la' | br snippet save list-all${NC}"
    echo -e "  ${DIM}br snippet get list-all | pbcopy${NC}"
    echo ""
}

# Initialize database on first run
init_db

# Main dispatch
case ${1:-list} in
    save|s)       save_snippet "$2" ;;
    get|g)        get_snippet "$2" ;;
    list|l|ls|"") list_snippets "$2" ;;
    search|find|f) search_snippets "$2" ;;
    delete|del|rm) delete_snippet "$2" ;;
    suggest|sug)  suggest_snippets ;;
    help|-h|--help) show_help ;;
    *)
        echo -e "  ${RED}✗${NC} Unknown: $1"
        show_help; exit 1 ;;
esac
