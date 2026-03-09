# Octavia (Pironman 5) NVMe Setup Guide

## Prerequisites
- Raspberry Pi Imager installed on your Mac
- NVMe drive installed in Pironman 5
- USB-C cable for power
- Ethernet cable (recommended for initial setup)

## Step 1: Flash Raspberry Pi OS to NVMe

Since you're using the NVMe bootloader, you can flash directly to NVMe:

1. **Remove the NVMe from Pironman 5** and connect it to your Mac via USB adapter

2. **Open Raspberry Pi Imager**
   ```bash
   # If not installed:
   brew install --cask raspberry-pi-imager
   ```

3. **Configure the OS:**
   - **OS**: Raspberry Pi OS (64-bit, Debian Bookworm)
   - **Storage**: Select your NVMe drive
   - **Settings** (gear icon):
     - Hostname: `octavia`
     - Enable SSH: Yes (use password or public key)
     - Username: `pi`
     - Password: [your choice]
     - WiFi: [optional - configure your network]
     - Locale: US/Central
     - Keyboard: US

4. **Write the image** and wait for completion

5. **Reinstall NVMe in Pironman 5**

## Step 2: First Boot & Initial Setup

1. **Power on** the Pironman 5
2. **Wait 2-3 minutes** for first boot to complete
3. **Find octavia's IP:**
   ```bash
   # From your Mac:
   nmap -sn 192.168.4.0/24 | grep -B 2 "Raspberry Pi"
   # Or check your router at 192.168.4.1
   ```

4. **SSH into octavia:**
   ```bash
   ssh pi@octavia.local
   # Or use the IP if .local doesn't work:
   ssh pi@192.168.4.XX
   ```

## Step 3: Update System

```bash
sudo apt update && sudo apt upgrade -y
sudo rpi-update
sudo reboot
```

## Step 4: Install Pironman 5 Software

```bash
# Install Pironman 5 software for OLED, RGB, cooling
cd ~
git clone https://github.com/sunfounder/pironman5.git
cd pironman5
sudo python3 install.py

# Configure Pironman (optional - customize RGB, fan curves, etc.)
pironman5 config
```

## Step 5: Configure Static IP (Optional)

Edit `/etc/dhcpcd.conf`:
```bash
sudo nano /etc/dhcpcd.conf
```

Add at the end:
```
interface eth0
static ip_address=192.168.4.XX/24
static routers=192.168.4.1
static domain_name_servers=192.168.4.1 8.8.8.8
```

Choose an IP that's not taken:
- 192.168.4.38 - lucidia
- 192.168.4.49 - alice
- 192.168.4.64 - aria
- Suggestion: **192.168.4.50** for octavia

```bash
sudo reboot
```

## Step 6: Install BlackRoad Node Setup

This will give octavia the same welcome banner as aria and lucidia.

### Check if aria/lucidia have BlackRoad setup scripts:
```bash
# From your Mac, check what setup exists:
ssh pi@aria64 "ls -la ~/br-* ~/.bashrc 2>/dev/null"
```

### If there's a setup script, copy it:
```bash
# Copy BlackRoad setup from aria to octavia
ssh pi@aria64 "tar czf - br-* .bashrc" | ssh pi@octavia "tar xzf -"
```

### Or create basic setup:
```bash
# On octavia:
cat >> ~/.bashrc << 'EOF'

# BlackRoad PS1
_blackroad_ps1() {
    echo "🖤🛣️ \u@\h:\w $ "
}
PS1=$(_blackroad_ps1)

# BlackRoad welcome
cat << 'WELCOME'
🌈  Welcome to BlackRoad Node
────────────────────────────────────────
  Host : $(hostname)
  IPs  : $(hostname -I)
  User : $(whoami)
  Time : $(date)
────────────────────────────────────────
  Commands:
    br-status   → quick health snapshot
    br-menu     → interactive node panel
WELCOME
EOF

source ~/.bashrc
```

## Step 7: Setup SSH Keys

```bash
# From your Mac, copy your SSH key to octavia:
ssh-copy-id -i ~/.ssh/id_do_ed25519.pub pi@octavia
```

Update `~/.ssh/config` on your Mac:
```bash
cat >> ~/.ssh/config << 'EOF'

Host octavia
  HostName 192.168.4.50
  User pi
  Port 22
  IdentityFile ~/.ssh/id_do_ed25519
EOF
```

## Step 8: Verify NVMe Performance

```bash
# Check NVMe is being used:
lsblk

# Test read speed:
sudo hdparm -t /dev/nvme0n1

# Test write speed:
dd if=/dev/zero of=~/test.img bs=1M count=1024 conv=fdatasync
rm ~/test.img
```

## Step 9: Install Docker (Optional - if aria/lucidia have it)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi
sudo systemctl enable docker
sudo reboot
```

## Verification Checklist

- [ ] Pironman 5 OLED shows system stats (CPU, RAM, temp, IP)
- [ ] RGB lights working
- [ ] Fan spinning based on temperature
- [ ] SSH access working
- [ ] Static IP configured (if desired)
- [ ] BlackRoad welcome banner displays on login
- [ ] NVMe boot confirmed (lsblk shows nvme0n1 as root)
- [ ] Network connectivity stable

## Troubleshooting

**OLED not working:**
```bash
sudo systemctl status pironman5
sudo systemctl restart pironman5
```

**Can't SSH:**
- Check if octavia is on network: `ping octavia.local`
- Check router DHCP leases
- Try direct connection with HDMI and keyboard

**Slow boot:**
- NVMe boot can take 30-60 seconds on first boot
- Check with HDMI to see boot messages

**Need to switch back to SD card:**
```bash
sudo raspi-config
# Advanced Options → Boot Order → SD Card Boot
```

## Next Steps

Once octavia is running:
1. Install any additional software (matching aria/lucidia)
2. Configure Tailscale (if lucidia has it at 100.66.235.47)
3. Setup any containers/services
4. Add to your infrastructure inventory

---

**Quick Reference:**
- Hostname: `octavia`
- User: `pi`
- Suggested IP: `192.168.4.50`
- SSH: `ssh pi@octavia` or `ssh octavia`
- OS: Raspberry Pi OS 64-bit (Bookworm)
- Storage: NVMe boot
- Hardware: Raspberry Pi 5 + Pironman 5 case
