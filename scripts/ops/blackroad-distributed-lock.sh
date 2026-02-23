#!/bin/bash
# BlackRoad Distributed Lock
# Coordination primitives for distributed operations
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

LOCK_DIR="$HOME/.blackroad/locks"
LOCK_DB="$LOCK_DIR/locks.db"
NODE_ID="${HOSTNAME:-$(hostname)}"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$LOCK_DIR"

    sqlite3 "$LOCK_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS locks (
    name TEXT PRIMARY KEY,
    owner TEXT,
    node TEXT,
    acquired_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,
    metadata TEXT
);

CREATE TABLE IF NOT EXISTS semaphores (
    name TEXT PRIMARY KEY,
    max_count INTEGER,
    current_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS semaphore_holders (
    semaphore TEXT,
    owner TEXT,
    node TEXT,
    acquired_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (semaphore, owner)
);

CREATE TABLE IF NOT EXISTS barriers (
    name TEXT PRIMARY KEY,
    required INTEGER,
    current INTEGER DEFAULT 0,
    status TEXT DEFAULT 'waiting'
);

CREATE TABLE IF NOT EXISTS barrier_participants (
    barrier TEXT,
    participant TEXT,
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (barrier, participant)
);

CREATE TABLE IF NOT EXISTS leader_election (
    group_name TEXT PRIMARY KEY,
    leader TEXT,
    node TEXT,
    term INTEGER DEFAULT 1,
    last_heartbeat DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

    echo -e "${GREEN}Distributed lock system initialized${RESET}"
    echo "  Node ID: $NODE_ID"
}

# Acquire lock
acquire() {
    local name="$1"
    local owner="${2:-$$}"
    local ttl="${3:-60}"  # seconds

    local expires=$(date -d "+${ttl} seconds" -Iseconds 2>/dev/null || date -v+${ttl}S -Iseconds)

    # Try to acquire
    local existing=$(sqlite3 "$LOCK_DB" "
        SELECT owner, node, expires_at FROM locks WHERE name = '$name'
    ")

    if [ -n "$existing" ]; then
        local existing_owner=$(echo "$existing" | cut -d'|' -f1)
        local existing_node=$(echo "$existing" | cut -d'|' -f2)
        local existing_expires=$(echo "$existing" | cut -d'|' -f3)

        # Check if expired
        if [ "$(date +%s)" -lt "$(date -d "$existing_expires" +%s 2>/dev/null || date -jf '%Y-%m-%dT%H:%M:%S' "$existing_expires" +%s)" ]; then
            echo -e "${RED}Lock held by $existing_owner on $existing_node${RESET}"
            return 1
        fi

        # Expired, take over
        sqlite3 "$LOCK_DB" "DELETE FROM locks WHERE name = '$name'"
    fi

    sqlite3 "$LOCK_DB" "
        INSERT INTO locks (name, owner, node, expires_at)
        VALUES ('$name', '$owner', '$NODE_ID', '$expires')
    "

    echo -e "${GREEN}Lock acquired: $name${RESET}"
    echo "  Owner: $owner"
    echo "  Expires: $expires"
}

# Release lock
release() {
    local name="$1"
    local owner="${2:-$$}"

    local lock=$(sqlite3 "$LOCK_DB" "SELECT owner FROM locks WHERE name = '$name'")

    if [ -z "$lock" ]; then
        echo -e "${YELLOW}Lock not held: $name${RESET}"
        return 0
    fi

    if [ "$lock" != "$owner" ]; then
        echo -e "${RED}Not lock owner (held by $lock)${RESET}"
        return 1
    fi

    sqlite3 "$LOCK_DB" "DELETE FROM locks WHERE name = '$name' AND owner = '$owner'"

    echo -e "${GREEN}Lock released: $name${RESET}"
}

# Extend lock TTL
extend() {
    local name="$1"
    local owner="${2:-$$}"
    local ttl="${3:-60}"

    local expires=$(date -d "+${ttl} seconds" -Iseconds 2>/dev/null || date -v+${ttl}S -Iseconds)

    sqlite3 "$LOCK_DB" "
        UPDATE locks SET expires_at = '$expires'
        WHERE name = '$name' AND owner = '$owner'
    "

    echo -e "${GREEN}Lock extended: $name until $expires${RESET}"
}

# Try lock with retry
try_lock() {
    local name="$1"
    local owner="${2:-$$}"
    local retries="${3:-10}"
    local delay="${4:-1}"

    for i in $(seq 1 $retries); do
        if acquire "$name" "$owner" >/dev/null 2>&1; then
            echo -e "${GREEN}Lock acquired after $i attempts${RESET}"
            return 0
        fi
        sleep "$delay"
    done

    echo -e "${RED}Failed to acquire lock after $retries attempts${RESET}"
    return 1
}

# With lock (execute command while holding lock)
with_lock() {
    local name="$1"
    shift
    local cmd="$*"

    if ! acquire "$name" "$$" 300 >/dev/null; then
        echo -e "${RED}Could not acquire lock${RESET}"
        return 1
    fi

    echo -e "${BLUE}Executing with lock: $name${RESET}"

    # Execute command
    eval "$cmd"
    local result=$?

    release "$name" "$$" >/dev/null

    return $result
}

# Create semaphore
semaphore_create() {
    local name="$1"
    local max="${2:-1}"

    sqlite3 "$LOCK_DB" "
        INSERT OR REPLACE INTO semaphores (name, max_count, current_count)
        VALUES ('$name', $max, 0)
    "

    echo -e "${GREEN}Semaphore created: $name (max: $max)${RESET}"
}

# Acquire semaphore slot
semaphore_acquire() {
    local name="$1"
    local owner="${2:-$$}"

    local sem=$(sqlite3 "$LOCK_DB" "SELECT max_count, current_count FROM semaphores WHERE name = '$name'")

    if [ -z "$sem" ]; then
        echo -e "${RED}Semaphore not found: $name${RESET}"
        return 1
    fi

    local max=$(echo "$sem" | cut -d'|' -f1)
    local current=$(echo "$sem" | cut -d'|' -f2)

    if [ "$current" -ge "$max" ]; then
        echo -e "${YELLOW}Semaphore full: $name ($current/$max)${RESET}"
        return 1
    fi

    sqlite3 "$LOCK_DB" "
        UPDATE semaphores SET current_count = current_count + 1 WHERE name = '$name';
        INSERT INTO semaphore_holders (semaphore, owner, node)
        VALUES ('$name', '$owner', '$NODE_ID');
    "

    echo -e "${GREEN}Semaphore acquired: $name ($((current+1))/$max)${RESET}"
}

# Release semaphore slot
semaphore_release() {
    local name="$1"
    local owner="${2:-$$}"

    sqlite3 "$LOCK_DB" "
        DELETE FROM semaphore_holders WHERE semaphore = '$name' AND owner = '$owner';
        UPDATE semaphores SET current_count = current_count - 1
        WHERE name = '$name' AND current_count > 0;
    "

    echo -e "${GREEN}Semaphore released: $name${RESET}"
}

# Create barrier
barrier_create() {
    local name="$1"
    local required="$2"

    sqlite3 "$LOCK_DB" "
        INSERT OR REPLACE INTO barriers (name, required, current, status)
        VALUES ('$name', $required, 0, 'waiting')
    "

    echo -e "${GREEN}Barrier created: $name (waiting for $required)${RESET}"
}

# Wait at barrier
barrier_wait() {
    local name="$1"
    local participant="${2:-$NODE_ID}"
    local timeout="${3:-300}"

    # Join barrier
    sqlite3 "$LOCK_DB" "
        INSERT OR IGNORE INTO barrier_participants (barrier, participant)
        VALUES ('$name', '$participant');
        UPDATE barriers SET current = (SELECT COUNT(*) FROM barrier_participants WHERE barrier = '$name')
        WHERE name = '$name';
    "

    local start=$(date +%s)

    echo -e "${BLUE}Waiting at barrier: $name${RESET}"

    while true; do
        local barrier=$(sqlite3 "$LOCK_DB" "SELECT required, current, status FROM barriers WHERE name = '$name'")
        local required=$(echo "$barrier" | cut -d'|' -f1)
        local current=$(echo "$barrier" | cut -d'|' -f2)
        local status=$(echo "$barrier" | cut -d'|' -f3)

        if [ "$current" -ge "$required" ] || [ "$status" = "released" ]; then
            sqlite3 "$LOCK_DB" "UPDATE barriers SET status = 'released' WHERE name = '$name'"
            echo -e "${GREEN}Barrier released: $name ($current/$required)${RESET}"
            return 0
        fi

        if [ $(($(date +%s) - start)) -ge "$timeout" ]; then
            echo -e "${RED}Barrier timeout: $name${RESET}"
            return 1
        fi

        sleep 1
    done
}

# Leader election
elect() {
    local group="$1"
    local candidate="${2:-$NODE_ID}"

    local current=$(sqlite3 "$LOCK_DB" "SELECT leader, last_heartbeat FROM leader_election WHERE group_name = '$group'")

    if [ -n "$current" ]; then
        local leader=$(echo "$current" | cut -d'|' -f1)
        local heartbeat=$(echo "$current" | cut -d'|' -f2)

        # Check if leader is alive (heartbeat within 30s)
        local hb_epoch=$(date -d "$heartbeat" +%s 2>/dev/null || date -jf '%Y-%m-%dT%H:%M:%S' "$heartbeat" +%s 2>/dev/null || echo 0)
        local now=$(date +%s)

        if [ $((now - hb_epoch)) -lt 30 ]; then
            if [ "$leader" = "$candidate" ]; then
                # Refresh heartbeat
                sqlite3 "$LOCK_DB" "UPDATE leader_election SET last_heartbeat = datetime('now') WHERE group_name = '$group'"
                echo -e "${GREEN}Still leader: $candidate${RESET}"
            else
                echo -e "${BLUE}Current leader: $leader${RESET}"
            fi
            return 0
        fi
    fi

    # Become leader
    sqlite3 "$LOCK_DB" "
        INSERT OR REPLACE INTO leader_election (group_name, leader, node, term, last_heartbeat)
        VALUES ('$group', '$candidate', '$NODE_ID', COALESCE((SELECT term FROM leader_election WHERE group_name = '$group'), 0) + 1, datetime('now'))
    "

    echo -e "${GREEN}Elected as leader: $candidate (group: $group)${RESET}"
}

# Check if leader
is_leader() {
    local group="$1"
    local candidate="${2:-$NODE_ID}"

    local leader=$(sqlite3 "$LOCK_DB" "SELECT leader FROM leader_election WHERE group_name = '$group'")

    [ "$leader" = "$candidate" ]
}

# List locks
list() {
    echo -e "${PINK}=== DISTRIBUTED LOCKS ===${RESET}"
    echo

    echo "Active locks:"
    sqlite3 "$LOCK_DB" "SELECT name, owner, node, expires_at FROM locks" | while IFS='|' read -r name owner node expires; do
        printf "  %-20s owner:%-10s node:%-10s expires:%s\n" "$name" "$owner" "$node" "$expires"
    done

    echo
    echo "Semaphores:"
    sqlite3 "$LOCK_DB" "SELECT name, current_count, max_count FROM semaphores" | while IFS='|' read -r name current max; do
        printf "  %-20s %d/%d\n" "$name" "$current" "$max"
    done

    echo
    echo "Barriers:"
    sqlite3 "$LOCK_DB" "SELECT name, current, required, status FROM barriers" | while IFS='|' read -r name current required status; do
        printf "  %-20s %d/%d (%s)\n" "$name" "$current" "$required" "$status"
    done

    echo
    echo "Leaders:"
    sqlite3 "$LOCK_DB" "SELECT group_name, leader, term FROM leader_election" | while IFS='|' read -r group leader term; do
        printf "  %-20s leader:%-15s term:%d\n" "$group" "$leader" "$term"
    done
}

# Cleanup expired
cleanup() {
    sqlite3 "$LOCK_DB" "
        DELETE FROM locks WHERE datetime(expires_at) < datetime('now');
        DELETE FROM barriers WHERE status = 'released' AND datetime(
            (SELECT MAX(joined_at) FROM barrier_participants WHERE barrier = barriers.name),
            '+1 hour'
        ) < datetime('now');
    "

    echo -e "${GREEN}Cleanup complete${RESET}"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Distributed Lock${RESET}"
    echo
    echo "Coordination primitives for the cluster"
    echo
    echo "Locks:"
    echo "  acquire <name> [owner] [ttl]     Acquire lock"
    echo "  release <name> [owner]           Release lock"
    echo "  extend <name> [owner] [ttl]      Extend lock TTL"
    echo "  try <name> [owner] [retries]     Try with retries"
    echo "  with <name> <command>            Execute with lock"
    echo
    echo "Semaphores:"
    echo "  sem-create <name> [max]          Create semaphore"
    echo "  sem-acquire <name> [owner]       Acquire slot"
    echo "  sem-release <name> [owner]       Release slot"
    echo
    echo "Barriers:"
    echo "  barrier-create <name> <count>    Create barrier"
    echo "  barrier-wait <name> [id]         Wait at barrier"
    echo
    echo "Leader Election:"
    echo "  elect <group> [candidate]        Run election"
    echo "  is-leader <group> [candidate]    Check if leader"
    echo
    echo "  list                             List all primitives"
    echo "  cleanup                          Remove expired"
    echo
    echo "Examples:"
    echo "  $0 acquire model-download"
    echo "  $0 with db-migration 'python migrate.py'"
    echo "  $0 elect inference-cluster"
}

# Ensure initialized
[ -f "$LOCK_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    acquire|lock)
        acquire "$2" "$3" "$4"
        ;;
    release|unlock)
        release "$2" "$3"
        ;;
    extend|renew)
        extend "$2" "$3" "$4"
        ;;
    try|try-lock)
        try_lock "$2" "$3" "$4" "$5"
        ;;
    with|with-lock)
        shift
        with_lock "$@"
        ;;
    sem-create)
        semaphore_create "$2" "$3"
        ;;
    sem-acquire)
        semaphore_acquire "$2" "$3"
        ;;
    sem-release)
        semaphore_release "$2" "$3"
        ;;
    barrier-create)
        barrier_create "$2" "$3"
        ;;
    barrier-wait)
        barrier_wait "$2" "$3" "$4"
        ;;
    elect)
        elect "$2" "$3"
        ;;
    is-leader)
        is_leader "$2" "$3" && echo "yes" || echo "no"
        ;;
    list|ls)
        list
        ;;
    cleanup)
        cleanup
        ;;
    *)
        help
        ;;
esac
