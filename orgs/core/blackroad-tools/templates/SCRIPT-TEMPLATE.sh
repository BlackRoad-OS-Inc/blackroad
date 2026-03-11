#!/usr/bin/env bash
# ============================================================================
# BlackRoad OS - Proprietary Software
# Copyright (c) 2025 BlackRoad OS, Inc. / Alexa Louise Amundson
# All Rights Reserved.
# ============================================================================
#
# [Script Name]
# [One-line description of what this script does]
#
# Usage:
#   ./script-name.sh                    # Interactive menu mode
#   ./script-name.sh [command] [args]   # Direct command mode
#   ./script-name.sh --help             # Show help
#
# Examples:
#   ./script-name.sh deploy             # Deploy service
#   ./script-name.sh status             # Check status
#   ./script-name.sh logs               # View logs

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
LOG_FILE="${PROJECT_ROOT}/script-name.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log() {
    echo -e "${GREEN}✓${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $1" >> "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    local missing=0

    if ! command_exists "python3"; then
        error "python3 not found"
        missing=1
    fi

    if ! command_exists "git"; then
        error "git not found"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        error "Missing required dependencies"
        exit 1
    fi

    log "All prerequisites met"
}

# =============================================================================
# Command Functions
# =============================================================================

cmd_deploy() {
    log "Starting deployment..."

    # Example deployment steps
    cd "$PROJECT_ROOT"

    # Pull latest code
    log "Pulling latest code..."
    git pull origin main

    # Install dependencies
    log "Installing dependencies..."
    pip3 install -r requirements.txt

    # Deploy to platform
    log "Deploying to platform..."
    railway up --service service-name

    # Verify deployment
    log "Verifying deployment..."
    sleep 5
    railway status

    log "Deployment complete!"
}

cmd_status() {
    log "Checking status..."

    # Check local services
    info "Local services:"
    pgrep -f "python3.*blackroad" | while read pid; do
        echo "  PID $pid: $(ps -p $pid -o command=)"
    done

    # Check Railway
    if command_exists "railway"; then
        info "Railway status:"
        railway status
    fi

    # Check health endpoints
    info "Health checks:"
    curl -sf http://localhost:8000/health && echo "  ✅ Local API" || echo "  ❌ Local API"
    curl -sf https://api.blackroad.io/health && echo "  ✅ Production API" || echo "  ❌ Production API"
}

cmd_logs() {
    log "Viewing logs..."

    # Show local log
    if [ -f "$LOG_FILE" ]; then
        tail -n 50 "$LOG_FILE"
    fi

    # Show Railway logs if available
    if command_exists "railway"; then
        info "Railway logs:"
        railway logs --tail 50
    fi
}

cmd_start() {
    log "Starting services..."

    cd "$PROJECT_ROOT"

    # Start service in background
    PORT=8000 python3 blackroad-service.py &

    # Wait for startup
    sleep 2

    # Verify
    curl -sf http://localhost:8000/health && log "Service started successfully" || error "Service failed to start"
}

cmd_stop() {
    log "Stopping services..."

    # Kill all matching processes
    pkill -f "python3.*blackroad-service" || warn "No processes found"

    log "Services stopped"
}

cmd_test() {
    log "Running tests..."

    cd "$PROJECT_ROOT"

    # Run unit tests
    pytest -m unit -v

    # Run integration tests
    pytest -m integration -v

    log "Tests complete"
}

cmd_clean() {
    log "Cleaning up..."

    cd "$PROJECT_ROOT"

    # Remove cache files
    find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete 2>/dev/null || true

    # Remove log files
    rm -f "$LOG_FILE"

    log "Cleanup complete"
}

# =============================================================================
# Menu Functions
# =============================================================================

show_menu() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║     [Service Name] Management          ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Commands:"
    echo "  1) deploy   - Deploy to production"
    echo "  2) status   - Check service status"
    echo "  3) logs     - View logs"
    echo "  4) start    - Start local service"
    echo "  5) stop     - Stop local service"
    echo "  6) test     - Run tests"
    echo "  7) clean    - Clean up files"
    echo "  q) quit     - Exit"
    echo ""
}

interactive_menu() {
    while true; do
        show_menu
        read -rp "Choose command: " choice

        case $choice in
            1|deploy)   cmd_deploy ;;
            2|status)   cmd_status ;;
            3|logs)     cmd_logs ;;
            4|start)    cmd_start ;;
            5|stop)     cmd_stop ;;
            6|test)     cmd_test ;;
            7|clean)    cmd_clean ;;
            q|quit)     log "Goodbye!"; exit 0 ;;
            *)          error "Invalid choice: $choice" ;;
        esac

        echo ""
        read -rp "Press Enter to continue..."
    done
}

# =============================================================================
# Help Function
# =============================================================================

show_help() {
    cat <<EOF
[Script Name] - [Description]

Usage:
  $0 [command] [args]

Commands:
  deploy              Deploy to production
  status              Check service status
  logs                View logs
  start               Start local service
  stop                Stop local service
  test                Run tests
  clean               Clean up files
  menu                Show interactive menu (default)
  help                Show this help message

Examples:
  $0                  # Interactive menu mode
  $0 deploy           # Deploy to production
  $0 status           # Check status
  $0 logs             # View logs

Environment Variables:
  RAILWAY_TOKEN       Railway API token (required for deploy)
  PORT               Service port (default: 8000)

For more information, see README.md
EOF
}

# =============================================================================
# Main Script Logic
# =============================================================================

main() {
    # Check prerequisites
    check_prerequisites

    # Handle command
    case "${1:-menu}" in
        deploy)         cmd_deploy ;;
        status)         cmd_status ;;
        logs)           cmd_logs ;;
        start)          cmd_start ;;
        stop)           cmd_stop ;;
        test)           cmd_test ;;
        clean)          cmd_clean ;;
        menu|"")        interactive_menu ;;
        -h|--help|help) show_help ;;
        *)
            error "Unknown command: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
