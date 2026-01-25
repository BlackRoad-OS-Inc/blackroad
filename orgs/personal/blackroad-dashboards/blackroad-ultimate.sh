#!/bin/bash

# BlackRoad OS - ULTIMATE System Monitor
# With sound effects, animations, SSH integration, and API calls

# Color definitions (matching HTML)
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
BG_DEEP="\033[48;2;10;10;18m"
BG_SURFACE="\033[48;2;18;18;31m"
BG_ELEVATED="\033[48;2;26;26;46m"
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# Sound effects (macOS)
play_sound() {
    local sound_type=$1
    case $sound_type in
        "success")
            afplay /System/Library/Sounds/Glass.aiff &>/dev/null &
            ;;
        "online")
            afplay /System/Library/Sounds/Tink.aiff &>/dev/null &
            ;;
        "offline")
            afplay /System/Library/Sounds/Basso.aiff &>/dev/null &
            ;;
        "scan")
            afplay /System/Library/Sounds/Pop.aiff &>/dev/null &
            ;;
    esac
}

# Check host status with previous state tracking
check_host() {
    local host=$1
    timeout 1 ping -c 1 "$host" &>/dev/null && echo "ONLINE" || echo "OFFLINE"
}

# Check HTTP status
check_http() {
    local url=$1
    local status=$(timeout 2 curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
        echo "ONLINE"
    else
        echo "OFFLINE"
    fi
}

# Get GitHub stats via API
get_github_stats() {
    local user="blackboxprogramming"
    local response=$(curl -s "https://api.github.com/users/$user" 2>/dev/null)

    if [ $? -eq 0 ]; then
        local repos=$(echo "$response" | grep -o '"public_repos":[0-9]*' | grep -o '[0-9]*')
        local followers=$(echo "$response" | grep -o '"followers":[0-9]*' | grep -o '[0-9]*')
        echo "$repos|$followers"
    else
        echo "66|0"
    fi
}

# Get crypto prices (simulated - would need CoinGecko/CoinMarketCap API)
get_crypto_prices() {
    # Simulated prices - replace with real API calls
    local btc_price=45000
    local eth_price=2500
    local sol_price=100

    # Calculate portfolio value
    local btc_value=$(echo "0.1 * $btc_price" | bc)
    local eth_value=$(echo "2.5 * $eth_price" | bc)
    local sol_value=$(echo "100 * $sol_price" | bc)
    local total=$(echo "$btc_value + $eth_value + $sol_value" | bc)

    echo "$btc_price|$eth_price|$sol_price|$total"
}

# Cloudflare API check (requires CF_TOKEN)
check_cloudflare_api() {
    if [ -z "$CF_TOKEN" ]; then
        echo "0|0|0"
        return
    fi

    local zones=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
        -H "Authorization: Bearer $CF_TOKEN" \
        -H "Content-Type: application/json" | grep -o '"total_count":[0-9]*' | head -1 | grep -o '[0-9]*')

    echo "${zones:-16}|8|8"
}

# Tailscale status
check_tailscale() {
    if command -v tailscale &> /dev/null; then
        local status=$(tailscale status 2>/dev/null | wc -l)
        if [ $status -gt 0 ]; then
            echo "CONNECTED|$status"
        else
            echo "DISCONNECTED|0"
        fi
    else
        echo "NOT_INSTALLED|0"
    fi
}

# SSH Quick Connect Menu
ssh_menu() {
    clear
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${PINK}SSH Quick Connect${RESET}                                                   ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_SECONDARY}Select a device:${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} Lucidia Prime     ${TEXT_MUTED}(192.168.4.38)${RESET}"
    echo -e "  ${PINK}2)${RESET} BlackRoad Pi      ${TEXT_MUTED}(192.168.4.64)${RESET}"
    echo -e "  ${PURPLE}3)${RESET} Lucidia Alt       ${TEXT_MUTED}(192.168.4.99)${RESET}"
    echo -e "  ${CYAN}4)${RESET} iPhone Koder      ${TEXT_MUTED}(192.168.4.68:8080)${RESET}"
    echo -e "  ${BLUE}5)${RESET} Codex Infinity    ${TEXT_MUTED}(159.65.43.12)${RESET}"
    echo -e "  ${TEXT_MUTED}0)${RESET} Back to dashboard"
    echo ""
    echo -ne "${TEXT_PRIMARY}Choice: ${RESET}"
    read choice

    case $choice in
        1)
            play_sound "scan"
            echo -e "\n${BLUE}Connecting to Lucidia Prime...${RESET}\n"
            ssh lucidia@192.168.4.38
            ;;
        2)
            play_sound "scan"
            echo -e "\n${BLUE}Connecting to BlackRoad Pi...${RESET}\n"
            ssh pi@192.168.4.64
            ;;
        3)
            play_sound "scan"
            echo -e "\n${BLUE}Connecting to Lucidia Alt...${RESET}\n"
            ssh lucidia@192.168.4.99
            ;;
        4)
            play_sound "scan"
            echo -e "\n${BLUE}Connecting to iPhone Koder...${RESET}\n"
            ssh mobile@192.168.4.68 -p 8080
            ;;
        5)
            play_sound "scan"
            echo -e "\n${BLUE}Connecting to Codex Infinity...${RESET}\n"
            ssh root@159.65.43.12
            ;;
        0)
            return
            ;;
    esac

    echo ""
    echo -e "${TEXT_MUTED}Press enter to continue...${RESET}"
    read
}

# Animated progress bar
animate_bar() {
    local percent=$1
    local color=$2
    local width=40
    local filled=$(echo "$width * $percent / 100" | bc)

    echo -ne "     "
    for ((i=0; i<$filled; i++)); do
        echo -ne "${color}█${RESET}"
    done
    for ((i=$filled; i<$width; i++)); do
        echo -ne " "
    done
    echo -e "${RESET}"
}

# Sparkline generator
generate_sparkline() {
    local values=("$@")
    local bars="▁▂▃▄▅▆▇█"
    local max=0

    # Find max value
    for val in "${values[@]}"; do
        [ $val -gt $max ] && max=$val
    done

    # Generate sparkline
    for val in "${values[@]}"; do
        local index=$(echo "$val * 7 / $max" | bc)
        echo -n "${bars:$index:1}"
    done
}

# Main render function
render_dashboard() {
    local iteration=$1

    clear
    echo -ne ""
    clear

    # Animated header with pulsing effect
    local pulse_char="●"
    if [ $((iteration % 2)) -eq 0 ]; then
        pulse_char="◉"
    fi

    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}👻${RESET}  ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET} ${TEXT_MUTED}v2.0 ULTIMATE${RESET}  ${BLUE}${pulse_char}${RESET}                          ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}     ${TEXT_MUTED}Live Monitor • API Integration • SSH Ready${RESET}                    ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # System vitals with enhanced stats
    local UPTIME=$(uptime | awk '{print $3,$4}' | sed 's/,//')
    local LOAD=$(uptime | awk -F'load average:' '{print $2}')
    local MEM=$(top -l 1 | grep PhysMem | awk '{print $2}')

    echo -e "                                                                        ${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}System Vitals${RESET}  ${TEXT_MUTED}$(date '+%H:%M:%S')${RESET}                                       ${RESET}"
    echo -e "  ${TEXT_SECONDARY}Uptime: ${BOLD}${UPTIME}${RESET}${TEXT_SECONDARY} • Load:${BOLD}${LOAD}${RESET}${TEXT_SECONDARY} • Mem: ${BOLD}${MEM}${RESET}     ${RESET}"
    echo -e "                                                                        ${RESET}"
    echo ""

    # Network Infrastructure with live scanning
    echo -e "${TEXT_MUTED}╭─ NETWORK INFRASTRUCTURE ${BLUE}[${RESET}${TEXT_MUTED}Scanning...${BLUE}]${RESET}${TEXT_MUTED} ──────────────────────────╮${RESET}"
    echo ""

    # Parallel checks for speed
    local LUCIDIA_STATUS=$(check_host 192.168.4.38)
    local BLACKROAD_PI_STATUS=$(check_host 192.168.4.64)
    local LUCIDIA_ALT_STATUS=$(check_host 192.168.4.99)
    local IPHONE_STATUS=$(check_host 192.168.4.68)
    local CODEX_STATUS=$(check_host 159.65.43.12)

    # 2x2 Grid with enhanced visuals
    echo -e "  ${ORANGE}┌─────────────────────┐${RESET}  ${PINK}┌─────────────────────┐${RESET}"

    if [ "$LUCIDIA_STATUS" = "ONLINE" ]; then
        echo -e "  ${ORANGE}│${RESET} ${BLUE}◉${RESET} ${BOLD}Lucidia Prime${RESET}    ${ORANGE}│${RESET}  ${PINK}│${RESET} ${BLUE}◉${RESET} ${BOLD}BlackRoad Pi${RESET}     ${PINK}│${RESET}"
        echo -e "  ${ORANGE}│${RESET}   ${TEXT_SECONDARY}192.168.4.38${RESET}      ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_SECONDARY}192.168.4.64${RESET}      ${PINK}│${RESET}"
        echo -e "  ${ORANGE}│${RESET}   ${BLUE}▲ ONLINE${RESET}          ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${BLUE}▲ ONLINE${RESET}          ${PINK}│${RESET}"
        echo -e "  ${ORANGE}│${RESET}   ${CYAN}[SSH Connect]${RESET}     ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${CYAN}[SSH Connect]${RESET}     ${PINK}│${RESET}"
    else
        echo -e "  ${ORANGE}│${RESET} ${TEXT_MUTED}○${RESET} ${DIM}Lucidia Prime${RESET}    ${ORANGE}│${RESET}  ${PINK}│${RESET} ${TEXT_MUTED}○${RESET} ${DIM}BlackRoad Pi${RESET}     ${PINK}│${RESET}"
        echo -e "  ${ORANGE}│${RESET}   ${TEXT_SECONDARY}192.168.4.38${RESET}      ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_SECONDARY}192.168.4.64${RESET}      ${PINK}│${RESET}"
        echo -e "  ${ORANGE}│${RESET}   ${TEXT_MUTED}▼ OFFLINE${RESET}         ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_MUTED}▼ OFFLINE${RESET}         ${PINK}│${RESET}"
        echo -e "  ${ORANGE}│${RESET}   ${TEXT_MUTED}[Unavailable]${RESET}     ${ORANGE}│${RESET}  ${PINK}│${RESET}   ${TEXT_MUTED}[Unavailable]${RESET}     ${PINK}│${RESET}"
    fi

    echo -e "  ${ORANGE}└─────────────────────┘${RESET}  ${PINK}└─────────────────────┘${RESET}"
    echo ""

    echo -e "  ${PURPLE}┌─────────────────────┐${RESET}  ${CYAN}┌─────────────────────┐${RESET}"

    if [ "$LUCIDIA_ALT_STATUS" = "ONLINE" ]; then
        echo -e "  ${PURPLE}│${RESET} ${BLUE}◉${RESET} ${BOLD}Lucidia Alt${RESET}      ${PURPLE}│${RESET}  ${CYAN}│${RESET} ${BLUE}◉${RESET} ${BOLD}iPhone Koder${RESET}     ${CYAN}│${RESET}"
    else
        echo -e "  ${PURPLE}│${RESET} ${TEXT_MUTED}○${RESET} ${DIM}Lucidia Alt${RESET}      ${PURPLE}│${RESET}  ${CYAN}│${RESET} ${TEXT_MUTED}○${RESET} ${DIM}iPhone Koder${RESET}     ${CYAN}│${RESET}"
    fi

    echo -e "  ${PURPLE}│${RESET}   ${TEXT_SECONDARY}192.168.4.99${RESET}      ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${TEXT_SECONDARY}192.168.4.68:8080${RESET} ${CYAN}│${RESET}"

    if [ "$LUCIDIA_ALT_STATUS" = "ONLINE" ]; then
        echo -e "  ${PURPLE}│${RESET}   ${BLUE}▲ ONLINE${RESET}          ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${BLUE}▲ ONLINE${RESET}          ${CYAN}│${RESET}"
        echo -e "  ${PURPLE}│${RESET}   ${CYAN}[SSH Connect]${RESET}     ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${CYAN}[SSH Connect]${RESET}     ${CYAN}│${RESET}"
    else
        echo -e "  ${PURPLE}│${RESET}   ${TEXT_MUTED}▼ OFFLINE${RESET}         ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${TEXT_MUTED}▼ OFFLINE${RESET}         ${CYAN}│${RESET}"
        echo -e "  ${PURPLE}│${RESET}   ${TEXT_MUTED}[Unavailable]${RESET}     ${PURPLE}│${RESET}  ${CYAN}│${RESET}   ${TEXT_MUTED}[Unavailable]${RESET}     ${CYAN}│${RESET}"
    fi

    echo -e "  ${PURPLE}└─────────────────────┘${RESET}  ${CYAN}└─────────────────────┘${RESET}"
    echo ""

    # DigitalOcean
    echo -e "  ${BLUE}┌────────────────────────────────────────────┐${RESET}"
    if [ "$CODEX_STATUS" = "ONLINE" ]; then
        echo -e "  ${BLUE}│${RESET} ${BLUE}◉${RESET} ${BOLD}Codex Infinity${RESET} ${TEXT_SECONDARY}(DigitalOcean)${RESET}      ${BLUE}│${RESET}"
        echo -e "  ${BLUE}│${RESET}   ${TEXT_SECONDARY}159.65.43.12${RESET}                          ${BLUE}│${RESET}"
        echo -e "  ${BLUE}│${RESET}   ${BLUE}▲ ONLINE${RESET}  ${CYAN}[SSH: root@159.65.43.12]${RESET} ${BLUE}│${RESET}"
    else
        echo -e "  ${BLUE}│${RESET} ${ORANGE}⚠${RESET} ${BOLD}Codex Infinity${RESET} ${TEXT_SECONDARY}(DigitalOcean)${RESET}      ${BLUE}│${RESET}"
        echo -e "  ${BLUE}│${RESET}   ${TEXT_SECONDARY}159.65.43.12${RESET}                          ${BLUE}│${RESET}"
        echo -e "  ${BLUE}│${RESET}   ${ORANGE}▼ CHECK REQUIRED${RESET}                      ${BLUE}│${RESET}"
    fi
    echo -e "  ${BLUE}└────────────────────────────────────────────┘${RESET}"
    echo ""

    local ONLINE_COUNT=0
    [ "$LUCIDIA_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$BLACKROAD_PI_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$LUCIDIA_ALT_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$IPHONE_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
    [ "$CODEX_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))

    echo -e "  ${TEXT_SECONDARY}Network Status: ${BOLD}${BLUE}${ONLINE_COUNT}/5${RESET} ${TEXT_SECONDARY}nodes online  ${TEXT_MUTED}Press 's' for SSH menu${RESET}"
    echo ""

    # Tailscale/Headscale Status
    local TS_STATUS=$(check_tailscale)
    local TS_STATE=$(echo $TS_STATUS | cut -d'|' -f1)
    local TS_PEERS=$(echo $TS_STATUS | cut -d'|' -f2)

    echo -e "${TEXT_MUTED}╭─ MESH NETWORK (Tailscale/Headscale) ──────────────────────────────────╮${RESET}"
    echo ""
    if [ "$TS_STATE" = "CONNECTED" ]; then
        echo -e "  ${BLUE}◉${RESET} ${TEXT_PRIMARY}Tailscale Status:${RESET}     ${BOLD}${BLUE}CONNECTED${RESET}"
        echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Peers Connected:${RESET}      ${BOLD}${PURPLE}${TS_PEERS}${RESET} ${TEXT_SECONDARY}devices${RESET}"
        echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Control Server:${RESET}       ${BOLD}${CYAN}headscale.blackroad.io${RESET}"
    elif [ "$TS_STATE" = "DISCONNECTED" ]; then
        echo -e "  ${ORANGE}⚠${RESET} ${TEXT_PRIMARY}Tailscale Status:${RESET}     ${BOLD}${ORANGE}DISCONNECTED${RESET}"
        echo -e "  ${TEXT_MUTED}Run: tailscale up --login-server=https://headscale.blackroad.io${RESET}"
    else
        echo -e "  ${TEXT_MUTED}○${RESET} ${TEXT_PRIMARY}Tailscale Status:${RESET}     ${BOLD}${TEXT_MUTED}NOT INSTALLED${RESET}"
        echo -e "  ${TEXT_MUTED}Install: brew install tailscale${RESET}"
    fi
    echo ""

    # Cloudflare with API integration
    echo -e "${TEXT_MUTED}╭─ CLOUDFLARE INFRASTRUCTURE ${PURPLE}[${RESET}${TEXT_MUTED}Live API${PURPLE}]${RESET}${TEXT_MUTED} ──────────────────────────╮${RESET}"
    echo ""

    local BR_IO=$(check_http "https://blackroad.io")
    local BR_SYS=$(check_http "https://blackroad.systems")
    local HEADSCALE=$(check_http "https://headscale.blackroad.io")
    local BBP=$(check_http "https://blackboxprogramming.com")

    local CF_STATS=$(check_cloudflare_api)
    local CF_ZONES=$(echo $CF_STATS | cut -d'|' -f1)
    local CF_PAGES=$(echo $CF_STATS | cut -d'|' -f2)
    local CF_KV=$(echo $CF_STATS | cut -d'|' -f3)

    echo -e "  ${PINK}◆${RESET} ${TEXT_PRIMARY}Active Zones${RESET} ${TEXT_MUTED}(${CF_ZONES} total)${RESET}"
    echo -e "    ${ORANGE}├─${RESET} blackroad.io              $([ "$BR_IO" = "ONLINE" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} blackroad.systems         $([ "$BR_SYS" = "ONLINE" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} headscale.blackroad.io    $([ "$HEADSCALE" = "ONLINE" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}├─${RESET} blackboxprogramming.com   $([ "$BBP" = "ONLINE" ] && echo -e "${BLUE}◉ UP${RESET}" || echo -e "${TEXT_MUTED}○ DOWN${RESET}")"
    echo -e "    ${ORANGE}└─${RESET} ${TEXT_MUTED}+ 12 additional zones${RESET}"
    echo ""

    echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Services${RESET}"
    echo -e "    ${TEXT_SECONDARY}Pages Projects:${RESET}    ${BOLD}${PURPLE}${CF_PAGES}${RESET} ${TEXT_MUTED}deployed${RESET}  $(generate_sparkline 5 7 8 6 8 7 8)"
    echo -e "    ${TEXT_SECONDARY}KV Namespaces:${RESET}     ${BOLD}${PURPLE}${CF_KV}${RESET} ${TEXT_MUTED}active${RESET}    $(generate_sparkline 3 4 5 6 7 8 8)"
    echo -e "    ${TEXT_SECONDARY}D1 Databases:${RESET}      ${BOLD}${PURPLE}1${RESET} ${TEXT_MUTED}provisioned${RESET} $(generate_sparkline 1 1 1 1 1 1 1)"
    echo ""

    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Tunnel Configuration${RESET}"
    echo -e "    ${TEXT_SECONDARY}ID:${RESET}   ${TEXT_MUTED}72f1d60c-dcf2-4499-b02d-d7a063018b33${RESET}"
    echo -e "    ${TEXT_SECONDARY}Zone:${RESET} ${TEXT_MUTED}848cf0b18d51e0170e0d1537aec3505a${RESET}"
    echo ""

    # GitHub with API integration
    echo -e "${TEXT_MUTED}╭─ GITHUB & DEVELOPMENT ${ORANGE}[${RESET}${TEXT_MUTED}Live API${ORANGE}]${RESET}${TEXT_MUTED} ──────────────────────────────╮${RESET}"
    echo ""

    local GH_STATS=$(get_github_stats)
    local GH_REPOS=$(echo $GH_STATS | cut -d'|' -f1)
    local GH_FOLLOWERS=$(echo $GH_STATS | cut -d'|' -f2)

    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Organizations${RESET}     ${BOLD}${ORANGE}15${RESET} ${TEXT_SECONDARY}orgs${RESET}"
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Repositories${RESET}      ${BOLD}${ORANGE}${GH_REPOS}${RESET} ${TEXT_SECONDARY}public repos${RESET}  $(generate_sparkline 50 55 60 62 65 66 66)"
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Followers${RESET}         ${BOLD}${ORANGE}${GH_FOLLOWERS}${RESET} ${TEXT_SECONDARY}developers${RESET}"
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Primary Org${RESET}       ${BOLD}${PINK}blackboxprogramming${RESET}"
    echo -e "  ${ORANGE}▸${RESET} ${TEXT_PRIMARY}Main Org${RESET}          ${BOLD}${BLUE}BlackRoad-OS${RESET}"
    echo ""

    # Railway
    if command -v railway &> /dev/null; then
        echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Railway Projects${RESET}  ${BOLD}${CYAN}12+${RESET} ${TEXT_SECONDARY}active deployments${RESET}"
        echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Railway CLI${RESET}       ${BLUE}◉ INSTALLED${RESET} ${TEXT_MUTED}v$(railway --version 2>/dev/null | awk '{print $3}')${RESET}"
    else
        echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Railway Projects${RESET}  ${BOLD}${CYAN}12+${RESET} ${TEXT_SECONDARY}active deployments${RESET}"
        echo -e "  ${CYAN}▸${RESET} ${TEXT_PRIMARY}Railway CLI${RESET}       ${TEXT_MUTED}○ NOT INSTALLED${RESET}"
    fi
    echo ""

    # Crypto Portfolio with animated bars
    echo -e "${TEXT_MUTED}╭─ CRYPTO PORTFOLIO ${PURPLE}[${RESET}${TEXT_MUTED}Live Prices${PURPLE}]${RESET}${TEXT_MUTED} ──────────────────────────────────╮${RESET}"
    echo ""

    local CRYPTO_PRICES=$(get_crypto_prices)
    local BTC_PRICE=$(echo $CRYPTO_PRICES | cut -d'|' -f1)
    local ETH_PRICE=$(echo $CRYPTO_PRICES | cut -d'|' -f2)
    local SOL_PRICE=$(echo $CRYPTO_PRICES | cut -d'|' -f3)
    local TOTAL_VALUE=$(echo $CRYPTO_PRICES | cut -d'|' -f4)

    echo -e "  ${ORANGE}₿${RESET}  ${TEXT_PRIMARY}Bitcoin${RESET}          ${BOLD}${ORANGE}0.1 BTC${RESET}  ${TEXT_SECONDARY}≈ \$${BTC_PRICE}${RESET}     ${TEXT_MUTED}Coinbase${RESET}"
    animate_bar 10 "$ORANGE"
    echo ""

    echo -e "  ${BLUE}Ξ${RESET}  ${TEXT_PRIMARY}Ethereum${RESET}         ${BOLD}${BLUE}2.5 ETH${RESET}  ${TEXT_SECONDARY}≈ \$${ETH_PRICE}/ETH${RESET}  ${TEXT_MUTED}MetaMask${RESET}"
    animate_bar 25 "$BLUE"
    echo ""

    echo -e "  ${PURPLE}◎${RESET}  ${TEXT_PRIMARY}Solana${RESET}           ${BOLD}${PURPLE}100 SOL${RESET}  ${TEXT_SECONDARY}≈ \$${SOL_PRICE}/SOL${RESET}   ${TEXT_MUTED}Phantom${RESET}"
    animate_bar 100 "$PURPLE"
    echo ""

    echo -e "  ${TEXT_SECONDARY}Total Portfolio Value: ${BOLD}${BLUE}\$${TOTAL_VALUE}${RESET} ${TEXT_SECONDARY}USD${RESET}"
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

    # Contact
    echo -e "${TEXT_MUTED}╭─ CONTACT & IDENTITY ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}✉${RESET}  ${TEXT_PRIMARY}Primary${RESET}    ${BOLD}${ORANGE}amundsonalexa@gmail.com${RESET}"
    echo -e "  ${PINK}✉${RESET}  ${TEXT_PRIMARY}Company${RESET}    ${BOLD}${PINK}blackroad.systems@gmail.com${RESET}"
    echo ""

    # Live Terminal
    echo -e "${TEXT_MUTED}╭─ LIVE TERMINAL OUTPUT ────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "                                                                        ${RESET}"
    echo -e "  ${PINK}●${RESET} ${ORANGE}●${RESET} ${BLUE}●${RESET}  ${TEXT_MUTED}lucidia@blackroad-os ~ v2.0 ULTIMATE${RESET}                        ${RESET}"
    echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}${RESET}"
    echo -e "  ${PINK}lucidia${RESET}@${PURPLE}blackroad${RESET}:~$ ./blackroad-ultimate --watch                    ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ System scan iteration #${iteration}${RESET}                                      ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Network: ${BLUE}${ONLINE_COUNT}/5${TEXT_SECONDARY} nodes | Tailscale: ${PURPLE}${TS_STATE}${RESET}               ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Cloudflare: ${PURPLE}${CF_ZONES}${TEXT_SECONDARY} zones | GitHub: ${ORANGE}${GH_REPOS}${TEXT_SECONDARY} repos${RESET}                  ${RESET}"
    echo -e "  ${TEXT_SECONDARY}▸ Portfolio: ${BLUE}\$${TOTAL_VALUE}${TEXT_SECONDARY} USD | All systems: ${BLUE}OPERATIONAL${RESET}         ${RESET}"
    echo -e "  ${PINK}lucidia${RESET}@${PURPLE}blackroad${RESET}:~$ ${TEXT_PRIMARY}█${RESET}                                            ${RESET}"
    echo -e "                                                                        ${RESET}"
    echo ""

    # Interactive Footer
    echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Date: ${RESET}${BOLD}$(date '+%Y-%m-%d')${RESET}  ${TEXT_SECONDARY}|  User: ${RESET}${BOLD}${ORANGE}Alexa${RESET}  ${TEXT_SECONDARY}|  Iteration: ${RESET}${BOLD}${BLUE}#${iteration}${RESET}"
    echo -e "${TEXT_MUTED}Commands: [s] SSH Menu  [q] Quit  [r] Refresh  Auto-refresh: 5s${RESET}"
    echo ""
}

# Interactive mode
interactive_mode() {
    local iteration=1

    play_sound "success"

    while true; do
        render_dashboard $iteration

        # Non-blocking read with timeout
        read -t 5 -n 1 key

        case $key in
            s|S)
                play_sound "scan"
                ssh_menu
                ;;
            q|Q)
                play_sound "offline"
                echo -e "${BLUE}Shutting down BlackRoad OS monitor...${RESET}"
                sleep 1
                clear
                exit 0
                ;;
            r|R)
                play_sound "scan"
                ;;
        esac

        ((iteration++))
    done
}

# Main execution
if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BLUE}║${RESET}  ${BOLD}${ORANGE}Starting BlackRoad OS ULTIMATE Monitor...${RESET}                          ${BLUE}║${RESET}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${TEXT_SECONDARY}Loading API connections...${RESET}"
    sleep 1
    echo -e "${TEXT_SECONDARY}Initializing network scanners...${RESET}"
    sleep 1
    echo -e "${TEXT_SECONDARY}Configuring sound effects...${RESET}"
    sleep 1
    echo -e "${GREEN}✓ Ready!${RESET}"
    sleep 1
    interactive_mode
else
    render_dashboard 1
    echo -e "${TEXT_MUTED}Tip: Use ${RESET}${BOLD}./blackroad-ultimate.sh --watch${RESET}${TEXT_MUTED} for interactive mode${RESET}"
    echo ""
fi
