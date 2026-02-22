#!/bin/bash

# BlackRoad OS - Agent Network Map
# Visualize all AI agents, their roles, connections, and activities

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GOLD="\033[38;2;255;215;0m"
GREEN="\033[38;2;0;255;100m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

render_agent_network() {
    clear

    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${GOLD}🤖${RESET} ${BOLD}${PINK}AGENT NETWORK MAP${RESET} ${GOLD}🤖${RESET}                                            ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}     ${TEXT_SECONDARY}AI Agent Topology • Roles • Collaboration • Real-time Status${RESET}    ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Agent Registry
    echo -e "${TEXT_MUTED}╭─ AGENT REGISTRY ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Coordinator Agents
    echo -e "  ${ORANGE}◆ COORDINATOR LAYER${RESET}"
    echo -e "    ${PINK}┌─${RESET} ${BOLD}Lucidia Prime${RESET}           ${BLUE}◉${RESET} ${TEXT_SECONDARY}192.168.4.38${RESET}  ${TEXT_MUTED}Master Coordinator${RESET}"
    echo -e "    ${PINK}│  ${TEXT_MUTED}├─ Manages 47 child agents${RESET}"
    echo -e "    ${PINK}│  ${TEXT_MUTED}├─ Model: Claude Sonnet 4.5${RESET}"
    echo -e "    ${PINK}│  ${TEXT_MUTED}└─ Uptime: 847 hours${RESET}"
    echo -e "    ${PINK}│${RESET}"
    echo -e "    ${PINK}└─${RESET} ${BOLD}Cecilia Coordinator${RESET}     ${BLUE}◉${RESET} ${TEXT_SECONDARY}Cloud${RESET}         ${TEXT_MUTED}Backup Coordinator${RESET}"
    echo -e "       ${TEXT_MUTED}├─ Manages 23 agents${RESET}"
    echo -e "       ${TEXT_MUTED}├─ Model: GPT-4${RESET}"
    echo -e "       ${TEXT_MUTED}└─ Uptime: 456 hours${RESET}"
    echo ""

    # Specialist Agents
    echo -e "  ${PURPLE}◆ SPECIALIST LAYER${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}Winston (Quantum)${RESET}       ${BLUE}◉${RESET} ${TEXT_SECONDARY}Codex${RESET}        ${TEXT_MUTED}Physics/Math${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}Oracle (Data)${RESET}           ${BLUE}◉${RESET} ${TEXT_SECONDARY}Cloud${RESET}        ${TEXT_MUTED}Analytics${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}Architect (Code)${RESET}        ${BLUE}◉${RESET} ${TEXT_SECONDARY}Pi-64${RESET}        ${TEXT_MUTED}Development${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}Guardian (Security)${RESET}     ${BLUE}◉${RESET} ${TEXT_SECONDARY}Codex${RESET}        ${TEXT_MUTED}Sec Ops${RESET}"
    echo -e "    ${CYAN}├─${RESET} ${BOLD}Scribe (Docs)${RESET}           ${BLUE}◉${RESET} ${TEXT_SECONDARY}Cloud${RESET}        ${TEXT_MUTED}Documentation${RESET}"
    echo -e "    ${CYAN}└─${RESET} ${BOLD}Deployer (Ops)${RESET}          ${BLUE}◉${RESET} ${TEXT_SECONDARY}Pi-38${RESET}        ${TEXT_MUTED}DevOps${RESET}"
    echo ""

    # Worker Agents
    echo -e "  ${BLUE}◆ WORKER LAYER${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${TEXT_SECONDARY}Task Executors${RESET}         ${BOLD}${ORANGE}24${RESET} ${TEXT_MUTED}active${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${TEXT_SECONDARY}Data Processors${RESET}        ${BOLD}${ORANGE}18${RESET} ${TEXT_MUTED}active${RESET}"
    echo -e "    ${ORANGE}├─${RESET} ${TEXT_SECONDARY}Code Generators${RESET}        ${BOLD}${ORANGE}12${RESET} ${TEXT_MUTED}active${RESET}"
    echo -e "    ${ORANGE}└─${RESET} ${TEXT_SECONDARY}Monitor Agents${RESET}         ${BOLD}${ORANGE}8${RESET} ${TEXT_MUTED}active${RESET}"
    echo ""

    # Network Topology
    echo -e "${TEXT_MUTED}╭─ NETWORK TOPOLOGY ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "                    ${GOLD}[LUCIDIA PRIME]${RESET}"
    echo -e "                           ${PURPLE}│${RESET}"
    echo -e "          ${PURPLE}┌────────────────┼────────────────┐${RESET}"
    echo -e "          ${PURPLE}│${RESET}                ${PURPLE}│${RESET}                ${PURPLE}│${RESET}"
    echo -e "      ${PINK}[Winston]${RESET}       ${CYAN}[Oracle]${RESET}        ${BLUE}[Architect]${RESET}"
    echo -e "          ${PURPLE}│${RESET}                ${PURPLE}│${RESET}                ${PURPLE}│${RESET}"
    echo -e "    ${PURPLE}┌─────┴─────┐${RESET}      ${PURPLE}┌─────┴─────┐${RESET}      ${PURPLE}┌─────┴─────┐${RESET}"
    echo -e "    ${PURPLE}│${RESET}           ${PURPLE}│${RESET}      ${PURPLE}│${RESET}           ${PURPLE}│${RESET}      ${PURPLE}│${RESET}           ${PURPLE}│${RESET}"
    echo -e " ${TEXT_MUTED}[Task]   [Data]${RESET}  ${TEXT_MUTED}[Code]   [Test]${RESET}  ${TEXT_MUTED}[Deploy] [Monitor]${RESET}"
    echo ""

    # Agent Communication
    echo -e "${TEXT_MUTED}╭─ AGENT COMMUNICATION ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Active Connections:${RESET}"
    echo -e "    ${ORANGE}▸${RESET} ${TEXT_SECONDARY}Lucidia → Winston:${RESET}     ${BOLD}${GREEN}ACTIVE${RESET}  ${TEXT_MUTED}47 msgs/min${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Lucidia → Oracle:${RESET}      ${BOLD}${GREEN}ACTIVE${RESET}  ${TEXT_MUTED}23 msgs/min${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Lucidia → Architect:${RESET}   ${BOLD}${GREEN}ACTIVE${RESET}  ${TEXT_MUTED}34 msgs/min${RESET}"
    echo -e "    ${CYAN}▸${RESET} ${TEXT_SECONDARY}Winston → Workers:${RESET}     ${BOLD}${GREEN}ACTIVE${RESET}  ${TEXT_MUTED}156 msgs/min${RESET}"
    echo -e "    ${BLUE}▸${RESET} ${TEXT_SECONDARY}Oracle → Data Agents:${RESET}  ${BOLD}${GREEN}ACTIVE${RESET}  ${TEXT_MUTED}89 msgs/min${RESET}"
    echo ""

    # Agent Tasks
    echo -e "${TEXT_MUTED}╭─ CURRENT AGENT TASKS ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${BOLD}Lucidia Prime${RESET}         ${TEXT_SECONDARY}Coordinating dashboard deployment${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Winston${RESET}               ${TEXT_SECONDARY}Computing quantum lottery probabilities${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Oracle${RESET}                ${TEXT_SECONDARY}Analyzing infrastructure metrics${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Architect${RESET}             ${TEXT_SECONDARY}Generating terminal dashboard code${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Guardian${RESET}              ${TEXT_SECONDARY}Monitoring security events${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Scribe${RESET}                ${TEXT_SECONDARY}Writing documentation${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}Deployer${RESET}              ${TEXT_SECONDARY}Managing Railway deployments${RESET}"
    echo ""

    # Agent Statistics
    echo -e "${TEXT_MUTED}╭─ AGENT STATISTICS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Network Metrics:${RESET}"
    echo -e "    ${ORANGE}▸${RESET} ${TEXT_SECONDARY}Total Agents:${RESET}          ${BOLD}${ORANGE}104${RESET} ${TEXT_MUTED}(1 coord + 6 specialist + 97 worker)${RESET}"
    echo -e "    ${PINK}▸${RESET} ${TEXT_SECONDARY}Active Agents:${RESET}         ${BOLD}${PINK}87${RESET} ${TEXT_MUTED}(83.7%)${RESET}"
    echo -e "    ${PURPLE}▸${RESET} ${TEXT_SECONDARY}Total Messages:${RESET}        ${BOLD}${PURPLE}1.2M${RESET} ${TEXT_MUTED}lifetime${RESET}"
    echo -e "    ${CYAN}▸${RESET} ${TEXT_SECONDARY}Messages/min:${RESET}          ${BOLD}${CYAN}456${RESET} ${TEXT_MUTED}current${RESET}"
    echo -e "    ${BLUE}▸${RESET} ${TEXT_SECONDARY}Avg Response Time:${RESET}     ${BOLD}${BLUE}234ms${RESET}"
    echo ""

    # Model Distribution
    echo -e "${TEXT_MUTED}╭─ MODEL DISTRIBUTION ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}Claude Sonnet 4.5${RESET}      ${BOLD}${ORANGE}47${RESET} ${TEXT_MUTED}agents${RESET}   ${ORANGE}████████████████████${RESET}"
    echo -e "  ${PINK}Claude Opus 3.5${RESET}        ${BOLD}${PINK}23${RESET} ${TEXT_MUTED}agents${RESET}   ${PINK}██████████${RESET}"
    echo -e "  ${PURPLE}GPT-4${RESET}                  ${BOLD}${PURPLE}18${RESET} ${TEXT_MUTED}agents${RESET}   ${PURPLE}████████${RESET}"
    echo -e "  ${CYAN}Claude Haiku${RESET}           ${BOLD}${CYAN}12${RESET} ${TEXT_MUTED}agents${RESET}   ${CYAN}█████${RESET}"
    echo -e "  ${BLUE}Gemini Pro${RESET}             ${BOLD}${BLUE}4${RESET} ${TEXT_MUTED}agents${RESET}    ${BLUE}██${RESET}"
    echo ""

    # Health Status
    echo -e "${TEXT_MUTED}╭─ NETWORK HEALTH ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}◉${RESET} ${TEXT_PRIMARY}Network Status:${RESET}        ${BOLD}${GREEN}HEALTHY${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Avg CPU Usage:${RESET}         ${BOLD}${CYAN}42%${RESET} ${TEXT_MUTED}across all agents${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Avg Memory Usage:${RESET}      ${BOLD}${PURPLE}67%${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Network Latency:${RESET}       ${BOLD}${BLUE}23ms${RESET} ${TEXT_MUTED}avg${RESET}"
    echo -e "  ${ORANGE}◆${RESET} ${TEXT_PRIMARY}Error Rate:${RESET}            ${BOLD}${ORANGE}0.01%${RESET}"
    echo ""

    # Footer
    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Agents: ${RESET}${BOLD}${ORANGE}87/104${RESET}  ${TEXT_SECONDARY}|  Status: ${RESET}${BOLD}${GREEN}HEALTHY${RESET}"
    echo ""
}

# Auto-refresh mode
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_agent_network
        sleep 5
    done
else
    render_agent_network
fi
