# BlackRoad AI — Org Index

> 7 AI/ML repositories in the `BlackRoad-AI` organization

| Repo | Stack | Description |
|------|-------|-------------|
| `blackroad-vllm` | Python, PyTorch, CUDA | High-throughput LLM inference (vLLM fork) |
| `blackroad-ai-ollama` | Docker, Ollama | Multi-model runtime with [MEMORY] integration |
| `blackroad-ai-qwen` | Docker, vLLM | Qwen model deployment |
| `blackroad-ai-deepseek` | Docker, vLLM | DeepSeek reasoning models |
| `blackroad-ai-api-gateway` | Docker | Unified AI API gateway (OpenAI-compatible) |
| `blackroad-ai-cluster` | Railway A100/H100 | Distributed GPU inference cluster |
| `blackroad-ai-memory-bridge` | Vector DB, Redis | Cross-model persistent memory |

## Quick Start

```bash
# Start Ollama with memory
cd blackroad-ai-ollama
docker-compose up -d

# Start AI gateway
cd blackroad-ai-api-gateway
docker-compose up -d

# Inference endpoint
curl http://localhost:8001/chat -d '{"model": "qwen2.5:7b", "message": "hello"}'
```

## Models Available

| Model | Size | Use Case |
|-------|------|---------|
| qwen2.5:7b | 7B | General purpose, fast |
| deepseek-r1:7b | 7B | Reasoning, code |
| llama3.2:3b | 3B | Lightweight |
| mistral:7b | 7B | Balanced |

---

*Total: 7 repos | Last updated: 2026-02-24*
