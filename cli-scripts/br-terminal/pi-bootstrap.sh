#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# BlackRoad Terminal OS — Raspberry Pi Bootstrap
# Auto-setup for BlackRoad Pi-Mesh nodes
# ══════════════════════════════════════════════════════════════════════════════

set -e

# Colors
ORANGE='\033[38;2;255;157;0m'
PINK='\033[38;2;255;0;102m'
PURPLE='\033[38;2;119;0;255m'
BLUE='\033[38;2;0;102;255m'
RESET='\033[0m'

echo ""
echo -e "${ORANGE}╔════════════════════════════════════════════╗${RESET}"
echo -e "${ORANGE}║${RESET}  🥧 BlackRoad Pi-Mesh Bootstrap         ${ORANGE}║${RESET}"
echo -e "${ORANGE}║${RESET}  Terminal OS + Agent Runtime            ${ORANGE}║${RESET}"
echo -e "${ORANGE}╚════════════════════════════════════════════╝${RESET}"
echo ""

# Detect Pi
if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
  echo -e "${BLUE}🥧 Raspberry Pi detected!${RESET}"
  IS_PI=true
else
  echo -e "${PURPLE}💻 Not a Pi, continuing anyway...${RESET}"
  IS_PI=false
fi

# Check for required tools
echo -e "${BLUE}🔍 Checking dependencies...${RESET}"

MISSING=()
command -v git >/dev/null 2>&1 || MISSING+=("git")
command -v python3 >/dev/null 2>&1 || MISSING+=("python3")
command -v pip3 >/dev/null 2>&1 || MISSING+=("python3-pip")
command -v curl >/dev/null 2>&1 || MISSING+=("curl")

if [ ${#MISSING[@]} -ne 0 ]; then
  echo -e "${PINK}❌ Missing dependencies: ${MISSING[*]}${RESET}"
  echo -e "${BLUE}Installing via apt...${RESET}"
  sudo apt-get update
  sudo apt-get install -y "${MISSING[@]}"
fi

echo -e "${BLUE}✅ All dependencies satisfied${RESET}"

# Clone or update blackroad-sandbox
BLACKROAD_HOME="$HOME/blackroad-sandbox"
if [ -d "$BLACKROAD_HOME" ]; then
  echo -e "${PURPLE}🔄 Updating blackroad-sandbox...${RESET}"
  cd "$BLACKROAD_HOME"
  git pull origin main
else
  echo -e "${PURPLE}📥 Cloning blackroad-sandbox...${RESET}"
  git clone https://github.com/BlackRoad-OS/blackroad-os-core.git "$BLACKROAD_HOME"
  cd "$BLACKROAD_HOME"
fi

# Install Python dependencies
echo -e "${BLUE}🐍 Installing Python dependencies...${RESET}"
pip3 install -e . --user

# Install Terminal OS
echo -e "${BLUE}🎨 Installing BlackRoad Terminal OS...${RESET}"
cd "$BLACKROAD_HOME/br-terminal"
chmod +x install.sh
./install.sh

# Pi-specific configuration
if [ "$IS_PI" = true ]; then
  echo -e "${PURPLE}🥧 Configuring Pi-specific settings...${RESET}"

  # Add to crontab for auto-start on boot
  CRON_JOB="@reboot cd $BLACKROAD_HOME && python3 src/blackroad_core/spawner.py --pi-mode"
  (crontab -l 2>/dev/null | grep -v "$CRON_JOB"; echo "$CRON_JOB") | crontab -
  echo -e "${BLUE}✅ Added agent spawner to crontab${RESET}"

  # Enable SSH (if not already)
  if ! systemctl is-enabled ssh >/dev/null 2>&1; then
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo -e "${BLUE}✅ Enabled SSH${RESET}"
  fi

  # Set hostname to blackroad-pi-XXX (last 3 chars of MAC)
  MAC=$(cat /sys/class/net/eth0/address 2>/dev/null || cat /sys/class/net/wlan0/address)
  MAC_SHORT=$(echo "$MAC" | tr -d ':' | tail -c 4)
  NEW_HOSTNAME="blackroad-pi-$MAC_SHORT"

  if [ "$(hostname)" != "$NEW_HOSTNAME" ]; then
    echo -e "${PURPLE}🏷️  Setting hostname to ${NEW_HOSTNAME}...${RESET}"
    sudo hostnamectl set-hostname "$NEW_HOSTNAME"
    echo -e "${BLUE}✅ Hostname set${RESET}"
  fi
fi

# Create welcome message
cat > "$HOME/.hushlogin" <<'EOF'
EOF

# Create MOTD
sudo tee /etc/motd >/dev/null <<'EOF'
╔════════════════════════════════════════════╗
║  🚗 BlackRoad Pi-Mesh Node                ║
║  Terminal OS + Agent Runtime              ║
╚════════════════════════════════════════════╝

Type 'br' to enter the sandbox.
Type 'br-status' to check agent status.

EOF

echo ""
echo -e "${ORANGE}╔════════════════════════════════════════════╗${RESET}"
echo -e "${ORANGE}║${RESET}  ✅ BlackRoad Pi-Mesh Bootstrap Complete ${ORANGE}║${RESET}"
echo -e "${ORANGE}╚════════════════════════════════════════════╝${RESET}"
echo ""

if [ "$IS_PI" = true ]; then
  echo -e "${BLUE}Pi Configuration:${RESET}"
  echo -e "  ${PURPLE}•${RESET} Hostname: $(hostname)"
  echo -e "  ${PURPLE}•${RESET} IP: $(hostname -I | awk '{print $1}')"
  echo -e "  ${PURPLE}•${RESET} Agent spawner: Enabled on boot"
  echo ""
fi

echo -e "${BLUE}Next steps:${RESET}"
echo -e "  ${PURPLE}1.${RESET} Source your shell: ${PURPLE}source ~/.zshrc${RESET}"
echo -e "  ${PURPLE}2.${RESET} Or reload: ${PURPLE}exec \$SHELL${RESET}"
echo -e "  ${PURPLE}3.${RESET} Check status: ${PURPLE}br-status${RESET}"
echo ""
echo -e "${ORANGE}🚗 Welcome to the BlackRoad Pi-Mesh! 🚗${RESET}"
echo ""
