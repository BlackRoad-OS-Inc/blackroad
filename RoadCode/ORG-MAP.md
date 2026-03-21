# BlackRoad Organization Map

> Turtles all the way down. Intelligent hierarchy.

## Hierarchy

```
enterprises/blackroad-os (PUBLIC FACE)
│
└── BlackRoad-OS-Inc (DATA LAYER — coordinates everything)
    │
    ├── blackroad-operator     ← OPERATES everything
    ├── RoadCode               ← THIS REPO (master workspace)
    ├── 19 domain repos        ← Website verticals
    ├── 100+ product repos     ← Software
    │
    └── Feeds DOWN to 15 sub-orgs:
        │
        ├── BlackRoad-OS           200 repos  Core platform
        ├── BlackRoad-Studio        11 repos  Creator tools
        ├── BlackRoad-Archive       15 repos  Storage/backup
        ├── BlackRoad-Interactive   16 repos  Games/3D/physics
        ├── BlackRoad-Security      20 repos  Auth/security
        ├── BlackRoad-Gov           13 repos  Governance/policy
        ├── BlackRoad-Education     11 repos  Learning/tutoring
        ├── BlackRoad-Hardware      18 repos  IoT/fleet/sensors
        ├── BlackRoad-Media         17 repos  Content/streaming
        ├── BlackRoad-Foundation    17 repos  CRM/HR/ops
        ├── BlackRoad-Ventures      12 repos  Investment/portfolio
        ├── BlackRoad-Cloud         13 repos  K8s/terraform/mesh
        ├── BlackRoad-Labs          14 repos  Research/experiments
        ├── BlackRoad-AI            20 repos  Ollama/models/inference
        └── Blackbox-Enterprises    12 repos  n8n/automation
```

## Domain → Sub-Org Mapping

| Domain | Sub-Org | Vertical |
|--------|---------|----------|
| blackroad.company | BlackRoad-Foundation | Corporate |
| blackroad.io | BlackRoad-OS | Master platform |
| blackroad.me | BlackRoad-Media | Social/identity |
| blackroad.network | BlackRoad-Cloud | Infrastructure |
| blackroad.systems | BlackRoad-Hardware | Fleet management |
| blackroadai.com | BlackRoad-AI | AI/ML |
| blackroadinc.us | BlackRoad-Foundation | Corporate/legal |
| blackroadqi.com | BlackRoad-Labs | Quantum/math |
| blackroadquantum.com | BlackRoad-Labs | Quantum computing |
| blackroadquantum.info | BlackRoad-Labs | Research/docs |
| blackroadquantum.net | BlackRoad-Cloud | Quantum network |
| blackroadquantum.shop | BlackRoad-Ventures | E-commerce |
| blackroadquantum.store | BlackRoad-Ventures | E-commerce |
| lucidia.earth | BlackRoad-AI | Creator platform |
| lucidia.studio | BlackRoad-Studio | Creative tools |
| lucidiaqi.com | BlackRoad-AI | AI/quantum |
| roadchain.io | BlackRoad-Security | Blockchain |
| roadcoin.io | BlackRoad-Gov | Payments/crypto |
| blackboxprogramming.io | Blackbox-Enterprises | Dev tools |

## Infrastructure Nodes

| Node | IP | Role | Key Services |
|------|-----|------|-------------|
| Alice | .49 | Gateway | nginx, PostgreSQL, Redis, Qdrant, Pi-hole, RoundTrip |
| Cecilia | .96 | AI Engine | Ollama (4 models), MinIO, PostgreSQL, InfluxDB |
| Octavia | .101 | Architect | Gitea (228 models), Docker, NATS |
| Aria | .98 | Interface | Docker, Portainer, nginx, Ollama |
| Lucidia | .38 | Dreamer | Ollama (6 models), nginx, 334 web apps |
| Gematria | DO | Edge Router | Caddy (114 domains), 279 websites, Ollama |
| Anastasia | DO | Cloud Edge | Caddy, Docker, Ollama |

## Google Drive Accounts

| Account | Key Folders |
|---------|------------|
| alexa@blackroad.io | BlackRoad OS Inc (13 folders), workspace, Root, Pi backups |
| amundsonalexa@gmail.com | BlackRoad OS, Templates, personal |

---
*BlackRoad OS, Inc. — PROPRIETARY. Pave Tomorrow.*
