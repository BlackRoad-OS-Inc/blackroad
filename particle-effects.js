/**
 * PARTICLE EFFECTS SYSTEM
 *
 * Beautiful particle effects for the metaverse:
 * - Rain (realistic droplets)
 * - Snow (gentle flakes)
 * - Fireflies (glowing insects)
 * - Cherry blossoms (falling petals)
 * - Stars (twinkling night sky)
 * - Magic sparkles
 * - Portal swirls
 * - Teleport bursts
 */

import * as THREE from 'three';

/**
 * RAIN SYSTEM
 */
export class RainEffect {
    constructor(scene, options = {}) {
        this.scene = scene;
        this.intensity = options.intensity || 1000;
        this.area = options.area || 100;
        this.speed = options.speed || 1.0;
        this.particles = null;
        this.velocities = [];
    }

    create() {
        const geometry = new THREE.BufferGeometry();
        const vertices = [];
        this.velocities = [];

        for (let i = 0; i < this.intensity; i++) {
            const x = (Math.random() - 0.5) * this.area;
            const y = Math.random() * 50 + 20;
            const z = (Math.random() - 0.5) * this.area;
            vertices.push(x, y, z);
            this.velocities.push(0.5 + Math.random() * 0.5); // Random fall speeds
        }

        geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));

        const material = new THREE.PointsMaterial({
            color: 0x8888ff,
            size: 0.2,
            transparent: true,
            opacity: 0.6
        });

        this.particles = new THREE.Points(geometry, material);
        this.scene.add(this.particles);
    }

    update() {
        if (!this.particles) return;

        const positions = this.particles.geometry.attributes.position.array;

        for (let i = 0; i < positions.length; i += 3) {
            // Fall down
            positions[i + 1] -= this.velocities[i / 3] * this.speed;

            // Reset to top when hit ground
            if (positions[i + 1] < 0) {
                positions[i + 1] = 50;
            }
        }

        this.particles.geometry.attributes.position.needsUpdate = true;
    }

    remove() {
        if (this.particles) {
            this.scene.remove(this.particles);
            this.particles = null;
        }
    }
}

/**
 * SNOW SYSTEM
 */
export class SnowEffect {
    constructor(scene, options = {}) {
        this.scene = scene;
        this.intensity = options.intensity || 2000;
        this.area = options.area || 100;
        this.particles = null;
        this.velocities = [];
        this.driftSpeeds = [];
    }

    create() {
        const geometry = new THREE.BufferGeometry();
        const vertices = [];
        this.velocities = [];
        this.driftSpeeds = [];

        for (let i = 0; i < this.intensity; i++) {
            const x = (Math.random() - 0.5) * this.area;
            const y = Math.random() * 50 + 20;
            const z = (Math.random() - 0.5) * this.area;
            vertices.push(x, y, z);
            this.velocities.push(0.1 + Math.random() * 0.2); // Slow fall
            this.driftSpeeds.push((Math.random() - 0.5) * 0.1); // Side drift
        }

        geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));

        const material = new THREE.PointsMaterial({
            color: 0xffffff,
            size: 0.3,
            transparent: true,
            opacity: 0.8,
            map: this.createSnowflakeTexture()
        });

        this.particles = new THREE.Points(geometry, material);
        this.scene.add(this.particles);
    }

    createSnowflakeTexture() {
        const canvas = document.createElement('canvas');
        canvas.width = 64;
        canvas.height = 64;
        const ctx = canvas.getContext('2d');

        const gradient = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
        gradient.addColorStop(0, 'rgba(255, 255, 255, 1)');
        gradient.addColorStop(0.5, 'rgba(255, 255, 255, 0.5)');
        gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');

        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, 64, 64);

        const texture = new THREE.Texture(canvas);
        texture.needsUpdate = true;
        return texture;
    }

    update() {
        if (!this.particles) return;

        const positions = this.particles.geometry.attributes.position.array;
        const time = Date.now() * 0.001;

        for (let i = 0; i < positions.length; i += 3) {
            // Fall down slowly
            positions[i + 1] -= this.velocities[i / 3];

            // Drift side to side
            positions[i] += Math.sin(time + i) * 0.01;
            positions[i + 2] += this.driftSpeeds[i / 3];

            // Reset to top
            if (positions[i + 1] < 0) {
                positions[i + 1] = 50;
                positions[i] = (Math.random() - 0.5) * this.area;
                positions[i + 2] = (Math.random() - 0.5) * this.area;
            }
        }

        this.particles.geometry.attributes.position.needsUpdate = true;
    }

    remove() {
        if (this.particles) {
            this.scene.remove(this.particles);
            this.particles = null;
        }
    }
}

/**
 * FIREFLIES SYSTEM
 */
export class FirefliesEffect {
    constructor(scene, options = {}) {
        this.scene = scene;
        this.count = options.count || 100;
        this.area = options.area || 50;
        this.height = options.height || { min: 1, max: 5 };
        this.particles = null;
        this.lights = [];
        this.phases = [];
    }

    create() {
        const geometry = new THREE.BufferGeometry();
        const vertices = [];
        const colors = [];
        this.phases = [];

        for (let i = 0; i < this.count; i++) {
            const x = (Math.random() - 0.5) * this.area;
            const y = this.height.min + Math.random() * (this.height.max - this.height.min);
            const z = (Math.random() - 0.5) * this.area;
            vertices.push(x, y, z);

            // Yellow-green firefly color
            colors.push(0.8, 1.0, 0.3);

            // Random phase for blinking
            this.phases.push(Math.random() * Math.PI * 2);

            // Add point light for some fireflies
            if (i % 10 === 0) {
                const light = new THREE.PointLight(0xffff00, 0.5, 3);
                light.position.set(x, y, z);
                this.scene.add(light);
                this.lights.push({ light, index: i * 3 });
            }
        }

        geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));

        const material = new THREE.PointsMaterial({
            size: 0.2,
            vertexColors: true,
            transparent: true,
            opacity: 1.0,
            blending: THREE.AdditiveBlending
        });

        this.particles = new THREE.Points(geometry, material);
        this.scene.add(this.particles);
    }

    update() {
        if (!this.particles) return;

        const positions = this.particles.geometry.attributes.position.array;
        const time = Date.now() * 0.001;

        for (let i = 0; i < positions.length; i += 3) {
            const phase = this.phases[i / 3];

            // Gentle floating movement
            positions[i] += Math.sin(time + phase) * 0.01;
            positions[i + 1] += Math.cos(time * 0.5 + phase) * 0.01;
            positions[i + 2] += Math.sin(time * 0.7 + phase) * 0.01;

            // Keep in bounds
            if (Math.abs(positions[i]) > this.area / 2) {
                positions[i] = (Math.random() - 0.5) * this.area;
            }
            if (Math.abs(positions[i + 2]) > this.area / 2) {
                positions[i + 2] = (Math.random() - 0.5) * this.area;
            }
        }

        // Update lights
        for (const { light, index } of this.lights) {
            light.position.set(
                positions[index],
                positions[index + 1],
                positions[index + 2]
            );
            // Blinking effect
            light.intensity = 0.3 + Math.sin(time * 3 + this.phases[index / 3]) * 0.2;
        }

        this.particles.geometry.attributes.position.needsUpdate = true;
    }

    remove() {
        if (this.particles) {
            this.scene.remove(this.particles);
            this.particles = null;
        }
        for (const { light } of this.lights) {
            this.scene.remove(light);
        }
        this.lights = [];
    }
}

/**
 * CHERRY BLOSSOMS SYSTEM
 */
export class CherryBlossomsEffect {
    constructor(scene, options = {}) {
        this.scene = scene;
        this.count = options.count || 500;
        this.area = options.area || 60;
        this.particles = null;
        this.velocities = [];
        this.rotations = [];
    }

    create() {
        const geometry = new THREE.BufferGeometry();
        const vertices = [];
        this.velocities = [];
        this.rotations = [];

        for (let i = 0; i < this.count; i++) {
            const x = (Math.random() - 0.5) * this.area;
            const y = Math.random() * 40 + 10;
            const z = (Math.random() - 0.5) * this.area;
            vertices.push(x, y, z);

            this.velocities.push({
                x: (Math.random() - 0.5) * 0.05,
                y: -0.05 - Math.random() * 0.1,
                z: (Math.random() - 0.5) * 0.05
            });

            this.rotations.push(Math.random() * Math.PI * 2);
        }

        geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));

        const material = new THREE.PointsMaterial({
            color: 0xffb7c5,
            size: 0.4,
            transparent: true,
            opacity: 0.8,
            map: this.createPetalTexture()
        });

        this.particles = new THREE.Points(geometry, material);
        this.scene.add(this.particles);
    }

    createPetalTexture() {
        const canvas = document.createElement('canvas');
        canvas.width = 64;
        canvas.height = 64;
        const ctx = canvas.getContext('2d');

        ctx.fillStyle = '#ffb7c5';
        ctx.beginPath();
        ctx.arc(32, 32, 20, 0, Math.PI * 2);
        ctx.fill();

        const texture = new THREE.Texture(canvas);
        texture.needsUpdate = true;
        return texture;
    }

    update() {
        if (!this.particles) return;

        const positions = this.particles.geometry.attributes.position.array;
        const time = Date.now() * 0.001;

        for (let i = 0; i < positions.length; i += 3) {
            const vel = this.velocities[i / 3];
            const rotation = this.rotations[i / 3];

            // Spiral fall
            positions[i] += vel.x + Math.sin(time + rotation) * 0.02;
            positions[i + 1] += vel.y;
            positions[i + 2] += vel.z + Math.cos(time + rotation) * 0.02;

            // Reset to top
            if (positions[i + 1] < 0) {
                positions[i] = (Math.random() - 0.5) * this.area;
                positions[i + 1] = 50;
                positions[i + 2] = (Math.random() - 0.5) * this.area;
            }
        }

        this.particles.geometry.attributes.position.needsUpdate = true;
    }

    remove() {
        if (this.particles) {
            this.scene.remove(this.particles);
            this.particles = null;
        }
    }
}

/**
 * STARS SYSTEM (Night Sky)
 */
export class StarsEffect {
    constructor(scene, options = {}) {
        this.scene = scene;
        this.count = options.count || 5000;
        this.radius = options.radius || 500;
        this.particles = null;
        this.twinklePhases = [];
    }

    create() {
        const geometry = new THREE.BufferGeometry();
        const vertices = [];
        const colors = [];
        this.twinklePhases = [];

        for (let i = 0; i < this.count; i++) {
            // Sphere distribution
            const theta = Math.random() * Math.PI * 2;
            const phi = Math.acos(2 * Math.random() - 1);
            const r = this.radius;

            const x = r * Math.sin(phi) * Math.cos(theta);
            const y = r * Math.sin(phi) * Math.sin(theta);
            const z = r * Math.cos(phi);

            vertices.push(x, y, z);

            // Star colors (white to blue)
            const colorVariation = 0.7 + Math.random() * 0.3;
            colors.push(colorVariation, colorVariation, 1);

            this.twinklePhases.push(Math.random() * Math.PI * 2);
        }

        geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));

        const material = new THREE.PointsMaterial({
            size: 1.5,
            vertexColors: true,
            transparent: true,
            opacity: 1.0
        });

        this.particles = new THREE.Points(geometry, material);
        this.scene.add(this.particles);
    }

    update() {
        if (!this.particles) return;

        const colors = this.particles.geometry.attributes.color.array;
        const time = Date.now() * 0.0005;

        for (let i = 0; i < colors.length; i += 3) {
            const phase = this.twinklePhases[i / 3];
            const twinkle = 0.7 + Math.sin(time + phase) * 0.3;

            colors[i] *= twinkle;
            colors[i + 1] *= twinkle;
            colors[i + 2] *= twinkle;
        }

        this.particles.geometry.attributes.color.needsUpdate = true;
    }

    remove() {
        if (this.particles) {
            this.scene.remove(this.particles);
            this.particles = null;
        }
    }
}

/**
 * MAGIC SPARKLES
 */
export class MagicSparkles {
    constructor(scene, position, options = {}) {
        this.scene = scene;
        this.position = position;
        this.count = options.count || 50;
        this.lifespan = options.lifespan || 2; // seconds
        this.color = options.color || 0x9B59B6;
        this.particles = null;
        this.velocities = [];
        this.lifetimes = [];
        this.startTime = Date.now();
    }

    create() {
        const geometry = new THREE.BufferGeometry();
        const vertices = [];
        const colors = [];
        this.velocities = [];
        this.lifetimes = [];

        for (let i = 0; i < this.count; i++) {
            vertices.push(
                this.position.x,
                this.position.y,
                this.position.z
            );

            // Random velocity
            this.velocities.push(new THREE.Vector3(
                (Math.random() - 0.5) * 2,
                (Math.random() - 0.5) * 2,
                (Math.random() - 0.5) * 2
            ));

            // Color
            const r = ((this.color >> 16) & 255) / 255;
            const g = ((this.color >> 8) & 255) / 255;
            const b = (this.color & 255) / 255;
            colors.push(r, g, b);

            this.lifetimes.push(Math.random());
        }

        geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));

        const material = new THREE.PointsMaterial({
            size: 0.3,
            vertexColors: true,
            transparent: true,
            opacity: 1.0,
            blending: THREE.AdditiveBlending
        });

        this.particles = new THREE.Points(geometry, material);
        this.scene.add(this.particles);
    }

    update() {
        if (!this.particles) return;

        const age = (Date.now() - this.startTime) / 1000;
        if (age > this.lifespan) {
            this.remove();
            return false;
        }

        const positions = this.particles.geometry.attributes.position.array;

        for (let i = 0; i < positions.length; i += 3) {
            const vel = this.velocities[i / 3];
            positions[i] += vel.x * 0.1;
            positions[i + 1] += vel.y * 0.1;
            positions[i + 2] += vel.z * 0.1;
        }

        this.particles.material.opacity = 1 - (age / this.lifespan);
        this.particles.geometry.attributes.position.needsUpdate = true;

        return true;
    }

    remove() {
        if (this.particles) {
            this.scene.remove(this.particles);
            this.particles = null;
        }
    }
}

/**
 * PARTICLE MANAGER
 * Manages all active particle systems
 */
export class ParticleManager {
    constructor(scene) {
        this.scene = scene;
        this.effects = {
            rain: null,
            snow: null,
            fireflies: null,
            cherryBlossoms: null,
            stars: null
        };
        this.tempEffects = []; // Temporary effects like sparkles
    }

    enableRain(intensity = 1000) {
        this.disableRain();
        this.effects.rain = new RainEffect(this.scene, { intensity });
        this.effects.rain.create();
    }

    disableRain() {
        if (this.effects.rain) {
            this.effects.rain.remove();
            this.effects.rain = null;
        }
    }

    enableSnow(intensity = 2000) {
        this.disableSnow();
        this.effects.snow = new SnowEffect(this.scene, { intensity });
        this.effects.snow.create();
    }

    disableSnow() {
        if (this.effects.snow) {
            this.effects.snow.remove();
            this.effects.snow = null;
        }
    }

    enableFireflies(count = 100) {
        this.disableFireflies();
        this.effects.fireflies = new FirefliesEffect(this.scene, { count });
        this.effects.fireflies.create();
    }

    disableFireflies() {
        if (this.effects.fireflies) {
            this.effects.fireflies.remove();
            this.effects.fireflies = null;
        }
    }

    enableCherryBlossoms(count = 500) {
        this.disableCherryBlossoms();
        this.effects.cherryBlossoms = new CherryBlossomsEffect(this.scene, { count });
        this.effects.cherryBlossoms.create();
    }

    disableCherryBlossoms() {
        if (this.effects.cherryBlossoms) {
            this.effects.cherryBlossoms.remove();
            this.effects.cherryBlossoms = null;
        }
    }

    enableStars(count = 5000) {
        this.disableStars();
        this.effects.stars = new StarsEffect(this.scene, { count });
        this.effects.stars.create();
    }

    disableStars() {
        if (this.effects.stars) {
            this.effects.stars.remove();
            this.effects.stars = null;
        }
    }

    addMagicSparkles(position, options = {}) {
        const sparkles = new MagicSparkles(this.scene, position, options);
        sparkles.create();
        this.tempEffects.push(sparkles);
    }

    update() {
        // Update persistent effects
        if (this.effects.rain) this.effects.rain.update();
        if (this.effects.snow) this.effects.snow.update();
        if (this.effects.fireflies) this.effects.fireflies.update();
        if (this.effects.cherryBlossoms) this.effects.cherryBlossoms.update();
        if (this.effects.stars) this.effects.stars.update();

        // Update temporary effects
        this.tempEffects = this.tempEffects.filter(effect => effect.update());
    }

    removeAll() {
        this.disableRain();
        this.disableSnow();
        this.disableFireflies();
        this.disableCherryBlossoms();
        this.disableStars();

        this.tempEffects.forEach(effect => effect.remove());
        this.tempEffects = [];
    }
}

export default ParticleManager;
