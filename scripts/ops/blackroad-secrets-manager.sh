#!/bin/bash
# BlackRoad Secrets Manager
# Secure secrets management for the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

SECRETS_DIR="$HOME/.blackroad/secrets"
SECRETS_FILE="$SECRETS_DIR/vault.enc"
KEY_FILE="$SECRETS_DIR/.key"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize vault
init() {
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"

    if [ ! -f "$KEY_FILE" ]; then
        openssl rand -base64 32 > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        echo -e "${GREEN}Generated encryption key${RESET}"
    fi

    if [ ! -f "$SECRETS_FILE" ]; then
        echo "{}" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass file:"$KEY_FILE" > "$SECRETS_FILE"
        echo -e "${GREEN}Created encrypted vault${RESET}"
    fi

    echo -e "${GREEN}Secrets manager initialized${RESET}"
    echo "  Vault: $SECRETS_FILE"
}

# Decrypt vault
decrypt_vault() {
    openssl enc -aes-256-cbc -d -salt -pbkdf2 -pass file:"$KEY_FILE" < "$SECRETS_FILE" 2>/dev/null
}

# Encrypt and save vault
encrypt_vault() {
    local data="$1"
    echo "$data" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass file:"$KEY_FILE" > "$SECRETS_FILE"
}

# Set a secret
set_secret() {
    local key="$1"
    local value="$2"

    if [ -z "$key" ] || [ -z "$value" ]; then
        echo "Usage: set <key> <value>"
        return 1
    fi

    local vault=$(decrypt_vault)
    vault=$(echo "$vault" | jq --arg k "$key" --arg v "$value" '.[$k] = $v')
    encrypt_vault "$vault"

    echo -e "${GREEN}Secret set: $key${RESET}"

    # Log access
    echo "$(date -Iseconds) SET $key" >> "$SECRETS_DIR/audit.log"
}

# Get a secret
get_secret() {
    local key="$1"

    if [ -z "$key" ]; then
        echo "Usage: get <key>"
        return 1
    fi

    local value=$(decrypt_vault | jq -r --arg k "$key" '.[$k] // empty')

    if [ -z "$value" ]; then
        echo -e "${YELLOW}Secret not found: $key${RESET}"
        return 1
    fi

    echo "$value"

    # Log access
    echo "$(date -Iseconds) GET $key" >> "$SECRETS_DIR/audit.log"
}

# Delete a secret
delete_secret() {
    local key="$1"

    local vault=$(decrypt_vault)
    vault=$(echo "$vault" | jq --arg k "$key" 'del(.[$k])')
    encrypt_vault "$vault"

    echo -e "${GREEN}Secret deleted: $key${RESET}"

    echo "$(date -Iseconds) DELETE $key" >> "$SECRETS_DIR/audit.log"
}

# List all secrets (keys only)
list_secrets() {
    echo -e "${PINK}=== SECRETS ===${RESET}"
    echo

    local keys=$(decrypt_vault | jq -r 'keys[]')

    if [ -z "$keys" ]; then
        echo "No secrets stored"
        return
    fi

    echo "$keys" | while read -r key; do
        local len=$(decrypt_vault | jq -r --arg k "$key" '.[$k] | length')
        echo "  $key (${len} chars)"
    done
}

# Export secrets to env file
export_env() {
    local output="${1:-.env}"

    echo -e "${PINK}=== EXPORT TO ENV ===${RESET}"
    echo "Output: $output"
    echo

    > "$output"
    chmod 600 "$output"

    decrypt_vault | jq -r 'to_entries[] | "\(.key)=\(.value)"' >> "$output"

    local count=$(wc -l < "$output")
    echo -e "${GREEN}Exported $count secrets${RESET}"
}

# Import secrets from env file
import_env() {
    local input="$1"

    if [ ! -f "$input" ]; then
        echo -e "${RED}File not found: $input${RESET}"
        return 1
    fi

    echo -e "${PINK}=== IMPORT FROM ENV ===${RESET}"
    echo "Input: $input"
    echo

    local count=0
    while IFS='=' read -r key value; do
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue

        set_secret "$key" "$value" >/dev/null
        ((count++))
    done < "$input"

    echo -e "${GREEN}Imported $count secrets${RESET}"
}

# Distribute secrets to nodes
distribute() {
    local key="$1"
    local nodes="${2:-all}"

    local value=$(get_secret "$key" 2>/dev/null)

    if [ -z "$value" ]; then
        echo -e "${RED}Secret not found: $key${RESET}"
        return 1
    fi

    echo -e "${PINK}=== DISTRIBUTE SECRET ===${RESET}"
    echo "Key: $key"
    echo

    local target_nodes=("${ALL_NODES[@]}")
    [ "$nodes" != "all" ] && target_nodes=($nodes)

    for node in "${target_nodes[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        # Create secure temp file on node
        ssh "$node" "
            mkdir -p ~/.blackroad/secrets
            chmod 700 ~/.blackroad/secrets
            echo '$value' > ~/.blackroad/secrets/$key
            chmod 600 ~/.blackroad/secrets/$key
        "

        echo -e "${GREEN}distributed${RESET}"
    done

    echo "$(date -Iseconds) DISTRIBUTE $key -> ${target_nodes[*]}" >> "$SECRETS_DIR/audit.log"
}

# Rotate a secret
rotate() {
    local key="$1"
    local new_value="$2"

    if [ -z "$new_value" ]; then
        # Generate random value
        new_value=$(openssl rand -base64 32)
    fi

    local old_value=$(get_secret "$key" 2>/dev/null)

    if [ -n "$old_value" ]; then
        # Archive old value
        local archive_file="$SECRETS_DIR/archive/${key}_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$SECRETS_DIR/archive"
        echo "$old_value" | openssl enc -aes-256-cbc -salt -pbkdf2 -pass file:"$KEY_FILE" > "$archive_file"
    fi

    set_secret "$key" "$new_value"

    echo -e "${GREEN}Secret rotated: $key${RESET}"
    echo "$(date -Iseconds) ROTATE $key" >> "$SECRETS_DIR/audit.log"
}

# Audit log
audit() {
    local lines="${1:-20}"

    echo -e "${PINK}=== AUDIT LOG ===${RESET}"
    echo

    if [ -f "$SECRETS_DIR/audit.log" ]; then
        tail -n "$lines" "$SECRETS_DIR/audit.log"
    else
        echo "No audit log"
    fi
}

# Generate API key
generate() {
    local name="$1"
    local length="${2:-32}"

    local key=$(openssl rand -base64 "$length" | tr -d '\n')

    if [ -n "$name" ]; then
        set_secret "$name" "$key"
        echo -e "${GREEN}Generated and stored: $name${RESET}"
    fi

    echo "$key"
}

# Sync secrets across nodes
sync() {
    echo -e "${PINK}=== SYNC SECRETS ===${RESET}"
    echo

    local keys=$(decrypt_vault | jq -r 'keys[]')

    for key in $keys; do
        distribute "$key" "all" >/dev/null
        echo "  $key: synced"
    done

    echo
    echo -e "${GREEN}All secrets synced${RESET}"
}

# Check secret health
check() {
    echo -e "${PINK}=== SECRET HEALTH CHECK ===${RESET}"
    echo

    # Check vault integrity
    echo -n "Vault integrity: "
    if decrypt_vault | jq . >/dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}CORRUPTED${RESET}"
        return 1
    fi

    # Check key file
    echo -n "Encryption key: "
    if [ -f "$KEY_FILE" ] && [ -r "$KEY_FILE" ]; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}MISSING${RESET}"
        return 1
    fi

    # Check permissions
    echo -n "Permissions: "
    local key_perms=$(stat -f "%Lp" "$KEY_FILE" 2>/dev/null || stat -c "%a" "$KEY_FILE" 2>/dev/null)
    local vault_perms=$(stat -f "%Lp" "$SECRETS_FILE" 2>/dev/null || stat -c "%a" "$SECRETS_FILE" 2>/dev/null)

    if [ "$key_perms" = "600" ]; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${YELLOW}Key file should be 600, is $key_perms${RESET}"
    fi

    # Count secrets
    local count=$(decrypt_vault | jq 'keys | length')
    echo "Secrets stored: $count"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Secrets Manager${RESET}"
    echo
    echo "Secure secrets management for the cluster"
    echo
    echo "Commands:"
    echo "  set <key> <value>     Store a secret"
    echo "  get <key>             Retrieve a secret"
    echo "  delete <key>          Delete a secret"
    echo "  list                  List all secret keys"
    echo "  export [file]         Export to .env file"
    echo "  import <file>         Import from .env file"
    echo "  distribute <key>      Push secret to nodes"
    echo "  rotate <key> [value]  Rotate a secret"
    echo "  generate [name] [len] Generate random secret"
    echo "  sync                  Sync all secrets to nodes"
    echo "  audit [lines]         View audit log"
    echo "  check                 Health check"
    echo
    echo "Examples:"
    echo "  $0 set API_KEY sk-abc123"
    echo "  $0 get API_KEY"
    echo "  $0 generate WEBHOOK_SECRET 64"
    echo "  $0 distribute API_KEY"
}

# Ensure initialized
[ -d "$SECRETS_DIR" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    set|store)
        set_secret "$2" "$3"
        ;;
    get|retrieve)
        get_secret "$2"
        ;;
    delete|rm)
        delete_secret "$2"
        ;;
    list|ls)
        list_secrets
        ;;
    export)
        export_env "$2"
        ;;
    import)
        import_env "$2"
        ;;
    distribute|push)
        distribute "$2" "$3"
        ;;
    rotate)
        rotate "$2" "$3"
        ;;
    generate|gen)
        generate "$2" "$3"
        ;;
    sync)
        sync
        ;;
    audit)
        audit "$2"
        ;;
    check|health)
        check
        ;;
    *)
        help
        ;;
esac
