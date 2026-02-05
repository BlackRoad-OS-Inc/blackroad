# BlackRoad AI Qwen

> Qwen model deployment and fine-tuning infrastructure

## Quick Reference

| Property | Value |
|----------|-------|
| **Model** | Qwen/Qwen2.5 |
| **Runtime** | Docker/vLLM |
| **Type** | LLM |
| **License** | Apache-2.0 |

## Model Variants

| Model | Parameters | VRAM |
|-------|------------|------|
| Qwen2.5-0.5B | 0.5B | 2GB |
| Qwen2.5-1.5B | 1.5B | 4GB |
| Qwen2.5-7B | 7B | 16GB |
| Qwen2.5-14B | 14B | 32GB |
| Qwen2.5-72B | 72B | 144GB |

## Deployment

```bash
# Via Ollama
ollama pull qwen2.5

# Via vLLM
vllm serve Qwen/Qwen2.5-7B-Instruct

# Via Docker
docker compose up -d
```

## API Usage

```python
import requests

response = requests.post("http://localhost:8000/v1/chat/completions",
    json={
        "model": "qwen2.5-7b",
        "messages": [{"role": "user", "content": "Hello!"}]
    }
)
```

## Features

- **Multilingual**: Strong Chinese/English support
- **Code**: Excellent code generation
- **Math**: Advanced mathematical reasoning
- **Long Context**: Up to 128K tokens

## Environment Variables

```env
MODEL_NAME=Qwen/Qwen2.5-7B-Instruct
TENSOR_PARALLEL_SIZE=1
MAX_MODEL_LEN=32768
```

## Railway Deployment

Uses Railway GPU for A100/H100 inference.

## Related Repos

- `blackroad-vllm` - Inference engine
- `blackroad-ai-ollama` - Ollama backend
- `blackroad-ai-deepseek` - DeepSeek model
