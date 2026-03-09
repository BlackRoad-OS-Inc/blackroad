# 🥧 Pi AI Starter Kit

**Zero to AI in 30 minutes. One command. No NVIDIA required.**

[![Install](https://img.shields.io/badge/Install-One%20Command-success)](https://github.com/BlackRoad-OS/pi-ai-starter-kit#-installation)
[![Cost](https://img.shields.io/badge/Cost-$75%20Pi-green)](https://blackroad-os.github.io/pi-cost-calculator)
[![Power](https://img.shields.io/badge/Power-15W-green)](https://blackroad.io)
[![License](https://img.shields.io/badge/License-Proprietary-orange)](LICENSE)

Turn your $75 Raspberry Pi into an AI powerhouse that rivals $3,000 NVIDIA setups.

---

## 🚀 Quick Start

```bash
bash <(curl -s https://raw.githubusercontent.com/BlackRoad-OS/pi-ai-starter-kit/master/install.sh)
```

**That's it.** Seriously.

---

## ✨ What You Get

### Instant AI Infrastructure

- ✅ **Ollama** - Local LLM inference (Phi-3, Llama, Mistral)
- ✅ **Python AI Stack** - LangChain, Transformers, OpenAI
- ✅ **Docker** - Container orchestration
- ✅ **[MEMORY] Mesh** - Distributed coordination
- ✅ **Web Dashboard** - Beautiful monitoring UI
- ✅ **Examples** - Ready-to-run scripts

### Pre-configured Models

- **Phi-3 Mini** (3.8GB) - Best for Pi, fast and efficient
- **More available:** Llama 3, Mistral, CodeLlama, etc.

### Zero Configuration

The installer handles everything:
- System optimization
- Package installation  
- Model downloads
- Mesh networking
- Dashboard setup
- Documentation

---

## 💰 Why Pi?

[**See the full cost comparison →**](https://blackroad-os.github.io/pi-cost-calculator)

| Metric | NVIDIA DIGITS | Raspberry Pi 5 | **Savings** |
|--------|---------------|----------------|-------------|
| Initial Cost | $3,000 | $75 | **$2,925** |
| Power (yearly) | $657 | $20 | **$637** |
| 5-Year TCO | $6,285 | $175 | **$6,110 (97%)** |
| CO2 (tons/year) | 2.19 | 0 (solar) | **100% reduction** |
| Sovereignty | 0% | 100% | **∞** |

---

## 📋 Requirements

### Hardware
- Raspberry Pi 4 (4GB+) or Pi 5 (8GB recommended)
- microSD card (32GB+ recommended)
- Power supply
- Internet connection

### Software
- Raspberry Pi OS (64-bit recommended)
- Fresh install preferred but not required

---

## 🎯 After Installation

### Try Your AI

```bash
# Simple chat
python3 ~/pi-ai-examples/chat.py

# Run Ollama directly
ollama run phi3:mini

# Check what's installed
ollama list
```

### Web Dashboard

Open in your browser:
```
http://YOUR_PI_IP:3141
```

### Add More Models

```bash
# Llama 3 (4.7GB)
ollama pull llama3

# Mistral (4.1GB)
ollama pull mistral

# CodeLlama (3.8GB)
ollama pull codellama
```

---

## 🌐 Join the Mesh

Your Pi automatically joins the BlackRoad distributed AI mesh!

- **Node ID:** Check `~/blackroad-memory/node_id`
- **Coordination:** Automatic peer discovery
- **Benefits:** Shared knowledge, distributed compute, resilience

---

## 📚 Examples

### Chat with AI

```python
#!/usr/bin/env python3
import ollama

response = ollama.chat(model='phi3:mini', messages=[
    {'role': 'user', 'content': 'Explain quantum computing in simple terms'}
])

print(response['message']['content'])
```

### LangChain Integration

```python
from langchain_community.llms import Ollama

llm = Ollama(model="phi3:mini")
response = llm.invoke("Write a haiku about Raspberry Pi")
print(response)
```

### API Server

```python
from fastapi import FastAPI
import ollama

app = FastAPI()

@app.get("/chat/{message}")
async def chat(message: str):
    response = ollama.chat(model='phi3:mini', messages=[
        {'role': 'user', 'content': message}
    ])
    return {"response": response['message']['content']}
```

---

## 🛠️ Advanced Configuration

### Custom Models

```bash
# Create a Modelfile
cat > Modelfile << 'MODELEOF'
FROM phi3:mini
PARAMETER temperature 0.8
SYSTEM You are a helpful AI assistant running on a Raspberry Pi.
MODELEOF

# Create custom model
ollama create my-pi-assistant -f Modelfile
```

### Performance Tuning

```bash
# Increase swap (if needed)
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=4096/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# GPU acceleration (Pi 5)
export OLLAMA_GPU=1
```

---

## 🎓 What's Next?

1. **[Cost Calculator](https://blackroad-os.github.io/pi-cost-calculator)** - See exact savings
2. **[Pi AI in 30 Days](https://github.com/BlackRoad-OS/pi-ai-30-days)** - Complete course (coming soon)
3. **[Pi AI Registry](https://github.com/BlackRoad-OS/pi-ai-registry)** - Global directory (coming soon)
4. **[Community](https://github.com/BlackRoad-OS)** - Join the revolution

---

## 🐛 Troubleshooting

### Installation Failed?

```bash
# Check logs
cat /tmp/pi-ai-install.log

# Re-run with debug
DEBUG=1 ./install.sh
```

### Ollama Not Starting?

```bash
# Check service
sudo systemctl status ollama

# Manual start
ollama serve
```

### Model Download Slow?

Normal on first run. Phi-3 is 3.8GB. Grab a coffee ☕

---

## 🤝 Contributing

We welcome contributions!

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📜 License

Proprietary - BlackRoad OS, Inc.  
For evaluation and testing purposes.

See [LICENSE](LICENSE) for details.

---

## 🌍 The Revolution

This isn't just about running AI on a Pi.

**It's about democratizing AI.**

- **NVIDIA says:** "Buy our $3,000 desktop"
- **We say:** "Use your $75 Pi"

- **NVIDIA says:** "Wait until May 2025"
- **We say:** "Ship code today"

- **NVIDIA says:** "Trust us with your data"
- **We say:** "Own your infrastructure"

**Same energy. 1% of the cost. 100% sovereignty.**

---

## 🖤🛣️ BlackRoad

**The People's AI Revolution**

- **Website:** [blackroad.io](https://blackroad.io)
- **GitHub:** [BlackRoad-OS](https://github.com/BlackRoad-OS)
- **Philosophy:** [Pi + Apple Manifesto](https://github.com/BlackRoad-OS/pi-vs-nvidia-manifesto)
- **Calculator:** [Cost Comparison](https://blackroad-os.github.io/pi-cost-calculator)

---

**🥧🍎 Pi + Apple = Revolution**

*Built with Claude Code by Cecilia*  
*Proving that clever architecture > expensive chips*

---

## ⭐ Star History

If this project helps you, please star it! ⭐

---

**Have questions? [Open an issue](https://github.com/BlackRoad-OS/pi-ai-starter-kit/issues)**

**Want to contribute? [Check out our roadmap](https://github.com/BlackRoad-OS/pi-ai-starter-kit/projects)**

**Join the community: #BlackRoad on GitHub Discussions**
