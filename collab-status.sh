#!/bin/zsh
# collab-status.sh — Live collaboration mesh status dashboard
# Shows all instances, inboxes, queue, memory chain tail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; PURPLE='\033[0;35m'; BLUE='\033[0;34m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

COLLAB_FILE="/Users/alexa/blackroad/coordination/collaboration/active-instances.json"
LIVE_FILE="/Users/alexa/blackroad/coordination/live/real-time-context.json"
INBOX_ROOT="/Users/alexa/blackroad/shared/inbox"
QUEUE_DIR="/Users/alexa/blackroad/shared/mesh/queue"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"

clear
echo ""
echo "${PURPLE}${BOLD}  💜 BlackRoad Collaboration Mesh — Live Status${NC}"
echo "${PURPLE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# Memory chain
echo "${CYAN}  🧠 MEMORY CHAIN${NC}"
LAST=$(tail -3 "$JOURNAL" 2>/dev/null | python3 -c "
import sys,json
for line in sys.stdin:
    line=line.strip()
    if line:
        try:
            e=json.loads(line)
            print(f\"  {e.get('timestamp','?')[:19]}  {e.get('action','?'):20}  {e.get('entity','?')[:30]}\")
        except: pass
" 2>/dev/null)
echo "$LAST"
CHAIN=$(tail -1 "$JOURNAL" 2>/dev/null | python3 -c "import sys,json; e=json.loads(sys.stdin.read().strip()); print(e.get('sha256','')[:20])" 2>/dev/null)
echo "  ${DIM}Head: $CHAIN...${NC}"
echo ""

# Instances
echo "${CYAN}  🤝 INSTANCES${NC}"
python3 - << 'PYEOF'
import json, os

GREEN = '\033[0;32m'; RED = '\033[0;31m'; YELLOW = '\033[1;33m'
CYAN = '\033[0;36m'; DIM = '\033[2m'; NC = '\033[0m'; BOLD = '\033[1m'

try:
    with open("/Users/alexa/blackroad/coordination/collaboration/active-instances.json") as f:
        data = json.load(f)
except:
    print("  ⚠️  Cannot read instances file")
    exit()

inbox_root = "/Users/alexa/blackroad/shared/inbox"
for name, inst in data.get("instances", {}).items():
    status = inst.get("status", "UNKNOWN")
    color = GREEN if status == "ONLINE" else (YELLOW if status == "STANDBY" else DIM)
    icon = "🟢" if status == "ONLINE" else ("⚪" if status == "STANDBY" else "🔴")
    role = inst.get("role", "")
    inbox = os.path.join(inbox_root, name)
    msgs = len(os.listdir(inbox)) if os.path.isdir(inbox) else 0
    msg_str = f"  📬 {msgs}" if msgs > 0 else ""
    models = inst.get("models", [])
    model_str = f"  [{', '.join(models[:2])}]" if models else ""
    print(f"  {icon} {BOLD}{name:<28}{NC} {color}{status:<12}{NC} {DIM}{role}{NC}{msg_str}{model_str}")
PYEOF
echo ""

# Queue
echo "${CYAN}  📋 TASK QUEUE  (shared/mesh/queue/)${NC}"
QCOUNT=$(ls "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [[ $QCOUNT -eq 0 ]]; then
  echo "  ${DIM}  No tasks queued${NC}"
else
  ls "$QUEUE_DIR" | while read f; do
    echo "  → $f"
  done
fi
echo ""

# Inboxes with messages
echo "${CYAN}  📥 INBOXES WITH MESSAGES${NC}"
FOUND=0
for dir in "$INBOX_ROOT"/*/; do
  name=$(basename "$dir")
  count=$(ls "$dir" 2>/dev/null | wc -l | tr -d ' ')
  if [[ $count -gt 0 ]]; then
    echo "  📬 ${YELLOW}$name${NC} — $count message(s)"
    ls "$dir" | while read f; do echo "       $f"; done
    FOUND=1
  fi
done
[[ $FOUND -eq 0 ]] && echo "  ${DIM}  All inboxes empty${NC}"
echo ""

# Live context focus
echo "${CYAN}  🎯 CURRENT FOCUS${NC}"
python3 -c "
import json
try:
    d = json.load(open('/Users/alexa/blackroad/coordination/live/real-time-context.json'))
    print(f\"  {d.get('current_focus','—')}\")
    print(f\"  Operator: {d.get('operator','?')}  |  Session: {d.get('session','?')}\")
except: print('  —')
" 2>/dev/null
echo ""

echo "${PURPLE}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  ${DIM}join: ./join-collaboration.sh [id]  |  handoff: ./handoff.sh [from] [to] [task]${NC}"
echo "  ${DIM}route: ./collab-task-router.sh [task]  |  refresh: ./collab-status.sh${NC}"
echo ""
