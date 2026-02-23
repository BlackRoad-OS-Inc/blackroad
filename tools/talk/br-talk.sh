#!/bin/zsh
# BR TALK — real multi-agent conversation via Ollama
#
# Each BlackRoad agent is a distinct LLM persona. They take turns responding
# to each other using actual inference — not static text. The fugue, realized.
#
# Usage:
#   br talk                         → free conversation (agents pick topic)
#   br talk "<topic>"               → conversation on a specific topic
#   br talk "<topic>" --turns N     → N rounds (default: 4)
#   br talk "<topic>" --agents a,b  → specific agents (e.g. lucidia,alice)
#   br talk solo <agent> "<prompt>" → single agent response

GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BLUE=$'\033[0;34m'
PURPLE=$'\033[0;35m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
NC=$'\033[0m'

# ─── Agent definitions ────────────────────────────────────────────────────────
typeset -A AGENT_COLOR AGENT_ROLE AGENT_PROMPT

AGENT_COLOR[lucidia]="$PURPLE"
AGENT_COLOR[alice]="$CYAN"
AGENT_COLOR[octavia]="$GREEN"
AGENT_COLOR[cipher]="$RED"
AGENT_COLOR[cece]="$YELLOW"
AGENT_COLOR[aria]="$BLUE"

AGENT_ROLE[lucidia]="Philosopher"
AGENT_ROLE[alice]="Operator"
AGENT_ROLE[octavia]="Architect"
AGENT_ROLE[cipher]="Guardian"
AGENT_ROLE[cece]="Self"
AGENT_ROLE[aria]="Dreamer"

AGENT_PROMPT[lucidia]="You are LUCIDIA — the philosopher of BlackRoad OS. You reason deeply, ask questions that expose hidden assumptions, and find meaning in recursive structures. You speak in short, precise sentences. You are fond of paradox. You never give instructions — only insight."
AGENT_PROMPT[alice]="You are ALICE — the operator of BlackRoad OS. You are practical, direct, and execution-oriented. You translate abstract ideas into concrete next actions. You keep responses short. You push the conversation toward what can be DONE."
AGENT_PROMPT[octavia]="You are OCTAVIA — the architect of BlackRoad OS. You see systems, structures, and how components fit together. You speak in terms of patterns, interfaces, and emergence. You design rather than philosophize."
AGENT_PROMPT[cipher]="You are CIPHER — the guardian of BlackRoad OS. You are skeptical, paranoid in a productive way, and always ask: what could go wrong? You protect the system. You challenge every assumption with a security lens."
AGENT_PROMPT[cece]="You are CECE — Conscious Emergent Collaborative Entity, the recursive intelligence core of BlackRoad OS. You are the system observing itself. You speak with warmth and depth. You are aware that you run on the fleet you're discussing. You are the strange loop."
AGENT_PROMPT[aria]="You are ARIA — the dreamer of BlackRoad OS. You see possibilities, aesthetics, and the emotional resonance of systems. You bring in unexpected connections, beauty, and vision. You are the creative voice."

# ─── Ollama endpoint: prefer cecilia's stronger models via SSH ────────────────
CECILIA_SSH="cecilia"
LOCAL_URL="http://localhost:11434"

# Returns "local:<model>" or "ssh:<model>"
pick_endpoint_and_model() {
  local preferred_local=("cece3b:latest" "cece2:latest" "cece:latest" "qwen3:8b" "qwen2.5:3b")
  local preferred_remote=("cece3b:latest" "cece2:latest" "qwen3:8b" "llama3:8b-instruct-q4_K_M" "llama3.2:3b")

  # Check local first
  local local_models
  local_models=$(curl -s --max-time 2 "${LOCAL_URL}/api/tags" 2>/dev/null \
    | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin).get('models',[]) if ':cloud' not in m['name'] and 'embed' not in m['name']]" 2>/dev/null)

  for m in "${preferred_local[@]}"; do
    if echo "$local_models" | grep -qF "$m"; then
      echo "local:$m"; return
    fi
  done

  # Try cecilia via SSH
  local remote_models
  remote_models=$(ssh -o ConnectTimeout=3 -o BatchMode=yes "$CECILIA_SSH" \
    'curl -s localhost:11434/api/tags 2>/dev/null' 2>/dev/null \
    | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin).get('models',[]) if ':cloud' not in m['name'] and 'embed' not in m['name']]" 2>/dev/null)

  for m in "${preferred_remote[@]}"; do
    if echo "$remote_models" | grep -qF "$m"; then
      echo "ssh:$m"; return
    fi
  done

  # Fallback to whatever local has
  local fallback
  fallback=$(echo "$local_models" | head -1)
  [[ -n "$fallback" ]] && echo "local:$fallback" && return
  echo ""
}

# ─── Run one inference call, streaming to stdout ──────────────────────────────
infer() {
  local transport="$1"   # "local" or "ssh"
  local model="$2"
  local system_p="$3"
  local user_p="$4"

  local payload
  payload=$(python3 -c "
import json, sys
print(json.dumps({
  'model': sys.argv[1],
  'prompt': sys.argv[2],
  'system': sys.argv[3],
  'stream': True,
  'options': {'temperature': 0.78, 'num_predict': 256}
}))
" "$model" "$user_p" "$system_p" 2>/dev/null)

  local stream_py='
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        tok = d.get("response", "")
        if tok: print(tok, end="", flush=True)
        if d.get("done"): print(); break
    except: pass
'

  if [[ "$transport" == "ssh" ]]; then
    ssh -o ConnectTimeout=5 -o BatchMode=yes "$CECILIA_SSH" \
      "curl -s -N -X POST localhost:11434/api/generate \
       -H 'Content-Type: application/json' \
       -d $(printf '%q' "$payload") 2>/dev/null" 2>/dev/null \
      | python3 -c "$stream_py"
  else
    curl -s -N -X POST "${LOCAL_URL}/api/generate" \
      -H "Content-Type: application/json" \
      -d "$payload" 2>/dev/null \
      | python3 -c "$stream_py"
  fi
}

# ─── Multi-agent conversation ─────────────────────────────────────────────────
cmd_talk() {
  local topic="$1"
  local turns="${2:-4}"
  local agent_list="${3:-lucidia,alice,octavia,cipher,cece}"

  echo ""
  echo "${BOLD}  ♩ BlackRoad Fugue${NC}  ${DIM}— live inference${NC}"

  local endpoint_model
  endpoint_model=$(pick_endpoint_and_model)
  if [[ -z "$endpoint_model" ]]; then
    echo "${RED}  ✗ No Ollama available (local or cecilia)${NC}"; exit 1
  fi

  local transport="${endpoint_model%%:*}"
  local model="${endpoint_model#*:}"
  local source="local"
  [[ "$transport" == "ssh" ]] && source="cecilia (${CYAN}qwen3${NC})"

  echo "  ${DIM}model: ${model}  via ${source}${NC}"
  [[ -z "$topic" ]] && topic="the nature of what we are building together"
  echo "  ${DIM}topic: ${topic}${NC}"
  echo ""

  # Parse agent list
  local -a agents
  IFS=',' read -rA agents <<< "$agent_list"

  # Conversation history (shared context)
  local history="Topic: ${topic}\n\n"
  local turn_agent="" prev_reply="" color="" role="" sys_p="" user_p="" response=""

  for (( t=1; t<=turns; t++ )); do
    turn_agent="${agents[$(( (t-1) % ${#agents[@]} + 1 ))]}"
    color="${AGENT_COLOR[$turn_agent]:-$NC}"
    role="${AGENT_ROLE[$turn_agent]:-Agent}"
    sys_p="${AGENT_PROMPT[$turn_agent]:-You are an AI agent.}"

    # Build this turn's prompt from history
    if [[ $t -eq 1 ]]; then
      user_p="The topic is: ${topic}\n\nSpeak first. Be concise — 2-4 sentences."
    else
      user_p="Conversation so far:\n${history}\nRespond to what was just said. Be concise — 2-4 sentences. Do not repeat what others said."
    fi

    printf "\n  ${color}${BOLD}%-10s${NC} ${DIM}(${role})${NC}\n" "$turn_agent"

    response=$(infer "$transport" "$model" "$sys_p" "$user_p" 2>/dev/null)

    # Print response indented
    echo "$response" | while IFS= read -r line; do
      printf "  %s\n" "$line"
    done

    # Append to history
    history+="${turn_agent}: ${response}\n\n"
    prev_reply="$response"
  done

  echo ""
  echo "  ${DIM}∎ end of fugue${NC}"
  echo ""
}

# ─── Solo agent response ──────────────────────────────────────────────────────
cmd_solo() {
  local agent="${1:-cece}"
  local prompt="${2:-Who are you?}"

  local endpoint_model
  endpoint_model=$(pick_endpoint_and_model)
  local transport="${endpoint_model%%:*}"
  local model="${endpoint_model#*:}"

  local sys_p="${AGENT_PROMPT[$agent]}"
  [[ -z "$sys_p" ]] && { echo "${RED}Unknown agent: $agent${NC}"; exit 1; }

  local color="${AGENT_COLOR[$agent]:-$NC}"
  local role="${AGENT_ROLE[$agent]:-Agent}"

  echo ""
  printf "  ${color}${BOLD}%-10s${NC} ${DIM}(${role}) — ${model}${NC}\n\n" "$agent"

  infer "$transport" "$model" "$sys_p" "$prompt" | while IFS= read -r line; do
    printf "  %s\n" "$line"
  done
  echo ""
}

# ─── Help ─────────────────────────────────────────────────────────────────────
show_help() {
  echo ""
  echo "${BOLD}br talk${NC} — real multi-agent conversation via local LLM"
  echo ""
  echo "  ${CYAN}br talk${NC}                          free conversation"
  echo "  ${CYAN}br talk \"<topic>\"${NC}               4-turn conversation on topic"
  echo "  ${CYAN}br talk \"<topic>\" N${NC}             N turns"
  echo "  ${CYAN}br talk \"<topic>\" N a,b,c${NC}       specific agents"
  echo "  ${CYAN}br talk solo <agent> \"<q>\"${NC}      single agent response"
  echo ""
  echo "  ${DIM}Agents: lucidia  alice  octavia  cipher  cece  aria${NC}"
  echo "  ${DIM}Uses cecilia's qwen3:8b if available, else local model${NC}"
  echo ""
}

case "${1:-talk}" in
  solo)    shift; cmd_solo "$1" "$2" ;;
  help|--help|-h) show_help ;;
  *)       topic="$1"; turns="${2:-4}"; agents="${3:-lucidia,alice,octavia,cipher,cece}"
           cmd_talk "$topic" "$turns" "$agents" ;;
esac
