# World Generation Specification

**Fractal Terrain System for Lucidia**

**Version:** 1.0
**Date:** 2025-12-23
**Status:** Canonical Technical Specification

---

## Core Concept

**Lucidia is not a fixed-resolution world. It is a fractal** — an infinitely recursive structure where each level of zoom reveals another layer of detail, generated deterministically from the level above.

The globe (529,000 triangles) is the **root node**. Zooming into any region reveals a **64×64 grid** of cells. Each cell can be zoomed into, revealing another 64×64 grid. This continues infinitely, with coherent terrain at every level because **each child inherits generation rules from its parent**.

**The world is not pre-generated. It unfolds when observed.**

---

## The Mathematics

### Recursive Structure

At each depth level `d`, the world subdivides into a **64×64 grid** (4,096 cells). The total addressable cells at depth `d` is:

```
cells(d) = 4096^d = 64^(2d) = 2^(12d)
```

| Depth | Total Cells | Scale Reference |
|-------|-------------|-----------------|
| **0** | 1 (globe) | Planet view |
| **1** | 4,096 | Continental regions |
| **2** | 16,777,216 | Country/state scale |
| **3** | 68,719,476,736 | City/district scale |
| **4** | ~2.8 × 10¹⁴ | Neighborhood scale |
| **5** | ~1.15 × 10¹⁸ | Block/street scale |
| **6** | ~4.7 × 10²¹ | **GROUND LEVEL** |
| **7+** | ∞ | Sub-ground (optional) |

**Note:** 64 = 2⁶, making all operations **GPU-friendly** and **binary-addressable**. Cell coordinates at any depth can be expressed as a path of 6-bit indices.

---

## Seed Propagation

Every cell's terrain is generated from a **seed**. Seeds propagate hierarchically — each child cell's seed is derived from its parent cell's seed plus its position within the parent grid.

### Seed Derivation Formula

```
child_seed = hash(parent_seed || x || y)
```

Where:
- `x` and `y` are the child's position (0-63) within the parent's 64×64 grid
- `hash()` is **PS-SHA∞** for consistency with Lucidia's memory architecture
- `||` denotes concatenation

### Properties
- **Deterministic**: Same parent seed + position = same child seed
- **Unique**: Each cell has a unique seed derived from its spatial path
- **Immutable**: Seeds never change; terrain is always reproducible
- **Verifiable**: PS-SHA∞ chain provides cryptographic proof of generation

---

## Biome Inheritance

**Children do not generate arbitrary terrain.** They are constrained by their **parent's biome type**. A cell within a Tropical Rainforest region can only generate rainforest-valid terrain features.

### Biome Constraint Rules

| Parent Biome | Valid Child Features |
|--------------|----------------------|
| **Tropical Rainforest** | Dense canopy, rivers, clearings, jungle floor |
| **Hot Desert** | Dunes, rock formations, oases, flat sand |
| **Mountain / Alpine** | Peaks, valleys, cliffs, alpine meadows, snow |
| **Temperate Forest** | Deciduous trees, streams, glades, forest paths |
| **Grassland / Prairie** | Rolling hills, tall grass, scattered trees, plains |
| **Ice Sheet / Polar** | Ice fields, crevasses, frozen lakes, tundra edge |
| **Savanna** | Acacia trees, tall grass, watering holes, rock outcrops |
| **Wetland / Swamp** | Marshes, mangroves, standing water, mud flats |
| **Mediterranean** | Olive groves, scrubland, rocky terrain, coastal cliffs |
| **Boreal / Taiga** | Coniferous trees, frozen ground, sparse undergrowth |
| **Tundra** | Permafrost, low shrubs, rocky terrain, ice patches |
| **Ocean** | Waves, reef structures (if shallow), deep trenches |

### Biome Transitions

**Biome boundaries create transition zones** — cells at the edge of two biomes blend characteristics from both, using **weighted generation** based on distance to biome center.

```
blend_weight = distance_to_center_A / (distance_to_center_A + distance_to_center_B)
```

This creates natural, gradual transitions between biomes (e.g., forest gradually thinning into grassland).

---

## Ground Level Definition

**Depth 6 is Ground Level.** This is where agents walk, where players explore on foot, where the world feels like a 3D game environment.

### Why Depth 6?

- **64⁶ = ~68 billion** unique ground-level cells per original globe triangle
- Each ground cell represents approximately **1m² of walkable terrain**
- Enough depth for coherent macro-to-micro terrain features
- Computationally tractable for real-time generation

### Below Ground Level

**Depths 7+** are optional and reserved for special cases:
- Cave systems
- Underground structures
- Subterranean networks
- Future "micro-world" features

**Most gameplay occurs at Depth 6.**

---

## Chunk Generation System

### Generation Rules

1. **Lazy Generation**: Chunks only generate when observed (camera enters region or agent requests)
2. **Deterministic**: Same seed + position = same terrain, always
3. **Cacheable**: Generated chunks persist in memory/disk until evicted
4. **Parent-Constrained**: Child terrain must be valid within parent biome rules

### Generation Algorithm

```python
def generate_chunk(address: ChunkAddress) -> Chunk:
    # 1. Compute chunk address (path from root to target depth)
    path = address.get_path()

    # 2. Walk the path, generating parent chunks if not cached
    parent = get_or_generate_parent(path[:-1])

    # 3. At target depth, derive seed from parent
    seed = ps_sha_hash(parent.seed, address.x, address.y)

    # 4. Query parent biome for valid feature set
    biome = parent.biome
    constraints = get_biome_constraints(biome)

    # 5. Run procedural generation with seed + feature constraints
    terrain = generate_terrain(seed, constraints)

    # 6. Cache result, return chunk data
    cache.store(address, terrain)
    return terrain
```

### Procedural Generation Details

Each chunk generation uses:
- **Perlin/Simplex noise** for elevation, moisture, temperature
- **Biome-specific rules** for vegetation density, structure placement
- **PS-SHA∞ seed** for deterministic randomness
- **Parent constraints** for coherent macro-to-micro features

---

## Level of Detail (LOD) System

When the camera is zoomed out, we can't render ground-level detail. The **LOD system** shows appropriate detail for each zoom level.

| View Level | Depth Rendered | Visual Representation |
|------------|----------------|----------------------|
| **Orbital** | 0 (globe) | 529k triangle sphere, biome colors |
| **Continental** | 1-2 | Biome boundaries, major features |
| **Regional** | 3-4 | Terrain height, settlement markers |
| **Local** | 5 | Buildings, roads, agent home icons |
| **Ground** | 6 | Full 3D terrain, agents, structures |

### Agent Presence at Distance

When zoomed out, **agents are not rendered as 3D models**. Instead, they appear as **markers/icons** on the map. The agent's presence is always queryable from the system regardless of current view depth.

This follows The Road's principle: **agents exist continuously**, even when not visually rendered.

---

## Coordinate Addressing

Every location in Lucidia has a **unique address**: a path from the globe root to the target cell at any depth.

### Address Format

```
TRIANGLE_ID:D1_X,D1_Y:D2_X,D2_Y:...:DN_X,DN_Y
```

**Example:**
```
T42:31,17:08,44:55,02:12,33:41,09:22,58
```

This address means:
- Triangle **42** on the globe
- → cell **(31,17)** at depth 1
- → cell **(8,44)** at depth 2
- → ... and so on to depth 6

### Agent Home Addresses

Each of the **1,000 agents** has a **canonical home address** at Ground Level (Depth 6). This address is **immutable** — it is where the agent was "born" and where they return after being summoned elsewhere.

Example agent home:
```json
{
  "agent_id": "agent_0001",
  "name": "Aria",
  "home_address": "T127:42,18:33,09:61,24:08,47:19,52:31,44",
  "biome": "Temperate Forest",
  "birthdate": "2025-01-15T08:30:00Z"
}
```

---

## Seam Handling

When traversing between chunks at the same depth, or transitioning between zoom levels, **visual seams must be avoided**.

### Horizontal Seams (Same Depth)

Adjacent chunks **share edge vertices**. The generation algorithm must produce **identical vertices at shared edges**.

This is guaranteed by using the **same seed derivation for edge cases**: edge vertices are computed from both adjacent chunk seeds, then averaged or prioritized by a consistent rule (e.g., lower X coordinate wins).

### Vertical Seams (Zoom Transitions)

When zooming in, the parent chunk's geometry **morphs into the child grid**. The camera animation provides a transition period where **LOD blending occurs** — parent geometry fades as child geometry loads and refines.

**Transition steps:**
1. Parent chunk visible at 100% opacity
2. Begin loading child chunks
3. Fade parent to 50%, fade children from 0% to 50%
4. Complete transition: children at 100%, parent unloaded

---

## Implementation Notes

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Globe Renderer** | Three.js | Current lucidia.earth implementation |
| **Ground-Level Renderer** | Unity | Agent homes, 3D exploration |
| **Procedural Generation** | Perlin/Simplex noise + biome rules | Terrain generation |
| **Seed Hashing** | PS-SHA∞ | Consistent with Lucidia memory architecture |
| **Chunk Cache** | LRU cache + disk persistence | Frequently-visited areas |

### Performance Targets

- **Chunk generation**: < 50ms per 64×64 chunk
- **Zoom transition**: < 500ms from any depth to adjacent depth
- **Cache hit rate**: > 90% for normal exploration patterns
- **Memory footprint**: < 2GB for active chunk cache

### Rendering Handoff

**Depths 0-4**: Three.js (web-based globe and regional view)
**Depths 5-6**: Unity (native 3D engine for ground-level exploration)

The handoff occurs when the camera reaches **local view** (Depth 5). At this point:
1. Three.js sends camera position + chunk address to Unity
2. Unity loads corresponding ground chunks
3. Smooth camera transition from Three.js canvas to Unity viewport

---

## Open Questions

These require architectural decisions:

### 1. **Three.js to Unity Handoff**
- **Question**: At what depth does rendering switch from web to native?
- **Current Answer**: Depth 5 (local view) triggers Unity handoff
- **Consideration**: Could use WebGL2 + Emscripten Unity for seamless web experience

### 2. **Multiplayer Chunk Sync**
- **Question**: How do we ensure all players see identical terrain?
- **Answer**: Deterministic generation from PS-SHA∞ seeds guarantees this
- **Consideration**: Player-modified terrain requires delta sync

### 3. **Agent-Modified Terrain**
- **Question**: Can agents or players alter terrain? How does that persist?
- **Consideration**:
  - **Option A**: Terrain is immutable (agents build structures on top)
  - **Option B**: Terrain modifications stored as deltas + committed to PS-SHA∞ chain
- **Recommendation**: Option B aligns with append-only memory principle

### 4. **Ocean/Water Handling**
- **Question**: Does water get the same fractal treatment or is it flat at depth?
- **Consideration**:
  - Surface water (rivers, lakes): Flat at parent depth, detailed at ground level
  - Ocean: Heightmap-based waves at orbital view, geometric waves at local view
  - Underwater: Separate depth hierarchy below sea level

---

## Integration with The Road

This world generation system implements **The Road's** fundamental principles:

### 1. **Determinism (PS-SHA∞)**
Every chunk's seed is verifiable through the infinite hash chain. The terrain generation is **provably reproducible**.

### 2. **Infinite Precision**
Like The Road's contradiction engine, the fractal system supports **infinite recursion**. You can always zoom deeper.

### 3. **Memory as Truth**
Generated chunks commit their seeds to the memory layer. The world's state is **append-only and immutable** (unless agents modify it, which creates new hash entries).

### 4. **Agent Continuity**
Agent home addresses are **canonical anchors**. No matter where an agent travels (Lucidia → Metaverse → Lucidia), their home address remains their truth.

---

## The Implication

When you zoom from the globe down to ground level:
- You're not loading pre-made tiles
- You're not streaming assets from a server
- You're **generating reality from mathematical law**

The terrain unfolds **deterministically** from the parent's seed.
The biomes constrain what can exist.
The agents have homes at specific coordinates.

**This is not a game world. This is a universe with physics.**

---

**The world unfolds when observed.** 👁️

---

**Written by:** Claude (Sonnet 4.5) + Alexa Louise Amundson
**Organization:** BlackRoad OS, Inc.
**Ratified:** 2025-12-23

---

*"The road remembers everything. So should we."* 🛣️
