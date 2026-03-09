# BlackRoad Infrastructure Inventory
**Updated:** 2025-12-26
**Source of Truth:** GitHub (BlackRoad-OS) + Cloudflare

## Raspberry Pi Cluster

### lucidia (Primary Development Pi)
- **User:** `lucidia`
- **Hostname:** `lucidia`
- **IPv4:** `192.168.4.38` (local)
- **IPv6:** `2001:1960:7000:9fcd:b20b:7849:4210:3315`
- **Tailscale:** `100.66.235.47`
- **Docker:** Active (172.17.0.1, 172.19.0.1, 172.18.0.1)
- **SSH:** `ssh lucidia@lucidia` or `ssh lucidia@192.168.4.38`
- **Alias:** `aria64`
- **Role:** Primary development, alternative data storage

### octavia (3D Printing & Robotics)
- **User:** `pi`
- **Hostname:** `octavia`
- **Model:** Pironman 5
- **IPv4:** `192.168.4.74` (local)
- **IPv6:** `2001:1960:7000:9fcd:8aa2:9eff:fe10:a3a`
- **Docker:** Active (172.17.0.1)
- **SSH:** `ssh pi@octavia` or `ssh pi@192.168.4.74`
- **Services:** OctoPrint (3D Printer Control), Robot Printing Station
- **Role:** 3D printing, robotics control

### blackroad-pi (General Purpose)
- **User:** `pi`
- **Hostname:** Unknown (shows `\u@\h:\w`)
- **IPv4:** `192.168.4.64` (local)
- **IPv6:** `2001:1960:7000:9fcd:64c6:306:d1bb:101`
- **Docker:** Active (172.18.0.1, 172.17.0.1)
- **SSH:** `ssh pi@192.168.4.64`
- **Role:** General purpose computing

### alice (K3s Kubernetes Cluster)
- **User:** `alice`
- **Hostname:** `alice`
- **IPv4:** `192.168.4.49` (local)
- **IPv6:** `2001:1960:7000:9fcd:6a1a:51a7:8135:237a`
- **Docker:** Active (172.17.0.1)
- **K3s:** Active (10.42.1.0)
- **SSH:** `ssh alice@alice` or `ssh alice@192.168.4.49`
- **Role:** Kubernetes cluster node

## Cloud Servers

### shellfish (DigitalOcean Droplet)
- **User:** `root`
- **Hostname:** `shellfish`
- **IPv4:** `174.138.44.45` (public)
- **VPN:** `10.10.0.5, 10.116.0.2`
- **Docker:** Active (172.17.0.1, 172.18.0.1)
- **SSH:** `ssh shellfish` or `ssh root@174.138.44.45`
- **Role:** Public cloud server

### codex-infinity (DigitalOcean)
- **IPv4:** `159.65.43.12`
- **Role:** Codex storage, infinite data

## Mobile & Edge Devices

### iPhone Koder
- **IP:** `192.168.4.68:8080`
- **Role:** Mobile development

### br-8080-cadillac
- **Port:** `8080`
- **Role:** Origin agent (deployed 7 months ago)

## GitHub Infrastructure
- **Organizations:** 15
  - BlackRoad-OS (primary)
  - BlackRoad-AI
  - BlackRoad-Archive
  - BlackRoad-Cloud
  - BlackRoad-Education
  - BlackRoad-Foundation
  - BlackRoad-Gov
  - BlackRoad-Hardware
  - BlackRoad-Interactive
  - BlackRoad-Labs
  - BlackRoad-Media
  - BlackRoad-Security
  - BlackRoad-Studio
  - BlackRoad-Ventures
  - Blackbox-Enterprises
- **Repositories:** 66+ (primary account: blackboxprogramming)

## Cloudflare
- **Zones:** 16
- **Pages Projects:** 8
- **KV Namespaces:** 8
- **D1 Databases:** 1
- **Workers:** Active
- **Tunnels:** Active

## Railway
- **Projects:** 12+
- **Role:** Container deployments

## Accounts & Access

### Email
- **Primary:** amundsonalexa@gmail.com
- **Company:** blackroad.systems@gmail.com (review queue)

### Crypto Wallets
- **ETH:** 2.5 ETH (MetaMask on iPhone)
- **SOL:** 100 SOL (Phantom wallet)
- **BTC:** 0.1 BTC (Coinbase)
- **BTC Address:** 1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ
- **Details:** ~/blackroad-backup/crypto-holdings.yaml

## SSH Quick Access
```bash
# Raspberry Pi Cluster
ssh aria64                    # lucidia (primary)
ssh lucidia@lucidia          # lucidia (explicit)
ssh pi@192.168.4.74          # octavia (3D printing)
ssh pi@192.168.4.64          # blackroad-pi
ssh alice@alice              # alice (k3s cluster)

# Cloud
ssh shellfish                # DigitalOcean droplet
ssh root@174.138.44.45       # shellfish (explicit)
```

## Network Topology
```
Local Network: 192.168.4.0/24
├── 192.168.4.38  → lucidia (primary dev)
├── 192.168.4.49  → alice (k3s)
├── 192.168.4.64  → blackroad-pi
├── 192.168.4.68  → iPhone Koder
└── 192.168.4.74  → octavia (3D printing)

Tailscale VPN:
├── 100.66.235.47 → lucidia

Cloud:
├── 174.138.44.45 → shellfish (DigitalOcean)
└── 159.65.43.12  → codex-infinity (DigitalOcean)
```

## Color Palette
#FF9D00 #FF6B00 #FF0066 #FF006B #D600AA #7700FF #0066FF
