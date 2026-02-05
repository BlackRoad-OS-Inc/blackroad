# BlackRoad OS RoadChain

> Bitcoin Cosmic Lottery Dashboard - Real-time mining progress tracker

## Quick Reference

| Property | Value |
|----------|-------|
| **Runtime** | Node.js |
| **Dashboard** | Next.js |
| **Terminal UI** | Blessed |
| **License** | MIT |

## Tech Stack

```
Node.js
├── Next.js (Dashboard UI)
├── Express (API Server)
├── Blessed/Blessed-Contrib (Terminal UI)
├── WebSocket (Real-time Updates)
├── node-cron (Scheduled Tasks)
└── Axios (HTTP Client)
```

## Commands

```bash
npm run dev          # Start all services (dev mode)
npm run dashboard    # Dashboard only
npm run api          # API server only
npm run collect      # Data collectors only
npm run build        # Build dashboard
npm run deploy       # Deploy to Cloudflare
```

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Collectors    │────▶│    API Server   │
│  (node-cron)    │     │    (Express)    │
└─────────────────┘     └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
           ┌───────────────┐         ┌───────────────┐
           │   Dashboard   │         │  Terminal UI  │
           │   (Next.js)   │         │   (Blessed)   │
           └───────────────┘         └───────────────┘
```

## Features

- **Mining Progress**: Real-time hash rate tracking
- **Lottery Status**: Cosmic lottery participation
- **Pi Integration**: Raspberry Pi mining nodes
- **WebSocket Updates**: Live data streaming

## Project Structure

```
dashboard/
├── pages/           # Next.js pages
├── components/      # React components
└── server.js        # Dashboard server

api/
└── server.js        # Express API

collectors/
└── index.js         # Data collection
```

## Environment Variables

```env
API_PORT=3001             # API server port
DASHBOARD_PORT=3000       # Dashboard port
WS_PORT=3002              # WebSocket port
BITCOIN_NODE_URL=         # Bitcoin node
```

## Deployment

```bash
# Deploy to Cloudflare Pages
npm run build
npm run deploy
```

## Related Repos

- `blackroad-pi-ops` - Pi operations
- `blackroad-tools` - DevOps utilities
- `blackroad-ecosystem-dashboard` - Ecosystem dash
