# Termius SSH Configuration for BlackRoad Pis

## Setup Overview

This enables: **Termius (iPhone) → Droplet (shellfish) → Pis**

All Pi access routes through the droplet as a jump host.

---

## 1. Import Private Key to Termius

1. Open Termius on iPhone
2. Go to **Keychain**
3. Tap **+ New Key**
4. **Import** your `id_do_ed25519` private key
5. Name it: `blackroad-key`

---

## 2. Add Jump Host (Droplet)

**Host:** shellfish
**Address:** 174.138.44.45
**Port:** 22
**Username:** root
**Key:** blackroad-key

---

## 3. Add Pi Hosts (with ProxyJump)

### Lucidia Pi (Origin Server)

**Host:** lucidia
**Address:** 192.168.4.38
**Port:** 22
**Username:** pi
**Key:** blackroad-key
**ProxyJump:** shellfish

### Aria Pi (AI Agent)

**Host:** aria
**Address:** 192.168.4.64
**Port:** 22
**Username:** pi
**Key:** blackroad-key
**ProxyJump:** shellfish

### Alice Pi (AI Agent)

**Host:** alice
**Address:** 192.168.4.49
**Port:** 22
**Username:** pi
**Key:** blackroad-key
**ProxyJump:** shellfish

### Lucidia Alternate

**Host:** lucidia-alt
**Address:** 192.168.4.99
**Port:** 22
**Username:** pi
**Key:** blackroad-key
**ProxyJump:** shellfish

---

## 4. SSH Config Format (if manually editing)

If Termius supports importing SSH config, use this:

```sshconfig
# Jump host (droplet)
Host shellfish
  HostName 174.138.44.45
  User root
  IdentityFile ~/.ssh/id_do_ed25519
  Port 22

# Pis (via jump host)
Host lucidia
  HostName 192.168.4.38
  User pi
  ProxyJump shellfish
  IdentityFile ~/.ssh/id_do_ed25519

Host aria
  HostName 192.168.4.64
  User pi
  ProxyJump shellfish
  IdentityFile ~/.ssh/id_do_ed25519

Host alice
  HostName 192.168.4.49
  User pi
  ProxyJump shellfish
  IdentityFile ~/.ssh/id_do_ed25519

Host lucidia-alt
  HostName 192.168.4.99
  User pi
  ProxyJump shellfish
  IdentityFile ~/.ssh/id_do_ed25519
```

---

## 5. Test Connection

From Termius:
1. Tap **lucidia**
2. Should connect through shellfish automatically
3. You'll see: `pi@lucidia:~$`

---

## Prerequisites

Before this works, you need:

✅ **SSH keys on all Pis** - Run: `./setup-pi-ssh-keys.sh`
✅ **Tailscale subnet routing** - MacBook must advertise `192.168.4.0/22`
✅ **Droplet on Tailscale** - Must accept routes from MacBook
✅ **Mac online** - MacBook must be running and on home network

---

## Verification Steps

### 1. Test from Mac

```bash
# Should work directly
ssh pi@192.168.4.38

# Should work via jump
ssh -J root@174.138.44.45 pi@192.168.4.38
```

### 2. Test from Droplet

```bash
# SSH to droplet
ssh root@174.138.44.45

# From droplet, ping Pis (requires Tailscale routing)
ping -c 1 192.168.4.38
ping -c 1 192.168.4.64
ping -c 1 192.168.4.49

# SSH to Pis (requires Tailscale routing)
ssh pi@192.168.4.38
```

### 3. Test from Termius (iPhone)

Just tap the Pi host in Termius - it should connect!

---

## Troubleshooting

### "Connection refused" or "No route to host"

**From droplet:**
1. Check Tailscale status: `tailscale status`
2. Check routes: `ip route | grep 192.168.4`
3. Verify MacBook subnet route is enabled

**Fix:** Set up Tailscale subnet routing (see setup-subnet-routing.sh)

### "Permission denied (publickey)"

**Issue:** SSH keys not on Pi

**Fix:**
```bash
# Run from Mac
./setup-pi-ssh-keys.sh
```

### "Connection timed out"

**Issue:** MacBook offline or not routing traffic

**Fix:**
1. Ensure MacBook is on and connected to home network
2. Check MacBook Tailscale: `tailscale status`
3. Verify subnet route is advertised: `tailscale status | grep "offering"`

---

## Network Flow

```
┌─────────────────┐
│  Termius        │
│  (iPhone)       │
└────────┬────────┘
         │ SSH to shellfish:22
         ↓
┌─────────────────┐
│  Droplet        │
│  174.138.44.45  │
│  (Tailscale)    │
└────────┬────────┘
         │ Route via Tailscale
         ↓
┌─────────────────┐
│  MacBook        │
│  (Subnet Router)│
│  Routes:        │
│  192.168.4.0/22 │
└────────┬────────┘
         │ Home LAN
         ↓
┌─────────────────┐
│  Pis            │
│  192.168.4.x    │
│  - Lucidia      │
│  - Aria         │
│  - Alice        │
└─────────────────┘
```

---

## Quick Setup Commands

```bash
# 1. Add SSH keys to all Pis
./setup-pi-ssh-keys.sh

# 2. Set up MacBook as subnet router (requires HEADSCALE_AUTHKEY)
HEADSCALE_AUTHKEY=your_key ./setup-subnet-routing.sh

# 3. Set up droplet (SSH to droplet first)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up \
  --login-server=https://headscale.blackroad.io \
  --authkey=YOUR_KEY \
  --accept-routes

# 4. Approve route in Headscale (on headscale server)
headscale routes list
headscale routes enable -r <route-id>

# 5. Import SSH config to Termius (manual step in app)
```

---

**Last Updated:** December 21, 2025
**Network:** BlackRoad Infrastructure
**Subnet:** 192.168.4.0/22
