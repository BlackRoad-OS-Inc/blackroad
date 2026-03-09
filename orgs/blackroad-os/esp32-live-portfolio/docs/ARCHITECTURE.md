# ESP32 Live Portfolio Hub - Real-Time Architecture

## Core Principle: Everything is LIVE

No static data. No hardcoded values. Every screen pulls real production metrics.

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
├─────────────────────────────────────────────────────────────────┤
│  GitHub API    Cloudflare API    Railway API    Stripe API      │
│  (15 orgs)     (16 zones)        (12 projects)  (revenue)       │
│                                                                  │
│  Linear API    EspoCRM API       Prometheus     Headscale       │
│  (tasks)       (leads/deals)     (metrics)      (VPN nodes)     │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   AGGREGATOR API (Cloudflare Worker)            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • Polls all APIs every 30-60 seconds                     │  │
│  │  • Caches in Cloudflare KV                                │  │
│  │  • Single unified JSON endpoint                           │  │
│  │  • WebSocket for push updates (optional)                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Endpoint: https://api.blackroad.io/v1/live-hub                 │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ESP32 CEO HUB                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  • Fetches /live-hub every 30 seconds                     │  │
│  │  • Parses JSON into display structs                       │  │
│  │  • Updates all screens with fresh data                    │  │
│  │  • Shows "LIVE" indicator when data < 60s old             │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Live Data Categories

### 1. GitHub Metrics (Real-time)
```json
{
  "github": {
    "total_repos": 199,
    "total_stars": 1247,
    "total_forks": 342,
    "open_prs": 23,
    "open_issues": 67,
    "commits_today": 45,
    "top_repos": [
      {"name": "blackroad-os-operator", "stars": 142, "activity": "high"},
      {"name": "blackroad-ai-platform", "stars": 98, "activity": "medium"}
    ],
    "orgs": {
      "BlackRoad-OS": {"repos": 199, "stars": 847},
      "BlackRoad-AI": {"repos": 12, "stars": 156}
    },
    "last_commit": "2m ago",
    "updated_at": "2026-01-11T05:50:00Z"
  }
}
```

### 2. Infrastructure Health (Real-time)
```json
{
  "infrastructure": {
    "servers": {
      "octavia": {"status": "online", "cpu": 23, "mem": 67, "ip": "192.168.4.38"},
      "alice": {"status": "online", "cpu": 12, "mem": 45, "ip": "192.168.4.49"},
      "aria": {"status": "offline", "last_seen": "2h ago", "ip": "192.168.4.64"},
      "codex": {"status": "online", "cpu": 45, "mem": 78, "ip": "159.65.43.12"}
    },
    "vpn_nodes": 7,
    "vpn_connected": 5,
    "total_bandwidth": "2.3 TB/day",
    "sovereignty_score": 67
  }
}
```

### 3. Cloudflare Status (Real-time)
```json
{
  "cloudflare": {
    "zones": 16,
    "pages_projects": 60,
    "workers": 8,
    "kv_namespaces": 8,
    "d1_databases": 1,
    "requests_24h": 45000,
    "bandwidth_24h": "12.4 GB",
    "domains": {
      "blackroad.io": {"status": "active", "requests": 12000},
      "lucidia.earth": {"status": "active", "requests": 8000}
    }
  }
}
```

### 4. Business Metrics (Real-time)
```json
{
  "business": {
    "crm": {
      "total_leads": 234,
      "hot_leads": 12,
      "deals_pipeline": 45,
      "pipeline_value": "$1.2M",
      "won_this_month": 3
    },
    "stripe": {
      "mrr": "$4,500",
      "arr": "$54,000",
      "customers": 23,
      "transactions_today": 7
    },
    "linear": {
      "open_issues": 45,
      "in_progress": 12,
      "completed_today": 8,
      "velocity": "23 pts/week"
    }
  }
}
```

### 5. AI/ML Systems (Real-time)
```json
{
  "ai": {
    "vllm": {"status": "online", "requests_today": 1200, "avg_latency": "450ms"},
    "localai": {"status": "online", "models_loaded": 3, "gpu_util": 67},
    "embeddings": {"status": "online", "vectors_stored": "2.3M"},
    "agents_active": 30000,
    "inference_today": 45000
  }
}
```

### 6. Crypto/Web3 (Real-time from CoinGecko)
```json
{
  "crypto": {
    "btc": {"price": 98450, "change_24h": 2.3},
    "eth": {"price": 3890, "change_24h": -1.2},
    "sol": {"price": 178, "change_24h": 5.6},
    "portfolio_value": "$15,234",
    "holdings": {
      "btc": 0.1,
      "eth": 2.5,
      "sol": 100
    }
  }
}
```

---

## Unified API Response

Single endpoint returns everything the ESP32 needs:

```
GET https://api.blackroad.io/v1/live-hub
```

```json
{
  "timestamp": "2026-01-11T05:50:00Z",
  "refresh_in": 30,
  "github": { ... },
  "infrastructure": { ... },
  "cloudflare": { ... },
  "business": { ... },
  "ai": { ... },
  "crypto": { ... },
  "alerts": [
    {"level": "warning", "source": "linear", "message": "3 P1 issues open"},
    {"level": "info", "source": "github", "message": "PR #456 needs review"}
  ],
  "summary": {
    "products_live": 67,
    "products_total": 199,
    "health_score": 94,
    "sovereignty_score": 67
  }
}
```

---

## ESP32 Update Cycle

```
Every 30 seconds:
  1. GET /v1/live-hub
  2. Parse JSON (ArduinoJson)
  3. Update global data structs
  4. Mark screens as "stale" → triggers redraw
  5. Flash "LIVE" indicator green

If fetch fails:
  1. Show "OFFLINE" indicator (yellow)
  2. Keep last known data
  3. Retry in 10 seconds
```

---

## Screen-Specific Data Binding

| Screen | Data Source | Update Rate |
|--------|-------------|-------------|
| HOME | summary.* | 30s |
| GITHUB | github.* | 30s |
| INFRA | infrastructure.* | 30s |
| CRM | business.crm.* | 60s |
| CRYPTO | crypto.* | 60s |
| AI | ai.* | 30s |
| ALERTS | alerts[] | 10s |
| VPN | infrastructure.vpn_* | 30s |

---

## Live Indicators on Every Screen

```
┌──────────────────────────────────────────┐
│ 🖤 GITHUB                    ● LIVE  30s │
│                              ↑           │
│                         Green dot +      │
│                         seconds since    │
│                         last update      │
└──────────────────────────────────────────┘
```

States:
- `● LIVE` (green) - Data < 60s old
- `● STALE` (yellow) - Data 60-300s old
- `● OFFLINE` (red) - Data > 300s old or fetch failed

---

## Implementation Files

```
esp32-live-hub/
├── api/
│   └── worker.js           # Cloudflare Worker aggregator
├── firmware/
│   ├── src/
│   │   ├── main.cpp        # Main firmware
│   │   ├── live_data.h     # Live data fetching
│   │   ├── data_structs.h  # Data structures
│   │   └── screens/        # Per-screen renderers
│   └── platformio.ini
└── ARCHITECTURE.md
```
