# BlackRoad Claude Integration

**Anthropic Claude API integration for BlackRoad infrastructure**

## Quick Start

```bash
# Set API key
export ANTHROPIC_API_KEY=sk-ant-...

# Test connection
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-20250514","max_tokens":100,"messages":[{"role":"user","content":"Hello"}]}'
```

## Cloudflare Worker

Deploy Claude proxy to Cloudflare:

```bash
cd worker
wrangler deploy
```

### Usage
```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
  baseURL: 'https://claude.blackroad.io/v1',
  apiKey: process.env.ANTHROPIC_API_KEY
});

const message = await client.messages.create({
  model: 'claude-sonnet-4-20250514',
  max_tokens: 1024,
  messages: [{ role: 'user', content: 'Hello, BlackRoad!' }]
});
```

## Rate Limiting

| Tier | RPM | TPM |
|------|-----|-----|
| Free | 60 | 100K |
| Pro | 1000 | 1M |
| Enterprise | Custom | Custom |

## Streaming

```typescript
const stream = await client.messages.stream({
  model: 'claude-sonnet-4-20250514',
  max_tokens: 1024,
  messages: [{ role: 'user', content: prompt }]
});

for await (const event of stream) {
  if (event.type === 'content_block_delta') {
    process.stdout.write(event.delta.text);
  }
}
```

## Error Handling

```typescript
try {
  const response = await client.messages.create({ ... });
} catch (error) {
  if (error instanceof Anthropic.APIError) {
    console.log(`Status: ${error.status}`);
    console.log(`Message: ${error.message}`);
  }
}
```

## Environment Variables

```bash
ANTHROPIC_API_KEY=sk-ant-...        # Required
CLAUDE_MODEL=claude-sonnet-4-20250514    # Default model
MAX_TOKENS=4096                      # Default max tokens
RATE_LIMIT_RPM=1000                  # Requests per minute
```

---

*BlackRoad OS - Claude Integration Layer*
