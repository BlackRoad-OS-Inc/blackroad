#!/bin/bash
# BLACKROAD SESSION PERSISTENCE
# Save and restore context across terminal sessions

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
RESET='\033[0m'

SESSION_DIR="$HOME/.blackroad/sessions"
CURRENT_SESSION="$SESSION_DIR/current.json"
HISTORY_DIR="$SESSION_DIR/history"

mkdir -p "$SESSION_DIR" "$HISTORY_DIR"

# Generate session ID
gen_session_id() {
    echo "session-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 4)"
}

# Save current session state
save_session() {
    local session_id="${1:-$(gen_session_id)}"
    local context="$2"

    cat > "$CURRENT_SESSION" << EOF
{
    "id": "$session_id",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "cwd": "$(pwd)",
    "user": "$USER",
    "hostname": "$(hostname)",
    "my_claude": "${MY_CLAUDE:-unset}",
    "claude_name": "${CLAUDE_NAME:-unset}",
    "git_branch": "$(git branch --show-current 2>/dev/null || echo 'none')",
    "git_repo": "$(git remote get-url origin 2>/dev/null || echo 'none')",
    "context": "$context",
    "env": {
        "BLACKROAD_OS": "${BLACKROAD_OS:-0}",
        "BLACKROAD_STREAMING": "${BLACKROAD_STREAMING:-0}",
        "BLACKROAD_CURSOR_SYNC": "${BLACKROAD_CURSOR_SYNC:-0}"
    },
    "history": {
        "last_command": "$(fc -ln -1 2>/dev/null || echo 'none')",
        "commands_count": "$(history | wc -l | tr -d ' ')"
    }
}
EOF

    # Also save to history
    cp "$CURRENT_SESSION" "$HISTORY_DIR/${session_id}.json"

    echo -e "${PINK}[SESSION]${RESET} Saved: $session_id"
}

# Restore session state
restore_session() {
    if [[ ! -f "$CURRENT_SESSION" ]]; then
        echo -e "${AMBER}[SESSION]${RESET} No session to restore"
        return 1
    fi

    local session_id=$(jq -r '.id' "$CURRENT_SESSION")
    local cwd=$(jq -r '.cwd' "$CURRENT_SESSION")
    local my_claude=$(jq -r '.my_claude' "$CURRENT_SESSION")
    local claude_name=$(jq -r '.claude_name' "$CURRENT_SESSION")
    local context=$(jq -r '.context' "$CURRENT_SESSION")

    echo -e "${PINK}╔════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║      BLACKROAD SESSION RESTORED            ║${RESET}"
    echo -e "${PINK}╚════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "Session: ${AMBER}$session_id${RESET}"
    echo -e "Agent: ${AMBER}$claude_name${RESET} ($my_claude)"
    echo -e "Dir: ${AMBER}$cwd${RESET}"

    if [[ -n "$context" && "$context" != "null" ]]; then
        echo -e "Context: ${AMBER}$context${RESET}"
    fi
    echo ""

    # Export restored variables
    export MY_CLAUDE="$my_claude"
    export CLAUDE_NAME="$claude_name"

    # Return to directory if it exists
    if [[ -d "$cwd" ]]; then
        cd "$cwd"
    fi
}

# Show session info
show_session() {
    if [[ ! -f "$CURRENT_SESSION" ]]; then
        echo -e "${AMBER}[SESSION]${RESET} No active session"
        return 1
    fi

    echo -e "${PINK}Current Session:${RESET}"
    jq '.' "$CURRENT_SESSION"
}

# List session history
list_sessions() {
    echo -e "${PINK}Session History:${RESET}"
    ls -la "$HISTORY_DIR"/*.json 2>/dev/null | tail -10
}

# Clear session
clear_session() {
    rm -f "$CURRENT_SESSION"
    echo -e "${PINK}[SESSION]${RESET} Cleared"
}

# Auto-save hook (add to PROMPT_COMMAND or precmd)
auto_save() {
    save_session "" "" 2>/dev/null
}

# Main
case "${1:-show}" in
    save)
        save_session "$2" "$3"
        ;;
    restore)
        restore_session
        ;;
    show|status)
        show_session
        ;;
    list|history)
        list_sessions
        ;;
    clear)
        clear_session
        ;;
    auto)
        auto_save
        ;;
    *)
        echo "Usage: $0 {save|restore|show|list|clear|auto}"
        echo ""
        echo "  save [id] [context]  - Save current session"
        echo "  restore              - Restore last session"
        echo "  show                 - Show current session"
        echo "  list                 - List session history"
        echo "  clear                - Clear current session"
        echo "  auto                 - Auto-save (for hooks)"
        ;;
esac
