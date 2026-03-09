/**
 * Three.js Terrain Renderer
 * Main scene controller integrating LODManager with Three.js rendering
 * Handles camera controls, mesh rendering, and depth transitions
 */

import * as THREE from 'three';
import { LODManager, CameraState, VisibleChunk } from './lod-manager';
import { MeshData } from './mesh-generator';

export interface RendererConfig {
  canvas: HTMLCanvasElement;
  initialAltitude?: number;
  enableStats?: boolean;
}

export class TerrainRenderer {
  private scene: THREE.Scene;
  private camera: THREE.PerspectiveCamera;
  private renderer: THREE.WebGLRenderer;
  private lodManager: LODManager;

  private meshes: Map<string, THREE.Mesh> = new Map();
  private animationFrameId: number | null = null;
  private lastFrameTime: number = 0;

  // Camera controls
  private targetPosition: THREE.Vector3;
  private currentPosition: THREE.Vector3;
  private targetAltitude: number;
  private currentAltitude: number;

  constructor(config: RendererConfig) {
    // Initialize Three.js scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x87ceeb); // Sky blue

    // Setup camera
    this.camera = new THREE.PerspectiveCamera(
      60,
      window.innerWidth / window.innerHeight,
      0.1,
      10000
    );

    // Initialize camera position (start at orbital view)
    this.currentAltitude = config.initialAltitude || 300;
    this.targetAltitude = this.currentAltitude;
    this.currentPosition = new THREE.Vector3(0, this.currentAltitude, 0);
    this.targetPosition = this.currentPosition.clone();
    this.camera.position.copy(this.currentPosition);
    this.camera.lookAt(0, 0, 0);

    // Setup renderer
    this.renderer = new THREE.WebGLRenderer({
      canvas: config.canvas,
      antialias: true,
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(window.devicePixelRatio);

    // Initialize LOD manager
    const initialCamera: CameraState = {
      position: { x: 0, y: this.currentAltitude, z: 0 },
      target: { x: 0, y: 0, z: 0 },
      altitude: this.currentAltitude,
      depth: 0,
    };
    this.lodManager = new LODManager(initialCamera);

    // Add lighting
    this.setupLighting();

    // Handle window resize
    window.addEventListener('resize', this.onWindowResize.bind(this));
  }

  /**
   * Setup scene lighting
   */
  private setupLighting(): void {
    // Ambient light
    const ambient = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambient);

    // Directional light (sun)
    const sun = new THREE.DirectionalLight(0xffffff, 0.8);
    sun.position.set(100, 200, 100);
    sun.castShadow = true;
    this.scene.add(sun);

    // Hemisphere light (sky/ground)
    const hemisphere = new THREE.HemisphereLight(0x87ceeb, 0x4a4a2a, 0.4);
    this.scene.add(hemisphere);
  }

  /**
   * Start rendering loop
   */
  start(): void {
    if (this.animationFrameId !== null) return;
    this.lastFrameTime = performance.now();
    this.animate();
  }

  /**
   * Stop rendering loop
   */
  stop(): void {
    if (this.animationFrameId !== null) {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
  }

  /**
   * Main animation loop
   */
  private animate(): void {
    this.animationFrameId = requestAnimationFrame(this.animate.bind(this));

    const now = performance.now();
    const deltaTime = (now - this.lastFrameTime) / 1000; // Convert to seconds
    this.lastFrameTime = now;

    // Update camera position (smooth interpolation)
    this.updateCamera(deltaTime);

    // Update LOD manager
    const cameraState: CameraState = {
      position: {
        x: this.currentPosition.x,
        y: this.currentPosition.y,
        z: this.currentPosition.z,
      },
      target: { x: 0, y: 0, z: 0 },
      altitude: this.currentAltitude,
      depth: this.lodManager.getCurrentDepth(),
    };
    this.lodManager.update(cameraState, deltaTime);

    // Update meshes
    this.updateMeshes();

    // Render
    this.renderer.render(this.scene, this.camera);
  }

  /**
   * Update camera position with smooth interpolation
   */
  private updateCamera(deltaTime: number): void {
    const lerpSpeed = 2.0 * deltaTime;

    // Interpolate altitude
    this.currentAltitude += (this.targetAltitude - this.currentAltitude) * lerpSpeed;

    // Interpolate position
    this.currentPosition.lerp(this.targetPosition, lerpSpeed);
    this.currentPosition.y = this.currentAltitude;

    // Update camera
    this.camera.position.copy(this.currentPosition);
    this.camera.lookAt(0, 0, 0);
  }

  /**
   * Update visible meshes based on LOD manager
   */
  private updateMeshes(): void {
    const visibleChunks = this.lodManager.getVisibleChunks();
    const visibleKeys = new Set<string>();

    // Add or update visible chunks
    for (const chunk of visibleChunks) {
      const key = this.addressToKey(chunk.address);
      visibleKeys.add(key);

      if (!this.meshes.has(key)) {
        // Create new mesh
        const mesh = this.createMesh(chunk);
        this.meshes.set(key, mesh);
        this.scene.add(mesh);
      } else {
        // Update existing mesh LOD
        const mesh = this.meshes.get(key)!;
        this.updateMeshLOD(mesh, chunk);
      }
    }

    // Remove chunks that are no longer visible
    for (const [key, mesh] of this.meshes.entries()) {
      if (!visibleKeys.has(key)) {
        this.scene.remove(mesh);
        mesh.geometry.dispose();
        if (mesh.material instanceof THREE.Material) {
          mesh.material.dispose();
        }
        this.meshes.delete(key);
      }
    }
  }

  /**
   * Create Three.js mesh from chunk data
   */
  private createMesh(chunk: VisibleChunk): THREE.Mesh {
    const meshData = chunk.currentLOD.meshData;
    const geometry = this.createGeometry(meshData);

    const material = new THREE.MeshStandardMaterial({
      vertexColors: true,
      flatShading: false,
      roughness: 0.8,
      metalness: 0.2,
    });

    const mesh = new THREE.Mesh(geometry, material);

    // Position mesh based on chunk address
    // For now, center at origin (will be updated for proper positioning)
    mesh.position.set(0, 0, 0);

    return mesh;
  }

  /**
   * Create Three.js geometry from mesh data
   */
  private createGeometry(meshData: MeshData): THREE.BufferGeometry {
    const geometry = new THREE.BufferGeometry();

    geometry.setAttribute(
      'position',
      new THREE.BufferAttribute(meshData.vertices, 3)
    );
    geometry.setAttribute(
      'normal',
      new THREE.BufferAttribute(meshData.normals, 3)
    );
    geometry.setAttribute(
      'color',
      new THREE.BufferAttribute(meshData.colors, 3)
    );
    geometry.setAttribute(
      'uv',
      new THREE.BufferAttribute(meshData.uvs, 2)
    );
    geometry.setIndex(new THREE.BufferAttribute(meshData.indices, 1));

    return geometry;
  }

  /**
   * Update mesh LOD level
   */
  private updateMeshLOD(mesh: THREE.Mesh, chunk: VisibleChunk): void {
    const newMeshData = chunk.currentLOD.meshData;
    const geometry = this.createGeometry(newMeshData);

    // Dispose old geometry
    mesh.geometry.dispose();

    // Update with new geometry
    mesh.geometry = geometry;
  }

  /**
   * Zoom to specific depth level
   */
  zoomToDepth(depth: number): void {
    // Map depth to altitude based on LODManager thresholds
    const altitudes = [300, 180, 120, 75, 50, 32, 15]; // Depths 0-6
    this.targetAltitude = altitudes[Math.min(depth, 6)];
  }

  /**
   * Zoom in (decrease altitude)
   */
  zoomIn(): void {
    this.targetAltitude = Math.max(10, this.targetAltitude * 0.7);
  }

  /**
   * Zoom out (increase altitude)
   */
  zoomOut(): void {
    this.targetAltitude = Math.min(400, this.targetAltitude * 1.4);
  }

  /**
   * Get current stats
   */
  getStats() {
    return {
      ...this.lodManager.getStats(),
      meshCount: this.meshes.size,
      fps: Math.round(1000 / (performance.now() - this.lastFrameTime)),
    };
  }

  /**
   * Handle window resize
   */
  private onWindowResize(): void {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }

  /**
   * Convert address to cache key
   */
  private addressToKey(address: any): string {
    return `${address.triangleId}:${address.path.map((p: any) => `${p.x},${p.y}`).join(':')}`;
  }

  /**
   * Cleanup
   */
  dispose(): void {
    this.stop();

    // Dispose all meshes
    for (const mesh of this.meshes.values()) {
      this.scene.remove(mesh);
      mesh.geometry.dispose();
      if (mesh.material instanceof THREE.Material) {
        mesh.material.dispose();
      }
    }
    this.meshes.clear();

    // Dispose renderer
    this.renderer.dispose();

    // Remove event listeners
    window.removeEventListener('resize', this.onWindowResize.bind(this));
  }
}
