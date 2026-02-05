# BlackRoad Ecosystem Dashboard

> Real-time dashboard for the BlackRoad ecosystem

## Quick Reference

| Property | Value |
|----------|-------|
| **Framework** | Next.js 14 |
| **React** | 18 |
| **License** | UNLICENSED |

## Commands

```bash
npm run dev      # Start development server
npm run build    # Production build
npm run start    # Start production server
```

## Tech Stack

```
Next.js 14
├── React 18
├── ESLint 9
└── Prettier 3
```

## Features

- **Real-time Metrics**: Live ecosystem monitoring
- **Agent Status**: 30,000 agent overview
- **Infrastructure Health**: Multi-cloud status
- **Traffic Analytics**: Request/response metrics

## Project Structure

```
app/
├── page.tsx         # Main dashboard
├── agents/          # Agent monitoring
├── infra/           # Infrastructure view
└── analytics/       # Analytics panels

components/
├── charts/          # Visualization components
├── cards/           # Metric cards
└── layout/          # Layout components
```

## Design System

Use official BlackRoad colors:
```css
--amber: #F5A623;
--hot-pink: #FF1D6C;
--electric-blue: #2979FF;
--violet: #9C27B0;
--background: #000000;
```

## Environment Variables

```env
NEXT_PUBLIC_API_URL=      # API endpoint
NEXT_PUBLIC_WS_URL=       # WebSocket endpoint
```

## Deployment

- Vercel / Cloudflare Pages
- Auto-deploy on push to main

## Related Repos

- `blackroad-os-web` - Main web app
- `blackroad-agents` - Agent API
- `blackroad-os-core` - Core engine
