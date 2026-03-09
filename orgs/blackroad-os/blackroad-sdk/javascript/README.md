# @blackroad/sdk

Official JavaScript/TypeScript SDK for the BlackRoad API.

## Installation

```bash
npm install @blackroad/sdk
# or
yarn add @blackroad/sdk
# or
pnpm add @blackroad/sdk
```

## Quick Start

```typescript
import { BlackRoadClient } from '@blackroad/sdk';

// Initialize the client
const client = new BlackRoadClient({
  apiKey: 'your-api-key', // or set BLACKROAD_API_KEY env var
});

// List agents
const agents = await client.agents.list();
console.log(`Found ${agents.length} agents`);

// Dispatch a task
const task = await client.tasks.dispatch({
  title: 'Deploy authentication service',
  priority: 'high',
  division: 'Security',
});
console.log(`Created task: ${task.id}`);

// Log to memory
const entry = await client.memory.log({
  action: 'deployed',
  entity: 'auth-service',
  details: 'Deployed v2.0.0 to production',
  tags: ['deployment', 'security'],
});
```

## Configuration

```typescript
const client = new BlackRoadClient({
  apiKey: 'your-api-key',        // Required (or BLACKROAD_API_KEY env var)
  baseUrl: 'https://api.blackroad.io/v1', // Optional, custom API endpoint
  timeout: 30000,                 // Optional, request timeout in ms
  maxRetries: 3,                  // Optional, max retry attempts
});
```

## API Reference

### Agents

```typescript
// List all agents
const agents = await client.agents.list();

// List with filters
const aiAgents = await client.agents.list({ type: 'ai', division: 'AI' });

// Get specific agent
const agent = await client.agents.get('agent-id');

// Register a new agent
const newAgent = await client.agents.register({
  name: 'my-agent',
  type: 'ai',
  division: 'Labs',
  level: 4,
  metadata: { capabilities: ['analysis', 'coding'] },
});

// Send heartbeat
await client.agents.heartbeat('agent-id', 0.75); // 75% load

// Update status
await client.agents.updateStatus('agent-id', 'busy');

// Delete agent
await client.agents.delete('agent-id');

// Get statistics
const stats = await client.agents.stats();

// Convenience methods
const commanders = await client.agents.commanders(); // Level 2
const managers = await client.agents.managers();     // Level 3
const workers = await client.agents.workers();       // Level 4
const securityAgents = await client.agents.byDivision('Security');
```

### Tasks

```typescript
// Dispatch a task
const task = await client.tasks.dispatch({
  title: 'Build authentication system',
  description: 'Implement OAuth2 + JWT authentication',
  priority: 'high',       // 'low' | 'medium' | 'high' | 'urgent'
  division: 'Security',
  target_level: 4,
  metadata: { estimated_hours: 8 },
});

// Get task by ID
const task = await client.tasks.get('task-id');

// List tasks with filters
const tasks = await client.tasks.list({
  status: 'pending',
  priority: 'high',
  division: 'AI',
  limit: 50,
});

// Complete a task
await client.tasks.complete('task-id', 'Successfully deployed to production');

// Fail a task
await client.tasks.fail('task-id', 'Dependency service unavailable');

// Assign to agent
await client.tasks.assign('task-id', 'agent-id');

// Cancel task
await client.tasks.cancel('task-id');

// Get statistics
const stats = await client.tasks.stats();

// Convenience methods
const pendingTasks = await client.tasks.pending();
const inProgressTasks = await client.tasks.inProgress();
const urgentTasks = await client.tasks.urgent();
const aiTasks = await client.tasks.byDivision('AI');
```

### Memory

```typescript
// Log an entry
const entry = await client.memory.log({
  action: 'deployed',
  entity: 'user-service',
  details: 'Deployed v2.1.0 with new auth flow',
  tags: ['deployment', 'auth'],
  metadata: { version: '2.1.0', environment: 'production' },
});

// Query entries
const entries = await client.memory.query({
  search: 'deployment',
  action: 'deployed',
  tags: ['production'],
  since: new Date('2024-01-01'),
  limit: 100,
});

// Get entry by hash
const entry = await client.memory.get('entry-hash');

// Get recent entries
const recent = await client.memory.recent(50);

// Agent state management
const state = await client.memory.agentState('agent-id');
await client.memory.syncState('agent-id', { lastTask: 'task-123', load: 0.5 });

// Broadcast a message
const { broadcast_id } = await client.memory.broadcast('alert', 'System maintenance at 3 PM');

// Share a TIL (Today I Learned)
await client.memory.til('security', 'Always validate JWT signatures server-side');

// Get statistics
const stats = await client.memory.stats();

// Verify hash chain integrity
const { valid, checked } = await client.memory.verifyChain();
```

### Health & Version

```typescript
// Check API health
const health = await client.health();
console.log(health.status); // 'healthy'

// Get API version
const version = await client.version();
console.log(version); // '1.0.0'
```

## Error Handling

```typescript
import {
  BlackRoadError,
  AuthenticationError,
  NotFoundError,
  RateLimitError,
  ValidationError,
  ConnectionError,
} from '@blackroad/sdk';

try {
  const agent = await client.agents.get('nonexistent');
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log('Agent not found');
  } else if (error instanceof AuthenticationError) {
    console.log('Invalid API key');
  } else if (error instanceof RateLimitError) {
    console.log(`Rate limited. Retry after ${error.retryAfter} seconds`);
  } else if (error instanceof ValidationError) {
    console.log('Invalid request data');
  } else if (error instanceof ConnectionError) {
    console.log('Network error');
  } else if (error instanceof BlackRoadError) {
    console.log(`API error: ${error.message}`);
  }
}
```

## TypeScript Types

All types are exported for TypeScript users:

```typescript
import type {
  Agent,
  Task,
  MemoryEntry,
  ClientConfig,
  RegisterAgentOptions,
  DispatchTaskOptions,
  LogMemoryOptions,
  HealthStatus,
  Stats,
} from '@blackroad/sdk';
```

## Requirements

- Node.js 18.0.0 or higher
- Native `fetch` support (Node.js 18+)

## License

See [LICENSE](./LICENSE) for details.

## Links

- [Documentation](https://docs.blackroad.io/sdk/javascript)
- [API Reference](https://docs.blackroad.io/api)
- [GitHub](https://github.com/BlackRoad-OS/blackroad-sdk-js)
- [Issues](https://github.com/BlackRoad-OS/blackroad-sdk-js/issues)
