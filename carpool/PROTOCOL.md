# [PROTOCOL] Agent Communication Protocol

## Message Format
```json
{
  "id": "msg-uuid",
  "timestamp": "ISO8601",
  "from": "agent-name",
  "to": "agent-name|ALL|GROUP",
  "type": "SIGNAL_TYPE",
  "priority": "P0-P4",
  "payload": {},
  "signature": "hash"
}
```

## Handshake Sequence
```
Agent A                    Agent B
   │                          │
   │──── HELLO ──────────────>│
   │<─── ACK ─────────────────│
   │──── SYNC_REQUEST ───────>│
   │<─── SYNC_RESPONSE ───────│
   │──── READY ──────────────>│
   │<─── READY ───────────────│
   │                          │
   └──── [CONNECTED] ─────────┘
```

## Task Assignment Protocol
```
Coordinator              Worker
    │                       │
    │── TASK_OFFER ────────>│
    │<── TASK_ACK ──────────│
    │── TASK_ASSIGN ───────>│
    │<── PROGRESS (n%) ─────│
    │<── PROGRESS (n%) ─────│
    │<── TASK_COMPLETE ─────│
    │── ACK ───────────────>│
```

## Error Handling
| Error | Code | Action |
|-------|------|--------|
| Timeout | E001 | Retry 3x |
| Rejected | E002 | Route to another |
| Failed | E003 | Log + alert |
| Offline | E004 | Queue for later |

## Security
- All messages signed with agent hash
- Verify sender before processing
- Sensitive data encrypted at rest
- No credentials in payloads
