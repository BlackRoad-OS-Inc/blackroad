#!/bin/bash
#===============================================================================
# BlackRoad OS — Branded Splash (fast version of boot)
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AM='\033[38;5;214m'   # amber
PK='\033[38;5;205m'   # pink
VL='\033[38;5;135m'   # violet
BL='\033[38;5;69m'    # blue
W='\033[1;37m'        # white bold
D='\033[2m'           # dim
G='\033[1;32m'        # green
CY='\033[0;36m'       # cyan
YL='\033[1;33m'       # yellow
RD='\033[1;31m'       # red
PU='\033[1;35m'       # purple
NC='\033[0m'

tput civis 2>/dev/null
trap 'tput cnorm 2>/dev/null; exit' INT TERM

_tw() {
    local text="$1" delay="${2:-0.03}" color="${3:-}"
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${color}${text:$i:1}${NC}"
        sleep "$delay"
    done
    echo ""
}

clear
echo ""; echo ""; echo ""; echo ""

# Logo — single color, fast
echo -e "    ${AM}██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗${NC}"
echo -e "    ${AM}██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗${NC}"
echo -e "    ${PK}██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║${NC}"
echo -e "    ${PK}██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║${NC}"
echo -e "    ${VL}██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝${NC}"
echo -e "    ${VL}╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝${NC}"
echo ""

# Tagline typewriter
printf "    "
_tw "Your AI. Your Hardware. Your Rules." 0.03 "${AM}"
echo ""

# Agent dots
echo -e "    ${RD}●${NC} ${D}LUCIDIA${NC}   ${CY}●${NC} ${D}ALICE${NC}   ${G}●${NC} ${D}OCTAVIA${NC}   ${YL}●${NC} ${D}PRISM${NC}   ${PU}●${NC} ${D}ECHO${NC}   ${BL}●${NC} ${D}CIPHER${NC}"
echo ""

# Divider + CTA
echo -e "    ${D}──────────────────────────────────────────────────────────────────────────${NC}"
echo ""
printf "    "
_tw "Type  br  to begin." 0.04 "${W}"
echo ""
printf "    "
_tw "Build something impossible." 0.035 "${D}"
echo ""

sleep 0.8
tput cnorm 2>/dev/null
