#!/bin/bash
# BlackRoad Terminal Pixel Visualizer
# ASCII art renderer for the metaverse

# BlackRoad colors (ANSI)
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
GREEN='\033[38;5;82m'
RESET='\033[0m'

clear

echo -e "${PINK}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║${RESET}        ${AMBER}🌌 BLACKROAD PIXEL METAVERSE - TERMINAL VIEW${RESET}        ${PINK}║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Display live sessions
echo -e "${BLUE}[ACTIVE SESSIONS]${RESET}"
SESSIONS=$(ps aux | grep "node dist/bin/cli.js" | grep -v grep | wc -l)
echo -e "  Sessions streaming: ${GREEN}$SESSIONS${RESET}"
echo ""

# Check for BlackRoad memory
if [ -d ~/.blackroad/memory/active-agents ]; then
  AGENT_COUNT=$(ls ~/.blackroad/memory/active-agents/*.json 2>/dev/null | wc -l)
  echo -e "${VIOLET}[ACTIVE AGENTS]${RESET}"
  echo -e "  Total agents: ${GREEN}$AGENT_COUNT${RESET}"
  echo ""
  
  # List agents
  for file in ~/.blackroad/memory/active-agents/*.json; do
    if [ -f "$file" ]; then
      NAME=$(jq -r '.name // .agent_id // "Unknown"' "$file" 2>/dev/null)
      ROLE=$(jq -r '.role // "agent"' "$file" 2>/dev/null)
      echo -e "  ${PINK}▸${RESET} ${AMBER}$NAME${RESET} ${BLUE}($ROLE)${RESET}"
    fi
  done
  echo ""
fi

# Display Claude Code sessions
echo -e "${AMBER}[CLAUDE CODE SESSIONS]${RESET}"
if [ -d ~/.claude/session-state ]; then
  CLAUDE_SESSIONS=$(ls -1 ~/.claude/session-state 2>/dev/null | wc -l)
  echo -e "  Active sessions: ${GREEN}$CLAUDE_SESSIONS${RESET}"
  
  # Show recent session activity
  RECENT=$(find ~/.claude/session-state -type f -mmin -5 | wc -l)
  echo -e "  Recent activity (5min): ${GREEN}$RECENT files${RESET}"
fi
echo ""

# Display memory stats
echo -e "${VIOLET}[MEMORY SYSTEM]${RESET}"
if [ -d ~/.blackroad/memory/journals ]; then
  JOURNAL_COUNT=$(ls ~/.blackroad/memory/journals/*.jsonl 2>/dev/null | wc -l)
  TOTAL_ENTRIES=0
  
  for journal in ~/.blackroad/memory/journals/*.jsonl; do
    if [ -f "$journal" ]; then
      LINES=$(wc -l < "$journal" 2>/dev/null)
      TOTAL_ENTRIES=$((TOTAL_ENTRIES + LINES))
    fi
  done
  
  echo -e "  Journal files: ${GREEN}$JOURNAL_COUNT${RESET}"
  echo -e "  Total entries: ${GREEN}$TOTAL_ENTRIES${RESET}"
fi
echo ""

# Display pixel grid (simple animation)
echo -e "${PINK}[PIXEL WORLD]${RESET}"
echo ""

# Draw a simple pixel grid with agents
WIDTH=60
HEIGHT=15

for y in $(seq 1 $HEIGHT); do
  echo -n "  "
  for x in $(seq 1 $WIDTH); do
    RAND=$((RANDOM % 100))
    if [ $RAND -lt 5 ]; then
      echo -n -e "${PINK}▓${RESET}"
    elif [ $RAND -lt 10 ]; then
      echo -n -e "${AMBER}▒${RESET}"
    elif [ $RAND -lt 12 ]; then
      echo -n -e "${BLUE}░${RESET}"
    else
      echo -n " "
    fi
  done
  echo ""
done

echo ""
echo -e "${GREEN}✓${RESET} Metaverse bridge active at ${BLUE}ws://localhost:8765${RESET}"
echo -e "${GREEN}✓${RESET} Web visualizer: ${BLUE}file://$(pwd)/public/pixel-world.html${RESET}"
echo ""
echo -e "${AMBER}Press Ctrl+C to exit...${RESET}"
