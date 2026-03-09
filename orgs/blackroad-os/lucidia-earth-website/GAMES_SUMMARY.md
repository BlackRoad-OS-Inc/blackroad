# 🎮 Game Templates - Quick Start Guide

All game templates created from the Lucidia Earth visualization system.

## ✅ Completed Games

### 1. Biomes Survival Game
**Route:** `/game-biomes-survival`  
**File:** `public/game-biomes-survival.html`

**Quick Summary:** Minecraft-like survival game with health, hunger, thirst, and stamina management. Gather resources, craft items, survive day/night cycles across 4 different biomes.

**Controls:**
- `WASD` - Move
- `SPACE` - Jump
- `SHIFT` - Sprint
- `E` - Gather resources
- `C` - Craft
- `MOUSE` - Look around

**Key Features:**
- ✅ Health/Hunger/Thirst/Stamina bars
- ✅ 8-slot inventory with stacking
- ✅ 4 crafting recipes (Campfire, Shelter, Tool, Torch)
- ✅ Day/night cycle (24-hour time)
- ✅ 4 biomes (Forest, Desert, Tundra, Jungle)
- ✅ 80+ gatherable resources
- ✅ First-person controls with pointer lock

**Resources to Gather:**
- Wood (from trees) - 3 per tree
- Stone (from rocks) - 2 per rock
- Berries, Mushrooms, Crystals

---

### 2. Jupiter Explorer (Space Flight Sim)
**Route:** `/game-jupiter-explorer`  
**File:** `public/game-jupiter-explorer.html`

**Quick Summary:** Fly a spacecraft through the Jovian system, scan the 4 Galilean moons, complete mission objectives. Full 6-degrees-of-freedom flight controls.

**Controls:**
- `W/S` - Thrust forward/backward
- `A/D` - Strafe left/right
- `Q/E` - Up/Down
- `SPACE` - Boost (2x thrust, drains fuel faster)
- `F` - Scan target
- `MOUSE` - Orient spacecraft

**Key Features:**
- ✅ 6 progressive mission objectives
- ✅ Fuel management system
- ✅ Scanner with target identification
- ✅ 4 Galilean moons (Io, Europa, Ganymede, Callisto)
- ✅ Orbital mechanics (moons orbit Jupiter)
- ✅ Real-time HUD (speed, distance, fuel, hull)
- ✅ Resource detection (sulfur, ice, minerals, water)

**Missions:**
1. Approach Jupiter (< 200km)
2. Scan Io (volcanic moon, sulfur)
3. Scan Europa (ice moon, subsurface ocean)
4. Scan Ganymede (largest moon, minerals)
5. Scan Callisto (cratered moon, water)
6. Complete all scans

---

## 🚀 How to Play

### Running Locally
```bash
cd /Users/alexa/projects/lucidia-earth
pnpm dev
```

### Access Games
- **Via Next.js Routes:**
  - http://localhost:3000/game-biomes-survival
  - http://localhost:3000/game-jupiter-explorer

- **Via Direct HTML:**
  - http://localhost:3000/game-biomes-survival.html
  - http://localhost:3000/game-jupiter-explorer.html

---

## 🛠️ Game Architecture

### Common Systems

All games share these core systems:

**1. HUD System**
- Status bars (health, fuel, resources)
- Real-time value updates
- Glassmorphic design with backdrop blur

**2. Input Handling**
- Pointer Lock API for mouse control
- Keyboard event listeners
- Continuous input reading in game loop

**3. Game Loop**
- RequestAnimationFrame for 60fps
- Delta time calculations
- State updates → Rendering

**4. Physics**
- Custom gravity implementation
- Collision detection (ground, objects)
- Velocity and momentum

**5. Inventory**
- Grid-based or list-based storage
- Stack management
- UI updates on item changes

### Technology Stack
- **3D Engine:** Three.js r128
- **Rendering:** WebGL via Three.js renderer
- **Input:** Keyboard Events + Pointer Lock API
- **UI:** Pure CSS with CSS Grid/Flexbox
- **State:** JavaScript objects
- **Physics:** Custom (no library)

---

## 📊 Stats

| Metric | Biomes Survival | Jupiter Explorer |
|--------|-----------------|------------------|
| Lines of Code | ~600 | ~550 |
| Features | 10 | 8 |
| Playable | ✅ Yes | ✅ Yes |
| Difficulty | Medium | Medium |
| Genre | Survival/Crafting | Space Sim |
| Play Time | 15-30 min | 10-20 min |

---

## 🎯 Future Enhancements

### For Both Games
- [ ] Save/Load system (LocalStorage)
- [ ] Sound effects and music
- [ ] Particle effects
- [ ] Screen shake on events
- [ ] Achievement system
- [ ] Tutorial/Help system
- [ ] Mobile touch controls
- [ ] Leaderboards

### Biomes Survival Specific
- [ ] More biomes (8 additional)
- [ ] Shelter building mechanics
- [ ] Hunger/thirst food items
- [ ] Weather system
- [ ] Enemy creatures
- [ ] More crafting recipes

### Jupiter Explorer Specific
- [ ] More celestial bodies (asteroids, stations)
- [ ] Combat mechanics
- [ ] Trading system
- [ ] Upgradeable spacecraft
- [ ] Multiplayer racing
- [ ] Deep space exploration

---

## 🎨 Design Philosophy

**From Visualization to Game:**

1. **Keep the Core Visual** - Preserve the original visualization aesthetic
2. **Add Interactivity** - Convert passive viewing into active gameplay
3. **Progressive Complexity** - Simple to learn, deeper with mastery
4. **Immediate Feedback** - Every action has visible/audible response
5. **Clear Goals** - Missions, objectives, or survival challenges

**UI Principles:**
- Minimal but informative
- Glassmorphic design (rgba + backdrop-blur)
- Non-intrusive (edges of screen)
- Color-coded information (green = good, red = danger)
- Tooltips and clear labels

---

## 📝 Creating Your Own Game

**Template Structure:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Your Game</title>
    <style>
        /* HUD CSS here */
    </style>
</head>
<body>
    <div id="canvas-container"></div>
    <!-- HUD elements -->
    <script src="three.js"></script>
    <script>
        // Game state
        let gameState = { ... };
        
        // Init function
        function init() { ... }
        
        // Game loop
        function animate() {
            requestAnimationFrame(animate);
            updateGame();
            renderer.render(scene, camera);
        }
        
        init();
    </script>
</body>
</html>
```

**Steps:**
1. Copy a visualization as base
2. Add game state object
3. Implement input handling
4. Create HUD elements
5. Add game mechanics
6. Test and polish

---

## 🏆 Achievement Ideas

### Biomes Survival
- [ ] First Craft - Craft your first item
- [ ] Shelter Builder - Build a shelter
- [ ] Survivor - Survive 7 days
- [ ] Explorer - Visit all 4 biomes
- [ ] Collector - Gather 100 resources
- [ ] Master Crafter - Craft all items

### Jupiter Explorer
- [ ] First Contact - Scan your first moon
- [ ] Cartographer - Scan all Galilean moons
- [ ] Speed Demon - Reach max boost speed
- [ ] Conservationist - Complete mission with >50% fuel
- [ ] Discoverer - Find hidden asteroid belt
- [ ] Ace Pilot - Complete all missions

---

**Created:** 2025-12-23  
**Project:** Lucidia Earth  
**Framework:** Three.js + Next.js  
**Status:** 2/6 Games Complete, 4 Planned
