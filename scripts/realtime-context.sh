#!/bin/bash
# BlackRoad Real-Time Context Refresh
# Provides instant context updates for Claude instances

set -e

VERSION="2.0.0-realtime"

# Configuration
MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL_DIR="$MEMORY_DIR/journals"
CONTEXT_DIR="$MEMORY_DIR/context"
SYNC_DIR="$MEMORY_DIR/sync"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Real-time context stream (for Claude to consume)
stream_context() {
    local instance_id="${1:-}"
    local last_position=0

    if [ -z "$instance_id" ]; then
        log_error "Usage: $0 stream <instance-id>"
        return 1
    fi

    echo -e "${CYAN}[STREAM]${NC} Starting real-time context stream for: $instance_id"
    echo -e "${CYAN}[STREAM]${NC} Press Ctrl+C to stop"
    echo ""

    # Get initial position
    if [ -f "$SYNC_DIR/instances/${instance_id}.json" ]; then
        last_position=$(jq -r '.journal_position' "$SYNC_DIR/instances/${instance_id}.json" 2>/dev/null || echo "0")
    fi

    # Stream new entries in real-time
    while true; do
        local current_count=$(wc -l < "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null || echo "0")

        if [ "$current_count" -gt "$last_position" ]; then
            local start_line=$((last_position + 1))

            echo -e "${GREEN}[UPDATE]${NC} New entries (${start_line}-${current_count}):"
            echo ""

            # Show new entries in context format
            sed -n "${start_line},${current_count}p" "$JOURNAL_DIR/master-journal.jsonl" | \
                jq -r '"  ⚡ [" + .timestamp + "] **" + .action + "**: " + .entity + " — " + .details'

            echo ""
            last_position=$current_count

            # Update instance position
            if [ -f "$SYNC_DIR/instances/${instance_id}.json" ]; then
                local temp_file="$SYNC_DIR/instances/${instance_id}.json.tmp"
                jq --arg pos "$current_count" '.journal_position = ($pos | tonumber) | .last_seen = "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'"' \
                    "$SYNC_DIR/instances/${instance_id}.json" > "$temp_file" && \
                    mv "$temp_file" "$SYNC_DIR/instances/${instance_id}.json"
            fi
        fi

        sleep 0.001  # 1ms polling
    done
}

# Get live context snapshot (what Claude should know RIGHT NOW)
get_live_context() {
    local instance_id="${1:-claude-live}"
    local format="${2:-markdown}"  # markdown, json, or compact

    echo -e "${CYAN}[LIVE]${NC} Generating live context snapshot..."

    if [ ! -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        echo "No journal found"
        return 1
    fi

    case "$format" in
        markdown)
            cat <<EOF
# 🔴 LIVE Memory Context
**Generated:** $(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
**Instance:** $instance_id
**Total Entries:** $(wc -l < "$JOURNAL_DIR/master-journal.jsonl")

---

## 🔥 Last 10 Actions (Real-Time)

$(tail -10 "$JOURNAL_DIR/master-journal.jsonl" | jq -r '"- [" + .timestamp + "] **" + .action + "**: " + .entity + " — " + .details')

---

## 🚀 Active Deployments

$(grep -E '"action":"deployed"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | tail -10 | jq -r '"- **" + .entity + "**: " + .details + " (" + .timestamp[0:19] + ")"' || echo "No deployments yet")

---

## 💡 Recent Decisions

$(grep -E '"action":"decided"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | tail -5 | jq -r '"- **" + .entity + "**: " + .details + " (" + .timestamp[0:19] + ")"' || echo "No decisions yet")

---

## 📊 Infrastructure State

$(grep -E '"action":"(configured|allocated|created)"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | tail -10 | jq -r '"- **" + .entity + "**: " + .details + " (" + .timestamp[0:19] + ")"' || echo "No infrastructure changes yet")

---

## 🔄 Active Claude Instances

$(if [ -d "$SYNC_DIR/instances" ]; then
    for instance_file in "$SYNC_DIR/instances"/*.json; do
        if [ -f "$instance_file" ]; then
            local iid=$(jq -r '.instance_id' "$instance_file")
            local pid=$(jq -r '.pid' "$instance_file")
            local pos=$(jq -r '.journal_position' "$instance_file")
            local last_seen=$(jq -r '.last_seen' "$instance_file")

            if ps -p "$pid" > /dev/null 2>&1; then
                echo "- **${iid}** (PID: $pid, Position: $pos, Last seen: $last_seen) ✅"
            fi
        fi
    done
else
    echo "No sync instances"
fi)

---

**Hash Chain Status:** $(tail -1 "$JOURNAL_DIR/master-journal.jsonl" | jq -r '"Last: " + .sha256[0:16] + "... → Parent: " + .parent_hash[0:16] + "..."')
EOF
            ;;

        json)
            cat <<EOF
{
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "instance_id": "$instance_id",
  "total_entries": $(wc -l < "$JOURNAL_DIR/master-journal.jsonl"),
  "recent_actions": $(tail -10 "$JOURNAL_DIR/master-journal.jsonl" | jq -s '.'),
  "active_deployments": $(grep -E '"action":"deployed"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | tail -10 | jq -s '.' || echo '[]'),
  "recent_decisions": $(grep -E '"action":"decided"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | tail -5 | jq -s '.' || echo '[]'),
  "active_instances": $(if [ -d "$SYNC_DIR/instances" ]; then
        find "$SYNC_DIR/instances" -name "*.json" -exec cat {} \; | jq -s '.'
    else
        echo '[]'
    fi)
}
EOF
            ;;

        compact)
            echo "=== LIVE CONTEXT ==="
            echo "Time: $(date -u +%H:%M:%S.%3N)"
            echo "Entries: $(wc -l < "$JOURNAL_DIR/master-journal.jsonl")"
            echo ""
            echo "Last 5 actions:"
            tail -5 "$JOURNAL_DIR/master-journal.jsonl" | jq -r '"  [" + .timestamp[11:23] + "] " + .action + ": " + .entity'
            echo ""
            ;;
    esac
}

# Auto-refresh context in background (for Claude to read periodically)
auto_refresh() {
    local instance_id="${1:-claude-auto}"
    local refresh_interval="${2:-0.001}"  # 1ms default
    local output_file="$CONTEXT_DIR/live-context-${instance_id}.md"

    echo -e "${CYAN}[AUTO-REFRESH]${NC} Starting auto-refresh for: $instance_id"
    echo -e "${CYAN}[AUTO-REFRESH]${NC} Interval: ${refresh_interval}s"
    echo -e "${CYAN}[AUTO-REFRESH]${NC} Output: $output_file"
    echo ""

    while true; do
        get_live_context "$instance_id" "markdown" > "$output_file"
        sleep "$refresh_interval"
    done
}

# Watch for specific actions (filtered real-time stream)
watch_actions() {
    local action_filter="$1"  # e.g., "deployed", "decided", "created"
    local instance_id="${2:-claude-watcher}"

    echo -e "${CYAN}[WATCH]${NC} Watching for actions matching: $action_filter"
    echo ""

    local last_position=0

    if [ -f "$SYNC_DIR/instances/${instance_id}.json" ]; then
        last_position=$(jq -r '.journal_position' "$SYNC_DIR/instances/${instance_id}.json" 2>/dev/null || echo "0")
    fi

    while true; do
        local current_count=$(wc -l < "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null || echo "0")

        if [ "$current_count" -gt "$last_position" ]; then
            local start_line=$((last_position + 1))

            # Show only matching actions
            sed -n "${start_line},${current_count}p" "$JOURNAL_DIR/master-journal.jsonl" | \
                jq -r "select(.action == \"$action_filter\") | \"⚡ [\" + .timestamp + \"] \" + .entity + \" — \" + .details" 2>/dev/null || true

            last_position=$current_count
        fi

        sleep 0.001  # 1ms polling
    done
}

# Get diff between two Claude instances
instance_diff() {
    local instance1="$1"
    local instance2="$2"

    if [ -z "$instance1" ] || [ -z "$instance2" ]; then
        echo "Usage: $0 diff <instance-id-1> <instance-id-2>"
        return 1
    fi

    local pos1=$(jq -r '.journal_position' "$SYNC_DIR/instances/${instance1}.json" 2>/dev/null || echo "0")
    local pos2=$(jq -r '.journal_position' "$SYNC_DIR/instances/${instance2}.json" 2>/dev/null || echo "0")

    echo -e "${BLUE}Instance Diff:${NC}"
    echo "  $instance1: position $pos1"
    echo "  $instance2: position $pos2"
    echo ""

    if [ "$pos1" -gt "$pos2" ]; then
        echo "  $instance1 is ahead by $((pos1 - pos2)) entries"
        echo ""
        echo "Entries $instance2 is missing:"
        sed -n "$((pos2 + 1)),${pos1}p" "$JOURNAL_DIR/master-journal.jsonl" | \
            jq -r '"  [" + .timestamp + "] " + .action + ": " + .entity'
    elif [ "$pos2" -gt "$pos1" ]; then
        echo "  $instance2 is ahead by $((pos2 - pos1)) entries"
        echo ""
        echo "Entries $instance1 is missing:"
        sed -n "$((pos1 + 1)),${pos2}p" "$JOURNAL_DIR/master-journal.jsonl" | \
            jq -r '"  [" + .timestamp + "] " + .action + ": " + .entity'
    else
        echo "  ✅ Instances are in sync"
    fi
}

# Show help
show_help() {
    cat <<EOF
BlackRoad Real-Time Context Refresh v${VERSION}

USAGE:
    memory-realtime-context.sh <command> [options]

COMMANDS:
    stream <instance-id>              Stream live updates (1ms polling)
    live [instance-id] [format]       Get live context snapshot
                                      Formats: markdown, json, compact
    auto-refresh <instance-id> [ms]   Auto-refresh context in background
    watch <action> [instance-id]      Watch for specific actions
    diff <id1> <id2>                  Show diff between instances
    help                              Show this help

EXAMPLES:
    # Stream live updates
    memory-realtime-context.sh stream claude-session-1

    # Get live markdown context (for Claude to read)
    memory-realtime-context.sh live claude-1 markdown

    # Get live JSON context
    memory-realtime-context.sh live claude-1 json

    # Auto-refresh every 1ms
    memory-realtime-context.sh auto-refresh claude-1 0.001

    # Watch only deployments
    memory-realtime-context.sh watch deployed

    # Compare two instances
    memory-realtime-context.sh diff claude-1 claude-2

REAL-TIME FEATURES:
    ✅ 1ms update polling
    ✅ Live context snapshots
    ✅ Filtered action watching
    ✅ Instance synchronization
    ✅ Auto-refresh background mode
    ✅ Multiple output formats

OUTPUT:
    Live contexts: $CONTEXT_DIR/live-context-*.md
    Sync status:   $SYNC_DIR/instances/

EOF
}

# Main command handler
case "${1:-help}" in
    stream)
        stream_context "${2:-}"
        ;;
    live)
        get_live_context "${2:-claude-live}" "${3:-markdown}"
        ;;
    auto-refresh)
        auto_refresh "${2:-claude-auto}" "${3:-0.001}"
        ;;
    watch)
        if [ -z "$2" ]; then
            echo "Usage: $0 watch <action> [instance-id]"
            exit 1
        fi
        watch_actions "$2" "${3:-claude-watcher}"
        ;;
    diff)
        instance_diff "$2" "$3"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
