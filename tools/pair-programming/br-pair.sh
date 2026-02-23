#!/bin/zsh
#===============================================================================
# BR Pair - AI Pair Programming
# Interactive coding assistant that watches and helps
#===============================================================================
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

PAIR_HOME="/Users/alexa/blackroad/tools/pair-programming"
SESSION_FILE="${PAIR_HOME}/current-session.json"
AGENT_HOME="${HOME}/.blackroad-agents"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Start pair programming session
start_pair() {
    local agent=${1:-octavia}
    
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🤖 Starting Pair Programming Session     ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if session already active
    if [[ -f "$SESSION_FILE" ]]; then
        echo -e "${YELLOW}Active session detected!${NC}"
        echo -ne "${CYAN}End current session and start new? [y/N]:${NC} "
        read -r response
        if [[ ${response:l} != "y" ]]; then
            echo -e "${YELLOW}Keeping current session${NC}"
            return 0
        fi
        stop_pair
    fi
    
    mkdir -p "$PAIR_HOME"
    
    echo -e "${GREEN}Pairing with:${NC} ${agent}"
    echo -e "${GREEN}Working directory:${NC} $(pwd)"
    echo ""
    
    # Create session
    cat > "$SESSION_FILE" <<EOF
{
  "agent": "$agent",
  "start_time": $(date +%s),
  "working_dir": "$(pwd)",
  "files_touched": [],
  "interactions": 0
}
EOF
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Session Active! Commands:                    ║${NC}"
    echo -e "${CYAN}║                                               ║${NC}"
    echo -e "${CYAN}║  br pair ask <question>  - Ask your pair      ║${NC}"
    echo -e "${CYAN}║  br pair review          - Review current file ║${NC}"
    echo -e "${CYAN}║  br pair suggest         - Get suggestions     ║${NC}"
    echo -e "${CYAN}║  br pair stop            - End session         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${GREEN}✓ Pair session started!${NC}"
    echo -e "${YELLOW}Tip: I'm watching your git changes and ready to help!${NC}"
}

# Ask the pair a question
ask_pair() {
    local question="$*"
    
    if [[ ! -f "$SESSION_FILE" ]]; then
        echo -e "${RED}No active pair session${NC}"
        echo "Start one with: br pair start [agent]"
        return 1
    fi
    
    if [[ -z "$question" ]]; then
        echo -e "${RED}Error: Question required${NC}"
        echo "Usage: br pair ask <question>"
        return 1
    fi
    
    local agent=$(jq -r '.agent' "$SESSION_FILE" 2>/dev/null || echo "octavia")
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     💬 Asking ${agent}...                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}You:${NC} $question"
    echo ""
    
    # Get current context
    local current_file=$(ls -t | head -1)
    local git_status=$(git status --short 2>/dev/null | head -5)
    
    # Build context
    local context="Working in: $(pwd)\n"
    if [[ -n "$git_status" ]]; then
        context+="Recent changes:\n$git_status\n\n"
    fi
    context+="Question: $question"
    
    # Simple response generator (in real version, this would call the agent)
    local agent_display=$(echo "${agent:0:1}" | tr '[:lower:]' '[:upper:]')${agent:1}
    echo -e "${GREEN}${agent_display}:${NC} "
    
    # Pattern-based responses
    if [[ "$question" =~ "how" ]] || [[ "$question" =~ "what" ]]; then
        echo "Great question! Let me help you with that."
        echo ""
        
        if [[ "$question" =~ "test" ]]; then
            echo "For testing, I recommend:"
            echo "1. Write tests that cover edge cases"
            echo "2. Use descriptive test names"
            echo "3. Keep tests isolated and fast"
            echo ""
            echo "Want me to generate a test template? Try: br pair suggest"
        elif [[ "$question" =~ "fix\|bug\|error" ]]; then
            echo "To debug this:"
            echo "1. Check the error message carefully"
            echo "2. Add console.log/print statements"
            echo "3. Use br git review to check recent changes"
            echo ""
            echo "Show me the error and I can help more specifically!"
        elif [[ "$question" =~ "refactor\|improve" ]]; then
            echo "Good instinct to refactor! Consider:"
            echo "1. Extract repeated code into functions"
            echo "2. Use meaningful variable names"
            echo "3. Keep functions small and focused"
            echo ""
            echo "Want a code review? Try: br pair review"
        else
            echo "I can help with that! Here's what I think:"
            echo ""
            echo "Based on your current context, you might want to:"
            echo "- Check the documentation: br snippet search <topic>"
            echo "- Review recent changes: br git status"
            echo "- Create a branch: br git branch"
        fi
    elif [[ "$question" =~ "should" ]] || [[ "$question" =~ "recommend" ]]; then
        echo "Based on best practices, I'd recommend:"
        echo ""
        echo "1. Keep your code DRY (Don't Repeat Yourself)"
        echo "2. Write tests alongside your code"
        echo "3. Commit frequently with good messages (br git commit)"
        echo ""
        echo "What specific area are you working on?"
    else
        echo "I'm here to help! I can assist with:"
        echo ""
        echo "- Code reviews (br pair review)"
        echo "- Writing tests"
        echo "- Debugging issues"
        echo "- Best practices"
        echo "- Git workflows (br git)"
        echo ""
        echo "Try asking: 'how do I test this?' or 'what should I refactor?'"
    fi
    
    echo ""
    
    # Update session
    if command -v jq &>/dev/null; then
        local interactions=$(jq '.interactions' "$SESSION_FILE")
        ((interactions++))
        jq ".interactions = $interactions" "$SESSION_FILE" > "${SESSION_FILE}.tmp" && mv "${SESSION_FILE}.tmp" "$SESSION_FILE"
    fi
}

# Review current file or changes
review_pair() {
    if [[ ! -f "$SESSION_FILE" ]]; then
        echo -e "${RED}No active pair session${NC}"
        echo "Start one with: br pair start"
        return 1
    fi
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     🔍 Code Review                            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check for uncommitted changes
    local changes=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ $changes -eq 0 ]]; then
        echo -e "${GREEN}✓ No uncommitted changes${NC}"
        echo ""
        echo "Everything looks clean! Start coding and I'll watch for issues."
        return 0
    fi
    
    echo -e "${YELLOW}Reviewing ${changes} file(s) with changes...${NC}"
    echo ""
    
    # Use the git review tool
    /Users/alexa/blackroad/tools/git-integration/br-git.sh review
    
    echo ""
    echo -e "${CYAN}Need help fixing something? Ask me: br pair ask 'how do I...?'${NC}"
}

# Get suggestions
suggest_pair() {
    if [[ ! -f "$SESSION_FILE" ]]; then
        echo -e "${RED}No active pair session${NC}"
        echo "Start one with: br pair start"
        return 1
    fi
    
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     💡 Smart Suggestions                      ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Analyze current context
    local git_status=$(git status --short 2>/dev/null)
    local branch=$(git branch --show-current 2>/dev/null)
    
    echo -e "${CYAN}Context Analysis:${NC}"
    echo "  Branch: ${branch:-main}"
    echo "  Working directory: $(pwd)"
    echo ""
    
    # Check what user is working on
    if echo "$git_status" | grep -q "test"; then
        echo -e "${GREEN}Working on tests?${NC} Great! Here's what I suggest:"
        echo ""
        echo "1. Cover edge cases and error conditions"
        echo "2. Use descriptive test names"
        echo "3. Run tests frequently: npm test / pytest / go test"
        echo ""
        echo "Need a test template? Check: br snippet search test"
        
    elif echo "$git_status" | grep -q ".md"; then
        echo -e "${GREEN}Working on documentation?${NC} Awesome! Suggestions:"
        echo ""
        echo "1. Include code examples"
        echo "2. Add a table of contents for long docs"
        echo "3. Keep it concise and scannable"
        echo ""
        echo "Lucidia is great for docs: br lucidia 'review my README'"
        
    elif [[ -n "$git_status" ]]; then
        echo -e "${GREEN}Active development detected!${NC} Suggestions:"
        echo ""
        echo "1. Commit frequently: br git commit"
        echo "2. Review before committing: br pair review"
        echo "3. Write tests as you go"
        echo "4. Save useful patterns: echo '<code>' | br snippet save <name>"
        echo ""
        
        # Suggest related snippets
        echo -e "${YELLOW}Relevant snippets:${NC}"
        /Users/alexa/blackroad/tools/snippet-manager/br-snippet.sh suggest
        
    else
        echo -e "${YELLOW}No active changes detected${NC}"
        echo ""
        echo "Ready to start? Try:"
        echo "  br git branch      - Create a feature branch"
        echo "  br snippet list    - Browse code snippets"
        echo "  br radar smart     - Analyze current context"
    fi
}

# Show session status
status_pair() {
    if [[ ! -f "$SESSION_FILE" ]]; then
        echo -e "${YELLOW}No active pair session${NC}"
        echo ""
        echo "Start one with: br pair start [agent]"
        return 0
    fi
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     📊 Pair Session Status                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    if command -v jq &>/dev/null; then
        local agent=$(jq -r '.agent' "$SESSION_FILE")
        local start=$(jq -r '.start_time' "$SESSION_FILE")
        local dir=$(jq -r '.working_dir' "$SESSION_FILE")
        local interactions=$(jq -r '.interactions' "$SESSION_FILE")
        
        local duration=$(($(date +%s) - start))
        local minutes=$((duration / 60))
        
        echo -e "${GREEN}Active Session:${NC}"
        echo "  Pair: ${agent}"
        echo "  Duration: ${minutes} minute(s)"
        echo "  Directory: ${dir}"
        echo "  Interactions: ${interactions}"
        echo ""
    fi
    
    echo -e "${CYAN}Available commands:${NC}"
    echo "  br pair ask <question>"
    echo "  br pair review"
    echo "  br pair suggest"
    echo "  br pair stop"
}

# Stop pair session
stop_pair() {
    if [[ ! -f "$SESSION_FILE" ]]; then
        echo -e "${YELLOW}No active pair session${NC}"
        return 0
    fi
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     👋 Ending Pair Session                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    if command -v jq &>/dev/null; then
        local agent=$(jq -r '.agent' "$SESSION_FILE")
        local start=$(jq -r '.start_time' "$SESSION_FILE")
        local interactions=$(jq -r '.interactions' "$SESSION_FILE")
        
        local duration=$(($(date +%s) - start))
        local minutes=$((duration / 60))
        
        echo -e "${GREEN}Session Summary:${NC}"
        echo "  Paired with: ${agent}"
        echo "  Duration: ${minutes} minute(s)"
        echo "  Interactions: ${interactions}"
        echo ""
    fi
    
    rm "$SESSION_FILE"
    
    echo -e "${GREEN}✓ Session ended${NC}"
    echo -e "${CYAN}Great work! Start again anytime with: br pair start${NC}"
}

# Help
show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR PAIR${NC}  ${DIM}AI pair programming in your terminal.${NC}"
  echo -e "  ${DIM}Octavia · Lucidia · Alice. Ship better code, faster.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  start [agent]                   ${NC} Start pair session (default: octavia)"
  echo -e "  ${AMBER}  ask <question>                  ${NC} Ask your AI pair a question"
  echo -e "  ${AMBER}  review                          ${NC} Review current diff before commit"
  echo -e "  ${AMBER}  suggest                         ${NC} Get context-aware code suggestions"
  echo -e "  ${AMBER}  status                          ${NC} Show active session"
  echo -e "  ${AMBER}  stop                            ${NC} End current session"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br pair start octavia${NC}"
  echo -e "  ${DIM}  br pair ask "how should I structure this auth module?"${NC}"
  echo -e "  ${DIM}  br pair review${NC}"
  echo -e "  ${DIM}  br pair suggest${NC}"
  echo -e ""
}
# Main dispatch
case ${1:-status} in
    start)
        start_pair "$2"
        ;;
    ask)
        shift
        ask_pair "$@"
        ;;
    review)
        review_pair
        ;;
    suggest|sug)
        suggest_pair
        ;;
    status)
        status_pair
        ;;
    stop|end)
        stop_pair
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
