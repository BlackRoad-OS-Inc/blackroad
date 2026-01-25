#!/bin/bash
# Manage GitHub webhook deployments

DEPLOYMENTS_FILE="$HOME/.blackroad-deploy/deployments.json"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-blackroad-deploy-secret}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

# Initialize deployments file
init_file() {
    mkdir -p "$(dirname "$DEPLOYMENTS_FILE")"
    if [ ! -f "$DEPLOYMENTS_FILE" ]; then
        echo "[]" > "$DEPLOYMENTS_FILE"
    fi
}

# Add deployment
add_deployment() {
    local repo=$1
    local target=$2
    local branch=${3:-main}
    local app_name=${4:-$repo}
    
    if [ -z "$repo" ] || [ -z "$target" ]; then
        echo "Usage: $0 add <repo> <target> [branch] [app-name]"
        exit 1
    fi
    
    init_file
    
    local new_deployment=$(cat <<JSON
{
  "repo": "$repo",
  "target": "$target",
  "branch": "$branch",
  "app_name": "$app_name"
}
JSON
)
    
    # Add to deployments
    python3 << PYEOF
import json

with open("$DEPLOYMENTS_FILE") as f:
    deployments = json.load(f)

new = $new_deployment
deployments.append(new)

with open("$DEPLOYMENTS_FILE", 'w') as f:
    json.dump(deployments, f, indent=2)
PYEOF
    
    log_success "Added deployment: $repo ($branch) → $target"
    echo ""
    log_info "Add this webhook to your GitHub repo:"
    log_info "URL: http://YOUR_IP:9000/webhook"
    log_info "Secret: $WEBHOOK_SECRET"
    log_info "Content type: application/json"
    log_info "Events: Just the push event"
}

# List deployments
list_deployments() {
    init_file
    
    echo -e "${BLUE}Configured Deployments:${NC}"
    echo ""
    
    python3 << 'PYEOF'
import json

with open("$DEPLOYMENTS_FILE") as f:
    deployments = json.load(f)

if not deployments:
    print("  No deployments configured")
else:
    for i, d in enumerate(deployments, 1):
        repo = d['repo']
        target = d['target']
        branch = d.get('branch', 'main')
        app = d.get('app_name', repo)
        print(f"  {i}. {repo} ({branch}) → {target} as '{app}'")
PYEOF
}

# Remove deployment
remove_deployment() {
    local index=$1
    
    if [ -z "$index" ]; then
        echo "Usage: $0 remove <number>"
        list_deployments
        exit 1
    fi
    
    init_file
    
    python3 << PYEOF
import json

with open("$DEPLOYMENTS_FILE") as f:
    deployments = json.load(f)

try:
    idx = int("$index") - 1
    removed = deployments.pop(idx)
    
    with open("$DEPLOYMENTS_FILE", 'w') as f:
        json.dump(deployments, f, indent=2)
    
    print(f"Removed: {removed['repo']} → {removed['target']}")
except (IndexError, ValueError):
    print("Invalid index")
    exit(1)
PYEOF
}

# Start webhook server
start_server() {
    log_info "Starting webhook server..."
    
    if pgrep -f "webhook-server.py" > /dev/null; then
        log_warn "Server already running"
        exit 0
    fi
    
    nohup ~/blackroad-deploy/scripts/webhook-server.py > ~/.blackroad-deploy/webhook.log 2>&1 &
    
    sleep 2
    
    if pgrep -f "webhook-server.py" > /dev/null; then
        log_success "Webhook server started"
        log_info "Logs: tail -f ~/.blackroad-deploy/webhook.log"
    else
        log_warn "Failed to start server"
        exit 1
    fi
}

# Stop webhook server
stop_server() {
    log_info "Stopping webhook server..."
    
    pkill -f "webhook-server.py"
    
    sleep 1
    
    if ! pgrep -f "webhook-server.py" > /dev/null; then
        log_success "Server stopped"
    else
        log_warn "Failed to stop server"
        exit 1
    fi
}

# Server status
server_status() {
    if pgrep -f "webhook-server.py" > /dev/null; then
        echo -e "${GREEN}✓${NC} Webhook server is running"
        echo ""
        log_info "Logs: tail -f ~/.blackroad-deploy/webhook.log"
    else
        echo -e "${YELLOW}✗${NC} Webhook server is not running"
        echo ""
        log_info "Start with: $0 start"
    fi
}

# Main
case "$1" in
    add)
        shift
        add_deployment "$@"
        ;;
    list|ls)
        list_deployments
        ;;
    remove|rm)
        shift
        remove_deployment "$@"
        ;;
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    status)
        server_status
        ;;
    *)
        echo "BlackRoad Webhook Manager"
        echo ""
        echo "Usage: $0 {add|list|remove|start|stop|status}"
        echo ""
        echo "Commands:"
        echo "  add <repo> <target> [branch] [app]  Add deployment"
        echo "  list                                 List deployments"
        echo "  remove <number>                      Remove deployment"
        echo "  start                                Start webhook server"
        echo "  stop                                 Stop webhook server"
        echo "  status                               Check server status"
        echo ""
        echo "Examples:"
        echo "  $0 add my-app aria64 main"
        echo "  $0 add my-api shellfish main api-v2"
        echo "  $0 start"
        exit 1
        ;;
esac
