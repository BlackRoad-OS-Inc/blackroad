#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# BlackRoad Terminal OS — Installer v0.5
# OS within the OS — Brand Edition
# ══════════════════════════════════════════════════════════════════════════════

set -e

AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
GREEN='\033[0;32m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${AMBER}${BOLD}◆ BR TERMINAL v0.5${NC}  ${DIM}OS within the OS — Brand Edition${NC}"
echo -e "${DIM}────────────────────────────────────────────────${NC}"
echo ""

SHELL_TYPE=$(basename "$SHELL")
if [[ "$SHELL_TYPE" == "zsh" ]]; then
  RC_FILE="$HOME/.zshrc"
elif [[ "$SHELL_TYPE" == "bash" ]]; then
  RC_FILE="$HOME/.bashrc"
else
  echo -e "${PINK}x Unsupported shell: $SHELL_TYPE${NC}"
  exit 1
fi

echo -e "  ${DIM}shell:${NC}  $SHELL_TYPE  →  $RC_FILE"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove previous BlackRoad Terminal block if present
if grep -q "BlackRoad Terminal OS" "$RC_FILE" 2>/dev/null; then
  echo -e "  ${AMBER}~${NC}  Removing previous installation..."
  sed -i.bak '/# BlackRoad Terminal OS/,/# End BlackRoad Terminal OS/d' "$RC_FILE"
fi

# Backup
BACKUP="${RC_FILE}.br-backup.$(date +%Y%m%d_%H%M%S)"
cp "$RC_FILE" "$BACKUP"
echo -e "  ${DIM}backup:${NC} $BACKUP"

# Append v0.5 block
cat >> "$RC_FILE" << ZSHBLOCK

# ══════════════════════════════════════════════════════════════════════════════
# BlackRoad Terminal OS — v0.5 Brand Edition
# Installed $(date '+%Y-%m-%d %H:%M:%S')
# ══════════════════════════════════════════════════════════════════════════════
[ -f "${SCRIPT_DIR}/br-env.zsh" ]        && source "${SCRIPT_DIR}/br-env.zsh"
[ -f "${SCRIPT_DIR}/br-aliases.zsh" ]    && source "${SCRIPT_DIR}/br-aliases.zsh"
[ -f "${SCRIPT_DIR}/br-os-commands.zsh" ] && source "${SCRIPT_DIR}/br-os-commands.zsh"
[ -f "${SCRIPT_DIR}/br-prompt.zsh" ]     && source "${SCRIPT_DIR}/br-prompt.zsh"
# ══════════════════════════════════════════════════════════════════════════════
# End BlackRoad Terminal OS
# ══════════════════════════════════════════════════════════════════════════════
ZSHBLOCK

echo ""
echo -e "  ${GREEN}v${NC}  br-env.zsh        brand colors, paths, history"
echo -e "  ${GREEN}v${NC}  br-aliases.zsh    hub(), brr(), agent(), cece(), git, docker"
echo -e "  ${GREEN}v${NC}  br-os-commands.zsh  br-help, welcome banner"
echo -e "  ${GREEN}v${NC}  br-prompt.zsh     λ-prompt, git dirty/ahead-behind"
echo ""
echo -e "  ${AMBER}${BOLD}◆ Installed!${NC}  Run: ${AMBER}source ${RC_FILE}${NC}"
echo ""
