# BlackRoad OS Docs

> Official documentation hub for BlackRoad OS

## Quick Reference

| Property | Value |
|----------|-------|
| **Framework** | Docusaurus 3 |
| **React** | 18 |
| **MDX** | 3.0 |
| **Node** | 18+ |
| **Package Manager** | npm |

## Commands

```bash
npm start        # Start dev server (port 3000)
npm run build    # Production build
npm run serve    # Serve production build
npm run deploy   # Deploy to GitHub Pages
npm run prepare:docs  # Prepare documentation
```

## Project Structure

```
docs/
├── intro.md              # Getting started
├── guides/               # Step-by-step guides
├── api/                  # API reference
├── agents/               # Agent documentation
└── infrastructure/       # Infra docs

src/
├── components/           # Custom React components
├── css/                  # Custom styles
└── pages/                # Custom pages

static/
├── img/                  # Images
└── assets/               # Other static files
```

## Documentation Standards

### Frontmatter

```yaml
---
title: Page Title
sidebar_position: 1
description: Brief description
tags: [agent, api, guide]
---
```

### Code Blocks

Always specify language:
```markdown
```typescript
// TypeScript code
```
```

### Admonitions

```markdown
:::note
Helpful information
:::

:::warning
Important caution
:::

:::danger
Critical warning
:::
```

## Design System

Use official BlackRoad colors in custom components:

```css
--amber: #F5A623;
--hot-pink: #FF1D6C;
--electric-blue: #2979FF;
--violet: #9C27B0;
```

## Key Sections

1. **Getting Started** - Quick setup guides
2. **Agent Framework** - Building custom agents
3. **API Reference** - Full API documentation
4. **Infrastructure** - Deployment and scaling
5. **Memory System** - PS-SHA∞ documentation

## Deployment

- **Production**: GitHub Pages / Cloudflare Pages
- **Domain**: docs.blackroad.io
- **Auto-deploy**: On push to main

## Related Repos

- `blackroad-os-web` - Main web app
- `blackroad-cli` - CLI tool
- `blackroad-os-core` - Core engine
