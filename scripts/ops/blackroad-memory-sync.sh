#!/bin/bash
# Sync memory across all agents
MEMORY_DIR="$HOME/.blackroad/memory"
AGENTS="cecilia lucidia aria octavia shellfish"

sync_to_agents() {
    for host in $AGENTS; do
        echo "Syncing to $host..."
        rsync -avz --delete "$MEMORY_DIR/" "$host:~/.blackroad/memory/" 2>/dev/null &
    done
    wait
    echo "Memory synced to all agents"
}

sync_from_agent() {
    local host=$1
    echo "Pulling memory from $host..."
    rsync -avz "$host:~/.blackroad/memory/" "$MEMORY_DIR/"
}

case "${1:-sync}" in
    sync|push) sync_to_agents ;;
    pull) sync_from_agent "${2:-cecilia}" ;;
    *) echo "Usage: memory-sync [sync|pull <agent>]" ;;
esac
