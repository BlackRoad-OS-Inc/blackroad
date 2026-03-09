#!/bin/bash
# Shellfish SSH Automation for Pi Mesh Deployments
# Designed for iOS Shellfish app + Pi mesh integration
# Version: 1.0.0

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Pi mesh configuration
declare -A PI_NODES=(
    ["lucidia"]="192.168.4.38"
    ["blackroad"]="192.168.4.64"
    ["lucidia-alt"]="192.168.4.99"
    ["iphone-koder"]="192.168.4.68:8080"
)

PI_USER="${PI_USER:-pi}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"
DEPLOY_BASE="/home/pi/services"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    echo "[$(date +'%H:%M:%S')] $*"
}

error() {
    echo "❌ [ERROR] $*" >&2
}

success() {
    echo "✅ $*"
}

# ============================================================================
# SSH CONNECTION FUNCTIONS
# ============================================================================

test_pi_connection() {
    local pi_name="$1"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Testing connection to $pi_name ($pi_ip)..."

    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$PI_USER@$pi_ip" "echo 'Connected to $pi_name'" 2>/dev/null; then
        success "Connected to $pi_name"
        return 0
    else
        error "Cannot connect to $pi_name"
        return 1
    fi
}

test_all_connections() {
    log "Testing all Pi connections..."

    local failed=0
    for pi_name in "${!PI_NODES[@]}"; do
        if ! test_pi_connection "$pi_name"; then
            ((failed++))
        fi
    done

    if [ $failed -eq 0 ]; then
        success "All Pi nodes are reachable!"
    else
        error "$failed Pi nodes are unreachable"
        return 1
    fi
}

# ============================================================================
# DEPLOYMENT FUNCTIONS
# ============================================================================

deploy_service() {
    local pi_name="$1"
    local service_name="$2"
    local local_path="$3"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Deploying $service_name to $pi_name..."

    # Create service directory on Pi
    ssh "$PI_USER@$pi_ip" "mkdir -p $DEPLOY_BASE/$service_name"

    # Sync files
    rsync -avz --delete \
        -e "ssh -o ConnectTimeout=10" \
        --exclude '.git' \
        --exclude 'node_modules' \
        --exclude '__pycache__' \
        --exclude '*.pyc' \
        --exclude '.env.local' \
        "$local_path/" \
        "$PI_USER@$pi_ip:$DEPLOY_BASE/$service_name/"

    # Make deployment script executable if exists
    ssh "$PI_USER@$pi_ip" "[ -f $DEPLOY_BASE/$service_name/deploy.sh ] && chmod +x $DEPLOY_BASE/$service_name/deploy.sh || true"

    # Run deployment
    if ssh "$PI_USER@$pi_ip" "[ -f $DEPLOY_BASE/$service_name/docker-compose.yml ]"; then
        log "Deploying with Docker Compose..."
        ssh "$PI_USER@$pi_ip" "cd $DEPLOY_BASE/$service_name && docker-compose up -d --build"
    elif ssh "$PI_USER@$pi_ip" "[ -f $DEPLOY_BASE/$service_name/deploy.sh ]"; then
        log "Running custom deployment script..."
        ssh "$PI_USER@$pi_ip" "cd $DEPLOY_BASE/$service_name && ./deploy.sh"
    else
        log "No deployment method found, files copied only"
    fi

    success "Deployed $service_name to $pi_name"
}

# ============================================================================
# SERVICE MANAGEMENT
# ============================================================================

restart_service() {
    local pi_name="$1"
    local service_name="$2"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Restarting $service_name on $pi_name..."

    ssh "$PI_USER@$pi_ip" "cd $DEPLOY_BASE/$service_name && docker-compose restart" || \
        ssh "$PI_USER@$pi_ip" "systemctl --user restart $service_name" || \
        error "Could not restart $service_name"

    success "Restarted $service_name"
}

stop_service() {
    local pi_name="$1"
    local service_name="$2"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Stopping $service_name on $pi_name..."

    ssh "$PI_USER@$pi_ip" "cd $DEPLOY_BASE/$service_name && docker-compose down" || \
        ssh "$PI_USER@$pi_ip" "systemctl --user stop $service_name" || \
        error "Could not stop $service_name"

    success "Stopped $service_name"
}

start_service() {
    local pi_name="$1"
    local service_name="$2"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Starting $service_name on $pi_name..."

    ssh "$PI_USER@$pi_ip" "cd $DEPLOY_BASE/$service_name && docker-compose up -d" || \
        ssh "$PI_USER@$pi_ip" "systemctl --user start $service_name" || \
        error "Could not start $service_name"

    success "Started $service_name"
}

get_service_status() {
    local pi_name="$1"
    local service_name="$2"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Getting status for $service_name on $pi_name..."

    ssh "$PI_USER@$pi_ip" "cd $DEPLOY_BASE/$service_name && docker-compose ps" || \
        ssh "$PI_USER@$pi_ip" "systemctl --user status $service_name" || \
        echo "Service status unavailable"
}

# ============================================================================
# LOGS & MONITORING
# ============================================================================

tail_logs() {
    local pi_name="$1"
    local service_name="$2"
    local lines="${3:-50}"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Tailing logs for $service_name on $pi_name (last $lines lines)..."

    ssh "$PI_USER@$pi_ip" "cd $DEPLOY_BASE/$service_name && docker-compose logs --tail=$lines -f" || \
        ssh "$PI_USER@$pi_ip" "journalctl --user -u $service_name -n $lines -f"
}

get_pi_status() {
    local pi_name="$1"
    local pi_ip="${PI_NODES[$pi_name]}"

    log "Getting system status for $pi_name..."

    ssh "$PI_USER@$pi_ip" "
        echo '═══════════════════════════════════════'
        echo ' 🥧 Pi Status: $pi_name'
        echo '═══════════════════════════════════════'
        echo ''
        echo '📊 Uptime:'
        uptime
        echo ''
        echo '💾 Memory:'
        free -h
        echo ''
        echo '📦 Disk:'
        df -h /
        echo ''
        echo '🌡️ Temperature:'
        vcgencmd measure_temp 2>/dev/null || echo 'N/A'
        echo ''
        echo '🐳 Docker:'
        docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo 'Docker not available'
    "
}

# ============================================================================
# SHELLFISH-SPECIFIC HELPERS
# ============================================================================

shellfish_quick_deploy() {
    # Quick deploy function designed for Shellfish shortcuts

    local service="${1:-}"
    local pi="${2:-lucidia}"

    if [ -z "$service" ]; then
        echo "Usage: shellfish_quick_deploy <service> [pi_name]"
        echo ""
        echo "Available Pi nodes:"
        for name in "${!PI_NODES[@]}"; do
            echo "  - $name (${PI_NODES[$name]})"
        done
        exit 1
    fi

    # Auto-detect repo path
    local repo_path=""
    if [ -d "/Users/alexa/projects/$service" ]; then
        repo_path="/Users/alexa/projects/$service"
    elif [ -d "/Users/alexa/$service" ]; then
        repo_path="/Users/alexa/$service"
    elif [ -d "$PWD" ] && [[ "$PWD" == *"$service"* ]]; then
        repo_path="$PWD"
    else
        error "Could not find repository for $service"
        exit 1
    fi

    log "Found repo at: $repo_path"
    deploy_service "$pi" "$service" "$repo_path"
}

shellfish_status_all() {
    # Quick status check for all Pi nodes

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  BlackRoad Pi Mesh Status                                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    for pi_name in "${!PI_NODES[@]}"; do
        if test_pi_connection "$pi_name" 2>/dev/null; then
            echo "✅ $pi_name (${PI_NODES[$pi_name]}) - ONLINE"
        else
            echo "❌ $pi_name (${PI_NODES[$pi_name]}) - OFFLINE"
        fi
    done
    echo ""
}

# ============================================================================
# AUTOMATIC DEPLOYMENT WORKFLOWS
# ============================================================================

auto_deploy_on_push() {
    # Git hook integration - deploy on push

    local repo_name=$(basename "$PWD")
    local default_pi="lucidia"

    log "Auto-deploying $repo_name to $default_pi..."

    deploy_service "$default_pi" "$repo_name" "$PWD"
}

watch_and_deploy() {
    # Watch for file changes and auto-deploy

    local service="$1"
    local pi="${2:-lucidia}"
    local watch_path="${3:-.}"

    log "Watching $watch_path for changes..."
    log "Will auto-deploy $service to $pi on changes"

    fswatch -o "$watch_path" | while read f; do
        log "Changes detected, deploying..."
        deploy_service "$pi" "$service" "$watch_path"
        log "Deployed! Watching for more changes..."
    done
}

# ============================================================================
# MAIN COMMAND INTERFACE
# ============================================================================

usage() {
    cat <<'EOF'
Shellfish Pi Deployment System

Usage: ./shellfish-pi-deploy.sh <command> [options]

CONNECTION:
  test <pi>                Test connection to Pi node
  test-all                 Test all Pi connections

DEPLOYMENT:
  deploy <pi> <service> <path>   Deploy service to Pi
  quick-deploy <service> [pi]    Quick deploy (auto-detects path)

SERVICE MANAGEMENT:
  start <pi> <service>     Start service
  stop <pi> <service>      Stop service
  restart <pi> <service>   Restart service
  status <pi> <service>    Get service status

MONITORING:
  logs <pi> <service> [lines]    Tail service logs
  pi-status <pi>                 Get Pi system status
  status-all                     Status of all Pi nodes

AUTOMATION:
  watch <service> <pi> [path]    Watch and auto-deploy on changes
  auto-deploy                    Deploy current directory

AVAILABLE PI NODES:
  - lucidia (192.168.4.38)
  - blackroad (192.168.4.64)
  - lucidia-alt (192.168.4.99)
  - iphone-koder (192.168.4.68:8080)

EXAMPLES:
  # Quick deploy from Shellfish
  ./shellfish-pi-deploy.sh quick-deploy blackroad-os-web

  # Test all connections
  ./shellfish-pi-deploy.sh test-all

  # View logs
  ./shellfish-pi-deploy.sh logs lucidia blackroad-os-web 100

  # Check Pi status
  ./shellfish-pi-deploy.sh pi-status lucidia

  # Auto-deploy on file changes
  ./shellfish-pi-deploy.sh watch blackroad-os-web lucidia

EOF
}

main() {
    case "${1:-}" in
        test)
            test_pi_connection "${2:-lucidia}"
            ;;
        test-all)
            test_all_connections
            ;;
        deploy)
            [ -z "${2:-}" ] && { error "Pi name required"; usage; exit 1; }
            [ -z "${3:-}" ] && { error "Service name required"; usage; exit 1; }
            [ -z "${4:-}" ] && { error "Path required"; usage; exit 1; }
            deploy_service "$2" "$3" "$4"
            ;;
        quick-deploy)
            shellfish_quick_deploy "${2:-}" "${3:-lucidia}"
            ;;
        start)
            [ -z "${2:-}" ] && { error "Pi name required"; usage; exit 1; }
            [ -z "${3:-}" ] && { error "Service name required"; usage; exit 1; }
            start_service "$2" "$3"
            ;;
        stop)
            [ -z "${2:-}" ] && { error "Pi name required"; usage; exit 1; }
            [ -z "${3:-}" ] && { error "Service name required"; usage; exit 1; }
            stop_service "$2" "$3"
            ;;
        restart)
            [ -z "${2:-}" ] && { error "Pi name required"; usage; exit 1; }
            [ -z "${3:-}" ] && { error "Service name required"; usage; exit 1; }
            restart_service "$2" "$3"
            ;;
        status)
            [ -z "${2:-}" ] && { error "Pi name required"; usage; exit 1; }
            [ -z "${3:-}" ] && { error "Service name required"; usage; exit 1; }
            get_service_status "$2" "$3"
            ;;
        logs)
            [ -z "${2:-}" ] && { error "Pi name required"; usage; exit 1; }
            [ -z "${3:-}" ] && { error "Service name required"; usage; exit 1; }
            tail_logs "$2" "$3" "${4:-50}"
            ;;
        pi-status)
            [ -z "${2:-}" ] && { error "Pi name required"; usage; exit 1; }
            get_pi_status "$2"
            ;;
        status-all)
            shellfish_status_all
            ;;
        watch)
            [ -z "${2:-}" ] && { error "Service name required"; usage; exit 1; }
            watch_and_deploy "$2" "${3:-lucidia}" "${4:-.}"
            ;;
        auto-deploy)
            auto_deploy_on_push
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
