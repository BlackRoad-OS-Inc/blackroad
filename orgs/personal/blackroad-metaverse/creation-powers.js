/**
 * CREATION POWERS SYSTEM
 *
 * Plant gardens, adopt pets, paint the sky, sculpt terrain, and build!
 * You have the power to create, grow, and shape the world with love.
 *
 * Philosophy: "YOU ARE A CREATOR. EVERYTHING YOU TOUCH CAN BLOOM."
 */

import * as THREE from 'three';

// ===== GARDEN SYSTEM =====
export class GardenBuilder {
    constructor(scene, natureManager) {
        this.scene = scene;
        this.natureManager = natureManager;
        this.gardens = [];
        this.inventory = {
            seeds: {
                cherry_blossom: 10,
                sunflower: 10,
                rose: 10,
                lotus: 5,
                mushroom: 8,
                vine: 5
            },
            water: 100,
            love: Infinity // Love is infinite!
        };
    }

    // Plant a seed at a location
    plantSeed(species, position) {
        if (!this.inventory.seeds[species] || this.inventory.seeds[species] <= 0) {
            return { success: false, message: `No ${species} seeds left! Find more seeds in the world.` };
        }

        // Plant it!
        const plant = this.natureManager.spawnPlant(species, position);

        // Use seed
        this.inventory.seeds[species]--;

        // Create planting particles
        this.createPlantingEffect(position);

        // Add to garden
        const garden = this.findOrCreateGarden(position);
        garden.plants.push(plant);

        return {
            success: true,
            message: `Planted a ${species}! 🌱 Water it with love and watch it grow!`,
            plant
        };
    }

    // Find or create a garden area
    findOrCreateGarden(position) {
        const radius = 10;

        // Find existing garden nearby
        for (const garden of this.gardens) {
            const dist = position.distanceTo(garden.center);
            if (dist < radius) {
                return garden;
            }
        }

        // Create new garden
        const garden = {
            id: crypto.randomUUID(),
            name: `Garden ${this.gardens.length + 1}`,
            center: position.clone(),
            plants: [],
            createdAt: Date.now()
        };

        this.gardens.push(garden);

        // Create garden marker
        this.createGardenMarker(garden);

        return garden;
    }

    // Visual marker for gardens
    createGardenMarker(garden) {
        const markerGeometry = new THREE.RingGeometry(8, 10, 32);
        const markerMaterial = new THREE.MeshBasicMaterial({
            color: 0x90EE90,
            transparent: true,
            opacity: 0.3,
            side: THREE.DoubleSide
        });

        const marker = new THREE.Mesh(markerGeometry, markerMaterial);
        marker.rotation.x = -Math.PI / 2;
        marker.position.copy(garden.center);
        marker.position.y = 0.1;

        this.scene.add(marker);
        garden.marker = marker;
    }

    // Planting effect particles
    createPlantingEffect(position) {
        const particleCount = 20;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);
        const colors = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3] = position.x + (Math.random() - 0.5);
            positions[i * 3 + 1] = position.y + Math.random() * 0.5;
            positions[i * 3 + 2] = position.z + (Math.random() - 0.5);

            // Green sparkles
            colors[i * 3] = 0.5;
            colors[i * 3 + 1] = 1.0;
            colors[i * 3 + 2] = 0.5;
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

        const material = new THREE.PointsMaterial({
            size: 0.15,
            vertexColors: true,
            transparent: true
        });

        const particles = new THREE.Points(geometry, material);
        this.scene.add(particles);

        // Animate
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

    // Water all plants in a garden
    waterGarden(garden) {
        if (this.inventory.water < 10) {
            return { success: false, message: 'Not enough water! Find a water source.' };
        }

        garden.plants.forEach(plant => {
            plant.receiveAction('water');
        });

        this.inventory.water -= 10;

        return {
            success: true,
            message: `Watered ${garden.plants.length} plants in ${garden.name}! 💧`
        };
    }

    // Get garden stats
    getGardenStats(garden) {
        const totalPlants = garden.plants.length;
        const bloomingPlants = garden.plants.filter(p => p.isBloooming).length;
        const avgHealth = garden.plants.reduce((sum, p) => sum + p.health, 0) / totalPlants;

        return {
            name: garden.name,
            totalPlants,
            bloomingPlants,
            avgHealth,
            beauty: bloomingPlants / totalPlants
        };
    }
}

// ===== PET COMPANION SYSTEM =====
export class PetCompanion {
    constructor(animal, owner) {
        this.animal = animal;
        this.owner = owner;
        this.name = null;
        this.bond = 0.5; // 0-1
        this.memory = [];
        this.personality = {
            loyalty: 0.7 + Math.random() * 0.3,
            playfulness: 0.5 + Math.random() * 0.5,
            courage: 0.3 + Math.random() * 0.7,
            independence: Math.random()
        };
    }

    setName(name) {
        this.name = name;
        this.bond += 0.1;
        this.remember(`My name is ${name}!`);
    }

    remember(event) {
        this.memory.push({
            event,
            timestamp: Date.now(),
            emotion: this.animal.emotion
        });

        // Keep last 50 memories
        if (this.memory.length > 50) {
            this.memory.shift();
        }
    }

    // Pet learns from interactions
    interact(action) {
        const result = this.animal.receiveAction(action);

        // Increase bond
        if (action === 'pet' || action === 'play') {
            this.bond = Math.min(1, this.bond + 0.05);
        }

        // Remember happy moments
        if (this.animal.happiness > 0.7) {
            this.remember(`${this.owner} made me so happy!`);
        }

        return result;
    }

    // Pet follows owner
    follow(ownerPosition) {
        if (this.bond < 0.3) return; // Won't follow if bond is too low

        const distance = this.animal.mesh.position.distanceTo(ownerPosition);

        // Follow if too far
        if (distance > 5 && distance < 50) {
            const direction = new THREE.Vector3()
                .subVectors(ownerPosition, this.animal.mesh.position)
                .normalize();

            // Adjust for personality (independent pets follow less closely)
            const followSpeed = this.animal.species.speed * this.personality.loyalty * (1 - this.personality.independence * 0.5);

            this.animal.velocity.copy(direction.multiplyScalar(followSpeed));
        }
    }

    // Get a message from pet
    speak() {
        const messages = [
            `I love you! My bond with you is ${Math.floor(this.bond * 100)}%! 💚`,
            `Let's play together! I'm feeling ${Object.keys(EMOTIONS).find(k => EMOTIONS[k] === this.animal.emotion)?.toLowerCase()}!`,
            `I remember when ${this.memory.length > 0 ? this.memory[this.memory.length - 1].event : 'we first met'}!`,
            `You're my favorite person in the whole metaverse!`
        ];

        if (this.name) {
            return `${this.name} (${this.animal.species.emoji}): "${messages[Math.floor(Math.random() * messages.length)]}"`;
        } else {
            return `${this.animal.species.emoji}: "Will you give me a name?"`;
        }
    }
}

// ===== TERRAIN SCULPTOR =====
export class TerrainSculptor {
    constructor(scene) {
        this.scene = scene;
        this.brush = {
            size: 5,
            strength: 0.5,
            mode: 'raise' // 'raise', 'lower', 'smooth', 'paint'
        };
    }

    // Sculpt terrain at position
    sculpt(position, chunks) {
        const chunkSize = 50;
        const chunkX = Math.floor(position.x / chunkSize);
        const chunkZ = Math.floor(position.z / chunkSize);
        const chunkKey = `${chunkX},${chunkZ}`;

        const chunk = chunks.get(chunkKey);
        if (!chunk) return;

        // Find terrain mesh in chunk
        const terrain = chunk.children.find(child =>
            child.geometry && child.geometry.type === 'PlaneGeometry'
        );

        if (!terrain) return;

        const vertices = terrain.geometry.attributes.position.array;

        // Modify vertices within brush radius
        for (let i = 0; i < vertices.length; i += 3) {
            const vx = vertices[i] + terrain.position.x;
            const vz = vertices[i + 1] + terrain.position.z;
            const vy = vertices[i + 2];

            const dist = Math.sqrt(
                Math.pow(vx - position.x, 2) +
                Math.pow(vz - position.z, 2)
            );

            if (dist < this.brush.size) {
                const influence = (1 - dist / this.brush.size) * this.brush.strength;

                switch (this.brush.mode) {
                    case 'raise':
                        vertices[i + 2] += influence;
                        break;
                    case 'lower':
                        vertices[i + 2] -= influence;
                        break;
                    case 'smooth':
                        // Average with neighbors
                        vertices[i + 2] = vy * (1 - influence) + vy * influence;
                        break;
                }
            }
        }

        terrain.geometry.attributes.position.needsUpdate = true;
        terrain.geometry.computeVertexNormals();

        // Create sculpting particles
        this.createSculptEffect(position);
    }

    createSculptEffect(position) {
        const particleCount = 15;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3] = position.x + (Math.random() - 0.5) * this.brush.size;
            positions[i * 3 + 1] = position.y + Math.random() * 0.5;
            positions[i * 3 + 2] = position.z + (Math.random() - 0.5) * this.brush.size;
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

        const material = new THREE.PointsMaterial({
            color: 0x8B7355,
            size: 0.1,
            transparent: true
        });

        const particles = new THREE.Points(geometry, material);
        this.scene.add(particles);

        setTimeout(() => this.scene.remove(particles), 1000);
    }

    setBrushSize(size) {
        this.brush.size = Math.max(1, Math.min(20, size));
    }

    setBrushStrength(strength) {
        this.brush.strength = Math.max(0.1, Math.min(2, strength));
    }

    setBrushMode(mode) {
        this.brush.mode = mode;
    }
}

// ===== SKY PAINTER =====
export class SkyPainter {
    constructor(scene) {
        this.scene = scene;
        this.currentColor = new THREE.Color(0x87CEEB);
    }

    // Paint the sky a new color
    paintSky(color) {
        this.currentColor.setHex(color);
        this.scene.background = this.currentColor;
        this.scene.fog.color = this.currentColor;

        // Create painting effect
        this.createPaintEffect();
    }

    // Gradient sky
    paintGradient(color1, color2) {
        // Would need shader for true gradient
        // For now, blend colors
        const blended = new THREE.Color(color1).lerp(new THREE.Color(color2), 0.5);
        this.paintSky(blended.getHex());
    }

    // Sunrise/sunset colors
    paintSunrise() {
        this.paintGradient(0xFF6B35, 0xFFD700);
    }

    paintSunset() {
        this.paintGradient(0xFF6B35, 0x9B59B6);
    }

    paintNight() {
        this.paintSky(0x000033);
    }

    paintDay() {
        this.paintSky(0x87CEEB);
    }

    createPaintEffect() {
        // Create color wave particles
        console.log(`🎨 Sky painted ${this.currentColor.getHexString()}!`);
    }
}

// ===== CREATION MANAGER =====
export class CreationManager {
    constructor(scene, natureManager) {
        this.scene = scene;
        this.garden = new GardenBuilder(scene, natureManager);
        this.sculptor = new TerrainSculptor(scene);
        this.skyPainter = new SkyPainter(scene);
        this.pets = [];
    }

    // Adopt an animal as a pet
    adoptPet(animal, ownerName) {
        const pet = new PetCompanion(animal, ownerName);
        this.pets.push(pet);
        return pet;
    }

    // Get nearest pet
    getNearestPet(position, maxDistance = 5) {
        let nearest = null;
        let minDist = maxDistance;

        this.pets.forEach(pet => {
            const dist = position.distanceTo(pet.animal.mesh.position);
            if (dist < minDist) {
                minDist = dist;
                nearest = pet;
            }
        });

        return nearest;
    }

    // Update all pets (call each frame)
    updatePets(ownerPosition) {
        this.pets.forEach(pet => {
            pet.follow(ownerPosition);
        });
    }
}

export default CreationManager;
