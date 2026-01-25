/**
 * PANGEA EARTH METAVERSE
 *
 * A geologically accurate recreation of Earth during the Pangea supercontinent era
 * (~335 to 175 million years ago - Carboniferous to Jurassic periods)
 *
 * Features:
 * - Realistic Pangea continental landmass
 * - Panthalassa (global ocean) and Tethys Sea
 * - Period-appropriate climate zones (tropical, arid, temperate, polar)
 * - Permian-Triassic-Jurassic biomes
 * - Accurate mountain ranges (Appalachian-Caledonian, Central Pangean Mountains)
 * - Volcanic provinces and fault lines
 * - Ancient flora and fauna
 */

import * as THREE from 'three';

/**
 * PANGEA GEOLOGICAL CONSTANTS
 * Based on paleontological and geological research
 */
export const PANGEA_CONFIG = {
    // Approximate dimensions (in simulation units, 1 unit = ~100km)
    CONTINENT_WIDTH: 200,
    CONTINENT_HEIGHT: 150,

    // Time period (Ma = Million years ago)
    ERA: {
        EARLY_PERMIAN: 299,    // Early assembly
        LATE_PERMIAN: 252,     // Peak formation
        EARLY_TRIASSIC: 251,   // Post P-T extinction
        LATE_TRIASSIC: 201,    // Pre-breakup
        EARLY_JURASSIC: 175    // Beginning of breakup
    },

    // Current simulation set to Late Permian (peak Pangea)
    CURRENT_PERIOD: 'LATE_PERMIAN',

    // Latitude zones for climate
    CLIMATE_ZONES: {
        POLAR: { lat: [90, 60], temp: -20 },      // < 60° latitude
        TEMPERATE: { lat: [60, 30], temp: 10 },   // 30-60° latitude
        SUBTROPICAL: { lat: [30, 15], temp: 25 }, // 15-30° latitude
        TROPICAL: { lat: [15, 0], temp: 30 }      // 0-15° latitude (equator)
    }
};

/**
 * PANGEA BIOMES
 * Realistic biomes for Late Permian - Early Jurassic periods
 */
export const PANGEA_BIOMES = {
    // ===== TERRESTRIAL BIOMES =====

    TROPICAL_RAINFOREST: {
        name: 'Equatorial Rainforest',
        period: ['PERMIAN', 'TRIASSIC', 'JURASSIC'],
        description: 'Dense tropical forests along the Tethys coastline',
        climate: { temp: 28, humidity: 95, rainfall: 3000 },
        colors: {
            ground: 0x2d4a1e,
            canopy: 0x1a3d0f,
            undergrowth: 0x4a7c3b
        },
        flora: [
            'glossopteris',      // Dominant Permian tree
            'tree_ferns',        // Giant ferns
            'horsetails',        // Primitive plants
            'cycads',            // Palm-like plants
            'ginkgos',           // Early ginkgo trees
            'conifers'           // Early conifers
        ],
        fauna: [
            'dimetrodon',        // Large synapsid (Permian)
            'lystrosaurus',      // Dominant herbivore (Triassic)
            'coelophysis',       // Early dinosaur (Triassic)
            'plateosaurus',      // Early sauropod (Triassic)
            'dilophosaurus',     // Predator (Jurassic)
            'giant_dragonflies', // Meganeura (Permian)
            'early_beetles'
        ],
        heightVariation: 8,
        density: 0.7
    },

    ARID_INTERIOR: {
        name: 'Pangean Interior Desert',
        period: ['PERMIAN', 'TRIASSIC', 'JURASSIC'],
        description: 'Massive continental interior - hot, dry mega-desert',
        climate: { temp: 45, humidity: 15, rainfall: 100 },
        colors: {
            sand: 0xd4a574,
            rock: 0x9c6b47,
            redBeds: 0x8b4513  // Red beds formation
        },
        flora: [
            'drought_adapted_conifers',
            'xerophytic_ferns',
            'dry_adapted_cycads',
            'lichens',
            'primitive_succulents'
        ],
        fauna: [
            'scutosaurus',       // Armored herbivore (Permian)
            'kannemeyeriids',    // Tusked dicynodonts (Triassic)
            'hyperodapedon',     // Rhynchosaur (Triassic)
            'postosuchus',       // Large predator (Triassic)
            'desert_crocodylomorphs',
            'therapsids'         // Mammal-like reptiles
        ],
        heightVariation: 15,
        density: 0.05,
        features: ['sand_dunes', 'rock_formations', 'dry_wadis', 'salt_flats']
    },

    APPALACHIAN_CALEDONIAN_HIGHLANDS: {
        name: 'Central Pangean Mountains',
        period: ['PERMIAN', 'TRIASSIC'],
        description: 'Eroding Appalachian-Caledonian mountain chain',
        climate: { temp: 5, humidity: 60, rainfall: 1200 },
        colors: {
            rock: 0x696969,
            vegetation: 0x4a6741,
            snow: 0xf0f8ff
        },
        flora: [
            'mountain_conifers',
            'lycophytes',        // Club mosses
            'mountain_ferns',
            'hardy_cycads'
        ],
        fauna: [
            'mountain_therapsids',
            'early_archosaurs',
            'cynognathus',       // Dog-toothed predator (Triassic)
            'mountain_insects'
        ],
        heightVariation: 50,
        density: 0.3,
        features: ['peaks', 'valleys', 'glaciers', 'erosion']
    },

    GONDWANA_POLAR_FOREST: {
        name: 'Southern Polar Forests',
        period: ['PERMIAN', 'TRIASSIC'],
        description: 'Cold-adapted Glossopteris forests of southern Pangea',
        climate: { temp: -5, humidity: 70, rainfall: 800 },
        colors: {
            snow: 0xfffafa,
            ice: 0xe0ffff,
            darkGreen: 0x2f4f2f
        },
        flora: [
            'glossopteris',      // Dominant southern flora
            'polar_ferns',
            'cold_adapted_conifers',
            'seed_ferns'
        ],
        fauna: [
            'lystrosaurus',      // Survived P-T extinction
            'thrinaxodon',       // Early cynodont
            'polar_insects',
            'early_mammals'
        ],
        heightVariation: 12,
        density: 0.4,
        features: ['glaciers', 'permafrost', 'seasonal_growth']
    },

    COASTAL_WETLANDS: {
        name: 'Tethys Coastal Wetlands',
        period: ['PERMIAN', 'TRIASSIC', 'JURASSIC'],
        description: 'Swamps and deltas along the Tethys Sea',
        climate: { temp: 24, humidity: 85, rainfall: 1800 },
        colors: {
            water: 0x4a7c8b,
            mud: 0x5a4a3a,
            vegetation: 0x6b8e23
        },
        flora: [
            'horsetails',
            'wetland_ferns',
            'mangrove_like_conifers',
            'cycads',
            'reed_like_plants'
        ],
        fauna: [
            'proterosuchids',    // Early archosaurs
            'procolophonids',    // Small reptiles
            'temnospondyls',     // Giant amphibians
            'phytosaurs',        // Crocodile-like (Triassic)
            'early_crocodilians',
            'fish',
            'insects'
        ],
        heightVariation: 3,
        density: 0.6,
        features: ['swamps', 'rivers', 'deltas', 'tidal_flats']
    },

    VOLCANIC_PROVINCES: {
        name: 'Siberian Traps Volcanic Region',
        period: ['LATE_PERMIAN'],
        description: 'Massive flood basalts - Permian-Triassic extinction cause',
        climate: { temp: 50, humidity: 40, rainfall: 600 },
        colors: {
            basalt: 0x3c3c3c,
            lava: 0xff4500,
            ash: 0x808080,
            sulfur: 0xffff00
        },
        flora: [
            'dead_forests',
            'pioneer_lichens',
            'hardy_ferns'
        ],
        fauna: [
            'extinction_survivors',
            'lystrosaurus'       // Post-extinction dominant species
        ],
        heightVariation: 25,
        density: 0.1,
        features: ['lava_flows', 'volcanic_cones', 'ash_fields', 'geysers'],
        hazards: ['toxic_gases', 'acid_rain', 'lava']
    },

    // ===== MARINE BIOMES =====

    PANTHALASSA_OCEAN: {
        name: 'Panthalassa - Global Ocean',
        period: ['PERMIAN', 'TRIASSIC', 'JURASSIC'],
        description: 'Vast super-ocean surrounding Pangea',
        climate: { temp: 18, salinity: 35 },
        colors: {
            deepWater: 0x001f3f,
            shallowWater: 0x4a7c8b,
            foam: 0xffffff
        },
        fauna: [
            'ammonites',         // Coiled cephalopods
            'nautiloids',
            'sharks',            // Early sharks
            'bony_fish',
            'placoderms',        // Armored fish (late Permian)
            'ichthyosaurs',      // Marine reptiles (Triassic+)
            'plesiosaurs',       // Long-necked marine reptiles
            'mosasaurs',         // Large predators
            'trilobites',        // Last survivors (early Permian)
            'sea_scorpions',
            'crinoids',          // Sea lilies
            'brachiopods',
            'coral_reefs'
        ],
        heightVariation: -50,  // Ocean depth
        density: 0.3,
        features: ['deep_trenches', 'seamounts', 'currents', 'waves']
    },

    TETHYS_SEA: {
        name: 'Tethys Sea',
        period: ['PERMIAN', 'TRIASSIC', 'JURASSIC'],
        description: 'Warm tropical sea cutting into eastern Pangea',
        climate: { temp: 26, salinity: 36 },
        colors: {
            water: 0x20b2aa,
            coral: 0xff6b9d,
            sand: 0xf4e4c1
        },
        fauna: [
            'reef_fish',
            'ammonites',
            'belemnites',
            'nothosaurs',        // Semi-aquatic predators
            'placodonts',        // Shell-crushing reptiles
            'early_turtles',
            'marine_crocodiles',
            'triassic_corals',
            'shellfish'
        ],
        heightVariation: -20,
        density: 0.5,
        features: ['coral_reefs', 'lagoons', 'atolls', 'shallow_seas']
    },

    SHALLOW_EPICONTINENTAL_SEA: {
        name: 'Shallow Continental Seas',
        period: ['PERMIAN', 'TRIASSIC', 'JURASSIC'],
        description: 'Shallow seas periodically flooding low-lying areas',
        climate: { temp: 22, salinity: 33 },
        colors: {
            water: 0x6fa8dc,
            seabed: 0xd4c5a0
        },
        fauna: [
            'horseshoe_crabs',
            'sea_urchins',
            'starfish',
            'bottom_feeders',
            'juvenile_marine_reptiles',
            'coastal_fish'
        ],
        heightVariation: -5,
        density: 0.4,
        features: ['tidal_zones', 'sand_bars', 'estuaries']
    }
};

/**
 * PANGEA TERRAIN GENERATOR
 * Generates geologically accurate Pangea landmass
 */
export class PangeaTerrainGenerator {
    constructor(scene) {
        this.scene = scene;
        this.noise = this.createPerlinNoise();
        this.chunks = new Map();
        this.chunkSize = 100; // Larger chunks for continental scale

        // Pangea center coordinates (simulation space)
        this.pangeaCenter = { x: 0, z: 0 };

        // Major geological features
        this.features = {
            // Mountain ranges
            appalachianCaledonian: {
                x: -20, z: 0,
                length: 80, width: 15,
                height: 50,
                orientation: 'NS'  // North-South
            },
            centralPangeanMountains: {
                x: 0, z: 0,
                length: 100, width: 20,
                height: 45,
                orientation: 'EW'  // East-West
            },

            // Tethys Sea
            tethysSea: {
                x: 40, z: 0,
                width: 30, depth: -25,
                orientation: 'EW'
            },

            // Volcanic provinces
            siberianTraps: {
                x: 50, z: 60,
                radius: 25,
                height: 20
            }
        };
    }

    createPerlinNoise() {
        // Perlin noise implementation
        const grad3 = [[1,1,0],[-1,1,0],[1,-1,0],[-1,-1,0],
                      [1,0,1],[-1,0,1],[1,0,-1],[-1,0,-1],
                      [0,1,1],[0,-1,1],[0,1,-1],[0,-1,-1]];
        const p = [];
        for(let i=0; i<256; i++) {
            p[i] = Math.floor(Math.random() * 256);
        }
        const perm = [];
        for(let i=0; i<512; i++) {
            perm[i] = p[i & 255];
        }

        return {
            noise: (x, y, z) => {
                let X = Math.floor(x) & 255;
                let Y = Math.floor(y) & 255;
                let Z = Math.floor(z) & 255;

                x -= Math.floor(x);
                y -= Math.floor(y);
                z -= Math.floor(z);

                const fade = t => t*t*t*(t*(t*6-15)+10);
                const mix = (a, b, t) => (1-t)*a + t*b;
                const dot = (g, x, y, z) => g[0]*x + g[1]*y + g[2]*z;

                let u = fade(x);
                let v = fade(y);
                let w = fade(z);

                let A = perm[X  ]+Y, AA = perm[A]+Z, AB = perm[A+1]+Z;
                let B = perm[X+1]+Y, BA = perm[B]+Z, BB = perm[B+1]+Z;

                return mix(
                    mix(
                        mix(dot(grad3[perm[AA  ]%12], x, y, z),
                            dot(grad3[perm[BA  ]%12], x-1, y, z), u),
                        mix(dot(grad3[perm[AB  ]%12], x, y-1, z),
                            dot(grad3[perm[BB  ]%12], x-1, y-1, z), u), v),
                    mix(
                        mix(dot(grad3[perm[AA+1]%12], x, y, z-1),
                            dot(grad3[perm[BA+1]%12], x-1, y, z-1), u),
                        mix(dot(grad3[perm[AB+1]%12], x, y-1, z-1),
                            dot(grad3[perm[BB+1]%12], x-1, y-1, z-1), u), v), w);
            }
        };
    }

    /**
     * Determine if point is on Pangea landmass
     */
    isOnPangea(x, z) {
        // Pangea rough outline (C-shaped)
        // Using parametric shape + noise for realistic coastline

        const centerDist = Math.sqrt(x * x + z * z);
        const angle = Math.atan2(z, x);

        // Base Pangea shape (simplified C-shape)
        const radius = 70 + 15 * Math.cos(angle * 2) + 10 * Math.sin(angle * 3);

        // Add coastal noise for realistic coastline
        const coastalNoise = this.noise.noise(x * 0.02, 0, z * 0.02) * 5;

        // Check if inside continent
        const onLand = centerDist < (radius + coastalNoise);

        // Cut out Tethys Sea (eastern indentation)
        const tethys = this.features.tethysSea;
        const inTethys = (
            x > tethys.x - tethys.width/2 &&
            x < tethys.x + tethys.width/2 &&
            Math.abs(z) < 20
        );

        return onLand && !inTethys;
    }

    /**
     * Get elevation at point
     */
    getElevation(x, z) {
        if (!this.isOnPangea(x, z)) {
            // Ocean floor
            return this.getOceanDepth(x, z);
        }

        let elevation = 0;

        // Base continental elevation
        elevation += 2;

        // Multi-scale noise for realistic terrain
        elevation += this.noise.noise(x * 0.01, 0, z * 0.01) * 15;
        elevation += this.noise.noise(x * 0.03, 1, z * 0.03) * 8;
        elevation += this.noise.noise(x * 0.08, 2, z * 0.08) * 3;

        // Add mountain ranges
        elevation += this.getMountainHeight(x, z);

        // Add volcanic features
        elevation += this.getVolcanicHeight(x, z);

        return elevation;
    }

    /**
     * Get mountain range heights
     */
    getMountainHeight(x, z) {
        let height = 0;

        // Appalachian-Caledonian range
        const app = this.features.appalachianCaledonian;
        const appDist = Math.abs(x - app.x);
        if (appDist < app.width && Math.abs(z) < app.length/2) {
            const falloff = 1 - (appDist / app.width);
            const ridgeNoise = this.noise.noise(x * 0.1, 5, z * 0.05);
            height += app.height * falloff * falloff * (0.7 + 0.3 * ridgeNoise);
        }

        // Central Pangean Mountains
        const central = this.features.centralPangeanMountains;
        const centralDist = Math.abs(z);
        if (centralDist < central.width && Math.abs(x) < central.length/2) {
            const falloff = 1 - (centralDist / central.width);
            const ridgeNoise = this.noise.noise(x * 0.05, 6, z * 0.1);
            height += central.height * falloff * falloff * (0.6 + 0.4 * ridgeNoise);
        }

        return height;
    }

    /**
     * Get volcanic province heights
     */
    getVolcanicHeight(x, z) {
        const siberian = this.features.siberianTraps;
        const dist = Math.sqrt(
            Math.pow(x - siberian.x, 2) +
            Math.pow(z - siberian.z, 2)
        );

        if (dist < siberian.radius) {
            const falloff = 1 - (dist / siberian.radius);
            // Volcanic cones with noise
            const coneNoise = this.noise.noise(x * 0.15, 10, z * 0.15);
            return siberian.height * falloff * (0.5 + 0.5 * coneNoise);
        }

        return 0;
    }

    /**
     * Get ocean depth
     */
    getOceanDepth(x, z) {
        // Panthalassa is deep, Tethys is shallow
        const tethys = this.features.tethysSea;
        const inTethys = (
            x > tethys.x - tethys.width &&
            x < tethys.x + tethys.width &&
            Math.abs(z) < 30
        );

        if (inTethys) {
            return -5 - this.noise.noise(x * 0.05, 20, z * 0.05) * 15;
        }

        // Deep Panthalassa
        const coastDist = this.getDistanceToCoast(x, z);
        const depth = -10 - coastDist * 0.5;
        const seabedNoise = this.noise.noise(x * 0.02, 30, z * 0.02) * 10;

        return depth + seabedNoise;
    }

    /**
     * Get distance to nearest coast
     */
    getDistanceToCoast(x, z) {
        // Simplified - just use distance from center
        const centerDist = Math.sqrt(x * x + z * z);
        return Math.max(0, centerDist - 70);
    }

    /**
     * Get biome at location
     */
    getBiomeAt(x, z, elevation) {
        // First check if ocean
        if (elevation < 0) {
            const tethys = this.features.tethysSea;
            if (x > tethys.x - tethys.width && x < tethys.x + tethys.width) {
                return PANGEA_BIOMES.TETHYS_SEA;
            }
            if (elevation > -10) {
                return PANGEA_BIOMES.SHALLOW_EPICONTINENTAL_SEA;
            }
            return PANGEA_BIOMES.PANTHALASSA_OCEAN;
        }

        // Land biomes based on latitude (z-coordinate) and features
        const latitude = Math.abs(z);

        // Volcanic province
        const siberian = this.features.siberianTraps;
        const volcDist = Math.sqrt(
            Math.pow(x - siberian.x, 2) +
            Math.pow(z - siberian.z, 2)
        );
        if (volcDist < siberian.radius) {
            return PANGEA_BIOMES.VOLCANIC_PROVINCES;
        }

        // Mountains
        if (elevation > 30) {
            return PANGEA_BIOMES.APPALACHIAN_CALEDONIAN_HIGHLANDS;
        }

        // Polar (high latitude)
        if (latitude > 60) {
            return PANGEA_BIOMES.GONDWANA_POLAR_FOREST;
        }

        // Coastal wetlands (low elevation near coast)
        if (elevation < 5 && this.nearCoast(x, z)) {
            return PANGEA_BIOMES.COASTAL_WETLANDS;
        }

        // Tropical (equatorial)
        if (latitude < 15) {
            return PANGEA_BIOMES.TROPICAL_RAINFOREST;
        }

        // Interior desert (mid-latitudes, continental interior)
        const centerDist = Math.sqrt(x * x + z * z);
        if (centerDist < 40 && latitude > 15 && latitude < 60) {
            return PANGEA_BIOMES.ARID_INTERIOR;
        }

        // Default to tropical rainforest
        return PANGEA_BIOMES.TROPICAL_RAINFOREST;
    }

    /**
     * Check if near coast
     */
    nearCoast(x, z) {
        const onLand = this.isOnPangea(x, z);
        // Check nearby points
        const searchRadius = 5;
        for (let dx = -searchRadius; dx <= searchRadius; dx += searchRadius) {
            for (let dz = -searchRadius; dz <= searchRadius; dz += searchRadius) {
                if (this.isOnPangea(x + dx, z + dz) !== onLand) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Generate chunk of Pangea terrain
     */
    generateChunk(chunkX, chunkZ) {
        const chunkKey = `${chunkX},${chunkZ}`;
        if (this.chunks.has(chunkKey)) {
            return this.chunks.get(chunkKey);
        }

        const chunk = new THREE.Group();
        chunk.name = `pangea_chunk_${chunkKey}`;

        const startX = chunkX * this.chunkSize;
        const startZ = chunkZ * this.chunkSize;

        // High resolution for continental detail
        const resolution = 64;
        const geometry = new THREE.PlaneGeometry(
            this.chunkSize,
            this.chunkSize,
            resolution - 1,
            resolution - 1
        );

        const vertices = geometry.attributes.position.array;
        const colors = [];

        // Generate heightmap and determine biomes
        for (let i = 0; i < vertices.length; i += 3) {
            const localX = vertices[i];
            const localZ = vertices[i + 1];
            const worldX = localX + startX + this.chunkSize/2;
            const worldZ = localZ + startZ + this.chunkSize/2;

            // Get elevation
            const elevation = this.getElevation(worldX, worldZ);
            vertices[i + 2] = elevation;

            // Get biome and color
            const biome = this.getBiomeAt(worldX, worldZ, elevation);
            const color = this.getBiomeColor(biome, elevation);
            colors.push(color.r, color.g, color.b);
        }

        geometry.attributes.position.needsUpdate = true;
        geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
        geometry.computeVertexNormals();

        // Create terrain mesh with vertex colors
        const material = new THREE.MeshStandardMaterial({
            vertexColors: true,
            roughness: 0.9,
            metalness: 0.1,
            flatShading: false
        });

        const terrain = new THREE.Mesh(geometry, material);
        terrain.rotation.x = -Math.PI / 2;
        terrain.position.set(startX + this.chunkSize/2, 0, startZ + this.chunkSize/2);
        terrain.receiveShadow = true;
        terrain.castShadow = true;

        chunk.add(terrain);

        // Add biome features (flora, fauna)
        this.addBiomeFeatures(chunk, startX, startZ);

        this.scene.add(chunk);
        this.chunks.set(chunkKey, chunk);

        return chunk;
    }

    /**
     * Get biome-specific color
     */
    getBiomeColor(biome, elevation) {
        const color = new THREE.Color();

        if (biome === PANGEA_BIOMES.PANTHALASSA_OCEAN) {
            // Deep to shallow gradient
            const depth = Math.abs(elevation);
            if (depth > 40) {
                color.setHex(0x001a33);  // Very deep
            } else if (depth > 20) {
                color.setHex(0x001f3f);  // Deep
            } else {
                color.setHex(0x003d66);  // Moderate
            }
        } else if (biome === PANGEA_BIOMES.TETHYS_SEA) {
            color.setHex(biome.colors.water);
        } else if (biome === PANGEA_BIOMES.SHALLOW_EPICONTINENTAL_SEA) {
            color.setHex(biome.colors.water);
        } else {
            // Land biomes
            const groundColor = biome.colors.ground || biome.colors.sand || biome.colors.rock;
            color.setHex(groundColor);

            // Add elevation-based variation
            if (elevation > 35) {
                color.setHex(biome.colors.snow || 0xffffff);  // Snow caps
            } else if (elevation > 25) {
                color.setHex(biome.colors.rock || 0x808080);  // Rocky peaks
            }
        }

        return color;
    }

    /**
     * Add period-appropriate flora and fauna
     */
    addBiomeFeatures(chunk, startX, startZ) {
        // Sample center point for biome determination
        const centerX = startX + this.chunkSize/2;
        const centerZ = startZ + this.chunkSize/2;
        const centerElevation = this.getElevation(centerX, centerZ);
        const biome = this.getBiomeAt(centerX, centerZ, centerElevation);

        // Skip oceans for now (add marine life later)
        if (centerElevation < 0) return;

        // Add flora based on biome
        if (biome.flora) {
            const floraCount = Math.floor(biome.density * 30);
            for (let i = 0; i < floraCount; i++) {
                const x = startX + Math.random() * this.chunkSize;
                const z = startZ + Math.random() * this.chunkSize;
                const y = this.getElevation(x, z);

                if (y > 0) {  // Only on land
                    const floraType = biome.flora[Math.floor(Math.random() * biome.flora.length)];
                    this.createFlora(chunk, x, y, z, floraType, biome);
                }
            }
        }

        // Add fauna
        if (biome.fauna && Math.random() < 0.3) {  // Sparse fauna
            const faunaCount = Math.floor(biome.density * 5);
            for (let i = 0; i < faunaCount; i++) {
                const x = startX + Math.random() * this.chunkSize;
                const z = startZ + Math.random() * this.chunkSize;
                const y = this.getElevation(x, z);

                if (y > 0) {
                    const faunaType = biome.fauna[Math.floor(Math.random() * biome.fauna.length)];
                    this.createFauna(chunk, x, y, z, faunaType, biome);
                }
            }
        }
    }

    /**
     * Create period-appropriate flora
     */
    createFlora(chunk, x, y, z, type, biome) {
        const plant = new THREE.Group();

        switch (type) {
            case 'glossopteris':
                // Dominant Permian tree fern
                this.createGlossopteris(plant);
                break;
            case 'tree_ferns':
                this.createTreeFern(plant);
                break;
            case 'cycads':
                this.createCycad(plant);
                break;
            case 'conifers':
                this.createConifer(plant);
                break;
            case 'horsetails':
                this.createHorsetail(plant);
                break;
            default:
                // Generic plant
                this.createGenericPlant(plant);
        }

        plant.position.set(x, y, z);
        plant.rotation.y = Math.random() * Math.PI * 2;
        chunk.add(plant);
    }

    createGlossopteris(group) {
        // Trunk
        const trunk = new THREE.Mesh(
            new THREE.CylinderGeometry(0.4, 0.6, 8, 8),
            new THREE.MeshStandardMaterial({
                color: 0x4a3c28,
                roughness: 0.95
            })
        );
        trunk.position.y = 4;
        group.add(trunk);

        // Fronds (distinctive tongue-shaped leaves)
        for (let i = 0; i < 12; i++) {
            const frond = new THREE.Mesh(
                new THREE.PlaneGeometry(2, 4),
                new THREE.MeshStandardMaterial({
                    color: 0x2d5016,
                    side: THREE.DoubleSide,
                    roughness: 0.8
                })
            );
            const angle = (i / 12) * Math.PI * 2;
            const radius = 2.5;
            frond.position.set(
                Math.cos(angle) * radius,
                6 + Math.random() * 2,
                Math.sin(angle) * radius
            );
            frond.rotation.y = angle;
            frond.rotation.x = -Math.PI / 4;
            group.add(frond);
        }
    }

    createTreeFern(group) {
        // Trunk
        const trunk = new THREE.Mesh(
            new THREE.CylinderGeometry(0.3, 0.4, 6, 8),
            new THREE.MeshStandardMaterial({ color: 0x3d2817 })
        );
        trunk.position.y = 3;
        group.add(trunk);

        // Fern fronds
        for (let i = 0; i < 16; i++) {
            const frond = new THREE.Mesh(
                new THREE.PlaneGeometry(1.5, 5),
                new THREE.MeshStandardMaterial({
                    color: 0x228b22,
                    side: THREE.DoubleSide
                })
            );
            const angle = (i / 16) * Math.PI * 2;
            frond.position.set(
                Math.cos(angle) * 2,
                6,
                Math.sin(angle) * 2
            );
            frond.rotation.y = angle;
            frond.rotation.x = -Math.PI / 6 - Math.random() * 0.3;
            group.add(frond);
        }
    }

    createCycad(group) {
        // Thick trunk
        const trunk = new THREE.Mesh(
            new THREE.CylinderGeometry(0.5, 0.6, 3, 8),
            new THREE.MeshStandardMaterial({ color: 0x6b5d4f })
        );
        trunk.position.y = 1.5;
        group.add(trunk);

        // Palm-like fronds
        for (let i = 0; i < 10; i++) {
            const frond = new THREE.Mesh(
                new THREE.PlaneGeometry(1, 3),
                new THREE.MeshStandardMaterial({
                    color: 0x3d5a2c,
                    side: THREE.DoubleSide
                })
            );
            const angle = (i / 10) * Math.PI * 2;
            frond.position.set(
                Math.cos(angle) * 1.5,
                3,
                Math.sin(angle) * 1.5
            );
            frond.rotation.y = angle;
            frond.rotation.x = -Math.PI / 3;
            group.add(frond);
        }
    }

    createConifer(group) {
        // Trunk
        const trunk = new THREE.Mesh(
            new THREE.CylinderGeometry(0.3, 0.5, 10, 8),
            new THREE.MeshStandardMaterial({ color: 0x4d3319 })
        );
        trunk.position.y = 5;
        group.add(trunk);

        // Conical foliage
        for (let layer = 0; layer < 5; layer++) {
            const radius = 3 - layer * 0.5;
            const foliage = new THREE.Mesh(
                new THREE.ConeGeometry(radius, 3, 8),
                new THREE.MeshStandardMaterial({ color: 0x1a3d0f })
            );
            foliage.position.y = 8 + layer * 2;
            group.add(foliage);
        }
    }

    createHorsetail(group) {
        // Segmented stem
        const segments = 8;
        for (let i = 0; i < segments; i++) {
            const segment = new THREE.Mesh(
                new THREE.CylinderGeometry(0.08, 0.1, 0.4, 12),
                new THREE.MeshStandardMaterial({
                    color: 0x4a7c3b,
                    roughness: 0.9
                })
            );
            segment.position.y = i * 0.5;
            group.add(segment);

            // Whorl of leaves at joints
            if (i > 0) {
                for (let j = 0; j < 12; j++) {
                    const leaf = new THREE.Mesh(
                        new THREE.PlaneGeometry(0.1, 0.4),
                        new THREE.MeshStandardMaterial({
                            color: 0x3d5a2c,
                            side: THREE.DoubleSide
                        })
                    );
                    const angle = (j / 12) * Math.PI * 2;
                    leaf.position.set(
                        Math.cos(angle) * 0.15,
                        i * 0.5,
                        Math.sin(angle) * 0.15
                    );
                    leaf.rotation.y = angle;
                    group.add(leaf);
                }
            }
        }
    }

    createGenericPlant(group) {
        const stem = new THREE.Mesh(
            new THREE.CylinderGeometry(0.05, 0.05, 1, 6),
            new THREE.MeshStandardMaterial({ color: 0x228b22 })
        );
        stem.position.y = 0.5;
        group.add(stem);

        const leaves = new THREE.Mesh(
            new THREE.SphereGeometry(0.3, 8, 8),
            new THREE.MeshStandardMaterial({ color: 0x4a7c3b })
        );
        leaves.position.y = 1;
        group.add(leaves);
    }

    /**
     * Create period-appropriate fauna
     */
    createFauna(chunk, x, y, z, type, biome) {
        const creature = new THREE.Group();

        switch (type) {
            case 'lystrosaurus':
                this.createLystrosaurus(creature);
                break;
            case 'dimetrodon':
                this.createDimetrodon(creature);
                break;
            case 'coelophysis':
                this.createCoelophysis(creature);
                break;
            default:
                // Generic creature
                this.createGenericCreature(creature);
        }

        creature.position.set(x, y, z);
        creature.rotation.y = Math.random() * Math.PI * 2;
        chunk.add(creature);
    }

    createLystrosaurus(group) {
        // Body (low, stocky)
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(1.2, 0.6, 2),
            new THREE.MeshStandardMaterial({ color: 0x6b5d4f })
        );
        body.position.y = 0.5;
        group.add(body);

        // Head with tusks
        const head = new THREE.Mesh(
            new THREE.BoxGeometry(0.6, 0.5, 0.7),
            new THREE.MeshStandardMaterial({ color: 0x7a6a5a })
        );
        head.position.set(0, 0.5, 1.2);
        group.add(head);

        // Tusks
        for (let side of [-1, 1]) {
            const tusk = new THREE.Mesh(
                new THREE.CylinderGeometry(0.03, 0.03, 0.3, 6),
                new THREE.MeshStandardMaterial({ color: 0xf5f5dc })
            );
            tusk.position.set(side * 0.2, 0.4, 1.4);
            tusk.rotation.x = Math.PI / 6;
            group.add(tusk);
        }

        // Legs
        for (let pos of [[0.4, 0.7], [-0.4, 0.7], [0.4, -0.7], [-0.4, -0.7]]) {
            const leg = new THREE.Mesh(
                new THREE.CylinderGeometry(0.1, 0.08, 0.5, 6),
                new THREE.MeshStandardMaterial({ color: 0x6b5d4f })
            );
            leg.position.set(pos[0], 0.25, pos[1]);
            group.add(leg);
        }
    }

    createDimetrodon(group) {
        // Body
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(0.8, 0.5, 2.5),
            new THREE.MeshStandardMaterial({ color: 0x5a4a3a })
        );
        body.position.y = 0.6;
        group.add(body);

        // Iconic sail
        const sail = new THREE.Mesh(
            new THREE.PlaneGeometry(3, 1.5),
            new THREE.MeshStandardMaterial({
                color: 0x8b4513,
                side: THREE.DoubleSide,
                emissive: 0x331100,
                emissiveIntensity: 0.2
            })
        );
        sail.position.y = 1.3;
        sail.rotation.x = Math.PI / 2;
        group.add(sail);

        // Head
        const head = new THREE.Mesh(
            new THREE.ConeGeometry(0.3, 0.8, 8),
            new THREE.MeshStandardMaterial({ color: 0x6a5a4a })
        );
        head.position.set(0, 0.6, 1.6);
        head.rotation.z = -Math.PI / 2;
        group.add(head);

        // Legs
        for (let pos of [[0.3, 1], [-0.3, 1], [0.3, -0.8], [-0.3, -0.8]]) {
            const leg = new THREE.Mesh(
                new THREE.CylinderGeometry(0.1, 0.08, 0.6, 6),
                new THREE.MeshStandardMaterial({ color: 0x5a4a3a })
            );
            leg.position.set(pos[0], 0.3, pos[1]);
            group.add(leg);
        }
    }

    createCoelophysis(group) {
        // Body (bipedal dinosaur)
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(0.4, 0.5, 1.5),
            new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
        );
        body.position.y = 1.2;
        body.rotation.x = Math.PI / 6;
        group.add(body);

        // Long neck and head
        const neck = new THREE.Mesh(
            new THREE.CylinderGeometry(0.15, 0.2, 0.8, 8),
            new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
        );
        neck.position.set(0, 1.5, 0.8);
        neck.rotation.x = -Math.PI / 4;
        group.add(neck);

        const head = new THREE.Mesh(
            new THREE.ConeGeometry(0.2, 0.5, 8),
            new THREE.MeshStandardMaterial({ color: 0x7a9e33 })
        );
        head.position.set(0, 1.8, 1.2);
        head.rotation.z = -Math.PI / 2;
        group.add(head);

        // Tail
        const tail = new THREE.Mesh(
            new THREE.CylinderGeometry(0.08, 0.15, 1.5, 8),
            new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
        );
        tail.position.set(0, 1, -1);
        tail.rotation.x = -Math.PI / 3;
        group.add(tail);

        // Hind legs (strong)
        for (let side of [-1, 1]) {
            const leg = new THREE.Mesh(
                new THREE.CylinderGeometry(0.1, 0.08, 1.2, 6),
                new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
            );
            leg.position.set(side * 0.2, 0.6, 0);
            group.add(leg);
        }

        // Small arms
        for (let side of [-1, 1]) {
            const arm = new THREE.Mesh(
                new THREE.CylinderGeometry(0.05, 0.04, 0.4, 6),
                new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
            );
            arm.position.set(side * 0.25, 1.3, 0.6);
            arm.rotation.x = Math.PI / 3;
            group.add(arm);
        }
    }

    createGenericCreature(group) {
        const body = new THREE.Mesh(
            new THREE.SphereGeometry(0.3, 8, 8),
            new THREE.MeshStandardMaterial({ color: 0x8b7355 })
        );
        body.position.y = 0.3;
        group.add(body);
    }

    /**
     * Update visible chunks based on camera position
     */
    update(cameraX, cameraZ) {
        const chunkX = Math.floor(cameraX / this.chunkSize);
        const chunkZ = Math.floor(cameraZ / this.chunkSize);

        const renderDistance = 3;

        // Generate visible chunks
        for (let x = chunkX - renderDistance; x <= chunkX + renderDistance; x++) {
            for (let z = chunkZ - renderDistance; z <= chunkZ + renderDistance; z++) {
                this.generateChunk(x, z);
            }
        }

        // Unload distant chunks
        for (const [key, chunk] of this.chunks.entries()) {
            const [cx, cz] = key.split(',').map(Number);
            const dist = Math.max(Math.abs(cx - chunkX), Math.abs(cz - chunkZ));

            if (dist > renderDistance + 1) {
                this.scene.remove(chunk);
                this.chunks.delete(key);
            }
        }
    }
}

export default PangeaTerrainGenerator;
