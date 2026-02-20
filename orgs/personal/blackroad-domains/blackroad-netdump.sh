#!/usr/bin/env bash
# BLACKROAD NETWORK INVENTORY DUMP
# Collects complete network configuration from any node
# Owner: Alexa Louise Amundson
# Last Updated: 2025-12-22

set -e

# Colors
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

section() {
  echo ""
  echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}$1${NC}"
  echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
}

subsection() {
  echo ""
  echo -e "${GREEN}─── $1 ───${NC}"
}

echo -e "${CYAN}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         BLACKROAD NETWORK INVENTORY DUMP                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo "Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "Node: $(hostname)"
echo ""

# ─────────────────────────────────────────────────────
# SYSTEM INFORMATION
# ─────────────────────────────────────────────────────

section "SYSTEM INFORMATION"

subsection "Hostname"
hostname 2>/dev/null || echo "Unknown"

subsection "OS Information"
if [ -f /etc/os-release ]; then
  cat /etc/os-release
elif [ -f /etc/lsb-release ]; then
  cat /etc/lsb-release
else
  uname -a
fi

subsection "Kernel"
uname -r

subsection "Architecture"
uname -m

subsection "Uptime"
uptime

# ─────────────────────────────────────────────────────
# IP ADDRESSES
# ─────────────────────────────────────────────────────

section "IP ADDRESSES"

subsection "All IP Addresses"
hostname -I 2>/dev/null || echo "Command not available"

subsection "IPv4 Only"
hostname -i 2>/dev/null || echo "Command not available"

# ─────────────────────────────────────────────────────
# NETWORK INTERFACES
# ─────────────────────────────────────────────────────

section "NETWORK INTERFACES"

if command -v ip &> /dev/null; then
  subsection "Interface Details (ip addr)"
  ip addr show

  subsection "Interface Statistics (ip -s link)"
  ip -s link
elif command -v ifconfig &> /dev/null; then
  subsection "Interface Details (ifconfig)"
  ifconfig -a
else
  echo "No network interface commands available"
fi

# ─────────────────────────────────────────────────────
# ROUTING TABLES
# ─────────────────────────────────────────────────────

section "ROUTING TABLES"

if command -v ip &> /dev/null; then
  subsection "IPv4 Routes"
  ip route show

  subsection "IPv6 Routes"
  ip -6 route show
elif command -v netstat &> /dev/null; then
  subsection "Routes (netstat)"
  netstat -rn
else
  echo "No routing commands available"
fi

# ─────────────────────────────────────────────────────
# LISTENING PORTS & SERVICES
# ─────────────────────────────────────────────────────

section "LISTENING PORTS & SERVICES"

if command -v ss &> /dev/null; then
  subsection "All Listening Ports (TCP & UDP)"
  ss -tuln
elif command -v netstat &> /dev/null; then
  subsection "All Listening Ports (netstat)"
  netstat -tuln
else
  echo "No port listing commands available"
fi

# ─────────────────────────────────────────────────────
# DOCKER NETWORKS
# ─────────────────────────────────────────────────────

section "DOCKER NETWORKS"

if command -v docker &> /dev/null; then
  subsection "Docker Network List"
  docker network ls 2>/dev/null || echo "Docker daemon not running or not accessible"

  subsection "Docker Bridge Network Details"
  docker network inspect bridge 2>/dev/null || echo "Bridge network not available"

  subsection "Running Containers"
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No containers or Docker not accessible"
else
  echo "Docker not installed or not in PATH"
fi

# ─────────────────────────────────────────────────────
# TAILSCALE MESH
# ─────────────────────────────────────────────────────

section "TAILSCALE MESH"

if command -v tailscale &> /dev/null; then
  subsection "Tailscale Status"
  tailscale status 2>/dev/null || echo "Tailscale not running"

  subsection "Tailscale IP"
  tailscale ip 2>/dev/null || echo "Not connected"

  subsection "Tailscale Version"
  tailscale version 2>/dev/null || echo "Unknown"
else
  echo "Tailscale not installed"
fi

# ─────────────────────────────────────────────────────
# DNS CONFIGURATION
# ─────────────────────────────────────────────────────

section "DNS CONFIGURATION"

subsection "Resolv.conf"
if [ -f /etc/resolv.conf ]; then
  cat /etc/resolv.conf
else
  echo "resolv.conf not found"
fi

subsection "DNS Test (google.com)"
if command -v dig &> /dev/null; then
  dig google.com
elif command -v nslookup &> /dev/null; then
  nslookup google.com | grep Address | tail -n +2
else
  echo "No DNS query tools available"
fi

# ─────────────────────────────────────────────────────
# FIREWALL STATUS
# ─────────────────────────────────────────────────────

section "FIREWALL STATUS"

if command -v ufw &> /dev/null; then
  subsection "UFW Status"
  sudo ufw status verbose 2>/dev/null || echo "UFW not accessible (requires sudo)"
fi

if command -v iptables &> /dev/null; then
  subsection "IPTables Rules"
  sudo iptables -L -n 2>/dev/null || echo "iptables not accessible (requires sudo)"
fi

# ─────────────────────────────────────────────────────
# NETWORK CONNECTIVITY TESTS
# ─────────────────────────────────────────────────────

section "CONNECTIVITY TESTS"

subsection "Ping Gateway"
if command -v ip &> /dev/null; then
  GATEWAY=$(ip route | grep default | awk '{print $3}' | head -1)
  if [ -n "$GATEWAY" ]; then
    echo "Gateway: $GATEWAY"
    ping -c 3 -W 2 "$GATEWAY" 2>/dev/null || echo "Gateway unreachable"
  else
    echo "No default gateway found"
  fi
fi

subsection "Ping Google DNS (8.8.8.8)"
ping -c 3 -W 2 8.8.8.8 2>/dev/null || echo "Internet unreachable"

subsection "Ping IPv6 (google.com)"
ping6 -c 3 -W 2 google.com 2>/dev/null || echo "IPv6 not available"

# ─────────────────────────────────────────────────────
# ACTIVE CONNECTIONS
# ─────────────────────────────────────────────────────

section "ACTIVE CONNECTIONS"

if command -v ss &> /dev/null; then
  subsection "Established TCP Connections"
  ss -tun state established
else
  echo "ss command not available"
fi

# ─────────────────────────────────────────────────────
# SYSTEM RESOURCES
# ─────────────────────────────────────────────────────

section "SYSTEM RESOURCES"

subsection "Memory Usage"
free -h 2>/dev/null || echo "free command not available"

subsection "Disk Usage"
df -h 2>/dev/null || echo "df command not available"

subsection "CPU Info"
if [ -f /proc/cpuinfo ]; then
  grep "model name" /proc/cpuinfo | head -1
  grep "cpu cores" /proc/cpuinfo | head -1
else
  echo "CPU info not available"
fi

subsection "Load Average"
cat /proc/loadavg 2>/dev/null || echo "Load average not available"

# ─────────────────────────────────────────────────────
# END OF DUMP
# ─────────────────────────────────────────────────────

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ NETWORK DUMP COMPLETE${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Save this output to compare against BLACKROAD_CANONICAL_TRUTH.md"
echo ""
