# Lucidia Earth Website

> 3D interactive landing page for Lucidia with Three.js Earth visualization

## Quick Reference

| Property | Value |
|----------|-------|
| **Framework** | Next.js 16.1.1 |
| **React** | 19.2.3 |
| **3D Engine** | Three.js 0.182 |
| **Animation** | Framer Motion 12 |
| **Styling** | TailwindCSS 4 |

## Commands

```bash
npm run dev      # Start development server
npm run build    # Production build
npm run start    # Start production server
npm run lint     # ESLint check
```

## Tech Stack

```
Next.js 16 (App Router)
├── React 19
├── Three.js (3D Graphics)
├── Framer Motion (Animations)
├── TailwindCSS 4
└── TypeScript 5
```

## Features

- **3D Earth**: Interactive globe visualization
- **Smooth Animations**: Framer Motion transitions
- **Responsive Design**: Mobile-first approach
- **Dark Theme**: BlackRoad design system

## Project Structure

```
app/
├── page.tsx         # Landing page
├── layout.tsx       # Root layout
└── globals.css      # Global styles

components/
├── Earth.tsx        # Three.js Earth component
├── Hero.tsx         # Hero section
├── Features.tsx     # Feature showcase
└── Navigation.tsx   # Nav component
```

## Three.js Usage

```typescript
import * as THREE from 'three'

// Earth sphere setup
const geometry = new THREE.SphereGeometry(1, 64, 64)
const material = new THREE.MeshStandardMaterial({
  map: earthTexture,
  normalMap: earthNormal
})
```

## Design System

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
```

## Deployment

- Vercel / Cloudflare Pages
- Domain: lucidia.earth

## Related Repos

- `lucidia-core` - AI reasoning engines
- `blackroad-os-web` - Main web app
- `blackroad-os-metaverse` - Metaverse platform
