# Lucidia Earth

Interactive 3D Earth visualization system with biomes, fractal terrain, and living ecosystems.

**Live:** https://dc29fb12.lucidia-earth.pages.dev
**Deployed:** Cloudflare Pages

## 🌍 Standard Template

**IMPORTANT:** The `public/biomes.html` file is the **canonical template** for ALL 3D Earth rendering visualizations in this project and related BlackRoad OS projects.

### Template Features
- Three.js r128 3D rendering
- Procedural biome generation (12 biome types)
- Real-world geographic mapping (86+ regions)
- Interactive controls (rotate, clouds, night mode, life toggle)
- Animated entities (trees, animals, agents, flowers, houses)
- Click-to-explore region info panels
- Real-time stats tracking
- Responsive UI with glassmorphic design

### Template Location
```
public/biomes.html (1,357 lines)
```

### When Creating New Earth Visualizations
1. Copy `public/biomes.html` as the base
2. Modify biome definitions, entity generators, or regions as needed
3. Embed via Next.js route using iframe pattern (see `app/biomes/page.tsx`)
4. Keep core Three.js scene setup, camera controls, and UI structure consistent

### Variants Using This Template
- `/biomes` - Standard biome visualization (🌟 CANONICAL TEMPLATE)
- `/biomes-infinite` - Infinite procedural generation
- `/biomes-pixel` - Pixelated/voxel style
- `/fractal-terrain` - Fractal heightmap generation
- `/genesis` - Genesis simulation
- `/game` - Open world game (first-person, resource gathering)
- `/jupiter` - Jupiter system (4 Galilean moons, Great Red Spot)
- `/living-world` - Living world with dynamic entities
- `/global-network` - Global network visualization
- `/street-level` - Street-level map view (MapLibre GL)

## Getting Started

```bash
pnpm install
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000)

## Build & Deploy

```bash
pnpm build
wrangler pages deploy out --project-name=lucidia-earth
```

## Architecture

- **Framework:** Next.js 16 (App Router, Static Export)
- **3D Engine:** Three.js r128
- **Styling:** Tailwind CSS 4
- **Deployment:** Cloudflare Pages
- **Textures:** unpkg CDN (earth-blue-marble, topology, clouds, night lights)

## Project Structure

```
app/
  ├── biomes/          # Standard biome viz (🌟 CANONICAL)
  ├── biomes-infinite/ # Infinite generation
  ├── biomes-pixel/    # Voxel style
  ├── fractal-terrain/ # Heightmap generation
  ├── genesis/         # Genesis simulation
  ├── game/            # Open world game
  ├── jupiter/         # Jupiter system
  ├── living-world/    # Living world
  ├── global-network/  # Global network
  └── street-level/    # Street-level map

public/
  ├── biomes.html                    # 🌟 CANONICAL TEMPLATE
  ├── biomes-infinite.html
  ├── biomes-pixel.html
  ├── fractal-earth.html
  ├── genesis-earth.html
  ├── open-world-game.html
  ├── jupiter.html
  ├── blackroad-living-world.html
  ├── blackroad-earth.html
  ├── blackroad-earth-street.html
  └── blackroad-earth-street-1.html
```

## Visualization Types

### 🌍 Earth Visualizations
1. **Biomes** - 12 biome types with 86+ real-world regions
2. **Biomes Infinite** - Procedural infinite generation
3. **Biomes Pixel** - Pixelated/voxel aesthetic
4. **Fractal Terrain** - Heightmap generation
5. **Genesis** - Genesis simulation
6. **Living World** - Dynamic entities and life
7. **Global Network** - Network visualization
8. **Street Level** - MapLibre GL street map

### 🎮 Interactive Game Templates
1. **Open World Game** - First-person exploration, resource gathering, inventory system
2. **Biomes Survival** - Survival mechanics (health, hunger, thirst, stamina), crafting, day/night cycle
3. **Jupiter Explorer** - Space flight sim with 6DOF controls, scanning, mission objectives

### 🪐 Other Planets
1. **Jupiter** - Gas giant with 4 Galilean moons, Great Red Spot, space probes

## 12 Biome Types

1. Tropical Rainforest (TR)
2. Temperate Forest (TF)
3. Boreal/Taiga (BT)
4. Tundra (TU)
5. Hot Desert (DH)
6. Cold Desert (DC)
7. Savanna (SV)
8. Grassland/Prairie (GR)
9. Mediterranean (MD)
10. Mountain/Alpine (MT)
11. Ice Sheet/Polar (IC)
12. Wetland/Swamp (WL)

## 🎮 Game Templates

See [GAME_TEMPLATES.md](./GAME_TEMPLATES.md) for complete game documentation.

### Completed Games (2/6)
1. **Biomes Survival** (`/game-biomes-survival`) - Survival mechanics, crafting, resource gathering
2. **Jupiter Explorer** (`/game-jupiter-explorer`) - Space exploration, scanning missions

### Planned Games (4/6)
3. Street Racer - Racing on real-world maps
4. Network Hacker - Node-based hacking puzzles
5. Genesis Simulator - God game with ecosystem management
6. Fractal Miner - Underground mining and crafting

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson

**PROPRIETARY AND CONFIDENTIAL**

This software is the proprietary property of BlackRoad OS, Inc. and is **NOT for commercial resale**.

### ⚠️ Usage Restrictions:
- ✅ **Permitted:** Testing, evaluation, and educational purposes
- ❌ **Prohibited:** Commercial use, resale, or redistribution without written permission

### 🏢 Enterprise Scale:
Designed to support:
- 30,000 AI Agents
- 30,000 Human Employees
- One Operator: Alexa Amundson (CEO)

### 📧 Contact:
For commercial licensing inquiries:
- **Email:** blackroad.systems@gmail.com
- **Organization:** BlackRoad OS, Inc.

See [LICENSE](LICENSE) for complete terms.
