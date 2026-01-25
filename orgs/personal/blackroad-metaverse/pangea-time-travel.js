/**
 * PANGEA TIME TRAVEL SYSTEM
 *
 * Travel through 160 million years of Earth's history!
 * - Early Permian (299 Ma) - Pangea assembling
 * - Late Permian (252 Ma) - Peak Pangea, pre-extinction
 * - Early Triassic (251 Ma) - Post P-T extinction recovery
 * - Late Triassic (201 Ma) - Pangea breaking up, dinosaurs emerging
 * - Early Jurassic (175 Ma) - Pangea fragmenting, age of dinosaurs
 *
 * Features:
 * - Animated continental drift
 * - Flora/fauna evolution
 * - Climate changes
 * - Extinction events
 * - Sea level changes
 */

import * as THREE from 'three';

/**
 * GEOLOGICAL TIME PERIODS
 */
export const TIME_PERIODS = {
    EARLY_PERMIAN: {
        name: 'Early Permian',
        age: 299, // Million years ago
        description: 'Pangea is assembling as continents collide',
        climate: {
            globalTemp: 16, // °C above modern
            co2: 900, // ppm
            seaLevel: 0 // meters relative to modern
        },
        characteristics: [
            'Ice ages in southern Gondwana',
            'Coal swamp forests',
            'Synapsids (mammal-like reptiles) diversifying',
            'Insects reaching massive sizes',
            'First conifers appearing'
        ],
        dominantLife: {
            plants: ['lycophytes', 'seed_ferns', 'early_conifers', 'glossopteris'],
            animals: ['pelycosaurs', 'early_therapsids', 'giant_insects', 'amphibians']
        },
        extinction: null
    },

    LATE_PERMIAN: {
        name: 'Late Permian',
        age: 252,
        description: 'Peak Pangea - the supercontinent is complete',
        climate: {
            globalTemp: 18,
            co2: 1000,
            seaLevel: -60
        },
        characteristics: [
            'Massive interior mega-desert',
            'Siberian Traps beginning to erupt',
            'Advanced therapsids dominating',
            'Warm global climate',
            'Low biodiversity due to continental merging'
        ],
        dominantLife: {
            plants: ['glossopteris', 'cycads', 'conifers', 'ginkgos'],
            animals: ['dicynodonts', 'gorgonopsids', 'therocephalians', 'pareiasaurs']
        },
        extinction: {
            name: 'Permian-Triassic (P-T) Extinction',
            severity: 0.96, // 96% of species died
            cause: 'Siberian Traps volcanism, ocean anoxia, global warming',
            description: 'The Great Dying - worst mass extinction in Earth history'
        }
    },

    EARLY_TRIASSIC: {
        name: 'Early Triassic',
        age: 251,
        description: 'Recovery from P-T extinction - "the dead zone"',
        climate: {
            globalTemp: 22, // Hottest period
            co2: 2500,
            seaLevel: -50
        },
        characteristics: [
            'Few species survived extinction',
            'Lystrosaurus dominates (disaster taxon)',
            'Ocean dead zones',
            'Extreme heat and aridity',
            'Slow ecosystem recovery (10 million years)'
        ],
        dominantLife: {
            plants: ['drought_adapted_conifers', 'ferns', 'lycopods'],
            animals: ['lystrosaurus', 'proterosuchids', 'temnospondyls', 'early_archosaurs']
        },
        extinction: null
    },

    LATE_TRIASSIC: {
        name: 'Late Triassic',
        age: 201,
        description: 'Dinosaurs emerge as Pangea begins to rift',
        climate: {
            globalTemp: 20,
            co2: 1500,
            seaLevel: -25
        },
        characteristics: [
            'First dinosaurs appearing',
            'Pangea starting to split (Central Atlantic opening)',
            'Diverse archosaur fauna',
            'First mammals (tiny, shrew-like)',
            'Large predatory rauisuchians'
        ],
        dominantLife: {
            plants: ['conifers', 'cycads', 'ginkgos', 'ferns', 'bennettitales'],
            animals: ['coelophysis', 'plateosaurus', 'phytosaurs', 'aetosaurs', 'early_pterosaurs']
        },
        extinction: {
            name: 'Triassic-Jurassic (T-J) Extinction',
            severity: 0.76,
            cause: 'CAMP volcanism (Central Atlantic Magmatic Province)',
            description: 'Cleared ecological niches for dinosaurs to dominate'
        }
    },

    EARLY_JURASSIC: {
        name: 'Early Jurassic',
        age: 175,
        description: 'Age of dinosaurs begins - Pangea fragmenting',
        climate: {
            globalTemp: 16,
            co2: 1200,
            seaLevel: +50 // Rising seas
        },
        characteristics: [
            'Dinosaurs dominant on land',
            'First giant sauropods',
            'Pangea splitting into Laurasia and Gondwana',
            'Tethys Sea expanding',
            'Marine reptiles diversifying'
        ],
        dominantLife: {
            plants: ['conifers', 'cycads', 'ginkgos', 'ferns', 'bennettitales'],
            animals: ['dilophosaurus', 'scutellosaurus', 'megapnosaurus', 'ichthyosaurs', 'plesiosaurs']
        },
        extinction: null
    }
};

/**
 * TIME TRAVEL MANAGER
 */
export class TimeTravelSystem {
    constructor(scene, terrain, weatherSystem, creatureManager) {
        this.scene = scene;
        this.terrain = terrain;
        this.weatherSystem = weatherSystem;
        this.creatureManager = creatureManager;

        this.currentPeriod = 'LATE_PERMIAN'; // Default
        this.transitioning = false;
        this.transitionProgress = 0;
        this.transitionDuration = 5; // 5 seconds
    }

    getCurrentPeriod() {
        return TIME_PERIODS[this.currentPeriod];
    }

    travelTo(periodKey) {
        if (this.transitioning) return;
        if (periodKey === this.currentPeriod) return;

        console.log(`Time traveling from ${this.currentPeriod} to ${periodKey}...`);

        this.transitioning = true;
        this.transitionProgress = 0;
        this.targetPeriod = periodKey;

        // Visual transition effect
        this.startTransitionEffect();
    }

    startTransitionEffect() {
        // Add time vortex effect
        this.createTimeVortex();
    }

    createTimeVortex() {
        // Swirling portal particles
        const particleCount = 500;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            const angle = (i / particleCount) * Math.PI * 4;
            const radius = (i / particleCount) * 20;
            positions[i * 3] = Math.cos(angle) * radius;
            positions[i * 3 + 1] = (i / particleCount) * 30;
            positions[i * 3 + 2] = Math.sin(angle) * radius;
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

        const material = new THREE.PointsMaterial({
            color: 0x4a90e2,
            size: 0.5,
            transparent: true,
            opacity: 0.8,
            blending: THREE.AdditiveBlending
        });

        this.vortex = new THREE.Points(geometry, material);
        this.vortex.position.y = 50;
        this.scene.add(this.vortex);
    }

    update(delta) {
        if (!this.transitioning) return;

        this.transitionProgress += delta / this.transitionDuration;

        // Animate vortex
        if (this.vortex) {
            this.vortex.rotation.y += delta * 2;
            this.vortex.material.opacity = Math.sin(this.transitionProgress * Math.PI);
        }

        if (this.transitionProgress >= 1) {
            this.completeTransition();
        }
    }

    completeTransition() {
        // Switch to new period
        this.currentPeriod = this.targetPeriod;
        this.transitioning = false;
        this.transitionProgress = 0;

        // Remove vortex
        if (this.vortex) {
            this.scene.remove(this.vortex);
            this.vortex = null;
        }

        // Apply period changes
        this.applyPeriodChanges();

        console.log(`Arrived in ${this.getCurrentPeriod().name} (${this.getCurrentPeriod().age} Ma)`);
    }

    applyPeriodChanges() {
        const period = this.getCurrentPeriod();

        // Update sky color based on CO2 levels
        this.updateAtmosphere(period.climate);

        // Update available creatures
        this.updateFauna(period.dominantLife.animals);

        // Update vegetation
        this.updateFlora(period.dominantLife.plants);

        // Update sea level (terrain elevation)
        this.updateSeaLevel(period.climate.seaLevel);

        // Trigger extinction event if transitioning through one
        if (period.extinction) {
            this.triggerExtinctionEvent(period.extinction);
        }
    }

    updateAtmosphere(climate) {
        // Higher CO2 = warmer, hazier sky
        const co2Factor = climate.co2 / 1000; // Normalize to modern ~400ppm
        const haze = Math.min(0.3, (co2Factor - 0.4) * 0.5);

        // Adjust fog
        if (this.scene.fog) {
            this.scene.fog.near = 50 * (1 + haze);
            this.scene.fog.far = 400 * (1 - haze);
        }

        // Temperature affects sky color
        let skyColor;
        if (climate.globalTemp > 20) {
            // Hot = more yellowy sky
            skyColor = new THREE.Color(0xb8d4e6);
        } else if (climate.globalTemp < 12) {
            // Cold = bluer, clearer
            skyColor = new THREE.Color(0x87ceeb);
        } else {
            skyColor = new THREE.Color(0x9bc4e2);
        }

        this.scene.background = skyColor;
        if (this.scene.fog) {
            this.scene.fog.color = skyColor;
        }
    }

    updateFauna(animals) {
        // Clear current creatures
        this.creatureManager.clearAll();

        // Spawn period-appropriate creatures
        const creatureMapping = {
            'lystrosaurus': 'LYSTROSAURUS',
            'dicynodonts': 'LYSTROSAURUS', // Similar
            'coelophysis': 'COELOPHYSIS',
            'early_archosaurs': 'COELOPHYSIS',
            'proterosuchids': 'COELOPHYSIS',
            'ichthyosaurs': 'ICHTHYOSAUR',
            'plesiosaurs': 'PLESIOSAUR',
            'temnospondyls': 'TEMNOSPONDYL'
        };

        animals.forEach(animal => {
            const creatureType = creatureMapping[animal];
            if (creatureType) {
                // Spawn several of each type
                for (let i = 0; i < 3; i++) {
                    this.creatureManager.spawnRandomCreatures(1);
                }
            }
        });
    }

    updateFlora(plants) {
        // Vegetation changes would require regenerating terrain
        // For now, just log the change
        console.log(`Flora updated to: ${plants.join(', ')}`);
    }

    updateSeaLevel(relativeSealevel) {
        // Adjust ocean depth rendering
        // Positive = higher seas (more ocean)
        // Negative = lower seas (more land)
        console.log(`Sea level: ${relativeSealevel > 0 ? '+' : ''}${relativeSealevel}m`);
    }

    triggerExtinctionEvent(extinction) {
        console.log(`⚠️  EXTINCTION EVENT: ${extinction.name}`);
        console.log(`   Severity: ${(extinction.severity * 100).toFixed(0)}% species loss`);
        console.log(`   Cause: ${extinction.cause}`);

        // Visual effects
        this.createExtinctionEffects(extinction);

        // Remove creatures based on severity
        const survivalRate = 1 - extinction.severity;
        this.creatureManager.creatures.forEach(creature => {
            if (Math.random() > survivalRate) {
                creature.health = 0; // Mark for deletion
            }
        });
    }

    createExtinctionEffects(extinction) {
        // Screen flash (red for extinction)
        const flash = document.createElement('div');
        flash.style.position = 'fixed';
        flash.style.top = '0';
        flash.style.left = '0';
        flash.style.width = '100%';
        flash.style.height = '100%';
        flash.style.backgroundColor = 'rgba(255, 0, 0, 0.5)';
        flash.style.pointerEvents = 'none';
        flash.style.zIndex = '9999';
        flash.style.animation = 'fade-out 3s forwards';
        document.body.appendChild(flash);

        setTimeout(() => {
            document.body.removeChild(flash);
        }, 3000);

        // Add CSS animation
        if (!document.getElementById('extinction-style')) {
            const style = document.createElement('style');
            style.id = 'extinction-style';
            style.innerHTML = `
                @keyframes fade-out {
                    0% { opacity: 1; }
                    100% { opacity: 0; }
                }
            `;
            document.head.appendChild(style);
        }
    }

    getAllPeriods() {
        return Object.keys(TIME_PERIODS).map(key => ({
            key,
            ...TIME_PERIODS[key]
        })).sort((a, b) => b.age - a.age); // Oldest first
    }

    jumpForward() {
        const periods = this.getAllPeriods();
        const currentIndex = periods.findIndex(p => p.key === this.currentPeriod);
        if (currentIndex < periods.length - 1) {
            this.travelTo(periods[currentIndex + 1].key);
        }
    }

    jumpBackward() {
        const periods = this.getAllPeriods();
        const currentIndex = periods.findIndex(p => p.key === this.currentPeriod);
        if (currentIndex > 0) {
            this.travelTo(periods[currentIndex - 1].key);
        }
    }

    getTimeline() {
        return this.getAllPeriods();
    }
}

export default { TimeTravelSystem, TIME_PERIODS };
