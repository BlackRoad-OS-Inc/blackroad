# [ALERTS] Alert System

## Alert Levels
| Level | Symbol | Action |
|-------|--------|--------|
| INFO | 🔵 | Log only |
| WARNING | 🟡 | Log + notify |
| ERROR | 🟠 | Log + notify + escalate |
| CRITICAL | 🔴 | All hands |

## Active Alerts
```
🔵 No active alerts
```

## Alert Channels
| Channel | Recipients | Method |
|---------|------------|--------|
| Core | LUCIDIA, CIPHER | Direct signal |
| All | Everyone | Broadcast |
| Hardware | Pi agents | Direct |
| Workers | 41 workers | Batch |

## Alert Format
```json
{
  "id": "alert-uuid",
  "level": "WARNING",
  "source": "agent-name",
  "message": "Description",
  "timestamp": "ISO8601",
  "acknowledged": false
}
```

## Acknowledge Alert
```bash
echo '{"id":"alert-001","ack_by":"CIPHER"}' >> carpool/alerts/acks.jsonl
```

## Escalation Path
```
INFO → (no escalation)
WARNING → LUCIDIA
ERROR → LUCIDIA + CIPHER
CRITICAL → ALL CORE + Alexandria
```
