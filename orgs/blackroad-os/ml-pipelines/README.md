# BlackRoad ML Pipelines

**End-to-end machine learning workflows**

## Pipeline Types

| Pipeline | Use Case | Framework |
|----------|----------|-----------|
| Training | Model training from scratch | PyTorch/JAX |
| Fine-tuning | Adapt pretrained models | HuggingFace |
| Evaluation | Benchmark performance | MLflow |
| Serving | Deploy to production | vLLM/Triton |

## Quick Start

```python
from blackroad_ml import Pipeline

# Fine-tuning pipeline
pipeline = Pipeline.finetune(
    base_model="mistralai/Mistral-7B-v0.1",
    dataset="blackroad/agent-instructions",
    output_dir="./models/blackroad-agent"
)

pipeline.run()
```

## Training Configuration

```yaml
# config/train.yaml
model:
  name: mistralai/Mistral-7B-v0.1
  quantization: qlora
  
training:
  epochs: 3
  batch_size: 4
  learning_rate: 2e-4
  gradient_accumulation: 4
  
data:
  train: data/train.jsonl
  eval: data/eval.jsonl
  max_length: 4096
```

## Supported Models

- Mistral 7B/8x7B
- Llama 3 8B/70B
- Phi-3 Mini/Small
- CodeLlama 7B/34B

## Infrastructure

- **GPU**: A100, H100, RTX 4090
- **Distributed**: DeepSpeed, FSDP
- **Tracking**: Weights & Biases, MLflow

---

*BlackRoad OS - ML at Scale*
