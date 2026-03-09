#!/bin/bash
#
# BlackRoad Salesforce Agent - Pi Cluster Deployment
#
# Deploys agent instances to Octavia (192.168.4.38) - the Agent Host node
# Supports deploying 500+ concurrent agent instances
#
# Usage:
#   ./scripts/deploy.sh              # Deploy single instance
#   ./scripts/deploy.sh --count 10   # Deploy 10 instances
#   ./scripts/deploy.sh --all        # Deploy to all agent nodes

set -e

# Configuration
DEPLOY_USER="alexa"
AGENT_HOST="192.168.4.38"  # Octavia - Agent Host
DEPLOY_PATH="/home/alexa/blackroad-salesforce-agent"
VENV_PATH="$DEPLOY_PATH/venv"
SERVICE_NAME="blackroad-salesforce-agent"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[DEPLOY]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Parse arguments
INSTANCE_COUNT=1
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --count|-c) INSTANCE_COUNT="$2"; shift ;;
        --host|-h) AGENT_HOST="$2"; shift ;;
        --all) DEPLOY_ALL=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# All agent nodes in the cluster
AGENT_NODES=(
    "192.168.4.38"   # Octavia - Primary Agent Host
    # Add more nodes as needed
)

deploy_to_host() {
    local HOST=$1
    local COUNT=$2

    log "Deploying to $HOST ($COUNT instances)..."

    # Create deployment directory
    ssh $DEPLOY_USER@$HOST "mkdir -p $DEPLOY_PATH"

    # Sync code
    log "Syncing code..."
    rsync -avz --exclude '.git' --exclude '__pycache__' --exclude 'venv' --exclude '*.pyc' \
        ./ $DEPLOY_USER@$HOST:$DEPLOY_PATH/

    # Setup virtual environment
    log "Setting up Python environment..."
    ssh $DEPLOY_USER@$HOST << EOF
        cd $DEPLOY_PATH
        python3 -m venv $VENV_PATH 2>/dev/null || true
        source $VENV_PATH/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
EOF

    # Create systemd service for each instance
    for i in $(seq 1 $COUNT); do
        local INSTANCE_NAME="${SERVICE_NAME}-${i}"
        log "Creating service: $INSTANCE_NAME"

        ssh $DEPLOY_USER@$HOST << EOF
            sudo tee /etc/systemd/system/${INSTANCE_NAME}.service > /dev/null << 'UNIT'
[Unit]
Description=BlackRoad Salesforce Agent Instance $i
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
WorkingDirectory=$DEPLOY_PATH
Environment="PATH=$VENV_PATH/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$VENV_PATH/bin/python -m src.main --config config/config.yaml --agent-id octavia-agent-$i
Restart=always
RestartSec=10

# Resource limits per instance
MemoryMax=256M
CPUQuota=25%

[Install]
WantedBy=multi-user.target
UNIT

            sudo systemctl daemon-reload
            sudo systemctl enable ${INSTANCE_NAME}
            sudo systemctl restart ${INSTANCE_NAME}
EOF
    done

    log "Deployment to $HOST complete!"
}

# Check config exists
if [ ! -f "config/config.yaml" ]; then
    if [ -f "config/config.example.yaml" ]; then
        warn "config/config.yaml not found. Copy from config.example.yaml and configure."
    fi
    error "Configuration file not found: config/config.yaml"
fi

# Deploy
if [ "$DEPLOY_ALL" = true ]; then
    log "Deploying to all agent nodes..."
    for NODE in "${AGENT_NODES[@]}"; do
        deploy_to_host $NODE $INSTANCE_COUNT
    done
else
    deploy_to_host $AGENT_HOST $INSTANCE_COUNT
fi

log ""
log "════════════════════════════════════════════════════════════"
log "  BlackRoad Salesforce Agent Deployed!"
log "  Host: $AGENT_HOST"
log "  Instances: $INSTANCE_COUNT"
log ""
log "  Commands:"
log "    Status:  ssh $DEPLOY_USER@$AGENT_HOST 'systemctl status $SERVICE_NAME-*'"
log "    Logs:    ssh $DEPLOY_USER@$AGENT_HOST 'journalctl -u $SERVICE_NAME-1 -f'"
log "    Stop:    ssh $DEPLOY_USER@$AGENT_HOST 'sudo systemctl stop $SERVICE_NAME-*'"
log "════════════════════════════════════════════════════════════"
