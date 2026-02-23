# Hydra — 4x Luckfox Pico Mini Swarm

## Overview

Hydra is a 4-node compute swarm built from **Luckfox Pico Mini** boards, designed for parallel agent workloads.

## Hardware (per node)

| Component | Spec |
|-----------|------|
| SoC | Rockchip RV1103 |
| CPU | ARM Cortex-A7 @ 1.2GHz |
| NPU | 0.5 TOPS |
| RAM | 64MB DDR2 |
| Storage | microSD |
| Size | Credit card (38×21mm) |
| Price | ~$6 USD |

## Swarm Configuration

```
Hydra Node 1 (192.168.4.70) — Worker
Hydra Node 2 (192.168.4.71) — Worker  
Hydra Node 3 (192.168.4.72) — Worker
Hydra Node 4 (192.168.4.73) — Coordinator
```

## Use Cases

- Parallel agent task execution (4 tasks simultaneously)
- Distributed memory shards (ECHO agent)
- Sensor network aggregation
- Low-power always-on monitoring

## Status: 🔜 Planned (Q3 2026)
