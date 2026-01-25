# Lucidia Earth Visualizations

Complete catalog of all visualization experiences in the Lucidia Earth project.

## 🌟 Canonical Template

**File:** `public/biomes.html`  
**Route:** `/biomes`

The master template for all 3D Earth rendering. Features 12 biome types, 86+ real-world regions, procedural entity generation, and interactive controls.

---

## 🌍 Earth Visualizations

### 1. Biomes (Canonical)
- **File:** `biomes.html`
- **Route:** `/biomes`
- **Features:** 12 biomes, 86+ regions, trees, animals, houses, flowers, agents

### 2. Biomes Infinite
- **File:** `biomes-infinite.html`
- **Route:** `/biomes-infinite`
- **Features:** Infinite procedural generation

### 3. Biomes Pixel
- **File:** `biomes-pixel.html`
- **Route:** `/biomes-pixel`
- **Features:** Pixelated/voxel aesthetic

### 4. Fractal Terrain
- **File:** `fractal-earth.html`
- **Route:** `/fractal-terrain`
- **Features:** Heightmap-based terrain generation

### 5. Genesis
- **File:** `genesis-earth.html`
- **Route:** `/genesis`
- **Features:** Genesis simulation

### 6. Living World
- **File:** `blackroad-living-world.html`
- **Route:** `/living-world`
- **Features:** Dynamic entities and life systems

### 7. Global Network
- **File:** `blackroad-earth.html`
- **Route:** `/global-network`
- **Features:** Network connectivity visualization

### 8. Street Level
- **File:** `blackroad-earth-street.html`
- **Route:** `/street-level`
- **Features:** MapLibre GL street-level map view

---

## 🎮 Interactive Experiences

### Open World Game
- **File:** `open-world-game.html`
- **Route:** `/game`
- **Features:**
  - First-person controls (WASD + mouse)
  - Physics (gravity, jumping, sprinting)
  - Resource gathering (trees, stones, crystals, mushrooms)
  - 6-slot inventory system
  - Health & energy management
  - Biome detection
  - 100 trees + 50 resources
  - Procedural terrain with shadows

---

## 🪐 Other Planets

### Jupiter System
- **File:** `jupiter.html`
- **Route:** `/jupiter`
- **Features:**
  - Procedurally generated Jupiter with atmospheric bands
  - Great Red Spot + 15 additional storms
  - 4 Galilean Moons (Io, Europa, Ganymede, Callisto)
  - Accurate orbital mechanics
  - 4 Space probes (Voyager 1/2, Galileo, Juno)
  - Clickable moons with detailed info panels
  - 8,000 star field

---

## Access Patterns

### Direct HTML
All visualizations can be accessed directly:
- `http://localhost:3000/biomes.html`
- `http://localhost:3000/jupiter.html`
- `http://localhost:3000/open-world-game.html`
- etc.

### Next.js Routes
All visualizations have Next.js routes:
- `http://localhost:3000/biomes`
- `http://localhost:3000/jupiter`
- `http://localhost:3000/game`
- etc.

---

## Technology Stack

- **3D Engine:** Three.js r128
- **Framework:** Next.js 16 (App Router)
- **Maps:** MapLibre GL (street-level)
- **Styling:** Tailwind CSS 4
- **Deployment:** Cloudflare Pages

---

## File Count

- **HTML Files:** 11
- **Next.js Routes:** 10
- **Total Lines:** ~500,000+ (estimated)
