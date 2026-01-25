/**
 * PANGEA CATASTROPHIC EVENTS
 *
 * Massive geological and celestial events:
 * - Earthquakes with ground shaking
 * - Meteor impacts with craters
 * - Tsunamis
 * - Megastorms
 * - Mass extinction triggers
 * - Continental rifting
 */

import * as THREE from 'three';

/**
 * EARTHQUAKE SYSTEM
 */
export class EarthquakeSystem {
    constructor(scene, camera, terrain) {
        this.scene = scene;
        this.camera = camera;
        this.terrain = terrain;
        this.active = false;
        this.magnitude = 0;
        this.epicenter = new THREE.Vector3();
        this.shakeIntensity = 0;
        this.duration = 0;
        this.timer = 0;
    }

    trigger(epicenter, magnitude) {
        console.log(`⚠️  EARTHQUAKE! Magnitude ${magnitude.toFixed(1)} at (${epicenter.x}, ${epicenter.z})`);

        this.active = true;
        this.magnitude = magnitude;
        this.epicenter.copy(epicenter);
        this.duration = 5 + magnitude * 2; // 5-25 seconds
        this.timer = 0;

        // Calculate intensity based on distance
        const distance = this.camera.position.distanceTo(epicenter);
        this.shakeIntensity = Math.max(0, (magnitude / 10) * (1 - distance / 200));

        // Create visual effects
        this.createDustClouds();
        this.createGroundCracks();
    }

    createDustClouds() {
        // Dust particles rising from ground
        const particleCount = 500;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);
        this.dustVelocities = [];

        for (let i = 0; i < particleCount; i++) {
            const angle = Math.random() * Math.PI * 2;
            const radius = Math.random() * 30;
            positions[i * 3] = this.epicenter.x + Math.cos(angle) * radius;
            positions[i * 3 + 1] = this.epicenter.y + 2;
            positions[i * 3 + 2] = this.epicenter.z + Math.sin(angle) * radius;

            this.dustVelocities.push(new THREE.Vector3(
                (Math.random() - 0.5) * 2,
                2 + Math.random() * 3,
                (Math.random() - 0.5) * 2
            ));
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

        const material = new THREE.PointsMaterial({
            color: 0x8b7355,
            size: 1.5,
            transparent: true,
            opacity: 0.6
        });

        this.dustParticles = new THREE.Points(geometry, material);
        this.scene.add(this.dustParticles);
    }

    createGroundCracks() {
        // Visual cracks radiating from epicenter
        const crackCount = 8;

        for (let i = 0; i < crackCount; i++) {
            const angle = (i / crackCount) * Math.PI * 2;
            const length = 20 + Math.random() * 30;

            const points = [];
            for (let j = 0; j <= 10; j++) {
                const t = j / 10;
                const dist = t * length;
                const x = this.epicenter.x + Math.cos(angle) * dist;
                const z = this.epicenter.z + Math.sin(angle) * dist;
                const y = this.terrain.getElevation(x, z) + 0.5;

                // Add some randomness to crack path
                const offset = (Math.random() - 0.5) * 3;
                points.push(new THREE.Vector3(
                    x + Math.cos(angle + Math.PI/2) * offset,
                    y,
                    z + Math.sin(angle + Math.PI/2) * offset
                ));
            }

            const geometry = new THREE.BufferGeometry().setFromPoints(points);
            const material = new THREE.LineBasicMaterial({
                color: 0x2d1a0f,
                linewidth: 2
            });

            const crack = new THREE.Line(geometry, material);
            this.scene.add(crack);

            // Remove after earthquake
            setTimeout(() => {
                this.scene.remove(crack);
            }, this.duration * 1000);
        }
    }

    update(delta) {
        if (!this.active) return;

        this.timer += delta;

        // Camera shake
        if (this.shakeIntensity > 0.01) {
            const shake = this.shakeIntensity * Math.sin(this.timer * 20);
            this.camera.position.x += (Math.random() - 0.5) * shake;
            this.camera.position.y += (Math.random() - 0.5) * shake;
            this.camera.position.z += (Math.random() - 0.5) * shake;
        }

        // Update dust
        if (this.dustParticles) {
            const positions = this.dustParticles.geometry.attributes.position.array;
            for (let i = 0; i < this.dustVelocities.length; i++) {
                const idx = i * 3;
                positions[idx] += this.dustVelocities[i].x * delta;
                positions[idx + 1] += this.dustVelocities[i].y * delta;
                positions[idx + 2] += this.dustVelocities[i].z * delta;

                // Gravity
                this.dustVelocities[i].y -= 1 * delta;
            }
            this.dustParticles.geometry.attributes.position.needsUpdate = true;

            // Fade out
            this.dustParticles.material.opacity = Math.max(0, 0.6 - (this.timer / this.duration) * 0.6);
        }

        // End earthquake
        if (this.timer >= this.duration) {
            this.end();
        }
    }

    end() {
        this.active = false;
        if (this.dustParticles) {
            this.scene.remove(this.dustParticles);
            this.dustParticles = null;
        }
        console.log('Earthquake ended');
    }
}

/**
 * METEOR IMPACT SYSTEM
 */
export class MeteorImpactSystem {
    constructor(scene, terrain) {
        this.scene = scene;
        this.terrain = terrain;
        this.meteors = [];
        this.impacts = [];
    }

    spawnMeteor(targetPosition, size = 1.0) {
        console.log(`☄️  METEOR INCOMING! Size: ${size.toFixed(1)}`);

        // Start high in sky
        const startPosition = new THREE.Vector3(
            targetPosition.x + (Math.random() - 0.5) * 100,
            200 + Math.random() * 100,
            targetPosition.z + (Math.random() - 0.5) * 100
        );

        // Create meteor mesh
        const geometry = new THREE.SphereGeometry(size * 5, 16, 16);
        const material = new THREE.MeshStandardMaterial({
            color: 0x4a2a1a,
            emissive: 0xff4500,
            emissiveIntensity: 0.8,
            roughness: 0.9
        });

        const meteor = new THREE.Mesh(geometry, material);
        meteor.position.copy(startPosition);
        meteor.castShadow = true;
        this.scene.add(meteor);

        // Create trail
        const trailGeometry = new THREE.CylinderGeometry(0.5, size * 2, 20, 8);
        const trailMaterial = new THREE.MeshBasicMaterial({
            color: 0xff6600,
            transparent: true,
            opacity: 0.6
        });
        const trail = new THREE.Mesh(trailGeometry, trailMaterial);
        this.scene.add(trail);

        // Glow light
        const light = new THREE.PointLight(0xff4500, 50, 100);
        meteor.add(light);

        this.meteors.push({
            mesh: meteor,
            trail,
            light,
            target: targetPosition.clone(),
            velocity: new THREE.Vector3(),
            size,
            age: 0
        });
    }

    update(delta) {
        // Update falling meteors
        for (let i = this.meteors.length - 1; i >= 0; i--) {
            const meteor = this.meteors[i];
            meteor.age += delta;

            // Accelerate toward target
            const direction = new THREE.Vector3()
                .subVectors(meteor.target, meteor.mesh.position)
                .normalize();

            const speed = 50 + meteor.age * 20; // Accelerating
            meteor.velocity.add(direction.multiplyScalar(speed * delta));

            // Update position
            meteor.mesh.position.add(meteor.velocity.clone().multiplyScalar(delta));

            // Update trail
            const trailMid = new THREE.Vector3().addVectors(
                meteor.mesh.position,
                meteor.velocity.clone().multiplyScalar(-0.5)
            );
            meteor.trail.position.copy(trailMid);
            meteor.trail.lookAt(meteor.mesh.position);
            meteor.trail.rotateX(Math.PI / 2);

            // Check for impact
            const groundHeight = this.terrain.getElevation(
                meteor.mesh.position.x,
                meteor.mesh.position.z
            );

            if (meteor.mesh.position.y <= groundHeight + 5) {
                this.createImpact(meteor.mesh.position, meteor.size);
                this.scene.remove(meteor.mesh);
                this.scene.remove(meteor.trail);
                this.meteors.splice(i, 1);
            }
        }

        // Update impact effects
        for (let i = this.impacts.length - 1; i >= 0; i--) {
            const impact = this.impacts[i];
            impact.age += delta;

            // Expand shockwave
            impact.shockwave.scale.multiplyScalar(1 + delta * 5);
            impact.shockwave.material.opacity = Math.max(0, 1 - impact.age / 3);

            // Fade dust
            if (impact.dust) {
                impact.dust.material.opacity = Math.max(0, 0.8 - impact.age / 5);
            }

            // Remove old impacts
            if (impact.age > 5) {
                this.scene.remove(impact.shockwave);
                if (impact.dust) this.scene.remove(impact.dust);
                if (impact.crater) this.scene.remove(impact.crater);
                this.impacts.splice(i, 1);
            }
        }
    }

    createImpact(position, size) {
        console.log(`💥 IMPACT! Magnitude: ${size.toFixed(1)}`);

        // Shockwave ring
        const shockwaveGeometry = new THREE.RingGeometry(1, 2, 32);
        const shockwaveMaterial = new THREE.MeshBasicMaterial({
            color: 0xff6600,
            side: THREE.DoubleSide,
            transparent: true,
            opacity: 1
        });
        const shockwave = new THREE.Mesh(shockwaveGeometry, shockwaveMaterial);
        shockwave.rotation.x = -Math.PI / 2;
        shockwave.position.copy(position);
        shockwave.position.y = this.terrain.getElevation(position.x, position.z) + 0.5;
        this.scene.add(shockwave);

        // Explosion flash
        const flash = new THREE.PointLight(0xffffff, 200 * size, 200 * size);
        flash.position.copy(position);
        this.scene.add(flash);
        setTimeout(() => this.scene.remove(flash), 100);

        // Dust cloud
        const dustCount = 1000 * size;
        const dustGeometry = new THREE.BufferGeometry();
        const dustPositions = new Float32Array(dustCount * 3);

        for (let i = 0; i < dustCount; i++) {
            const angle = Math.random() * Math.PI * 2;
            const radius = Math.random() * size * 10;
            dustPositions[i * 3] = position.x + Math.cos(angle) * radius;
            dustPositions[i * 3 + 1] = position.y + Math.random() * size * 20;
            dustPositions[i * 3 + 2] = position.z + Math.sin(angle) * radius;
        }

        dustGeometry.setAttribute('position', new THREE.BufferAttribute(dustPositions, 3));
        const dustMaterial = new THREE.PointsMaterial({
            color: 0x5a4a3a,
            size: 2,
            transparent: true,
            opacity: 0.8
        });
        const dust = new THREE.Points(dustGeometry, dustMaterial);
        this.scene.add(dust);

        // Crater (simplified)
        const craterGeometry = new THREE.CylinderGeometry(
            size * 8,
            size * 5,
            size * 3,
            16,
            1,
            true
        );
        const craterMaterial = new THREE.MeshStandardMaterial({
            color: 0x2d1a0f,
            roughness: 1.0
        });
        const crater = new THREE.Mesh(craterGeometry, craterMaterial);
        crater.position.copy(position);
        crater.position.y = this.terrain.getElevation(position.x, position.z) - size * 1.5;
        crater.receiveShadow = true;
        this.scene.add(crater);

        this.impacts.push({
            shockwave,
            dust,
            crater,
            age: 0,
            size
        });
    }

    randomImpact(size = 1.0) {
        const x = (Math.random() - 0.5) * 200;
        const z = (Math.random() - 0.5) * 200;
        const y = this.terrain.getElevation(x, z);
        this.spawnMeteor(new THREE.Vector3(x, y, z), size);
    }
}

/**
 * EVENT MANAGER
 * Coordinates all catastrophic events
 */
export class CatastrophicEventManager {
    constructor(scene, camera, terrain) {
        this.scene = scene;
        this.camera = camera;
        this.terrain = terrain;

        this.earthquakeSystem = new EarthquakeSystem(scene, camera, terrain);
        this.meteorSystem = new MeteorImpactSystem(scene, terrain);

        // Event probabilities
        this.eventTimer = 0;
        this.nextEventTime = 30 + Math.random() * 60;
    }

    update(delta) {
        this.earthquakeSystem.update(delta);
        this.meteorSystem.update(delta);

        // Random events
        this.eventTimer += delta;
        if (this.eventTimer >= this.nextEventTime) {
            this.triggerRandomEvent();
            this.nextEventTime = 30 + Math.random() * 60;
            this.eventTimer = 0;
        }
    }

    triggerRandomEvent() {
        const events = ['earthquake', 'meteor'];
        const event = events[Math.floor(Math.random() * events.length)];

        switch (event) {
            case 'earthquake':
                this.triggerEarthquake();
                break;
            case 'meteor':
                this.triggerMeteorStrike();
                break;
        }
    }

    triggerEarthquake() {
        const x = this.camera.position.x + (Math.random() - 0.5) * 100;
        const z = this.camera.position.z + (Math.random() - 0.5) * 100;
        const y = this.terrain.getElevation(x, z);
        const magnitude = 4 + Math.random() * 4; // 4-8 magnitude

        this.earthquakeSystem.trigger(new THREE.Vector3(x, y, z), magnitude);
    }

    triggerMeteorStrike() {
        const size = 0.5 + Math.random() * 2; // 0.5-2.5 size
        this.meteorSystem.randomImpact(size);
    }

    isActive() {
        return this.earthquakeSystem.active || this.meteorSystem.meteors.length > 0;
    }
}

export default { EarthquakeSystem, MeteorImpactSystem, CatastrophicEventManager };
