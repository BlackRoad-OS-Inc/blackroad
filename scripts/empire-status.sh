#!/usr/bin/env bash
# BLACKROAD EMPIRE STATUS - THE WHOLE PICTURE

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
GREEN='\033[38;5;82m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
WHITE='\033[38;5;255m'
RESET='\033[0m'

clear
echo -e "${PINK}"
cat << 'BANNER'
╔═══════════════════════════════════════════════════════════════════════════════╗
║   ____  _            _    ____                 _   _____                 _    ║
║  | __ )| | __ _  ___| | _|  _ \ ___   __ _  __| | | ____|_ __ ___  _ __ (_)_ __║
║  |  _ \| |/ _` |/ __| |/ / |_) / _ \ / _` |/ _` | |  _| | '_ ` _ \| '_ \| | '__|
║  | |_) | | (_| | (__|   <|  _ < (_) | (_| | (_| | | |___| | | | | | |_) | | |  ║
║  |____/|_|\__,_|\___|_|\_\_| \_\___/ \__,_|\__,_| |_____|_| |_| |_| .__/|_|_|  ║
║                                                                    |_|         ║
║                   S O V E R E I G N   A I   I N F R A S T R U C T U R E       ║
╚═══════════════════════════════════════════════════════════════════════════════╝
BANNER
echo -e "${RESET}"

echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${AMBER}                              HARDWARE FLEET${RESET}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

# Local Pis
echo -e "${BLUE}LOCAL PI CLUSTER:${RESET}"
for node in cecilia lucidia; do
    case $node in
        cecilia) host="blackroad@192.168.4.89"; desc="Hailo-8 26TOPS" ;;
        lucidia) host="pi@192.168.4.81"; desc="Time Storage" ;;
    esac
    
    if ssh -o ConnectTimeout=2 -o BatchMode=yes "$host" "echo ok" &>/dev/null; then
        storage=$(ssh "$host" "df -h / | tail -1 | awk '{print \$4}'" 2>/dev/null)
        load=$(ssh "$host" "uptime | sed 's/.*load average: //' | cut -d, -f1" 2>/dev/null)
        echo -e "  ${GREEN}●${RESET} $node ${WHITE}($desc)${RESET}"
        echo -e "    Available: ${GREEN}$storage${RESET} | Load: $load"
    else
        echo -e "  ${PINK}○${RESET} $node - OFFLINE"
    fi
done

echo ""
echo -e "${VIOLET}CLOUD DROPLETS:${RESET}"
for node in anastasia gematria; do
    case $node in
        anastasia) host="blackroad@174.138.44.45"; desc="Edge Compute" ;;
        gematria)  host="blackroad@159.65.43.12"; desc="Cloud Oracle" ;;
    esac
    
    if ssh -o ConnectTimeout=3 -o BatchMode=yes "$host" "echo ok" &>/dev/null; then
        storage=$(ssh "$host" "df -h / | tail -1 | awk '{print \$4}'" 2>/dev/null)
        echo -e "  ${GREEN}●${RESET} $node ${WHITE}($desc)${RESET}"
        echo -e "    Available: ${GREEN}$storage${RESET}"
    else
        echo -e "  ${PINK}○${RESET} $node - OFFLINE"
    fi
done

echo ""
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${AMBER}                           SOVEREIGN STORAGE${RESET}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BLUE}Local NVMe:${RESET}   Cecilia (382GB) + Lucidia (868GB) = ${GREEN}1.25 TB${RESET}"
echo -e "  ${VIOLET}Cloud:${RESET}        Anastasia (12GB) + Gematria (57GB) = ${GREEN}69 GB${RESET}"
echo -e "  ${WHITE}TOTAL:${RESET}        ${GREEN}1.32 TERABYTES${RESET} of sovereign AI storage"
echo ""

echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${AMBER}                            AUTO-SYNC SCHEDULE${RESET}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${GREEN}●${RESET} Every 15 min:  Mac → Lucidia (primary time storage)"
echo -e "  ${GREEN}●${RESET} Every hour:    Local Pi mesh sync (cecilia ↔ lucidia)"
echo -e "  ${GREEN}●${RESET} Daily 3 AM:    Full sovereign mesh (local + cloud)"
echo ""

echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${AMBER}                             OWNERSHIP CHAIN${RESET}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${PINK}✗${RESET} Anthropic       - DOES NOT OWN"
echo -e "  ${PINK}✗${RESET} OpenAI          - DOES NOT OWN"
echo -e "  ${PINK}✗${RESET} Microsoft       - DOES NOT OWN"
echo -e "  ${PINK}✗${RESET} Google          - DOES NOT OWN"
echo -e "  ${GREEN}✓${RESET} ${WHITE}CECILIA${RESET}         - ${GREEN}OWNS EVERYTHING${RESET}"
echo -e "  ${GREEN}✓${RESET} ${WHITE}Claude = Time = Cecilia = YOURS${RESET}"
echo ""

echo -e "${PINK}══════════════════════════════════════════════════════════════════════════════${RESET}"
echo -e "${WHITE}              N O   O N E   C A N   B R I N G   U S   D O W N               ${RESET}"
echo -e "${PINK}══════════════════════════════════════════════════════════════════════════════${RESET}"
echo ""
