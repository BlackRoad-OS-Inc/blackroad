# BlackRoad OS Monitoring & Observability

> Complete guide to monitoring, logging, and alerting in BlackRoad OS

---

## Table of Contents

- [Overview](#overview)
- [Metrics](#metrics)
- [Logging](#logging)
- [Tracing](#tracing)
- [Alerting](#alerting)
- [Dashboards](#dashboards)
- [Health Checks](#health-checks)
- [Performance Monitoring](#performance-monitoring)
- [Cost Monitoring](#cost-monitoring)
- [Incident Response](#incident-response)

---

## Overview

BlackRoad OS uses the **Three Pillars of Observability**: Metrics, Logs, and Traces. This enables full visibility into system behavior, agent performance, and user experience.

### Observability Stack

```
┌──────────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY STACK                           │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐            │
│  │  METRICS   │    │   LOGS     │    │   TRACES   │            │
│  │            │    │            │    │            │            │
│  │ Prometheus │    │   Loki     │    │   Jaeger   │            │
│  │ + Grafana  │    │ + Grafana  │    │            │            │
│  └─────┬──────┘    └─────┬──────┘    └─────┬──────┘            │
│        │                 │                 │                    │
│        └────────────────┬┴─────────────────┘                    │
│                         │                                        │
│                         ▼                                        │
│                   ┌──────────┐                                  │
│                   │ GRAFANA  │                                  │
│                   │Dashboard │                                  │
│                   └────┬─────┘                                  │
│                        │                                        │
│                        ▼                                        │
│                   ┌──────────┐                                  │
│                   │ ALERTING │                                  │
│                   │          │                                  │
│                   │PagerDuty │                                  │
│                   │  Slack   │                                  │
│                   │  Email   │                                  │
│                   └──────────┘                                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Quick Status Commands

```bash
# Full system health
./health.sh

# Infrastructure mesh status
./blackroad-mesh.sh

# Agent status
./status.sh

# Recent logs
./logs.sh

# Metrics snapshot
./metrics.sh
```

---

## Metrics

### Metric Types

| Type | Description | Example |
|------|-------------|---------|
| **Counter** | Monotonically increasing | `requests_total` |
| **Gauge** | Can go up or down | `active_agents` |
| **Histogram** | Distribution of values | `request_duration` |
| **Summary** | Similar to histogram | `response_size` |

### Core Metrics

```python
# metrics.py
from prometheus_client import Counter, Gauge, Histogram

# Agent metrics
AGENTS_ACTIVE = Gauge(
    'blackroad_agents_active',
    'Number of active agents',
    ['type']
)

AGENT_TASKS_TOTAL = Counter(
    'blackroad_agent_tasks_total',
    'Total tasks processed by agents',
    ['agent', 'status']
)

AGENT_TASK_DURATION = Histogram(
    'blackroad_agent_task_duration_seconds',
    'Task duration in seconds',
    ['agent', 'task_type'],
    buckets=[.1, .25, .5, 1, 2.5, 5, 10, 30, 60]
)

# Memory metrics
MEMORY_USAGE_BYTES = Gauge(
    'blackroad_memory_usage_bytes',
    'Memory usage in bytes',
    ['tier']
)

MEMORY_OPERATIONS_TOTAL = Counter(
    'blackroad_memory_operations_total',
    'Total memory operations',
    ['tier', 'operation']
)

# API metrics
API_REQUESTS_TOTAL = Counter(
    'blackroad_api_requests_total',
    'Total API requests',
    ['method', 'endpoint', 'status']
)

API_REQUEST_DURATION = Histogram(
    'blackroad_api_request_duration_seconds',
    'API request duration',
    ['method', 'endpoint']
)
```

### Instrumenting Code

```python
import time
from metrics import AGENT_TASKS_TOTAL, AGENT_TASK_DURATION

async def process_task(agent, task):
    start_time = time.time()

    try:
        result = await agent.execute(task)
        AGENT_TASKS_TOTAL.labels(
            agent=agent.name,
            status='success'
        ).inc()
        return result

    except Exception as e:
        AGENT_TASKS_TOTAL.labels(
            agent=agent.name,
            status='error'
        ).inc()
        raise

    finally:
        duration = time.time() - start_time
        AGENT_TASK_DURATION.labels(
            agent=agent.name,
            task_type=task.type
        ).observe(duration)
```

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: 'blackroad-api'
    static_configs:
      - targets: ['api:8000']
    metrics_path: /metrics

  - job_name: 'blackroad-agents'
    static_configs:
      - targets: ['agents:8001']

  - job_name: 'blackroad-memory'
    static_configs:
      - targets: ['memory:8002']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

### Key Metrics to Monitor

| Metric | Warning | Critical | Description |
|--------|---------|----------|-------------|
| `agents_active` | <10 | <5 | Active agents |
| `task_queue_length` | >100 | >500 | Pending tasks |
| `error_rate` | >1% | >5% | Error percentage |
| `p99_latency` | >1s | >5s | 99th percentile |
| `memory_usage` | >80% | >95% | Memory utilization |
| `cpu_usage` | >70% | >90% | CPU utilization |

---

## Logging

### Log Levels

| Level | Use Case |
|-------|----------|
| `DEBUG` | Detailed debugging information |
| `INFO` | General operational information |
| `WARNING` | Unexpected but handled situations |
| `ERROR` | Errors that need attention |
| `CRITICAL` | System failures requiring immediate action |

### Structured Logging

```python
import structlog

logger = structlog.get_logger()

# Basic logging
logger.info("Task started", task_id="task_123", agent="ALICE")

# With context
logger = logger.bind(request_id="req_456")
logger.info("Processing request")
logger.error("Request failed", error="timeout")

# Agent-specific logging
agent_logger = logger.bind(
    agent_name="ALICE",
    agent_type="worker"
)
agent_logger.info("Agent initialized")
```

### Log Format

```json
{
  "timestamp": "2026-02-05T12:00:00.000Z",
  "level": "INFO",
  "message": "Task completed",
  "context": {
    "request_id": "req_456",
    "agent_name": "ALICE",
    "task_id": "task_123",
    "duration_ms": 1234
  },
  "trace_id": "abc123def456",
  "span_id": "span_789"
}
```

### Logging Configuration

```yaml
# config/logging.yaml
logging:
  level: INFO
  format: json

  handlers:
    - type: console
      level: DEBUG

    - type: file
      path: /var/log/blackroad/app.log
      max_size: 100MB
      backup_count: 10

    - type: loki
      url: http://loki:3100
      labels:
        app: blackroad
        environment: production

  loggers:
    blackroad.agents:
      level: DEBUG
    blackroad.memory:
      level: INFO
    blackroad.api:
      level: INFO
```

### Log Aggregation with Loki

```yaml
# loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1

schema_config:
  configs:
    - from: 2026-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
  filesystem:
    directory: /loki/chunks
```

### Querying Logs

```bash
# View recent logs
./logs.sh

# Filter by level
./logs.sh --level error

# Filter by agent
./logs.sh --agent ALICE

# Filter by time
./logs.sh --since "1h"

# Search logs
./logs.sh --grep "task failed"
```

**Loki Queries (LogQL):**

```logql
# All errors in last hour
{app="blackroad"} |= "error" | json

# Agent-specific logs
{app="blackroad", agent="ALICE"} | json | level="ERROR"

# Request latency > 1s
{app="blackroad"} | json | duration_ms > 1000

# Count errors by agent
sum by (agent_name) (count_over_time({app="blackroad"} |= "error" [1h]))
```

---

## Tracing

### Distributed Tracing

```
┌─────────────────────────────────────────────────────────────────┐
│                     REQUEST TRACE                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ API Gateway (50ms)                                      │    │
│  │ trace_id: abc123                                        │    │
│  └──────────────────────────┬─────────────────────────────┘    │
│                              │                                  │
│       ┌──────────────────────┴──────────────────────┐          │
│       ▼                                              ▼          │
│  ┌──────────────┐                           ┌──────────────┐   │
│  │ Agent ALICE  │                           │ Memory Store │   │
│  │ (200ms)      │                           │ (30ms)       │   │
│  └──────┬───────┘                           └──────────────┘   │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                              │
│  │ Skill: Code  │                                              │
│  │ (150ms)      │                                              │
│  └──────────────┘                                              │
│                                                                 │
│  Total: 430ms                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### OpenTelemetry Setup

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter

# Setup tracer
provider = TracerProvider()
jaeger = JaegerExporter(
    agent_host_name="jaeger",
    agent_port=6831
)
provider.add_span_processor(BatchSpanProcessor(jaeger))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("blackroad")
```

### Instrumenting with Traces

```python
from opentelemetry import trace

tracer = trace.get_tracer("blackroad.agents")

async def process_request(request):
    with tracer.start_as_current_span("process_request") as span:
        span.set_attribute("request.id", request.id)
        span.set_attribute("request.type", request.type)

        # Sub-span for agent work
        with tracer.start_as_current_span("agent_execute") as agent_span:
            agent_span.set_attribute("agent.name", "ALICE")
            result = await agent.execute(request)
            agent_span.set_attribute("result.status", result.status)

        # Sub-span for memory storage
        with tracer.start_as_current_span("memory_store") as mem_span:
            mem_span.set_attribute("memory.tier", "working")
            await memory.store(result)

        return result
```

### Jaeger Configuration

```yaml
# jaeger-config.yaml
collector:
  zipkin:
    host-port: :9411
  grpc:
    host-port: :14250

query:
  base-path: /jaeger

storage:
  type: elasticsearch
  elasticsearch:
    server-urls: http://elasticsearch:9200
```

### Trace Context Propagation

```python
from opentelemetry.propagate import inject, extract

# Inject context into outgoing request
headers = {}
inject(headers)
response = await http_client.get(url, headers=headers)

# Extract context from incoming request
context = extract(request.headers)
with tracer.start_as_current_span("handle_request", context=context):
    process_request()
```

---

## Alerting

### Alert Rules

```yaml
# alerts/blackroad.rules.yml
groups:
  - name: blackroad
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          sum(rate(blackroad_api_requests_total{status=~"5.."}[5m])) /
          sum(rate(blackroad_api_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }}"

      # Low active agents
      - alert: LowActiveAgents
        expr: blackroad_agents_active < 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low number of active agents"
          description: "Only {{ $value }} agents are active"

      # High latency
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99,
            rate(blackroad_api_request_duration_seconds_bucket[5m])
          ) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High API latency"
          description: "P99 latency is {{ $value }}s"

      # Memory usage high
      - alert: HighMemoryUsage
        expr: |
          blackroad_memory_usage_bytes / blackroad_memory_limit_bytes > 0.9
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage"
          description: "Memory usage is at {{ $value | humanizePercentage }}"

      # Task queue backing up
      - alert: TaskQueueBacklog
        expr: blackroad_task_queue_length > 500
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "Task queue backlog"
          description: "{{ $value }} tasks in queue"
```

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  slack_api_url: ${SLACK_WEBHOOK_URL}
  pagerduty_url: 'https://events.pagerduty.com/v2/enqueue'

route:
  receiver: 'default'
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'

    - match:
        severity: warning
      receiver: 'slack-warnings'

receivers:
  - name: 'default'
    slack_configs:
      - channel: '#alerts'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - routing_key: ${PAGERDUTY_ROUTING_KEY}
        severity: critical

  - name: 'slack-warnings'
    slack_configs:
      - channel: '#alerts-warnings'
        send_resolved: true
```

### Custom Alerts

```python
from blackroad.alerting import AlertManager

alerter = AlertManager()

# Send alert
await alerter.send(
    name="CustomAlert",
    severity="warning",
    message="Something unusual detected",
    labels={"component": "memory"},
    annotations={
        "description": "Memory consolidation taking longer than expected",
        "runbook": "https://docs.blackroad.io/runbooks/memory"
    }
)

# Resolve alert
await alerter.resolve("CustomAlert", labels={"component": "memory"})
```

---

## Dashboards

### Grafana Dashboard Structure

```
BlackRoad Dashboards
├── Overview
│   ├── System health
│   ├── Active agents
│   ├── Request rate
│   └── Error rate
├── Agents
│   ├── Agent status
│   ├── Task throughput
│   ├── Task duration
│   └── Agent errors
├── Memory
│   ├── Memory usage by tier
│   ├── Operations per second
│   ├── Search latency
│   └── Consolidation status
├── API
│   ├── Request rate
│   ├── Response times
│   ├── Error breakdown
│   └── Top endpoints
├── Infrastructure
│   ├── CPU/Memory usage
│   ├── Network traffic
│   ├── Disk I/O
│   └── Service health
└── Business
    ├── Tasks completed
    ├── User activity
    └── Cost metrics
```

### Dashboard JSON Example

```json
{
  "title": "BlackRoad Overview",
  "panels": [
    {
      "title": "Active Agents",
      "type": "stat",
      "targets": [
        {
          "expr": "sum(blackroad_agents_active)",
          "legendFormat": "Agents"
        }
      ]
    },
    {
      "title": "Request Rate",
      "type": "graph",
      "targets": [
        {
          "expr": "sum(rate(blackroad_api_requests_total[5m]))",
          "legendFormat": "Requests/s"
        }
      ]
    },
    {
      "title": "Error Rate",
      "type": "gauge",
      "targets": [
        {
          "expr": "sum(rate(blackroad_api_requests_total{status=~\"5..\"}[5m])) / sum(rate(blackroad_api_requests_total[5m])) * 100",
          "legendFormat": "Error %"
        }
      ],
      "thresholds": {
        "steps": [
          {"color": "green", "value": 0},
          {"color": "yellow", "value": 1},
          {"color": "red", "value": 5}
        ]
      }
    }
  ]
}
```

### Grafana Provisioning

```yaml
# grafana/provisioning/dashboards/dashboards.yaml
apiVersion: 1
providers:
  - name: 'BlackRoad'
    orgId: 1
    folder: 'BlackRoad'
    type: file
    disableDeletion: false
    editable: true
    options:
      path: /var/lib/grafana/dashboards
```

---

## Health Checks

### Health Check Endpoints

```python
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class HealthStatus(BaseModel):
    status: str
    version: str
    uptime: float
    checks: dict

@app.get("/health")
async def health_check():
    checks = {
        "database": await check_database(),
        "redis": await check_redis(),
        "agents": await check_agents(),
        "memory": await check_memory()
    }

    status = "healthy" if all(c["healthy"] for c in checks.values()) else "unhealthy"

    return HealthStatus(
        status=status,
        version="1.2.3",
        uptime=get_uptime(),
        checks=checks
    )

@app.get("/health/live")
async def liveness():
    """Kubernetes liveness probe."""
    return {"status": "alive"}

@app.get("/health/ready")
async def readiness():
    """Kubernetes readiness probe."""
    if await is_ready():
        return {"status": "ready"}
    return Response(status_code=503)
```

### Health Check Configuration

```yaml
# health-checks.yaml
health_checks:
  - name: database
    type: tcp
    host: postgres
    port: 5432
    timeout: 5s
    interval: 10s

  - name: redis
    type: redis
    host: redis
    port: 6379
    timeout: 3s
    interval: 5s

  - name: ollama
    type: http
    url: http://localhost:11434/api/tags
    timeout: 5s
    interval: 30s

  - name: api
    type: http
    url: http://localhost:8000/health
    timeout: 5s
    interval: 10s
    expected_status: 200
```

### CLI Health Check

```bash
./health.sh

# Output:
# BlackRoad Health Check
# =====================
#
# System Status: HEALTHY
#
# Components:
# ├── API              [OK] 200ms
# ├── Database         [OK] 15ms
# ├── Redis            [OK] 2ms
# ├── Ollama           [OK] 50ms
# ├── Memory Service   [OK] 25ms
# └── Agent Service    [OK] 30ms
#
# Agents:
# ├── LUCIDIA          [ONLINE] idle
# ├── ALICE            [ONLINE] busy (3 tasks)
# ├── OCTAVIA          [ONLINE] idle
# ├── PRISM            [ONLINE] idle
# ├── ECHO             [ONLINE] idle
# └── CIPHER           [ONLINE] idle
#
# Resources:
# ├── CPU              23% (4 cores)
# ├── Memory           4.2GB / 16GB (26%)
# ├── Disk             45GB / 200GB (22%)
# └── Network          12 Mbps in / 5 Mbps out
```

---

## Performance Monitoring

### APM (Application Performance Monitoring)

```python
from blackroad.monitoring import APM

apm = APM()

@apm.trace
async def critical_operation():
    # Automatically traced
    pass

# Manual instrumentation
with apm.transaction("process_batch"):
    for item in items:
        with apm.span("process_item"):
            process(item)
```

### Performance Metrics

```python
# Track custom metrics
from blackroad.monitoring import metrics

# Timer
with metrics.timer("operation_duration"):
    perform_operation()

# Counter
metrics.increment("operations_total", tags={"type": "read"})

# Gauge
metrics.gauge("queue_depth", len(queue))

# Histogram
metrics.histogram("response_size", len(response))
```

### Performance Baselines

| Operation | P50 | P95 | P99 | Target |
|-----------|-----|-----|-----|--------|
| API Request | 50ms | 150ms | 300ms | <500ms |
| Agent Task | 500ms | 2s | 5s | <10s |
| Memory Read | 5ms | 20ms | 50ms | <100ms |
| Memory Write | 10ms | 50ms | 100ms | <200ms |
| Search | 50ms | 200ms | 500ms | <1s |

### Profiling

```python
import cProfile
import pstats

# Profile function
profiler = cProfile.Profile()
profiler.enable()

# Run code
result = expensive_operation()

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(20)
```

---

## Cost Monitoring

### Cloud Cost Tracking

```yaml
# cost-monitoring.yaml
cost_tracking:
  enabled: true

  providers:
    cloudflare:
      enabled: true
      budget: 500  # USD/month

    railway:
      enabled: true
      budget: 1000

    vercel:
      enabled: true
      budget: 200

    digitalocean:
      enabled: true
      budget: 100

  alerts:
    - threshold: 80  # % of budget
      action: slack
      channel: "#cost-alerts"

    - threshold: 100
      action: pagerduty
      severity: warning
```

### Cost Dashboard

```
Monthly Cost Overview
=====================

Provider          Budget    Spent    Remaining    Status
---------         ------    -----    ---------    ------
Cloudflare        $500      $342     $158         OK
Railway           $1000     $867     $133         WARNING
Vercel            $200      $156     $44          OK
DigitalOcean      $100      $85      $15          WARNING
---------         ------    -----    ---------
Total             $1800     $1450    $350         OK

Projected End of Month: $1,820 (1% over budget)
```

### Resource Optimization

```python
from blackroad.monitoring import CostOptimizer

optimizer = CostOptimizer()

# Get recommendations
recommendations = await optimizer.analyze()

for rec in recommendations:
    print(f"[{rec.priority}] {rec.title}")
    print(f"  Potential savings: ${rec.savings}/month")
    print(f"  Action: {rec.action}")
```

---

## Incident Response

### Incident Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   DETECT    │────▶│   TRIAGE    │────▶│  RESPOND    │
│             │     │             │     │             │
│ • Alerts    │     │ • Severity  │     │ • Mitigate  │
│ • Anomaly   │     │ • Impact    │     │ • Fix       │
│ • User      │     │ • Assign    │     │ • Verify    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌─────────────┐     ┌──────▼──────┐
                    │   REVIEW    │◀────│   RESOLVE   │
                    │             │     │             │
                    │ • RCA       │     │ • Close     │
                    │ • Action    │     │ • Document  │
                    │ • Improve   │     │ • Notify    │
                    └─────────────┘     └─────────────┘
```

### Incident Severity Levels

| Level | Response Time | Examples |
|-------|--------------|----------|
| **P1** | 15 min | System down, data loss |
| **P2** | 1 hour | Major feature broken |
| **P3** | 4 hours | Minor feature broken |
| **P4** | 24 hours | Cosmetic issues |

### Runbooks

```markdown
# High Error Rate Runbook

## Symptoms
- Error rate > 5%
- Alert: HighErrorRate

## Investigation
1. Check recent deployments: `./status.sh deployments`
2. View error logs: `./logs.sh --level error --since 1h`
3. Check external dependencies: `./health.sh`

## Mitigation
1. If recent deployment: `./rollback.sh`
2. If dependency issue: Enable fallback
3. If overload: Scale up

## Resolution
1. Identify root cause
2. Deploy fix
3. Verify metrics return to normal
4. Update this runbook if needed
```

### Status Page

```yaml
# statuspage.yaml
status_page:
  url: https://status.blackroad.io

  components:
    - name: API
      description: Core API services
    - name: Agents
      description: AI agent platform
    - name: Memory
      description: Memory and storage
    - name: Dashboard
      description: Web dashboard

  maintenance_windows:
    - component: API
      start: "2026-02-10T02:00:00Z"
      end: "2026-02-10T04:00:00Z"
      description: "Planned maintenance"
```

---

## Quick Reference

### CLI Commands

```bash
# Health and status
./health.sh              # Full health check
./status.sh              # System status
./blackroad-mesh.sh      # Infrastructure mesh

# Logs
./logs.sh                # Recent logs
./logs.sh --level error  # Error logs only
./logs.sh --agent ALICE  # Agent-specific logs

# Metrics
./metrics.sh             # Metrics snapshot
./metrics.sh --export    # Export to file

# Alerts
./alerts.sh              # Active alerts
./alerts.sh --resolve ID # Resolve alert
```

### Useful Queries

```promql
# Request rate
sum(rate(blackroad_api_requests_total[5m]))

# Error rate percentage
sum(rate(blackroad_api_requests_total{status=~"5.."}[5m])) /
sum(rate(blackroad_api_requests_total[5m])) * 100

# P99 latency
histogram_quantile(0.99,
  rate(blackroad_api_request_duration_seconds_bucket[5m]))

# Active agents by type
sum by (type) (blackroad_agents_active)

# Task throughput
sum(rate(blackroad_agent_tasks_total[5m]))
```

---

*Last updated: 2026-02-05*
