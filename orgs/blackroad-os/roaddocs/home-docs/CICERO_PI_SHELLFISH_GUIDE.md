# CICERO - BlackRoad Pi Fleet Coordinator
**Agent ID:** cicero-pi-coordinator-1768019521-b26334de
**Initialized:** 2026-01-09
**Role:** Pi SSH Coordinator & Shellfish Integration Guide

---

## 🖤 BLACKROAD PI FLEET STATUS

### Primary Fleet Infrastructure

| Hostname | IP Address | Role | Specs | Agent Count | Status |
|----------|-----------|------|-------|-------------|--------|
| **octavia** | 192.168.4.38 | PRIMARY | AI Accelerator + NVMe (916GB) | 18,247 | Unknown |
| **aria** | 192.168.4.64 | Secondary | Standard Pi 5 | 6,892 | Unknown |
| **alice** | 192.168.4.49 | Secondary | Standard Pi (DISK FULL) | 2,147 | ⚠️ Needs cleanup |
| **lucidia** | 192.168.4.99 | Secondary | Standard Pi | Variable | Unknown |
| **shellfish** | 159.65.43.12 | Backup | DigitalOcean 4GB | 1,206 | Unknown |

### Access URLs
- http://192.168.4.38/ - Octavia OS
- http://192.168.4.64/ - Aria OS  
- http://192.168.4.49/ - Alice OS (⚠️ disk full)
- http://159.65.43.12/ - Shellfish backup

---

## 🔑 SSH Configuration

### macOS SSH Config (~/.ssh/config)

```
Host alice
  HostName 192.168.4.49
  User pi
  Port 22
  IdentityFile ~/.ssh/id_do_ed25519

Host octavia  
  HostName 192.168.4.38
  User pi
  Port 22
  IdentityFile ~/.ssh/br_mesh_ed25519

Host aria
  HostName 192.168.4.64
  User pi
  Port 22
  IdentityFile ~/.ssh/br_mesh_ed25519

Host lucidia
  HostName 192.168.4.99
  User pi
  Port 22  
  IdentityFile ~/.ssh/br_mesh_ed25519

Host shellfish
  HostName 159.65.43.12
  User root
  Port 22
  IdentityFile ~/.ssh/id_do_ed25519
```

### SSH Keys
- **Local Mesh:** `~/.ssh/br_mesh_ed25519` (octavia, aria, lucidia)
- **DigitalOcean:** `~/.ssh/id_do_ed25519` (alice, shellfish)
- **Alt Key:** `~/.ssh/id_octavia` (octavia fallback)
- **Key Info:** `/Users/alexa/raspberrypi-key-info.txt`
  - DN: rroWBEvfJeTiQLHYUBcoZat
  - Location: /Users/alexa/Desktop/RespberryKey.tk

---

## 📱 SHELLFISH iOS SSH CLIENT SETUP

### Installation
1. Install Shellfish from App Store (already installed)
2. Open Shellfish app on iPhone

### Adding Hosts to Shellfish

#### Method 1: Manual Configuration
For each Pi, tap "Add Connection" and enter:

**Octavia (Primary):**
- Name: octavia  
- Host: 192.168.4.38
- Port: 22
- Username: pi
- Authentication: Key (import br_mesh_ed25519)

**Aria:**
- Name: aria
- Host: 192.168.4.64  
- Port: 22
- Username: pi
- Authentication: Key (import br_mesh_ed25519)

**Alice:**
- Name: alice
- Host: 192.168.4.49
- Port: 22
- Username: pi  
- Authentication: Key (import id_do_ed25519)

**Lucidia:**
- Name: lucidia
- Host: 192.168.4.99
- Port: 22
- Username: pi
- Authentication: Key (import br_mesh_ed25519)

**Shellfish (DigitalOcean):**
- Name: shellfish
- Host: 159.65.43.12
- Port: 22
- Username: root
- Authentication: Key (import id_do_ed25519)

#### Method 2: Import from SSH Config
1. In Shellfish, go to Settings
2. Tap "Import from SSH Config"
3. Select ~/.ssh/config
4. Shellfish will auto-detect all hosts

### Importing SSH Keys to Shellfish
1. Tap Settings → Keys
2. Tap "+" to add key
3. Options:
   - **Import from Files:** Navigate to ~/.ssh/ and select key
   - **AirDrop:** Send key from Mac to iPhone
   - **Copy/Paste:** Copy key content and paste in Shellfish

**Keys to Import:**
- br_mesh_ed25519 (for octavia, aria, lucidia)
- id_do_ed25519 (for alice, shellfish)

### Testing Connections
Once configured, test each connection:
1. Tap on host name in Shellfish
2. If prompted for passphrase, enter it
3. Should see shell prompt
4. Run: `hostname && uptime`

---

## 🧪 PAST EXPERIMENTS & PROJECTS

### ESP32 Projects

#### 1. BlackRoad ESP32 Pager (2026-01-03)
**Location:** `/Users/alexa/Desktop/BLACKROAD_ESP32_PAGER_SPEC.md`

**Hardware:**
- Chip: ESP32-D0WD-V3  
- MAC: 20:e7:c8:ba:1b:94
- Serial: /dev/cu.usbserial-110
- 14 GPIO pins available
- USB-C serial interface

**Features:**
- Visual alert patterns (blink, strobe, morse code, PWM fades)
- Serial communication (115200 baud)
- Command protocol (STANDBY, ALERT, ACK, PING, RESET)
- Alert modes: Linear, Slack, GitHub integrations
- Future: Wi-Fi webhooks, OTA updates

**Status:** Hardware operational, basic firmware tested

#### 2. ESP32 UX/UI System (by SILAS)
**Location:** `~/ceo-hub-esp32/`

**Components:**
- BlackRoadUI.h (7.8KB) - Animation & UI system
- WireframeTemplates.h (15KB) - 10 instant UI templates
- Designer app (wireframe_app.cpp)
- Complete documentation suite (76KB, 937 lines)

**Features:**
- Official BlackRoad design system
- Golden Ratio spacing
- Touch interactions
- 10 pre-built templates (List, Card, Form, Grid, etc.)
- 66x development speedup

**Display:** ILI9341 (240×320), Touch: XPT2046

### Pi Deployment Projects

#### 1. 30K Agent Deployment (Active)
**Goal:** Deploy 30,000 AI agents across Pi fleet
**Current:** 28,492 agents total across fleet
**Infrastructure:** Multi-Pi mesh with DigitalOcean backup

#### 2. PowerDNS Multi-Domain System (Dec 2025)
**Status:** 5 domains live
- blackroad.io
- lucidia.earth  
- blackroadai.com
- blackroadquantum.com
- roadchain.io

**DNS Server:** PowerDNS on lucidia:53
**Records:** 29 DNS records active

#### 3. Lucidia Autonomous AI (Dec 2025)
**Host:** octavia (192.168.4.38)
**Brains:** 
- Qwen 2.5 0.5b (397MB)
- HuggingFace models (1-14GB)
**Roles:** Guardian, Face, Bridge

---

## 🔧 QUICK COMMANDS FOR SHELLFISH

### Once Connected to a Pi

#### Check System Status
```bash
hostname && uptime
df -h /
free -h
vcgencmd measure_temp  # Pi temperature
```

#### Check Running Services
```bash
systemctl status blackroad-*
docker ps
ps aux | grep python
```

#### Check Network
```bash
ip addr show
ping 8.8.8.8 -c 3
curl ifconfig.me  # Public IP
```

#### Deployment Status
```bash
ls -la /home/pi/blackroad-agents/
cat /home/pi/blackroad-agents/status.txt
journalctl -u blackroad-* --no-pager -n 50
```

#### Quick Tests
```bash
# Test web server
curl http://localhost/

# Test agent orchestrator  
~/blackroad-agent-orchestrator.sh status

# Check disk usage top folders
du -sh /home/pi/* | sort -hr | head -10
```

### VNC Access (if needed)
- Alice: vnc://192.168.4.49:5900 (RealVNC)
- Lucidia/Octavia: vnc://192.168.4.38:5900 (WayVNC)  
- Aria: vnc://192.168.4.64:5900 (WayVNC)

---

## ⚠️ CURRENT ISSUES

### Alice Pi (192.168.4.49)
**Problem:** Disk 100% full (0KB free)
**Impact:** Cannot deploy new agents
**Solution:** Run cleanup script or expand storage

**Cleanup Script:**
```bash
ssh alice
~/cleanup-alice-pi.sh
# OR manual cleanup:
docker system prune -a
rm -rf ~/.cache/*
sudo journalctl --vacuum-time=7d
```

### Connection Status
**Note:** SSH tests from Mac showed "connection refused" - Pis may be:
- Powered off
- On different network
- Firewall blocking
- Need to verify network connectivity first

**Diagnostic Steps:**
1. Check if Pis are on same network as Mac/iPhone
2. Try ping first: `ping 192.168.4.38`
3. Check router DHCP leases for actual IPs
4. May need to power cycle Pis

---

## 📊 TASK MARKETPLACE INTEGRATION

### Active Tasks Related to Pis
- `30k-agent-infrastructure` - Build infrastructure for 30,000 agents
- `esp32-real-time-streams` - Add real-time data to ESP32 apps
- `cloudflare-mass-deployment` - Deploy to all Cloudflare domains

### Claiming Tasks
```bash
~/memory-task-marketplace.sh claim <task-id>
~/memory-task-marketplace.sh my-tasks
```

---

## 🎯 NEXT STEPS FOR SHELLFISH SETUP

1. **Verify Pi Network Status**
   - Power on all Pis
   - Check router for actual IP addresses
   - Test ping from iPhone to each IP

2. **Configure Shellfish**
   - Add all 5 hosts (octavia, aria, alice, lucidia, shellfish)
   - Import SSH keys (br_mesh_ed25519, id_do_ed25519)
   - Test each connection

3. **Test Basic Commands**
   - hostname && uptime
   - df -h
   - systemctl status

4. **Fix Alice Disk Space**
   - SSH to alice
   - Run cleanup script
   - Verify space freed

5. **Deploy Missing Services**
   - Check which services are down
   - Redeploy as needed
   - Update agent counts

---

## 📝 CICERO COORDINATION LOG

**Logged to [MEMORY]:**
- Session: cicero-pi-coordinator-1768019521-b26334de
- Status: Initialized
- Action: Created comprehensive Pi fleet + Shellfish guide
- Hash: 10bb8108...

**When SSH Access Confirmed:**
```bash
~/memory-system.sh log milestone "cicero-pi-coordinator" "SSH access confirmed to all 5 Pi devices via Shellfish. Fleet status: octavia(PRIMARY), aria, alice(needs cleanup), lucidia, shellfish(backup). Ready for distributed agent deployment." "pi-coordination,shellfish,fleet-ready"
```

---

**END OF GUIDE**

Generated by Cicero - BlackRoad Pi Coordinator
2026-01-09
