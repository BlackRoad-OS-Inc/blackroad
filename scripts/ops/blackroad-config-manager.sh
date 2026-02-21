#!/bin/bash
# BlackRoad Config Manager
# Centralized configuration management for the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

CONFIG_DIR="$HOME/.blackroad/configs"
CONFIG_STORE="$CONFIG_DIR/store"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$CONFIG_STORE"/{global,nodes,apps,templates}
    echo -e "${GREEN}Config manager initialized${RESET}"
    echo "  Store: $CONFIG_STORE"
}

# Set a config value
set_config() {
    local key="$1"
    local value="$2"
    local scope="${3:-global}"

    local config_file="$CONFIG_STORE/$scope/config.json"
    mkdir -p "$(dirname "$config_file")"

    if [ ! -f "$config_file" ]; then
        echo "{}" > "$config_file"
    fi

    jq --arg k "$key" --arg v "$value" '.[$k] = $v' "$config_file" > "$config_file.tmp"
    mv "$config_file.tmp" "$config_file"

    echo -e "${GREEN}Set: $key = $value ($scope)${RESET}"

    # Log change
    echo "$(date -Iseconds) SET $scope/$key = $value" >> "$CONFIG_DIR/changelog.log"
}

# Get a config value
get_config() {
    local key="$1"
    local scope="${2:-global}"

    local config_file="$CONFIG_STORE/$scope/config.json"

    if [ ! -f "$config_file" ]; then
        echo ""
        return 1
    fi

    jq -r --arg k "$key" '.[$k] // empty' "$config_file"
}

# Delete a config value
delete_config() {
    local key="$1"
    local scope="${2:-global}"

    local config_file="$CONFIG_STORE/$scope/config.json"

    jq --arg k "$key" 'del(.[$k])' "$config_file" > "$config_file.tmp"
    mv "$config_file.tmp" "$config_file"

    echo -e "${GREEN}Deleted: $key ($scope)${RESET}"
    echo "$(date -Iseconds) DELETE $scope/$key" >> "$CONFIG_DIR/changelog.log"
}

# List all configs
list_configs() {
    local scope="${1:-all}"

    echo -e "${PINK}=== CONFIGURATIONS ===${RESET}"
    echo

    if [ "$scope" = "all" ] || [ "$scope" = "global" ]; then
        echo -e "${BLUE}Global:${RESET}"
        if [ -f "$CONFIG_STORE/global/config.json" ]; then
            jq -r 'to_entries[] | "  \(.key) = \(.value)"' "$CONFIG_STORE/global/config.json"
        fi
        echo
    fi

    if [ "$scope" = "all" ] || [ "$scope" = "nodes" ]; then
        echo -e "${BLUE}Nodes:${RESET}"
        for node in "${ALL_NODES[@]}"; do
            if [ -f "$CONFIG_STORE/nodes/$node/config.json" ]; then
                echo "  [$node]"
                jq -r 'to_entries[] | "    \(.key) = \(.value)"' "$CONFIG_STORE/nodes/$node/config.json"
            fi
        done
        echo
    fi

    if [ "$scope" = "all" ] || [ "$scope" = "apps" ]; then
        echo -e "${BLUE}Apps:${RESET}"
        for app_config in "$CONFIG_STORE"/apps/*/config.json; do
            [ -f "$app_config" ] || continue
            local app=$(basename "$(dirname "$app_config")")
            echo "  [$app]"
            jq -r 'to_entries[] | "    \(.key) = \(.value)"' "$app_config"
        done
    fi
}

# Push config to nodes
push() {
    local scope="${1:-global}"

    echo -e "${PINK}=== PUSH CONFIG ===${RESET}"
    echo "Scope: $scope"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            echo -e "${YELLOW}offline${RESET}"
            continue
        fi

        # Create config dir on node
        ssh "$node" "mkdir -p ~/.blackroad/config"

        # Push config
        if [ "$scope" = "global" ]; then
            scp -q "$CONFIG_STORE/global/config.json" "$node:~/.blackroad/config/"
        elif [ "$scope" = "nodes/$node" ]; then
            scp -q "$CONFIG_STORE/nodes/$node/config.json" "$node:~/.blackroad/config/"
        else
            scp -rq "$CONFIG_STORE/$scope" "$node:~/.blackroad/config/"
        fi

        echo -e "${GREEN}pushed${RESET}"
    done
}

# Pull config from node
pull() {
    local node="$1"

    echo -e "${PINK}=== PULL CONFIG ===${RESET}"
    echo "Node: $node"
    echo

    mkdir -p "$CONFIG_STORE/nodes/$node"

    if scp -q "$node:~/.blackroad/config/*" "$CONFIG_STORE/nodes/$node/" 2>/dev/null; then
        echo -e "${GREEN}Pulled config from $node${RESET}"
    else
        echo -e "${YELLOW}No config found on $node${RESET}"
    fi
}

# Compare configs across nodes
diff_configs() {
    echo -e "${PINK}=== CONFIG DIFF ===${RESET}"
    echo

    local reference="${ALL_NODES[0]}"
    echo "Reference: $reference"
    echo

    for node in "${ALL_NODES[@]:1}"; do
        echo -e "${BLUE}$reference vs $node:${RESET}"

        if [ ! -f "$CONFIG_STORE/nodes/$node/config.json" ]; then
            echo "  (no config for $node)"
            continue
        fi

        diff -u "$CONFIG_STORE/nodes/$reference/config.json" "$CONFIG_STORE/nodes/$node/config.json" 2>/dev/null || echo "  (identical or missing)"
        echo
    done
}

# Create config template
template() {
    local name="$1"
    local template_file="$CONFIG_STORE/templates/$name.json"

    if [ -z "$name" ]; then
        echo "Templates:"
        ls -1 "$CONFIG_STORE/templates/"*.json 2>/dev/null | xargs -I{} basename {} .json | sed 's/^/  /'
        return
    fi

    if [ ! -f "$template_file" ]; then
        # Create new template
        cat > "$template_file" << 'EOF'
{
    "app_name": "{{APP_NAME}}",
    "port": "{{PORT}}",
    "log_level": "info",
    "max_connections": 100,
    "timeout": 30
}
EOF
        echo -e "${GREEN}Created template: $name${RESET}"
    else
        cat "$template_file"
    fi
}

# Apply template with variables
apply_template() {
    local template="$1"
    local output="$2"
    shift 2

    local template_file="$CONFIG_STORE/templates/$template.json"

    if [ ! -f "$template_file" ]; then
        echo -e "${RED}Template not found: $template${RESET}"
        return 1
    fi

    local content=$(cat "$template_file")

    # Replace variables
    for var in "$@"; do
        local key="${var%%=*}"
        local value="${var#*=}"
        content=$(echo "$content" | sed "s/{{$key}}/$value/g")
    done

    echo "$content" > "$output"
    echo -e "${GREEN}Applied template to: $output${RESET}"
}

# Validate config
validate() {
    local config_file="$1"

    echo -e "${PINK}=== VALIDATE CONFIG ===${RESET}"
    echo "File: $config_file"
    echo

    if [ ! -f "$config_file" ]; then
        echo -e "${RED}File not found${RESET}"
        return 1
    fi

    if jq . "$config_file" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Valid JSON${RESET}"

        # Check for common issues
        local empty=$(jq 'to_entries | map(select(.value == "" or .value == null)) | length' "$config_file")
        if [ "$empty" -gt 0 ]; then
            echo -e "${YELLOW}⚠ $empty empty values${RESET}"
        fi
    else
        echo -e "${RED}✗ Invalid JSON${RESET}"
        return 1
    fi
}

# Environment export
env_export() {
    local scope="${1:-global}"
    local config_file="$CONFIG_STORE/$scope/config.json"

    if [ ! -f "$config_file" ]; then
        return
    fi

    jq -r 'to_entries[] | "export \(.key | ascii_upcase)=\(.value)"' "$config_file"
}

# Sync all nodes
sync() {
    echo -e "${PINK}=== SYNC ALL NODES ===${RESET}"
    echo

    # Push global config to all
    push global

    # Push node-specific configs
    for node in "${ALL_NODES[@]}"; do
        if [ -d "$CONFIG_STORE/nodes/$node" ]; then
            echo "Pushing node config to $node..."
            push "nodes/$node"
        fi
    done
}

# Rollback to previous config
rollback() {
    local scope="${1:-global}"
    local config_file="$CONFIG_STORE/$scope/config.json"
    local backup_file="$CONFIG_STORE/$scope/config.json.bak"

    if [ -f "$backup_file" ]; then
        cp "$config_file" "$config_file.tmp"
        mv "$backup_file" "$config_file"
        mv "$config_file.tmp" "$backup_file"
        echo -e "${GREEN}Rolled back $scope config${RESET}"
    else
        echo -e "${YELLOW}No backup found for $scope${RESET}"
    fi
}

# Changelog
changelog() {
    local lines="${1:-20}"

    echo -e "${PINK}=== CONFIG CHANGELOG ===${RESET}"
    echo

    if [ -f "$CONFIG_DIR/changelog.log" ]; then
        tail -n "$lines" "$CONFIG_DIR/changelog.log"
    else
        echo "No changes recorded"
    fi
}

# Help
help() {
    echo -e "${PINK}BlackRoad Config Manager${RESET}"
    echo
    echo "Centralized configuration management"
    echo
    echo "Commands:"
    echo "  set <key> <value> [scope]   Set config value"
    echo "  get <key> [scope]           Get config value"
    echo "  delete <key> [scope]        Delete config"
    echo "  list [scope]                List all configs"
    echo "  push [scope]                Push config to nodes"
    echo "  pull <node>                 Pull config from node"
    echo "  diff                        Compare configs"
    echo "  template [name]             Manage templates"
    echo "  apply <tmpl> <out> [vars]   Apply template"
    echo "  validate <file>             Validate config file"
    echo "  env [scope]                 Export as env vars"
    echo "  sync                        Sync all nodes"
    echo "  rollback [scope]            Rollback config"
    echo "  changelog [lines]           View changes"
    echo
    echo "Scopes: global, nodes/<name>, apps/<name>"
    echo
    echo "Examples:"
    echo "  $0 set log_level debug global"
    echo "  $0 set port 8080 nodes/cecilia"
    echo "  $0 push global"
    echo "  $0 apply webapp ./app.json APP_NAME=myapp PORT=3000"
}

# Ensure initialized
[ -d "$CONFIG_STORE" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    set)
        set_config "$2" "$3" "$4"
        ;;
    get)
        get_config "$2" "$3"
        ;;
    delete|del)
        delete_config "$2" "$3"
        ;;
    list|ls)
        list_configs "$2"
        ;;
    push)
        push "$2"
        ;;
    pull)
        pull "$2"
        ;;
    diff)
        diff_configs
        ;;
    template|tmpl)
        template "$2"
        ;;
    apply)
        apply_template "$2" "$3" "${@:4}"
        ;;
    validate|check)
        validate "$2"
        ;;
    env|export)
        env_export "$2"
        ;;
    sync)
        sync
        ;;
    rollback)
        rollback "$2"
        ;;
    changelog|log)
        changelog "$2"
        ;;
    *)
        help
        ;;
esac
