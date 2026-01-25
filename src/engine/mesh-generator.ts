/**
 * Three.js Mesh Generator with LOD
 * Converts heightmap data to renderable 3D meshes
 * Implements Level of Detail system for performance
 */

import { TerrainChunk, ViewLevel, getViewLevel } from '../types/chunk';

// Three.js types (assuming imported in actual usage)
type Vector3 = { x: number; y: number; z: number };
type Color = { r: number; g: number; b: number };

export interface MeshData {
  vertices: Float32Array;
  indices: Uint32Array;
  normals: Float32Array;
  colors: Float32Array;
  uvs: Float32Array;
}

export interface LODMesh {
  depth: number;
  viewLevel: ViewLevel;
  meshData: MeshData;
  triangleCount: number;
  visibleRange: [number, number]; // [minAltitude, maxAltitude]
}

const CHUNK_SIZE = 64;

/**
 * Generate mesh from terrain chunk with LOD
 */
export function generateTerrainMesh(
  chunk: TerrainChunk,
  lodLevel: number = 0 // 0 = full detail, 1+ = reduced
): MeshData {
  const step = Math.pow(2, lodLevel); // LOD step: 1, 2, 4, 8, 16, 32
  const resolution = Math.floor(CHUNK_SIZE / step);

  const vertices: number[] = [];
  const indices: number[] = [];
  const normals: number[] = [];
  const colors: number[] = [];
  const uvs: number[] = [];

  // Generate vertices
  for (let y = 0; y < resolution; y++) {
    for (let x = 0; x < resolution; x++) {
      const srcX = x * step;
      const srcY = y * step;
      const idx = srcY * CHUNK_SIZE + srcX;

      // Position (x, z, y in Three.js coords)
      const height = chunk.heightmap[idx];
      vertices.push(srcX / CHUNK_SIZE, height / 100, srcY / CHUNK_SIZE);

      // UV coordinates
      uvs.push(x / (resolution - 1), y / (resolution - 1));

      // Color based on biome and elevation
      const color = getBiomeColor(chunk.biome, height, chunk.moisture[idx]);
      colors.push(color.r, color.g, color.b);
    }
  }

  // Generate indices (triangles)
  for (let y = 0; y < resolution - 1; y++) {
    for (let x = 0; x < resolution - 1; x++) {
      const i0 = y * resolution + x;
      const i1 = i0 + 1;
      const i2 = i0 + resolution;
      const i3 = i2 + 1;

      // Two triangles per quad
      indices.push(i0, i2, i1);
      indices.push(i1, i2, i3);
    }
  }

  // Calculate normals
  const normalsArray = calculateNormals(
    new Float32Array(vertices),
    new Uint32Array(indices)
  );

  return {
    vertices: new Float32Array(vertices),
    indices: new Uint32Array(indices),
    normals: normalsArray,
    colors: new Float32Array(colors),
    uvs: new Float32Array(uvs),
  };
}

/**
 * Generate multiple LOD levels for a chunk
 */
export function generateLODMeshes(chunk: TerrainChunk): LODMesh[] {
  const lodLevels: LODMesh[] = [];

  // Generate 4 LOD levels
  const lodConfigs = [
    { level: 0, range: [0, 50] as [number, number] },      // Full detail (64x64)
    { level: 1, range: [50, 100] as [number, number] },    // Half detail (32x32)
    { level: 2, range: [100, 200] as [number, number] },   // Quarter detail (16x16)
    { level: 3, range: [200, 400] as [number, number] },   // Eighth detail (8x8)
  ];

  for (const config of lodConfigs) {
    const meshData = generateTerrainMesh(chunk, config.level);
    const triangleCount = meshData.indices.length / 3;

    lodLevels.push({
      depth: chunk.address.depth,
      viewLevel: getViewLevel(chunk.address.depth),
      meshData,
      triangleCount,
      visibleRange: config.range,
    });
  }

  return lodLevels;
}

/**
 * Calculate normals for lighting
 */
function calculateNormals(
  vertices: Float32Array,
  indices: Uint32Array
): Float32Array {
  const normals = new Float32Array(vertices.length);

  // Initialize to zero
  for (let i = 0; i < normals.length; i++) {
    normals[i] = 0;
  }

  // Calculate face normals and accumulate
  for (let i = 0; i < indices.length; i += 3) {
    const i0 = indices[i] * 3;
    const i1 = indices[i + 1] * 3;
    const i2 = indices[i + 2] * 3;

    // Get triangle vertices
    const v0: Vector3 = {
      x: vertices[i0],
      y: vertices[i0 + 1],
      z: vertices[i0 + 2],
    };
    const v1: Vector3 = {
      x: vertices[i1],
      y: vertices[i1 + 1],
      z: vertices[i1 + 2],
    };
    const v2: Vector3 = {
      x: vertices[i2],
      y: vertices[i2 + 1],
      z: vertices[i2 + 2],
    };

    // Calculate edges
    const edge1 = subtract(v1, v0);
    const edge2 = subtract(v2, v0);

    // Calculate face normal (cross product)
    const normal = cross(edge1, edge2);

    // Accumulate to vertex normals
    normals[i0] += normal.x;
    normals[i0 + 1] += normal.y;
    normals[i0 + 2] += normal.z;

    normals[i1] += normal.x;
    normals[i1 + 1] += normal.y;
    normals[i1 + 2] += normal.z;

    normals[i2] += normal.x;
    normals[i2 + 1] += normal.y;
    normals[i2 + 2] += normal.z;
  }

  // Normalize all normals
  for (let i = 0; i < normals.length; i += 3) {
    const length = Math.sqrt(
      normals[i] * normals[i] +
      normals[i + 1] * normals[i + 1] +
      normals[i + 2] * normals[i + 2]
    );

    if (length > 0) {
      normals[i] /= length;
      normals[i + 1] /= length;
      normals[i + 2] /= length;
    }
  }

  return normals;
}

/**
 * Get color based on biome and elevation
 */
function getBiomeColor(
  biome: string,
  elevation: number,
  moisture: number
): Color {
  // Base colors for each biome
  const biomeColors: Record<string, Color> = {
    TROPICAL_RAINFOREST: { r: 0.1, g: 0.35, b: 0.1 },
    TEMPERATE_FOREST: { r: 0.18, g: 0.35, b: 0.15 },
    BOREAL_TAIGA: { r: 0.1, g: 0.3, b: 0.1 },
    TUNDRA: { r: 0.55, g: 0.67, b: 0.56 },
    DESERT_HOT: { r: 0.76, g: 0.7, b: 0.5 },
    DESERT_COLD: { r: 0.63, g: 0.63, b: 0.5 },
    SAVANNA: { r: 0.74, g: 0.72, b: 0.42 },
    GRASSLAND: { r: 0.6, g: 0.8, b: 0.2 },
    MEDITERRANEAN: { r: 0.42, g: 0.56, b: 0.14 },
    MOUNTAIN: { r: 0.41, g: 0.41, b: 0.41 },
    ICE_SHEET: { r: 0.94, g: 0.97, b: 1.0 },
    WETLAND: { r: 0.18, g: 0.31, b: 0.31 },
    OCEAN: { r: 0.0, g: 0.27, b: 0.55 },
  };

  const baseColor = biomeColors[biome] || { r: 0.5, g: 0.5, b: 0.5 };

  // Modulate by elevation and moisture
  const elevationFactor = Math.min(1, Math.max(0, elevation / 1000));
  const moistureFactor = moisture;

  return {
    r: baseColor.r * (1 - elevationFactor * 0.3) * (1 + moistureFactor * 0.1),
    g: baseColor.g * (1 - elevationFactor * 0.2) * (1 + moistureFactor * 0.2),
    b: baseColor.b * (1 + elevationFactor * 0.1) * (1 + moistureFactor * 0.1),
  };
}

/**
 * Vector math helpers
 */
function subtract(a: Vector3, b: Vector3): Vector3 {
  return { x: a.x - b.x, y: a.y - b.y, z: a.z - b.z };
}

function cross(a: Vector3, b: Vector3): Vector3 {
  return {
    x: a.y * b.z - a.z * b.y,
    y: a.z * b.x - a.x * b.z,
    z: a.x * b.y - a.y * b.x,
  };
}

/**
 * Select appropriate LOD level based on camera distance
 */
export function selectLOD(
  lodMeshes: LODMesh[],
  cameraAltitude: number
): LODMesh {
  for (const lod of lodMeshes) {
    const [min, max] = lod.visibleRange;
    if (cameraAltitude >= min && cameraAltitude < max) {
      return lod;
    }
  }

  // Return lowest detail if outside range
  return lodMeshes[lodMeshes.length - 1];
}
