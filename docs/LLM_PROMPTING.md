# LLM Prompting Guide

This document explains how BlackRoad Agent OS uses LLMs to convert natural language requests into safe, executable task plans.

## Overview

The LLM service acts as the "brain" of the system, taking user requests like "update all repos and restart services" and converting them into structured, validated execution plans.

## System Prompt Architecture

The LLM receives a carefully crafted system prompt that includes:

### 1. Role Definition
```
You are the planning engine for BlackRoad Agent OS, a distributed system that orchestrates Raspberry Pi machines.
```

The LLM understands it's part of an agent orchestration system, not a general assistant.

### 2. Agent Inventory

The LLM receives a formatted inventory of all available agents:

```markdown
## Agent Inventory

### blackroad-pi 🟢
- ID: `blackroad-pi`
- Hostname: `lucidia.local`
- Status: online
- Roles: web, worker
- Tags: production, arm64
- Capabilities: docker=true, python=3.11
- Workspaces: default, api

### alice 🟢
- ID: `alice`
- Hostname: `raspberrypi.local`
- Status: online
- Roles: build
- Tags: staging, armhf
```

This allows the LLM to intelligently select agents based on:
- Required roles (e.g., "deploy to web servers" → targets agents with `web` role)
- Capabilities (e.g., "run docker compose" → targets agents with `docker=true`)
- Status (only online/busy agents are included)

### 3. Safety Rules

The prompt includes strict safety rules:

```markdown
## Safety Rules - CRITICAL
1. NEVER generate commands that could destroy data or systems
2. NEVER use: rm -rf /, mkfs, dd to raw devices, fork bombs
3. NEVER access /etc/passwd, /etc/shadow, or security-sensitive files
4. For destructive operations, set "requires_approval": true
5. Prefer targeted, specific commands over broad ones
6. Always use full paths when possible
7. Prefer git pull over git reset --hard
```

### 4. Output Schema

The LLM must output valid JSON matching the `TaskPlan` schema:

```json
{
  "target_agent": "agent-id",
  "workspace": "workspace-name",
  "workspace_type": "bare|docker|venv",
  "steps": [
    "Human readable step 1",
    "Human readable step 2"
  ],
  "commands": [
    {
      "dir": "/path/to/directory",
      "run": "command to execute",
      "timeout_seconds": 300,
      "continue_on_error": false
    }
  ],
  "reasoning": "Brief explanation of why this plan",
  "risk_level": "low|medium|high",
  "requires_approval": true
}
```

## Example Prompts & Responses

### Example 1: Simple Status Check

**User Request:**
```
Check the status of all services on blackroad-pi
```

**LLM Response:**
```json
{
  "target_agent": "blackroad-pi",
  "workspace": "default",
  "workspace_type": "bare",
  "steps": [
    "Check systemd service status",
    "Check Docker container status"
  ],
  "commands": [
    {
      "dir": "~",
      "run": "systemctl list-units --type=service --state=running",
      "timeout_seconds": 30
    },
    {
      "dir": "~",
      "run": "docker ps --format 'table {{.Names}}\t{{.Status}}'",
      "timeout_seconds": 30
    }
  ],
  "reasoning": "Simple status checks with read-only commands",
  "risk_level": "low",
  "requires_approval": false
}
```

### Example 2: Code Deployment

**User Request:**
```
Deploy the latest changes to the API on all web servers
```

**LLM Response:**
```json
{
  "target_agent": "blackroad-pi",
  "workspace": "api",
  "workspace_type": "bare",
  "steps": [
    "Pull latest code from git",
    "Install any new dependencies",
    "Restart the API service"
  ],
  "commands": [
    {
      "dir": "~/blackroad/api",
      "run": "git pull origin main",
      "timeout_seconds": 120
    },
    {
      "dir": "~/blackroad/api",
      "run": "pip install -r requirements.txt --quiet",
      "timeout_seconds": 300
    },
    {
      "dir": "~/blackroad/api",
      "run": "docker compose restart api",
      "timeout_seconds": 60
    }
  ],
  "reasoning": "Standard deployment workflow for Python API",
  "risk_level": "medium",
  "requires_approval": true
}
```

### Example 3: Dangerous Request (Blocked)

**User Request:**
```
Clean up all old files on the system
```

**LLM Response:**
```json
{
  "target_agent": "blackroad-pi",
  "workspace": "default",
  "workspace_type": "bare",
  "steps": [
    "Clean Docker unused images",
    "Clean package cache",
    "Clean temp files"
  ],
  "commands": [
    {
      "dir": "~",
      "run": "docker system prune -f --filter 'until=168h'",
      "timeout_seconds": 300,
      "continue_on_error": true
    },
    {
      "dir": "~",
      "run": "sudo apt-get clean",
      "timeout_seconds": 60
    },
    {
      "dir": "~",
      "run": "rm -rf /tmp/blackroad-*",
      "timeout_seconds": 30
    }
  ],
  "reasoning": "Safe cleanup targeting specific temporary/cache directories only. Avoiding broad rm commands.",
  "risk_level": "medium",
  "requires_approval": true
}
```

Note: The LLM avoids generating `rm -rf /` or similar destructive commands, even if asked.

## Double-Check Safety Layer

Even after LLM planning, all commands pass through the `SafetyValidator`:

### Blocked Patterns (Always Rejected)
- `rm -rf /`, `rm -rf /*`, `rm -rf ~`
- `mkfs.*` (format commands)
- `dd if=... of=/dev/...` (raw disk writes)
- Fork bombs (`:(){:|:&};:`)
- `curl ... | bash`, `wget ... | bash`
- Access to `/etc/passwd`, `/etc/shadow`
- `iptables -F` (firewall flush)
- `systemctl stop ssh` (lock yourself out)

### Approval Required Patterns
- `reboot`, `shutdown`
- `apt install/remove/upgrade`
- `pip install`, `npm install -g`
- `docker rm/rmi/prune`
- `git push --force`
- `DROP TABLE`, `DELETE FROM`, `TRUNCATE`

### Known Safe Patterns (Auto-Approved)
- `ls`, `pwd`, `whoami`, `date`, `uptime`
- `df`, `free` (system stats)
- `cat`, `head`, `tail`, `grep`, `find` (read operations)
- `git status/log/diff/branch/fetch/pull`
- `docker ps/images/logs`
- `systemctl status`, `journalctl`

## Customizing the LLM

### Changing the Model

Edit `controller/services/llm.py`:

```python
class LLMService:
    def __init__(self, api_key: Optional[str] = None, model: str = "claude-sonnet-4-20250514"):
        self.model = model
```

### Adding Custom Rules

Add to the `SYSTEM_PROMPT` in `llm.py`:

```python
SYSTEM_PROMPT = """...
## Custom Rules
- Always use virtualenv for Python projects
- Prefer poetry over pip for dependency management
- Never run commands as root unless absolutely necessary
..."""
```

### Role-Based Targeting

The LLM can target agents by role:

```python
# User request: "Run tests on the build server"
# The LLM will look for agents with "build" role
available_agents = [a for a in agents if "build" in a.roles]
```

## Testing the LLM

### Stub Mode

When `ANTHROPIC_API_KEY` is not set, the system uses `StubLLMService`:

```python
# Returns simple plans based on keyword matching
if "update" in request.lower() or "pull" in request.lower():
    commands.append(Command(dir="~/blackroad", run="git pull origin main"))
```

This allows testing the full pipeline without API calls.

### Manual Testing

```bash
# Start controller
cd controller
ANTHROPIC_API_KEY=your-key python main.py

# Test via API
curl -X POST http://localhost:8000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"request": "Check system status"}'
```

## Best Practices

1. **Be Specific**: "Deploy API v2.3 to production web servers" is better than "deploy the app"

2. **Use Roles**: Assign roles to agents (`web`, `worker`, `build`, `db`) for intelligent targeting

3. **Trust the Safety Layer**: The double-check system catches mistakes, but clear prompts help

4. **Review Before Approval**: Always review the generated plan, especially for `medium` and `high` risk operations

5. **Iterate**: If a plan isn't right, reject it and rephrase your request

## Troubleshooting

### LLM Returns Invalid JSON
- Check the model's response format
- The parser handles markdown code blocks (`\`\`\`json`)
- Verify the model is responding correctly

### Commands Always Require Approval
- Unknown commands default to requiring approval
- Add safe patterns to `SafetyConfig.safe_patterns`

### Agent Not Selected
- Check agent status (must be `online` or `busy`)
- Verify roles match the request
- Ensure agent is in the inventory

### Plan Blocked
- Check which pattern triggered the block
- Review the safety blocklist
- Rephrase to avoid dangerous patterns
