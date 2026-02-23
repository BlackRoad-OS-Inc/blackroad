#!/bin/bash

# BlackRoad OS - NEXT LEVEL
# A complete windowing operating system in terminal!

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
WINDOWS=()
ACTIVE_WINDOW=0
TASKBAR_APPS=()
NOTIFICATIONS=()
CLIPBOARD=""
SYSTEM_UPTIME=$((5 * 24 * 60 + 14 * 60))  # 5d 14h in minutes

# Sound system
play_sound() {
    local sound=$1
    case $sound in
        boot) afplay /System/Library/Sounds/Glass.aiff 2>/dev/null & ;;
        click) afplay /System/Library/Sounds/Tink.aiff 2>/dev/null & ;;
        notification) afplay /System/Library/Sounds/Morse.aiff 2>/dev/null & ;;
        error) afplay /System/Library/Sounds/Basso.aiff 2>/dev/null & ;;
        shutdown) afplay /System/Library/Sounds/Blow.aiff 2>/dev/null & ;;
    esac
}

# Notification system
add_notification() {
    local msg=$1
    NOTIFICATIONS+=("$msg")
    play_sound notification
}

# Boot sequence with progress
boot_sequence() {
    clear
    play_sound boot

    echo ""
    echo ""
    echo -e "                    ${BOLD}${ORANGE}███████████████████████████████${RESET}"
    echo -e "                    ${BOLD}${ORANGE}█${RESET}                             ${BOLD}${ORANGE}█${RESET}"
    echo -e "                    ${BOLD}${ORANGE}█${RESET}   ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET}       ${BOLD}${ORANGE}█${RESET}"
    echo -e "                    ${BOLD}${ORANGE}█${RESET}   ${TEXT_MUTED}NEXT LEVEL${RESET}            ${BOLD}${ORANGE}█${RESET}"
    echo -e "                    ${BOLD}${ORANGE}█${RESET}                             ${BOLD}${ORANGE}█${RESET}"
    echo -e "                    ${BOLD}${ORANGE}███████████████████████████████${RESET}"
    echo ""
    echo ""

    # Boot progress
    local steps=("Initializing kernel" "Loading drivers" "Starting event bus" "Mounting memory vault" "Starting agent orchestrator" "Initializing window manager" "Loading desktop environment" "Starting network services" "PS-SHA∞ verification" "System ready")

    for step in "${steps[@]}"; do
        echo -e "                        ${TEXT_MUTED}${step}...${RESET}"
        sleep 0.3
        echo -e "                        ${BLUE}[✓]${RESET} ${TEXT_SECONDARY}${step} complete${RESET}"
        sleep 0.2
    done

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
    echo -e "                    ${BOLD}${ORANGE}╔═════════════════════════════════╗${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                                 ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}     ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET}         ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}     ${TEXT_MUTED}NEXT LEVEL${RESET}              ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                                 ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}╚═════════════════════════════════╝${RESET}"
    echo ""
    echo ""
    echo -e "                        ${TEXT_SECONDARY}User: ${RESET}${BOLD}${ORANGE}${CURRENT_USER}${RESET}"
    echo ""
    echo -e "                        ${TEXT_MUTED}Press ENTER to login...${RESET}"
    read
    play_sound click
    add_notification "Welcome back, ${CURRENT_USER}!"
}

# Draw system tray
draw_system_tray() {
    local time=$(date '+%H:%M')
    local cpu_usage=34
    local mem_usage=67
    local network="⬆︎ 2.3MB/s ⬇︎ 1.1MB/s"

    echo -ne "${TEXT_SECONDARY}${time}${RESET}  "
    echo -ne "${BLUE}CPU:${cpu_usage}%${RESET}  "
    echo -ne "${PURPLE}MEM:${mem_usage}%${RESET}  "
    echo -ne "${CYAN}${network}${RESET}  "
    echo -ne "${ORANGE}🔊${RESET}"
}

# Draw taskbar
draw_taskbar() {
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -ne "${BOLD}${ORANGE}║${RESET} "

    # App shortcuts
    echo -ne "${BOLD}${ORANGE}[⚡ Start]${RESET} "
    echo -ne "${BLUE}[📊 Dashboard]${RESET} "
    echo -ne "${PURPLE}[📁 Files]${RESET} "
    echo -ne "${PINK}[💻 Terminal]${RESET} "
    echo -ne "${CYAN}[⚙️  Settings]${RESET} "

    # Spacer
    echo -ne "        "

    # System tray
    draw_system_tray

    echo -e " ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
}

# Draw window
draw_window() {
    local title=$1
    local content=$2
    local width=70

    echo -e "${BOLD}${ORANGE}╔$(printf '═%.0s' {1..70})╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET} ${BOLD}${TEXT_PRIMARY}${title}${RESET} $(printf ' %.0s' {1..60}) ${BOLD}${ORANGE}[_][□][X]║${RESET}"
    echo -e "${BOLD}${ORANGE}╠$(printf '═%.0s' {1..70})╣${RESET}"
}

# Desktop environment with window manager
desktop() {
    while true; do
        clear

        # Top bar
        echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -ne "${BOLD}${ORANGE}║${RESET} ${BOLD}${ORANGE}👻 BlackRoad OS${RESET}  "

        # Active windows indicator
        if [ ${#WINDOWS[@]} -gt 0 ]; then
            echo -ne "${TEXT_MUTED}[${#WINDOWS[@]} windows]${RESET}  "
        fi

        # Notifications badge
        if [ ${#NOTIFICATIONS[@]} -gt 0 ]; then
            echo -ne "${PINK}🔔 ${#NOTIFICATIONS[@]}${RESET}  "
        fi

        # Right side - system info
        printf '%*s' $((58 - ${#WINDOWS[@]} * 2 - ${#NOTIFICATIONS[@]} * 2)) ""
        draw_system_tray
        echo -e " ${BOLD}${ORANGE}║${RESET}"
        echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""

        # Main desktop area
        echo -e "${TEXT_MUTED}QUICK LAUNCH${RESET}"
        echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${BOLD}${ORANGE}[1]${RESET} 📱 ${TEXT_PRIMARY}Applications${RESET}     ${BOLD}${PINK}[2]${RESET} 📁 ${TEXT_PRIMARY}File Manager${RESET}     ${BOLD}${PURPLE}[3]${RESET} ⚙️  ${TEXT_PRIMARY}Processes${RESET}"
        echo -e "  ${BOLD}${BLUE}[4]${RESET} 📡 ${TEXT_PRIMARY}Network${RESET}          ${BOLD}${CYAN}[5]${RESET} 💻 ${TEXT_PRIMARY}Terminal${RESET}         ${BOLD}${ORANGE}[6]${RESET} 📊 ${TEXT_PRIMARY}Monitor${RESET}"
        echo -e "  ${BOLD}${PINK}[7]${RESET} 📦 ${TEXT_PRIMARY}Packages${RESET}         ${BOLD}${PURPLE}[8]${RESET} 📝 ${TEXT_PRIMARY}Text Editor${RESET}      ${BOLD}${BLUE}[9]${RESET} 📜 ${TEXT_PRIMARY}Logs${RESET}"
        echo ""

        # Desktop widgets
        echo -e "${TEXT_MUTED}SYSTEM STATUS${RESET}"
        echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo ""

        # Mini resource graphs
        echo -e "  ${TEXT_SECONDARY}CPU${RESET}     ${BLUE}████████░░░░░░░░░░${RESET} ${BOLD}34%${RESET}   ${TEXT_SECONDARY}Memory${RESET}  ${PURPLE}█████████████░░░░░░░${RESET} ${BOLD}67%${RESET}"
        echo -e "  ${TEXT_SECONDARY}Network${RESET} ${CYAN}███░░░░░░░░░░░░░░░${RESET} ${BOLD}12%${RESET}   ${TEXT_SECONDARY}Disk${RESET}    ${ORANGE}████░░░░░░░░░░░░░░░${RESET} ${BOLD}23%${RESET}"
        echo ""

        # Active agents
        echo -e "${TEXT_MUTED}ACTIVE AGENTS${RESET} ${TEXT_SECONDARY}(47 running)${RESET}"
        echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${BLUE}●${RESET} Lucidia Prime  ${BLUE}●${RESET} Oracle  ${BLUE}●${RESET} Sentinel  ${BLUE}●${RESET} Metrics  ${BLUE}●${RESET} Crystal  ${TEXT_MUTED}+42 more${RESET}"
        echo ""

        # Recent notifications
        if [ ${#NOTIFICATIONS[@]} -gt 0 ]; then
            echo -e "${TEXT_MUTED}NOTIFICATIONS${RESET}"
            echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
            echo ""
            local count=0
            for notif in "${NOTIFICATIONS[@]}"; do
                if [ $count -lt 3 ]; then
                    echo -e "  ${ORANGE}!${RESET} ${TEXT_SECONDARY}${notif}${RESET}"
                    ((count++))
                fi
            done
            if [ ${#NOTIFICATIONS[@]} -gt 3 ]; then
                echo -e "  ${TEXT_MUTED}+ $((${#NOTIFICATIONS[@]} - 3)) more${RESET}"
            fi
            echo ""
        fi

        echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo ""
        echo -e "  ${TEXT_MUTED}Shortcuts: ${TEXT_SECONDARY}[n]${TEXT_MUTED} Notifications  ${TEXT_SECONDARY}[k]${TEXT_MUTED} Shortcuts  ${TEXT_SECONDARY}[h]${TEXT_MUTED} Help  ${TEXT_SECONDARY}[q]${TEXT_MUTED} Shutdown${RESET}"
        echo -ne "\n${TEXT_PRIMARY}> ${RESET}"

        read -rsn1 choice

        case $choice in
            1) apps_menu ;;
            2) file_manager ;;
            3) process_manager ;;
            4) network_manager ;;
            5) terminal_window ;;
            6) system_monitor ;;
            7) package_manager ;;
            8) text_editor ;;
            9) log_viewer ;;
            n|N) notifications_center ;;
            k|K) keyboard_shortcuts ;;
            h|H) help_center ;;
            q|Q) shutdown_menu ;;
        esac
    done
}

# Apps menu with categories
apps_menu() {
    clear
    draw_window "Applications" ""
    echo ""
    echo -e "${TEXT_MUTED}DASHBOARDS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} Basic Dashboard        ${PINK}2)${RESET} Live Monitor          ${PURPLE}3)${RESET} Full System"
    echo -e "  ${BLUE}4)${RESET} ULTIMATE Edition       ${CYAN}5)${RESET} Windows 95            ${ORANGE}6)${RESET} Agent Detail"
    echo ""
    echo -e "${TEXT_MUTED}TOOLS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${PURPLE}7)${RESET} Terminal               ${BLUE}8)${RESET} File Manager          ${CYAN}9)${RESET} System Monitor"
    echo -e "  ${ORANGE}a)${RESET} Process Manager        ${PINK}b)${RESET} Network Tools         ${PURPLE}c)${RESET} Text Editor"
    echo ""
    echo -e "${TEXT_MUTED}DEVELOPMENT${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}d)${RESET} Package Manager        ${CYAN}e)${RESET} Log Viewer            ${ORANGE}f)${RESET} Settings"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -ne "\n${TEXT_PRIMARY}Choice (0 to cancel): ${RESET}"

    read app_choice
    play_sound click

    case $app_choice in
        1) ./blackroad-dashboard.sh; read -p "Press ENTER..." ;;
        2) ./blackroad-live-dashboard.sh; read -p "Press ENTER..." ;;
        3) ./blackroad-full-system.sh --watch ;;
        4) ./blackroad-ultimate.sh --watch ;;
        5) ./blackroad-os95.sh --boot ;;
        6) ./agent-detail.sh "Lucidia Prime" "192.168.4.38" "online" "sonnet-4.5" "overview" --watch ;;
        7) terminal_window ;;
        8) file_manager ;;
        9) system_monitor ;;
        a) process_manager ;;
        b) network_manager ;;
        c) text_editor ;;
        d) package_manager ;;
        e) log_viewer ;;
        f) settings_advanced ;;
    esac
}

# Enhanced file manager with tree view
file_manager() {
    clear
    draw_window "File Manager - ~/" ""
    echo ""
    echo -e "${TEXT_MUTED}LOCATION${RESET} ${ORANGE}~/${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}blackroad-dashboards/${RESET}"
    echo -e "  ${TEXT_MUTED}├──${RESET} ${ORANGE}📄${RESET} blackroad-os.sh"
    echo -e "  ${TEXT_MUTED}├──${RESET} ${ORANGE}📄${RESET} blackroad-next-level-os.sh"
    echo -e "  ${TEXT_MUTED}├──${RESET} ${ORANGE}📄${RESET} setup.sh"
    echo -e "  ${TEXT_MUTED}└──${RESET} ${PURPLE}📄${RESET} README.md"
    echo ""
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}agents/${RESET}  ${TEXT_MUTED}(47 active)${RESET}"
    echo -e "  ${TEXT_MUTED}├──${RESET} ${CYAN}🤖${RESET} Lucidia-Prime/"
    echo -e "  ${TEXT_MUTED}├──${RESET} ${CYAN}🤖${RESET} Oracle/"
    echo -e "  ${TEXT_MUTED}├──${RESET} ${CYAN}🤖${RESET} Sentinel/"
    echo -e "  ${TEXT_MUTED}└──${RESET} ${TEXT_MUTED}... +44 more${RESET}"
    echo ""
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}memory-vault/${RESET}  ${TEXT_MUTED}(28.0 MB)${RESET}"
    echo -e "  ${BLUE}📁${RESET} ${TEXT_PRIMARY}cloudflare/${RESET}    ${TEXT_MUTED}(16 zones)${RESET}"
    echo -e "  ${ORANGE}📄${RESET} ${TEXT_SECONDARY}.blackroad-config${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "\n${TEXT_MUTED}[o] Open  [c] Copy  [v] Paste  [d] Delete  [ESC] Back${RESET}"
    read -p ""
}

# Advanced process manager
process_manager() {
    clear
    draw_window "Process Manager" ""
    echo ""
    echo -e "${TEXT_MUTED}SYSTEM PROCESSES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    printf "  %-5s %-25s %-8s %-8s %-10s\n" "PID" "NAME" "CPU" "MEM" "STATUS"
    echo -e "${TEXT_MUTED}  $(printf '─%.0s' {1..70})${RESET}"
    printf "  ${BLUE}%-5s${RESET} %-25s ${ORANGE}%-8s${RESET} ${PURPLE}%-8s${RESET} ${BLUE}%-10s${RESET}\n" "1" "blackroad-kernel" "2%" "124MB" "running"
    printf "  ${BLUE}%-5s${RESET} %-25s ${ORANGE}%-8s${RESET} ${PURPLE}%-8s${RESET} ${BLUE}%-10s${RESET}\n" "42" "event-bus" "5%" "87MB" "running"
    printf "  ${BLUE}%-5s${RESET} %-25s ${ORANGE}%-8s${RESET} ${PURPLE}%-8s${RESET} ${BLUE}%-10s${RESET}\n" "128" "memory-vault" "3%" "256MB" "running"
    printf "  ${BLUE}%-5s${RESET} %-25s ${ORANGE}%-8s${RESET} ${PURPLE}%-8s${RESET} ${BLUE}%-10s${RESET}\n" "256" "agent-orchestrator" "12%" "512MB" "running"
    echo ""
    echo -e "${TEXT_MUTED}AGENT PROCESSES${RESET} ${TEXT_SECONDARY}(showing 10 of 47)${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    printf "  ${BLUE}%-5s${RESET} %-25s ${ORANGE}%-8s${RESET} ${PURPLE}%-8s${RESET} ${BLUE}%-10s${RESET}\n" "1024" "Lucidia-Prime" "8%" "256MB" "active"
    printf "  ${BLUE}%-5s${RESET} %-25s ${ORANGE}%-8s${RESET} ${PURPLE}%-8s${RESET} ${BLUE}%-10s${RESET}\n" "2048" "Oracle" "4%" "128MB" "active"
    printf "  ${BLUE}%-5s${RESET} %-25s ${ORANGE}%-8s${RESET} ${PURPLE}%-8s${RESET} ${BLUE}%-10s${RESET}\n" "4096" "Sentinel" "6%" "196MB" "active"
    echo -e "  ${TEXT_MUTED}... +44 more agents${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "\n${TEXT_MUTED}Total: ${RESET}${BOLD}51${RESET} ${TEXT_MUTED}processes  •  CPU: ${RESET}${BOLD}34%${RESET}  ${TEXT_MUTED}•  Memory: ${RESET}${BOLD}67%${RESET}"
    read -p ""
}

# Network manager with live status
network_manager() {
    clear
    draw_window "Network Manager" ""
    echo ""
    echo -e "${TEXT_MUTED}Scanning infrastructure...${RESET}"
    echo ""

    local lucidia=$(ping -c 1 -W 1 192.168.4.38 &>/dev/null && echo "${BLUE}● ONLINE${RESET}" || echo "${TEXT_MUTED}○ OFFLINE${RESET}")
    local pi=$(ping -c 1 -W 1 192.168.4.64 &>/dev/null && echo "${BLUE}● ONLINE${RESET}" || echo "${TEXT_MUTED}○ OFFLINE${RESET}")
    local alt=$(ping -c 1 -W 1 192.168.4.99 &>/dev/null && echo "${BLUE}● ONLINE${RESET}" || echo "${TEXT_MUTED}○ OFFLINE${RESET}")
    local iphone=$(ping -c 1 -W 1 192.168.4.68 &>/dev/null && echo "${BLUE}● ONLINE${RESET}" || echo "${TEXT_MUTED}○ OFFLINE${RESET}")
    local droplet=$(ping -c 1 -W 1 159.65.43.12 &>/dev/null && echo "${BLUE}● ONLINE${RESET}" || echo "${TEXT_MUTED}○ OFFLINE${RESET}")

    echo -e "${TEXT_MUTED}RASPBERRY PI NETWORK${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    printf "  %-25s %-20s %s\n" "Lucidia Prime" "192.168.4.38" "$lucidia"
    printf "  %-25s %-20s %s\n" "BlackRoad Pi" "192.168.4.64" "$pi"
    printf "  %-25s %-20s %s\n" "Lucidia Alt" "192.168.4.99" "$alt"
    printf "  %-25s %-20s %s\n" "iPhone Koder" "192.168.4.68:8080" "$iphone"
    echo ""
    echo -e "${TEXT_MUTED}CLOUD INFRASTRUCTURE${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    printf "  %-25s %-20s %s\n" "Codex Infinity" "159.65.43.12" "$droplet"
    printf "  %-25s %-20s ${BLUE}%s${RESET}\n" "Cloudflare" "16 zones" "● ONLINE"
    printf "  %-25s %-20s ${BLUE}%s${RESET}\n" "GitHub" "15 orgs, 66 repos" "● ONLINE"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    read -p ""
}

# Terminal window
terminal_window() {
    clear
    draw_window "Terminal - ${CURRENT_USER}@blackroad" ""
    echo ""
    echo -e "${TEXT_MUTED}BlackRoad OS Terminal v1.0${RESET}"
    echo ""

    while true; do
        echo -ne "${ORANGE}${CURRENT_USER}@blackroad${RESET}:${BLUE}~${RESET}\$ "
        read cmd args

        case $cmd in
            exit) play_sound click; return ;;
            clear) clear; draw_window "Terminal - ${CURRENT_USER}@blackroad" ""; echo "" ;;
            ls) echo -e "${BLUE}blackroad-dashboards${RESET}  ${PURPLE}agents${RESET}  ${CYAN}memory-vault${RESET}" ;;
            pwd) echo "/home/${CURRENT_USER}" ;;
            whoami) echo "${CURRENT_USER}" ;;
            date) date ;;
            uptime) echo "up 5 days, 14 hours, 23 minutes" ;;
            top) echo -e "${ORANGE}PID  USER     CPU  MEM  COMMAND${RESET}\n1    root     2%   124M blackroad-kernel\n42   root     5%   87M  event-bus" ;;
            help) echo -e "Available commands: ${CYAN}ls pwd whoami date uptime top help exit${RESET}" ;;
            "") ;;
            *) echo -e "${PINK}blackroad-os:${RESET} command not found: ${cmd}" ;;
        esac
    done
}

# System monitor with graphs
system_monitor() {
    clear
    draw_window "System Monitor" ""
    echo ""
    echo -e "${TEXT_MUTED}REAL-TIME RESOURCE USAGE${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}CPU Usage${RESET}        ${BLUE}34%${RESET}"
    echo -ne "  ${BLUE}"; printf '█%.0s' {1..17}; echo -e "${TEXT_MUTED}$(printf '░%.0s' {1..33})${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Memory${RESET}           ${PURPLE}67%${RESET}"
    echo -ne "  ${PURPLE}"; printf '█%.0s' {1..33}; echo -e "${TEXT_MUTED}$(printf '░%.0s' {1..17})${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Network I/O${RESET}      ${CYAN}12%${RESET}"
    echo -ne "  ${CYAN}"; printf '█%.0s' {1..6}; echo -e "${TEXT_MUTED}$(printf '░%.0s' {1..44})${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Disk Usage${RESET}       ${ORANGE}23%${RESET}"
    echo -ne "  ${ORANGE}"; printf '█%.0s' {1..11}; echo -e "${TEXT_MUTED}$(printf '░%.0s' {1..39})${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}SYSTEM INFO${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Uptime:${RESET}      ${BOLD}${ORANGE}5d 14h 23m${RESET}"
    echo -e "  ${TEXT_SECONDARY}Load Avg:${RESET}    ${BOLD}${PURPLE}2.34, 2.12, 1.98${RESET}"
    echo -e "  ${TEXT_SECONDARY}Processes:${RESET}   ${BOLD}${BLUE}51 total${RESET}, ${BOLD}${CYAN}47 agents${RESET}"
    echo -e "  ${TEXT_SECONDARY}Events/min:${RESET}  ${BOLD}${PINK}1.2K${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    read -p ""
}

# Package manager
package_manager() {
    clear
    draw_window "Package Manager" ""
    echo ""
    echo -e "${TEXT_MUTED}INSTALLED PACKAGES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}blackroad-kernel${RESET}       ${TEXT_SECONDARY}v1.0.0${RESET}  ${TEXT_MUTED}Core system${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}event-bus${RESET}              ${TEXT_SECONDARY}v2.1.3${RESET}  ${TEXT_MUTED}Message broker${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}memory-vault${RESET}           ${TEXT_SECONDARY}v1.5.2${RESET}  ${TEXT_MUTED}Storage system${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}agent-orchestrator${RESET}     ${TEXT_SECONDARY}v3.0.1${RESET}  ${TEXT_MUTED}Agent manager${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}ps-sha-infinity${RESET}        ${TEXT_SECONDARY}v1.0.0${RESET}  ${TEXT_MUTED}Security${RESET}"
    echo -e "  ${BLUE}✓${RESET} ${TEXT_PRIMARY}z-framework${RESET}            ${TEXT_SECONDARY}v2.0.0${RESET}  ${TEXT_MUTED}Core framework${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}AVAILABLE UPDATES${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}⬆${RESET} ${TEXT_PRIMARY}event-bus${RESET}              ${TEXT_SECONDARY}v2.1.3 → v2.2.0${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "\n${TEXT_MUTED}[u] Update all  [i] Install  [r] Remove  [ESC] Back${RESET}"
    read -p ""
}

# Text editor
text_editor() {
    clear
    draw_window "Text Editor - untitled.txt" ""
    echo ""
    echo -e "${TEXT_MUTED}   1${RESET}  "
    echo -e "${TEXT_MUTED}   2${RESET}  ${TEXT_SECONDARY}# BlackRoad OS${RESET}"
    echo -e "${TEXT_MUTED}   3${RESET}  ${TEXT_SECONDARY}A complete terminal operating system${RESET}"
    echo -e "${TEXT_MUTED}   4${RESET}  "
    echo -e "${TEXT_MUTED}   5${RESET}  ${PURPLE}def${RESET} ${BLUE}main${RESET}():"
    echo -e "${TEXT_MUTED}   6${RESET}      ${CYAN}print${RESET}(${ORANGE}\"Hello, BlackRoad!\"${RESET})"
    echo -e "${TEXT_MUTED}   7${RESET}  "
    echo -e "${TEXT_MUTED}   8${RESET}  _"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_MUTED}[Ctrl+S] Save  [Ctrl+Q] Quit  [Ctrl+F] Find${RESET}"
    read -p ""
}

# Log viewer
log_viewer() {
    clear
    draw_window "System Logs" ""
    echo ""
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${TEXT_MUTED}SYSTEM LOGS${RESET} ${TEXT_SECONDARY}(real-time)${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  System initialized"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Event bus started"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${ORANGE}[WARN]${RESET}  High memory usage: 67%"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${PURPLE}[EVENT]${RESET} Agent spawned: Oracle"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Memory vault sync complete"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${CYAN}[API]${RESET}   Anthropic API: 247ms"
    echo -e "  ${TEXT_MUTED}[$timestamp]${RESET} ${BLUE}[INFO]${RESET}  Desktop environment loaded"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    read -p ""
}

# Notifications center
notifications_center() {
    clear
    draw_window "Notification Center" ""
    echo ""
    if [ ${#NOTIFICATIONS[@]} -eq 0 ]; then
        echo -e "  ${TEXT_MUTED}No notifications${RESET}"
    else
        for i in "${!NOTIFICATIONS[@]}"; do
            echo -e "  ${ORANGE}${i}.${RESET} ${TEXT_SECONDARY}${NOTIFICATIONS[$i]}${RESET}"
        done
    fi
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "\n${TEXT_MUTED}[c] Clear all  [ESC] Back${RESET}"
    read -rsn1 choice
    if [ "$choice" == "c" ]; then
        NOTIFICATIONS=()
        add_notification "All notifications cleared"
    fi
}

# Keyboard shortcuts
keyboard_shortcuts() {
    clear
    draw_window "Keyboard Shortcuts" ""
    echo ""
    echo -e "${TEXT_MUTED}NAVIGATION${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}1-9${RESET}     ${TEXT_SECONDARY}Quick launch apps${RESET}"
    echo -e "  ${ORANGE}n${RESET}       ${TEXT_SECONDARY}Open notification center${RESET}"
    echo -e "  ${ORANGE}k${RESET}       ${TEXT_SECONDARY}Show keyboard shortcuts${RESET}"
    echo -e "  ${ORANGE}h${RESET}       ${TEXT_SECONDARY}Open help${RESET}"
    echo -e "  ${ORANGE}q${RESET}       ${TEXT_SECONDARY}Shutdown menu${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}WINDOW MANAGEMENT${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}ESC${RESET}     ${TEXT_SECONDARY}Close current window${RESET}"
    echo -e "  ${ORANGE}TAB${RESET}     ${TEXT_SECONDARY}Switch between windows${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    read -p ""
}

# Help center
help_center() {
    clear
    draw_window "Help Center" ""
    echo ""
    echo -e "${TEXT_MUTED}ABOUT BLACKROAD OS${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${BOLD}${ORANGE}BlackRoad OS${RESET} ${TEXT_SECONDARY}v1.0.0 - NEXT LEVEL${RESET}"
    echo -e "  ${TEXT_MUTED}A complete terminal operating system${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Features:${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Full windowing system${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Multi-tasking support${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}47 active agents${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Real-time monitoring${RESET}"
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Package management${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Created with 💜 by:${RESET}"
    echo -e "  ${TEXT_PRIMARY}Alexa${RESET} ${TEXT_MUTED}&${RESET} ${TEXT_PRIMARY}Claude (Anthropic)${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    read -p ""
}

# Settings advanced
settings_advanced() {
    clear
    draw_window "Advanced Settings" ""
    echo ""
    echo -e "${TEXT_MUTED}SYSTEM CONFIGURATION${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Deployment Mode:${RESET}      ${BOLD}${PURPLE}Hybrid${RESET}      ${TEXT_MUTED}[change]${RESET}"
    echo -e "  ${TEXT_SECONDARY}Max Agents:${RESET}           ${BOLD}${ORANGE}100${RESET}         ${TEXT_MUTED}[change]${RESET}"
    echo -e "  ${TEXT_SECONDARY}Default Model:${RESET}        ${BOLD}${BLUE}sonnet-4.5${RESET}  ${TEXT_MUTED}[change]${RESET}"
    echo -e "  ${TEXT_SECONDARY}Sound Effects:${RESET}        ${BOLD}${BLUE}Enabled${RESET}     ${TEXT_MUTED}[toggle]${RESET}"
    echo -e "  ${TEXT_SECONDARY}Notifications:${RESET}        ${BOLD}${BLUE}Enabled${RESET}     ${TEXT_MUTED}[toggle]${RESET}"
    echo ""
    echo -e "${TEXT_MUTED}THEME${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${ORANGE}●${RESET} ${ORANGE}#FF9D00${RESET}  ${PINK}●${RESET} ${PINK}#E91E8C${RESET}  ${PURPLE}●${RESET} ${PURPLE}#9945FF${RESET}  ${BLUE}●${RESET} ${BLUE}#14F195${RESET}  ${CYAN}●${RESET} ${CYAN}#00D4FF${RESET}"
    echo ""
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    read -p ""
}

# Shutdown menu
shutdown_menu() {
    clear
    echo ""
    echo ""
    echo -e "                    ${BOLD}${ORANGE}╔═════════════════════════════════╗${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                                 ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}   ${BOLD}${TEXT_PRIMARY}Shutdown Options${RESET}          ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}║${RESET}                                 ${BOLD}${ORANGE}║${RESET}"
    echo -e "                    ${BOLD}${ORANGE}╚═════════════════════════════════╝${RESET}"
    echo ""
    echo -e "                        ${ORANGE}1)${RESET} ${TEXT_PRIMARY}Shutdown${RESET}"
    echo -e "                        ${PINK}2)${RESET} ${TEXT_PRIMARY}Restart${RESET}"
    echo -e "                        ${PURPLE}3)${RESET} ${TEXT_PRIMARY}Log Out${RESET}"
    echo -e "                        ${TEXT_MUTED}0)${RESET} ${TEXT_MUTED}Cancel${RESET}"
    echo ""
    echo -ne "                        ${TEXT_PRIMARY}Choice: ${RESET}"

    read -rsn1 choice

    case $choice in
        1) shutdown_sequence; exit 0 ;;
        2) play_sound shutdown; clear; main ;;
        3) desktop ;;
    esac
}

# Shutdown sequence
shutdown_sequence() {
    clear
    play_sound shutdown
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
    echo -e "                        ${TEXT_MUTED}Closing windows...${RESET}"
    sleep 0.3
    echo -e "                        ${TEXT_MUTED}Saving state...${RESET}"
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
