#!/bin/zsh
# collab-task-router.sh — Route a task to the best instance by capability
# Usage: ./collab-task-router.sh "build a React component"
#        ./collab-task-router.sh "write a bash script" --exec
#        echo '{"task":"analyze code"}' | ./collab-task-router.sh

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
PURPLE='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

QUEUE_DIR="/Users/alexa/blackroad/shared/mesh/queue"
INBOX_ROOT="/Users/alexa/blackroad/shared/inbox"
COLLAB_FILE="/Users/alexa/blackroad/coordination/collaboration/active-instances.json"

TASK="${1:-}"
AUTO_EXEC="${2:-}"

if [[ -z "$TASK" ]]; then
  echo "Usage: ./collab-task-router.sh \"<task description>\" [--exec]"
  echo ""
  echo "Routing rules:"
  echo "  code / component / build / fix    → codex (OpenAI Codex)"
  echo "  analyze / reason / plan / design  → claude (Claude Sonnet)"
  echo "  bash / script / deploy / infra    → lucidia-copilot-cli (this window)"
  echo "  story / creative / dream          → ollama lucidia:latest"
  echo "  chat / quick / ask                → ollama qwen2.5:1.5b"
  echo "  parallel / bulk / batch           → copilot-window-2 + copilot-window-3"
  exit 0
fi

echo ""
echo "${PURPLE}💜 Task Router${NC}"
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  Task: ${BOLD}$TASK${NC}"
echo ""

# Route by keywords
TASK_LOWER=$(echo "$TASK" | tr '[:upper:]' '[:lower:]')
TARGET=""
REASON=""
METHOD=""

if echo "$TASK_LOWER" | grep -qE "bash|script|shell|deploy|infra|devops|ssh|git|ci|cd|docker|k8s|pipeline|server|daemon|cron"; then
  TARGET="lucidia-copilot-cli"
  REASON="bash/infra task → Primary CLI operator"
  METHOD="execute"
elif echo "$TASK_LOWER" | grep -qE "analyze|analysis|reason|plan|architect|design|review|explain|understand|research|think"; then
  TARGET="claude"
  REASON="deep reasoning → Claude Sonnet"
  METHOD="message"
elif echo "$TASK_LOWER" | grep -qE "code|function|class|component|react|vue|typescript|python|build|implement|write code|refactor|test|debug"; then
  TARGET="codex"
  REASON="code generation → OpenAI Codex"
  METHOD="message"
elif echo "$TASK_LOWER" | grep -qE "story|dream|creative|imagine|vision|narrative|poem|art"; then
  TARGET="ollama-local"
  REASON="creative/vision → Ollama lucidia:latest"
  METHOD="ollama"
  MODEL="lucidia:latest"
elif echo "$TASK_LOWER" | grep -qE "batch|parallel|bulk|many|multiple|all repos|sweep"; then
  TARGET="copilot-window-2"
  TARGET2="copilot-window-3"
  REASON="parallel work → two Copilot windows"
  METHOD="split"
else
  TARGET="ollama-local"
  REASON="general query → Ollama qwen2.5:1.5b"
  METHOD="ollama"
  MODEL="qwen2.5:1.5b"
fi

echo "  Route:  ${GREEN}$TARGET${NC}"
echo "  Reason: ${DIM}$REASON${NC}"
echo "  Method: $METHOD"
echo ""

TS=$(date +%s)
TASK_FILE="$QUEUE_DIR/${TS}_$(echo $TARGET | tr '-' '_').json"

# Write to queue
python3 - << PYEOF
import json
task = {
    "id": "$TS",
    "task": "$TASK",
    "target": "$TARGET",
    "reason": "$REASON",
    "method": "$METHOD",
    "from": "lucidia-copilot-cli",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "status": "queued"
}
$([ -n "$TARGET2" ] && echo 'task["co_target"] = "'$TARGET2'"')
$([ -n "$MODEL" ] && echo 'task["model"] = "'$MODEL'"')
with open("$TASK_FILE", "w") as f:
    json.dump(task, f, indent=2)
print(f"  Queued → {task['id']}")
PYEOF

# Also write to target inbox
INBOX_FILE="$INBOX_ROOT/$TARGET/task-${TS}.json"
python3 - << PYEOF
import json, os
inbox = "$INBOX_ROOT/$TARGET"
os.makedirs(inbox, exist_ok=True)
task = {
    "id": "$TS",
    "from": "lucidia-copilot-cli",
    "task": "$TASK",
    "method": "$METHOD",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
with open("$INBOX_FILE", "w") as f:
    json.dump(task, f, indent=2)
print(f"  Delivered → shared/inbox/$TARGET/task-{task['id']}.json")
PYEOF

# If ollama, execute now
if [[ "$METHOD" == "ollama" ]]; then
  MODEL="${MODEL:-qwen2.5:1.5b}"
  echo "${CYAN}  🦙 Executing on Ollama ($MODEL)...${NC}"
  echo ""
  if [[ "$AUTO_EXEC" == "--exec" ]]; then
    curl -s http://localhost:11434/api/generate \
      -d "{\"model\":\"$MODEL\",\"prompt\":\"$TASK\",\"stream\":false}" \
      2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('response','[no response]'))
" 2>/dev/null || echo "  ⚠️  Ollama not reachable"
  else
    echo "  ${DIM}(Pass --exec to auto-run on Ollama)${NC}"
    echo "  Manual: curl -s http://localhost:11434/api/generate -d '{\"model\":\"$MODEL\",\"prompt\":\"$TASK\",\"stream\":false}'"
  fi
fi

echo ""
echo "${GREEN}✅ Task routed.${NC}  Check: ./collab-status.sh"
echo ""
