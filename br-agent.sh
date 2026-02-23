#!/bin/zsh
# BR Agent - AI Agent Manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

GATEWAY_URL="${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}"

AGENTS=(octavia lucidia alice aria shellfish)
declare -A AGENT_ROLES
AGENT_ROLES=(
  [octavia]="Architect — systems design, strategy"
  [lucidia]="Dreamer — creative, vision"
  [alice]="Operator — DevOps, automation"
  [aria]="Interface — frontend, UX"
  [shellfish]="Hacker — security, exploits"
)

show_help() {
  echo -e "${PURPLE}${BOLD}BR Agent{{NC}"
  echo "  br agent list              List all agents"
  echo "  br agent chat <agent> <msg> Chat with an agent"
  echo "  br agent status            Check agent availability"
  echo "  br agent route <task>      Route task to best agent"
  echo "  br agent broadcast <msg>   Broadcast to all agents"
  echo ""
  echo -e "  ${YELLOW}Agents:{{NC} octavia, lucidia, alice, aria, shellfish"
}

cmd_list() {
  echo -e "${PURPLE}${BOLD}BlackRoad Agents{{NC}\n"
  for A in "${AGENTS[@]}"; do
    echo -e "  ${CYAN}${A}{{NC} — ${AGENT_ROLES[$A]}"
  done
}

cmd_chat() {
  local AGENT="${1:-lucidia}"
  local MSG="${2:-Hello}"
  echo -e "${CYAN}Chatting with ${AGENT}...{{NC}\n"

  RESULT=$(curl -s -m 15 -X POST "$GATEWAY_URL/v1/chat" \
    -H "Content-Type: application/json" \
    -d "{\"agent\":\"$AGENT\",\"message\":\"$MSG\"}" 2>/dev/null)

  if [[ -n "$RESULT" ]]; then
    echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
  else
    if command -v ollama &>/dev/null; then
      echo -e "${YELLOW}(via ollama){{NC}"
      ollama run llama3.2 "You are $AGENT. ${AGENT_ROLES[$AGENT]}. Respond: $MSG" 2>/dev/null
    else
      echo -e "${RED}Gateway offline and ollama not found{{NC}"
    fi
  fi
}

cmd_status() {
  echo -e "${CYAN}Agent Status{{NC}\n"
  GW=$(curl -s -m 3 "$GATEWAY_URL/health" 2>/dev/null)
  if [[ -n "$GW" ]]; then
    echo -e "  ${GREEN}● Gateway online{{NC} — agents reachable"
  else
    echo -e "  ${YELLOW}● Gateway offline{{NC} — local mode only"
  fi
  if command -v ollama &>/dev/null; then
    MODELS=$(curl -s -m 3 http://localhost:11434/api/tags 2>/dev/null | \
      python3 -c "import json,sys; m=json.load(sys.stdin); print(len(m.get('models',[])),'models')" 2>/dev/null)
    echo -e "  ${GREEN}● Ollama{{NC} — $MODELS available"
  else
    echo -e "  ${RED}● Ollama{{NC} — not running"
  fi
  echo ""
  for A in "${AGENTS[@]}"; do
    echo -e "  ${YELLOW}●{{NC} $A — ${AGENT_ROLES[$A]}"
  done
}

cmd_route() {
  local TASK="${*:-help me}"
  echo -e "${CYAN}Routing task: \"$TASK\"{{NC}\n"
  if echo "$TASK" | grep -qi "deploy\|docker\|ci\|infra\|server"; then
    echo -e "  ${GREEN}→ alice{{NC} (Operator) — DevOps task detected"
  elif echo "$TASK" | grep -qi "design\|frontend\|ui\|ux\|css\|react"; then
    echo -e "  ${GREEN}→ aria{{NC} (Interface) — UI/UX task detected"
  elif echo "$TASK" | grep -qi "security\|hack\|vuln\|exploit\|audit"; then
    echo -e "  ${GREEN}→ shellfish{{NC} (Hacker) — Security task detected"
  elif echo "$TASK" | grep -qi "architect\|design\|system\|strategy\|plan"; then
    echo -e "  ${GREEN}→ octavia{{NC} (Architect) — Architecture task detected"
  else
    echo -e "  ${GREEN}→ lucidia{{NC} (Dreamer) — General task"
  fi
  echo -e "\n  Use: ${CYAN}br agent chat <agent> \"$TASK\"{{NC}"
}

cmd_broadcast() {
  local MSG="${*:-ping}"
  echo -e "${CYAN}Broadcasting: \"$MSG\"{{NC}\n"
  RESULT=$(curl -s -m 10 -X POST "$GATEWAY_URL/v1/broadcast" \
    -H "Content-Type: application/json" \
    -d "{\"message\":\"$MSG\"}" 2>/dev/null)
  if [[ -n "$RESULT" ]]; then
    echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
  else
    echo -e "${YELLOW}Gateway offline — writing to shared/inbox{{NC}"
    mkdir -p /Users/alexa/blackroad/shared/inbox
    echo "{\"from\":\"cli\",\"to\":\"all\",\"message\":\"$MSG\",\"time\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
      > /Users/alexa/blackroad/shared/inbox/broadcast-$(date +%s).json
    echo -e "  ${GREEN}Written to shared/inbox{{NC}"
  fi
}

case "${1:-help}" in
  list)       cmd_list ;;
  chat)       cmd_chat "$2" "${@:3}" ;;
  status)     cmd_status ;;
  route)      cmd_route "${@:2}" ;;
  broadcast)  cmd_broadcast "${@:2}" ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1{{NC}"
    show_help ;;
esac
