# 🧠 Multi-Model Continuity Testing Framework

Tests reasoning and context continuity across different open-source LLM models deployed on the BlackRoad Cluster.

## Overview

This framework tests how well different AI models can:
1. **Maintain reasoning** across multi-turn conversations
2. **Transfer context** between different models
3. **Distribute reasoning** across multiple nodes
4. **Preserve continuity** when switching models mid-task

## Models Tested

### Currently Deployed
- **Phi-3.5** (3.8B parameters) - Microsoft's efficient model
- **TinyLlama** (1.1B parameters) - Compact reasoning model
- **Gemma 2** (2B parameters) - Google's instruction-tuned model
- **Qwen 2.5** (1.5B parameters) - Alibaba's multilingual model
- **DeepSeek-R1** (1.5B parameters) - DeepSeek's reasoning model

### Cluster Distribution
```
Octavia (Pi 5):   phi3.5, tinyllama, gemma2
Lucidia (Pi 5):   qwen2.5, phi3.5
Aria (Pi 5):      deepseek-r1, phi3.5
Shellfish (x86):  phi3.5 (cloud fallback)
```

## Test Suite

### 1. Reasoning Continuity Test
Tests if a model can answer follow-up questions that require understanding previous responses.

**Example:**
```
Q1: "What is a transistor?"
A1: [Model responds]
Q2: "Based on that, why does it generate heat?"
A2: [Model must reference A1]
```

### 2. Context Transfer Test
Tests if context can be passed from Model A to Model B successfully.

**Example:**
```
Model A: "Count from 1 to 5, give me first 3"
Model A: "1, 2, 3"
Model B (with context): "Continue the sequence"
Model B: "4, 5" ← Success if it continues correctly
```

### 3. Distributed Reasoning Test
Multiple models solve different parts of the same problem.

**Example:**
```
Model A: Calculate quantum states for 1 billion transistors
Model B: Calculate for 4 billion transistors
Model C: Compare the results
```

### 4. Cross-Model Validation Test
Different models validate each other's reasoning.

## Running Tests

### Prerequisites
```bash
# All cluster nodes need:
- Ollama installed
- Python 3.8+
- SSH access configured
```

### Quick Start
```bash
cd tests/model-continuity
python3 multi_model_test.py
```

### Run Specific Test
```python
from multi_model_test import ModelContinuityTester

tester = ModelContinuityTester({
    "octavia": "192.168.4.81",
    "lucidia": "192.168.4.38"
})

# Run single test
tester.test_reasoning_continuity()
tester.generate_report()
```

## Results Format

Results are saved as JSON:
```json
{
  "session_id": "abc123ef",
  "timestamp": "2026-01-10T02:00:00",
  "test_results": [
    {
      "test_name": "reasoning_continuity",
      "models_tested": ["phi3.5", "gemma2"],
      "results": [...]
    }
  ]
}
```

## Key Metrics

Each test tracks:
- **Response Time** - How long each model takes
- **Continuity Score** - Did it maintain context?
- **Accuracy** - Was the response correct?
- **Node Distribution** - Which nodes were used
- **Token Count** - Approximate tokens processed

## Example Output

```
════════════════════════════════════════════════════════════════════════════════
🧪 MULTI-MODEL CONTINUITY TEST REPORT
════════════════════════════════════════════════════════════════════════════════

Session ID: f3a21b4c
Timestamp: 2026-01-10T02:15:30
Tests Run: 3

───────────────────────────────────────────────────────────────────────────────
TEST: REASONING CONTINUITY
───────────────────────────────────────────────────────────────────────────────
Models Tested: phi3.5, gemma2, qwen2.5

Model: phi3.5 on octavia
  Initial Query Time: 2.4s
  Follow-up Time: 1.8s
  Total Time: 4.2s
  Continuity: ✓ Maintained

Model: gemma2 on octavia
  Initial Query Time: 3.1s
  Follow-up Time: 2.2s
  Total Time: 5.3s
  Continuity: ✓ Maintained

[...]
```

## Use Cases

### 1. Multi-Agent Systems
Test how different AI agents can collaborate and hand off tasks.

### 2. Model Selection
Determine which models best maintain context for your application.

### 3. Distributed AI
Validate distributed reasoning across cluster nodes.

### 4. Quantum Computing Research
Test if models can reason about quantum computing concepts across multiple turns.

## Integration with Memory System

All test results are logged to BlackRoad Memory System:

```bash
~/memory-system.sh log experiment \
  "[MODEL_CONTINUITY] Multi-model test session f3a21b4c" \
  "Results summary..." \
  "ai,continuity,testing"
```

## Future Enhancements

- [ ] Add more models (Llama 3, Mixtral, etc.)
- [ ] Test multi-modal continuity (text → image → text)
- [ ] Measure semantic similarity of responses
- [ ] Automatic context optimization
- [ ] Real-time continuity monitoring
- [ ] API key management for cloud models
- [ ] Load balancing across nodes

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│            Multi-Model Continuity Framework             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐         │
│  │ Octavia  │    │ Lucidia  │    │   Aria   │         │
│  ├──────────┤    ├──────────┤    ├──────────┤         │
│  │ Phi-3.5  │    │ Qwen 2.5 │    │DeepSeek  │         │
│  │  Gemma2  │    │ Phi-3.5  │    │ Phi-3.5  │         │
│  │TinyLlama │    │          │    │          │         │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘         │
│       │               │               │                │
│       └───────────────┼───────────────┘                │
│                       │                                │
│              ┌────────▼────────┐                       │
│              │  Test Orchestra │                       │
│              │   - Query       │                       │
│              │   - Track       │                       │
│              │   - Validate    │                       │
│              └────────┬────────┘                       │
│                       │                                │
│              ┌────────▼────────┐                       │
│              │   [MEMORY]      │                       │
│              │   Results DB    │                       │
│              └─────────────────┘                       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Contributing

See main [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](../../LICENSE)

---

**Part of the Quantum Computing Revolution Project**
*Testing distributed intelligence across quantum hardware* 🌌
