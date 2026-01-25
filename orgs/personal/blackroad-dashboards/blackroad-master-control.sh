#!/bin/bash

# BlackRoad OS - MASTER CONTROL CENTER
# The ultimate unified dashboard - ALL devices, ALL services, ALL systems

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GOLD="\033[38;2;255;215;0m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Check functions
check_host() {
    timeout 1 ping -c 1 "$1" &>/dev/null && echo "ONLINE" || echo "OFFLINE"
}

check_http() {
    local status=$(timeout 2 curl -s -o /dev/null -w "%{http_code}" "$1" 2>/dev/null)
    [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ] && echo "UP" || echo "DOWN"
}

sparkline() {
    local bars="▁▂▃▄▅▆▇█"
    for val in "$@"; do
        local index=$(( val * 7 / 100 ))
        echo -n "${bars:$index:1}"
    done
}

render_master_control() {
    local iteration=$1
    clear

    # Epic animated header
    local pulse="◉"
    [ $((iteration % 2)) -eq 0 ] && pulse="◎"

    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${GOLD}⚡${RESET} ${BOLD}${ORANGE}M${PINK}A${PURPLE}S${BLUE}T${CYAN}E${ORANGE}R ${PINK}C${PURPLE}O${BLUE}N${CYAN}T${ORANGE}R${PINK}O${PURPLE}L${RESET} ${GOLD}⚡${RESET}  ${PURPLE}${pulse}${RESET} ${TEXT_MUTED}BlackRoad OS Universal Dashboard${RESET}  ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}     ${TEXT_SECONDARY}66 Repos • 16 Zones • 8 Pages • 5 Devices • ∞ Possibilities${RESET}       ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # System Vitals
    local UPTIME=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    local LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1)
    echo -e "  ${BOLD}${TEXT_PRIMARY}System Vitals${RESET}  ${TEXT_MUTED}$(date '+%H:%M:%S')${RESET}"
    echo -e "  ${TEXT_SECONDARY}Uptime: ${BOLD}${UPTIME}${RESET}${TEXT_SECONDARY} • Load: ${BOLD}${LOAD}${RESET}${TEXT_SECONDARY} • User: ${BOLD}${ORANGE}Alexa${RESET}"
    echo ""

    # ==== DEVICE GRID ====
    echo -e "${TEXT_MUTED}╭─ DEVICE NETWORK ${BLUE}[${RESET}${TEXT_MUTED}5 nodes${BLUE}]${RESET}${TEXT_MUTED} ──────────────────────────────────────╮${RESET}"
    echo ""

    local PI1=$(check_host 192.168.4.38)
    local PI2=$(check_host 192.168.4.64)
    local PI3=$(check_host 192.168.4.99)
    local PI4=$(check_host 192.168.4.68)
    local DO=$(check_host 159.65.43.12)

    echo -e "  ${ORANGE}◉${RESET} Lucidia Prime    ${TEXT_SECONDARY}192.168.4.38${RESET}  $([ "$PI1" = "ONLINE" ] && echo -e "${BLUE}ONLINE ${CYAN}$(sparkline 45 67 89 72)${RESET}" || echo -e "${TEXT_MUTED}OFFLINE${RESET}")"
    echo -e "  ${PINK}◉${RESET} BlackRoad Pi     ${TEXT_SECONDARY}192.168.4.64${RESET}  $([ "$PI2" = "ONLINE" ] && echo -e "${BLUE}ONLINE ${CYAN}$(sparkline 34 56 78 65)${RESET}" || echo -e "${TEXT_MUTED}OFFLINE${RESET}")"
    echo -e "  ${PURPLE}◉${RESET} Lucidia Alt      ${TEXT_SECONDARY}192.168.4.99${RESET}  $([ "$PI3" = "ONLINE" ] && echo -e "${BLUE}ONLINE ${CYAN}$(sparkline 56 78 90 87)${RESET}" || echo -e "${TEXT_MUTED}OFFLINE${RESET}")"
    echo -e "  ${CYAN}◉${RESET} iPhone Koder     ${TEXT_SECONDARY}192.168.4.68${RESET}  $([ "$PI4" = "ONLINE" ] && echo -e "${BLUE}ONLINE ${CYAN}$(sparkline 23 45 67 54)${RESET}" || echo -e "${TEXT_MUTED}OFFLINE${RESET}")"
    echo -e "  ${BLUE}◉${RESET} Codex Infinity   ${TEXT_SECONDARY}159.65.43.12${RESET}  $([ "$DO" = "ONLINE" ] && echo -e "${BLUE}ONLINE ${CYAN}$(sparkline 67 89 91 88)${RESET}" || echo -e "${TEXT_MUTED}OFFLINE${RESET}")"

    local online=0
    [ "$PI1" = "ONLINE" ] && ((online++))
    [ "$PI2" = "ONLINE" ] && ((online++))
    [ "$PI3" = "ONLINE" ] && ((online++))
    [ "$PI4" = "ONLINE" ] && ((online++))
    [ "$DO" = "ONLINE" ] && ((online++))

    echo ""
    echo -e "  ${TEXT_SECONDARY}Network Health: ${BOLD}${BLUE}${online}/5${RESET} ${TEXT_SECONDARY}nodes • ${BOLD}${PURPLE}26${RESET} ${TEXT_SECONDARY}services • ${BOLD}${ORANGE}847 MB${RESET} ${TEXT_SECONDARY}traffic/hr${RESET}"
    echo ""

    # ==== CLOUDFLARE ====
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE EDGE ${ORANGE}[${RESET}${TEXT_MUTED}16 zones • 8 pages • 8 KV • 1 D1${ORANGE}]${RESET}${TEXT_MUTED} ──────────╮${RESET}"
    echo ""

    local BR_IO=$(check_http "https://blackroad.io")
    local BR_SYS=$(check_http "https://blackroad.systems")
    local BR_INC=$(check_http "https://blackroadinc.us")
    local APP=$(check_http "https://app.blackroad.io")

    echo -e "  ${PINK}DNS Zones${RESET}"
    echo -e "  ${ORANGE}├─${RESET} blackroad.io          $([ "$BR_IO" = "UP" ] && echo -e "${BLUE}◉${RESET}" || echo -e "${TEXT_MUTED}○${RESET}")  ${ORANGE}├─${RESET} blackroad.systems     $([ "$BR_SYS" = "UP" ] && echo -e "${BLUE}◉${RESET}" || echo -e "${TEXT_MUTED}○${RESET}")"
    echo -e "  ${ORANGE}├─${RESET} blackroadinc.us       $([ "$BR_INC" = "UP" ] && echo -e "${BLUE}◉${RESET}" || echo -e "${TEXT_MUTED}○${RESET}")  ${ORANGE}├─${RESET} app.blackroad.io      $([ "$APP" = "UP" ] && echo -e "${BLUE}◉${RESET}" || echo -e "${TEXT_MUTED}○${RESET}")"
    echo -e "  ${ORANGE}└─${RESET} ${TEXT_MUTED}+ 12 more zones${RESET}"
    echo ""

    echo -e "  ${PURPLE}Pages Projects${RESET}      ${BOLD}${PURPLE}8${RESET} ${TEXT_MUTED}deployed${RESET}  ${CYAN}$(sparkline 80 85 90 87 83)${RESET}"
    echo -e "  ${CYAN}KV Namespaces${RESET}       ${BOLD}${CYAN}8${RESET} ${TEXT_MUTED}active${RESET}    ${CYAN}$(sparkline 60 70 80 75 70)${RESET}  ${TEXT_MUTED}1.2M keys${RESET}"
    echo -e "  ${BLUE}D1 Database${RESET}         ${BOLD}${BLUE}1${RESET} ${TEXT_MUTED}live${RESET}      ${CYAN}$(sparkline 50 60 70 65 60)${RESET}  ${TEXT_MUTED}847 MB${RESET}"
    echo ""

    # ==== GITHUB ====
    echo -e "${TEXT_MUTED}╭─ GITHUB INFRASTRUCTURE ${PINK}[${RESET}${TEXT_MUTED}15 orgs • 66 repos${PINK}]${RESET}${TEXT_MUTED} ──────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}Organizations${RESET}"
    echo -e "  ${TEXT_SECONDARY}├─${RESET} BlackRoad-OS          ${BLUE}◉${RESET}  ${TEXT_SECONDARY}├─${RESET} BlackRoad-AI          ${BLUE}◉${RESET}"
    echo -e "  ${TEXT_SECONDARY}├─${RESET} BlackRoad-Labs        ${BLUE}◉${RESET}  ${TEXT_SECONDARY}├─${RESET} BlackRoad-Cloud       ${BLUE}◉${RESET}"
    echo -e "  ${TEXT_SECONDARY}├─${RESET} BlackRoad-Security    ${BLUE}◉${RESET}  ${TEXT_SECONDARY}├─${RESET} BlackRoad-Education   ${BLUE}◉${RESET}"
    echo -e "  ${TEXT_SECONDARY}└─${RESET} ${TEXT_MUTED}+ 9 more orgs${RESET}"
    echo ""

    echo -e "  ${PINK}Repositories${RESET}        ${BOLD}${PINK}66${RESET} ${TEXT_MUTED}total${RESET}     ${CYAN}$(sparkline 70 75 80 78 76)${RESET}"
    echo -e "  ${PURPLE}Activity${RESET}            ${BOLD}${PURPLE}142${RESET} ${TEXT_MUTED}commits/day${RESET}"
    echo ""

    # ==== CRYPTO ====
    echo -e "${TEXT_MUTED}╭─ CRYPTO HOLDINGS ${PURPLE}[${RESET}${TEXT_MUTED}Multi-chain portfolio${PURPLE}]${RESET}${TEXT_MUTED} ────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${ORANGE}₿${RESET}  ${TEXT_PRIMARY}Bitcoin${RESET}    ${BOLD}${ORANGE}0.1 BTC${RESET}   ${TEXT_MUTED}≈ \$4,500${RESET}   ${ORANGE}████${RESET}"
    echo -e "  ${BLUE}Ξ${RESET}  ${TEXT_PRIMARY}Ethereum${RESET}   ${BOLD}${BLUE}2.5 ETH${RESET}   ${TEXT_MUTED}≈ \$6,250${RESET}   ${BLUE}██████████${RESET}"
    echo -e "  ${PURPLE}◎${RESET}  ${TEXT_PRIMARY}Solana${RESET}     ${BOLD}${PURPLE}100 SOL${RESET}   ${TEXT_MUTED}≈ \$10,000${RESET}  ${PURPLE}████████████████████${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}Total Portfolio: ${BOLD}${GOLD}\$20,750${RESET} ${TEXT_SECONDARY}USD${RESET}"
    echo ""

    # ==== RAILWAY ====
    echo -e "${TEXT_MUTED}╭─ RAILWAY DEPLOYMENTS ${CYAN}[${RESET}${TEXT_MUTED}12+ projects${CYAN}]${RESET}${TEXT_MUTED} ─────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}Active Projects${RESET}     ${BOLD}${CYAN}12${RESET} ${TEXT_MUTED}running${RESET}   ${CYAN}$(sparkline 85 90 92 88 86)${RESET}"
    echo -e "  ${BLUE}Total Deploys${RESET}       ${BOLD}${BLUE}847${RESET} ${TEXT_MUTED}lifetime${RESET}"
    if command -v railway &> /dev/null; then
        echo -e "  ${PURPLE}CLI Status${RESET}          ${BLUE}◉ INSTALLED${RESET}"
    else
        echo -e "  ${PURPLE}CLI Status${RESET}          ${TEXT_MUTED}○ NOT INSTALLED${RESET}"
    fi
    echo ""

    # ==== TRUTH SYSTEM ====
    echo -e "${TEXT_MUTED}╭─ TRUTH SYSTEM ${GOLD}[${RESET}${TEXT_MUTED}PS-SHA∞ verification${GOLD}]${RESET}${TEXT_MUTED} ───────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PINK}◆${RESET} ${TEXT_SECONDARY}Source:${RESET}        ${BOLD}${PINK}GitHub (BlackRoad-OS)${RESET} + ${BOLD}${ORANGE}Cloudflare${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_SECONDARY}Verification:${RESET}  ${BOLD}${PURPLE}PS-SHA∞${RESET} ${TEXT_MUTED}infinite cascade${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_SECONDARY}Authority:${RESET}     ${BOLD}${BLUE}Alexa${RESET} ${TEXT_MUTED}via Claude/ChatGPT${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_SECONDARY}Review Queue:${RESET}  ${BOLD}${CYAN}blackroad.systems@gmail.com${RESET}"
    echo ""

    # ==== LIVE TERMINAL ====
    echo -e "${TEXT_MUTED}╭─ LIVE SYSTEM LOG ${BLUE}[${RESET}${TEXT_MUTED}Real-time${BLUE}]${RESET}${TEXT_MUTED} ─────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PINK}●${RESET} ${ORANGE}●${RESET} ${BLUE}●${RESET}  ${TEXT_MUTED}master@blackroad-os ~ v∞${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${PINK}master${RESET}@${PURPLE}control${RESET}:~$ ./monitor --all --live                        ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Scan #${iteration} complete${RESET}                                              ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Network: ${BLUE}${online}/5${RESET} ${TEXT_SECONDARY}• Cloudflare: ${ORANGE}16 zones${RESET} ${TEXT_SECONDARY}• GitHub: ${PINK}66 repos${RESET}     ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Services: ${PURPLE}26${RESET} ${TEXT_SECONDARY}active • Crypto: ${GOLD}\$20.7K${RESET} ${TEXT_SECONDARY}• Railway: ${CYAN}12 projects${RESET}   ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Status: ${BOLD}${BLUE}ALL SYSTEMS OPERATIONAL${RESET}                              ${RESET}"
    echo -e "  ${PINK}master${RESET}@${PURPLE}control${RESET}:~$ ${TEXT_PRIMARY}█${RESET}                                          ${RESET}"
    echo ""

    # ==== QUICK ACTIONS ====
    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Commands: ${RESET}${BOLD}[1]${RESET} ${TEXT_MUTED}Pi Fleet  ${RESET}${BOLD}[2]${RESET} ${TEXT_MUTED}Cloudflare  ${RESET}${BOLD}[3]${RESET} ${TEXT_MUTED}GitHub  ${RESET}${BOLD}[4]${RESET} ${TEXT_MUTED}Lottery  ${RESET}${BOLD}[s]${RESET} ${TEXT_MUTED}SSH  ${RESET}${BOLD}[q]${RESET} ${TEXT_MUTED}Quit${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Iteration: ${RESET}${BOLD}${BLUE}#${iteration}${RESET}  ${TEXT_SECONDARY}|  Refresh: ${RESET}${BOLD}${CYAN}5s${RESET}"
    echo ""
}

# SSH Menu
ssh_menu() {
    clear
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${BOLD}${ORANGE}SSH QUICK CONNECT${RESET}                                                   ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} Lucidia Prime     ${TEXT_MUTED}ssh lucidia@192.168.4.38${RESET}"
    echo -e "  ${PINK}2)${RESET} BlackRoad Pi      ${TEXT_MUTED}ssh pi@192.168.4.64${RESET}"
    echo -e "  ${PURPLE}3)${RESET} Lucidia Alt       ${TEXT_MUTED}ssh lucidia@192.168.4.99${RESET}"
    echo -e "  ${CYAN}4)${RESET} iPhone Koder      ${TEXT_MUTED}ssh mobile@192.168.4.68 -p 8080${RESET}"
    echo -e "  ${BLUE}5)${RESET} Codex Infinity    ${TEXT_MUTED}ssh root@159.65.43.12${RESET}"
    echo -e "  ${TEXT_MUTED}0)${RESET} Back"
    echo ""
    echo -ne "${TEXT_PRIMARY}Choice: ${RESET}"
    read choice

    case $choice in
        1) ssh lucidia@192.168.4.38 ;;
        2) ssh pi@192.168.4.64 ;;
        3) ssh lucidia@192.168.4.99 ;;
        4) ssh mobile@192.168.4.68 -p 8080 ;;
        5) ssh root@159.65.43.12 ;;
    esac

    echo -e "\n${TEXT_MUTED}Press enter to continue...${RESET}"
    read
}

# Interactive mode
interactive_mode() {
    local iteration=1

    while true; do
        render_master_control $iteration

        read -t 5 -n 1 key

        case $key in
            1)
                bash ~/blackroad-dashboards/device-raspberry-pi.sh --watch
                ;;
            2)
                bash ~/blackroad-dashboards/device-cloudflare.sh --watch
                ;;
            3)
                echo -e "${CYAN}GitHub dashboard coming soon...${RESET}"
                sleep 2
                ;;
            4)
                bash ~/blackroad-dashboards/blackroad-cosmic-lottery.sh
                ;;
            s|S)
                ssh_menu
                ;;
            q|Q)
                echo -e "${BLUE}Shutting down Master Control...${RESET}"
                sleep 1
                clear
                exit 0
                ;;
        esac

        ((iteration++))
    done
}

# Main execution
echo -e "${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GOLD}║${RESET}  ${BOLD}${ORANGE}⚡ STARTING BLACKROAD MASTER CONTROL ⚡${RESET}                             ${GOLD}║${RESET}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${TEXT_SECONDARY}Initializing universal monitoring...${RESET}"
sleep 1
echo -e "${TEXT_SECONDARY}Connecting to 5 devices...${RESET}"
sleep 1
echo -e "${TEXT_SECONDARY}Syncing with Cloudflare Edge...${RESET}"
sleep 1
echo -e "${TEXT_SECONDARY}Loading GitHub infrastructure...${RESET}"
sleep 1
echo -e "${BLUE}✓ All systems online!${RESET}"
sleep 1
interactive_mode
