# BlackRoad Mesh Setup Runbook
**Version:** 1.0.0
**Updated:** 2025-12-26
**Target:** Complete mesh + operator setup with role-based menus

---

## Current Reality (Baseline)

**Devices:**
- `lucidia` - User: `lucidia`, IP: 192.168.4.38
- `alice` - User: `alice`, IP: 192.168.4.49
- `aria64` - User: `pi`, IP: 192.168.4.64
- `octavia` - User: `pi`, IP: 192.168.4.74
- `shellfish` - User: `root`, IP: 174.138.44.45 (DigitalOcean)

**Goals:**
1. Canonical SSH aliases: `br-ssh lucidia-pi`, `br-ssh alice-pi`, etc.
2. Role-based menu system on all Pis
3. Operator tools on Mac: `~/blackroad-backpack/`
4. Zero lockout risk, full verification at each step

---

## Section A: Operator-Mac Setup

### A1. Create Operator Directory Structure

```bash
# Create blackroad-backpack directory
mkdir -p ~/blackroad-backpack/{mesh,operator,legacy}

# Create mesh hosts file
cat > ~/blackroad-backpack/mesh/mesh-hosts.txt << 'EOF'
# BlackRoad Mesh Nodes
# Format: alias|user@host|role|description

lucidia-pi|lucidia@192.168.4.38|ops|Primary Development & Alt Data Storage
alice-pi|alice@192.168.4.49|ops|Kubernetes K3s Cluster Node
aria-pi|pi@192.168.4.64|sim|Simulation & Backup Node
octavia-pi|pi@192.168.4.74|holo|3D Printing & OctoPrint & Robotics
operator-shellfish|root@174.138.44.45|cloud|DigitalOcean Droplet
EOF

echo "✅ Created mesh hosts inventory"
```

### A2. Create `br-ssh` Tool

```bash
cat > ~/blackroad-backpack/operator/br-ssh << 'EOFSH'
#!/usr/bin/env bash
# BlackRoad SSH - Quick connect to mesh nodes
VERSION="1.0.0"

HOSTS_FILE="$HOME/blackroad-backpack/mesh/mesh-hosts.txt"

list_hosts() {
    echo "🖤🛣️  BlackRoad Mesh Nodes"
    echo ""
    while IFS='|' read -r alias conn role desc; do
        [[ "$alias" =~ ^# ]] && continue
        printf "  %-20s %-30s %-10s %s\n" "$alias" "$conn" "[$role]" "$desc"
    done < "$HOSTS_FILE"
}

if [[ $# -eq 0 ]] || [[ "$1" == "list" ]]; then
    list_hosts
    exit 0
fi

# Connect to specified host
HOST="$1"
shift

# Look up in hosts file
while IFS='|' read -r alias conn role desc; do
    [[ "$alias" =~ ^# ]] && continue
    if [[ "$alias" == "$HOST" ]]; then
        echo "🔌 Connecting to $HOST ($conn) [$role]"
        ssh "$HOST" "$@"
        exit $?
    fi
done < "$HOSTS_FILE"

echo "❌ Unknown host: $HOST"
echo "Run 'br-ssh list' to see available hosts"
exit 1
EOFSH

chmod +x ~/blackroad-backpack/operator/br-ssh
echo "✅ Created br-ssh tool"
```

### A3. Create `br-mesh` Tool (Run Commands on All Pis)

```bash
cat > ~/blackroad-backpack/operator/br-mesh << 'EOFMESH'
#!/usr/bin/env bash
# BlackRoad Mesh - Execute commands across all Pi nodes
VERSION="1.0.0"

HOSTS_FILE="$HOME/blackroad-backpack/mesh/mesh-hosts.txt"

if [[ $# -eq 0 ]]; then
    echo "Usage: br-mesh <command>"
    echo "Example: br-mesh 'uname -a'"
    exit 1
fi

COMMAND="$*"

echo "🖤🛣️  Executing across BlackRoad Mesh: $COMMAND"
echo ""

while IFS='|' read -r alias conn role desc; do
    [[ "$alias" =~ ^# ]] && continue
    [[ "$role" == "cloud" ]] && continue  # Skip cloud nodes

    echo "━━━ $alias ($conn) ━━━"
    ssh "$alias" "$COMMAND" || echo "⚠️  Failed on $alias"
    echo ""
done < "$HOSTS_FILE"
EOFMESH

chmod +x ~/blackroad-backpack/operator/br-mesh
echo "✅ Created br-mesh tool"
```

### A4. Add to PATH

```bash
# Add to your shell profile (bashrc/zshrc)
cat >> ~/.zshrc << 'EOF'

# BlackRoad Operator Tools
export PATH="$HOME/blackroad-backpack/operator:$PATH"
EOF

# Reload shell
source ~/.zshrc

echo "✅ Added operator tools to PATH"
```

---

## Section B: SSH Config Setup + Verification

### B1. Verify Current Keys

```bash
echo "📋 Available SSH Keys:"
ls -la ~/.ssh | egrep 'id_.*(ed25519|rsa)'
echo ""
echo "Press ENTER to continue..."
read
```

### B2. Backup Current SSH Config

```bash
cp ~/.ssh/config ~/.ssh/config.backup.$(date +%Y%m%d-%H%M%S)
echo "✅ Backed up SSH config"
```

### B3. Create Clean SSH Config

```bash
# First, let's check what the current aria64 alias points to
echo "Checking aria64 configuration..."
ssh -G aria64 | egrep '^(user|hostname|identityfile) ' | head -3

# We'll use id_br_ed25519 as primary key
# Create new SSH config with canonical hosts at the TOP (first match wins)

cat > ~/.ssh/config << 'EOFCONFIG'
# ==============================================================
# BlackRoad Mesh - Canonical Node Aliases (PRIORITY SECTION)
# ==============================================================

# Lucidia Pi - Primary Development & Alt Data Storage
Host lucidia-pi
  HostName 192.168.4.38
  User lucidia
  IdentityFile ~/.ssh/id_br_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3

# Alice Pi - Kubernetes K3s Cluster
Host alice-pi
  HostName 192.168.4.49
  User alice
  IdentityFile ~/.ssh/id_br_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3

# Aria Pi - Simulation & Backup Node
Host aria-pi
  HostName 192.168.4.64
  User pi
  IdentityFile ~/.ssh/id_br_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3

# Octavia Pi - 3D Printing & Robotics
Host octavia-pi
  HostName 192.168.4.74
  User pi
  IdentityFile ~/.ssh/id_br_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3

# Operator Shellfish - DigitalOcean Droplet
Host operator-shellfish
  HostName 174.138.44.45
  User root
  IdentityFile ~/.ssh/id_do_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3

# ==============================================================
# Legacy Aliases (Compatibility - keep your existing shortcuts)
# ==============================================================

Host lucidia
  HostName 192.168.4.38
  User lucidia
  IdentityFile ~/.ssh/id_do_ed25519

Host alice
  HostName 192.168.4.49
  User alice
  IdentityFile ~/.ssh/id_do_ed25519

Host aria64
  HostName 192.168.4.64
  User pi
  IdentityFile ~/.ssh/id_br_ed25519

Host octavia
  HostName 192.168.4.74
  User pi
  IdentityFile ~/.ssh/id_octavia

Host shellfish
  HostName 174.138.44.45
  User root
  IdentityFile ~/.ssh/id_do_ed25519

# ==============================================================
# Global Defaults
# ==============================================================
Host *
  ServerAliveInterval 30
  ServerAliveCountMax 3
  ConnectTimeout 10
  AddKeysToAgent yes

EOFCONFIG

echo "✅ Created new SSH config with canonical aliases"
```

### B4. Verify SSH Config

```bash
echo "🔍 Verifying SSH configuration for each canonical host..."
echo ""

for host in lucidia-pi alice-pi aria-pi octavia-pi operator-shellfish; do
    echo "━━━ $host ━━━"
    ssh -G "$host" | egrep '^(user|hostname|identityfile) ' | head -3
    echo ""
done

echo "Press ENTER to continue..."
read
```

### B5. Add Public Keys to Nodes (If Needed)

```bash
# Check if id_br_ed25519.pub exists
if [[ -f ~/.ssh/id_br_ed25519.pub ]]; then
    PUBKEY_FILE="~/.ssh/id_br_ed25519.pub"
elif [[ -f ~/.ssh/id_ed25519.pub ]]; then
    PUBKEY_FILE="~/.ssh/id_ed25519.pub"
else
    echo "⚠️  No ed25519 public key found. Generate one:"
    echo "ssh-keygen -t ed25519 -f ~/.ssh/id_br_ed25519 -C 'blackroad-mesh'"
    exit 1
fi

echo "Using public key: $PUBKEY_FILE"
echo ""
echo "Adding key to each node (you may need to enter passwords)..."

# Add to lucidia (using existing lucidia alias that works)
echo "→ lucidia-pi"
ssh-copy-id -i $PUBKEY_FILE lucidia@lucidia 2>/dev/null || ssh-copy-id -i $PUBKEY_FILE lucidia@192.168.4.38

# Add to alice
echo "→ alice-pi"
ssh-copy-id -i $PUBKEY_FILE alice@alice 2>/dev/null || ssh-copy-id -i $PUBKEY_FILE alice@192.168.4.49

# Add to aria (using existing aria64 alias)
echo "→ aria-pi"
ssh-copy-id -i $PUBKEY_FILE aria64 2>/dev/null || ssh-copy-id -i $PUBKEY_FILE pi@192.168.4.64

# Add to octavia
echo "→ octavia-pi"
ssh-copy-id -i $PUBKEY_FILE pi@192.168.4.74

echo ""
echo "✅ Public keys added (or already present)"
```

### B6. Test Canonical Aliases

```bash
echo "🧪 Testing canonical SSH aliases..."
echo ""

for host in lucidia-pi alice-pi aria-pi octavia-pi; do
    echo -n "Testing $host ... "
    if ssh -o ConnectTimeout=5 "$host" "echo OK" 2>/dev/null; then
        echo "✅"
    else
        echo "❌ (check keys/config)"
    fi
done

echo ""
echo "Press ENTER to continue..."
read
```

---

## Section C: Per-Node Menu Install

### C1. Create Menu Framework Files (Local)

```bash
# Create menu framework locally first
mkdir -p ~/blackroad-backpack/menu/{lib,roles}

# Main menu launcher
cat > ~/blackroad-backpack/menu/br-menu.sh << 'EOFMENU'
#!/usr/bin/env bash
# BlackRoad Node Menu System
VERSION="1.0.0"

CONFIG_FILE="/opt/blackroad/config/node.env"
LIB_DIR="/opt/blackroad/menu/lib"
ROLES_DIR="/opt/blackroad/menu/roles"

# Load node config
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    NODE_NAME="unknown"
    NODE_ROLE="generic"
fi

# Load UI helpers
source "$LIB_DIR/ui.sh"

# Load role-specific menu
source "$ROLES_DIR/${NODE_ROLE}.sh"

# Main menu loop
while true; do
    show_header "$NODE_NAME" "$NODE_ROLE"
    show_menu
    read -rp "Select option: " choice
    handle_choice "$choice"

    # Exit if requested
    [[ "$choice" == "q" || "$choice" == "Q" ]] && break
done
EOFMENU

# UI helpers
cat > ~/blackroad-backpack/menu/lib/ui.sh << 'EOFUI'
#!/usr/bin/env bash
# UI Helper Functions

show_header() {
    local node="$1"
    local role="$2"

    clear
    echo "╔════════════════════════════════════════╗"
    echo "║   🖤🛣️  BlackRoad Node Menu v1.0.0    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "  Node: $node"
    echo "  Role: $role"
    echo "  Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
}

menu_item() {
    local key="$1"
    local desc="$2"
    printf "  [%s] %s\n" "$key" "$desc"
}
EOFUI

# OPS role
cat > ~/blackroad-backpack/menu/roles/ops.sh << 'EOFOPS'
#!/usr/bin/env bash
# OPS Role Menu

show_menu() {
    menu_item "1" "System Status"
    menu_item "2" "Network Info"
    menu_item "3" "Docker Containers"
    menu_item "4" "Disk Usage"
    menu_item "5" "Memory Usage"
    menu_item "6" "Update System"
    menu_item "s" "Shell"
    menu_item "q" "Quit"
    echo ""
}

handle_choice() {
    case "$1" in
        1)
            echo "━━━ System Status ━━━"
            uptime
            echo ""
            systemctl status --no-pager | head -20
            read -rp "Press ENTER to continue..."
            ;;
        2)
            echo "━━━ Network Info ━━━"
            ip addr show
            echo ""
            ip route
            read -rp "Press ENTER to continue..."
            ;;
        3)
            echo "━━━ Docker Containers ━━━"
            docker ps -a
            read -rp "Press ENTER to continue..."
            ;;
        4)
            echo "━━━ Disk Usage ━━━"
            df -h
            read -rp "Press ENTER to continue..."
            ;;
        5)
            echo "━━━ Memory Usage ━━━"
            free -h
            read -rp "Press ENTER to continue..."
            ;;
        6)
            echo "━━━ Update System ━━━"
            sudo apt update && sudo apt upgrade -y
            read -rp "Press ENTER to continue..."
            ;;
        s|S)
            echo "Launching shell... (type 'exit' to return)"
            bash
            ;;
        q|Q)
            echo "Goodbye!"
            ;;
        *)
            echo "Invalid choice"
            sleep 1
            ;;
    esac
}
EOFOPS

# SIM role
cat > ~/blackroad-backpack/menu/roles/sim.sh << 'EOFSIM'
#!/usr/bin/env bash
# SIM (Simulation) Role Menu

show_menu() {
    menu_item "1" "System Status"
    menu_item "2" "Run Simulation"
    menu_item "3" "View Logs"
    menu_item "s" "Shell"
    menu_item "q" "Quit"
    echo ""
}

handle_choice() {
    case "$1" in
        1)
            echo "━━━ System Status ━━━"
            uptime
            read -rp "Press ENTER to continue..."
            ;;
        2)
            echo "━━━ Run Simulation ━━━"
            echo "Simulation runner not yet configured"
            read -rp "Press ENTER to continue..."
            ;;
        3)
            echo "━━━ Logs ━━━"
            journalctl -n 50 --no-pager
            read -rp "Press ENTER to continue..."
            ;;
        s|S)
            bash
            ;;
        q|Q)
            echo "Goodbye!"
            ;;
        *)
            echo "Invalid choice"
            sleep 1
            ;;
    esac
}
EOFSIM

# HOLO role (for octavia - 3D printing)
cat > ~/blackroad-backpack/menu/roles/holo.sh << 'EOFHOLO'
#!/usr/bin/env bash
# HOLO (Holographic/3D) Role Menu

show_menu() {
    menu_item "1" "System Status"
    menu_item "2" "OctoPrint Status"
    menu_item "3" "Printer Info"
    menu_item "4" "View Camera"
    menu_item "s" "Shell"
    menu_item "q" "Quit"
    echo ""
}

handle_choice() {
    case "$1" in
        1)
            echo "━━━ System Status ━━━"
            uptime
            echo ""
            vcgencmd measure_temp 2>/dev/null || echo "Temp sensor unavailable"
            read -rp "Press ENTER to continue..."
            ;;
        2)
            echo "━━━ OctoPrint Status ━━━"
            systemctl status octoprint --no-pager 2>/dev/null || echo "OctoPrint not installed"
            read -rp "Press ENTER to continue..."
            ;;
        3)
            echo "━━━ Printer Info ━━━"
            echo "3D Printer control interface"
            echo "Access OctoPrint at: http://$(hostname -I | awk '{print $1}'):5000"
            read -rp "Press ENTER to continue..."
            ;;
        4)
            echo "━━━ Camera ━━━"
            echo "Camera stream not yet configured"
            read -rp "Press ENTER to continue..."
            ;;
        s|S)
            bash
            ;;
        q|Q)
            echo "Goodbye!"
            ;;
        *)
            echo "Invalid choice"
            sleep 1
            ;;
    esac
}
EOFHOLO

# GENERIC role
cat > ~/blackroad-backpack/menu/roles/generic.sh << 'EOFGEN'
#!/usr/bin/env bash
# Generic Role Menu

show_menu() {
    menu_item "1" "System Status"
    menu_item "2" "Network Info"
    menu_item "s" "Shell"
    menu_item "q" "Quit"
    echo ""
}

handle_choice() {
    case "$1" in
        1)
            echo "━━━ System Status ━━━"
            uptime
            read -rp "Press ENTER to continue..."
            ;;
        2)
            echo "━━━ Network Info ━━━"
            hostname -I
            read -rp "Press ENTER to continue..."
            ;;
        s|S)
            bash
            ;;
        q|Q)
            echo "Goodbye!"
            ;;
        *)
            echo "Invalid choice"
            sleep 1
            ;;
    esac
}
EOFGEN

chmod +x ~/blackroad-backpack/menu/br-menu.sh

echo "✅ Created menu framework files"
```

### C2. Deploy Menu to Each Node

**For lucidia-pi (role: ops):**

```bash
echo "━━━ Deploying to lucidia-pi ━━━"

# Create directories
ssh lucidia-pi "sudo mkdir -p /opt/blackroad/{menu/{lib,roles},config}"

# Upload menu files
scp ~/blackroad-backpack/menu/br-menu.sh lucidia-pi:/tmp/
scp ~/blackroad-backpack/menu/lib/ui.sh lucidia-pi:/tmp/
scp ~/blackroad-backpack/menu/roles/ops.sh lucidia-pi:/tmp/

# Move to proper locations
ssh lucidia-pi "sudo mv /tmp/br-menu.sh /opt/blackroad/menu/ && \
  sudo mv /tmp/ui.sh /opt/blackroad/menu/lib/ && \
  sudo mv /tmp/ops.sh /opt/blackroad/menu/roles/ && \
  sudo chmod +x /opt/blackroad/menu/br-menu.sh"

# Create node config
ssh lucidia-pi "echo 'NODE_NAME=\"lucidia-pi\"' | sudo tee /opt/blackroad/config/node.env && \
  echo 'NODE_ROLE=\"ops\"' | sudo tee -a /opt/blackroad/config/node.env"

# Add to bashrc (only if not already present)
ssh lucidia-pi "grep -q 'blackroad/menu' ~/.bashrc || \
  echo -e '\n# BlackRoad Menu\nif [[ -f /opt/blackroad/menu/br-menu.sh ]]; then\n  /opt/blackroad/menu/br-menu.sh\nfi' >> ~/.bashrc"

echo "✅ Deployed to lucidia-pi"
```

**For alice-pi (role: ops):**

```bash
echo "━━━ Deploying to alice-pi ━━━"

ssh alice-pi "sudo mkdir -p /opt/blackroad/{menu/{lib,roles},config}"

scp ~/blackroad-backpack/menu/br-menu.sh alice-pi:/tmp/
scp ~/blackroad-backpack/menu/lib/ui.sh alice-pi:/tmp/
scp ~/blackroad-backpack/menu/roles/ops.sh alice-pi:/tmp/

ssh alice-pi "sudo mv /tmp/br-menu.sh /opt/blackroad/menu/ && \
  sudo mv /tmp/ui.sh /opt/blackroad/menu/lib/ && \
  sudo mv /tmp/ops.sh /opt/blackroad/menu/roles/ && \
  sudo chmod +x /opt/blackroad/menu/br-menu.sh"

ssh alice-pi "echo 'NODE_NAME=\"alice-pi\"' | sudo tee /opt/blackroad/config/node.env && \
  echo 'NODE_ROLE=\"ops\"' | sudo tee -a /opt/blackroad/config/node.env"

ssh alice-pi "grep -q 'blackroad/menu' ~/.bashrc || \
  echo -e '\n# BlackRoad Menu\nif [[ -f /opt/blackroad/menu/br-menu.sh ]]; then\n  /opt/blackroad/menu/br-menu.sh\nfi' >> ~/.bashrc"

echo "✅ Deployed to alice-pi"
```

**For aria-pi (role: sim):**

```bash
echo "━━━ Deploying to aria-pi ━━━"

ssh aria-pi "sudo mkdir -p /opt/blackroad/{menu/{lib,roles},config}"

scp ~/blackroad-backpack/menu/br-menu.sh aria-pi:/tmp/
scp ~/blackroad-backpack/menu/lib/ui.sh aria-pi:/tmp/
scp ~/blackroad-backpack/menu/roles/sim.sh aria-pi:/tmp/

ssh aria-pi "sudo mv /tmp/br-menu.sh /opt/blackroad/menu/ && \
  sudo mv /tmp/ui.sh /opt/blackroad/menu/lib/ && \
  sudo mv /tmp/sim.sh /opt/blackroad/menu/roles/ && \
  sudo chmod +x /opt/blackroad/menu/br-menu.sh"

ssh aria-pi "echo 'NODE_NAME=\"aria-pi\"' | sudo tee /opt/blackroad/config/node.env && \
  echo 'NODE_ROLE=\"sim\"' | sudo tee -a /opt/blackroad/config/node.env"

ssh aria-pi "grep -q 'blackroad/menu' ~/.bashrc || \
  echo -e '\n# BlackRoad Menu\nif [[ -f /opt/blackroad/menu/br-menu.sh ]]; then\n  /opt/blackroad/menu/br-menu.sh\nfi' >> ~/.bashrc"

echo "✅ Deployed to aria-pi"
```

**For octavia-pi (role: holo):**

```bash
echo "━━━ Deploying to octavia-pi ━━━"

ssh octavia-pi "sudo mkdir -p /opt/blackroad/{menu/{lib,roles},config}"

scp ~/blackroad-backpack/menu/br-menu.sh octavia-pi:/tmp/
scp ~/blackroad-backpack/menu/lib/ui.sh octavia-pi:/tmp/
scp ~/blackroad-backpack/menu/roles/holo.sh octavia-pi:/tmp/

ssh octavia-pi "sudo mv /tmp/br-menu.sh /opt/blackroad/menu/ && \
  sudo mv /tmp/ui.sh /opt/blackroad/menu/lib/ && \
  sudo mv /tmp/holo.sh /opt/blackroad/menu/roles/ && \
  sudo chmod +x /opt/blackroad/menu/br-menu.sh"

ssh octavia-pi "echo 'NODE_NAME=\"octavia-pi\"' | sudo tee /opt/blackroad/config/node.env && \
  echo 'NODE_ROLE=\"holo\"' | sudo tee -a /opt/blackroad/config/node.env"

ssh octavia-pi "grep -q 'blackroad/menu' ~/.bashrc || \
  echo -e '\n# BlackRoad Menu\nif [[ -f /opt/blackroad/menu/br-menu.sh ]]; then\n  /opt/blackroad/menu/br-menu.sh\nfi' >> ~/.bashrc"

echo "✅ Deployed to octavia-pi"
```

---

## Section D: Mesh-Wide Verification

### D1. Test SSH Connections

```bash
echo "🧪 Testing all canonical SSH aliases..."
echo ""

for host in lucidia-pi alice-pi aria-pi octavia-pi; do
    echo "━━━ $host ━━━"
    ssh "$host" "echo 'Connected as:' && whoami && echo 'Node:' && hostname && echo 'IPs:' && hostname -I"
    echo ""
done
```

### D2. Verify Menu Installation

```bash
echo "🧪 Verifying menu installation on all nodes..."
echo ""

for host in lucidia-pi alice-pi aria-pi octavia-pi; do
    echo "━━━ $host ━━━"
    ssh "$host" "ls -la /opt/blackroad/menu/ && cat /opt/blackroad/config/node.env"
    echo ""
done
```

### D3. Test br-ssh Tool

```bash
echo "🧪 Testing br-ssh tool..."
echo ""

br-ssh list

echo ""
echo "Testing connection via br-ssh..."
br-ssh lucidia-pi "echo '✅ br-ssh works!'"
```

### D4. Test br-mesh Tool

```bash
echo "🧪 Testing br-mesh tool..."
echo ""

br-mesh "uname -a"
```

---

## Section E: Rollback Notes

### E1. Restore SSH Config

```bash
# If something goes wrong, restore backup
cp ~/.ssh/config.backup.YYYYMMDD-HHMMSS ~/.ssh/config
```

### E2. Remove Menu from Nodes

```bash
# On each node:
ssh <node> "sudo rm -rf /opt/blackroad && \
  sed -i.bak '/BlackRoad Menu/,+3d' ~/.bashrc"
```

### E3. Remove Operator Tools

```bash
# Remove backpack directory
rm -rf ~/blackroad-backpack

# Remove from PATH (edit ~/.zshrc manually)
```

---

## Quick Reference Commands

**SSH to nodes:**
```bash
ssh lucidia-pi
ssh alice-pi
ssh aria-pi
ssh octavia-pi
ssh operator-shellfish
```

**Operator tools:**
```bash
br-ssh list                    # List all mesh nodes
br-ssh lucidia-pi             # Connect to node
br-mesh "uptime"              # Run command on all Pis
```

**Menu on nodes:**
- Menu launches automatically on SSH login
- Press `s` for shell, `q` to quit menu

---

## Success Criteria

✅ All canonical aliases work: `ssh lucidia-pi`, `ssh alice-pi`, etc.
✅ Menu system installed on all 4 Pis
✅ Operator tools (`br-ssh`, `br-mesh`) functional
✅ No SSH lockouts
✅ Legacy aliases still work: `ssh lucidia`, `ssh aria64`, etc.

---

**End of Runbook**
