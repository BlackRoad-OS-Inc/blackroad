#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# BlackRoad OS COMPACT - 6-Panel Optimized Layout
# Works on smaller terminals - no space issues!
# ═══════════════════════════════════════════════════════════════

VERSION="2.0.0-COMPACT"
CONFIG_DIR="$HOME/.config/blackroad"

# Load colors
source "$CONFIG_DIR/colors.sh" 2>/dev/null || {
  ORANGE='\033[38;5;214m'
  BRIGHT_ORANGE='\033[38;5;202m'
  HOT_PINK='\033[38;5;199m'
  MAGENTA='\033[38;5;165m'
  PURPLE='\033[38;5;93m'
  BLUE='\033[38;5;33m'
  NAVY='\033[38;5;17m'
  R='\033[0m'
  B='\033[1m'
}

# Banner
show_banner() {
  clear
  echo -e "${B}"
  echo -e "${ORANGE}╔═══════════════════════════════════════════════════════════════╗${R}"
  echo -e "${BRIGHT_ORANGE}║ ${B}\033[97m██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗${BRIGHT_ORANGE}     ║${R}"
  echo -e "${HOT_PINK}║ ${B}\033[97m██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗${HOT_PINK}    ║${R}"
  echo -e "${MAGENTA}║ ${B}\033[97m██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║${MAGENTA}    ║${R}"
  echo -e "${PURPLE}║ ${B}\033[97m██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║${PURPLE}    ║${R}"
  echo -e "${BLUE}║ ${B}\033[97m██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝${BLUE}    ║${R}"
  echo -e "${NAVY}║ ${B}\033[97m╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝${NAVY}     ║${R}"
  echo -e "${ORANGE}╠═══════════════════════════════════════════════════════════════╣${R}"
  echo -e "${HOT_PINK}║          ${B}\033[97mC O M P A C T   M E S H   G R I D${HOT_PINK}                 ║${R}"
  echo -e "${MAGENTA}║                     ${B}\033[97mblackroad${MAGENTA} \033[2m\033[97m${VERSION}${MAGENTA}                      ║${R}"
  echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${R}"
  echo -e "${R}"
}

show_banner

echo -e "${ORANGE}🚀 Launching Compact 6-Panel Grid...${R}\n"

# Kill existing session
tmux kill-session -t blackroad-compact 2>/dev/null || true

# Create session with conservative sizing
tmux new-session -d -s blackroad-compact -n "MESH"

# Configure tmux
tmux set-option -t blackroad-compact status-style "bg=colour17,fg=colour214"
tmux set-option -t blackroad-compact status-left "#[fg=colour17,bg=colour214,bold] 🚗 blackroad #[default]"
tmux set-option -t blackroad-compact status-right "#[fg=colour17,bg=colour33,bold] %H:%M:%S #[default]"
tmux set-option -t blackroad-compact status-interval 1
tmux set-option -t blackroad-compact mouse on

# Create 2x3 grid (easier to fit)
# Row 1: aria, lucidia, alice
tmux send-keys -t blackroad-compact "ssh aria" C-m
tmux split-window -h -t blackroad-compact
tmux send-keys -t blackroad-compact "ssh lucidia" C-m
tmux split-window -h -t blackroad-compact
tmux send-keys -t blackroad-compact "ssh alice" C-m

# Row 2: claude, operator, docker
tmux select-pane -t blackroad-compact.0
tmux split-window -v -t blackroad-compact
tmux send-keys -t blackroad-compact "clear && echo '🤖 CLAUDE AI' && claude" C-m

tmux select-pane -t blackroad-compact.1
tmux split-window -v -t blackroad-compact
tmux send-keys -t blackroad-compact "clear && echo '💻 OPERATOR' && exec zsh" C-m

tmux select-pane -t blackroad-compact.2
tmux split-window -v -t blackroad-compact
tmux send-keys -t blackroad-compact "clear && echo '🐳 DOCKER' && docker ps && exec zsh" C-m

# Even layout
tmux select-layout -t blackroad-compact tiled

echo -e "${BLUE}✓ Compact Grid Launched!${R}\n"
echo -e "${ORANGE}Layout: 2 rows × 3 columns (fits any terminal size)${R}\n"
sleep 1

# Attach
tmux attach-session -t blackroad-compact
