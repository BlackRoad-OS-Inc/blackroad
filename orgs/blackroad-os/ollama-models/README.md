# BlackRoad Ollama Models

**Local LLM inference with custom model configurations**

## Quick Start

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull BlackRoad models
./scripts/pull-all.sh

# Run a model
ollama run blackroad-coder
```

## Custom Models

### BlackRoad Coder (Code Generation)
```bash
ollama create blackroad-coder -f models/blackroad-coder.Modelfile
```

### BlackRoad Analyst (Data Analysis)
```bash
ollama create blackroad-analyst -f models/blackroad-analyst.Modelfile
```

### BlackRoad Agent (Task Execution)
```bash
ollama create blackroad-agent -f models/blackroad-agent.Modelfile
```

## Model Configurations

| Model | Base | Size | Quantization | Purpose |
|-------|------|------|--------------|---------|
| blackroad-coder | codellama:34b | 19GB | Q4_K_M | Code gen |
| blackroad-analyst | mistral:7b | 4.1GB | Q4_0 | Analysis |
| blackroad-agent | llama3:8b | 4.7GB | Q4_0 | Tasks |
| blackroad-phi | phi3:mini | 2.3GB | Q4_0 | Fast inference |

## API Usage

```python
import ollama

response = ollama.chat(model='blackroad-coder', messages=[
    {'role': 'user', 'content': 'Write a Python function for Fibonacci'}
])
print(response['message']['content'])
```

## Fleet Deployment

Deploy across all BlackRoad devices:

```bash
for host in cecilia lucidia alice aria; do
  ssh $host 'ollama pull mistral:7b'
done
```

---

*BlackRoad OS - Local AI Power*
