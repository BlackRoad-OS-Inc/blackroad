/**
 * LIVING MUSIC SYSTEM
 *
 * Procedural music generation, nature sounds, and ambient soundscapes!
 * Every biome has its own music, every creature makes sounds,
 * and you can create your own instruments!
 *
 * Philosophy: "MUSIC IS THE LANGUAGE OF THE UNIVERSE"
 */

// ===== MUSIC THEORY =====
export const SCALES = {
    major: [0, 2, 4, 5, 7, 9, 11],           // Happy, bright
    minor: [0, 2, 3, 5, 7, 8, 10],           // Sad, emotional
    pentatonic: [0, 2, 4, 7, 9],             // Asian, peaceful
    blues: [0, 3, 5, 6, 7, 10],              // Soulful, groovy
    harmonic_minor: [0, 2, 3, 5, 7, 8, 11],  // Mystical, exotic
    dorian: [0, 2, 3, 5, 7, 9, 10],          // Jazz, sophisticated
    lydian: [0, 2, 4, 6, 7, 9, 11],          // Dreamy, floating
    phrygian: [0, 1, 3, 5, 7, 8, 10]         // Spanish, dramatic
};

export const CHORDS = {
    major: [0, 4, 7],
    minor: [0, 3, 7],
    diminished: [0, 3, 6],
    augmented: [0, 4, 8],
    major7: [0, 4, 7, 11],
    minor7: [0, 3, 7, 10],
    dominant7: [0, 4, 7, 10],
    suspended: [0, 5, 7]
};

// ===== WEB AUDIO HELPER =====
let audioContext = null;
let masterGain = null;

function initAudio() {
    if (!audioContext) {
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        masterGain = audioContext.createGain();
        masterGain.gain.value = 0.3;
        masterGain.connect(audioContext.destination);
    }
    return audioContext;
}

// ===== PROCEDURAL INSTRUMENT =====
export class Instrument {
    constructor(type = 'sine') {
        this.context = initAudio();
        this.type = type; // 'sine', 'square', 'sawtooth', 'triangle'
        this.envelope = {
            attack: 0.1,
            decay: 0.2,
            sustain: 0.7,
            release: 0.3
        };
    }

    // Convert note name to frequency (e.g., "A4" -> 440Hz)
    noteToFreq(note) {
        const notes = { 'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2 };
        const octave = parseInt(note.slice(-1));
        const noteName = note[0];
        const accidental = note.length > 2 ? (note[1] === '#' ? 1 : -1) : 0;

        const semitones = notes[noteName] + accidental + (octave - 4) * 12;
        return 440 * Math.pow(2, semitones / 12);
    }

    // Play a note with ADSR envelope
    playNote(frequency, duration = 1, volume = 0.5) {
        const now = this.context.currentTime;

        // Create oscillator
        const osc = this.context.createOscillator();
        osc.type = this.type;
        osc.frequency.setValueAtTime(frequency, now);

        // Create gain for envelope
        const gain = this.context.createGain();
        gain.gain.setValueAtTime(0, now);

        // ADSR Envelope
        const { attack, decay, sustain, release } = this.envelope;

        // Attack
        gain.gain.linearRampToValueAtTime(volume, now + attack);

        // Decay
        gain.gain.linearRampToValueAtTime(volume * sustain, now + attack + decay);

        // Sustain (hold)
        const sustainTime = duration - attack - decay - release;

        // Release
        gain.gain.linearRampToValueAtTime(0, now + duration);

        // Connect
        osc.connect(gain);
        gain.connect(masterGain);

        // Play
        osc.start(now);
        osc.stop(now + duration);

        return osc;
    }

    // Play a chord
    playChord(frequencies, duration = 2, volume = 0.3) {
        frequencies.forEach(freq => {
            this.playNote(freq, duration, volume / frequencies.length);
        });
    }
}

// ===== NATURE SOUNDS =====
export class NatureSounds {
    constructor() {
        this.context = initAudio();
        this.activeSounds = [];
    }

    // Rain sound (white noise filtered)
    rain(intensity = 0.5) {
        const bufferSize = this.context.sampleRate * 2;
        const buffer = this.context.createBuffer(1, bufferSize, this.context.sampleRate);
        const data = buffer.getChannelData(0);

        // White noise
        for (let i = 0; i < bufferSize; i++) {
            data[i] = (Math.random() * 2 - 1) * intensity;
        }

        const source = this.context.createBufferSource();
        source.buffer = buffer;
        source.loop = true;

        // Low-pass filter for rain sound
        const filter = this.context.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 1000;
        filter.Q.value = 1;

        const gain = this.context.createGain();
        gain.gain.value = intensity * 0.3;

        source.connect(filter);
        filter.connect(gain);
        gain.connect(masterGain);

        source.start();
        this.activeSounds.push({ source, gain, type: 'rain' });

        return { source, gain };
    }

    // Wind sound (low frequency noise)
    wind(intensity = 0.5) {
        const osc1 = this.context.createOscillator();
        const osc2 = this.context.createOscillator();

        osc1.type = 'sawtooth';
        osc2.type = 'sine';
        osc1.frequency.value = 80 + Math.random() * 40;
        osc2.frequency.value = 120 + Math.random() * 40;

        const filter = this.context.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 300;

        const gain = this.context.createGain();
        gain.gain.value = intensity * 0.2;

        // LFO for wind gusts
        const lfo = this.context.createOscillator();
        lfo.frequency.value = 0.1;
        const lfoGain = this.context.createGain();
        lfoGain.gain.value = intensity * 0.1;

        lfo.connect(lfoGain);
        lfoGain.connect(gain.gain);

        osc1.connect(filter);
        osc2.connect(filter);
        filter.connect(gain);
        gain.connect(masterGain);

        osc1.start();
        osc2.start();
        lfo.start();

        this.activeSounds.push({ source: osc1, gain, type: 'wind' });

        return { source: osc1, gain };
    }

    // Bird chirp
    chirp() {
        const now = this.context.currentTime;
        const osc = this.context.createOscillator();
        osc.type = 'sine';

        // Chirp frequency sweep
        const startFreq = 2000 + Math.random() * 1000;
        const endFreq = startFreq - 500;

        osc.frequency.setValueAtTime(startFreq, now);
        osc.frequency.exponentialRampToValueAtTime(endFreq, now + 0.1);

        const gain = this.context.createGain();
        gain.gain.setValueAtTime(0.3, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.15);

        osc.connect(gain);
        gain.connect(masterGain);

        osc.start(now);
        osc.stop(now + 0.15);
    }

    // Water flowing
    water(intensity = 0.5) {
        const bufferSize = this.context.sampleRate * 2;
        const buffer = this.context.createBuffer(1, bufferSize, this.context.sampleRate);
        const data = buffer.getChannelData(0);

        // Pink-ish noise for water
        for (let i = 0; i < bufferSize; i++) {
            data[i] = (Math.random() * 2 - 1) * intensity * 0.5;
        }

        const source = this.context.createBufferSource();
        source.buffer = buffer;
        source.loop = true;

        // Band-pass filter
        const filter = this.context.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.value = 800;
        filter.Q.value = 0.5;

        const gain = this.context.createGain();
        gain.gain.value = intensity * 0.4;

        source.connect(filter);
        filter.connect(gain);
        gain.connect(masterGain);

        source.start();
        this.activeSounds.push({ source, gain, type: 'water' });

        return { source, gain };
    }

    // Firefly glow sound (gentle pulse)
    fireflyGlow() {
        const now = this.context.currentTime;
        const osc = this.context.createOscillator();
        osc.type = 'sine';
        osc.frequency.value = 800 + Math.random() * 400;

        const gain = this.context.createGain();
        gain.gain.setValueAtTime(0, now);
        gain.gain.linearRampToValueAtTime(0.1, now + 0.3);
        gain.gain.linearRampToValueAtTime(0, now + 0.6);

        osc.connect(gain);
        gain.connect(masterGain);

        osc.start(now);
        osc.stop(now + 0.6);
    }

    stopAll() {
        this.activeSounds.forEach(({ source }) => {
            try {
                source.stop();
            } catch (e) {
                // Already stopped
            }
        });
        this.activeSounds = [];
    }
}

// ===== BIOME SOUNDSCAPES =====
export class BiomeSoundscape {
    constructor(biomeType) {
        this.biomeType = biomeType;
        this.sounds = new NatureSounds();
        this.instrument = new Instrument('sine');
        this.isPlaying = false;
        this.loops = [];
    }

    start() {
        if (this.isPlaying) return;
        this.isPlaying = true;

        switch (this.biomeType) {
            case 'forest':
                this.forestAmbience();
                break;
            case 'ocean':
                this.oceanAmbience();
                break;
            case 'mountains':
                this.mountainAmbience();
                break;
            case 'desert':
                this.desertAmbience();
                break;
            case 'crystal':
                this.crystalAmbience();
                break;
            case 'sky':
                this.skyAmbience();
                break;
        }
    }

    forestAmbience() {
        // Gentle wind
        this.sounds.wind(0.3);

        // Random bird chirps
        const chirpLoop = setInterval(() => {
            if (Math.random() < 0.3) {
                this.sounds.chirp();
            }
        }, 2000);
        this.loops.push(chirpLoop);

        // Ambient music (pentatonic scale)
        const musicLoop = setInterval(() => {
            const scale = SCALES.pentatonic;
            const baseNote = 55; // A2
            const note = baseNote * Math.pow(2, scale[Math.floor(Math.random() * scale.length)] / 12);
            this.instrument.playNote(note, 2, 0.1);
        }, 4000);
        this.loops.push(musicLoop);
    }

    oceanAmbience() {
        // Water flowing
        this.sounds.water(0.6);

        // Whale-like sounds
        const instrument = new Instrument('sine');
        instrument.envelope = { attack: 1, decay: 0.5, sustain: 0.8, release: 2 };

        const whaleLoop = setInterval(() => {
            const freq = 80 + Math.random() * 120;
            instrument.playNote(freq, 5, 0.15);
        }, 8000);
        this.loops.push(whaleLoop);
    }

    mountainAmbience() {
        // Strong wind
        this.sounds.wind(0.7);

        // Echoing notes (lydian mode)
        const instrument = new Instrument('triangle');
        instrument.envelope = { attack: 0.3, decay: 0.4, sustain: 0.6, release: 1.5 };

        const echoLoop = setInterval(() => {
            const scale = SCALES.lydian;
            const baseNote = 220; // A3
            const note = baseNote * Math.pow(2, scale[Math.floor(Math.random() * scale.length)] / 12);
            instrument.playNote(note, 3, 0.12);
        }, 5000);
        this.loops.push(echoLoop);
    }

    desertAmbience() {
        // Light wind
        this.sounds.wind(0.4);

        // Sparse, exotic notes (phrygian scale)
        const instrument = new Instrument('sawtooth');
        instrument.envelope = { attack: 0.2, decay: 0.3, sustain: 0.5, release: 1 };

        const desertLoop = setInterval(() => {
            const scale = SCALES.phrygian;
            const baseNote = 110; // A2
            const note = baseNote * Math.pow(2, scale[Math.floor(Math.random() * scale.length)] / 12);
            instrument.playNote(note, 2, 0.08);
        }, 6000);
        this.loops.push(desertLoop);
    }

    crystalAmbience() {
        // Crystal chimes (high frequencies)
        const instrument = new Instrument('sine');
        instrument.envelope = { attack: 0.01, decay: 0.1, sustain: 0.3, release: 2 };

        const chimeLoop = setInterval(() => {
            const scale = SCALES.lydian;
            const baseNote = 880; // A5
            const note = baseNote * Math.pow(2, scale[Math.floor(Math.random() * scale.length)] / 12);
            instrument.playNote(note, 3, 0.15);

            // Firefly glow sound
            if (Math.random() < 0.5) {
                setTimeout(() => this.sounds.fireflyGlow(), Math.random() * 1000);
            }
        }, 3000);
        this.loops.push(chimeLoop);
    }

    skyAmbience() {
        // Gentle wind
        this.sounds.wind(0.5);

        // Floating, dreamy notes (major scale)
        const instrument = new Instrument('triangle');
        instrument.envelope = { attack: 0.5, decay: 0.3, sustain: 0.8, release: 2 };

        const skyLoop = setInterval(() => {
            const scale = SCALES.major;
            const baseNote = 440; // A4
            const note = baseNote * Math.pow(2, scale[Math.floor(Math.random() * scale.length)] / 12);
            instrument.playNote(note, 4, 0.1);
        }, 4500);
        this.loops.push(skyLoop);
    }

    stop() {
        this.isPlaying = false;
        this.sounds.stopAll();
        this.loops.forEach(loop => clearInterval(loop));
        this.loops = [];
    }
}

// ===== PROCEDURAL MELODY GENERATOR =====
export class MelodyGenerator {
    constructor(scale = 'pentatonic', tempo = 120) {
        this.scale = SCALES[scale];
        this.tempo = tempo;
        this.instrument = new Instrument('sine');
        this.baseNote = 440; // A4
    }

    // Generate a random melody
    generateMelody(length = 8) {
        const melody = [];
        let lastNote = 0;

        for (let i = 0; i < length; i++) {
            // Prefer steps (nearby notes) over jumps
            const step = Math.random() < 0.7 ?
                (Math.random() < 0.5 ? -1 : 1) :
                Math.floor(Math.random() * this.scale.length);

            let noteIndex = (lastNote + step) % this.scale.length;
            if (noteIndex < 0) noteIndex += this.scale.length;

            const semitones = this.scale[noteIndex];
            const frequency = this.baseNote * Math.pow(2, semitones / 12);

            melody.push({
                frequency,
                duration: 60 / this.tempo, // Quarter note
                noteIndex
            });

            lastNote = noteIndex;
        }

        return melody;
    }

    // Play a melody
    playMelody(melody, loop = false) {
        let time = 0;

        const play = () => {
            melody.forEach(({ frequency, duration }, i) => {
                setTimeout(() => {
                    this.instrument.playNote(frequency, duration * 0.8, 0.2);
                }, time * 1000);
                time += duration;
            });

            if (loop) {
                setTimeout(play, time * 1000);
            }
        };

        play();
    }
}

// ===== MUSIC MANAGER =====
export class MusicManager {
    constructor() {
        this.currentSoundscape = null;
        this.natureSounds = new NatureSounds();
        this.volume = 0.3;
    }

    setBiome(biomeType) {
        if (this.currentSoundscape) {
            this.currentSoundscape.stop();
        }

        this.currentSoundscape = new BiomeSoundscape(biomeType);
        this.currentSoundscape.start();
    }

    playAnimalSound(animalType) {
        switch (animalType) {
            case 'bird':
                this.natureSounds.chirp();
                break;
            case 'butterfly':
            case 'bee':
                this.natureSounds.fireflyGlow();
                break;
        }
    }

    setVolume(volume) {
        this.volume = Math.max(0, Math.min(1, volume));
        if (masterGain) {
            masterGain.gain.value = this.volume;
        }
    }

    stop() {
        if (this.currentSoundscape) {
            this.currentSoundscape.stop();
        }
        this.natureSounds.stopAll();
    }
}

export default MusicManager;
