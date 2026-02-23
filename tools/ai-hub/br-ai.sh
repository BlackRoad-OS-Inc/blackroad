#!/usr/bin/env zsh
# BR AI Hub — Unified AI gateway: ollama/openai/anthropic/gateway

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'
BOLD='\033[1m'
DB="$HOME/.blackroad/ai-hub.db"
GATEWAY="${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}"
OLLAMA="${BLACKROAD_OLLAMA_URL:-http://localhost:11434}"
OPENAI_KEY="${BLACKROAD_OPENAI_API_KEY:-}"
ANTHROPIC_KEY="${BLACKROAD_ANTHROPIC_API_KEY:-}"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS conversations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  model TEXT DEFAULT '',
  provider TEXT DEFAULT '',
  ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS models (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  provider TEXT NOT NULL,
  context_len INTEGER DEFAULT 4096,
  notes TEXT DEFAULT '',
  last_used TEXT DEFAULT NULL
);
CREATE TABLE IF NOT EXISTS usage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider TEXT NOT NULL,
  model TEXT NOT NULL,
  prompt_tokens INTEGER DEFAULT 0,
  completion_tokens INTEGER DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
SQL
  # Seed known models
  sqlite3 "$DB" <<'SQL'
INSERT OR IGNORE INTO models VALUES ('gpt-4o','GPT-4o','openai',128000,'Flagship','');
INSERT OR IGNORE INTO models VALUES ('gpt-4o-mini','GPT-4o Mini','openai',128000,'Fast/cheap','');
INSERT OR IGNORE INTO models VALUES ('gpt-3.5-turbo','GPT-3.5 Turbo','openai',16385,'Legacy fast','');
INSERT OR IGNORE INTO models VALUES ('claude-3-5-sonnet','Claude 3.5 Sonnet','anthropic',200000,'Best for code','');
INSERT OR IGNORE INTO models VALUES ('claude-3-haiku','Claude 3 Haiku','anthropic',200000,'Fast/cheap','');
INSERT OR IGNORE INTO models VALUES ('claude-opus-4','Claude Opus 4','anthropic',200000,'Most capable','');
INSERT OR IGNORE INTO models VALUES ('llama3.2','Llama 3.2 3B','ollama',128000,'Local fast','');
INSERT OR IGNORE INTO models VALUES ('qwen2.5:7b','Qwen 2.5 7B','ollama',128000,'Local general','');
INSERT OR IGNORE INTO models VALUES ('deepseek-r1:7b','DeepSeek-R1 7B','ollama',64000,'Local reasoning','');
INSERT OR IGNORE INTO models VALUES ('lucidia','Lucidia Custom','ollama',8192,'BlackRoad agent','');
SQL
}

detect_provider() {
  local model="$1"
  if [[ "$model" == gpt-* ]]; then echo "openai"
  elif [[ "$model" == claude-* ]]; then echo "anthropic"
  elif [[ "$model" == gateway ]]; then echo "gateway"
  else echo "ollama"
  fi
}

call_ollama() {
  local model="$1" prompt="$2" system="${3:-You are a helpful AI assistant.}"
  local payload
  payload=$(python3 -c "
import json, sys
print(json.dumps({
  'model': sys.argv[1],
  'prompt': sys.argv[2],
  'system': sys.argv[3],
  'stream': False
}))
" "$model" "$prompt" "$system")
  curl -s -X POST "$OLLAMA/api/generate" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('response', 'No response'))
except: print('Error: failed to parse response')
"
}

call_openai() {
  local model="$1" prompt="$2" system="${3:-You are a helpful AI assistant.}"
  [[ -z "$OPENAI_KEY" ]] && { echo "Error: BLACKROAD_OPENAI_API_KEY not set"; return 1; }
  local payload
  payload=$(python3 -c "
import json, sys
print(json.dumps({
  'model': sys.argv[1],
  'messages': [
    {'role': 'system', 'content': sys.argv[3]},
    {'role': 'user', 'content': sys.argv[2]}
  ]
}))
" "$model" "$prompt" "$system")
  curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Authorization: Bearer $OPENAI_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    if 'error' in d: print(f'Error: {d[\"error\"][\"message\"]}')
    else: print(d['choices'][0]['message']['content'])
except: print('Error: failed to parse response')
"
}

call_anthropic() {
  local model="$1" prompt="$2" system="${3:-You are a helpful AI assistant.}"
  [[ -z "$ANTHROPIC_KEY" ]] && { echo "Error: BLACKROAD_ANTHROPIC_API_KEY not set"; return 1; }
  local payload
  payload=$(python3 -c "
import json, sys
print(json.dumps({
  'model': sys.argv[1],
  'max_tokens': 4096,
  'system': sys.argv[3],
  'messages': [{'role': 'user', 'content': sys.argv[2]}]
}))
" "$model" "$prompt" "$system")
  curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "x-api-key: $ANTHROPIC_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    if 'error' in d: print(f'Error: {d[\"error\"][\"message\"]}')
    else: print(d['content'][0]['text'])
except: print('Error: failed to parse response')
"
}

call_gateway() {
  local model="$1" prompt="$2" system="${3:-You are a helpful AI assistant.}"
  local payload
  payload=$(python3 -c "
import json, sys
print(json.dumps({'model': sys.argv[1], 'prompt': sys.argv[2], 'system': sys.argv[3]}))
" "$model" "$prompt" "$system")
  curl -s -X POST "$GATEWAY/v1/generate" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('response', d.get('content', str(d))))
except: print('Error: gateway unavailable')
"
}

pick_best_model() {
  # Auto-detect best available ollama model
  local models
  models=$(curl -sf --max-time 3 "$OLLAMA/api/tags" | python3 -c \
    "import json,sys; ms=[m['name'] for m in json.load(sys.stdin).get('models',[])]; print('\n'.join(ms))" 2>/dev/null)
  for preferred in "qwen2.5:7b" "qwen2.5:3b" "llama3.2" "llama3.2:1b" "lucidia:latest" "tinyllama:latest"; do
    echo "$models" | grep -q "^${preferred}" && { echo "$preferred"; return; }
  done
  echo "$models" | head -1
}

cmd_ask() {
  local model="${BR_AI_MODEL:-}"
  [[ -z "$model" ]] && model=$(pick_best_model)
  [[ -z "$model" ]] && model="llama3.2"
  local system="You are a helpful AI assistant integrated with BlackRoad OS."
  local prompt=""
  # Parse flags
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -m|--model) model="$2"; shift 2 ;;
      -s|--system) system="$2"; shift 2 ;;
      *) prompt="$prompt $1"; shift ;;
    esac
  done
  prompt="${prompt## }"
  [[ -z "$prompt" ]] && { echo "Usage: br ai ask [-m model] <prompt>"; exit 1; }

  local provider; provider=$(detect_provider "$model")
  echo ""
  echo -e "${PURPLE}${BOLD}🤖 $model${NC} ${CYAN}(${provider})${NC}"
  echo ""

  local response=""
  case "$provider" in
    ollama)    response=$(call_ollama "$model" "$prompt" "$system") ;;
    openai)    response=$(call_openai "$model" "$prompt" "$system") ;;
    anthropic) response=$(call_anthropic "$model" "$prompt" "$system") ;;
    gateway)   response=$(call_gateway "$model" "$prompt" "$system") ;;
  esac

  echo "$response" | fold -s -w 80 | sed 's/^/  /'
  echo ""

  # Save conversation
  local session="default"
  sqlite3 "$DB" "INSERT INTO conversations (session,role,content,model,provider) VALUES ('$session','user','$(echo "$prompt" | sed "s/'/''/g")', '$model','$provider');"
  sqlite3 "$DB" "INSERT INTO conversations (session,role,content,model,provider) VALUES ('$session','assistant','$(echo "$response" | head -c 500 | sed "s/'/''/g")', '$model','$provider');"
  sqlite3 "$DB" "UPDATE models SET last_used=datetime('now') WHERE id='$model';"
}

cmd_code() {
  local model="${BR_AI_MODEL:-}"
  [[ -z "$model" ]] && model=$(pick_best_model)
  [[ -z "$model" ]] && model="llama3.2"
  local lang="general"
  local prompt=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -m|--model) model="$2"; shift 2 ;;
      -l|--lang) lang="$2"; shift 2 ;;
      *) prompt="$prompt $1"; shift ;;
    esac
  done
  prompt="${prompt## }"
  [[ -z "$prompt" ]] && { echo "Usage: br ai code [-m model] [-l lang] <prompt>"; exit 1; }
  local system="You are an expert $lang developer. Provide concise, working code. Format code in markdown code blocks."
  cmd_ask -m "$model" -s "$system" "$prompt"
}

cmd_review() {
  local model="${BR_AI_MODEL:-llama3.2}"
  local file=""
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -m|--model) model="$2"; shift 2 ;;
      *) file="$1"; shift ;;
    esac
  done
  [[ -z "$file" ]] && { echo "Usage: br ai review [-m model] <file>"; exit 1; }
  [[ ! -f "$file" ]] && { echo -e "${RED}✗ File not found: $file${NC}"; exit 1; }
  local content; content=$(cat "$file")
  local system="You are an expert code reviewer. Identify bugs, security issues, and improvements. Be concise."
  local prompt="Review this code and provide feedback:\n\n$content"
  cmd_ask -m "$model" -s "$system" "$prompt"
}

cmd_diff_review() {
  local model="${BR_AI_MODEL:-llama3.2}"
  local diff_content
  diff_content=$(git --no-pager diff 2>/dev/null || echo "No git diff available")
  [[ -z "$diff_content" ]] && { echo "No staged changes. Run: git add <files>"; exit 1; }
  local system="You are a code reviewer. Review this git diff and point out issues, bugs, or improvements concisely."
  cmd_ask -m "$model" -s "$system" "Review this diff:\n$diff_content"
}

cmd_models() {
  echo ""
  echo -e "${CYAN}${BOLD}🤖 Available Models${NC}"
  echo ""
  # Check ollama
  local ollama_models=""
  ollama_models=$(curl -s "$OLLAMA/api/tags" 2>/dev/null | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for m in d.get('models', []):
        print(m['name'])
except: pass
" 2>/dev/null)

  echo -e "  ${GREEN}Ollama (local):${NC}"
  if [[ -n "$ollama_models" ]]; then
    echo "$ollama_models" | while IFS= read -r m; do
      printf "    %-25s  ✓ available\n" "$m"
    done
  else
    echo "    (ollama not running)"
  fi
  echo ""
  echo -e "  ${BLUE}OpenAI:${NC}"
  sqlite3 "$DB" "SELECT id, name, context_len FROM models WHERE provider='openai';" | while IFS="|" read -r id nm ctx; do
    [[ -n "$OPENAI_KEY" ]] && avail="key set" || avail="no key"
    printf "    %-25s  ctx=%-7s  %s\n" "$nm" "${ctx}k" "$avail"
  done
  echo ""
  echo -e "  ${PURPLE}Anthropic:${NC}"
  sqlite3 "$DB" "SELECT id, name, context_len FROM models WHERE provider='anthropic';" | while IFS="|" read -r id nm ctx; do
    [[ -n "$ANTHROPIC_KEY" ]] && avail="key set" || avail="no key"
    printf "    %-25s  ctx=%-7s  %s\n" "$nm" "${ctx}k" "$avail"
  done
  echo ""
  echo -e "  ${YELLOW}Gateway ($GATEWAY):${NC}"
  local gw_ok
  gw_ok=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY/health" 2>/dev/null)
  [[ "$gw_ok" == "200" ]] && echo "    ✓ Gateway online" || echo "    ✗ Gateway offline"
  echo ""
}

cmd_chat() {
  local model="${1:-}"
  [[ -z "$model" ]] && model=$(pick_best_model)
  [[ -z "$model" ]] && model="llama3.2"
  local provider; provider=$(detect_provider "$model")
  echo ""
  echo -e "${PURPLE}${BOLD}💬 Chat with $model${NC} ${CYAN}(${provider})${NC}"
  echo -e "  ${YELLOW}Type 'exit' or Ctrl+C to quit${NC}"
  echo ""
  while true; do
    printf "${GREEN}you>  ${NC}"; read -r prompt
    [[ "$prompt" == "exit" || "$prompt" == "quit" ]] && break
    [[ -z "$prompt" ]] && continue
    printf "${PURPLE}ai>   ${NC}"
    local response=""
    case "$provider" in
      ollama)    response=$(call_ollama "$model" "$prompt") ;;
      openai)    response=$(call_openai "$model" "$prompt") ;;
      anthropic) response=$(call_anthropic "$model" "$prompt") ;;
      gateway)   response=$(call_gateway "$model" "$prompt") ;;
    esac
    echo "$response" | fold -s -w 72
    echo ""
  done
  echo -e "${CYAN}Goodbye!${NC}"
}

cmd_history() {
  local limit="${1:-20}"
  echo ""
  echo -e "${CYAN}${BOLD}📜 AI History${NC}"
  echo ""
  sqlite3 -separator "|" "$DB" "SELECT role, content, model, ts FROM conversations ORDER BY ts DESC LIMIT $limit;" | while IFS="|" read -r role content model ts; do
    local color="$CYAN"; [[ "$role" == "assistant" ]] && color="$PURPLE"
    printf "  ${color}%-12s${NC}  ${BLUE}%s${NC}  %s\n" "$role" "$model" "${ts:0:16}"
    echo "  ${content:0:80}"
    echo ""
  done
}

show_help() {
  echo ""
  echo -e "${PURPLE}${BOLD}br ai${NC} — Unified AI hub"
  echo ""
  echo -e "  ${GREEN}br ai ask [-m model] <prompt>${NC}      One-shot question"
  echo -e "  ${GREEN}br ai code [-m model] <prompt>${NC}     Code generation"
  echo -e "  ${GREEN}br ai review <file>${NC}                Code review a file"
  echo -e "  ${GREEN}br ai diff${NC}                         Review current git diff"
  echo -e "  ${GREEN}br ai chat [model]${NC}                 Interactive chat"
  echo -e "  ${GREEN}br ai models${NC}                       List available models"
  echo -e "  ${GREEN}br ai history${NC}                      Show conversation history"
  echo ""
  echo -e "  Providers: ${YELLOW}ollama${NC} (local) | ${BLUE}openai${NC} | ${PURPLE}anthropic${NC} | ${CYAN}gateway${NC}"
  echo -e "  Default model: ${YELLOW}llama3.2${NC} (set \$BR_AI_MODEL to override)"
  echo ""
  echo -e "  Examples:"
  echo -e "    ${CYAN}br ai ask 'What is a closure?'${NC}"
  echo -e "    ${CYAN}br ai ask -m gpt-4o 'Explain OAuth2'${NC}"
  echo -e "    ${CYAN}br ai code -l typescript 'Create a debounce function'${NC}"
  echo -e "    ${CYAN}br ai review src/auth.ts${NC}"
  echo -e "    ${CYAN}br ai chat qwen2.5:7b${NC}"
  echo ""
}

init_db
case "${1:-help}" in
  ask|query|q)  shift; cmd_ask "$@" ;;
  code|gen)     shift; cmd_code "$@" ;;
  review)       shift; cmd_review "$@" ;;
  diff)         cmd_diff_review ;;
  chat)         shift; cmd_chat "$@" ;;
  models|list)  cmd_models ;;
  history)      shift; cmd_history "$@" ;;
  help|-h)      show_help ;;
  *)            # Pass through as prompt: br ai "what is..."
                prompt="$*"; [[ -n "$prompt" ]] && cmd_ask "$prompt" || show_help ;;
esac
