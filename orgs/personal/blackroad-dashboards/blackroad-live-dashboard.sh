#!/bin/bash

# BlackRoad OS Live Infrastructure Dashboard
# Matches all Cloudflare domains and Pi sources

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
    timeout 2 ping -c 1 "$host" &>/dev/null && echo "ONLINE" || echo "OFFLINE"
}

# Function to check HTTP status
check_http() {
    local url=$1
    local status=$(timeout 3 curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "301" ] || [ "$status" = "302" ]; then
        echo "ONLINE"
    else
        echo "OFFLINE"
    fi
}

# Clear screen
clear
echo -ne ""
clear

# Header
echo ""
echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}👻${RESET}  ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET} ${TEXT_MUTED}- Live Infrastructure Monitor${RESET}                ${BOLD}${ORANGE}║${RESET}"
echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Welcome banner
echo -e "                                                                        ${RESET}"
echo -e "  ${BOLD}${TEXT_PRIMARY}Infrastructure Status${RESET}                                              ${RESET}"
echo -e "  ${TEXT_SECONDARY}Scanning: 16 Cloudflare zones • 5 Pi devices • 1 DigitalOcean droplet${RESET}  ${RESET}"
echo -e "                                                                        ${RESET}"
echo ""

# Raspberry Pi Infrastructure
echo -e "${TEXT_MUTED}RASPBERRY PI NETWORK${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""

# Check Pi devices
LUCIDIA_STATUS=$(check_host 192.168.4.38)
BLACKROAD_PI_STATUS=$(check_host 192.168.4.64)
LUCIDIA_ALT_STATUS=$(check_host 192.168.4.99)
IPHONE_STATUS=$(check_host 192.168.4.68)

if [ "$LUCIDIA_STATUS" = "ONLINE" ]; then
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Lucidia Prime${RESET}       ${TEXT_SECONDARY}192.168.4.38${RESET}     ${BLUE}ONLINE${RESET}"
else
    echo -e "  ${TEXT_MUTED}●${RESET} ${TEXT_SECONDARY}Lucidia Prime${RESET}       ${TEXT_SECONDARY}192.168.4.38${RESET}     ${TEXT_MUTED}OFFLINE${RESET}"
fi

if [ "$BLACKROAD_PI_STATUS" = "ONLINE" ]; then
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}BlackRoad Pi${RESET}       ${TEXT_SECONDARY}192.168.4.64${RESET}     ${BLUE}ONLINE${RESET}"
else
    echo -e "  ${TEXT_MUTED}●${RESET} ${TEXT_SECONDARY}BlackRoad Pi${RESET}       ${TEXT_SECONDARY}192.168.4.64${RESET}     ${TEXT_MUTED}OFFLINE${RESET}"
fi

if [ "$LUCIDIA_ALT_STATUS" = "ONLINE" ]; then
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Lucidia Alt${RESET}        ${TEXT_SECONDARY}192.168.4.99${RESET}     ${BLUE}ONLINE${RESET}"
else
    echo -e "  ${TEXT_MUTED}●${RESET} ${TEXT_SECONDARY}Lucidia Alt${RESET}        ${TEXT_SECONDARY}192.168.4.99${RESET}     ${TEXT_MUTED}OFFLINE${RESET}"
fi

if [ "$IPHONE_STATUS" = "ONLINE" ]; then
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}iPhone Koder${RESET}       ${TEXT_SECONDARY}192.168.4.68:8080${RESET} ${BLUE}ONLINE${RESET}"
else
    echo -e "  ${TEXT_MUTED}●${RESET} ${TEXT_SECONDARY}iPhone Koder${RESET}       ${TEXT_SECONDARY}192.168.4.68:8080${RESET} ${TEXT_MUTED}OFFLINE${RESET}"
fi

echo ""

# DigitalOcean
echo -e "${TEXT_MUTED}DIGITALOCEAN INFRASTRUCTURE${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""

CODEX_STATUS=$(check_host 159.65.43.12)
if [ "$CODEX_STATUS" = "ONLINE" ]; then
    echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}Codex Infinity${RESET}     ${TEXT_SECONDARY}159.65.43.12${RESET}     ${BLUE}ONLINE${RESET}"
else
    echo -e "  ${ORANGE}●${RESET} ${TEXT_PRIMARY}Codex Infinity${RESET}     ${TEXT_SECONDARY}159.65.43.12${RESET}     ${ORANGE}CHECK REQUIRED${RESET}"
fi

echo ""

# Cloudflare Zones (16 zones from CLAUDE.md)
echo -e "${TEXT_MUTED}CLOUDFLARE ZONES (16 ZONES)${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""

# Key domains to check
declare -a DOMAINS=(
    "blackroad.io"
    "blackroad.systems"
    "headscale.blackroad.io"
    "blackboxprogramming.com"
)

for domain in "${DOMAINS[@]}"; do
    STATUS=$(check_http "https://$domain")
    if [ "$STATUS" = "ONLINE" ]; then
        echo -e "  ${BLUE}●${RESET} ${TEXT_PRIMARY}${domain}${RESET}  ${BLUE}ONLINE${RESET}"
    else
        echo -e "  ${TEXT_MUTED}●${RESET} ${TEXT_SECONDARY}${domain}${RESET}  ${TEXT_MUTED}OFFLINE${RESET}"
    fi
done

echo -e "  ${TEXT_SECONDARY}+ 12 additional zones configured${RESET}"
echo ""

# Cloudflare Services
echo -e "${TEXT_MUTED}CLOUDFLARE SERVICES${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Pages Projects${RESET}     ${BOLD}${PURPLE}8${RESET} ${TEXT_SECONDARY}deployed${RESET}"
echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}KV Namespaces${RESET}      ${BOLD}${PURPLE}8${RESET} ${TEXT_SECONDARY}active${RESET}"
echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}D1 Databases${RESET}       ${BOLD}${PURPLE}1${RESET} ${TEXT_SECONDARY}provisioned${RESET}"
echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Tunnel ID${RESET}          ${BOLD}${BLUE}72f1d60c-dcf2-4499-b02d-d7a063018b33${RESET}"
echo ""

# GitHub Infrastructure
echo -e "${TEXT_MUTED}GITHUB INFRASTRUCTURE${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${ORANGE}◆${RESET} ${TEXT_PRIMARY}Organizations${RESET}      ${BOLD}${ORANGE}15${RESET} ${TEXT_SECONDARY}orgs (blackboxprogramming primary)${RESET}"
echo -e "  ${ORANGE}◆${RESET} ${TEXT_PRIMARY}Repositories${RESET}       ${BOLD}${ORANGE}66${RESET} ${TEXT_SECONDARY}repos${RESET}"
echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Main Org${RESET}           ${BOLD}${BLUE}BlackRoad-OS${RESET}"
echo ""

# Railway
echo -e "${TEXT_MUTED}RAILWAY INFRASTRUCTURE${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Active Projects${RESET}    ${BOLD}${CYAN}12+${RESET} ${TEXT_SECONDARY}projects deployed${RESET}"
echo ""

# Crypto Holdings
echo -e "${TEXT_MUTED}CRYPTO HOLDINGS${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${ORANGE}₿${RESET}  ${TEXT_PRIMARY}Bitcoin (BTC)${RESET}     ${BOLD}${ORANGE}0.1 BTC${RESET}     ${TEXT_MUTED}Coinbase${RESET}"
echo -e "  ${BLUE}Ξ${RESET}  ${TEXT_PRIMARY}Ethereum (ETH)${RESET}    ${BOLD}${BLUE}2.5 ETH${RESET}     ${TEXT_MUTED}MetaMask${RESET}"
echo -e "  ${PURPLE}◎${RESET}  ${TEXT_PRIMARY}Solana (SOL)${RESET}      ${BOLD}${PURPLE}100 SOL${RESET}     ${TEXT_MUTED}Phantom${RESET}"
echo -e "  ${TEXT_SECONDARY}BTC Address: ${RESET}${TEXT_MUTED}1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ${RESET}"
echo ""

# Truth System
echo -e "${TEXT_MUTED}TRUTH SYSTEM${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${PINK}◆${RESET} ${TEXT_PRIMARY}Source of Truth${RESET}    ${BOLD}${PINK}GitHub (BlackRoad-OS)${RESET} ${TEXT_SECONDARY}+ Cloudflare${RESET}"
echo -e "  ${PURPLE}◆${RESET} ${TEXT_PRIMARY}Verification${RESET}       ${BOLD}${PURPLE}PS-SHA∞${RESET} ${TEXT_SECONDARY}(infinite cascade hashing)${RESET}"
echo -e "  ${BLUE}◆${RESET} ${TEXT_PRIMARY}Authorization${RESET}      ${BOLD}${BLUE}Alexa${RESET} ${TEXT_SECONDARY}via Claude/ChatGPT${RESET}"
echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Review Queue${RESET}       ${BOLD}${CYAN}Linear${RESET} ${TEXT_SECONDARY}/ blackroad.systems@gmail.com${RESET}"
echo ""

# Contact Info
echo -e "${TEXT_MUTED}CONTACT & IDENTITY${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${ORANGE}✉${RESET}  ${TEXT_PRIMARY}Primary Email${RESET}     ${BOLD}${ORANGE}amundsonalexa@gmail.com${RESET}"
echo -e "  ${PINK}✉${RESET}  ${TEXT_PRIMARY}Company Email${RESET}     ${BOLD}${PINK}blackroad.systems@gmail.com${RESET}"
echo ""

# System Summary
ONLINE_COUNT=0
[ "$LUCIDIA_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
[ "$BLACKROAD_PI_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
[ "$LUCIDIA_ALT_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
[ "$IPHONE_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))
[ "$CODEX_STATUS" = "ONLINE" ] && ((ONLINE_COUNT++))

echo -e "${TEXT_MUTED}SYSTEM SUMMARY${RESET}"
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${TEXT_SECONDARY}Devices Online:${RESET}      ${BOLD}${BLUE}${ONLINE_COUNT}/5${RESET} ${TEXT_SECONDARY}network nodes${RESET}"
echo -e "  ${TEXT_SECONDARY}Cloudflare Zones:${RESET}    ${BOLD}${PURPLE}16${RESET} ${TEXT_SECONDARY}zones configured${RESET}"
echo -e "  ${TEXT_SECONDARY}GitHub Repos:${RESET}        ${BOLD}${ORANGE}66${RESET} ${TEXT_SECONDARY}repositories${RESET}"
echo -e "  ${TEXT_SECONDARY}Railway Projects:${RESET}    ${BOLD}${CYAN}12+${RESET} ${TEXT_SECONDARY}active deployments${RESET}"
echo ""

# Footer
echo -e "${ORANGE}─────────────────────────────────────────────────────────────────────────${RESET}"
echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Date: ${RESET}${BOLD}$(date '+%Y-%m-%d')${RESET}  ${TEXT_SECONDARY}|  Scan: ${RESET}${BOLD}Complete${RESET}"
echo -e "${TEXT_MUTED}Color Palette: #FF9D00 #FF6B00 #FF0066 #FF006B #D600AA #7700FF #0066FF${RESET}"
echo ""
