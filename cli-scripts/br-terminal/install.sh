#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# BlackRoad Terminal OS — Installer
# OS within the OS — Neon Edition
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
echo -e "${ORANGE}║${RESET}  🚗 BlackRoad Terminal OS Installer     ${ORANGE}║${RESET}"
echo -e "${ORANGE}║${RESET}  OS within the OS — v0.4                ${ORANGE}║${RESET}"
echo -e "${ORANGE}╚════════════════════════════════════════════╝${RESET}"
echo ""

# Detect shell
SHELL_TYPE=$(basename "$SHELL")
if [[ "$SHELL_TYPE" == "zsh" ]]; then
  RC_FILE="$HOME/.zshrc"
  SHELL_NAME="Zsh"
elif [[ "$SHELL_TYPE" == "bash" ]]; then
  RC_FILE="$HOME/.bashrc"
  SHELL_NAME="Bash"
else
  echo -e "${PINK}❌ Unsupported shell: $SHELL_TYPE${RESET}"
  echo "   BlackRoad Terminal OS supports Bash and Zsh only."
  exit 1
fi

echo -e "${BLUE}🔍 Detected shell: ${SHELL_NAME}${RESET}"
echo -e "${BLUE}📄 Config file: ${RC_FILE}${RESET}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if already installed
if grep -q "BlackRoad Terminal OS" "$RC_FILE" 2>/dev/null; then
  echo -e "${PINK}⚠️  BlackRoad Terminal OS already installed!${RESET}"
  read -p "   Reinstall? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}✨ Installation cancelled${RESET}"
    exit 0
  fi

  # Remove old installation
  echo -e "${PURPLE}🔄 Removing old installation...${RESET}"
  sed -i.bak '/# BlackRoad Terminal OS/,/# End BlackRoad Terminal OS/d' "$RC_FILE"
fi

# Backup existing config
BACKUP_FILE="${RC_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$RC_FILE" "$BACKUP_FILE"
echo -e "${PURPLE}💾 Backed up ${RC_FILE} → ${BACKUP_FILE}${RESET}"

# Add to shell config
echo "" >> "$RC_FILE"
echo "# ══════════════════════════════════════════════════════════════════════════════" >> "$RC_FILE"
echo "# BlackRoad Terminal OS — v0.4 Emoji Edition" >> "$RC_FILE"
echo "# OS within the OS — Installed $(date '+%Y-%m-%d %H:%M:%S')" >> "$RC_FILE"
echo "# ══════════════════════════════════════════════════════════════════════════════" >> "$RC_FILE"
echo "" >> "$RC_FILE"
echo "# Load BlackRoad Terminal components" >> "$RC_FILE"
echo "[ -f \"${SCRIPT_DIR}/br-env.zsh\" ] && source \"${SCRIPT_DIR}/br-env.zsh\"" >> "$RC_FILE"
echo "[ -f \"${SCRIPT_DIR}/br-aliases.zsh\" ] && source \"${SCRIPT_DIR}/br-aliases.zsh\"" >> "$RC_FILE"
echo "[ -f \"${SCRIPT_DIR}/br-os-commands.zsh\" ] && source \"${SCRIPT_DIR}/br-os-commands.zsh\"" >> "$RC_FILE"
echo "[ -f \"${SCRIPT_DIR}/br-prompt.zsh\" ] && source \"${SCRIPT_DIR}/br-prompt.zsh\"" >> "$RC_FILE"
echo "" >> "$RC_FILE"
echo "# ══════════════════════════════════════════════════════════════════════════════" >> "$RC_FILE"
echo "# End BlackRoad Terminal OS" >> "$RC_FILE"
echo "# ══════════════════════════════════════════════════════════════════════════════" >> "$RC_FILE"

echo ""
echo -e "${ORANGE}✅ BlackRoad Terminal OS installed!${RESET}"
echo ""
echo -e "${BLUE}Components installed:${RESET}"
echo -e "  ${PURPLE}•${RESET} br-prompt.zsh  — Neon-branded λ-prompt with emojis"
echo -e "  ${PURPLE}•${RESET} br-aliases.zsh — BlackRoad aliases & functions"
echo -e "  ${PURPLE}•${RESET} br-env.zsh     — Environment variables & paths"
echo ""
echo -e "${BLUE}To activate now:${RESET}"
echo -e "  ${PURPLE}source ${RC_FILE}${RESET}"
echo ""
echo -e "${BLUE}Or simply:${RESET}"
echo -e "  ${PURPLE}reload${RESET}"
echo ""
echo -e "${ORANGE}🚗 Welcome to BlackRoad Terminal OS! 🚗${RESET}"
echo ""
