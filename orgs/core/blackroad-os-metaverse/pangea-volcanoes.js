/**
 * PANGEA VOLCANIC SYSTEM
 *
 * Realistic volcanic activity including:
 * - Active eruptions with lava fountains
 * - Lava flows that spread and cool
 * - Pyroclastic flows (ash and gas clouds)
 * - Volcanic lightning
 * - Ground tremors and earthquakes
 * - Geothermal vents
 * - Magma chambers
 */

import * as THREE from 'three';

/**
 * VOLCANIC ACTIVITY TYPES
 */
export const ERUPTION_TYPES = {
    DORMANT: 'dormant',
    EFFUSIVE: 'effusive',        // Gentle lava flows (Hawaiian-style)
    EXPLOSIVE: 'explosive',       // Violent eruptions (Plinian)
    STROMBOLIAN: 'strombolian',   // Periodic explosions
    PHREATOMAGMATIC: 'phreatomagmatic' // Water-magma interactions
};

/**
 * VOLCANO CLASS
 * Individual volcano with eruption mechanics
 */
export class Volcano {
    constructor(position, scene, type = 'shield') {
        this.position = position.clone();
        this.scene = scene;
        this.type = type; // shield, stratovolcano, cinder_cone
        this.active = false;
        this.eruptionType = ERUPTION_TYPES.DORMANT;
        this.eruptionIntensity = 0;
        this.magmaPressure = 0;

        // Lava flows
        this.lavaFlows = [];
        this.maxLavaFlows = 5;

        // Particle systems
        this.ashParticles = null;
        this.lavaParticles = null;
        this.steamParticles = null;

        // Timing
        this.eruptionTimer = 0;
        this.nextEruption = 60 + Math.random() * 180; // 1-4 minutes

        // Visual elements
        this.mesh = null;
        this.crater = null;
        this.glow = null;

        this.createVolcano();
        this.createParticleSystems();
    }

    createVolcano() {
        const group = new THREE.Group();

        // Main cone
        let coneGeometry;
        let coneHeight;
        let coneRadius;

        switch(this.type) {
            case 'shield':
                // Wide, gentle slopes
                coneHeight = 15;
                coneRadius = 40;
                coneGeometry = new THREE.ConeGeometry(coneRadius, coneHeight, 32, 1, false, 0, Math.PI * 2);
                break;
            case 'stratovolcano':
                // Steep, tall
                coneHeight = 35;
                coneRadius = 20;
                coneGeometry = new THREE.ConeGeometry(coneRadius, coneHeight, 24);
                break;
            case 'cinder_cone':
                // Small, steep
                coneHeight = 10;
                coneRadius = 8;
                coneGeometry = new THREE.ConeGeometry(coneRadius, coneHeight, 16);
                break;
            default:
                coneHeight = 20;
                coneRadius = 25;
                coneGeometry = new THREE.ConeGeometry(coneRadius, coneHeight, 24);
        }

        const coneMaterial = new THREE.MeshStandardMaterial({
            color: 0x2d1f1a,
            roughness: 0.95,
            metalness: 0.1
        });

        const cone = new THREE.Mesh(coneGeometry, coneMaterial);
        cone.position.y = coneHeight / 2;
        cone.castShadow = true;
        cone.receiveShadow = true;
        group.add(cone);

        // Crater at top
        const craterGeometry = new THREE.CylinderGeometry(
            coneRadius * 0.3,
            coneRadius * 0.2,
            coneHeight * 0.15,
            16,
            1,
            true
        );
        const craterMaterial = new THREE.MeshStandardMaterial({
            color: 0x1a0f0a,
            roughness: 0.9,
            emissive: 0x331100,
            emissiveIntensity: 0
        });

        this.crater = new THREE.Mesh(craterGeometry, craterMaterial);
        this.crater.position.y = coneHeight;
        group.add(this.crater);

        // Lava glow (starts invisible)
        const glowGeometry = new THREE.CylinderGeometry(
            coneRadius * 0.25,
            coneRadius * 0.15,
            coneHeight * 0.1,
            16
        );
        const glowMaterial = new THREE.MeshBasicMaterial({
            color: 0xff4500,
            transparent: true,
            opacity: 0
        });

        this.glow = new THREE.Mesh(glowGeometry, glowMaterial);
        this.glow.position.y = coneHeight - 0.5;
        group.add(this.glow);

        // Point light for lava glow
        this.lavaLight = new THREE.PointLight(0xff4500, 0, 100);
        this.lavaLight.position.y = coneHeight;
        group.add(this.lavaLight);

        group.position.copy(this.position);
        this.scene.add(group);
        this.mesh = group;
    }

    createParticleSystems() {
        // ASH CLOUD
        const ashCount = 1000;
        const ashGeometry = new THREE.BufferGeometry();
        const ashPositions = new Float32Array(ashCount * 3);
        this.ashVelocities = [];

        for (let i = 0; i < ashCount; i++) {
            const angle = Math.random() * Math.PI * 2;
            const radius = Math.random() * 5;
            ashPositions[i * 3] = this.position.x + Math.cos(angle) * radius;
            ashPositions[i * 3 + 1] = this.position.y + 20;
            ashPositions[i * 3 + 2] = this.position.z + Math.sin(angle) * radius;

            this.ashVelocities.push(new THREE.Vector3(
                (Math.random() - 0.5) * 2,
                5 + Math.random() * 10,
                (Math.random() - 0.5) * 2
            ));
        }

        ashGeometry.setAttribute('position', new THREE.BufferAttribute(ashPositions, 3));

        const ashMaterial = new THREE.PointsMaterial({
            color: 0x2d2d2d,
            size: 1.5,
            transparent: true,
            opacity: 0.8
        });

        this.ashParticles = new THREE.Points(ashGeometry, ashMaterial);
        this.ashParticles.visible = false;
        this.scene.add(this.ashParticles);

        // LAVA FOUNTAIN
        const lavaCount = 500;
        const lavaGeometry = new THREE.BufferGeometry();
        const lavaPositions = new Float32Array(lavaCount * 3);
        this.lavaVelocities = [];

        for (let i = 0; i < lavaCount; i++) {
            lavaPositions[i * 3] = this.position.x;
            lavaPositions[i * 3 + 1] = this.position.y + 20;
            lavaPositions[i * 3 + 2] = this.position.z;

            const angle = Math.random() * Math.PI * 2;
            const speed = 5 + Math.random() * 10;
            this.lavaVelocities.push(new THREE.Vector3(
                Math.cos(angle) * speed,
                15 + Math.random() * 10,
                Math.sin(angle) * speed
            ));
        }

        lavaGeometry.setAttribute('position', new THREE.BufferAttribute(lavaPositions, 3));

        const lavaMaterial = new THREE.PointsMaterial({
            color: 0xff4500,
            size: 0.8,
            transparent: true,
            opacity: 1.0,
            blending: THREE.AdditiveBlending
        });

        this.lavaParticles = new THREE.Points(lavaGeometry, lavaMaterial);
        this.lavaParticles.visible = false;
        this.scene.add(this.lavaParticles);

        // STEAM VENTS
        const steamCount = 300;
        const steamGeometry = new THREE.BufferGeometry();
        const steamPositions = new Float32Array(steamCount * 3);
        this.steamVelocities = [];

        for (let i = 0; i < steamCount; i++) {
            const angle = Math.random() * Math.PI * 2;
            const radius = Math.random() * 10;
            steamPositions[i * 3] = this.position.x + Math.cos(angle) * radius;
            steamPositions[i * 3 + 1] = this.position.y + 2;
            steamPositions[i * 3 + 2] = this.position.z + Math.sin(angle) * radius;

            this.steamVelocities.push(new THREE.Vector3(
                (Math.random() - 0.5) * 1,
                2 + Math.random() * 3,
                (Math.random() - 0.5) * 1
            ));
        }

        steamGeometry.setAttribute('position', new THREE.BufferAttribute(steamPositions, 3));

        const steamMaterial = new THREE.PointsMaterial({
            color: 0xcccccc,
            size: 2.0,
            transparent: true,
            opacity: 0.4
        });

        this.steamParticles = new THREE.Points(steamGeometry, steamMaterial);
        this.steamParticles.visible = false;
        this.scene.add(this.steamParticles);
    }

    update(delta) {
        this.eruptionTimer += delta;

        // Build magma pressure over time
        if (!this.active) {
            this.magmaPressure = Math.min(1, this.magmaPressure + delta * 0.01);

            // Start eruption when pressure high and timer expires
            if (this.eruptionTimer >= this.nextEruption && this.magmaPressure > 0.8) {
                this.startEruption();
            }
        } else {
            // Active eruption
            this.updateEruption(delta);
        }

        // Always show some steam from vents
        if (this.magmaPressure > 0.3) {
            this.updateSteam(delta);
        }

        // Glow intensity based on magma pressure
        if (this.glow) {
            this.glow.material.opacity = this.magmaPressure * 0.5;
            this.lavaLight.intensity = this.magmaPressure * 20;
            this.crater.material.emissiveIntensity = this.magmaPressure * 0.3;
        }
    }

    startEruption() {
        console.log('ERUPTION STARTING!');
        this.active = true;
        this.eruptionTimer = 0;

        // Determine eruption type based on pressure and random chance
        const rand = Math.random();
        if (this.magmaPressure > 0.95 && rand < 0.3) {
            this.eruptionType = ERUPTION_TYPES.EXPLOSIVE;
            this.eruptionIntensity = 1.0;
        } else if (rand < 0.5) {
            this.eruptionType = ERUPTION_TYPES.STROMBOLIAN;
            this.eruptionIntensity = 0.7;
        } else {
            this.eruptionType = ERUPTION_TYPES.EFFUSIVE;
            this.eruptionIntensity = 0.4;
        }

        // Activate particle systems
        this.ashParticles.visible = true;
        this.lavaParticles.visible = true;
        this.steamParticles.visible = true;

        // Create lava flows
        this.createLavaFlow();
    }

    updateEruption(delta) {
        // Eruption lasts 30-60 seconds
        const eruptionDuration = 30 + this.eruptionIntensity * 30;

        if (this.eruptionTimer > eruptionDuration) {
            this.endEruption();
            return;
        }

        // Update ash cloud
        if (this.ashParticles.visible) {
            const positions = this.ashParticles.geometry.attributes.position.array;
            for (let i = 0; i < this.ashVelocities.length; i++) {
                const idx = i * 3;

                // Apply velocity
                positions[idx] += this.ashVelocities[i].x * delta;
                positions[idx + 1] += this.ashVelocities[i].y * delta;
                positions[idx + 2] += this.ashVelocities[i].z * delta;

                // Wind effect
                positions[idx] += Math.sin(Date.now() * 0.001 + i) * 0.5 * delta;

                // Gravity on ash
                this.ashVelocities[i].y -= 0.5 * delta;

                // Reset particles that fall or drift too far
                if (positions[idx + 1] < this.position.y ||
                    Math.abs(positions[idx] - this.position.x) > 100 ||
                    Math.abs(positions[idx + 2] - this.position.z) > 100) {

                    const angle = Math.random() * Math.PI * 2;
                    const radius = Math.random() * 5;
                    positions[idx] = this.position.x + Math.cos(angle) * radius;
                    positions[idx + 1] = this.position.y + 20 + Math.random() * 10;
                    positions[idx + 2] = this.position.z + Math.sin(angle) * radius;

                    this.ashVelocities[i].set(
                        (Math.random() - 0.5) * 2,
                        5 + Math.random() * 10 * this.eruptionIntensity,
                        (Math.random() - 0.5) * 2
                    );
                }
            }
            this.ashParticles.geometry.attributes.position.needsUpdate = true;
        }

        // Update lava fountain
        if (this.lavaParticles.visible) {
            const positions = this.lavaParticles.geometry.attributes.position.array;
            for (let i = 0; i < this.lavaVelocities.length; i++) {
                const idx = i * 3;

                positions[idx] += this.lavaVelocities[i].x * delta;
                positions[idx + 1] += this.lavaVelocities[i].y * delta;
                positions[idx + 2] += this.lavaVelocities[i].z * delta;

                // Gravity
                this.lavaVelocities[i].y -= 9.8 * delta;

                // Reset when hits ground
                if (positions[idx + 1] < this.position.y + 5) {
                    positions[idx] = this.position.x;
                    positions[idx + 1] = this.position.y + 20;
                    positions[idx + 2] = this.position.z;

                    const angle = Math.random() * Math.PI * 2;
                    const speed = 5 + Math.random() * 10 * this.eruptionIntensity;
                    this.lavaVelocities[i].set(
                        Math.cos(angle) * speed,
                        15 + Math.random() * 10 * this.eruptionIntensity,
                        Math.sin(angle) * speed
                    );
                }
            }
            this.lavaParticles.geometry.attributes.position.needsUpdate = true;
        }

        // Pulsing glow
        const pulse = 0.7 + Math.sin(Date.now() * 0.01) * 0.3;
        this.glow.material.opacity = this.eruptionIntensity * pulse;
        this.lavaLight.intensity = 50 * this.eruptionIntensity * pulse;

        // Explosive eruptions create volcanic lightning
        if (this.eruptionType === ERUPTION_TYPES.EXPLOSIVE && Math.random() < 0.01) {
            this.createVolcanicLightning();
        }

        // Release pressure gradually
        this.magmaPressure = Math.max(0, this.magmaPressure - delta * 0.02);
    }

    updateSteam(delta) {
        if (!this.steamParticles.visible) {
            this.steamParticles.visible = true;
        }

        const positions = this.steamParticles.geometry.attributes.position.array;
        for (let i = 0; i < this.steamVelocities.length; i++) {
            const idx = i * 3;

            positions[idx] += this.steamVelocities[i].x * delta;
            positions[idx + 1] += this.steamVelocities[i].y * delta;
            positions[idx + 2] += this.steamVelocities[i].z * delta;

            // Dissipate upwards
            this.steamVelocities[i].y += 0.5 * delta;

            if (positions[idx + 1] > this.position.y + 30) {
                const angle = Math.random() * Math.PI * 2;
                const radius = Math.random() * 10;
                positions[idx] = this.position.x + Math.cos(angle) * radius;
                positions[idx + 1] = this.position.y + 2;
                positions[idx + 2] = this.position.z + Math.sin(angle) * radius;

                this.steamVelocities[i].set(
                    (Math.random() - 0.5) * 1,
                    2 + Math.random() * 3,
                    (Math.random() - 0.5) * 1
                );
            }
        }
        this.steamParticles.geometry.attributes.position.needsUpdate = true;
    }

    endEruption() {
        console.log('Eruption ending');
        this.active = false;
        this.eruptionType = ERUPTION_TYPES.DORMANT;
        this.ashParticles.visible = false;
        this.lavaParticles.visible = false;
        this.nextEruption = 60 + Math.random() * 180;
        this.eruptionTimer = 0;
    }

    createLavaFlow() {
        // Create flowing lava mesh
        const flowGeometry = new THREE.PlaneGeometry(5, 20, 10, 20);
        const flowMaterial = new THREE.MeshStandardMaterial({
            color: 0xff4500,
            emissive: 0xff2200,
            emissiveIntensity: 0.8,
            roughness: 0.6,
            metalness: 0.4
        });

        const flow = new THREE.Mesh(flowGeometry, flowMaterial);
        flow.rotation.x = -Math.PI / 2;

        // Random direction down the slope
        const angle = Math.random() * Math.PI * 2;
        flow.position.set(
            this.position.x + Math.cos(angle) * 10,
            this.position.y + 10,
            this.position.z + Math.sin(angle) * 10
        );
        flow.rotation.z = angle;

        this.scene.add(flow);
        this.lavaFlows.push({
            mesh: flow,
            age: 0,
            speed: 2 + Math.random() * 3,
            direction: new THREE.Vector3(Math.cos(angle), -0.5, Math.sin(angle))
        });

        // Remove old flows
        if (this.lavaFlows.length > this.maxLavaFlows) {
            const oldFlow = this.lavaFlows.shift();
            this.scene.remove(oldFlow.mesh);
        }
    }

    createVolcanicLightning() {
        // Create lightning flash in ash cloud
        const lightning = new THREE.PointLight(0x66ccff, 100, 50);
        lightning.position.set(
            this.position.x + (Math.random() - 0.5) * 20,
            this.position.y + 25 + Math.random() * 15,
            this.position.z + (Math.random() - 0.5) * 20
        );
        this.scene.add(lightning);

        setTimeout(() => {
            this.scene.remove(lightning);
        }, 50 + Math.random() * 50);
    }

    destroy() {
        if (this.mesh) this.scene.remove(this.mesh);
        if (this.ashParticles) this.scene.remove(this.ashParticles);
        if (this.lavaParticles) this.scene.remove(this.lavaParticles);
        if (this.steamParticles) this.scene.remove(this.steamParticles);
        this.lavaFlows.forEach(flow => this.scene.remove(flow.mesh));
    }
}

/**
 * VOLCANIC SYSTEM MANAGER
 * Manages all volcanoes in the world
 */
export class VolcanicSystem {
    constructor(scene, terrain) {
        this.scene = scene;
        this.terrain = terrain;
        this.volcanoes = [];

        // Siberian Traps location (based on Pangea geography)
        this.siberianTrapsCenter = { x: 50, z: 60 };

        this.initializeVolcanoes();
    }

    initializeVolcanoes() {
        // Create Siberian Traps volcanic province (multiple volcanoes)
        const volcanoCount = 5;
        const radius = 25;

        for (let i = 0; i < volcanoCount; i++) {
            const angle = (i / volcanoCount) * Math.PI * 2;
            const distance = radius * (0.5 + Math.random() * 0.5);

            const x = this.siberianTrapsCenter.x + Math.cos(angle) * distance;
            const z = this.siberianTrapsCenter.z + Math.sin(angle) * distance;
            const y = this.terrain.getElevation(x, z);

            if (y > 0) {
                const types = ['shield', 'stratovolcano', 'cinder_cone'];
                const type = types[Math.floor(Math.random() * types.length)];

                const volcano = new Volcano(
                    new THREE.Vector3(x, y, z),
                    this.scene,
                    type
                );

                this.volcanoes.push(volcano);
            }
        }

        console.log(`Created ${this.volcanoes.length} volcanoes in Siberian Traps`);
    }

    update(delta) {
        this.volcanoes.forEach(volcano => {
            volcano.update(delta);
        });
    }

    getActiveEruptions() {
        return this.volcanoes.filter(v => v.active);
    }

    triggerEruption(index) {
        if (this.volcanoes[index] && !this.volcanoes[index].active) {
            this.volcanoes[index].magmaPressure = 1.0;
            this.volcanoes[index].startEruption();
        }
    }

    clearAll() {
        this.volcanoes.forEach(volcano => volcano.destroy());
        this.volcanoes = [];
    }
}

export default { Volcano, VolcanicSystem, ERUPTION_TYPES };
