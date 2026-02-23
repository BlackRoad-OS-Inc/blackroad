#!/bin/bash
# Phase 3: Setup WireGuard + Caddy on codex-infinity (159.65.43.12)
# Run ON codex-infinity: bash /tmp/setup-edge.sh
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1" >&2; }
info()  { echo -e "${CYAN}[i]${NC} $1"; }

# These must be set before running
CODEX_WG_PRIVKEY="${CODEX_WG_PRIVKEY:?Set CODEX_WG_PRIVKEY}"
CECILIA_WG_PUBKEY="${CECILIA_WG_PUBKEY:?Set CECILIA_WG_PUBKEY}"
LUCIDIA_WG_PUBKEY="${LUCIDIA_WG_PUBKEY:?Set LUCIDIA_WG_PUBKEY}"
OCTAVIA_WG_PUBKEY="${OCTAVIA_WG_PUBKEY:?Set OCTAVIA_WG_PUBKEY}"
ARIA_WG_PUBKEY="${ARIA_WG_PUBKEY:?Set ARIA_WG_PUBKEY}"
ALICE_WG_PUBKEY="${ALICE_WG_PUBKEY:?Set ALICE_WG_PUBKEY}"
CF_API_TOKEN="${CF_API_TOKEN:?Set CF_API_TOKEN for Caddy DNS challenge}"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Phase 3: Edge Setup - codex-infinity"
echo "  IP: $(hostname -I | awk '{print $1}')"
echo "═══════════════════════════════════════════════════"
echo ""

# ─── WIREGUARD ───
setup_wireguard() {
  log "Installing WireGuard..."
  apt update && apt install -y wireguard

  cat > /etc/wireguard/wg0.conf << WGCONF
[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = ${CODEX_WG_PRIVKEY}
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; sysctl -w net.ipv4.ip_forward=1
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Cecilia - DB + DNS (Pi 5)
[Peer]
PublicKey = ${CECILIA_WG_PUBKEY}
AllowedIPs = 10.10.0.2/32
PersistentKeepalive = 25

# Lucidia - MinIO (Pi 5)
[Peer]
PublicKey = ${LUCIDIA_WG_PUBKEY}
AllowedIPs = 10.10.0.3/32
PersistentKeepalive = 25

# Octavia - App Server (Pi 5)
[Peer]
PublicKey = ${OCTAVIA_WG_PUBKEY}
AllowedIPs = 10.10.0.4/32
PersistentKeepalive = 25

# Aria - AI + Mesh (Pi 5)
[Peer]
PublicKey = ${ARIA_WG_PUBKEY}
AllowedIPs = 10.10.0.5/32
PersistentKeepalive = 25

# Alice - Monitoring (Pi 4)
[Peer]
PublicKey = ${ALICE_WG_PUBKEY}
AllowedIPs = 10.10.0.7/32
PersistentKeepalive = 25
WGCONF

  chmod 600 /etc/wireguard/wg0.conf
  systemctl enable wg-quick@wg0
  systemctl start wg-quick@wg0
  log "WireGuard running (10.10.0.1)"
}

# ─── CADDY ───
setup_caddy() {
  log "Installing Caddy with Cloudflare DNS module..."

  # Install xcaddy to build custom Caddy
  apt install -y golang debian-keyring debian-archive-keyring apt-transport-https curl

  # Download Caddy with cloudflare DNS plugin
  curl -o /tmp/caddy "https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com/caddy-dns/cloudflare"
  chmod +x /tmp/caddy
  mv /tmp/caddy /usr/bin/caddy

  # Stop any existing web servers
  systemctl stop nginx 2>/dev/null || true
  systemctl disable nginx 2>/dev/null || true
  systemctl stop apache2 2>/dev/null || true
  systemctl disable apache2 2>/dev/null || true

  # Create Caddy environment file
  mkdir -p /etc/caddy
  cat > /etc/caddy/env << ENV
CF_API_TOKEN=${CF_API_TOKEN}
ENV
  chmod 600 /etc/caddy/env

  # Write the Caddyfile
  cat > /etc/caddy/Caddyfile << 'CADDYFILE'
{
    email blackroad.systems@gmail.com
    acme_dns cloudflare {env.CF_API_TOKEN}
}

# ══════════════════════════════════════════════
# TIER 1: Critical API Services
# ══════════════════════════════════════════════

# API Gateway (Octavia :3000)
api.blackroad.io {
    reverse_proxy 10.10.0.4:3000
    header {
        X-Powered-By "BlackRoad OS"
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
    }
}

core.blackroad.io {
    reverse_proxy 10.10.0.4:3000
}

operator.blackroad.io {
    reverse_proxy 10.10.0.4:3001
}

# Payment Gateway (Cecilia :3002 - same machine as DB for security)
pay.blackroad.io, payments.blackroad.io {
    reverse_proxy 10.10.0.2:3002
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Content-Security-Policy "default-src 'self' https://js.stripe.com; script-src 'self' 'unsafe-inline' https://js.stripe.com; frame-src https://js.stripe.com"
    }
}

# Command Center (Octavia :3003)
cmd.blackroad.io {
    reverse_proxy 10.10.0.4:3003
}

# Tools API (Octavia :3004)
tools.blackroad.io {
    reverse_proxy 10.10.0.4:3004
}

# Agents API (Octavia :3005)
agents.blackroad.io {
    reverse_proxy 10.10.0.4:3005
}

# ══════════════════════════════════════════════
# TIER 2: Site/Page Workers
# ══════════════════════════════════════════════

# Main site (Octavia :8080)
blackroad.io, www.blackroad.io {
    reverse_proxy 10.10.0.4:8080
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }
}

# Prism Console (Octavia :8081)
prism.blackroad.io {
    reverse_proxy 10.10.0.4:8081
}

# Mesh (Octavia :8082)
mesh.blackroad.io {
    reverse_proxy 10.10.0.4:8082
}

# Platform Hub (Octavia :8083)
hub.blackroad.io {
    reverse_proxy 10.10.0.4:8083
}

# Jobs Platform (Octavia :8084)
jobs.blackroad.io {
    reverse_proxy 10.10.0.4:8084
}

# Dashboard (Octavia :8085)
dashboard.blackroad.io {
    reverse_proxy 10.10.0.4:8085
}

# AI/Ollama (Aria)
ai.blackroad.io {
    reverse_proxy 10.10.0.5:11434
}

# MinIO Console (Lucidia)
storage.blackroad.io {
    reverse_proxy 10.10.0.3:9001
}

# ══════════════════════════════════════════════
# TIER 3: Subdomain Router (catch-all)
# All 67+ subdomains → single Hono service on Octavia :4000
# ══════════════════════════════════════════════

*.blackroad.io {
    reverse_proxy 10.10.0.4:4000
    header {
        X-Powered-By "BlackRoad OS"
    }
}
CADDYFILE

  # Caddy systemd service with env file
  mkdir -p /etc/systemd/system/caddy.service.d
  cat > /etc/systemd/system/caddy.service.d/override.conf << 'OVERRIDE'
[Service]
EnvironmentFile=/etc/caddy/env
OVERRIDE

  systemctl daemon-reload
  systemctl enable caddy
  systemctl start caddy
  log "Caddy running with auto-SSL"
}

# ─── FIREWALL ───
setup_firewall() {
  log "Configuring firewall..."

  apt install -y ufw
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp comment "SSH"
  ufw allow 80/tcp comment "HTTP (ACME challenge)"
  ufw allow 443/tcp comment "HTTPS"
  ufw allow 51820/udp comment "WireGuard"
  ufw --force enable
  log "Firewall: SSH, HTTP, HTTPS, WireGuard only"
}

# ─── VERIFY ───
verify() {
  echo ""
  log "Verifying..."

  # WireGuard
  if wg show wg0 &>/dev/null; then
    local peers
    peers=$(wg show wg0 peers | wc -l)
    log "  WireGuard: UP ($peers peers configured)"
  else
    error "  WireGuard: DOWN"
  fi

  # Caddy
  if systemctl is-active caddy &>/dev/null; then
    log "  Caddy: running"
  else
    error "  Caddy: not running"
    journalctl -u caddy --no-pager -n 20
  fi

  # Firewall
  info "  Firewall rules:"
  ufw status numbered 2>/dev/null | head -20
}

# ─── MAIN ───
setup_wireguard
setup_caddy
setup_firewall
verify

echo ""
echo "═══════════════════════════════════════════════════"
log "Phase 3 (edge) complete!"
info "WireGuard: 10.10.0.1 on :51820"
info "Caddy: HTTPS on :443 with auto-SSL"
info ""
info "Next: Set up WireGuard on each Pi"
info "  scp setup-pi-wireguard.sh pi@<ip>:/tmp/"
info "  ssh pi@<ip> 'sudo bash /tmp/setup-pi-wireguard.sh'"
echo "═══════════════════════════════════════════════════"
