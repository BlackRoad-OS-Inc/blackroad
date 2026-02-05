# BlackBox n8n - Planning

> Development planning for workflow automation fork

## Purpose

Maintain a sovereign fork of n8n for:
- Custom BlackRoad integrations
- Agent workflow triggers
- Internal automation needs
- Extended node types

---

## Upstream Sync

### Current Version
- **Upstream**: n8n 1.70.x
- **Fork**: blackbox-n8n 1.70.0-br.1
- **Last sync**: 2026-01-15

### Sync Schedule
- **Weekly**: Security patches
- **Monthly**: Feature releases
- **Quarterly**: Major versions

---

## Custom Integrations

### BlackRoad Nodes (Custom)

| Node | Purpose | Status |
|------|---------|--------|
| BlackRoad Agent | Trigger agent tasks | ✅ Done |
| BlackRoad Memory | Read/write memory | ✅ Done |
| BlackRoad API | API gateway calls | 🔄 In Progress |
| BlackRoad Event | Event pub/sub | 📋 Planned |

### Planned Nodes

| Node | Purpose | Priority | ETA |
|------|---------|----------|-----|
| Ollama | Local LLM inference | P0 | Q1 |
| Pinecone | Vector search | P1 | Q1 |
| Railway | Deploy trigger | P2 | Q2 |
| Cloudflare | Worker management | P2 | Q2 |

---

## Current Sprint

### Sprint 2026-02

#### Goals
- [ ] Sync with upstream 1.71.x
- [ ] Complete BlackRoad API node
- [ ] Add Ollama node
- [ ] Fix memory leak in agent node

#### Tasks

| Task | Priority | Status | Est. |
|------|----------|--------|------|
| Upstream merge | P0 | 🔄 In Progress | 2d |
| API node completion | P0 | 📋 Planned | 3d |
| Ollama node | P1 | 📋 Planned | 4d |
| Memory leak fix | P0 | 📋 Planned | 1d |

---

## Architecture

### Node Development

```
packages/nodes-blackroad/
├── nodes/
│   ├── BlackRoadAgent/
│   │   ├── BlackRoadAgent.node.ts
│   │   ├── BlackRoadAgent.node.json
│   │   └── blackroad.svg
│   ├── BlackRoadMemory/
│   ├── BlackRoadApi/
│   └── BlackRoadEvent/
├── credentials/
│   └── BlackRoadApi.credentials.ts
└── package.json
```

### Node Template

```typescript
import { IExecuteFunctions } from 'n8n-core';
import { INodeType, INodeTypeDescription } from 'n8n-workflow';

export class BlackRoadAgent implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'BlackRoad Agent',
    name: 'blackRoadAgent',
    icon: 'file:blackroad.svg',
    group: ['transform'],
    version: 1,
    description: 'Interact with BlackRoad agents',
    inputs: ['main'],
    outputs: ['main'],
    properties: [
      {
        displayName: 'Agent',
        name: 'agent',
        type: 'options',
        options: [
          { name: 'LUCIDIA', value: 'lucidia' },
          { name: 'ALICE', value: 'alice' },
          { name: 'OCTAVIA', value: 'octavia' },
        ],
        default: 'alice',
      },
      {
        displayName: 'Task',
        name: 'task',
        type: 'string',
        default: '',
      },
    ],
  };

  async execute(this: IExecuteFunctions) {
    // Implementation
  }
}
```

---

## Deployment

### Current Setup
- Docker Compose (local)
- PostgreSQL database
- Redis queue

### Production Target
- Railway deployment
- Managed PostgreSQL
- Redis cluster
- Auto-scaling workers

### Docker Compose

```yaml
services:
  n8n:
    image: blackroad/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - QUEUE_BULL_REDIS_HOST=redis
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    volumes:
      - redis_data:/data
```

---

## Testing

### Test Categories

| Category | Coverage | Target |
|----------|----------|--------|
| Unit tests | 45% | 80% |
| Integration | 20% | 60% |
| E2E | 10% | 40% |

### Custom Node Tests

```typescript
describe('BlackRoadAgent', () => {
  it('should trigger agent task', async () => {
    const node = new BlackRoadAgent();
    const result = await node.execute.call(mockExecute, {
      agent: 'alice',
      task: 'test task',
    });
    expect(result.success).toBe(true);
  });
});
```

---

## Upstream Contributions

### Contributed
- Bug fix: Memory leak in webhook node (#12345)
- Feature: Improved error messages (#12456)

### Planned Contributions
- Performance: Batch execution optimization
- Feature: Better TypeScript support
- Docs: Node development guide

---

*Last updated: 2026-02-05*
