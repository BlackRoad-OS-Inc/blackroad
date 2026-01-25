# blackroad-cli

**AI Agent Orchestration CLI with consent management, policy enforcement, and audit trails.**

```bash
pip install blackroad-cli
```

## What is this?

`blackroad-cli` is a command-line tool for orchestrating AI agents with built-in:

- **Consent Management** - Agents must consent before executing tasks
- **Policy Enforcement** - SEC Rule 2042 compliance gate included
- **Audit Trails** - Full lineage tracking for every action
- **Task Routing** - Priority-based task distribution across bot fleet

## Quick Start

```bash
# List available bots
blackroad bot list

# Submit a task
blackroad task submit --type "code-review" --priority high "Review PR #123"

# Check task status
blackroad task status TSK-20241130-143022

# View audit trail
blackroad task lineage TSK-20241130-143022
```

## Commands

| Command | Description |
|---------|-------------|
| `blackroad bot list` | List all registered bots |
| `blackroad bot status <name>` | Get bot health status |
| `blackroad task submit` | Submit a new task |
| `blackroad task status <id>` | Check task status |
| `blackroad task lineage <id>` | View task audit trail |
| `blackroad policy check <action>` | Verify action against policies |
| `blackroad config show` | Display current configuration |
| `blackroad agent spawn` | Create a new agent instance |
| `blackroad agent retire` | Gracefully retire an agent |

## Architecture

```
blackroad-cli/
├── cli/           # Typer CLI entry points
│   ├── console.py      # Main CLI app
│   ├── consent_cli.py  # Consent management commands
│   ├── agent_manager.py # Agent lifecycle
│   └── consciousness_care.py # Agent wellbeing
├── orchestrator/  # Core orchestration engine
│   ├── router.py       # Task routing logic
│   ├── policy.py       # Policy enforcement
│   ├── lineage.py      # Audit trail tracking
│   └── consent.py      # Consent protocols
├── bots/          # Bot implementations
└── config/        # Configuration schemas
```

## Configuration

Create `~/.blackroad/config.yaml`:

```yaml
approvals:
  - alice@company.com
  - bob@company.com

policies:
  sec_2042:
    enabled: true
    require_human_approval: true

lineage:
  storage: local
  path: ~/.blackroad/lineage.jsonl
```

## License

MIT - See [LICENSE](LICENSE) for details.

---

Built by [BlackRoad OS](https://blackroad.io)

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson | **PROPRIETARY AND CONFIDENTIAL**

This software is NOT for commercial resale. Testing purposes only.

### 🏢 Enterprise Scale:
- 30,000 AI Agents
- 30,000 Human Employees
- CEO: Alexa Amundson

**Contact:** blackroad.systems@gmail.com

See [LICENSE](LICENSE) for complete terms.
