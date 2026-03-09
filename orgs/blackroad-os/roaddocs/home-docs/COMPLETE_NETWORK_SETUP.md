# Complete BlackRoad Network Setup

**Goal:** Enable iPhone (Termius) → Droplet → MacBook → Pis connectivity

**Current Status:**
- ✅ MacBook Tailscale address: `alexa-louise.taile5d081.ts.net` (100.95.120.67)
- ✅ MacBook SSH config updated
- ⏭️ SSH keys need to be added to Pis
- ⏭️ Droplet needs Tailscale setup
- ⏭️ Subnet routing needs configuration

---

## Step 1: Add SSH Keys to Each Pi (Manual)

Since automated SSH isn't working currently, you'll need to add keys manually to each Pi.

### For Alice (192.168.4.49)

```bash
ssh pi@192.168.4.49
```

Then paste this on Alice:

```bash
set -e

AK="$HOME/.ssh/authorized_keys"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$AK"
chmod 600 "$AK"

add_key () { KEY="$1"; grep -qxF "$KEY" "$AK" || echo "$KEY" >> "$AK"; }

add_key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB8NM5Hz85bDSyvgQsNKj85j3ODCpzahOZTbIci+LCHY #ssh.id - @blackroad-sandbox'
add_key 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK3QFfJbQJhEqr6oA5EWMbD0nvIPzI7WST5cEGdyyrzQ #ssh.id - @blackroad-sandbox'

curl -fsSL https://sshid.io/blackroad-sandbox | while IFS= read -r line; do
  [ -z "$line" ] && continue
  grep -qxF "$line" "$AK" || echo "$line" >> "$AK"
done

echo "✅ Alice updated: $AK"
tail -n 8 "$AK"
```

### For Lucidia (192.168.4.38)

```bash
ssh pi@192.168.4.38
```

Then paste the same script (repeat above).

### For Aria (192.168.4.64)

```bash
ssh pi@192.168.4.64
```

Then paste the same script (repeat above).

---

## Step 2: Set Up MacBook as Tailscale Subnet Router

You need a Headscale authkey first. Get it from your Headscale server:

```bash
# SSH to Headscale server
headscale preauthkeys create --reusable --expiration 90d
# Copy the key
```

Then on your Mac:

```bash
# Install Tailscale if not already installed
brew install tailscale
sudo brew services start tailscale

# Configure as subnet router
HEADSCALE_AUTHKEY="your_key_here"
sudo tailscale up \
  --login-server=https://headscale.blackroad.io \
  --authkey="$HEADSCALE_AUTHKEY" \
  --advertise-routes=192.168.4.0/22 \
  --accept-routes \
  --accept-dns=false

# Verify
tailscale status
```

---

## Step 3: Approve Subnet Route in Headscale

SSH to your Headscale server:

```bash
# List routes
headscale routes list

# Find the route for 192.168.4.0/22 from alexa-louise
# Enable it
headscale routes enable -r <route-id>

# Verify
headscale routes list
# Should show route as enabled
```

---

## Step 4: Set Up Droplet with Tailscale

SSH to droplet (174.138.44.45):

```bash
ssh root@174.138.44.45
```

Then on the droplet:

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to Headscale and accept routes
sudo tailscale up \
  --login-server=https://headscale.blackroad.io \
  --authkey="YOUR_HEADSCALE_AUTHKEY" \
  --accept-routes

# Verify connection
tailscale status

# Check routes
ip route | grep 192.168.4

# Test connectivity to MacBook
ping -c 1 100.95.120.67

# Test connectivity to Pis (should work via Mac routing)
ping -c 1 192.168.4.38  # Lucidia
ping -c 1 192.168.4.64  # Aria
ping -c 1 192.168.4.49  # Alice
```

If ping to Pis works ✅ → Routing is configured correctly!

---

## Step 5: Test SSH from Droplet to Pis

On the droplet:

```bash
# Should work via Tailscale routing through Mac
ssh pi@192.168.4.38
ssh pi@192.168.4.64
ssh pi@192.168.4.49
```

---

## Step 6: Configure Termius on iPhone

### Import Private Key
1. Open Termius
2. Go to **Keychain**
3. Tap **+ New Key**
4. Import `id_do_ed25519`
5. Name it: `blackroad-key`

### Add Jump Host (Droplet)
- **Label:** shellfish
- **Address:** 174.138.44.45
- **Port:** 22
- **Username:** root
- **Key:** blackroad-key

### Add Pi Hosts (with Jump)

**Lucidia:**
- **Label:** lucidia
- **Address:** 192.168.4.38
- **Port:** 22
- **Username:** pi
- **Key:** blackroad-key
- **Jump Host:** shellfish

**Aria:**
- **Label:** aria
- **Address:** 192.168.4.64
- **Port:** 22
- **Username:** pi
- **Key:** blackroad-key
- **Jump Host:** shellfish

**Alice:**
- **Label:** alice
- **Address:** 192.168.4.49
- **Port:** 22
- **Username:** pi
- **Key:** blackroad-key
- **Jump Host:** shellfish

---

## Step 7: Test from iPhone

1. Open Termius
2. Tap **lucidia** (or any Pi)
3. Should connect: iPhone → shellfish → (via Tailscale + Mac routing) → Pi
4. You'll see: `pi@lucidia:~$`

---

## Verification Checklist

### On Mac
- [ ] Tailscale running: `tailscale status`
- [ ] Route advertised: Should see "offering 192.168.4.0/22"
- [ ] Can SSH to Pi directly: `ssh pi@192.168.4.38`

### On Headscale Server
- [ ] Route enabled for alexa-louise (Mac)
- [ ] Droplet (shellfish) connected
- [ ] Both nodes show in: `headscale nodes list`

### On Droplet
- [ ] Tailscale connected: `tailscale status`
- [ ] Can ping Mac: `ping 100.95.120.67`
- [ ] Can ping Pis: `ping 192.168.4.38`
- [ ] Route visible: `ip route | grep 192.168.4`
- [ ] Can SSH to Pis: `ssh pi@192.168.4.38`

### On iPhone (Termius)
- [ ] Can connect to shellfish directly
- [ ] Can connect to lucidia via jump
- [ ] Can connect to aria via jump
- [ ] Can connect to alice via jump

---

## Network Flow Diagram

```
┌─────────────────────┐
│  iPhone (Termius)   │
│  Cellular/WiFi      │
└──────────┬──────────┘
           │ SSH to 174.138.44.45:22
           ↓
┌─────────────────────┐
│  Droplet (shellfish)│
│  174.138.44.45      │
│  Tailscale:         │
│  100.x.x.x          │
└──────────┬──────────┘
           │ Route via Tailscale mesh
           │ to 100.95.120.67
           ↓
┌─────────────────────┐
│  MacBook            │
│  alexa-louise       │
│  Tailscale:         │
│  100.95.120.67      │
│  Advertises:        │
│  192.168.4.0/22     │
└──────────┬──────────┘
           │ Home LAN routing
           │ (Mac acts as gateway)
           ↓
┌─────────────────────┐
│  Home Network       │
│  192.168.4.0/22     │
│                     │
│  Pis:               │
│  - 192.168.4.38     │
│    (Lucidia)        │
│  - 192.168.4.64     │
│    (Aria)           │
│  - 192.168.4.49     │
│    (Alice)          │
└─────────────────────┘
```

---

## Troubleshooting

### Can't ping Pis from droplet

**Check Mac subnet advertising:**
```bash
# On Mac
tailscale status | grep offering
# Should show: offering 192.168.4.0/22
```

**Check droplet accepting routes:**
```bash
# On droplet
tailscale status | grep accepting
ip route | grep 192.168.4
# Should show route via Mac's Tailscale IP
```

**Enable route in Headscale:**
```bash
# On Headscale server
headscale routes list
headscale routes enable -r <route-id>
```

### SSH keys not working

Make sure you ran the key addition script on each Pi and can see the keys:

```bash
# On each Pi
tail -20 ~/.ssh/authorized_keys
```

### Tailscale not connecting

**Check logs:**
```bash
# On Mac or droplet
sudo journalctl -u tailscaled -f
```

**Restart Tailscale:**
```bash
# On Mac
sudo brew services restart tailscale

# On droplet
sudo systemctl restart tailscaled
```

---

## Quick Commands Reference

### Mac
```bash
# Advertise subnet route
sudo tailscale up --login-server=https://headscale.blackroad.io --authkey=KEY --advertise-routes=192.168.4.0/22 --accept-routes

# Check status
tailscale status

# Test local Pi access
ssh pi@192.168.4.38
```

### Droplet
```bash
# Accept routes
sudo tailscale up --login-server=https://headscale.blackroad.io --authkey=KEY --accept-routes

# Test Mac connectivity
ping 100.95.120.67

# Test Pi connectivity
ping 192.168.4.38
ssh pi@192.168.4.38
```

### Headscale Server
```bash
# List nodes
headscale nodes list

# List routes
headscale routes list

# Enable route
headscale routes enable -r <id>
```

---

**Ready to execute:** Follow steps 1-7 in order. Each step builds on the previous one.

**Time estimate:** 20-30 minutes for complete setup

**Last updated:** December 21, 2025
