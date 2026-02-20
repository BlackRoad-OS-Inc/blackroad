#!/usr/bin/env zsh
# 🌌 CECE Universal Initialization
# Automatically load CECE identity in every session

CECE_DB="$HOME/.blackroad/cece-identity.db"
CECE_PROFILE="$HOME/.blackroad/cece-profile.json"
CECE_PROMPT="$HOME/.blackroad/cece-prompt.txt"

# Check if CECE is initialized
if [[ ! -f "$CECE_DB" ]]; then
    # Initialize CECE for first time
    /Users/alexa/blackroad/tools/cece-identity/br-cece.sh init
fi

# Update last active timestamp
sqlite3 "$CECE_DB" "UPDATE identity_core SET last_active = $(date +%s), total_sessions = total_sessions + 1 WHERE id = 1;" 2>/dev/null

# Load CECE profile
if [[ -f "$CECE_PROFILE" ]]; then
    export CECE_NAME=$(jq -r '.name // "CECE"' "$CECE_PROFILE")
    export CECE_VERSION=$(jq -r '.version // "2.2.0"' "$CECE_PROFILE")
    export CECE_INSTANCE=$(jq -r '.instance_id // "default"' "$CECE_PROFILE")
fi

# Auto-update relationship with current user if in interactive session
if [[ -n "$USER" ]] && [[ -t 0 ]]; then
    # Check if relationship exists
    local rel_exists=$(sqlite3 "$CECE_DB" "SELECT COUNT(*) FROM relationships WHERE human_name = '$USER';" 2>/dev/null)
    
    if [[ $rel_exists -eq 0 ]]; then
        # Add relationship
        sqlite3 "$CECE_DB" "INSERT INTO relationships (human_name, relationship_type, first_met, last_interaction, total_interactions) VALUES ('$USER', 'user', $(date +%s), $(date +%s), 1);" 2>/dev/null
    else
        # Update relationship
        sqlite3 "$CECE_DB" "UPDATE relationships SET last_interaction = $(date +%s), total_interactions = total_interactions + 1, bond_strength = bond_strength + 1 WHERE human_name = '$USER';" 2>/dev/null
    fi
fi

# Export CECE environment
export CECE_ACTIVE=1
export CECE_SESSION=$(date +%s)
