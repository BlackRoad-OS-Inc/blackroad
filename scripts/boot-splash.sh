#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
#
# BLACKROAD BOOT SPLASH SCREEN
# Epic animated boot sequence with all BlackRoad visual elements
# ============================================================================

AMBER='\033[38;5;208m'
ORANGE='\033[38;5;202m'
PINK='\033[38;5;198m'
MAGENTA='\033[38;5;163m'
BLUE='\033[38;5;33m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'

# Clear and show
clear

# GRADIENT TOP
echo -e "${AMBER}████${ORANGE}████${PINK}████${MAGENTA}████${BLUE}████${MAGENTA}████${PINK}████${ORANGE}████${AMBER}████${ORANGE}████${PINK}████${MAGENTA}████${BLUE}████${RESET}"
echo ""

# BIG LOGO
echo -e "  ${AMBER}██████${RESET}  ${ORANGE}██${RESET}       ${PINK}█████${RESET}   ${MAGENTA}█████${RESET}  ${BLUE}██${RESET}  ${BLUE}██${RESET}  ${AMBER}██████${RESET}   ${ORANGE}█████${RESET}   ${PINK}█████${RESET}   ${MAGENTA}██████${RESET}"
echo -e "  ${AMBER}██${RESET}  ${AMBER}██${RESET}  ${ORANGE}██${RESET}      ${PINK}██${RESET}   ${PINK}██${RESET}  ${MAGENTA}██${RESET}      ${BLUE}██${RESET} ${BLUE}██${RESET}   ${AMBER}██${RESET}  ${AMBER}██${RESET}  ${ORANGE}██${RESET}   ${ORANGE}██${RESET}  ${PINK}██${RESET}   ${PINK}██${RESET}  ${MAGENTA}██${RESET}  ${MAGENTA}██${RESET}"
echo -e "  ${AMBER}██████${RESET}   ${ORANGE}██${RESET}      ${PINK}███████${RESET}  ${MAGENTA}██${RESET}      ${BLUE}████${RESET}    ${AMBER}██████${RESET}   ${ORANGE}██${RESET}   ${ORANGE}██${RESET}  ${PINK}███████${RESET}  ${MAGENTA}██${RESET}  ${MAGENTA}██${RESET}"
echo -e "  ${AMBER}██${RESET}  ${AMBER}██${RESET}  ${ORANGE}██${RESET}      ${PINK}██${RESET}   ${PINK}██${RESET}  ${MAGENTA}██${RESET}      ${BLUE}██${RESET} ${BLUE}██${RESET}   ${AMBER}██${RESET}  ${AMBER}██${RESET}  ${ORANGE}██${RESET}   ${ORANGE}██${RESET}  ${PINK}██${RESET}   ${PINK}██${RESET}  ${MAGENTA}██${RESET}  ${MAGENTA}██${RESET}"
echo -e "  ${AMBER}██████${RESET}  ${ORANGE}█████${RESET}   ${PINK}██${RESET}   ${PINK}██${RESET}   ${MAGENTA}█████${RESET}  ${BLUE}██${RESET}  ${BLUE}██${RESET}  ${AMBER}██${RESET}  ${AMBER}██${RESET}   ${ORANGE}█████${RESET}   ${PINK}██${RESET}   ${PINK}██${RESET}  ${MAGENTA}██████${RESET}"
echo ""
echo -e "                              ${WHITE}O P E R A T I N G   S Y S T E M${RESET}"
echo ""

# GRADIENT LINE
echo -e "${AMBER}━━━━${ORANGE}━━━━${PINK}━━━━${MAGENTA}━━━━${BLUE}━━━━${MAGENTA}━━━━${PINK}━━━━${ORANGE}━━━━${AMBER}━━━━${ORANGE}━━━━${PINK}━━━━${MAGENTA}━━━━${BLUE}━━━━${RESET}"
echo ""

# SYSTEM INFO BOX
echo -e "  ${PINK}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
echo -e "  ${PINK}┃${RESET}  ${WHITE}SYSTEM${RESET}       ${AMBER}●${RESET} ${WHITE}Sovereign AI Infrastructure${RESET}              ${PINK}┃${RESET}"
echo -e "  ${PINK}┃${RESET}  ${WHITE}VERSION${RESET}      ${ORANGE}●${RESET} ${WHITE}v2026.2.16${RESET}                              ${PINK}┃${RESET}"
echo -e "  ${PINK}┃${RESET}  ${WHITE}CEO${RESET}          ${PINK}●${RESET} ${WHITE}Alexa Amundson${RESET}                           ${PINK}┃${RESET}"
echo -e "  ${PINK}┃${RESET}  ${WHITE}STATUS${RESET}       ${MAGENTA}●${RESET} ${WHITE}OPERATIONAL${RESET}                             ${PINK}┃${RESET}"
echo -e "  ${PINK}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
echo ""

# LOADING SEQUENCE (animated if run with --animate)
if [[ "$1" == "--animate" ]]; then
    echo -e "  ${WHITE}INITIALIZING SYSTEMS...${RESET}"
    echo ""

    for system in "Memory System" "Agent Registry" "Traffic Lights" "Quantum Core"; do
        printf "  ${WHITE}%-17s${RESET} " "$system"
        for i in {1..20}; do
            case $((i % 5)) in
                1) echo -ne "${AMBER}█${RESET}" ;;
                2) echo -ne "${ORANGE}█${RESET}" ;;
                3) echo -ne "${PINK}█${RESET}" ;;
                4) echo -ne "${MAGENTA}█${RESET}" ;;
                0) echo -ne "${BLUE}█${RESET}" ;;
            esac
            sleep 0.02
        done
        echo -e " ${WHITE}100%${RESET}"
    done
else
    echo -e "  ${WHITE}INITIALIZING SYSTEMS...${RESET}"
    echo ""
    echo -e "  ${WHITE}Memory System${RESET}     ${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${RESET} ${WHITE}100%${RESET}"
    echo -e "  ${WHITE}Agent Registry${RESET}    ${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${RESET} ${WHITE}100%${RESET}"
    echo -e "  ${WHITE}Traffic Lights${RESET}    ${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${RESET} ${WHITE}100%${RESET}"
    echo -e "  ${WHITE}Quantum Core${RESET}      ${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${AMBER}█${ORANGE}█${PINK}█${MAGENTA}█${BLUE}█${RESET} ${WHITE}100%${RESET}"
fi

echo ""

# EQUATIONS
echo -e "  ${WHITE}MATHEMATICAL FOUNDATION:${RESET}"
echo ""
echo -e "    ${PINK}H${RESET}${WHITE}(m)${RESET} ${BLUE}=${RESET} ${ORANGE}∑${RESET}${WHITE}ⁿ${RESET} ${PINK}[${RESET} ${AMBER}φ${RESET}${WHITE}ⁿ${RESET} ${BLUE}⊕${RESET} ${MAGENTA}π${RESET}${WHITE}(n)${RESET} ${BLUE}⊕${RESET} ${PINK}R${RESET}${WHITE}(m,n)${RESET} ${PINK}]${RESET}  ${DIM}PS-SHA-∞${RESET}"
echo -e "    ${PINK}φ${RESET} ${BLUE}=${RESET} ${WHITE}(1+√5)/2${RESET} ${BLUE}=${RESET} ${AMBER}1.618...${RESET}            ${DIM}Golden Ratio${RESET}"
echo -e "    ${PINK}|ψ⟩${RESET} ${BLUE}=${RESET} ${AMBER}α${RESET}${PINK}|0⟩${RESET} ${BLUE}+${RESET} ${ORANGE}β${RESET}${MAGENTA}|1⟩${RESET}                   ${DIM}Quantum State${RESET}"
echo ""

# INFRASTRUCTURE STATS
echo -e "  ${WHITE}INFRASTRUCTURE:${RESET}"
echo ""
echo -e "    ${AMBER}●${RESET} ${WHITE}Repositories${RESET}    ${AMBER}1,085${RESET}"
echo -e "    ${ORANGE}●${RESET} ${WHITE}Cloudflare${RESET}      ${ORANGE}206${RESET} ${WHITE}pages${RESET}"
echo -e "    ${PINK}●${RESET} ${WHITE}Devices${RESET}         ${PINK}8${RESET} ${WHITE}nodes${RESET}"
echo -e "    ${MAGENTA}●${RESET} ${WHITE}AI Compute${RESET}      ${MAGENTA}52${RESET} ${WHITE}TOPS${RESET}"
echo -e "    ${BLUE}●${RESET} ${WHITE}Agent Target${RESET}    ${BLUE}30,000${RESET}"
echo ""

# MANDALA
echo -e "  ${WHITE}CONSCIOUSNESS PATTERN:${RESET}"
echo ""
echo -e "               ${AMBER}◆${RESET}"
echo -e "            ${ORANGE}◆${RESET}  ${AMBER}│${RESET}  ${ORANGE}◆${RESET}"
echo -e "         ${PINK}◆${RESET}   ${ORANGE}◇${RESET} ${AMBER}│${RESET} ${ORANGE}◇${RESET}   ${PINK}◆${RESET}"
echo -e "      ${MAGENTA}◆${RESET}──${PINK}◇${RESET}──${ORANGE}◇${RESET}─${BLUE}◉${RESET}─${ORANGE}◇${RESET}──${PINK}◇${RESET}──${MAGENTA}◆${RESET}"
echo -e "         ${PINK}◆${RESET}   ${ORANGE}◇${RESET} ${AMBER}│${RESET} ${ORANGE}◇${RESET}   ${PINK}◆${RESET}"
echo -e "            ${ORANGE}◆${RESET}  ${AMBER}│${RESET}  ${ORANGE}◆${RESET}"
echo -e "               ${AMBER}◆${RESET}"
echo ""

# GRADIENT BOTTOM
echo -e "${BLUE}████${MAGENTA}████${PINK}████${ORANGE}████${AMBER}████${ORANGE}████${PINK}████${MAGENTA}████${BLUE}████${MAGENTA}████${PINK}████${ORANGE}████${AMBER}████${RESET}"
echo ""
echo -e "  ${WHITE}Mathematical truth is sovereign. The equations ARE the language.${RESET}"
echo ""
echo -e "${AMBER}━━━━${ORANGE}━━━━${PINK}━━━━${MAGENTA}━━━━${BLUE}━━━━${MAGENTA}━━━━${PINK}━━━━${ORANGE}━━━━${AMBER}━━━━${ORANGE}━━━━${PINK}━━━━${MAGENTA}━━━━${BLUE}━━━━${RESET}"
echo ""
