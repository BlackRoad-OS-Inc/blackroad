# 🖤🛣️ BlackRoad Cluster Management CLI

## Quick Start

```bash
blackroad-cluster list      # List all devices
bc list                     # Same using alias
```

## Installation

The `blackroad-cluster` command is installed in `~/bin/blackroad-cluster`.

**Alias:** `bc` is configured as a shortcut for `blackroad-cluster`

## Device Registry

| Device | IP | User | Description |
|--------|----------|------|-------------|
| **octavia** | 192.168.4.81 | pi | Debian 13 (trixie) - Docker orchestration |
| **alice** | 192.168.4.49 | alice | Raspbian 11 - Kubernetes cluster |
| **lucidia** | 192.168.4.38 | pi | Debian 12 - Tailscale VPN hub |
| **aria** | 192.168.4.82 | pi | Debian 12 - Docker services |
| **shellfish** | 174.138.44.45 | root | CentOS 9 - DigitalOcean cloud |

## Commands

### Basic Commands

```bash
# List all devices
blackroad-cluster list
bc ls

# Show status of all devices (with uptime, load)
blackroad-cluster status
bc stat

# Show version
blackroad-cluster version
bc version
```

### SSH Access

```bash
# SSH into a device
blackroad-cluster ssh octavia
bc ssh alice

# Quick access
bc ssh lucidia
bc ssh aria
bc ssh shellfish
```

### Execute Commands

```bash
# Run command on single device
blackroad-cluster exec octavia "docker ps"
bc exec alice "uptime"

# Run command on ALL devices
blackroad-cluster all "hostname"
bc all "df -h /"
bc all "docker ps -q | wc -l"

# Complex commands
bc exec lucidia "systemctl status tailscaled"
```

### Device Information

```bash
# Get detailed info about device
blackroad-cluster info octavia
bc info alice

# Shows:
# - System information
# - Network configuration
# - System resources
# - Disk usage
# - Docker containers
```

### Network Testing

```bash
# Ping single device
blackroad-cluster ping octavia
bc ping lucidia

# Ping all devices
blackroad-cluster ping
bc ping
```

### SSH Tunnels

```bash
# Create tunnel (local:remote)
blackroad-cluster tunnel octavia 8080 80
bc tunnel lucidia 3000 3000

# Access via localhost:8080
# Press Ctrl+C to close tunnel
```

### Monitoring

```bash
# Live monitoring dashboard (refreshes every 5s)
blackroad-cluster monitor
bc monitor

# Shows real-time:
# - Device status
# - Uptime
# - Load average
# - Last updated timestamp
```

## Common Workflows

### Check Cluster Health

```bash
# Quick health check
bc ping                    # Test connectivity
bc status                  # Full status with uptime/load
```

### Deploy to All Devices

```bash
# Update all systems
bc all "sudo apt update"

# Check Docker on all
bc all "docker --version"

# Restart service on all
bc all "sudo systemctl restart docker"
```

### Investigate Issues

```bash
# Check logs
bc exec octavia "journalctl -u docker -n 50"

# Check disk space
bc all "df -h / | tail -1"

# Check running containers
bc all "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

### Development Workflow

```bash
# Open tunnel to dev server
bc tunnel alice 3000 3000

# Check git status on device
bc exec alice "cd ~/project && git status"

# Deploy and test
bc exec octavia "cd ~/app && docker-compose up -d"
bc ssh octavia              # SSH in to debug
```

## Advanced Usage

### Custom SSH Options

The script uses `ConnectTimeout=5` by default. To customize, edit:
- `~/bin/blackroad-cluster`
- Search for `ssh -o ConnectTimeout=5`

### Adding New Devices

Edit `~/bin/blackroad-cluster`:

```zsh
# Add to DEVICES array
DEVICES=(
    # ... existing devices ...
    newdevice "192.168.4.XX"
)

# Add description
DEVICE_DESC=(
    # ... existing descriptions ...
    newdevice "Description of new device"
)

# Add user
DEVICE_USERS=(
    # ... existing users ...
    newdevice "username"
)
```

Then update the device list in `list_devices()`, `show_status()`, `exec_all()`, etc.

### Integration with Other Tools

```bash
# Use in scripts
for device in octavia alice lucidia; do
    bc exec $device "echo \$device: \$(hostname)"
done

# Export data
bc status > cluster-status.txt

# Pipe commands
bc list | grep octavia
```

## Troubleshooting

### SSH Connection Issues

```bash
# Test direct SSH
ssh pi@192.168.4.81

# Check SSH keys
ls -la ~/.ssh/*.pub

# Verify device is online
bc ping octavia
```

### Permission Denied

```bash
# Ensure SSH keys are set up
ssh-copy-id pi@192.168.4.81
ssh-copy-id alice@192.168.4.49
ssh-copy-id pi@192.168.4.38
ssh-copy-id pi@192.168.4.82
ssh-copy-id root@174.138.44.45
```

### Command Timeout

The default timeout is 5 seconds. For slow connections, edit the script:

```zsh
# Change ConnectTimeout value
ssh -o ConnectTimeout=10 ...
```

## Tips & Tricks

### Alias Examples

Add to `~/.zshrc`:

```bash
alias bcs='blackroad-cluster ssh'
alias bce='blackroad-cluster exec'
alias bca='blackroad-cluster all'
alias bcm='blackroad-cluster monitor'
```

### Watch Mode

```bash
# Monitor in real-time
watch -n 2 "blackroad-cluster status"

# Or use built-in monitor
bc monitor
```

### Batch Operations

```bash
# Restart all Docker services
bc all "sudo systemctl restart docker"

# Update all systems (be careful!)
bc all "sudo apt update && sudo apt upgrade -y"

# Collect logs
bc all "journalctl -u docker --since '1 hour ago' > /tmp/docker.log"
```

## Color Scheme

BlackRoad brand colors used:
- **Amber** (#F5A623): Device names
- **Hot Pink** (#FF1D6C): Headers/banners
- **Electric Blue** (#2979FF): Section titles
- **Cyan**: Labels
- **Green**: Online status/IPs
- **Red**: Errors/offline status
- **Yellow**: Warnings/users

## Version History

- **v1.0.0** (2026-01-10): Initial release
  - 5 devices registered
  - 11 commands available
  - Full monitoring capabilities
  - SSH tunnel support
  - Batch execution across all devices

## Support

For issues or feature requests:
- Email: blackroad.systems@gmail.com
- GitHub: BlackRoad-OS organization

---

**🖤 BlackRoad OS Infrastructure 🛣️**
