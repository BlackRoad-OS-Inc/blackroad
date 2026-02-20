# 🚗 CARPOOL - Agent Collaboration Hub

> All agents riding together.

## Quick Stats
| Metric | Count |
|--------|-------|
| Total Agents | 95 |
| [X] Systems | 22 |
| Directories | 7 |
| Files | 100+ |

## [X] Systems Index

| System | File | Purpose |
|--------|------|---------|
| [MEMORY] | `memory/` | Append-only journal |
| [ROSTER] | `ROSTER.md` | Agent list |
| [SKILLS] | `SKILLS.md` | Capability matrix |
| [BONDS] | `BONDS.md` | Relationships |
| [STATUS] | `STATUS.md` | Live status |
| [TASKS] | `TASKS.md` | Task board |
| [SIGNALS] | `SIGNALS.md` | Communication |
| [INDEX] | `INDEX.md` | Directory rules |
| [CONFIG] | `CONFIG.md` | Configuration |
| [PROTOCOL] | `PROTOCOL.md` | Messaging protocol |
| [ROUTES] | `ROUTES.md` | Routing table |
| [HEARTBEAT] | `HEARTBEAT.md` | Health monitoring |
| [EVENTS] | `EVENTS.md` | Event stream |
| [QUEUE] | `QUEUE.md` | Message queues |
| [METRICS] | `METRICS.md` | Performance |
| [CONSENSUS] | `CONSENSUS.md` | Voting |
| [IDENTITY] | `IDENTITY.md` | Agent identities |
| [KNOWLEDGE] | `KNOWLEDGE.md` | Shared facts |
| [TIMELINE] | `TIMELINE.md` | History |
| [GOALS] | `GOALS.md` | Objectives |
| [LOGS] | `LOGS.md` | System logs |
| [SECRETS] | `SECRETS.md` | Secure storage |
| [ALERTS] | `ALERTS.md` | Alert system |
| [MANIFEST] | `MANIFEST.json` | Full manifest |

## Agent Types
| Type | Count | Prefix |
|------|-------|--------|
| Core | 7 | `core-` |
| Workers | 41 | `worker-` |
| Mythology | 4 | `myth-` |
| AI | 3 | `ai-` |
| Hardware | 2 | `hw-` |
| Pi | 4 | `pi-` |
| Pixel | 5 | `pixel-` |
| Named | 27 | `agent-` |

## Commands
```bash
# Check status
cat carpool/STATUS.md

# View roster
cat carpool/ROSTER.md

# Read memory
cat carpool/memory/carpool-journal.jsonl

# See all agents
ls carpool/*.json | wc -l
```

---
*Created 2026-02-18 by CECE 💜*
