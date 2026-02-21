#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# BlackRoad OS - The Terminal Internet
# One command to rule them all
# ═══════════════════════════════════════════════════════════════

set -e

VERSION="1.0.0"
CONFIG_DIR="$HOME/.config/blackroad"

# Colors
R='\033[0m'
B='\033[1m'
C='\033[36m'
G='\033[32m'
Y='\033[33m'
M='\033[35m'
O='\033[38;5;208m'
RED='\033[31m'

# Banner
show_banner() {
  clear
  echo -e "${B}${M}"
  cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║ ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗     ║
    ║ ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗    ║
    ║ ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║    ║
    ║ ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║    ║
    ║ ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝    ║
    ║ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝     ║
    ╠═══════════════════════════════════════════════════════════════╣
    ║              T H E   T E R M I N A L   I N T E R N E T        ║
    ║                        Version ${VERSION}                          ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
  echo -e "${R}"
}

# Check dependencies
check_deps() {
  local missing=()

  if ! command -v tmux &> /dev/null; then
    missing+=("tmux")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing dependencies: ${missing[*]}${R}"
    echo -e "${Y}Install with: brew install ${missing[*]}${R}"
    exit 1
  fi
}

# Pre-flight check
preflight() {
  echo -e "${C}⚡ Running pre-flight checks...${R}\n"

  local nodes=("aria:192.168.4.64" "lucidia:192.168.4.38" "alice:192.168.4.49" "shellfish:174.138.44.45")
  local online=0
  local total=${#nodes[@]}

  for node_info in "${nodes[@]}"; do
    IFS=':' read -r name ip <<< "$node_info"
    printf "  %-12s " "[$name]"
    if ping -c 1 -W 1 $ip &>/dev/null; then
      echo -e "${G}● ONLINE${R}"
      ((online++))
    else
      echo -e "${RED}● OFFLINE${R}"
    fi
  done

  echo ""
  echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo -e "${G}✓ Mesh Status: ${online}/${total} nodes online${R}"
  echo ""
}

# Launch Brady Bunch Grid
launch_grid() {
  echo -e "${Y}🚀 Launching Brady Bunch Grid...${R}\n"
  sleep 1

  # Create tmux session with synchronized panes support
  tmux new-session -d -s blackroad-os -n mesh

  # Set tmux options for the session
  tmux set-option -t blackroad-os status-style "bg=colour235,fg=colour136"
  tmux set-option -t blackroad-os status-left "#[fg=colour235,bg=colour136,bold] 🚗 BLACKROAD OS #[default]"
  tmux set-option -t blackroad-os status-right "#[fg=colour235,bg=colour136,bold] %H:%M:%S | operator@blackroad #[default]"
  tmux set-option -t blackroad-os status-interval 1

  # Create 3x2 grid layout (Brady Bunch style)
  # Top row: aria, lucidia, alice
  tmux send-keys -t blackroad-os:mesh "ssh aria" C-m

  tmux split-window -h -t blackroad-os:mesh
  tmux send-keys -t blackroad-os:mesh "ssh lucidia" C-m

  tmux split-window -h -t blackroad-os:mesh
  tmux send-keys -t blackroad-os:mesh "ssh alice" C-m

  # Bottom row: shellfish, operator (mac), claude
  tmux select-pane -t blackroad-os:mesh.0
  tmux split-window -v -t blackroad-os:mesh
  tmux send-keys -t blackroad-os:mesh "ssh shellfish" C-m

  tmux select-pane -t blackroad-os:mesh.1
  tmux split-window -v -t blackroad-os:mesh
  tmux send-keys -t blackroad-os:mesh "clear && echo '💻 OPERATOR@BLACKROAD - MAC CONTROL' && echo '' && $CONFIG_DIR/node-banner.sh operator && exec zsh" C-m

  tmux select-pane -t blackroad-os:mesh.2
  tmux split-window -v -t blackroad-os:mesh
  tmux send-keys -t blackroad-os:mesh "clear && echo '🤖 CLAUDE AI CO-PILOT' && echo '' && claude" C-m

  # Balance the layout
  tmux select-layout -t blackroad-os:mesh tiled

  # Enable mouse support
  tmux set-option -t blackroad-os mouse on

  # Create control window with broadcast instructions
  tmux new-window -t blackroad-os -n control
  tmux send-keys -t blackroad-os:control "clear" C-m
  tmux send-keys -t blackroad-os:control "cat << 'CONTROL_EOF'
╔════════════════════════════════════════════════════════════════╗
║           🚗 BLACKROAD OS - CONTROL CENTER                    ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  BROADCAST MODE - Talk to all windows at once!                ║
║                                                                ║
║  Controls:                                                     ║
║  ─────────────────────────────────────────────────────────────║
║                                                                ║
║  Ctrl+B then :                                                 ║
║    → Enter tmux command mode                                   ║
║                                                                ║
║  :setw synchronize-panes on                                    ║
║    → Enable broadcast (type in one, sends to all!)            ║
║                                                                ║
║  :setw synchronize-panes off                                   ║
║    → Disable broadcast                                         ║
║                                                                ║
║  Ctrl+B then [ arrow keys ]                                    ║
║    → Navigate between panes                                    ║
║                                                                ║
║  Ctrl+B then z                                                 ║
║    → Zoom/unzoom current pane                                  ║
║                                                                ║
║  Ctrl+B then d                                                 ║
║    → Detach (session keeps running)                            ║
║                                                                ║
║  Ctrl+B then w                                                 ║
║    → Switch between windows                                    ║
║                                                                ║
║  Quick Commands:                                               ║
║  ─────────────────────────────────────────────────────────────║
║                                                                ║
║  Ctrl+B then :                                                 ║
║    send-keys -t blackroad-os:mesh.0 'uptime' C-m               ║
║    → Send command to specific pane (0-5)                       ║
║                                                                ║
║  Broadcast Example:                                            ║
║  1. Ctrl+B :                                                   ║
║  2. setw synchronize-panes on                                  ║
║  3. Switch to 'mesh' window (Ctrl+B w)                         ║
║  4. Type 'uptime' - executes on ALL nodes!                     ║
║  5. Ctrl+B :                                                   ║
║  6. setw synchronize-panes off                                 ║
║                                                                ║
╠════════════════════════════════════════════════════════════════╣
║  Window 0: mesh      - Brady Bunch Grid (6 panes)             ║
║  Window 1: control   - This control panel                     ║
╠════════════════════════════════════════════════════════════════╣
║  Press Ctrl+B then w to switch to mesh window                 ║
╚════════════════════════════════════════════════════════════════╝

Type 'help' for more commands, or just press Ctrl+B then w to get started!

CONTROL_EOF
" C-m

  # Add helper functions to control window
  tmux send-keys -t blackroad-os:control "cat > /tmp/br-control-help.sh << 'HELPER_EOF'
#!/bin/bash

help() {
  cat << 'HELP_TEXT'
BlackRoad OS Commands:
  broadcast-on   - Enable broadcast mode (type to all panes)
  broadcast-off  - Disable broadcast mode
  goto-mesh      - Switch to mesh grid window
  status         - Show all node status
  exec-all       - Execute command on all nodes
HELP_TEXT
}

broadcast-on() {
  tmux setw -t blackroad-os:mesh synchronize-panes on
  echo '✓ Broadcast mode enabled - commands will be sent to ALL panes'
}

broadcast-off() {
  tmux setw -t blackroad-os:mesh synchronize-panes off
  echo '✓ Broadcast mode disabled'
}

goto-mesh() {
  tmux select-window -t blackroad-os:mesh
}

status() {
  echo 'Checking mesh status...'
  for node in aria lucidia alice shellfish; do
    printf \"  %-12s \" \"[\$node]\"
    if ping -c 1 -W 1 \$node &>/dev/null; then
      echo -e \"\033[32m● ONLINE\033[0m\"
    else
      echo -e \"\033[31m● OFFLINE\033[0m\"
    fi
  done
}

exec-all() {
  if [ -z \"\$1\" ]; then
    echo \"Usage: exec-all <command>\"
    return 1
  fi

  echo \"Executing '\$@' on all nodes...\"
  for pane in {0..2}; do
    tmux send-keys -t blackroad-os:mesh.\$pane \"\$@\" C-m
  done
  tmux send-keys -t blackroad-os:mesh.3 \"\$@\" C-m
}

HELPER_EOF
source /tmp/br-control-help.sh
" C-m

  # Switch to mesh window
  tmux select-window -t blackroad-os:mesh

  # Attach to session
  echo -e "${G}✓ BlackRoad OS Grid Launched!${R}\n"
  echo -e "${C}Attaching to session in 2 seconds...${R}"
  echo -e "${Y}Tip: Use Ctrl+B then : and type 'setw synchronize-panes on' to broadcast!${R}\n"
  sleep 2

  tmux attach-session -t blackroad-os
}

# Main menu
main_menu() {
  show_banner
  preflight

  echo -e "${B}${C}What would you like to do?${R}\n"
  echo -e "  ${Y}1${R}) Launch COMPACT Grid (6-panel, fits any screen) ${G}✓ RECOMMENDED${R}"
  echo -e "  ${Y}2${R}) Launch ULTIMATE Grid (12-panel AI ecosystem) ${O}⚡ FULLSCREEN NEEDED${R}"
  echo -e "  ${Y}3${R}) Quick status check"
  echo -e "  ${Y}4${R}) Help & Documentation"
  echo -e "  ${Y}5${R}) Exit"
  echo ""
  read -p "$(echo -e ${C}Choose [1-5]: ${R})" choice

  case $choice in
    1)
      echo -e "\n${G}✓ Launching COMPACT mode (works on any screen size)...${R}\n"
      exec blackroad-os-compact
      ;;
    2)
      echo -e "\n${O}⚡ Launching ULTIMATE mode (make terminal FULLSCREEN first!)...${R}\n"
      sleep 1
      exec blackroad-os-ultimate
      ;;
    3)
      preflight
      read -p "Press Enter to continue..."
      main_menu
      ;;
    4)
      less "$CONFIG_DIR/README.md"
      main_menu
      ;;
    5)
      echo -e "\n${M}🚗 blackroad - Drive safe!${R}\n"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice${R}"
      sleep 1
      main_menu
      ;;
  esac
}

# Parse arguments
case "${1:-}" in
  --version|-v)
    echo "BlackRoad OS v${VERSION}"
    exit 0
    ;;
  --help|-h)
    cat << HELP
BlackRoad OS - The Terminal Internet

Usage: blackroad-os [OPTIONS]

Options:
  --version, -v     Show version
  --help, -h        Show this help
  --grid            Launch grid directly (skip menu)
  --status          Show mesh status

Interactive mode (no arguments):
  Launches full interactive menu with Brady Bunch grid

Grid Features:
  - 6-panel tmux layout (aria, lucidia, alice, shellfish, operator, claude)
  - Broadcast mode: Type once, execute everywhere
  - Mouse support enabled
  - Live status bar
  - Control panel with instructions

Examples:
  blackroad-os              # Interactive menu
  blackroad-os --grid       # Launch grid directly
  blackroad-os --status     # Quick status check

HELP
    exit 0
    ;;
  --grid)
    show_banner
    preflight
    launch_grid
    ;;
  --status)
    show_banner
    preflight
    exit 0
    ;;
  "")
    # Check dependencies
    check_deps
    # No arguments - run interactive menu
    main_menu
    ;;
  *)
    echo "Unknown option: $1"
    echo "Use --help for usage information"
    exit 1
    ;;
esac
