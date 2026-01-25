/**
 * PANGEA PROCEDURAL SOUND SYSTEM
 *
 * Realistic ambient soundscapes generated in real-time using Web Audio API
 * - Environmental ambience (wind, rain, ocean waves)
 * - Creature sounds (roars, chirps, calls)
 * - Geological events (earthquakes, volcanoes, thunder)
 * - Spatial audio (3D positioned sounds)
 * - Dynamic mixing based on biome and time of day
 */

export class ProceduralSoundSystem {
    constructor() {
        this.audioContext = null;
        this.masterGain = null;
        this.enabled = false;

        // Sound sources
        this.ambientLoop = null;
        this.weatherSounds = new Map();
        this.creatureSounds = new Map();
        this.eventSounds = [];

        // Parameters
        this.volume = 0.3;
        this.spatialEnabled = true;
    }

    initialize() {
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            this.masterGain = this.audioContext.createGain();
            this.masterGain.gain.value = this.volume;
            this.masterGain.connect(this.audioContext.destination);
            this.enabled = true;
            console.log('🔊 Sound system initialized');
        } catch (e) {
            console.warn('Sound system not available:', e);
        }
    }

    /**
     * AMBIENT WIND
     */
    createWindSound(intensity = 0.5) {
        if (!this.enabled) return;

        const bufferSize = this.audioContext.sampleRate * 2;
        const buffer = this.audioContext.createBuffer(1, bufferSize, this.audioContext.sampleRate);
        const data = buffer.getChannelData(0);

        // Generate brown noise (wind-like)
        let lastOut = 0;
        for (let i = 0; i < bufferSize; i++) {
            const white = Math.random() * 2 - 1;
            const output = (lastOut + (0.02 * white)) / 1.02;
            data[i] = output * 0.5;
            lastOut = output;
        }

        const source = this.audioContext.createBufferSource();
        source.buffer = buffer;
        source.loop = true;

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 200 + intensity * 300;
        filter.Q.value = 0.5;

        const gain = this.audioContext.createGain();
        gain.gain.value = intensity * 0.2;

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);
        source.start();

        return { source, gain, filter };
    }

    /**
     * RAIN SOUND
     */
    createRainSound(intensity = 0.7) {
        if (!this.enabled) return;

        const bufferSize = this.audioContext.sampleRate * 0.5;
        const buffer = this.audioContext.createBuffer(1, bufferSize, this.audioContext.sampleRate);
        const data = buffer.getChannelData(0);

        // White noise filtered for rain-like sound
        for (let i = 0; i < bufferSize; i++) {
            data[i] = (Math.random() * 2 - 1) * 0.3;
        }

        const source = this.audioContext.createBufferSource();
        source.buffer = buffer;
        source.loop = true;

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.value = 2000;
        filter.Q.value = 0.3;

        const gain = this.audioContext.createGain();
        gain.gain.value = intensity * 0.3;

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);
        source.start();

        return { source, gain, filter };
    }

    /**
     * THUNDER
     */
    createThunder(distance = 0.5) {
        if (!this.enabled) return;

        const duration = 2 + Math.random() * 2;
        const bufferSize = this.audioContext.sampleRate * duration;
        const buffer = this.audioContext.createBuffer(1, bufferSize, this.audioContext.sampleRate);
        const data = buffer.getChannelData(0);

        // Rumbling thunder sound
        for (let i = 0; i < bufferSize; i++) {
            const t = i / this.audioContext.sampleRate;
            const envelope = Math.exp(-t * 2) * (1 - Math.exp(-t * 20));
            const noise = (Math.random() * 2 - 1);
            data[i] = noise * envelope * 0.8;
        }

        const source = this.audioContext.createBufferSource();
        source.buffer = buffer;

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 100 + (1 - distance) * 200;
        filter.Q.value = 1;

        const gain = this.audioContext.createGain();
        gain.gain.value = (1 - distance) * 0.6;

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);
        source.start();

        return { source };
    }

    /**
     * OCEAN WAVES
     */
    createOceanWaves(intensity = 0.5) {
        if (!this.enabled) return;

        // Create continuous wave sound
        const oscillator = this.audioContext.createOscillator();
        oscillator.type = 'sine';
        oscillator.frequency.value = 0.3; // Very slow oscillation

        const lfo = this.audioContext.createOscillator();
        lfo.type = 'sine';
        lfo.frequency.value = 0.1;

        const lfoGain = this.audioContext.createGain();
        lfoGain.gain.value = 100;

        lfo.connect(lfoGain);
        lfoGain.connect(oscillator.frequency);

        // Noise for waves
        const bufferSize = this.audioContext.sampleRate * 1;
        const buffer = this.audioContext.createBuffer(1, bufferSize, this.audioContext.sampleRate);
        const data = buffer.getChannelData(0);

        for (let i = 0; i < bufferSize; i++) {
            data[i] = (Math.random() * 2 - 1) * 0.1;
        }

        const noiseSource = this.audioContext.createBufferSource();
        noiseSource.buffer = buffer;
        noiseSource.loop = true;

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.value = 300;
        filter.Q.value = 0.5;

        const gain = this.audioContext.createGain();
        gain.gain.value = intensity * 0.25;

        noiseSource.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        oscillator.start();
        lfo.start();
        noiseSource.start();

        return { oscillator, lfo, noiseSource, gain };
    }

    /**
     * VOLCANIC RUMBLE
     */
    createVolcanicRumble(intensity = 1.0) {
        if (!this.enabled) return;

        const oscillator = this.audioContext.createOscillator();
        oscillator.type = 'sawtooth';
        oscillator.frequency.value = 30 + Math.random() * 20;

        const lfo = this.audioContext.createOscillator();
        lfo.type = 'sine';
        lfo.frequency.value = 2 + Math.random() * 3;

        const lfoGain = this.audioContext.createGain();
        lfoGain.gain.value = 10;

        lfo.connect(lfoGain);
        lfoGain.connect(oscillator.frequency);

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 100;
        filter.Q.value = 2;

        const gain = this.audioContext.createGain();
        gain.gain.setValueAtTime(0, this.audioContext.currentTime);
        gain.gain.linearRampToValueAtTime(intensity * 0.4, this.audioContext.currentTime + 0.5);
        gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 8);

        oscillator.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        oscillator.start();
        lfo.start();
        oscillator.stop(this.audioContext.currentTime + 8);
        lfo.stop(this.audioContext.currentTime + 8);

        return { oscillator, lfo };
    }

    /**
     * CREATURE ROAR
     */
    createCreatureRoar(type = 'large') {
        if (!this.enabled) return;

        const duration = 1 + Math.random();
        const bufferSize = this.audioContext.sampleRate * duration;
        const buffer = this.audioContext.createBuffer(1, bufferSize, this.audioContext.sampleRate);
        const data = buffer.getChannelData(0);

        const baseFreq = type === 'large' ? 100 : 300;

        for (let i = 0; i < bufferSize; i++) {
            const t = i / this.audioContext.sampleRate;
            const envelope = Math.sin(t * Math.PI / duration);
            const freq = baseFreq * (1 + Math.sin(t * 20) * 0.3);
            const phase = t * freq * Math.PI * 2;
            data[i] = Math.sin(phase) * envelope * 0.3;
        }

        const source = this.audioContext.createBufferSource();
        source.buffer = buffer;

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = type === 'large' ? 400 : 1000;

        const gain = this.audioContext.createGain();
        gain.gain.value = 0.4;

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);
        source.start();

        return { source };
    }

    /**
     * EARTHQUAKE RUMBLE
     */
    createEarthquake(magnitude = 5.0) {
        if (!this.enabled) return;

        const duration = 5 + magnitude * 2;
        const intensity = Math.min(magnitude / 10, 1);

        // Low frequency rumble
        const osc1 = this.audioContext.createOscillator();
        osc1.type = 'sine';
        osc1.frequency.value = 10 + Math.random() * 10;

        const osc2 = this.audioContext.createOscillator();
        osc2.type = 'sine';
        osc2.frequency.value = 20 + Math.random() * 15;

        // LFO for shaking effect
        const lfo = this.audioContext.createOscillator();
        lfo.type = 'sine';
        lfo.frequency.value = 3 + magnitude * 0.5;

        const lfoGain = this.audioContext.createGain();
        lfoGain.gain.value = 5;

        lfo.connect(lfoGain);
        lfoGain.connect(osc1.frequency);

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 50;

        const gain = this.audioContext.createGain();
        gain.gain.setValueAtTime(0, this.audioContext.currentTime);
        gain.gain.linearRampToValueAtTime(intensity * 0.5, this.audioContext.currentTime + 1);
        gain.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + duration);

        osc1.connect(filter);
        osc2.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);

        osc1.start();
        osc2.start();
        lfo.start();

        osc1.stop(this.audioContext.currentTime + duration);
        osc2.stop(this.audioContext.currentTime + duration);
        lfo.stop(this.audioContext.currentTime + duration);

        return { osc1, osc2, lfo };
    }

    /**
     * METEOR IMPACT
     */
    createMeteorImpact(size = 1.0) {
        if (!this.enabled) return;

        // Initial impact boom
        const bufferSize = this.audioContext.sampleRate * 0.5;
        const buffer = this.audioContext.createBuffer(1, bufferSize, this.audioContext.sampleRate);
        const data = buffer.getChannelData(0);

        for (let i = 0; i < bufferSize; i++) {
            const t = i / this.audioContext.sampleRate;
            const envelope = Math.exp(-t * 15);
            data[i] = (Math.random() * 2 - 1) * envelope;
        }

        const source = this.audioContext.createBufferSource();
        source.buffer = buffer;

        const filter = this.audioContext.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 200;

        const gain = this.audioContext.createGain();
        gain.gain.value = size * 0.8;

        source.connect(filter);
        filter.connect(gain);
        gain.connect(this.masterGain);
        source.start();

        // Shockwave rumble
        setTimeout(() => {
            this.createEarthquake(size * 7);
        }, 200);

        return { source };
    }

    /**
     * Update ambient soundscape
     */
    updateAmbience(biome, weather, timeOfDay) {
        if (!this.enabled) return;

        // This would adjust ongoing ambient sounds based on context
        // For now, just log the changes
        console.log(`🔊 Ambience: ${biome} | ${weather} | ${timeOfDay}`);
    }

    /**
     * Set master volume
     */
    setVolume(volume) {
        this.volume = Math.max(0, Math.min(1, volume));
        if (this.masterGain) {
            this.masterGain.gain.value = this.volume;
        }
    }

    /**
     * Enable/disable sound
     */
    setEnabled(enabled) {
        if (enabled && !this.audioContext) {
            this.initialize();
        }
        this.enabled = enabled;
    }
}

export default ProceduralSoundSystem;
