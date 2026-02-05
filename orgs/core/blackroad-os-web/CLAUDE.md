# BlackRoad OS Web

> Main web application for BlackRoad OS - the 30,000 agent orchestration platform

## Quick Reference

| Property | Value |
|----------|-------|
| **Framework** | Next.js 16.1.1 |
| **React** | 19.2.3 |
| **Styling** | TailwindCSS 4 |
| **State** | Zustand 5.0.9 |
| **Node** | 22+ |
| **Package Manager** | npm |

## Tech Stack

```
Next.js 16 (App Router)
├── React 19 (Server Components)
├── TailwindCSS 4
├── Zustand (State Management)
├── Radix UI (Primitives)
└── TypeScript 5
```

## Commands

```bash
npm run dev      # Start development server (port 3000)
npm run build    # Production build
npm run start    # Start production server
npm run lint     # ESLint check
```

## Project Structure

```
src/
├── app/           # Next.js App Router pages
├── components/    # React components
├── lib/           # Utilities and helpers
├── hooks/         # Custom React hooks
└── store/         # Zustand stores
```

## Design System

**CRITICAL: Use Official BlackRoad Colors Only**

```css
/* Official Palette */
--amber: #F5A623;
--hot-pink: #FF1D6C;
--electric-blue: #2979FF;
--violet: #9C27B0;
--background: #000000;
--text: #FFFFFF;
```

**FORBIDDEN Colors (Old System - DO NOT USE):**
- #FF9D00, #FF6B00, #FF0066, #FF006B, #D600AA, #7700FF, #0066FF

## Key Features

- **Agent Dashboard**: Real-time monitoring of 30,000 agents
- **Control Center**: Mission coordination and task management
- **Memory Viewer**: PS-SHA∞ hash-chain journal explorer
- **Trinity System**: Greenlight/Yellowlight/Redlight status

## Environment Variables

```env
NEXT_PUBLIC_API_URL=        # API endpoint
NEXT_PUBLIC_WS_URL=         # WebSocket endpoint
NEXT_PUBLIC_CLOUDFLARE_ID=  # Cloudflare account
```

## Deployment

- **Production**: Vercel / Cloudflare Pages
- **Preview**: Auto-deployed on PR
- **Domain**: blackroad.io

## Related Repos

- `blackroad-os-docs` - Documentation
- `blackroad-cli` - CLI tool
- `blackroad-os-core` - Core orchestration engine
