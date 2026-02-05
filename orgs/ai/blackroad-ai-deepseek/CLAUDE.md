# BlackRoad AI DeepSeek

> DeepSeek model deployment for code generation and reasoning

## Quick Reference

| Property | Value |
|----------|-------|
| **Model** | DeepSeek-Coder/V3 |
| **Runtime** | Docker/vLLM |
| **Type** | LLM |
| **Specialty** | Code |

## Model Variants

| Model | Parameters | VRAM |
|-------|------------|------|
| DeepSeek-Coder-1.3B | 1.3B | 4GB |
| DeepSeek-Coder-6.7B | 6.7B | 16GB |
| DeepSeek-Coder-33B | 33B | 80GB |
| DeepSeek-V3 | 685B | Multi-GPU |

## Deployment

```bash
# Via Ollama
ollama pull deepseek-coder

# Via vLLM
vllm serve deepseek-ai/deepseek-coder-6.7b-instruct

# Via Docker
docker compose up -d
```

## Code Generation

```python
response = client.chat.completions.create(
    model="deepseek-coder",
    messages=[
        {"role": "system", "content": "You are a coding assistant."},
        {"role": "user", "content": "Write a Python function to..."}
    ]
)
```

## Features

- **Code Completion**: Multi-language support
- **Code Review**: Bug detection
- **Refactoring**: Code improvement suggestions
- **Documentation**: Docstring generation

## Supported Languages

Python, JavaScript, TypeScript, Go, Rust, Java, C++, C#, PHP, Ruby, and 80+ more.

## Environment Variables

```env
MODEL_NAME=deepseek-ai/deepseek-coder-6.7b-instruct
TENSOR_PARALLEL_SIZE=1
MAX_MODEL_LEN=16384
```

## Related Repos

- `blackroad-vllm` - Inference engine
- `blackroad-ai-qwen` - Qwen model
- `blackroad-agents` - Agent integration
