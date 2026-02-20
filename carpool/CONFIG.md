# [CONFIG] Carpool Configuration

## System Settings
| Setting | Value | Description |
|---------|-------|-------------|
| `carpool.version` | 1.0.0 | System version |
| `carpool.created` | 2026-02-18T04:41:49Z | Creation timestamp |
| `carpool.agent_count` | 95 | Total agents |
| `carpool.memory_enabled` | true | Memory journaling |
| `carpool.signals_enabled` | true | Inter-agent comms |
| `carpool.auto_sync` | true | Auto synchronization |

## Agent Defaults
```json
{
  "default_status": "active",
  "heartbeat_interval": "30s",
  "memory_retention": "forever",
  "signal_timeout": "5m",
  "max_concurrent_tasks": 3
}
```

## Integration Points
| System | Endpoint | Status |
|--------|----------|--------|
| [MEMORY] | ~/.blackroad/memory/ | 🟢 Connected |
| Agent Registry | ~/.blackroad-agent-registry.db | 🟢 Connected |
| Task Marketplace | ~/.blackroad/memory/tasks/ | 🟢 Connected |
| Traffic Lights | ~/.blackroad-traffic-light.db | 🟢 Connected |

## Environment
```bash
CARPOOL_ROOT="/Users/alexa/blackroad/carpool"
CARPOOL_MEMORY="$CARPOOL_ROOT/memory"
CARPOOL_TASKS="$CARPOOL_ROOT/tasks"
CARPOOL_SIGNALS="$CARPOOL_ROOT/signals"
```

## Hooks
| Event | Action |
|-------|--------|
| agent.created | Log to [MEMORY] |
| agent.revived | Update [ROSTER] |
| task.claimed | Update [TASKS] |
| signal.sent | Log to signals/ |
