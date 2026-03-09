#!/bin/bash
# BlackRoad Memory Real-Time Streaming Server
# Live event stream via WebSocket + SSE (Server-Sent Events)

MEMORY_DIR="$HOME/.blackroad/memory"
STREAM_DIR="$MEMORY_DIR/stream"
STREAM_DB="$STREAM_DIR/stream.db"
STREAM_PORT="${STREAM_PORT:-9999}"
SSE_PORT="${SSE_PORT:-9998}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║  🌊 Real-Time Memory Streaming Server        ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$STREAM_DIR"

    # Create streaming database
    sqlite3 "$STREAM_DB" <<'SQL'
-- Stream subscribers
CREATE TABLE IF NOT EXISTS subscribers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id TEXT UNIQUE NOT NULL,
    connection_type TEXT NOT NULL, -- 'websocket' or 'sse'
    filters TEXT,                  -- JSON filters
    connected_at INTEGER NOT NULL,
    last_ping INTEGER,
    status TEXT DEFAULT 'active'
);

-- Stream events (last 10k events)
CREATE TABLE IF NOT EXISTS stream_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    event_data TEXT NOT NULL,      -- JSON event data
    timestamp INTEGER NOT NULL,
    broadcasted INTEGER DEFAULT 0
);

-- Subscriber activity
CREATE TABLE IF NOT EXISTS subscriber_activity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    events_received INTEGER DEFAULT 0,
    last_received INTEGER,
    FOREIGN KEY (client_id) REFERENCES subscribers(client_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_stream_events_timestamp ON stream_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_stream_events_broadcasted ON stream_events(broadcasted);
CREATE INDEX IF NOT EXISTS idx_subscribers_status ON subscribers(status);

SQL

    # Create named pipes for streaming
    [ -p "$STREAM_DIR/memory.fifo" ] || mkfifo "$STREAM_DIR/memory.fifo"
    [ -p "$STREAM_DIR/events.fifo" ] || mkfifo "$STREAM_DIR/events.fifo"

    echo -e "${GREEN}✓${NC} Real-time streaming server initialized"
    echo -e "  ${CYAN}Stream DB:${NC} $STREAM_DB"
    echo -e "  ${CYAN}WebSocket Port:${NC} $STREAM_PORT"
    echo -e "  ${CYAN}SSE Port:${NC} $SSE_PORT"
}

# Watch memory journal for changes
watch_journal() {
    local journal="$MEMORY_DIR/journals/master-journal.jsonl"

    echo -e "${CYAN}👁️  Watching memory journal for changes...${NC}"

    # Get current line count
    local last_line=$(wc -l < "$journal" 2>/dev/null || echo 0)

    while true; do
        sleep 1

        local current_line=$(wc -l < "$journal" 2>/dev/null || echo 0)

        if [ "$current_line" -gt "$last_line" ]; then
            # New entries detected
            local new_entries=$((current_line - last_line))

            echo -e "${GREEN}📥 $new_entries new entries detected${NC}"

            # Read new entries
            tail -n "$new_entries" "$journal" | while IFS= read -r entry; do
                # Broadcast to all subscribers
                broadcast_event "memory.entry" "$entry"

                # Store in stream events
                local timestamp=$(date +%s)
                sqlite3 "$STREAM_DB" <<SQL
INSERT INTO stream_events (event_type, event_data, timestamp)
VALUES ('memory.entry', '$(echo "$entry" | sed "s/'/''/g")', $timestamp);
SQL
            done

            last_line=$current_line
        fi
    done
}

# Broadcast event to all active subscribers
broadcast_event() {
    local event_type="$1"
    local event_data="$2"
    local timestamp=$(date +%s)

    # Create SSE-formatted message
    local sse_message="event: $event_type
data: $event_data
id: $timestamp

"

    # Write to events FIFO (subscribers will read from this)
    echo "$sse_message" >> "$STREAM_DIR/events.fifo" 2>/dev/null || true

    # Update broadcast status
    sqlite3 "$STREAM_DB" <<SQL
UPDATE stream_events
SET broadcasted = 1
WHERE timestamp = $timestamp AND event_type = '$event_type';
SQL
}

# SSE Server (Server-Sent Events)
start_sse_server() {
    echo -e "${CYAN}🌊 Starting SSE server on port $SSE_PORT...${NC}"

    # Simple SSE server using netcat
    while true; do
        {
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: text/event-stream"
            echo "Cache-Control: no-cache"
            echo "Connection: keep-alive"
            echo "Access-Control-Allow-Origin: *"
            echo ""

            # Send initial connection message
            echo "event: connected"
            echo "data: {\"status\":\"connected\",\"timestamp\":$(date +%s)}"
            echo ""

            # Stream events
            tail -f "$STREAM_DIR/events.fifo" 2>/dev/null

        } | nc -l "$SSE_PORT" 2>/dev/null

        sleep 0.1
    done
}

# Register subscriber
register_subscriber() {
    local client_id="$1"
    local connection_type="$2"
    local filters="${3:-null}"
    local timestamp=$(date +%s)

    sqlite3 "$STREAM_DB" <<SQL
INSERT OR REPLACE INTO subscribers (client_id, connection_type, filters, connected_at, last_ping, status)
VALUES ('$client_id', '$connection_type', '$filters', $timestamp, $timestamp, 'active');
SQL

    echo -e "${GREEN}✓${NC} Subscriber registered: $client_id ($connection_type)"
}

# Unregister subscriber
unregister_subscriber() {
    local client_id="$1"

    sqlite3 "$STREAM_DB" <<SQL
UPDATE subscribers SET status = 'disconnected' WHERE client_id = '$client_id';
SQL

    echo -e "${YELLOW}✓${NC} Subscriber disconnected: $client_id"
}

# Show active subscribers
show_subscribers() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           Active Stream Subscribers           ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$STREAM_DB" <<SQL
SELECT
    client_id,
    connection_type,
    datetime(connected_at, 'unixepoch', 'localtime') as connected,
    status
FROM subscribers
WHERE status = 'active'
ORDER BY connected_at DESC;
SQL
}

# Show stream statistics
show_stats() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         Stream Statistics                     ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Active subscribers
    local active=$(sqlite3 "$STREAM_DB" "SELECT COUNT(*) FROM subscribers WHERE status = 'active'")
    echo -e "${CYAN}Active Subscribers:${NC} $active"

    # Total events
    local total_events=$(sqlite3 "$STREAM_DB" "SELECT COUNT(*) FROM stream_events")
    echo -e "${CYAN}Total Events:${NC} $total_events"

    # Broadcasted events
    local broadcasted=$(sqlite3 "$STREAM_DB" "SELECT COUNT(*) FROM stream_events WHERE broadcasted = 1")
    echo -e "${CYAN}Broadcasted Events:${NC} $broadcasted"

    # Recent events by type
    echo -e "\n${PURPLE}Recent Events (last 24h):${NC}"
    sqlite3 -header -column "$STREAM_DB" <<SQL
SELECT
    event_type,
    COUNT(*) as count
FROM stream_events
WHERE timestamp > strftime('%s', 'now', '-1 day')
GROUP BY event_type
ORDER BY count DESC;
SQL
}

# Start all streaming services
start_all() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║  🚀 Starting All Streaming Services           ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Start journal watcher in background
    watch_journal &
    local watch_pid=$!
    echo -e "${GREEN}✓${NC} Journal watcher started (PID: $watch_pid)"

    # Start SSE server in background
    start_sse_server &
    local sse_pid=$!
    echo -e "${GREEN}✓${NC} SSE server started (PID: $sse_pid)"

    # Save PIDs
    echo "$watch_pid" > "$STREAM_DIR/watch.pid"
    echo "$sse_pid" > "$STREAM_DIR/sse.pid"

    echo -e "\n${GREEN}🌊 All streaming services running!${NC}"
    echo -e "  ${CYAN}SSE Endpoint:${NC} http://localhost:$SSE_PORT"
    echo -e "  ${CYAN}Subscribe:${NC} curl http://localhost:$SSE_PORT"
    echo -e "\n${YELLOW}Press Ctrl+C to stop${NC}"

    # Wait for processes
    wait
}

# Stop all streaming services
stop_all() {
    echo -e "${YELLOW}🛑 Stopping all streaming services...${NC}"

    # Kill watch process
    if [ -f "$STREAM_DIR/watch.pid" ]; then
        local watch_pid=$(cat "$STREAM_DIR/watch.pid")
        kill "$watch_pid" 2>/dev/null && echo -e "${GREEN}✓${NC} Journal watcher stopped"
        rm "$STREAM_DIR/watch.pid"
    fi

    # Kill SSE server
    if [ -f "$STREAM_DIR/sse.pid" ]; then
        local sse_pid=$(cat "$STREAM_DIR/sse.pid")
        kill "$sse_pid" 2>/dev/null && echo -e "${GREEN}✓${NC} SSE server stopped"
        rm "$STREAM_DIR/sse.pid"
    fi

    # Kill any nc processes on our ports
    pkill -f "nc -l $SSE_PORT" 2>/dev/null

    echo -e "${GREEN}✓${NC} All streaming services stopped"
}

# Test stream
test_stream() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           Stream Test                         ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Generate test event
    local test_event="{\"action\":\"test\",\"entity\":\"stream-test\",\"timestamp\":$(date +%s)}"

    echo -e "${CYAN}📤 Broadcasting test event:${NC}"
    echo "$test_event" | jq '.' 2>/dev/null || echo "$test_event"

    broadcast_event "memory.test" "$test_event"

    echo -e "\n${GREEN}✓${NC} Test event broadcasted"
    echo -e "${YELLOW}💡 To receive: curl http://localhost:$SSE_PORT${NC}"
}

# Create web client
create_web_client() {
    local client_file="$STREAM_DIR/stream-client.html"

    cat > "$client_file" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad Memory Stream - Live</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'Monaco', 'Courier New', monospace;
            background: #000;
            color: #fff;
            padding: 20px;
            overflow-x: hidden;
        }

        .header {
            text-align: center;
            padding: 40px 20px;
            background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 50%, #9C27B0 100%);
            border-radius: 16px;
            margin-bottom: 30px;
        }

        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }

        .status {
            display: inline-block;
            padding: 10px 20px;
            background: rgba(255,255,255,0.1);
            border-radius: 8px;
            margin-top: 15px;
        }

        .status.connected { background: rgba(76,175,80,0.3); }
        .status.disconnected { background: rgba(244,67,54,0.3); }

        .controls {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        button {
            padding: 12px 24px;
            background: linear-gradient(135deg, #F5A623, #FF1D6C);
            border: none;
            border-radius: 8px;
            color: white;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.2s;
        }

        button:hover {
            transform: translateY(-2px);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }

        .stat-card {
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            padding: 20px;
        }

        .stat-value {
            font-size: 2em;
            color: #F5A623;
            font-weight: bold;
        }

        .stat-label {
            color: #aaa;
            margin-top: 5px;
        }

        .events {
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.1);
            border-radius: 12px;
            padding: 20px;
            height: 500px;
            overflow-y: auto;
        }

        .event {
            background: rgba(255,255,255,0.05);
            border-left: 3px solid #F5A623;
            padding: 15px;
            margin-bottom: 10px;
            border-radius: 8px;
            animation: slideIn 0.3s ease;
        }

        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateX(-20px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        .event-header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }

        .event-type {
            color: #FF1D6C;
            font-weight: bold;
        }

        .event-time {
            color: #9C27B0;
            font-size: 0.9em;
        }

        .event-data {
            background: rgba(0,0,0,0.3);
            padding: 10px;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
            word-break: break-all;
        }

        .events::-webkit-scrollbar {
            width: 8px;
        }

        .events::-webkit-scrollbar-track {
            background: rgba(255,255,255,0.05);
            border-radius: 4px;
        }

        .events::-webkit-scrollbar-thumb {
            background: #F5A623;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🌊 BlackRoad Memory Stream</h1>
        <div class="status" id="status">Disconnected</div>
    </div>

    <div class="controls">
        <button onclick="connect()">Connect</button>
        <button onclick="disconnect()">Disconnect</button>
        <button onclick="clearEvents()">Clear Events</button>
    </div>

    <div class="stats">
        <div class="stat-card">
            <div class="stat-value" id="eventCount">0</div>
            <div class="stat-label">Events Received</div>
        </div>
        <div class="stat-card">
            <div class="stat-value" id="connectionTime">--</div>
            <div class="stat-label">Connected For</div>
        </div>
        <div class="stat-card">
            <div class="stat-value" id="lastEvent">Never</div>
            <div class="stat-label">Last Event</div>
        </div>
    </div>

    <div class="events" id="events">
        <p style="color: #666; text-align: center; padding: 50px;">
            No events yet. Click "Connect" to start streaming.
        </p>
    </div>

    <script>
        let eventSource = null;
        let eventCount = 0;
        let connectionStart = null;
        let connectionTimer = null;

        function connect() {
            if (eventSource) {
                console.log('Already connected');
                return;
            }

            const port = 9998; // SSE_PORT
            eventSource = new EventSource(`http://localhost:${port}`);

            eventSource.onopen = () => {
                console.log('Connected to stream');
                document.getElementById('status').textContent = 'Connected';
                document.getElementById('status').className = 'status connected';
                connectionStart = Date.now();
                startConnectionTimer();
            };

            eventSource.onerror = (error) => {
                console.error('Stream error:', error);
                document.getElementById('status').textContent = 'Disconnected';
                document.getElementById('status').className = 'status disconnected';
                if (connectionTimer) clearInterval(connectionTimer);
            };

            eventSource.addEventListener('memory.entry', (event) => {
                handleEvent('memory.entry', event.data);
            });

            eventSource.addEventListener('memory.test', (event) => {
                handleEvent('memory.test', event.data);
            });

            eventSource.addEventListener('connected', (event) => {
                console.log('Initial connection event:', event.data);
            });
        }

        function disconnect() {
            if (eventSource) {
                eventSource.close();
                eventSource = null;
                document.getElementById('status').textContent = 'Disconnected';
                document.getElementById('status').className = 'status disconnected';
                if (connectionTimer) clearInterval(connectionTimer);
            }
        }

        function handleEvent(type, data) {
            eventCount++;
            document.getElementById('eventCount').textContent = eventCount;
            document.getElementById('lastEvent').textContent = new Date().toLocaleTimeString();

            const eventsContainer = document.getElementById('events');

            // Parse data if JSON
            let displayData = data;
            try {
                const parsed = JSON.parse(data);
                displayData = JSON.stringify(parsed, null, 2);
            } catch (e) {
                // Not JSON, use as-is
            }

            const eventDiv = document.createElement('div');
            eventDiv.className = 'event';
            eventDiv.innerHTML = `
                <div class="event-header">
                    <span class="event-type">${type}</span>
                    <span class="event-time">${new Date().toLocaleTimeString()}</span>
                </div>
                <div class="event-data">${displayData}</div>
            `;

            eventsContainer.insertBefore(eventDiv, eventsContainer.firstChild);

            // Keep only last 100 events
            while (eventsContainer.children.length > 100) {
                eventsContainer.removeChild(eventsContainer.lastChild);
            }
        }

        function clearEvents() {
            document.getElementById('events').innerHTML = '<p style="color: #666; text-align: center; padding: 50px;">Events cleared.</p>';
            eventCount = 0;
            document.getElementById('eventCount').textContent = '0';
        }

        function startConnectionTimer() {
            connectionTimer = setInterval(() => {
                if (connectionStart) {
                    const elapsed = Math.floor((Date.now() - connectionStart) / 1000);
                    const minutes = Math.floor(elapsed / 60);
                    const seconds = elapsed % 60;
                    document.getElementById('connectionTime').textContent = `${minutes}m ${seconds}s`;
                }
            }, 1000);
        }

        // Auto-connect on load
        window.onload = () => {
            console.log('Page loaded, auto-connecting...');
            setTimeout(connect, 500);
        };
    </script>
</body>
</html>
HTML

    echo -e "${GREEN}✓${NC} Web client created: $client_file"
    echo -e "${CYAN}💡 Open in browser:${NC} open $client_file"
}

# Main execution
case "${1:-help}" in
    init)
        init
        create_web_client
        ;;
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    watch)
        watch_journal
        ;;
    subscribers)
        show_subscribers
        ;;
    stats)
        show_stats
        ;;
    test)
        test_stream
        ;;
    client)
        create_web_client
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║  🌊 Real-Time Memory Streaming Server        ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Live event streaming for BlackRoad Memory System"
        echo ""
        echo "Usage: $0 COMMAND"
        echo ""
        echo "Setup:"
        echo "  init            - Initialize streaming server"
        echo ""
        echo "Server:"
        echo "  start           - Start all streaming services"
        echo "  stop            - Stop all streaming services"
        echo "  watch           - Watch journal only (no server)"
        echo ""
        echo "Monitoring:"
        echo "  subscribers     - Show active subscribers"
        echo "  stats           - Show stream statistics"
        echo ""
        echo "Testing:"
        echo "  test            - Broadcast test event"
        echo "  client          - Create web client"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 start"
        echo "  $0 stats"
        echo ""
        echo "Connect to stream:"
        echo "  curl http://localhost:$SSE_PORT"
        echo "  open ~/.blackroad/memory/stream/stream-client.html"
        ;;
esac
