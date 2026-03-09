# BlackRoad Parallel Deployment Progress

**Started:** December 21, 2025, 1:25 PM CST
**Mode:** DNS + Network in Parallel

---

## Track A: DNS Updates (26 domains)

### Zone 1: blackroad.io (Priority - Currently 500 errors)
- [ ] console.blackroad.io
- [ ] app.blackroad.io
- [ ] os.blackroad.io
- [ ] desktop.blackroad.io

**Status:** ⏳ In Progress
**Test Command:** `curl -s https://console.blackroad.io/ | grep "HELLO FROM PI"`

### Zone 2: lucidia.earth (High Priority)
- [ ] console.lucidia.earth
- [ ] os.lucidia.earth
- [ ] desktop.lucidia.earth

**Status:** ⏭️ Pending

### Zone 3: blackroad.systems
- [ ] console.blackroad.systems
- [ ] os.blackroad.systems
- [ ] desktop.blackroad.systems

**Status:** ⏭️ Pending

### Zones 4-9: (Remaining 16 domains)
- [ ] blackroad.me (3 domains)
- [ ] blackroad.network (3 domains)
- [ ] blackroadai.com (3 domains)
- [ ] blackroadquantum.com (3 domains)
- [ ] lucidia.studio (3 domains)
- [ ] blackroadinc.us (1 domain - root)

**Status:** ⏭️ Pending

---

## Track B: Network Setup

### Step 1: Headscale Authkey
**Status:** ⏳ Waiting for authkey from user

**Command to run on Headscale server:**
```bash
headscale preauthkeys create --reusable --expiration 90d
```

### Step 2: MacBook Subnet Router
**Status:** ⏭️ Ready (Tailscale installed, waiting for authkey)

**Command to run:**
```bash
HEADSCALE_AUTHKEY=<key> sudo tailscale up \
  --login-server=https://headscale.blackroad.io \
  --authkey="$HEADSCALE_AUTHKEY" \
  --advertise-routes=192.168.4.0/22 \
  --accept-routes \
  --accept-dns=false
```

### Step 3: Enable Route in Headscale
**Status:** ⏭️ Pending (after Step 2)

**Commands:**
```bash
headscale routes list
headscale routes enable -r <route-id>
```

### Step 4: Droplet Tailscale
**Status:** ⏭️ Ready (script prepared)

**Command:**
```bash
HEADSCALE_AUTHKEY=<key> ssh root@174.138.44.45 'bash -s' < ~/setup-droplet-tailscale.sh
```

### Step 5: Test Connectivity
**Status:** ⏭️ Pending

**Commands from droplet:**
```bash
ping -c 1 100.95.120.67  # Mac
ping -c 1 192.168.4.38   # Lucidia
ssh pi@192.168.4.38      # SSH test
```

### Step 6: Add SSH Keys to Pis
**Status:** ⏭️ Manual (requires direct access)

### Step 7: Configure Termius
**Status:** ⏭️ Pending (after SSH keys)

---

## Real-Time Test Results

### DNS Tests (Updated as zones are completed)

```bash
# Run this after each DNS update
cd ~/blackroad-console-deploy
./test-all-domains.sh
```

**Current Results:**
- ✅ Working from Pi: 0
- ⚠️ Working (no banner): 1
- ❌ Not working: 25

**Target:**
- ✅ Working from Pi: 26

### Network Tests

**Mac Tailscale:**
```bash
tailscale status
# Expected: Connected to headscale.blackroad.io
```

**Droplet Routing:**
```bash
ssh root@174.138.44.45 'ping -c 1 192.168.4.38'
# Expected: 64 bytes from 192.168.4.38
```

---

## Completion Criteria

### DNS Track Complete ✅
- [ ] All 26 domains return HTTP 200
- [ ] All 26 domains show "HELLO FROM PI" banner
- [ ] Test script shows: "✅ Working from Pi: 26"

### Network Track Complete ✅
- [ ] MacBook advertising subnet 192.168.4.0/22
- [ ] Route enabled in Headscale
- [ ] Droplet can ping all Pis
- [ ] Droplet can SSH to all Pis
- [ ] Termius configured with jump host
- [ ] iPhone can SSH to Pis via Termius

---

## Quick Reference Commands

### Test Single Domain
```bash
curl -I https://console.blackroad.io/
curl -s https://console.blackroad.io/ | grep "HELLO FROM PI"
```

### Test All Domains
```bash
./test-all-domains.sh
```

### Check MacBook Tailscale
```bash
tailscale status
```

### Check Droplet Connectivity
```bash
ssh root@174.138.44.45 'tailscale status && ping -c 1 192.168.4.38'
```

---

**Update this file as progress is made!**
