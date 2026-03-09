# Lucidia Earth - Complete Project Index

**Project:** Interactive 3D Earth Visualization & Game System
**Framework:** Next.js 16 + Three.js r128
**Deployment:** Cloudflare Pages
**Created:** 2025-12-23

---

## 📊 Project Stats

- **HTML Visualizations:** 13
- **Next.js Routes:** 12
- **Game Templates:** 2 (4 more planned)
- **Documentation Files:** 7
- **Total Biomes:** 12
- **Real-world Regions:** 86+
- **Planets:** 2 (Earth, Jupiter)

---

## 🗂️ Quick Navigation

### Documentation
- [README.md](./README.md) - Main project documentation
- [VISUALIZATIONS.md](./VISUALIZATIONS.md) - Complete visualization catalog
- [GAME_TEMPLATES.md](./GAME_TEMPLATES.md) - Game design documentation
- [GAMES_SUMMARY.md](./GAMES_SUMMARY.md) - Quick start guide for games
- [INDEX.md](./INDEX.md) - This file

### Key Files
- `public/biomes.html` - 🌟 **CANONICAL TEMPLATE** for all Earth visualizations
- `public/jupiter.html` - Jupiter system template
- `public/open-world-game.html` - Original open world game
- `public/game-biomes-survival.html` - Survival game template
- `public/game-jupiter-explorer.html` - Space flight sim template

---

## 🌍 All Visualizations

### Earth-Based (10)
1. **Biomes** (`/biomes`) - Canonical template with 12 biomes, 86+ regions
2. **Biomes Infinite** (`/biomes-infinite`) - Procedural infinite generation
3. **Biomes Pixel** (`/biomes-pixel`) - Pixelated/voxel aesthetic
4. **Fractal Terrain** (`/fractal-terrain`) - Heightmap generation
5. **Genesis** (`/genesis`) - Genesis simulation
6. **Living World** (`/living-world`) - Dynamic entities
7. **Global Network** (`/global-network`) - Network visualization
8. **Street Level** (`/street-level`) - MapLibre GL map

### Space-Based (2)
9. **Jupiter** (`/jupiter`) - Gas giant with 4 Galilean moons
10. **Jupiter Explorer Game** (`/game-jupiter-explorer`) - Space flight simulation

### Game Templates (3)
11. **Open World Game** (`/game`) - First-person exploration
12. **Biomes Survival** (`/game-biomes-survival`) - Survival mechanics
13. **Jupiter Explorer** (`/game-jupiter-explorer`) - Space missions

---

## 🎮 Games Quick Reference

### ✅ Completed (2)

| Game | Route | Genre | Key Features |
|------|-------|-------|--------------|
| Biomes Survival | `/game-biomes-survival` | Survival/Crafting | Health, Hunger, Thirst, Stamina, Crafting, Day/Night |
| Jupiter Explorer | `/game-jupiter-explorer` | Space Sim | 6DOF Flight, Scanning, Missions, Fuel Management |

### 🔄 Planned (4)

| Game | Based On | Genre | Status |
|------|----------|-------|--------|
| Street Racer | `blackroad-earth-street.html` | Racing | Planned |
| Network Hacker | `blackroad-earth.html` | Puzzle/Strategy | Planned |
| Genesis Simulator | `blackroad-living-world.html` | God Game | Planned |
| Fractal Miner | `fractal-earth.html` | Mining/Crafting | Planned |

---

## 📁 File Structure

```
lucidia-earth/
├── app/                          # Next.js routes
│   ├── biomes/                   # Canonical biome viz
│   ├── biomes-infinite/
│   ├── biomes-pixel/
│   ├── fractal-terrain/
│   ├── genesis/
│   ├── game/                     # Original open world game
│   ├── game-biomes-survival/     # Survival game
│   ├── game-jupiter-explorer/    # Space flight sim
│   ├── jupiter/                  # Jupiter visualization
│   ├── living-world/
│   ├── global-network/
│   └── street-level/
│
├── public/                       # Static HTML files
│   ├── biomes.html              # 🌟 CANONICAL TEMPLATE
│   ├── biomes-infinite.html
│   ├── biomes-pixel.html
│   ├── fractal-earth.html
│   ├── genesis-earth.html
│   ├── jupiter.html
│   ├── open-world-game.html
│   ├── game-biomes-survival.html
│   ├── game-jupiter-explorer.html
│   ├── blackroad-living-world.html
│   ├── blackroad-earth.html
│   ├── blackroad-earth-street.html
│   └── blackroad-earth-street-1.html
│
└── Documentation
    ├── README.md
    ├── VISUALIZATIONS.md
    ├── GAME_TEMPLATES.md
    ├── GAMES_SUMMARY.md
    └── INDEX.md (this file)
```

---

## 🎯 Feature Matrix

| Feature | Biomes | Jupiter | Open World | Survival | Explorer |
|---------|--------|---------|------------|----------|----------|
| 3D Rendering | ✅ | ✅ | ✅ | ✅ | ✅ |
| Interactive | ✅ | ✅ | ✅ | ✅ | ✅ |
| First-Person | ❌ | ❌ | ✅ | ✅ | ✅ |
| Inventory | ❌ | ❌ | ✅ | ✅ | ❌ |
| Crafting | ❌ | ❌ | ❌ | ✅ | ❌ |
| Missions | ❌ | ❌ | ❌ | ❌ | ✅ |
| Physics | ❌ | ❌ | ✅ | ✅ | ✅ |
| Resource Gathering | ❌ | ❌ | ✅ | ✅ | ❌ |
| Survival Stats | ❌ | ❌ | ✅ | ✅ | ❌ |
| Day/Night Cycle | ✅ | ❌ | ❌ | ✅ | ❌ |
| Biomes | ✅ | ❌ | ✅ | ✅ | ❌ |
| Space Flight | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## 🌟 12 Biome Types

1. **TR** - Tropical Rainforest
2. **TF** - Temperate Forest
3. **BT** - Boreal/Taiga
4. **TU** - Tundra
5. **DH** - Hot Desert
6. **DC** - Cold Desert
7. **SV** - Savanna
8. **GR** - Grassland/Prairie
9. **MD** - Mediterranean
10. **MT** - Mountain/Alpine
11. **IC** - Ice Sheet/Polar
12. **WL** - Wetland/Swamp

---

## 🚀 Getting Started

### Development
```bash
cd /Users/alexa/projects/lucidia-earth
pnpm install
pnpm dev
```

Open http://localhost:3000

### Build
```bash
pnpm build
```

### Deploy
```bash
wrangler pages deploy out --project-name=lucidia-earth
```

---

## 🛠️ Technology Stack

### Frontend
- **Framework:** Next.js 16 (App Router, Static Export)
- **3D Engine:** Three.js r128
- **Styling:** Tailwind CSS 4
- **Maps:** MapLibre GL (street-level only)
- **Icons:** Lucide React (Next.js routes)

### Deployment
- **Platform:** Cloudflare Pages
- **CDN:** unpkg (Three.js textures)
- **Assets:** Static export to `out/`

### Input
- **Keyboard:** Event listeners
- **Mouse:** Pointer Lock API + move events
- **Touch:** TouchEvent API (mobile support)

---

## 📈 Lines of Code (Estimated)

| Component | Lines |
|-----------|-------|
| Biomes Template | 1,357 |
| Jupiter Template | 830 |
| Open World Game | 830 |
| Biomes Survival | 600 |
| Jupiter Explorer | 550 |
| Other Visualizations | ~6,000 |
| Next.js Routes | ~120 |
| **Total** | **~10,287** |

---

## 🎨 Design System

### Colors
- **Primary:** #FF1D6C (Pink/Red)
- **Secondary:** #F5A623 (Orange/Gold)
- **Jupiter:** #d4a574 (Tan/Brown)
- **Earth Forest:** #2d5a27 (Green)
- **UI Background:** rgba(0,0,0,0.85)
- **Borders:** rgba(255,255,255,0.1)

### Typography
- **Font:** -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif
- **Headings:** 10px uppercase, letter-spacing 0.1em
- **Body:** 12-14px regular

### Components
- **Glassmorphic Panels:** backdrop-filter: blur(20px)
- **Rounded Corners:** 12px standard, 50px for pills
- **Shadows:** Minimal, mostly on hover
- **Transitions:** 0.2-0.3s ease

---

## 🏆 Achievement System (Planned)

### Global Achievements
- **Explorer:** Visit all visualizations
- **Collector:** Scan all moons and biomes
- **Survivor:** Survive 7 days in survival mode
- **Pilot:** Complete all Jupiter missions
- **Creator:** Use all visualization templates

---

## 📝 TODO

### High Priority
- [ ] Add sound effects and music
- [ ] Implement save/load system
- [ ] Mobile touch controls optimization
- [ ] Tutorial systems for games

### Medium Priority
- [ ] Complete remaining 4 game templates
- [ ] Add multiplayer support
- [ ] Implement achievement system
- [ ] Create more biomes (20 total)

### Low Priority
- [ ] VR support
- [ ] Controller support
- [ ] Mod system
- [ ] Level editor

---

## 🔗 Live Demos

**Production:** https://dc29fb12.lucidia-earth.pages.dev

**Routes:**
- `/biomes` - Canonical template
- `/jupiter` - Jupiter system
- `/game` - Open world game
- `/game-biomes-survival` - Survival game
- `/game-jupiter-explorer` - Space flight sim

---

**Last Updated:** 2025-12-23
**Maintainer:** BlackRoad Systems
**License:** Proprietary
**Status:** Active Development
