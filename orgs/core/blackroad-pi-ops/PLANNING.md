# BlackRoad Pi Ops - Planning

> Development planning for Raspberry Pi edge device management

## Vision

Create a robust edge computing network with:
- 10+ Raspberry Pi devices
- LED matrix displays
- Holographic projections
- Local AI inference

---

## Device Inventory

### Current Devices

| Device | IP | Status | Role |
|--------|----|----|------|
| lucidia | 192.168.4.38 | ✅ Online | Primary |
| blackroad-pi | 192.168.4.64 | ✅ Online | Secondary |
| lucidia-alt | 192.168.4.99 | ⚠️ Offline | Backup |
| iPhone Koder | 192.168.4.68 | ✅ Online | Mobile |

### Planned Devices

| Device | Role | Priority | ETA |
|--------|------|----------|-----|
| pi-display-01 | LED Matrix | P1 | Q1 |
| pi-holo-01 | Holographic | P2 | Q2 |
| pi-cluster-01-04 | Compute cluster | P2 | Q2 |
| jetson-nano-01 | GPU inference | P1 | Q1 |

---

## Current Sprint

### Sprint 2026-02

#### Goals
- [ ] Fix lucidia-alt connectivity
- [ ] Deploy LED bridge to all devices
- [ ] Implement remote OTA updates
- [ ] Add device health monitoring

#### Tasks

| Task | Priority | Status | Est. |
|------|----------|--------|------|
| Network diagnostics | P0 | 🔄 In Progress | 1d |
| LED bridge deployment | P1 | 📋 Planned | 2d |
| OTA update system | P1 | 📋 Planned | 3d |
| Health monitoring | P2 | 📋 Planned | 2d |

---

## Architecture

### Edge Network Topology

```
┌─────────────────────────────────────────────────────────────┐
│                    HOME NETWORK                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    ┌─────────────┐                         │
│                    │   Router    │                         │
│                    │192.168.4.1  │                         │
│                    └──────┬──────┘                         │
│                           │                                 │
│      ┌────────────────────┼────────────────────┐           │
│      │                    │                    │           │
│      ▼                    ▼                    ▼           │
│ ┌─────────┐         ┌─────────┐         ┌─────────┐       │
│ │ lucidia │         │blackroad│         │lucidia- │       │
│ │   .38   │         │  -pi.64 │         │ alt.99  │       │
│ └─────────┘         └─────────┘         └─────────┘       │
│      │                    │                    │           │
│      │              ┌─────┴─────┐              │           │
│      │              ▼           ▼              │           │
│      │         ┌────────┐ ┌────────┐          │           │
│      │         │LED Strip│ │Display │          │           │
│      │         └────────┘ └────────┘          │           │
│      │                                         │           │
│      └─────────────┐               ┌───────────┘           │
│                    ▼               ▼                       │
│              ┌─────────────────────────┐                   │
│              │   Cloudflare Tunnel     │                   │
│              │   (QUIC to Internet)    │                   │
│              └─────────────────────────┘                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## LED Features

### Current Capabilities
- Solid colors
- Basic patterns (rainbow, pulse)
- Brightness control
- Remote API control

### Planned Features

| Feature | Description | Priority |
|---------|-------------|----------|
| Agent status display | Show agent states | P0 |
| Task notifications | Flash on task complete | P1 |
| Music visualization | Audio reactive | P2 |
| Custom animations | User-defined patterns | P2 |

### LED API

```
POST /led/pattern
{
  "pattern": "agent_status",
  "agents": ["LUCIDIA", "ALICE", "OCTAVIA"],
  "brightness": 128
}

POST /led/notify
{
  "type": "task_complete",
  "color": "#00FF00",
  "duration_ms": 500
}
```

---

## Holographic Display

### Hardware
- Pepper's ghost illusion setup
- Transparent pyramid
- 4-way display projection

### Software Requirements
- Real-time 3D rendering
- Agent avatar display
- Status visualization
- Voice synchronization

### Development Phases

1. **Phase 1**: Basic pyramid display
2. **Phase 2**: Agent avatars
3. **Phase 3**: Interactive gestures
4. **Phase 4**: Voice integration

---

## OTA Updates

### Update Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   GitHub    │────▶│   Server    │────▶│     Pi      │
│  (Release)  │     │  (Update)   │     │  (Install)  │
└─────────────┘     └─────────────┘     └─────────────┘
                          │
                          ▼
                    ┌─────────────┐
                    │   Rollback  │
                    │  (if fail)  │
                    └─────────────┘
```

### Safety Features
- Automatic rollback on failure
- Staged rollout (one device at a time)
- Health check before/after
- Manual override capability

---

## Monitoring

### Metrics to Track

| Metric | Interval | Alert Threshold |
|--------|----------|-----------------|
| CPU temp | 30s | >80°C |
| Memory usage | 30s | >90% |
| Disk space | 5m | <10% free |
| Network latency | 1m | >100ms |
| Uptime | 1m | <99% |

### Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                    PI FLEET DASHBOARD                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  DEVICE          STATUS    CPU    MEM    TEMP    UPTIME    │
│  ─────────────────────────────────────────────────────────  │
│  lucidia         ● Online  23%    45%    52°C    14d 3h    │
│  blackroad-pi    ● Online  18%    38%    48°C    7d 12h    │
│  lucidia-alt     ○ Offline  -      -      -       -         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

*Last updated: 2026-02-05*
