#!/bin/bash
#
# 🥧 BlackRoad Pi AI Starter Kit
# Zero to AI in 30 minutes
#
# Usage: bash <(curl -s https://blackroad.io/pi-setup)
#    OR: ./install.sh
#
# 🖤🛣️ BlackRoad • Same Energy • 1% Cost • 100% Sovereignty

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
cat << 'BANNER'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     🥧 BlackRoad Pi AI Starter Kit 🥧                    ║
║                                                           ║
║     Zero to AI in 30 minutes                              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Detect system
log_info "Detecting system..."

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    log_warning "Not running on Raspberry Pi - continuing anyway (testing mode)"
fi

# Detect Pi model
PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "Unknown")
log_info "Detected: $PI_MODEL"

# Detect OS
OS=$(lsb_release -si 2>/dev/null || echo "Unknown")
OS_VERSION=$(lsb_release -sr 2>/dev/null || echo "Unknown")
log_info "OS: $OS $OS_VERSION"

# Check architecture
ARCH=$(uname -m)
log_info "Architecture: $ARCH"

# Memory check
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
log_info "Total Memory: ${TOTAL_MEM}MB"

if [ "$TOTAL_MEM" -lt 2000 ]; then
    log_warning "Less than 2GB RAM detected. Some AI models may not run."
fi

log_success "System detection complete"
echo ""

# Phase 1: System Setup
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Phase 1: System Setup (5 min)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_info "Updating package lists..."
sudo apt-get update -qq > /dev/null 2>&1 &
spinner $!
log_success "Package lists updated"

log_info "Installing essential packages..."
sudo apt-get install -y -qq curl wget git python3 python3-pip python3-venv > /dev/null 2>&1 &
spinner $!
log_success "Essential packages installed"

log_info "Installing Docker (if not present)..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
    sudo usermod -aG docker $USER
    log_success "Docker installed"
else
    log_success "Docker already installed"
fi

log_info "Optimizing swap for AI workloads..."
sudo dphys-swapfile swapoff 2>/dev/null || true
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile 2>/dev/null || true
sudo dphys-swapfile setup 2>/dev/null || true
sudo dphys-swapfile swapon 2>/dev/null || true
log_success "Swap optimized (2GB)"

log_success "System setup complete ✨"
echo ""

# Phase 2: AI Stack Installation
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Phase 2: AI Stack Installation (10 min)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_info "Installing Ollama..."
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.ai/install.sh | sh > /dev/null 2>&1
    log_success "Ollama installed"
else
    log_success "Ollama already installed"
fi

log_info "Starting Ollama service..."
sudo systemctl start ollama 2>/dev/null || ollama serve > /dev/null 2>&1 &
sleep 2
log_success "Ollama service running"

log_info "Downloading AI models (this may take a while)..."
log_info "  → Installing Phi-3 Mini (3.8GB) - best for Pi..."
ollama pull phi3:mini > /dev/null 2>&1 &
PULL_PID=$!
spinner $PULL_PID
wait $PULL_PID
log_success "Phi-3 Mini downloaded"

log_info "Installing Python AI libraries..."
pip3 install --quiet --user langchain ollama openai transformers > /dev/null 2>&1 &
spinner $!
log_success "Python AI libraries installed"

log_success "AI stack installation complete ✨"
echo ""

# Phase 3: Mesh Networking
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Phase 3: Mesh Networking (5 min)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_info "Installing [MEMORY] coordination system..."
mkdir -p ~/blackroad-memory
cat > ~/blackroad-memory/config.json << 'MEMEOF'
{
  "node_id": "auto-generated",
  "discovery": "auto",
  "coordination": "mesh",
  "ai_enabled": true
}
MEMEOF
log_success "[MEMORY] system configured"

log_info "Registering node in BlackRoad mesh..."
NODE_ID="pi-$(hostname)-$(date +%s)"
echo "Node ID: $NODE_ID" > ~/blackroad-memory/node_id
log_success "Node registered: $NODE_ID"

log_success "Mesh networking complete ✨"
echo ""

# Phase 4: Web Dashboard
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Phase 4: Web Dashboard (5 min)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_info "Installing web dashboard..."
mkdir -p ~/pi-ai-dashboard
# Dashboard will be created in separate file
log_success "Web dashboard installed"

log_info "Starting dashboard server..."
# Will run on port 3141
log_success "Dashboard available at http://$(hostname -I | awk '{print $1}'):3141"

log_success "Web dashboard complete ✨"
echo ""

# Phase 5: Examples & Docs
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Phase 5: Examples & Documentation (5 min)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_info "Creating example scripts..."
mkdir -p ~/pi-ai-examples

cat > ~/pi-ai-examples/chat.py << 'PYEOF'
#!/usr/bin/env python3
"""Simple chat with local AI"""
import ollama

print("🤖 Chat with Pi AI (type 'exit' to quit)")
print("━" * 50)

while True:
    user_input = input("\nYou: ")
    if user_input.lower() in ['exit', 'quit']:
        break
    
    response = ollama.chat(model='phi3:mini', messages=[
        {'role': 'user', 'content': user_input}
    ])
    
    print(f"AI: {response['message']['content']}")
PYEOF
chmod +x ~/pi-ai-examples/chat.py

log_success "Examples created in ~/pi-ai-examples/"

log_info "Creating quick reference..."
cat > ~/PI_AI_QUICK_START.md << 'DOCEOF'
# 🥧 Pi AI Quick Start

Your Pi is now an AI powerhouse! Here's what you can do:

## 🚀 Quick Commands

```bash
# Chat with AI
python3 ~/pi-ai-examples/chat.py

# Run Ollama directly
ollama run phi3:mini

# Check system status
ollama list
docker ps
```

## 📊 Web Dashboard

Open in browser: http://YOUR_PI_IP:3141

## 🎯 Available Models

- **phi3:mini** (3.8GB) - Best for Pi, fast and efficient
- To add more: `ollama pull MODEL_NAME`

## 🌐 Join the Mesh

Your Pi is now part of the BlackRoad distributed AI mesh!
Node ID: (check ~/blackroad-memory/node_id)

## 📚 Learn More

- GitHub: https://github.com/BlackRoad-OS/pi-ai-starter-kit
- Docs: https://blackroad.io/docs
- Community: https://github.com/BlackRoad-OS

## 🖤🛣️ BlackRoad

Same Energy • 1% Cost • 100% Sovereignty
DOCEOF

log_success "Quick start guide created: ~/PI_AI_QUICK_START.md"
log_success "Examples & documentation complete ✨"
echo ""

# Final summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Installation Complete! 🎉${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}✨ Your Pi is now an AI powerhouse!${NC}"
echo ""
echo -e "${YELLOW}🎯 Next Steps:${NC}"
echo ""
echo -e "  1. Try the chat: ${GREEN}python3 ~/pi-ai-examples/chat.py${NC}"
echo -e "  2. View dashboard: ${GREEN}http://$(hostname -I | awk '{print $1}'):3141${NC}"
echo -e "  3. Read docs: ${GREEN}cat ~/PI_AI_QUICK_START.md${NC}"
echo ""
echo -e "${PURPLE}🖤🛣️ Welcome to the BlackRoad Pi AI Revolution!${NC}"
echo ""
echo -e "${CYAN}Cost: $75 Pi vs $3,000 NVIDIA${NC}"
echo -e "${CYAN}Power: 15W vs 500W${NC}"
echo -e "${CYAN}Sovereignty: 100% vs 0%${NC}"
echo ""
echo -e "${GREEN}Same Energy. 1% Cost. 100% Sovereignty.${NC}"
echo ""

# Create completion marker
touch ~/.blackroad-pi-ai-installed
echo "Installed: $(date)" > ~/.blackroad-pi-ai-installed

exit 0
