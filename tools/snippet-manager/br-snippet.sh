#!/bin/zsh
#===============================================================================
# BR Snippet - Code Snippet Manager
# Save, retrieve, and manage code snippets
#===============================================================================

SNIPPET_HOME="/Users/alexa/blackroad/tools/snippet-manager"
SNIPPET_DB="${SNIPPET_HOME}/snippets.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

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
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     💾 Save Code Snippet                     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
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
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     📋 Snippet: $name${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -n "$description" ]]; then
        echo -e "${CYAN}Description:${NC} $description"
        echo ""
    fi
    
    echo -e "${YELLOW}Language:${NC} $language"
    echo ""
    echo "$code"
    echo ""
    
    # Update usage stats
    sqlite3 "$SNIPPET_DB" <<EOF
UPDATE snippets 
SET use_count = use_count + 1, last_used = $(date +%s)
WHERE name='$name';
EOF
    
    echo -e "${CYAN}Tip: Copy with:${NC} br snippet get $name | pbcopy"
}

# List snippets
list_snippets() {
    local filter=${1:-""}
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     📚 Snippet Library                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
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
        echo -e "${GREEN}${count}. ${name}${NC} ${CYAN}(${language})${NC}"
        if [[ -n "$description" ]]; then
            echo "   $description"
        fi
        echo "   Uses: $use_count"
        echo ""
    done <<< "$results"
    
    echo -e "${CYAN}Total: ${count} snippet(s)${NC}"
}

# Search snippets
search_snippets() {
    local query=$1
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}Error: Search query required${NC}"
        echo "Usage: br snippet search <query>"
        return 1
    fi
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     🔍 Search Results                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Searching for: '$query'${NC}"
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
        echo -e "${GREEN}${count}. ${name}${NC} ${CYAN}(${language})${NC}"
        if [[ -n "$description" ]]; then
            echo "   $description"
        fi
        
        # Show matching line
        local match=$(echo "$code" | grep -i "$query" | head -1 | cut -c1-60)
        if [[ -n "$match" ]]; then
            echo "   ${YELLOW}...${match}...${NC}"
        fi
        echo ""
    done <<< "$results"
    
    echo -e "${CYAN}Found: ${count} match(es)${NC}"
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
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     💡 Snippet Suggestions                    ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
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
        echo -e "${YELLOW}No $language snippets available${NC}"
        echo "Create one with: br snippet save <name>"
        return 0
    fi
    
    local count=0
    while IFS='|||' read -r name description; do
        ((count++))
        echo -e "  ${count}. ${GREEN}${name}${NC}"
        if [[ -n "$description" ]]; then
            echo "     ${description}"
        fi
    done <<< "$results"
    
    echo ""
    echo -e "${CYAN}Get snippet:${NC} br snippet get <name>"
}

# Show help
show_help() {
    cat <<EOF
BR Snippet - Code Snippet Manager

Usage: br snippet {command} [args]

Commands:
  save <name>      - Save code snippet from stdin
  get <name>       - Retrieve and display snippet
  list [filter]    - List all snippets (optional filter)
  search <query>   - Search snippets by name/content
  delete <name>    - Delete a snippet
  suggest          - Get suggestions for current context

Examples:
  echo "ls -la" | br snippet save list-all
  br snippet get list-all
  br snippet list bash
  br snippet search loop
  br snippet suggest

EOF
}

# Initialize database on first run
init_db

# Main dispatch
case ${1:-list} in
    save|s)
        save_snippet "$2"
        ;;
    get|g)
        get_snippet "$2"
        ;;
    list|l|ls)
        list_snippets "$2"
        ;;
    search|find|f)
        search_snippets "$2"
        ;;
    delete|del|rm)
        delete_snippet "$2"
        ;;
    suggest|sug)
        suggest_snippets
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
