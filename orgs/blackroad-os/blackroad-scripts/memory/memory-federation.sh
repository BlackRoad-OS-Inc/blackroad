#!/bin/bash
# BlackRoad Memory Federation System
# Sync memory across multiple machines/environments

MEMORY_DIR="$HOME/.blackroad/memory"
FEDERATION_DIR="$MEMORY_DIR/federation"
FEDERATION_DB="$FEDERATION_DIR/federation.db"
FEDERATION_PORT="${FEDERATION_PORT:-7777}"

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
    echo -e "${PURPLE}║     🌐 Memory Federation System               ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$FEDERATION_DIR/peers"

    # Create federation database
    sqlite3 "$FEDERATION_DB" <<'SQL'
-- Federation nodes
CREATE TABLE IF NOT EXISTS nodes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    node_id TEXT UNIQUE NOT NULL,
    hostname TEXT NOT NULL,
    ip_address TEXT,
    port INTEGER DEFAULT 7777,
    status TEXT DEFAULT 'active',      -- 'active', 'inactive', 'syncing'
    last_seen INTEGER,
    last_sync INTEGER,
    total_entries INTEGER DEFAULT 0,
    sync_offset INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL
);

-- Sync history
CREATE TABLE IF NOT EXISTS sync_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    node_id TEXT NOT NULL,
    sync_type TEXT NOT NULL,           -- 'push', 'pull', 'bidirectional'
    entries_sent INTEGER DEFAULT 0,
    entries_received INTEGER DEFAULT 0,
    duration INTEGER,                   -- milliseconds
    success INTEGER,
    error TEXT,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (node_id) REFERENCES nodes(node_id)
);

-- Sync conflicts
CREATE TABLE IF NOT EXISTS sync_conflicts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    node_id TEXT NOT NULL,
    entry_hash TEXT NOT NULL,
    local_data TEXT NOT NULL,
    remote_data TEXT NOT NULL,
    resolution TEXT,                    -- 'local', 'remote', 'merged', 'pending'
    resolved_at INTEGER,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (node_id) REFERENCES nodes(node_id)
);

-- Federation events
CREATE TABLE IF NOT EXISTS federation_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    node_id TEXT,
    details TEXT,
    timestamp INTEGER NOT NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sync_history_node ON sync_history(node_id);
CREATE INDEX IF NOT EXISTS idx_sync_history_timestamp ON sync_history(timestamp);
CREATE INDEX IF NOT EXISTS idx_sync_conflicts_node ON sync_conflicts(node_id);
CREATE INDEX IF NOT EXISTS idx_federation_events_timestamp ON federation_events(timestamp);

SQL

    # Get this node's ID
    local node_id=$(hostname)_$(date +%s)
    local hostname=$(hostname)
    local ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    local timestamp=$(date +%s)

    # Register this node
    sqlite3 "$FEDERATION_DB" <<SQL
INSERT OR IGNORE INTO nodes (node_id, hostname, ip_address, port, last_seen, created_at)
VALUES ('$node_id', '$hostname', '$ip', $FEDERATION_PORT, $timestamp, $timestamp);
SQL

    # Save node ID
    echo "$node_id" > "$FEDERATION_DIR/node_id"

    echo -e "${GREEN}✓${NC} Federation system initialized"
    echo -e "  ${CYAN}Node ID:${NC} $node_id"
    echo -e "  ${CYAN}Hostname:${NC} $hostname"
    echo -e "  ${CYAN}IP:${NC} $ip"
    echo -e "  ${CYAN}Port:${NC} $FEDERATION_PORT"
}

# Get this node's ID
get_node_id() {
    if [ -f "$FEDERATION_DIR/node_id" ]; then
        cat "$FEDERATION_DIR/node_id"
    else
        echo "unknown"
    fi
}

# Discover peers on local network
discover_peers() {
    echo -e "${CYAN}🔍 Discovering peers on local network...${NC}"

    local my_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    local subnet=$(echo "$my_ip" | cut -d. -f1-3)

    echo -e "${YELLOW}Scanning subnet: $subnet.0/24${NC}"

    # Scan common IPs
    for i in {1..254}; do
        local ip="$subnet.$i"

        # Skip own IP
        [ "$ip" = "$my_ip" ] && continue

        # Try to connect to federation port
        timeout 0.1 bash -c "echo '' > /dev/tcp/$ip/$FEDERATION_PORT" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Found peer: $ip"

            # Register peer
            register_peer "$ip" "$FEDERATION_PORT"
        fi
    done

    echo -e "${CYAN}Discovery complete${NC}"
}

# Register a peer
register_peer() {
    local ip="$1"
    local port="${2:-$FEDERATION_PORT}"

    # Get peer info (simplified - in real impl would query peer)
    local node_id="peer_${ip//./_}_$(date +%s)"
    local hostname="$ip"
    local timestamp=$(date +%s)

    sqlite3 "$FEDERATION_DB" <<SQL
INSERT OR IGNORE INTO nodes (node_id, hostname, ip_address, port, last_seen, created_at)
VALUES ('$node_id', '$hostname', '$ip', $port, $timestamp, $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Registered peer: $node_id ($ip:$port)"

    # Log event
    log_event "peer_registered" "$node_id" "Registered peer at $ip:$port"
}

# Manually add peer
add_peer() {
    local peer_address="$1"  # format: hostname:port or ip:port

    if [ -z "$peer_address" ]; then
        echo -e "${RED}Error: Peer address required${NC}"
        echo "Usage: $0 add-peer HOSTNAME:PORT"
        return 1
    fi

    local hostname=$(echo "$peer_address" | cut -d: -f1)
    local port=$(echo "$peer_address" | cut -d: -f2)

    [ -z "$port" ] && port=$FEDERATION_PORT

    # Resolve IP
    local ip=$(host "$hostname" 2>/dev/null | grep "has address" | head -1 | awk '{print $4}')

    if [ -z "$ip" ]; then
        ip="$hostname"  # Assume it's already an IP
    fi

    register_peer "$ip" "$port"
}

# Remove peer
remove_peer() {
    local node_id="$1"

    if [ -z "$node_id" ]; then
        echo -e "${RED}Error: Node ID required${NC}"
        return 1
    fi

    sqlite3 "$FEDERATION_DB" <<SQL
UPDATE nodes SET status = 'inactive' WHERE node_id = '$node_id';
SQL

    echo -e "${GREEN}✓${NC} Peer removed: $node_id"

    log_event "peer_removed" "$node_id" "Peer marked as inactive"
}

# List all peers
list_peers() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         Federation Peers                      ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$FEDERATION_DB" <<SQL
SELECT
    node_id,
    hostname,
    ip_address,
    port,
    status,
    datetime(last_seen, 'unixepoch', 'localtime') as last_seen,
    total_entries
FROM nodes
ORDER BY last_seen DESC;
SQL
}

# Sync with peer (push)
sync_push() {
    local node_id="$1"
    local limit="${2:-100}"

    if [ -z "$node_id" ]; then
        echo -e "${RED}Error: Node ID required${NC}"
        return 1
    fi

    echo -e "${CYAN}📤 Pushing to peer: $node_id (limit: $limit)${NC}"

    local start_time=$(date +%s%3N)

    # Get peer info
    local peer_info=$(sqlite3 "$FEDERATION_DB" "SELECT ip_address, port FROM nodes WHERE node_id = '$node_id' AND status = 'active'")

    if [ -z "$peer_info" ]; then
        echo -e "${RED}✗${NC} Peer not found or inactive: $node_id"
        return 1
    fi

    local peer_ip=$(echo "$peer_info" | cut -d'|' -f1)
    local peer_port=$(echo "$peer_info" | cut -d'|' -f2)

    # Get sync offset
    local offset=$(sqlite3 "$FEDERATION_DB" "SELECT sync_offset FROM nodes WHERE node_id = '$node_id'")
    [ -z "$offset" ] && offset=0

    # Get entries to sync
    local journal="$MEMORY_DIR/journals/master-journal.jsonl"
    local entries=$(tail -n +$((offset + 1)) "$journal" | head -n "$limit")
    local count=$(echo "$entries" | grep -c '^')

    if [ "$count" -eq 0 ]; then
        echo -e "${YELLOW}⚠${NC}  No new entries to sync"
        return 0
    fi

    echo -e "${CYAN}Sending $count entries...${NC}"

    # In real implementation, would send via HTTP/gRPC
    # For demo, just save to peer directory
    mkdir -p "$FEDERATION_DIR/peers/$node_id"
    echo "$entries" > "$FEDERATION_DIR/peers/$node_id/push_$(date +%s).jsonl"

    # Update sync offset
    sqlite3 "$FEDERATION_DB" <<SQL
UPDATE nodes SET sync_offset = sync_offset + $count, last_sync = $(date +%s) WHERE node_id = '$node_id';
SQL

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    # Log sync
    sqlite3 "$FEDERATION_DB" <<SQL
INSERT INTO sync_history (node_id, sync_type, entries_sent, duration, success, timestamp)
VALUES ('$node_id', 'push', $count, $duration, 1, $(date +%s));
SQL

    echo -e "${GREEN}✓${NC} Sync completed: $count entries in ${duration}ms"

    log_event "sync_push" "$node_id" "Pushed $count entries"
}

# Sync with peer (pull)
sync_pull() {
    local node_id="$1"
    local limit="${2:-100}"

    if [ -z "$node_id" ]; then
        echo -e "${RED}Error: Node ID required${NC}"
        return 1
    fi

    echo -e "${CYAN}📥 Pulling from peer: $node_id (limit: $limit)${NC}"

    local start_time=$(date +%s%3N)

    # In real implementation, would request from peer
    # For demo, check peer directory
    local peer_dir="$FEDERATION_DIR/peers/$node_id"

    if [ ! -d "$peer_dir" ]; then
        echo -e "${YELLOW}⚠${NC}  No data from peer"
        return 0
    fi

    # Get latest push file
    local latest=$(ls -t "$peer_dir"/push_*.jsonl 2>/dev/null | head -1)

    if [ -z "$latest" ]; then
        echo -e "${YELLOW}⚠${NC}  No new entries from peer"
        return 0
    fi

    local count=$(wc -l < "$latest")

    echo -e "${CYAN}Receiving $count entries...${NC}"

    # Append to journal (in real impl, would validate & merge)
    cat "$latest" >> "$MEMORY_DIR/journals/master-journal.jsonl"

    # Mark as processed
    mv "$latest" "$latest.processed"

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    # Log sync
    sqlite3 "$FEDERATION_DB" <<SQL
INSERT INTO sync_history (node_id, sync_type, entries_received, duration, success, timestamp)
VALUES ('$node_id', 'pull', $count, $duration, 1, $(date +%s));
SQL

    echo -e "${GREEN}✓${NC} Sync completed: $count entries in ${duration}ms"

    log_event "sync_pull" "$node_id" "Pulled $count entries"
}

# Bidirectional sync
sync_bidirectional() {
    local node_id="$1"
    local limit="${2:-100}"

    echo -e "${CYAN}🔄 Bidirectional sync with: $node_id${NC}"

    sync_push "$node_id" "$limit"
    sync_pull "$node_id" "$limit"
}

# Sync all peers
sync_all() {
    local limit="${1:-100}"

    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Syncing All Peers                         ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Get all active peers
    sqlite3 "$FEDERATION_DB" "SELECT node_id FROM nodes WHERE status = 'active'" | \
    while IFS= read -r node_id; do
        [ -z "$node_id" ] && continue

        echo -e "\n${CYAN}Syncing: $node_id${NC}"
        sync_bidirectional "$node_id" "$limit"
    done

    echo -e "\n${GREEN}✓${NC} All peers synced"
}

# Show sync statistics
show_stats() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Federation Statistics                     ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Total peers
    local total_peers=$(sqlite3 "$FEDERATION_DB" "SELECT COUNT(*) FROM nodes")
    local active_peers=$(sqlite3 "$FEDERATION_DB" "SELECT COUNT(*) FROM nodes WHERE status = 'active'")

    echo -e "${CYAN}Peers:${NC}"
    echo -e "  Total: $total_peers"
    echo -e "  Active: $active_peers"

    # Sync statistics
    echo -e "\n${CYAN}Sync History (last 24h):${NC}"
    sqlite3 -header -column "$FEDERATION_DB" <<SQL
SELECT
    sync_type,
    COUNT(*) as syncs,
    SUM(entries_sent) as sent,
    SUM(entries_received) as received,
    AVG(duration) as avg_ms
FROM sync_history
WHERE timestamp > strftime('%s', 'now', '-1 day')
GROUP BY sync_type;
SQL

    # Conflicts
    local conflicts=$(sqlite3 "$FEDERATION_DB" "SELECT COUNT(*) FROM sync_conflicts WHERE resolution = 'pending'")
    echo -e "\n${CYAN}Conflicts:${NC}"
    echo -e "  Pending: $conflicts"
}

# Log federation event
log_event() {
    local event_type="$1"
    local node_id="$2"
    local details="$3"
    local timestamp=$(date +%s)

    sqlite3 "$FEDERATION_DB" <<SQL
INSERT INTO federation_events (event_type, node_id, details, timestamp)
VALUES ('$event_type', '$node_id', '$details', $timestamp);
SQL
}

# Show recent events
show_events() {
    local limit="${1:-20}"

    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Recent Federation Events                 ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$FEDERATION_DB" <<SQL
SELECT
    event_type,
    node_id,
    details,
    datetime(timestamp, 'unixepoch', 'localtime') as time
FROM federation_events
ORDER BY timestamp DESC
LIMIT $limit;
SQL
}

# Start federation server
start_server() {
    echo -e "${CYAN}🌐 Starting federation server on port $FEDERATION_PORT...${NC}"

    # Simple HTTP server for federation protocol
    while true; do
        {
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo ""
            echo "{\"status\":\"online\",\"node_id\":\"$(get_node_id)\",\"timestamp\":$(date +%s)}"
        } | nc -l "$FEDERATION_PORT" 2>/dev/null

        sleep 0.1
    done
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    discover)
        discover_peers
        ;;
    add-peer)
        add_peer "$2"
        ;;
    remove-peer)
        remove_peer "$2"
        ;;
    list)
        list_peers
        ;;
    push)
        sync_push "$2" "$3"
        ;;
    pull)
        sync_pull "$2" "$3"
        ;;
    sync)
        sync_bidirectional "$2" "$3"
        ;;
    sync-all)
        sync_all "$2"
        ;;
    stats)
        show_stats
        ;;
    events)
        show_events "$2"
        ;;
    server)
        start_server
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🌐 Memory Federation System               ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Sync memory across multiple machines"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                    - Initialize federation"
        echo "  server                  - Start federation server"
        echo ""
        echo "Peers:"
        echo "  discover                - Discover peers on network"
        echo "  add-peer HOST:PORT      - Manually add peer"
        echo "  remove-peer NODE_ID     - Remove peer"
        echo "  list                    - List all peers"
        echo ""
        echo "Sync:"
        echo "  push NODE_ID [LIMIT]    - Push to peer"
        echo "  pull NODE_ID [LIMIT]    - Pull from peer"
        echo "  sync NODE_ID [LIMIT]    - Bidirectional sync"
        echo "  sync-all [LIMIT]        - Sync with all peers"
        echo ""
        echo "Monitoring:"
        echo "  stats                   - Show statistics"
        echo "  events [LIMIT]          - Show recent events"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 server &"
        echo "  $0 discover"
        echo "  $0 add-peer 192.168.1.100:7777"
        echo "  $0 sync-all 100"
        ;;
esac
