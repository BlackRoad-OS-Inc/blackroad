#!/bin/bash
#===============================================================================
# lib/colors.sh — BlackRoad brand colors + formatting (single source of truth)
#===============================================================================

# Brand colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'

# Standard colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Bright variants
BRED='\033[1;31m'
BGREEN='\033[1;32m'
BYELLOW='\033[1;33m'
BBLUE='\033[1;34m'
BPURPLE='\033[1;35m'
BCYAN='\033[1;36m'
BWHITE='\033[1;37m'

# Agent color map (works in both bash 4+ and zsh)
if [[ -n "$ZSH_VERSION" ]]; then
    typeset -A AGENT_COLOR_MAP
else
    declare -A AGENT_COLOR_MAP 2>/dev/null || true
fi
AGENT_COLOR_MAP=(
    [LUCIDIA]="$BRED"
    [ALICE]="$BCYAN"
    [OCTAVIA]="$BGREEN"
    [PRISM]="$BYELLOW"
    [ECHO]="$BPURPLE"
    [CIPHER]="$BBLUE"
    [lucidia]="$BRED"
    [alice]="$BCYAN"
    [octavia]="$BGREEN"
    [prism]="$BYELLOW"
    [echo]="$BPURPLE"
    [cipher]="$BBLUE"
)

# Agent names list
BR_AGENT_NAMES=(LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER)

#-------------------------------------------------------------------------------
# Helper functions
#-------------------------------------------------------------------------------
br_header() {
    local title="$1"
    echo -e "${PINK}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PINK}│${NC}  ${WHITE}${title}${NC}$(printf '%*s' $((62 - ${#title})) '')  ${PINK}│${NC}"
    echo -e "${PINK}└──────────────────────────────────────────────────────────────────┘${NC}"
}

br_ok() {
    echo -e "  ${BGREEN}✓${NC} $1"
}

br_err() {
    echo -e "  ${BRED}✗${NC} $1" >&2
}

br_warn() {
    echo -e "  ${BYELLOW}⚠${NC} $1"
}

br_info() {
    echo -e "  ${BCYAN}ℹ${NC} $1"
}

br_dim() {
    echo -e "  ${DIM}$1${NC}"
}

# Get color for an agent name
agent_color() {
    local name="${1^^}"
    echo "${AGENT_COLOR_MAP[$name]:-$NC}"
}
