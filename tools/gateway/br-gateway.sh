#!/bin/zsh
# BR Gateway — BlackRoad Core Gateway management

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

GATEWAY_URL="${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}"
GATEWAY_DIR="$(cd "$(dirname "$0")/../.." && pwd)/blackroad-core/gateway"

show_help() {
  echo "${CYAN}${BOLD}BR Gateway — BlackRoad Core AI Gateway${NC}"
  echo ""
  echo "${BOLD}Commands:${NC}"
  echo "  ${GREEN}start${NC}         Start the gateway server"
  echo "  ${GREEN}stop${NC}          Stop the gateway server"
  echo "  ${GREEN}status${NC}        Show gateway health + metrics"
  echo "  ${GREEN}agents${NC}        List available agents"
  echo "  ${GREEN}providers${NC}     List configured AI providers"
  echo "  ${GREEN}memory${NC}        Show memory journal stats"
  echo "  ${GREEN}call${NC}          Make an agent call: br gateway call <agent> <intent> <input>"
  echo "  ${GREEN}verify${NC}        Verify a claim: br gateway verify 'claim text'"
  echo "  ${GREEN}logs${NC}          Show recent gateway logs"
}

cmd_start() {
  if pgrep -f "blackroad-core/gateway/server.js" > /dev/null 2>&1; then
    echo "${YELLOW}Gateway already running${NC}"
    cmd_status; return
  fi
  echo "${CYAN}Starting BlackRoad Gateway...${NC}"
  cd "$GATEWAY_DIR" && node server.js > logs/startup.log 2>&1 &
  sleep 2
  if curl -sf "$GATEWAY_URL/healthz" > /dev/null 2>&1; then
    echo "${GREEN}✓ Gateway running at $GATEWAY_URL${NC}"
  else
    echo "${RED}✗ Gateway failed to start — check logs/startup.log${NC}"
  fi
}

cmd_stop() {
  local PID=$(pgrep -f "blackroad-core/gateway/server.js" 2>/dev/null | head -1)
  if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null && echo "${GREEN}✓ Gateway stopped (PID $PID)${NC}"
  else
    echo "${YELLOW}Gateway not running${NC}"
  fi
}

cmd_status() {
  echo "${CYAN}${BOLD}BlackRoad Gateway Status${NC}"
  local health=$(curl -sf "$GATEWAY_URL/healthz" 2>/dev/null)
  if [ -n "$health" ]; then
    echo "${GREEN}● Online${NC} — $GATEWAY_URL"
    curl -sf "$GATEWAY_URL/metrics" 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin).get('metrics',{})
print(f'  Requests: {d.get(\"total_requests\",0)} | Success: {d.get(\"successful\",0)} | Errors: {d.get(\"errors\",0)}')
" 2>/dev/null
  else
    echo "${RED}● Offline${NC} — run: br gateway start"
  fi
}

cmd_providers() {
  echo "${CYAN}${BOLD}Configured Providers${NC}"
  local data=$(curl -sf "$GATEWAY_URL/v1/providers" 2>/dev/null)
  if [ -z "$data" ]; then
    echo "${YELLOW}Gateway offline — listing from source...${NC}"
    ls "$GATEWAY_DIR/providers/" 2>/dev/null | grep -v index | sed 's/\.js//' | while read p; do
      echo "  ${GREEN}●${NC} $p"
    done
    return
  fi
  echo "$data" | python3 -c "import json,sys; [print(f'  \033[0;32m●\033[0m {p}') for p in json.load(sys.stdin).get('providers',[])]" 2>/dev/null
}

cmd_memory() {
  local sub="${1:-stats}"
  if [ "$sub" = "recent" ]; then
    curl -sf "$GATEWAY_URL/v1/memory/recent?limit=10" 2>/dev/null | python3 -c "
import json,sys
for e in json.load(sys.stdin).get('entries',[]):
    print(f'  {e.get(\"ts\",\"\")[:19]}  {e.get(\"agent\",\"?\"):<12} {e.get(\"status\",\"?\")[:3]}')
" 2>/dev/null || echo "${RED}Gateway offline${NC}"
  else
    curl -sf "$GATEWAY_URL/v1/memory" 2>/dev/null | python3 -c "
import json,sys
m=json.load(sys.stdin).get('memory',{})
print(f'  Journal entries: {m.get(\"journal_entries\",0)}')
print(f'  Context keys:    {m.get(\"context_keys\",0)}')
print(f'  Session calls:   {m.get(\"total_session_calls\",0)}')
" 2>/dev/null || echo "${RED}Gateway offline${NC}"
  fi
}

cmd_call() {
  local agent="${1:-octavia}"; local intent="${2:-analyze}"; local input="${*:3}"
  [[ -z "$input" ]] && input="Hello from br gateway"
  echo "${CYAN}→ $agent / $intent${NC}"
  curl -sf -X POST "$GATEWAY_URL/v1/agent" \
    -H "Content-Type: application/json" \
    -d "{\"agent\":\"$agent\",\"intent\":\"$intent\",\"input\":\"$input\"}" 2>/dev/null | \
    python3 -c "
import json,sys; d=json.load(sys.stdin)
if d.get('status')=='ok':
    print(d.get('response',''))
    print(f'\n\033[0;36m  {d.get(\"provider\",\"?\")} | {d.get(\"duration_ms\",0)}ms\033[0m')
else: print('\033[0;31m✗\033[0m', d.get('error','unknown'))
" 2>/dev/null || echo "${RED}Gateway offline${NC}"
}

cmd_verify() {
  local claim="${*:-BlackRoad has over 100 worlds}"
  echo "${CYAN}Verifying: \"$claim\"${NC}"
  curl -sf -X POST "$GATEWAY_URL/v1/verify" \
    -H "Content-Type: application/json" \
    -d "{\"claim\":\"$claim\"}" 2>/dev/null | \
    python3 -c "
import json,sys; d=json.load(sys.stdin)
conf=d.get('confidence',0)
ok=d.get('verified',False)
color='\033[0;32m' if ok else '\033[0;33m'
print(f'  {color}Confidence: {conf}%\033[0m | Verified: {ok}')
" 2>/dev/null || echo "${RED}Gateway offline${NC}"
}

case "${1:-help}" in
  start)     cmd_start ;;
  stop)      cmd_stop ;;
  status)    cmd_status ;;
  agents)    curl -sf "$GATEWAY_URL/v1/agents" 2>/dev/null | python3 -c "import json,sys; [print(f'  {a[\"name\"]:<14} {a.get(\"description\",\"\")[:50]}') for a in json.load(sys.stdin).get('agents',[])]" 2>/dev/null || echo "Gateway offline" ;;
  providers) cmd_providers ;;
  memory)    shift; cmd_memory "$@" ;;
  call)      shift; cmd_call "$@" ;;
  worlds)    curl -sf "$GATEWAY_URL/v1/worlds" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin).get('worlds',{}); print(f'🌍 {d.get(\"total\",\"?\")} worlds')" 2>/dev/null || echo "Gateway offline" ;;
  verify)    shift; cmd_verify "$@" ;;
  logs)      LOG="$GATEWAY_DIR/logs/gateway.jsonl"; [ -f "$LOG" ] && tail -20 "$LOG" | python3 -c "import json,sys; [print(f'{d.get(\"timestamp\",\"\")[:19]} {d.get(\"status\",\"?\"):<8} {d.get(\"agent\",\"?\")}') for line in sys.stdin for d in [json.loads(line)] if d]" 2>/dev/null || echo "No logs yet" ;;
  *)         show_help ;;
esac
