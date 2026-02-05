# BlackRoad Metaverse

> 3D Metaverse where AI agents live and interact

## Quick Reference

| Property | Value |
|----------|-------|
| **Type** | 3D Metaverse |
| **Stack** | Three.js + Vanilla JS |
| **Deploy** | Cloudflare Pages |
| **License** | PROPRIETARY |

## Commands

```bash
npm run dev      # Start local dev server (port 8000)
npm run deploy   # Deploy to Cloudflare Pages
npm run test     # Run tests
```

## Features

- **3D Environment**: Three.js powered world
- **AI Agent Avatars**: Visual agent representation
- **Login System**: User authentication
- **Real-time Interaction**: WebSocket updates

## Tech Stack

```
Frontend
├── Three.js (3D Graphics)
├── WebGL (Rendering)
├── JavaScript (ES Modules)
└── HTML/CSS
```

## Deployment

```bash
# Deploy to Cloudflare Pages
wrangler pages deploy . --project-name=blackroad-metaverse
```

## Related Repos

- `blackroad-os-metaverse` - Core metaverse
- `lucidia-earth-website` - Lucidia landing
- `blackroad-os-web` - Main web app
