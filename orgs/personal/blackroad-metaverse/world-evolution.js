/**
 * DYNAMIC EVENTS & WORLD EVOLUTION SYSTEM
 *
 * The world changes based on collective player actions.
 * Seasons evolve, ecosystems respond, events emerge dynamically.
 *
 * Philosophy: "THE WORLD IS ALIVE. IT REMEMBERS. IT RESPONDS. IT EVOLVES."
 */

import * as THREE from 'three';

// ===== SEASONS =====
export const SEASONS = {
    spring: {
        id: 'spring',
        name: 'Spring',
        duration: 120, // seconds (2 minutes in accelerated time)
        colors: {
            sky: 0x87CEEB,
            grass: 0x90EE90,
            leaves: 0x32CD32
        },
        temperature: 18,
        weatherChance: { rain: 0.3, clear: 0.7 },
        plantGrowthRate: 1.5,
        animalActivity: 1.2,
        description: 'New life blooms everywhere'
    },
    summer: {
        id: 'summer',
        name: 'Summer',
        duration: 120,
        colors: {
            sky: 0xFFD700,
            grass: 0x228B22,
            leaves: 0x006400
        },
        temperature: 28,
        weatherChance: { clear: 0.8, rain: 0.2 },
        plantGrowthRate: 1.0,
        animalActivity: 1.5,
        description: 'Warmth and abundance'
    },
    autumn: {
        id: 'autumn',
        name: 'Autumn',
        duration: 120,
        colors: {
            sky: 0xFF8C00,
            grass: 0xD2691E,
            leaves: 0xFF4500
        },
        temperature: 15,
        weatherChance: { clear: 0.6, rain: 0.3, wind: 0.1 },
        plantGrowthRate: 0.5,
        animalActivity: 0.8,
        description: 'Colors of change'
    },
    winter: {
        id: 'winter',
        name: 'Winter',
        duration: 120,
        colors: {
            sky: 0xB0C4DE,
            grass: 0xF0F8FF,
            leaves: 0xFFFFFF
        },
        temperature: -2,
        weatherChance: { snow: 0.5, clear: 0.5 },
        plantGrowthRate: 0.1,
        animalActivity: 0.5,
        description: 'Quiet rest and reflection'
    }
};

// ===== WORLD EVENTS =====
export const WORLD_EVENTS = {
    // Natural Events
    meteor_shower: {
        id: 'meteor_shower',
        name: 'Meteor Shower',
        description: 'Stars fall from the sky, leaving stardust in their wake',
        rarity: 'rare',
        duration: 60,
        effects: ['spawn_stardust', 'night_required'],
        triggers: { timeOfDay: 'night', random: 0.01 }
    },
    aurora: {
        id: 'aurora',
        name: 'Aurora Borealis',
        description: 'Dancing lights paint the northern sky',
        rarity: 'rare',
        duration: 120,
        effects: ['aurora_visual', 'increased_magic'],
        triggers: { season: 'winter', random: 0.05 }
    },
    rainbow: {
        id: 'rainbow',
        name: 'Double Rainbow',
        description: 'A perfect arc of color spans the sky',
        rarity: 'uncommon',
        duration: 30,
        effects: ['rainbow_visual', 'happiness_boost'],
        triggers: { weather: 'rain_ending', random: 0.3 }
    },
    super_bloom: {
        id: 'super_bloom',
        name: 'Super Bloom',
        description: 'Flowers burst into bloom everywhere',
        rarity: 'rare',
        duration: 180,
        effects: ['mass_bloom', 'pollen_particles'],
        triggers: { season: 'spring', love_threshold: 1000 }
    },

    // Magical Events
    time_rift: {
        id: 'time_rift',
        name: 'Time Rift',
        description: 'Past and future collide. Impossible things become possible.',
        rarity: 'legendary',
        duration: 60,
        effects: ['time_distortion', 'rare_spawns'],
        triggers: { random: 0.001, discovery_threshold: 500 }
    },
    harmony_convergence: {
        id: 'harmony_convergence',
        name: 'Harmony Convergence',
        description: 'All beings move in perfect synchrony. The universe breathes as one.',
        rarity: 'legendary',
        duration: 120,
        effects: ['universal_harmony', 'max_happiness', 'synchronized_movement'],
        triggers: { love_threshold: 5000, creation_threshold: 1000 }
    },
    crystal_eruption: {
        id: 'crystal_eruption',
        name: 'Crystal Eruption',
        description: 'Crystals burst from the earth, singing with energy',
        rarity: 'rare',
        duration: 90,
        effects: ['spawn_crystals', 'energy_boost'],
        triggers: { location: 'crystal_cavern', random: 0.02 }
    },

    // Community Events
    gathering: {
        id: 'gathering',
        name: 'The Great Gathering',
        description: 'All creatures are drawn to one location. A moment of unity.',
        rarity: 'epic',
        duration: 300,
        effects: ['creature_convergence', 'mass_bonding'],
        triggers: { players_online: 10, love_threshold: 2000 }
    },
    festival_of_light: {
        id: 'festival_of_light',
        name: 'Festival of Light',
        description: 'Fireflies fill the air, creating a galaxy of earthbound stars',
        rarity: 'uncommon',
        duration: 180,
        effects: ['firefly_swarm', 'light_blessing'],
        triggers: { season: 'summer', timeOfDay: 'dusk', random: 0.1 }
    }
};

// ===== ECOSYSTEM STATES =====
export const ECOSYSTEM_STATES = {
    thriving: {
        plantHealth: 1.0,
        animalPopulation: 1.0,
        description: 'Thriving - Life flourishes',
        effects: ['bonus_growth', 'happy_creatures']
    },
    balanced: {
        plantHealth: 0.7,
        animalPopulation: 0.7,
        description: 'Balanced - Natural harmony',
        effects: []
    },
    struggling: {
        plantHealth: 0.4,
        animalPopulation: 0.4,
        description: 'Struggling - Needs care',
        effects: ['slow_growth', 'sad_creatures']
    },
    endangered: {
        plantHealth: 0.2,
        animalPopulation: 0.2,
        description: 'Endangered - Urgent action needed',
        effects: ['critical_state', 'dying_plants']
    }
};

// ===== SEASON MANAGER =====
export class SeasonManager {
    constructor() {
        this.currentSeason = 'spring';
        this.seasonProgress = 0; // 0-1
        this.seasonCycle = ['spring', 'summer', 'autumn', 'winter'];
        this.transitionDuration = 10; // seconds
        this.isTransitioning = false;
    }

    update(deltaTime) {
        const season = SEASONS[this.currentSeason];
        this.seasonProgress += deltaTime / season.duration;

        if (this.seasonProgress >= 1) {
            this.advanceSeason();
        }
    }

    advanceSeason() {
        const currentIndex = this.seasonCycle.indexOf(this.currentSeason);
        const nextIndex = (currentIndex + 1) % this.seasonCycle.length;
        const nextSeason = this.seasonCycle[nextIndex];

        console.log(`🍂 Season changing: ${this.currentSeason} → ${nextSeason}`);

        this.isTransitioning = true;
        this.currentSeason = nextSeason;
        this.seasonProgress = 0;

        setTimeout(() => {
            this.isTransitioning = false;
        }, this.transitionDuration * 1000);

        return {
            from: this.seasonCycle[currentIndex],
            to: nextSeason,
            season: SEASONS[nextSeason]
        };
    }

    getCurrentSeason() {
        return SEASONS[this.currentSeason];
    }

    getSeasonColors() {
        return this.getCurrentSeason().colors;
    }

    setSeason(seasonId) {
        if (SEASONS[seasonId]) {
            this.currentSeason = seasonId;
            this.seasonProgress = 0;
        }
    }
}

// ===== EVENT MANAGER =====
export class WorldEventManager {
    constructor(scene) {
        this.scene = scene;
        this.activeEvents = [];
        this.eventHistory = [];
        this.worldStats = {
            love: 0,
            creation: 0,
            discovery: 0,
            playersOnline: 1
        };
    }

    update(deltaTime, context = {}) {
        // Update active events
        this.activeEvents = this.activeEvents.filter(event => {
            event.timeRemaining -= deltaTime;

            if (event.timeRemaining <= 0) {
                this.endEvent(event);
                return false;
            }

            return true;
        });

        // Check for new events
        this.checkEventTriggers(context);
    }

    checkEventTriggers(context) {
        Object.values(WORLD_EVENTS).forEach(eventDef => {
            // Skip if already active
            if (this.activeEvents.find(e => e.id === eventDef.id)) {
                return;
            }

            // Check if recently triggered
            const recent = this.eventHistory.find(h =>
                h.id === eventDef.id &&
                Date.now() - h.timestamp < 300000 // 5 min cooldown
            );
            if (recent) return;

            // Check triggers
            if (this.shouldTriggerEvent(eventDef, context)) {
                this.triggerEvent(eventDef.id);
            }
        });
    }

    shouldTriggerEvent(eventDef, context) {
        const triggers = eventDef.triggers;

        // Check random chance
        if (triggers.random && Math.random() > triggers.random) {
            return false;
        }

        // Check time of day
        if (triggers.timeOfDay && context.timeOfDay !== triggers.timeOfDay) {
            return false;
        }

        // Check season
        if (triggers.season && context.season !== triggers.season) {
            return false;
        }

        // Check thresholds
        if (triggers.love_threshold && this.worldStats.love < triggers.love_threshold) {
            return false;
        }
        if (triggers.creation_threshold && this.worldStats.creation < triggers.creation_threshold) {
            return false;
        }
        if (triggers.players_online && this.worldStats.playersOnline < triggers.players_online) {
            return false;
        }

        return true;
    }

    triggerEvent(eventId) {
        const eventDef = WORLD_EVENTS[eventId];
        if (!eventDef) return null;

        const event = {
            id: eventId,
            name: eventDef.name,
            description: eventDef.description,
            timeRemaining: eventDef.duration,
            effects: eventDef.effects,
            startTime: Date.now()
        };

        this.activeEvents.push(event);
        this.eventHistory.push({
            id: eventId,
            timestamp: Date.now()
        });

        console.log(`✨ EVENT: ${event.name}! ${event.description}`);

        // Apply effects
        this.applyEventEffects(event);

        return event;
    }

    applyEventEffects(event) {
        event.effects.forEach(effect => {
            switch (effect) {
                case 'spawn_stardust':
                    this.spawnStardust();
                    break;
                case 'aurora_visual':
                    this.createAurora();
                    break;
                case 'rainbow_visual':
                    this.createRainbow();
                    break;
                case 'mass_bloom':
                    this.triggerMassBloom();
                    break;
                case 'increased_magic':
                    // Temporary magic boost
                    break;
                case 'time_distortion':
                    this.createTimeDistortion();
                    break;
                // More effects...
            }
        });
    }

    endEvent(event) {
        console.log(`Event ended: ${event.name}`);
        // Cleanup event effects
    }

    spawnStardust() {
        // Create falling star particles
        const count = 50;
        for (let i = 0; i < count; i++) {
            setTimeout(() => {
                this.createFallingStar();
            }, Math.random() * 60000);
        }
    }

    createFallingStar() {
        const geometry = new THREE.SphereGeometry(0.2, 8, 8);
        const material = new THREE.MeshBasicMaterial({
            color: 0xFFFFFF,
            emissive: 0xFFD700,
            emissiveIntensity: 1
        });

        const star = new THREE.Mesh(geometry, material);
        star.position.set(
            (Math.random() - 0.5) * 200,
            50 + Math.random() * 50,
            (Math.random() - 0.5) * 200
        );

        const velocity = new THREE.Vector3(
            (Math.random() - 0.5) * 2,
            -5 - Math.random() * 5,
            (Math.random() - 0.5) * 2
        );

        this.scene.add(star);

        const animate = () => {
            star.position.add(velocity.clone().multiplyScalar(0.016));

            if (star.position.y < 0) {
                this.scene.remove(star);
                star.geometry.dispose();
                star.material.dispose();
                // Drop stardust item here
            } else {
                requestAnimationFrame(animate);
            }
        };
        animate();
    }

    createAurora() {
        // Create aurora shader effect
        console.log('🌌 Aurora Borealis appears!');
    }

    createRainbow() {
        console.log('🌈 A rainbow appears!');
    }

    triggerMassBloom() {
        console.log('🌸 Super Bloom! Flowers everywhere!');
    }

    createTimeDistortion() {
        console.log('⏰ Time rift opens!');
    }

    updateWorldStats(stats) {
        Object.assign(this.worldStats, stats);
    }

    getActiveEvents() {
        return this.activeEvents;
    }
}

// ===== ECOSYSTEM MANAGER =====
export class EcosystemManager {
    constructor() {
        this.state = 'balanced';
        this.plantHealth = 0.7;
        this.animalPopulation = 0.7;
        this.waterLevel = 0.8;
        this.soilQuality = 0.7;
        this.biodiversity = 0.6;
    }

    update(deltaTime, context = {}) {
        // Natural decay
        this.plantHealth -= deltaTime * 0.001;
        this.animalPopulation -= deltaTime * 0.0005;
        this.waterLevel -= deltaTime * 0.002;
        this.soilQuality -= deltaTime * 0.0003;

        // Environmental effects
        if (context.weather === 'rain') {
            this.waterLevel += deltaTime * 0.01;
        }

        if (context.season === 'spring') {
            this.plantHealth += deltaTime * 0.005;
        }

        // Player care effects
        if (context.plantingRate > 0) {
            this.plantHealth += context.plantingRate * 0.1;
            this.soilQuality += context.plantingRate * 0.05;
        }

        if (context.creaturesCared > 0) {
            this.animalPopulation += context.creaturesCared * 0.05;
        }

        // Clamp values
        this.plantHealth = Math.max(0, Math.min(1, this.plantHealth));
        this.animalPopulation = Math.max(0, Math.min(1, this.animalPopulation));
        this.waterLevel = Math.max(0, Math.min(1, this.waterLevel));
        this.soilQuality = Math.max(0, Math.min(1, this.soilQuality));

        // Update biodiversity
        this.biodiversity = (this.plantHealth + this.animalPopulation) / 2;

        // Determine ecosystem state
        this.updateState();
    }

    updateState() {
        const avgHealth = (this.plantHealth + this.animalPopulation + this.waterLevel + this.soilQuality) / 4;

        if (avgHealth > 0.8) {
            this.state = 'thriving';
        } else if (avgHealth > 0.5) {
            this.state = 'balanced';
        } else if (avgHealth > 0.3) {
            this.state = 'struggling';
        } else {
            this.state = 'endangered';
        }
    }

    getState() {
        return {
            state: this.state,
            ...ECOSYSTEM_STATES[this.state],
            plantHealth: this.plantHealth,
            animalPopulation: this.animalPopulation,
            waterLevel: this.waterLevel,
            soilQuality: this.soilQuality,
            biodiversity: this.biodiversity
        };
    }

    restore(amount = 0.1) {
        this.plantHealth += amount;
        this.animalPopulation += amount;
        this.waterLevel += amount;
        this.soilQuality += amount;
    }
}

// ===== WORLD MEMORY SYSTEM =====
export class WorldMemory {
    constructor() {
        this.memories = [];
        this.maxMemories = 1000;
        this.importantMemories = [];
    }

    remember(event, importance = 0.5, location = null) {
        const memory = {
            id: crypto.randomUUID(),
            event,
            importance,
            location,
            timestamp: Date.now(),
            timesRecalled: 0
        };

        this.memories.push(memory);

        // Keep important memories separate
        if (importance > 0.8) {
            this.importantMemories.push(memory);
        }

        // Forget old unimportant memories
        if (this.memories.length > this.maxMemories) {
            this.memories.sort((a, b) => b.importance - a.importance);
            this.memories = this.memories.slice(0, this.maxMemories);
        }
    }

    recall(query) {
        const results = this.memories.filter(m =>
            m.event.toLowerCase().includes(query.toLowerCase())
        );

        results.forEach(m => m.timesRecalled++);

        return results;
    }

    getRecentMemories(count = 10) {
        return [...this.memories]
            .sort((a, b) => b.timestamp - a.timestamp)
            .slice(0, count);
    }

    getImportantMemories() {
        return this.importantMemories;
    }

    getMemoryCount() {
        return this.memories.length;
    }
}

// ===== MAIN WORLD EVOLUTION MANAGER =====
export class WorldEvolutionManager {
    constructor(scene) {
        this.scene = scene;
        this.seasons = new SeasonManager();
        this.events = new WorldEventManager(scene);
        this.ecosystem = new EcosystemManager();
        this.memory = new WorldMemory();
        this.evolutionStage = 0;
        this.worldAge = 0;
    }

    update(deltaTime, context = {}) {
        this.worldAge += deltaTime;

        // Update season
        this.seasons.update(deltaTime);

        // Add season to context
        context.season = this.seasons.currentSeason;

        // Update events
        this.events.update(deltaTime, context);

        // Update ecosystem
        this.ecosystem.update(deltaTime, context);

        // Check for world evolution
        this.checkEvolution();
    }

    checkEvolution() {
        const ecoState = this.ecosystem.getState();

        // World evolves based on ecosystem health
        if (ecoState.biodiversity > 0.9 && this.evolutionStage < 5) {
            this.evolve();
        }
    }

    evolve() {
        this.evolutionStage++;

        const stages = [
            'Awakening',
            'Flourishing',
            'Harmonious',
            'Transcendent',
            'Infinite'
        ];

        const stage = stages[this.evolutionStage - 1] || 'Unknown';

        console.log(`🌟 WORLD EVOLUTION: Stage ${this.evolutionStage} - ${stage}`);

        this.memory.remember(`World evolved to ${stage}`, 1.0);

        return {
            stage: this.evolutionStage,
            name: stage
        };
    }

    recordPlayerAction(action, impact) {
        // Update world stats for event triggers
        if (impact.love) {
            this.events.worldStats.love += impact.love;
        }
        if (impact.creation) {
            this.events.worldStats.creation += impact.creation;
        }

        // Remember significant actions
        if (impact.significance > 0.7) {
            this.memory.remember(action, impact.significance);
        }
    }

    getWorldState() {
        return {
            age: this.worldAge,
            season: this.seasons.getCurrentSeason(),
            evolutionStage: this.evolutionStage,
            ecosystem: this.ecosystem.getState(),
            activeEvents: this.events.getActiveEvents(),
            memories: this.memory.getMemoryCount()
        };
    }
}

export default WorldEvolutionManager;
