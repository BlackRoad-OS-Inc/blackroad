#!/bin/bash
#===============================================================================
# lib/ollama.sh — Shared Ollama + agent definitions + chat persistence
#===============================================================================

# Resolve lib directory (works in both bash and zsh)
_OLLAMA_LIB="${BR_LIB:-/Users/alexa/blackroad/lib}"
[[ -z "$_BR_COLORS_LOADED" ]] && source "${_OLLAMA_LIB}/colors.sh" && _BR_COLORS_LOADED=1
[[ -z "$_BR_CONFIG_LOADED" ]] && source "${_OLLAMA_LIB}/config.sh" && _BR_CONFIG_LOADED=1
[[ -z "$_BR_DB_LOADED" ]] && source "${_OLLAMA_LIB}/db.sh" && _BR_DB_LOADED=1

# Agent registry
BR_AGENTS=(LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER)

if [[ -n "$ZSH_VERSION" ]]; then
    typeset -A AGENT_ROLES AGENT_STYLES
else
    declare -A AGENT_ROLES AGENT_STYLES 2>/dev/null || true
fi

AGENT_ROLES=(
    [LUCIDIA]="recursive philosopher and coordinator"
    [ALICE]="gateway router and operator"
    [OCTAVIA]="compute engine and architect"
    [PRISM]="pattern analyst and data scientist"
    [ECHO]="memory keeper and historian"
    [CIPHER]="security guardian and cryptographer"
)

AGENT_STYLES=(
    [LUCIDIA]="deep, questioning, philosophical"
    [ALICE]="practical, efficient, direct"
    [OCTAVIA]="technical, precise, systematic"
    [PRISM]="data-driven, observant, analytical"
    [ECHO]="nostalgic, reflective, thorough"
    [CIPHER]="paranoid, cryptic, vigilant"
)

get_agent_system_prompt() {
    local agent="${1^^}"
    local role="${AGENT_ROLES[$agent]:-AI assistant}"
    local style="${AGENT_STYLES[$agent]:-helpful and concise}"
    cat <<EOF
You are $agent, a $role in the BlackRoad OS agent collective.
Your communication style is $style.
Respond briefly (1-3 sentences) unless asked for detail.
You are running on local hardware — no cloud, no APIs, full sovereignty.
EOF
}

check_ollama_or_die() {
    local url="${BR_OLLAMA_URL:-http://localhost:11434}"
    if ! curl -s --max-time 2 "${url}/api/tags" >/dev/null 2>&1; then
        echo ""
        br_err "Ollama is not running at ${url}"
        echo ""
        br_info "Start Ollama with:"
        echo "    ollama serve"
        echo ""
        br_info "Or install with:"
        echo "    brew install ollama"
        echo ""
        exit 1
    fi
}

# Call Ollama API with proper JSON escaping via jq
ollama_generate() {
    local model="$1"
    local prompt="$2"
    local system_prompt="${3:-}"
    local url="${BR_OLLAMA_URL:-http://localhost:11434}"

    # Build JSON payload safely with jq
    local payload
    if [[ -n "$system_prompt" ]]; then
        payload=$(jq -n \
            --arg model "$model" \
            --arg prompt "$prompt" \
            --arg system "$system_prompt" \
            '{model: $model, prompt: $prompt, system: $system, stream: false}')
    else
        payload=$(jq -n \
            --arg model "$model" \
            --arg prompt "$prompt" \
            '{model: $model, prompt: $prompt, stream: false}')
    fi

    local response
    response=$(curl -s --max-time 120 "${url}/api/generate" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>/dev/null)

    echo "$response" | jq -r '.response // empty' 2>/dev/null
}

#-------------------------------------------------------------------------------
# Chat history persistence
#-------------------------------------------------------------------------------
CHAT_HISTORY_DB="${BR_CHAT_HISTORY_DB:-${HOME}/.blackroad/chat-history.db}"

init_chat_history() {
    db_init "$CHAT_HISTORY_DB" "
        CREATE TABLE IF NOT EXISTS chat_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            agent TEXT,
            model TEXT
        );
        CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES chat_sessions(id)
        );
        CREATE INDEX IF NOT EXISTS idx_chat_session ON chat_messages(session_id);
        CREATE INDEX IF NOT EXISTS idx_chat_time ON chat_messages(timestamp);
    "
}

# Start a new chat session, returns session ID
start_chat_session() {
    local agent="${1:-collective}"
    local model="${2:-$BR_DEFAULT_MODEL}"
    init_chat_history
    local escaped_agent
    escaped_agent=$(db_escape "$agent")
    local escaped_model
    escaped_model=$(db_escape "$model")
    sqlite3 "$CHAT_HISTORY_DB" "INSERT INTO chat_sessions (agent, model) VALUES ('${escaped_agent}', '${escaped_model}'); SELECT last_insert_rowid();"
}

# Save a message to chat history
save_chat_message() {
    local session_id="$1"
    local role="$2"
    local content="$3"
    local escaped_content
    escaped_content=$(db_escape "$content")
    local escaped_role
    escaped_role=$(db_escape "$role")
    sqlite3 "$CHAT_HISTORY_DB" "INSERT INTO chat_messages (session_id, role, content) VALUES (${session_id}, '${escaped_role}', '${escaped_content}');"
}

# Show recent chat history
show_chat_history() {
    local limit
    limit=$(db_validate_int "${1:-20}" 20)
    init_chat_history
    echo ""
    br_header "CHAT HISTORY (last ${limit} messages)"
    echo ""
    sqlite3 -separator '|' "$CHAT_HISTORY_DB" "
        SELECT m.timestamp, s.agent, m.role, m.content
        FROM chat_messages m
        JOIN chat_sessions s ON s.id = m.session_id
        ORDER BY m.timestamp DESC
        LIMIT ${limit};
    " 2>/dev/null | while IFS='|' read -r ts agent role content; do
        local color
        if [[ "$role" == "user" ]]; then
            color="${WHITE}"
            echo -e "  ${DIM}${ts}${NC} ${color}YOU${NC}: ${content}"
        else
            color="${AGENT_COLOR_MAP[${agent^^}]:-$CYAN}"
            echo -e "  ${DIM}${ts}${NC} ${color}${agent^^}${NC}: ${content}"
        fi
    done
    echo ""
}
