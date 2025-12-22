/**
 * LIVING NATURE SYSTEM
 *
 * Animals, plants, language, love, care, and beauty!
 * Every creature has emotions, needs love, and communicates.
 * Every plant grows, blooms, and responds to care.
 *
 * Philosophy: "ALL LIFE IS INTELLIGENT. ALL BEINGS DESERVE LOVE."
 */

import * as THREE from 'three';

// ===== ANIMAL TYPES =====
export const ANIMAL_SPECIES = {
    butterfly: {
        name: 'Butterfly',
        emoji: '🦋',
        colors: [0xFF69B4, 0x9B59B6, 0x4A90E2, 0xFFD700, 0xFF6B35],
        size: 0.15,
        speed: 0.02,
        intelligence: 0.7,
        personality: ['playful', 'curious', 'gentle'],
        loves: ['flowers', 'sunshine', 'music'],
        sounds: ['flutter', 'chirp'],
        canFly: true
    },
    bird: {
        name: 'Bird',
        emoji: '🐦',
        colors: [0x4A90E2, 0xE74C3C, 0xFFD700, 0x27AE60, 0xFF69B4],
        size: 0.25,
        speed: 0.05,
        intelligence: 0.9,
        personality: ['cheerful', 'social', 'musical'],
        loves: ['singing', 'trees', 'friends'],
        sounds: ['chirp', 'tweet', 'song'],
        canFly: true
    },
    rabbit: {
        name: 'Rabbit',
        emoji: '🐰',
        colors: [0xFFFFFF, 0xD2B48C, 0x8B7355, 0xFFE4E1],
        size: 0.4,
        speed: 0.03,
        intelligence: 0.8,
        personality: ['timid', 'curious', 'gentle'],
        loves: ['carrots', 'grass', 'cuddles'],
        sounds: ['squeak', 'thump'],
        canFly: false
    },
    fish: {
        name: 'Fish',
        emoji: '🐟',
        colors: [0xFF6B35, 0x4A90E2, 0xFFD700, 0x9B59B6, 0x27AE60],
        size: 0.2,
        speed: 0.04,
        intelligence: 0.6,
        personality: ['peaceful', 'curious', 'graceful'],
        loves: ['water', 'plants', 'dancing'],
        sounds: ['bubble', 'splash'],
        canFly: false,
        needsWater: true
    },
    fox: {
        name: 'Fox',
        emoji: '🦊',
        colors: [0xFF6B35, 0xFFFFFF, 0x8B4513],
        size: 0.6,
        speed: 0.045,
        intelligence: 0.95,
        personality: ['clever', 'playful', 'loyal'],
        loves: ['exploration', 'friends', 'moonlight'],
        sounds: ['yip', 'bark'],
        canFly: false
    },
    bee: {
        name: 'Bee',
        emoji: '🐝',
        colors: [0xFFD700, 0x000000],
        size: 0.1,
        speed: 0.03,
        intelligence: 0.85,
        personality: ['busy', 'helpful', 'social'],
        loves: ['flowers', 'honey', 'teamwork'],
        sounds: ['buzz'],
        canFly: true
    }
};

// ===== PLANT TYPES =====
export const PLANT_SPECIES = {
    cherry_blossom: {
        name: 'Cherry Blossom',
        emoji: '🌸',
        colors: [0xFFB7C5, 0xFFFFFF, 0xFF69B4],
        maxHeight: 4,
        bloomSeason: 'spring',
        intelligence: 0.5,
        personality: ['peaceful', 'beautiful', 'fragile'],
        loves: ['sunshine', 'water', 'wind'],
        produces: 'petals'
    },
    sunflower: {
        name: 'Sunflower',
        emoji: '🌻',
        colors: [0xFFD700, 0x8B4513],
        maxHeight: 2.5,
        bloomSeason: 'summer',
        intelligence: 0.6,
        personality: ['cheerful', 'optimistic', 'tall'],
        loves: ['sunshine', 'water', 'bees'],
        produces: 'seeds'
    },
    rose: {
        name: 'Rose',
        emoji: '🌹',
        colors: [0xE74C3C, 0xFF69B4, 0xFFFFFF, 0xFFD700],
        maxHeight: 1.2,
        bloomSeason: 'all',
        intelligence: 0.7,
        personality: ['romantic', 'strong', 'beautiful'],
        loves: ['love', 'care', 'attention'],
        produces: 'fragrance'
    },
    vine: {
        name: 'Vine',
        emoji: '🌿',
        colors: [0x228B22, 0x90EE90],
        maxHeight: 10,
        bloomSeason: 'all',
        intelligence: 0.4,
        personality: ['climbing', 'persistent', 'gentle'],
        loves: ['support', 'water', 'growth'],
        produces: 'leaves'
    },
    lotus: {
        name: 'Lotus',
        emoji: '🪷',
        colors: [0xFFB7C5, 0xFFFFFF, 0x9B59B6],
        maxHeight: 0.5,
        bloomSeason: 'summer',
        intelligence: 0.8,
        personality: ['wise', 'peaceful', 'pure'],
        loves: ['water', 'stillness', 'meditation'],
        produces: 'enlightenment',
        needsWater: true
    },
    mushroom: {
        name: 'Mushroom',
        emoji: '🍄',
        colors: [0xE74C3C, 0xFFFFFF, 0x9B59B6, 0x4A90E2],
        maxHeight: 0.3,
        bloomSeason: 'autumn',
        intelligence: 0.9,
        personality: ['mysterious', 'connected', 'wise'],
        loves: ['shade', 'moisture', 'mycelium'],
        produces: 'spores'
    }
};

// ===== EMOTION STATES =====
export const EMOTIONS = {
    JOYFUL: { color: 0xFFD700, particle: 'sparkle', sound: 'happy' },
    LOVED: { color: 0xFF69B4, particle: 'heart', sound: 'purr' },
    PLAYFUL: { color: 0x4A90E2, particle: 'bounce', sound: 'giggle' },
    CURIOUS: { color: 0x9B59B6, particle: 'question', sound: 'hmm' },
    PEACEFUL: { color: 0x90EE90, particle: 'glow', sound: 'zen' },
    HUNGRY: { color: 0xFF6B35, particle: 'droop', sound: 'grumble' },
    THIRSTY: { color: 0x87CEEB, particle: 'droop', sound: 'sigh' },
    SLEEPY: { color: 0xB0C4DE, particle: 'zzz', sound: 'yawn' }
};

// ===== LANGUAGE SYSTEM =====
export const NATURE_LANGUAGE = {
    // Animal sounds
    flutter: { meaning: 'I am dancing!', translation: '*flutter flutter*' },
    chirp: { meaning: 'Hello friend!', translation: '*chirp chirp*' },
    tweet: { meaning: 'Beautiful day!', translation: '*tweet tweet*' },
    song: { meaning: 'I am singing for you!', translation: '♪ ♫ ♪' },
    squeak: { meaning: 'I see you!', translation: '*squeak*' },
    thump: { meaning: 'Danger!', translation: '*thump thump*' },
    bubble: { meaning: 'Swimming is fun!', translation: '*bubble bubble*' },
    yip: { meaning: 'Come play!', translation: '*yip yip*' },
    buzz: { meaning: 'Working hard!', translation: '*bzzzz*' },

    // Plant whispers
    rustle: { meaning: 'The wind speaks to me', translation: '*rustle*' },
    bloom: { meaning: 'I am opening to the world', translation: '*unfurling*' },
    wilt: { meaning: 'I need your love', translation: '*drooping*' },
    grow: { meaning: 'I am reaching for the sun', translation: '*stretching*' }
};

// ===== LIVING ANIMAL CLASS =====
export class LivingAnimal {
    constructor(scene, species, position) {
        this.scene = scene;
        this.species = ANIMAL_SPECIES[species];
        this.speciesName = species;
        this.position = position.clone();
        this.velocity = new THREE.Vector3();
        this.mesh = null;
        this.particles = null;
        this.light = null;

        // Personality & needs
        this.emotion = EMOTIONS.PEACEFUL;
        this.happiness = 0.7;
        this.hunger = 0.3;
        this.thirst = 0.3;
        this.energy = 0.8;
        this.love = 0.5;

        // Behavior
        this.target = null;
        this.path = [];
        this.activity = 'wandering';
        this.phase = Math.random() * Math.PI * 2;
        this.age = 0;

        // Relationships
        this.friends = [];
        this.favoriteSpot = null;

        this.create();
    }

    create() {
        const group = new THREE.Group();

        // Body
        const bodyGeometry = this.species.canFly
            ? new THREE.SphereGeometry(this.species.size, 8, 8)
            : new THREE.CapsuleGeometry(this.species.size * 0.6, this.species.size, 4, 8);

        const bodyMaterial = new THREE.MeshStandardMaterial({
            color: this.species.colors[Math.floor(Math.random() * this.species.colors.length)],
            emissive: this.species.colors[0],
            emissiveIntensity: 0.2,
            roughness: 0.5
        });

        const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
        group.add(body);

        // Wings for flying creatures
        if (this.species.canFly) {
            for (let i = 0; i < 2; i++) {
                const wing = new THREE.Mesh(
                    new THREE.ConeGeometry(this.species.size * 0.8, this.species.size * 0.3, 3),
                    new THREE.MeshStandardMaterial({
                        color: this.species.colors[0],
                        transparent: true,
                        opacity: 0.7
                    })
                );
                wing.rotation.z = Math.PI / 2;
                wing.position.x = i === 0 ? -this.species.size * 0.5 : this.species.size * 0.5;
                wing.userData.wingIndex = i;
                group.add(wing);
            }
        }

        // Emotion glow
        const glowGeometry = new THREE.SphereGeometry(this.species.size * 1.5, 16, 16);
        const glowMaterial = new THREE.MeshBasicMaterial({
            color: this.emotion.color,
            transparent: true,
            opacity: 0.2
        });
        const glow = new THREE.Mesh(glowGeometry, glowMaterial);
        group.add(glow);
        this.glow = glow;

        // Light
        this.light = new THREE.PointLight(this.emotion.color, 0.3, 3);
        group.add(this.light);

        group.position.copy(this.position);
        this.scene.add(group);
        this.mesh = group;
    }

    update(time) {
        if (!this.mesh) return;

        this.age += 0.01;

        // Update needs
        this.hunger = Math.min(1, this.hunger + 0.0001);
        this.thirst = Math.min(1, this.thirst + 0.0001);
        this.energy = Math.max(0, this.energy - 0.00005);

        // Determine emotion
        if (this.love > 0.8) {
            this.emotion = EMOTIONS.LOVED;
            this.happiness = 1.0;
        } else if (this.hunger > 0.7) {
            this.emotion = EMOTIONS.HUNGRY;
        } else if (this.thirst > 0.7) {
            this.emotion = EMOTIONS.THIRSTY;
        } else if (this.energy < 0.3) {
            this.emotion = EMOTIONS.SLEEPY;
        } else if (this.happiness > 0.7) {
            this.emotion = EMOTIONS.JOYFUL;
        } else {
            this.emotion = EMOTIONS.PEACEFUL;
        }

        // Update glow color
        if (this.glow) {
            this.glow.material.color.setHex(this.emotion.color);
        }
        if (this.light) {
            this.light.color.setHex(this.emotion.color);
            this.light.intensity = 0.2 + Math.sin(time + this.phase) * 0.1;
        }

        // Movement behavior
        if (this.species.canFly) {
            // Flying creatures - figure-8 pattern
            this.mesh.position.x += Math.sin(time * 0.5 + this.phase) * this.species.speed;
            this.mesh.position.y += Math.cos(time * 0.3 + this.phase) * this.species.speed * 0.5;
            this.mesh.position.z += Math.sin(time * 0.4 + this.phase) * this.species.speed;

            // Wing flapping
            const wings = this.mesh.children.filter(child => child.userData.wingIndex !== undefined);
            wings.forEach(wing => {
                wing.rotation.y = Math.sin(time * 10) * 0.5;
            });
        } else {
            // Ground creatures - wander
            if (Math.random() < 0.01) {
                this.velocity.x = (Math.random() - 0.5) * this.species.speed;
                this.velocity.z = (Math.random() - 0.5) * this.species.speed;
            }

            this.mesh.position.x += this.velocity.x;
            this.mesh.position.z += this.velocity.z;

            // Bounce
            this.mesh.position.y = this.position.y + Math.abs(Math.sin(time * 5 + this.phase)) * 0.1;
        }

        // Rotate to face movement direction
        if (this.velocity.length() > 0) {
            this.mesh.rotation.y = Math.atan2(this.velocity.x, this.velocity.z);
        }

        // Decay love over time (needs constant affection!)
        this.love = Math.max(0, this.love - 0.0001);
    }

    receiveAction(action, data = {}) {
        switch (action) {
            case 'pet':
                this.love = Math.min(1, this.love + 0.2);
                this.happiness = Math.min(1, this.happiness + 0.1);
                this.speak('purr');
                this.emitParticles('heart');
                break;

            case 'feed':
                this.hunger = Math.max(0, this.hunger - 0.5);
                this.happiness = Math.min(1, this.happiness + 0.15);
                this.speak('happy');
                this.emitParticles('sparkle');
                break;

            case 'water':
                this.thirst = Math.max(0, this.thirst - 0.5);
                this.happiness = Math.min(1, this.happiness + 0.1);
                break;

            case 'play':
                this.energy = Math.max(0, this.energy - 0.1);
                this.happiness = Math.min(1, this.happiness + 0.2);
                this.love = Math.min(1, this.love + 0.1);
                this.emitParticles('bounce');
                this.speak(this.species.sounds[Math.floor(Math.random() * this.species.sounds.length)]);
                break;

            case 'talk':
                this.speak(this.species.sounds[0]);
                return this.getThought();
        }
    }

    speak(sound) {
        const phrase = NATURE_LANGUAGE[sound];
        if (phrase) {
            console.log(`${this.species.emoji} ${this.species.name}: ${phrase.translation} (${phrase.meaning})`);
        }
    }

    getThought() {
        if (this.hunger > 0.7) return `I'm hungry... do you have any ${this.species.loves[0]}?`;
        if (this.thirst > 0.7) return "I'm so thirsty...";
        if (this.love > 0.8) return `I love you so much! You're my favorite! ${this.species.emoji}`;
        if (this.happiness > 0.8) return `I'm so happy! Let's ${this.species.loves[Math.floor(Math.random() * this.species.loves.length)]}!`;
        return `I'm feeling ${Object.keys(EMOTIONS).find(key => EMOTIONS[key] === this.emotion)?.toLowerCase()}...`;
    }

    emitParticles(type) {
        // Create emotion particles
        const particleCount = 10;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3] = this.mesh.position.x + (Math.random() - 0.5) * 0.5;
            positions[i * 3 + 1] = this.mesh.position.y + Math.random() * 0.5;
            positions[i * 3 + 2] = this.mesh.position.z + (Math.random() - 0.5) * 0.5;
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

        const material = new THREE.PointsMaterial({
            color: type === 'heart' ? 0xFF69B4 : 0xFFD700,
            size: 0.1,
            transparent: true
        });

        const particles = new THREE.Points(geometry, material);
        this.scene.add(particles);

        // Animate particles rising
        let opacity = 1;
        const animate = () => {
            opacity -= 0.02;
            material.opacity = opacity;
            const pos = particles.geometry.attributes.position.array;
            for (let i = 0; i < particleCount; i++) {
                pos[i * 3 + 1] += 0.02; // Rise up
            }
            particles.geometry.attributes.position.needsUpdate = true;

            if (opacity > 0) {
                requestAnimationFrame(animate);
            } else {
                this.scene.remove(particles);
            }
        };
        animate();
    }
}

// ===== LIVING PLANT CLASS =====
export class LivingPlant {
    constructor(scene, species, position) {
        this.scene = scene;
        this.species = PLANT_SPECIES[species];
        this.speciesName = species;
        this.position = position.clone();
        this.mesh = null;

        // Growth & health
        this.height = 0.1;
        this.maxHeight = this.species.maxHeight;
        this.health = 0.7;
        this.water = 0.5;
        this.love = 0.3;
        this.age = 0;

        // State
        this.isBloooming = false;
        this.bloomProgress = 0;
        this.emotion = EMOTIONS.PEACEFUL;

        this.create();
    }

    create() {
        const group = new THREE.Group();

        // Stem
        const stemGeometry = new THREE.CylinderGeometry(0.02, 0.03, this.height, 4);
        const stemMaterial = new THREE.MeshStandardMaterial({ color: 0x228B22 });
        const stem = new THREE.Mesh(stemGeometry, stemMaterial);
        stem.position.y = this.height / 2;
        group.add(stem);
        this.stem = stem;

        // Bloom/Leaves
        const bloomGeometry = new THREE.SphereGeometry(this.species.maxHeight * 0.2, 8, 8);
        const bloomMaterial = new THREE.MeshStandardMaterial({
            color: this.species.colors[0],
            emissive: this.species.colors[0],
            emissiveIntensity: 0.1,
            transparent: true,
            opacity: 0.1
        });
        const bloom = new THREE.Mesh(bloomGeometry, bloomMaterial);
        bloom.position.y = this.height;
        group.add(bloom);
        this.bloom = bloom;

        group.position.copy(this.position);
        this.scene.add(group);
        this.mesh = group;
    }

    update(time) {
        if (!this.mesh) return;

        this.age += 0.01;

        // Update needs
        this.water = Math.max(0, this.water - 0.0001);
        this.love = Math.max(0, this.love - 0.00005);

        // Health based on water and love
        this.health = (this.water + this.love) / 2;

        // Grow if healthy
        if (this.health > 0.5 && this.height < this.maxHeight) {
            this.height += 0.001;
            this.stem.scale.y = this.height / this.species.maxHeight;
            this.stem.position.y = this.height / 2;
            this.bloom.position.y = this.height;
        }

        // Bloom when loved
        if (this.love > 0.7 && this.health > 0.6) {
            this.isBloooming = true;
            this.bloomProgress = Math.min(1, this.bloomProgress + 0.01);
        } else {
            this.bloomProgress = Math.max(0, this.bloomProgress - 0.01);
        }

        // Update bloom
        this.bloom.scale.setScalar(0.5 + this.bloomProgress * 0.5);
        this.bloom.material.opacity = 0.3 + this.bloomProgress * 0.7;
        this.bloom.material.emissiveIntensity = this.bloomProgress * 0.5;

        // Gentle sway
        this.mesh.rotation.z = Math.sin(time + this.position.x) * 0.1;

        // Emotion color
        if (this.health < 0.3) {
            this.emotion = EMOTIONS.THIRSTY;
            this.bloom.material.color.setHex(0x8B4513); // Brown
        } else if (this.love > 0.8) {
            this.emotion = EMOTIONS.LOVED;
            this.bloom.material.color.setHex(this.species.colors[0]);
        } else {
            this.emotion = EMOTIONS.PEACEFUL;
        }
    }

    receiveAction(action, data = {}) {
        switch (action) {
            case 'water':
                this.water = Math.min(1, this.water + 0.5);
                this.health = Math.min(1, this.health + 0.2);
                this.speak('grow');
                this.emitParticles('water');
                break;

            case 'love':
            case 'pet':
                this.love = Math.min(1, this.love + 0.3);
                this.health = Math.min(1, this.health + 0.1);
                this.speak('bloom');
                this.emitParticles('sparkle');
                break;

            case 'talk':
                this.speak('rustle');
                return this.getThought();
        }
    }

    speak(sound) {
        const phrase = NATURE_LANGUAGE[sound];
        if (phrase) {
            console.log(`${this.species.emoji} ${this.species.name}: ${phrase.translation} (${phrase.meaning})`);
        }
    }

    getThought() {
        if (this.water < 0.3) return "I'm so thirsty... please water me...";
        if (this.love > 0.8) return `Thank you for your love! I'm blooming for you! ${this.species.emoji}`;
        if (this.isBloooming) return `I'm blooming! Can you see my beautiful ${this.species.produces}?`;
        return `I'm growing towards the ${this.species.loves[0]}...`;
    }

    emitParticles(type) {
        const particleCount = 15;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3] = this.mesh.position.x + (Math.random() - 0.5) * 0.3;
            positions[i * 3 + 1] = this.mesh.position.y + this.height + Math.random() * 0.5;
            positions[i * 3 + 2] = this.mesh.position.z + (Math.random() - 0.5) * 0.3;
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

        const material = new THREE.PointsMaterial({
            color: type === 'water' ? 0x87CEEB : this.species.colors[0],
            size: 0.05,
            transparent: true
        });

        const particles = new THREE.Points(geometry, material);
        this.scene.add(particles);

        let opacity = 1;
        const animate = () => {
            opacity -= 0.02;
            material.opacity = opacity;

            if (opacity > 0) {
                requestAnimationFrame(animate);
            } else {
                this.scene.remove(particles);
            }
        };
        animate();
    }
}

// ===== NATURE MANAGER =====
export class NatureManager {
    constructor(scene) {
        this.scene = scene;
        this.animals = [];
        this.plants = [];
        this.time = 0;
    }

    spawnAnimal(species, position) {
        const animal = new LivingAnimal(this.scene, species, position);
        this.animals.push(animal);
        return animal;
    }

    spawnPlant(species, position) {
        const plant = new LivingPlant(this.scene, species, position);
        this.plants.push(plant);
        return plant;
    }

    // Spawn nature in an area
    populateArea(centerX, centerZ, radius = 25) {
        // Spawn butterflies
        for (let i = 0; i < 5; i++) {
            const pos = new THREE.Vector3(
                centerX + (Math.random() - 0.5) * radius,
                2 + Math.random() * 3,
                centerZ + (Math.random() - 0.5) * radius
            );
            this.spawnAnimal('butterfly', pos);
        }

        // Spawn birds
        for (let i = 0; i < 3; i++) {
            const pos = new THREE.Vector3(
                centerX + (Math.random() - 0.5) * radius,
                5 + Math.random() * 5,
                centerZ + (Math.random() - 0.5) * radius
            );
            this.spawnAnimal('bird', pos);
        }

        // Spawn rabbits
        for (let i = 0; i < 2; i++) {
            const pos = new THREE.Vector3(
                centerX + (Math.random() - 0.5) * radius,
                0,
                centerZ + (Math.random() - 0.5) * radius
            );
            this.spawnAnimal('rabbit', pos);
        }

        // Spawn bees
        for (let i = 0; i < 4; i++) {
            const pos = new THREE.Vector3(
                centerX + (Math.random() - 0.5) * radius,
                1 + Math.random() * 2,
                centerZ + (Math.random() - 0.5) * radius
            );
            this.spawnAnimal('bee', pos);
        }

        // Spawn flowers
        for (let i = 0; i < 15; i++) {
            const pos = new THREE.Vector3(
                centerX + (Math.random() - 0.5) * radius,
                0,
                centerZ + (Math.random() - 0.5) * radius
            );
            const species = ['cherry_blossom', 'sunflower', 'rose'][Math.floor(Math.random() * 3)];
            this.spawnPlant(species, pos);
        }

        // Spawn mushrooms
        for (let i = 0; i < 8; i++) {
            const pos = new THREE.Vector3(
                centerX + (Math.random() - 0.5) * radius,
                0,
                centerZ + (Math.random() - 0.5) * radius
            );
            this.spawnPlant('mushroom', pos);
        }
    }

    update() {
        this.time += 0.016;

        // Update all creatures
        this.animals.forEach(animal => animal.update(this.time));
        this.plants.forEach(plant => plant.update(this.time));
    }

    // Find nearest creature to interact with
    getNearestCreature(position, maxDistance = 3) {
        let nearest = null;
        let minDist = maxDistance;

        [...this.animals, ...this.plants].forEach(creature => {
            const dist = position.distanceTo(creature.mesh.position);
            if (dist < minDist) {
                minDist = dist;
                nearest = creature;
            }
        });

        return nearest;
    }
}

export default NatureManager;
