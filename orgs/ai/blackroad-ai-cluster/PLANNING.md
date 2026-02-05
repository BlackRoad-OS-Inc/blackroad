# BlackRoad AI Cluster - Planning

> Development planning for GPU cluster orchestration

## Vision

Build an intelligent GPU cluster management system with:
- Automatic workload scheduling
- Cost optimization
- Multi-cloud GPU provisioning
- Real-time monitoring

---

## Cluster Inventory

### Current Resources

| Provider | GPU Type | Count | Memory | Status |
|----------|----------|-------|--------|--------|
| Railway | A100 | 1 | 80GB | ✅ Active |
| Local | RTX 4090 | 1 | 24GB | ✅ Active |
| - | - | - | - | - |

### Target Resources (Q2 2026)

| Provider | GPU Type | Count | Memory | Purpose |
|----------|----------|-------|--------|---------|
| Railway | H100 | 8 | 640GB | Production |
| Railway | A100 | 4 | 320GB | Staging |
| Local | RTX 4090 | 2 | 48GB | Development |
| Spot | Mixed | 10+ | Varies | Burst |

---

## Current Sprint

### Sprint 2026-02

#### Goals
- [ ] Design cluster scheduler
- [ ] Implement GPU health monitoring
- [ ] Create cost optimization rules
- [ ] Build admin dashboard

#### Tasks

| Task | Priority | Status | Est. |
|------|----------|--------|------|
| Scheduler architecture | P0 | 🔄 In Progress | 3d |
| Health check system | P0 | 📋 Planned | 2d |
| Cost tracking | P1 | 📋 Planned | 2d |
| Dashboard UI | P2 | 📋 Planned | 4d |

---

## Scheduler Design

### Job Queue

```
┌─────────────────────────────────────────────────────────────┐
│                    JOB SCHEDULER                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                    Job Queue                          │ │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │ │
│  │  │ Job 1  │ │ Job 2  │ │ Job 3  │ │ Job N  │        │ │
│  │  │ P: Hi  │ │ P: Med │ │ P: Low │ │ P: Med │        │ │
│  │  │ GPU: 4 │ │ GPU: 1 │ │ GPU: 2 │ │ GPU: 8 │        │ │
│  │  └────────┘ └────────┘ └────────┘ └────────┘        │ │
│  └───────────────────────────────────────────────────────┘ │
│                           │                                 │
│                           ▼                                 │
│  ┌───────────────────────────────────────────────────────┐ │
│  │                   Scheduler                           │ │
│  │                                                       │ │
│  │  Rules:                                               │ │
│  │  1. Priority: Hi > Med > Low                         │ │
│  │  2. GPU fit: Find smallest fit                       │ │
│  │  3. Locality: Prefer same node                       │ │
│  │  4. Cost: Use spot for low priority                  │ │
│  └───────────────────────────────────────────────────────┘ │
│                           │                                 │
│         ┌─────────────────┼─────────────────┐              │
│         ▼                 ▼                 ▼              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐      │
│  │  Node 1     │   │  Node 2     │   │  Node 3     │      │
│  │  H100 x4    │   │  H100 x4    │   │  A100 x4    │      │
│  └─────────────┘   └─────────────┘   └─────────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Scheduling Algorithm

```python
def schedule_job(job):
    # 1. Find eligible nodes
    eligible = [n for n in nodes if n.available_gpus >= job.gpu_count]

    # 2. Apply scheduling rules
    if job.priority == "high":
        # Use dedicated nodes
        eligible = [n for n in eligible if n.type == "dedicated"]
    elif job.priority == "low":
        # Prefer spot instances
        eligible = sorted(eligible, key=lambda n: n.cost_per_gpu)

    # 3. Select best fit
    node = min(eligible, key=lambda n: n.available_gpus - job.gpu_count)

    # 4. Schedule
    return node.schedule(job)
```

---

## Cost Optimization

### Pricing (per hour)

| GPU | Dedicated | Spot | Savings |
|-----|-----------|------|---------|
| H100 | $4.00 | $1.20 | 70% |
| A100 | $2.50 | $0.75 | 70% |
| A10 | $1.00 | $0.30 | 70% |

### Optimization Strategies

1. **Spot Instance Usage**
   - Use for batch jobs
   - Implement checkpointing
   - Auto-migrate on preemption

2. **Auto-Scaling**
   - Scale down during low usage
   - Pre-warm before peak hours
   - Right-size instances

3. **Job Consolidation**
   - Batch similar jobs
   - Multi-tenant GPU sharing
   - Time-based scheduling

### Monthly Cost Targets

| Month | Current | Target | Savings |
|-------|---------|--------|---------|
| Feb 2026 | $2,000 | $2,000 | - |
| Mar 2026 | $5,000 | $4,000 | 20% |
| Apr 2026 | $10,000 | $7,500 | 25% |
| May 2026 | $15,000 | $10,500 | 30% |

---

## Health Monitoring

### Metrics Collected

| Metric | Interval | Alert |
|--------|----------|-------|
| GPU utilization | 10s | <20% |
| GPU memory | 10s | >95% |
| GPU temperature | 30s | >85°C |
| Job duration | On complete | >SLA |
| Error rate | 1m | >1% |

### Health Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                   GPU CLUSTER HEALTH                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  NODE           GPU    UTIL   MEM    TEMP   JOBS   STATUS  │
│  ───────────────────────────────────────────────────────── │
│  railway-h100-1  H100   87%   72GB   68°C    3    ● Online │
│  railway-h100-2  H100   92%   75GB   71°C    4    ● Online │
│  railway-a100-1  A100   45%   32GB   55°C    1    ● Online │
│  local-4090-1    4090   0%    0GB    42°C    0    ○ Idle   │
│                                                             │
│  CLUSTER TOTALS                                            │
│  ─────────────                                             │
│  Total GPUs: 12      Active Jobs: 8                        │
│  Total Memory: 464GB  Queue Depth: 15                      │
│  Avg Utilization: 74%  Est. Wait: 12min                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## API Design

### Endpoints

```
POST /jobs              # Submit job
GET  /jobs              # List jobs
GET  /jobs/:id          # Job details
DELETE /jobs/:id        # Cancel job

GET  /nodes             # List nodes
GET  /nodes/:id         # Node details
POST /nodes/:id/drain   # Drain node

GET  /cluster/status    # Cluster overview
GET  /cluster/costs     # Cost breakdown
POST /cluster/scale     # Scale cluster
```

### Job Spec

```yaml
job:
  name: "llama-70b-inference"
  image: "blackroad/vllm:latest"
  gpu_count: 4
  gpu_type: "H100"
  priority: "high"
  timeout: 3600
  env:
    MODEL: "meta-llama/Llama-2-70b"
  resources:
    memory: "256Gi"
    cpu: "32"
```

---

*Last updated: 2026-02-05*
