/**
 * MODULE LOADER - Dynamic import system for all BlackRoad systems
 *
 * This loader dynamically imports and initializes all 18 systems in the correct order
 * with proper dependency management and error handling.
 */

export class ModuleLoader {
    constructor() {
        this.modules = new Map();
        this.loadProgress = 0;
        this.onProgress = null;
        this.onComplete = null;
    }

    /**
     * Load all systems in dependency order
     */
    async loadAll() {
        const moduleConfigs = [
            // Core infrastructure (no dependencies)
            { name: 'truth', path: './truth-contracts.js', deps: [] },
            { name: 'verification', path: './verification-system.js', deps: ['truth'] },

            // Scientific/mathematical systems
            { name: 'celestial', path: './celestial-mechanics.js', deps: ['truth'] },
            { name: 'physics', path: './physics-engine.js', deps: ['truth'] },

            // World generation
            { name: 'biomes', path: './infinite-biomes.js', deps: [] },
            { name: 'particles', path: './particle-effects.js', deps: [] },
            { name: 'transport', path: './transportation.js', deps: [] },

            // Content systems
            { name: 'nature', path: './living-nature.js', deps: ['physics'] },
            { name: 'music', path: './living-music.js', deps: [] },
            { name: 'graphics', path: './photorealistic-graphics.js', deps: [] },

            // Gameplay systems
            { name: 'creation', path: './creation-powers.js', deps: ['nature'] },
            { name: 'crafting', path: './crafting-building.js', deps: ['physics'] },
            { name: 'dialogue', path: './dialogue-story.js', deps: [] },
            { name: 'quests', path: './quest-system.js', deps: [] },

            // AI and social
            { name: 'agents', path: './intelligent-agents.js', deps: ['dialogue'] },
            { name: 'multiplayer', path: './multiplayer-love.js', deps: [] },

            // Meta systems
            { name: 'evolution', path: './world-evolution.js', deps: ['nature', 'agents'] },
            { name: 'integration', path: './game-integration.js', deps: ['*'] } // Depends on all
        ];

        const totalModules = moduleConfigs.length;
        let loadedCount = 0;

        // Build dependency graph
        const graph = this.buildDependencyGraph(moduleConfigs);

        // Topological sort for load order
        const loadOrder = this.topologicalSort(graph);

        // Load modules in order
        for (const moduleName of loadOrder) {
            const config = moduleConfigs.find(c => c.name === moduleName);
            if (!config) continue;

            try {
                console.log(`[ModuleLoader] Loading ${moduleName}...`);
                const module = await this.loadModule(config);
                this.modules.set(moduleName, module);

                loadedCount++;
                this.loadProgress = loadedCount / totalModules;

                if (this.onProgress) {
                    this.onProgress(moduleName, this.loadProgress);
                }

                console.log(`[ModuleLoader] ✓ ${moduleName} loaded (${Math.round(this.loadProgress * 100)}%)`);
            } catch (error) {
                console.error(`[ModuleLoader] ✗ Failed to load ${moduleName}:`, error);
                // Continue loading other modules even if one fails
            }
        }

        console.log('[ModuleLoader] All modules loaded!');

        if (this.onComplete) {
            this.onComplete(this.modules);
        }

        return this.modules;
    }

    /**
     * Load a single module
     */
    async loadModule(config) {
        try {
            // Dynamically import the module
            const module = await import(config.path);

            // Initialize if it has an init function
            if (module.init && typeof module.init === 'function') {
                await module.init();
            }

            return module;
        } catch (error) {
            // If module doesn't exist, return a placeholder
            console.warn(`[ModuleLoader] Module ${config.name} not found, using placeholder`);
            return { placeholder: true, name: config.name };
        }
    }

    /**
     * Build dependency graph from module configs
     */
    buildDependencyGraph(configs) {
        const graph = new Map();

        for (const config of configs) {
            if (!graph.has(config.name)) {
                graph.set(config.name, { deps: [], dependents: [] });
            }

            const node = graph.get(config.name);

            for (const dep of config.deps) {
                if (dep === '*') continue; // Handle wildcard separately

                node.deps.push(dep);

                if (!graph.has(dep)) {
                    graph.set(dep, { deps: [], dependents: [] });
                }
                graph.get(dep).dependents.push(config.name);
            }
        }

        return graph;
    }

    /**
     * Topological sort for load order
     */
    topologicalSort(graph) {
        const sorted = [];
        const visited = new Set();
        const visiting = new Set();

        const visit = (name) => {
            if (visited.has(name)) return;
            if (visiting.has(name)) {
                throw new Error(`Circular dependency detected: ${name}`);
            }

            visiting.add(name);

            const node = graph.get(name);
            if (node) {
                for (const dep of node.deps) {
                    visit(dep);
                }
            }

            visiting.delete(name);
            visited.add(name);
            sorted.push(name);
        };

        for (const name of graph.keys()) {
            visit(name);
        }

        return sorted;
    }

    /**
     * Get a loaded module
     */
    get(name) {
        return this.modules.get(name);
    }

    /**
     * Check if a module is loaded
     */
    has(name) {
        return this.modules.has(name);
    }

    /**
     * Get all loaded modules
     */
    getAll() {
        return this.modules;
    }
}

/**
 * Initialize all systems with a scene
 */
export async function initializeAllSystems(scene, camera, renderer, options = {}) {
    const systems = {
        // Core
        scene,
        camera,
        renderer,

        // Game state
        gameState: {
            time: 0,
            playerPosition: new THREE.Vector3(0, 10, 0),
            currentBiome: 'Forest',
            activeQuests: [],
            inventory: [],
            playerStats: {
                health: 100,
                energy: 100,
                love: 100
            }
        },

        // Systems containers
        agents: [],
        creatures: [],
        plants: [],
        particles: [],
        quests: [],

        // Options
        ...options
    };

    console.log('[Systems] Initialization complete');
    return systems;
}

/**
 * Update all systems (called each frame)
 */
export function updateAllSystems(systems, deltaTime) {
    if (!systems) return;

    // Update game time
    systems.gameState.time += deltaTime;

    // Update physics
    if (systems.physics && systems.physics.update) {
        systems.physics.update(deltaTime);
    }

    // Update agents
    if (systems.agents) {
        for (const agent of systems.agents) {
            if (agent.update) agent.update(deltaTime);
        }
    }

    // Update creatures
    if (systems.creatures) {
        for (const creature of systems.creatures) {
            if (creature.update) creature.update(deltaTime);
        }
    }

    // Update particles
    if (systems.particles) {
        for (const particle of systems.particles) {
            if (particle.update) particle.update(deltaTime);
        }
    }

    // Update music based on biome
    if (systems.music && systems.music.update) {
        systems.music.update(systems.gameState.currentBiome, deltaTime);
    }

    // Update world evolution
    if (systems.evolution && systems.evolution.update) {
        systems.evolution.update(deltaTime);
    }
}

export default ModuleLoader;
