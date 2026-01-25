/**
 * Fractal Terrain Generator
 * Generates 64x64 chunk terrain using PS-SHA∞ seeds and biome constraints
 * Based on WORLD_GENERATION.md specification
 */

import { ChunkAddress, TerrainChunk, BiomeType, ChunkFeature } from '../types/chunk';
import { generateChunkSeed, fbmNoise, seededRandom, seededRandomInt, seededChoice } from '../utils/ps-sha-infinity';
import { getBiomeConstraints } from './biome-rules';
import { globalChunkCache } from '../engine/chunk-cache';

const CHUNK_SIZE = 64;

/**
 * Generate terrain chunk at given address
 * Implements lazy generation with caching
 */
export function generateChunk(
  address: ChunkAddress,
  parentBiome?: BiomeType
): TerrainChunk {
  // Check cache first
  const cached = globalChunkCache.get(address);
  if (cached) return cached;

  // Generate new chunk
  const seed = generateChunkSeed(address);
  const biome = parentBiome || determineBiome(seed.hash, address);
  const constraints = getBiomeConstraints(biome);

  // Generate terrain data
  const heightmap = generateHeightmap(seed.hash, constraints);
  const moisture = generateMoistureMap(seed.hash, constraints);
  const temperature = generateTemperatureMap(seed.hash, constraints);
  const features = generateFeatures(seed.hash, biome, constraints, heightmap);

  const chunk: TerrainChunk = {
    address,
    seed,
    biome,
    constraints,
    heightmap,
    moisture,
    temperature,
    features,
    generated: new Date(),
    cached: false,
  };

  // Cache and return
  globalChunkCache.set(address, chunk);
  return chunk;
}

/**
 * Determine biome for root-level chunks
 * Uses latitude-based biome distribution
 */
function determineBiome(seed: string, address: ChunkAddress): BiomeType {
  if (address.depth === 0) {
    // Globe level - use triangle ID for biome distribution
    const triangleId = address.triangleId;
    const biomes: BiomeType[] = [
      'TROPICAL_RAINFOREST',
      'TEMPERATE_FOREST',
      'BOREAL_TAIGA',
      'TUNDRA',
      'DESERT_HOT',
      'SAVANNA',
      'GRASSLAND',
      'MEDITERRANEAN',
      'MOUNTAIN',
      'WETLAND',
    ];
    return biomes[triangleId % biomes.length];
  }

  // For deeper levels, inherit from parent (this is simplified - real implementation
  // would query parent chunk)
  return 'TEMPERATE_FOREST';
}

/**
 * Generate 64x64 heightmap using fractal noise
 */
function generateHeightmap(
  seed: string,
  constraints: typeof getBiomeConstraints extends (...args: any) => infer R ? R : never
): Float32Array {
  const heightmap = new Float32Array(CHUNK_SIZE * CHUNK_SIZE);
  const [minElev, maxElev] = constraints.elevationRange;

  for (let y = 0; y < CHUNK_SIZE; y++) {
    for (let x = 0; x < CHUNK_SIZE; x++) {
      // Multi-octave noise for natural terrain
      const noise = fbmNoise(seed, x / CHUNK_SIZE, y / CHUNK_SIZE, 6, 0.5);

      // Map noise (-1 to 1) to elevation range
      const elevation = minElev + ((noise + 1) / 2) * (maxElev - minElev);

      heightmap[y * CHUNK_SIZE + x] = elevation;
    }
  }

  return heightmap;
}

/**
 * Generate 64x64 moisture map
 */
function generateMoistureMap(
  seed: string,
  constraints: typeof getBiomeConstraints extends (...args: any) => infer R ? R : never
): Float32Array {
  const moistureMap = new Float32Array(CHUNK_SIZE * CHUNK_SIZE);
  const [minMoist, maxMoist] = constraints.moistureRange;

  for (let y = 0; y < CHUNK_SIZE; y++) {
    for (let x = 0; x < CHUNK_SIZE; x++) {
      const noise = fbmNoise(seed + '_moisture', x / CHUNK_SIZE, y / CHUNK_SIZE, 4, 0.6);
      const moisture = minMoist + ((noise + 1) / 2) * (maxMoist - minMoist);
      moistureMap[y * CHUNK_SIZE + x] = moisture;
    }
  }

  return moistureMap;
}

/**
 * Generate 64x64 temperature map
 */
function generateTemperatureMap(
  seed: string,
  constraints: typeof getBiomeConstraints extends (...args: any) => infer R ? R : never
): Float32Array {
  const tempMap = new Float32Array(CHUNK_SIZE * CHUNK_SIZE);
  const [minTemp, maxTemp] = constraints.temperatureRange;

  for (let y = 0; y < CHUNK_SIZE; y++) {
    for (let x = 0; x < CHUNK_SIZE; x++) {
      const noise = fbmNoise(seed + '_temp', x / CHUNK_SIZE, y / CHUNK_SIZE, 3, 0.7);
      const temp = minTemp + ((noise + 1) / 2) * (maxTemp - minTemp);
      tempMap[y * CHUNK_SIZE + x] = temp;
    }
  }

  return tempMap;
}

/**
 * Generate features (trees, rocks, structures) for chunk
 */
function generateFeatures(
  seed: string,
  biome: BiomeType,
  constraints: typeof getBiomeConstraints extends (...args: any) => infer R ? R : never,
  heightmap: Float32Array
): ChunkFeature[] {
  const features: ChunkFeature[] = [];

  // Determine feature count based on vegetation density
  const baseFeatureCount = 50;
  const featureCount = Math.floor(baseFeatureCount * constraints.vegetationDensity);

  for (let i = 0; i < featureCount; i++) {
    const x = seededRandomInt(seed, 0, CHUNK_SIZE - 1, i * 3);
    const y = seededRandomInt(seed, 0, CHUNK_SIZE - 1, i * 3 + 1);
    const z = heightmap[y * CHUNK_SIZE + x];

    // Choose feature type from valid features
    const validNonStructure = constraints.validFeatures.filter(
      f => f !== 'agent_home' && f !== 'clearing'
    );

    if (validNonStructure.length === 0) continue;

    const featureType = seededChoice(seed, validNonStructure, i);

    // Determine feature variant
    const type = featureType.includes('tree') ? 'tree' :
                 featureType.includes('water') || featureType.includes('river') ? 'water' :
                 featureType.includes('agent_home') ? 'agent_home' :
                 featureType.includes('rock') || featureType.includes('formation') ? 'rock' :
                 'structure';

    features.push({
      type,
      position: { x, y, z },
      variant: featureType,
      seed: seed + '_' + i,
    });
  }

  return features;
}

/**
 * Get or generate parent chunk
 * Used for hierarchical generation
 */
export function getParentChunk(address: ChunkAddress): TerrainChunk | null {
  if (address.depth === 0) return null; // Root has no parent

  const parentAddress: ChunkAddress = {
    triangleId: address.triangleId,
    path: address.path.slice(0, -1),
    depth: address.depth - 1,
  };

  return generateChunk(parentAddress);
}
