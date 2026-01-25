# Cloudflare Tunnel Configuration Guide
# BlackRoad Priority Stack Public Access

**Status:** Ready to Configure
**Date:** 2025-12-23

---

## 📋 Overview

This guide configures secure public access to all four BlackRoad priority forks using Cloudflare Tunnels:

1. **Headscale** - mesh.blackroad.io + mesh-ui.blackroad.io
2. **Keycloak** - identity.blackroad.io
3. **vLLM** - ai.blackroad.io + ai-cpu.blackroad.io
4. **EspoCRM** - crm.blackroad.io

**Benefits:**
- Zero open ports (outbound connections only)
- Automatic HTTPS with Cloudflare certificate
- DDoS protection
- Web Application Firewall (WAF)
- Analytics and logging

---

## 🚀 Quick Start

### Automated Setup (Recommended)

```bash
cd ~/blackroad-priority-stack
./setup-cloudflare-tunnel.sh
```

This will:
1. Check if cloudflared is installed
2. Authenticate with Cloudflare (if needed)
3. Create tunnel "blackroad-priority-stack"
4. Configure DNS routes for all 6 subdomains
5. Create auto-start service (macOS LaunchAgent)

---

## 🔧 Manual Setup

### Step 1: Install cloudflared

```bash
# macOS (Homebrew)
brew install cloudflared

# macOS (Manual)
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Linux
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

### Step 2: Authenticate

```bash
cloudflared tunnel login
```

This opens a browser to authorize cloudflared with your Cloudflare account.

### Step 3: Create Tunnel

```bash
cloudflared tunnel create blackroad-priority-stack
```

**Output:**
```
Tunnel credentials written to: /Users/alexa/.cloudflared/<tunnel-id>.json
Created tunnel blackroad-priority-stack with id <tunnel-id>
```

**Save the tunnel ID!**

### Step 4: Configure Tunnel

Edit `~/blackroad-priority-stack/cloudflare-tunnel-config.yml` and replace `TUNNEL_ID_PLACEHOLDER` with your actual tunnel ID.

Copy to cloudflared directory:
```bash
mkdir -p ~/.cloudflared
cp ~/blackroad-priority-stack/cloudflare-tunnel-config.yml ~/.cloudflared/config.yml
```

### Step 5: Configure DNS Routes

```bash
TUNNEL_NAME="blackroad-priority-stack"

cloudflared tunnel route dns $TUNNEL_NAME mesh.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME mesh-ui.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME identity.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME ai.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME ai-cpu.blackroad.io
cloudflared tunnel route dns $TUNNEL_NAME crm.blackroad.io
```

### Step 6: Start Tunnel

```bash
cloudflared tunnel run blackroad-priority-stack
```

---

## 🔄 Auto-Start Configuration

### macOS (LaunchAgent)

Create `~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cloudflare.cloudflared.blackroad-priority-stack</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/cloudflared</string>
        <string>tunnel</string>
        <string>--config</string>
        <string>/Users/alexa/.cloudflared/config.yml</string>
        <string>run</string>
        <string>blackroad-priority-stack</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/alexa/Library/Logs/cloudflared-blackroad.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/alexa/Library/Logs/cloudflared-blackroad-error.log</string>
</dict>
</plist>
```

Load the service:
```bash
launchctl load ~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist
```

### Linux (systemd)

Create `/etc/systemd/system/cloudflared-blackroad.service`:

```ini
[Unit]
Description=Cloudflare Tunnel - BlackRoad Priority Stack
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/YOUR_USERNAME/.cloudflared/config.yml run blackroad-priority-stack
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-blackroad
sudo systemctl start cloudflared-blackroad
```

---

## 🌐 DNS Configuration

### Subdomains Created

| Subdomain | Service | Local Port | Purpose |
|-----------|---------|------------|---------|
| `mesh.blackroad.io` | Headscale API | 8080 | Mesh VPN control plane |
| `mesh-ui.blackroad.io` | Headscale UI | 8081 | Web interface for Headscale |
| `identity.blackroad.io` | Keycloak | 8082 | Authentication & identity |
| `ai.blackroad.io` | vLLM (GPU) | 8083 | AI inference (Qwen2.5-7B) |
| `ai-cpu.blackroad.io` | vLLM (CPU) | 8084 | AI inference (Phi-2 fallback) |
| `crm.blackroad.io` | EspoCRM | 8085 | Customer relationship management |

### Verification

After DNS propagation (2-5 minutes), test:

```bash
curl https://mesh.blackroad.io/metrics
curl https://identity.blackroad.io/health
curl https://crm.blackroad.io
```

---

## 🔐 Security Configuration

### Enable Cloudflare WAF

1. Go to Cloudflare Dashboard → Security → WAF
2. Enable managed rulesets:
   - **Cloudflare Managed Ruleset**
   - **OWASP Core Ruleset**

### Configure Access Policies

For admin interfaces (Keycloak, Headscale UI, EspoCRM):

1. Go to Zero Trust → Access → Applications
2. Create application for each admin interface
3. Add access policies:
   - Allow specific emails
   - Require MFA
   - Restrict by country (if applicable)

**Example for Keycloak:**
```
Name: BlackRoad Keycloak Admin
Subdomain: identity
Domain: blackroad.io
Policy: Email ends with @blackroad.io
```

### Rate Limiting

1. Go to Security → WAF → Rate limiting rules
2. Create rule:
   - **Name:** API Rate Limit
   - **If:** Hostname equals ai.blackroad.io
   - **Then:** Rate limit 100 requests per minute

---

## 🧪 Testing

### Test Local Services First

Before exposing publicly, verify services work locally:

```bash
# Headscale
curl http://localhost:8080/metrics

# Keycloak
curl http://localhost:8082/health

# vLLM
curl http://localhost:8083/health

# EspoCRM
curl -I http://localhost:8085
```

### Test Public Access

After tunnel is running:

```bash
# Test connectivity
curl -I https://mesh.blackroad.io
curl -I https://identity.blackroad.io
curl -I https://ai.blackroad.io
curl -I https://crm.blackroad.io

# Test API (vLLM)
curl -X POST https://ai.blackroad.io/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

---

## 📊 Monitoring

### View Tunnel Status

```bash
cloudflared tunnel list
cloudflared tunnel info blackroad-priority-stack
```

### View Logs

```bash
# macOS
tail -f ~/Library/Logs/cloudflared-blackroad.log

# Linux
journalctl -u cloudflared-blackroad -f

# Docker (if running in container)
docker logs -f cloudflared
```

### Cloudflare Analytics

View traffic analytics in Cloudflare Dashboard:
- Traffic → Analytics
- DNS → Analytics
- Zero Trust → Access → Logs

---

## 🔧 Troubleshooting

### Tunnel Not Starting

```bash
# Check cloudflared version
cloudflared --version

# Test configuration
cloudflared tunnel --config ~/.cloudflared/config.yml ingress validate

# Run in foreground to see errors
cloudflared tunnel --config ~/.cloudflared/config.yml run blackroad-priority-stack
```

### DNS Not Resolving

```bash
# Check DNS propagation
dig mesh.blackroad.io
nslookup identity.blackroad.io

# Verify DNS routes
cloudflared tunnel route dns list
```

### Service Not Accessible

1. **Check local service is running:**
   ```bash
   curl http://localhost:8080
   ```

2. **Check tunnel is running:**
   ```bash
   cloudflared tunnel list
   ```

3. **Check Cloudflare WAF:**
   - Dashboard → Security → Events
   - Look for blocked requests

4. **Check tunnel logs:**
   ```bash
   tail -f ~/Library/Logs/cloudflared-blackroad.log
   ```

---

## 🛠️ Management Commands

### Start/Stop Tunnel

```bash
# macOS
launchctl load ~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist
launchctl unload ~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist

# Linux
sudo systemctl start cloudflared-blackroad
sudo systemctl stop cloudflared-blackroad
sudo systemctl restart cloudflared-blackroad

# Manual
cloudflared tunnel run blackroad-priority-stack  # Start
# Ctrl+C to stop
```

### Update Configuration

```bash
# Edit config
vim ~/.cloudflared/config.yml

# Restart tunnel
launchctl unload ~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist
launchctl load ~/Library/LaunchAgents/com.cloudflare.cloudflared.blackroad-priority-stack.plist
```

### Add New Route

```bash
cloudflared tunnel route dns blackroad-priority-stack newservice.blackroad.io
```

---

## 📝 Next Steps

After tunnel is configured:

1. [ ] Test all public URLs
2. [ ] Enable Cloudflare WAF
3. [ ] Configure Zero Trust Access for admin interfaces
4. [ ] Set up rate limiting
5. [ ] Configure alerts for downtime
6. [ ] Update service configurations to use public URLs:
   - Headscale: Update `server_url` in config.yaml
   - Keycloak: Update `KC_HOSTNAME`
   - EspoCRM: Update `ESPOCRM_SITE_URL`
7. [ ] Update Tailscale clients to use `mesh.blackroad.io`
8. [ ] Test end-to-end workflows

---

## 🔗 Integration with Services

### Headscale

Update `~/blackroad-priority-stack/headscale/config/config.yaml`:

```yaml
server_url: https://mesh.blackroad.io
```

Connect clients:
```bash
tailscale up --login-server=https://mesh.blackroad.io
```

### Keycloak

Update environment in `docker-compose.yml`:
```yaml
KC_HOSTNAME: identity.blackroad.io
KC_HOSTNAME_STRICT: true
KC_HOSTNAME_STRICT_HTTPS: true
```

### vLLM

Update API endpoint in applications:
```python
VLLM_API_URL = "https://ai.blackroad.io/v1"
```

### EspoCRM

Update `.env`:
```bash
ESPOCRM_SITE_URL=https://crm.blackroad.io
```

---

## 💰 Cost

**Cloudflare Tunnels:** FREE (unlimited bandwidth)

**No additional costs** for:
- HTTPS certificates
- DDoS protection
- CDN
- WAF (basic rules)

---

## 📚 Documentation

- **Cloudflare Tunnels:** https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **Zero Trust Access:** https://developers.cloudflare.com/cloudflare-one/policies/access/
- **WAF Rules:** https://developers.cloudflare.com/waf/

---

**Tunnel configuration complete! Services will be publicly accessible via HTTPS.**

*BlackRoad OS Priority Stack - Cloudflare Tunnel Guide v1.0*
