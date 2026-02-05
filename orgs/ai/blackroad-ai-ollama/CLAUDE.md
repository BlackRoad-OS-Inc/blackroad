# BlackRoad AI Ollama

> Docker-based Ollama deployment for BlackRoad infrastructure

## Quick Reference

| Property | Value |
|----------|-------|
| **Runtime** | Docker |
| **Base** | Ollama Official |
| **Type** | LLM Server |
| **Port** | 11434 |

## Deployment

```bash
# Build container
docker build -t blackroad-ollama .

# Run with GPU
docker compose up -d

# Or without Docker
ollama serve
```

## Docker Compose

```yaml
services:
  ollama:
    image: blackroad-ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

## Models

Common models to pull:
```bash
ollama pull llama3.2
ollama pull mistral
ollama pull codellama
ollama pull deepseek-coder
```

## API Endpoints

```
GET  /api/tags           # List models
POST /api/generate       # Generate text
POST /api/chat           # Chat completion
POST /api/embeddings     # Text embeddings
GET  /api/ps             # Running models
```

## Environment Variables

```env
OLLAMA_HOST=0.0.0.0:11434
OLLAMA_MODELS=/root/.ollama/models
OLLAMA_DEBUG=false
OLLAMA_NUM_PARALLEL=4
```

## BlackRoad Integration

Used by:
- Agent wake scripts (`wake.sh`)
- Interactive CLI tools
- Lucidia reasoning engines
- Memory system embeddings

## Health Check

```bash
curl http://localhost:11434/api/tags
```

## Related Repos

- `blackroad-vllm` - High-throughput inference
- `blackroad-ai-qwen` - Qwen model
- `lucidia-core` - Reasoning engines
