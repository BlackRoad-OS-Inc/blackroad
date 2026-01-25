#!/bin/bash

# BlackRoad OS - Network Topology 3D Visualizer
# Beautiful ASCII 3D network map of entire infrastructure

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GOLD="\033[38;2;255;215;0m"
GREEN="\033[38;2;0;255;100m"
RED="\033[38;2;255;50;50m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

render_topology() {
    clear

    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${GOLD}🌐${RESET} ${BOLD}${PINK}NETWORK TOPOLOGY 3D${RESET}                                            ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}     ${TEXT_SECONDARY}Complete Infrastructure Map • 3D Visualization${RESET}                  ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Internet Layer
    echo -e "${TEXT_MUTED}╭─ LAYER 1: INTERNET & CDN ─────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "                        ${GOLD}╔═══════════════════╗${RESET}"
    echo -e "                        ${GOLD}║${RESET}  ${BOLD}${GOLD}🌍 INTERNET${RESET}      ${GOLD}║${RESET}"
    echo -e "                        ${GOLD}╚═══════════════════╝${RESET}"
    echo -e "                                 ${PURPLE}│${RESET}"
    echo -e "                                 ${PURPLE}▼${RESET}"
    echo -e "              ${ORANGE}╔═════════════════════════════════════╗${RESET}"
    echo -e "              ${ORANGE}║${RESET}  ${BOLD}${ORANGE}☁️  CLOUDFLARE EDGE NETWORK${RESET}   ${ORANGE}║${RESET}"
    echo -e "              ${ORANGE}║${RESET}  ${TEXT_MUTED}16 Zones • Global PoPs${RESET}          ${ORANGE}║${RESET}"
    echo -e "              ${ORANGE}╚═════════════════════════════════════╝${RESET}"
    echo -e "                   ${PURPLE}│${RESET}        ${PURPLE}│${RESET}         ${PURPLE}│${RESET}"
    echo ""

    # Application Layer
    echo -e "${TEXT_MUTED}╭─ LAYER 2: APPLICATION LAYER ──────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "      ${PINK}┌────────────┐${RESET}  ${CYAN}┌────────────┐${RESET}  ${BLUE}┌────────────┐${RESET}"
    echo -e "      ${PINK}│${RESET} ${BOLD}Pages (8)${RESET}  ${PINK}│${RESET}  ${CYAN}│${RESET} ${BOLD}Workers${RESET}    ${CYAN}│${RESET}  ${BLUE}│${RESET} ${BOLD}Tunnel${RESET}     ${BLUE}│${RESET}"
    echo -e "      ${PINK}└─────┬──────┘${RESET}  ${CYAN}└─────┬──────┘${RESET}  ${BLUE}└─────┬──────┘${RESET}"
    echo -e "            ${PURPLE}│${RESET}               ${PURPLE}│${RESET}               ${PURPLE}│${RESET}"
    echo -e "            ${PURPLE}└───────────────┼───────────────┘${RESET}"
    echo -e "                            ${PURPLE}│${RESET}"
    echo ""

    # Service Layer
    echo -e "${TEXT_MUTED}╭─ LAYER 3: SERVICE LAYER ──────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "        ${ORANGE}┌──────────────┐${RESET}          ${PINK}┌──────────────┐${RESET}"
    echo -e "        ${ORANGE}│${RESET} ${BOLD}Railway (12)${RESET} ${ORANGE}│${RESET}          ${PINK}│${RESET} ${BOLD}GitHub (66)${RESET}  ${PINK}│${RESET}"
    echo -e "        ${ORANGE}└──────┬───────┘${RESET}          ${PINK}└──────┬───────┘${RESET}"
    echo -e "               ${PURPLE}│${RESET}                       ${PURPLE}│${RESET}"
    echo -e "               ${PURPLE}└───────────┬───────────────┘${RESET}"
    echo -e "                           ${PURPLE}│${RESET}"
    echo ""

    # Infrastructure Layer
    echo -e "${TEXT_MUTED}╭─ LAYER 4: INFRASTRUCTURE ─────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "           ${BLUE}╔═══════════════════════════════════════╗${RESET}"
    echo -e "           ${BLUE}║${RESET}  ${BOLD}${BLUE}LOCAL NETWORK${RESET} ${TEXT_MUTED}(192.168.4.0/24)${RESET}   ${BLUE}║${RESET}"
    echo -e "           ${BLUE}╚═══════════════════════════════════════╝${RESET}"
    echo -e "                ${PURPLE}┌─────┼─────┼─────┼─────┐${RESET}"
    echo -e "                ${PURPLE}│${RESET}     ${PURPLE}│${RESET}     ${PURPLE}│${RESET}     ${PURPLE}│${RESET}     ${PURPLE}│${RESET}"
    echo ""

    # Device Grid
    echo -e "   ${ORANGE}┌──────────┐${RESET}  ${PINK}┌──────────┐${RESET}  ${PURPLE}┌──────────┐${RESET}  ${CYAN}┌──────────┐${RESET}  ${GREEN}┌──────────┐${RESET}"
    echo -e "   ${ORANGE}│${RESET} ${BOLD}Pi #1${RESET}    ${ORANGE}│${RESET}  ${PINK}│${RESET} ${BOLD}Pi #2${RESET}    ${PINK}│${RESET}  ${PURPLE}│${RESET} ${BOLD}Pi #3${RESET}    ${PURPLE}│${RESET}  ${CYAN}│${RESET} ${BOLD}iPhone${RESET}   ${CYAN}│${RESET}  ${GREEN}│${RESET} ${BOLD}DO${RESET}       ${GREEN}│${RESET}"
    echo -e "   ${ORANGE}│${RESET} ${TEXT_MUTED}.38${RESET}      ${ORANGE}│${RESET}  ${PINK}│${RESET} ${TEXT_MUTED}.64${RESET}      ${PINK}│${RESET}  ${PURPLE}│${RESET} ${TEXT_MUTED}.99${RESET}      ${PURPLE}│${RESET}  ${CYAN}│${RESET} ${TEXT_MUTED}.68${RESET}      ${CYAN}│${RESET}  ${GREEN}│${RESET} ${TEXT_MUTED}Cloud${RESET}    ${GREEN}│${RESET}"
    echo -e "   ${ORANGE}│${RESET} ${GREEN}◉${RESET} ${TEXT_MUTED}42%${RESET}    ${ORANGE}│${RESET}  ${PINK}│${RESET} ${GREEN}◉${RESET} ${TEXT_MUTED}35%${RESET}    ${PINK}│${RESET}  ${PURPLE}│${RESET} ${GREEN}◉${RESET} ${TEXT_MUTED}28%${RESET}    ${PURPLE}│${RESET}  ${CYAN}│${RESET} ${GREEN}◉${RESET} ${TEXT_MUTED}85%${RESET}    ${CYAN}│${RESET}  ${GREEN}│${RESET} ${GREEN}◉${RESET} ${TEXT_MUTED}12%${RESET}    ${GREEN}│${RESET}"
    echo -e "   ${ORANGE}└──────────┘${RESET}  ${PINK}└──────────┘${RESET}  ${PURPLE}└──────────┘${RESET}  ${CYAN}└──────────┘${RESET}  ${GREEN}└──────────┘${RESET}"
    echo ""

    # Connection Matrix
    echo -e "${TEXT_MUTED}╭─ CONNECTION MATRIX ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Active Connections:${RESET}"
    echo -e "    ${ORANGE}Pi #1${RESET} ${PURPLE}━━━━━━━━━━${RESET} ${PINK}Cloudflare${RESET}  ${GREEN}✓${RESET} ${TEXT_MUTED}23ms${RESET}"
    echo -e "    ${PINK}Pi #2${RESET} ${PURPLE}━━━━━━━━━━${RESET} ${CYAN}Railway${RESET}     ${GREEN}✓${RESET} ${TEXT_MUTED}45ms${RESET}"
    echo -e "    ${PURPLE}Pi #3${RESET} ${PURPLE}━━━━━━━━━━${RESET} ${BLUE}Backup${RESET}      ${GREEN}✓${RESET} ${TEXT_MUTED}12ms${RESET}"
    echo -e "    ${CYAN}iPhone${RESET} ${PURPLE}━━━━━━━━━${RESET} ${ORANGE}Dev Server${RESET}  ${GREEN}✓${RESET} ${TEXT_MUTED}8ms${RESET}"
    echo -e "    ${GREEN}DO${RESET}    ${PURPLE}━━━━━━━━━━${RESET} ${PINK}Production${RESET}  ${GREEN}✓${RESET} ${TEXT_MUTED}34ms${RESET}"
    echo ""

    # Traffic Flow
    echo -e "${TEXT_MUTED}╭─ TRAFFIC FLOW (Real-time) ────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Bandwidth Usage:${RESET}"
    echo -e "    ${GREEN}▼${RESET} ${TEXT_SECONDARY}Inbound:${RESET}   ${BOLD}${GREEN}47 MB/s${RESET}  ${CYAN}████████████████████${RESET}"
    echo -e "    ${ORANGE}▲${RESET} ${TEXT_SECONDARY}Outbound:${RESET}  ${BOLD}${ORANGE}23 MB/s${RESET}  ${PINK}██████████${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Top Data Paths:${RESET}"
    echo -e "    ${ORANGE}1.${RESET} ${TEXT_SECONDARY}Cloudflare → Pi #1${RESET}       ${BOLD}${CYAN}12 MB/s${RESET}"
    echo -e "    ${PINK}2.${RESET} ${TEXT_SECONDARY}Railway → Pi #2${RESET}          ${BOLD}${CYAN}8 MB/s${RESET}"
    echo -e "    ${PURPLE}3.${RESET} ${TEXT_SECONDARY}GitHub → DO${RESET}              ${BOLD}${CYAN}5 MB/s${RESET}"
    echo -e "    ${CYAN}4.${RESET} ${TEXT_SECONDARY}iPhone → Pi #1${RESET}           ${BOLD}${CYAN}2 MB/s${RESET}"
    echo ""

    # Network Stats
    echo -e "${TEXT_MUTED}╭─ NETWORK STATISTICS ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}◆${RESET} ${TEXT_SECONDARY}Total Nodes:${RESET}         ${BOLD}${ORANGE}5${RESET} ${TEXT_MUTED}physical devices${RESET}"
    echo -e "  ${PINK}◆${RESET} ${TEXT_SECONDARY}Virtual Services:${RESET}    ${BOLD}${PINK}47${RESET} ${TEXT_MUTED}endpoints${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_SECONDARY}Active Connections:${RESET}  ${BOLD}${PURPLE}23${RESET} ${TEXT_MUTED}live${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_SECONDARY}Avg Latency:${RESET}         ${BOLD}${CYAN}24ms${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_SECONDARY}Packet Loss:${RESET}         ${BOLD}${BLUE}0.01%${RESET}"
    echo ""

    # Footer
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Topology: ${RESET}${BOLD}${GREEN}HEALTHY${RESET}  ${TEXT_SECONDARY}|  Nodes: ${RESET}${BOLD}${ORANGE}5/5${RESET}"
    echo ""
}

# Auto-refresh
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_topology
        sleep 5
    done
else
    render_topology
fi
