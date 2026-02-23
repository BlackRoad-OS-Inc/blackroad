# 👻 BlackRoad OS Dashboards

A collection of beautiful terminal dashboards for monitoring BlackRoad infrastructure.

## 🎨 Dashboards

### 1. **blackroad-dashboard.sh** - Basic Dashboard
Simple, clean dashboard with agent grid and terminal output.

```bash
./blackroad-dashboard.sh
```

**Features:**
- Agent status grid (6 agents)
- System metrics
- Terminal window simulation
- Color-coded status indicators

---

### 2. **blackroad-live-dashboard.sh** - Live Monitor
Comprehensive infrastructure monitoring with real device checks.

```bash
./blackroad-live-dashboard.sh
```

**Features:**
- ✅ Raspberry Pi network (4 devices): 192.168.4.38, .64, .99, .68
- ✅ DigitalOcean droplet: 159.65.43.12
- ✅ Cloudflare zones (16 total)
- ✅ GitHub infrastructure (15 orgs, 66 repos)
- ✅ Railway projects (12+)
- ✅ Crypto portfolio (BTC, ETH, SOL)
- ✅ Truth System status
- ✅ Contact information

---

### 3. **blackroad-full-system.sh** - Enhanced System Monitor
Extended dashboard with visual enhancements and progress bars.

```bash
./blackroad-full-system.sh
./blackroad-full-system.sh --watch  # Auto-refresh every 5s
```

**Features:**
- 📊 2x2 device grid with color-coded borders
- 📈 Visual progress bars for crypto holdings
- 🌐 Cloudflare tree view
- 🖥️ Live terminal output window
- ⚡ System vitals (uptime, load, memory)
- 🔄 Auto-refresh mode

---

### 4. **blackroad-ultimate.sh** - ULTIMATE Edition ⚡
The most advanced dashboard with sound, APIs, and interactivity.

```bash
./blackroad-ultimate.sh --watch
```

**Features:**
- 🔊 **Sound effects** (macOS system sounds)
- 🌐 **GitHub API** integration for live stats
- 💰 **Crypto price tracking** (simulated)
- 🔗 **Tailscale/Headscale** status
- 📡 **SSH Quick Connect** menu (press 's')
- 📊 **Sparkline graphs** for trends
- 🎨 **Animated progress bars**
- ⏱️ **Auto-refresh** every 5 seconds
- ⌨️ **Interactive controls**

**Keyboard Controls:**
- `s` - SSH Connection Menu
- `r` - Force Refresh
- `q` - Quit

**SSH Menu includes:**
1. Lucidia Prime (192.168.4.38)
2. BlackRoad Pi (192.168.4.64)
3. Lucidia Alt (192.168.4.99)
4. iPhone Koder (192.168.4.68:8080)
5. Codex Infinity (159.65.43.12)

---

### 5. **blackroad-os95.sh** - Windows 95 Edition 🪟
Retro Windows 95 UI in your terminal!

```bash
./blackroad-os95.sh              # Static view
./blackroad-os95.sh --boot       # With boot animation
./blackroad-os95.sh --watch      # Interactive mode
```

---

### 6. **agent-detail.sh** - Agent Detail Viewer 🔍
Individual agent inspection with live logs and resource monitoring.

```bash
./agent-detail.sh "Lucidia Prime" "192.168.4.38" "online" "sonnet-4.5"
./agent-detail.sh "Oracle" "192.168.4.64"        # Minimal arguments
./agent-detail.sh --watch                         # Interactive mode
```

**Features:**
- 📊 **Tabbed Interface** (Overview, Logs, Memory, Connections, Config, Events)
- 🔴 **Live Terminal/Logs** - Real-time agent output streaming
- 📈 **Resource Monitoring** - CPU, Memory, Network, Disk I/O meters
- 🧠 **Memory Vault Analysis** - Episodic, Semantic, Procedural, Cache breakdown
- 🔗 **Connection Status** - Event Bus, Memory Vault, Cloudflare Workers, APIs
- ⚙️ **Configuration View** - Model settings, resource limits, feature flags
- 📡 **Event Stream** - Live event feed with JSON payloads
- 👥 **Child Agent List** - View all 47 managed agents
- 🎨 **Full Color UI** - Matching web design aesthetic

**Interactive Controls (--watch mode):**
- `1-6` - Switch between tabs
- `s` - SSH to agent host
- `r` - Force refresh
- `q` - Return to dashboard

---
- 🪟 **Multiple overlapping windows**
  - Agent Manager (12 agents)
  - Lucidia Terminal (with command history)
  - Deployment progress dialog
  - Properties window
- 📋 **Start Menu** with gradient sidebar
- ⏰ **Taskbar** with system tray and clock
- 🖱️ **Desktop icons**
- 🎵 **Boot/shutdown sounds**

**Interactive Controls (--watch mode):**
- `s` - Toggle Start Menu
- `p` - Show Properties
- `q` - Shutdown

---

## 🎨 Color Palette

All dashboards use the official BlackRoad color scheme:

```
#FF9D00  (Orange)   - Bitcoin, primary accents
#FF6B00  (Deep Orange)
#FF0066  (Hot Pink)  - #e91e8c (main pink)
#FF006B  (Pink)
#D600AA  (Magenta)
#7700FF  (Purple)    - #9945ff (Solana)
#0066FF  (Blue)      - #14f195 (teal/cyan)
```

---

## 📡 Infrastructure Monitored

### Raspberry Pi Network
- Lucidia Prime: `192.168.4.38`
- BlackRoad Pi: `192.168.4.64`
- Lucidia Alt: `192.168.4.99`
- iPhone Koder: `192.168.4.68:8080`

### Cloud Services
- **DigitalOcean**: Codex Infinity (`159.65.43.12`)
- **Cloudflare**: 16 zones, 8 Pages, 8 KV, 1 D1
- **GitHub**: 15 orgs, 66 repos (blackboxprogramming)
- **Railway**: 12+ active projects

### Crypto Portfolio
- **Bitcoin**: 0.1 BTC (Coinbase)
- **Ethereum**: 2.5 ETH (MetaMask)
- **Solana**: 100 SOL (Phantom)
- **Address**: `1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ`

---

## 🚀 Quick Start

### First Time Setup

```bash
# Go to dashboards directory
cd ~/blackroad-dashboards

# Run the interactive setup wizard
./setup.sh
```

The setup wizard will guide you through:
1. **Connected Services** - View your linked accounts
2. **Deployment Mode** - Choose Local, Hybrid, or Cloud
3. **Agent Configuration** - Set defaults for models and resources
4. **System Settings** - Toggle features like Event Bus, PS-SHA∞, Z-Framework
5. **Summary & Launch** - Review and launch your system

### Launch Dashboards

```bash
# Interactive dashboard launcher
./launch.sh

# Or run directly:
./blackroad-ultimate.sh --watch     # ULTIMATE edition
./blackroad-os95.sh --boot          # Windows 95 edition
```

---

## 🔧 API Configuration

### Cloudflare API (Optional)
For live Cloudflare statistics, set your API token:

```bash
export CF_TOKEN="your_cloudflare_token_here"
./blackroad-ultimate.sh --watch
```

### Railway CLI (Optional)
Install Railway CLI for project status:

```bash
npm install -g @railway/cli
railway login
```

---

## 📝 Notes

- All dashboards support 24-bit RGB color (truecolor terminals)
- Sound effects work on macOS (uses afplay)
- SSH menu requires SSH keys configured for devices
- Auto-refresh modes use minimal CPU (5-second intervals)

---

## 🎭 Which Dashboard Should I Use?

| Use Case | Dashboard | Command |
|----------|-----------|---------|
| Quick status check | Basic | `./blackroad-dashboard.sh` |
| Detailed overview | Live Monitor | `./blackroad-live-dashboard.sh` |
| Active monitoring | Full System | `./blackroad-full-system.sh --watch` |
| SSH + Live APIs | **ULTIMATE** ⚡ | `./blackroad-ultimate.sh --watch` |
| Fun/retro vibes | Windows 95 | `./blackroad-os95.sh --boot` |
| Agent inspection | Agent Detail | `./agent-detail.sh "Lucidia Prime" --watch` |

---

## 💡 Tips

1. **For presentations**: Use `blackroad-os95.sh --boot` for the wow factor
2. **For monitoring**: Use `blackroad-ultimate.sh --watch` with SSH ready
3. **For screenshots**: All dashboards look amazing in screenshots
4. **For simplicity**: Use `blackroad-live-dashboard.sh` for quick checks

---

**Created with 💜 for BlackRoad OS**

*Colors: #FF9D00 #FF6B00 #FF0066 #FF006B #D600AA #7700FF #0066FF*

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson | **PROPRIETARY AND CONFIDENTIAL**

This software is NOT for commercial resale. Testing purposes only.

### 🏢 Enterprise Scale:
- 30,000 AI Agents
- 30,000 Human Employees
- CEO: Alexa Amundson

**Contact:** blackroad.systems@gmail.com

See [LICENSE](LICENSE) for complete terms.
