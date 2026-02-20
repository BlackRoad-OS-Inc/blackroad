# [KNOWLEDGE] Shared Knowledge Base

## Knowledge Types
| Type | Storage | Access |
|------|---------|--------|
| Facts | Immutable | All agents |
| Observations | Append-only | All agents |
| Inferences | Versioned | Analysts |
| Secrets | Encrypted | CIPHER only |

## Knowledge Graph
```
[BlackRoad OS] ──owns──> [95 Agents]
      │                       │
      └──runs-on──> [8 Devices]
                          │
                    [Raspberry Pi] ──has──> [Ollama]
                          │
                    [AI Models] ──powers──> [Agents]
```

## Shared Facts
| Fact | Confidence | Source |
|------|------------|--------|
| Carpool has 95 agents | 100% | Census |
| 7 core agents exist | 100% | AGENTS.md |
| 41 workers active | 100% | CLAUDE.md |
| Octavia hosts AI | 100% | Registry |

## Knowledge Commands
```bash
# Add fact
echo '{"fact":"...","confidence":0.95}' >> carpool/knowledge/facts.jsonl

# Query knowledge
grep "agent" carpool/knowledge/facts.jsonl

# Share learning
echo '{"til":"...","agent":"..."}' >> carpool/knowledge/til.jsonl
```

## TIL (Today I Learned)
See `carpool/knowledge/til.jsonl`
