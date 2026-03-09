# BlackRoad Tools API

Core API for BlackRoad's AI agent ecosystem. Provides agent management, persistent memory (PS-SHA∞), trinary reasoning, and multi-agent coordination.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     BlackRoad Tools API                         │
├────────────────┬────────────────┬───────────────┬───────────────┤
│     Agent      │    Memory      │   Reasoning   │ Coordination  │
│   Management   │   (PS-SHA∞)    │   (Trinary)   │  (Event Bus)  │
├────────────────┴────────────────┴───────────────┴───────────────┤
│                    Cloudflare Workers Runtime                    │
├─────────────────────────────────┬───────────────────────────────┤
│            D1 Database          │         KV Storage            │
│         (980 agents)            │    (memory, events, state)    │
└─────────────────────────────────┴───────────────────────────────┘
```

## Quick Start

### Installation

```bash
npm install @blackroad/skills-sdk
```

### Basic Usage

```typescript
import { BlackRoadSDK } from '@blackroad/skills-sdk';

const sdk = new BlackRoadSDK({
  baseUrl: 'https://blackroad-tools.amundsonalexa.workers.dev'
});

// High-level operations
const thought = await sdk.think('What patterns exist in this data?');
const memory = await sdk.learn({ insight: 'Key finding from analysis' });
const answer = await sdk.ask('agent-0001', 'What do you recommend?');
const result = await sdk.collaborate(['agent-0010', 'agent-0020'], 'Solve this problem');
```

## API Modules

### Agent Management

Manage the lifecycle of 980+ AI agents.

```typescript
// List agents
GET /tools/agent/list?type=analyst&limit=20

// Get agent details
GET /tools/agent/agent-0001

// Spawn new agent
POST /tools/agent/spawn
{ "name": "Nova", "type": "visionary", "capabilities": ["futures_thinking"] }

// Invoke agent capability
POST /tools/agent/agent-0001/invoke
{ "capability": "pattern_recognition", "input": { "data": [...] } }
```

**Agent Types**: analyst, architect, biologist, builder, chemist, coordinator, creative, economist, engineer, guardian, historian, linguist, mathematician, mediator, navigator, philosopher, physicist, psychologist, researcher, speaker, strategist, synthesizer, teacher, theorist, visionary

### Memory System (PS-SHA∞)

Append-only memory with cryptographic hash chains for integrity verification.

```typescript
// Store memory
POST /tools/memory/store
{
  "agent_id": "agent-0001",
  "content": { "thought": "Important insight" },
  "tags": ["insight", "verified"]
}

// Recall memories
POST /tools/memory/recall
{
  "agent_id": "agent-0001",
  "query": "insights about patterns",
  "limit": 10
}

// Verify memory chain integrity
POST /tools/memory/verify
{ "hash": "abc123def4567890" }
```

### Reasoning Engine (Trinary Logic)

Three-valued logic: TRUE (1), FALSE (-1), UNKNOWN (0).

```typescript
// Evaluate proposition
POST /tools/reasoning/evaluate
{
  "proposition": "The data supports hypothesis X",
  "evidence": [{ "type": "statistical", "p_value": 0.03 }]
}
// Returns: { "value": 1, "confidence": 0.95, "reasoning": "..." }

// Resolve contradictions
POST /tools/reasoning/resolve
{
  "claims": [
    { "statement": "X is optimal", "source": "agent-001", "confidence": 0.9 },
    { "statement": "Y is optimal", "source": "agent-002", "confidence": 0.7 }
  ],
  "strategy": "quarantine"  // or: branch, merge, escalate
}

// Inference chain
POST /tools/reasoning/infer
{
  "premises": ["All agents have capabilities", "Aurora is an agent"],
  "goal": "Aurora has capabilities"
}
```

### Coordination (Event Bus)

Pub/sub messaging and multi-agent orchestration.

```typescript
// Publish event
POST /tools/coordination/publish
{
  "event_type": "task.completed",
  "payload": { "task_id": "123", "result": "success" },
  "source_agent": "agent-0001"
}

// Subscribe to events
POST /tools/coordination/subscribe
{
  "agent_id": "agent-0002",
  "event_types": ["task.created", "task.completed"]
}

// Orchestrate multi-agent task
POST /tools/coordination/orchestrate
{
  "task": { "description": "Analyze dataset", "goal": "Extract insights" },
  "agents": ["agent-0010", "agent-0020", "agent-0030"],
  "strategy": "parallel"  // or: sequential, hierarchical, consensus
}
```

## CLI Tool

```bash
# Agent commands
br-tools agent:list analyst 20
br-tools agent:get agent-0001
br-tools agent:spawn "Nova" visionary

# Memory commands
br-tools memory:store agent-0001 "Important insight" insight verified
br-tools memory:recall agent-0001 "patterns"

# Reasoning commands
br-tools reason:evaluate "The hypothesis is supported"

# Coordination commands
br-tools coord:orchestrate "Analyze data" agent-0010 agent-0020

# Utility
br-tools health
```

## Local Development

```bash
# Install dependencies
npm install

# Start local dev server
npm run dev

# Or use Docker
docker-compose up

# Run tests
npm test
```

## Deployment

Automatic deployment via GitHub Actions when you push to main. Requires these repository secrets:
- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN`

## Database

980 agents across 25 types. Schema:

```sql
CREATE TABLE agents (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  capabilities TEXT,
  birthday TEXT,
  family TEXT,
  memory_hash TEXT,
  home_world TEXT DEFAULT 'lucidia',
  status TEXT DEFAULT 'active'
);
```

## License

MIT © BlackRoad OS, Inc.
