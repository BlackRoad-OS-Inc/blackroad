# BlackRoad OS Integration

This is a BlackRoad OS fork of **airbyte**.

## Gateway Integration

All AI features route through the BlackRoad tokenless gateway:
```
BLACKROAD_GATEWAY_URL=http://127.0.0.1:8787
```

## Agent Support

Tasks from this service can be routed to the agent fleet:
```bash
br agent route "airbyte" --task "your task"
```

## Memory Persistence

Operations logged to PS-SHA∞ hash-chain journal at `~/.blackroad/memory/`.

## Organization

**Blackbox-Enterprises** org · part of BlackRoad OS, Inc.

---
*© BlackRoad OS, Inc. All rights reserved.*
