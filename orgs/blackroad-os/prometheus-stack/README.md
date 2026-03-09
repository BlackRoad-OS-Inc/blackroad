# BlackRoad Prometheus Stack

**Full observability for sovereign infrastructure**

## Components

- **Prometheus** - Metrics collection
- **Alertmanager** - Alert routing
- **Node Exporter** - System metrics
- **Blackbox Exporter** - Endpoint probing

## Quick Start

```bash
# Helm install
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f values.yaml
```

## Custom Metrics

### BlackRoad Agent Metrics
```yaml
- job_name: 'blackroad-agents'
  static_configs:
    - targets:
      - 'cecilia:9090'
      - 'lucidia:9090'
      - 'alice:9090'
      - 'aria:9090'
  metrics_path: /metrics
  relabel_configs:
    - source_labels: [__address__]
      target_label: instance
```

### AI Inference Metrics
```yaml
- job_name: 'vllm'
  static_configs:
    - targets: ['vllm:8000']
  metrics_path: /metrics
```

## Alerting Rules

```yaml
groups:
- name: blackroad
  rules:
  - alert: AgentDown
    expr: up{job="blackroad-agents"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Agent {{ $labels.instance }} is down"
      
  - alert: HighInferenceLatency
    expr: vllm_request_latency_seconds > 5
    for: 2m
    labels:
      severity: warning
```

## Storage

```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: longhorn
          resources:
            requests:
              storage: 100Gi
```

## Access

- Prometheus: http://prometheus.blackroad.io:9090
- Alertmanager: http://alertmanager.blackroad.io:9093

---

*BlackRoad OS - Observable Sovereignty*
