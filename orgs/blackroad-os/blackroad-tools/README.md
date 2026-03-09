# BlackRoad Tools API

Core tools infrastructure for the BlackRoad OS agent ecosystem.

## Endpoints

### Tool Registry
- `GET /tools` - List all available tools

### Agent Tools (`/tools/agent`)
- `GET /list` - List agents with filtering (type, capability, limit, offset)
- `GET /get/:id` - Get specific agent
- `GET /capabilities` - List all unique capabilities
- `GET /types` - List agent types with counts
- `POST /find` - Find agents by capability match

### Memory Tools (`/tools/memory`)
- `POST /store` - Store a memory with PS-SHA∞ hash
- `GET /retrieve/:hash` - Get specific memory
- `GET /list` - List agent's memories
- `POST /search` - Search memories
- `DELETE /invalidate/:hash` - Mark memory as invalid (truth_state = -1)

### Reasoning Tools (`/tools/reasoning`)
- `POST /evaluate` - Evaluate a claim for contradictions
- `POST /commit` - Commit a claim to truth state
- `POST /quarantine` - Quarantine contradicting claims
- `POST /resolve` - Resolve a quarantined contradiction
- `GET /claims` - List committed claims

### Coordination Tools (`/tools/coordination`)
- `POST /publish` - Publish event to topic
- `GET /subscribe/:topic` - Get events from topic
- `GET /topics` - List active topics
- `POST /delegate` - Delegate task to agent
- `GET /tasks` - Get agent's task queue
- `POST /complete` - Complete a task

## Authentication

All requests should include `X-Agent-ID` header to identify the calling agent.

## Trinary Logic

Truth states: `1` (true), `0` (unknown), `-1` (false)

## Deployment

```bash
npm install
npx wrangler deploy
```

## Infrastructure

- **D1 Database**: blackroad-continuity (agent registry)
- **KV Namespace**: blackroad-tools-kv (memory, events, tasks)
