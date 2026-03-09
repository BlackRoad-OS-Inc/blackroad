#!/bin/bash
#
# BlackRoad Agent Swarm Controller
#
# Manages hundreds of agent instances across the Pi cluster.
# The secret sauce: 500 agents × 1 Salesforce seat = unlimited scale
#
# Usage:
#   ./scripts/swarm.sh status              # Show all agent status
#   ./scripts/swarm.sh start 100           # Start 100 agents
#   ./scripts/swarm.sh stop                # Stop all agents
#   ./scripts/swarm.sh scale 500           # Scale to 500 agents
#   ./scripts/swarm.sh stats               # Show queue statistics

set -e

# Configuration
DEPLOY_USER="alexa"
AGENT_HOST="192.168.4.38"  # Octavia
SERVICE_PREFIX="blackroad-salesforce-agent"
DEPLOY_PATH="/home/alexa/blackroad-salesforce-agent"
VENV_PATH="$DEPLOY_PATH/venv"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           BlackRoad Agent Swarm Controller                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

status() {
    header
    echo -e "${GREEN}Agent Status on $AGENT_HOST:${NC}"
    echo ""
    ssh $DEPLOY_USER@$AGENT_HOST "systemctl list-units --type=service --all | grep $SERVICE_PREFIX || echo 'No agents running'"
    echo ""
    echo -e "${GREEN}Queue Statistics:${NC}"
    ssh $DEPLOY_USER@$AGENT_HOST "cd $DEPLOY_PATH && source $VENV_PATH/bin/activate && python -c \"
from src.queue import TaskQueue
q = TaskQueue()
stats = q.stats()
print(f'  Pending:    {stats[\"pending\"]}')
print(f'  Processing: {stats[\"processing\"]}')
print(f'  Completed:  {stats[\"completed\"]}')
print(f'  Failed:     {stats[\"failed\"]}')
print(f'  Total:      {stats[\"total\"]}')
\" 2>/dev/null || echo '  Queue not initialized'"
}

start_agents() {
    local COUNT=$1
    header
    echo -e "${GREEN}Starting $COUNT agents...${NC}"

    for i in $(seq 1 $COUNT); do
        local INSTANCE_NAME="${SERVICE_PREFIX}-${i}"

        # Check if service exists, create if not
        ssh $DEPLOY_USER@$AGENT_HOST << EOF
            if [ ! -f /etc/systemd/system/${INSTANCE_NAME}.service ]; then
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
MemoryMax=256M
CPUQuota=25%

[Install]
WantedBy=multi-user.target
UNIT
                sudo systemctl daemon-reload
            fi
            sudo systemctl start ${INSTANCE_NAME} 2>/dev/null || true
EOF
        echo -e "  Started agent $i"
    done

    echo ""
    echo -e "${GREEN}$COUNT agents started!${NC}"
}

stop_agents() {
    header
    echo -e "${YELLOW}Stopping all agents...${NC}"
    ssh $DEPLOY_USER@$AGENT_HOST "sudo systemctl stop ${SERVICE_PREFIX}-* 2>/dev/null || true"
    echo -e "${GREEN}All agents stopped.${NC}"
}

scale_agents() {
    local TARGET=$1
    header
    echo -e "${GREEN}Scaling to $TARGET agents...${NC}"

    # Get current count
    CURRENT=$(ssh $DEPLOY_USER@$AGENT_HOST "systemctl list-units --type=service --state=running | grep -c $SERVICE_PREFIX || echo 0")

    if [ $TARGET -gt $CURRENT ]; then
        # Scale up
        echo "Scaling up from $CURRENT to $TARGET..."
        for i in $(seq $((CURRENT + 1)) $TARGET); do
            local INSTANCE_NAME="${SERVICE_PREFIX}-${i}"
            ssh $DEPLOY_USER@$AGENT_HOST "sudo systemctl start ${INSTANCE_NAME} 2>/dev/null || true"
        done
    elif [ $TARGET -lt $CURRENT ]; then
        # Scale down
        echo "Scaling down from $CURRENT to $TARGET..."
        for i in $(seq $((TARGET + 1)) $CURRENT); do
            local INSTANCE_NAME="${SERVICE_PREFIX}-${i}"
            ssh $DEPLOY_USER@$AGENT_HOST "sudo systemctl stop ${INSTANCE_NAME} 2>/dev/null || true"
        done
    fi

    echo -e "${GREEN}Scaled to $TARGET agents.${NC}"
}

show_stats() {
    header
    echo -e "${GREEN}Swarm Statistics:${NC}"
    echo ""

    # Agent count
    RUNNING=$(ssh $DEPLOY_USER@$AGENT_HOST "systemctl list-units --type=service --state=running | grep -c $SERVICE_PREFIX || echo 0")
    echo -e "  Running Agents: ${CYAN}$RUNNING${NC}"

    # Memory usage
    echo -e "  Memory Usage:"
    ssh $DEPLOY_USER@$AGENT_HOST "free -h | head -2"

    # CPU usage
    echo -e "\n  CPU Load:"
    ssh $DEPLOY_USER@$AGENT_HOST "uptime"

    # Queue stats
    echo -e "\n  Queue:"
    ssh $DEPLOY_USER@$AGENT_HOST "cd $DEPLOY_PATH && source $VENV_PATH/bin/activate && python -c \"
from src.queue import TaskQueue
q = TaskQueue()
stats = q.stats()
print(f'    Pending:    {stats[\"pending\"]}')
print(f'    Processing: {stats[\"processing\"]}')
print(f'    Completed:  {stats[\"completed\"]}')
print(f'    Failed:     {stats[\"failed\"]}')
\" 2>/dev/null || echo '    Queue not initialized'"

    # Throughput estimate
    echo ""
    echo -e "  ${GREEN}Estimated Throughput:${NC}"
    echo -e "    $RUNNING agents × 4 workers × 60 ops/min = ${CYAN}$((RUNNING * 4 * 60)) ops/min${NC}"
}

# Main
case "$1" in
    status)
        status
        ;;
    start)
        start_agents ${2:-1}
        ;;
    stop)
        stop_agents
        ;;
    scale)
        if [ -z "$2" ]; then
            echo "Usage: $0 scale <count>"
            exit 1
        fi
        scale_agents $2
        ;;
    stats)
        show_stats
        ;;
    *)
        echo "BlackRoad Agent Swarm Controller"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  status          Show agent and queue status"
        echo "  start <count>   Start N agent instances"
        echo "  stop            Stop all agents"
        echo "  scale <count>   Scale to exactly N agents"
        echo "  stats           Show detailed statistics"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 start 100"
        echo "  $0 scale 500"
        ;;
esac
