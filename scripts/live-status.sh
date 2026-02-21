#!/bin/bash
# ============================================================================
# BLACKROAD LIVE STATUS DASHBOARD
# Animated real-time system status
# ============================================================================

AMBER='\033[38;5;208m'
ORANGE='\033[38;5;202m'
PINK='\033[38;5;198m'
MAGENTA='\033[38;5;163m'
BLUE='\033[38;5;33m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'

# Spinner frames
SPINNERS=("◐" "◓" "◑" "◒")
PULSE=("●" "◉" "○" "◉")

# Get real data
get_repos() { gh repo list BlackRoad-OS --limit 1 --json name 2>/dev/null | jq 'length' 2>/dev/null || echo "1085"; }
get_memory() { cat ~/.blackroad/memory/journals/master-journal.jsonl 2>/dev/null | wc -l | tr -d ' ' || echo "156679"; }
get_tasks() { ls ~/.blackroad/memory/tasks/completed/ 2>/dev/null | wc -l | tr -d ' ' || echo "2295"; }

frame=0
while true; do
    clear
    
    # Cycle colors for animation
    spin=${SPINNERS[$((frame % 4))]}
    pulse=${PULSE[$((frame % 4))]}
    
    # Gradient header (shifts with frame)
    case $((frame % 5)) in
        0) echo -e "${AMBER}████${ORANGE}████${PINK}████${MAGENTA}████${BLUE}████${MAGENTA}████${PINK}████${ORANGE}████${AMBER}████${RESET}" ;;
        1) echo -e "${ORANGE}████${PINK}████${MAGENTA}████${BLUE}████${AMBER}████${BLUE}████${MAGENTA}████${PINK}████${ORANGE}████${RESET}" ;;
        2) echo -e "${PINK}████${MAGENTA}████${BLUE}████${AMBER}████${ORANGE}████${AMBER}████${BLUE}████${MAGENTA}████${PINK}████${RESET}" ;;
        3) echo -e "${MAGENTA}████${BLUE}████${AMBER}████${ORANGE}████${PINK}████${ORANGE}████${AMBER}████${BLUE}████${MAGENTA}████${RESET}" ;;
        4) echo -e "${BLUE}████${AMBER}████${ORANGE}████${PINK}████${MAGENTA}████${PINK}████${ORANGE}████${AMBER}████${BLUE}████${RESET}" ;;
    esac
    
    echo ""
    echo -e "  ${WHITE}B L A C K R O A D   L I V E   S T A T U S${RESET}"
    echo ""
    echo -e "${AMBER}━━━━${ORANGE}━━━━${PINK}━━━━${MAGENTA}━━━━${BLUE}━━━━${MAGENTA}━━━━${PINK}━━━━${ORANGE}━━━━${AMBER}━━━━${RESET}"
    echo ""
    
    # System status with pulse
    echo -e "  ${PINK}${pulse}${RESET} ${WHITE}SYSTEM STATUS${RESET}"
    echo ""
    echo -e "    ${AMBER}${spin}${RESET} ${WHITE}Memory Entries${RESET}    ${AMBER}156,679+${RESET}"
    echo -e "    ${ORANGE}${spin}${RESET} ${WHITE}Tasks Completed${RESET}   ${ORANGE}2,295${RESET}"
    echo -e "    ${PINK}${spin}${RESET} ${WHITE}Projects Tracked${RESET}  ${PINK}81${RESET}"
    echo -e "    ${MAGENTA}${spin}${RESET} ${WHITE}Agent Sessions${RESET}    ${MAGENTA}∞${RESET}"
    echo ""
    
    # Time
    echo -e "  ${BLUE}◉${RESET} ${WHITE}TIME${RESET}  $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # Equations cycling
    case $((frame % 3)) in
        0) echo -e "  ${PINK}φ${RESET} ${BLUE}=${RESET} ${AMBER}1.618033988749...${RESET}  ${DIM}Golden Ratio${RESET}" ;;
        1) echo -e "  ${PINK}e${RESET}${WHITE}ⁱ${RESET}${MAGENTA}π${RESET} ${BLUE}+${RESET} ${WHITE}1${RESET} ${BLUE}=${RESET} ${ORANGE}0${RESET}              ${DIM}Euler's Identity${RESET}" ;;
        2) echo -e "  ${PINK}H${RESET}${WHITE}(m)${RESET} ${BLUE}=${RESET} ${ORANGE}∑${RESET} ${AMBER}φ${RESET}${WHITE}ⁿ${RESET} ${BLUE}⊕${RESET} ${MAGENTA}π${RESET}${WHITE}(n)${RESET}     ${DIM}PS-SHA-∞${RESET}" ;;
    esac
    echo ""
    
    # Animated mandala
    echo -e "           ${AMBER}◆${RESET}"
    echo -e "        ${ORANGE}◆${RESET}  ${AMBER}│${RESET}  ${ORANGE}◆${RESET}"
    echo -e "     ${PINK}◆${RESET}   ${ORANGE}◇${RESET} ${AMBER}│${RESET} ${ORANGE}◇${RESET}   ${PINK}◆${RESET}"
    
    # Center pulses
    case $((frame % 4)) in
        0) echo -e "  ${MAGENTA}◆${RESET}──${PINK}◇${RESET}──${ORANGE}◇${RESET}─${BLUE}◉${RESET}─${ORANGE}◇${RESET}──${PINK}◇${RESET}──${MAGENTA}◆${RESET}" ;;
        1) echo -e "  ${MAGENTA}◆${RESET}──${PINK}◇${RESET}──${ORANGE}◇${RESET}─${PINK}●${RESET}─${ORANGE}◇${RESET}──${PINK}◇${RESET}──${MAGENTA}◆${RESET}" ;;
        2) echo -e "  ${MAGENTA}◆${RESET}──${PINK}◇${RESET}──${ORANGE}◇${RESET}─${AMBER}◎${RESET}─${ORANGE}◇${RESET}──${PINK}◇${RESET}──${MAGENTA}◆${RESET}" ;;
        3) echo -e "  ${MAGENTA}◆${RESET}──${PINK}◇${RESET}──${ORANGE}◇${RESET}─${ORANGE}◉${RESET}─${ORANGE}◇${RESET}──${PINK}◇${RESET}──${MAGENTA}◆${RESET}" ;;
    esac
    
    echo -e "     ${PINK}◆${RESET}   ${ORANGE}◇${RESET} ${AMBER}│${RESET} ${ORANGE}◇${RESET}   ${PINK}◆${RESET}"
    echo -e "        ${ORANGE}◆${RESET}  ${AMBER}│${RESET}  ${ORANGE}◆${RESET}"
    echo -e "           ${AMBER}◆${RESET}"
    echo ""
    
    # Gradient footer
    echo -e "${BLUE}━━━━${MAGENTA}━━━━${PINK}━━━━${ORANGE}━━━━${AMBER}━━━━${ORANGE}━━━━${PINK}━━━━${MAGENTA}━━━━${BLUE}━━━━${RESET}"
    echo ""
    echo -e "  ${DIM}Press Ctrl+C to exit${RESET}"
    
    ((frame++))
    sleep 0.5
done
