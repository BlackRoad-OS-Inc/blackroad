/**
 * GAME INTEGRATION SYSTEM
 *
 * Brings all metaverse systems together into a cohesive, playable experience.
 * Handles initialization, game loop, UI, controls, and system coordination.
 *
 * Philosophy: "EVERYTHING WORKS TOGETHER IN HARMONY"
 */

import * as THREE from 'three';
import { BiomeGenerator } from './infinite-biomes.js';
import { LivingNature, EMOTIONS } from './living-nature.js';
import { MusicEngine, NatureSoundscape } from './living-music.js';
import { CreationManager } from './creation-powers.js';
import { MultiplayerManager } from './multiplayer-love.js';
import { PhotorealisticRenderer, AdvancedMaterials, AdvancedLighting, CustomShaders } from './photorealistic-graphics.js';
import { ParticleSystem } from './particle-effects.js';
import { TransportationSystem } from './transportation.js';

// ===== GAME STATE MANAGER =====
export class GameState {
    constructor() {
        this.player = {
            id: null,
            username: null,
            position: new THREE.Vector3(0, 5, 0),
            rotation: new THREE.Euler(0, 0, 0),
            velocity: new THREE.Vector3(0, 0, 0),
            isFlying: false,
            currentBiome: 'grassland',
            inventory: {
                seeds: {},
                gifts: {},
                materials: {}
            },
            stats: {
                creaturesLoved: 0,
                plantsGrown: 0,
                giftsGiven: 0,
                distanceTraveled: 0,
                timeInWorld: 0
            }
        };

        this.world = {
            timeOfDay: 0.25, // 0 = midnight, 0.5 = noon
            weather: 'clear', // 'clear', 'rain', 'snow'
            season: 'spring',
            temperature: 20,
            windSpeed: 0.5
        };

        this.settings = {
            graphics: 'ultra', // 'low', 'medium', 'high', 'ultra'
            musicVolume: 0.7,
            soundVolume: 0.8,
            uiScale: 1.0,
            showFPS: false,
            renderDistance: 500
        };

        this.paused = false;
        this.startTime = Date.now();
    }

    updateTime(deltaTime) {
        if (this.paused) return;

        // Increment time of day (24-hour cycle over 24 real minutes)
        this.world.timeOfDay += deltaTime / (24 * 60);
        if (this.world.timeOfDay >= 1) {
            this.world.timeOfDay -= 1;
        }

        // Update stats
        this.player.stats.timeInWorld += deltaTime;
    }

    getCurrentHour() {
        return Math.floor(this.world.timeOfDay * 24);
    }

    getTimeString() {
        const hour = this.getCurrentHour();
        const minute = Math.floor((this.world.timeOfDay * 24 * 60) % 60);
        const ampm = hour >= 12 ? 'PM' : 'AM';
        const displayHour = hour % 12 || 12;
        return `${displayHour}:${minute.toString().padStart(2, '0')} ${ampm}`;
    }

    save() {
        const saveData = {
            player: this.player,
            world: this.world,
            settings: this.settings,
            timestamp: Date.now()
        };
        localStorage.setItem('blackroad_save', JSON.stringify(saveData));
        return saveData;
    }

    load() {
        const saved = localStorage.getItem('blackroad_save');
        if (saved) {
            const data = JSON.parse(saved);
            this.player = { ...this.player, ...data.player };
            this.world = { ...this.world, ...data.world };
            this.settings = { ...this.settings, ...data.settings };
            return true;
        }
        return false;
    }
}

// ===== UI SYSTEM =====
export class UIManager {
    constructor(gameState) {
        this.gameState = gameState;
        this.elements = {};
        this.notifications = [];
        this.createUI();
    }

    createUI() {
        // HUD Container
        const hud = document.createElement('div');
        hud.id = 'game-hud';
        hud.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            font-family: 'Inter', -apple-system, sans-serif;
            color: white;
            z-index: 1000;
        `;
        document.body.appendChild(hud);

        // Top Bar
        this.createTopBar(hud);

        // Bottom Controls
        this.createBottomControls(hud);

        // Notification Area
        this.createNotificationArea(hud);

        // Interaction Prompt
        this.createInteractionPrompt(hud);

        // Stats Panel
        this.createStatsPanel(hud);

        // Inventory Panel
        this.createInventoryPanel(hud);
    }

    createTopBar(parent) {
        const topBar = document.createElement('div');
        topBar.style.cssText = `
            position: absolute;
            top: 20px;
            left: 50%;
            transform: translateX(-50%);
            padding: 12px 24px;
            background: rgba(0, 0, 0, 0.6);
            backdrop-filter: blur(10px);
            border-radius: 12px;
            display: flex;
            gap: 24px;
            align-items: center;
            pointer-events: all;
        `;

        // Time Display
        const timeDisplay = document.createElement('div');
        timeDisplay.id = 'time-display';
        timeDisplay.innerHTML = `⏰ <span id="time-text">12:00 PM</span>`;
        topBar.appendChild(timeDisplay);

        // Weather Display
        const weatherDisplay = document.createElement('div');
        weatherDisplay.id = 'weather-display';
        weatherDisplay.innerHTML = `☀️ <span id="weather-text">Clear</span>`;
        topBar.appendChild(weatherDisplay);

        // Biome Display
        const biomeDisplay = document.createElement('div');
        biomeDisplay.id = 'biome-display';
        biomeDisplay.innerHTML = `🌍 <span id="biome-text">Grassland</span>`;
        topBar.appendChild(biomeDisplay);

        parent.appendChild(topBar);

        this.elements.timeText = document.getElementById('time-text');
        this.elements.weatherText = document.getElementById('weather-text');
        this.elements.biomeText = document.getElementById('biome-text');
    }

    createBottomControls(parent) {
        const controls = document.createElement('div');
        controls.style.cssText = `
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            display: flex;
            gap: 12px;
            pointer-events: all;
        `;

        const buttons = [
            { id: 'fly-btn', text: '🕊️ Fly', key: 'F' },
            { id: 'plant-btn', text: '🌱 Plant', key: 'P' },
            { id: 'sculpt-btn', text: '🏔️ Sculpt', key: 'T' },
            { id: 'gift-btn', text: '🎁 Gift', key: 'G' },
            { id: 'stats-btn', text: '📊 Stats', key: 'Tab' }
        ];

        buttons.forEach(btn => {
            const button = document.createElement('button');
            button.id = btn.id;
            button.textContent = btn.text;
            button.style.cssText = `
                padding: 10px 20px;
                background: rgba(255, 255, 255, 0.1);
                backdrop-filter: blur(10px);
                border: 2px solid rgba(255, 255, 255, 0.3);
                border-radius: 8px;
                color: white;
                font-size: 14px;
                cursor: pointer;
                transition: all 0.3s;
            `;
            button.addEventListener('mouseenter', () => {
                button.style.background = 'rgba(255, 255, 255, 0.2)';
                button.style.transform = 'scale(1.05)';
            });
            button.addEventListener('mouseleave', () => {
                button.style.background = 'rgba(255, 255, 255, 0.1)';
                button.style.transform = 'scale(1)';
            });
            controls.appendChild(button);
            this.elements[btn.id] = button;
        });

        parent.appendChild(controls);
    }

    createNotificationArea(parent) {
        const area = document.createElement('div');
        area.id = 'notification-area';
        area.style.cssText = `
            position: absolute;
            top: 100px;
            right: 20px;
            width: 300px;
            display: flex;
            flex-direction: column;
            gap: 10px;
        `;
        parent.appendChild(area);
        this.elements.notificationArea = area;
    }

    createInteractionPrompt(parent) {
        const prompt = document.createElement('div');
        prompt.id = 'interaction-prompt';
        prompt.style.cssText = `
            position: absolute;
            bottom: 120px;
            left: 50%;
            transform: translateX(-50%);
            padding: 12px 24px;
            background: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(10px);
            border-radius: 8px;
            font-size: 16px;
            display: none;
            pointer-events: none;
        `;
        parent.appendChild(prompt);
        this.elements.interactionPrompt = prompt;
    }

    createStatsPanel(parent) {
        const panel = document.createElement('div');
        panel.id = 'stats-panel';
        panel.style.cssText = `
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 500px;
            max-height: 600px;
            background: rgba(0, 0, 0, 0.9);
            backdrop-filter: blur(20px);
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 16px;
            padding: 24px;
            display: none;
            overflow-y: auto;
            pointer-events: all;
        `;

        panel.innerHTML = `
            <h2 style="margin-top: 0; text-align: center;">📊 Your Journey</h2>
            <div id="stats-content">
                <div class="stat-row">
                    <span>💚 Creatures Loved:</span>
                    <span id="stat-creatures">0</span>
                </div>
                <div class="stat-row">
                    <span>🌱 Plants Grown:</span>
                    <span id="stat-plants">0</span>
                </div>
                <div class="stat-row">
                    <span>🎁 Gifts Given:</span>
                    <span id="stat-gifts">0</span>
                </div>
                <div class="stat-row">
                    <span>🚶 Distance Traveled:</span>
                    <span id="stat-distance">0 km</span>
                </div>
                <div class="stat-row">
                    <span>⏰ Time in World:</span>
                    <span id="stat-time">0 min</span>
                </div>
            </div>
            <button id="close-stats" style="
                width: 100%;
                padding: 12px;
                margin-top: 20px;
                background: rgba(255, 255, 255, 0.1);
                border: 2px solid rgba(255, 255, 255, 0.3);
                border-radius: 8px;
                color: white;
                cursor: pointer;
            ">Close</button>
        `;

        parent.appendChild(panel);
        this.elements.statsPanel = panel;

        document.getElementById('close-stats').addEventListener('click', () => {
            panel.style.display = 'none';
        });
    }

    createInventoryPanel(parent) {
        const panel = document.createElement('div');
        panel.id = 'inventory-panel';
        panel.style.cssText = `
            position: absolute;
            top: 100px;
            left: 20px;
            width: 300px;
            background: rgba(0, 0, 0, 0.8);
            backdrop-filter: blur(10px);
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 12px;
            padding: 16px;
            display: none;
            pointer-events: all;
        `;

        panel.innerHTML = `
            <h3 style="margin-top: 0;">🎒 Inventory</h3>
            <div id="inventory-content"></div>
        `;

        parent.appendChild(panel);
        this.elements.inventoryPanel = panel;
    }

    showNotification(message, type = 'info', duration = 3000) {
        const notification = document.createElement('div');
        notification.style.cssText = `
            padding: 12px 20px;
            background: ${type === 'success' ? 'rgba(0, 255, 0, 0.2)' :
                          type === 'error' ? 'rgba(255, 0, 0, 0.2)' :
                          'rgba(255, 255, 255, 0.2)'};
            backdrop-filter: blur(10px);
            border: 2px solid ${type === 'success' ? 'rgba(0, 255, 0, 0.5)' :
                                type === 'error' ? 'rgba(255, 0, 0, 0.5)' :
                                'rgba(255, 255, 255, 0.5)'};
            border-radius: 8px;
            animation: slideIn 0.3s ease-out;
        `;
        notification.textContent = message;

        this.elements.notificationArea.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease-out';
            setTimeout(() => notification.remove(), 300);
        }, duration);
    }

    showInteractionPrompt(text) {
        this.elements.interactionPrompt.textContent = text;
        this.elements.interactionPrompt.style.display = 'block';
    }

    hideInteractionPrompt() {
        this.elements.interactionPrompt.style.display = 'none';
    }

    toggleStatsPanel() {
        const panel = this.elements.statsPanel;
        const isVisible = panel.style.display === 'block';
        panel.style.display = isVisible ? 'none' : 'block';

        if (!isVisible) {
            this.updateStatsPanel();
        }
    }

    updateStatsPanel() {
        const stats = this.gameState.player.stats;
        document.getElementById('stat-creatures').textContent = stats.creaturesLoved;
        document.getElementById('stat-plants').textContent = stats.plantsGrown;
        document.getElementById('stat-gifts').textContent = stats.giftsGiven;
        document.getElementById('stat-distance').textContent = (stats.distanceTraveled / 1000).toFixed(2) + ' km';
        document.getElementById('stat-time').textContent = (stats.timeInWorld / 60).toFixed(1) + ' min';
    }

    update() {
        // Update top bar
        this.elements.timeText.textContent = this.gameState.getTimeString();
        this.elements.weatherText.textContent = this.gameState.world.weather.charAt(0).toUpperCase() + this.gameState.world.weather.slice(1);
        this.elements.biomeText.textContent = this.gameState.player.currentBiome.charAt(0).toUpperCase() + this.gameState.player.currentBiome.slice(1);
    }
}

// ===== INPUT MANAGER =====
export class InputManager {
    constructor() {
        this.keys = {};
        this.mouse = {
            x: 0,
            y: 0,
            leftButton: false,
            rightButton: false,
            wheelDelta: 0
        };
        this.locked = false;

        this.setupEventListeners();
    }

    setupEventListeners() {
        // Keyboard
        document.addEventListener('keydown', (e) => {
            this.keys[e.code] = true;
        });

        document.addEventListener('keyup', (e) => {
            this.keys[e.code] = false;
        });

        // Mouse
        document.addEventListener('mousemove', (e) => {
            this.mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
            this.mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;

            if (this.locked) {
                this.mouse.movementX = e.movementX || 0;
                this.mouse.movementY = e.movementY || 0;
            }
        });

        document.addEventListener('mousedown', (e) => {
            if (e.button === 0) this.mouse.leftButton = true;
            if (e.button === 2) this.mouse.rightButton = true;
        });

        document.addEventListener('mouseup', (e) => {
            if (e.button === 0) this.mouse.leftButton = false;
            if (e.button === 2) this.mouse.rightButton = false;
        });

        document.addEventListener('wheel', (e) => {
            this.mouse.wheelDelta = e.deltaY;
        });

        // Pointer lock
        document.addEventListener('click', () => {
            if (!this.locked) {
                document.body.requestPointerLock();
            }
        });

        document.addEventListener('pointerlockchange', () => {
            this.locked = document.pointerLockElement === document.body;
        });
    }

    isKeyPressed(keyCode) {
        return this.keys[keyCode] || false;
    }

    resetFrame() {
        this.mouse.movementX = 0;
        this.mouse.movementY = 0;
        this.mouse.wheelDelta = 0;
    }
}

// ===== CAMERA CONTROLLER =====
export class CameraController {
    constructor(camera, gameState) {
        this.camera = camera;
        this.gameState = gameState;
        this.sensitivity = 0.002;
        this.distance = 5;
        this.height = 2;
        this.pitch = 0;
        this.yaw = 0;
    }

    update(input) {
        if (!input.locked) return;

        // Mouse look
        this.yaw -= input.mouse.movementX * this.sensitivity;
        this.pitch -= input.mouse.movementY * this.sensitivity;
        this.pitch = Math.max(-Math.PI / 2.5, Math.min(Math.PI / 2.5, this.pitch));

        // Camera position (third person)
        const playerPos = this.gameState.player.position;
        const offset = new THREE.Vector3(
            Math.sin(this.yaw) * Math.cos(this.pitch) * this.distance,
            this.height + Math.sin(this.pitch) * this.distance,
            Math.cos(this.yaw) * Math.cos(this.pitch) * this.distance
        );

        this.camera.position.copy(playerPos).add(offset);
        this.camera.lookAt(playerPos);
    }

    getForwardDirection() {
        return new THREE.Vector3(
            -Math.sin(this.yaw),
            0,
            -Math.cos(this.yaw)
        ).normalize();
    }

    getRightDirection() {
        return new THREE.Vector3(
            Math.cos(this.yaw),
            0,
            -Math.sin(this.yaw)
        ).normalize();
    }
}

// ===== MAIN GAME MANAGER =====
export class BlackRoadGame {
    constructor(containerId = 'game-container') {
        this.container = document.getElementById(containerId);
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.id = containerId;
            document.body.appendChild(this.container);
        }

        // Core systems
        this.gameState = new GameState();
        this.input = new InputManager();

        // Three.js setup
        this.scene = new THREE.Scene();
        this.camera = new THREE.PerspectiveCamera(
            75,
            window.innerWidth / window.innerHeight,
            0.1,
            2000
        );

        // Use photorealistic renderer
        this.renderer = new PhotorealisticRenderer(this.container, this.scene, this.camera);

        // Game systems
        this.cameraController = new CameraController(this.camera, this.gameState);
        this.biomeGenerator = new BiomeGenerator(this.scene);
        this.nature = new LivingNature(this.scene);
        this.music = new MusicEngine();
        this.soundscape = new NatureSoundscape();
        this.creation = new CreationManager(this.scene, this.nature);
        this.multiplayer = new MultiplayerManager(this.scene);
        this.lighting = new AdvancedLighting(this.scene);
        this.particles = new ParticleSystem(this.scene);
        this.ui = new UIManager(this.gameState);

        // Performance tracking
        this.lastTime = performance.now();
        this.deltaTime = 0;

        this.init();
    }

    init() {
        console.log('🌍 Initializing BlackRoad Metaverse...');

        // Setup lighting
        this.lighting.createSun(1.5);
        this.lighting.createHemisphere(0.5);
        this.lighting.createAmbient(0.3);

        // Setup fog
        this.scene.fog = new THREE.FogExp2(0x87CEEB, 0.002);

        // Initial camera position
        this.camera.position.set(0, 10, 10);

        // Generate initial chunks
        this.generateWorldAroundPlayer();

        // Spawn some initial creatures
        this.spawnInitialCreatures();

        // Start music
        this.music.start();
        this.soundscape.start('grassland');

        // Setup event listeners
        this.setupEventListeners();

        // Start game loop
        this.animate();

        console.log('✅ BlackRoad Metaverse ready!');
        this.ui.showNotification('Welcome to BlackRoad! 💚', 'success', 5000);
    }

    setupEventListeners() {
        window.addEventListener('resize', () => this.onWindowResize());

        // Button listeners
        this.ui.elements['fly-btn'].addEventListener('click', () => this.toggleFly());
        this.ui.elements['stats-btn'].addEventListener('click', () => this.ui.toggleStatsPanel());
    }

    onWindowResize() {
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(window.innerWidth, window.innerHeight);
    }

    generateWorldAroundPlayer() {
        const chunkSize = 50;
        const renderDistance = 3;
        const playerChunkX = Math.floor(this.gameState.player.position.x / chunkSize);
        const playerChunkZ = Math.floor(this.gameState.player.position.z / chunkSize);

        for (let x = -renderDistance; x <= renderDistance; x++) {
            for (let z = -renderDistance; z <= renderDistance; z++) {
                this.biomeGenerator.ensureChunkLoaded(
                    playerChunkX + x,
                    playerChunkZ + z
                );
            }
        }
    }

    spawnInitialCreatures() {
        const creatures = ['butterfly', 'bird', 'rabbit', 'fish', 'fox', 'bee'];
        const radius = 20;

        creatures.forEach((species, i) => {
            const angle = (i / creatures.length) * Math.PI * 2;
            const position = new THREE.Vector3(
                Math.cos(angle) * radius,
                5,
                Math.sin(angle) * radius
            );
            this.nature.spawnAnimal(species, position);
        });
    }

    toggleFly() {
        this.gameState.player.isFlying = !this.gameState.player.isFlying;
        this.ui.showNotification(
            this.gameState.player.isFlying ? '🕊️ Flying enabled!' : '🚶 Walking mode',
            'success'
        );
    }

    handlePlayerMovement() {
        const speed = this.gameState.player.isFlying ? 0.5 : 0.3;
        const forward = this.cameraController.getForwardDirection();
        const right = this.cameraController.getRightDirection();

        const velocity = new THREE.Vector3(0, 0, 0);

        if (this.input.isKeyPressed('KeyW')) {
            velocity.add(forward.clone().multiplyScalar(speed));
        }
        if (this.input.isKeyPressed('KeyS')) {
            velocity.add(forward.clone().multiplyScalar(-speed));
        }
        if (this.input.isKeyPressed('KeyA')) {
            velocity.add(right.clone().multiplyScalar(-speed));
        }
        if (this.input.isKeyPressed('KeyD')) {
            velocity.add(right.clone().multiplyScalar(speed));
        }

        if (this.gameState.player.isFlying) {
            if (this.input.isKeyPressed('Space')) {
                velocity.y = speed;
            }
            if (this.input.isKeyPressed('ShiftLeft')) {
                velocity.y = -speed;
            }
        }

        // Apply velocity
        this.gameState.player.position.add(velocity);

        // Track distance
        const distance = velocity.length();
        this.gameState.player.stats.distanceTraveled += distance;

        // Keep above ground if not flying
        if (!this.gameState.player.isFlying && this.gameState.player.position.y < 1) {
            this.gameState.player.position.y = 1;
        }
    }

    update(deltaTime) {
        // Update game state
        this.gameState.updateTime(deltaTime);

        // Handle input
        this.handlePlayerMovement();
        this.cameraController.update(this.input);

        // Update world systems
        this.biomeGenerator.update(this.gameState.player.position);
        this.nature.update();
        this.creation.updatePets(this.gameState.player.position);
        this.lighting.updateSunPosition(this.gameState.world.timeOfDay);
        this.particles.update();

        // Update UI
        this.ui.update();

        // Update current biome
        const biome = this.biomeGenerator.getBiomeAt(
            this.gameState.player.position.x,
            this.gameState.player.position.z
        );
        if (biome !== this.gameState.player.currentBiome) {
            this.gameState.player.currentBiome = biome;
            this.soundscape.transitionTo(biome);
            this.ui.showNotification(`Entered ${biome} biome`, 'info');
        }

        // Reset input state
        this.input.resetFrame();
    }

    animate() {
        requestAnimationFrame(() => this.animate());

        const currentTime = performance.now();
        this.deltaTime = (currentTime - this.lastTime) / 1000;
        this.lastTime = currentTime;

        if (!this.gameState.paused) {
            this.update(this.deltaTime);
        }

        this.renderer.render();
    }

    // Public API
    pause() {
        this.gameState.paused = true;
        this.ui.showNotification('Game paused', 'info');
    }

    resume() {
        this.gameState.paused = false;
        this.ui.showNotification('Game resumed', 'info');
    }

    save() {
        const saveData = this.gameState.save();
        this.ui.showNotification('Game saved!', 'success');
        return saveData;
    }

    load() {
        const loaded = this.gameState.load();
        if (loaded) {
            this.ui.showNotification('Game loaded!', 'success');
            // Teleport player to saved position
            this.camera.position.copy(this.gameState.player.position);
        } else {
            this.ui.showNotification('No save file found', 'error');
        }
        return loaded;
    }
}

export default BlackRoadGame;
