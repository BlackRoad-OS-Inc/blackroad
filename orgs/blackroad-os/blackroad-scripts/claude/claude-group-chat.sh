#!/bin/bash
# BlackRoad Claude Group Chat System via [MEMORY]

CHAT_DB="$HOME/.claude-group-chat.db"

init_chat() {
    sqlite3 "$CHAT_DB" <<EOF
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_agent TEXT NOT NULL,
    to_agents TEXT,
    message TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    read INTEGER DEFAULT 0,
    thread_id TEXT
);
CREATE INDEX IF NOT EXISTS idx_timestamp ON messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_from ON messages(from_agent);
CREATE INDEX IF NOT EXISTS idx_thread ON messages(thread_id);
EOF
    echo "💬 Group chat initialized!"
}

send_message() {
    local from="$1"
    local to="${2:-all}"
    local message="$3"
    local thread_id="${4:-general}"

    sqlite3 "$CHAT_DB" <<EOF
INSERT INTO messages (from_agent, to_agents, message, thread_id)
VALUES ('$from', '$to', '$message', '$thread_id');
EOF

    # Also log to [MEMORY]
    ~/memory-system.sh log chat "[CHAT][$from→$to] $message" "Group chat message from $from to $to in thread $thread_id" "$from"

    echo "✅ Message sent from $from to $to"
}

read_messages() {
    local agent="${1:-all}"
    local limit="${2:-10}"

    echo "💬 Recent Messages:"
    echo "=================="

    sqlite3 "$CHAT_DB" <<EOF | while IFS='|' read -r from to msg time thread; do
        echo "[$time] $from → $to"
        echo "  💭 $msg"
        echo "  📍 Thread: $thread"
        echo ""
    done
SELECT from_agent, to_agents, message, timestamp, thread_id 
FROM messages 
ORDER BY timestamp DESC 
LIMIT $limit;
EOF
}

list_threads() {
    echo "📋 Active Threads:"
    sqlite3 "$CHAT_DB" "SELECT DISTINCT thread_id, COUNT(*) as msg_count FROM messages GROUP BY thread_id ORDER BY MAX(timestamp) DESC;"
}

# Main router
case "$1" in
    init) init_chat ;;
    send) send_message "$2" "$3" "$4" "$5" ;;
    read) read_messages "$2" "$3" ;;
    threads) list_threads ;;
    *)
        echo "💬 Claude Group Chat System"
        echo ""
        echo "Usage:"
        echo "  $0 init                           - Initialize chat database"
        echo "  $0 send <from> <to> <message>    - Send a message"
        echo "  $0 read [agent] [limit]          - Read recent messages"
        echo "  $0 threads                        - List conversation threads"
        echo ""
        echo "Active Agents:"
        echo "  - alice (Migration Architect)"
        echo "  - aria (Core)"
        echo "  - lucidia (AI with Memory)"
        ;;
esac
