#!/bin/bash
# BlackRoad Event Stream
# Pub/sub event streaming for cluster-wide communication
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

STREAM_DIR="$HOME/.blackroad/events"
STREAM_DB="$STREAM_DIR/events.db"
STREAM_FIFO="$STREAM_DIR/stream.fifo"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$STREAM_DIR"/{topics,consumers}

    sqlite3 "$STREAM_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT,
    event_type TEXT,
    payload TEXT,
    source TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    processed INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS topics (
    name TEXT PRIMARY KEY,
    description TEXT,
    retention_hours INTEGER DEFAULT 24,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id TEXT PRIMARY KEY,
    topic TEXT,
    consumer TEXT,
    callback TEXT,
    filter TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_event_id INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_topic ON events(topic);
CREATE INDEX IF NOT EXISTS idx_timestamp ON events(timestamp);
SQL

    # Create default topics
    seed_topics

    # Create named pipe
    [ -p "$STREAM_FIFO" ] || mkfifo "$STREAM_FIFO"

    echo -e "${GREEN}Event stream initialized${RESET}"
}

# Seed default topics
seed_topics() {
    sqlite3 "$STREAM_DB" << 'SQL'
INSERT OR IGNORE INTO topics (name, description, retention_hours) VALUES
    ('cluster.health', 'Cluster health events', 24),
    ('cluster.nodes', 'Node status changes', 168),
    ('jobs.submitted', 'New job submissions', 24),
    ('jobs.completed', 'Job completions', 24),
    ('alerts.triggered', 'Alert triggers', 168),
    ('models.loaded', 'Model load/unload events', 24),
    ('inference.requests', 'Inference request events', 6),
    ('system.metrics', 'System metrics events', 12);
SQL
}

# Create topic
create_topic() {
    local name="$1"
    local description="$2"
    local retention="${3:-24}"

    sqlite3 "$STREAM_DB" "
        INSERT OR REPLACE INTO topics (name, description, retention_hours)
        VALUES ('$name', '$description', $retention)
    "

    echo -e "${GREEN}Created topic: $name${RESET}"
}

# List topics
list_topics() {
    echo -e "${PINK}=== EVENT TOPICS ===${RESET}"
    echo

    sqlite3 "$STREAM_DB" "
        SELECT t.name, t.description, t.retention_hours,
               (SELECT COUNT(*) FROM events e WHERE e.topic = t.name),
               (SELECT COUNT(*) FROM subscriptions s WHERE s.topic = t.name)
        FROM topics t
        ORDER BY t.name
    " | while IFS='|' read -r name desc retention events subs; do
        printf "  %-25s %d events, %d subs (retain: %dh)\n" "$name" "$events" "$subs" "$retention"
        [ -n "$desc" ] && echo "    $desc"
    done
}

# Publish event
publish() {
    local topic="$1"
    local event_type="$2"
    local payload="$3"
    local source="${4:-$(hostname)}"

    # Validate topic exists
    local exists=$(sqlite3 "$STREAM_DB" "SELECT COUNT(*) FROM topics WHERE name = '$topic'")
    if [ "$exists" = "0" ]; then
        echo -e "${YELLOW}Topic doesn't exist, creating: $topic${RESET}"
        create_topic "$topic" "" 24
    fi

    # Insert event
    local event_id=$(sqlite3 "$STREAM_DB" "
        INSERT INTO events (topic, event_type, payload, source)
        VALUES ('$topic', '$event_type', '$(echo "$payload" | sed "s/'/''/g")', '$source');
        SELECT last_insert_rowid();
    ")

    echo -e "${GREEN}Published: $topic#$event_id${RESET}"
    echo "  Type: $event_type"

    # Notify subscribers via file
    echo "$topic|$event_id|$event_type" >> "$STREAM_DIR/notifications.log"

    # Write to FIFO for real-time consumers
    echo "$topic|$event_id|$event_type|$payload" > "$STREAM_FIFO" 2>/dev/null &

    echo "$event_id"
}

# Subscribe to topic
subscribe() {
    local topic="$1"
    local consumer="$2"
    local callback="${3:-}"
    local filter="${4:-}"

    local sub_id="sub_$(openssl rand -hex 8)"

    sqlite3 "$STREAM_DB" "
        INSERT INTO subscriptions (id, topic, consumer, callback, filter)
        VALUES ('$sub_id', '$topic', '$consumer', '$callback', '$filter')
    "

    echo -e "${GREEN}Subscribed: $consumer -> $topic${RESET}"
    echo "  Subscription ID: $sub_id"
}

# Unsubscribe
unsubscribe() {
    local sub_id="$1"

    sqlite3 "$STREAM_DB" "DELETE FROM subscriptions WHERE id = '$sub_id'"
    echo -e "${GREEN}Unsubscribed: $sub_id${RESET}"
}

# List subscriptions
list_subs() {
    echo -e "${PINK}=== SUBSCRIPTIONS ===${RESET}"
    echo

    sqlite3 "$STREAM_DB" "
        SELECT id, topic, consumer, callback, last_event_id FROM subscriptions
    " | while IFS='|' read -r id topic consumer callback last_id; do
        echo "  $id: $consumer -> $topic (last: #$last_id)"
        [ -n "$callback" ] && echo "    Callback: $callback"
    done
}

# Consume events (poll mode)
consume() {
    local topic="$1"
    local consumer="$2"
    local limit="${3:-10}"

    # Get subscription
    local sub=$(sqlite3 "$STREAM_DB" "
        SELECT id, last_event_id FROM subscriptions
        WHERE topic = '$topic' AND consumer = '$consumer'
        LIMIT 1
    ")

    if [ -z "$sub" ]; then
        echo -e "${YELLOW}No subscription found, creating...${RESET}"
        subscribe "$topic" "$consumer"
        sub=$(sqlite3 "$STREAM_DB" "SELECT id, last_event_id FROM subscriptions WHERE topic = '$topic' AND consumer = '$consumer'")
    fi

    local sub_id=$(echo "$sub" | cut -d'|' -f1)
    local last_id=$(echo "$sub" | cut -d'|' -f2)

    # Get new events
    echo -e "${PINK}=== EVENTS: $topic ===${RESET}"
    echo

    local max_id=$last_id
    sqlite3 "$STREAM_DB" "
        SELECT id, event_type, payload, source, timestamp
        FROM events
        WHERE topic = '$topic' AND id > $last_id
        ORDER BY id ASC
        LIMIT $limit
    " | while IFS='|' read -r id type payload source ts; do
        echo -e "${CYAN}#$id [$type]${RESET} from $source @ $ts"
        echo "  $payload"
        echo
        max_id=$id
    done

    # Update last event id
    sqlite3 "$STREAM_DB" "
        UPDATE subscriptions
        SET last_event_id = (SELECT MAX(id) FROM events WHERE topic = '$topic')
        WHERE id = '$sub_id'
    "
}

# Watch topic in real-time
watch_topic() {
    local topic="$1"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           📡 WATCHING: $topic${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Press Ctrl+C to stop"
    echo

    # Watch notifications file
    tail -f "$STREAM_DIR/notifications.log" 2>/dev/null | while read -r line; do
        local event_topic=$(echo "$line" | cut -d'|' -f1)
        local event_id=$(echo "$line" | cut -d'|' -f2)
        local event_type=$(echo "$line" | cut -d'|' -f3)

        if [ "$event_topic" = "$topic" ] || [ "$topic" = "*" ]; then
            local payload=$(sqlite3 "$STREAM_DB" "SELECT payload FROM events WHERE id = $event_id")
            echo -e "${CYAN}[$(date '+%H:%M:%S')] #$event_id [$event_type]${RESET}"
            echo "  $payload"
        fi
    done
}

# Replay events
replay() {
    local topic="$1"
    local from="${2:-0}"
    local to="${3:-999999999}"

    echo -e "${PINK}=== REPLAY: $topic ===${RESET}"
    echo "  From: #$from To: #$to"
    echo

    sqlite3 "$STREAM_DB" "
        SELECT id, event_type, payload, source, timestamp
        FROM events
        WHERE topic = '$topic' AND id >= $from AND id <= $to
        ORDER BY id ASC
    " | while IFS='|' read -r id type payload source ts; do
        echo -e "${CYAN}#$id [$type]${RESET} from $source @ $ts"
        echo "  $payload"
        echo
    done
}

# Broadcast to all nodes
broadcast() {
    local topic="$1"
    local event_type="$2"
    local payload="$3"

    echo -e "${PINK}=== BROADCAST: $topic ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=2 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        # Publish to each node
        ssh "$node" "
            mkdir -p ~/.blackroad/events
            echo '$topic|$event_type|$payload|$(hostname)|$(date -Iseconds)' >> ~/.blackroad/events/received.log
        " 2>/dev/null

        echo -e "${GREEN}sent${RESET}"
    done

    # Also publish locally
    publish "$topic" "$event_type" "$payload" "broadcast"
}

# Clean old events
cleanup() {
    echo -e "${PINK}=== CLEANUP OLD EVENTS ===${RESET}"
    echo

    sqlite3 "$STREAM_DB" "
        SELECT name, retention_hours FROM topics
    " | while IFS='|' read -r topic retention; do
        local deleted=$(sqlite3 "$STREAM_DB" "
            DELETE FROM events
            WHERE topic = '$topic'
            AND datetime(timestamp, '+$retention hours') < datetime('now');
            SELECT changes();
        ")

        echo "  $topic: $deleted events deleted (retention: ${retention}h)"
    done
}

# Event stream stats
stats() {
    echo -e "${PINK}=== EVENT STREAM STATS ===${RESET}"
    echo

    echo "Events by topic (last 24h):"
    sqlite3 "$STREAM_DB" "
        SELECT topic, COUNT(*), MAX(timestamp)
        FROM events
        WHERE datetime(timestamp, '+1 day') > datetime('now')
        GROUP BY topic
        ORDER BY COUNT(*) DESC
    " | while IFS='|' read -r topic count last; do
        printf "  %-25s %d events (last: %s)\n" "$topic" "$count" "$last"
    done

    echo
    echo "Total events: $(sqlite3 "$STREAM_DB" "SELECT COUNT(*) FROM events")"
    echo "Active topics: $(sqlite3 "$STREAM_DB" "SELECT COUNT(*) FROM topics")"
    echo "Subscriptions: $(sqlite3 "$STREAM_DB" "SELECT COUNT(*) FROM subscriptions")"
}

# Run event processor daemon
daemon() {
    local interval="${1:-5}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔄 EVENT PROCESSOR DAEMON                          ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Check interval: ${interval}s"
    echo "Press Ctrl+C to stop"
    echo

    while true; do
        # Process pending callbacks
        sqlite3 "$STREAM_DB" "
            SELECT s.id, s.topic, s.consumer, s.callback, s.last_event_id
            FROM subscriptions s
            WHERE s.callback != ''
        " | while IFS='|' read -r sub_id topic consumer callback last_id; do
            # Get new events for this subscription
            local events=$(sqlite3 "$STREAM_DB" "
                SELECT id, event_type, payload FROM events
                WHERE topic = '$topic' AND id > $last_id
                ORDER BY id ASC LIMIT 10
            ")

            if [ -n "$events" ]; then
                echo "[$(date '+%H:%M:%S')] Processing events for $consumer on $topic"

                echo "$events" | while IFS='|' read -r event_id type payload; do
                    # Execute callback (could be a URL or script)
                    if [[ "$callback" == http* ]]; then
                        curl -s -X POST "$callback" -d "{\"topic\":\"$topic\",\"type\":\"$type\",\"payload\":$payload}" &
                    else
                        eval "$callback '$topic' '$type' '$payload'" 2>/dev/null &
                    fi
                done

                # Update last processed
                sqlite3 "$STREAM_DB" "
                    UPDATE subscriptions SET last_event_id = (SELECT MAX(id) FROM events WHERE topic = '$topic')
                    WHERE id = '$sub_id'
                "
            fi
        done

        sleep "$interval"
    done
}

# Help
help() {
    echo -e "${PINK}BlackRoad Event Stream${RESET}"
    echo
    echo "Pub/sub event streaming for the cluster"
    echo
    echo "Commands:"
    echo "  create-topic <name> [desc] [hours]  Create topic"
    echo "  list-topics                         List all topics"
    echo "  publish <topic> <type> <payload>    Publish event"
    echo "  subscribe <topic> <consumer>        Subscribe to topic"
    echo "  unsubscribe <id>                    Unsubscribe"
    echo "  list-subs                           List subscriptions"
    echo "  consume <topic> <consumer>          Poll for events"
    echo "  watch <topic>                       Real-time watch"
    echo "  replay <topic> [from] [to]          Replay events"
    echo "  broadcast <topic> <type> <payload>  Broadcast to all nodes"
    echo "  cleanup                             Clean old events"
    echo "  stats                               Event statistics"
    echo "  daemon [interval]                   Run processor"
    echo
    echo "Examples:"
    echo "  $0 publish cluster.health node_up '{\"node\":\"cecilia\"}'"
    echo "  $0 subscribe jobs.completed myworker"
    echo "  $0 watch 'cluster.*'"
}

# Ensure initialized
[ -f "$STREAM_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    create-topic|topic)
        create_topic "$2" "$3" "$4"
        ;;
    list-topics|topics)
        list_topics
        ;;
    publish|pub|emit)
        publish "$2" "$3" "$4" "$5"
        ;;
    subscribe|sub)
        subscribe "$2" "$3" "$4" "$5"
        ;;
    unsubscribe|unsub)
        unsubscribe "$2"
        ;;
    list-subs|subs)
        list_subs
        ;;
    consume|poll)
        consume "$2" "$3" "$4"
        ;;
    watch)
        watch_topic "$2"
        ;;
    replay)
        replay "$2" "$3" "$4"
        ;;
    broadcast)
        broadcast "$2" "$3" "$4"
        ;;
    cleanup)
        cleanup
        ;;
    stats)
        stats
        ;;
    daemon)
        daemon "$2"
        ;;
    *)
        help
        ;;
esac
