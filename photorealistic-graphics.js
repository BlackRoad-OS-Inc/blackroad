/**
 * PHOTOREALISTIC GRAPHICS SYSTEM
 *
 * Advanced shaders, realistic lighting, post-processing, water physics, and sky!
 * Make the metaverse look like REALITY but MORE BEAUTIFUL.
 *
 * Philosophy: "BEAUTY IS IN THE DETAILS. LIGHT IS EVERYTHING."
 */

import * as THREE from 'three';

// ===== ADVANCED MATERIAL LIBRARY =====
export class AdvancedMaterials {
    constructor() {
        this.materials = new Map();
    }

    // Physically-based rendering materials
    createPBRMaterial(name, options = {}) {
        const material = new THREE.MeshStandardMaterial({
            color: options.color || 0xffffff,
            metalness: options.metalness !== undefined ? options.metalness : 0.0,
            roughness: options.roughness !== undefined ? options.roughness : 0.5,
            emissive: options.emissive || 0x000000,
            emissiveIntensity: options.emissiveIntensity || 0.0,
            transparent: options.transparent || false,
            opacity: options.opacity !== undefined ? options.opacity : 1.0,
            normalScale: options.normalScale || new THREE.Vector2(1, 1),
            envMapIntensity: options.envMapIntensity !== undefined ? options.envMapIntensity : 1.0
        });

        this.materials.set(name, material);
        return material;
    }

    // Realistic metals
    gold() {
        return this.createPBRMaterial('gold', {
            color: 0xFFD700,
            metalness: 1.0,
            roughness: 0.2,
            emissive: 0xFFD700,
            emissiveIntensity: 0.1
        });
    }

    silver() {
        return this.createPBRMaterial('silver', {
            color: 0xC0C0C0,
            metalness: 1.0,
            roughness: 0.15
        });
    }

    copper() {
        return this.createPBRMaterial('copper', {
            color: 0xB87333,
            metalness: 1.0,
            roughness: 0.3
        });
    }

    // Realistic glass
    glass(tint = 0xffffff, opacity = 0.3) {
        return new THREE.MeshPhysicalMaterial({
            color: tint,
            metalness: 0.0,
            roughness: 0.0,
            transmission: 1.0 - opacity,
            transparent: true,
            opacity: opacity,
            ior: 1.5, // Index of refraction
            thickness: 0.5,
            envMapIntensity: 1.0
        });
    }

    // Realistic water
    water() {
        return new THREE.MeshPhysicalMaterial({
            color: 0x006994,
            metalness: 0.0,
            roughness: 0.1,
            transmission: 0.9,
            transparent: true,
            opacity: 0.8,
            ior: 1.333, // Water IOR
            thickness: 1.0,
            envMapIntensity: 1.5
        });
    }

    // Crystal/gem
    crystal(color = 0x9B59B6) {
        return new THREE.MeshPhysicalMaterial({
            color: color,
            metalness: 0.0,
            roughness: 0.0,
            transmission: 0.95,
            transparent: true,
            opacity: 0.5,
            ior: 2.4, // Diamond-like
            thickness: 1.0,
            clearcoat: 1.0,
            clearcoatRoughness: 0.0,
            envMapIntensity: 2.0
        });
    }

    // Glowing materials
    glow(color = 0xFFFFFF, intensity = 1.0) {
        return this.createPBRMaterial('glow', {
            color: color,
            emissive: color,
            emissiveIntensity: intensity,
            metalness: 0.0,
            roughness: 0.5
        });
    }

    // Realistic skin
    skin(tone = 0xFFE4C4) {
        return new THREE.MeshPhysicalMaterial({
            color: tone,
            metalness: 0.0,
            roughness: 0.6,
            transmission: 0.1,
            transparent: true,
            opacity: 1.0,
            ior: 1.4,
            thickness: 0.5,
            subsurfaceScattering: true // Would need custom shader for true SSS
        });
    }

    // Realistic plant material
    leaf(color = 0x228B22) {
        return new THREE.MeshPhysicalMaterial({
            color: color,
            metalness: 0.0,
            roughness: 0.7,
            transmission: 0.3,
            transparent: true,
            opacity: 0.9,
            side: THREE.DoubleSide,
            clearcoat: 0.3,
            clearcoatRoughness: 0.4
        });
    }
}

// ===== CUSTOM SHADERS =====
export class CustomShaders {
    // Holographic shader
    static hologram() {
        return {
            vertexShader: `
                varying vec3 vNormal;
                varying vec3 vPosition;

                void main() {
                    vNormal = normalize(normalMatrix * normal);
                    vPosition = position;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                }
            `,
            fragmentShader: `
                uniform vec3 color;
                uniform float time;
                varying vec3 vNormal;
                varying vec3 vPosition;

                void main() {
                    float fresnel = pow(1.0 - abs(dot(vNormal, vec3(0.0, 0.0, 1.0))), 3.0);
                    float scanline = sin(vPosition.y * 20.0 + time * 5.0) * 0.5 + 0.5;
                    vec3 finalColor = color * (fresnel + scanline * 0.3);
                    float alpha = fresnel * 0.8 + scanline * 0.2;
                    gl_FragColor = vec4(finalColor, alpha);
                }
            `,
            uniforms: {
                color: { value: new THREE.Color(0x00ffff) },
                time: { value: 0.0 }
            }
        };
    }

    // Aurora/northern lights shader
    static aurora() {
        return {
            vertexShader: `
                varying vec2 vUv;
                varying vec3 vPosition;

                void main() {
                    vUv = uv;
                    vPosition = position;
                    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                }
            `,
            fragmentShader: `
                uniform float time;
                uniform vec3 color1;
                uniform vec3 color2;
                varying vec2 vUv;
                varying vec3 vPosition;

                // Noise function
                float noise(vec2 p) {
                    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
                }

                void main() {
                    vec2 pos = vUv * 3.0;
                    float wave1 = sin(pos.x * 2.0 + time) * 0.5;
                    float wave2 = sin(pos.x * 3.0 - time * 0.7) * 0.3;
                    float n = noise(pos + time * 0.1);

                    float intensity = (wave1 + wave2 + n * 0.2) * 0.5 + 0.5;
                    vec3 color = mix(color1, color2, intensity);
                    float alpha = intensity * 0.7;

                    gl_FragColor = vec4(color, alpha);
                }
            `,
            uniforms: {
                time: { value: 0.0 },
                color1: { value: new THREE.Color(0x00ff88) },
                color2: { value: new THREE.Color(0x8800ff) }
            }
        };
    }

    // Flowing water shader
    static flowingWater() {
        return {
            vertexShader: `
                varying vec2 vUv;
                varying vec3 vNormal;
                uniform float time;

                void main() {
                    vUv = uv;
                    vNormal = normal;

                    vec3 pos = position;
                    // Wave animation
                    pos.y += sin(pos.x * 2.0 + time) * 0.2;
                    pos.y += cos(pos.z * 2.0 + time * 1.3) * 0.15;

                    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
                }
            `,
            fragmentShader: `
                uniform vec3 waterColor;
                uniform float time;
                varying vec2 vUv;
                varying vec3 vNormal;

                void main() {
                    // Animated ripples
                    float wave = sin(vUv.x * 20.0 + time * 2.0) * 0.5 + 0.5;
                    wave += cos(vUv.y * 20.0 + time * 1.5) * 0.5;

                    vec3 color = waterColor + vec3(wave * 0.1);
                    float alpha = 0.7 + wave * 0.1;

                    gl_FragColor = vec4(color, alpha);
                }
            `,
            uniforms: {
                waterColor: { value: new THREE.Color(0x006994) },
                time: { value: 0.0 }
            }
        };
    }
}

// ===== ADVANCED LIGHTING SYSTEM =====
export class AdvancedLighting {
    constructor(scene) {
        this.scene = scene;
        this.lights = [];
    }

    // Create realistic sun
    createSun(intensity = 1.5) {
        const sun = new THREE.DirectionalLight(0xFFFAF0, intensity);
        sun.position.set(100, 100, 50);
        sun.castShadow = true;

        // High quality shadows
        sun.shadow.mapSize.width = 2048;
        sun.shadow.mapSize.height = 2048;
        sun.shadow.camera.near = 0.5;
        sun.shadow.camera.far = 500;
        sun.shadow.camera.left = -100;
        sun.shadow.camera.right = 100;
        sun.shadow.camera.top = 100;
        sun.shadow.camera.bottom = -100;
        sun.shadow.bias = -0.0001;

        this.scene.add(sun);
        this.lights.push({ type: 'sun', light: sun });

        return sun;
    }

    // Ambient lighting with color
    createAmbient(color = 0xffffff, intensity = 0.4) {
        const ambient = new THREE.AmbientLight(color, intensity);
        this.scene.add(ambient);
        this.lights.push({ type: 'ambient', light: ambient });
        return ambient;
    }

    // Hemisphere light (sky + ground)
    createHemisphere(skyColor = 0x87CEEB, groundColor = 0x228B22, intensity = 0.6) {
        const hemi = new THREE.HemisphereLight(skyColor, groundColor, intensity);
        this.scene.add(hemi);
        this.lights.push({ type: 'hemisphere', light: hemi });
        return hemi;
    }

    // Point light with shadows
    createPointLight(position, color = 0xffffff, intensity = 1.0, distance = 10) {
        const point = new THREE.PointLight(color, intensity, distance);
        point.position.copy(position);
        point.castShadow = true;
        point.shadow.mapSize.width = 512;
        point.shadow.mapSize.height = 512;

        this.scene.add(point);
        this.lights.push({ type: 'point', light: point });

        return point;
    }

    // Spot light for dramatic effects
    createSpotLight(position, target, color = 0xffffff, intensity = 1.5) {
        const spot = new THREE.SpotLight(color, intensity);
        spot.position.copy(position);
        spot.target.position.copy(target);
        spot.angle = Math.PI / 6;
        spot.penumbra = 0.3;
        spot.decay = 2;
        spot.distance = 100;
        spot.castShadow = true;

        this.scene.add(spot);
        this.scene.add(spot.target);
        this.lights.push({ type: 'spot', light: spot });

        return spot;
    }

    // Update sun position based on time
    updateSunPosition(timeOfDay) {
        const sun = this.lights.find(l => l.type === 'sun')?.light;
        if (!sun) return;

        const angle = timeOfDay * Math.PI * 2;
        const distance = 100;

        sun.position.set(
            Math.cos(angle) * distance,
            Math.sin(angle) * distance,
            50
        );

        // Color temperature changes
        const t = Math.sin(angle);
        if (t > 0) {
            // Daytime - warm white
            sun.color.setRGB(1.0, 0.98, 0.94);
            sun.intensity = 1.5;
        } else if (t > -0.2) {
            // Sunset/sunrise - orange
            sun.color.setRGB(1.0, 0.6, 0.3);
            sun.intensity = 0.8;
        } else {
            // Night - moonlight blue
            sun.color.setRGB(0.7, 0.8, 1.0);
            sun.intensity = 0.3;
        }
    }
}

// ===== POST-PROCESSING EFFECTS =====
export class PostProcessing {
    constructor(renderer, scene, camera) {
        this.renderer = renderer;
        this.scene = scene;
        this.camera = camera;
        this.effects = {};
    }

    // Note: In real implementation, would use EffectComposer from three/examples/jsm/postprocessing/
    // This is a simplified mock structure

    enableBloom(strength = 0.5) {
        console.log(`✨ Bloom enabled (strength: ${strength})`);
        this.effects.bloom = { enabled: true, strength };
    }

    enableDepthOfField(focus = 10, aperture = 0.025, maxblur = 0.01) {
        console.log(`📸 Depth of field enabled`);
        this.effects.dof = { enabled: true, focus, aperture, maxblur };
    }

    enableSSAO(radius = 5, intensity = 0.5) {
        console.log(`🌫️ SSAO enabled (Screen-space ambient occlusion)`);
        this.effects.ssao = { enabled: true, radius, intensity };
    }

    enableColorGrading(preset = 'warm') {
        console.log(`🎨 Color grading: ${preset}`);
        const presets = {
            warm: { r: 1.1, g: 1.0, b: 0.9 },
            cool: { r: 0.9, g: 1.0, b: 1.1 },
            vibrant: { r: 1.2, g: 1.1, b: 1.0 },
            dreamy: { r: 1.0, g: 0.95, b: 1.1 }
        };
        this.effects.colorGrading = { enabled: true, ...presets[preset] };
    }

    enableVignette(darkness = 0.5) {
        console.log(`🖼️ Vignette enabled`);
        this.effects.vignette = { enabled: true, darkness };
    }

    enableGodRays(intensity = 0.5) {
        console.log(`☀️ God rays enabled`);
        this.effects.godRays = { enabled: true, intensity };
    }
}

// ===== REALISTIC WATER SYSTEM =====
export class RealisticWater {
    constructor(scene, size = 100) {
        this.scene = scene;
        this.size = size;
        this.mesh = null;
        this.material = null;
        this.time = 0;
    }

    create(position = new THREE.Vector3(0, 0, 0)) {
        const geometry = new THREE.PlaneGeometry(this.size, this.size, 128, 128);

        const shader = CustomShaders.flowingWater();
        this.material = new THREE.ShaderMaterial({
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            uniforms: shader.uniforms,
            transparent: true,
            side: THREE.DoubleSide
        });

        this.mesh = new THREE.Mesh(geometry, this.material);
        this.mesh.rotation.x = -Math.PI / 2;
        this.mesh.position.copy(position);

        this.scene.add(this.mesh);

        return this.mesh;
    }

    update(deltaTime) {
        this.time += deltaTime;
        if (this.material) {
            this.material.uniforms.time.value = this.time;
        }
    }

    addCaustics() {
        // Caustic light patterns under water
        console.log('💧 Caustics added to water');
        // Would require additional shader for light patterns
    }
}

// ===== REALISTIC SKY SYSTEM =====
export class RealisticSky {
    constructor(scene) {
        this.scene = scene;
        this.skyMesh = null;
        this.clouds = [];
        this.stars = null;
        this.aurora = null;
    }

    createSky() {
        // Sky dome
        const skyGeometry = new THREE.SphereGeometry(500, 32, 32);
        const skyMaterial = new THREE.MeshBasicMaterial({
            color: 0x87CEEB,
            side: THREE.BackSide
        });
        this.skyMesh = new THREE.Mesh(skyGeometry, skyMaterial);
        this.scene.add(this.skyMesh);

        return this.skyMesh;
    }

    createClouds(count = 20) {
        for (let i = 0; i < count; i++) {
            const cloud = new THREE.Group();

            // Multiple puffs per cloud
            for (let j = 0; j < 3 + Math.floor(Math.random() * 3); j++) {
                const puff = new THREE.Mesh(
                    new THREE.SphereGeometry(5 + Math.random() * 5, 8, 8),
                    new THREE.MeshBasicMaterial({
                        color: 0xFFFFFF,
                        transparent: true,
                        opacity: 0.7
                    })
                );
                puff.position.set(
                    (Math.random() - 0.5) * 10,
                    (Math.random() - 0.5) * 3,
                    (Math.random() - 0.5) * 10
                );
                cloud.add(puff);
            }

            cloud.position.set(
                (Math.random() - 0.5) * 400,
                50 + Math.random() * 50,
                (Math.random() - 0.5) * 400
            );

            this.scene.add(cloud);
            this.clouds.push({
                mesh: cloud,
                velocity: (Math.random() - 0.5) * 0.02
            });
        }
    }

    createStars(count = 1000) {
        const geometry = new THREE.BufferGeometry();
        const positions = new Float32Array(count * 3);
        const colors = new Float32Array(count * 3);

        for (let i = 0; i < count; i++) {
            // Random position on sphere
            const theta = Math.random() * Math.PI * 2;
            const phi = Math.acos(Math.random() * 2 - 1);
            const r = 400;

            positions[i * 3] = r * Math.sin(phi) * Math.cos(theta);
            positions[i * 3 + 1] = r * Math.sin(phi) * Math.sin(theta);
            positions[i * 3 + 2] = r * Math.cos(phi);

            // Star colors (white/blue/yellow)
            const colorType = Math.random();
            if (colorType < 0.7) {
                // White
                colors[i * 3] = 1.0;
                colors[i * 3 + 1] = 1.0;
                colors[i * 3 + 2] = 1.0;
            } else if (colorType < 0.9) {
                // Blue
                colors[i * 3] = 0.7;
                colors[i * 3 + 1] = 0.8;
                colors[i * 3 + 2] = 1.0;
            } else {
                // Yellow
                colors[i * 3] = 1.0;
                colors[i * 3 + 1] = 0.9;
                colors[i * 3 + 2] = 0.7;
            }
        }

        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

        const material = new THREE.PointsMaterial({
            size: 2,
            vertexColors: true,
            transparent: true,
            opacity: 0
        });

        this.stars = new THREE.Points(geometry, material);
        this.scene.add(this.stars);
    }

    createAurora() {
        const shader = CustomShaders.aurora();
        const geometry = new THREE.PlaneGeometry(200, 50, 32, 32);
        const material = new THREE.ShaderMaterial({
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            uniforms: shader.uniforms,
            transparent: true,
            side: THREE.DoubleSide
        });

        this.aurora = new THREE.Mesh(geometry, material);
        this.aurora.position.set(0, 80, -150);
        this.scene.add(this.aurora);
    }

    update(timeOfDay, deltaTime) {
        // Update sky color based on time
        if (this.skyMesh) {
            const colors = [
                new THREE.Color(0x000033), // Midnight
                new THREE.Color(0xFF6B35), // Sunrise
                new THREE.Color(0x87CEEB), // Day
                new THREE.Color(0xFF6B35), // Sunset
                new THREE.Color(0x000033)  // Midnight
            ];

            const index = timeOfDay * 4;
            const floor = Math.floor(index);
            const ceil = Math.ceil(index) % 4;
            const mix = index - floor;

            this.skyMesh.material.color.lerpColors(colors[floor], colors[ceil], mix);
        }

        // Animate clouds
        this.clouds.forEach(({ mesh, velocity }) => {
            mesh.position.x += velocity;
            if (Math.abs(mesh.position.x) > 250) {
                mesh.position.x = -mesh.position.x;
            }
        });

        // Show/hide stars based on time
        if (this.stars) {
            const isNight = timeOfDay < 0.25 || timeOfDay > 0.75;
            this.stars.material.opacity = isNight ? 1.0 : 0.0;
        }

        // Animate aurora
        if (this.aurora && this.aurora.material.uniforms) {
            this.aurora.material.uniforms.time.value += deltaTime;
        }
    }
}

// ===== GRAPHICS MANAGER =====
export class PhotorealisticGraphics {
    constructor(renderer, scene, camera) {
        this.renderer = renderer;
        this.scene = scene;
        this.camera = camera;

        this.materials = new AdvancedMaterials();
        this.lighting = new AdvancedLighting(scene);
        this.postProcessing = new PostProcessing(renderer, scene, camera);
        this.sky = new RealisticSky(scene);
        this.waters = [];

        this.init();
    }

    init() {
        // Enable shadows
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

        // Tone mapping for HDR
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.0;

        // Setup lighting
        this.lighting.createSun();
        this.lighting.createHemisphere();

        // Setup sky
        this.sky.createSky();
        this.sky.createClouds(15);
        this.sky.createStars(500);

        // Enable post-processing
        this.postProcessing.enableBloom(0.3);
        this.postProcessing.enableColorGrading('warm');

        console.log('🎨 Photorealistic graphics initialized!');
    }

    createWater(position, size = 100) {
        const water = new RealisticWater(this.scene, size);
        water.create(position);
        this.waters.push(water);
        return water;
    }

    update(timeOfDay, deltaTime) {
        this.lighting.updateSunPosition(timeOfDay);
        this.sky.update(timeOfDay, deltaTime);
        this.waters.forEach(water => water.update(deltaTime));
    }
}

export default PhotorealisticGraphics;
