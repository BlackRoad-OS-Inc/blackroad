# BlackRoad AI Cluster

> GPU cluster orchestration for distributed AI inference

## Quick Reference

| Property | Value |
|----------|-------|
| **Type** | Cluster Manager |
| **GPUs** | A100, H100, RTX |
| **Platform** | Railway/Cloud |

## Features

- **GPU Scheduling**: Efficient resource allocation
- **Model Distribution**: Tensor parallelism
- **Auto-scaling**: Dynamic node management
- **Health Monitoring**: GPU utilization tracking

## Architecture

```
┌─────────────────────────────────────────────┐
│              Cluster Manager                 │
└──────────────────┬──────────────────────────┘
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
┌─────────┐   ┌─────────┐   ┌─────────┐
│ Node 1  │   │ Node 2  │   │ Node 3  │
│ A100 x4 │   │ H100 x2 │   │ RTX x8  │
└─────────┘   └─────────┘   └─────────┘
```

## GPU Nodes

| Provider | GPU | Memory | Use Case |
|----------|-----|--------|----------|
| Railway | A100 | 80GB | Large models |
| Railway | H100 | 80GB | Fastest inference |
| Local | RTX 4090 | 24GB | Development |

## API Endpoints

```
GET  /cluster/status     # Cluster overview
GET  /cluster/nodes      # List nodes
POST /cluster/schedule   # Schedule job
GET  /cluster/jobs       # Job status
POST /cluster/scale      # Scale cluster
```

## Job Scheduling

```yaml
job:
  name: inference-llama-70b
  model: meta-llama/Llama-2-70b
  gpus: 4
  priority: high
  timeout: 3600
```

## Environment Variables

```env
CLUSTER_API_URL=         # Cluster API
RAILWAY_TOKEN=           # Railway auth
NODE_SELECTOR=gpu=true   # Node selection
```

## Monitoring

- GPU utilization
- Memory usage
- Queue depth
- Job latency

## Related Repos

- `blackroad-vllm` - Inference engine
- `blackroad-ai-api-gateway` - API routing
- `blackroad-agents` - Job submission
