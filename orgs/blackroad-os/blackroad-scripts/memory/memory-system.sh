#!/bin/bash
# BlackRoad Memory System Controller
# Provides continuous memory for Claude Code sessions via PS-SHA∞ journals

set -e

VERSION="1.0.0"

# Configuration
MEMORY_DIR="$HOME/.blackroad/memory"
SESSION_DIR="$MEMORY_DIR/sessions"
JOURNAL_DIR="$MEMORY_DIR/journals"
LEDGER_DIR="$MEMORY_DIR/ledger"
CONTEXT_DIR="$MEMORY_DIR/context"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize memory system
init_memory() {
    log_info "Initializing BlackRoad Memory System..."

    mkdir -p "$SESSION_DIR" "$JOURNAL_DIR" "$LEDGER_DIR" "$CONTEXT_DIR"

    # Create genesis entry if not exists
    if [ ! -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        local genesis_hash="$(echo -n "genesis" | shasum -a 256 | cut -d' ' -f1)"

        echo "{\"timestamp\":\"${timestamp}\",\"action\":\"genesis\",\"entity\":\"memory-system\",\"details\":\"BlackRoad Memory System initialized\",\"sha256\":\"${genesis_hash}\",\"parent_hash\":\"0000000000000000\"}" > "$JOURNAL_DIR/master-journal.jsonl"

        echo "{\"hash\":\"${genesis_hash}\",\"timestamp\":\"${timestamp}\",\"parent\":\"0000000000000000\",\"action_count\":0}" > "$LEDGER_DIR/memory-ledger.jsonl"

        log_success "Memory system initialized with genesis hash: ${genesis_hash:0:8}..."
    else
        log_warning "Memory system already initialized"
    fi

    # Create config
    cat > "$MEMORY_DIR/config.json" <<EOF
{
  "version": "${VERSION}",
  "initialized": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "hash_function": "sha256",
  "encoding": "utf-8"
}
EOF

    log_success "Memory system ready at: $MEMORY_DIR"
}

# Create new session
new_session() {
    local session_name="${1:-default}"
    local session_id="$(date +%Y-%m-%d-%H%M)-${session_name}"
    local session_file="$SESSION_DIR/${session_id}.json"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Get last action
    local last_action="N/A"
    if [ -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        last_action="$(tail -1 "$JOURNAL_DIR/master-journal.jsonl" | jq -r '.action + ": " + .entity' 2>/dev/null || echo "N/A")"
    fi

    # Count git repos
    local git_repos=$(find ~/projects -name .git -type d 2>/dev/null | wc -l | tr -d ' ')

    cat > "$session_file" <<EOF
{
  "session_id": "${session_id}",
  "timestamp": "${timestamp}",
  "type": "session_start",
  "context": {
    "working_directory": "$(pwd)",
    "git_repos": ${git_repos},
    "last_action": "${last_action}",
    "hostname": "$(hostname)",
    "user": "$(whoami)"
  }
}
EOF

    # Create symlink to current session
    ln -sf "$session_file" "$SESSION_DIR/current-session.json"

    # Log session start
    log_action "session_start" "$session_id" "Working directory: $(pwd)"

    log_success "Session created: $session_id"
}

# Log action to journal (with lock-free concurrent write support)
log_action() {
    local action="$1"
    local entity="$2"
    local details="${3:-}"

    if [ ! -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        log_error "Memory system not initialized. Run: $0 init"
        return 1
    fi

    # Use high-precision timestamp with nanoseconds for uniqueness
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

    # Lock-free read: get parent hash (atomic tail operation)
    local parent_hash="$(tail -1 "$JOURNAL_DIR/master-journal.jsonl" | jq -r '.sha256' 2>/dev/null || echo '0000000000000000')"

    # Add process ID and random nonce for uniqueness in concurrent writes
    local nonce="$$-$(od -An -N4 -tu4 < /dev/urandom | tr -d ' ')"
    local hash_input="${timestamp}${action}${entity}${details}${parent_hash}${nonce}"
    local sha256="$(echo -n "$hash_input" | shasum -a 256 | cut -d' ' -f1)"
    local action_count=$(wc -l < "$JOURNAL_DIR/master-journal.jsonl")

    # Prepare JSON entry (use jq to properly escape multiline strings, -c for compact)
    local temp_file="$JOURNAL_DIR/.temp-${sha256:0:16}.jsonl"
    jq -nc \
        --arg timestamp "$timestamp" \
        --arg action "$action" \
        --arg entity "$entity" \
        --arg details "$details" \
        --arg sha256 "$sha256" \
        --arg parent_hash "$parent_hash" \
        --arg nonce "$nonce" \
        '{timestamp: $timestamp, action: $action, entity: $entity, details: $details, sha256: $sha256, parent_hash: $parent_hash, nonce: $nonce}' \
        > "$temp_file"

    # Lock-free atomic append (>> is atomic at filesystem level for small writes)
    cat "$temp_file" >> "$JOURNAL_DIR/master-journal.jsonl"
    rm -f "$temp_file"

    # Update ledger (also atomic append)
    local ledger_entry="{\"hash\":\"${sha256}\",\"timestamp\":\"${timestamp}\",\"parent\":\"${parent_hash}\",\"action_count\":${action_count},\"nonce\":\"${nonce}\"}"
    echo "$ledger_entry" >> "$LEDGER_DIR/memory-ledger.jsonl"

    echo -e "${PURPLE}[MEMORY]${NC} Logged: ${action} → ${entity} (hash: ${sha256:0:8}...)"
}

# Synthesize context from journals
synthesize_context() {
    log_info "Synthesizing context from memory journals..."

    if [ ! -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        log_error "No journal found. Run: $0 init"
        return 1
    fi

    # Recent actions
    echo "# Recent Actions" > "$CONTEXT_DIR/recent-actions.md"
    echo "" >> "$CONTEXT_DIR/recent-actions.md"
    tail -50 "$JOURNAL_DIR/master-journal.jsonl" | \
        jq -r '"- [" + .timestamp[0:19] + "] **" + .action + "**: " + .entity + " — " + .details' \
        >> "$CONTEXT_DIR/recent-actions.md"

    # Infrastructure state
    echo "# Infrastructure State" > "$CONTEXT_DIR/infrastructure-state.md"
    echo "" >> "$CONTEXT_DIR/infrastructure-state.md"
    grep -E '"action":"(deployed|configured|allocated)"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | \
        tail -30 | \
        jq -r '"- **" + .entity + "**: " + .details + " (" + .timestamp[0:10] + ")"' \
        >> "$CONTEXT_DIR/infrastructure-state.md" || echo "No infrastructure changes yet" >> "$CONTEXT_DIR/infrastructure-state.md"

    # Decisions made
    echo "# Decisions Made" > "$CONTEXT_DIR/decisions.md"
    echo "" >> "$CONTEXT_DIR/decisions.md"
    grep -E '"action":"decided"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | \
        jq -r '"- **" + .entity + "**: " + .details + " (" + .timestamp[0:10] + ")"' \
        >> "$CONTEXT_DIR/decisions.md" || echo "No decisions logged yet" >> "$CONTEXT_DIR/decisions.md"

    log_success "Context synthesized to: $CONTEXT_DIR/"
}

# Show session summary
show_summary() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  🧠 BlackRoad Memory System Status    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    if [ ! -f "$SESSION_DIR/current-session.json" ]; then
        log_warning "No active session. Run: $0 new [name]"
        return 0
    fi

    # Current session
    local session_id=$(jq -r '.session_id' "$SESSION_DIR/current-session.json" 2>/dev/null || echo "unknown")
    local session_time=$(jq -r '.timestamp' "$SESSION_DIR/current-session.json" 2>/dev/null || echo "unknown")
    local working_dir=$(jq -r '.context.working_directory' "$SESSION_DIR/current-session.json" 2>/dev/null || echo "unknown")

    echo -e "  ${GREEN}Session:${NC} $session_id"
    echo -e "  ${GREEN}Started:${NC} $session_time"
    echo -e "  ${GREEN}Directory:${NC} $working_dir"
    echo ""

    # Journal stats
    if [ -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        local total_entries=$(wc -l < "$JOURNAL_DIR/master-journal.jsonl")
        local last_hash=$(tail -1 "$JOURNAL_DIR/master-journal.jsonl" | jq -r '.sha256' | cut -c1-16)
        local last_action=$(tail -1 "$JOURNAL_DIR/master-journal.jsonl" | jq -r '.action + ": " + .entity')

        echo -e "  ${GREEN}Total entries:${NC} $total_entries"
        echo -e "  ${GREEN}Last hash:${NC} ${last_hash}..."
        echo -e "  ${GREEN}Last action:${NC} $last_action"
        echo ""

        # Recent changes
        echo -e "${BLUE}Recent changes:${NC}"
        tail -5 "$JOURNAL_DIR/master-journal.jsonl" | \
            jq -r '"  [" + .timestamp[11:19] + "] " + .action + ": " + .entity' | \
            sed "s/^/  /"
    else
        log_warning "No journal entries yet"
    fi

    echo ""
}

# Verify integrity
verify_integrity() {
    log_info "Verifying memory integrity..."

    if [ ! -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        log_error "No journal found"
        return 1
    fi

    local entries=$(wc -l < "$JOURNAL_DIR/master-journal.jsonl")
    local valid=0
    local invalid=0
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))
        local parent_hash=$(echo "$line" | jq -r '.parent_hash')
        local stored_hash=$(echo "$line" | jq -r '.sha256')

        # Skip genesis entry
        if [ "$parent_hash" = "0000000000000000" ]; then
            ((valid++))
            continue
        fi

        # Verify parent exists in previous entries
        if head -$((line_num - 1)) "$JOURNAL_DIR/master-journal.jsonl" | grep -q "\"sha256\":\"$parent_hash\""; then
            ((valid++))
        else
            ((invalid++))
            log_warning "Broken chain at entry $line_num (hash: ${stored_hash:0:8}...)"
        fi
    done < "$JOURNAL_DIR/master-journal.jsonl"

    echo ""
    if [ $invalid -eq 0 ]; then
        log_success "Memory integrity verified ✅ ($valid entries, 0 broken)"
    else
        log_error "Found $invalid broken entries ❌ ($valid valid entries)"
        return 1
    fi
}

# Export context for Claude Code
export_context() {
    log_info "Exporting context for Claude Code..."

    synthesize_context

    cat > "$CONTEXT_DIR/session-restore-context.md" <<EOF
# 🧠 BlackRoad Session Context

**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

---

## Session Summary

$(show_summary 2>&1)

---

## Recent Infrastructure Changes

$(grep -E '"action":"(deployed|configured|allocated)"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | tail -20 | jq -r '"- [" + .timestamp[0:19] + "] **" + .action + "**: " + .entity + " — " + .details' || echo "No infrastructure changes yet")

---

## Recent Decisions

$(grep -E '"action":"decided"' "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null | tail -10 | jq -r '"- [" + .timestamp[0:19] + "] **" + .entity + "**: " + .details' || echo "No decisions logged yet")

---

## Active Deployments

$(ssh pi@aria64 "docker ps --format '{{.Names}} → {{.Ports}}'" 2>/dev/null || echo "Cannot reach aria64")

---

## Current Working State

**Directory:** $(pwd)

**Git Status:**
\`\`\`
$(git status -s 2>/dev/null || echo "Not in git repository")
\`\`\`

---

**Memory integrity:** $(verify_integrity &>/dev/null && echo "✅ Verified" || echo "⚠️  Check needed")

EOF

    log_success "Context exported to: $CONTEXT_DIR/session-restore-context.md"
    echo ""
    echo "View with: cat $CONTEXT_DIR/session-restore-context.md"
}

# Show help
show_help() {
    cat <<EOF
BlackRoad Memory System v${VERSION}

USAGE:
    memory-system.sh <command> [options]

COMMANDS:
    init                          Initialize memory system
    new [session-name]            Create new session
    log <action> <entity> [details]  Log action to journal
    summary                       Show current session summary
    synthesize                    Synthesize context from journals
    verify                        Verify memory integrity
    export                        Export context for Claude Code
    help                          Show this help

EXAMPLES:
    # Initialize
    memory-system.sh init

    # Start new session
    memory-system.sh new infrastructure-audit

    # Log actions
    memory-system.sh log deployed "api.blackroad.io" "Port 8080, FastAPI"
    memory-system.sh log created "new-script.sh" "Automated deployment"
    memory-system.sh log decided "architecture" "Using Headscale for mesh"

    # View state
    memory-system.sh summary
    memory-system.sh export

    # Verify
    memory-system.sh verify

MEMORY LOCATIONS:
    Sessions:  $SESSION_DIR/
    Journals:  $JOURNAL_DIR/
    Ledger:    $LEDGER_DIR/
    Context:   $CONTEXT_DIR/

EOF
}

# Main command handler
case "${1:-help}" in
    init)
        init_memory
        ;;
    new)
        new_session "${2:-default}"
        ;;
    log)
        if [ -z "$2" ] || [ -z "$3" ]; then
            log_error "Usage: $0 log <action> <entity> [details]"
            exit 1
        fi
        log_action "$2" "$3" "${4:-}"
        ;;
    synthesize)
        synthesize_context
        ;;
    summary)
        show_summary
        ;;
    verify)
        verify_integrity
        ;;
    export)
        export_context
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
