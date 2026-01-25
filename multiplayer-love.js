/**
 * MULTIPLAYER LOVE SYSTEM
 *
 * See other players, build together, share gardens, give gifts, and create community!
 * Everything is more beautiful when shared with friends.
 *
 * Philosophy: "TOGETHER WE BLOOM. LOVE MULTIPLIES WHEN SHARED."
 */

import * as THREE from 'three';

// ===== PLAYER AVATAR =====
export class PlayerAvatar {
    constructor(scene, playerData) {
        this.scene = scene;
        this.id = playerData.id;
        this.username = playerData.username;
        this.position = new THREE.Vector3(
            playerData.position?.x || 0,
            playerData.position?.y || 1.6,
            playerData.position?.z || 0
        );
        this.rotation = playerData.rotation || 0;
        this.color = playerData.color || 0x4A90E2;
        this.mesh = null;
        this.nameTag = null;
        this.statusEmoji = playerData.statusEmoji || '😊';
        this.currentActivity = playerData.activity || 'exploring';

        this.create();
    }

    create() {
        const group = new THREE.Group();

        // Body (capsule)
        const bodyGeometry = new THREE.CapsuleGeometry(0.3, 1.2, 4, 8);
        const bodyMaterial = new THREE.MeshStandardMaterial({
            color: this.color,
            emissive: this.color,
            emissiveIntensity: 0.2,
            roughness: 0.5
        });
        const body = new THREE.Mesh(bodyGeometry, bodyMaterial);
        body.position.y = 0.8;
        group.add(body);

        // Head (sphere)
        const headGeometry = new THREE.SphereGeometry(0.25, 16, 16);
        const headMaterial = new THREE.MeshStandardMaterial({
            color: 0xFFE4C4, // Skin tone
            roughness: 0.6
        });
        const head = new THREE.Mesh(headGeometry, headMaterial);
        head.position.y = 1.6;
        group.add(head);

        // Glow aura
        const auraGeometry = new THREE.SphereGeometry(0.8, 32, 32);
        const auraMaterial = new THREE.MeshBasicMaterial({
            color: this.color,
            transparent: true,
            opacity: 0.15
        });
        const aura = new THREE.Mesh(auraGeometry, auraMaterial);
        aura.position.y = 1;
        group.add(aura);
        this.aura = aura;

        // Name tag
        this.createNameTag(group);

        group.position.copy(this.position);
        group.rotation.y = this.rotation;

        this.scene.add(group);
        this.mesh = group;
    }

    createNameTag(parent) {
        // Create a simple text sprite (would use Canvas texture in real impl)
        const canvas = document.createElement('canvas');
        canvas.width = 256;
        canvas.height = 64;
        const ctx = canvas.getContext('2d');

        // Background
        ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        ctx.roundRect(0, 0, 256, 64, 10);
        ctx.fill();

        // Text
        ctx.fillStyle = 'white';
        ctx.font = 'bold 24px Inter';
        ctx.textAlign = 'center';
        ctx.fillText(`${this.statusEmoji} ${this.username}`, 128, 40);

        const texture = new THREE.CanvasTexture(canvas);
        const spriteMaterial = new THREE.SpriteMaterial({ map: texture });
        const sprite = new THREE.Sprite(spriteMaterial);
        sprite.position.y = 2.5;
        sprite.scale.set(2, 0.5, 1);

        parent.add(sprite);
        this.nameTag = sprite;
    }

    updatePosition(position, rotation) {
        if (this.mesh) {
            // Smooth interpolation
            this.mesh.position.lerp(
                new THREE.Vector3(position.x, position.y, position.z),
                0.2
            );
            this.mesh.rotation.y = rotation;
        }
        this.position.set(position.x, position.y, position.z);
        this.rotation = rotation;
    }

    setActivity(activity, emoji) {
        this.currentActivity = activity;
        this.statusEmoji = emoji;
        this.updateNameTag();
    }

    updateNameTag() {
        if (!this.nameTag) return;

        const canvas = document.createElement('canvas');
        canvas.width = 256;
        canvas.height = 64;
        const ctx = canvas.getContext('2d');

        ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        ctx.roundRect(0, 0, 256, 64, 10);
        ctx.fill();

        ctx.fillStyle = 'white';
        ctx.font = 'bold 24px Inter';
        ctx.textAlign = 'center';
        ctx.fillText(`${this.statusEmoji} ${this.username}`, 128, 40);

        this.nameTag.material.map.image = canvas;
        this.nameTag.material.map.needsUpdate = true;
    }

    // Pulse aura when receiving love
    receiveLove() {
        if (!this.aura) return;

        // Pulse animation
        let scale = 1;
        const pulse = () => {
            scale += 0.05;
            this.aura.scale.setScalar(scale);

            if (scale < 1.5) {
                requestAnimationFrame(pulse);
            } else {
                // Reset
                this.aura.scale.setScalar(1);
            }
        };
        pulse();

        // Create heart particles
        this.emitHearts();
    }

    emitHearts() {
        const particleCount = 10;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3] = this.position.x + (Math.random() - 0.5);
            positions[i * 3 + 1] = this.position.y + 1 + Math.random();
            positions[i * 3 + 2] = this.position.z + (Math.random() - 0.5);
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));

        const material = new THREE.PointsMaterial({
            color: 0xFF69B4,
            size: 0.2,
            transparent: true
        });

        const particles = new THREE.Points(geometry, material);
        this.scene.add(particles);

        let opacity = 1;
        const animate = () => {
            opacity -= 0.02;
            material.opacity = opacity;

            const pos = particles.geometry.attributes.position.array;
            for (let i = 0; i < particleCount; i++) {
                pos[i * 3 + 1] += 0.03; // Rise
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

    remove() {
        if (this.mesh) {
            this.scene.remove(this.mesh);
        }
    }
}

// ===== COLLABORATIVE BUILDING =====
export class CollaborativeBuilder {
    constructor() {
        this.activeBuilders = new Map(); // userId -> buildAction
        this.sharedProjects = [];
    }

    // Track what someone is building
    startBuilding(userId, buildType, position) {
        this.activeBuilders.set(userId, {
            type: buildType,
            position: position.clone(),
            startTime: Date.now()
        });

        return {
            message: `You started ${buildType}!`,
            canCollaborate: true
        };
    }

    // Join someone's building project
    joinBuilding(userId, targetUserId) {
        const targetBuild = this.activeBuilders.get(targetUserId);
        if (!targetBuild) {
            return { success: false, message: 'Nothing to join!' };
        }

        return {
            success: true,
            message: `Joined building ${targetBuild.type} together!`,
            buildData: targetBuild
        };
    }

    // Complete a collaborative build
    completeBuilding(userIds, buildType, position) {
        const project = {
            id: crypto.randomUUID(),
            type: buildType,
            position: position.clone(),
            builders: [...userIds],
            completedAt: Date.now(),
            love: userIds.length * 10 // More builders = more love!
        };

        this.sharedProjects.push(project);

        // Clear active builds
        userIds.forEach(id => this.activeBuilders.delete(id));

        return {
            success: true,
            message: `Built ${buildType} together! ${project.love} love created! 💚`,
            project
        };
    }
}

// ===== SHARED GARDEN SYSTEM =====
export class CommunityGarden {
    constructor(id, name, center) {
        this.id = id;
        this.name = name;
        this.center = center;
        this.plants = [];
        this.contributors = new Set();
        this.totalLove = 0;
        this.founded = Date.now();
    }

    addPlant(plant, contributorId) {
        this.plants.push({
            plant,
            plantedBy: contributorId,
            plantedAt: Date.now()
        });
        this.contributors.add(contributorId);
    }

    water(contributorId) {
        this.contributors.add(contributorId);
        this.totalLove += 5;

        // Water all plants
        this.plants.forEach(({ plant }) => {
            plant.receiveAction('water');
        });

        return {
            success: true,
            message: `Watered community garden! ${this.contributors.size} gardeners, ${this.plants.length} plants! 💧`
        };
    }

    getStats() {
        return {
            name: this.name,
            totalPlants: this.plants.length,
            gardeners: this.contributors.size,
            totalLove: this.totalLove,
            founded: this.founded,
            bloomingPlants: this.plants.filter(p => p.plant.isBloooming).length
        };
    }
}

// ===== GIFT SYSTEM =====
export class GiftSystem {
    constructor() {
        this.giftHistory = [];
    }

    // Give a gift to another player
    giveGift(fromUserId, toUserId, giftType, giftData) {
        const gift = {
            id: crypto.randomUUID(),
            from: fromUserId,
            to: toUserId,
            type: giftType,
            data: giftData,
            timestamp: Date.now(),
            message: giftData.message || '💚',
            opened: false
        };

        this.giftHistory.push(gift);

        return {
            success: true,
            message: `Gift sent! ${this.getGiftEmoji(giftType)}`,
            gift
        };
    }

    getGiftEmoji(giftType) {
        const emojis = {
            seeds: '🌱',
            love: '💚',
            pet: '🐾',
            flower: '🌸',
            music: '🎵',
            color: '🎨',
            treasure: '💎'
        };
        return emojis[giftType] || '🎁';
    }

    // Open a gift
    openGift(giftId, userId) {
        const gift = this.giftHistory.find(g => g.id === giftId && g.to === userId);
        if (!gift) {
            return { success: false, message: 'Gift not found!' };
        }

        if (gift.opened) {
            return { success: false, message: 'Already opened!' };
        }

        gift.opened = true;
        gift.openedAt = Date.now();

        return {
            success: true,
            message: `Opened gift from ${gift.from}! ${gift.message}`,
            gift
        };
    }

    // Get pending gifts for a user
    getPendingGifts(userId) {
        return this.giftHistory.filter(g => g.to === userId && !g.opened);
    }
}

// ===== WORLD PORTAL SYSTEM =====
export class WorldPortal {
    constructor(scene, position, destination) {
        this.scene = scene;
        this.position = position;
        this.destination = destination; // { worldId, position }
        this.mesh = null;
        this.particles = null;

        this.create();
    }

    create() {
        const group = new THREE.Group();

        // Portal ring
        const ringGeometry = new THREE.TorusGeometry(2, 0.3, 16, 100);
        const ringMaterial = new THREE.MeshStandardMaterial({
            color: 0x9B59B6,
            emissive: 0x9B59B6,
            emissiveIntensity: 0.5,
            metalness: 0.8,
            roughness: 0.2
        });
        const ring = new THREE.Mesh(ringGeometry, ringMaterial);
        group.add(ring);

        // Portal surface (shimmering)
        const surfaceGeometry = new THREE.CircleGeometry(2, 32);
        const surfaceMaterial = new THREE.MeshBasicMaterial({
            color: 0x9B59B6,
            transparent: true,
            opacity: 0.5,
            side: THREE.DoubleSide
        });
        const surface = new THREE.Mesh(surfaceGeometry, surfaceMaterial);
        group.add(surface);

        // Particles swirling
        this.createParticles(group);

        group.position.copy(this.position);
        group.rotation.y = Math.PI / 2;

        this.scene.add(group);
        this.mesh = group;

        // Animate
        this.animate();
    }

    createParticles(parent) {
        const particleCount = 50;
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(particleCount * 3);
        const colors = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            const angle = (i / particleCount) * Math.PI * 2;
            const radius = Math.random() * 1.8;

            positions[i * 3] = Math.cos(angle) * radius;
            positions[i * 3 + 1] = (Math.random() - 0.5) * 0.2;
            positions[i * 3 + 2] = Math.sin(angle) * radius;

            colors[i * 3] = 0.6;
            colors[i * 3 + 1] = 0.35;
            colors[i * 3 + 2] = 0.7;
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

        const material = new THREE.PointsMaterial({
            size: 0.1,
            vertexColors: true,
            transparent: true,
            opacity: 0.8,
            blending: THREE.AdditiveBlending
        });

        this.particles = new THREE.Points(geometry, material);
        parent.add(this.particles);
    }

    animate() {
        const rotate = () => {
            if (!this.mesh) return;

            this.mesh.rotation.z += 0.01;

            if (this.particles) {
                const positions = this.particles.geometry.attributes.position.array;
                for (let i = 0; i < positions.length; i += 3) {
                    const angle = Math.atan2(positions[i + 2], positions[i]);
                    const radius = Math.sqrt(positions[i] ** 2 + positions[i + 2] ** 2);

                    const newAngle = angle + 0.02;
                    positions[i] = Math.cos(newAngle) * radius;
                    positions[i + 2] = Math.sin(newAngle) * radius;
                }
                this.particles.geometry.attributes.position.needsUpdate = true;
            }

            requestAnimationFrame(rotate);
        };
        rotate();
    }

    checkEnter(playerPosition) {
        const distance = playerPosition.distanceTo(this.position);
        return distance < 2;
    }
}

// ===== MULTIPLAYER MANAGER =====
export class MultiplayerManager {
    constructor(scene) {
        this.scene = scene;
        this.players = new Map(); // userId -> PlayerAvatar
        this.localPlayerId = null;
        this.collaborativeBuilder = new CollaborativeBuilder();
        this.communityGardens = [];
        this.giftSystem = new GiftSystem();
        this.portals = [];
        this.websocket = null;
    }

    // Connect to multiplayer server
    connect(serverUrl, userId, username) {
        this.localPlayerId = userId;

        // WebSocket connection (mock for now)
        console.log(`🌐 Connecting to ${serverUrl} as ${username}...`);

        // In real implementation:
        // this.websocket = new WebSocket(serverUrl);
        // this.websocket.onmessage = (event) => this.handleMessage(event);

        return {
            success: true,
            message: `Connected as ${username}! 🌐`
        };
    }

    // Add another player to the world
    addPlayer(playerData) {
        if (this.players.has(playerData.id)) {
            return this.players.get(playerData.id);
        }

        const avatar = new PlayerAvatar(this.scene, playerData);
        this.players.set(playerData.id, avatar);

        console.log(`👋 ${playerData.username} joined!`);

        return avatar;
    }

    // Update player position
    updatePlayer(playerId, position, rotation) {
        const player = this.players.get(playerId);
        if (player) {
            player.updatePosition(position, rotation);
        }
    }

    // Remove player
    removePlayer(playerId) {
        const player = this.players.get(playerId);
        if (player) {
            player.remove();
            this.players.delete(playerId);
            console.log(`👋 ${player.username} left`);
        }
    }

    // Send love to another player
    sendLove(fromUserId, toUserId, amount = 1) {
        const targetPlayer = this.players.get(toUserId);
        if (!targetPlayer) {
            return { success: false, message: 'Player not found!' };
        }

        targetPlayer.receiveLove();

        return {
            success: true,
            message: `Sent ${amount} love to ${targetPlayer.username}! 💚`
        };
    }

    // Create community garden
    createCommunityGarden(name, position, founderId) {
        const garden = new CommunityGarden(
            crypto.randomUUID(),
            name,
            position
        );

        garden.contributors.add(founderId);
        this.communityGardens.push(garden);

        return {
            success: true,
            message: `Created community garden "${name}"! Plant together! 🌱`,
            garden
        };
    }

    // Find nearest community garden
    getNearestCommunityGarden(position, maxDistance = 20) {
        let nearest = null;
        let minDist = maxDistance;

        this.communityGardens.forEach(garden => {
            const dist = position.distanceTo(garden.center);
            if (dist < minDist) {
                minDist = dist;
                nearest = garden;
            }
        });

        return nearest;
    }

    // Create portal to another world
    createPortal(position, destinationWorldId) {
        const portal = new WorldPortal(this.scene, position, {
            worldId: destinationWorldId,
            position: new THREE.Vector3(0, 1.6, 0)
        });

        this.portals.push(portal);

        return {
            success: true,
            message: `Portal created to ${destinationWorldId}! ✨`,
            portal
        };
    }

    // Check if player near any portal
    checkPortals(playerPosition) {
        for (const portal of this.portals) {
            if (portal.checkEnter(playerPosition)) {
                return portal.destination;
            }
        }
        return null;
    }

    // Broadcast position to other players (mock)
    broadcastPosition(position, rotation, activity) {
        // In real implementation, send via WebSocket
        console.log(`📡 Broadcasting position: ${position.x.toFixed(1)}, ${position.y.toFixed(1)}, ${position.z.toFixed(1)}`);
    }
}

export default MultiplayerManager;
