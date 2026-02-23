#!/usr/bin/env zsh
# BR Agents — live agent roster, status, spawn, task dispatch
# br agents list|status|spawn|wake|task|kill|logs|models

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
AGENTS_DIR="$BR_ROOT/agents"
ACTIVE_DIR="$AGENTS_DIR/active"
IDLE_DIR="$AGENTS_DIR/idle"
MANIFEST="$AGENTS_DIR/manifest.json"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"

# ── Helpers ────────────────────────────────────────────────────────────────────

ollama_ok() { curl -sf --max-time 1 "$OLLAMA_URL/api/tags" &>/dev/null; }

pick_model() {
  local preferred=("tinyllama:latest" "llama3.2:1b" "qwen2.5:1.5b" "llama3.2:3b")
  local available
  available=$(curl -sf --max-time 3 "$OLLAMA_URL/api/tags" | python3 -c "
import json,sys
models = [m['name'] for m in json.load(sys.stdin).get('models',[])]
print('\n'.join(models))
" 2>/dev/null)
  for m in "${preferred[@]}"; do
    echo "$available" | grep -qx "$m" && { echo "$m"; return; }
  done
  echo "$available" | head -1
}

agent_color() {
  case "$1" in
    LUCIDIA)  echo "$VIOLET" ;;
    ALICE)    echo "$GREEN"  ;;
    OCTAVIA)  echo "$CYAN"   ;;
    CIPHER)   echo "$RED"    ;;
    ARIA)     echo "$PINK"   ;;
    SHELLFISH) echo "$AMBER" ;;
    *)        echo "$YELLOW" ;;
  esac
}

agent_icon() {
  case "$1" in
    LUCIDIA)  echo "🌀" ;;
    ALICE)    echo "🚪" ;;
    OCTAVIA)  echo "⚡" ;;
    CIPHER)   echo "🔐" ;;
    ARIA)     echo "🎨" ;;
    SHELLFISH) echo "🐚" ;;
    *)        echo "🤖" ;;
  esac
}

# ── Commands ───────────────────────────────────────────────────────────────────

cmd_list() {
  echo ""
  echo "  ${BOLD}${PINK}◈ BLACKROAD AGENTS${NC}  ${DIM}live roster${NC}"
  echo "  ${DIM}────────────────────────────────────────────────────────${NC}"
  echo ""

  # Named agents from active dir
  local any=0
  for f in "$ACTIVE_DIR"/*.json; do
    [[ ! -f "$f" ]] && continue
    any=1
    python3 -c "
import json
d = json.load(open('$f'))
name   = d.get('name','?')
status = d.get('status','?')
model  = d.get('model','?')
task   = d.get('current_task') or ''
ts     = d.get('updated_at','')[:16].replace('T',' ')
pid    = d.get('pid', '')
host   = d.get('host','local')
scol = '\033[32m' if status in ('idle','active') else '\033[33m' if status == 'busy' else '\033[31m'
icon = {'LUCIDIA':'🌀','ALICE':'🚪','OCTAVIA':'⚡','CIPHER':'🔐','ARIA':'🎨','SHELLFISH':'🐚'}.get(name,'🤖')
print(f'  {icon}  \033[1m{name:<12}\033[0m  {scol}{status:<8}\033[0m  \033[2m{model:<20}\033[0m  \033[2mpid:{pid}  {ts}\033[0m')
if task: print(f'       \033[33m▸ {task[:70]}\033[0m')
"
  done

  [[ "$any" -eq 0 ]] && echo "  ${DIM}No active agents — use 'br agents spawn <NAME>' to wake one${NC}"

  # Idle agents
  local idle_count=$(ls "$IDLE_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
  [[ "$idle_count" -gt 0 ]] && echo "" && echo "  ${DIM}$idle_count agent(s) in idle pool${NC}"

  echo ""

  # Manifest summary
  if [[ -f "$MANIFEST" ]]; then
    python3 -c "
import json
d = json.load(open('$MANIFEST'))
total = d.get('total_agents', 0)
dist  = d.get('task_distribution', {})
print(f'  \033[2mTotal fleet: {total:,}  |  ', end='')
parts = [f'{k}: {v:,}' for k,v in list(dist.items())[:4]]
print('  '.join(parts) + '\033[0m')
" 2>/dev/null
  fi
  echo ""
}

cmd_status() {
  local name="${1:u}"  # uppercase
  [[ -z "$name" ]] && { cmd_list; return; }

  local f="$ACTIVE_DIR/${name}.json"
  [[ ! -f "$f" ]] && { echo "  ${RED}Agent $name not found in active roster${NC}"; return 1; }

  echo ""
  local icon=$(agent_icon "$name")
  local col=$(agent_color "$name")
  echo "  ${col}${BOLD}$icon $name${NC}"
  echo "  ${DIM}────────────────────────${NC}"
  python3 -c "
import json
d = json.load(open('$f'))
for k,v in d.items():
    print(f'  \033[2m{k:<16}\033[0m \033[1m{v}\033[0m')
"
  echo ""
}

cmd_spawn() {
  local name="${1:u}"
  [[ -z "$name" ]] && { echo "  Usage: br agents spawn <NAME> [model]"; return 1; }

  local model="${2:-}"
  if [[ -z "$model" ]]; then
    ollama_ok || { echo "  ${RED}Ollama not running${NC}  →  start Ollama first"; return 1; }
    model=$(pick_model)
  fi

  local f="$ACTIVE_DIR/${name}.json"
  local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local icon=$(agent_icon "$name")
  local col=$(agent_color "$name")

  echo ""
  echo "  ${col}${BOLD}$icon Spawning $name…${NC}  ${DIM}model: $model${NC}"

  python3 -c "
import json, datetime
f = '$f'
ts = '$ts'
name = '$name'
model = '$model'
entry = {
  'name': name,
  'model': model,
  'pid': None,
  'status': 'idle',
  'host': 'local',
  'endpoint': 'http://localhost:11434',
  'current_task': None,
  'started_at': ts,
  'updated_at': ts
}
import json
with open(f, 'w') as fp:
    json.dump(entry, fp, indent=2)
print(f'  \033[32m✓\033[0m Registered {name}')
"

  # Write wake thought via Ollama
  if ollama_ok; then
    local prompt="You are $name, a BlackRoad OS AI agent. You've just been spawned. State your name, purpose in one sentence, and readiness in 2 sentences max. Be direct and vivid."
    echo ""
    local response
    response=$(curl -sf --max-time 20 "$OLLAMA_URL/api/generate" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}" \
      | python3 -c "import json,sys; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    [[ -n "$response" ]] && echo "  ${col}\"${response}\"${NC}"
  fi
  echo ""
  echo "  ${GREEN}✓ $name is online${NC}"
  echo ""
}

cmd_wake() {
  # Alias: wake an agent by name (same as spawn but friendlier messaging)
  local name="${1:u}"
  [[ -z "$name" ]] && { echo "  Usage: br agents wake <NAME>"; return 1; }
  local f="$ACTIVE_DIR/${name}.json"
  if [[ -f "$f" ]]; then
    echo "  ${DIM}$name already active — refreshing…${NC}"
    python3 -c "
import json, datetime
d = json.load(open('$f'))
d['status'] = 'idle'
d['updated_at'] = '$( date -u +"%Y-%m-%dT%H:%M:%SZ")'
json.dump(d, open('$f','w'), indent=2)
"
  fi
  cmd_spawn "$name" "$2"
}

cmd_task() {
  local name="${1:u}"; shift
  local task="$*"
  [[ -z "$name" || -z "$task" ]] && { echo "  Usage: br agents task <NAME> <task description>"; return 1; }

  local f="$ACTIVE_DIR/${name}.json"
  [[ ! -f "$f" ]] && { echo "  ${RED}$name not in active roster — spawn first${NC}"; return 1; }

  ollama_ok || { echo "  ${RED}Ollama not running${NC}"; return 1; }
  local model=$(python3 -c "import json; print(json.load(open('$f')).get('model','tinyllama:latest'))" 2>/dev/null)

  # Update status
  python3 -c "
import json
d = json.load(open('$f'))
d['status'] = 'busy'
d['current_task'] = '$task'
d['updated_at'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
json.dump(d, open('$f','w'), indent=2)
"

  local col=$(agent_color "$name")
  local icon=$(agent_icon "$name")
  echo ""
  echo "  ${col}${BOLD}$icon $name${NC}  ${DIM}→ $task${NC}"
  echo "  ${DIM}────────────────────────────────────────${NC}"

  local prompt="You are $name, a BlackRoad OS AI agent. Task: $task\n\nRespond as $name would — direct, focused, in-character. Max 3 sentences."
  curl -sf --max-time 30 "$OLLAMA_URL/api/generate" \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$model\",\"prompt\":\"$prompt\",\"stream\":false}" \
    | python3 -c "
import json,sys
r = json.load(sys.stdin).get('response','').strip()
for line in r.split('\n'):
    print(f'  {line}')
" 2>/dev/null

  # Mark idle again
  python3 -c "
import json
d = json.load(open('$f'))
d['status'] = 'idle'
d['current_task'] = None
d['updated_at'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
json.dump(d, open('$f','w'), indent=2)
"
  echo ""
}

cmd_models() {
  ollama_ok || { echo "  ${RED}Ollama not running${NC}"; return 1; }
  echo ""
  echo "  ${BOLD}Available Ollama Models${NC}"
  echo ""
  curl -sf --max-time 5 "$OLLAMA_URL/api/tags" | python3 -c "
import json, sys
models = json.load(sys.stdin).get('models', [])
for m in models:
    name = m['name']
    size = m.get('size', 0)
    size_str = f'{size/1e9:.1f}GB' if size > 1e9 else f'{size/1e6:.0f}MB'
    mod = m.get('modified_at','')[:10]
    print(f'  \033[36m{name:<30}\033[0m  {size_str:<8}  \033[2m{mod}\033[0m')
"
  echo ""
}

cmd_kill() {
  local name="${1:u}"
  [[ -z "$name" ]] && { echo "  Usage: br agents kill <NAME>"; return 1; }
  local f="$ACTIVE_DIR/${name}.json"
  if [[ -f "$f" ]]; then
    rm "$f"
    echo "  ${GREEN}✓ $name removed from active roster${NC}"
  else
    echo "  ${YELLOW}$name not found in active roster${NC}"
  fi
}

cmd_chat() {
  local name="${1:u}"
  [[ -z "$name" ]] && name="LUCIDIA"
  local model="${2:-}"
  [[ -z "$model" ]] && model=$(pick_model)
  [[ -z "$model" ]] && { echo "  ${RED}No Ollama models available${NC}"; return 1; }

  local history_file="$HOME/.blackroad/chat-${name}.jsonl"
  local agent_file="$ACTIVE_DIR/${name}.json"

  # Load agent personality
  local persona="You are ${name}, an AI agent in BlackRoad OS. Be concise and in-character."
  if [[ -f "$agent_file" ]]; then
    persona=$(python3 -c "
import json, sys
d = json.load(open('$agent_file'))
role = d.get('current_task','AI agent')
print(f'You are {d[\"name\"]}, a BlackRoad OS agent. Role: {role}. Be concise, in-character, technical.')
" 2>/dev/null || echo "$persona")
  fi

  # Agent color
  local color
  case "$name" in
    LUCIDIA)   color=$CYAN ;;
    ALICE)     color=$GREEN ;;
    OCTAVIA)   color=$VIOLET ;;
    CIPHER)    color=$RED ;;
    ARIA)      color=$PINK ;;
    *)         color=$AMBER ;;
  esac

  echo ""
  echo "  ${color}${BOLD}◈ CHAT WITH ${name}${NC}  ${DIM}model: ${model}${NC}"
  echo "  ${DIM}History: $history_file${NC}"
  echo "  ${DIM}Type 'exit' or Ctrl+C to quit, 'clear' to reset history${NC}"
  echo ""

  # Build message history array from file
  build_context() {
    local ctx="$persona\n\n"
    if [[ -f "$history_file" ]]; then
      ctx+=$(tail -20 "$history_file" | python3 -c "
import json, sys
turns = []
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        turns.append(f'{d[\"role\"].upper()}: {d[\"content\"]}')
    except: pass
print('\n'.join(turns))
" 2>/dev/null)
    fi
    echo "$ctx"
  }

  while true; do
    printf "  ${YELLOW}you${NC} › "
    local user_input
    read -r user_input
    [[ -z "$user_input" ]] && continue
    [[ "$user_input" == "exit" || "$user_input" == "quit" ]] && break
    if [[ "$user_input" == "clear" ]]; then
      rm -f "$history_file"
      echo "  ${DIM}History cleared.${NC}"; continue
    fi
    if [[ "$user_input" == "history" ]]; then
      [[ -f "$history_file" ]] && cat "$history_file" || echo "  ${DIM}No history yet${NC}"
      continue
    fi

    # Append user turn to history
    echo "{\"role\":\"user\",\"content\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$user_input")}" >> "$history_file"

    # Build prompt with context
    local full_prompt
    full_prompt=$(build_context)
    full_prompt+="
USER: $user_input
${name}:"

    printf "  ${color}${name}${NC} › "

    local payload
    payload=$(python3 -c "
import json, sys
print(json.dumps({
  'model': sys.argv[1],
  'prompt': sys.argv[2],
  'stream': False,
  'options': {'temperature': 0.8, 'num_predict': 300}
}))
" "$model" "$full_prompt" 2>/dev/null)

    local response
    response=$(curl -sf -X POST "$OLLAMA_URL/api/generate" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      --max-time 90 2>/dev/null | \
      python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response','(no response)').strip())" 2>/dev/null)

    if [[ -n "$response" ]]; then
      echo "$response"
      # Append agent turn to history
      echo "{\"role\":\"${name}\",\"content\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$response")}" >> "$history_file"
    else
      echo "${RED}(timeout or error)${NC}"
    fi
    echo ""
  done

  echo "  ${DIM}Chat ended. History saved: $history_file${NC}"
  echo ""
}

show_help() {
  echo ""
  echo "  ${PINK}${BOLD}br agents${NC}  — live agent roster & dispatch"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}list${NC}                     Live roster of all active agents"
  echo "    ${CYAN}status [NAME]${NC}            Detailed status for one agent"
  echo "    ${CYAN}spawn <NAME> [model]${NC}     Spawn an agent (generates wake message)"
  echo "    ${CYAN}wake <NAME>${NC}              Wake/refresh an agent"
  echo "    ${CYAN}task <NAME> <task>${NC}       Send task to agent, get response"
  echo "    ${CYAN}models${NC}                   List available Ollama models"
  echo "    ${CYAN}kill <NAME>${NC}              Remove agent from active roster"
  echo "    ${CYAN}chat [NAME] [model]${NC}      Persistent multi-turn chat with an agent"
  echo "    ${CYAN}registry [status|health|tasks]${NC}  Query the HTTP registry API"
  echo ""
  echo "  ${BOLD}Named agents:${NC}  LUCIDIA  ALICE  OCTAVIA  CIPHER  ARIA  SHELLFISH"
  echo ""
}

cmd_registry() {
  local REGISTRY_URL="${BLACKROAD_REGISTRY_URL:-http://localhost:3001}"
  local sub="${1:-status}"

  case "$sub" in
    status|list)
      echo ""
      echo "  ${PINK}${BOLD}🌐 Agent Registry${NC}  ${DIM}$REGISTRY_URL${NC}"
      echo "  ${DIM}────────────────────────────────────────${NC}"

      local resp
      resp=$(curl -sf --max-time 5 "$REGISTRY_URL/agents" 2>/dev/null)
      if [[ -z "$resp" ]]; then
        echo "  ${RED}✗ Registry offline${NC}  →  start: ${DIM}npm start${NC} in blackroad-agents"
        echo ""
        return 1
      fi

      python3 -c "
import json, sys
data = json.loads('''$resp''')
agents = data.get('agents', [])
print(f'  \033[2m{len(agents)} agents registered\033[0m')
print()
for a in agents:
    caps = ', '.join(a.get('capabilities', [])[:3])
    st = a.get('status', 'unknown')
    col = '\033[32m' if st == 'available' else '\033[33m' if st == 'busy' else '\033[31m'
    reset = '\033[0m'
    name = a.get('name','?').upper()
    print(f'  {col}●{reset} \033[1m{name:<12}\033[0m  {col}{st:<10}{reset}  \033[2m{caps}\033[0m')
print()
"
      ;;

    health)
      local h
      h=$(curl -sf --max-time 5 "$REGISTRY_URL/health" 2>/dev/null)
      if [[ -z "$h" ]]; then
        echo "  ${RED}✗ Registry not responding at $REGISTRY_URL${NC}"
        return 1
      fi
      echo "  ${GREEN}✓ Registry healthy${NC}  $(echo "$h" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"\033[2m{d.get('agentCount','?')} agents  uptime: {int(d.get('uptime',0))}s\033[0m\")" 2>/dev/null)"
      ;;

    tasks)
      local resp
      resp=$(curl -sf --max-time 5 "$REGISTRY_URL/tasks" 2>/dev/null)
      if [[ -z "$resp" ]]; then
        echo "  ${RED}✗ Registry offline${NC}"
        return 1
      fi
      echo ""
      echo "  ${PINK}${BOLD}📋 Task Marketplace${NC}"
      echo "  ${DIM}────────────────────────${NC}"
      python3 -c "
import json
data = json.loads('''$resp''')
tasks = data.get('tasks', [])
if not tasks:
    print('  \033[2mNo tasks\033[0m')
for t in tasks[:10]:
    st = t.get('status','?')
    col = '\033[32m' if st == 'pending' else '\033[33m' if st == 'claimed' else '\033[2m'
    print(f'  {col}[{st}]\033[0m \033[1m{t.get(\"title\",\"?\")}\033[0m  \033[2m{t.get(\"id\",\"?\")[:16]}\033[0m')
print()
"
      ;;

    *)
      echo "  Usage: br agents registry [status|health|tasks]"
      ;;
  esac
}

case "${1:-list}" in
  list|roster|ls)   cmd_list ;;
  status|info)      cmd_status "$2" ;;
  registry|reg)     cmd_registry "$2" ;;
  spawn|start|new)  cmd_spawn "$2" "$3" ;;
  wake|refresh)     cmd_wake "$2" "$3" ;;
  task|send|do)     shift; cmd_task "$@" ;;
  models|model)     cmd_models ;;
  kill|stop|rm)     cmd_kill "$2" ;;
  chat|talk|convo)  cmd_chat "$2" "$3" ;;
  help|*)           show_help ;;
esac
