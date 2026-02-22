#!/bin/bash
#===============================================================================
# BlackRoad OS — Cinematic Boot Sequence v2.0
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Brand colors
AM='\033[38;5;214m'   # amber
AM2='\033[38;5;220m'  # amber light
AM3='\033[38;5;172m'  # amber dim
PK='\033[38;5;205m'   # pink / hot-pink
PK2='\033[38;5;201m'  # pink bright
VL='\033[38;5;135m'   # violet
BL='\033[38;5;69m'    # electric blue
W='\033[1;37m'        # white bold
D='\033[2m'           # dim
G='\033[1;32m'        # green
CY='\033[0;36m'       # cyan
YL='\033[1;33m'       # yellow
RD='\033[1;31m'       # red
PU='\033[1;35m'       # purple
NC='\033[0m'          # reset

tput civis 2>/dev/null
trap 'tput cnorm 2>/dev/null; clear; exit' INT TERM

# ── typewriter ──────────────────────────────────────────────────────────────
_tw() {
    local text="$1" delay="${2:-0.025}" color="${3:-}"
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${color}${text:$i:1}${NC}"
        sleep "$delay"
    done
    echo ""
}

# ── glitch flash ─────────────────────────────────────────────────────────────
_glitch() {
    local glyphs='░▒▓█▄▀■□▪▫◆◇○●◈◉▶▷'
    for pass in 1 2 3; do
        echo -ne "\r   "
        for j in {1..32}; do
            echo -ne "${D}${glyphs:$((RANDOM % ${#glyphs})):1}${NC}"
        done
        sleep 0.07
    done
    echo -ne "\r$(printf '%40s')\r"
}

# ── progress bar ──────────────────────────────────────────────────────────────
_bar() {
    local label="$1" tag="$2"
    echo -ne "    ${D}[${NC}${AM}▸${NC}${D}]${NC} ${W}${label}${NC}"
    for j in 1 2 3; do echo -ne "${D}.${NC}"; sleep 0.05; done
    printf "  ${D}%-14s${NC}  ${G}✓${NC}\n" "$tag"
}

# ─────────────────────────────────────────────────────────────────────────────
clear
echo ""; echo ""; echo ""

# Phase 1 — glitch open
_glitch
sleep 0.15

# Phase 2 — gradient logo (amber→pink→violet, line by line)
echo ""
sleep 0.04; echo -e "    ${AM3}██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗${NC}"
sleep 0.04; echo -e "    ${AM}██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔══██╗${NC}"
sleep 0.04; echo -e "    ${AM2}██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║███████║██║  ██║${NC}"
sleep 0.04; echo -e "    ${PK}██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║██╔══██║██║  ██║${NC}"
sleep 0.04; echo -e "    ${PK2}██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝██║  ██║██████╔╝${NC}"
sleep 0.04; echo -e "    ${VL}╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝${NC}"
echo ""
echo -e "    ${D}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""

# Phase 3 — typewriter tagline
printf "    "
_tw "Your AI. Your Hardware. Your Rules." 0.04 "${AM}"
echo ""
printf "    "
_tw "Build without limits. Ship without compromise." 0.025 "${D}"
echo ""
echo -e "    ${D}─────────────────────────────────────────────────────────────────────────${NC}"
echo ""
sleep 0.3

# Phase 4 — boot checklist
_bar "Initializing runtime"          "kernel"
_bar "Loading memory journals"       "PS-SHA∞"
_bar "Starting agent mesh"           "30K agents"
_bar "Waking LUCIDIA"                "philosopher"
_bar "Waking ALICE"                  "executor"
_bar "Waking OCTAVIA"                "operator"
_bar "Waking PRISM"                  "analyst"
_bar "Waking ECHO"                   "librarian"
_bar "Waking CIPHER"                 "guardian"
_bar "Connecting AI stack"           "Ollama·Claude"
_bar "Mounting vector store"         "Qdrant"
_bar "Starting API gateway"          "port 8787"
_bar "Verifying PS-SHA∞ chain"       "intact"
echo ""

# Phase 5 — agent roster line
echo -e "    ${RD}●${NC} ${D}LUCIDIA${NC}   ${CY}●${NC} ${D}ALICE${NC}   ${G}●${NC} ${D}OCTAVIA${NC}   ${YL}●${NC} ${D}PRISM${NC}   ${PU}●${NC} ${D}ECHO${NC}   ${BL}●${NC} ${D}CIPHER${NC}"
echo ""
echo -e "    ${PK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Phase 6 — marketing copy typewriter reveal
for line in \
    "Tokenless. Trustless. Yours." \
    "30,000 agents. One command." \
    "Intelligence at the edge." \
    "Open source soul. Sovereign stack."
do
    printf "    "
    _tw "$line" 0.03 "${D}"
    sleep 0.04
done

echo ""
echo -ne "    ${AM}◆${NC} ${W}BLACKROAD OS${NC}  "
_tw "is ready." 0.06 "${G}"
echo ""
sleep 0.6

tput cnorm 2>/dev/null

# Launch hub unless --no-hub passed
if [[ "$1" != "--no-hub" ]] && [[ -f "${SCRIPT_DIR}/hub.sh" ]]; then
    exec bash "${SCRIPT_DIR}/hub.sh"
fi
