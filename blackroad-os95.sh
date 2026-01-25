#!/bin/bash

# BlackRoad OS 95 - Terminal Edition
# Windows 95 aesthetic meets CLI power

# Colors (Win95 palette + BlackRoad colors)
WIN_GRAY="\033[48;2;192;192;192m"
WIN_BLUE="\033[48;2;0;0;128m"
WIN_TITLEBAR="\033[48;2;0;0;128m"
WIN_BLACK="\033[30m"
WIN_WHITE="\033[97m"
TEAL_BG="\033[48;2;0;128;128m"

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
DIM="\033[2m"

# Sound effects
play_startup() {
    afplay /System/Library/Sounds/Glass.aiff &>/dev/null &
}

play_click() {
    afplay /System/Library/Sounds/Tink.aiff &>/dev/null &
}

play_error() {
    afplay /System/Library/Sounds/Basso.aiff &>/dev/null &
}

# Hide cursor
hide_cursor() {
    tput civis
}

# Show cursor
show_cursor() {
    tput cnorm
}

# Move cursor
move_cursor() {
    tput cup $1 $2
}

# Clear screen
clear_screen() {
    clear
    tput cup 0 0
}

# Boot sequence
boot_sequence() {
    clear_screen
    hide_cursor

    # Windows 95 boot screen
    echo -ne "${WIN_BLACK}${TEAL_BG}"
    clear

    move_cursor 10 25
    echo -e "${TEXT_PRIMARY}${BOLD}BlackRoad OS 95${RESET}${TEAL_BG}"

    move_cursor 12 20
    echo -e "${TEXT_SECONDARY}Starting up your computer...${RESET}${TEAL_BG}"

    # Progress bar
    move_cursor 15 15
    echo -ne "${WIN_GRAY}${WIN_BLACK}▓"
    for i in {1..50}; do
        echo -n "░"
        sleep 0.02
    done
    echo -e "${RESET}${TEAL_BG}"

    sleep 1
    play_startup
    sleep 1
}

# Desktop background
draw_desktop() {
    clear_screen
    echo -ne "${TEAL_BG}"
    clear

    # Desktop icons (left side)
    move_cursor 2 3
    echo -e "${TEXT_PRIMARY}💻 My Computer${RESET}${TEAL_BG}"

    move_cursor 4 3
    echo -e "${TEXT_PRIMARY}🗂️  Network${RESET}${TEAL_BG}"

    move_cursor 6 3
    echo -e "${TEXT_PRIMARY}🗑️  Recycle Bin${RESET}${TEAL_BG}"

    move_cursor 8 3
    echo -e "${TEXT_PRIMARY}👻 BlackRoad OS${RESET}${TEAL_BG}"

    move_cursor 10 3
    echo -e "${TEXT_PRIMARY}🤖 Agent Manager${RESET}${TEAL_BG}"

    move_cursor 12 3
    echo -e "${TEXT_PRIMARY}📟 Lucidia Terminal${RESET}${TEAL_BG}"
}

# Taskbar
draw_taskbar() {
    local time=$(date '+%I:%M %p')
    local taskbar_row=$(tput lines)

    move_cursor $taskbar_row 0
    echo -ne "${WIN_GRAY}"
    printf "%-$(tput cols)s" " "

    # Start button
    move_cursor $taskbar_row 1
    echo -ne "${WIN_GRAY}${WIN_BLACK}${BOLD}┌─────────┐${RESET}${WIN_GRAY}"

    move_cursor $((taskbar_row)) 1
    echo -ne "${WIN_GRAY}${WIN_BLACK}${BOLD}│${RESET}${WIN_GRAY}${ORANGE}👻${RESET}${WIN_GRAY}${WIN_BLACK}${BOLD} Start ${WIN_BLACK}│${RESET}${WIN_GRAY}"

    # Active windows
    move_cursor $taskbar_row 15
    echo -ne "${WIN_BLACK}├───────────────────┐ ├──────────────────┐${RESET}${WIN_GRAY}"

    move_cursor $taskbar_row 15
    echo -ne "${WIN_BLACK}│${RESET}${WIN_GRAY} 🤖 Agent Manager ${WIN_BLACK}│ │${RESET}${WIN_GRAY} 📟 Terminal     ${WIN_BLACK}│${RESET}${WIN_GRAY}"

    # System tray
    local tray_col=$(($(tput cols) - 18))
    move_cursor $taskbar_row $tray_col
    echo -ne "${WIN_BLACK}│${RESET}${WIN_GRAY} 🔊 🌐 ${BLUE}●${RESET}${WIN_GRAY} ${WIN_BLACK}${time}${RESET}${WIN_GRAY}"
}

# Window frame
draw_window() {
    local title=$1
    local icon=$2
    local row=$3
    local col=$4
    local width=$5
    local height=$6

    # Title bar
    move_cursor $row $col
    echo -ne "${WIN_TITLEBAR}${TEXT_PRIMARY}"
    printf "%-${width}s" " $icon $title"
    echo -ne " ${BOLD}_ □ ×${RESET}${TEAL_BG}"

    # Window body
    for ((i=1; i<height; i++)); do
        move_cursor $((row + i)) $col
        echo -ne "${WIN_GRAY}${WIN_BLACK}"
        printf "%-${width}s" " "
        echo -ne "${RESET}${TEAL_BG}"
    done

    # Status bar
    move_cursor $((row + height - 1)) $col
    echo -ne "${WIN_GRAY}${WIN_BLACK}├"
    printf "─%.0s" $(seq 1 $((width - 2)))
    echo -ne "┤${RESET}${TEAL_BG}"
}

# Agent Manager Window
show_agent_manager() {
    draw_window "BlackRoad Agent Manager" "🤖" 3 20 60 25

    # Menu bar
    move_cursor 4 20
    echo -ne "${WIN_GRAY}${WIN_BLACK} File  Edit  View  Agents  Help ${RESET}${TEAL_BG}"

    move_cursor 5 20
    echo -ne "${WIN_GRAY}${WIN_BLACK}├"
    printf "─%.0s" $(seq 1 58)
    echo -ne "┤${RESET}${TEAL_BG}"

    # Agent grid
    local agents=("👻 Lucidia" "🔮 Oracle" "🛡️  Sentinel" "📊 Metrics" "💎 Crystal" "🌐 Navigator" "⚡ Spark" "🎭 Mirror" "🔥 Phoenix" "🌙 Luna" "☀️  Solar" "🎯 Focus")
    local row=7
    local col_offset=0

    for ((i=0; i<12; i++)); do
        local agent_row=$((row + (i / 4) * 3))
        local agent_col=$((22 + (i % 4) * 15))

        move_cursor $agent_row $agent_col
        echo -ne "${WIN_GRAY}${BOLD}${ORANGE}${agents[$i]}${RESET}${TEAL_BG}"
    done

    # Status bar
    move_cursor 26 20
    echo -ne "${WIN_GRAY}${WIN_BLACK}├"
    printf "─%.0s" $(seq 1 58)
    echo -ne "┤${RESET}${TEAL_BG}"

    move_cursor 27 22
    echo -ne "${WIN_GRAY}${WIN_BLACK} 47 agents online                       192.168.4.x ${RESET}${TEAL_BG}"
}

# Terminal Window
show_terminal() {
    draw_window "Lucidia Terminal - lucidia@lucidia1" "📟" 6 45 70 20

    # Terminal content (black background)
    for ((i=7; i<25; i++)); do
        move_cursor $i 45
        echo -ne "\033[48;2;0;0;0m\033[38;2;192;192;192m"
        printf "%-70s" " "
        echo -ne "${RESET}${TEAL_BG}"
    done

    # Terminal text
    move_cursor 8 47
    echo -ne "\033[48;2;0;0;0m\033[38;2;192;192;192mBlackRoad OS [Version 95.2.0.57]${RESET}${TEAL_BG}"

    move_cursor 9 47
    echo -ne "\033[48;2;0;0;0m\033[38;2;192;192;192m(C) 2025 BlackRoad OS, Inc.${RESET}${TEAL_BG}"

    move_cursor 11 47
    echo -ne "\033[48;2;0;0;0m${BLUE}C:\\BLACKROAD>${RESET}\033[48;2;0;0;0m\033[38;2;192;192;192m orchestrate --status${RESET}${TEAL_BG}"

    move_cursor 13 47
    echo -ne "\033[48;2;0;0;0m${ORANGE}▸${RESET}\033[48;2;0;0;0m\033[38;2;192;192;192m Lucidia Core: ${BLUE}ONLINE${RESET}${TEAL_BG}"

    move_cursor 14 47
    echo -ne "\033[48;2;0;0;0m${PINK}▸${RESET}\033[48;2;0;0;0m\033[38;2;192;192;192m Agent Count: ${PINK}47/1000${RESET}\033[48;2;0;0;0m\033[38;2;192;192;192m active${RESET}${TEAL_BG}"

    move_cursor 15 47
    echo -ne "\033[48;2;0;0;0m${PURPLE}▸${RESET}\033[48;2;0;0;0m\033[38;2;192;192;192m Memory Vault: PS-SHA∞ verified${RESET}${TEAL_BG}"

    move_cursor 16 47
    echo -ne "\033[48;2;0;0;0m${BLUE}▸${RESET}\033[48;2;0;0;0m\033[38;2;192;192;192m Z-Framework: Z:=yx-w loaded${RESET}${TEAL_BG}"

    move_cursor 18 47
    echo -ne "\033[48;2;0;0;0m${BLUE}C:\\BLACKROAD>${RESET}\033[48;2;0;0;0m\033[38;2;192;192;192m agent spawn --name=\"Nova\"${RESET}${TEAL_BG}"

    move_cursor 20 47
    echo -ne "\033[48;2;0;0;0m${ORANGE}Agent Nova initialized successfully!${RESET}${TEAL_BG}"

    move_cursor 21 47
    echo -ne "\033[48;2;0;0;0m\033[38;2;192;192;192mAgent ID: AGT-0048${RESET}${TEAL_BG}"

    move_cursor 23 47
    echo -ne "\033[48;2;0;0;0m${BLUE}C:\\BLACKROAD>${RESET}\033[48;2;0;0;0m\033[38;2;255;255;255m█${RESET}${TEAL_BG}"
}

# Progress Dialog
show_progress() {
    local dialog_row=12
    local dialog_col=35

    # Dialog box
    draw_window "Deploying Agents..." "⏳" $dialog_row $dialog_col 50 12

    move_cursor $((dialog_row + 2)) $((dialog_col + 3))
    echo -ne "${WIN_GRAY}${WIN_BLACK}📦 Deploying: ${BOLD}Agent Collective${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 3)) $((dialog_col + 3))
    echo -ne "${WIN_GRAY}${TEXT_MUTED}From: C:\\BLACKROAD\\AGENTS${RESET}${TEAL_BG}"

    # Progress bar
    move_cursor $((dialog_row + 5)) $((dialog_col + 3))
    echo -ne "${WIN_GRAY}${WIN_BLACK}┌"
    printf "─%.0s" $(seq 1 42)
    echo -ne "┐${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 6)) $((dialog_col + 3))
    echo -ne "${WIN_GRAY}${WIN_BLACK}│${WIN_BLUE}"
    printf "%.0s " $(seq 1 20)
    echo -ne "${WIN_GRAY}${WIN_BLACK}"
    printf "%.0s " $(seq 1 22)
    echo -ne "│${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 7)) $((dialog_col + 3))
    echo -ne "${WIN_GRAY}${WIN_BLACK}└"
    printf "─%.0s" $(seq 1 42)
    echo -ne "┘${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 8)) $((dialog_col + 3))
    echo -ne "${WIN_GRAY}${TEXT_MUTED}47 of 1,000 agents deployed          4.7%${RESET}${TEAL_BG}"

    # Button
    move_cursor $((dialog_row + 10)) $((dialog_col + 17))
    echo -ne "${WIN_GRAY}${WIN_BLACK}┌──────────┐${RESET}${TEAL_BG}"
    move_cursor $((dialog_row + 10)) $((dialog_col + 17))
    echo -ne "${WIN_GRAY}${WIN_BLACK}│  Cancel  │${RESET}${TEAL_BG}"
}

# Properties Dialog
show_properties() {
    local dialog_row=8
    local dialog_col=50

    draw_window "BlackRoad OS Properties" "👻" $dialog_row $dialog_col 45 18

    # Tabs
    move_cursor $((dialog_row + 2)) $((dialog_col + 2))
    echo -ne "${WIN_GRAY}${WIN_BLACK}┌─────────┐ ┌────────┐ ┌─────────┐${RESET}${TEAL_BG}"
    move_cursor $((dialog_row + 2)) $((dialog_col + 2))
    echo -ne "${WIN_GRAY}${WIN_BLACK}│ General │ │ Agents │ │ Network │${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 3)) $((dialog_col + 2))
    echo -ne "${WIN_GRAY}${WIN_BLACK}└─────────┴─┴────────┴─┴─────────┴──────┘${RESET}${TEAL_BG}"

    # Content
    move_cursor $((dialog_row + 5)) $((dialog_col + 15))
    echo -ne "${WIN_GRAY}${BOLD}${ORANGE}👻${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 7)) $((dialog_col + 10))
    echo -ne "${WIN_GRAY}${BOLD}${WIN_BLACK}BlackRoad OS 95${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 8)) $((dialog_col + 11))
    echo -ne "${WIN_GRAY}${TEXT_MUTED}Version 2.0.57${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 10)) $((dialog_col + 3))
    echo -ne "${WIN_GRAY}${WIN_BLACK}${BOLD}Registered to:${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 11)) $((dialog_col + 5))
    echo -ne "${WIN_GRAY}${WIN_BLACK}Cecilia${RESET}${TEAL_BG}"

    move_cursor $((dialog_row + 12)) $((dialog_col + 5))
    echo -ne "${WIN_GRAY}${WIN_BLACK}BlackRoad OS, Inc.${RESET}${TEAL_BG}"

    # Buttons
    move_cursor $((dialog_row + 16)) $((dialog_col + 8))
    echo -ne "${WIN_GRAY}${WIN_BLACK}┌────┐ ┌────────┐ ┌───────┐${RESET}${TEAL_BG}"
    move_cursor $((dialog_row + 16)) $((dialog_col + 8))
    echo -ne "${WIN_GRAY}${WIN_BLACK}│ OK │ │ Cancel │ │ Apply │${RESET}${TEAL_BG}"
}

# Start Menu
show_start_menu() {
    local menu_row=$(($(tput lines) - 18))
    local menu_col=2

    # Menu background
    for ((i=0; i<16; i++)); do
        move_cursor $((menu_row + i)) $menu_col
        echo -ne "${WIN_GRAY}${WIN_BLACK}"
        printf "%-30s" " "
        echo -ne "${RESET}${TEAL_BG}"
    done

    # Sidebar gradient
    for ((i=0; i<16; i++)); do
        move_cursor $((menu_row + i)) $menu_col
        if [ $i -lt 5 ]; then
            echo -ne "\033[48;2;153;69;255m "
        elif [ $i -lt 10 ]; then
            echo -ne "\033[48;2;233;30;140m "
        else
            echo -ne "\033[48;2;247;147;26m "
        fi
    done

    # Sidebar text
    move_cursor $((menu_row + 14)) $((menu_col + 1))
    echo -ne "\033[48;2;247;147;26m${TEXT_PRIMARY}${BOLD}B${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 13)) $((menu_col + 1))
    echo -ne "\033[48;2;247;147;26m${TEXT_PRIMARY}${BOLD}l${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 12)) $((menu_col + 1))
    echo -ne "\033[48;2;233;30;140m${TEXT_PRIMARY}${BOLD}a${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 11)) $((menu_col + 1))
    echo -ne "\033[48;2;233;30;140m${TEXT_PRIMARY}${BOLD}c${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 10)) $((menu_col + 1))
    echo -ne "\033[48;2;233;30;140m${TEXT_PRIMARY}${BOLD}k${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 9)) $((menu_col + 1))
    echo -ne "\033[48;2;153;69;255m${TEXT_PRIMARY}${BOLD}R${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 8)) $((menu_col + 1))
    echo -ne "\033[48;2;153;69;255m${TEXT_PRIMARY}${BOLD}o${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 7)) $((menu_col + 1))
    echo -ne "\033[48;2;153;69;255m${TEXT_PRIMARY}${BOLD}a${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 6)) $((menu_col + 1))
    echo -ne "\033[48;2;153;69;255m${TEXT_PRIMARY}${BOLD}d${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 5)) $((menu_col + 1))
    echo -ne "\033[48;2;153;69;255m${TEXT_PRIMARY}${BOLD}9${RESET}${TEAL_BG}"
    move_cursor $((menu_row + 4)) $((menu_col + 1))
    echo -ne "\033[48;2;153;69;255m${TEXT_PRIMARY}${BOLD}5${RESET}${TEAL_BG}"

    # Menu items
    local items=("📁 Programs ▸" "📄 Documents ▸" "⚙️  Settings ▸" "🔍 Find ▸" "❓ Help" "▶️  Run...")
    for ((i=0; i<6; i++)); do
        move_cursor $((menu_row + i)) $((menu_col + 3))
        echo -ne "${WIN_GRAY}${WIN_BLACK} ${items[$i]}                ${RESET}${TEAL_BG}"
    done

    # Divider
    move_cursor $((menu_row + 6)) $((menu_col + 3))
    echo -ne "${WIN_GRAY}${TEXT_MUTED}"
    printf "─%.0s" $(seq 1 26)
    echo -ne "${RESET}${TEAL_BG}"

    # BlackRoad items
    local br_items=("🤖 Agent Manager" "📟 Lucidia Terminal" "🧠 Lucidia Core")
    for ((i=0; i<3; i++)); do
        move_cursor $((menu_row + 7 + i)) $((menu_col + 3))
        echo -ne "${WIN_GRAY}${WIN_BLACK} ${br_items[$i]}           ${RESET}${TEAL_BG}"
    done

    # Bottom divider
    move_cursor $((menu_row + 10)) $((menu_col + 3))
    echo -ne "${WIN_GRAY}${TEXT_MUTED}"
    printf "─%.0s" $(seq 1 26)
    echo -ne "${RESET}${TEAL_BG}"

    # Shutdown
    move_cursor $((menu_row + 11)) $((menu_col + 3))
    echo -ne "${WIN_GRAY}${WIN_BLACK} 🔌 Shut Down...          ${RESET}${TEAL_BG}"
}

# Main render loop
main_screen() {
    draw_desktop
    show_agent_manager
    show_terminal
    show_progress
    # show_properties
    # show_start_menu
    draw_taskbar

    # Position cursor off-screen
    move_cursor $(tput lines) $(tput cols)
}

# Interactive mode
interactive() {
    local menu_open=false

    while true; do
        main_screen

        if [ "$menu_open" = true ]; then
            show_start_menu
        fi

        # Read user input
        read -t 5 -n 1 key

        case $key in
            s|S)
                play_click
                if [ "$menu_open" = true ]; then
                    menu_open=false
                else
                    menu_open=true
                fi
                ;;
            q|Q)
                break
                ;;
            p|P)
                show_properties
                sleep 3
                ;;
        esac
    done
}

# Shutdown sequence
shutdown_sequence() {
    clear_screen
    echo -ne "${WIN_BLUE}${TEXT_PRIMARY}"
    clear

    move_cursor 12 25
    echo -e "${BOLD}It's now safe to turn off"
    move_cursor 13 25
    echo -e "your computer.${RESET}"

    move_cursor 16 30
    echo -e "${ORANGE}👻${RESET}${WIN_BLUE}"

    sleep 2
    clear
    show_cursor
}

# Trap cleanup
cleanup() {
    show_cursor
    clear
}

trap cleanup EXIT

# Main execution
if [ "$1" = "--boot" ] || [ "$1" = "-b" ]; then
    boot_sequence
    main_screen
    move_cursor $(tput lines) 0
    echo ""
    show_cursor
elif [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    boot_sequence
    interactive
    shutdown_sequence
else
    main_screen
    move_cursor $(tput lines) 0
    echo ""
    echo -e "${TEXT_MUTED}Tip: ${RESET}${BOLD}./blackroad-os95.sh --boot${RESET}${TEXT_MUTED} for boot sequence${RESET}"
    echo -e "${TEXT_MUTED}     ${RESET}${BOLD}./blackroad-os95.sh --watch${RESET}${TEXT_MUTED} for interactive mode${RESET}"
    echo ""
    show_cursor
fi
