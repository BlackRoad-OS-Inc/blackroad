#!/usr/bin/env bash
# BlackRoad Network Discovery Script
# Finds all devices on the network, identifies Raspberry Pis

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Raspberry Pi MAC prefixes
PI_PREFIXES="b8:27:eb dc:a6:32 e4:5f:01 2c:cf:67 d8:3a:dd 28:cd:c1"

is_raspberry_pi() {
    local mac="$1"
    mac=$(echo "$mac" | tr '[:upper:]' '[:lower:]')
    local prefix="${mac:0:8}"

    for p in $PI_PREFIXES; do
        if [[ "$prefix" == "$p" ]]; then
            return 0
        fi
    done
    return 1
}

get_known_name() {
    local mac="$1"
    mac=$(echo "$mac" | tr '[:upper:]' '[:lower:]')

    case "$mac" in
        "2c:cf:67:cf:fa:17") echo "Lucidia" ;;
        "88:a2:9e:0d:42:07") echo "Aria" ;;
        *) echo "" ;;
    esac
}

# SSH probe - find all SSH-accessible Pis
ssh_probe() {
    local base="${1:-192.168.4}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🖤🛣️ BLACKROAD SSH PROBE 🖤🛣️                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}Scanning ${base}.1-254 for SSH...${NC}"
    echo

    local found=0

    for i in $(seq 1 254); do
        local ip="${base}.${i}"

        # Quick port check with nc
        if nc -z -w1 "$ip" 22 2>/dev/null; then
            # Try SSH with pi user
            local hostname=$(ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=no "pi@$ip" "hostname" 2>/dev/null)

            if [[ -n "$hostname" ]]; then
                local model=$(ssh -o ConnectTimeout=2 -o BatchMode=yes "pi@$ip" "cat /proc/device-tree/model 2>/dev/null | tr -d '\0'" 2>/dev/null || echo "")
                local tailscale_ip=$(ssh -o ConnectTimeout=2 -o BatchMode=yes "pi@$ip" "tailscale ip -4 2>/dev/null" 2>/dev/null || echo "none")

                echo -e "${GREEN}✓ $ip${NC} → ${WHITE}$hostname${NC}"
                [[ -n "$model" ]] && echo -e "    Model: $model"
                [[ "$tailscale_ip" != "none" ]] && echo -e "    Tailscale: $tailscale_ip"
                ((found++))
            else
                # SSH open but auth failed
                echo -e "${YELLOW}? $ip${NC} → SSH open, auth failed (might be Pi)"
            fi
        fi
    done

    echo
    echo -e "${WHITE}Found ${GREEN}$found${WHITE} accessible Pis${NC}"
}

# Quick network scan
quick_scan() {
    local base="${1:-192.168.4}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🖤🛣️ BLACKROAD QUICK SCAN 🖤🛣️                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo

    echo -e "${WHITE}Active devices on ${base}.0/24:${NC}"
    echo

    printf "%-15s %-20s %-6s %-15s\n" "IP" "MAC" "PI?" "NAME"
    printf "%-15s %-20s %-6s %-15s\n" "---------------" "--------------------" "------" "---------------"

    for i in $(seq 1 254); do
        local ip="${base}.${i}"

        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            # Get MAC from arp
            local mac=$(arp -n "$ip" 2>/dev/null | grep -v incomplete | awk '{print $3}' | grep -v Address | head -1)

            local is_pi="No"
            local name=""

            if [[ -n "$mac" ]]; then
                if is_raspberry_pi "$mac"; then
                    is_pi="${GREEN}YES${NC}"
                    name=$(get_known_name "$mac")
                fi
            fi

            printf "%-15s %-20s " "$ip" "${mac:-unknown}"
            echo -e "$is_pi  $name"
        fi
    done
}

# Full scan with details
full_scan() {
    local base="${1:-192.168.4}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🖤🛣️ BLACKROAD FULL NETWORK SCAN 🖤🛣️              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "Scanning ${WHITE}${base}.0/24${NC} at $(date)"
    echo

    local pi_count=0
    local total=0

    echo -e "${WHITE}=== RASPBERRY PIS ===${NC}"
    echo

    for i in $(seq 1 254); do
        local ip="${base}.${i}"

        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            ((total++))
            local mac=$(arp -n "$ip" 2>/dev/null | grep -v incomplete | awk '{print $3}' | grep -v Address | head -1)

            if [[ -n "$mac" ]] && is_raspberry_pi "$mac"; then
                ((pi_count++))
                local name=$(get_known_name "$mac")

                echo -e "${GREEN}PI FOUND:${NC} $ip"
                echo -e "  MAC: $mac"
                [[ -n "$name" ]] && echo -e "  Known as: ${WHITE}$name${NC}"

                # Try SSH to get more info
                local hostname=$(ssh -o ConnectTimeout=2 -o BatchMode=yes -o StrictHostKeyChecking=no "pi@$ip" "hostname" 2>/dev/null)
                if [[ -n "$hostname" ]]; then
                    echo -e "  Hostname: ${GREEN}$hostname${NC} (SSH OK)"
                    local model=$(ssh -o ConnectTimeout=2 -o BatchMode=yes "pi@$ip" "cat /proc/device-tree/model 2>/dev/null | tr -d '\0'" 2>/dev/null)
                    [[ -n "$model" ]] && echo -e "  Model: $model"
                else
                    echo -e "  SSH: ${RED}Not accessible${NC}"
                fi
                echo
            fi
        fi
    done

    echo -e "${WHITE}=== SUMMARY ===${NC}"
    echo -e "Total devices: $total"
    echo -e "Raspberry Pis: ${GREEN}$pi_count${NC}"
}

# Add to /etc/hosts
add_to_hosts() {
    echo -e "${CYAN}Generating /etc/hosts entries...${NC}"
    echo
    echo "# BlackRoad Pi Cluster"
    echo "192.168.4.38    lucidia"
    echo "192.168.4.82    aria"
    echo "# Add these to /etc/hosts with: sudo tee -a /etc/hosts"
}

show_help() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        🖤🛣️ BLACKROAD NETWORK DISCOVERY 🖤🛣️              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo "Usage: $0 <command> [network-base]"
    echo
    echo "Commands:"
    echo "  ssh      - Find all SSH-accessible Pis (recommended)"
    echo "  quick    - Quick scan showing all devices"
    echo "  full     - Full scan with Pi details"
    echo "  hosts    - Generate /etc/hosts entries"
    echo "  help     - Show this help"
    echo
    echo "Examples:"
    echo "  $0 ssh                  # Scan 192.168.4.x"
    echo "  $0 ssh 192.168.1        # Scan 192.168.1.x"
    echo "  $0 quick 10.0.0         # Scan 10.0.0.x"
}

# Main
case "${1:-help}" in
    ssh)   ssh_probe "${2:-192.168.4}" ;;
    quick) quick_scan "${2:-192.168.4}" ;;
    full)  full_scan "${2:-192.168.4}" ;;
    hosts) add_to_hosts ;;
    *)     show_help ;;
esac
