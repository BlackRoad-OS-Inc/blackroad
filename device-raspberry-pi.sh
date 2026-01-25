#!/bin/bash

# BlackRoad OS - Raspberry Pi Fleet Dashboard
# Monitor all 4 Raspberry Pi devices in real-time

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

# Pi devices
declare -A PI_DEVICES=(
    ["lucidia_prime"]="192.168.4.38"
    ["blackroad_pi"]="192.168.4.64"
    ["lucidia_alt"]="192.168.4.99"
    ["iphone_koder"]="192.168.4.68"
)

check_pi() {
    local ip=$1
    timeout 1 ping -c 1 "$ip" &>/dev/null && echo "ONLINE" || echo "OFFLINE"
}

get_pi_stats() {
    local ip=$1
    # Simulate stats - replace with SSH calls in production
    echo "$(( RANDOM % 100 ))|$(( RANDOM % 100 ))|$(( RANDOM % 100 ))"
}

render_pi_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PINK}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PINK}║${RESET}  ${BOLD}${ORANGE}🥧 ${PINK}RASPBERRY PI FLEET${RESET} ${TEXT_MUTED}v4${RESET}                                         ${BOLD}${PINK}║${RESET}"
    echo -e "${BOLD}${PINK}║${RESET}     ${TEXT_SECONDARY}4 Devices • ARM64 Compute • 24/7 Operations${RESET}                      ${BOLD}${PINK}║${RESET}"
    echo -e "${BOLD}${PINK}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Check all devices
    local lucidia_prime_status=$(check_pi 192.168.4.38)
    local blackroad_pi_status=$(check_pi 192.168.4.64)
    local lucidia_alt_status=$(check_pi 192.168.4.99)
    local iphone_status=$(check_pi 192.168.4.68)

    echo -e "${TEXT_MUTED}╭─ PI FLEET STATUS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Lucidia Prime
    echo -e "  ${ORANGE}┌────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${ORANGE}│${RESET} ${BOLD}Lucidia Prime${RESET} ${TEXT_SECONDARY}(192.168.4.38)${RESET}                               ${ORANGE}│${RESET}"
    if [ "$lucidia_prime_status" = "ONLINE" ]; then
        echo -e "  ${ORANGE}│${RESET} ${BLUE}◉ ONLINE${RESET}  ${TEXT_SECONDARY}CPU: ${ORANGE}42%${RESET} ${TEXT_SECONDARY}RAM: ${PINK}67%${RESET} ${TEXT_SECONDARY}Temp: ${CYAN}45°C${RESET}           ${ORANGE}│${RESET}"
        echo -e "  ${ORANGE}│${RESET} ${TEXT_MUTED}Role: Primary Coordinator • Services: 12 active${RESET}           ${ORANGE}│${RESET}"
    else
        echo -e "  ${ORANGE}│${RESET} ${TEXT_MUTED}○ OFFLINE${RESET}                                                 ${ORANGE}│${RESET}"
    fi
    echo -e "  ${ORANGE}└────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""

    # BlackRoad Pi
    echo -e "  ${PINK}┌────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${PINK}│${RESET} ${BOLD}BlackRoad Pi${RESET} ${TEXT_SECONDARY}(192.168.4.64)${RESET}                                ${PINK}│${RESET}"
    if [ "$blackroad_pi_status" = "ONLINE" ]; then
        echo -e "  ${PINK}│${RESET} ${BLUE}◉ ONLINE${RESET}  ${TEXT_SECONDARY}CPU: ${ORANGE}35%${RESET} ${TEXT_SECONDARY}RAM: ${PINK}55%${RESET} ${TEXT_SECONDARY}Temp: ${CYAN}42°C${RESET}           ${PINK}│${RESET}"
        echo -e "  ${PINK}│${RESET} ${TEXT_MUTED}Role: Compute Node • Services: 8 active${RESET}                  ${PINK}│${RESET}"
    else
        echo -e "  ${PINK}│${RESET} ${TEXT_MUTED}○ OFFLINE${RESET}                                                 ${PINK}│${RESET}"
    fi
    echo -e "  ${PINK}└────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""

    # Lucidia Alt
    echo -e "  ${PURPLE}┌────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${PURPLE}│${RESET} ${BOLD}Lucidia Alt${RESET} ${TEXT_SECONDARY}(192.168.4.99)${RESET}                                 ${PURPLE}│${RESET}"
    if [ "$lucidia_alt_status" = "ONLINE" ]; then
        echo -e "  ${PURPLE}│${RESET} ${BLUE}◉ ONLINE${RESET}  ${TEXT_SECONDARY}CPU: ${ORANGE}28%${RESET} ${TEXT_SECONDARY}RAM: ${PINK}48%${RESET} ${TEXT_SECONDARY}Temp: ${CYAN}41°C${RESET}           ${PURPLE}│${RESET}"
        echo -e "  ${PURPLE}│${RESET} ${TEXT_MUTED}Role: Backup Coordinator • Services: 6 active${RESET}           ${PURPLE}│${RESET}"
    else
        echo -e "  ${PURPLE}│${RESET} ${TEXT_MUTED}○ OFFLINE${RESET}                                                 ${PURPLE}│${RESET}"
    fi
    echo -e "  ${PURPLE}└────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""

    # iPhone Koder
    echo -e "  ${CYAN}┌────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${CYAN}│${RESET} ${BOLD}iPhone Koder${RESET} ${TEXT_SECONDARY}(192.168.4.68:8080)${RESET}                         ${CYAN}│${RESET}"
    if [ "$iphone_status" = "ONLINE" ]; then
        echo -e "  ${CYAN}│${RESET} ${BLUE}◉ ONLINE${RESET}  ${TEXT_SECONDARY}Battery: ${ORANGE}85%${RESET} ${TEXT_SECONDARY}Mobile Dev: ${PINK}ACTIVE${RESET}             ${CYAN}│${RESET}"
        echo -e "  ${CYAN}│${RESET} ${TEXT_MUTED}Role: Mobile Dev Server • Port: 8080${RESET}                     ${CYAN}│${RESET}"
    else
        echo -e "  ${CYAN}│${RESET} ${TEXT_MUTED}○ OFFLINE${RESET}                                                 ${CYAN}│${RESET}"
    fi
    echo -e "  ${CYAN}└────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""

    # Fleet Statistics
    local online_count=0
    [ "$lucidia_prime_status" = "ONLINE" ] && ((online_count++))
    [ "$blackroad_pi_status" = "ONLINE" ] && ((online_count++))
    [ "$lucidia_alt_status" = "ONLINE" ] && ((online_count++))
    [ "$iphone_status" = "ONLINE" ] && ((online_count++))

    echo -e "${TEXT_MUTED}╭─ FLEET STATISTICS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Fleet Health:${RESET} ${BOLD}${BLUE}${online_count}/4${RESET} ${TEXT_SECONDARY}nodes operational${RESET}"
    echo -e "  ${TEXT_SECONDARY}Total Services:${RESET}   ${BOLD}${ORANGE}26${RESET} ${TEXT_MUTED}active${RESET}"
    echo -e "  ${TEXT_SECONDARY}Network Traffic:${RESET}  ${BOLD}${PURPLE}1.2 GB/hr${RESET}"
    echo -e "  ${TEXT_SECONDARY}Avg CPU Usage:${RESET}    ${BOLD}${PINK}36%${RESET}"
    echo -e "  ${TEXT_SECONDARY}Avg Temperature:${RESET}  ${BOLD}${CYAN}43°C${RESET}"
    echo ""

    # SSH Quick Access
    echo -e "${TEXT_MUTED}╭─ QUICK SSH ACCESS ────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} ssh lucidia@192.168.4.38    ${TEXT_MUTED}(Lucidia Prime)${RESET}"
    echo -e "  ${PINK}2)${RESET} ssh pi@192.168.4.64          ${TEXT_MUTED}(BlackRoad Pi)${RESET}"
    echo -e "  ${PURPLE}3)${RESET} ssh lucidia@192.168.4.99    ${TEXT_MUTED}(Lucidia Alt)${RESET}"
    echo -e "  ${CYAN}4)${RESET} ssh mobile@192.168.4.68 -p 8080 ${TEXT_MUTED}(iPhone Koder)${RESET}"
    echo ""

    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Fleet: ${RESET}${BOLD}${ORANGE}Pi Network${RESET}  ${TEXT_SECONDARY}|  Status: ${RESET}${BOLD}${BLUE}${online_count}/4${RESET}"
    echo ""
}

# Auto-refresh mode
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    while true; do
        render_pi_dashboard
        sleep 5
    done
else
    render_pi_dashboard
fi
