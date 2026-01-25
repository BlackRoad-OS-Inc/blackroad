// Sound Manager for RoadWorld
// Provides audio feedback for game events using Web Audio API

export class SoundManager {
    constructor() {
        this.audioContext = null;
        this.isEnabled = true;
        this.volume = 0.5;
        this.sounds = {};

        // Try to initialize on user interaction
        this.initialized = false;
    }

    init() {
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            this.masterGain = this.audioContext.createGain();
            this.masterGain.connect(this.audioContext.destination);
            this.masterGain.gain.value = this.volume;
            this.initialized = true;
            console.log('🔊 Sound Manager initialized');
        } catch (e) {
            console.warn('Web Audio API not supported:', e);
            this.initialized = false;
        }
    }

    ensureContext() {
        if (!this.initialized) {
            this.init();
        }
        if (this.audioContext && this.audioContext.state === 'suspended') {
            this.audioContext.resume();
        }
    }

    // Generate sounds programmatically (no external files needed)
    generateTone(frequency, duration, type = 'sine', attack = 0.01, decay = 0.1) {
        this.ensureContext();
        if (!this.audioContext) return;

        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(this.masterGain);

        oscillator.frequency.value = frequency;
        oscillator.type = type;

        const now = this.audioContext.currentTime;
        gainNode.gain.setValueAtTime(0, now);
        gainNode.gain.linearRampToValueAtTime(0.3, now + attack);
        gainNode.gain.exponentialRampToValueAtTime(0.01, now + duration);

        oscillator.start(now);
        oscillator.stop(now + duration);
    }

    // Sound effects for different game events
    playCollect(rarity = 'common') {
        if (!this.isEnabled) return;
        this.ensureContext();

        // Different sounds for different rarities
        switch (rarity) {
            case 'common':
                this.generateTone(880, 0.15, 'sine');
                setTimeout(() => this.generateTone(1100, 0.1, 'sine'), 50);
                break;
            case 'rare':
                this.generateTone(660, 0.1, 'sine');
                setTimeout(() => this.generateTone(880, 0.1, 'sine'), 50);
                setTimeout(() => this.generateTone(1100, 0.15, 'sine'), 100);
                break;
            case 'epic':
                this.generateTone(440, 0.1, 'sine');
                setTimeout(() => this.generateTone(660, 0.1, 'sine'), 80);
                setTimeout(() => this.generateTone(880, 0.1, 'sine'), 160);
                setTimeout(() => this.generateTone(1100, 0.2, 'sine'), 240);
                break;
            case 'legendary':
                this.playFanfare();
                break;
        }
    }

    playLevelUp() {
        if (!this.isEnabled) return;
        this.ensureContext();

        // Triumphant ascending notes
        const notes = [523, 659, 784, 1047]; // C5, E5, G5, C6
        notes.forEach((freq, i) => {
            setTimeout(() => this.generateTone(freq, 0.2, 'sine'), i * 100);
        });

        // Add a sustain chord
        setTimeout(() => {
            this.generateTone(523, 0.5, 'sine');
            this.generateTone(659, 0.5, 'sine');
            this.generateTone(784, 0.5, 'sine');
        }, 400);
    }

    playAchievement() {
        if (!this.isEnabled) return;
        this.ensureContext();

        // Achievement unlock sound
        const notes = [392, 494, 587, 784]; // G4, B4, D5, G5
        notes.forEach((freq, i) => {
            setTimeout(() => this.generateTone(freq, 0.15, 'sine'), i * 80);
        });

        setTimeout(() => {
            this.generateTone(784, 0.3, 'triangle');
        }, 350);
    }

    playMissionComplete() {
        if (!this.isEnabled) return;
        this.ensureContext();

        // Mission complete jingle
        const notes = [440, 554, 659, 880]; // A4, C#5, E5, A5
        notes.forEach((freq, i) => {
            setTimeout(() => this.generateTone(freq, 0.12, 'sine'), i * 70);
        });
    }

    playClick() {
        if (!this.isEnabled) return;
        this.ensureContext();

        this.generateTone(800, 0.05, 'sine');
    }

    playMove() {
        if (!this.isEnabled) return;
        this.ensureContext();

        // Subtle movement sound
        this.generateTone(300, 0.08, 'sine');
        setTimeout(() => this.generateTone(350, 0.06, 'sine'), 30);
    }

    playError() {
        if (!this.isEnabled) return;
        this.ensureContext();

        this.generateTone(200, 0.15, 'sawtooth');
        setTimeout(() => this.generateTone(150, 0.2, 'sawtooth'), 100);
    }

    playNotification() {
        if (!this.isEnabled) return;
        this.ensureContext();

        this.generateTone(880, 0.1, 'sine');
        setTimeout(() => this.generateTone(660, 0.15, 'sine'), 100);
    }

    playFanfare() {
        if (!this.isEnabled) return;
        this.ensureContext();

        // Epic fanfare for legendary items
        const melody = [
            { freq: 523, delay: 0, duration: 0.15 },
            { freq: 659, delay: 100, duration: 0.15 },
            { freq: 784, delay: 200, duration: 0.15 },
            { freq: 1047, delay: 300, duration: 0.3 },
            { freq: 880, delay: 500, duration: 0.15 },
            { freq: 1047, delay: 600, duration: 0.4 }
        ];

        melody.forEach(note => {
            setTimeout(() => {
                this.generateTone(note.freq, note.duration, 'sine');
            }, note.delay);
        });
    }

    playAmbient(type = 'explore') {
        if (!this.isEnabled) return;
        this.ensureContext();

        // Ambient pad sounds
        const chords = {
            explore: [261, 329, 392], // C major
            night: [220, 261, 329],   // A minor
            dawn: [293, 369, 440]     // D major
        };

        const chord = chords[type] || chords.explore;

        chord.forEach(freq => {
            const oscillator = this.audioContext.createOscillator();
            const gainNode = this.audioContext.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(this.masterGain);

            oscillator.frequency.value = freq;
            oscillator.type = 'sine';

            const now = this.audioContext.currentTime;
            gainNode.gain.setValueAtTime(0, now);
            gainNode.gain.linearRampToValueAtTime(0.05, now + 1);
            gainNode.gain.linearRampToValueAtTime(0, now + 4);

            oscillator.start(now);
            oscillator.stop(now + 4);
        });
    }

    setVolume(value) {
        this.volume = Math.max(0, Math.min(1, value));
        if (this.masterGain) {
            this.masterGain.gain.value = this.volume;
        }
    }

    toggle() {
        this.isEnabled = !this.isEnabled;
        return this.isEnabled;
    }

    mute() {
        this.isEnabled = false;
    }

    unmute() {
        this.isEnabled = true;
    }
}
