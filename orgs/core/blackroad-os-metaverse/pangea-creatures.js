/**
 * PANGEA LIVING CREATURES
 *
 * Animated, AI-driven prehistoric animals with realistic behaviors
 * - Autonomous movement and pathfinding
 * - Hunting, grazing, swimming behaviors
 * - Flocking/herding for social species
 * - Day/night activity cycles
 * - Territorial behaviors
 */

import * as THREE from 'three';

/**
 * CREATURE AI BEHAVIORS
 */
export const BEHAVIORS = {
    IDLE: 'idle',
    WANDER: 'wander',
    GRAZE: 'graze',
    HUNT: 'hunt',
    FLEE: 'flee',
    SWIM: 'swim',
    FLY: 'fly',
    SLEEP: 'sleep',
    DRINK: 'drink',
    SOCIALIZE: 'socialize',
    TERRITORIAL: 'territorial'
};

/**
 * CREATURE TYPES WITH AI PROFILES
 */
export const CREATURE_TYPES = {
    LYSTROSAURUS: {
        name: 'Lystrosaurus',
        type: 'herbivore',
        size: 'medium',
        speed: 3,
        behaviors: [BEHAVIORS.GRAZE, BEHAVIORS.WANDER, BEHAVIORS.SOCIALIZE, BEHAVIORS.FLEE],
        social: true,
        herdSize: [3, 8],
        activeTime: 'day',
        diet: ['ferns', 'low_plants'],
        soundFrequency: 0.1,
        aggression: 0.1,
        stamina: 0.7
    },

    DIMETRODON: {
        name: 'Dimetrodon',
        type: 'carnivore',
        size: 'large',
        speed: 4,
        behaviors: [BEHAVIORS.HUNT, BEHAVIORS.TERRITORIAL, BEHAVIORS.WANDER, BEHAVIORS.IDLE],
        social: false,
        herdSize: [1, 1],
        activeTime: 'day',
        diet: ['small_animals', 'fish'],
        soundFrequency: 0.05,
        aggression: 0.8,
        stamina: 0.6,
        huntRange: 30
    },

    COELOPHYSIS: {
        name: 'Coelophysis',
        type: 'carnivore',
        size: 'small',
        speed: 8,
        behaviors: [BEHAVIORS.HUNT, BEHAVIORS.WANDER, BEHAVIORS.SOCIALIZE],
        social: true,
        herdSize: [2, 5],
        activeTime: 'day',
        diet: ['insects', 'small_animals'],
        soundFrequency: 0.2,
        aggression: 0.6,
        stamina: 0.9
    },

    CYNOGNATHUS: {
        name: 'Cynognathus',
        type: 'carnivore',
        size: 'medium',
        speed: 6,
        behaviors: [BEHAVIORS.HUNT, BEHAVIORS.WANDER, BEHAVIORS.TERRITORIAL],
        social: false,
        herdSize: [1, 2],
        activeTime: 'both',
        diet: ['small_animals', 'carrion'],
        soundFrequency: 0.15,
        aggression: 0.7,
        stamina: 0.75
    },

    TEMNOSPONDYL: {
        name: 'Temnospondyl',
        type: 'carnivore',
        size: 'large',
        speed: 2,
        behaviors: [BEHAVIORS.SWIM, BEHAVIORS.HUNT, BEHAVIORS.IDLE],
        social: false,
        herdSize: [1, 1],
        activeTime: 'both',
        diet: ['fish', 'small_animals'],
        soundFrequency: 0.08,
        aggression: 0.5,
        stamina: 0.4,
        aquatic: true
    },

    PTEROSAUR: {
        name: 'Pterosaur',
        type: 'carnivore',
        size: 'medium',
        speed: 12,
        behaviors: [BEHAVIORS.FLY, BEHAVIORS.HUNT, BEHAVIORS.WANDER],
        social: true,
        herdSize: [3, 10],
        activeTime: 'day',
        diet: ['fish', 'insects'],
        soundFrequency: 0.3,
        aggression: 0.3,
        stamina: 0.8,
        flying: true
    },

    PLESIOSAUR: {
        name: 'Plesiosaur',
        type: 'carnivore',
        size: 'large',
        speed: 5,
        behaviors: [BEHAVIORS.SWIM, BEHAVIORS.HUNT],
        social: false,
        herdSize: [1, 2],
        activeTime: 'both',
        diet: ['fish', 'cephalopods'],
        soundFrequency: 0.05,
        aggression: 0.6,
        stamina: 0.7,
        aquatic: true,
        deepWater: true
    },

    ICHTHYOSAUR: {
        name: 'Ichthyosaur',
        type: 'carnivore',
        size: 'large',
        speed: 10,
        behaviors: [BEHAVIORS.SWIM, BEHAVIORS.HUNT],
        social: true,
        herdSize: [2, 6],
        activeTime: 'both',
        diet: ['fish', 'squid'],
        soundFrequency: 0.1,
        aggression: 0.5,
        stamina: 0.9,
        aquatic: true
    }
};

/**
 * LIVING CREATURE CLASS
 * Individual creature with AI and animation
 */
export class LivingCreature {
    constructor(type, position, scene, terrain) {
        this.type = CREATURE_TYPES[type];
        this.scene = scene;
        this.terrain = terrain;

        // State
        this.position = position.clone();
        this.velocity = new THREE.Vector3();
        this.rotation = Math.random() * Math.PI * 2;
        this.health = 1.0;
        this.energy = 1.0;
        this.hunger = 0.0;

        // AI
        this.behavior = BEHAVIORS.WANDER;
        this.target = null;
        this.targetPosition = null;
        this.behaviorTimer = 0;
        this.soundTimer = 0;

        // Animation
        this.animationTime = Math.random() * Math.PI * 2;
        this.animationSpeed = 1 + Math.random();

        // Create 3D model
        this.mesh = this.createMesh(type);
        this.mesh.position.copy(position);
        this.mesh.rotation.y = this.rotation;
        scene.add(this.mesh);
    }

    createMesh(type) {
        const group = new THREE.Group();

        switch(type) {
            case 'LYSTROSAURUS':
                this.createLystrosaurusMesh(group);
                break;
            case 'DIMETRODON':
                this.createDimetrodonMesh(group);
                break;
            case 'COELOPHYSIS':
                this.createCoelophysisMesh(group);
                break;
            case 'PTEROSAUR':
                this.createPterosaurMesh(group);
                break;
            case 'PLESIOSAUR':
                this.createPlesiosaurMesh(group);
                break;
            case 'ICHTHYOSAUR':
                this.createIchthyosaurMesh(group);
                break;
            default:
                this.createGenericMesh(group);
        }

        return group;
    }

    createLystrosaurusMesh(group) {
        // Body (stocky, low)
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(1.2, 0.6, 2),
            new THREE.MeshStandardMaterial({
                color: 0x6b5d4f,
                roughness: 0.9
            })
        );
        body.position.y = 0.5;
        body.castShadow = true;
        group.add(body);

        // Head with tusks
        const head = new THREE.Mesh(
            new THREE.BoxGeometry(0.6, 0.5, 0.7),
            new THREE.MeshStandardMaterial({ color: 0x7a6a5a })
        );
        head.position.set(0, 0.5, 1.2);
        head.castShadow = true;
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

        // Legs (animated)
        this.legs = [];
        for (let i = 0; i < 4; i++) {
            const leg = new THREE.Mesh(
                new THREE.CylinderGeometry(0.1, 0.08, 0.5, 6),
                new THREE.MeshStandardMaterial({ color: 0x6b5d4f })
            );
            const x = (i % 2 === 0) ? 0.4 : -0.4;
            const z = (i < 2) ? 0.7 : -0.7;
            leg.position.set(x, 0.25, z);
            leg.castShadow = true;
            group.add(leg);
            this.legs.push(leg);
        }

        this.bodyParts = { body, head };
    }

    createDimetrodonMesh(group) {
        // Body
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(0.8, 0.5, 2.5),
            new THREE.MeshStandardMaterial({ color: 0x5a4a3a })
        );
        body.position.y = 0.6;
        body.castShadow = true;
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
        sail.castShadow = true;
        group.add(sail);

        // Head
        const head = new THREE.Mesh(
            new THREE.ConeGeometry(0.3, 0.8, 8),
            new THREE.MeshStandardMaterial({ color: 0x6a5a4a })
        );
        head.position.set(0, 0.6, 1.6);
        head.rotation.z = -Math.PI / 2;
        head.castShadow = true;
        group.add(head);

        // Legs
        this.legs = [];
        for (let i = 0; i < 4; i++) {
            const leg = new THREE.Mesh(
                new THREE.CylinderGeometry(0.1, 0.08, 0.6, 6),
                new THREE.MeshStandardMaterial({ color: 0x5a4a3a })
            );
            const x = (i % 2 === 0) ? 0.3 : -0.3;
            const z = (i < 2) ? 1 : -0.8;
            leg.position.set(x, 0.3, z);
            leg.castShadow = true;
            group.add(leg);
            this.legs.push(leg);
        }

        this.bodyParts = { body, head, sail };
    }

    createCoelophysisMesh(group) {
        // Body (bipedal)
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(0.4, 0.5, 1.5),
            new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
        );
        body.position.set(0, 1.2, -0.2);
        body.rotation.x = Math.PI / 8;
        body.castShadow = true;
        group.add(body);

        // Neck
        const neck = new THREE.Mesh(
            new THREE.CylinderGeometry(0.15, 0.2, 0.8, 8),
            new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
        );
        neck.position.set(0, 1.5, 0.5);
        neck.rotation.x = -Math.PI / 4;
        neck.castShadow = true;
        group.add(neck);

        // Head
        const head = new THREE.Mesh(
            new THREE.ConeGeometry(0.2, 0.5, 8),
            new THREE.MeshStandardMaterial({ color: 0x7a9e33 })
        );
        head.position.set(0, 1.8, 1.0);
        head.rotation.z = -Math.PI / 2;
        head.castShadow = true;
        group.add(head);

        // Tail
        const tail = new THREE.Mesh(
            new THREE.CylinderGeometry(0.08, 0.15, 1.5, 8),
            new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
        );
        tail.position.set(0, 1, -1.2);
        tail.rotation.x = -Math.PI / 3;
        tail.castShadow = true;
        group.add(tail);

        // Hind legs
        this.legs = [];
        for (let side of [-1, 1]) {
            const leg = new THREE.Mesh(
                new THREE.CylinderGeometry(0.1, 0.08, 1.2, 6),
                new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
            );
            leg.position.set(side * 0.2, 0.6, -0.2);
            leg.castShadow = true;
            group.add(leg);
            this.legs.push(leg);
        }

        // Small arms
        for (let side of [-1, 1]) {
            const arm = new THREE.Mesh(
                new THREE.CylinderGeometry(0.05, 0.04, 0.4, 6),
                new THREE.MeshStandardMaterial({ color: 0x6b8e23 })
            );
            arm.position.set(side * 0.25, 1.3, 0.4);
            arm.rotation.x = Math.PI / 3;
            group.add(arm);
        }

        this.bodyParts = { body, head, neck, tail };
    }

    createPterosaurMesh(group) {
        // Body (small, light)
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(0.3, 0.3, 0.6),
            new THREE.MeshStandardMaterial({ color: 0x8b7355 })
        );
        body.position.y = 0.3;
        body.castShadow = true;
        group.add(body);

        // Head with crest
        const head = new THREE.Mesh(
            new THREE.ConeGeometry(0.15, 0.4, 8),
            new THREE.MeshStandardMaterial({ color: 0x9b8365 })
        );
        head.position.set(0, 0.3, 0.5);
        head.rotation.z = -Math.PI / 2;
        head.castShadow = true;
        group.add(head);

        // Crest
        const crest = new THREE.Mesh(
            new THREE.PlaneGeometry(0.3, 0.4),
            new THREE.MeshStandardMaterial({
                color: 0xff6b35,
                side: THREE.DoubleSide
            })
        );
        crest.position.set(0, 0.5, 0.5);
        crest.rotation.y = Math.PI / 2;
        group.add(crest);

        // Wings
        this.wings = [];
        for (let side of [-1, 1]) {
            const wing = new THREE.Mesh(
                new THREE.PlaneGeometry(2, 1),
                new THREE.MeshStandardMaterial({
                    color: 0x8b7355,
                    side: THREE.DoubleSide,
                    transparent: true,
                    opacity: 0.8
                })
            );
            wing.position.set(side * 0.3, 0.3, 0);
            wing.rotation.y = side * Math.PI / 6;
            group.add(wing);
            this.wings.push({ mesh: wing, side });
        }

        this.bodyParts = { body, head };
    }

    createPlesiosaurMesh(group) {
        // Body
        const body = new THREE.Mesh(
            new THREE.BoxGeometry(1, 0.8, 2),
            new THREE.MeshStandardMaterial({ color: 0x2d5a4a })
        );
        body.position.y = 0;
        group.add(body);

        // Long neck
        const neckSegments = 5;
        this.neckParts = [];
        for (let i = 0; i < neckSegments; i++) {
            const segment = new THREE.Mesh(
                new THREE.CylinderGeometry(0.2, 0.25, 0.4, 8),
                new THREE.MeshStandardMaterial({ color: 0x2d5a4a })
            );
            segment.position.set(0, 0.2, 1 + i * 0.3);
            group.add(segment);
            this.neckParts.push(segment);
        }

        // Head
        const head = new THREE.Mesh(
            new THREE.ConeGeometry(0.25, 0.6, 8),
            new THREE.MeshStandardMaterial({ color: 0x3d6a5a })
        );
        head.position.set(0, 0.2, 2.5);
        head.rotation.z = -Math.PI / 2;
        group.add(head);

        // Flippers
        this.flippers = [];
        for (let i = 0; i < 4; i++) {
            const flipper = new THREE.Mesh(
                new THREE.BoxGeometry(0.8, 0.1, 0.3),
                new THREE.MeshStandardMaterial({ color: 0x2d5a4a })
            );
            const x = (i % 2 === 0) ? 0.7 : -0.7;
            const z = (i < 2) ? 0.8 : -0.8;
            flipper.position.set(x, 0, z);
            group.add(flipper);
            this.flippers.push(flipper);
        }

        this.bodyParts = { body, head };
    }

    createIchthyosaurMesh(group) {
        // Streamlined body
        const body = new THREE.Mesh(
            new THREE.CylinderGeometry(0.4, 0.2, 3, 12),
            new THREE.MeshStandardMaterial({ color: 0x1a3d5a })
        );
        body.rotation.z = Math.PI / 2;
        group.add(body);

        // Head
        const head = new THREE.Mesh(
            new THREE.ConeGeometry(0.4, 0.8, 12),
            new THREE.MeshStandardMaterial({ color: 0x2a4d6a })
        );
        head.position.x = 1.9;
        head.rotation.z = -Math.PI / 2;
        group.add(head);

        // Dorsal fin
        const dorsalFin = new THREE.Mesh(
            new THREE.PlaneGeometry(0.8, 0.6),
            new THREE.MeshStandardMaterial({
                color: 0x1a3d5a,
                side: THREE.DoubleSide
            })
        );
        dorsalFin.position.set(0, 0.6, 0);
        dorsalFin.rotation.x = Math.PI / 2;
        group.add(dorsalFin);

        // Tail
        this.tail = new THREE.Mesh(
            new THREE.PlaneGeometry(0.6, 1),
            new THREE.MeshStandardMaterial({
                color: 0x1a3d5a,
                side: THREE.DoubleSide
            })
        );
        this.tail.position.set(-1.7, 0, 0);
        this.tail.rotation.y = Math.PI / 2;
        group.add(this.tail);

        // Flippers
        this.flippers = [];
        for (let side of [-1, 1]) {
            const flipper = new THREE.Mesh(
                new THREE.BoxGeometry(0.8, 0.1, 0.3),
                new THREE.MeshStandardMaterial({ color: 0x1a3d5a })
            );
            flipper.position.set(0.5, 0, side * 0.5);
            group.add(flipper);
            this.flippers.push(flipper);
        }

        this.bodyParts = { body, head };
    }

    createGenericMesh(group) {
        const body = new THREE.Mesh(
            new THREE.SphereGeometry(0.5, 8, 8),
            new THREE.MeshStandardMaterial({ color: 0x8b7355 })
        );
        body.position.y = 0.5;
        body.castShadow = true;
        group.add(body);
        this.bodyParts = { body };
    }

    /**
     * UPDATE AI AND ANIMATION
     */
    update(delta, creatures) {
        // Update timers
        this.behaviorTimer -= delta;
        this.soundTimer -= delta;
        this.animationTime += delta * this.animationSpeed;

        // Energy and hunger
        this.energy = Math.max(0, this.energy - delta * 0.01);
        this.hunger = Math.min(1, this.hunger + delta * 0.02);

        // Decide behavior
        if (this.behaviorTimer <= 0) {
            this.decideBehavior(creatures);
            this.behaviorTimer = 3 + Math.random() * 7; // 3-10 seconds
        }

        // Execute behavior
        this.executeBehavior(delta);

        // Animate
        this.animate(delta);

        // Update position
        this.mesh.position.copy(this.position);
        this.mesh.rotation.y = this.rotation;
    }

    decideBehavior(creatures) {
        const behaviors = this.type.behaviors;

        // Low energy = rest
        if (this.energy < 0.2) {
            this.behavior = BEHAVIORS.IDLE;
            return;
        }

        // High hunger = find food
        if (this.hunger > 0.7) {
            if (this.type.type === 'herbivore') {
                this.behavior = BEHAVIORS.GRAZE;
            } else {
                this.behavior = BEHAVIORS.HUNT;
            }
            return;
        }

        // Random behavior from available
        this.behavior = behaviors[Math.floor(Math.random() * behaviors.length)];
    }

    executeBehavior(delta) {
        switch(this.behavior) {
            case BEHAVIORS.WANDER:
                this.wander(delta);
                break;
            case BEHAVIORS.GRAZE:
                this.graze(delta);
                break;
            case BEHAVIORS.HUNT:
                this.hunt(delta);
                break;
            case BEHAVIORS.SWIM:
                this.swim(delta);
                break;
            case BEHAVIORS.FLY:
                this.fly(delta);
                break;
            case BEHAVIORS.IDLE:
                this.idle(delta);
                break;
            default:
                this.wander(delta);
        }
    }

    wander(delta) {
        // Random walk
        if (!this.targetPosition || this.position.distanceTo(this.targetPosition) < 2) {
            this.targetPosition = new THREE.Vector3(
                this.position.x + (Math.random() - 0.5) * 40,
                this.position.y,
                this.position.z + (Math.random() - 0.5) * 40
            );
        }

        this.moveToward(this.targetPosition, delta);
    }

    graze(delta) {
        // Move slowly, eating
        if (Math.random() < 0.1) {
            this.hunger = Math.max(0, this.hunger - 0.1);
        }

        if (Math.random() < 0.3) {
            this.wander(delta);
        }
    }

    hunt(delta) {
        // Look for prey (simplified)
        if (!this.targetPosition || Math.random() < 0.1) {
            this.targetPosition = new THREE.Vector3(
                this.position.x + (Math.random() - 0.5) * 60,
                this.position.y,
                this.position.z + (Math.random() - 0.5) * 60
            );
        }

        this.moveToward(this.targetPosition, delta, this.type.speed * 1.2);
    }

    swim(delta) {
        // Undulating movement in water
        if (!this.targetPosition || this.position.distanceTo(this.targetPosition) < 3) {
            this.targetPosition = new THREE.Vector3(
                this.position.x + (Math.random() - 0.5) * 50,
                -5 - Math.random() * 20, // Stay underwater
                this.position.z + (Math.random() - 0.5) * 50
            );
        }

        this.moveToward(this.targetPosition, delta, this.type.speed);

        // Vertical undulation
        this.position.y += Math.sin(this.animationTime * 2) * 0.3 * delta;
    }

    fly(delta) {
        // Flying in air
        if (!this.targetPosition || this.position.distanceTo(this.targetPosition) < 5) {
            this.targetPosition = new THREE.Vector3(
                this.position.x + (Math.random() - 0.5) * 80,
                20 + Math.random() * 30, // High altitude
                this.position.z + (Math.random() - 0.5) * 80
            );
        }

        this.moveToward(this.targetPosition, delta, this.type.speed);
    }

    idle(delta) {
        // Just chill
        this.energy = Math.min(1, this.energy + delta * 0.05);
    }

    moveToward(target, delta, speedMultiplier = 1) {
        const direction = new THREE.Vector3()
            .subVectors(target, this.position)
            .normalize();

        const speed = this.type.speed * speedMultiplier * delta;

        this.velocity.copy(direction).multiplyScalar(speed);
        this.position.add(this.velocity);

        // Face direction
        this.rotation = Math.atan2(direction.x, direction.z);

        // Constrain to terrain (if land creature)
        if (!this.type.aquatic && !this.type.flying) {
            const terrainHeight = this.terrain.getElevation(this.position.x, this.position.z);
            if (terrainHeight > 0) {
                this.position.y = terrainHeight;
            }
        }
    }

    animate(delta) {
        // Leg animation (walking)
        if (this.legs && this.velocity.length() > 0.1) {
            this.legs.forEach((leg, i) => {
                const phase = i * Math.PI + this.animationTime * 8;
                leg.rotation.x = Math.sin(phase) * 0.5;
            });
        }

        // Wing flapping
        if (this.wings) {
            this.wings.forEach(wing => {
                const flap = Math.sin(this.animationTime * 10) * 0.8;
                wing.mesh.rotation.z = wing.side * (Math.PI / 6 + flap);
            });
        }

        // Tail swaying
        if (this.tail) {
            this.tail.rotation.y = Math.PI / 2 + Math.sin(this.animationTime * 5) * 0.4;
        }

        // Flipper swimming
        if (this.flippers) {
            this.flippers.forEach((flipper, i) => {
                const phase = i * Math.PI + this.animationTime * 4;
                flipper.rotation.x = Math.sin(phase) * 0.6;
            });
        }

        // Neck undulation
        if (this.neckParts) {
            this.neckParts.forEach((part, i) => {
                const wave = Math.sin(this.animationTime * 2 + i * 0.3) * 0.1;
                part.position.y = 0.2 + wave;
            });
        }

        // Body bobbing
        if (this.bodyParts && this.bodyParts.body) {
            this.bodyParts.body.position.y += Math.sin(this.animationTime * 3) * 0.02;
        }
    }

    destroy() {
        this.scene.remove(this.mesh);
    }
}

/**
 * CREATURE MANAGER
 * Spawns and manages all creatures in the world
 */
export class CreatureManager {
    constructor(scene, terrain) {
        this.scene = scene;
        this.terrain = terrain;
        this.creatures = [];
        this.maxCreatures = 50;
        this.spawnRadius = 150;
    }

    spawnCreature(type, position) {
        const creature = new LivingCreature(type, position, this.scene, this.terrain);
        this.creatures.push(creature);
        return creature;
    }

    spawnInBiome(biome, count = 1) {
        // Spawn creatures appropriate for biome
        const creatureTypes = this.getCreatureTypesForBiome(biome);

        for (let i = 0; i < count; i++) {
            if (this.creatures.length >= this.maxCreatures) break;

            const type = creatureTypes[Math.floor(Math.random() * creatureTypes.length)];
            const position = this.findSpawnPosition(biome);

            if (position) {
                this.spawnCreature(type, position);
            }
        }
    }

    getCreatureTypesForBiome(biome) {
        // Match creatures to biomes
        const biomeCreatures = {
            TROPICAL_RAINFOREST: ['LYSTROSAURUS', 'DIMETRODON', 'COELOPHYSIS'],
            ARID_INTERIOR: ['COELOPHYSIS', 'CYNOGNATHUS'],
            COASTAL_WETLANDS: ['LYSTROSAURUS', 'TEMNOSPONDYL'],
            PANTHALASSA_OCEAN: ['PLESIOSAUR', 'ICHTHYOSAUR'],
            TETHYS_SEA: ['ICHTHYOSAUR'],
            GONDWANA_POLAR_FOREST: ['LYSTROSAURUS'],
            DEFAULT: ['LYSTROSAURUS', 'COELOPHYSIS']
        };

        return biomeCreatures[biome] || biomeCreatures.DEFAULT;
    }

    findSpawnPosition(biome) {
        // Find valid spawn location
        for (let attempts = 0; attempts < 10; attempts++) {
            const x = (Math.random() - 0.5) * this.spawnRadius;
            const z = (Math.random() - 0.5) * this.spawnRadius;
            const y = this.terrain.getElevation(x, z);

            // Check if valid for biome
            if (biome.includes('OCEAN') || biome.includes('SEA')) {
                if (y < 0) {
                    return new THREE.Vector3(x, y, z);
                }
            } else {
                if (y > 0) {
                    return new THREE.Vector3(x, y, z);
                }
            }
        }
        return null;
    }

    update(delta) {
        // Update all creatures
        this.creatures.forEach(creature => {
            creature.update(delta, this.creatures);
        });

        // Remove dead creatures
        this.creatures = this.creatures.filter(creature => {
            if (creature.health <= 0) {
                creature.destroy();
                return false;
            }
            return true;
        });

        // Spawn new creatures if below threshold
        if (this.creatures.length < this.maxCreatures * 0.5) {
            this.spawnRandomCreatures(5);
        }
    }

    spawnRandomCreatures(count) {
        const types = Object.keys(CREATURE_TYPES);
        for (let i = 0; i < count; i++) {
            const type = types[Math.floor(Math.random() * types.length)];
            const typeData = CREATURE_TYPES[type];

            let position;
            if (typeData.aquatic) {
                position = new THREE.Vector3(
                    (Math.random() - 0.5) * this.spawnRadius,
                    -10 - Math.random() * 20,
                    (Math.random() - 0.5) * this.spawnRadius
                );
            } else if (typeData.flying) {
                position = new THREE.Vector3(
                    (Math.random() - 0.5) * this.spawnRadius,
                    20 + Math.random() * 20,
                    (Math.random() - 0.5) * this.spawnRadius
                );
            } else {
                const x = (Math.random() - 0.5) * this.spawnRadius;
                const z = (Math.random() - 0.5) * this.spawnRadius;
                const y = this.terrain.getElevation(x, z);
                if (y > 0) {
                    position = new THREE.Vector3(x, y, z);
                }
            }

            if (position) {
                this.spawnCreature(type, position);
            }
        }
    }

    clearAll() {
        this.creatures.forEach(creature => creature.destroy());
        this.creatures = [];
    }
}

export default CreatureManager;
