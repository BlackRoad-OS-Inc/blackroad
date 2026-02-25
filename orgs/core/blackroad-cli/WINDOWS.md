# BlackRoad Multi-Window Terminal

## Overview

The **Multi-Window Terminal** is a powerful feature of the BlackRoad CLI that provides simultaneous access to 7 different environments in a single terminal interface. Each window updates in real-time (every second), supports scrolling, copy/paste between windows, and has full internet access.

## Window Layout

```
┌──────────────────┬──────────────────┬──────────────────┐
│      ARIA        │      CODEX       │    SHELLFISH     │
│  192.168.4.64    │  159.65.43.12    │  174.138.44.45   │
│   (Raspberry Pi) │   (DigitalOcean) │   (Cloud Server) │
├──────────────────┼──────────────────┼──────────────────┤
│      ALICE       │     LUCIDIA      │     CLAUDE       │
│  192.168.4.49    │  192.168.4.38    │   (AI Assistant) │
│   (Pi Network)   │   (Raspberry Pi) │  Anthropic API   │
├──────────────────┴──────────────────┴──────────────────┤
│                     OLLAMA                              │
│              (Local AI - Full Width)                    │
│           llama3.2, codellama, mistral                  │
└─────────────────────────────────────────────────────────┘
```

## Features

### 🔌 SSH Windows (Top Row + Left Middle)

**ARIA** (192.168.4.64)
- Raspberry Pi node (user: alexa)
- Primary edge compute node
- Color: Orange (#FF9D00)

**CODEX** (159.65.43.12)
- DigitalOcean Droplet (user: root)
- Main cloud infrastructure
- Color: Deep Orange (#FF6B00)

**SHELLFISH** (174.138.44.45)
- Cloud server (user: root)
- Additional compute capacity
- Color: Pink (#FF0066)

**ALICE** (192.168.4.49)
- Pi network node (user: alice)
- Mesh networking
- Color: Magenta (#D600AA)

**LUCIDIA** (192.168.4.38)
- Primary Raspberry Pi (user: lucidia)
- Core local compute
- Color: Purple (#7700FF)

### 🤖 AI Windows

**CLAUDE** (Top Right)
- Anthropic Claude 3.5 Sonnet API
- Full conversation support
- Internet access via commands
- Color: Blue (#0066FF)

**Commands:**
```
/clear           - Clear conversation
/help            - Show help
/web <url>       - Fetch and analyze web content
```

**OLLAMA** (Bottom Full Width)
- Local AI models (llama3.2, codellama, mistral)
- No API key required
- Model switching
- Internet tools built-in
- Color: Teal (#00FFAA)

**Commands:**
```
/model <name>    - Switch AI model
/models          - List available models
/clear           - Clear conversation
/ping <host>     - Ping a host
/curl <url>      - Fetch URL content
```

## Controls

### Global Controls

| Key Combination | Action |
|----------------|--------|
| `Tab` | Switch to next window |
| `Ctrl+Y` | Copy content from focused window |
| `Ctrl+P` | Paste content to focused window |
| `Mouse Click` | Focus window |
| `Q` or `Esc` or `Ctrl+C` | Quit multi-window mode |

### Window-Specific Controls

| Key | Action |
|-----|--------|
| `↑` or `k` | Scroll up one line |
| `↓` or `j` | Scroll down one line |
| `Page Up` | Scroll up one page |
| `Page Down` | Scroll down one page |
| `Mouse Wheel` | Scroll in focused window |

### AI Window Input

When focused on Claude or Ollama windows:
- Type your message
- Press `Enter` to send
- Use `/` commands for special functions
- `Backspace` to edit current input

## Features in Detail

### 🔄 Real-Time Updates

All windows update every second:
- SSH connections send keepalive packets
- Status bar shows current time
- Connection status monitored
- Active window count displayed

### 📋 Inter-Window Copy/Paste

Copy/paste workflow:
1. Focus the window you want to copy from (click or Tab)
2. Press `Ctrl+Y` to copy content
3. Focus target window
4. Press `Ctrl+P` to paste

Perfect for:
- Moving commands between servers
- Sharing AI responses
- Copying logs for analysis
- Transferring configurations

### 📜 Scrolling

Each window maintains up to 1000 lines of history:
- Vim-style navigation (`j`/`k`)
- Standard arrow keys
- Page Up/Down for quick navigation
- Auto-scrolls to bottom on new output
- Mouse wheel support

### 🌐 Internet Access

All windows have internet access:

**SSH Windows:**
- Full shell access
- `curl`, `wget`, `ping`, etc.
- Install packages
- Git operations
- API calls

**AI Windows:**
- `/web <url>` - Fetch and analyze web pages
- `/ping <host>` - Test connectivity
- `/curl <url>` - Download content
- Queries can include URLs for real-time info

## Usage Examples

### Starting Multi-Window Terminal

```bash
# Start the multi-window interface
br windows

# or use the alias
br w
```

### Example Workflows

**1. Deploy Across Multiple Servers**
```
[ARIA] > git pull && pm2 restart all
[CODEX] > git pull && systemctl restart nginx
[SHELLFISH] > docker-compose up -d
```

**2. Monitor Logs Simultaneously**
```
[ARIA] > tail -f /var/log/app.log
[LUCIDIA] > journalctl -f
[CODEX] > docker logs -f myapp
```

**3. Ask AI About Code**
```
[CLAUDE] > /web https://docs.anthropic.com/api
[CLAUDE] > Explain how to use the Messages API
[OLLAMA] > Write a Python script to call the API
```

**4. Network Diagnostics**
```
[ARIA] > ping 192.168.4.64
[ALICE] > traceroute blackroad.io
[OLLAMA] > /ping google.com
```

**5. Cross-Server File Transfer**
```
[ARIA] > cat config.json
# Copy with Ctrl+Y
[CODEX] > nano config.json
# Paste with Ctrl+P
```

## Setup Requirements

### SSH Connections

Ensure SSH key-based authentication is configured:

```bash
# Generate SSH key if needed
ssh-keygen -t ed25519 -C "blackroad-cli"

# Copy to servers
ssh-copy-id alexa@192.168.4.64
ssh-copy-id root@159.65.43.12
ssh-copy-id root@174.138.44.45
ssh-copy-id alice@192.168.4.49
ssh-copy-id lucidia@192.168.4.38
```

### Claude API

Set your Anthropic API key:

```bash
export ANTHROPIC_API_KEY=your-key-here

# Add to ~/.zshrc or ~/.bashrc to persist
echo 'export ANTHROPIC_API_KEY=your-key-here' >> ~/.zshrc
```

### Ollama

Install and start Ollama:

```bash
# Install Ollama
brew install ollama  # macOS
# or visit https://ollama.ai

# Start Ollama service
ollama serve

# Pull models
ollama pull llama3.2
ollama pull codellama
ollama pull mistral
```

## Status Bar

The bottom status bar shows:
- **Active connections**: Number of live SSH sessions
- **Current time**: Updates every second
- **Keyboard shortcuts**: Quick reference
- **System status**: Overall health

Format:
```
BlackRoad OS Multi-Window | 5 active | Tab=Switch C-y=Copy C-p=Paste Q=Quit | 14:23:45
```

## Tips & Tricks

### 1. Quick Navigation
Use `Tab` repeatedly to cycle through all windows quickly. The focused window has a white border.

### 2. AI-Assisted Debugging
Copy error messages from SSH windows and paste into Claude/Ollama for instant analysis and solutions.

### 3. Model Selection
Use codellama in Ollama for code-specific tasks, llama3.2 for general chat, and mistral for fast responses.

### 4. Web Research
Claude can fetch and analyze live web content - perfect for checking documentation or API status.

### 5. Parallel Execution
Run the same command on multiple servers simultaneously by quickly switching windows with Tab.

### 6. Log Monitoring
Open log files in multiple SSH windows and use scrolling to review different sections while other windows continue updating.

## Troubleshooting

**SSH Connection Fails**
```
- Check SSH keys are properly configured
- Verify host is reachable: ping <host>
- Test manual SSH: ssh user@host
```

**Claude Not Responding**
```
- Verify ANTHROPIC_API_KEY is set
- Check internet connection
- Ensure API key has sufficient credits
```

**Ollama Not Working**
```
- Start Ollama: ollama serve
- Check service: curl http://localhost:11434
- Pull models: ollama pull llama3.2
```

**Window Not Updating**
```
- Check internet connection
- Restart multi-window: Q then br windows
- Verify SSH connection didn't timeout
```

## Performance Notes

- Each SSH window maintains its own process
- AI requests are async and non-blocking
- Maximum 1000 lines per window buffer
- 1-second update interval is configurable
- Low CPU usage when idle
- Network bandwidth depends on activity

## Advanced Configuration

The windows can be customized by editing:
```
~/blackroad-cli/commands/windows.js
```

Modify:
- `WINDOWS` object for different hosts
- Layout percentages for window sizes
- Update interval (default: 1000ms)
- Color schemes
- Buffer sizes

## Integration with Other Commands

The multi-window terminal works alongside other BR commands:

```bash
# Check status before opening windows
br status

# View network map
br network

# Then open multi-window for detailed work
br windows
```

## Security Considerations

- SSH connections use key-based authentication
- API keys loaded from environment variables
- No credentials stored in code
- Each window is isolated
- Clipboard data cleared on exit

---

**Built with ❤️ by BlackRoad OS**

Experience the power of simultaneous multi-environment management with AI assistance, all in a single terminal interface!
