# BlackRoad Event Bus

**Pub/sub messaging for distributed systems**

## Features

- **Topics**: Create and manage event topics
- **Subscriptions**: Push and pull delivery
- **Ordering**: FIFO guarantees per partition
- **Durability**: At-least-once delivery
- **Dead Letter**: Failed message handling

## Quick Start

```typescript
import { EventBus } from '@blackroad-os/event-bus';

const bus = new EventBus({ url: 'https://events.blackroad.io' });

// Publish event
await bus.publish('agent.task.completed', {
  agentId: 'cecilia',
  taskId: 'task-123',
  result: 'success'
});

// Subscribe to events
bus.subscribe('agent.task.*', async (event) => {
  console.log('Task event:', event);
});
```

## Topics

| Topic | Description | Retention |
|-------|-------------|-----------|
| `agent.*` | Agent lifecycle events | 7 days |
| `task.*` | Task execution events | 30 days |
| `deploy.*` | Deployment events | 90 days |
| `alert.*` | System alerts | 7 days |

## Event Schema

```typescript
interface Event<T = unknown> {
  id: string;           // UUID
  type: string;         // Event type
  source: string;       // Producer ID
  time: string;         // ISO timestamp
  data: T;              // Payload
  metadata?: Record<string, string>;
}
```

## Cloudflare Queues Integration

```toml
# wrangler.toml
[[queues.producers]]
queue = "blackroad-events"
binding = "EVENTS"

[[queues.consumers]]
queue = "blackroad-events"
max_batch_size = 10
max_batch_timeout = 30
```

## Patterns

### Fan-out
```typescript
await bus.publish('order.created', order, {
  fanout: ['inventory', 'billing', 'notification']
});
```

### Request-Reply
```typescript
const response = await bus.request('agent.query', {
  query: 'status',
  timeout: 5000
});
```

---

*BlackRoad OS - Event-Driven Architecture*
