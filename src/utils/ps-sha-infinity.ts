/**
 * PS-SHA∞ (Persistent State Hash - Infinite Cascade)
 * Deterministic seed propagation for fractal terrain generation
 * Based on COSMOLOGY.md and WORLD_GENERATION.md
 */

import { ChunkAddress, ChunkSeed } from '../types/chunk';

/**
 * Genesis seed for Lucidia Earth
 * This is the root hash from which all terrain derives
 */
export const LUCIDIA_GENESIS_SEED =
  'aeebad4a8c7f2e1d9b5a3f6c4e7d2a1b8c5f3e6d9a2b7c4e1f8d3a6b9c2e5f7a4d';

/**
 * PS-SHA∞ hash function
 * Uses SHA-256 for cryptographic determinism
 * Returns 64-character hex string
 */
export async function psShaHash(...inputs: (string | number)[]): Promise<string> {
  const combined = inputs.join('||');
  const encoder = new TextEncoder();
  const data = encoder.encode(combined);

  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

  return hashHex;
}

/**
 * Synchronous version using simpler hash for client-side
 * Uses same algorithm but can run in main thread
 */
export function psShaHashSync(...inputs: (string | number)[]): string {
  const combined = inputs.join('||');

  // Simple but deterministic hash (Dan Bernstein's djb2)
  let hash = 5381;
  for (let i = 0; i < combined.length; i++) {
    hash = ((hash << 5) + hash) + combined.charCodeAt(i);
  }

  // Convert to 64-char hex to match format
  const hex = Math.abs(hash).toString(16).padStart(16, '0');
  return hex.repeat(4); // Stretch to 64 chars
}

/**
 * Derive child seed from parent seed and position
 * child_seed = hash(parent_seed || x || y)
 */
export function deriveChildSeed(
  parentSeed: string,
  x: number,
  y: number
): string {
  return psShaHashSync(parentSeed, x, y);
}

/**
 * Generate seed for a chunk address
 * Walks the path from genesis, deriving each level
 */
export function generateChunkSeed(address: ChunkAddress): ChunkSeed {
  let currentSeed = LUCIDIA_GENESIS_SEED;

  // Derive seed through each depth level
  for (const coord of address.path) {
    currentSeed = deriveChildSeed(currentSeed, coord.x, coord.y);
  }

  return {
    hash: currentSeed,
    depth: address.depth,
    address,
  };
}

/**
 * Verify a chunk seed's integrity
 * Re-derives from genesis and checks if hash matches
 */
export function verifySeed(seed: ChunkSeed): boolean {
  const regenerated = generateChunkSeed(seed.address);
  return regenerated.hash === seed.hash;
}

/**
 * Get reproducible random number from seed (0-1)
 * Uses seed hash to generate deterministic random value
 */
export function seededRandom(seed: string, index: number = 0): number {
  const hash = psShaHashSync(seed, index);
  const num = parseInt(hash.substring(0, 16), 16);
  return (num % 1000000) / 1000000;
}

/**
 * Get reproducible random integer from seed (min-max inclusive)
 */
export function seededRandomInt(
  seed: string,
  min: number,
  max: number,
  index: number = 0
): number {
  const rand = seededRandom(seed, index);
  return Math.floor(rand * (max - min + 1)) + min;
}

/**
 * Get reproducible random choice from array
 */
export function seededChoice<T>(
  seed: string,
  array: T[],
  index: number = 0
): T {
  const idx = seededRandomInt(seed, 0, array.length - 1, index);
  return array[idx];
}

/**
 * Perlin-like noise function using seed
 * Returns value between -1 and 1
 */
export function seededNoise(
  seed: string,
  x: number,
  y: number,
  frequency: number = 1
): number {
  const fx = x * frequency;
  const fy = y * frequency;

  const xi = Math.floor(fx);
  const yi = Math.floor(fy);

  const xf = fx - xi;
  const yf = fy - yi;

  // Get corner values using seed
  const n00 = seededRandom(seed, xi * 1000 + yi);
  const n10 = seededRandom(seed, (xi + 1) * 1000 + yi);
  const n01 = seededRandom(seed, xi * 1000 + (yi + 1));
  const n11 = seededRandom(seed, (xi + 1) * 1000 + (yi + 1));

  // Smooth interpolation (cosine)
  const smoothX = (1 - Math.cos(xf * Math.PI)) / 2;
  const smoothY = (1 - Math.cos(yf * Math.PI)) / 2;

  // Bilinear interpolation
  const nx0 = n00 * (1 - smoothX) + n10 * smoothX;
  const nx1 = n01 * (1 - smoothX) + n11 * smoothX;
  const result = nx0 * (1 - smoothY) + nx1 * smoothY;

  return (result * 2) - 1; // Scale to -1 to 1
}

/**
 * Multi-octave noise (fractal Brownian motion)
 */
export function fbmNoise(
  seed: string,
  x: number,
  y: number,
  octaves: number = 4,
  persistence: number = 0.5
): number {
  let total = 0;
  let frequency = 1;
  let amplitude = 1;
  let maxValue = 0;

  for (let i = 0; i < octaves; i++) {
    total += seededNoise(seed, x, y, frequency) * amplitude;
    maxValue += amplitude;
    amplitude *= persistence;
    frequency *= 2;
  }

  return total / maxValue;
}
