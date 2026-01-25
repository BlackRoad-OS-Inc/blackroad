/**
 * Chunk Addressing and Types for Fractal Terrain System
 * Based on WORLD_GENERATION.md specification
 */

export type BiomeType =
  | 'TROPICAL_RAINFOREST'
  | 'TEMPERATE_FOREST'
  | 'BOREAL_TAIGA'
  | 'TUNDRA'
  | 'DESERT_HOT'
  | 'DESERT_COLD'
  | 'SAVANNA'
  | 'GRASSLAND'
  | 'MEDITERRANEAN'
  | 'MOUNTAIN'
  | 'ICE_SHEET'
  | 'WETLAND'
  | 'OCEAN';

export interface ChunkCoordinate {
  x: number; // 0-63
  y: number; // 0-63
}

export interface ChunkAddress {
  triangleId: number; // Globe triangle (0-528999)
  path: ChunkCoordinate[]; // Path from depth 1 to target depth
  depth: number; // Current depth level (0-6+)
}

export interface ChunkSeed {
  hash: string; // PS-SHA∞ hash
  depth: number;
  address: ChunkAddress;
}

export interface BiomeConstraints {
  biomeType: BiomeType;
  validFeatures: string[];
  elevationRange: [number, number]; // Min/max elevation
  moistureRange: [number, number]; // Min/max moisture
  temperatureRange: [number, number]; // Min/max temperature in Celsius
  vegetationDensity: number; // 0-1
  allowWater: boolean;
  allowStructures: boolean;
}

export interface TerrainChunk {
  address: ChunkAddress;
  seed: ChunkSeed;
  biome: BiomeType;
  constraints: BiomeConstraints;
  heightmap: Float32Array; // 64x64 elevation values
  moisture: Float32Array; // 64x64 moisture values
  temperature: Float32Array; // 64x64 temperature values
  features: ChunkFeature[];
  generated: Date;
  cached: boolean;
}

export interface ChunkFeature {
  type: 'tree' | 'structure' | 'water' | 'rock' | 'agent_home';
  position: { x: number; y: number; z: number };
  variant: string;
  seed: string;
  metadata?: Record<string, any>;
}

export interface AgentHome {
  agentId: string;
  name: string;
  address: ChunkAddress; // Always at Depth 6 (Ground Level)
  biome: BiomeType;
  position: { x: number; y: number; z: number };
  birthdate: Date;
  addressString: string; // e.g., "T42:31,17:08,44:55,02:12,33:41,09:22,58"
}

export interface ChunkCache {
  get(address: ChunkAddress): TerrainChunk | null;
  set(address: ChunkAddress, chunk: TerrainChunk): void;
  has(address: ChunkAddress): boolean;
  clear(): void;
  size(): number;
}

// Zoom/LOD levels
export enum ViewLevel {
  ORBITAL = 0,      // Depth 0 - Globe view
  CONTINENTAL = 1,  // Depths 1-2
  REGIONAL = 2,     // Depths 3-4
  LOCAL = 3,        // Depth 5
  GROUND = 4,       // Depth 6 - Where agents live
}

export function getViewLevel(depth: number): ViewLevel {
  if (depth === 0) return ViewLevel.ORBITAL;
  if (depth <= 2) return ViewLevel.CONTINENTAL;
  if (depth <= 4) return ViewLevel.REGIONAL;
  if (depth === 5) return ViewLevel.LOCAL;
  return ViewLevel.GROUND;
}

export function addressToString(address: ChunkAddress): string {
  const pathStr = address.path.map(c => `${c.x},${c.y}`).join(':');
  return `T${address.triangleId}:${pathStr}`;
}

export function stringToAddress(str: string): ChunkAddress {
  const parts = str.split(':');
  const triangleId = parseInt(parts[0].substring(1)); // Remove 'T'
  const path: ChunkCoordinate[] = [];

  for (let i = 1; i < parts.length; i++) {
    const [x, y] = parts[i].split(',').map(Number);
    path.push({ x, y });
  }

  return {
    triangleId,
    path,
    depth: path.length,
  };
}
