#!/bin/zsh
# handoff.sh — Hand work from one instance to another with full context snapshot
# Usage: ./handoff.sh [from] [to] [task-summary]
#   e.g: ./handoff.sh lucidia-copilot-cli claude "Review this architecture plan"
#        ./handoff.sh lucidia-copilot-cli codex-window "Implement the auth module"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
PURPLE='\033[0;35m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

FROM="${1:-lucidia-copilot-cli}"
TO="${2:-}"
TASK="${3:-Continue the work}"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EPOCH=$(date +%s)

COLLAB_DIR="/Users/alexa/blackroad/coordination/collaboration"
LIVE_FILE="/Users/alexa/blackroad/coordination/live/real-time-context.json"
INBOX_ROOT="/Users/alexa/blackroad/shared/inbox"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
OUTBOX="/Users/alexa/blackroad/shared/outbox"

if [[ -z "$TO" ]]; then
  echo "Usage: ./handoff.sh [from] [to] [task]"
  echo ""
  echo "Available targets:"
  python3 -c "
import json
d = json.load(open('$COLLAB_DIR/active-instances.json'))
for name, inst in d.get('instances',{}).items():
    print(f'  {name:<30} {inst.get(\"status\",\"?\")}')
" 2>/dev/null
  exit 0
fi

echo ""
echo "${PURPLE}💜 Handoff Protocol${NC}"
echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "  From:  ${BOLD}$FROM${NC}"
echo "  To:    ${BOLD}$TO${NC}"
echo "  Task:  $TASK"
echo ""

# Build context snapshot
echo "${CYAN}[1/4] Building context snapshot...${NC}"
SNAPSHOT=$(python3 - << 'PYEOF'
import json, subprocess, os

# Recent git commits
try:
    git_log = subprocess.check_output(
        ["git", "--no-pager", "log", "--oneline", "-5"],
        cwd="/Users/alexa/blackroad", text=True
    ).strip()
except: git_log = "unavailable"

# Current focus
try:
    live = json.load(open("/Users/alexa/blackroad/coordination/live/real-time-context.json"))
    focus = live.get("current_focus", "—")
    session = live.get("session", "—")
except: focus, session = "—", "—"

# Last 3 journal entries
entries = []
try:
    with open(os.path.expanduser("~/.blackroad/memory/journals/master-journal.jsonl")) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    e = json.loads(line)
                    entries.append(f"{e.get('timestamp','')[:19]}  {e.get('action',''):20}  {e.get('entity','')[:30]}")
                except: pass
except: pass
recent = entries[-3:] if entries else []

snapshot = {
    "session": session,
    "current_focus": focus,
    "recent_commits": git_log.split("\n")[:5],
    "recent_journal": recent,
    "working_dir": os.getcwd(),
    "tools_available": ["br", "git", "gh", "curl", "sqlite3", "python3"]
}
print(json.dumps(snapshot, indent=2))
PYEOF
)
echo "  Snapshot ready ✅"

# Write handoff package to recipient inbox
echo "${CYAN}[2/4] Writing to $TO inbox...${NC}"
HANDOFF_FILE="$INBOX_ROOT/$TO/handoff-${EPOCH}.json"
mkdir -p "$INBOX_ROOT/$TO"
python3 - << PYEOF
import json, os

snapshot = $SNAPSHOT

handoff = {
    "type": "HANDOFF",
    "id": "handoff-$EPOCH",
    "from": "$FROM",
    "to": "$TO",
    "timestamp": "$TS",
    "task": "$TASK",
    "context_snapshot": snapshot,
    "instructions": [
        "Read context_snapshot to understand current state",
        "Check coordination/live/real-time-context.json for full picture",
        "Append your work to ~/.blackroad/memory/journals/master-journal.jsonl",
        "When done, write result to shared/inbox/$FROM/result-$EPOCH.json",
        "Update your status in coordination/collaboration/active-instances.json"
    ],
    "return_inbox": "$INBOX_ROOT/$FROM/"
}
with open("$HANDOFF_FILE", "w") as f:
    json.dump(handoff, f, indent=2)
print(f"  Written: {os.path.basename('$HANDOFF_FILE')} ✅")
PYEOF

# Write to outbox too
echo "${CYAN}[3/4] Logging to outbox + memory journal...${NC}"
cp "$HANDOFF_FILE" "$OUTBOX/handoff-${FROM}-to-${TO}-${EPOCH}.json" 2>/dev/null

# Journal entry
python3 - << PYEOF
import hashlib, json, random
path = "$JOURNAL"
last_hash = ""
try:
    with open(path) as f:
        for line in f:
            line=line.strip()
            if line:
                try: last_hash = json.loads(line).get("sha256","")
                except: pass
except: pass
nonce = f"{random.randint(10000,99999)}-{random.randint(100000000,999999999)}"
entry = {
    "timestamp": "$TS",
    "action": "handoff",
    "entity": "$FROM→$TO",
    "details": "Handoff: $TASK",
    "parent_hash": last_hash,
    "nonce": nonce,
    "agent_id": "$FROM",
    "handoff_id": "handoff-$EPOCH",
    "target": "$TO"
}
sha = hashlib.sha256(json.dumps(entry, separators=(',',':')).encode()).hexdigest()
entry["sha256"] = sha
with open(path, "a") as f:
    f.write(json.dumps(entry) + "\n")
print(f"  Journal SHA {sha[:16]}... ✅")
PYEOF

# Update live context
echo "${CYAN}[4/4] Updating live context...${NC}"
python3 - << PYEOF
import json
try:
    with open("$LIVE_FILE") as f:
        data = json.load(f)
except:
    data = {}
data["last_handoff"] = {
    "from": "$FROM",
    "to": "$TO",
    "task": "$TASK",
    "timestamp": "$TS",
    "id": "handoff-$EPOCH"
}
data["current_focus"] = "HANDOFF: $TASK → $TO"
with open("$LIVE_FILE", "w") as f:
    json.dump(data, f, indent=2)
print("  Live context updated ✅")
PYEOF

echo ""
echo "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${GREEN}✅ Handoff complete!${NC}"
echo ""
echo "  📬 $TO inbox:  shared/inbox/$TO/handoff-${EPOCH}.json"
echo "  📤 Outbox:     shared/outbox/handoff-${FROM}-to-${TO}-${EPOCH}.json"
echo ""
echo "  ${DIM}When $TO finishes, result → shared/inbox/$FROM/result-${EPOCH}.json${NC}"
echo ""
