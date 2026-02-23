# Chimera — Milk-V Duo S Heterogeneous Compute Module

## Overview

Chimera is the BlackRoad OS heterogeneous compute module based on the **Milk-V Duo S** (SG2000 SoC).

## Hardware Specs

| Component | Spec |
|-----------|------|
| SoC | Sophgo SG2000 |
| CPU | RISC-V C906 @ 1GHz + ARM Cortex-A53 @ 1GHz |
| NPU | 1 TOPS @ INT8 |
| RAM | 512MB DDR3 |
| Storage | microSD + eMMC |
| IO | 2x USB, MIPI CSI, Ethernet |
| Price | ~$9 USD |

## Role in BlackRoad OS

- **Edge inference**: Run quantized models (ONNX, NCNN) locally
- **Vision processing**: Camera input → Pi → gateway
- **Sensor aggregation**: I2C/SPI peripherals
- **Failover compute**: Lightweight tasks when main Pis are busy

## Setup

```bash
# Flash Debian image to microSD
# Boot, then:
ssh root@192.168.4.xxx  # password: milkv

# Install BlackRoad agent
curl -fsSL https://install.blackroad.io | sh
br agent register --name chimera --type edge-compute
```

## Integration with Pi Fleet

```
[Chimera] --eth--> [alice Pi] --tunnel--> [Cloudflare] ---> [Internet]
              ↕ local mesh (192.168.4.x)
[aria Pi] <----> [alice Pi]
```

## Status: 🔜 Planned (Q2 2026)
