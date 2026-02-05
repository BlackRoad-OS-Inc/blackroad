# BlackRoad AI API Gateway

> Unified API gateway for all BlackRoad AI services

## Quick Reference

| Property | Value |
|----------|-------|
| **Runtime** | Docker |
| **Type** | API Gateway |
| **Purpose** | LLM Routing |

## Features

- **Model Routing**: Route to Ollama, vLLM, or external APIs
- **Load Balancing**: Distribute across GPU nodes
- **Rate Limiting**: Request throttling
- **Authentication**: API key validation

## Deployment

```bash
# Build and run
docker build -t blackroad-api-gateway .
docker compose up -d
```

## Docker Compose

```yaml
services:
  gateway:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OLLAMA_URL=http://ollama:11434
      - VLLM_URL=http://vllm:8000
```

## API Endpoints

```
POST /v1/chat/completions    # OpenAI-compatible
POST /v1/completions         # Text completion
POST /v1/embeddings          # Embeddings
GET  /health                 # Health check
GET  /models                 # Available models
```

## Routing Rules

| Model Pattern | Backend |
|---------------|---------|
| `gpt-*` | OpenAI API |
| `claude-*` | Anthropic API |
| `llama*` | Ollama/vLLM |
| `mistral*` | Ollama/vLLM |
| `deepseek*` | Ollama/vLLM |

## Environment Variables

```env
GATEWAY_PORT=8000
OLLAMA_URL=http://localhost:11434
VLLM_URL=http://localhost:8001
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

## Related Repos

- `blackroad-ai-ollama` - Ollama backend
- `blackroad-vllm` - vLLM backend
- `blackroad-agents` - Agent consumers
