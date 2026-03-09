# BlackRoad vLLM Deployment

**High-throughput LLM inference with OpenAI-compatible API**

## Quick Start

```bash
# Docker (single GPU)
docker run --gpus all -p 8000:8000 \
  vllm/vllm-openai:latest \
  --model mistralai/Mistral-7B-Instruct-v0.2

# Docker Compose (production)
docker compose up -d
```

## Supported Models

| Model | VRAM Required | Max Tokens | Use Case |
|-------|---------------|------------|----------|
| Mistral-7B | 16GB | 32K | General purpose |
| Llama-3-70B | 140GB | 8K | Complex reasoning |
| CodeLlama-34B | 68GB | 16K | Code generation |
| Mixtral-8x7B | 96GB | 32K | Multi-task |

## Configuration

### Environment Variables
```bash
MODEL_NAME=mistralai/Mistral-7B-Instruct-v0.2
TENSOR_PARALLEL_SIZE=1
MAX_MODEL_LEN=32768
GPU_MEMORY_UTILIZATION=0.9
QUANTIZATION=awq  # or gptq, squeezellm, None
```

### OpenAI-Compatible API
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="blackroad"
)

response = client.chat.completions.create(
    model="mistralai/Mistral-7B-Instruct-v0.2",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

## Kubernetes Deployment

```bash
kubectl apply -f k8s/
```

## Monitoring

- Prometheus metrics: `:8000/metrics`
- Health check: `:8000/health`
- Model info: `:8000/v1/models`

---

*BlackRoad OS - Sovereign AI Inference*
