/**
 * LOD (Level of Detail) Manager
 * Handles dynamic mesh loading/unloading based on camera position
 * Manages transitions between depth levels (0-6)
 */

import { ChunkAddress, ViewLevel, getViewLevel } from '../types/chunk';
import { generateChunk } from '../generators/terrain-generator';
import { generateLODMeshes, LODMesh, selectLOD } from './mesh-generator';

export interface CameraState {
  position: { x: number; y: number; z: number };
  target: { x: number; y: number; z: number };
  altitude: number; // Distance from surface
  depth: number; // Current zoom depth (0-6)
}

export interface VisibleChunk {
  address: ChunkAddress;
  lodMeshes: LODMesh[];
  currentLOD: LODMesh;
  distance: number;
}

export class LODManager {
  private visibleChunks: Map<string, VisibleChunk> = new Map();
  private camera: CameraState;
  private currentDepth: number = 0;
  private targetDepth: number = 0;
  private transitionProgress: number = 1; // 0-1, 1 = complete

  constructor(initialCamera: CameraState) {
    this.camera = initialCamera;
  }

  /**
   * Update camera state and manage LOD transitions
   */
  update(newCamera: CameraState, deltaTime: number): void {
    this.camera = newCamera;

    // Determine target depth based on altitude
    this.targetDepth = this.getDepthFromAltitude(newCamera.altitude);

    // Handle depth transitions
    if (this.currentDepth !== this.targetDepth) {
      this.transitionProgress = Math.min(1, this.transitionProgress + deltaTime * 2);

      if (this.transitionProgress >= 1) {
        this.currentDepth = this.targetDepth;
        this.onDepthChange();
      }
    } else {
      this.transitionProgress = 1;
    }

    // Update visible chunks
    this.updateVisibleChunks();
  }

  /**
   * Get current camera state
   */
  getCamera(): CameraState {
    return this.camera;
  }

  /**
   * Get current depth level
   */
  getCurrentDepth(): number {
    return this.currentDepth;
  }

  /**
   * Get transition progress (for smooth LOD blending)
   */
  getTransitionProgress(): number {
    return this.transitionProgress;
  }

  /**
   * Get all visible chunks
   */
  getVisibleChunks(): VisibleChunk[] {
    return Array.from(this.visibleChunks.values());
  }

  /**
   * Determine depth level from camera altitude
   * Based on WORLD_GENERATION.md zoom levels
   */
  private getDepthFromAltitude(altitude: number): number {
    if (altitude > 250) return 0;  // Orbital - Globe view
    if (altitude > 150) return 1;  // Continental
    if (altitude > 90) return 2;   // Regional
    if (altitude > 60) return 3;   // Country
    if (altitude > 40) return 4;   // State
    if (altitude > 25) return 5;   // Local
    return 6;                      // Ground level
  }

  /**
   * Called when depth level changes
   */
  private onDepthChange(): void {
    console.log(`[LOD] Depth changed to ${this.currentDepth} (${getViewLevel(this.currentDepth)})`);

    // Clear chunks from previous depth
    this.visibleChunks.clear();

    // Trigger chunk loading for new depth
    this.updateVisibleChunks();
  }

  /**
   * Update which chunks are visible and their LOD
   */
  private updateVisibleChunks(): void {
    // For now, simplified: load chunks in view frustum at current depth
    // In production, this would use frustum culling

    // Determine visible region based on camera position
    const visibleRadius = this.getVisibleRadius();
    const chunkAddresses = this.getChunksInRadius(
      this.camera.position,
      visibleRadius,
      this.currentDepth
    );

    // Update or add visible chunks
    for (const address of chunkAddresses) {
      const key = this.addressToKey(address);

      if (!this.visibleChunks.has(key)) {
        // Generate new chunk
        const chunk = generateChunk(address);
        const lodMeshes = generateLODMeshes(chunk);
        const distance = this.getDistanceToChunk(address);
        const currentLOD = selectLOD(lodMeshes, this.camera.altitude);

        this.visibleChunks.set(key, {
          address,
          lodMeshes,
          currentLOD,
          distance,
        });
      } else {
        // Update existing chunk's LOD
        const visibleChunk = this.visibleChunks.get(key)!;
        visibleChunk.distance = this.getDistanceToChunk(address);
        visibleChunk.currentLOD = selectLOD(
          visibleChunk.lodMeshes,
          this.camera.altitude
        );
      }
    }

    // Remove chunks outside visible radius
    for (const [key, chunk] of this.visibleChunks.entries()) {
      if (chunk.distance > visibleRadius * 1.5) {
        this.visibleChunks.delete(key);
      }
    }
  }

  /**
   * Get visible radius based on current altitude
   */
  private getVisibleRadius(): number {
    // Higher altitude = larger visible area
    return Math.max(1, this.camera.altitude * 0.5);
  }

  /**
   * Get chunks within radius at current depth
   * Simplified: returns center chunk and neighbors
   */
  private getChunksInRadius(
    position: { x: number; y: number; z: number },
    radius: number,
    depth: number
  ): ChunkAddress[] {
    // Simplified implementation - returns 3x3 grid around camera
    const addresses: ChunkAddress[] = [];

    // At depth 0, just return single global chunk
    if (depth === 0) {
      return [{
        triangleId: 0,
        path: [],
        depth: 0,
      }];
    }

    // For deeper depths, create a grid
    const gridSize = 3; // 3x3 grid
    for (let y = 0; y < gridSize; y++) {
      for (let x = 0; x < gridSize; x++) {
        const path: { x: number; y: number }[] = [];

        // Build path to depth
        for (let d = 0; d < depth; d++) {
          path.push({
            x: Math.floor(x * 64 / gridSize),
            y: Math.floor(y * 64 / gridSize),
          });
        }

        addresses.push({
          triangleId: 0, // Simplified
          path,
          depth,
        });
      }
    }

    return addresses;
  }

  /**
   * Get distance from camera to chunk
   */
  private getDistanceToChunk(address: ChunkAddress): number {
    // Simplified: use address depth as proxy for distance
    return Math.abs(this.currentDepth - address.depth) * 100;
  }

  /**
   * Convert address to cache key
   */
  private addressToKey(address: ChunkAddress): string {
    return `${address.triangleId}:${address.path.map(p => `${p.x},${p.y}`).join(':')}`;
  }

  /**
   * Get statistics
   */
  getStats() {
    return {
      currentDepth: this.currentDepth,
      targetDepth: this.targetDepth,
      transitionProgress: this.transitionProgress,
      visibleChunks: this.visibleChunks.size,
      cameraAltitude: this.camera.altitude,
      viewLevel: getViewLevel(this.currentDepth),
    };
  }
}
