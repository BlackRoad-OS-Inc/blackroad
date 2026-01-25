#!/bin/bash
#
# BlackRoad Agent OS - Agent Installation Script
# Run this on each Raspberry Pi to set up the agent
#
set -e

# Configuration
INSTALL_DIR="${INSTALL_DIR:-/home/pi/blackroad-agent-os}"
AGENT_ID="${AGENT_ID:-$(hostname)}"
CONTROLLER_URL="${CONTROLLER_URL:-ws://localhost:8000/ws/agent}"
AGENT_ROLES="${AGENT_ROLES:-worker}"
AGENT_TAGS="${AGENT_TAGS:-}"

echo "=========================================="
echo "  BlackRoad Agent OS - Agent Installer"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Install directory: $INSTALL_DIR"
echo "  Agent ID: $AGENT_ID"
echo "  Controller URL: $CONTROLLER_URL"
echo "  Roles: $AGENT_ROLES"
echo "  Tags: $AGENT_TAGS"
echo ""

# Check Python version
python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
if [[ $(echo "$python_version < 3.10" | bc -l) -eq 1 ]]; then
    echo "Error: Python 3.10+ required (found $python_version)"
    exit 1
fi
echo "Python version: $python_version"

# Clone or update repo
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo "Cloning repository..."
    git clone https://github.com/BlackRoad-OS/blackroad-agent-os.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# Set up virtual environment
echo "Setting up Python virtual environment..."
cd agent
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Create config directory
sudo mkdir -p /etc/blackroad

# Create environment file
echo "Creating environment configuration..."
sudo tee /etc/blackroad/agent.env > /dev/null << EOF
AGENT_ID=$AGENT_ID
CONTROLLER_URL=$CONTROLLER_URL
AGENT_ROLES=$AGENT_ROLES
AGENT_TAGS=$AGENT_TAGS
HEARTBEAT_INTERVAL=15
RECONNECT_DELAY=5
LOG_LEVEL=INFO
EOF

# Install systemd service
echo "Installing systemd service..."
sudo cp "$INSTALL_DIR/deploy/agent.service" /etc/systemd/system/blackroad-agent.service

# Update service file with correct paths
sudo sed -i "s|/home/pi/blackroad-agent-os|$INSTALL_DIR|g" /etc/systemd/system/blackroad-agent.service
sudo sed -i "s|User=pi|User=$(whoami)|g" /etc/systemd/system/blackroad-agent.service
sudo sed -i "s|Group=pi|Group=$(whoami)|g" /etc/systemd/system/blackroad-agent.service

# Reload systemd
sudo systemctl daemon-reload

# Enable and start service
echo "Enabling and starting agent service..."
sudo systemctl enable blackroad-agent
sudo systemctl start blackroad-agent

# Check status
sleep 2
if sudo systemctl is-active --quiet blackroad-agent; then
    echo ""
    echo "=========================================="
    echo "  Installation Complete!"
    echo "=========================================="
    echo ""
    echo "Agent is running and connected to controller."
    echo ""
    echo "Useful commands:"
    echo "  sudo systemctl status blackroad-agent    # Check status"
    echo "  sudo journalctl -u blackroad-agent -f    # View logs"
    echo "  sudo systemctl restart blackroad-agent   # Restart agent"
    echo ""
else
    echo ""
    echo "Warning: Agent service may not be running correctly."
    echo "Check logs with: sudo journalctl -u blackroad-agent -f"
    exit 1
fi
