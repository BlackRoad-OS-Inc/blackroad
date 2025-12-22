/**
 * TRANSPORTATION SYSTEMS
 *
 * Multiple ways to explore the infinite metaverse:
 * - Teleportation (instant travel)
 * - Flying (freedom mode)
 * - Portals (dimensional gates)
 * - Vehicles (hover cars, ships)
 * - Fast travel network
 */

export class TransportationSystem {
    constructor(scene, camera, controls) {
        this.scene = scene;
        this.camera = camera;
        this.controls = controls;
        this.portals = [];
        this.isFlying = false;
        this.flySpeed = 0.5;
        this.teleportCooldown = 0;
    }

    /**
     * TELEPORTATION
     * Instant travel anywhere
     */
    teleport(x, y, z, showEffect = true) {
        if (this.teleportCooldown > 0) return false;

        // Teleport effect
        if (showEffect) {
            this.createTeleportEffect(
                this.camera.position.clone(),
                new THREE.Vector3(x, y, z)
            );
        }

        // Move camera
        this.camera.position.set(x, y, z);

        // Cooldown
        this.teleportCooldown = 2000; // 2 seconds
        setTimeout(() => this.teleportCooldown = 0, 2000);

        return true;
    }

    /**
     * Create teleport visual effect
     */
    createTeleportEffect(from, to) {
        // Particle burst at origin
        const particles = new THREE.Group();
        for (let i = 0; i < 50; i++) {
            const particle = new THREE.Mesh(
                new THREE.SphereGeometry(0.05, 8, 8),
                new THREE.MeshBasicMaterial({
                    color: 0x9B59B6,
                    transparent: true,
                    opacity: 1
                })
            );
            particle.position.copy(from);
            particle.velocity = new THREE.Vector3(
                (Math.random() - 0.5) * 2,
                (Math.random() - 0.5) * 2,
                (Math.random() - 0.5) * 2
            );
            particles.add(particle);
        }
        this.scene.add(particles);

        // Animate particles
        let time = 0;
        const animate = () => {
            time += 0.016;
            particles.children.forEach(p => {
                p.position.add(p.velocity.clone().multiplyScalar(0.1));
                p.material.opacity = 1 - (time / 2);
            });

            if (time < 2) {
                requestAnimationFrame(animate);
            } else {
                this.scene.remove(particles);
            }
        };
        animate();
    }

    /**
     * FLYING MODE
     * Toggle creative-mode flying
     */
    toggleFlying() {
        this.isFlying = !this.isFlying;
        return this.isFlying;
    }

    /**
     * Update flying (call each frame)
     */
    updateFlying(keys) {
        if (!this.isFlying) return;

        const speed = this.flySpeed;

        if (keys.space) {
            this.camera.position.y += speed;
        }
        if (keys.shift) {
            this.camera.position.y -= speed;
        }
    }

    /**
     * CREATE PORTAL
     * Dimensional gate to another location
     */
    createPortal(position, destination, color = 0x9B59B6) {
        const portal = {
            id: crypto.randomUUID(),
            position: position.clone(),
            destination: destination.clone(),
            color: color,
            mesh: null
        };

        // Create portal visual
        const portalGeometry = new THREE.TorusGeometry(2, 0.3, 16, 100);
        const portalMaterial = new THREE.MeshBasicMaterial({
            color: color,
            transparent: true,
            opacity: 0.6
        });
        const portalMesh = new THREE.Mesh(portalGeometry, portalMaterial);
        portalMesh.position.copy(position);
        portalMesh.rotation.y = Math.PI / 2;

        // Add swirling effect
        const innerGeometry = new THREE.CircleGeometry(2, 32);
        const innerMaterial = new THREE.MeshBasicMaterial({
            color: color,
            transparent: true,
            opacity: 0.3,
            side: THREE.DoubleSide
        });
        const innerMesh = new THREE.Mesh(innerGeometry, innerMaterial);
        innerMesh.rotation.y = Math.PI / 2;
        portalMesh.add(innerMesh);

        this.scene.add(portalMesh);
        portal.mesh = portalMesh;

        // Animate portal
        const animate = () => {
            portalMesh.rotation.z += 0.02;
            innerMesh.rotation.z -= 0.03;
            requestAnimationFrame(animate);
        };
        animate();

        this.portals.push(portal);
        return portal;
    }

    /**
     * Check if near portal and auto-teleport
     */
    checkPortals() {
        const playerPos = this.camera.position;

        for (const portal of this.portals) {
            const distance = playerPos.distanceTo(portal.position);
            if (distance < 3) {
                // Enter portal!
                this.teleport(
                    portal.destination.x,
                    portal.destination.y,
                    portal.destination.z
                );
                return true;
            }
        }
        return false;
    }

    /**
     * FAST TRAVEL NETWORK
     * Pre-defined waypoints
     */
    createFastTravelNetwork() {
        const waypoints = [
            { name: 'Spawn', position: new THREE.Vector3(0, 1.6, 0) },
            { name: 'Alice\'s Library', position: new THREE.Vector3(-50, 10, 0) },
            { name: 'Aria\'s Studio', position: new THREE.Vector3(100, 5, 100) },
            { name: 'Lucidia\'s Observatory', position: new THREE.Vector3(-100, 50, -100) },
            { name: 'Crystal Forest', position: new THREE.Vector3(200, 1.6, 200) },
            { name: 'Ocean Paradise', position: new THREE.Vector3(-200, 1.6, 300) },
            { name: 'Mountain Peak', position: new THREE.Vector3(0, 100, -500) }
        ];

        return waypoints;
    }

    /**
     * HOVER VEHICLE
     * Create rideable hover platform
     */
    createHoverVehicle(position) {
        const vehicle = new THREE.Group();

        // Platform
        const platform = new THREE.Mesh(
            new THREE.CylinderGeometry(2, 2, 0.3, 32),
            new THREE.MeshStandardMaterial({
                color: 0x4A90E2,
                metalness: 0.8,
                roughness: 0.2,
                emissive: 0x4A90E2,
                emissiveIntensity: 0.3
            })
        );
        vehicle.add(platform);

        // Glow rings
        for (let i = 0; i < 3; i++) {
            const ring = new THREE.Mesh(
                new THREE.TorusGeometry(2 + i * 0.5, 0.1, 16, 100),
                new THREE.MeshBasicMaterial({
                    color: 0x4A90E2,
                    transparent: true,
                    opacity: 0.5 - i * 0.15
                })
            );
            ring.position.y = -0.3 - i * 0.2;
            vehicle.add(ring);
        }

        vehicle.position.copy(position);
        this.scene.add(vehicle);

        // Hover animation
        let hoverTime = 0;
        const animate = () => {
            hoverTime += 0.05;
            vehicle.position.y = position.y + Math.sin(hoverTime) * 0.3;
            vehicle.rotation.y += 0.01;
            requestAnimationFrame(animate);
        };
        animate();

        return vehicle;
    }
}

export default TransportationSystem;
