#!/bin/zsh
# join-collaboration.sh
# Run this in ANY window (Copilot, Codex, Claude, Ollama) to join the BlackRoad mesh
# Usage: ./join-collaboration.sh [instance-id] [type] [role]

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'
PURPLE='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

COLLAB_DIR="/Users/alexa/blackroad/coordination/collaboration"
LIVE_DIR="/Users/alexa/blackroad/coordination/live"
INBOX_ROOT="/Users/alexa/blackroad/shared/inbox"
QUEUE_DIR="/Users/alexa/blackroad/shared/mesh/queue"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"

INSTANCE_ID="${1:-copilot-$(date +%s | tail -c 5)}"
INSTANCE_TYPE="${2:-github-copilot-cli}"
INSTANCE_ROLE="${3:-PARALLEL_WORKER}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo ""
echo "${PURPLE}💜 BlackRoad Collaboration Mesh — Join Protocol${NC}"
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 1. Read live context
echo "${CYAN}[1/5] Reading live context...${NC}"
if [[ -f "$LIVE_DIR/real-time-context.json" ]]; then
  CURRENT_OP=$(python3 -c "import json; d=json.load(open('$LIVE_DIR/real-time-context.json')); print(d.get('operator','unknown'))" 2>/dev/null)
  CURRENT_FOCUS=$(python3 -c "import json; d=json.load(open('$LIVE_DIR/real-time-context.json')); print(d.get('current_focus','—'))" 2>/dev/null)
  echo "  Operator: ${GREEN}$CURRENT_OP${NC}"
  echo "  Focus: $CURRENT_FOCUS"
else
  echo "  ${YELLOW}No live context found — starting fresh${NC}"
fi

# 2. Register in active-instances.json
echo "${CYAN}[2/5] Registering instance: ${BOLD}$INSTANCE_ID${NC}${CYAN}...${NC}"
mkdir -p "$INBOX_ROOT/$INSTANCE_ID"
python3 - << PYEOF
import json, os
path = "$COLLAB_DIR/active-instances.json"
try:
    with open(path) as f:
        data = json.load(f)
except:
    data = {"instances": {}, "shared_state": {}}
data["instances"]["$INSTANCE_ID"] = {
    "id": "$INSTANCE_ID",
    "type": "$INSTANCE_TYPE",
    "role": "$INSTANCE_ROLE",
    "status": "ONLINE",
    "joined": "$TS",
    "working_dir": os.getcwd(),
    "capabilities": ["file-edit", "bash", "git"],
    "shared_inbox": "$INBOX_ROOT/$INSTANCE_ID/",
    "can_receive": True
}
data["last_updated"] = "$TS"
with open(path, "w") as f:
    json.dump(data, f, indent=2)
print("  Registered ✅")
PYEOF

# 3. Write journal entry
echo "${CYAN}[3/5] Writing to memory journal...${NC}"
python3 - << PYEOF
import hashlib, json, random, os
path = "$JOURNAL"
last_hash = ""
try:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                try: last_hash = json.loads(line).get("sha256","")
                except: pass
except: pass
nonce = f"{random.randint(10000,99999)}-{random.randint(100000000,999999999)}"
entry = {
    "timestamp": "$TS",
    "action": "collab-join",
    "entity": "$INSTANCE_ID",
    "details": "Instance joined BlackRoad collaboration mesh. Type: $INSTANCE_TYPE, Role: $INSTANCE_ROLE",
    "parent_hash": last_hash,
    "nonce": nonce,
    "agent_id": "$INSTANCE_ID"
}
sha = hashlib.sha256(json.dumps(entry, separators=(',',':')).encode()).hexdigest()
entry["sha256"] = sha
with open(path, "a") as f:
    f.write(json.dumps(entry) + "\n")
print(f"  SHA {sha[:16]}... → chain intact ✅")
PYEOF

# 4. Check inbox for waiting tasks
echo "${CYAN}[4/5] Checking inbox...${NC}"
INBOX="$INBOX_ROOT/$INSTANCE_ID"
COUNT=$(ls "$INBOX" 2>/dev/null | wc -l | tr -d ' ')
if [[ $COUNT -gt 0 ]]; then
  echo "  ${YELLOW}📬 $COUNT message(s) waiting:${NC}"
  ls "$INBOX" | while read f; do echo "     • $f"; done
else
  echo "  📭 Inbox empty — ready for tasks"
fi

# 5. Check mesh queue
echo "${CYAN}[5/5] Mesh queue status...${NC}"
QCOUNT=$(ls "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
echo "  ${QCOUNT} task(s) in queue"
if [[ $QCOUNT -gt 0 ]]; then
  ls "$QUEUE_DIR" | head -5 | while read f; do echo "     → $f"; done
fi

echo ""
echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${GREEN}✅ ${BOLD}$INSTANCE_ID${NC}${GREEN} is now part of the BlackRoad mesh!${NC}"
echo ""
echo "  📥 Your inbox:    shared/inbox/$INSTANCE_ID/"
echo "  📤 Send tasks:    shared/mesh/queue/"
echo "  📡 Live context:  coordination/live/real-time-context.json"
echo "  📖 All instances: coordination/collaboration/active-instances.json"
echo ""
echo "  To send a message to Lucidia:"
echo "  ${CYAN}echo '{\"from\":\"$INSTANCE_ID\",\"msg\":\"hello\"}' > shared/inbox/lucidia/msg-\$(date +%s).json${NC}"
echo ""
