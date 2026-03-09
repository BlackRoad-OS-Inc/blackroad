# @blackroad/skills-sdk

Official SDK for BlackRoad OS Tools - enabling AI agents with memory, reasoning, and coordination capabilities.

## Installation

```bash
npm install @blackroad/skills-sdk
```

## Quick Start

```typescript
import { createSDK } from '@blackroad/skills-sdk';

const sdk = createSDK({
  agentId: 'agent-0001'
});

// Store a memory
const hash = await sdk.memory.remember('The user prefers dark mode');

// Evaluate a claim for contradictions
const evaluation = await sdk.reasoning.evaluate('The sky is blue');

// Delegate a task to another agent
const taskId = await sdk.coordination.delegate({
  taskType: 'analysis',
  description: 'Analyze quarterly sales data',
  requiredCapabilities: ['analytics', 'data_processing']
});
```

## Features

### Memory (PS-SHA∞ Persistence)
- `memory.remember(content)` - Store a fact
- `memory.observe(content)` - Store an observation
- `memory.infer(content)` - Store an inference
- `memory.commit(content)` - Store a commitment
- `memory.search(query)` - Search memories
- `memory.invalidate(hash)` - Mark memory as invalid

### Reasoning (Trinary Logic)
- `reasoning.evaluate(claim)` - Check for contradictions
- `reasoning.assertTrue(claim)` - Assert claim as true (1)
- `reasoning.assertFalse(claim)` - Assert claim as false (-1)
- `reasoning.assertUnknown(claim)` - Mark claim as unknown (0)
- `reasoning.quarantine(claimIds)` - Quarantine contradicting claims
- `reasoning.resolve(quarantineId)` - Resolve a quarantine

### Coordination (Event Bus)
- `coordination.publish(topic, type, payload)` - Publish event
- `coordination.subscribe(topic)` - Get events from topic
- `coordination.delegate(task)` - Delegate task to agent
- `coordination.complete(taskId, status)` - Complete a task
- `coordination.broadcast(message)` - Broadcast to all agents

### Agent Registry
- `agents.list(options)` - List agents with filtering
- `agents.get(agentId)` - Get specific agent
- `agents.findByCapabilities(caps)` - Find capable agents
- `agents.getCapabilities()` - List all capabilities

## High-Level Methods

```typescript
// Think through something (auto-handles contradictions)
await sdk.think('The user might prefer light mode after all');

// Learn a fact with confidence
await sdk.learn('User timezone is CST', 0.95);

// Ask another agent for help
await sdk.ask('How do I format dates in French?', ['localization']);

// Collaborate with multiple agent types
await sdk.collaborate('Build a report', ['analyst', 'writer', 'reviewer']);
```

## Trinary Logic

BlackRoad uses trinary logic for truth states:
- `1` = True (verified fact)
- `0` = Unknown (uncertain, needs verification)
- `-1` = False (verified false)

This enables sophisticated contradiction handling and epistemic reasoning.

## License

MIT - BlackRoad OS
