#!/bin/bash
# BlackRoad Local Coding Assistant
# Ollama-powered coding environment integrated with BlackRoad infrastructure

set -e

VERSION="1.0.0"
OLLAMA_MODEL="${BR_CODE_MODEL:-qwen2.5-coder:7b}"
OLLAMA_API="http://localhost:11434"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Header
clear
cat <<'HEADER'
╔════════════════════════════════════════════════════════╗
║   🦙 BlackRoad Local Coding Assistant v1.0.0          ║
║   Powered by Ollama + qwen2.5-coder                  ║
╚════════════════════════════════════════════════════════╝
HEADER

# Check if Ollama is running
check_ollama() {
  if ! curl -s "$OLLAMA_API/api/tags" > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Ollama is not running"
    echo -e "${YELLOW}Start it with:${NC} ollama serve &"
    exit 1
  fi
  echo -e "${GREEN}✓${NC} Ollama is running"
}

# Check if model is available
check_model() {
  if ! ollama list 2>/dev/null | grep -q "$OLLAMA_MODEL"; then
    echo -e "${YELLOW}⚠${NC} Model $OLLAMA_MODEL not found"
    read -p "Pull it now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${CYAN}Pulling $OLLAMA_MODEL...${NC}"
      ollama pull "$OLLAMA_MODEL"
    else
      exit 1
    fi
  fi
  echo -e "${GREEN}✓${NC} Model $OLLAMA_MODEL is ready"
}

# Log to memory system if available
log_to_memory() {
  local action="$1"
  local details="$2"
  if [ -f "$HOME/memory-system.sh" ]; then
    "$HOME/memory-system.sh" log "$action" "br-code-assistant" "$details" "ai,coding,ollama" 2>/dev/null || true
  fi
}

# Search codex for existing solutions
search_codex() {
  local query="$1"
  if [ -f "$HOME/blackroad-codex-search.py" ]; then
    echo -e "${CYAN}Searching codex for: $query${NC}"
    python3 "$HOME/blackroad-codex-search.py" "$query" 2>/dev/null | head -20 || true
  fi
}

# Main menu
show_menu() {
  echo ""
  echo -e "${BLUE}📋 Commands:${NC}"
  echo "  1. 💬 Chat Mode - Interactive coding session"
  echo "  2. 🔧 Task Mode - Execute specific coding task"
  echo "  3. 🔍 Analyze - Analyze files/directories"
  echo "  4. 🧪 Review - Code review mode"
  echo "  5. 📚 Codex Search - Search existing solutions"
  echo "  6. 🤖 Aider Mode - Agentic pair programming (if installed)"
  echo "  7. ⚙️  Settings - Configure model/options"
  echo "  0. ← Exit"
  echo ""
}

# Interactive chat mode
chat_mode() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  💬 CHAT MODE - Interactive Coding Session           ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Type your coding question or task. Type 'exit' to return."
  echo ""
  
  log_to_memory "start_chat" "model=$OLLAMA_MODEL"
  
  # System prompt for coding assistant
  local SYSTEM_PROMPT='You are a local AI coding assistant running on Ollama.
You have full terminal access and can:
- read and write project files
- generate, modify, and explain code
- run tests and debugging instructions
- follow multi-step task instructions

Your goal is to help the user with real programming tasks.

CONSTRAINTS:
1. Do not ask for cloud APIs — run everything locally using Ollama CLI.
2. Only operate within the current project directory.
3. If tests exist, run them and report outcomes.
4. For refactors, explain before making changes.
5. If instructions are ambiguous, ask a clarifying question.
6. Safety first — avoid destructive actions unless explicitly confirmed.

COMMAND RULES:
- To create or modify files, output a diff patch.
- To run shell commands, wrap the command in backticks: `command`
- To show code examples, wrap them in proper language tags (```python, ```js, etc.)

Current project: '"$(pwd)"'
'
  
  # Start interactive session
  echo "$SYSTEM_PROMPT" | ollama run "$OLLAMA_MODEL" 2>/dev/null || echo -e "${RED}Failed to start chat${NC}"
}

# Task execution mode
task_mode() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  🔧 TASK MODE - Execute Coding Task                  ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
  read -p "Describe your coding task: " TASK
  
  if [ -z "$TASK" ]; then
    echo -e "${RED}No task provided${NC}"
    return
  fi
  
  echo -e "${CYAN}Searching codex first...${NC}"
  search_codex "$TASK"
  
  echo ""
  echo -e "${CYAN}Executing task with $OLLAMA_MODEL...${NC}"
  echo ""
  
  local PROMPT="SYSTEM: You are a local coding assistant. Current directory: $(pwd)

USER TASK: $TASK

Provide:
1. Step-by-step plan
2. Code changes (as diffs if modifying existing files)
3. Commands to run
4. Testing instructions"

  echo "$PROMPT" | ollama run "$OLLAMA_MODEL"
  
  log_to_memory "execute_task" "task=$TASK"
}

# Analyze files/directories
analyze_mode() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  🔍 ANALYZE MODE - Code Analysis                     ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
  read -p "Path to analyze (file or directory): " TARGET
  
  if [ ! -e "$TARGET" ]; then
    echo -e "${RED}Path does not exist: $TARGET${NC}"
    return
  fi
  
  echo -e "${CYAN}Analyzing $TARGET...${NC}"
  echo ""
  
  local CONTENT=""
  if [ -f "$TARGET" ]; then
    CONTENT=$(cat "$TARGET")
  else
    CONTENT=$(find "$TARGET" -type f -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" 2>/dev/null | head -20 | xargs cat 2>/dev/null || echo "No code files found")
  fi
  
  local PROMPT="SYSTEM: You are a code analysis assistant.

TASK: Analyze the following code and provide:
1. Architecture overview
2. Key functions/components
3. Potential issues or improvements
4. Testing suggestions

CODE:
$CONTENT"

  echo "$PROMPT" | ollama run "$OLLAMA_MODEL"
  
  log_to_memory "analyze" "target=$TARGET"
}

# Code review mode
review_mode() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  🧪 REVIEW MODE - Code Review                        ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
  read -p "File to review: " FILE
  
  if [ ! -f "$FILE" ]; then
    echo -e "${RED}File does not exist: $FILE${NC}"
    return
  fi
  
  echo -e "${CYAN}Reviewing $FILE...${NC}"
  echo ""
  
  local CONTENT=$(cat "$FILE")
  local PROMPT="SYSTEM: You are a code review assistant focused on quality.

TASK: Review the following code and identify:
1. Bugs or logic errors
2. Security vulnerabilities
3. Performance issues
4. Best practice violations
5. Suggestions for improvement

Be concise and actionable.

CODE:
$CONTENT"

  echo "$PROMPT" | ollama run "$OLLAMA_MODEL"
  
  log_to_memory "review" "file=$FILE"
}

# Codex search
codex_search_mode() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  📚 CODEX SEARCH - Find Existing Solutions           ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
  read -p "Search query: " QUERY
  
  if [ -z "$QUERY" ]; then
    echo -e "${RED}No query provided${NC}"
    return
  fi
  
  search_codex "$QUERY"
  
  read -p "Press Enter to continue..."
}

# Aider mode (if installed)
aider_mode() {
  if ! command -v aider &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Aider is not installed"
    echo ""
    echo "Install with: pip install aider-chat"
    echo ""
    read -p "Install now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${CYAN}Installing aider-chat...${NC}"
      pip3 install aider-chat
    else
      return
    fi
  fi
  
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  🤖 AIDER MODE - Agentic Pair Programming            ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Starting Aider with Ollama model: $OLLAMA_MODEL"
  echo ""
  
  log_to_memory "start_aider" "model=$OLLAMA_MODEL"
  
  # Configure Aider to use Ollama
  export OLLAMA_API_BASE="$OLLAMA_API"
  aider --model "ollama/$OLLAMA_MODEL"
}

# Settings
settings_mode() {
  echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  ⚙️  SETTINGS                                         ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Current model: $OLLAMA_MODEL"
  echo ""
  echo "Available models:"
  ollama list
  echo ""
  read -p "Change model? (leave blank to keep current): " NEW_MODEL
  
  if [ -n "$NEW_MODEL" ]; then
    export BR_CODE_MODEL="$NEW_MODEL"
    echo -e "${GREEN}✓${NC} Model changed to $NEW_MODEL (for this session)"
    echo "To make permanent, add to ~/.zshrc:"
    echo "  export BR_CODE_MODEL=\"$NEW_MODEL\""
  fi
  
  read -p "Press Enter to continue..."
}

# Main loop
main() {
  check_ollama
  check_model
  
  while true; do
    show_menu
    read -p "Select option: " choice
    
    case $choice in
      1) chat_mode ;;
      2) task_mode ;;
      3) analyze_mode ;;
      4) review_mode ;;
      5) codex_search_mode ;;
      6) aider_mode ;;
      7) settings_mode ;;
      0) 
        echo -e "${GREEN}Goodbye!${NC}"
        log_to_memory "exit" "session_end"
        exit 0
        ;;
      *) 
        echo -e "${RED}Invalid option${NC}"
        sleep 1
        ;;
    esac
  done
}

# Check for direct invocation with arguments
if [ $# -gt 0 ]; then
  case "$1" in
    chat)
      check_ollama
      check_model
      chat_mode
      ;;
    task)
      check_ollama
      check_model
      shift
      TASK="$*"
      task_mode
      ;;
    analyze)
      check_ollama
      check_model
      TARGET="$2"
      analyze_mode
      ;;
    review)
      check_ollama
      check_model
      FILE="$2"
      review_mode
      ;;
    search)
      shift
      QUERY="$*"
      search_codex "$QUERY"
      ;;
    aider)
      check_ollama
      check_model
      aider_mode
      ;;
    --help|-h)
      echo "BlackRoad Local Coding Assistant"
      echo ""
      echo "Usage:"
      echo "  br-code-assistant           Interactive menu"
      echo "  br-code-assistant chat      Start chat mode"
      echo "  br-code-assistant task <description>"
      echo "  br-code-assistant analyze <path>"
      echo "  br-code-assistant review <file>"
      echo "  br-code-assistant search <query>"
      echo "  br-code-assistant aider     Start Aider"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown command: $1${NC}"
      echo "Run 'br-code-assistant --help' for usage"
      exit 1
      ;;
  esac
else
  main
fi
