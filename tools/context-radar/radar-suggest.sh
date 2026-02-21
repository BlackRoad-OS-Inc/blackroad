#!/bin/zsh
#===============================================================================
# Context Radar - Suggestion Engine
# Provides intelligent file and agent suggestions based on context
#===============================================================================

RADAR_HOME="/Users/alexa/blackroad/tools/context-radar"
RADAR_DB="${RADAR_HOME}/data/radar.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Source database functions
source "${RADAR_HOME}/radar-db.sh"

# Suggest files related to current context
suggest_files() {
    local context_file=${1:-$(pwd)}
    local limit=${2:-5}
    
    # Make path absolute
    if [[ ! "$context_file" =~ ^/ ]]; then
        context_file="$(pwd)/$context_file"
    fi
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🎯 Context Suggestions                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Context:${NC} ${context_file##*/}"
    echo ""
    
    # Get related files
    local results=$(get_related_files "$context_file" "$limit")
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No suggestions yet. Keep working and I'll learn your patterns!${NC}"
        return
    fi
    
    echo -e "${GREEN}Suggested files:${NC}"
    echo ""
    
    local count=1
    while IFS=$'\t' read -r filepath strength access_count rel_type; do
        local filename="${filepath##*/}"
        local dir="${filepath%/*}"
        dir="${dir##*/}"
        
        # Format relationship type
        local rel_icon="●"
        case $rel_type in
            test-source) rel_icon="🧪" ;;
            documentation) rel_icon="📖" ;;
            co-accessed) rel_icon="🔗" ;;
        esac
        
        # Format strength as bars
        local bars=$(printf '%.0f' $strength)
        local strength_viz=$(printf '█%.0s' {1..$bars})
        
        echo -e "  ${count}. ${rel_icon} ${GREEN}${filename}${NC}"
        echo -e "     ${CYAN}${dir}/${NC}"
        echo -e "     Strength: ${strength_viz} (${access_count} co-accesses)"
        echo ""
        
        ((count++))
    done <<< "$results"
    
    echo -e "${YELLOW}Tip: Use 'br radar open <number>' to open a suggestion${NC}"
}

# Suggest agent for current context
suggest_agent() {
    local context=${1:-$(pwd)}
    
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🤖 Agent Suggestion                       ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Simple heuristics (can be ML-powered later)
    if [[ "$context" =~ "test" ]]; then
        echo -e "${GREEN}→ ALICE${NC} - The Operator (great for testing & DevOps)"
    elif [[ "$context" =~ "\.md$" ]] || [[ "$context" =~ "README" ]] || [[ "$context" =~ "doc" ]]; then
        echo -e "${CYAN}→ LUCIDIA${NC} - The Dreamer (perfect for documentation & vision)"
    elif [[ "$context" =~ "\.sh$" ]] || [[ "$context" =~ "script" ]]; then
        echo -e "${RED}→ SHELLFISH${NC} - The Hacker (shell scripting expert)"
    elif [[ "$context" =~ "\.py$" ]] || [[ "$context" =~ "\.js$" ]] || [[ "$context" =~ "\.go$" ]]; then
        echo -e "${PURPLE}→ OCTAVIA${NC} - The Architect (code design & structure)"
    elif [[ "$context" =~ "ui" ]] || [[ "$context" =~ "frontend" ]] || [[ "$context" =~ "component" ]]; then
        echo -e "${BLUE}→ ARIA${NC} - The Interface (UI/UX specialist)"
    else
        echo -e "${PURPLE}→ OCTAVIA${NC} - The Architect (good all-rounder)"
    fi
    
    echo ""
    echo -e "${YELLOW}Tip: Invoke with 'br <agent> <your question>'${NC}"
}

# Show current context (what files are hot right now)
show_context() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     📊 Current Context                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${GREEN}Recent file activity:${NC}"
    echo ""
    
    local results=$(get_recent_activity 10)
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No activity tracked yet${NC}"
        return
    fi
    
    while IFS=$'\t' read -r filepath access_type timestamp; do
        local filename="${filepath##*/}"
        
        local icon="📄"
        case $access_type in
            created) icon="✨" ;;
            modified) icon="✏️" ;;
            deleted) icon="🗑️" ;;
        esac
        
        echo -e "  ${icon} ${GREEN}${filename}${NC} (${access_type})"
        echo -e "     ${timestamp}"
        echo ""
    done <<< "$results"
}

# Create a context bundle
create_bundle() {
    local bundle_name=$1
    shift
    local files=("$@")
    
    if [[ -z "$bundle_name" ]] || [[ ${#files[@]} -eq 0 ]]; then
        echo "Usage: radar-suggest.sh bundle <name> <file1> [file2] ..."
        return 1
    fi
    
    # Create JSON array of files
    local files_json="["
    for file in "${files[@]}"; do
        files_json+="\"$file\","
    done
    files_json="${files_json%,}]"
    
    local timestamp=$(date +%s)
    
    sqlite3 "$RADAR_DB" <<EOF
INSERT INTO context_bundles (name, files, created_at, last_used)
VALUES ('$bundle_name', '$files_json', $timestamp, $timestamp)
ON CONFLICT(name) DO UPDATE SET
    files = '$files_json',
    last_used = $timestamp;
EOF
    
    echo -e "${GREEN}✓ Bundle '$bundle_name' created with ${#files[@]} files${NC}"
}

# List bundles
list_bundles() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     📦 Context Bundles                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    local results=$(sqlite3 "$RADAR_DB" -separator $'\t' \
        "SELECT name, files, use_count, datetime(created_at, 'unixepoch', 'localtime') 
         FROM context_bundles ORDER BY last_used DESC;")
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No bundles created yet${NC}"
        echo ""
        echo "Create one with: br radar bundle <name> <file1> <file2> ..."
        return
    fi
    
    while IFS=$'\t' read -r name files use_count created; do
        local file_count=$(echo "$files" | grep -o ',' | wc -l)
        ((file_count++))
        
        echo -e "${GREEN}${name}${NC}"
        echo -e "  Files: ${file_count} | Uses: ${use_count} | Created: ${created}"
        echo ""
    done <<< "$results"
}

# Smart mode - analyze current directory and suggest next actions
smart_suggest() {
    local current_dir=$(pwd)
    
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🧠 Smart Context Analysis                 ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Analyzing: ${current_dir##*/}${NC}"
    echo ""
    
    # Check for common patterns
    if [[ -f "package.json" ]]; then
        echo -e "${GREEN}📦 Node.js project detected${NC}"
        echo "  Suggestions:"
        echo "  - Review package.json dependencies"
        echo "  - Check for tests in __tests__/ or *.test.js"
        echo ""
    fi
    
    if [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]]; then
        echo -e "${GREEN}🐍 Python project detected${NC}"
        echo "  Suggestions:"
        echo "  - Review requirements.txt"
        echo "  - Check for tests in tests/ directory"
        echo ""
    fi
    
    if [[ -d ".git" ]]; then
        echo -e "${GREEN}📂 Git repository${NC}"
        local uncommitted=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [[ $uncommitted -gt 0 ]]; then
            echo "  ⚠️  ${uncommitted} uncommitted changes"
        else
            echo "  ✓ Working tree clean"
        fi
        echo ""
    fi
    
    # Show related files based on current location
    local recent_files=$(find "$current_dir" -type f -not -path "*/.*" -not -path "*/node_modules/*" -mtime -1 2>/dev/null | head -5)
    if [[ -n "$recent_files" ]]; then
        echo -e "${GREEN}Recently modified:${NC}"
        echo "$recent_files" | while read -r file; do
            echo "  - ${file##*/}"
        done
        echo ""
    fi
    
    suggest_agent "$current_dir"
}

# Help
show_help() {
    cat <<EOF
Context Radar - Smart Suggestion Engine

Usage: radar-suggest.sh {command} [args]

Commands:
  suggest [file] [limit]  - Suggest related files (default: current dir, limit: 5)
  agent [context]         - Suggest which agent to use
  context                 - Show current work context
  bundle <name> <files>   - Create a context bundle
  bundles                 - List all bundles
  smart                   - Smart analysis of current directory

Examples:
  radar-suggest.sh suggest ./src/api.py
  radar-suggest.sh agent test
  radar-suggest.sh bundle api-work ./api.py ./test_api.py
  radar-suggest.sh smart

EOF
}

# Main dispatch
case ${1:-suggest} in
    suggest|s)
        suggest_files "$2" "$3"
        ;;
    agent|a)
        suggest_agent "$2"
        ;;
    context|ctx)
        show_context
        ;;
    bundle|b)
        shift
        create_bundle "$@"
        ;;
    bundles|list)
        list_bundles
        ;;
    smart)
        smart_suggest
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
// comment
