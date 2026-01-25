# BlackRoad Agent OS - Setup Guide

This guide walks you through deploying BlackRoad Agent OS with a controller on your main machine and agents on your Raspberry Pis.

## Prerequisites

### Controller Machine (Mac/Linux)
- Python 3.11+
- Docker (optional, for containerized deployment)
- Anthropic API key (for Claude LLM)

### Agent Machines (Raspberry Pi)
- Raspberry Pi OS (Bookworm or newer)
- Python 3.11+
- Docker (optional)
- Network connectivity to controller

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/BlackRoad-OS/blackroad-agent-os.git
cd blackroad-agent-os
```

### 2. Set Up the Controller

```bash
cd controller

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export ANTHROPIC_API_KEY="your-api-key"
export PORT=8000

# Run the controller
python main.py
```

The controller will start on `http://localhost:8000`.

### 3. Set Up a Pi Agent

SSH into your Raspberry Pi:

```bash
ssh pi@your-pi-hostname.local
```

Then set up the agent:

```bash
# Clone the repo
git clone https://github.com/BlackRoad-OS/blackroad-agent-os.git
cd blackroad-agent-os/agent

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure the agent
export AGENT_ID="blackroad-pi"
export CONTROLLER_URL="ws://your-controller-ip:8000/ws/agent"
export AGENT_ROLES="web,worker"
export AGENT_TAGS="production"

# Run the agent
python main.py
```

## Production Deployment

### Controller as systemd Service

Create `/etc/systemd/system/blackroad-controller.service`:

```ini
[Unit]
Description=BlackRoad Agent OS Controller
After=network.target

[Service]
Type=simple
User=blackroad
WorkingDirectory=/opt/blackroad-agent-os/controller
Environment=ANTHROPIC_API_KEY=your-api-key
Environment=PORT=8000
ExecStart=/opt/blackroad-agent-os/controller/venv/bin/python main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable blackroad-controller
sudo systemctl start blackroad-controller
```

### Agent as systemd Service

Create `/etc/systemd/system/blackroad-agent.service` on each Pi:

```ini
[Unit]
Description=BlackRoad Agent Daemon
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/blackroad-agent-os/agent
Environment=AGENT_ID=blackroad-pi
Environment=CONTROLLER_URL=ws://controller-hostname:8000/ws/agent
Environment=AGENT_ROLES=web,worker
Environment=AGENT_TAGS=production
ExecStart=/home/pi/blackroad-agent-os/agent/venv/bin/python main.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable blackroad-agent
sudo systemctl start blackroad-agent
```

## Cloudflare Tunnel Access

If your controller is behind a firewall, use Cloudflare Tunnel:

```bash
# Install cloudflared on controller
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create blackroad

# Configure tunnel
cat > ~/.cloudflared/config.yml << EOF
tunnel: YOUR_TUNNEL_ID
credentials-file: /home/pi/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  - hostname: blackroad.yourdomain.com
    service: http://localhost:8000
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run blackroad
```

Update agent configuration to use the tunnel URL:

```bash
export CONTROLLER_URL="wss://blackroad.yourdomain.com/ws/agent"
```

## Configuration Reference

### Controller Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 8000 | HTTP server port |
| `ANTHROPIC_API_KEY` | - | Claude API key (required for LLM) |
| `LOG_LEVEL` | INFO | Logging level |

### Agent Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENT_ID` | hostname | Unique agent identifier |
| `CONTROLLER_URL` | ws://localhost:8000/ws/agent | WebSocket URL to controller |
| `AGENT_DISPLAY_NAME` | - | Human-friendly name |
| `AGENT_ROLES` | - | Comma-separated roles (web,worker,build) |
| `AGENT_TAGS` | - | Comma-separated tags (production,staging) |
| `HEARTBEAT_INTERVAL` | 15 | Seconds between heartbeats |
| `RECONNECT_DELAY` | 5 | Seconds before reconnection attempt |
| `WORKSPACE_ROOT` | ~/blackroad/workspaces | Directory for workspaces |
| `DOCKER_ENABLED` | true | Enable Docker workspaces |
| `LOG_LEVEL` | INFO | Logging level |

## Verifying the Setup

### Check Controller Health

```bash
curl http://localhost:8000/health
```

Expected response:

```json
{
  "status": "healthy",
  "agents": {
    "total": 2,
    "online": 2,
    "available": 2
  }
}
```

### Check Agent Connection

```bash
curl http://localhost:8000/api/agents
```

Expected response:

```json
[
  {
    "id": "blackroad-pi",
    "hostname": "lucidia.local",
    "display_name": "blackroad-pi",
    "status": "online",
    "roles": ["web", "worker"],
    "capabilities": {
      "docker": true,
      "python": "3.11.2"
    }
  }
]
```

### Submit a Test Task

```bash
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"request": "Check system uptime", "skip_approval": true}'
```

## Web UI

Access the web interface at `http://localhost:8000/static/index.html`

Features:
- Real-time agent status monitoring
- Task creation and management
- Plan review and approval
- Live command output streaming
- Task history and audit logs

## Troubleshooting

### Agent Won't Connect

1. Check network connectivity:
   ```bash
   ping controller-hostname
   ```

2. Verify WebSocket port is open:
   ```bash
   curl http://controller-hostname:8000/health
   ```

3. Check agent logs:
   ```bash
   journalctl -u blackroad-agent -f
   ```

### Commands Timeout

1. Increase timeout in task request:
   ```json
   {"request": "...", "timeout_seconds": 600}
   ```

2. Check agent telemetry for resource constraints

### LLM Returns Empty Plans

1. Verify API key is set:
   ```bash
   echo $ANTHROPIC_API_KEY
   ```

2. Check controller logs for API errors:
   ```bash
   journalctl -u blackroad-controller -f
   ```

3. Test without LLM (stub mode) by unsetting the API key

## Security Considerations

1. **API Key Protection**: Never commit API keys. Use environment variables or secrets management.

2. **Network Security**: Use TLS for production. Cloudflare Tunnel provides this automatically.

3. **Agent Authentication**: In production, implement token-based agent authentication.

4. **Command Auditing**: All commands are logged in `/logs/audit/audit-YYYY-MM-DD.jsonl`.

5. **Approval Workflow**: Enable approval for all tasks in production (`skip_approval: false`).

## Next Steps

- [Architecture Documentation](./ARCHITECTURE.md)
- [LLM Prompting Guide](./LLM_PROMPTING.md)
- [API Reference](../schemas/api.yaml)
