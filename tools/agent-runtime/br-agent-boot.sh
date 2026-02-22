#!/bin/zsh
# BlackRoad Agent Boot — starts all 6 named agents on login
# Called by launchd: com.blackroad.agents.plist

RUNTIME="/Users/alexa/blackroad/tools/agent-runtime/br-runtime.sh"
LOG="$HOME/.blackroad/logs/agent-boot.log"
mkdir -p "$HOME/.blackroad/logs"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

log "=== Agent boot starting ==="

# Agent → model map
typeset -A AGENTS
AGENTS=(
    LUCIDIA   "lucidia:latest"
    ALICE     "llama3.2:3b"
    CIPHER    "qwen2.5:1.5b"
    OCTAVIA   "llama3.1:latest"
    ARIA      "qwen2.5:1.5b"
    SHELLFISH "llama3.2:1b"
)

# Wait for Ollama to be ready (up to 60s)
for i in {1..12}; do
    curl -sf http://localhost:11434/api/tags > /dev/null 2>&1 && break
    log "Waiting for Ollama ($i/12)..."
    sleep 5
done

for agent model in ${(kv)AGENTS}; do
    # Skip if already running
    state_file="$HOME/.blackroad/agents/active/${agent}.json"
    if [[ -f "$state_file" ]]; then
        pid=$(python3 -c "import json; d=json.load(open('$state_file')); print(d.get('pid',0))" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log "$agent already running (pid=$pid), skipping"
            continue
        fi
    fi
    log "Starting $agent with $model"
    zsh "$RUNTIME" start "$agent" "$model" >> "$LOG" 2>&1
done

log "=== Agent boot complete ==="
