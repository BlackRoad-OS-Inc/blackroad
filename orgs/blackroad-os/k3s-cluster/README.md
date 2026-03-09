# BlackRoad K3s Cluster

**Lightweight Kubernetes for Pi Fleet**

## Cluster Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Control Plane                          │
│                      (Cecilia)                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │  etcd    │  │  API     │  │  Sched   │               │
│  └──────────┘  └──────────┘  └──────────┘               │
└──────────────────────────────────────────────────────────┘
         │              │              │
    ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
    │ Lucidia │    │  Alice  │    │  Aria   │
    │ (Agent) │    │ (Agent) │    │ (Agent) │
    └─────────┘    └─────────┘    └─────────┘
```

## Quick Install

### Control Plane (Cecilia)
```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-init \
  --disable traefik \
  --flannel-backend=wireguard-native
```

### Agent Nodes
```bash
# Get token from Cecilia
TOKEN=$(ssh cecilia "cat /var/lib/rancher/k3s/server/node-token")

# Join cluster
curl -sfL https://get.k3s.io | K3S_URL=https://cecilia:6443 K3S_TOKEN=$TOKEN sh -
```

## Configuration

### k3s-server.yaml
```yaml
# /etc/rancher/k3s/config.yaml
cluster-init: true
disable:
  - traefik
flannel-backend: wireguard-native
node-label:
  - "blackroad.io/role=control-plane"
  - "blackroad.io/device=pi5"
tls-san:
  - "cecilia"
  - "k8s.blackroad.io"
```

## Storage

```bash
# Install Longhorn for distributed storage
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml
```

## GPU Support (Hailo-8)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hailo-workload
spec:
  containers:
  - name: inference
    resources:
      limits:
        hailo.ai/h8: 1
```

## Monitoring

```bash
kubectl apply -f monitoring/
```

---

*BlackRoad OS - Edge Kubernetes at Scale*
