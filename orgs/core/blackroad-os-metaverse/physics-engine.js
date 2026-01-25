/**
 * ENVIRONMENTAL PHYSICS ENGINE
 *
 * Realistic physics simulation with wind, gravity, water, temperature,
 * and environmental forces that affect all objects in the metaverse.
 *
 * Philosophy: "THE UNIVERSE FOLLOWS NATURAL LAWS, BUT MAGIC EXISTS IN THE DETAILS"
 */

import * as THREE from 'three';

// ===== PHYSICS CONSTANTS =====
export const PHYSICS_CONSTANTS = {
    GRAVITY: -9.81,
    AIR_DENSITY: 1.225,
    WATER_DENSITY: 1000,
    TERMINAL_VELOCITY: 53,
    FRICTION: {
        GRASS: 0.8,
        SAND: 0.6,
        WATER: 0.95,
        ICE: 0.05,
        STONE: 0.7
    }
};

// ===== PHYSICAL OBJECT CLASS =====
export class PhysicalObject {
    constructor(mesh, properties = {}) {
        this.mesh = mesh;

        // Physical properties
        this.mass = properties.mass || 1.0;
        this.density = properties.density || 1.0;
        this.drag = properties.drag || 0.1;
        this.elasticity = properties.elasticity || 0.5; // Bounciness
        this.friction = properties.friction || 0.7;
        this.isStatic = properties.isStatic || false;

        // State
        this.velocity = new THREE.Vector3(0, 0, 0);
        this.acceleration = new THREE.Vector3(0, 0, 0);
        this.angularVelocity = new THREE.Vector3(0, 0, 0);
        this.forces = [];

        // Collision
        this.radius = properties.radius || 0.5;
        this.grounded = false;
        this.submerged = false;
        this.submersionDepth = 0;

        // Temperature affects
        this.temperature = 20; // Celsius
        this.canFreeze = properties.canFreeze || false;
        this.canBurn = properties.canBurn || false;
    }

    applyForce(force) {
        if (this.isStatic) return;
        this.forces.push(force.clone());
    }

    applyImpulse(impulse) {
        if (this.isStatic) return;
        this.velocity.add(impulse.clone().divideScalar(this.mass));
    }

    update(deltaTime) {
        if (this.isStatic) return;

        // Sum all forces
        const totalForce = new THREE.Vector3(0, 0, 0);
        this.forces.forEach(force => totalForce.add(force));
        this.forces = [];

        // Calculate acceleration (F = ma)
        this.acceleration.copy(totalForce.divideScalar(this.mass));

        // Update velocity
        this.velocity.add(this.acceleration.clone().multiplyScalar(deltaTime));

        // Air resistance / drag
        const dragForce = this.velocity.clone()
            .multiplyScalar(-this.drag * this.velocity.length());
        this.velocity.add(dragForce.multiplyScalar(deltaTime));

        // Update position
        const deltaPosition = this.velocity.clone().multiplyScalar(deltaTime);
        this.mesh.position.add(deltaPosition);

        // Update rotation
        this.mesh.rotation.x += this.angularVelocity.x * deltaTime;
        this.mesh.rotation.y += this.angularVelocity.y * deltaTime;
        this.mesh.rotation.z += this.angularVelocity.z * deltaTime;

        // Reset acceleration
        this.acceleration.set(0, 0, 0);
    }

    checkGroundCollision(groundHeight = 0) {
        const objectBottom = this.mesh.position.y - this.radius;

        if (objectBottom <= groundHeight) {
            this.mesh.position.y = groundHeight + this.radius;

            if (this.velocity.y < 0) {
                // Bounce
                this.velocity.y *= -this.elasticity;

                // Stop bouncing if velocity is very small
                if (Math.abs(this.velocity.y) < 0.1) {
                    this.velocity.y = 0;
                    this.grounded = true;
                }
            }

            // Apply friction
            this.velocity.x *= this.friction;
            this.velocity.z *= this.friction;
        } else {
            this.grounded = false;
        }
    }

    checkWaterSubmersion(waterLevel = 0) {
        const objectBottom = this.mesh.position.y - this.radius;
        const objectTop = this.mesh.position.y + this.radius;

        if (objectTop > waterLevel && objectBottom < waterLevel) {
            // Partially submerged
            this.submerged = true;
            this.submersionDepth = (waterLevel - objectBottom) / (this.radius * 2);

            // Buoyancy force (Archimedes' principle)
            const volume = (4/3) * Math.PI * Math.pow(this.radius, 3) * this.submersionDepth;
            const buoyancyForce = PHYSICS_CONSTANTS.WATER_DENSITY * volume * -PHYSICS_CONSTANTS.GRAVITY;

            this.applyForce(new THREE.Vector3(0, buoyancyForce, 0));

            // Water resistance
            this.velocity.multiplyScalar(0.95);

        } else if (objectTop <= waterLevel) {
            // Fully submerged
            this.submerged = true;
            this.submersionDepth = 1;

            const volume = (4/3) * Math.PI * Math.pow(this.radius, 3);
            const buoyancyForce = PHYSICS_CONSTANTS.WATER_DENSITY * volume * -PHYSICS_CONSTANTS.GRAVITY;

            this.applyForce(new THREE.Vector3(0, buoyancyForce, 0));

            this.velocity.multiplyScalar(0.9);
        } else {
            this.submerged = false;
            this.submersionDepth = 0;
        }
    }
}

// ===== WIND SYSTEM =====
export class WindSystem {
    constructor() {
        this.globalWind = new THREE.Vector3(0, 0, 0);
        this.gusts = [];
        this.turbulence = 0.5;
        this.baseSpeed = 2.0;
        this.time = 0;
    }

    update(deltaTime) {
        this.time += deltaTime;

        // Slowly changing wind direction
        const angle = Math.sin(this.time * 0.1) * Math.PI * 2;
        const speed = this.baseSpeed + Math.sin(this.time * 0.2) * 1.0;

        this.globalWind.set(
            Math.cos(angle) * speed,
            0,
            Math.sin(angle) * speed
        );

        // Update gusts
        this.gusts = this.gusts.filter(gust => {
            gust.lifetime -= deltaTime;
            gust.strength *= 0.99;
            return gust.lifetime > 0;
        });

        // Spawn random gusts
        if (Math.random() < 0.01) {
            this.spawnGust();
        }
    }

    spawnGust() {
        this.gusts.push({
            position: new THREE.Vector3(
                (Math.random() - 0.5) * 100,
                0,
                (Math.random() - 0.5) * 100
            ),
            direction: new THREE.Vector3(
                (Math.random() - 0.5) * 2,
                0,
                (Math.random() - 0.5) * 2
            ).normalize(),
            strength: 5 + Math.random() * 10,
            radius: 10 + Math.random() * 20,
            lifetime: 3 + Math.random() * 5
        });
    }

    getWindAt(position) {
        let wind = this.globalWind.clone();

        // Add turbulence
        wind.x += (Math.random() - 0.5) * this.turbulence;
        wind.z += (Math.random() - 0.5) * this.turbulence;

        // Add gusts
        this.gusts.forEach(gust => {
            const distance = position.distanceTo(gust.position);
            if (distance < gust.radius) {
                const influence = 1 - (distance / gust.radius);
                const gustForce = gust.direction.clone()
                    .multiplyScalar(gust.strength * influence);
                wind.add(gustForce);
            }
        });

        return wind;
    }

    applyWindTo(object, position) {
        const wind = this.getWindAt(position);
        const windForce = wind.clone().multiplyScalar(object.drag);
        object.applyForce(windForce);
    }
}

// ===== GRAVITY FIELD SYSTEM =====
export class GravityField {
    constructor() {
        this.globalGravity = new THREE.Vector3(0, PHYSICS_CONSTANTS.GRAVITY, 0);
        this.anomalies = [];
    }

    addAnomaly(position, strength, radius) {
        this.anomalies.push({
            position: position.clone(),
            strength,
            radius
        });
    }

    removeAnomaly(index) {
        this.anomalies.splice(index, 1);
    }

    getGravityAt(position) {
        let gravity = this.globalGravity.clone();

        // Add anomalies (attractors or repellers)
        this.anomalies.forEach(anomaly => {
            const direction = anomaly.position.clone().sub(position);
            const distance = direction.length();

            if (distance < anomaly.radius && distance > 0.1) {
                const influence = 1 - (distance / anomaly.radius);
                const force = direction.normalize()
                    .multiplyScalar(anomaly.strength * influence);
                gravity.add(force);
            }
        });

        return gravity;
    }

    applyGravityTo(object, position) {
        const gravity = this.getGravityAt(position);
        const gravityForce = gravity.clone().multiplyScalar(object.mass);
        object.applyForce(gravityForce);
    }
}

// ===== WATER FLOW SYSTEM =====
export class WaterFlowSystem {
    constructor() {
        this.currents = [];
        this.waterLevel = 0;
        this.waveHeight = 0.5;
        this.waveSpeed = 1.0;
        this.time = 0;
    }

    update(deltaTime) {
        this.time += deltaTime;
    }

    addCurrent(position, direction, strength, radius) {
        this.currents.push({
            position: position.clone(),
            direction: direction.normalize(),
            strength,
            radius
        });
    }

    getWaterLevelAt(x, z) {
        // Wave simulation using sine waves
        const wave1 = Math.sin(x * 0.1 + this.time * this.waveSpeed) * this.waveHeight;
        const wave2 = Math.sin(z * 0.15 - this.time * this.waveSpeed * 0.7) * this.waveHeight * 0.5;

        return this.waterLevel + wave1 + wave2;
    }

    getCurrentAt(position) {
        let current = new THREE.Vector3(0, 0, 0);

        this.currents.forEach(c => {
            const distance = position.distanceTo(c.position);
            if (distance < c.radius) {
                const influence = 1 - (distance / c.radius);
                const force = c.direction.clone()
                    .multiplyScalar(c.strength * influence);
                current.add(force);
            }
        });

        return current;
    }

    applyWaterForceTo(object, position) {
        if (object.submerged) {
            const current = this.getCurrentAt(position);
            object.applyForce(current.multiplyScalar(object.submersionDepth));
        }
    }
}

// ===== TEMPERATURE SYSTEM =====
export class TemperatureSystem {
    constructor() {
        this.ambientTemperature = 20; // Celsius
        this.heatSources = [];
        this.coldSources = [];
    }

    addHeatSource(position, temperature, radius) {
        this.heatSources.push({ position: position.clone(), temperature, radius });
    }

    addColdSource(position, temperature, radius) {
        this.coldSources.push({ position: position.clone(), temperature, radius });
    }

    getTemperatureAt(position) {
        let temp = this.ambientTemperature;

        // Heat sources
        this.heatSources.forEach(source => {
            const distance = position.distanceTo(source.position);
            if (distance < source.radius) {
                const influence = 1 - (distance / source.radius);
                temp += (source.temperature - this.ambientTemperature) * influence;
            }
        });

        // Cold sources
        this.coldSources.forEach(source => {
            const distance = position.distanceTo(source.position);
            if (distance < source.radius) {
                const influence = 1 - (distance / source.radius);
                temp -= (this.ambientTemperature - source.temperature) * influence;
            }
        });

        return temp;
    }

    updateObjectTemperature(object, position, deltaTime) {
        const envTemp = this.getTemperatureAt(position);
        const tempDiff = envTemp - object.temperature;

        // Thermal equilibrium approach
        object.temperature += tempDiff * 0.1 * deltaTime;

        // Handle phase changes
        if (object.canFreeze && object.temperature < 0) {
            object.frozen = true;
            object.friction *= 0.1; // Ice is slippery
        } else if (object.frozen && object.temperature > 0) {
            object.frozen = false;
        }

        if (object.canBurn && object.temperature > 200) {
            object.burning = true;
        }
    }
}

// ===== COLLISION DETECTION =====
export class CollisionSystem {
    constructor() {
        this.objects = [];
    }

    addObject(object) {
        this.objects.push(object);
    }

    removeObject(object) {
        const index = this.objects.indexOf(object);
        if (index > -1) {
            this.objects.splice(index, 1);
        }
    }

    checkCollisions() {
        for (let i = 0; i < this.objects.length; i++) {
            for (let j = i + 1; j < this.objects.length; j++) {
                this.checkCollision(this.objects[i], this.objects[j]);
            }
        }
    }

    checkCollision(obj1, obj2) {
        const distance = obj1.mesh.position.distanceTo(obj2.mesh.position);
        const minDistance = obj1.radius + obj2.radius;

        if (distance < minDistance) {
            this.resolveCollision(obj1, obj2, distance, minDistance);
        }
    }

    resolveCollision(obj1, obj2, distance, minDistance) {
        // Separate objects
        const direction = obj2.mesh.position.clone()
            .sub(obj1.mesh.position)
            .normalize();

        const overlap = minDistance - distance;
        const separation = direction.clone().multiplyScalar(overlap / 2);

        if (!obj1.isStatic) obj1.mesh.position.sub(separation);
        if (!obj2.isStatic) obj2.mesh.position.add(separation);

        // Calculate collision response
        const relativeVelocity = obj2.velocity.clone().sub(obj1.velocity);
        const velocityAlongNormal = relativeVelocity.dot(direction);

        if (velocityAlongNormal < 0) {
            // Objects are moving towards each other
            const e = Math.min(obj1.elasticity, obj2.elasticity);
            const impulse = -(1 + e) * velocityAlongNormal / (1/obj1.mass + 1/obj2.mass);

            const impulseVector = direction.clone().multiplyScalar(impulse);

            if (!obj1.isStatic) {
                obj1.velocity.sub(impulseVector.clone().divideScalar(obj1.mass));
            }
            if (!obj2.isStatic) {
                obj2.velocity.add(impulseVector.clone().divideScalar(obj2.mass));
            }
        }
    }
}

// ===== MAIN PHYSICS ENGINE =====
export class PhysicsEngine {
    constructor(scene) {
        this.scene = scene;
        this.objects = [];
        this.wind = new WindSystem();
        this.gravity = new GravityField();
        this.water = new WaterFlowSystem();
        this.temperature = new TemperatureSystem();
        this.collision = new CollisionSystem();
        this.enabled = true;
    }

    addObject(mesh, properties) {
        const physObject = new PhysicalObject(mesh, properties);
        this.objects.push(physObject);
        this.collision.addObject(physObject);
        return physObject;
    }

    removeObject(physObject) {
        const index = this.objects.indexOf(physObject);
        if (index > -1) {
            this.objects.splice(index, 1);
            this.collision.removeObject(physObject);
        }
    }

    update(deltaTime) {
        if (!this.enabled) return;

        // Clamp deltaTime to prevent physics explosions
        deltaTime = Math.min(deltaTime, 0.033);

        // Update environmental systems
        this.wind.update(deltaTime);
        this.water.update(deltaTime);

        // Update all physical objects
        this.objects.forEach(obj => {
            const position = obj.mesh.position;

            // Apply environmental forces
            this.gravity.applyGravityTo(obj, position);
            this.wind.applyWindTo(obj, position);
            this.water.applyWaterForceTo(obj, position);

            // Update temperature
            this.temperature.updateObjectTemperature(obj, position, deltaTime);

            // Update physics
            obj.update(deltaTime);

            // Check ground collision
            obj.checkGroundCollision(0);

            // Check water submersion
            const waterLevel = this.water.getWaterLevelAt(position.x, position.z);
            obj.checkWaterSubmersion(waterLevel);
        });

        // Check collisions
        this.collision.checkCollisions();
    }

    // Utility functions
    createFallingObject(position, mesh, mass = 1.0) {
        const obj = this.addObject(mesh, {
            mass,
            elasticity: 0.6,
            friction: 0.8
        });
        mesh.position.copy(position);
        return obj;
    }

    createFloatingObject(position, mesh) {
        const obj = this.addObject(mesh, {
            mass: 0.5,
            density: 0.3, // Less dense than water
            elasticity: 0.4
        });
        mesh.position.copy(position);
        return obj;
    }

    createProjectile(position, velocity, mesh, mass = 0.5) {
        const obj = this.addObject(mesh, {
            mass,
            drag: 0.05,
            elasticity: 0.3
        });
        mesh.position.copy(position);
        obj.velocity.copy(velocity);
        return obj;
    }

    // Effects
    createExplosion(position, force, radius) {
        this.objects.forEach(obj => {
            const distance = obj.mesh.position.distanceTo(position);
            if (distance < radius) {
                const direction = obj.mesh.position.clone().sub(position).normalize();
                const strength = force * (1 - distance / radius);
                const impulse = direction.multiplyScalar(strength);
                obj.applyImpulse(impulse);
            }
        });
    }

    createWind(position, direction, strength, radius, duration) {
        // Temporary wind gust
        this.wind.gusts.push({
            position: position.clone(),
            direction: direction.normalize(),
            strength,
            radius,
            lifetime: duration
        });
    }

    setWaterLevel(level) {
        this.water.waterLevel = level;
    }

    getStats() {
        return {
            objects: this.objects.length,
            windSpeed: this.wind.globalWind.length().toFixed(2),
            gusts: this.wind.gusts.length,
            gravityAnomalies: this.gravity.anomalies.length,
            waterCurrent: this.water.currents.length,
            heatSources: this.temperature.heatSources.length
        };
    }
}

export default PhysicsEngine;
