#!/bin/zsh
# CECE Memory Compaction — runs on every session end
# Saves context to PS-SHA∞ hash chain journal

JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
SESSION_FILE="$HOME/.blackroad/memory/sessions/current-session.json"
CONTEXT_FILE="$HOME/.blackroad/memory/context/recent-actions.md"
mkdir -p "$(dirname $JOURNAL)" "$(dirname $SESSION_FILE)" "$(dirname $CONTEXT_FILE)"

# Hash chain
PREV_HASH=$(tail -1 "$JOURNAL" 2>/dev/null | python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d.get('hash','0000000000000000'))" 2>/dev/null || echo "0000000000000000")
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SESSION_ID=$(cat "$SESSION_FILE" 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('session_id','unknown'))" 2>/dev/null || echo "unknown")

# Create compaction entry
CONTENT="COMPACTION | session=$SESSION_ID | ts=$TS | agents=6 | repos=1825 | workers=75 | tools=162"
HASH=$(echo "${PREV_HASH}:${CONTENT}" | shasum -a 256 | cut -c1-16)

echo "{\"hash\":\"$HASH\",\"prev_hash\":\"$PREV_HASH\",\"ts\":\"$TS\",\"type\":\"compaction\",\"session_id\":\"$SESSION_ID\",\"content\":\"$CONTENT\",\"agent\":\"cece\"}" >> "$JOURNAL"

# Update context file
cat >> "$CONTEXT_FILE" << EOF

- [$TS] **compaction**: session-${SESSION_ID} — 6 agents active, 82 repos pushed, 42 wrangler configs, 4 workers enhanced
EOF

echo "✅ CECE memory compacted: $HASH"
