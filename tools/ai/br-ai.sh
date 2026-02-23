#!/usr/bin/env zsh
# BR AI — Unified Ollama AI frontend
# br ai ask|file|diff|review|summarize|models|chat|code

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
DEFAULT_MODEL="${BR_AI_MODEL:-}"

# Pick best available model
pick_model() {
  if [[ -n "$DEFAULT_MODEL" ]]; then echo "$DEFAULT_MODEL"; return; fi
  local models
  models=$(curl -sf "${OLLAMA_URL}/api/tags" | python3 -c \
    "import json,sys; ms=[m['name'] for m in json.load(sys.stdin).get('models',[])]; print('\n'.join(ms))" 2>/dev/null)
  for preferred in "lucidia:latest" "llama3.2" "qwen2.5" "tinyllama"; do
    echo "$models" | grep -q "^${preferred}" && { echo "$preferred"; return; }
  done
  echo "$models" | head -1
}

# Stream a prompt to Ollama
ollama_ask() {
  local model="$1" prompt="$2" system="${3:-}"
  local payload
  if [[ -n "$system" ]]; then
    payload=$(python3 -c "import json; print(json.dumps({'model':'$model','prompt':$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$prompt"),'system':$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$system"),'stream':True}))")
  else
    payload=$(python3 -c "import json,sys; print(json.dumps({'model':'$model','prompt':sys.argv[1],'stream':True}))" "$prompt")
  fi

  curl -sf -X POST "${OLLAMA_URL}/api/generate" \
    -H "Content-Type: application/json" \
    -d "$payload" \
  | python3 -c "
import json,sys
for line in sys.stdin:
    try:
        d = json.loads(line)
        if d.get('response'): print(d['response'], end='', flush=True)
    except: pass
print()
"
}

header() {
  local model="$1"
  echo ""
  echo "  ${BOLD}${VIOLET}✦ BLACKROAD AI${NC}  ${DIM}model: ${model}${NC}"
  echo "  ${DIM}────────────────────────────────────────${NC}"
}

# br ai ask "question"
cmd_ask() {
  local q="$*"
  [[ -z "$q" ]] && { echo "  Usage: br ai ask <question>"; exit 1; }
  local model=$(pick_model)
  [[ -z "$model" ]] && { echo "  ${RED}✗ Ollama not running. Start with: ollama serve${NC}"; exit 1; }
  header "$model"
  echo "  ${CYAN}?${NC} $q"
  echo ""
  ollama_ask "$model" "$q" | sed 's/^/  /'
  echo ""
}

# br ai file <path> [prompt]
cmd_file() {
  local fpath="$1"; shift
  local prompt="${*:-Summarize this file. What does it do, what are the key parts?}"
  [[ -z "$fpath" || ! -f "$fpath" ]] && { echo "  ${RED}File not found: $fpath${NC}"; exit 1; }
  local model=$(pick_model)
  header "$model"
  echo "  ${CYAN}File:${NC} $fpath"
  echo "  ${CYAN}Ask:${NC}  $prompt"
  echo ""
  local content
  content=$(cat "$fpath" | head -300)
  local full_prompt="File: ${fpath}

Content:
${content}

---
${prompt}"
  ollama_ask "$model" "$full_prompt" "You are a code reviewer. Be concise and direct." | sed 's/^/  /'
  echo ""
}

# br ai diff [since-commit]
cmd_diff() {
  local ref="${1:-HEAD}"
  local model=$(pick_model)
  header "$model"
  echo "  ${CYAN}Reviewing diff${NC} ${DIM}($ref)${NC}…"
  echo ""
  local diff
  if [[ "$ref" == "HEAD" ]]; then
    diff=$(git --no-pager diff --staged 2>/dev/null || git --no-pager diff HEAD 2>/dev/null)
  else
    diff=$(git --no-pager diff "${ref}" 2>/dev/null)
  fi
  [[ -z "$diff" ]] && { echo "  ${DIM}No diff found.${NC}"; exit 0; }
  diff="${diff:0:8000}"  # cap at 8k chars
  local prompt="Review this git diff. Identify: bugs, security issues, improvements. Be concise.

${diff}"
  ollama_ask "$model" "$prompt" "You are an expert code reviewer. Flag only real issues." | sed 's/^/  /'
  echo ""
}

# br ai review <file>
cmd_review() {
  local fpath="$1"
  [[ -z "$fpath" || ! -f "$fpath" ]] && { echo "  ${RED}File not found: $fpath${NC}"; exit 1; }
  cmd_file "$fpath" "Review this code. Find bugs, security issues, and suggest improvements. Be specific."
}

# br ai commit — generate a commit message for staged changes
cmd_commit() {
  local model=$(pick_model)
  header "$model"
  echo "  ${CYAN}Generating commit message${NC}…"
  echo ""
  local diff
  diff=$(git --no-pager diff --staged 2>/dev/null | head -200)
  [[ -z "$diff" ]] && { echo "  ${DIM}No staged changes. Run git add first.${NC}"; exit 0; }
  local prompt="Generate a concise git commit message for this diff. Use conventional commits format (feat/fix/chore/docs/refactor). One line summary, optionally a short body. No markdown.

${diff}"
  local msg
  msg=$(ollama_ask "$model" "$prompt" "You generate clean git commit messages. Never use markdown code blocks.")
  echo "  ${GREEN}Suggested message:${NC}"
  echo ""
  echo "$msg" | sed 's/^/  /'
  echo ""
  echo "  ${DIM}Copy with:${NC} git commit -m \"<message>\""
  echo ""
}

# br ai summarize <file|dir>
cmd_summarize() {
  local target="${1:-.}"
  local model=$(pick_model)
  header "$model"
  if [[ -f "$target" ]]; then
    cmd_file "$target" "Give a 3-sentence summary: what this does, who uses it, what's notable."
  elif [[ -d "$target" ]]; then
    echo "  ${CYAN}Summarizing directory:${NC} $target"
    echo ""
    local files
    files=$(ls "$target" | head -30 | tr '\n' ' ')
    local readme=""
    [[ -f "$target/README.md" ]] && readme=$(head -50 "$target/README.md")
    local prompt="Directory: $target
Files: $files
README excerpt: $readme

Summarize what this project/directory does in 3-5 sentences."
    ollama_ask "$model" "$prompt" | sed 's/^/  /'
    echo ""
  else
    echo "  ${RED}Not a file or directory: $target${NC}"
  fi
}

# br ai models
cmd_models() {
  header "registry"
  echo "  ${CYAN}Available Ollama models:${NC}"
  echo ""
  curl -sf "${OLLAMA_URL}/api/tags" | python3 -c "
import json,sys
try:
  data = json.load(sys.stdin)
  for m in data.get('models', []):
    size = m.get('size', 0)
    gb = f'{size/1e9:.1f}GB' if size > 1e9 else f'{size/1e6:.0f}MB'
    print(f\"  {'  '}{m['name']:<30} {gb}\")
except Exception as e:
  print(f'  Error: {e}')
" 2>/dev/null || echo "  ${RED}Ollama offline${NC}"
  echo ""
  local cur=$(pick_model)
  echo "  ${DIM}Active model:${NC} ${AMBER}${cur}${NC}"
  echo "  ${DIM}Set default:${NC}  export BR_AI_MODEL=<name>"
  echo ""
}

# br ai chat [model] — interactive REPL
cmd_chat() {
  local model="${1:-$(pick_model)}"
  [[ -z "$model" ]] && { echo "  ${RED}Ollama offline${NC}"; exit 1; }
  header "$model"
  echo "  ${DIM}Interactive chat — type 'exit' or Ctrl-C to quit${NC}"
  echo ""
  while true; do
    printf "  ${AMBER}you${NC}  › "
    read -r input
    [[ "$input" == "exit" || "$input" == "quit" ]] && break
    [[ -z "$input" ]] && continue
    echo ""
    printf "  ${VIOLET}ai ${NC}  › "
    ollama_ask "$model" "$input" | sed 's/^/  /'
    echo ""
  done
  echo "  ${DIM}Session ended.${NC}"
}

# br ai code <task> — code generation
cmd_code() {
  local task="$*"
  [[ -z "$task" ]] && { echo "  Usage: br ai code <task description>"; exit 1; }
  local model=$(pick_model)
  header "$model"
  echo "  ${CYAN}Coding:${NC} $task"
  echo ""
  ollama_ask "$model" "$task" "You are an expert programmer. Provide clean, working code with brief explanation." | sed 's/^/  /'
  echo ""
}

show_help() {
  echo ""
  echo "  ${VIOLET}${BOLD}br ai${NC}  — Ollama AI frontend"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}ask <question>${NC}           Quick question"
  echo "    ${CYAN}file <path> [prompt]${NC}     Ask about a file"
  echo "    ${CYAN}review <path>${NC}            Code review a file"
  echo "    ${CYAN}diff [ref]${NC}               Review current git diff"
  echo "    ${CYAN}commit${NC}                   Generate commit message for staged changes"
  echo "    ${CYAN}summarize <path|dir>${NC}     Summarize file or directory"
  echo "    ${CYAN}code <task>${NC}              Generate code"
  echo "    ${CYAN}chat [model]${NC}             Interactive chat REPL"
  echo "    ${CYAN}models${NC}                   List available models"
  echo ""
  echo "  ${BOLD}Config:${NC}"
  echo "    ${DIM}export BR_AI_MODEL=llama3.2${NC}   set default model"
  echo "    ${DIM}export OLLAMA_URL=http://...${NC}   custom Ollama endpoint"
  echo ""
}

case "${1:-help}" in
  ask)       shift; cmd_ask "$@" ;;
  file)      shift; cmd_file "$@" ;;
  review)    shift; cmd_review "$@" ;;
  diff)      shift; cmd_diff "$@" ;;
  commit)    cmd_commit ;;
  summarize|sum) shift; cmd_summarize "$@" ;;
  code)      shift; cmd_code "$@" ;;
  chat)      cmd_chat "$2" ;;
  models|ls) cmd_models ;;
  help|*)    show_help ;;
esac
