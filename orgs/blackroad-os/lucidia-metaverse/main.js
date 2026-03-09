import * as THREE from 'three';
import { PointerLockControls } from 'three/addons/controls/PointerLockControls.js';
import * as CANNON from 'cannon-es';

// ===========================
// LUCIDIA METAVERSE ENGINE
// ===========================

class LucidiaMetaverse {
    constructor() {
        this.scene = new THREE.Scene();
        this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        this.clock = new THREE.Clock();

        // Physics world
        this.world = new CANNON.World();
        this.world.gravity.set(0, -30, 0);

        // Player
        this.player = {
            velocity: new THREE.Vector3(),
            canJump: false,
            height: 1.8,
            speed: 10,
            jumpPower: 15
        };

        // Controls
        this.moveForward = false;
        this.moveBackward = false;
        this.moveLeft = false;
        this.moveRight = false;
        this.canRun = false;

        // Other players
        this.otherPlayers = new Map();

        // FPS counter
        this.frameCount = 0;
        this.lastTime = performance.now();

        this.init();
    }

    init() {
        // Renderer setup
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(window.devicePixelRatio);
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.0;
        document.getElementById('canvas-container').appendChild(this.renderer.domElement);

        // Camera position
        this.camera.position.set(0, this.player.height, 10);

        // Create environment
        this.createSky();
        this.createLighting();
        this.createGround();
        this.createCityscape();
        this.createFloatingIslands();
        this.createPortals();
        this.createParticleEffects();

        // Physics for player
        const playerShape = new CANNON.Sphere(0.5);
        this.playerBody = new CANNON.Body({
            mass: 70,
            shape: playerShape,
            linearDamping: 0.9
        });
        this.playerBody.position.set(0, this.player.height, 10);
        this.world.addBody(this.playerBody);

        // Controls
        this.controls = new PointerLockControls(this.camera, document.body);

        // Event listeners
        this.setupEventListeners();

        // Hide loading screen
        setTimeout(() => {
            document.getElementById('loading').style.display = 'none';
            document.getElementById('controls').style.display = 'block';
            document.getElementById('chat').style.display = 'block';
            document.getElementById('chat-input').style.display = 'block';
            this.addChatMessage('System', 'Welcome to Lucidia Metaverse');
        }, 2000);

        // Start animation loop
        this.animate();
    }

    createSky() {
        // Gradient sky
        const skyGeo = new THREE.SphereGeometry(500, 32, 32);
        const skyMat = new THREE.ShaderMaterial({
            uniforms: {
                topColor: { value: new THREE.Color(0x0077ff) },
                bottomColor: { value: new THREE.Color(0xFF006B) },
                offset: { value: 33 },
                exponent: { value: 0.6 }
            },
            vertexShader: `
                varying vec3 vWorldPosition;
                void main() {
                    vec4 worldPosition = modelMatrix * vec4(position, 1.0);
                    vWorldPosition = worldPosition.xyz;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                }
            `,
            fragmentShader: `
                uniform vec3 topColor;
                uniform vec3 bottomColor;
                uniform float offset;
                uniform float exponent;
                varying vec3 vWorldPosition;
                void main() {
                    float h = normalize(vWorldPosition + offset).y;
                    gl_FragColor = vec4(mix(bottomColor, topColor, max(pow(max(h, 0.0), exponent), 0.0)), 1.0);
                }
            `,
            side: THREE.BackSide
        });

        const sky = new THREE.Mesh(skyGeo, skyMat);
        this.scene.add(sky);

        // Stars
        const starsGeometry = new THREE.BufferGeometry();
        const starsMaterial = new THREE.PointsMaterial({ color: 0xFFFFFF, size: 0.1 });
        const starsVertices = [];

        for (let i = 0; i < 10000; i++) {
            const x = (Math.random() - 0.5) * 1000;
            const y = Math.random() * 500;
            const z = (Math.random() - 0.5) * 1000;
            starsVertices.push(x, y, z);
        }

        starsGeometry.setAttribute('position', new THREE.Float32BufferAttribute(starsVertices, 3));
        const stars = new THREE.Points(starsGeometry, starsMaterial);
        this.scene.add(stars);
    }

    createLighting() {
        // Ambient light
        const ambient = new THREE.AmbientLight(0xffffff, 0.5);
        this.scene.add(ambient);

        // Directional light (sun)
        const sun = new THREE.DirectionalLight(0xFFD700, 1.5);
        sun.position.set(50, 100, 50);
        sun.castShadow = true;
        sun.shadow.camera.left = -50;
        sun.shadow.camera.right = 50;
        sun.shadow.camera.top = 50;
        sun.shadow.camera.bottom = -50;
        sun.shadow.mapSize.width = 2048;
        sun.shadow.mapSize.height = 2048;
        this.scene.add(sun);

        // Point lights for atmosphere
        const colors = [0xFF9D00, 0xFF6B00, 0xFF0066, 0x7700FF, 0x0066FF];
        for (let i = 0; i < 5; i++) {
            const light = new THREE.PointLight(colors[i], 2, 50);
            light.position.set(
                Math.random() * 100 - 50,
                5,
                Math.random() * 100 - 50
            );
            this.scene.add(light);
        }
    }

    createGround() {
        // Main ground
        const groundGeo = new THREE.PlaneGeometry(200, 200, 50, 50);
        const groundMat = new THREE.MeshStandardMaterial({
            color: 0x1a1a2e,
            roughness: 0.8,
            metalness: 0.2,
            wireframe: false
        });

        const ground = new THREE.Mesh(groundGeo, groundMat);
        ground.rotation.x = -Math.PI / 2;
        ground.receiveShadow = true;
        this.scene.add(ground);

        // Physics ground
        const groundShape = new CANNON.Plane();
        const groundBody = new CANNON.Body({ mass: 0 });
        groundBody.addShape(groundShape);
        groundBody.quaternion.setFromAxisAngle(new CANNON.Vec3(1, 0, 0), -Math.PI / 2);
        this.world.addBody(groundBody);

        // Grid overlay
        const gridHelper = new THREE.GridHelper(200, 50, 0xFF9D00, 0xFF006B);
        gridHelper.position.y = 0.01;
        this.scene.add(gridHelper);
    }

    createCityscape() {
        // Create procedural buildings
        for (let i = 0; i < 50; i++) {
            const width = Math.random() * 3 + 2;
            const height = Math.random() * 30 + 10;
            const depth = Math.random() * 3 + 2;

            const buildingGeo = new THREE.BoxGeometry(width, height, depth);
            const buildingMat = new THREE.MeshStandardMaterial({
                color: new THREE.Color().setHSL(Math.random(), 0.5, 0.3),
                emissive: new THREE.Color().setHSL(Math.random(), 1, 0.2),
                emissiveIntensity: 0.3,
                roughness: 0.7,
                metalness: 0.5
            });

            const building = new THREE.Mesh(buildingGeo, buildingMat);

            // Random position in a circle around spawn
            const angle = Math.random() * Math.PI * 2;
            const distance = Math.random() * 40 + 30;
            building.position.set(
                Math.cos(angle) * distance,
                height / 2,
                Math.sin(angle) * distance
            );

            building.castShadow = true;
            building.receiveShadow = true;
            this.scene.add(building);

            // Windows
            for (let j = 0; j < Math.floor(height / 3); j++) {
                const windowGeo = new THREE.PlaneGeometry(width * 0.8, 2);
                const windowMat = new THREE.MeshBasicMaterial({
                    color: Math.random() > 0.7 ? 0xFFFF00 : 0x333333
                });
                const window1 = new THREE.Mesh(windowGeo, windowMat);
                window1.position.copy(building.position);
                window1.position.y = j * 3 + 2;
                window1.position.z += depth / 2 + 0.01;
                this.scene.add(window1);
            }
        }
    }

    createFloatingIslands() {
        // Floating platforms
        for (let i = 0; i < 10; i++) {
            const islandGeo = new THREE.CylinderGeometry(5, 3, 2, 8);
            const islandMat = new THREE.MeshStandardMaterial({
                color: 0x8B4513,
                roughness: 0.9
            });

            const island = new THREE.Mesh(islandGeo, islandMat);
            island.position.set(
                Math.random() * 100 - 50,
                Math.random() * 30 + 20,
                Math.random() * 100 - 50
            );
            island.castShadow = true;
            island.receiveShadow = true;
            this.scene.add(island);

            // Glowing crystal on top
            const crystalGeo = new THREE.OctahedronGeometry(1);
            const crystalMat = new THREE.MeshStandardMaterial({
                color: 0xFF00FF,
                emissive: 0xFF00FF,
                emissiveIntensity: 1
            });
            const crystal = new THREE.Mesh(crystalGeo, crystalMat);
            crystal.position.copy(island.position);
            crystal.position.y += 2;
            this.scene.add(crystal);
        }
    }

    createPortals() {
        // Create portal rings
        const portalPositions = [
            { x: 20, y: 5, z: 0 },
            { x: -20, y: 5, z: 0 },
            { x: 0, y: 5, z: 20 },
            { x: 0, y: 5, z: -20 }
        ];

        portalPositions.forEach(pos => {
            const ringGeo = new THREE.TorusGeometry(3, 0.2, 16, 100);
            const ringMat = new THREE.MeshStandardMaterial({
                color: 0x00FFFF,
                emissive: 0x00FFFF,
                emissiveIntensity: 2,
                metalness: 1
            });

            const ring = new THREE.Mesh(ringGeo, ringMat);
            ring.position.set(pos.x, pos.y, pos.z);
            this.scene.add(ring);

            // Portal surface
            const portalGeo = new THREE.CircleGeometry(2.8, 32);
            const portalMat = new THREE.MeshBasicMaterial({
                color: 0x0066FF,
                transparent: true,
                opacity: 0.5,
                side: THREE.DoubleSide
            });
            const portal = new THREE.Mesh(portalGeo, portalMat);
            portal.position.copy(ring.position);
            this.scene.add(portal);
        });
    }

    createParticleEffects() {
        // Floating particles
        const particleCount = 1000;
        const particlesGeometry = new THREE.BufferGeometry();
        const particlePositions = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount * 3; i += 3) {
            particlePositions[i] = (Math.random() - 0.5) * 100;
            particlePositions[i + 1] = Math.random() * 50;
            particlePositions[i + 2] = (Math.random() - 0.5) * 100;
        }

        particlesGeometry.setAttribute('position', new THREE.BufferAttribute(particlePositions, 3));

        const particlesMaterial = new THREE.PointsMaterial({
            color: 0xFF9D00,
            size: 0.1,
            transparent: true,
            opacity: 0.6
        });

        this.particles = new THREE.Points(particlesGeometry, particlesMaterial);
        this.scene.add(this.particles);
    }

    setupEventListeners() {
        // Click to enable pointer lock
        document.body.addEventListener('click', () => {
            if (!this.controls.isLocked) {
                this.controls.lock();
            }
        });

        // Keyboard controls
        document.addEventListener('keydown', (e) => {
            switch (e.code) {
                case 'KeyW': this.moveForward = true; break;
                case 'KeyS': this.moveBackward = true; break;
                case 'KeyA': this.moveLeft = true; break;
                case 'KeyD': this.moveRight = true; break;
                case 'ShiftLeft': this.canRun = true; break;
                case 'Space':
                    if (this.player.canJump) {
                        this.playerBody.velocity.y = this.player.jumpPower;
                        this.player.canJump = false;
                    }
                    break;
                case 'KeyT':
                    e.preventDefault();
                    document.getElementById('chat-input').focus();
                    break;
            }
        });

        document.addEventListener('keyup', (e) => {
            switch (e.code) {
                case 'KeyW': this.moveForward = false; break;
                case 'KeyS': this.moveBackward = false; break;
                case 'KeyA': this.moveLeft = false; break;
                case 'KeyD': this.moveRight = false; break;
                case 'ShiftLeft': this.canRun = false; break;
            }
        });

        // Chat input
        document.getElementById('chat-input').addEventListener('keydown', (e) => {
            if (e.code === 'Enter') {
                const msg = e.target.value.trim();
                if (msg) {
                    this.addChatMessage('You', msg);
                    e.target.value = '';
                }
                e.target.blur();
                this.controls.lock();
            } else if (e.code === 'Escape') {
                e.target.blur();
                this.controls.lock();
            }
        });

        // Window resize
        window.addEventListener('resize', () => {
            this.camera.aspect = window.innerWidth / window.innerHeight;
            this.camera.updateProjectionMatrix();
            this.renderer.setSize(window.innerWidth, window.innerHeight);
        });

        // VR button (if supported)
        if ('xr' in navigator) {
            navigator.xr.isSessionSupported('immersive-vr').then((supported) => {
                if (supported) {
                    document.getElementById('vr-button').style.display = 'block';
                    document.getElementById('vr-button').addEventListener('click', () => {
                        this.enterVR();
                    });
                }
            });
        }
    }

    addChatMessage(sender, message) {
        const chatDiv = document.getElementById('chat');
        const msgEl = document.createElement('div');
        msgEl.style.marginBottom = '5px';
        msgEl.innerHTML = `<strong>${sender}:</strong> ${message}`;
        chatDiv.appendChild(msgEl);
        chatDiv.scrollTop = chatDiv.scrollHeight;
    }

    updateMovement(delta) {
        const speed = this.canRun ? this.player.speed * 2 : this.player.speed;
        const velocity = new CANNON.Vec3(0, this.playerBody.velocity.y, 0);

        const forward = new THREE.Vector3();
        const right = new THREE.Vector3();

        this.camera.getWorldDirection(forward);
        forward.y = 0;
        forward.normalize();

        right.crossVectors(forward, new THREE.Vector3(0, 1, 0));

        if (this.moveForward) velocity.z -= forward.z * speed;
        if (this.moveBackward) velocity.z += forward.z * speed;
        if (this.moveLeft) velocity.x -= right.x * speed;
        if (this.moveRight) velocity.x += right.x * speed;

        if (this.moveForward) velocity.x -= forward.x * speed;
        if (this.moveBackward) velocity.x += forward.x * speed;
        if (this.moveLeft) velocity.z -= right.z * speed;
        if (this.moveRight) velocity.z += right.z * speed;

        this.playerBody.velocity.x = velocity.x;
        this.playerBody.velocity.z = velocity.z;

        // Check if on ground
        if (Math.abs(this.playerBody.velocity.y) < 0.1 && this.playerBody.position.y < this.player.height + 0.1) {
            this.player.canJump = true;
        }

        // Update camera position
        this.camera.position.x = this.playerBody.position.x;
        this.camera.position.y = this.playerBody.position.y + this.player.height / 2;
        this.camera.position.z = this.playerBody.position.z;

        // Update HUD
        document.getElementById('position').textContent =
            `${this.camera.position.x.toFixed(1)}, ${this.camera.position.y.toFixed(1)}, ${this.camera.position.z.toFixed(1)}`;
    }

    updateFPS() {
        this.frameCount++;
        const currentTime = performance.now();

        if (currentTime >= this.lastTime + 1000) {
            document.getElementById('fps').textContent = this.frameCount;
            this.frameCount = 0;
            this.lastTime = currentTime;
        }
    }

    enterVR() {
        this.renderer.xr.enabled = true;
        navigator.xr.requestSession('immersive-vr').then((session) => {
            this.renderer.xr.setSession(session);
        });
    }

    animate() {
        requestAnimationFrame(() => this.animate());

        const delta = this.clock.getDelta();

        // Update physics
        this.world.step(1 / 60, delta, 3);

        // Update movement
        if (this.controls.isLocked) {
            this.updateMovement(delta);
        }

        // Animate particles
        if (this.particles) {
            this.particles.rotation.y += 0.0005;
        }

        // Update FPS counter
        this.updateFPS();

        // Render
        this.renderer.render(this.scene, this.camera);
    }
}

// Initialize the metaverse when page loads
window.addEventListener('load', () => {
    new LucidiaMetaverse();
});
