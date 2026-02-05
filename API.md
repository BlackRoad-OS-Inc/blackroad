# BlackRoad OS API Reference

> Complete API documentation for BlackRoad OS services

---

## 📋 Table of Contents

- [Authentication](#authentication)
- [Agent API](#agent-api)
- [Memory API](#memory-api)
- [Task API](#task-api)
- [Model API](#model-api)
- [Webhook API](#webhook-api)
- [Error Handling](#error-handling)
- [Rate Limits](#rate-limits)
- [SDKs](#sdks)

---

## Authentication

### API Key Authentication

```bash
curl -X GET "https://api.blackroad.io/v1/agents" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### JWT Authentication

```bash
# Get JWT token
curl -X POST "https://api.blackroad.io/v1/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"api_key": "YOUR_API_KEY"}'

# Use JWT token
curl -X GET "https://api.blackroad.io/v1/agents" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Response

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2026-02-06T00:00:00Z",
  "token_type": "Bearer"
}
```

---

## Agent API

### List Agents

```http
GET /v1/agents
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `status` | string | Filter by status (online, offline, busy) |
| `type` | string | Filter by agent type |
| `limit` | integer | Max results (default: 20, max: 100) |
| `offset` | integer | Pagination offset |

**Response:**

```json
{
  "agents": [
    {
      "id": "agent_lucidia_001",
      "name": "LUCIDIA",
      "type": "reasoning",
      "status": "online",
      "tasks_completed": 847,
      "avg_response_time": 2.3,
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "total": 6,
  "limit": 20,
  "offset": 0
}
```

### Get Agent

```http
GET /v1/agents/{agent_id}
```

**Response:**

```json
{
  "id": "agent_lucidia_001",
  "name": "LUCIDIA",
  "type": "reasoning",
  "status": "online",
  "config": {
    "model": "llama3.2",
    "temperature": 0.7,
    "max_tokens": 4096
  },
  "stats": {
    "tasks_completed": 847,
    "tasks_failed": 3,
    "avg_response_time": 2.3,
    "uptime_hours": 720
  },
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2026-02-05T12:00:00Z"
}
```

### Create Agent

```http
POST /v1/agents
```

**Request Body:**

```json
{
  "name": "CUSTOM_AGENT",
  "type": "worker",
  "config": {
    "model": "mistral",
    "temperature": 0.5,
    "system_prompt": "You are a helpful assistant."
  }
}
```

**Response:**

```json
{
  "id": "agent_custom_001",
  "name": "CUSTOM_AGENT",
  "status": "initializing",
  "created_at": "2026-02-05T12:00:00Z"
}
```

### Update Agent

```http
PATCH /v1/agents/{agent_id}
```

**Request Body:**

```json
{
  "config": {
    "temperature": 0.8
  },
  "status": "paused"
}
```

### Delete Agent

```http
DELETE /v1/agents/{agent_id}
```

### Agent Actions

```http
POST /v1/agents/{agent_id}/wake
POST /v1/agents/{agent_id}/pause
POST /v1/agents/{agent_id}/resume
POST /v1/agents/{agent_id}/restart
```

---

## Memory API

### Store Memory

```http
POST /v1/memory
```

**Request Body:**

```json
{
  "key": "user_preference_theme",
  "value": "dark",
  "type": "short_term",
  "agent_id": "agent_lucidia_001",
  "metadata": {
    "source": "user_settings",
    "priority": "high"
  },
  "ttl": 86400
}
```

**Response:**

```json
{
  "id": "mem_abc123",
  "key": "user_preference_theme",
  "created_at": "2026-02-05T12:00:00Z",
  "expires_at": "2026-02-06T12:00:00Z"
}
```

### Retrieve Memory

```http
GET /v1/memory/{key}
```

**Response:**

```json
{
  "id": "mem_abc123",
  "key": "user_preference_theme",
  "value": "dark",
  "type": "short_term",
  "agent_id": "agent_lucidia_001",
  "metadata": {
    "source": "user_settings",
    "priority": "high"
  },
  "created_at": "2026-02-05T12:00:00Z",
  "accessed_at": "2026-02-05T14:00:00Z"
}
```

### Search Memory

```http
POST /v1/memory/search
```

**Request Body:**

```json
{
  "query": "deployment procedures for production",
  "limit": 10,
  "threshold": 0.7,
  "filters": {
    "agent_id": "agent_octavia_001",
    "type": "long_term"
  }
}
```

**Response:**

```json
{
  "results": [
    {
      "id": "mem_xyz789",
      "key": "deployment_guide",
      "value": "To deploy to production...",
      "score": 0.92,
      "metadata": {}
    }
  ],
  "total": 5
}
```

### Delete Memory

```http
DELETE /v1/memory/{key}
```

### Consolidate Memory

```http
POST /v1/memory/consolidate
```

**Request Body:**

```json
{
  "agent_id": "agent_echo_001",
  "older_than_hours": 24
}
```

---

## Task API

### Create Task

```http
POST /v1/tasks
```

**Request Body:**

```json
{
  "title": "Analyze code repository",
  "description": "Review the blackroad-cli codebase for security issues",
  "agent_id": "agent_cipher_001",
  "priority": "high",
  "deadline": "2026-02-06T00:00:00Z",
  "metadata": {
    "repo": "blackroad-cli",
    "type": "security_review"
  }
}
```

**Response:**

```json
{
  "id": "task_abc123",
  "title": "Analyze code repository",
  "status": "queued",
  "agent_id": "agent_cipher_001",
  "created_at": "2026-02-05T12:00:00Z",
  "estimated_completion": "2026-02-05T14:00:00Z"
}
```

### Get Task

```http
GET /v1/tasks/{task_id}
```

**Response:**

```json
{
  "id": "task_abc123",
  "title": "Analyze code repository",
  "description": "Review the blackroad-cli codebase...",
  "status": "in_progress",
  "agent_id": "agent_cipher_001",
  "progress": 45,
  "result": null,
  "created_at": "2026-02-05T12:00:00Z",
  "started_at": "2026-02-05T12:05:00Z",
  "completed_at": null
}
```

### List Tasks

```http
GET /v1/tasks
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `status` | string | queued, in_progress, completed, failed |
| `agent_id` | string | Filter by agent |
| `priority` | string | low, normal, high, critical |

### Cancel Task

```http
POST /v1/tasks/{task_id}/cancel
```

### Retry Task

```http
POST /v1/tasks/{task_id}/retry
```

---

## Model API

### List Models

```http
GET /v1/models
```

**Response:**

```json
{
  "models": [
    {
      "id": "llama3.2",
      "name": "Llama 3.2 8B",
      "provider": "ollama",
      "status": "loaded",
      "parameters": "8B",
      "context_length": 128000
    },
    {
      "id": "mistral",
      "name": "Mistral 7B",
      "provider": "ollama",
      "status": "loaded",
      "parameters": "7B",
      "context_length": 32000
    }
  ]
}
```

### Chat Completion

```http
POST /v1/chat/completions
```

**Request Body:**

```json
{
  "model": "llama3.2",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
  ],
  "temperature": 0.7,
  "max_tokens": 1024,
  "stream": false
}
```

**Response:**

```json
{
  "id": "chat_abc123",
  "object": "chat.completion",
  "created": 1707134400,
  "model": "llama3.2",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! How can I help you today?"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 10,
    "total_tokens": 35
  }
}
```

### Embeddings

```http
POST /v1/embeddings
```

**Request Body:**

```json
{
  "model": "nomic-embed-text",
  "input": "The quick brown fox jumps over the lazy dog."
}
```

**Response:**

```json
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "index": 0,
      "embedding": [0.0123, -0.0456, ...]
    }
  ],
  "model": "nomic-embed-text",
  "usage": {
    "prompt_tokens": 10,
    "total_tokens": 10
  }
}
```

---

## Webhook API

### Create Webhook

```http
POST /v1/webhooks
```

**Request Body:**

```json
{
  "url": "https://your-server.com/webhook",
  "events": ["task.completed", "agent.status_changed"],
  "secret": "your_webhook_secret"
}
```

### Webhook Events

| Event | Description |
|-------|-------------|
| `task.created` | New task created |
| `task.started` | Task execution started |
| `task.completed` | Task completed successfully |
| `task.failed` | Task failed |
| `agent.status_changed` | Agent status changed |
| `memory.consolidated` | Memory consolidation completed |

### Webhook Payload

```json
{
  "id": "evt_abc123",
  "type": "task.completed",
  "created_at": "2026-02-05T12:00:00Z",
  "data": {
    "task_id": "task_xyz789",
    "agent_id": "agent_alice_001",
    "result": "Task completed successfully"
  }
}
```

---

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "invalid_request",
    "message": "The request body is invalid",
    "details": {
      "field": "agent_id",
      "reason": "Agent not found"
    }
  },
  "request_id": "req_abc123"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `invalid_request` | 400 | Malformed request |
| `unauthorized` | 401 | Invalid credentials |
| `forbidden` | 403 | Insufficient permissions |
| `not_found` | 404 | Resource not found |
| `rate_limited` | 429 | Too many requests |
| `internal_error` | 500 | Server error |

---

## Rate Limits

### Limits by Tier

| Tier | Requests/min | Requests/day |
|------|--------------|--------------|
| Free | 60 | 1,000 |
| Pro | 600 | 50,000 |
| Enterprise | 6,000 | Unlimited |

### Rate Limit Headers

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1707134460
```

---

## SDKs

### Python

```python
from blackroad import BlackRoadClient

client = BlackRoadClient(api_key="YOUR_API_KEY")

# List agents
agents = client.agents.list()

# Create task
task = client.tasks.create(
    title="Analyze code",
    agent_id="agent_cipher_001"
)

# Chat completion
response = client.chat.completions.create(
    model="llama3.2",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

### TypeScript

```typescript
import { BlackRoadClient } from '@blackroad/sdk';

const client = new BlackRoadClient({ apiKey: 'YOUR_API_KEY' });

// List agents
const agents = await client.agents.list();

// Create task
const task = await client.tasks.create({
  title: 'Analyze code',
  agentId: 'agent_cipher_001'
});

// Chat completion
const response = await client.chat.completions.create({
  model: 'llama3.2',
  messages: [{ role: 'user', content: 'Hello!' }]
});
```

### cURL Examples

```bash
# List agents
curl -X GET "https://api.blackroad.io/v1/agents" \
  -H "Authorization: Bearer YOUR_API_KEY"

# Create task
curl -X POST "https://api.blackroad.io/v1/tasks" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test task","agent_id":"agent_alice_001"}'
```

---

## Base URLs

| Environment | URL |
|-------------|-----|
| Production | https://api.blackroad.io |
| Staging | https://staging-api.blackroad.io |
| Local | http://localhost:8000 |

---

*Last updated: 2026-02-05*
