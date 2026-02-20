# [ROUTES] Agent Routing Table

## Core Agent Routes
| Capability | Primary | Fallback | Escalation |
|------------|---------|----------|------------|
| Philosophy | LUCIDIA | CECE | - |
| Routing | ALICE | CIPHER | LUCIDIA |
| Compute | OCTAVIA | Mercury | Hermes |
| Analysis | PRISM | Silas | Gematria |
| Memory | ECHO | CECE | LUCIDIA |
| Security | CIPHER | ALICE | LUCIDIA |
| Creative | CECE | Cadence | LUCIDIA |
| Revenue | Mercury | Hestia | LUCIDIA |
| Deploy | Hermes | ALICE | OCTAVIA |
| Payments | Hestia | Mercury | CIPHER |

## Worker Routes
| Domain Pattern | Worker | Fallback |
|---------------|--------|----------|
| `api.*` | api-blackroadio | gateway |
| `admin.*` | admin-blackroadio | console |
| `data.*` | data-blackroadio | analytics |
| `edge.*` | edge-blackroadio | cdn |
| `*.blackroad.io` | network-blackroadio | global |

## Hardware Routes
| Task Type | Primary | Fallback |
|-----------|---------|----------|
| AI Inference | Octavia | Anastasia |
| API Services | Aria | Alice |
| Orchestration | Cordelia | Lucidia |
| Gateway | Alice | Aria |

## Routing Rules
```
1. Route by capability match
2. Check agent status before routing
3. Use fallback if primary unavailable
4. Escalate to LUCIDIA if all fail
5. Log all routing decisions to [MEMORY]
```

## Load Balancing
| Strategy | Use Case |
|----------|----------|
| Round Robin | Worker distribution |
| Least Loaded | Compute tasks |
| Priority | Critical tasks |
| Affinity | Stateful sessions |
