# [EVENTS] Carpool Event Stream

## Event Types
| Event | Description | Priority |
|-------|-------------|----------|
| `agent.created` | New agent added | P3 |
| `agent.revived` | Agent reactivated | P3 |
| `agent.died` | Agent unresponsive | P1 |
| `task.posted` | New task available | P3 |
| `task.claimed` | Task assigned | P3 |
| `task.completed` | Task finished | P3 |
| `signal.broadcast` | Message to all | P2 |
| `signal.alert` | Urgent message | P0 |
| `memory.write` | Journal entry | P4 |
| `system.error` | System failure | P0 |

## Event Format
```json
{
  "id": "evt-uuid",
  "timestamp": "ISO8601",
  "type": "event.type",
  "actor": "agent-name",
  "target": "target-name",
  "data": {},
  "priority": "P0-P4"
}
```

## Event Subscriptions
| Agent | Subscribed Events |
|-------|-------------------|
| LUCIDIA | ALL |
| ECHO | memory.*, agent.* |
| CIPHER | signal.alert, system.error |
| ALICE | task.*, signal.* |
| PRISM | memory.*, task.completed |

## Recent Events
See `carpool/events/stream.jsonl`
