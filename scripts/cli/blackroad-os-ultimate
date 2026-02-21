#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# BlackRoad OS ULTIMATE - The Complete AI Ecosystem
# 12-Panel Brady Bunch Grid with ALL AI Services
# ═══════════════════════════════════════════════════════════════

set -e

VERSION="2.0.0-ULTIMATE"
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

# Load colors
source "$CONFIG_DIR/colors.sh" 2>/dev/null || {
  # Fallback colors
  ORANGE='\033[38;5;214m'
  BRIGHT_ORANGE='\033[38;5;202m'
  HOT_PINK='\033[38;5;199m'
  MAGENTA='\033[38;5;165m'
  PURPLE='\033[38;5;93m'
  BLUE='\033[38;5;33m'
  NAVY='\033[38;5;17m'
}

# Banner
show_banner() {
  clear
  echo -e "${B}"
  echo -e "${ORANGE}    ╔═══════════════════════════════════════════════════════════════╗${R}"
  echo -e "${BRIGHT_ORANGE}    ║ ${B}\033[97m██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗${BRIGHT_ORANGE}     ║${R}"
  echo -e "${HOT_PINK}    ║ ${B}\033[97m██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗${HOT_PINK}    ║${R}"
  echo -e "${MAGENTA}    ║ ${B}\033[97m██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║${MAGENTA}    ║${R}"
  echo -e "${PURPLE}    ║ ${B}\033[97m██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║${PURPLE}    ║${R}"
  echo -e "${BLUE}    ║ ${B}\033[97m██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝${BLUE}    ║${R}"
  echo -e "${NAVY}    ║ ${B}\033[97m╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝${NAVY}     ║${R}"
  echo -e "${ORANGE}    ╠═══════════════════════════════════════════════════════════════╣${R}"
  echo -e "${BRIGHT_ORANGE}    ║          ${B}\033[97mU L T I M A T E   A I   E C O S Y S T E M${BRIGHT_ORANGE}           ║${R}"
  echo -e "${HOT_PINK}    ║                     ${B}\033[97mblackroad${HOT_PINK} \033[2m\033[97mv2.0.0-ULTIMATE${HOT_PINK}                      ║${R}"
  echo -e "${MAGENTA}    ╚═══════════════════════════════════════════════════════════════╝${R}"
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

  echo -e "${B}${C}═══ INFRASTRUCTURE NODES ═══${R}"
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
  echo -e "${B}${C}═══ AI SERVICES ═══${R}"

  # Check Claude CLI
  printf "  %-12s " "[Claude]"
  if command -v claude &> /dev/null; then
    echo -e "${G}● INSTALLED${R}"
  else
    echo -e "${Y}● NOT INSTALLED${R}"
  fi

  # Check shell-gpt (ChatGPT)
  printf "  %-12s " "[ChatGPT]"
  if command -v sgpt &> /dev/null; then
    echo -e "${G}● INSTALLED${R}"
  else
    echo -e "${Y}● BROWSER ONLY${R}"
  fi

  # Check Docker for Enclave
  printf "  %-12s " "[Enclave AI]"
  if docker ps 2>/dev/null | grep -q enclave-ai; then
    echo -e "${G}● RUNNING${R}"
  elif command -v docker &> /dev/null; then
    echo -e "${Y}● READY${R}"
  else
    echo -e "${RED}● DOCKER NEEDED${R}"
  fi

  # Gemini, Grok, Perplexity (browser-based)
  printf "  %-12s " "[Gemini]"
  echo -e "${C}● BROWSER${R}"
  printf "  %-12s " "[Grok]"
  echo -e "${C}● BROWSER${R}"
  printf "  %-12s " "[Perplexity]"
  echo -e "${C}● BROWSER${R}"

  echo ""
  echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo -e "${G}✓ Infrastructure: ${online}/${total} nodes online${R}"
  echo ""
}

# Launch ULTIMATE 12-Panel Grid
launch_ultimate_grid() {
  echo -e "${Y}🚀 Launching ULTIMATE 12-Panel Grid...${R}\n"
  echo -e "${C}Layout: 4 rows × 3 columns${R}"
  echo -e "${M}Pi Nodes | AI Ecosystem | Control Center${R}\n"
  echo -e "${ORANGE}💡 Tip: Make your terminal window FULLSCREEN for best experience${R}\n"
  sleep 2

  # Source AI wrappers
  source "$CONFIG_DIR/ai-wrappers.sh"

  # Kill existing session if it exists
  tmux kill-session -t blackroad-ultimate 2>/dev/null || true

  # Create tmux session with larger default size
  tmux new-session -d -s blackroad-ultimate -n "AI-MESH" -x 240 -y 70

  # Configure tmux with BlackRoad branding
  tmux set-option -t blackroad-ultimate status-style "bg=colour17,fg=colour214"  # Navy bg, Orange fg
  tmux set-option -t blackroad-ultimate status-left "#[fg=colour17,bg=colour214,bold] 🚗 blackroad ${R}#[fg=colour17,bg=colour199] ULTIMATE ${R}#[default]"
  tmux set-option -t blackroad-ultimate status-right "#[fg=colour17,bg=colour33,bold] %H:%M:%S #[default]#[fg=colour17,bg=colour165,bold] operator@blackroad #[default]"
  tmux set-option -t blackroad-ultimate status-interval 1
  tmux set-option -t blackroad-ultimate mouse on

  # Set default terminal for proper font rendering
  tmux set-option -t blackroad-ultimate default-terminal "screen-256color"

  # Allow aggressive resizing
  tmux set-window-option -t blackroad-ultimate aggressive-resize on

  # ═══════════════════════════════════════════════════════════
  # ROW 1: Pi Infrastructure Nodes
  # ═══════════════════════════════════════════════════════════

  # Pane 0: ARIA
  tmux send-keys -t blackroad-ultimate "clear && ssh aria" C-m

  # Pane 1: LUCIDIA
  tmux split-window -h -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && ssh lucidia" C-m

  # Pane 2: ALICE
  tmux split-window -h -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && ssh alice" C-m

  # ═══════════════════════════════════════════════════════════
  # ROW 2: Cloud + Primary AI
  # ═══════════════════════════════════════════════════════════

  # Pane 3: SHELLFISH (Cloud)
  tmux select-pane -t blackroad-ultimate.0
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && ssh shellfish" C-m

  # Pane 4: CLAUDE AI
  tmux select-pane -t blackroad-ultimate.1
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '🤖 CLAUDE AI CO-PILOT' && echo '' && claude" C-m

  # Pane 5: CHATGPT
  tmux select-pane -t blackroad-ultimate.2
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '💚 ChatGPT Interface' && echo '' && source $CONFIG_DIR/ai-wrappers.sh && chatgpt" C-m

  # ═══════════════════════════════════════════════════════════
  # ROW 3: Extended AI Ecosystem
  # ═══════════════════════════════════════════════════════════

  # Pane 6: GEMINI
  tmux select-pane -t blackroad-ultimate.3
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '🔷 Google Gemini' && echo '' && source $CONFIG_DIR/ai-wrappers.sh && gemini" C-m

  # Pane 7: GROK
  tmux select-pane -t blackroad-ultimate.4
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '⚡ Grok (X.AI)' && echo '' && source $CONFIG_DIR/ai-wrappers.sh && grok" C-m

  # Pane 8: PERPLEXITY
  tmux select-pane -t blackroad-ultimate.5
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '🔍 Perplexity AI' && echo '' && source $CONFIG_DIR/ai-wrappers.sh && perplexity" C-m

  # ═══════════════════════════════════════════════════════════
  # ROW 4: Enclave AI + Control Panels
  # ═══════════════════════════════════════════════════════════

  # Pane 9: ENCLAVE AI
  tmux select-pane -t blackroad-ultimate.6
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '🔐 Enclave AI' && echo '' && source $CONFIG_DIR/ai-wrappers.sh && enclave" C-m

  # Pane 10: OPERATOR (Your Mac)
  tmux select-pane -t blackroad-ultimate.7
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '💻 OPERATOR@BLACKROAD - MAC CONTROL' && echo '' && $CONFIG_DIR/node-banner.sh operator && exec zsh" C-m

  # Pane 11: DOCKER / LOGS
  tmux select-pane -t blackroad-ultimate.8
  tmux split-window -v -t blackroad-ultimate
  tmux send-keys -t blackroad-ultimate "clear && echo '🐳 DOCKER MONITOR' && echo '' && docker ps && echo '' && echo 'Commands: docker ps, docker logs <container>' && exec zsh" C-m

  # Balance layout
  tmux select-layout -t blackroad-ultimate tiled

  # Create control window
  tmux new-window -t blackroad-ultimate -n "CONTROL"
  tmux send-keys -t blackroad-ultimate:CONTROL "clear" C-m
  tmux send-keys -t blackroad-ultimate:CONTROL "cat << 'CONTROL_EOF'
╔════════════════════════════════════════════════════════════════╗
║       🚗 BLACKROAD OS ULTIMATE - CONTROL CENTER               ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  12-PANEL LAYOUT - THE COMPLETE AI ECOSYSTEM                  ║
║                                                                ║
║  ┌─────────────┬──────────────┬─────────────┐                ║
║  │    ARIA     │   LUCIDIA    │    ALICE    │  Row 1: Pi     ║
║  ├─────────────┼──────────────┼─────────────┤                ║
║  │  SHELLFISH  │    CLAUDE    │   CHATGPT   │  Row 2: Core   ║
║  ├─────────────┼──────────────┼─────────────┤                ║
║  │   GEMINI    │     GROK     │ PERPLEXITY  │  Row 3: AI     ║
║  ├─────────────┼──────────────┼─────────────┤                ║
║  │  ENCLAVE    │   OPERATOR   │   DOCKER    │  Row 4: Ctrl   ║
║  └─────────────┴──────────────┴─────────────┘                ║
║                                                                ║
║  BROADCAST MODE:                                              ║
║  ──────────────────────────────────────────────────────────  ║
║  Ctrl+B : setw synchronize-panes on   → Broadcast to all     ║
║  Ctrl+B : setw synchronize-panes off  → Individual control   ║
║                                                                ║
║  NAVIGATION:                                                   ║
║  ──────────────────────────────────────────────────────────  ║
║  Ctrl+B [arrows]  → Move between panes                        ║
║  Ctrl+B z         → Zoom/unzoom pane                          ║
║  Ctrl+B w         → Window list                               ║
║  Ctrl+B d         → Detach session                            ║
║  Mouse click      → Select pane                               ║
║                                                                ║
║  USEFUL COMMANDS:                                              ║
║  ──────────────────────────────────────────────────────────  ║
║  Broadcast 'uptime' to all Pi nodes (0-3)                     ║
║  Query all AI services simultaneously                         ║
║  Monitor all systems in real-time                             ║
║                                                                ║
╠════════════════════════════════════════════════════════════════╣
║  Press Ctrl+B then w, select 'AI-MESH' to enter the grid     ║
╚════════════════════════════════════════════════════════════════╝

CONTROL_EOF
" C-m

  # Switch to AI-MESH window
  tmux select-window -t blackroad-ultimate:AI-MESH

  echo -e "${G}✓ ULTIMATE Grid Launched!${R}\n"
  echo -e "${C}Attaching to session...${R}"
  echo -e "${Y}Layout: 12 panels (4×3 grid)${R}"
  echo -e "${M}Pi Nodes + All AI Services + Control Panels${R}\n"
  sleep 2

  tmux attach-session -t blackroad-ultimate
}

# Main execution
show_banner
check_deps
preflight

echo -e "${B}${Y}Ready to launch the ULTIMATE AI Ecosystem?${R}\n"
read -p "Press Enter to continue or Ctrl+C to cancel..."

launch_ultimate_grid
