# BlackRoad Job Queue

**Background task processing with BullMQ**

## Features

- **Delayed Jobs**: Schedule tasks for future execution
- **Retries**: Automatic retry with backoff
- **Priorities**: Process critical tasks first
- **Concurrency**: Parallel worker execution
- **Progress**: Real-time job progress tracking

## Quick Start

```typescript
import { Queue, Worker } from '@blackroad-os/job-queue';

// Create queue
const queue = new Queue('agent-tasks');

// Add job
await queue.add('process-inference', {
  model: 'mistral-7b',
  prompt: 'Hello, world!'
}, {
  priority: 1,
  attempts: 3,
  backoff: { type: 'exponential', delay: 1000 }
});

// Process jobs
const worker = new Worker('agent-tasks', async (job) => {
  const result = await runInference(job.data);
  return result;
});
```

## Job Types

| Type | Description | Timeout | Retries |
|------|-------------|---------|---------|
| `inference` | AI model inference | 5m | 3 |
| `deploy` | Deployment tasks | 10m | 2 |
| `sync` | Data synchronization | 2m | 5 |
| `notify` | Send notifications | 30s | 3 |

## Dashboard

```bash
# Start Bull Board dashboard
npm run dashboard

# Access at http://localhost:3000/admin/queues
```

## Redis Configuration

```yaml
# docker-compose.yml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
```

## Cloudflare Queues

```typescript
// For serverless deployment
export default {
  async queue(batch: MessageBatch, env: Env) {
    for (const message of batch.messages) {
      await processJob(message.body);
      message.ack();
    }
  }
};
```

---

*BlackRoad OS - Background Processing at Scale*
