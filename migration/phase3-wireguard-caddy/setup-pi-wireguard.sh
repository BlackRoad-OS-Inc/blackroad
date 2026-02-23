#!/bin/bash
# Setup WireGuard on a Pi to connect to codex-infinity
# Run ON each Pi: sudo bash setup-pi-wireguard.sh <device-name>
# Example: sudo bash setup-pi-wireguard.sh cecilia
set -euo pipefail

DEVICE="${1:?Usage: $0 <device-name> (cecilia|lucidia|octavia|aria|alice)}"

CODEX_PUBKEY="${CODEX_WG_PUBKEY:?Set CODEX_WG_PUBKEY}"
MY_PRIVKEY="${MY_WG_PRIVKEY:?Set MY_WG_PRIVKEY}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# Device → WireGuard IP mapping
declare -A WG_IPS=(
  ["cecilia"]="10.10.0.2"
  ["lucidia"]="10.10.0.3"
  ["octavia"]="10.10.0.4"
  ["aria"]="10.10.0.5"
  ["alice"]="10.10.0.7"
)

MY_IP="${WG_IPS[$DEVICE]}"
if [ -z "$MY_IP" ]; then
  echo "Unknown device: $DEVICE"
  echo "Valid: cecilia, lucidia, octavia, aria, alice"
  exit 1
fi

log "Setting up WireGuard for $DEVICE ($MY_IP)"

# Install WireGuard
apt update && apt install -y wireguard

# Write config
cat > /etc/wireguard/wg0.conf << WGCONF
[Interface]
Address = ${MY_IP}/24
PrivateKey = ${MY_PRIVKEY}

[Peer]
PublicKey = ${CODEX_PUBKEY}
Endpoint = 159.65.43.12:51820
AllowedIPs = 10.10.0.0/24
PersistentKeepalive = 25
WGCONF

chmod 600 /etc/wireguard/wg0.conf

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Verify
sleep 2
if ping -c 1 -W 3 10.10.0.1 &>/dev/null; then
  log "Connected to codex-infinity (10.10.0.1)"
else
  echo -e "\033[1;33m[!]\033[0m Cannot ping 10.10.0.1 yet - may need NAT traversal time"
fi

log "WireGuard configured for $DEVICE at $MY_IP"
