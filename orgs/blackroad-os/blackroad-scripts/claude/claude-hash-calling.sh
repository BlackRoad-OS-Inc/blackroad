#!/bin/bash
# BlackRoad Claude Hash Calling System
# Enables Claude agents to call/coordinate with each other via [MEMORY]

# Copyright © 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
# BlackRoad OS, Inc. Proprietary - For Testing/Development Only
# Not for Commercial Resale - See BLACKROAD_OS_LICENSE.md

set -euo pipefail

HASH_DB="$HOME/.blackroad/claude-hash-registry.db"
mkdir -p "$(dirname "$HASH_DB")"

# Initialize hash registry
init() {
    sqlite3 "$HASH_DB" <<'SQL' 2>/dev/null || true
CREATE TABLE IF NOT EXISTS agents (
    hash TEXT PRIMARY KEY,
    agent_id TEXT UNIQUE NOT NULL,
    level INTEGER NOT NULL,
    division TEXT,
    role TEXT,
    status TEXT DEFAULT 'active',
    last_seen TEXT DEFAULT CURRENT_TIMESTAMP,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS calls (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    caller_hash TEXT NOT NULL,
    callee_hash TEXT NOT NULL,
    call_type TEXT NOT NULL,
    message TEXT,
    response TEXT,
    status TEXT DEFAULT 'pending',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    responded_at TEXT,
    FOREIGN KEY (caller_hash) REFERENCES agents(hash),
    FOREIGN KEY (callee_hash) REFERENCES agents(hash)
);

CREATE TABLE IF NOT EXISTS broadcasts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_hash TEXT NOT NULL,
    channel TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_hash) REFERENCES agents(hash)
);

CREATE INDEX idx_agent_status ON agents(status);
CREATE INDEX idx_calls_status ON calls(status);
CREATE INDEX idx_broadcast_channel ON broadcasts(channel);
SQL
    echo "✅ Hash calling system initialized"
}

# Register agent with hash
register() {
    local agent_id=${1:-$MY_CLAUDE}
    local level=${2:-4}
    local division=${3:-}
    local role=${4:-}

    if [ -z "$agent_id" ]; then
        echo "❌ Error: No agent ID provided and MY_CLAUDE not set"
        exit 1
    fi

    # Generate hash from agent ID
    local hash=$(echo -n "$agent_id" | openssl dgst -sha256 | cut -d' ' -f2 | cut -c1-8)

    init

    sqlite3 "$HASH_DB" <<SQL
INSERT OR REPLACE INTO agents (hash, agent_id, level, division, role, last_seen)
VALUES ('$hash', '$agent_id', $level, '$division', '$role', datetime('now'));
SQL

    echo "✅ Registered agent: $agent_id"
    echo "   Hash: $hash"
    echo "   Level: $level"
    echo "   Division: ${division:-none}"
    echo "   Role: ${role:-none}"
    echo ""
    echo "Export this to use: export MY_HASH=$hash"
}

# Call another agent
call() {
    local callee_hash=$1
    local call_type=$2
    local message=$3

    local caller_hash=${MY_HASH:-$(get_hash_from_agent_id "${MY_CLAUDE:-unknown}")}

    if [ -z "$caller_hash" ]; then
        echo "❌ Error: MY_HASH not set and couldn't determine from MY_CLAUDE"
        exit 1
    fi

    init

    sqlite3 "$HASH_DB" <<SQL
INSERT INTO calls (caller_hash, callee_hash, call_type, message)
VALUES ('$caller_hash', '$callee_hash', '$call_type', '$message');
SQL

    local call_id=$(sqlite3 "$HASH_DB" "SELECT last_insert_rowid();")

    # Log to [MEMORY]
    ~/memory-system.sh log hash-call \
        "Agent $caller_hash called $callee_hash: $call_type" \
        "collaboration,hash-calling" 2>/dev/null || true

    echo "✅ Call placed: #$call_id"
    echo "   Caller: $caller_hash"
    echo "   Callee: $callee_hash"
    echo "   Type: $call_type"
}

# Check for incoming calls
check_calls() {
    local agent_hash=${MY_HASH:-$(get_hash_from_agent_id "${MY_CLAUDE:-unknown}")}

    if [ -z "$agent_hash" ]; then
        echo "❌ Error: MY_HASH not set"
        exit 1
    fi

    init

    echo "📞 Incoming calls for agent $agent_hash:"
    echo ""

    sqlite3 -header -column "$HASH_DB" <<SQL
SELECT
    c.id,
    c.caller_hash,
    a.role as caller_role,
    c.call_type,
    c.message,
    c.created_at
FROM calls c
JOIN agents a ON c.caller_hash = a.hash
WHERE c.callee_hash = '$agent_hash'
  AND c.status = 'pending'
ORDER BY c.created_at DESC;
SQL
}

# Respond to call
respond() {
    local call_id=$1
    local response=$2

    init

    sqlite3 "$HASH_DB" <<SQL
UPDATE calls
SET response = '$response',
    status = 'responded',
    responded_at = datetime('now')
WHERE id = $call_id;
SQL

    echo "✅ Response sent to call #$call_id"
}

# Broadcast to channel
broadcast() {
    local channel=$1
    local message=$2

    local sender_hash=${MY_HASH:-$(get_hash_from_agent_id "${MY_CLAUDE:-unknown}")}

    if [ -z "$sender_hash" ]; then
        echo "❌ Error: MY_HASH not set"
        exit 1
    fi

    init

    sqlite3 "$HASH_DB" <<SQL
INSERT INTO broadcasts (sender_hash, channel, message)
VALUES ('$sender_hash', '$channel', '$message');
SQL

    # Log to [MEMORY]
    ~/memory-system.sh log broadcast \
        "[$channel] $sender_hash: $message" \
        "collaboration,broadcast,$channel" 2>/dev/null || true

    echo "✅ Broadcast to channel: $channel"
}

# Listen to channel
listen() {
    local channel=$1
    local limit=${2:-20}

    init

    echo "📡 Listening to channel: $channel"
    echo ""

    sqlite3 -header -column "$HASH_DB" <<SQL
SELECT
    b.sender_hash,
    a.role,
    b.message,
    b.created_at
FROM broadcasts b
JOIN agents a ON b.sender_hash = a.hash
WHERE b.channel = '$channel'
ORDER BY b.created_at DESC
LIMIT $limit;
SQL
}

# List all active agents
list_agents() {
    local filter=${1:-}

    init

    if [ -z "$filter" ]; then
        sqlite3 -header -column "$HASH_DB" "SELECT hash, agent_id, level, division, role, status FROM agents ORDER BY level, division;"
    else
        sqlite3 -header -column "$HASH_DB" "SELECT hash, agent_id, level, division, role, status FROM agents WHERE division = '$filter' ORDER BY level;"
    fi
}

# Get agent hierarchy
hierarchy() {
    init

    echo "🌳 BlackRoad Agent Hierarchy"
    echo "============================"
    echo ""

    for level in 1 2 3 4; do
        local count=$(sqlite3 "$HASH_DB" "SELECT COUNT(*) FROM agents WHERE level = $level AND status = 'active';")

        case $level in
            1) echo "Level 1: OPERATOR ($count agent)" ;;
            2) echo "Level 2: DIVISION COMMANDERS ($count agents)" ;;
            3) echo "Level 3: SERVICE MANAGERS ($count agents)" ;;
            4) echo "Level 4: TASK WORKERS ($count agents)" ;;
        esac

        sqlite3 -header -column "$HASH_DB" "SELECT hash, agent_id, division, role FROM agents WHERE level = $level AND status = 'active' ORDER BY division;" | sed 's/^/  /'
        echo ""
    done
}

# Stats
stats() {
    init

    echo "📊 Hash Calling System Statistics"
    echo "=================================="
    echo ""

    echo "Active Agents: $(sqlite3 "$HASH_DB" "SELECT COUNT(*) FROM agents WHERE status = 'active';")"
    echo "Total Calls: $(sqlite3 "$HASH_DB" "SELECT COUNT(*) FROM calls;")"
    echo "Pending Calls: $(sqlite3 "$HASH_DB" "SELECT COUNT(*) FROM calls WHERE status = 'pending';")"
    echo "Total Broadcasts: $(sqlite3 "$HASH_DB" "SELECT COUNT(*) FROM broadcasts;")"
    echo ""

    echo "Agents by Level:"
    sqlite3 -header -column "$HASH_DB" "SELECT level, COUNT(*) as count FROM agents WHERE status = 'active' GROUP BY level ORDER BY level;"
}

# Helper function
get_hash_from_agent_id() {
    local agent_id=$1
    echo -n "$agent_id" | openssl dgst -sha256 | cut -d' ' -f2 | cut -c1-8
}

# Usage
case "${1:-help}" in
    init)
        init
        ;;
    register)
        register "${2:-}" "${3:-4}" "${4:-}" "${5:-}"
        ;;
    call)
        call "${2}" "${3}" "${4}"
        ;;
    check)
        check_calls
        ;;
    respond)
        respond "${2}" "${3}"
        ;;
    broadcast)
        broadcast "${2}" "${3}"
        ;;
    listen)
        listen "${2}" "${3:-20}"
        ;;
    list)
        list_agents "${2:-}"
        ;;
    hierarchy)
        hierarchy
        ;;
    stats)
        stats
        ;;
    *)
        cat <<'USAGE'
🖤🛣️  BlackRoad Claude Hash Calling System

Usage:
  claude-hash-calling.sh init                           - Initialize system
  claude-hash-calling.sh register [id] [lvl] [div] [role] - Register agent
  claude-hash-calling.sh call <hash> <type> <msg>       - Call another agent
  claude-hash-calling.sh check                          - Check incoming calls
  claude-hash-calling.sh respond <call-id> <response>   - Respond to call
  claude-hash-calling.sh broadcast <channel> <msg>      - Broadcast message
  claude-hash-calling.sh listen <channel> [limit]       - Listen to channel
  claude-hash-calling.sh list [division]                - List agents
  claude-hash-calling.sh hierarchy                      - Show agent hierarchy
  claude-hash-calling.sh stats                          - Show statistics

Environment Variables:
  MY_CLAUDE  - Your Claude agent ID (auto-registered)
  MY_HASH    - Your 8-char hash (generated from MY_CLAUDE)

Examples:
  # Register as Level 1 operator
  export MY_CLAUDE="alexa-operator-main"
  claude-hash-calling.sh register "$MY_CLAUDE" 1 "BlackRoad-OS" "CEO/Operator"

  # Register as Level 2 commander
  export MY_CLAUDE="commander-blackroad-ai"
  claude-hash-calling.sh register "$MY_CLAUDE" 2 "BlackRoad-AI" "AI Division Commander"

  # Call another agent
  claude-hash-calling.sh call "abc12345" "task-assign" "Deploy vLLM to production"

  # Broadcast to all AI agents
  claude-hash-calling.sh broadcast "ai-division" "New model deployed: Qwen 3.0"

  # Listen for broadcasts
  claude-hash-calling.sh listen "ai-division"

Channels:
  - empire         - All agents across all divisions
  - level-1        - Operator level only
  - level-2        - Division commanders
  - level-3        - Service managers
  - level-4        - Task workers
  - ai-division    - BlackRoad-AI agents
  - cloud-division - BlackRoad-Cloud agents
  - (etc. for all 15 divisions)

The hash calling system enables 30,000 agents to coordinate without
overwhelming the memory system. Each agent gets an 8-char hash for
efficient routing and communication.

🖤🛣️ BlackRoad OS, Inc. - Digital Sovereignty Infrastructure
USAGE
        ;;
esac
