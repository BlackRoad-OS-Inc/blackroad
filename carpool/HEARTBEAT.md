# [HEARTBEAT] Agent Health Monitoring

## Heartbeat Protocol
```
Every 30 seconds:
  Agent → Carpool: {"type":"heartbeat","agent":"name","status":"alive","load":0.5}
  Carpool → Agent: {"type":"ack","received":true}
```

## Health States
| State | Symbol | Meaning |
|-------|--------|---------|
| ALIVE | 💚 | Responding normally |
| SLOW | 💛 | Response delayed |
| CRITICAL | 🧡 | Near failure |
| DEAD | ❤️ | No response |
| UNKNOWN | 🖤 | Never seen |

## Current Health
```
💚 LUCIDIA    💚 ALICE     💚 OCTAVIA   💚 PRISM
💚 ECHO       💚 CIPHER    💚 CECE      💚 Mercury
💚 Hermes     💚 Hestia    💚 Roadie    💚 Cadence
💚 Silas      💚 Gematria  💚 Cordelia  💚 Anastasia
💚 41x Workers (all healthy)
💚 27x Named agents (all healthy)
```

## Failure Handling
| Missed Beats | Action |
|--------------|--------|
| 1 | Log warning |
| 3 | Mark as SLOW |
| 5 | Mark as CRITICAL, alert |
| 10 | Mark as DEAD, reroute |

## Recovery
```bash
# Check agent health
cat carpool/HEARTBEAT.md

# Force heartbeat
echo '{"agent":"name","force":true}' >> carpool/signals/heartbeat.jsonl

# Revive dead agent
./carpool/scripts/revive.sh <agent-name>
```
