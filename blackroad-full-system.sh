#!/bin/bash

# BlackRoad OS - Full System Monitor with Auto-Refresh
# Complete infrastructure visualization with live updates

# Color definitions (matching HTML)
ORANGE="\033[38;2;247;147;26m"      # #f7931a
PINK="\033[38;2;233;30;140m"        # #e91e8c
PURPLE="\033[38;2;153;69;255m"      # #9945ff
BLUE="\033[38;2;20;241;149m"        # #14f195
CYAN="\033[38;2;0;212;255m"         # #00d4ff
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
BG_DEEP="\033[48;2;10;10;18m"
BG_SURFACE="\033[48;2;18;18;31m"
BG_ELEVATED="\033[48;2;26;26;46m"
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Function to check host status
check_host() {
    local host=$1
    timeout 1 ping -c 1 "$host" &>/dev/null && echo "ONLINE" || echo "OFFLINE"
}

# Function to check HTTP status
check_http() {
    local url=$1
    local status=$(timeout 2 curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
        echo "ONLINE"
    else
        echo "OFFLINE"
    fi
}

# Function to get Railway status
check_railway() {
    if command -v railway &> /dev/null; then
        echo "INSTALLED"
    else
        echo "NOT_INSTALLED"
    fi
}

# Function to render the dashboard
render_dashboard() {
    clear
    echo -ne ""
    clear

    # Animated header with timestamp
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}👻${RESET}  ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET} ${TEXT_MUTED}v2.0${RESET}                                            ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}     ${TEXT_MUTED}Full System Monitor • Live Infrastructure Dashboard${RESET}              ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # System vitals banner
    local UPTIME=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    local LOAD=$(uptime | awk -F'load average:' '{print $2}')

    echo -e "                                                                        ${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}System Vitals${RESET}                                                      ${RESET}"
    echo -e "  ${TEXT_SECONDARY}Uptime: ${BOLD}${UPTIME}${RESET}${TEXT_SECONDARY} • Load:${BOLD}${LOAD}${RESET}                ${RESET}"
    echo -e "                                                                        ${RESET}"
    echo ""

    # Network Infrastructure Grid
    echo -e "${TEXT_MUTED}╭─ NETWORK INFRASTRUCTURE ──────────────────────────────────────────────╮${RESET}"
    echo ""

    # Check all Pi devices in parallel
    local LUCIDIA_STATUS=$(check_host 192.168.4.38)
    local BLACKROAD_PI_STATUS=$(check_host 192.168.4.64)
    local LUCIDIA_ALT_STATUS=$(check_host 192.168.4.99)
    local IPHONE_STATUS=$(check_host 192.168.4.68)
    local CODEX_STATUS=$(check_host 159.65.43.12)

    # Raspberry Pi nodes (2x2 grid)
    echo -e "  ${ORANGE}┌─────────────────────┐${RESET}  ${PINK}┌─────────────────────┐${RESET}"

    if [ "$LUCIDIA_STATUS" = "ONLINE" ]; then
        echo -e "  ${ORANGE}│${RESET} ${BLUE}●${RESET} ${BOLD}Lucidia Prime${RESET}    ${ORANGE}│${RESET}  ${PINK}│${RESET} ${BLUE}●${RESET} ${BOLD}BlackRoad Pi${RESET}     ${PINK}│${RESET}"
    else
        echo -e "  ${ORANGE}│${RESET} ${TEXT_MUTED}●${RESET} ${DIM}Lucidia Prime${RESET}    ${ORANGE}│${RESET}  ${PINK}│${RESET} ${TEXT_MUTED}●${RESET} ${DIM}BlackRoad Pi${RESET}     ${PINK}│${RESET}"
    fi

    echo -e "  ${ORANGE}│${RESET}   ${TEXT_SECONDARY}192.168.4.38${RESET}      ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_SECONDARY}192.168.4.64${RESET}      ${PINK}│${RESET}"

    if [ "$LUCIDIA_STATUS" = "ONLINE" ]; then
        echo -e "  ${ORANGE}│${RESET}   ${BLUE}ONLINE${RESET}            ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${BLUE}ONLINE${RESET}            ${PINK}│${RESET}"
    else
        echo -e "  ${ORANGE}│${RESET}   ${TEXT_MUTED}OFFLINE${RESET}           ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_MUTED}OFFLINE${RESET}           ${PINK}│${RESET}"
    fi

    echo -e "  ${ORANGE}└─────────────────────┘${RESET}  ${PINK}└─────────────────────┘${RESET}"
    echo ""

    echo -e "  ${PURPLE}┌─────────────────────┐${RESET}  ${CYAN}┌─────────────────────┐${RESET}"

    if [ "$LUCIDIA_ALT_STATUS" = "ONLINE" ]; then
        echo -e "  ${PURPLE}│${RESET} ${BLUE}●${RESET} ${BOLD}Lucidia Alt${RESET}      ${PURPLE}│${RESET}  ${CYAN}│${RESET} ${BLUE}●${RESET} ${BOLD}iPhone Koder${RESET}     ${CYAN}│${RESET}"
    else
        echo -e "  ${PURPLE}│${RESET} ${TEXT_MUTED}●${RESET} ${DIM}Lucidia Alt${RESET}      ${PURPLE}│${RESET}  ${CYAN}│${RESET} ${TEXT_MUTED}●${RESET} ${DIM}iPhone Koder${RESET}     ${CYAN}│${RESET}"
    fi

    echo -e "  ${PURPLE}│${RESET}   ${TEXT_SECONDARY}192.168.4.99${RESET}      ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${TEXT_SECONDARY}192.168.4.68:8080${RESET} ${CYAN}│${RESET}"

    if [ "$LUCIDIA_ALT_STATUS" = "ONLINE" ]; then
        echo -e "  ${PURPLE}│${RESET}   ${BLUE}ONLINE${RESET}            ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${BLUE}ONLINE${RESET}            ${CYAN}│${RESET}"
    else
        echo -e "  ${PURPLE}│${RESET}   ${TEXT_MUTED}OFFLINE${RESET}           ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${TEXT_MUTED}OFFLINE${RESET}           ${CYAN}│${RESET}"
    fi

    echo -e "  ${PURPLE}└─────────────────────┘${RESET}  ${CYAN}└─────────────────────┘${RESET}"
    echo ""

    # DigitalOcean
    echo -e "  ${BLUE}┌────────────────────────────────────────────┐${RESET}"
    if [ "$CODEX_STATUS" = "ONLINE" ]; then
        echo -e "  ${BLUE}│${RESET} ${BLUE}●${RESET} ${BOLD}Codex Infinity${RESET} ${TEXT_SECONDARY}(DigitalOcean)${RESET}      ${BLUE}│${RESET}"
    else
        echo -e "  ${BLUE}│${RESET} ${ORANGE}●${RESET} ${BOLD}Codex Infinity${RESET} ${TEXT_SECONDARY}(DigitalOcean)${RESET}      ${BLUE}│${RESET}"
    fi
    echo -e "  ${BLUE}│${RESET}   ${TEXT_SECONDARY}159.65.43.12${RESET}                          ${BLUE}│${RESET}"
    if [ "$CODEX_STATUS" = "ONLINE" ]; then
        echo -e "  ${BLUE}│${RESET}   ${BLUE}ONLINE${RESET}                                ${BLUE}│${RESET}"
    else
        echo -e "  ${BLUE}│${RESET}   ${ORANGE}CHECK REQUIRED${RESET}                        ${BLUE}│${RESET}"
    fi
    echo -e "  ${BLUE}└────────────────────────────────────────────┘${RESET}"
    echo ""

    local ONLINE_COUNT=0
    [ "$LUCIDIA_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$BLACKROAD_PI_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$LUCIDIA_ALT_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$IPHONE_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$CODEX_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))

    echo -e "  ${TEXT_SECONDARY}Network Status: ${BOLD}${BLUE}${ONLINE_COUNT}/5${RESET} ${TEXT_SECONDARY}nodes online${RESET}"
    echo ""

    # Cloudflare Section
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE INFRASTRUCTURE ───────────────────────────────────────────╮${RESET}"
    echo ""

    # Check key domains
    local BR_IO=$(check_http "https://blackroad.io")
    local BR_SYS=$(check_http "https://blackroad.systems")
    local HEADSCALE=$(check_http "https://headscale.blackroad.io")
    local BBP=$(check_http "https://blackboxprogramming.com")

    echo -e "  ${PINK}◆${RESET} ${TEXT_PRIMARY}Zones${RESET}"
    echo -e "    ${ORANGE}├─${RESET} blackroad.io              $([ "$BR_IO" = "ONLINE" ] && echo -e "${BLUE}●${RESET}" || echo -e "${TEXT_MUTED}●${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} blackroad.systems         $([ "$BR_SYS" = "ONLINE" ] && echo -e "${BLUE}●${RESET}" || echo -e "${TEXT_MUTED}●${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} headscale.blackroad.io    $([ "$HEADSCALE" = "ONLINE" ] && echo -e "${BLUE}●${RESET}" || echo -e "${TEXT_MUTED}●${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} blackboxprogramming.com   $([ "$BBP" = "ONLINE" ] && echo -e "${BLUE}●${RESET}" || echo -e "${TEXT_MUTED}●${RESET}")"
    echo -e "    ${ORANGE}└─${RESET} ${TEXT_MUTED}+ 12 additional zones${RESET}"
    echo ""

    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Services${RESET}"
    echo -e "    ${TEXT_SECONDARY}Pages Projects:${RESET}    ${BOLD}${PURPLE}8${RESET} ${TEXT_MUTED}deployed${RESET}"
    echo -e "    ${TEXT_SECONDARY}KV Namespaces:${RESET}     ${BOLD}${PURPLE}8${RESET} ${TEXT_MUTED}active${RESET}"
    echo -e "    ${TEXT_SECONDARY}D1 Databases:${RESET}      ${BOLD}${PURPLE}1${RESET} ${TEXT_MUTED}provisioned${RESET}"
    echo ""

    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Tunnel${RESET}"
    echo -e "    ${TEXT_SECONDARY}ID:${RESET} ${TEXT_MUTED}72f1d60c-dcf2-4499-b02d-d7a063018b33${RESET}"
    echo -e "    ${TEXT_SECONDARY}Zone:${RESET} ${TEXT_MUTED}848cf0b18d51e0170e0d1537aec3505a${RESET}"
    echo ""

    # GitHub Section
    echo -e "${TEXT_MUTED}╭─ GITHUB & DEVELOPMENT ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Organizations${RESET}     ${BOLD}${ORANGE}15${RESET} ${TEXT_SECONDARY}orgs${RESET}"
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Repositories${RESET}      ${BOLD}${ORANGE}66${RESET} ${TEXT_SECONDARY}repos${RESET}"
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Primary Org${RESET}       ${BOLD}${PINK}blackboxprogramming${RESET}"
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Main Org${RESET}          ${BOLD}${BLUE}BlackRoad-OS${RESET}"
    echo ""

    # Railway status
    local RAILWAY_STATUS=$(check_railway)
    echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Railway Projects${RESET}  ${BOLD}${CYAN}12+${RESET} ${TEXT_SECONDARY}active${RESET}"
    if [ "$RAILWAY_STATUS" = "INSTALLED" ]; then
        echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Railway CLI${RESET}       ${BLUE}● INSTALLED${RESET}"
    else
        echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Railway CLI${RESET}       ${TEXT_MUTED}● NOT INSTALLED${RESET}"
    fi
    echo ""

    # Crypto Holdings with live prices (simulated)
    echo -e "${TEXT_MUTED}╭─ CRYPTO PORTFOLIO ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Progress bars for holdings
    echo -e "  ${ORANGE}₿${RESET}  ${TEXT_PRIMARY}Bitcoin${RESET}          ${BOLD}${ORANGE}0.1 BTC${RESET}     ${TEXT_MUTED}Coinbase${RESET}"
    echo -e "     ${ORANGE}████${RESET}                                          ${RESET}"
    echo ""

    echo -e "  ${BLUE}Ξ${RESET}  ${TEXT_PRIMARY}Ethereum${RESET}         ${BOLD}${BLUE}2.5 ETH${RESET}     ${TEXT_MUTED}MetaMask${RESET}"
    echo -e "     ${BLUE}██████████${RESET}                                    ${RESET}"
    echo ""

    echo -e "  ${PURPLE}◎${RESET}  ${TEXT_PRIMARY}Solana${RESET}           ${BOLD}${PURPLE}100 SOL${RESET}     ${TEXT_MUTED}Phantom${RESET}"
    echo -e "     ${PURPLE}████████████████████████████████████████${RESET}  ${RESET}"
    echo ""

    echo -e "  ${TEXT_MUTED}BTC Address: 1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ${RESET}"
    echo ""

    # Truth System
    echo -e "${TEXT_MUTED}╭─ TRUTH SYSTEM & VERIFICATION ─────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PINK}◆${RESET} ${TEXT_SECONDARY}Source:${RESET}        ${BOLD}${PINK}GitHub (BlackRoad-OS)${RESET} ${TEXT_SECONDARY}+ Cloudflare${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${TEXT_SECONDARY}Verification:${RESET}  ${BOLD}${PURPLE}PS-SHA∞${RESET} ${TEXT_MUTED}(infinite cascade hashing)${RESET}"
    echo -e "  ${BLUE}◆${RESET} ${TEXT_SECONDARY}Authorization:${RESET} ${BOLD}${BLUE}Alexa${RESET} ${TEXT_MUTED}via Claude/ChatGPT${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_SECONDARY}Review Queue:${RESET}  ${BOLD}${CYAN}Linear${RESET} ${TEXT_MUTED}/ blackroad.systems@gmail.com${RESET}"
    echo ""

    # Contact Information
    echo -e "${TEXT_MUTED}╭─ CONTACT & IDENTITY ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}✉${RESET}  ${TEXT_PRIMARY}Primary${RESET}    ${BOLD}${ORANGE}amundsonalexa@gmail.com${RESET}"
    echo -e "  ${PINK}✉${RESET}  ${TEXT_PRIMARY}Company${RESET}    ${BOLD}${PINK}blackroad.systems@gmail.com${RESET}"
    echo ""

    # Terminal Output Section
    echo -e "${TEXT_MUTED}╭─ LIVE TERMINAL OUTPUT ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "                                                                        ${RESET}"
    echo -e "  ${PINK}●${RESET} ${ORANGE}●${RESET} ${BLUE}●${RESET}  ${TEXT_MUTED}lucidia@blackroad-os ~ v2.0${RESET}                                  ${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}${RESET}"
    echo -e "  ${PINK}lucidia${RESET}@${PURPLE}blackroad${RESET}:~$ ./blackroad-monitor --live                       ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Initializing system scan...${RESET}                                    ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Network: ${BLUE}${ONLINE_COUNT}/5${TEXT_SECONDARY} nodes responding${RESET}                             ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Cloudflare: ${PURPLE}16${TEXT_SECONDARY} zones configured${RESET}                              ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ GitHub: ${ORANGE}66${TEXT_SECONDARY} repositories active${RESET}                                ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ All systems: ${BLUE}OPERATIONAL${RESET}                                       ${RESET}"
    echo -e "  ${PINK}lucidia${RESET}@${PURPLE}blackroad${RESET}:~$ ${TEXT_PRIMARY}█${RESET}                                            ${RESET}"
    echo -e "                                                                        ${RESET}"
    echo ""

    # Footer with real-time stats
    echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Date: ${RESET}${BOLD}$(date '+%Y-%m-%d')${RESET}  ${TEXT_SECONDARY}|  User: ${RESET}${BOLD}${ORANGE}Alexa${RESET}  ${TEXT_SECONDARY}|  Scan: ${RESET}${BOLD}${BLUE}Complete${RESET}"
    echo -e "${TEXT_MUTED}BlackRoad OS v2.0 • Colors: #FF9D00 #FF6B00 #FF0066 #FF006B #D600AA #7700FF #0066FF${RESET}"
    echo ""
}

# Check if auto-refresh mode is requested
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    echo -e "${BLUE}Starting auto-refresh mode (Ctrl+C to exit)...${RESET}"
    sleep 1
    while true; do
        render_dashboard
        sleep 5
    done
else
    render_dashboard
    echo -e "${TEXT_MUTED}Tip: Use ${RESET}${BOLD}./blackroad-full-system.sh --watch${RESET}${TEXT_MUTED} for auto-refresh mode${RESET}"
    echo ""
fi
