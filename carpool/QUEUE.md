# [QUEUE] Message Queues

## Queue Types
| Queue | Purpose | Consumers |
|-------|---------|-----------|
| `tasks.high` | Urgent tasks | All agents |
| `tasks.normal` | Standard tasks | Available agents |
| `tasks.background` | Low priority | Idle agents |
| `signals.broadcast` | Global messages | All agents |
| `signals.direct` | 1:1 messages | Target agent |
| `events.stream` | Event log | ECHO, PRISM |
| `heartbeat` | Health checks | Carpool monitor |

## Queue Stats
```
tasks.high:      0 pending, 0 processing
tasks.normal:    5 pending, 2 processing
tasks.background: 3 pending, 0 processing
signals.broadcast: 1 pending
signals.direct:  0 pending
```

## Queue Commands
```bash
# Add to queue
echo '{"task":"..."}' >> carpool/queue/tasks.normal.jsonl

# Process from queue
head -1 carpool/queue/tasks.normal.jsonl

# Queue depth
wc -l carpool/queue/*.jsonl
```

## Dead Letter Queue
Failed messages go to `queue/dlq.jsonl` for retry or inspection.
