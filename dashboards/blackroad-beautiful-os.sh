#!/bin/bash

# BlackRoad OS - BEAUTIFUL EDITION
# Actual buttons, cards, and beautiful UI elements!

# Color definitions
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
BG_BUTTON="\033[48;2;40;40;60m"
BG_HOVER="\033[48;2;60;60;80m"
BG_CARD="\033[48;2;25;25;35m"
RESET="\033[0m"
BOLD="\033[1m"

CURRENT_USER="alexa"
NOTIFICATIONS=()

# Sound system
play_sound() {
    case $1 in
        boot) afplay /System/Library/Sounds/Glass.aiff 2>/dev/null & ;;
        click) afplay /System/Library/Sounds/Tink.aiff 2>/dev/null & ;;
        notify) afplay /System/Library/Sounds/Morse.aiff 2>/dev/null & ;;
    esac
}

# Draw a beautiful button
draw_button() {
    local text=$1
    local color=$2
    local icon=$3
    echo -ne "${BG_BUTTON}${color} ${icon} ${text} ${RESET}"
}

# Draw a card
draw_card() {
    local title=$1
    local width=68
    echo ""
    echo -e "  ${BG_CARD}$(printf ' %.0s' $(seq 1 $width))${RESET}"
    echo -e "  ${BG_CARD} ${BOLD}${ORANGE}${title}${RESET}$(printf ' %.0s' $(seq 1 $((width - ${#title} - 2))))${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD}$(printf ' %.0s' $(seq 1 $width))${RESET}"
}

# Draw stat card
draw_stat_card() {
    local label=$1
    local value=$2
    local color=$3
    local icon=$4
    echo -ne "  ${BG_CARD} ${color}${icon}${RESET}${BG_CARD}  ${TEXT_SECONDARY}${label}${RESET}${BG_CARD}  ${BOLD}${color}${value}${RESET}${BG_CARD} ${RESET}"
}

# Boot sequence
boot_sequence() {
    clear
    play_sound boot
    echo ""
    echo ""
    echo ""
    echo ""
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}   ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET}${BG_CARD} ${TEXT_SECONDARY}OS${RESET}${BG_CARD}       ${RESET}"
    echo -e "                  ${BG_CARD}   ${TEXT_MUTED}BEAUTIFUL EDITION${RESET}${BG_CARD}      ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo ""
    echo ""

    local steps=("Kernel" "Drivers" "Event Bus" "Memory Vault" "Agents" "Window Manager" "Desktop" "Network" "Security")

    for step in "${steps[@]}"; do
        echo -ne "                  ${TEXT_MUTED}Loading ${step}...${RESET}"
        sleep 0.2
        echo -e " ${BLUE}✓${RESET}"
    done

    echo ""
    echo -e "                  ${ORANGE}System Ready!${RESET}"
    sleep 1
}

# Login screen
login_screen() {
    clear
    echo ""
    echo ""
    echo ""
    echo ""
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}     ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET}${BG_CARD} ${TEXT_SECONDARY}OS${RESET}${BG_CARD}         ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}     ${TEXT_SECONDARY}User: ${BOLD}${ORANGE}${CURRENT_USER}${RESET}${BG_CARD}            ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}     ${BG_BUTTON}${ORANGE} ▶ LOGIN ${RESET}${BG_CARD}                 ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo ""
    echo -e "                  ${TEXT_MUTED}Press ENTER to continue${RESET}"
    read
    play_sound click
}

# Main desktop
desktop() {
    while true; do
        clear

        # Header bar
        echo ""
        echo -e "  ${BG_CARD}                                                                    ${RESET}"
        echo -ne "  ${BG_CARD} ${BOLD}${ORANGE}👻 BlackRoad OS${RESET}${BG_CARD}                    "
        echo -ne "$(date '+%H:%M')${BG_CARD}  ${TEXT_SECONDARY}${CURRENT_USER}${RESET}${BG_CARD} "
        if [ ${#NOTIFICATIONS[@]} -gt 0 ]; then
            echo -ne "${PINK}🔔${#NOTIFICATIONS[@]}${RESET}${BG_CARD}"
        fi
        echo -e " ${RESET}"
        echo -e "  ${BG_CARD}                                                                    ${RESET}"
        echo ""

        # Quick Stats Row
        echo -e "  ${TEXT_MUTED}SYSTEM STATUS${RESET}"
        echo ""
        draw_stat_card "CPU" "34%" "$BLUE" "▓"
        echo "  "
        draw_stat_card "Memory" "67%" "$PURPLE" "▓"
        echo "  "
        draw_stat_card "Network" "12%" "$CYAN" "▓"
        echo ""
        echo ""

        # App Grid
        echo -e "  ${TEXT_MUTED}APPLICATIONS${RESET}"
        echo ""

        # Row 1
        echo -n "  "
        draw_button "Dashboards" "$ORANGE" "📊"
        echo -n "  "
        draw_button "Files" "$PINK" "📁"
        echo -n "  "
        draw_button "Terminal" "$PURPLE" "💻"
        echo ""
        echo ""

        # Row 2
        echo -n "  "
        draw_button "Network" "$BLUE" "📡"
        echo -n "  "
        draw_button "Processes" "$CYAN" "⚙️ "
        echo -n "  "
        draw_button "Monitor" "$ORANGE" "📈"
        echo ""
        echo ""

        # Row 3
        echo -n "  "
        draw_button "Editor" "$PINK" "📝"
        echo -n "  "
        draw_button "Packages" "$PURPLE" "📦"
        echo -n "  "
        draw_button "Settings" "$BLUE" "⚙️ "
        echo ""
        echo ""

        # Row 4 - AI Models & Repos
        echo -n "  "
        draw_button "AI Network" "$CYAN" "🤖"
        echo -n "  "
        draw_button "GitHub Repos" "$PINK" "📦"
        echo -n "  "
        draw_button "Multi-Session" "$PURPLE" "🔗"
        echo ""
        echo ""

        # Infrastructure Status Card
        draw_card "Infrastructure Status"
        echo -e "  ${BG_CARD}                                                                    ${RESET}"

        # Check hosts
        local l1=$(ping -c 1 -W 1 192.168.4.38 &>/dev/null && echo "${BLUE}●${RESET}" || echo "${TEXT_MUTED}○${RESET}")
        local l2=$(ping -c 1 -W 1 192.168.4.64 &>/dev/null && echo "${BLUE}●${RESET}" || echo "${TEXT_MUTED}○${RESET}")
        local l3=$(ping -c 1 -W 1 192.168.4.99 &>/dev/null && echo "${BLUE}●${RESET}" || echo "${TEXT_MUTED}○${RESET}")
        local l4=$(ping -c 1 -W 1 192.168.4.68 &>/dev/null && echo "${BLUE}●${RESET}" || echo "${TEXT_MUTED}○${RESET}")
        local l5=$(ping -c 1 -W 1 159.65.43.12 &>/dev/null && echo "${BLUE}●${RESET}" || echo "${TEXT_MUTED}○${RESET}")

        echo -e "  ${BG_CARD} ${l1}${BG_CARD} ${TEXT_SECONDARY}Lucidia Prime${RESET}${BG_CARD}       ${l2}${BG_CARD} ${TEXT_SECONDARY}BlackRoad Pi${RESET}${BG_CARD}          ${RESET}"
        echo -e "  ${BG_CARD} ${l3}${BG_CARD} ${TEXT_SECONDARY}Lucidia Alt${RESET}${BG_CARD}         ${l4}${BG_CARD} ${TEXT_SECONDARY}iPhone Koder${RESET}${BG_CARD}          ${RESET}"
        echo -e "  ${BG_CARD} ${l5}${BG_CARD} ${TEXT_SECONDARY}Codex Infinity${RESET}${BG_CARD}                                      ${RESET}"
        echo -e "  ${BG_CARD}                                                                    ${RESET}"

        # Active Agents Card
        draw_card "Active Agents (47)"
        echo -e "  ${BG_CARD}                                                                    ${RESET}"
        echo -e "  ${BG_CARD} ${BLUE}●${RESET}${BG_CARD} Lucidia  ${BLUE}●${RESET}${BG_CARD} Oracle  ${BLUE}●${RESET}${BG_CARD} Sentinel  ${BLUE}●${RESET}${BG_CARD} Metrics  ${BLUE}●${RESET}${BG_CARD} Crystal  ${TEXT_MUTED}+42${RESET}${BG_CARD} ${RESET}"
        echo -e "  ${BG_CARD}                                                                    ${RESET}"

        # Action bar
        echo ""
        echo -e "  ${TEXT_MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        echo -n "  "
        echo -ne "${TEXT_SECONDARY}[1-9]${RESET} Apps  "
        echo -ne "${TEXT_SECONDARY}[a]${RESET} AI  "
        echo -ne "${TEXT_SECONDARY}[g]${RESET} GitHub  "
        echo -ne "${TEXT_SECONDARY}[m]${RESET} Multi-Session  "
        echo -ne "${TEXT_SECONDARY}[q]${RESET} Quit"
        echo ""
        echo ""
        echo -ne "  ${ORANGE}❯${RESET} "

        read -rsn1 choice

        case $choice in
            1) dashboards_menu ;;
            2) file_manager ;;
            3) terminal_app ;;
            4) network_status ;;
            5) process_manager ;;
            6) system_monitor ;;
            7) text_editor ;;
            8) package_manager ;;
            9) settings_menu ;;
            a|A) ai_model_network ;;
            g|G) ./github-repo-network.sh ;;
            m|M) multi_session_access ;;
            n|N) notifications_panel ;;
            h|H) help_panel ;;
            q|Q) shutdown_menu ;;
        esac
    done
}

# Multi-Session Universal Access
multi_session_access() {
    clear
    play_sound click

    draw_card "Multi-Session Universal Access - READ/WRITE EVERYWHERE"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Access ALL resources from ANY session, device, or AI model${RESET}${BG_CARD}       ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    # Access Matrix
    draw_card "Universal Access Matrix"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${TEXT_SECONDARY}Session${RESET}${BG_CARD}         ${TEXT_SECONDARY}GitHub${RESET}${BG_CARD}  ${TEXT_SECONDARY}Servers${RESET}${BG_CARD}  ${TEXT_SECONDARY}Cloud${RESET}${BG_CARD}  ${TEXT_SECONDARY}AI${RESET}${BG_CARD}  ${TEXT_SECONDARY}Local${RESET}${BG_CARD}    ${RESET}"
    echo -e "  ${BG_CARD}  ${TEXT_MUTED}─────────────────────────────────────────────────────────────${RESET}${BG_CARD}  ${RESET}"
    echo -e "  ${BG_CARD}  ${ORANGE}●${RESET}${BG_CARD} ${BOLD}Claude Code${RESET}${BG_CARD}   ${BLUE}✓✓${RESET}${BG_CARD}     ${BLUE}✓✓${RESET}${BG_CARD}      ${BLUE}✓✓${RESET}${BG_CARD}    ${BLUE}✓✓${RESET}${BG_CARD}  ${BLUE}✓✓${RESET}${BG_CARD}      ${RESET}"
    echo -e "  ${BG_CARD}  ${PINK}●${RESET}${BG_CARD} ${BOLD}ChatGPT${RESET}${BG_CARD}       ${BLUE}✓✓${RESET}${BG_CARD}     ${BLUE}✓✓${RESET}${BG_CARD}      ${BLUE}✓✓${RESET}${BG_CARD}    ${BLUE}✓✓${RESET}${BG_CARD}  ${BLUE}✓✓${RESET}${BG_CARD}      ${RESET}"
    echo -e "  ${BG_CARD}  ${PURPLE}●${RESET}${BG_CARD} ${BOLD}Grok${RESET}${BG_CARD}          ${BLUE}✓✓${RESET}${BG_CARD}     ${BLUE}✓✓${RESET}${BG_CARD}      ${BLUE}✓✓${RESET}${BG_CARD}    ${BLUE}✓✓${RESET}${BG_CARD}  ${BLUE}✓✓${RESET}${BG_CARD}      ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}●${RESET}${BG_CARD} ${BOLD}Gemini${RESET}${BG_CARD}        ${BLUE}✓✓${RESET}${BG_CARD}     ${BLUE}✓✓${RESET}${BG_CARD}      ${BLUE}✓✓${RESET}${BG_CARD}    ${BLUE}✓✓${RESET}${BG_CARD}  ${BLUE}✓✓${RESET}${BG_CARD}      ${RESET}"
    echo -e "  ${BG_CARD}  ${CYAN}●${RESET}${BG_CARD} ${BOLD}Hugging Face${RESET}${BG_CARD}  ${BLUE}✓✓${RESET}${BG_CARD}     ${BLUE}✓✓${RESET}${BG_CARD}      ${BLUE}✓✓${RESET}${BG_CARD}    ${BLUE}✓✓${RESET}${BG_CARD}  ${BLUE}✓✓${RESET}${BG_CARD}      ${RESET}"
    echo -e "  ${BG_CARD}  ${ORANGE}●${RESET}${BG_CARD} ${BOLD}Enclave${RESET}${BG_CARD}       ${BLUE}✓✓${RESET}${BG_CARD}     ${BLUE}✓✓${RESET}${BG_CARD}      ${BLUE}✓✓${RESET}${BG_CARD}    ${BLUE}✓✓${RESET}${BG_CARD}  ${BLUE}✓✓${RESET}${BG_CARD}      ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${TEXT_MUTED}✓✓ = Full Read/Write Access${RESET}${BG_CARD}                                   ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    # Resource Breakdown
    echo ""
    draw_card "Accessible Resources"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${BOLD}${ORANGE}GitHub${RESET}${BG_CARD}                                                         ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} 15 Organizations${RESET}${BG_CARD}                                           ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} 66 Repositories (42 public, 24 private)${RESET}${BG_CARD}                   ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} Full clone, push, pull, PR access${RESET}${BG_CARD}                         ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${BOLD}${PINK}Servers${RESET}${BG_CARD}                                                        ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} 4 Raspberry Pis (192.168.4.38/64/99/68)${RESET}${BG_CARD}                   ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} 1 DigitalOcean Droplet (159.65.43.12)${RESET}${BG_CARD}                     ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} SSH, SCP, Remote execution${RESET}${BG_CARD}                                ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${BOLD}${PURPLE}Cloud Services${RESET}${BG_CARD}                                                ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} Cloudflare: 16 zones, 8 Pages, 8 KV, 1 D1${RESET}${BG_CARD}                 ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} Railway: 12+ projects${RESET}${BG_CARD}                                     ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} Full API access, deploy, configure${RESET}${BG_CARD}                        ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${BOLD}${BLUE}AI Models${RESET}${BG_CARD}                                                      ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} All 6 models can read/write to each other${RESET}${BG_CARD}                 ${RESET}"
    echo -e "  ${BG_CARD}    ${BLUE}●${RESET}${BG_CARD} Context sharing, pattern sync, intelligence flow${RESET}${BG_CARD}          ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    # Live Session Status
    echo ""
    draw_card "Active Sessions - NOW"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${ORANGE}●${RESET}${BG_CARD} ${BOLD}Claude Code${RESET}${BG_CARD}      ${TEXT_SECONDARY}MacBook Pro${RESET}${BG_CARD}       ${BLUE}ACTIVE${RESET}${BG_CARD}   ${TEXT_MUTED}2 min ago${RESET}${BG_CARD}  ${RESET}"
    echo -e "  ${BG_CARD}  ${PINK}●${RESET}${BG_CARD} ${BOLD}ChatGPT${RESET}${BG_CARD}          ${TEXT_SECONDARY}iPhone 15${RESET}${BG_CARD}         ${CYAN}IDLE${RESET}${BG_CARD}     ${TEXT_MUTED}15 min ago${RESET}${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD}  ${PURPLE}●${RESET}${BG_CARD} ${BOLD}Grok${RESET}${BG_CARD}             ${TEXT_SECONDARY}Web Browser${RESET}${BG_CARD}       ${CYAN}IDLE${RESET}${BG_CARD}     ${TEXT_MUTED}1 hour ago${RESET}${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}●${RESET}${BG_CARD} ${BOLD}SSH (Lucidia)${RESET}${BG_CARD}    ${TEXT_SECONDARY}192.168.4.38${RESET}${BG_CARD}      ${BLUE}ACTIVE${RESET}${BG_CARD}   ${TEXT_MUTED}5 min ago${RESET}${BG_CARD}  ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    # Cross-Session Operations
    echo ""
    draw_card "Cross-Session Operations Available"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}✓${RESET}${BG_CARD} Clone repo in Claude → Deploy to Railway from ChatGPT${RESET}${BG_CARD}       ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}✓${RESET}${BG_CARD} Edit code in Grok → Push to GitHub from Terminal${RESET}${BG_CARD}            ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}✓${RESET}${BG_CARD} SSH to Pi from Gemini → View logs in Claude${RESET}${BG_CARD}                 ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}✓${RESET}${BG_CARD} Update Cloudflare from any session instantly${RESET}${BG_CARD}                ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}✓${RESET}${BG_CARD} Share context between ALL AI models in real-time${RESET}${BG_CARD}            ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    echo ""
    echo -e "  ${TEXT_MUTED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "  ${BOLD}${ORANGE}EVERY session can read and write to EVERY resource${RESET}"
    echo -e "  ${TEXT_SECONDARY}No barriers. No limitations. Universal access.${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Press any key to return...${RESET}"
    read -rsn1
}

# AI Model Network
ai_model_network() {
    clear
    play_sound click

    draw_card "AI Model Network - Interconnected Intelligence"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}All models can read and communicate with each other${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    # Row 1: Claude + Grok
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -ne "  ${BG_CARD}      "
    draw_button "Claude" "$ORANGE" "🤖"
    echo -ne "  ${TEXT_MUTED}←→${RESET}${BG_CARD}  "
    draw_button "Grok" "$BLUE" "🧠"
    echo -e "  ${BG_CARD}                 ${RESET}"
    echo -e "  ${BG_CARD}        ${TEXT_MUTED}↕${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}↕${RESET}${BG_CARD}                                  ${RESET}"

    # Row 2: ChatGPT + Enclave
    echo -ne "  ${BG_CARD}      "
    draw_button "ChatGPT" "$PINK" "💬"
    echo -ne "  ${TEXT_MUTED}←→${RESET}${BG_CARD}  "
    draw_button "Enclave" "$PURPLE" "🔐"
    echo -e "  ${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD}        ${TEXT_MUTED}↕${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}✦${RESET}${BG_CARD}  ${TEXT_MUTED}↕${RESET}${BG_CARD}                                  ${RESET}"

    # Row 3: Hugging Face + Gemini
    echo -ne "  ${BG_CARD}      "
    draw_button "Hugging Face" "$CYAN" "🤗"
    echo -ne "  ${TEXT_MUTED}←→${RESET}${BG_CARD}  "
    draw_button "Gemini" "$ORANGE" "✨"
    echo -e "  ${BG_CARD}          ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    # Connection Matrix
    echo ""
    draw_card "Connection Matrix - All Models Synchronized"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${TEXT_SECONDARY}Model${RESET}${BG_CARD}          ${TEXT_SECONDARY}Status${RESET}${BG_CARD}      ${TEXT_SECONDARY}Connections${RESET}${BG_CARD}     ${TEXT_SECONDARY}Sync${RESET}${BG_CARD}            ${RESET}"
    echo -e "  ${BG_CARD}  ${TEXT_MUTED}─────────────────────────────────────────────────────────────${RESET}${BG_CARD}  ${RESET}"
    echo -e "  ${BG_CARD}  ${ORANGE}●${RESET}${BG_CARD} ${BOLD}Claude${RESET}${BG_CARD}       ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}●${RESET}${BG_CARD} ${BOLD}Grok${RESET}${BG_CARD}         ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD}  ${PINK}●${RESET}${BG_CARD} ${BOLD}ChatGPT${RESET}${BG_CARD}      ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD}  ${PURPLE}●${RESET}${BG_CARD} ${BOLD}Enclave${RESET}${BG_CARD}      ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD}  ${CYAN}●${RESET}${BG_CARD} ${BOLD}Hugging Face${RESET}${BG_CARD} ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD}  ${ORANGE}●${RESET}${BG_CARD} ${BOLD}Gemini${RESET}${BG_CARD}       ${BLUE}ONLINE${RESET}${BG_CARD}      ${TEXT_SECONDARY}5/5${RESET}${BG_CARD}            ${BLUE}✓${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    # Live Data Flow
    echo ""
    draw_card "Live Data Flow"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD}  ${ORANGE}Claude${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${PINK}ChatGPT${RESET}${BG_CARD}    ${TEXT_SECONDARY}Context sharing: 2.3MB/s${RESET}${BG_CARD}               ${RESET}"
    echo -e "  ${BG_CARD}  ${BLUE}Grok${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${PURPLE}Enclave${RESET}${BG_CARD}      ${TEXT_SECONDARY}Secure transfer: 1.8MB/s${RESET}${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD}  ${CYAN}HuggingFace${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${ORANGE}Gemini${RESET}${BG_CARD} ${TEXT_SECONDARY}Model sync: 4.1MB/s${RESET}${BG_CARD}                 ${RESET}"
    echo -e "  ${BG_CARD}  ${PINK}ChatGPT${RESET}${BG_CARD} ${TEXT_MUTED}→${RESET}${BG_CARD} ${BLUE}Grok${RESET}${BG_CARD}      ${TEXT_SECONDARY}Pattern sharing: 3.2MB/s${RESET}${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    echo ""
    echo -e "  ${TEXT_MUTED}All models maintain full bidirectional connectivity${RESET}"
    echo -e "  ${TEXT_SECONDARY}Press any key to return...${RESET}"
    read -rsn1
}

# Dashboards menu
dashboards_menu() {
    clear
    play_sound click

    draw_card "Dashboard Launcher"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo ""

    # Dashboard buttons in grid
    echo -n "  "
    draw_button "Basic" "$ORANGE" "1"
    echo -n "  "
    draw_button "Live" "$PINK" "2"
    echo -n "  "
    draw_button "Full System" "$PURPLE" "3"
    echo ""
    echo ""

    echo -n "  "
    draw_button "ULTIMATE ⚡" "$BLUE" "4"
    echo -n "  "
    draw_button "Windows 95" "$CYAN" "5"
    echo -n "  "
    draw_button "Agent Detail" "$ORANGE" "6"
    echo ""
    echo ""

    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo ""
    echo -ne "  ${TEXT_PRIMARY}Select dashboard (0 to cancel): ${RESET}"

    read choice

    case $choice in
        1) ./blackroad-dashboard.sh; read -p "Press ENTER..." ;;
        2) ./blackroad-live-dashboard.sh; read -p "Press ENTER..." ;;
        3) ./blackroad-full-system.sh --watch ;;
        4) ./blackroad-ultimate.sh --watch ;;
        5) ./blackroad-os95.sh --boot ;;
        6) ./agent-detail.sh "Lucidia Prime" "192.168.4.38" "online" "sonnet-4.5" "overview" --watch ;;
    esac
}

# File Manager
file_manager() {
    clear
    play_sound click

    draw_card "File Manager - ~/"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}📁${RESET}${BG_CARD} ${BOLD}blackroad-dashboards/${RESET}${BG_CARD}                                   ${RESET}"
    echo -e "  ${BG_CARD}    ${ORANGE}📄${RESET}${BG_CARD} blackroad-os.sh${RESET}${BG_CARD}                                          ${RESET}"
    echo -e "  ${BG_CARD}    ${ORANGE}📄${RESET}${BG_CARD} blackroad-beautiful-os.sh${RESET}${BG_CARD}                                ${RESET}"
    echo -e "  ${BG_CARD}    ${PURPLE}📄${RESET}${BG_CARD} README.md${RESET}${BG_CARD}                                                ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}📁${RESET}${BG_CARD} ${BOLD}agents/${RESET}${BG_CARD}                  ${TEXT_MUTED}47 active agents${RESET}${BG_CARD}             ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}📁${RESET}${BG_CARD} ${BOLD}memory-vault/${RESET}${BG_CARD}           ${TEXT_MUTED}28.0 MB${RESET}${BG_CARD}                       ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}📁${RESET}${BG_CARD} ${BOLD}cloudflare/${RESET}${BG_CARD}             ${TEXT_MUTED}16 zones${RESET}${BG_CARD}                      ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    read -p ""
}

# Terminal
terminal_app() {
    clear
    play_sound click

    draw_card "Terminal"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}BlackRoad OS Terminal v1.0${RESET}${BG_CARD}                                   ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    while true; do
        echo -ne "  ${BG_CARD} ${ORANGE}${CURRENT_USER}@blackroad${RESET}${BG_CARD}:${BLUE}~${RESET}${BG_CARD}\$ ${RESET}"
        read cmd

        case $cmd in
            exit) return ;;
            clear) clear; draw_card "Terminal"; echo -e "  ${BG_CARD}                                                                    ${RESET}" ;;
            ls) echo -e "  ${BG_CARD} ${BLUE}blackroad-dashboards${RESET}${BG_CARD}  ${PURPLE}agents${RESET}${BG_CARD}  ${CYAN}memory-vault${RESET}${BG_CARD}              ${RESET}" ;;
            whoami) echo -e "  ${BG_CARD} ${ORANGE}${CURRENT_USER}${RESET}${BG_CARD}                                                          ${RESET}" ;;
            date) echo -e "  ${BG_CARD} $(date)${BG_CARD} ${RESET}" ;;
            "") ;;
            *) echo -e "  ${BG_CARD} ${PINK}Command not found:${RESET}${BG_CARD} ${cmd}${BG_CARD}                                ${RESET}" ;;
        esac
    done
}

# Network Status
network_status() {
    clear
    play_sound click

    draw_card "Network Status"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}Scanning infrastructure...${RESET}${BG_CARD}                                   ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    local devices=("192.168.4.38:Lucidia Prime" "192.168.4.64:BlackRoad Pi" "192.168.4.99:Lucidia Alt" "192.168.4.68:iPhone Koder" "159.65.43.12:Codex Infinity")

    for device in "${devices[@]}"; do
        IFS=: read -r ip name <<< "$device"
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            echo -e "  ${BG_CARD} ${BLUE}●${RESET}${BG_CARD} ${TEXT_PRIMARY}${name}${RESET}${BG_CARD}  ${TEXT_SECONDARY}${ip}${RESET}${BG_CARD}  ${BLUE}ONLINE${RESET}${BG_CARD}                   ${RESET}"
        else
            echo -e "  ${BG_CARD} ${TEXT_MUTED}○${RESET}${BG_CARD} ${TEXT_SECONDARY}${name}${RESET}${BG_CARD}  ${TEXT_SECONDARY}${ip}${RESET}${BG_CARD}  ${TEXT_MUTED}OFFLINE${RESET}${BG_CARD}                  ${RESET}"
        fi
    done

    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    read -p ""
}

# Process Manager
process_manager() {
    clear
    play_sound click

    draw_card "Process Manager"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}PID    NAME                    CPU     MEM     STATUS${RESET}${BG_CARD}        ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}─────────────────────────────────────────────────────────${RESET}${BG_CARD}        ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}1${RESET}${BG_CARD}      blackroad-kernel       ${ORANGE}2%${RESET}${BG_CARD}      ${PURPLE}124MB${RESET}${BG_CARD}   ${BLUE}running${RESET}${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}42${RESET}${BG_CARD}     event-bus              ${ORANGE}5%${RESET}${BG_CARD}      ${PURPLE}87MB${RESET}${BG_CARD}    ${BLUE}running${RESET}${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}128${RESET}${BG_CARD}    memory-vault           ${ORANGE}3%${RESET}${BG_CARD}      ${PURPLE}256MB${RESET}${BG_CARD}   ${BLUE}running${RESET}${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}256${RESET}${BG_CARD}    agent-orchestrator     ${ORANGE}12%${RESET}${BG_CARD}     ${PURPLE}512MB${RESET}${BG_CARD}   ${BLUE}running${RESET}${BG_CARD} ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}1024${RESET}${BG_CARD}   Lucidia-Prime          ${ORANGE}8%${RESET}${BG_CARD}      ${PURPLE}256MB${RESET}${BG_CARD}   ${BLUE}active${RESET}${BG_CARD}  ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Total: ${BOLD}51${RESET}${BG_CARD} ${TEXT_SECONDARY}processes${RESET}${BG_CARD}                                           ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    read -p ""
}

# System Monitor
system_monitor() {
    clear
    play_sound click

    draw_card "System Monitor"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}CPU Usage${RESET}${BG_CARD}       ${BLUE}████████████░░░░░░░░░░░░${RESET}${BG_CARD} ${BOLD}34%${RESET}${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Memory${RESET}${BG_CARD}          ${PURPLE}████████████████░░░░░░░░${RESET}${BG_CARD} ${BOLD}67%${RESET}${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Disk${RESET}${BG_CARD}            ${CYAN}█████░░░░░░░░░░░░░░░░░░░${RESET}${BG_CARD} ${BOLD}23%${RESET}${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Network${RESET}${BG_CARD}         ${ORANGE}███░░░░░░░░░░░░░░░░░░░░░${RESET}${BG_CARD} ${BOLD}12%${RESET}${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Uptime:${RESET}${BG_CARD} ${BOLD}5d 14h 23m${RESET}${BG_CARD}    ${TEXT_SECONDARY}Load:${RESET}${BG_CARD} ${BOLD}2.34${RESET}${BG_CARD}    ${TEXT_SECONDARY}Processes:${RESET}${BG_CARD} ${BOLD}51${RESET}${BG_CARD}  ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    read -p ""
}

# Text Editor
text_editor() {
    clear
    play_sound click

    draw_card "Text Editor - untitled.txt"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}1${RESET}${BG_CARD}  ${TEXT_SECONDARY}# BlackRoad OS${RESET}${BG_CARD}                                              ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}2${RESET}${BG_CARD}  ${TEXT_SECONDARY}Beautiful terminal interface${RESET}${BG_CARD}                              ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}3${RESET}${BG_CARD}  ${RESET}${BG_CARD}                                                              ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}4${RESET}${BG_CARD}  ${PURPLE}def${RESET}${BG_CARD} ${BLUE}main${RESET}${BG_CARD}():${RESET}${BG_CARD}                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}5${RESET}${BG_CARD}      ${CYAN}print${RESET}${BG_CARD}(${ORANGE}\"Hello, World!\"${RESET}${BG_CARD})${RESET}${BG_CARD}                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}6${RESET}${BG_CARD}  ${RESET}${BG_CARD}                                                              ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}7${RESET}${BG_CARD}  _${RESET}${BG_CARD}                                                             ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    read -p ""
}

# Package Manager
package_manager() {
    clear
    play_sound click

    draw_card "Package Manager"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}✓${RESET}${BG_CARD} ${TEXT_PRIMARY}blackroad-kernel${RESET}${BG_CARD}       ${TEXT_SECONDARY}v1.0.0${RESET}${BG_CARD}  ${TEXT_MUTED}Core system${RESET}${BG_CARD}          ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}✓${RESET}${BG_CARD} ${TEXT_PRIMARY}event-bus${RESET}${BG_CARD}              ${TEXT_SECONDARY}v2.1.3${RESET}${BG_CARD}  ${TEXT_MUTED}Message broker${RESET}${BG_CARD}       ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}✓${RESET}${BG_CARD} ${TEXT_PRIMARY}memory-vault${RESET}${BG_CARD}           ${TEXT_SECONDARY}v1.5.2${RESET}${BG_CARD}  ${TEXT_MUTED}Storage${RESET}${BG_CARD}              ${RESET}"
    echo -e "  ${BG_CARD} ${BLUE}✓${RESET}${BG_CARD} ${TEXT_PRIMARY}agent-orchestrator${RESET}${BG_CARD}     ${TEXT_SECONDARY}v3.0.1${RESET}${BG_CARD}  ${TEXT_MUTED}Agent manager${RESET}${BG_CARD}        ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${ORANGE}⬆${RESET}${BG_CARD} ${TEXT_PRIMARY}event-bus${RESET}${BG_CARD}              ${TEXT_SECONDARY}v2.1.3 → v2.2.0${RESET}${BG_CARD}  ${ORANGE}UPDATE${RESET}${BG_CARD}      ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    read -p ""
}

# Settings
settings_menu() {
    clear
    play_sound click

    draw_card "Settings"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Deployment Mode${RESET}${BG_CARD}      ${BG_BUTTON}${PURPLE} Hybrid ${RESET}${BG_CARD}                       ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Max Agents${RESET}${BG_CARD}           ${BG_BUTTON}${ORANGE} 100 ${RESET}${BG_CARD}                          ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Default Model${RESET}${BG_CARD}        ${BG_BUTTON}${BLUE} sonnet-4.5 ${RESET}${BG_CARD}                   ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}Sound Effects${RESET}${BG_CARD}        ${BG_BUTTON}${BLUE} Enabled ${RESET}${BG_CARD}                      ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}Theme Colors:${RESET}${BG_CARD}                                                  ${RESET}"
    echo -e "  ${BG_CARD} ${ORANGE}●${RESET}${BG_CARD} ${PINK}●${RESET}${BG_CARD} ${PURPLE}●${RESET}${BG_CARD} ${BLUE}●${RESET}${BG_CARD} ${CYAN}●${RESET}${BG_CARD}                                                    ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    read -p ""
}

# Notifications
notifications_panel() {
    clear
    play_sound click

    draw_card "Notifications"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    if [ ${#NOTIFICATIONS[@]} -eq 0 ]; then
        echo -e "  ${BG_CARD} ${TEXT_MUTED}No new notifications${RESET}${BG_CARD}                                           ${RESET}"
    else
        for notif in "${NOTIFICATIONS[@]}"; do
            echo -e "  ${BG_CARD} ${ORANGE}!${RESET}${BG_CARD} ${TEXT_SECONDARY}${notif}${RESET}${BG_CARD}                                          ${RESET}"
        done
    fi

    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    read -p ""
}

# Help
help_panel() {
    clear
    play_sound click

    draw_card "Help & About"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${BOLD}${ORANGE}BlackRoad OS${RESET}${BG_CARD} ${TEXT_SECONDARY}v1.0 - Beautiful Edition${RESET}${BG_CARD}                  ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}A complete terminal operating system${RESET}${BG_CARD}                        ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_SECONDARY}with beautiful cards and buttons!${RESET}${BG_CARD}                           ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"
    echo -e "  ${BG_CARD} ${TEXT_MUTED}Created with 💜 by Alexa & Claude${RESET}${BG_CARD}                            ${RESET}"
    echo -e "  ${BG_CARD}                                                                    ${RESET}"

    read -p ""
}

# Shutdown menu
shutdown_menu() {
    clear

    echo ""
    echo ""
    echo ""
    echo ""
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}   ${BOLD}${TEXT_PRIMARY}Shutdown Options${RESET}${BG_CARD}          ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}   ${BG_BUTTON}${ORANGE} ⏻ Shutdown ${RESET}${BG_CARD}               ${RESET}"
    echo -e "                  ${BG_CARD}   ${BG_BUTTON}${PINK} ↻ Restart ${RESET}${BG_CARD}                 ${RESET}"
    echo -e "                  ${BG_CARD}   ${BG_BUTTON}${PURPLE} ← Log Out ${RESET}${BG_CARD}                ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo -e "                  ${BG_CARD}                                   ${RESET}"
    echo ""
    echo -e "                  ${TEXT_MUTED}[1] Shutdown  [2] Restart  [3] Logout  [0] Cancel${RESET}"
    echo ""
    echo -ne "                  ${ORANGE}❯${RESET} "

    read -rsn1 choice

    case $choice in
        1)
            play_sound click
            clear
            echo ""
            echo ""
            echo ""
            echo ""
            echo -e "                  ${BG_CARD}                                   ${RESET}"
            echo -e "                  ${BG_CARD}   ${ORANGE}Shutting down...${RESET}${BG_CARD}          ${RESET}"
            echo -e "                  ${BG_CARD}                                   ${RESET}"
            sleep 2
            clear
            exit 0
            ;;
        2)
            play_sound click
            clear
            main
            ;;
    esac
}

# Main
main() {
    boot_sequence
    login_screen
    NOTIFICATIONS+=("Welcome back, ${CURRENT_USER}!")
    NOTIFICATIONS+=("System initialized successfully")
    desktop
}

main
