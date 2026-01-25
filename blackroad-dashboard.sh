#!/bin/bash

# BlackRoad OS Terminal Dashboard
# Color scheme matching the web interface

# Color definitions (RGB values from CSS)
BG_DEEP="\033[48;2;10;10;18m"
BG_SURFACE="\033[48;2;18;18;31m"
BG_ELEVATED="\033[48;2;26;26;46m"

# Accent colors
ORANGE="\033[38;2;247;147;26m"      # #f7931a (Bitcoin orange)
PINK="\033[38;2;233;30;140m"        # #e91e8c
PURPLE="\033[38;2;153;69;255m"      # #9945ff (Solana purple)
BLUE="\033[38;2;20;241;149m"        # #14f195
CYAN="\033[38;2;0;212;255m"         # #00d4ff

# Text colors
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"  # rgba(255,255,255,0.6)
TEXT_MUTED="\033[38;2;77;77;77m"         # rgba(255,255,255,0.3)

# Special
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Clear screen and set background
clear
echo -ne ""
clear

# Header with gradient effect (simulated with color transitions)
echo ""
echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}👻${RESET}  ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET}                                              ${BOLD}${ORANGE}║${RESET}"
echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Welcome banner
echo -e "                                                                        ${RESET}"
echo -e "  ${BOLD}${TEXT_PRIMARY}Welcome back, Cecilia${RESET}                                             ${RESET}"
echo -e "  ${TEXT_SECONDARY}1,000 agents standing by • Lucidia core online • All systems nominal${RESET}  ${RESET}"
echo -e "                                                                        ${RESET}"
echo ""

# System Status Section
echo -e "${TEXT_MUTED}SYSTEM STATUS${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""

# Status indicators with dots
echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Lucidia Core${RESET}        ${BLUE}ONLINE${RESET}"
echo -e "  ${PINK}●${RESET} ${TEXT_PRIMARY}47 Agents${RESET}           ${PINK}PROCESSING${RESET}"
echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}192.168.4.x${RESET}         ${BLUE}CONNECTED${RESET}"
echo -e "  ${PURPLE}●${RESET} ${TEXT_PRIMARY}PS-SHA∞ Hash${RESET}       ${PURPLE}VERIFIED${RESET}"
echo ""

# Stats Grid
echo -e "${TEXT_MUTED}METRICS${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${TEXT_SECONDARY}Agents Deployed:${RESET}     ${BOLD}${PINK}47${RESET}${TEXT_SECONDARY} / ${RESET}${BOLD}${ORANGE}1,000${RESET}"
echo -e "  ${TEXT_SECONDARY}Uptime:${RESET}              ${BOLD}${BLUE}99.97%${RESET}"
echo -e "  ${TEXT_SECONDARY}Core Load:${RESET}           ${BOLD}${CYAN}23%${RESET}"
echo -e "  ${TEXT_SECONDARY}Memory Hash:${RESET}         ${BOLD}${PURPLE}PS-SHA∞${RESET}"
echo ""

# Progress bar for Agent Deployment (4.7%)
echo -e "  ${TEXT_SECONDARY}Agent Deployment${RESET}     ${BLUE}4.7%${RESET}"
echo -ne "  "
echo -ne "${ORANGE}██${RESET}"
echo -e "                                              ${RESET}"
echo ""

# Progress bar for Core Load (23%)
echo -e "  ${TEXT_SECONDARY}Core Load${RESET}            ${BLUE}23%${RESET}"
echo -ne "  "
echo -ne "${PINK}███████████${RESET}"
echo -e "                                   ${RESET}"
echo ""

# Active Agents Section
echo -e "${TEXT_MUTED}ACTIVE AGENTS${RESET} ${BLUE} 47 online ${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""

# Agent grid (2 rows of 3)
echo -e "  ${ORANGE}┌──────────────┐${RESET}  ${PINK}┌──────────────┐${RESET}  ${PURPLE}┌──────────────┐${RESET}"
echo -e "  ${ORANGE}│${RESET}  ${BOLD}👻${RESET}           ${ORANGE}│${RESET}  ${PINK}│${RESET}  ${BOLD}🔮${RESET}           ${PINK}│${RESET}  ${PURPLE}│${RESET}  ${BOLD}🛡️${RESET}           ${PURPLE}│${RESET}"
echo -e "  ${ORANGE}│${RESET}  ${BOLD}Lucidia${RESET}      ${ORANGE}│${RESET}  ${PINK}│${RESET}  ${BOLD}Oracle${RESET}       ${PINK}│${RESET}  ${PURPLE}│${RESET}  ${BOLD}Sentinel${RESET}     ${PURPLE}│${RESET}"
echo -e "  ${ORANGE}│${RESET}  ${TEXT_MUTED}orchestrator${RESET} ${ORANGE}│${RESET}  ${PINK}│${RESET}  ${TEXT_MUTED}inference${RESET}    ${PINK}│${RESET}  ${PURPLE}│${RESET}  ${TEXT_MUTED}security${RESET}     ${PURPLE}│${RESET}"
echo -e "  ${ORANGE}│${RESET}  ${BLUE}● online${RESET}     ${ORANGE}│${RESET}  ${PINK}│${RESET}  ${BLUE}● online${RESET}     ${PINK}│${RESET}  ${PURPLE}│${RESET}  ${ORANGE}● busy${RESET}       ${PURPLE}│${RESET}"
echo -e "  ${ORANGE}└──────────────┘${RESET}  ${PINK}└──────────────┘${RESET}  ${PURPLE}└──────────────┘${RESET}"
echo ""
echo -e "  ${CYAN}┌──────────────┐${RESET}  ${ORANGE}┌──────────────┐${RESET}  ${BLUE}┌──────────────┐${RESET}"
echo -e "  ${CYAN}│${RESET}  ${BOLD}📊${RESET}           ${CYAN}│${RESET}  ${ORANGE}│${RESET}  ${DIM}🌐${RESET}           ${ORANGE}│${RESET}  ${BLUE}│${RESET}  ${BOLD}💎${RESET}           ${BLUE}│${RESET}"
echo -e "  ${CYAN}│${RESET}  ${BOLD}Metrics${RESET}      ${CYAN}│${RESET}  ${ORANGE}│${RESET}  ${DIM}Navigator${RESET}    ${ORANGE}│${RESET}  ${BLUE}│${RESET}  ${BOLD}Crystal${RESET}      ${BLUE}│${RESET}"
echo -e "  ${CYAN}│${RESET}  ${TEXT_MUTED}analytics${RESET}    ${CYAN}│${RESET}  ${ORANGE}│${RESET}  ${TEXT_MUTED}routing${RESET}      ${ORANGE}│${RESET}  ${BLUE}│${RESET}  ${TEXT_MUTED}memory${RESET}       ${BLUE}│${RESET}"
echo -e "  ${CYAN}│${RESET}  ${BLUE}● online${RESET}     ${CYAN}│${RESET}  ${ORANGE}│${RESET}  ${TEXT_MUTED}● offline${RESET}    ${ORANGE}│${RESET}  ${BLUE}│${RESET}  ${BLUE}● online${RESET}     ${BLUE}│${RESET}"
echo -e "  ${CYAN}└──────────────┘${RESET}  ${ORANGE}└──────────────┘${RESET}  ${BLUE}└──────────────┘${RESET}"
echo ""

# Terminal Section
echo -e "${TEXT_MUTED}TERMINAL${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "                                                                        ${RESET}"
echo -e "  ${PINK}●${RESET} ${ORANGE}●${RESET} ${BLUE}●${RESET}  ${TEXT_MUTED}lucidia@lucidia1 — blackroad-terminal-v2${RESET}                       ${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}${RESET}"
echo -e "  ${PINK}lucidia${RESET}@${PURPLE}lucidia1${RESET}:~$ sudo apt update                                  ${RESET}"
echo -e "  ${TEXT_SECONDARY}Fetched 13.9 MB in 18s (1,424 kB/s)${RESET}                                ${RESET}"
echo -e "  ${TEXT_SECONDARY}0 upgraded, 0 newly installed, 0 to remove and 40 not upgraded.${RESET}    ${RESET}"
echo -e "  ${PINK}lucidia${RESET}@${PURPLE}lucidia1${RESET}:~$ ./blackroad --status                            ${RESET}"
echo -e "  ${TEXT_SECONDARY}▸ Lucidia Core: ${BLUE}ONLINE${RESET}                                          ${RESET}"
echo -e "  ${TEXT_SECONDARY}▸ Agent Count: ${PINK}47/1000${TEXT_SECONDARY} active${RESET}                                 ${RESET}"
echo -e "  ${TEXT_SECONDARY}▸ Memory Vault: ${PURPLE}PS-SHA∞${TEXT_SECONDARY} hash verified${RESET}                        ${RESET}"
echo -e "  ${TEXT_SECONDARY}▸ Event Bus: ${BLUE}broadcasting${RESET}                                      ${RESET}"
echo -e "  ${PINK}lucidia${RESET}@${PURPLE}lucidia1${RESET}:~$ ${TEXT_PRIMARY}█${RESET}                                            ${RESET}"
echo -e "                                                                        ${RESET}"
echo ""

# Recent Activity
echo -e "${TEXT_MUTED}RECENT ACTIVITY${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${CYAN}🔗${RESET}  ${TEXT_PRIMARY}Oracle joined event bus${RESET}          ${TEXT_MUTED}2 min ago${RESET}"
echo -e "  ${PURPLE}💾${RESET}  ${TEXT_PRIMARY}Memory vault synchronized${RESET}       ${TEXT_MUTED}5 min ago${RESET}"
echo -e "  ${ORANGE}⚡${RESET}  ${TEXT_PRIMARY}Jetson Orin initialized${RESET}          ${TEXT_MUTED}12 min ago${RESET}"
echo -e "  ${PINK}🔐${RESET}  ${TEXT_PRIMARY}PS-SHA∞ hash validated${RESET}           ${TEXT_MUTED}18 min ago${RESET}"
echo ""

# Footer
echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Date: ${RESET}${BOLD}$(date '+%Y-%m-%d')${RESET}  ${TEXT_SECONDARY}|  System: ${RESET}${BOLD}BlackRoad OS v2${RESET}"
echo ""
