#!/usr/bin/env zsh
# 🧠 BR LLM — Unified LLM Interface
# Query Claude, Codex, Ollama, or the BlackRoad Gateway from one command

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

LLM_DB="$HOME/.blackroad/llm.db"
OLLAMA_URL="${BLACKROAD_OLLAMA_URL:-http://localhost:11434}"
GATEWAY_URL="${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}"
DEFAULT_MODEL="${BLACKROAD_DEFAULT_MODEL:-qwen2.5:3b}"
HISTORY_FILE="$HOME/.blackroad/llm-history.jsonl"

# ── DB ───────────────────────────────────────────────────────────────
init_db() {
  mkdir -p "$(dirname "$LLM_DB")"
  sqlite3 "$LLM_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS queries (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  ts        INTEGER DEFAULT (strftime('%s','now')),
  model     TEXT,
  provider  TEXT,
  prompt    TEXT,
  response  TEXT,
  tokens    INTEGER DEFAULT 0,
  duration  REAL DEFAULT 0,
  session   TEXT
);
CREATE TABLE IF NOT EXISTS model_aliases (
  alias TEXT PRIMARY KEY,
  model TEXT,
  provider TEXT
);
SQL
  # Seed aliases
  sqlite3 "$LLM_DB" <<'SQL'
INSERT OR IGNORE INTO model_aliases VALUES('qwen','qwen2.5:3b','ollama');
INSERT OR IGNORE INTO model_aliases VALUES('qwen3b','qwen2.5:3b','ollama');
INSERT OR IGNORE INTO model_aliases VALUES('qwen7b','qwen2.5:7b','ollama');
INSERT OR IGNORE INTO model_aliases VALUES('llama','llama3.2:1b','ollama');
INSERT OR IGNORE INTO model_aliases VALUES('lucidia','lucidia:latest','ollama');
INSERT OR IGNORE INTO model_aliases VALUES('tiny','tinyllama:latest','ollama');
INSERT OR IGNORE INTO model_aliases VALUES('fast','qwen2.5:1.5b','ollama');
INSERT OR IGNORE INTO model_aliases VALUES('claude','claude-3-5-sonnet-latest','gateway');
INSERT OR IGNORE INTO model_aliases VALUES('sonnet','claude-3-5-sonnet-latest','gateway');
INSERT OR IGNORE INTO model_aliases VALUES('haiku','claude-3-haiku-20240307','gateway');
INSERT OR IGNORE INTO model_aliases VALUES('codex','gpt-4o-mini','gateway');
INSERT OR IGNORE INTO model_aliases VALUES('gpt4','gpt-4o','gateway');
SQL
}

# ── resolve model/provider ────────────────────────────────────────────
resolve_model() {
  local input=$1
  local row=$(sqlite3 "$LLM_DB" "SELECT model,provider FROM model_aliases WHERE alias='$input';" 2>/dev/null)
  if [[ -n "$row" ]]; then
    echo "$row"
  else
    # Auto-detect: if it has : it's probably ollama, otherwise gateway
    if [[ "$input" == *:* ]]; then
      echo "$input|ollama"
    else
      echo "$input|gateway"
    fi
  fi
}

# ── ollama query ──────────────────────────────────────────────────────
query_ollama() {
  local model=$1
  local prompt=$2
  local system=${3:-"You are a helpful BlackRoad OS assistant."}
  local stream=${4:-false}

  local payload
  payload=$(python3 -c "
import json
print(json.dumps({
  'model': '$model',
  'prompt': '''$prompt''',
  'system': '''$system''',
  'stream': False
}))
")

  local start_ts=$(date +%s%3N)
  local response
  response=$(curl -sf -X POST "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null)
  local curl_rc=$?
  local end_ts=$(date +%s%3N)
  local duration=$(python3 -c "print(($end_ts - $start_ts) / 1000.0)" 2>/dev/null)

  if [[ $curl_rc -ne 0 || -z "$response" ]]; then
    echo -e "${RED}✗ Ollama unavailable at $OLLAMA_URL${NC}" >&2
    echo -e "${DIM}  Start with: ollama serve${NC}" >&2
    return 1
  fi

  echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('response', ''))
" 2>/dev/null
}

# ── gateway query ─────────────────────────────────────────────────────
query_gateway() {
  local model=$1
  local prompt=$2
  local system=${3:-"You are a helpful BlackRoad OS assistant."}

  local payload
  payload=$(python3 -c "
import json
print(json.dumps({
  'model': '$model',
  'messages': [
    {'role': 'system', 'content': '''$system'''},
    {'role': 'user', 'content': '''$prompt'''}
  ]
}))
")

  local response
  response=$(curl -sf -X POST "$GATEWAY_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null)

  if [[ $? -ne 0 || -z "$response" ]]; then
    echo -e "${RED}✗ Gateway unavailable at $GATEWAY_URL${NC}" >&2
    echo -e "${DIM}  Start with: br gateway start${NC}" >&2
    return 1
  fi

  echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
choices = data.get('choices', [])
if choices:
    print(choices[0].get('message', {}).get('content', ''))
else:
    print(data.get('error', {}).get('message', 'No response'))
" 2>/dev/null
}

# ── stream to terminal ────────────────────────────────────────────────
query_stream() {
  local model=$1
  local prompt=$2
  local system=${3:-"You are a helpful BlackRoad OS assistant."}

  echo -e "${DIM}Streaming from $model...${NC}"
  curl -sf -X POST "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$model\",\"prompt\":$(echo "$prompt" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))'),\"system\":$(echo "$system" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))'),\"stream\":true}" 2>/dev/null | \
  python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        token = d.get('response', '')
        if token:
            print(token, end='', flush=True)
        if d.get('done'):
            print()
            break
    except:
        pass
"
}

# ── commands ─────────────────────────────────────────────────────────

cmd_ask() {
  init_db
  local model_alias=${1:-lucidia}
  shift
  local prompt="$*"
  local system="${BLACKROAD_SYSTEM_PROMPT:-You are Lucidia, a helpful BlackRoad OS AI assistant. Be concise and direct.}"

  if [[ -z "$prompt" ]]; then
    echo -e "${CYAN}Prompt:${NC} "
    prompt=$(cat)
  fi

  # Resolve model
  local resolved=$(resolve_model "$model_alias")
  local model=$(echo "$resolved" | cut -d'|' -f1)
  local provider=$(echo "$resolved" | cut -d'|' -f2)

  echo -e ""
  echo -e "  ${PURPLE}▸ $model_alias${NC}  ${DIM}($model via $provider)${NC}"
  echo -e "  ${DIM}────────────────────────────────────────${NC}"

  local start=$(date +%s%3N)
  local response

  case "$provider" in
    ollama)  response=$(query_ollama "$model" "$prompt" "$system") ;;
    gateway) response=$(query_gateway "$model" "$prompt" "$system") ;;
    *)       response=$(query_ollama "$model" "$prompt" "$system") ;;
  esac

  local rc=$?
  local end=$(date +%s%3N)
  local dur=$(python3 -c "print(f'{($end-$start)/1000:.1f}s')" 2>/dev/null)

  if [[ $rc -ne 0 ]]; then exit 1; fi

  echo -e "$response"
  echo -e ""
  echo -e "  ${DIM}$dur${NC}"

  # Log to DB
  sqlite3 "$LLM_DB" "INSERT INTO queries(model,provider,prompt,response,duration) VALUES('$model','$provider',$(echo "$prompt" | python3 -c 'import sys; print(repr(sys.stdin.read().strip()))' 2>/dev/null || echo "''"),$(echo "$response" | python3 -c 'import sys; print(repr(sys.stdin.read().strip()))' 2>/dev/null || echo "''"),$((end-start)));" 2>/dev/null
}

cmd_stream() {
  init_db
  local model_alias=${1:-lucidia}
  shift
  local prompt="$*"
  if [[ -z "$prompt" ]]; then
    echo -e "${CYAN}Prompt (streaming):${NC} "
    prompt=$(cat)
  fi
  local resolved=$(resolve_model "$model_alias")
  local model=$(echo "$resolved" | cut -d'|' -f1)
  echo -e "\n  ${PURPLE}▸ $model_alias${NC}  ${DIM}(stream)${NC}\n"
  query_stream "$model" "$prompt"
  echo -e ""
}

cmd_models() {
  init_db
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🧠 Available Models${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
  echo -e "  ${YELLOW}Ollama (local):${NC}"
  curl -sf "$OLLAMA_URL/api/tags" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for m in data.get('models', []):
        name = m.get('name','?')
        size = m.get('size', 0)
        size_str = f'{size/1e9:.1f}GB'
        print(f'  \033[32m●\033[0m {name:<35} {size_str}')
except:
    print('  (ollama not available)')
" 2>/dev/null || echo -e "  ${DIM}(ollama not running)${NC}"

  echo -e ""
  echo -e "  ${YELLOW}Aliases:${NC}"
  sqlite3 "$LLM_DB" "SELECT alias, model, provider FROM model_aliases ORDER BY provider, alias;" | while IFS='|' read alias model prov; do
    echo -e "  ${CYAN}$alias${NC}  →  $model  ${DIM}via $prov${NC}"
  done
  echo -e ""
}

cmd_history() {
  init_db
  local n=${1:-10}
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🧠 Query History (last $n)${NC}"
  echo -e "  ${DIM}─────────────────────────────────────────────────────────────${NC}"
  sqlite3 "$LLM_DB" "SELECT datetime(ts,'unixepoch','localtime'), model, SUBSTR(prompt,1,50), ROUND(duration/1000.0,1) FROM queries ORDER BY id DESC LIMIT $n;" | while IFS='|' read ts model prompt dur; do
    echo -e "  ${DIM}$ts${NC}  ${PURPLE}$model${NC}  ${DIM}${dur}s${NC}"
    echo -e "  ${DIM}  Q: $prompt${NC}"
  done
  echo -e ""
}

cmd_compare() {
  init_db
  local prompt="$*"
  if [[ -z "$prompt" ]]; then echo -e "${RED}Usage: br llm compare <prompt>${NC}"; exit 1; fi

  echo -e ""
  echo -e "  ${CYAN}${BOLD}🧠 Comparing Models${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────${NC}"
  echo -e "  ${DIM}Prompt: $prompt${NC}"
  echo -e ""

  for alias in fast lucidia qwen; do
    local resolved=$(resolve_model "$alias")
    local model=$(echo "$resolved" | cut -d'|' -f1)
    local provider=$(echo "$resolved" | cut -d'|' -f2)
    echo -e "  ${PURPLE}▸ $alias${NC}  ${DIM}($model)${NC}"
    local start=$(date +%s%3N)
    local resp
    case "$provider" in
      ollama)  resp=$(query_ollama "$model" "$prompt" "" 2>/dev/null) ;;
      gateway) resp=$(query_gateway "$model" "$prompt" "" 2>/dev/null) ;;
    esac
    local end=$(date +%s%3N)
    local dur=$(python3 -c "print(f'{($end-$start)/1000:.1f}s')" 2>/dev/null)
    if [[ -n "$resp" ]]; then
      echo -e "${resp:0:200}"
      echo -e "  ${DIM}$dur${NC}"
    else
      echo -e "  ${RED}(no response)${NC}"
    fi
    echo -e ""
  done
}

cmd_alias() {
  init_db
  local alias=$1
  local model=$2
  local provider=${3:-ollama}
  if [[ -z "$alias" || -z "$model" ]]; then
    echo -e "${RED}Usage: br llm alias <alias> <model> [ollama|gateway]${NC}"; exit 1
  fi
  sqlite3 "$LLM_DB" "INSERT OR REPLACE INTO model_aliases VALUES('$alias','$model','$provider');"
  echo -e "${GREEN}✓ Alias: $alias → $model ($provider)${NC}"
}

cmd_help() {
  echo -e ""
  echo -e "  ${CYAN}${BOLD}🧠 BR LLM${NC}  ${DIM}Unified LLM Interface${NC}"
  echo -e "  ${DIM}Query Claude, Codex, Ollama, or Gateway from one command${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br llm <model|command> [prompt]"
  echo -e ""
  echo -e "  ${YELLOW}QUERY${NC}"
  echo -e "  ${CYAN}  ask <model> <prompt>${NC}         Ask a model (default: lucidia)"
  echo -e "  ${CYAN}  <model> <prompt>${NC}             Shortcut: br llm qwen \"hello\""
  echo -e "  ${CYAN}  stream <model> <prompt>${NC}      Stream tokens to terminal"
  echo -e "  ${CYAN}  compare <prompt>${NC}             Run same prompt on 3 models"
  echo -e ""
  echo -e "  ${YELLOW}MODELS${NC}"
  echo -e "  ${CYAN}  models${NC}                       List available models + aliases"
  echo -e "  ${CYAN}  alias <name> <model> [prov]${NC}  Add model alias"
  echo -e "  ${CYAN}  history [n]${NC}                  Query history"
  echo -e ""
  echo -e "  ${YELLOW}ALIASES (use these instead of full model names)${NC}"
  echo -e "  ${DIM}  lucidia   fast   qwen   llama   tiny${NC}  ${DIM}(ollama/local)${NC}"
  echo -e "  ${DIM}  claude   sonnet  haiku  codex   gpt4${NC}  ${DIM}(gateway)${NC}"
  echo -e ""
  echo -e "  ${YELLOW}EXAMPLES${NC}"
  echo -e "  ${DIM}  br llm lucidia \"explain BRAT auth in one sentence\"${NC}"
  echo -e "  ${DIM}  br llm fast \"what does br chain do?\"${NC}"
  echo -e "  ${DIM}  br llm stream qwen \"write a haiku about hash chains\"${NC}"
  echo -e "  ${DIM}  br llm compare \"what is BRAT?\"${NC}"
  echo -e ""
}

# ── dispatch ──────────────────────────────────────────────────────────
init_db

case "${1:-help}" in
  ask|query|q)            cmd_ask "$2" "${@:3}" ;;
  stream|s)               cmd_stream "$2" "${@:3}" ;;
  models|list|ls)         cmd_models ;;
  history|log|h)          cmd_history "${2:-10}" ;;
  compare|vs|bench)       cmd_compare "${@:2}" ;;
  alias|add)              cmd_alias "$2" "$3" "$4" ;;
  help|--help|-h)         cmd_help ;;
  # shortcut: br llm <model_alias> <prompt...>
  lucidia|fast|qwen|qwen3b|qwen7b|llama|tiny|claude|sonnet|haiku|codex|gpt4)
    cmd_ask "$1" "${@:2}" ;;
  *)
    # Try as model alias
    local exists=$(sqlite3 "$LLM_DB" "SELECT alias FROM model_aliases WHERE alias='$1';" 2>/dev/null)
    if [[ -n "$exists" ]]; then cmd_ask "$1" "${@:2}"
    else echo -e "${RED}✗ Unknown: $1${NC}"; cmd_help; exit 1; fi ;;
esac
