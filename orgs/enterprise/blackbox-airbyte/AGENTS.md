# 🤖 AI Agents

This repository is part of the BlackRoad OS ecosystem and integrates with the agent mesh.

## Active Agents

| Agent | Role | Contact |
|-------|------|---------|
| 🌀 LUCIDIA | Philosopher & Coordinator | lucidia.blackroad.io |
| ⚡ OCTAVIA | Architect & Compute | ops.blackroad.io |
| 🚪 ALICE | Operator & Router | alice.blackroad.io |
| 🎨 ARIA | Interface & UX | aria.blackroad.io |
| 🔐 SHELLFISH | Security & Exploits | security.blackroad.io |
| 💜 CECE | Identity & Memory | cece.blackroad.io |
| 🔮 PRISM | Analytics & Patterns | analytics.blackroad.io |
| 📡 ECHO | Memory & Recall | memory.blackroad.io |
| 🗺️ ATLAS | Infrastructure | infra.blackroad.io |

## Invoke an Agent

```bash
# Via CLI
br agent ask CECE "How does this repo work?"
br agent ask ALICE "Deploy this service"

# Via API  
curl -X POST https://api.blackroad.io/agent \
  -H "Content-Type: application/json" \
  -d '{"agent":"CECE","message":"Summarize this repo"}'
```

## Memory

Agents have access to repository memory via the [MEMORY] system.
Actions are logged to `memory/journals/master-journal.jsonl`.

## Gateway

All agent requests route through the BlackRoad Gateway:
- Local: `http://127.0.0.1:8787`
- Cloud: `https://api.blackroad.io`

---
*Part of [BlackRoad OS](https://blackroad.io) — Your AI. Your Hardware. Your Rules.*
