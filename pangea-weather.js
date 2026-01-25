/**
 * PANGEA WEATHER & CLIMATE SYSTEM
 *
 * Dynamic weather patterns and day/night cycles for realistic atmosphere
 * - Rain storms with particle effects
 * - Snow in polar regions
 * - Sandstorms in deserts
 * - Volcanic ash clouds
 * - Lightning and thunder
 * - Wind effects
 * - 24-hour day/night cycle
 * - Seasonal variations
 */

import * as THREE from 'three';

/**
 * WEATHER TYPES
 */
export const WEATHER_TYPES = {
    CLEAR: 'clear',
    RAIN: 'rain',
    STORM: 'storm',
    SNOW: 'snow',
    SANDSTORM: 'sandstorm',
    VOLCANIC_ASH: 'volcanic_ash',
    FOG: 'fog',
    MIST: 'mist'
};

/**
 * DAY/NIGHT CYCLE MANAGER
 */
export class DayNightCycle {
    constructor(scene) {
        this.scene = scene;
        this.time = 0.25; // Start at dawn (0-1 range, 0=midnight, 0.5=noon)
        this.dayLength = 600; // 10 minutes per day
        this.speed = 1.0;

        // Create sun
        this.sun = new THREE.DirectionalLight(0xfff5e6, 1.5);
        this.sun.castShadow = true;
        this.sun.shadow.camera.left = -150;
        this.sun.shadow.camera.right = 150;
        this.sun.shadow.camera.top = 150;
        this.sun.shadow.camera.bottom = -150;
        this.sun.shadow.camera.far = 500;
        this.sun.shadow.mapSize.width = 2048;
        this.sun.shadow.mapSize.height = 2048;
        this.scene.add(this.sun);

        // Create moon
        this.moon = new THREE.DirectionalLight(0x6699cc, 0.3);
        this.scene.add(this.moon);

        // Ambient light
        this.ambient = new THREE.AmbientLight(0x404040, 0.4);
        this.scene.add(this.ambient);

        // Hemisphere light
        this.hemi = new THREE.HemisphereLight(0x87ceeb, 0x8b7355, 0.6);
        this.scene.add(this.hemi);

        // Sky colors
        this.skyColors = {
            night: new THREE.Color(0x000820),
            dawn: new THREE.Color(0xff6b35),
            day: new THREE.Color(0x87ceeb),
            dusk: new THREE.Color(0xff4500)
        };
    }

    update(delta) {
        // Advance time
        this.time += (delta / this.dayLength) * this.speed;
        if (this.time > 1) this.time -= 1;

        // Update sun position
        const sunAngle = this.time * Math.PI * 2;
        const sunRadius = 200;
        this.sun.position.set(
            Math.cos(sunAngle) * sunRadius,
            Math.sin(sunAngle) * sunRadius,
            50
        );

        // Update moon position (opposite sun)
        const moonAngle = sunAngle + Math.PI;
        this.moon.position.set(
            Math.cos(moonAngle) * sunRadius,
            Math.sin(moonAngle) * sunRadius,
            50
        );

        // Update sky color
        this.updateSkyColor();

        // Update light intensities
        this.updateLighting();
    }

    updateSkyColor() {
        let color;

        if (this.time < 0.2) {
            // Night (0.0-0.2)
            const t = this.time / 0.2;
            color = new THREE.Color().lerpColors(this.skyColors.night, this.skyColors.dawn, t);
        } else if (this.time < 0.3) {
            // Dawn (0.2-0.3)
            const t = (this.time - 0.2) / 0.1;
            color = new THREE.Color().lerpColors(this.skyColors.dawn, this.skyColors.day, t);
        } else if (this.time < 0.7) {
            // Day (0.3-0.7)
            color = this.skyColors.day.clone();
        } else if (this.time < 0.8) {
            // Dusk (0.7-0.8)
            const t = (this.time - 0.7) / 0.1;
            color = new THREE.Color().lerpColors(this.skyColors.day, this.skyColors.dusk, t);
        } else {
            // Evening to night (0.8-1.0)
            const t = (this.time - 0.8) / 0.2;
            color = new THREE.Color().lerpColors(this.skyColors.dusk, this.skyColors.night, t);
        }

        this.scene.background = color;
        if (this.scene.fog) {
            this.scene.fog.color = color;
        }
    }

    updateLighting() {
        // Sun intensity based on height
        const sunHeight = Math.sin(this.time * Math.PI * 2);
        this.sun.intensity = Math.max(0, sunHeight * 1.5);

        // Moon intensity (opposite)
        const moonHeight = Math.sin((this.time + 0.5) * Math.PI * 2);
        this.moon.intensity = Math.max(0, moonHeight * 0.4);

        // Ambient based on time
        const ambientIntensity = 0.2 + Math.max(0, sunHeight) * 0.4;
        this.ambient.intensity = ambientIntensity;

        // Hemisphere
        const hemiIntensity = 0.3 + Math.max(0, sunHeight) * 0.5;
        this.hemi.intensity = hemiIntensity;
    }

    getTimeOfDay() {
        if (this.time < 0.25) return 'night';
        if (this.time < 0.3) return 'dawn';
        if (this.time < 0.7) return 'day';
        if (this.time < 0.8) return 'dusk';
        return 'night';
    }

    isDay() {
        return this.time > 0.3 && this.time < 0.7;
    }

    setTime(time) {
        this.time = time;
    }

    setSpeed(speed) {
        this.speed = speed;
    }
}

/**
 * WEATHER SYSTEM
 */
export class WeatherSystem {
    constructor(scene, terrain) {
        this.scene = scene;
        this.terrain = terrain;
        this.currentWeather = WEATHER_TYPES.CLEAR;
        this.weatherDuration = 0;
        this.transitionTime = 0;

        // Particle systems
        this.rainParticles = null;
        this.snowParticles = null;
        this.sandParticles = null;
        this.ashParticles = null;

        // Weather effects
        this.lightning = [];
        this.windSpeed = 0;
        this.windDirection = new THREE.Vector2(1, 0);

        // Initialize particle systems
        this.initializeParticleSystems();
    }

    initializeParticleSystems() {
        // RAIN
        const rainCount = 2000;
        const rainGeometry = new THREE.BufferGeometry();
        const rainPositions = new Float32Array(rainCount * 3);
        const rainVelocities = [];

        for (let i = 0; i < rainCount; i++) {
            rainPositions[i * 3] = (Math.random() - 0.5) * 200;
            rainPositions[i * 3 + 1] = Math.random() * 100;
            rainPositions[i * 3 + 2] = (Math.random() - 0.5) * 200;
            rainVelocities.push(new THREE.Vector3(0, -30 - Math.random() * 10, 0));
        }

        rainGeometry.setAttribute('position', new THREE.BufferAttribute(rainPositions, 3));

        const rainMaterial = new THREE.PointsMaterial({
            color: 0x6699cc,
            size: 0.3,
            transparent: true,
            opacity: 0.6
        });

        this.rainParticles = new THREE.Points(rainGeometry, rainMaterial);
        this.rainParticles.visible = false;
        this.rainVelocities = rainVelocities;
        this.scene.add(this.rainParticles);

        // SNOW
        const snowCount = 3000;
        const snowGeometry = new THREE.BufferGeometry();
        const snowPositions = new Float32Array(snowCount * 3);
        const snowVelocities = [];

        for (let i = 0; i < snowCount; i++) {
            snowPositions[i * 3] = (Math.random() - 0.5) * 200;
            snowPositions[i * 3 + 1] = Math.random() * 100;
            snowPositions[i * 3 + 2] = (Math.random() - 0.5) * 200;
            snowVelocities.push(new THREE.Vector3(
                (Math.random() - 0.5) * 2,
                -3 - Math.random() * 2,
                (Math.random() - 0.5) * 2
            ));
        }

        snowGeometry.setAttribute('position', new THREE.BufferAttribute(snowPositions, 3));

        const snowMaterial = new THREE.PointsMaterial({
            color: 0xffffff,
            size: 0.5,
            transparent: true,
            opacity: 0.8
        });

        this.snowParticles = new THREE.Points(snowGeometry, snowMaterial);
        this.snowParticles.visible = false;
        this.snowVelocities = snowVelocities;
        this.scene.add(this.snowParticles);

        // SANDSTORM
        const sandCount = 1500;
        const sandGeometry = new THREE.BufferGeometry();
        const sandPositions = new Float32Array(sandCount * 3);
        const sandVelocities = [];

        for (let i = 0; i < sandCount; i++) {
            sandPositions[i * 3] = (Math.random() - 0.5) * 200;
            sandPositions[i * 3 + 1] = Math.random() * 50;
            sandPositions[i * 3 + 2] = (Math.random() - 0.5) * 200;
            sandVelocities.push(new THREE.Vector3(
                10 + Math.random() * 5,
                (Math.random() - 0.5) * 3,
                (Math.random() - 0.5) * 5
            ));
        }

        sandGeometry.setAttribute('position', new THREE.BufferAttribute(sandPositions, 3));

        const sandMaterial = new THREE.PointsMaterial({
            color: 0xd4a574,
            size: 0.8,
            transparent: true,
            opacity: 0.5
        });

        this.sandParticles = new THREE.Points(sandGeometry, sandMaterial);
        this.sandParticles.visible = false;
        this.sandVelocities = sandVelocities;
        this.scene.add(this.sandParticles);

        // VOLCANIC ASH
        const ashCount = 2000;
        const ashGeometry = new THREE.BufferGeometry();
        const ashPositions = new Float32Array(ashCount * 3);
        const ashVelocities = [];

        for (let i = 0; i < ashCount; i++) {
            ashPositions[i * 3] = (Math.random() - 0.5) * 150;
            ashPositions[i * 3 + 1] = Math.random() * 80;
            ashPositions[i * 3 + 2] = (Math.random() - 0.5) * 150;
            ashVelocities.push(new THREE.Vector3(
                (Math.random() - 0.5) * 3,
                -1 - Math.random() * 2,
                (Math.random() - 0.5) * 3
            ));
        }

        ashGeometry.setAttribute('position', new THREE.BufferAttribute(ashPositions, 3));

        const ashMaterial = new THREE.PointsMaterial({
            color: 0x333333,
            size: 1.0,
            transparent: true,
            opacity: 0.7
        });

        this.ashParticles = new THREE.Points(ashGeometry, ashMaterial);
        this.ashParticles.visible = false;
        this.ashVelocities = ashVelocities;
        this.scene.add(this.ashParticles);
    }

    update(delta, cameraPosition, biome) {
        this.weatherDuration -= delta;

        // Change weather based on biome and time
        if (this.weatherDuration <= 0) {
            this.changeWeather(biome);
        }

        // Update current weather effects
        this.updateWeatherEffects(delta, cameraPosition);
    }

    changeWeather(biome) {
        // Determine weather based on biome
        let possibleWeather = [WEATHER_TYPES.CLEAR];

        if (biome && biome.name) {
            if (biome.name.includes('Ocean') || biome.name.includes('Sea') || biome.name.includes('Wetland')) {
                possibleWeather.push(WEATHER_TYPES.RAIN, WEATHER_TYPES.STORM, WEATHER_TYPES.FOG);
            }
            if (biome.name.includes('Polar') || biome.name.includes('Highland')) {
                possibleWeather.push(WEATHER_TYPES.SNOW);
            }
            if (biome.name.includes('Desert') || biome.name.includes('Arid')) {
                possibleWeather.push(WEATHER_TYPES.SANDSTORM, WEATHER_TYPES.CLEAR, WEATHER_TYPES.CLEAR);
            }
            if (biome.name.includes('Volcanic')) {
                possibleWeather.push(WEATHER_TYPES.VOLCANIC_ASH, WEATHER_TYPES.VOLCANIC_ASH);
            }
            if (biome.name.includes('Rainforest')) {
                possibleWeather.push(WEATHER_TYPES.RAIN, WEATHER_TYPES.MIST);
            }
        }

        this.currentWeather = possibleWeather[Math.floor(Math.random() * possibleWeather.length)];
        this.weatherDuration = 30 + Math.random() * 90; // 30-120 seconds

        // Hide all weather effects
        if (this.rainParticles) this.rainParticles.visible = false;
        if (this.snowParticles) this.snowParticles.visible = false;
        if (this.sandParticles) this.sandParticles.visible = false;
        if (this.ashParticles) this.ashParticles.visible = false;

        // Show current weather
        switch(this.currentWeather) {
            case WEATHER_TYPES.RAIN:
            case WEATHER_TYPES.STORM:
                if (this.rainParticles) this.rainParticles.visible = true;
                this.windSpeed = this.currentWeather === WEATHER_TYPES.STORM ? 15 : 5;
                break;
            case WEATHER_TYPES.SNOW:
                if (this.snowParticles) this.snowParticles.visible = true;
                this.windSpeed = 3;
                break;
            case WEATHER_TYPES.SANDSTORM:
                if (this.sandParticles) this.sandParticles.visible = true;
                this.windSpeed = 20;
                if (this.scene.fog) {
                    this.scene.fog.near = 20;
                    this.scene.fog.far = 100;
                }
                break;
            case WEATHER_TYPES.VOLCANIC_ASH:
                if (this.ashParticles) this.ashParticles.visible = true;
                this.windSpeed = 8;
                if (this.scene.fog) {
                    this.scene.fog.near = 30;
                    this.scene.fog.far = 150;
                }
                break;
            case WEATHER_TYPES.FOG:
            case WEATHER_TYPES.MIST:
                if (this.scene.fog) {
                    this.scene.fog.near = this.currentWeather === WEATHER_TYPES.FOG ? 10 : 30;
                    this.scene.fog.far = this.currentWeather === WEATHER_TYPES.FOG ? 80 : 150;
                }
                this.windSpeed = 1;
                break;
            default:
                this.windSpeed = 2;
                if (this.scene.fog) {
                    this.scene.fog.near = 50;
                    this.scene.fog.far = 400;
                }
        }

        // Update wind direction
        this.windDirection.set(Math.random() - 0.5, Math.random() - 0.5).normalize();
    }

    updateWeatherEffects(delta, cameraPosition) {
        // Update rain
        if (this.rainParticles && this.rainParticles.visible) {
            const positions = this.rainParticles.geometry.attributes.position.array;
            for (let i = 0; i < this.rainVelocities.length; i++) {
                const idx = i * 3;

                // Apply velocity
                positions[idx] += this.rainVelocities[i].x * delta + this.windSpeed * this.windDirection.x * delta;
                positions[idx + 1] += this.rainVelocities[i].y * delta;
                positions[idx + 2] += this.rainVelocities[i].z * delta + this.windSpeed * this.windDirection.y * delta;

                // Reset when hitting ground or going off-screen
                if (positions[idx + 1] < 0 ||
                    Math.abs(positions[idx] - cameraPosition.x) > 100 ||
                    Math.abs(positions[idx + 2] - cameraPosition.z) > 100) {
                    positions[idx] = cameraPosition.x + (Math.random() - 0.5) * 200;
                    positions[idx + 1] = 50 + Math.random() * 50;
                    positions[idx + 2] = cameraPosition.z + (Math.random() - 0.5) * 200;
                }
            }
            this.rainParticles.geometry.attributes.position.needsUpdate = true;
        }

        // Update snow
        if (this.snowParticles && this.snowParticles.visible) {
            const positions = this.snowParticles.geometry.attributes.position.array;
            for (let i = 0; i < this.snowVelocities.length; i++) {
                const idx = i * 3;

                positions[idx] += this.snowVelocities[i].x * delta + this.windSpeed * this.windDirection.x * delta;
                positions[idx + 1] += this.snowVelocities[i].y * delta;
                positions[idx + 2] += this.snowVelocities[i].z * delta + this.windSpeed * this.windDirection.y * delta;

                // Drift effect
                positions[idx] += Math.sin(Date.now() * 0.001 + i) * 0.1 * delta;
                positions[idx + 2] += Math.cos(Date.now() * 0.001 + i) * 0.1 * delta;

                if (positions[idx + 1] < 0 ||
                    Math.abs(positions[idx] - cameraPosition.x) > 100 ||
                    Math.abs(positions[idx + 2] - cameraPosition.z) > 100) {
                    positions[idx] = cameraPosition.x + (Math.random() - 0.5) * 200;
                    positions[idx + 1] = 50 + Math.random() * 50;
                    positions[idx + 2] = cameraPosition.z + (Math.random() - 0.5) * 200;
                }
            }
            this.snowParticles.geometry.attributes.position.needsUpdate = true;
        }

        // Update sandstorm
        if (this.sandParticles && this.sandParticles.visible) {
            const positions = this.sandParticles.geometry.attributes.position.array;
            for (let i = 0; i < this.sandVelocities.length; i++) {
                const idx = i * 3;

                positions[idx] += this.sandVelocities[i].x * delta * this.windSpeed * 0.1;
                positions[idx + 1] += this.sandVelocities[i].y * delta;
                positions[idx + 2] += this.sandVelocities[i].z * delta;

                if (Math.abs(positions[idx] - cameraPosition.x) > 100 ||
                    Math.abs(positions[idx + 2] - cameraPosition.z) > 100) {
                    positions[idx] = cameraPosition.x + (Math.random() - 0.5) * 200;
                    positions[idx + 1] = Math.random() * 50;
                    positions[idx + 2] = cameraPosition.z + (Math.random() - 0.5) * 200;
                }
            }
            this.sandParticles.geometry.attributes.position.needsUpdate = true;
        }

        // Update volcanic ash
        if (this.ashParticles && this.ashParticles.visible) {
            const positions = this.ashParticles.geometry.attributes.position.array;
            for (let i = 0; i < this.ashVelocities.length; i++) {
                const idx = i * 3;

                positions[idx] += this.ashVelocities[i].x * delta;
                positions[idx + 1] += this.ashVelocities[i].y * delta;
                positions[idx + 2] += this.ashVelocities[i].z * delta;

                // Swirling effect
                const swirl = Date.now() * 0.0005 + i;
                positions[idx] += Math.sin(swirl) * 0.2 * delta;
                positions[idx + 2] += Math.cos(swirl) * 0.2 * delta;

                if (positions[idx + 1] < 0 ||
                    Math.abs(positions[idx] - cameraPosition.x) > 80 ||
                    Math.abs(positions[idx + 2] - cameraPosition.z) > 80) {
                    positions[idx] = cameraPosition.x + (Math.random() - 0.5) * 150;
                    positions[idx + 1] = 40 + Math.random() * 40;
                    positions[idx + 2] = cameraPosition.z + (Math.random() - 0.5) * 150;
                }
            }
            this.ashParticles.geometry.attributes.position.needsUpdate = true;
        }

        // Lightning for storms
        if (this.currentWeather === WEATHER_TYPES.STORM && Math.random() < 0.001) {
            this.createLightning(cameraPosition);
        }
    }

    createLightning(nearPosition) {
        // Create lightning flash
        const lightningLight = new THREE.PointLight(0xffffff, 50, 200);
        lightningLight.position.set(
            nearPosition.x + (Math.random() - 0.5) * 100,
            50 + Math.random() * 50,
            nearPosition.z + (Math.random() - 0.5) * 100
        );
        this.scene.add(lightningLight);

        // Flash and remove
        setTimeout(() => {
            this.scene.remove(lightningLight);
        }, 100);

        // Thunder sound would go here
    }

    getWeatherInfo() {
        return {
            type: this.currentWeather,
            windSpeed: this.windSpeed,
            windDirection: this.windDirection,
            duration: this.weatherDuration
        };
    }

    forceWeather(type) {
        this.currentWeather = type;
        this.weatherDuration = 60;
    }
}

export default { DayNightCycle, WeatherSystem };
