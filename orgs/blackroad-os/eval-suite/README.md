# BlackRoad Evaluation Suite

**Comprehensive AI model benchmarking and testing**

## Benchmarks

| Benchmark | Metrics | Models |
|-----------|---------|--------|
| MMLU | Accuracy | All LLMs |
| HumanEval | Pass@k | Code models |
| MT-Bench | Score 1-10 | Chat models |
| Custom | Configurable | Any |

## Quick Start

```python
from blackroad_eval import Evaluator, Benchmark

evaluator = Evaluator(model="mistral-7b")

# Run standard benchmark
results = evaluator.run(Benchmark.MMLU)
print(f"MMLU Score: {results.accuracy:.2%}")

# Custom evaluation
custom = evaluator.run_custom(
    dataset="./test_cases.jsonl",
    metrics=["accuracy", "latency", "cost"]
)
```

## Metrics

- **Accuracy**: Correctness on benchmarks
- **Latency**: Response time (p50, p95, p99)
- **Throughput**: Tokens per second
- **Cost**: $ per 1M tokens
- **Safety**: Refusal rate, toxicity

## Comparison Dashboard

```bash
# Generate comparison report
blackroad-eval compare \
  --models mistral-7b,llama3-8b,claude-sonnet \
  --benchmarks mmlu,humaneval \
  --output report.html
```

## CI/CD Integration

```yaml
- name: Evaluate Model
  run: |
    blackroad-eval run \
      --model ${{ env.MODEL }} \
      --threshold 0.85 \
      --fail-on-regression
```

---

*BlackRoad OS - Measure What Matters*
