#!/bin/bash

# BlackRoad OS - Complete Operating System
# A WHOLE ASS OS in your terminal!

# Color definitions
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

# System state
CURRENT_USER="alexa"
CURRENT_DIR="~"
RUNNING_PROCESSES=("blackroad-kernel" "event-bus" "memory-vault" "agent-orchestrator")
NOTIFICATIONS=()

# Boot sequence
boot_sequence() {
    clear
    echo ""
    echo ""
    echo ""
    echo -e "                    ${BOLD}${ORANGE}███████████████████████████${RESET}"
    echo -e "                    ${BOLD}${ORANGE}█${RESET}                         ${BOLD}${ORANGE}█${RESET}"
    echo -e "                    ${BOLD}${ORANGE}█${RESET}   ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET}   ${BOLD}${ORANGE}█${RESET}"
    echo -e "                    ${BOLD}${ORANGE}█${RESET}                         ${BOLD}${ORANGE}█${RESET}"
    echo -e "                    ${BOLD}${ORANGE}███████████████████████████${RESET}"
    echo ""
    echo ""
    echo -e "                        ${TEXT_MUTED}Initializing kernel...${RESET}"
    sleep 0.5
    echo -e "                        ${BLUE}[✓]${RESET} ${TEXT_SECONDARY}Kernel loaded${RESET}"
    sleep 0.3
    echo -e "                        ${BLUE}[✓]${RESET} ${TEXT_SECONDARY}Memory vault initialized${RESET}"
    sleep 0.3
    echo -e "                        ${BLUE}[✓]${RESET} ${TEXT_SECONDARY}Event bus started${RESET}"
    sleep 0.3
    echo -e "                        ${BLUE}[✓]${RESET} ${TEXT_SECONDARY}Agent orchestrator online${RESET}"
    sleep 0.3
    echo -e "                        ${BLUE}[✓]${RESET} ${TEXT_SECONDARY}Network interfaces ready${RESET}"
    sleep 0.3
    echo -e "                        ${BLUE}[✓]${RESET} ${TEXT_SECONDARY}PS-SHA∞ verification complete${RESET}"
    sleep 0.5
    echo ""
    echo -e "                        ${ORANGE}Welcome to BlackRoad OS${RESET}"
    sleep 1
}

# Login screen
login_screen() {
    clear
    echo ""
    echo ""
    echo ""
    echo -e "                    ${BOLD}${ORANGE}╔═════════════════════════════╗${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                             ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}     ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET}     ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                             ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}╚═════════════════════════════╝${RESET}"
    echo ""
    echo ""
    echo -e "                        ${TEXT_SECONDARY}User: ${RESET}${BOLD}${ORANGE}${CURRENT_USER}${RESET}"
    echo ""
    echo -e "                        ${TEXT_MUTED}Press ENTER to login...${RESET}"
    read
}

# Desktop environment
desktop() {
    while true; do
        clear

        # Top bar
        echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BOLD}${ORANGE}║${RESET} ${BOLD}${ORANGE}👻${RESET} ${TEXT_PRIMARY}BlackRoad OS${RESET}                    ${TEXT_MUTED}$(date '+%H:%M')${RESET}  ${TEXT_SECONDARY}${CURRENT_USER}@blackroad${RESET} ${BOLD}${ORANGE}║${RESET}"
        echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""

        # Main menu bar
        echo -e "  ${BOLD}${ORANGE}[1]${RESET} ${TEXT_PRIMARY}Apps${RESET}  ${BOLD}${PINK}[2]${RESET} ${TEXT_PRIMARY}Files${RESET}  ${BOLD}${PURPLE}[3]${RESET} ${TEXT_PRIMARY}Processes${RESET}  ${BOLD}${BLUE}[4]${RESET} ${TEXT_PRIMARY}Network${RESET}  ${BOLD}${CYAN}[5]${RESET} ${TEXT_PRIMARY}Settings${RESET}  ${BOLD}${TEXT_MUTED}[q]${RESET} ${TEXT_MUTED}Shutdown${RESET}"
        echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo ""

        # Desktop content
        echo -e "${TEXT_MUTED}QUICK ACCESS${RESET}"
        echo ""
        echo -e "  ${ORANGE}📊${RESET} ${TEXT_PRIMARY}Dashboards${RESET}         ${TEXT_MUTED}Launch monitoring dashboards${RESET}"
        echo -e "  ${PURPLE}🤖${RESET} ${TEXT_PRIMARY}Agent Manager${RESET}      ${TEXT_MUTED}Manage 47 active agents${RESET}"
        echo -e "  ${BLUE}📡${RESET} ${TEXT_PRIMARY}Infrastructure${RESET}     ${TEXT_MUTED}5 devices • 16 zones${RESET}"
        echo -e "  ${CYAN}💾${RESET} ${TEXT_PRIMARY}Memory Vault${RESET}       ${TEXT_MUTED}28.0 MB • 2,596 entries${RESET}"
        echo -e "  ${PINK}⚡${RESET} ${TEXT_PRIMARY}Event Bus${RESET}          ${TEXT_MUTED}1.2K events/min${RESET}"
        echo ""

        # System status
        echo -e "${TEXT_MUTED}SYSTEM STATUS${RESET}"
        echo ""
        echo -e "  ${BLUE}●${RESET} ${TEXT_SECONDARY}CPU:${RESET} ${BOLD}${BLUE}34%${RESET}  ${PURPLE}●${RESET} ${TEXT_SECONDARY}Memory:${RESET} ${BOLD}${PURPLE}67%${RESET}  ${CYAN}●${RESET} ${TEXT_SECONDARY}Disk:${RESET} ${BOLD}${CYAN}23%${RESET}  ${ORANGE}●${RESET} ${TEXT_SECONDARY}Uptime:${RESET} ${BOLD}${ORANGE}5d 14h${RESET}"
        echo ""

        # Notifications
        if [ ${#NOTIFICATIONS[@]} -gt 0 ]; then
            echo -e "${TEXT_MUTED}NOTIFICATIONS${RESET}"
            echo ""
            for notif in "${NOTIFICATIONS[@]}"; do
                echo -e "  ${ORANGE}!${RESET} ${TEXT_SECONDARY}${notif}${RESET}"
            done
            echo ""
        fi

        echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -ne "${TEXT_PRIMARY}> ${RESET}"

        read -rsn1 choice

        case $choice in
            1) apps_menu ;;
            2) file_manager ;;
            3) process_manager ;;
            4) network_tools ;;
            5) settings_menu ;;
            q|Q) shutdown_sequence; exit 0 ;;
        esac
    done
}

# Apps menu
apps_menu() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${ORANGE}📱${RESET}  ${BOLD}${TEXT_PRIMARY}Applications${RESET}                                                    ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}DASHBOARDS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} ${BOLD}Basic Dashboard${RESET}        ${TEXT_MUTED}Quick status overview${RESET}"
    echo -e "  ${PINK}2)${RESET} ${BOLD}Live Monitor${RESET}           ${TEXT_MUTED}Infrastructure monitoring${RESET}"
    echo -e "  ${PURPLE}3)${RESET} ${BOLD}Full System${RESET}            ${TEXT_MUTED}Enhanced with progress bars${RESET}"
    echo -e "  ${BLUE}4)${RESET} ${BOLD}ULTIMATE Edition${RESET}       ${TEXT_MUTED}All features + sound${RESET}"
    echo -e "  ${CYAN}5)${RESET} ${BOLD}Windows 95${RESET}             ${TEXT_MUTED}Retro UI experience${RESET}"
    echo -e "  ${ORANGE}6)${RESET} ${BOLD}Agent Detail${RESET}          ${TEXT_MUTED}Inspect individual agents${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}TOOLS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${PURPLE}7)${RESET} ${BOLD}Terminal${RESET}               ${TEXT_MUTED}Command line interface${RESET}"
    echo -e "  ${BLUE}8)${RESET} ${BOLD}System Monitor${RESET}         ${TEXT_MUTED}Resource usage${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -ne "${TEXT_PRIMARY}Choice (0 to go back): ${RESET}"

    read app_choice

    case $app_choice in
        1) ./blackroad-dashboard.sh; read -p "Press ENTER to continue..." ;;
        2) ./blackroad-live-dashboard.sh; read -p "Press ENTER to continue..." ;;
        3) ./blackroad-full-system.sh --watch ;;
        4) ./blackroad-ultimate.sh --watch ;;
        5) ./blackroad-os95.sh --boot ;;
        6) ./agent-detail.sh "Lucidia Prime" "192.168.4.38" "online" "sonnet-4.5" "overview" --watch ;;
        7) terminal_app ;;
        8) system_monitor ;;
        0) return ;;
    esac
}

# File manager
file_manager() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${PINK}📁${RESET}  ${BOLD}${TEXT_PRIMARY}File Manager${RESET} ${TEXT_MUTED}- ${CURRENT_DIR}${RESET}                                   ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}DIRECTORIES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}blackroad-dashboards${RESET}    ${TEXT_MUTED}7 files${RESET}"
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}agents${RESET}                  ${TEXT_MUTED}47 active agents${RESET}"
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}memory-vault${RESET}            ${TEXT_MUTED}28.0 MB${RESET}"
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}cloudflare${RESET}              ${TEXT_MUTED}16 zones${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}FILES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}📄${RESET} ${TEXT_SECONDARY}blackroad-os.sh${RESET}         ${TEXT_MUTED}Main launcher${RESET}"
    echo -e "  ${PURPLE}📄${RESET} ${TEXT_SECONDARY}README.md${RESET}               ${TEXT_MUTED}Documentation${RESET}"
    echo -e "  ${CYAN}📄${RESET} ${TEXT_SECONDARY}setup.sh${RESET}                ${TEXT_MUTED}Setup wizard${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}Press ENTER to go back...${RESET}"
    read
}

# Process manager
process_manager() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${PURPLE}⚙️${RESET}  ${BOLD}${TEXT_PRIMARY}Process Manager${RESET}                                                ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}RUNNING PROCESSES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}blackroad-kernel${RESET}        ${TEXT_SECONDARY}PID: 1${RESET}      ${ORANGE}CPU: 2%${RESET}   ${PURPLE}MEM: 124MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}event-bus${RESET}               ${TEXT_SECONDARY}PID: 42${RESET}     ${ORANGE}CPU: 5%${RESET}   ${PURPLE}MEM: 87MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}memory-vault${RESET}            ${TEXT_SECONDARY}PID: 128${RESET}    ${ORANGE}CPU: 3%${RESET}   ${PURPLE}MEM: 256MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${BOLD}${TEXT_PRIMARY}agent-orchestrator${RESET}      ${TEXT_SECONDARY}PID: 256${RESET}    ${ORANGE}CPU: 12%${RESET}  ${PURPLE}MEM: 512MB${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}AGENT PROCESSES${RESET} ${TEXT_SECONDARY}(showing 6 of 47)${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Lucidia Prime${RESET}           ${TEXT_SECONDARY}PID: 1024${RESET}   ${ORANGE}CPU: 8%${RESET}   ${PURPLE}MEM: 256MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Oracle${RESET}                  ${TEXT_SECONDARY}PID: 2048${RESET}   ${ORANGE}CPU: 4%${RESET}   ${PURPLE}MEM: 128MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Sentinel${RESET}                ${TEXT_SECONDARY}PID: 4096${RESET}   ${ORANGE}CPU: 6%${RESET}   ${PURPLE}MEM: 196MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Metrics${RESET}                 ${TEXT_SECONDARY}PID: 8192${RESET}   ${ORANGE}CPU: 3%${RESET}   ${PURPLE}MEM: 92MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Crystal${RESET}                 ${TEXT_SECONDARY}PID: 16384${RESET}  ${ORANGE}CPU: 5%${RESET}   ${PURPLE}MEM: 164MB${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Navigator${RESET}               ${TEXT_SECONDARY}PID: 32768${RESET}  ${ORANGE}CPU: 2%${RESET}   ${PURPLE}MEM: 78MB${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Total: ${RESET}${BOLD}${ORANGE}51${RESET} ${TEXT_SECONDARY}processes  •  CPU: ${RESET}${BOLD}${ORANGE}34%${RESET}  ${TEXT_SECONDARY}•  Memory: ${RESET}${BOLD}${PURPLE}67%${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}Press ENTER to go back...${RESET}"
    read
}

# Network tools
network_tools() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BLUE}📡${RESET}  ${BOLD}${TEXT_PRIMARY}Network Tools${RESET}                                                  ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}Scanning infrastructure...${RESET}"
    echo ""

    # Check infrastructure
    local lucidia=$(ping -c 1 -W 1 192.168.4.38 &>/dev/null && echo "${BLUE}ONLINE${RESET}" || echo "${TEXT_MUTED}OFFLINE${RESET}")
    local pi=$(ping -c 1 -W 1 192.168.4.64 &>/dev/null && echo "${BLUE}ONLINE${RESET}" || echo "${TEXT_MUTED}OFFLINE${RESET}")
    local alt=$(ping -c 1 -W 1 192.168.4.99 &>/dev/null && echo "${BLUE}ONLINE${RESET}" || echo "${TEXT_MUTED}OFFLINE${RESET}")
    local iphone=$(ping -c 1 -W 1 192.168.4.68 &>/dev/null && echo "${BLUE}ONLINE${RESET}" || echo "${TEXT_MUTED}OFFLINE${RESET}")
    local droplet=$(ping -c 1 -W 1 159.65.43.12 &>/dev/null && echo "${BLUE}ONLINE${RESET}" || echo "${TEXT_MUTED}OFFLINE${RESET}")

    echo -e "${TEXT_MUTED}RASPBERRY PI NETWORK${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_PRIMARY}Lucidia Prime${RESET}       ${TEXT_SECONDARY}192.168.4.38${RESET}      ${lucidia}"
    echo -e "  ${TEXT_PRIMARY}BlackRoad Pi${RESET}        ${TEXT_SECONDARY}192.168.4.64${RESET}      ${pi}"
    echo -e "  ${TEXT_PRIMARY}Lucidia Alt${RESET}         ${TEXT_SECONDARY}192.168.4.99${RESET}      ${alt}"
    echo -e "  ${TEXT_PRIMARY}iPhone Koder${RESET}        ${TEXT_SECONDARY}192.168.4.68:8080${RESET} ${iphone}"
    echo ""
    echo -e "${TEXT_MUTED}CLOUD INFRASTRUCTURE${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_PRIMARY}Codex Infinity${RESET}      ${TEXT_SECONDARY}159.65.43.12${RESET}      ${droplet}"
    echo -e "  ${TEXT_PRIMARY}Cloudflare${RESET}          ${TEXT_SECONDARY}16 zones${RESET}          ${BLUE}ONLINE${RESET}"
    echo -e "  ${TEXT_PRIMARY}GitHub${RESET}              ${TEXT_SECONDARY}15 orgs, 66 repos${RESET} ${BLUE}ONLINE${RESET}"
    echo -e "  ${TEXT_PRIMARY}Railway${RESET}             ${TEXT_SECONDARY}12+ projects${RESET}      ${BLUE}ONLINE${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}MESH NETWORK${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_PRIMARY}Tailscale/Headscale${RESET} ${TEXT_SECONDARY}headscale.blackroad.io${RESET} ${BLUE}ACTIVE${RESET}"
    echo -e "  ${TEXT_SECONDARY}Control Plane:${RESET} ${TEXT_MUTED}192.168.4.x network${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}Press ENTER to go back...${RESET}"
    read
}

# Settings menu
settings_menu() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${CYAN}⚙️${RESET}  ${BOLD}${TEXT_PRIMARY}System Settings${RESET}                                                ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}SYSTEM${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Deployment Mode:${RESET}    ${BOLD}${PURPLE}Hybrid${RESET}"
    echo -e "  ${TEXT_SECONDARY}Max Agents:${RESET}         ${BOLD}${ORANGE}100${RESET}"
    echo -e "  ${TEXT_SECONDARY}Default Model:${RESET}      ${BOLD}${BLUE}sonnet-4.5${RESET}"
    echo -e "  ${TEXT_SECONDARY}Memory per Agent:${RESET}   ${BOLD}${CYAN}256 MB${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}FEATURES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}Event Bus${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}PS-SHA∞${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}Z-Framework${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}Auto-scaling${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}Memory Vault${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}ABOUT${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}BlackRoad OS ${RESET}${BOLD}${ORANGE}v1.0.0${RESET}"
    echo -e "  ${TEXT_MUTED}A complete terminal operating system${RESET}"
    echo -e "  ${TEXT_MUTED}Created with 💜 by Alexa & Claude${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}Press ENTER to go back...${RESET}"
    read
}

# Terminal app
terminal_app() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${PURPLE}💻${RESET}  ${BOLD}${TEXT_PRIMARY}Terminal${RESET}                                                       ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_PRIMARY}BlackRoad OS Terminal ${RESET}${TEXT_MUTED}[Type 'exit' to return]${RESET}"
    echo ""

    while true; do
        echo -ne "${ORANGE}${CURRENT_USER}@blackroad${RESET}:${BLUE}${CURRENT_DIR}${RESET}\$ "
        read cmd

        case $cmd in
            exit) return ;;
            ls) echo -e "${BLUE}blackroad-dashboards${RESET}  ${PURPLE}agents${RESET}  ${CYAN}memory-vault${RESET}  ${ORANGE}cloudflare${RESET}" ;;
            pwd) echo "$CURRENT_DIR" ;;
            whoami) echo "$CURRENT_USER" ;;
            date) date ;;
            uptime) echo "up 5 days, 14 hours" ;;
            *) echo -e "${PINK}blackroad-os:${RESET} command not found: $cmd" ;;
        esac
    done
}

# System monitor
system_monitor() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BLUE}📊${RESET}  ${BOLD}${TEXT_PRIMARY}System Monitor${RESET}                                                 ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}RESOURCE USAGE${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}CPU${RESET}              ${BLUE}34%${RESET}"
    echo -ne "  "
    echo -e "${BLUE}██████████${RESET}                                        "
    echo ""
    echo -e "  ${TEXT_SECONDARY}Memory${RESET}           ${PURPLE}67%${RESET}"
    echo -ne "  "
    echo -e "${PURPLE}████████████████████${RESET}                            "
    echo ""
    echo -e "  ${TEXT_SECONDARY}Disk${RESET}             ${CYAN}23%${RESET}"
    echo -ne "  "
    echo -e "${CYAN}██████${RESET}                                          "
    echo ""
    echo -e "  ${TEXT_SECONDARY}Network${RESET}          ${ORANGE}12%${RESET}"
    echo -ne "  "
    echo -e "${ORANGE}███${RESET}                                             "
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Uptime:${RESET} ${BOLD}${ORANGE}5d 14h 23m${RESET}  ${TEXT_SECONDARY}•  Load:${RESET} ${BOLD}${PURPLE}2.34${RESET}  ${TEXT_SECONDARY}•  Processes:${RESET} ${BOLD}${BLUE}51${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}Press ENTER to go back...${RESET}"
    read
}

# Shutdown sequence
shutdown_sequence() {
    clear
    echo ""
    echo ""
    echo ""
    echo -e "                    ${BOLD}${ORANGE}╔═══════════════════════════╗${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                           ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}   ${BOLD}${ORANGE}Shutting down...${RESET}      ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                           ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}╚═══════════════════════════╝${RESET}"
    echo ""
    echo ""
    sleep 0.5
    echo -e "                        ${TEXT_MUTED}Stopping agents...${RESET}"
    sleep 0.3
    echo -e "                        ${TEXT_MUTED}Closing event bus...${RESET}"
    sleep 0.3
    echo -e "                        ${TEXT_MUTED}Syncing memory vault...${RESET}"
    sleep 0.3
    echo -e "                        ${TEXT_MUTED}Kernel shutdown...${RESET}"
    sleep 0.5
    echo ""
    echo -e "                        ${ORANGE}Goodbye! 👻${RESET}"
    echo ""
    sleep 1
    clear
}

# Main execution
main() {
    boot_sequence
    login_screen
    desktop
}

main
