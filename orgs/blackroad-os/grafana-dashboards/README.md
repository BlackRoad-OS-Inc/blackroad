# BlackRoad Grafana Dashboards

**Pre-built dashboards for sovereign infrastructure**

## Available Dashboards

### Infrastructure
| Dashboard | ID | Description |
|-----------|-----|-------------|
| Cluster Overview | 1001 | K3s cluster health and resources |
| Node Metrics | 1002 | Per-node CPU, memory, disk, network |
| Pod Resources | 1003 | Pod resource consumption |

### AI/ML
| Dashboard | ID | Description |
|-----------|-----|-------------|
| vLLM Inference | 2001 | Inference latency, throughput, GPU |
| Ollama Models | 2002 | Model performance, memory |
| Hailo-8 Edge | 2003 | Edge inference metrics |

### Business
| Dashboard | ID | Description |
|-----------|-----|-------------|
| API Gateway | 3001 | Request rates, latencies, errors |
| Agent Activity | 3002 | Agent task completion, uptime |
| Cost Tracking | 3003 | Cloud spend, optimization |

## Installation

```bash
# Import dashboards
kubectl apply -f dashboards/
```

## Dashboard JSON Structure

```json
{
  "dashboard": {
    "title": "BlackRoad Cluster Overview",
    "uid": "blackroad-cluster",
    "panels": [...]
  },
  "overwrite": true,
  "folderId": 0
}
```

## Data Sources

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    type: loki
    url: http://loki:3100
```

## Provisioning

```yaml
# grafana.ini
[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/cluster-overview.json
```

---

*BlackRoad OS - Visual Intelligence*
