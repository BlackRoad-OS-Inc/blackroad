#!/bin/bash
#===============================================================================
# lib/config.sh — Configuration system for BR CLI
#===============================================================================

BR_CONFIG_FILE="${HOME}/.blackroad/cli.conf"
BR_VERSION="2.0.0"

# Defaults (used if not set in config file)
BR_DEFAULT_MODEL="${BR_DEFAULT_MODEL:-llama3.2}"
BR_OLLAMA_URL="${BR_OLLAMA_URL:-http://localhost:11434}"
BR_CHAT_HISTORY_DB="${BR_CHAT_HISTORY_DB:-${HOME}/.blackroad/chat-history.db}"

init_config() {
    mkdir -p "$(dirname "$BR_CONFIG_FILE")"
    if [[ ! -f "$BR_CONFIG_FILE" ]]; then
        cat > "$BR_CONFIG_FILE" <<'CONF'
# BlackRoad CLI Configuration
# Edit with: br config edit
# Reload with: br config show

# Version (do not edit)
BR_VERSION=2.0.0

# Default Ollama model for chat
BR_DEFAULT_MODEL=llama3.2

# Ollama API URL
BR_OLLAMA_URL=http://localhost:11434

# Chat history database path
BR_CHAT_HISTORY_DB=~/.blackroad/chat-history.db

# Agent home directory
BR_AGENT_HOME=~/.blackroad-agents
CONF
        echo "Created config: $BR_CONFIG_FILE"
    else
        echo "Config already exists: $BR_CONFIG_FILE"
    fi
}

load_config() {
    if [[ -f "$BR_CONFIG_FILE" ]]; then
        # Source config, ignoring comments and blank lines
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            # Expand ~ to HOME
            value="${value/#\~/$HOME}"
            # Export the variable
            export "$key=$value" 2>/dev/null
        done < "$BR_CONFIG_FILE"
    fi
}

show_config() {
    if [[ -f "$BR_CONFIG_FILE" ]]; then
        echo "Configuration: $BR_CONFIG_FILE"
        echo "────────────────────────────────────────"
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                echo -e "\033[2m${line}\033[0m"
            elif [[ -n "$line" ]]; then
                local key="${line%%=*}"
                local val="${line#*=}"
                echo -e "  \033[1;36m${key}\033[0m = \033[1;37m${val}\033[0m"
            fi
        done < "$BR_CONFIG_FILE"
    else
        echo "No config found. Run: br config init"
    fi
}

set_config() {
    local key=$1
    local value=$2
    if [[ -z "$key" ]] || [[ -z "$value" ]]; then
        echo "Usage: br config set <KEY> <value>"
        return 1
    fi
    if [[ ! -f "$BR_CONFIG_FILE" ]]; then
        init_config >/dev/null
    fi
    if grep -q "^${key}=" "$BR_CONFIG_FILE" 2>/dev/null; then
        # Update existing key
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s|^${key}=.*|${key}=${value}|" "$BR_CONFIG_FILE"
        else
            sed -i "s|^${key}=.*|${key}=${value}|" "$BR_CONFIG_FILE"
        fi
        echo "Updated: ${key}=${value}"
    else
        echo "${key}=${value}" >> "$BR_CONFIG_FILE"
        echo "Added: ${key}=${value}"
    fi
}

# Auto-load config on source
load_config
