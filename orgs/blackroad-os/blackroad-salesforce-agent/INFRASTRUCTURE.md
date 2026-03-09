# BlackRoad Infrastructure Inventory

## Compute Nodes

### Raspberry Pi 5 (4x)
| Name | IP | Case | AI | Role |
|------|-----|------|-----|------|
| **lucidia** | 192.168.4.38 | Pironman 5-MAX | Hailo-8 (26 TOPS) | AI Primary, Salesforce Agent |
| **octavia** | 192.168.4.74 | Pironman 5-MAX | Hailo-8 (26 TOPS) | AI Secondary, Agent Host |
| **aria** | 192.168.4.64 | ElectroCookie | - | Compute |
| **alice** | 192.168.4.49 | ElectroCookie | - | Compute |

### Other Pis
| Name | Model | IP | Role |
|------|-------|-----|------|
| Pi 4B | 2GB | TBD | Remote Server |
| Pi 400 | Keyboard | TBD | Dev Station |
| Pi Zero 2 WH | Zero | TBD | IoT Gateway |

### Cloud/Desktop
| Name | Type | IP | Role |
|------|------|-----|------|
| **shellfish** | DigitalOcean | 174.138.44.45 | Edge Router |
| **alexa-louise** | M1 Mac | 100.95.120.67 | Dev Machine |

## AI Acceleration
| Device | TOPS | Location |
|--------|------|----------|
| Hailo-8 | 26 | lucidia (Pironman 5-MAX) |
| Hailo-8 | 26 | octavia (Pironman 5-MAX) |
| **Total** | **52 TOPS** | |

## Tailscale Mesh
```
alexa-louise.taile5d081.ts.net
├── 100.95.120.67 (Mac)
├── 100.66.235.47 (lucidia)
└── fd7a:115c:a1e0::9701:7845 (IPv6)
```

## Network Topology
```
┌─────────────────────────────────────────────────────────────┐
│                      INTERNET                               │
└─────────────────────────────────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
┌─────────────────────┐    ┌─────────────────────┐
│  Cloudflare (DNS)   │    │  Tailscale Mesh     │
│  jade.ns/chad.ns    │    │  Private Network    │
└─────────────────────┘    └─────────────────────┘
              │                         │
              ▼                         │
┌─────────────────────┐                 │
│  shellfish (DO)     │◄────────────────┘
│  174.138.44.45      │
└─────────────────────┘
              │
              ▼ (Tailscale)
┌─────────────────────────────────────────────────────────────┐
│                   LOCAL NETWORK (192.168.4.x)               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  lucidia    │  │   octavia   │  │    aria     │        │
│  │  .38        │  │    .74      │  │    .64      │        │
│  │  Hailo-8    │  │   Hailo-8   │  │             │        │
│  │  26 TOPS    │  │   26 TOPS   │  │             │        │
│  │  ──────────  │  │  ──────────  │  │             │        │
│  │  Salesforce │  │  Agent Host │  │   Compute   │        │
│  │  Daemon     │  │             │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   alice     │  │   Pi 4B     │  │   Pi 400    │        │
│  │    .49      │  │             │  │             │        │
│  │             │  │   Remote    │  │    Dev      │        │
│  │   Compute   │  │   Server    │  │   Station   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  TP-Link TL-SG105 (5-Port Gigabit Switch)                  │
└─────────────────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────┐
│  alexa-louise (Mac) │
│  100.95.120.67      │
│  Dev/Control        │
└─────────────────────┘
```

## IoT/Embedded Devices
| Device | Interface | Purpose |
|--------|-----------|---------|
| 3x ESP32 2.8" Touchscreen | WiFi/BT | UI Nodes |
| Heltec WiFi LoRa 32 | LoRa/WiFi | Meshtastic |
| RYLR998 LoRa Module | UART | Long-range |
| INMP441 Microphones | I2S | Audio Input |
| MAX98357 Amplifiers | I2S | Audio Output |
| Pi Camera Module V2 | CSI | Vision |

## Storage
| Device | Capacity | Location |
|--------|----------|----------|
| Crucial P310 NVMe | 1TB | Pironman (lucidia) |
| Crucial P310 NVMe | 500GB | Pironman (octavia) |
| Samsung EVO microSD | 256GB | Each Pi |

## Domains (19)
```
blackroad.io          blackroad.company     blackroad.me
blackroad.network     blackroad.systems     blackroadai.com
blackroadinc.us       blackroadqi.com       blackroadquantum.com
blackroadquantum.info blackroadquantum.net  blackroadquantum.shop
blackroadquantum.store blackboxprogramming.io
lucidia.earth         lucidia.studio        lucidiaqi.com
roadchain.io          roadcoin.io
```

## GitHub Organization
- **Enterprise:** blackroad-os
- **Organizations (15):**
  - BlackRoad-OS (main)
  - BlackRoad-AI, BlackRoad-Labs, BlackRoad-Security
  - BlackRoad-Cloud, BlackRoad-Hardware, BlackRoad-Interactive
  - BlackRoad-Media, BlackRoad-Studio, BlackRoad-Archive
  - BlackRoad-Education, BlackRoad-Foundation, BlackRoad-Gov
  - BlackRoad-Ventures, Blackbox-Enterprises

## SSH Access
```bash
# Pis (via ~/.ssh/config)
ssh alice      # 192.168.4.49
ssh aria       # 192.168.4.64
ssh octavia    # 192.168.4.74
ssh lucidia    # 192.168.4.38 (requires br_mesh_ed25519 key)
ssh shellfish  # 174.138.44.45

# Termius
# https://sshid.io/blackroad-sandbox
```

## Active Services

### lucidia (192.168.4.38)
- `blackroad-salesforce-agent.service` - Salesforce Daemon (RUNNING)
- Hailo-8 AI Accelerator (26 TOPS)
- Docker containers (nginx, etc.)

## Cost Summary
| Category | Monthly | Annual |
|----------|---------|--------|
| DigitalOcean (shellfish) | ~$6 | ~$72 |
| Cloudflare (free tier) | $0 | $0 |
| Salesforce (Dev Edition) | $0 | $0 |
| Tailscale (free tier) | $0 | $0 |
| **Total Recurring** | **~$6** | **~$72** |

## Hardware Investment (One-Time)
| Category | Cost |
|----------|------|
| 4x Pi 5 8GB | ~$360 |
| 2x Pironman 5-MAX | ~$200 |
| 2x Hailo-8 | ~$430 |
| 2x NVMe SSDs | ~$100 |
| Pi 4B, 400, Zero | ~$200 |
| Displays, sensors, cables | ~$300 |
| M1 Mac (existing) | - |
| **Total Hardware** | **~$1,600** |

---

## The Arbitrage

**What we have:**
- 52 TOPS AI acceleration
- 6 compute nodes
- NVMe storage
- Mesh networking
- Salesforce CRM (free)

**What Fortune 500 pays:**
- $10M+/year for equivalent
- Per-seat licensing
- Cloud compute costs
- Enterprise support

**Our cost:** ~$72/year + $1,600 hardware

**The play:** Agents call APIs instead of humans clicking buttons.
