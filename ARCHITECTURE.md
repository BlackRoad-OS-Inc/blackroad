# BlackRoad OS Architecture

> System architecture, design patterns, and technical specifications

---

## 📐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BLACKROAD OS                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │   Web App   │  │     CLI     │  │   Mobile    │  │  VS Code    │       │
│  │  (Next.js)  │  │   (Rust)    │  │   (React)   │  │ Extension   │       │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘       │
│         │                │                │                │               │
│         └────────────────┴────────────────┴────────────────┘               │
│                                   │                                         │
│                          ┌────────▼────────┐                               │
│                          │   API Gateway   │                               │
│                          │  (Cloudflare)   │                               │
│                          └────────┬────────┘                               │
│                                   │                                         │
│         ┌─────────────────────────┼─────────────────────────┐              │
│         │                         │                         │              │
│  ┌──────▼──────┐          ┌──────▼──────┐          ┌──────▼──────┐       │
│  │   Agent     │          │   Memory    │          │    Model    │       │
│  │  Service    │          │   Service   │          │   Service   │       │
│  │  (Python)   │          │  (Python)   │          │   (vLLM)    │       │
│  └──────┬──────┘          └──────┬──────┘          └──────┬──────┘       │
│         │                         │                         │              │
│         └─────────────────────────┼─────────────────────────┘              │
│                                   │                                         │
│                    ┌──────────────┴──────────────┐                         │
│                    │                             │                         │
│             ┌──────▼──────┐              ┌──────▼──────┐                   │
│             │  PostgreSQL │              │   Redis     │                   │
│             │  (Primary)  │              │  (Cache)    │                   │
│             └─────────────┘              └─────────────┘                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Component Architecture

### 1. Client Layer

```
┌─────────────────────────────────────────────────────────────┐
│                      CLIENT LAYER                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ blackroad-os-web│  │  blackroad-cli  │                  │
│  │                 │  │                 │                  │
│  │ • Next.js 16    │  │ • Rust          │                  │
│  │ • React 19      │  │ • Clap CLI      │                  │
│  │ • TailwindCSS 4 │  │ • TUI (ratatui) │                  │
│  │ • Zustand       │  │ • Async runtime │                  │
│  └─────────────────┘  └─────────────────┘                  │
│                                                             │
│  Features:                                                  │
│  • Real-time WebSocket updates                             │
│  • Offline-first with sync                                 │
│  • Progressive Web App                                     │
│  • Native keyboard shortcuts                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. API Layer

```
┌─────────────────────────────────────────────────────────────┐
│                       API LAYER                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  API Gateway                         │   │
│  │              (Cloudflare Workers)                    │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ • Rate limiting (1000 req/min)                      │   │
│  │ • JWT validation                                    │   │
│  │ • Request routing                                   │   │
│  │ • Response caching                                  │   │
│  │ • DDoS protection                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│           ┌───────────────┼───────────────┐                │
│           ▼               ▼               ▼                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │  REST API   │ │ GraphQL API │ │ WebSocket   │          │
│  │  /api/v1/*  │ │  /graphql   │ │   /ws       │          │
│  └─────────────┘ └─────────────┘ └─────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3. Service Layer

```
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │ Agent Service │  │Memory Service │  │ Model Service │  │
│  │               │  │               │  │               │  │
│  │ • FastAPI     │  │ • FastAPI     │  │ • vLLM        │  │
│  │ • Celery      │  │ • Pinecone    │  │ • PyTorch     │  │
│  │ • Redis       │  │ • Redis       │  │ • CUDA        │  │
│  │               │  │               │  │               │  │
│  │ Endpoints:    │  │ Endpoints:    │  │ Endpoints:    │  │
│  │ POST /agents  │  │ POST /store   │  │ POST /chat    │  │
│  │ GET /agents   │  │ POST /search  │  │ POST /embed   │  │
│  │ POST /tasks   │  │ GET /retrieve │  │ GET /models   │  │
│  └───────────────┘  └───────────────┘  └───────────────┘  │
│                                                             │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  │
│  │ Auth Service  │  │ Task Service  │  │ Event Service │  │
│  │               │  │               │  │               │  │
│  │ • JWT tokens  │  │ • Job queues  │  │ • Pub/sub     │  │
│  │ • OAuth2      │  │ • Scheduling  │  │ • Webhooks    │  │
│  │ • RBAC        │  │ • Retries     │  │ • SSE         │  │
│  └───────────────┘  └───────────────┘  └───────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4. Data Layer

```
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ PostgreSQL  │  │   Redis     │  │  Pinecone   │        │
│  │             │  │             │  │             │        │
│  │ • Users     │  │ • Sessions  │  │ • Vectors   │        │
│  │ • Agents    │  │ • Cache     │  │ • Memories  │        │
│  │ • Tasks     │  │ • Queues    │  │ • Embeddings│        │
│  │ • Logs      │  │ • Pub/Sub   │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Cloudflare  │  │ Cloudflare  │  │   S3/R2     │        │
│  │     KV      │  │     D1      │  │             │        │
│  │             │  │             │  │ • Files     │        │
│  │ • Config    │  │ • Edge data │  │ • Backups   │        │
│  │ • Feature   │  │ • Analytics │  │ • Exports   │        │
│  │   flags     │  │             │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🤖 Agent Architecture

### Agent Lifecycle

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  CREATE  │───▶│  READY   │───▶│  ACTIVE  │───▶│ COMPLETE │
└──────────┘    └────┬─────┘    └────┬─────┘    └──────────┘
                     │               │
                     │    ┌──────────▼──────────┐
                     │    │      RUNNING        │
                     │    │                     │
                     │    │  ┌──────────────┐  │
                     │    │  │   THINKING   │  │
                     │    │  └──────┬───────┘  │
                     │    │         │          │
                     │    │  ┌──────▼───────┐  │
                     │    │  │   ACTING     │  │
                     │    │  └──────┬───────┘  │
                     │    │         │          │
                     │    │  ┌──────▼───────┐  │
                     │    │  │  OBSERVING   │  │
                     │    │  └──────────────┘  │
                     │    └────────────────────┘
                     │               │
                     ▼               ▼
               ┌──────────┐   ┌──────────┐
               │  PAUSED  │   │  ERROR   │
               └──────────┘   └──────────┘
```

### Agent Types

| Type | Description | Use Case |
|------|-------------|----------|
| **LUCIDIA** | Philosophical reasoning | Deep analysis |
| **ALICE** | Task execution | Automation |
| **OCTAVIA** | Technical operations | DevOps |
| **PRISM** | Pattern analysis | Data insights |
| **ECHO** | Memory management | Knowledge |
| **CIPHER** | Security | Protection |

### Agent Communication

```
┌─────────────────────────────────────────────────────────────┐
│                  AGENT COMMUNICATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Direct Messages (1:1)                                      │
│  ┌─────────┐         ┌─────────┐                           │
│  │ Agent A │◀───────▶│ Agent B │                           │
│  └─────────┘   msg   └─────────┘                           │
│                                                             │
│  Broadcast (1:N)                                            │
│  ┌─────────┐    msg    ┌─────────┐                         │
│  │ Agent A │──────────▶│ Agent B │                         │
│  └─────────┘     │     └─────────┘                         │
│                  │     ┌─────────┐                         │
│                  └────▶│ Agent C │                         │
│                        └─────────┘                         │
│                                                             │
│  Pub/Sub (Topic-based)                                      │
│  ┌─────────┐           ┌───────────┐         ┌─────────┐  │
│  │Publisher│──publish─▶│  Topic    │──notify─▶│Subscriber│  │
│  └─────────┘           │ "tasks"   │         └─────────┘  │
│                        └───────────┘                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧠 Memory Architecture

### Memory Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                   MEMORY HIERARCHY                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  WORKING MEMORY                      │   │
│  │                   (Redis, <1ms)                      │   │
│  │                                                      │   │
│  │  • Current context                                   │   │
│  │  • Active task state                                 │   │
│  │  • Recent interactions                               │   │
│  │  TTL: 24 hours                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 EPISODIC MEMORY                      │   │
│  │                 (PostgreSQL, <10ms)                  │   │
│  │                                                      │   │
│  │  • Interaction history                               │   │
│  │  • Task completions                                  │   │
│  │  • Event sequences                                   │   │
│  │  TTL: 30 days                                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 SEMANTIC MEMORY                      │   │
│  │                 (Pinecone, <100ms)                   │   │
│  │                                                      │   │
│  │  • Knowledge embeddings                              │   │
│  │  • Concept relationships                             │   │
│  │  • Learned patterns                                  │   │
│  │  TTL: Forever                                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 ARCHIVAL MEMORY                      │   │
│  │                    (R2/S3, <1s)                      │   │
│  │                                                      │   │
│  │  • Full conversation logs                            │   │
│  │  • Large documents                                   │   │
│  │  • Historical data                                   │   │
│  │  TTL: Forever (cold storage)                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### PS-SHA∞ Hash Chain

```
┌──────────────────────────────────────────────────────────────┐
│                    PS-SHA∞ MEMORY CHAIN                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Entry 1          Entry 2          Entry 3          Entry N  │
│  ┌──────┐        ┌──────┐        ┌──────┐        ┌──────┐  │
│  │ Data │        │ Data │        │ Data │        │ Data │  │
│  │ Hash │───────▶│ Hash │───────▶│ Hash │───────▶│ Hash │  │
│  │ Time │  prev  │ Time │  prev  │ Time │  prev  │ Time │  │
│  └──────┘  hash  └──────┘  hash  └──────┘  hash  └──────┘  │
│                                                              │
│  Hash Formula:                                               │
│  hash[n] = SHA256(data[n] + hash[n-1] + timestamp[n])       │
│                                                              │
│  Properties:                                                 │
│  • Tamper-evident: Any modification breaks the chain         │
│  • Append-only: Cannot insert or delete entries              │
│  • Verifiable: Can prove integrity at any point              │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🌐 Infrastructure Architecture

### Multi-Cloud Deployment

```
┌─────────────────────────────────────────────────────────────┐
│                  MULTI-CLOUD ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   CLOUDFLARE                         │   │
│  │                                                      │   │
│  │  • Edge Workers (75+)                               │   │
│  │  • KV Storage                                       │   │
│  │  • D1 Database                                      │   │
│  │  • R2 Object Storage                                │   │
│  │  • Tunnel (QUIC)                                    │   │
│  │  • DNS Management                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│         ┌─────────────────┼─────────────────┐              │
│         ▼                 ▼                 ▼              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐      │
│  │   RAILWAY   │   │   VERCEL    │   │DIGITALOCEAN │      │
│  │             │   │             │   │             │      │
│  │ • GPU (H100)│   │ • Next.js   │   │ • Droplets  │      │
│  │ • vLLM      │   │ • Edge      │   │ • Volumes   │      │
│  │ • K8s       │   │ • Analytics │   │ • Spaces    │      │
│  └─────────────┘   └─────────────┘   └─────────────┘      │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   EDGE DEVICES                       │   │
│  │                                                      │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │   │
│  │  │ Pi: 38  │  │ Pi: 64  │  │ Pi: 99  │             │   │
│  │  │ lucidia │  │blackroad│  │lucidia- │             │   │
│  │  │         │  │   -pi   │  │   alt   │             │   │
│  │  └─────────┘  └─────────┘  └─────────┘             │   │
│  │                                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    NETWORK TOPOLOGY                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                        INTERNET                             │
│                           │                                 │
│                    ┌──────▼──────┐                         │
│                    │  Cloudflare │                         │
│                    │    Edge     │                         │
│                    └──────┬──────┘                         │
│                           │                                 │
│            ┌──────────────┼──────────────┐                 │
│            │              │              │                 │
│     ┌──────▼──────┐┌──────▼──────┐┌──────▼──────┐        │
│     │   US-WEST   ││   US-EAST   ││     EU      │        │
│     │             ││             ││             │        │
│     │ • Railway   ││ • Railway   ││ • Railway   │        │
│     │ • Workers   ││ • Workers   ││ • Workers   │        │
│     └──────┬──────┘└──────┬──────┘└──────┬──────┘        │
│            │              │              │                 │
│            └──────────────┼──────────────┘                 │
│                           │                                 │
│                    ┌──────▼──────┐                         │
│                    │   Internal  │                         │
│                    │   Network   │                         │
│                    └──────┬──────┘                         │
│                           │                                 │
│     ┌─────────────────────┼─────────────────────┐         │
│     │                     │                     │         │
│     ▼                     ▼                     ▼         │
│  ┌──────┐            ┌──────┐            ┌──────┐        │
│  │  DB  │            │Redis │            │Pinecone       │
│  │ (PG) │            │Cluster            │              │
│  └──────┘            └──────┘            └──────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Architecture

### Defense in Depth

```
┌─────────────────────────────────────────────────────────────┐
│                  SECURITY LAYERS                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: Edge Security                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • DDoS Protection (Cloudflare)                      │   │
│  │ • WAF Rules                                         │   │
│  │ • Bot Management                                    │   │
│  │ • Rate Limiting                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│  Layer 2: Transport Security                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • TLS 1.3 Everywhere                                │   │
│  │ • mTLS for Service-to-Service                       │   │
│  │ • Certificate Pinning                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│  Layer 3: Application Security                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • JWT Authentication                                │   │
│  │ • RBAC Authorization                                │   │
│  │ • Input Validation                                  │   │
│  │ • Output Encoding                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│  Layer 4: Data Security                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ • Encryption at Rest (AES-256)                      │   │
│  │ • Encryption in Transit (TLS)                       │   │
│  │ • Key Management (Vault)                            │   │
│  │ • Data Masking                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Observability Architecture

### Metrics, Logs, Traces

```
┌─────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY STACK                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     METRICS                          │   │
│  │                   (Prometheus)                       │   │
│  │                                                      │   │
│  │  • Request latency                                   │   │
│  │  • Error rates                                       │   │
│  │  • Agent counts                                      │   │
│  │  • Resource utilization                              │   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                      LOGS                            │   │
│  │                (Structured JSON)                     │   │
│  │                                                      │   │
│  │  • Application logs                                  │   │
│  │  • Access logs                                       │   │
│  │  • Audit logs                                        │   │
│  │  • Error logs                                        │   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     TRACES                           │   │
│  │                 (OpenTelemetry)                      │   │
│  │                                                      │   │
│  │  • Distributed tracing                               │   │
│  │  • Request flow                                      │   │
│  │  • Service dependencies                              │   │
│  │  • Performance bottlenecks                           │   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │                                 │
│                    ┌──────▼──────┐                         │
│                    │   Grafana   │                         │
│                    │ Dashboards  │                         │
│                    └─────────────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Appendix

### Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Next.js 16, React 19 | Web application |
| CLI | Rust, Clap | Command line |
| API Gateway | Cloudflare Workers | Edge routing |
| Backend | Python, FastAPI | Services |
| ML Inference | vLLM, PyTorch | Model serving |
| Database | PostgreSQL | Primary data |
| Cache | Redis | Session/cache |
| Vector DB | Pinecone | Embeddings |
| Object Storage | Cloudflare R2 | Files |
| Monitoring | Prometheus, Grafana | Observability |

---

*Last updated: 2026-02-05*
