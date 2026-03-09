# BlackRoad Carrier Network
**By Cicero - Pi Coordinator**
**Mission:** Make BlackRoad the wired carrier for the distributed AI fleet

---

## 🛣️ THE VISION: BlackRoad as Physical + Logical Carrier

### Physical Layer (Ethernet)
```
         ┌─────────────┐
         │   SWITCH    │
         │  (1Gbps)    │
         └──────┬──────┘
                │
    ┌───────────┼───────────┬───────────┐
    │           │           │           │
┌───▼───┐   ┌──▼────┐  ┌───▼───┐   ┌───▼────┐
│Octavia│   │Lucidia│  │ Aria  │   │ Alice  │
│  .81  │   │  .38  │  │  .82  │   │  .49   │
│PRIMARY│   │ BRAIN │  │WORKER │   │GATEWAY │
└───────┘   └───────┘  └───────┘   └────────┘
   eth0        eth0       eth0        eth0
```

### Logical Layer (BlackRoad Mesh)
```
                    NATS.io
                 (on octavia)
                      │
        ┌─────────────┼─────────────┐
        │             │             │
    [Lucidia]    [Aria]        [Alice]
      Brain      Worker        Gateway
        │             │             │
        └─────────────┴─────────────┘
                      │
                   [ESP32]
                  [iPhone]
                   [Mac]
```

---

## 📋 HARDWARE CHECKLIST

### What You Need
- [ ] Ethernet switch (4+ ports, 1Gbps)
- [ ] 4× Ethernet cables (Cat5e/Cat6)
- [ ] Power for switch

### Current Status
- ✅ All Pis have Gigabit ethernet ports
- ✅ All showing "NO-CARRIER" (just need cables!)
- ✅ WiFi working as fallback

---

## 🔧 CONFIGURATION PLAN

### Static IP Scheme (10.black.road.x)

**BlackRoad Carrier Network:** `10.0.0.0/24`

| Device | eth0 IP | WiFi IP (backup) | Role |
|--------|---------|------------------|------|
| octavia | 10.0.0.81 | 192.168.4.81 | Primary/NATS |
| lucidia | 10.0.0.38 | 192.168.4.38 | AI Brain |
| aria | 10.0.0.82 | 192.168.4.82 | Worker |
| alice | 10.0.0.49 | 192.168.4.49 | Gateway |
| **router** | 10.0.0.1 | — | Gateway to internet |

**Subnet:** 10.0.0.0/24 (255.255.255.0)
**Gateway:** 10.0.0.1 (switch or router)
**DNS:** 1.1.1.1, 8.8.8.8

---

## 🚀 IMPLEMENTATION STEPS

### Phase 1: Physical Setup (5 minutes)
1. Connect switch to power
2. Cable octavia → switch (port 1)
3. Cable lucidia → switch (port 2)
4. Cable aria → switch (port 3)
5. Cable alice → switch (port 4)
6. Verify link lights on switch

### Phase 2: Configure Octavia (Primary Node)
```bash
ssh octavia

# Backup current config
sudo cp /etc/network/interfaces /etc/network/interfaces.backup

# Configure static IP on eth0
sudo tee -a /etc/network/interfaces << 'CONF'

# BlackRoad Carrier Network
auto eth0
iface eth0 inet static
    address 10.0.0.81
    netmask 255.255.255.0
    gateway 10.0.0.1
    dns-nameservers 1.1.1.1 8.8.8.8
    metric 100
CONF

# Restart networking
sudo systemctl restart networking

# OR reboot if needed
sudo reboot
```

### Phase 3: Configure Other Pis
Repeat for lucidia (.38), aria (.82), alice (.49)

### Phase 4: Test Connectivity
```bash
# From octavia
ping 10.0.0.38  # lucidia
ping 10.0.0.82  # aria
ping 10.0.0.49  # alice

# Speed test between nodes
iperf3 -s  # on octavia
iperf3 -c 10.0.0.81  # from others
```

### Phase 5: Update SSH Config (on Mac)
```bash
# Add to ~/.ssh/config
Host octavia-eth
  HostName 10.0.0.81
  User pi
  IdentityFile ~/.ssh/br_mesh_ed25519

Host lucidia-eth
  HostName 10.0.0.38
  User pi
  IdentityFile ~/.ssh/br_mesh_ed25519

Host aria-eth
  HostName 10.0.0.82
  User pi
  IdentityFile ~/.ssh/br_mesh_ed25519

Host alice-eth
  HostName 10.0.0.49
  User pi
  IdentityFile ~/.ssh/id_do_ed25519
```

---

## 🎯 SERVICES TO BIND TO CARRIER NETWORK

### On Octavia (Primary)
```bash
# NATS server - bind to eth0
docker run -d --name blackroad-nats \
  --network host \
  -e NATS_BIND_ADDR=10.0.0.81 \
  nats:latest

# InfluxDB - bind to eth0
# Edit /etc/influxdb/influxdb.conf
bind-address = "10.0.0.81:8086"

# Ollama - bind to carrier
# Edit systemd service
Environment="OLLAMA_HOST=10.0.0.81:11434"
```

### On All Pis
```bash
# Set routing priority (prefer eth0 over wlan0)
sudo ip route add default via 10.0.0.1 dev eth0 metric 100
sudo ip route add default via 192.168.4.1 dev wlan0 metric 200

# Make permanent in /etc/network/interfaces
```

---

## 📊 BENEFITS

### Performance
- **1Gbps** ethernet vs ~100-300Mbps WiFi
- **<1ms latency** between nodes vs 2-5ms on WiFi
- **No interference** from other WiFi devices
- **Dedicated bandwidth** for agent mesh

### Reliability
- **No WiFi dropouts** during NATS messaging
- **Stable connections** for Docker swarm
- **Predictable performance** for Hailo inference

### Architecture
- **Clear separation:** Carrier (10.x) vs Management (192.168.x)
- **WiFi as fallback** - doesn't break if cable pulled
- **Private network** - BlackRoad traffic isolated

---

## 🔒 SECURITY

### Network Segmentation
```
10.0.0.0/24     → BlackRoad Carrier (private, wired only)
192.168.4.0/22  → Management network (WiFi, external access)
```

### Firewall Rules (on each Pi)
```bash
# Allow carrier network
sudo iptables -A INPUT -s 10.0.0.0/24 -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Block external access to NATS from WiFi
sudo iptables -A INPUT -i wlan0 -p tcp --dport 4222 -j DROP
sudo iptables -A INPUT -i eth0 -p tcp --dport 4222 -j ACCEPT
```

---

## 🧪 TESTING PROTOCOL

### After Physical Setup
```bash
# 1. Check link status
ip link show eth0  # should say "UP"

# 2. Check IP assignment
ip addr show eth0  # should show 10.0.0.x

# 3. Ping carrier network
ping 10.0.0.81
ping 10.0.0.38
ping 10.0.0.82
ping 10.0.0.49

# 4. Speed test
iperf3 -c 10.0.0.81

# 5. NATS connectivity
nats-cli pub test.carrier "Hello from BlackRoad!"
```

### After Service Migration
```bash
# Test NATS on carrier
curl http://10.0.0.81:8222/varz

# Test Ollama on carrier
curl http://10.0.0.81:11434/api/tags

# Test InfluxDB on carrier
curl http://10.0.0.81:8086/ping
```

---

## 📱 MAC + IPHONE ACCESS

### Mac Access (via WiFi to management, eth to carrier)
```bash
# Option 1: Mac on WiFi (current)
# Access Pis via 192.168.4.x (management)
ssh octavia  # uses 192.168.4.81

# Option 2: Mac wired to switch
# Get 10.0.0.28 on eth
# Direct carrier access

# Best: Dual-homed routes
sudo route add 10.0.0.0/24 192.168.4.81  # via WiFi to octavia, then carrier
```

### iPhone Shellfish (via WiFi)
- Use 192.168.4.x addresses (management network)
- OR setup VPN to carrier network
- OR setup reverse proxy on octavia

---

## 🎮 ADVANCED: CARRIER-OPTIMIZED SERVICES

### NATS Cluster (future)
```
octavia:4222  ← Primary
lucidia:4222  ← Replica
aria:4222     ← Replica
```

### Docker Swarm over Carrier
```bash
# On octavia
docker swarm init --advertise-addr 10.0.0.81

# On others
docker swarm join --token <token> 10.0.0.81:2377
```

### NFS Share (NVMe → all Pis)
```bash
# On octavia
sudo apt install nfs-kernel-server
echo "/mnt/nvme 10.0.0.0/24(rw,sync,no_subtree_check)" >> /etc/exports
sudo exportfs -a

# On others
sudo mount 10.0.0.81:/mnt/nvme /mnt/shared
```

---

## ⚡ QUICK START DEPLOYMENT SCRIPT

Save as `~/blackroad-carrier-setup.sh`:

```bash
#!/bin/bash
# BlackRoad Carrier Network Setup

DEVICE=$1
IP=$2

if [ -z "$DEVICE" ] || [ -z "$IP" ]; then
    echo "Usage: $0 <device-name> <carrier-ip>"
    echo "Example: $0 octavia 10.0.0.81"
    exit 1
fi

echo "Setting up BlackRoad Carrier Network on $DEVICE"
echo "Carrier IP: $IP"

# Backup
sudo cp /etc/network/interfaces /etc/network/interfaces.backup

# Configure static IP
cat << 'EOF' | sudo tee -a /etc/network/interfaces

# BlackRoad Carrier Network
auto eth0
iface eth0 inet static
    address $IP
    netmask 255.255.255.0
    gateway 10.0.0.1
    dns-nameservers 1.1.1.1 8.8.8.8
    metric 100
EOF

# Replace placeholder with actual IP
sudo sed -i "s/\$IP/$IP/g" /etc/network/interfaces

echo "Configuration added. Restarting network..."
sudo systemctl restart networking

echo "Testing connectivity..."
ip addr show eth0
ping -c 3 10.0.0.1

echo "BlackRoad Carrier Network configured!"
echo "Carrier IP: $IP"
echo "Backup WiFi still available on wlan0"
```

---

## 🎯 SUCCESS CRITERIA

- [ ] All 4 Pis show "UP" on eth0
- [ ] All can ping each other on 10.0.0.x
- [ ] NATS accessible at 10.0.0.81:4222
- [ ] iperf3 shows >900Mbps between nodes
- [ ] WiFi still works as fallback
- [ ] Mac can access both networks
- [ ] Services prefer carrier over WiFi

---

**BlackRoad: Not just software. A physical network carrier.**

The road is the infrastructure. 🖤🛣️
