/**
 * INFINITE BIOME GENERATION
 *
 * Procedurally generates never-ending beautiful landscapes:
 * - Forests with trees and flowers
 * - Oceans with waves
 * - Mountains with snow
 * - Deserts with dunes
 * - Crystal caverns
 * - Floating islands
 * - And infinite more...
 */

import * as THREE from 'three';

/**
 * PERLIN NOISE
 * For natural terrain generation
 */
class PerlinNoise {
    constructor(seed = Math.random()) {
        this.grad3 = [[1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],
                      [1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],
                      [0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1]];
        this.p = [];
        for(let i=0; i<256; i++) {
            this.p[i] = Math.floor(Math.random() * 256);
        }
        this.perm = [];
        for(let i=0; i<512; i++) {
            this.perm[i] = this.p[i & 255];
        }
    }

    dot(g, x, y, z) {
        return g[0]*x + g[1]*y + g[2]*z;
    }

    mix(a, b, t) {
        return (1-t)*a + t*b;
    }

    fade(t) {
        return t*t*t*(t*(t*6-15)+10);
    }

    noise(x, y, z) {
        let X = Math.floor(x) & 255;
        let Y = Math.floor(y) & 255;
        let Z = Math.floor(z) & 255;

        x -= Math.floor(x);
        y -= Math.floor(y);
        z -= Math.floor(z);

        let u = this.fade(x);
        let v = this.fade(y);
        let w = this.fade(z);

        let A = this.perm[X  ]+Y, AA = this.perm[A]+Z, AB = this.perm[A+1]+Z;
        let B = this.perm[X+1]+Y, BA = this.perm[B]+Z, BB = this.perm[B+1]+Z;

        return this.mix(
            this.mix(
                this.mix(this.dot(this.grad3[this.perm[AA  ]%12], x, y, z),
                        this.dot(this.grad3[this.perm[BA  ]%12], x-1, y, z), u),
                this.mix(this.dot(this.grad3[this.perm[AB  ]%12], x, y-1, z),
                        this.dot(this.grad3[this.perm[BB  ]%12], x-1, y-1, z), u), v),
            this.mix(
                this.mix(this.dot(this.grad3[this.perm[AA+1]%12], x, y, z-1),
                        this.dot(this.grad3[this.perm[BA+1]%12], x-1, y, z-1), u),
                this.mix(this.dot(this.grad3[this.perm[AB+1]%12], x, y-1, z-1),
                        this.dot(this.grad3[this.perm[BB+1]%12], x-1, y-1, z-1), u), v), w);
    }
}

/**
 * BIOME TYPES
 */
export const BIOMES = {
    FOREST: {
        name: 'Enchanted Forest',
        colors: {
            ground: 0x2d5016,
            plants: 0x4CAF50,
            flowers: [0xFF6B9D, 0xFFD700, 0x9B59B6, 0x4A90E2],
            sky: 0x87CEEB
        },
        features: ['trees', 'flowers', 'mushrooms', 'fireflies'],
        density: 0.3,
        heightVariation: 5
    },
    OCEAN: {
        name: 'Infinite Ocean',
        colors: {
            water: 0x006994,
            foam: 0xffffff,
            sky: 0x87CEEB
        },
        features: ['waves', 'coral', 'fish', 'seaweed'],
        density: 0.1,
        heightVariation: 2
    },
    MOUNTAIN: {
        name: 'Crystalline Peaks',
        colors: {
            rock: 0x8B7355,
            snow: 0xFFFAFA,
            crystal: 0x9B59B6,
            sky: 0xB0E0E6
        },
        features: ['peaks', 'snow', 'crystals', 'ice'],
        density: 0.2,
        heightVariation: 50
    },
    DESERT: {
        name: 'Golden Dunes',
        colors: {
            sand: 0xF4A460,
            rock: 0x8B7355,
            sky: 0xFFA500
        },
        features: ['dunes', 'cacti', 'rocks', 'mirages'],
        density: 0.05,
        heightVariation: 10
    },
    CRYSTAL: {
        name: 'Crystal Caverns',
        colors: {
            crystal: [0x9B59B6, 0x4A90E2, 0xE74C3C, 0x27AE60],
            glow: 0xFFFFFF,
            ground: 0x2C3E50
        },
        features: ['giant_crystals', 'glowing_ore', 'gems', 'light_beams'],
        density: 0.4,
        heightVariation: 15
    },
    FLOATING: {
        name: 'Sky Islands',
        colors: {
            grass: 0x7CFC00,
            stone: 0x708090,
            sky: 0xE0F6FF,
            clouds: 0xFFFFFF
        },
        features: ['floating_islands', 'waterfalls', 'clouds', 'birds'],
        density: 0.15,
        heightVariation: 30
    }
};

/**
 * INFINITE BIOME GENERATOR
 */
export class InfiniteBiomeGenerator {
    constructor(scene) {
        this.scene = scene;
        this.noise = new PerlinNoise();
        this.chunks = new Map();
        this.chunkSize = 50;
        this.renderDistance = 5; // chunks
        this.currentChunk = { x: 0, z: 0 };
    }

    /**
     * Get biome at world position
     */
    getBiomeAt(x, z) {
        // Use noise to determine biome
        const biomeNoise = this.noise.noise(x * 0.01, 0, z * 0.01);
        const moistureNoise = this.noise.noise(x * 0.02, 100, z * 0.02);

        if (biomeNoise > 0.6) return BIOMES.MOUNTAIN;
        if (biomeNoise < -0.3) return BIOMES.OCEAN;
        if (moistureNoise > 0.3) return BIOMES.FOREST;
        if (moistureNoise < -0.3) return BIOMES.DESERT;
        if (Math.abs(biomeNoise) < 0.1 && Math.abs(moistureNoise) < 0.1) return BIOMES.CRYSTAL;
        if (biomeNoise > 0.4 && moistureNoise > 0) return BIOMES.FLOATING;

        return BIOMES.FOREST; // Default
    }

    /**
     * Generate terrain chunk
     */
    generateChunk(chunkX, chunkZ) {
        const chunkKey = `${chunkX},${chunkZ}`;
        if (this.chunks.has(chunkKey)) return this.chunks.get(chunkKey);

        const chunk = new THREE.Group();
        chunk.name = chunkKey;

        const startX = chunkX * this.chunkSize;
        const startZ = chunkZ * this.chunkSize;

        // Generate terrain mesh
        const resolution = 32;
        const geometry = new THREE.PlaneGeometry(
            this.chunkSize,
            this.chunkSize,
            resolution - 1,
            resolution - 1
        );

        const vertices = geometry.attributes.position.array;
        const biome = this.getBiomeAt(startX + this.chunkSize/2, startZ + this.chunkSize/2);

        // Heightmap
        for (let i = 0; i < vertices.length; i += 3) {
            const x = vertices[i] + startX;
            const z = vertices[i + 1] + startZ;

            // Multi-octave noise for natural terrain
            let height = 0;
            height += this.noise.noise(x * 0.02, 0, z * 0.02) * 10;
            height += this.noise.noise(x * 0.05, 1, z * 0.05) * 5;
            height += this.noise.noise(x * 0.1, 2, z * 0.1) * 2;

            vertices[i + 2] = height * (biome.heightVariation / 10);
        }

        geometry.attributes.position.needsUpdate = true;
        geometry.computeVertexNormals();

        // Material based on biome
        const material = new THREE.MeshStandardMaterial({
            color: biome.colors.ground || biome.colors.grass || 0x4CAF50,
            roughness: 0.8,
            metalness: 0.2
        });

        const terrain = new THREE.Mesh(geometry, material);
        terrain.rotation.x = -Math.PI / 2;
        terrain.position.set(startX + this.chunkSize/2, 0, startZ + this.chunkSize/2);
        chunk.add(terrain);

        // Add biome features
        this.addBiomeFeatures(chunk, startX, startZ, biome);

        chunk.position.set(0, 0, 0);
        this.scene.add(chunk);
        this.chunks.set(chunkKey, chunk);

        return chunk;
    }

    /**
     * Add beautiful features to biome
     */
    addBiomeFeatures(chunk, startX, startZ, biome) {
        const features = biome.features;

        // Trees
        if (features.includes('trees')) {
            for (let i = 0; i < 20; i++) {
                const x = startX + Math.random() * this.chunkSize;
                const z = startZ + Math.random() * this.chunkSize;
                const y = this.getHeightAt(x, z);
                this.createTree(chunk, x, y, z, biome);
            }
        }

        // Flowers
        if (features.includes('flowers')) {
            for (let i = 0; i < 50; i++) {
                const x = startX + Math.random() * this.chunkSize;
                const z = startZ + Math.random() * this.chunkSize;
                const y = this.getHeightAt(x, z);
                this.createFlower(chunk, x, y, z, biome);
            }
        }

        // Crystals
        if (features.includes('giant_crystals')) {
            for (let i = 0; i < 10; i++) {
                const x = startX + Math.random() * this.chunkSize;
                const z = startZ + Math.random() * this.chunkSize;
                const y = this.getHeightAt(x, z);
                this.createCrystal(chunk, x, y, z, biome);
            }
        }

        // Floating islands
        if (features.includes('floating_islands')) {
            for (let i = 0; i < 3; i++) {
                const x = startX + Math.random() * this.chunkSize;
                const z = startZ + Math.random() * this.chunkSize;
                const y = 20 + Math.random() * 30;
                this.createFloatingIsland(chunk, x, y, z);
            }
        }
    }

    /**
     * Create beautiful tree
     */
    createTree(chunk, x, y, z, biome) {
        const tree = new THREE.Group();

        // Trunk
        const trunk = new THREE.Mesh(
            new THREE.CylinderGeometry(0.3, 0.5, 5, 8),
            new THREE.MeshStandardMaterial({ color: 0x8B4513 })
        );
        trunk.position.y = 2.5;
        tree.add(trunk);

        // Foliage
        const foliage = new THREE.Mesh(
            new THREE.SphereGeometry(3, 8, 8),
            new THREE.MeshStandardMaterial({
                color: biome.colors.plants,
                roughness: 0.9
            })
        );
        foliage.position.y = 6;
        tree.add(foliage);

        tree.position.set(x, y, z);
        chunk.add(tree);
    }

    /**
     * Create beautiful flower
     */
    createFlower(chunk, x, y, z, biome) {
        const flower = new THREE.Group();

        // Stem
        const stem = new THREE.Mesh(
            new THREE.CylinderGeometry(0.02, 0.02, 0.5, 4),
            new THREE.MeshStandardMaterial({ color: 0x228B22 })
        );
        stem.position.y = 0.25;
        flower.add(stem);

        // Petals
        const colors = biome.colors.flowers || [0xFF69B4];
        const petalColor = colors[Math.floor(Math.random() * colors.length)];

        for (let i = 0; i < 6; i++) {
            const petal = new THREE.Mesh(
                new THREE.CircleGeometry(0.2, 16),
                new THREE.MeshStandardMaterial({
                    color: petalColor,
                    side: THREE.DoubleSide
                })
            );
            const angle = (i / 6) * Math.PI * 2;
            petal.position.set(
                Math.cos(angle) * 0.2,
                0.5,
                Math.sin(angle) * 0.2
            );
            petal.rotation.y = angle;
            flower.add(petal);
        }

        // Center
        const center = new THREE.Mesh(
            new THREE.SphereGeometry(0.1, 8, 8),
            new THREE.MeshStandardMaterial({ color: 0xFFD700 })
        );
        center.position.y = 0.5;
        flower.add(center);

        flower.position.set(x, y, z);
        chunk.add(flower);
    }

    /**
     * Create glowing crystal
     */
    createCrystal(chunk, x, y, z, biome) {
        const height = 3 + Math.random() * 5;
        const colors = biome.colors.crystal;
        const color = Array.isArray(colors)
            ? colors[Math.floor(Math.random() * colors.length)]
            : colors;

        const crystal = new THREE.Mesh(
            new THREE.ConeGeometry(0.5, height, 6),
            new THREE.MeshStandardMaterial({
                color: color,
                emissive: color,
                emissiveIntensity: 0.5,
                metalness: 0.8,
                roughness: 0.2,
                transparent: true,
                opacity: 0.8
            })
        );

        crystal.position.set(x, y + height/2, z);
        crystal.rotation.y = Math.random() * Math.PI;

        // Add point light
        const light = new THREE.PointLight(color, 2, 10);
        light.position.set(x, y + height, z);
        chunk.add(light);

        chunk.add(crystal);
    }

    /**
     * Create floating island
     */
    createFloatingIsland(chunk, x, y, z) {
        const island = new THREE.Group();

        // Base
        const base = new THREE.Mesh(
            new THREE.SphereGeometry(5, 16, 16, 0, Math.PI * 2, 0, Math.PI / 2),
            new THREE.MeshStandardMaterial({ color: 0x8B7355 })
        );
        island.add(base);

        // Grass top
        const grass = new THREE.Mesh(
            new THREE.CircleGeometry(5, 32),
            new THREE.MeshStandardMaterial({ color: 0x7CFC00 })
        );
        grass.rotation.x = -Math.PI / 2;
        island.add(grass);

        // Waterfall
        const water = new THREE.Mesh(
            new THREE.CylinderGeometry(0.5, 0.5, y, 8, 1, true),
            new THREE.MeshStandardMaterial({
                color: 0x4A90E2,
                transparent: true,
                opacity: 0.6
            })
        );
        water.position.set(4, -y/2, 0);
        island.add(water);

        island.position.set(x, y, z);
        chunk.add(island);
    }

    /**
     * Get terrain height at position
     */
    getHeightAt(x, z) {
        let height = 0;
        height += this.noise.noise(x * 0.02, 0, z * 0.02) * 10;
        height += this.noise.noise(x * 0.05, 1, z * 0.05) * 5;
        height += this.noise.noise(x * 0.1, 2, z * 0.1) * 2;
        return height;
    }

    /**
     * Update chunks based on player position
     */
    update(playerX, playerZ) {
        const chunkX = Math.floor(playerX / this.chunkSize);
        const chunkZ = Math.floor(playerZ / this.chunkSize);

        // Generate new chunks in render distance
        for (let x = chunkX - this.renderDistance; x <= chunkX + this.renderDistance; x++) {
            for (let z = chunkZ - this.renderDistance; z <= chunkZ + this.renderDistance; z++) {
                this.generateChunk(x, z);
            }
        }

        // Unload distant chunks
        for (const [key, chunk] of this.chunks.entries()) {
            const [cx, cz] = key.split(',').map(Number);
            const distance = Math.max(Math.abs(cx - chunkX), Math.abs(cz - chunkZ));

            if (distance > this.renderDistance + 2) {
                this.scene.remove(chunk);
                this.chunks.delete(key);
            }
        }
    }
}

export default InfiniteBiomeGenerator;
