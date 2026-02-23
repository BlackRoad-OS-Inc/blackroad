#!/bin/bash
# Generate WireGuard keys for all devices
# Run from Mac
set -euo pipefail

KEYS_DIR="$(dirname "$0")/keys"
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# Check wg is available
if ! command -v wg &>/dev/null; then
  echo "Install WireGuard tools first:"
  echo "  macOS: brew install wireguard-tools"
  echo "  Linux: sudo apt install wireguard-tools"
  exit 1
fi

DEVICES=(
  "codex-infinity"   # 10.10.0.1 - DO primary edge
  "cecilia"          # 10.10.0.2 - DB + DNS
  "lucidia"          # 10.10.0.3 - MinIO
  "octavia"          # 10.10.0.4 - App server
  "aria"             # 10.10.0.5 - AI + Mesh
  "shellfish"        # 10.10.0.6 - DO failover
  "alice"            # 10.10.0.7 - Monitoring
)

echo ""
echo "═══════════════════════════════════════════════════"
echo "  WireGuard Key Generation"
echo "═══════════════════════════════════════════════════"
echo ""

for device in "${DEVICES[@]}"; do
  privkey=$(wg genkey)
  pubkey=$(echo "$privkey" | wg pubkey)

  echo "$privkey" > "$KEYS_DIR/${device}.key"
  echo "$pubkey" > "$KEYS_DIR/${device}.pub"
  chmod 600 "$KEYS_DIR/${device}.key"

  log "$device"
  info "  Private: $KEYS_DIR/${device}.key"
  info "  Public:  $pubkey"
done

echo ""
log "Keys saved to: $KEYS_DIR/"
echo ""
echo "SECURITY: Keep .key files secret! Only share .pub files."
echo "These keys are needed by setup-edge.sh and setup-pi-wireguard.sh"
