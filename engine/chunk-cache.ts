/**
 * LRU Chunk Cache
 * Stores generated chunks with automatic eviction
 * Based on WORLD_GENERATION.md spec (< 2GB memory footprint, > 90% hit rate)
 */

import { ChunkAddress, TerrainChunk, ChunkCache, addressToString } from '../types/chunk';

export class LRUChunkCache implements ChunkCache {
  private cache: Map<string, { chunk: TerrainChunk; lastAccess: number }>;
  private maxSize: number;
  private hits: number = 0;
  private misses: number = 0;

  constructor(maxSize: number = 1000) {
    this.cache = new Map();
    this.maxSize = maxSize;
  }

  get(address: ChunkAddress): TerrainChunk | null {
    const key = addressToString(address);
    const entry = this.cache.get(key);

    if (entry) {
      // Update last access time
      entry.lastAccess = Date.now();
      this.hits++;
      return entry.chunk;
    }

    this.misses++;
    return null;
  }

  set(address: ChunkAddress, chunk: TerrainChunk): void {
    const key = addressToString(address);

    // Evict oldest if at capacity
    if (this.cache.size >= this.maxSize && !this.cache.has(key)) {
      this.evictOldest();
    }

    this.cache.set(key, {
      chunk: { ...chunk, cached: true },
      lastAccess: Date.now(),
    });
  }

  has(address: ChunkAddress): boolean {
    return this.cache.has(addressToString(address));
  }

  clear(): void {
    this.cache.clear();
    this.hits = 0;
    this.misses = 0;
  }

  size(): number {
    return this.cache.size;
  }

  getHitRate(): number {
    const total = this.hits + this.misses;
    return total === 0 ? 0 : this.hits / total;
  }

  getStats() {
    return {
      size: this.cache.size,
      maxSize: this.maxSize,
      hits: this.hits,
      misses: this.misses,
      hitRate: this.getHitRate(),
    };
  }

  private evictOldest(): void {
    let oldestKey: string | null = null;
    let oldestTime = Infinity;

    for (const [key, entry] of this.cache.entries()) {
      if (entry.lastAccess < oldestTime) {
        oldestTime = entry.lastAccess;
        oldestKey = key;
      }
    }

    if (oldestKey) {
      this.cache.delete(oldestKey);
    }
  }
}

// Global cache instance
export const globalChunkCache = new LRUChunkCache(1000);
