# 🤖 BlackRoad AI - Qwen2.5 Model

**Proprietary Qwen2.5 deployment with [MEMORY] integration**

## 🎯 Overview

This is BlackRoad's deployment of the Qwen2.5-7B model (Apache 2.0), enhanced with:
- 🧠 **[MEMORY] Integration** - Full access to BlackRoad memory system
- ⚡ **Action Execution** - Can execute bash commands, API calls
- 🎨 **Emoji Enhancement** - Contextual emoji support
- 🤝 **Claude Collaboration** - Works with other Claude instances
- 🌐 **Cluster Deployment** - Distributed across Pi network

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│           Qwen2.5 Model Service                 │
│  ┌──────────────┐  ┌────────────────┐           │
│  │   FastAPI    │  │  [MEMORY]      │           │
│  │   Server     │◄─┤  Bridge        │           │
│  └──────┬───────┘  └────────────────┘           │
│         │                                        │
│  ┌──────▼───────┐  ┌────────────────┐           │
│  │   Qwen2.5    │  │  Action        │           │
│  │   7B Model   │  │  Executor      │           │
│  └──────────────┘  └────────────────┘           │
└─────────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
    User Apps          BlackRoad Memory System
```

## 🚀 Quick Start

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run server
python src/main.py
```

### Docker Deployment
```bash
# Build image
docker build -t blackroad-ai-qwen:latest .

# Run container
docker-compose up -d

# Check logs
docker logs -f blackroad-ai-qwen
```

### Deploy to Pi Cluster
```bash
# Deploy to all Pis
./deploy-to-cluster.sh

# Deploy to specific Pi
./deploy-to-pi.sh lucidia
```

## 📡 API Endpoints

### Health Check
```bash
curl http://localhost:8000/health
```

### Chat Completion
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Explain quantum computing",
    "max_tokens": 512,
    "temperature": 0.7,
    "use_memory": true,
    "enable_actions": true,
    "session_id": "user-123"
  }'
```

Response:
```json
{
  "response": "🧠 Quantum computing harnesses quantum mechanics...",
  "tokens_used": 156,
  "memory_context_used": true,
  "actions_executed": [],
  "emoji_enhanced": true
}
```

## 🧠 [MEMORY] Integration

The model automatically:
- ✅ Reads context from BlackRoad memory system
- ✅ Saves all interactions for future reference
- ✅ Collaborates with other Claude instances
- ✅ Broadcasts status updates

Example memory interaction:
```python
# Memory bridge automatically includes context
memory_bridge.get_context("session-123")
# Returns recent conversation history + system context

# Saves interaction
memory_bridge.save_interaction(
    session_id="session-123",
    user_message="Hello",
    assistant_response="Hi! 🖤🛣️",
    tags=["greeting", "qwen"]
)
```

## ⚡ Action Execution

The model can execute approved actions:
- `memory_log` - Write to memory system
- `memory_check` - Read from memory system
- `collaboration_status` - Check other Claude instances

Blacklisted actions (security):
- `rm`, `shutdown`, `reboot` - System commands

## 🎨 Emoji Enhancement

Automatically enhances responses with contextual emojis:
- ✅ Success indicators
- ❌ Error markers
- 🚀 Progress indicators
- 🖤🛣️ BlackRoad signature

## 🌐 Cluster Deployment

Deployed across BlackRoad Pi network:
- **lucidia** (192.168.4.38) - Primary node
- **aria** (192.168.4.64) - Secondary node
- **alice** (192.168.4.49) - Tertiary node
- **octavia** (192.168.4.74) - Quaternary node
- **shellfish** (174.138.44.45) - Cloud node

Load balancing handled by API Gateway.

## 📊 Monitoring

- Health checks: `http://localhost:8000/health`
- Metrics: `http://localhost:9090/metrics` (Prometheus)
- Logs: `docker logs blackroad-ai-qwen`

## 🎨 BlackRoad Brand Integration

All responses follow BlackRoad design principles:
- Colors: Hot Pink (#FF1D6C), Amber (#F5A623), Electric Blue (#2979FF), Violet (#9C27B0)
- Signature: 🖤🛣️ Built with BlackRoad Vision

## 📄 License

- **Model**: Apache 2.0 (Qwen2.5)
- **Enhancements**: BlackRoad Proprietary
- **Memory Bridge**: BlackRoad Proprietary

## 🤝 Contributing

This is part of BlackRoad's AI infrastructure. See main repo for contribution guidelines.

---

🌌 **Built with the BlackRoad Vision** - Quantum principles meet distributed AI

---

## 🖤 BlackRoad OS

This repository is part of the **BlackRoad OS** ecosystem - the operating system for AI-first companies.

### 🌟 The Vision

BlackRoad OS enables entire companies to operate exclusively by AI while serving as the API layer above Google, OpenAI, and Anthropic, managing their AI model memory and continuity.

- **OS in a Window**: [os.blackroad.io](https://os.blackroad.io)
- **3D AI Models**: [products.blackroad.io](https://products.blackroad.io)
- **Agent Orchestration**: 30,000 AI agents coordinated via memory system

### 🤖 GitHub Integration

Need help? Mention **@blackroad** in any issue or PR to summon our intelligent agent cascade!

### 📊 Repository Stats

- **Organization**: Part of 15 BlackRoad organizations
- **Total Repos**: 144+ across the empire
- **AI Agents**: 30,000+ available for assistance

### 🔗 Links

- [BlackRoad OS](https://blackroad.io)
- [Documentation](https://docs.blackroad.io)
- [Status](https://status.blackroad.io)
- [GitHub Organizations](https://github.com/BlackRoad-OS)

### 📧 Contact

- Email: blackroad.systems@gmail.com
- Primary: amundsonalexa@gmail.com

### ⚖️ License

Copyright © 2026 BlackRoad OS, Inc. - All Rights Reserved

See [LICENSE](./LICENSE) for details.

---

🖤🛣️ **The road is the destination.**
