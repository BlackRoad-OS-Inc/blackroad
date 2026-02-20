#!/usr/bin/env python3
"""
BlackRoad Conductor ML - Drumstick Intelligence System

Captures every MIDI event, logs to structured files, learns your patterns
in real-time using unsupervised ML, and predicts what you'll play next.

Features:
  - Full MIDI event logging (JSONL + SQLite)
  - Real-time BPM, velocity dynamics, zone heatmaps
  - Feature extraction: inter-onset intervals, velocity curves, note sequences
  - KMeans clustering of rhythmic phrases
  - Markov chain for next-note prediction
  - Anomaly detection (unusual patterns)
  - Session comparison (how today differs from past sessions)
  - Drum sound synthesis through speakers
  - GitHub command dispatch on recognized patterns

Data stored in: ~/.blackroad/conductor/
"""

import mido
import sounddevice as sd
import numpy as np
import sys
import os
import json
import time
import threading
import sqlite3
import signal
from collections import deque, Counter, defaultdict
from datetime import datetime
import math

# ML
from sklearn.cluster import KMeans, DBSCAN
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
import subprocess

# ══════════════════════════════════════════════════════════════
#  CONFIG
# ══════════════════════════════════════════════════════════════
SAMPLE_RATE = 48000
AUDIO_DEVICE = 2
DATA_DIR = os.path.expanduser("~/.blackroad/conductor")
DB_PATH = os.path.join(DATA_DIR, "conductor.db")
LOG_PATH = os.path.join(DATA_DIR, "events.jsonl")

# Ensure data dir
os.makedirs(DATA_DIR, exist_ok=True)

# Colors
RESET  = "\033[0m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
PINK   = "\033[38;5;205m"
AMBER  = "\033[38;5;214m"
BLUE   = "\033[38;5;69m"
VIOLET = "\033[38;5;135m"
GREEN  = "\033[38;5;82m"
CYAN   = "\033[38;5;87m"
WHITE  = "\033[1;37m"
RED    = "\033[38;5;196m"
GRAY   = "\033[38;5;240m"
YELLOW = "\033[38;5;220m"

# ── Tenor Quads Mode ──
# Aerband sticks have unstable zone detection — one stick hitting the same
# spot sends different MIDI notes. We can only reliably detect LEFT vs RIGHT.
#
# Mapping (stick-based, not zone-based):
#   Left stick  → Drum 1 (highest, 220 Hz) — always, any velocity
#   Right stick → Drum 2 (mid-high, 170 Hz) — always, any velocity
#   Stomp/kick  → Drum 3 (mid-low, 130 Hz)
#   Both sticks together (within 30ms) → Drum 4 (lowest, 95 Hz)
#
# Velocity only controls VOLUME, not which drum.
#
LEFT_STICK_NOTES  = {38, 42, 44, 46, 48, 50, 37, 39, 40}
RIGHT_STICK_NOTES = {47, 49, 51, 53, 52, 55, 57, 43, 45, 41}
KICK_NOTES        = {36, 35}

NOTE_MAP = {
    1: {"name": "DRUM-1",  "short": "D1", "color": CYAN,   "zone": "L"},
    2: {"name": "DRUM-2",  "short": "D2", "color": BLUE,   "zone": "L"},
    3: {"name": "DRUM-3",  "short": "D3", "color": VIOLET, "zone": "R"},
    4: {"name": "DRUM-4",  "short": "D4", "color": PINK,   "zone": "R"},
}

def note_info(note):
    return NOTE_MAP.get(note, {"name": f"N{note}", "short": f"{note:2}", "color": GRAY, "zone": "?"})


# ══════════════════════════════════════════════════════════════
#  DATABASE
# ══════════════════════════════════════════════════════════════
def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""CREATE TABLE IF NOT EXISTS hits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        timestamp REAL,
        note INTEGER,
        velocity INTEGER,
        note_name TEXT,
        zone TEXT,
        ioi REAL,
        bpm REAL
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS sessions (
        session_id TEXT PRIMARY KEY,
        start_time REAL,
        end_time REAL,
        total_hits INTEGER,
        avg_velocity REAL,
        avg_bpm REAL,
        dominant_note INTEGER,
        notes_json TEXT
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS patterns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        timestamp REAL,
        pattern_notes TEXT,
        pattern_velocities TEXT,
        pattern_iois TEXT,
        cluster_id INTEGER,
        label TEXT
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        timestamp REAL,
        predicted_note INTEGER,
        actual_note INTEGER,
        correct INTEGER
    )""")
    c.execute("""CREATE TABLE IF NOT EXISTS gestures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        timestamp REAL,
        gesture_type TEXT,
        label TEXT,
        action TEXT
    )""")
    # Self-improving brain table
    c.execute("""CREATE TABLE IF NOT EXISTS brain (
        key TEXT PRIMARY KEY,
        value REAL,
        updated_at REAL
    )""")
    # Improvement log — tracks how the system changes itself
    c.execute("""CREATE TABLE IF NOT EXISTS improvements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        timestamp REAL,
        system TEXT,
        param TEXT,
        old_value REAL,
        new_value REAL,
        reason TEXT
    )""")
    conn.commit()
    return conn


# ══════════════════════════════════════════════════════════════
#  SELF-IMPROVING BRAIN
# ══════════════════════════════════════════════════════════════

class Brain:
    """Cross-session self-improving system.

    Learns from your playing and auto-tunes:
    1. Ghost filter thresholds (debounce, velocity floor)
    2. Drum sound richness (evolves with XP/level)
    3. Prediction confidence weighting
    4. Combo timing tolerance
    """

    def __init__(self, db):
        self.db = db
        self.params = {}
        self.improvements_this_session = []
        self._load()

    def _load(self):
        """Load learned parameters from DB."""
        try:
            c = self.db.cursor()
            c.execute("SELECT key, value FROM brain")
            for key, value in c.fetchall():
                self.params[key] = value
        except Exception:
            pass

    def get(self, key, default=0.0):
        return self.params.get(key, default)

    def _set(self, key, value, session_id="", reason=""):
        old = self.params.get(key, None)
        self.params[key] = value
        now = time.time()
        try:
            c = self.db.cursor()
            c.execute("INSERT OR REPLACE INTO brain (key, value, updated_at) VALUES (?,?,?)",
                      (key, value, now))
            if old is not None and old != value:
                c.execute("INSERT INTO improvements (session_id,timestamp,system,param,old_value,new_value,reason) VALUES (?,?,?,?,?,?,?)",
                          (session_id, now, key.split(".")[0], key, old, value, reason))
                self.improvements_this_session.append((key, old, value, reason))
            self.db.commit()
        except Exception:
            pass

    # ── Ghost filter auto-tuning ──

    def learn_timing(self, iois, session_id=""):
        """Analyze real IOIs to auto-tune debounce thresholds."""
        if len(iois) < 30:
            return

        arr = np.array([x for x in iois if x > 0])
        if len(arr) < 20:
            return

        arr_ms = arr * 1000

        # Find the natural gap between real hits vs ghosts
        # Real hits are usually > 50ms apart, ghosts < 30ms
        real_hits = arr_ms[arr_ms > 40]
        if len(real_hits) < 10:
            return

        # Minimum real IOI = 5th percentile of real hits
        min_real_ioi = np.percentile(real_hits, 5)

        # Optimal debounce = halfway between ghost range and real range
        optimal_debounce = max(15, min(min_real_ioi * 0.6, 50))
        current_debounce = self.get("filter.debounce_ms", 35)

        if abs(optimal_debounce - current_debounce) > 3:
            self._set("filter.debounce_ms", round(optimal_debounce, 1), session_id,
                      f"5th%ile IOI={min_real_ioi:.0f}ms → debounce={optimal_debounce:.0f}ms")

        # Learn velocity floor from ghost distribution
        ghost_hits = arr_ms[arr_ms <= 40]
        if len(ghost_hits) > 5:
            # Count how many passed with low velocity — this is our ghost sig
            sessions_played = self.get("stats.sessions", 0)
            if sessions_played > 2:
                # After enough sessions, tighten the velocity floor
                optimal_vel_floor = min(25, 15 + sessions_played)
                current_floor = self.get("filter.min_velocity", 20)
                if optimal_vel_floor != current_floor:
                    self._set("filter.min_velocity", optimal_vel_floor, session_id,
                              f"Session #{sessions_played}: vel floor → {optimal_vel_floor}")

    # ── Sound evolution ──

    @property
    def sound_level(self):
        """Sound richness level based on total XP earned across all sessions."""
        total_xp = self.get("stats.total_xp", 0)
        if total_xp >= 10000: return 5   # legendary
        if total_xp >= 5000: return 4    # epic
        if total_xp >= 2000: return 3    # rich
        if total_xp >= 500: return 2     # warm
        if total_xp >= 100: return 1     # developing
        return 0                          # basic

    def evolve_sounds(self, session_id=""):
        """Evolve drum sounds based on total play history."""
        level = self.sound_level
        old_level = self.get("sound.level", 0)
        if level > old_level:
            self._set("sound.level", level, session_id,
                      f"Sound evolved: level {old_level} → {level}")
            return True
        return False

    # ── Prediction improvement ──

    def learn_predictions(self, correct, total, session_id=""):
        """Track prediction accuracy improvement over sessions."""
        if total < 5:
            return

        accuracy = correct / total
        prev_accuracy = self.get("predict.best_accuracy", 0)
        lifetime_correct = self.get("predict.lifetime_correct", 0) + correct
        lifetime_total = self.get("predict.lifetime_total", 0) + total

        self._set("predict.lifetime_correct", lifetime_correct, session_id, "")
        self._set("predict.lifetime_total", lifetime_total, session_id, "")

        if accuracy > prev_accuracy:
            self._set("predict.best_accuracy", accuracy, session_id,
                      f"New best: {accuracy*100:.1f}% (was {prev_accuracy*100:.1f}%)")

    # ── Session tracking ──

    def start_session(self, session_id):
        sessions = self.get("stats.sessions", 0) + 1
        self._set("stats.sessions", sessions, session_id, f"Session #{sessions}")
        total_hits = self.get("stats.total_hits", 0)
        return {"session_num": sessions, "total_hits": total_hits, "sound_level": self.sound_level}

    def end_session(self, session_id, hits, xp_earned, iois):
        total_hits = self.get("stats.total_hits", 0) + hits
        total_xp = self.get("stats.total_xp", 0) + xp_earned
        self._set("stats.total_hits", total_hits, session_id, f"+{hits} hits = {total_hits}")
        self._set("stats.total_xp", total_xp, session_id, f"+{xp_earned} XP = {total_xp}")

        # Auto-tune filter
        self.learn_timing(iois, session_id)

        # Check sound evolution
        self.evolve_sounds(session_id)

    def improvement_report(self):
        """Generate report of all self-improvements this session."""
        if not self.improvements_this_session:
            return None
        lines = []
        for key, old, new, reason in self.improvements_this_session:
            if reason:
                lines.append(f"  {key}: {old} → {new} ({reason})")
        return lines


# ══════════════════════════════════════════════════════════════
#  AUDIO SYNTHESIS — evolving drum models
# ══════════════════════════════════════════════════════════════

def _env(t, attack=0.001, decay=0.1):
    """Attack-decay envelope."""
    a = np.minimum(t / max(attack, 1e-6), 1.0)
    d = np.exp(-t / max(decay, 1e-6))
    return a * d

def synth_kick(v):
    """808-style kick: pitch sweep 160→45 Hz, sub-bass body, short click transient."""
    a = (v / 127) * 0.9
    dur = 0.25
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Pitch sweep — fast exponential drop
    freq = 45 + 115 * np.exp(-t * 28)
    phase = np.cumsum(freq / SAMPLE_RATE) * 2 * np.pi
    # Main body — saturated sine
    body = np.tanh(1.8 * np.sin(phase)) * _env(t, 0.001, 0.12)
    # Sub layer for weight
    sub = 0.5 * np.sin(2 * np.pi * 45 * t) * _env(t, 0.002, 0.15)
    # Click transient
    click_n = int(SAMPLE_RATE * 0.004)
    click = np.zeros(n)
    click[:click_n] = 0.8 * np.random.randn(click_n) * np.exp(-np.linspace(0, 12, click_n))
    return (a * (body + sub + click)).astype(np.float32)

def synth_snare(v):
    """Layered snare: 200 Hz body + 160 Hz harmonic + bandpassed noise for wires."""
    a = (v / 127) * 0.75
    dur = 0.18
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Tonal body — two sine components with pitch drop
    body1 = np.sin(2 * np.pi * 200 * t) * _env(t, 0.0005, 0.04)
    body2 = 0.6 * np.sin(2 * np.pi * 160 * t) * _env(t, 0.0005, 0.035)
    # Noise layer — filtered for snare wire character
    noise = np.random.randn(n)
    # Simple high-pass: difference filter for brightness
    noise_hp = np.diff(np.concatenate([[0], noise])) * 0.7
    wires = noise_hp * _env(t, 0.0005, 0.09)
    # Transient snap
    snap_n = int(SAMPLE_RATE * 0.003)
    snap = np.zeros(n)
    snap[:snap_n] = np.random.randn(snap_n) * np.exp(-np.linspace(0, 8, snap_n))
    return (a * (0.45 * body1 + 0.3 * body2 + 0.55 * wires + 0.4 * snap)).astype(np.float32)

def synth_hihat(v):
    """Hi-hat: layered metallic noise with ring frequencies."""
    a = (v / 127) * 0.45
    dur = 0.07
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Metallic noise — bandpass character from summed high-freq sines
    w = np.random.randn(n) * 0.4
    for f in [3700, 5200, 7400, 9800, 12500]:
        w += 0.15 * np.sin(2 * np.pi * f * t + np.random.rand() * 6.28)
    # Sharp envelope
    env = _env(t, 0.0003, 0.018)
    return (a * w * env).astype(np.float32)

def synth_hihat_open(v):
    """Open hi-hat: longer decay, more ring."""
    a = (v / 127) * 0.4
    dur = 0.25
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    w = np.random.randn(n) * 0.35
    for f in [3700, 5200, 7400, 9800]:
        w += 0.18 * np.sin(2 * np.pi * f * t + np.random.rand() * 6.28)
    env = _env(t, 0.0005, 0.12)
    return (a * w * env).astype(np.float32)

def synth_tom(v, hz=120, evo=0):
    """Evolving marching tenor tom. Sound richness grows with evo level (0-5).

    Level 0: Basic sine + click (starter sound)
    Level 1: Add warmth (2nd harmonic stronger)
    Level 2: Add body (slight saturation)
    Level 3: Add resonance (longer sustain, 3rd harmonic)
    Level 4: Add presence (sub-octave, fuller body)
    Level 5: Legendary — full overtone series, rich sustain, chest-thump sub
    """
    a = 0.45 + (v / 127) * 0.45  # consistent volume, never silent

    # Duration grows with level — richer sounds ring longer
    dur = 0.12 + evo * 0.025  # 0.12s → 0.245s at level 5
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)

    # Pitch sweep
    sweep = 0.3 + evo * 0.04  # more dramatic sweep at higher levels
    freq = hz + hz * sweep * np.exp(-t * 25)
    phase = np.cumsum(freq / SAMPLE_RATE) * 2 * np.pi

    # ── Level 0: Basic sine ──
    body = np.sin(phase) * _env(t, 0.0005, 0.05 + evo * 0.015)

    # ── Level 1+: Warmer 2nd harmonic ──
    harm2 = (0.15 + min(evo, 5) * 0.06) * np.sin(phase * 2.0) * _env(t, 0.0005, 0.04 + evo * 0.01)

    # ── Level 2+: Saturation for body ──
    if evo >= 2:
        body = np.tanh((1.0 + evo * 0.15) * body) * 0.85

    # ── Level 3+: 3rd harmonic for ring ──
    harm3 = 0.0
    if evo >= 3:
        harm3 = 0.08 * (evo - 2) * np.sin(phase * 3.01) * _env(t, 0.001, 0.03 + evo * 0.008)

    # ── Level 4+: Sub-octave for chest thump ──
    sub = 0.0
    if evo >= 4:
        sub = 0.15 * (evo - 3) * np.sin(phase * 0.5) * _env(t, 0.002, 0.06)

    # ── Level 5: Overtone shimmer ──
    shimmer = 0.0
    if evo >= 5:
        shimmer = 0.04 * np.sin(phase * 4.02) * _env(t, 0.001, 0.02)
        shimmer += 0.02 * np.sin(phase * 5.03) * _env(t, 0.001, 0.015)

    # Click transient (deterministic, always present)
    click_n = int(SAMPLE_RATE * 0.003)
    click = np.zeros(n)
    click_t = np.linspace(0, 1, click_n)
    click[:click_n] = 0.6 * np.sin(2 * np.pi * 1500 * click_t) * np.exp(-click_t * 8)

    w = body + harm2 + click
    if evo >= 3: w = w + harm3
    if evo >= 4: w = w + sub
    if evo >= 5: w = w + shimmer

    return (a * w).astype(np.float32)

def synth_crash(v):
    """Crash cymbal: long noisy wash with metallic shimmer."""
    a = (v / 127) * 0.35
    dur = 1.0
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Noise wash
    w = np.random.randn(n) * 0.3
    # Metallic partials — detuned for shimmer
    for f in [2100, 2800, 3900, 5300, 6700, 8900, 11200]:
        w += 0.08 * np.sin(2 * np.pi * f * (1 + 0.002 * np.sin(2*np.pi*0.5*t)) * t
                           + np.random.rand() * 6.28)
    # Two-stage decay: fast initial, slow tail
    env = 0.6 * np.exp(-t * 6) + 0.4 * np.exp(-t * 1.5)
    # Transient
    trans_n = int(SAMPLE_RATE * 0.008)
    trans = np.zeros(n)
    trans[:trans_n] = 0.7 * np.random.randn(trans_n) * np.exp(-np.linspace(0, 6, trans_n))
    return (a * (w * env + trans)).astype(np.float32)

def synth_ride(v):
    """Ride cymbal: clear bell with controlled wash."""
    a = (v / 127) * 0.32
    dur = 0.5
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Bell — clear ping
    bell = 0.4 * np.sin(2 * np.pi * 2800 * t) * _env(t, 0.0005, 0.15)
    bell += 0.2 * np.sin(2 * np.pi * 5600 * t) * _env(t, 0.0005, 0.08)
    # Wash
    w = np.random.randn(n) * 0.15
    for f in [3200, 5800, 8500]:
        w += 0.1 * np.sin(2 * np.pi * f * t + np.random.rand() * 6.28)
    wash = w * _env(t, 0.001, 0.2)
    # Stick click
    click_n = int(SAMPLE_RATE * 0.003)
    click = np.zeros(n)
    click[:click_n] = 0.5 * np.random.randn(click_n) * np.exp(-np.linspace(0, 10, click_n))
    return (a * (bell + wash + click)).astype(np.float32)

def synth_ride_bell(v):
    """Ride bell: brighter, more ping, less wash."""
    a = (v / 127) * 0.35
    dur = 0.4
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    bell = 0.6 * np.sin(2 * np.pi * 3200 * t) * _env(t, 0.0003, 0.12)
    bell += 0.35 * np.sin(2 * np.pi * 6400 * t) * _env(t, 0.0003, 0.06)
    bell += 0.15 * np.sin(2 * np.pi * 9600 * t) * _env(t, 0.0003, 0.03)
    click_n = int(SAMPLE_RATE * 0.002)
    click = np.zeros(n)
    click[:click_n] = 0.6 * np.random.randn(click_n) * np.exp(-np.linspace(0, 12, click_n))
    return (a * (bell + click)).astype(np.float32)

# ── Instrument Voices ──
_sound_evo = 0  # set by main() from Brain

def synth_piano(v, hz=262):
    """Piano note: decaying sine with harmonics, velocity-sensitive."""
    a = 0.3 + (v / 127) * 0.6
    dur = 0.8 + _sound_evo * 0.15  # longer sustain as sound evolves
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Fundamental
    w = np.sin(2 * np.pi * hz * t) * _env(t, 0.001, 0.35 + _sound_evo * 0.05)
    # 2nd harmonic (octave)
    w += 0.3 * np.sin(2 * np.pi * hz * 2 * t) * _env(t, 0.001, 0.20)
    # 3rd harmonic (adds brightness)
    w += 0.12 * np.sin(2 * np.pi * hz * 3 * t) * _env(t, 0.001, 0.12)
    # 4th harmonic (richness at higher evo)
    if _sound_evo >= 2:
        w += 0.06 * np.sin(2 * np.pi * hz * 4 * t) * _env(t, 0.001, 0.08)
    # 5th+ at legendary
    if _sound_evo >= 4:
        w += 0.03 * np.sin(2 * np.pi * hz * 5 * t) * _env(t, 0.001, 0.05)
    # Hammer strike transient
    strike_n = int(SAMPLE_RATE * 0.004)
    strike = np.zeros(n)
    strike_t = np.linspace(0, 1, strike_n)
    strike[:strike_n] = 0.4 * np.sin(2 * np.pi * 3000 * strike_t) * np.exp(-strike_t * 12)
    return (a * (w + strike)).astype(np.float32)

# Voice banks — each is a set of 4 sounds
VOICE_BANKS = {
    "piano": {
        "name": "Piano",
        "icon": "🎹",
        "map": lambda: {
            1: lambda v: synth_piano(v, 523),   # C5
            2: lambda v: synth_piano(v, 392),   # G4
            3: lambda v: synth_piano(v, 330),   # E4
            4: lambda v: synth_piano(v, 262),   # C4
        },
    },
    "drums": {
        "name": "Tenor Quads",
        "icon": "🥁",
        "map": lambda: {
            1: lambda v: synth_tom(v, 220, _sound_evo),
            2: lambda v: synth_tom(v, 170, _sound_evo),
            3: lambda v: synth_tom(v, 130, _sound_evo),
            4: lambda v: synth_tom(v, 95,  _sound_evo),
        },
    },
    "bells": {
        "name": "Bells",
        "icon": "🔔",
        "map": lambda: {
            1: lambda v: synth_piano(v, 1047),  # C6
            2: lambda v: synth_piano(v, 880),   # A5
            3: lambda v: synth_piano(v, 698),   # F5
            4: lambda v: synth_piano(v, 523),   # C5
        },
    },
    "bass": {
        "name": "Bass",
        "icon": "🎸",
        "map": lambda: {
            1: lambda v: synth_tom(v, 110, _sound_evo),  # A2
            2: lambda v: synth_tom(v, 82,  _sound_evo),  # E2
            3: lambda v: synth_tom(v, 65,  _sound_evo),  # C2
            4: lambda v: synth_tom(v, 55,  _sound_evo),  # A1
        },
    },
}

VOICE_ORDER = ["piano", "drums", "bells", "bass"]
_current_voice = "piano"

def _make_synth_map():
    return VOICE_BANKS[_current_voice]["map"]()

def cycle_voice(direction=1):
    """Cycle through voice banks."""
    global _current_voice, SYNTH_MAP
    idx = VOICE_ORDER.index(_current_voice)
    idx = (idx + direction) % len(VOICE_ORDER)
    _current_voice = VOICE_ORDER[idx]
    SYNTH_MAP = _make_synth_map()
    bank = VOICE_BANKS[_current_voice]
    return bank

SYNTH_MAP = _make_synth_map()


# ══════════════════════════════════════════════════════════════
#  MIDI FILTER — debounce + ghost note suppression
# ══════════════════════════════════════════════════════════════

class MidiFilter:
    """Cleans up Aerband air drumstick MIDI quirks.

    Problems solved:
    1. Ghost double-triggers: sticks fire 2-3 notes within 1-5ms on a single hit.
       Fix: per-note debounce window — suppress same note within DEBOUNCE_MS.
    2. Cross-talk: one hit bleeds into adjacent zones (e.g. tom-hi + ride).
       Fix: global debounce — any note within GLOBAL_MS of a louder note gets dropped.
    3. Velocity spikes: ghost hits often have very low velocity.
       Fix: suppress hits under MIN_VELOCITY.
    """

    DEBOUNCE_MS = 35      # Same-note minimum gap
    GLOBAL_MS = 20        # Any-note minimum gap (keeps loudest)
    MIN_VELOCITY = 20     # Below this = ghost hit

    def __init__(self):
        self.last_note_time = {}   # note → timestamp
        self.last_note_vel = {}    # note → velocity
        self.last_any_time = 0.0
        self.last_any_vel = 0
        self.last_any_note = 0
        self.suppressed = 0
        self.passed = 0

    def accept(self, note, velocity, now=None):
        """Returns True if this hit should be processed, False if it's a ghost."""
        if now is None:
            now = time.time()

        # 1. Velocity floor
        if velocity < self.MIN_VELOCITY:
            self.suppressed += 1
            return False

        # 2. Per-note debounce
        prev_t = self.last_note_time.get(note, 0)
        gap_ms = (now - prev_t) * 1000
        if gap_ms < self.DEBOUNCE_MS:
            # Keep the louder one
            if velocity <= self.last_note_vel.get(note, 0):
                self.suppressed += 1
                return False

        # 3. Global cross-talk debounce
        global_gap_ms = (now - self.last_any_time) * 1000
        if global_gap_ms < self.GLOBAL_MS and note != self.last_any_note:
            # Two different notes within 20ms = cross-talk, keep louder
            if velocity < self.last_any_vel:
                self.suppressed += 1
                return False

        # Accept this hit
        self.last_note_time[note] = now
        self.last_note_vel[note] = velocity
        self.last_any_time = now
        self.last_any_vel = velocity
        self.last_any_note = note
        self.passed += 1
        return True

class AudioMixer:
    """Persistent audio stream that mixes sounds without opening new PortAudio streams."""

    def __init__(self, sr=SAMPLE_RATE, device=AUDIO_DEVICE, buffer_len=2.0):
        self.sr = sr
        self.buffer_size = int(sr * buffer_len)
        self.buffer = np.zeros(self.buffer_size, dtype=np.float32)
        self.write_pos = 0
        self.lock = threading.Lock()
        self.stream = None
        try:
            self.stream = sd.OutputStream(
                samplerate=sr, channels=1, dtype='float32',
                device=device, blocksize=1024,
                callback=self._callback
            )
            self.stream.start()
        except Exception:
            pass  # audio unavailable — MIDI still works

    def _callback(self, outdata, frames, time_info, status):
        with self.lock:
            end = self.write_pos + frames
            if end <= self.buffer_size:
                outdata[:, 0] = self.buffer[self.write_pos:end]
                self.buffer[self.write_pos:end] = 0
            else:
                first = self.buffer_size - self.write_pos
                outdata[:first, 0] = self.buffer[self.write_pos:]
                outdata[first:, 0] = self.buffer[:frames - first]
                self.buffer[self.write_pos:] = 0
                self.buffer[:frames - first] = 0
            self.write_pos = end % self.buffer_size

    def play(self, note, vel):
        fn = SYNTH_MAP.get(note)
        if fn and self.stream:
            try:
                audio = fn(vel)
                with self.lock:
                    n = len(audio)
                    pos = self.write_pos
                    end = pos + n
                    if end <= self.buffer_size:
                        self.buffer[pos:end] += audio
                    else:
                        first = self.buffer_size - pos
                        self.buffer[pos:] += audio[:first]
                        self.buffer[:n - first] += audio[first:]
            except Exception:
                pass

    def close(self):
        if self.stream:
            try:
                self.stream.stop()
                self.stream.close()
            except Exception:
                pass

# Global mixer (initialized in main)
_mixer = None

_current_drum = 1  # start on Drum 1

def remap_note(midi_note, velocity=64):
    """All stick hits → current drum. Stomp → Drum 3. Cycle drum with stomp+hit."""
    if midi_note in KICK_NOTES:
        return 3
    return _current_drum

def cycle_drum(direction=1):
    """Cycle to next/prev drum (1,2,4 — skip 3 which is stomp)."""
    global _current_drum
    order = [1, 2, 4]
    idx = order.index(_current_drum) if _current_drum in order else 0
    idx = (idx + direction) % len(order)
    _current_drum = order[idx]
    return _current_drum

def play_sound(note, vel):
    """Play sound for a quad drum number (1-4)."""
    if _mixer:
        _mixer.play(note, vel)


# ══════════════════════════════════════════════════════════════
#  ML: FEATURE EXTRACTION
# ══════════════════════════════════════════════════════════════
class FeatureExtractor:
    """Extract rhythmic features from a window of hits."""

    @staticmethod
    def extract_phrase(notes, velocities, iois):
        """Extract feature vector from a phrase (window of 4-8 hits)."""
        if len(notes) < 2:
            return None

        features = {}

        # Timing features
        features["mean_ioi"] = np.mean(iois) if iois else 0
        features["std_ioi"] = np.std(iois) if iois else 0
        features["min_ioi"] = np.min(iois) if iois else 0
        features["max_ioi"] = np.max(iois) if iois else 0
        features["ioi_range"] = features["max_ioi"] - features["min_ioi"]

        # Velocity features
        features["mean_vel"] = np.mean(velocities)
        features["std_vel"] = np.std(velocities)
        features["vel_trend"] = np.polyfit(range(len(velocities)), velocities, 1)[0] if len(velocities) > 1 else 0  # crescendo/decrescendo slope
        features["max_vel"] = np.max(velocities)
        features["min_vel"] = np.min(velocities)
        features["dynamic_range"] = features["max_vel"] - features["min_vel"]

        # Note diversity
        unique_notes = set(notes)
        features["n_unique_notes"] = len(unique_notes)
        features["note_entropy"] = -sum((c/len(notes))*np.log2(c/len(notes))
                                        for c in Counter(notes).values()) if len(notes) > 1 else 0

        # Zone distribution
        zones = [note_info(n)["zone"] for n in notes]
        zone_counts = Counter(zones)
        total = len(zones)
        for z in ["L", "R", "C", "D", "X"]:
            features[f"zone_{z}_pct"] = zone_counts.get(z, 0) / total

        # Rhythmic regularity (coefficient of variation of IOIs)
        features["rhythm_regularity"] = features["std_ioi"] / features["mean_ioi"] if features["mean_ioi"] > 0 else 0

        # Hand alternation ratio
        hands = []
        for n in notes:
            info = note_info(n)
            z = info["zone"]
            if z in ("L",): hands.append("L")
            elif z in ("R",): hands.append("R")
            else: hands.append("B")  # both/center
        alternations = sum(1 for i in range(1, len(hands)) if hands[i] != hands[i-1])
        features["alternation_ratio"] = alternations / max(len(hands)-1, 1)

        # Has kick, has snare, has hihat
        features["has_kick"] = 1.0 if any(n in (35,36) for n in notes) else 0.0
        features["has_snare"] = 1.0 if any(n in (37,38,39,40) for n in notes) else 0.0
        features["has_hihat"] = 1.0 if any(n in (42,44,46) for n in notes) else 0.0
        features["has_cymbal"] = 1.0 if any(n in (49,51,52,53,55,57) for n in notes) else 0.0

        return features


# ══════════════════════════════════════════════════════════════
#  ML: PATTERN LEARNER
# ══════════════════════════════════════════════════════════════
class PatternLearner:
    """Learns and clusters rhythmic patterns in real-time."""

    def __init__(self, db):
        self.db = db
        self.scaler = StandardScaler()
        self.kmeans = None
        self.feature_names = None
        self.phrases = []  # list of feature dicts
        self.phrase_meta = []  # list of (notes, vels, iois) for each phrase
        self.cluster_labels = {}  # cluster_id → human label
        self.n_clusters = 5
        self.fitted = False
        self.min_phrases_to_fit = 10

        # Markov chain for prediction
        self.transitions = defaultdict(Counter)  # note → {next_note: count}
        self.total_transitions = defaultdict(int)

        # Anomaly detection
        self.anomaly_threshold = 2.0  # std deviations from cluster center

        # Load existing data
        self._load_history()

    def _load_history(self):
        """Load past patterns from DB to warm-start the model."""
        try:
            c = self.db.cursor()
            c.execute("SELECT pattern_notes, pattern_velocities, pattern_iois FROM patterns ORDER BY id DESC LIMIT 500")
            rows = c.fetchall()
            for notes_json, vels_json, iois_json in rows:
                notes = json.loads(notes_json)
                vels = json.loads(vels_json)
                iois = json.loads(iois_json)
                feats = FeatureExtractor.extract_phrase(notes, vels, iois)
                if feats:
                    self.phrases.append(feats)
                    self.phrase_meta.append((notes, vels, iois))
            if len(self.phrases) >= self.min_phrases_to_fit:
                self._fit()
        except Exception:
            pass

    def _fit(self):
        """Fit KMeans on accumulated phrases."""
        if len(self.phrases) < self.min_phrases_to_fit:
            return

        self.feature_names = sorted(self.phrases[0].keys())
        X = np.array([[p[f] for f in self.feature_names] for p in self.phrases])

        # Handle NaN/inf
        X = np.nan_to_num(X, nan=0.0, posinf=0.0, neginf=0.0)

        self.scaler.fit(X)
        X_scaled = self.scaler.transform(X)

        k = min(self.n_clusters, len(X) // 2, 8)
        if k < 2:
            return

        self.kmeans = KMeans(n_clusters=k, n_init=10, random_state=42)
        self.kmeans.fit(X_scaled)
        self.fitted = True

        # Auto-label clusters based on features
        for i in range(k):
            mask = self.kmeans.labels_ == i
            cluster_feats = X[mask].mean(axis=0)
            feat_dict = dict(zip(self.feature_names, cluster_feats))
            self.cluster_labels[i] = self._auto_label(feat_dict)

    def _auto_label(self, feat_dict):
        """Generate a human-readable label for a cluster."""
        parts = []
        if feat_dict.get("has_kick", 0) > 0.5 and feat_dict.get("has_snare", 0) > 0.5 and feat_dict.get("has_hihat", 0) > 0.5:
            parts.append("Full Beat")
        elif feat_dict.get("has_hihat", 0) > 0.7:
            parts.append("Hat Pattern")
        elif feat_dict.get("has_kick", 0) > 0.5 and feat_dict.get("has_snare", 0) > 0.5:
            parts.append("Kick-Snare")
        elif feat_dict.get("has_kick", 0) > 0.5:
            parts.append("Kick Heavy")
        elif feat_dict.get("has_snare", 0) > 0.5:
            parts.append("Snare Heavy")
        else:
            parts.append("Mixed")

        if feat_dict.get("vel_trend", 0) > 5:
            parts.append("Crescendo")
        elif feat_dict.get("vel_trend", 0) < -5:
            parts.append("Decrescendo")

        if feat_dict.get("rhythm_regularity", 0) < 0.15:
            parts.append("Steady")
        elif feat_dict.get("rhythm_regularity", 0) > 0.4:
            parts.append("Loose")

        if feat_dict.get("mean_vel", 0) > 100:
            parts.append("Loud")
        elif feat_dict.get("mean_vel", 0) < 50:
            parts.append("Soft")

        return " | ".join(parts) if parts else "Unknown"

    def add_phrase(self, notes, velocities, iois, session_id):
        """Add a new phrase and update model."""
        feats = FeatureExtractor.extract_phrase(notes, velocities, iois)
        if feats is None:
            return None

        self.phrases.append(feats)
        self.phrase_meta.append((notes, velocities, iois))

        # Store in DB
        try:
            c = self.db.cursor()
            cluster_id = -1
            label = "unclustered"

            if self.fitted:
                X = np.array([[feats[f] for f in self.feature_names]])
                X = np.nan_to_num(X, nan=0.0, posinf=0.0, neginf=0.0)
                X_scaled = self.scaler.transform(X)
                cluster_id = int(self.kmeans.predict(X_scaled)[0])
                label = self.cluster_labels.get(cluster_id, f"cluster-{cluster_id}")

                # Anomaly check
                center = self.kmeans.cluster_centers_[cluster_id]
                dist = np.linalg.norm(X_scaled[0] - center)
                if dist > self.anomaly_threshold:
                    label = f"ANOMALY ({label})"

            c.execute("""INSERT INTO patterns
                (session_id, timestamp, pattern_notes, pattern_velocities, pattern_iois, cluster_id, label)
                VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (session_id, time.time(), json.dumps(notes), json.dumps([int(v) for v in velocities]),
                 json.dumps([round(i, 4) for i in iois]), cluster_id, label))
            self.db.commit()

            # Re-fit periodically
            if len(self.phrases) % 20 == 0:
                self._fit()

            return {"cluster_id": cluster_id, "label": label}
        except Exception as e:
            return {"cluster_id": -1, "label": f"err: {e}"}

    def update_transitions(self, prev_note, curr_note):
        """Update Markov chain."""
        self.transitions[prev_note][curr_note] += 1
        self.total_transitions[prev_note] += 1

    def predict_next(self, current_note):
        """Predict the most likely next note."""
        if current_note not in self.transitions:
            return None, 0.0
        counts = self.transitions[current_note]
        total = self.total_transitions[current_note]
        if total == 0:
            return None, 0.0
        best_note = counts.most_common(1)[0]
        return best_note[0], best_note[1] / total

    def get_cluster_summary(self):
        """Return summary of all clusters."""
        if not self.fitted:
            return "Model not yet fitted (need {} more phrases)".format(
                max(0, self.min_phrases_to_fit - len(self.phrases)))
        lines = []
        labels = self.kmeans.labels_
        for i in range(self.kmeans.n_clusters):
            count = int(np.sum(labels == i))
            label = self.cluster_labels.get(i, f"cluster-{i}")
            lines.append(f"  [{i}] {label} ({count} phrases)")
        return "\n".join(lines)


# ══════════════════════════════════════════════════════════════
#  LIVE SESSION
# ══════════════════════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════
#  SPATIAL GESTURE RECOGNITION
#  Maps MIDI notes to a 2D spatial grid, detects shapes
#  drawn by stick movement sequences
# ══════════════════════════════════════════════════════════════
class SpatialRecognizer:
    """
    The Aerband sticks map physical positions to notes.
    We assign each note a 2D coordinate and detect gestures
    from the path of consecutive hits.

    Aerband air-space grid (from 154-hit mapping):
        49=Crash(0.5,0.05)        — high reach up, center
        42=HH(0.15,0.25)         — left hand, high
        48=TomHI(0.25,0.40)      — left stick, mid height
        47=TomMH(0.75,0.40)      — right stick, mid height
        51=Ride(0.85,0.25)       — right hand, high
        38=Snare(0.50,0.55)      — center, mid level
        36=Kick(0.50,0.85)       — low stomp / foot tap
    """

    # Quad drum → (x, y) — linear left-to-right like marching tenor quads
    NOTE_POS = {
        1: (0.15, 0.50),  # Drum 1 — far left (highest)
        2: (0.38, 0.50),  # Drum 2 — mid-left
        3: (0.62, 0.50),  # Drum 3 — mid-right
        4: (0.85, 0.50),  # Drum 4 — far right (lowest)
        43: (0.70, 0.50),  # Tom low
        41: (0.70, 0.55),  # Tom floor
        36: (0.50, 0.80),  # Kick
        35: (0.50, 0.82),  # Kick 2
        52: (0.75, 0.10),  # China
        55: (0.60, 0.12),  # Splash
        57: (0.90, 0.15),  # Crash 2
    }

    GESTURES = {
        "circle_cw":     {"label": "CIRCLE (clockwise)",     "icon": "⭕", "action": "Cycle through all orgs"},
        "circle_ccw":    {"label": "CIRCLE (counter-CW)",    "icon": "🔄", "action": "Reverse cycle orgs"},
        "sweep_left":    {"label": "SWEEP LEFT",             "icon": "⬅️",  "action": "Previous page/view"},
        "sweep_right":   {"label": "SWEEP RIGHT",            "icon": "➡️",  "action": "Next page/view"},
        "sweep_down":    {"label": "SWEEP DOWN",             "icon": "⬇️",  "action": "Drill into detail"},
        "sweep_up":      {"label": "SWEEP UP",               "icon": "⬆️",  "action": "Zoom out / overview"},
        "box":           {"label": "BOX",                    "icon": "⬜", "action": "Select / capture region"},
        "zigzag":        {"label": "ZIGZAG",                 "icon": "⚡", "action": "Rapid multi-target scan"},
        "cross":         {"label": "CROSS (X)",              "icon": "❌", "action": "Cancel / abort"},
        "triangle":      {"label": "TRIANGLE",               "icon": "🔺", "action": "Deploy to 3 targets"},
    }

    def __init__(self):
        self.path = deque(maxlen=20)  # (x, y, timestamp)
        self.last_gesture = None
        self.last_gesture_time = 0
        self.gesture_cooldown = 1.5  # seconds between gestures
        self.gesture_history = []

    def add_hit(self, note, timestamp):
        pos = self.NOTE_POS.get(note)
        if pos:
            self.path.append((pos[0], pos[1], timestamp))

    def check_gestures(self):
        """Analyze the recent path for geometric shapes."""
        now = time.time()
        if now - self.last_gesture_time < self.gesture_cooldown:
            return None

        # Need at least 4 points
        if len(self.path) < 4:
            return None

        # Only look at recent points (within 3 seconds)
        points = [(x, y) for x, y, t in self.path if now - t < 3.0]
        if len(points) < 4:
            return None

        gesture = self._classify_path(points)
        if gesture:
            self.last_gesture = gesture
            self.last_gesture_time = now
            self.gesture_history.append((gesture, now))
            self.path.clear()  # reset after recognized gesture
            return gesture

        return None

    def _classify_path(self, points):
        """Classify a sequence of 2D points as a gesture."""
        n = len(points)
        xs = [p[0] for p in points]
        ys = [p[1] for p in points]

        dx_total = xs[-1] - xs[0]  # total horizontal displacement
        dy_total = ys[-1] - ys[0]  # total vertical displacement
        x_range = max(xs) - min(xs)
        y_range = max(ys) - min(ys)

        # Compute total path length
        path_len = sum(math.sqrt((xs[i+1]-xs[i])**2 + (ys[i+1]-ys[i])**2) for i in range(n-1))

        # Compute signed area (for circle direction detection)
        signed_area = 0
        for i in range(n-1):
            signed_area += (xs[i+1] - xs[i]) * (ys[i+1] + ys[i])

        # Center of mass
        cx, cy = np.mean(xs), np.mean(ys)

        # Average distance from center (for circularity)
        dists = [math.sqrt((x-cx)**2 + (y-cy)**2) for x, y in points]
        avg_dist = np.mean(dists)
        dist_std = np.std(dists)

        # Start-end distance
        start_end_dist = math.sqrt(dx_total**2 + dy_total**2)

        # ── Circle detection ──
        # Circle = path returns near start, consistent distance from center
        if n >= 5 and start_end_dist < 0.25 and avg_dist > 0.1 and path_len > 0.5:
            circularity = dist_std / max(avg_dist, 0.01)
            if circularity < 0.5:
                if signed_area > 0:
                    return "circle_cw"
                else:
                    return "circle_ccw"

        # ── Box detection ──
        # Box = 4+ direction changes, returns near start, has corners
        if n >= 5 and start_end_dist < 0.25 and x_range > 0.15 and y_range > 0.15:
            direction_changes = self._count_direction_changes(xs, ys)
            if direction_changes >= 3:
                return "box"

        # ── Triangle detection ──
        if n >= 4 and start_end_dist < 0.3:
            direction_changes = self._count_direction_changes(xs, ys)
            if direction_changes == 2 and path_len > 0.4:
                return "triangle"

        # ── Sweeps (linear movements) ──
        if path_len > 0.01:  # avoid division by zero
            linearity = math.sqrt(dx_total**2 + dy_total**2) / path_len
        else:
            linearity = 0

        if linearity > 0.6 and path_len > 0.2:
            if abs(dx_total) > abs(dy_total):
                if dx_total > 0.2:
                    return "sweep_right"
                elif dx_total < -0.2:
                    return "sweep_left"
            else:
                if dy_total > 0.2:
                    return "sweep_down"
                elif dy_total < -0.2:
                    return "sweep_up"

        # ── Zigzag ──
        direction_changes = self._count_direction_changes(xs, ys)
        if direction_changes >= 4 and path_len > 0.4:
            return "zigzag"

        # ── Cross (X shape) ──
        if n >= 5 and x_range > 0.2 and y_range > 0.2:
            mid = n // 2
            first_half_dx = xs[mid] - xs[0]
            second_half_dx = xs[-1] - xs[mid]
            if (first_half_dx > 0 and second_half_dx < 0) or (first_half_dx < 0 and second_half_dx > 0):
                return "cross"

        return None

    def _count_direction_changes(self, xs, ys):
        """Count significant direction changes in path."""
        changes = 0
        min_delta = 0.05
        prev_dx, prev_dy = 0, 0
        for i in range(1, len(xs)):
            dx = xs[i] - xs[i-1]
            dy = ys[i] - ys[i-1]
            if abs(dx) > min_delta or abs(dy) > min_delta:
                if prev_dx != 0 or prev_dy != 0:
                    # Check if direction reversed
                    if (dx * prev_dx < 0 and abs(dx) > min_delta) or \
                       (dy * prev_dy < 0 and abs(dy) > min_delta):
                        changes += 1
                prev_dx, prev_dy = dx, dy
        return changes


# ══════════════════════════════════════════════════════════════
#  COMBO SYSTEM - Fighting-game style note sequences → commands
# ══════════════════════════════════════════════════════════════
class ComboSystem:
    """Track note sequences and match against combo dictionary."""

    # Each combo: (note_sequence, command, description, category, xp_reward)
    COMBOS = {
        # ── Git combos (intuitive quad patterns) ──
        "git-status":    {"seq": [2,2,4,4],           "cmd": "git status",                       "desc": "Git Status",         "cat": "git",    "xp": 10},
        "git-log":       {"seq": [1,1,1,1,1],         "cmd": "git log --oneline -10",            "desc": "Recent Commits",     "cat": "git",    "xp": 10},
        "git-diff":      {"seq": [2,4,2,4,2],         "cmd": "git diff --stat",                  "desc": "Git Diff",           "cat": "git",    "xp": 15},
        "git-branch":    {"seq": [1,2,1,2,1],         "cmd": "git branch -a",                    "desc": "List Branches",      "cat": "git",    "xp": 10},
        # ── GitHub combos ──
        "repo-list":     {"seq": [4,2,4,2,1],         "cmd": "gh repo list BlackRoad-OS --limit 5", "desc": "List Repos",      "cat": "github",  "xp": 20},
        "pr-list":       {"seq": [1,2,1,2,4],         "cmd": "gh pr list --limit 5",             "desc": "List PRs",           "cat": "github",  "xp": 20},
        "issue-list":    {"seq": [3,2,3,2,1],         "cmd": "gh issue list --limit 5",          "desc": "List Issues",        "cat": "github",  "xp": 20},
        "notifications": {"seq": [1,1,2,2,1,1],       "cmd": "gh api notifications --jq '.[0:5] | .[].subject.title'", "desc": "Notifications", "cat": "github", "xp": 25},
        # ── Infrastructure combos ──
        "health":        {"seq": [2,3,2,3],            "cmd": "echo '🏥 Health check: all systems nominal'", "desc": "Health Check", "cat": "infra", "xp": 15},
        "agent-roster":  {"seq": [1,2,1,2,1,2],       "cmd": "echo '🤖 Agents: LUCIDIA ✓ | ALICE ✓ | OCTAVIA ✓ | PRISM ✓ | ECHO ✓ | CIPHER ✓'", "desc": "Agent Roster", "cat": "infra", "xp": 15},
        "disk-usage":    {"seq": [4,4,4,4],            "cmd": "df -h / | tail -1",               "desc": "Disk Usage",         "cat": "infra",  "xp": 10},
        "processes":     {"seq": [3,3,3,3],            "cmd": "ps aux | head -8",                "desc": "Top Processes",      "cat": "infra",  "xp": 10},
        # ── BlackRoad combos (scale runs across all 4 drums) ──
        "br-stats":      {"seq": [1,2,3,4,3,2],       "cmd": "echo '📊 BlackRoad: 16 orgs | 1,206 repos | 30K agents'", "desc": "BR Stats", "cat": "blackroad", "xp": 30},
        "traffic-light": {"seq": [4,3,2,1,2,3],       "cmd": "echo '🚦 Traffic: 58 green | 0 yellow | 0 red'",         "desc": "Traffic Lights", "cat": "blackroad", "xp": 25},
        # ── Power combos (longer sequences) ──
        "full-deploy":   {"seq": [1,1,2,2,3,3,4,4],   "cmd": "echo '🚀 FULL DEPLOY SEQUENCE INITIATED'", "desc": "FULL DEPLOY", "cat": "power", "xp": 50},
        "system-scan":   {"seq": [1,2,3,4,1,2],       "cmd": "echo '🔍 SYSTEM SCAN: All 8 devices responding'", "desc": "System Scan", "cat": "power", "xp": 40},
    }

    def __init__(self):
        self.note_buffer = deque(maxlen=12)
        self.time_buffer = deque(maxlen=12)
        self.last_combo = None
        self.last_combo_time = 0
        self.combo_cooldown = 2.0
        self.combo_history = []  # (name, timestamp)
        self.combo_counts = Counter()
        self.combo_streak = 0
        self.max_combo_streak = 0

    def add_note(self, note, timestamp):
        self.note_buffer.append(note)
        self.time_buffer.append(timestamp)

    def check_combos(self):
        """Check if recent notes match any combo."""
        now = time.time()
        if now - self.last_combo_time < self.combo_cooldown:
            return None

        notes = list(self.note_buffer)
        times = list(self.time_buffer)
        if len(notes) < 3:
            return None

        # Only consider notes within last 4 seconds
        recent_notes = []
        for n, t in zip(reversed(notes), reversed(times)):
            if now - t < 4.0:
                recent_notes.insert(0, n)
            else:
                break

        if len(recent_notes) < 3:
            return None

        # Check each combo (longest first for priority)
        best_match = None
        best_len = 0
        for name, combo in self.COMBOS.items():
            seq = combo["seq"]
            slen = len(seq)
            if slen > len(recent_notes):
                continue
            # Check if the last N notes match the combo
            if recent_notes[-slen:] == seq and slen > best_len:
                best_match = name
                best_len = slen

        if best_match:
            self.last_combo = best_match
            self.last_combo_time = now
            self.combo_history.append((best_match, now))
            self.combo_counts[best_match] += 1
            self.combo_streak += 1
            self.max_combo_streak = max(self.max_combo_streak, self.combo_streak)
            self.note_buffer.clear()
            return best_match

        return None

    def break_streak(self):
        """Call when too much time passes without a combo."""
        self.combo_streak = 0


# ══════════════════════════════════════════════════════════════
#  MOOD / ENERGY ENGINE - Real-time playing style classification
# ══════════════════════════════════════════════════════════════
class MoodEngine:
    """Classify current playing energy from rolling windows."""

    MOODS = {
        "AGGRESSIVE": {"icon": "🔥", "color": RED,    "desc": "Fast + Loud",          "theme": "red"},
        "LOCKED_IN":  {"icon": "🎯", "color": GREEN,  "desc": "Steady + Consistent",  "theme": "green"},
        "BUILDING":   {"icon": "📈", "color": AMBER,  "desc": "Crescendo + Accel",    "theme": "amber"},
        "FADING":     {"icon": "📉", "color": VIOLET, "desc": "Decrescendo + Decel",  "theme": "violet"},
        "CHAOTIC":    {"icon": "🌀", "color": YELLOW, "desc": "Irregular + Varied",   "theme": "yellow"},
        "CHILL":      {"icon": "🌊", "color": CYAN,   "desc": "Slow + Soft",          "theme": "cyan"},
        "FLOWING":    {"icon": "💫", "color": BLUE,    "desc": "Moderate + Smooth",    "theme": "blue"},
    }

    def __init__(self):
        self.window_vel = deque(maxlen=20)     # recent velocities
        self.window_ioi = deque(maxlen=20)     # recent IOIs
        self.window_notes = deque(maxlen=20)   # recent notes
        self.current_mood = "FLOWING"
        self.mood_history = []                 # (mood, timestamp)
        self.mood_durations = Counter()        # mood → total seconds
        self.last_mood_change = time.time()

    def update(self, velocity, ioi, note):
        now = time.time()
        self.window_vel.append(velocity)
        self.window_ioi.append(ioi)
        self.window_notes.append(note)

        if len(self.window_vel) < 5:
            return self.current_mood

        vels = list(self.window_vel)
        iois = [x for x in self.window_ioi if x > 0]

        avg_vel = np.mean(vels)
        vel_trend = np.polyfit(range(len(vels)), vels, 1)[0] if len(vels) > 2 else 0
        avg_ioi = np.mean(iois) if iois else 0.5
        ioi_std = np.std(iois) if len(iois) > 2 else 0
        ioi_cv = ioi_std / max(avg_ioi, 0.01)  # coefficient of variation
        bpm_est = 60 / avg_ioi if avg_ioi > 0 else 0

        # IOI trend (accelerando/decelerando)
        ioi_trend = np.polyfit(range(len(iois)), iois, 1)[0] if len(iois) > 2 else 0

        # Note diversity
        unique = len(set(self.window_notes))

        # Classify
        new_mood = self._classify(avg_vel, vel_trend, bpm_est, ioi_cv, ioi_trend, unique)

        if new_mood != self.current_mood:
            # Track duration of previous mood
            self.mood_durations[self.current_mood] += now - self.last_mood_change
            self.last_mood_change = now
            self.current_mood = new_mood
            self.mood_history.append((new_mood, now))

        return self.current_mood

    def _classify(self, avg_vel, vel_trend, bpm, ioi_cv, ioi_trend, unique):
        # AGGRESSIVE: loud + fast
        if avg_vel > 95 and bpm > 140:
            return "AGGRESSIVE"
        # BUILDING: getting louder and/or faster
        if vel_trend > 2.0 or (vel_trend > 0.5 and ioi_trend < -0.005):
            return "BUILDING"
        # FADING: getting softer and/or slower
        if vel_trend < -2.0 or (vel_trend < -0.5 and ioi_trend > 0.005):
            return "FADING"
        # CHAOTIC: irregular timing + varied notes
        if ioi_cv > 0.5 and unique >= 4:
            return "CHAOTIC"
        # LOCKED_IN: very regular + consistent velocity
        if ioi_cv < 0.15 and np.std(list(self.window_vel)) < 15:
            return "LOCKED_IN"
        # CHILL: slow + soft
        if avg_vel < 55 and bpm < 90:
            return "CHILL"
        # Default
        return "FLOWING"

    @property
    def mood_info(self):
        return self.MOODS.get(self.current_mood, self.MOODS["FLOWING"])


# ══════════════════════════════════════════════════════════════
#  DRUM RUDIMENT DETECTION
# ══════════════════════════════════════════════════════════════
class RudimentDetector:
    """Detect standard drum rudiments from hand patterns."""

    # Hand assignment: map notes to L/R hand based on drum kit position
    LEFT_NOTES = {1, 2}   # Drum 1-2 (left side of quads)
    RIGHT_NOTES = {3, 4}  # Drum 3-4 (right side of quads)

    RUDIMENTS = {
        "single_stroke":   {"pattern": "RLRL",     "label": "Single Stroke Roll",   "icon": "🥁", "xp": 10},
        "double_stroke":   {"pattern": "RRLL",     "label": "Double Stroke Roll",   "icon": "🔄", "xp": 15},
        "paradiddle":      {"pattern": "RLRR",     "label": "Paradiddle",           "icon": "✨", "xp": 20},
        "paradiddle_inv":  {"pattern": "LRLL",     "label": "Inverted Paradiddle",  "icon": "✨", "xp": 20},
        "double_para":     {"pattern": "RLRLRR",   "label": "Double Paradiddle",    "icon": "🌟", "xp": 30},
        "triple_stroke":   {"pattern": "RRRLLL",   "label": "Triple Stroke Roll",   "icon": "🔄", "xp": 25},
        "six_stroke":      {"pattern": "RLLRRL",   "label": "Six Stroke Roll",      "icon": "💫", "xp": 35},
    }

    def __init__(self):
        self.hand_buffer = deque(maxlen=16)  # recent L/R assignments
        self.timing_buffer = deque(maxlen=16)
        self.vel_buffer = deque(maxlen=16)
        self.detected_history = []  # (name, timestamp, tightness)
        self.rudiment_counts = Counter()
        self.last_detection_time = 0
        self.detection_cooldown = 0.8
        # Flam detection
        self.flam_threshold = 0.035  # 35ms = flam

    def note_to_hand(self, note):
        if note in self.LEFT_NOTES: return "L"
        if note in self.RIGHT_NOTES: return "R"
        return "L" if note % 2 == 0 else "R"  # fallback

    def add_hit(self, note, velocity, timestamp):
        hand = self.note_to_hand(note)
        self.hand_buffer.append(hand)
        self.timing_buffer.append(timestamp)
        self.vel_buffer.append(velocity)

    def check_rudiments(self):
        """Check for rudiment patterns in recent hand sequence."""
        now = time.time()
        if now - self.last_detection_time < self.detection_cooldown:
            return None

        hands = "".join(self.hand_buffer)
        times = list(self.timing_buffer)

        if len(hands) < 4:
            return None

        # Check for flam (two hits < 35ms apart)
        if len(times) >= 2:
            last_ioi = times[-1] - times[-2]
            if 0 < last_ioi < self.flam_threshold:
                self.last_detection_time = now
                result = {"name": "flam", "label": "Flam", "icon": "🔨", "xp": 12, "tightness": 1.0 - (last_ioi / self.flam_threshold)}
                self.detected_history.append(("flam", now, result["tightness"]))
                self.rudiment_counts["flam"] += 1
                return result

        # Check each rudiment pattern (longest first)
        for name, rud in sorted(self.RUDIMENTS.items(), key=lambda x: -len(x[1]["pattern"])):
            pat = rud["pattern"]
            plen = len(pat)
            if len(hands) >= plen and hands[-plen:] == pat:
                # Check timing tightness (how even are the IOIs?)
                if len(times) >= plen:
                    recent_times = times[-plen:]
                    iois = [recent_times[i+1]-recent_times[i] for i in range(len(recent_times)-1)]
                    if iois:
                        avg_ioi = np.mean(iois)
                        ioi_std = np.std(iois)
                        tightness = max(0, 1.0 - (ioi_std / max(avg_ioi, 0.01)))
                    else:
                        tightness = 0.5
                else:
                    tightness = 0.5

                self.last_detection_time = now
                self.detected_history.append((name, now, tightness))
                self.rudiment_counts[name] += 1
                return {"name": name, "label": rud["label"], "icon": rud["icon"],
                        "xp": rud["xp"], "tightness": tightness}

        return None


# ══════════════════════════════════════════════════════════════
#  ACHIEVEMENT & STREAK SYSTEM
# ══════════════════════════════════════════════════════════════
class AchievementSystem:
    """Persistent XP, levels, badges, and streaks."""

    LEVEL_THRESHOLDS = [0, 50, 150, 300, 500, 800, 1200, 1800, 2500, 3500, 5000,
                        7000, 10000, 15000, 20000, 30000, 50000, 75000, 100000]

    BADGES = {
        # Hit milestones
        "first_blood":    {"name": "First Blood",         "icon": "🩸", "desc": "First 10 hits",           "check": lambda s: s.total_hits >= 10},
        "centurion":      {"name": "Centurion",           "icon": "💯", "desc": "100 hits in a session",   "check": lambda s: s.total_hits >= 100},
        "five_hundred":   {"name": "500 Club",            "icon": "🎖️", "desc": "500 hits in a session",   "check": lambda s: s.total_hits >= 500},
        "thousand":       {"name": "Millennium",          "icon": "👑", "desc": "1000 hits in a session",  "check": lambda s: s.total_hits >= 1000},
        # Speed
        "tempo_120":      {"name": "Cruising",            "icon": "🚗", "desc": "Sustain 120+ BPM",        "check": lambda s: s.bpm >= 120},
        "tempo_160":      {"name": "Speed Racer",         "icon": "🏎️", "desc": "Sustain 160+ BPM",        "check": lambda s: s.bpm >= 160},
        "tempo_200":      {"name": "Speed Demon",         "icon": "👹", "desc": "Sustain 200+ BPM",        "check": lambda s: s.bpm >= 200},
        # Dynamics
        "whisper":        {"name": "Whisper",             "icon": "🤫", "desc": "Hit below velocity 25",   "check": lambda s: any(v < 25 for _, _, v in s.hits[-20:])},
        "thunder":        {"name": "Thunder",             "icon": "⚡", "desc": "Hit above velocity 120",  "check": lambda s: any(v > 120 for _, _, v in s.hits[-20:])},
        "full_dynamic":   {"name": "Full Spectrum",       "icon": "🌈", "desc": "Use full velocity range", "check": lambda s: s._vel_range() > 100},
        # Zones
        "all_zones":      {"name": "Everywhere",          "icon": "🗺️", "desc": "Hit all 5 zones",         "check": lambda s: len(s.zone_counts) >= 5},
        "all_notes":      {"name": "Full Kit",            "icon": "🥁", "desc": "Play 6+ different notes", "check": lambda s: len(s.note_counts) >= 6},
        # Prediction
        "oracle_5":       {"name": "Oracle",              "icon": "🔮", "desc": "5 correct predictions",   "check": lambda s: s.predictions_correct >= 5},
        "oracle_20":      {"name": "Seer",                "icon": "👁️", "desc": "20 correct predictions",  "check": lambda s: s.predictions_correct >= 20},
        # Duration
        "marathon_5":     {"name": "Warm Up",             "icon": "🏃", "desc": "5 minute session",        "check": lambda s: s.duration >= 300},
        "marathon_15":    {"name": "Marathon",            "icon": "🏅", "desc": "15 minute session",       "check": lambda s: s.duration >= 900},
        # Combos & Rudiments (checked externally)
        "first_combo":    {"name": "Combo Starter",       "icon": "🎮", "desc": "Execute first combo",     "check": lambda s: s._combo_count() >= 1},
        "combo_master":   {"name": "Combo Master",        "icon": "🕹️", "desc": "Execute 10 combos",       "check": lambda s: s._combo_count() >= 10},
        "first_rudiment": {"name": "Drum Student",        "icon": "📚", "desc": "First rudiment detected", "check": lambda s: s._rudiment_count() >= 1},
        "rudiment_5":     {"name": "Drum Apprentice",     "icon": "🎓", "desc": "5 rudiments detected",    "check": lambda s: s._rudiment_count() >= 5},
        "first_gesture":  {"name": "Shape Shifter",       "icon": "🔷", "desc": "First gesture detected",  "check": lambda s: len(s.spatial.gesture_history) >= 1},
        "gesture_artist":  {"name": "Air Painter",        "icon": "🎨", "desc": "5 gestures detected",     "check": lambda s: len(s.spatial.gesture_history) >= 5},
        # War chant
        "war_chant_1":    {"name": "War Drummer",         "icon": "🪘", "desc": "First Hawaiian War Chant", "check": lambda s: s.war_chant.total_chants >= 1},
        "war_chant_5":    {"name": "Chant Master",        "icon": "🌺", "desc": "5 War Chants in a session", "check": lambda s: s.war_chant.total_chants >= 5},
        "chain_3":        {"name": "Chain Reaction",      "icon": "⛓️", "desc": "Chain 3 autopilot actions", "check": lambda s: s.war_chant.max_chain >= 3},
        "chain_5":        {"name": "Unstoppable",         "icon": "🌋", "desc": "Chain 5 autopilot actions", "check": lambda s: s.war_chant.max_chain >= 5},
    }

    def __init__(self, db):
        self.db = db
        self.xp = 0
        self.level = 1
        self.unlocked = set()  # badge keys
        self.streak_bpm_start = 0     # when current BPM streak started
        self.streak_bpm_target = 0    # BPM we're streak-ing at
        self.best_streak_secs = 0
        self.current_streak_secs = 0
        self.pending_notifications = []  # (type, message) to display

        self._load()

    def _load(self):
        """Load persistent XP and badges from DB."""
        try:
            c = self.db.cursor()
            c.execute("""CREATE TABLE IF NOT EXISTS achievements (
                key TEXT PRIMARY KEY,
                value TEXT
            )""")
            self.db.commit()
            c.execute("SELECT value FROM achievements WHERE key='xp'")
            row = c.fetchone()
            if row:
                self.xp = int(row[0])
            c.execute("SELECT value FROM achievements WHERE key='unlocked'")
            row = c.fetchone()
            if row:
                self.unlocked = set(json.loads(row[0]))
            c.execute("SELECT value FROM achievements WHERE key='best_streak'")
            row = c.fetchone()
            if row:
                self.best_streak_secs = float(row[0])
            self._update_level()
        except Exception:
            pass

    def _save(self):
        try:
            c = self.db.cursor()
            c.execute("INSERT OR REPLACE INTO achievements (key, value) VALUES ('xp', ?)", (str(self.xp),))
            c.execute("INSERT OR REPLACE INTO achievements (key, value) VALUES ('unlocked', ?)", (json.dumps(list(self.unlocked)),))
            c.execute("INSERT OR REPLACE INTO achievements (key, value) VALUES ('best_streak', ?)", (str(self.best_streak_secs),))
            self.db.commit()
        except Exception:
            pass

    def _update_level(self):
        for i, threshold in enumerate(self.LEVEL_THRESHOLDS):
            if self.xp >= threshold:
                self.level = i + 1

    def add_xp(self, amount, reason=""):
        old_level = self.level
        self.xp += amount
        self._update_level()
        if self.level > old_level:
            self.pending_notifications.append(
                ("level_up", f"LEVEL UP! {old_level} → {self.level}  (+{amount} XP: {reason})")
            )

    def check_badges(self, session):
        """Check all badge conditions against current session state."""
        newly_unlocked = []
        for key, badge in self.BADGES.items():
            if key not in self.unlocked:
                try:
                    if badge["check"](session):
                        self.unlocked.add(key)
                        self.add_xp(50, f"Badge: {badge['name']}")
                        newly_unlocked.append(badge)
                        self.pending_notifications.append(
                            ("badge", f"BADGE UNLOCKED: {badge['icon']} {badge['name']} - {badge['desc']}")
                        )
                except Exception:
                    pass
        if newly_unlocked:
            self._save()
        return newly_unlocked

    def update_streak(self, bpm):
        """Track BPM consistency streak."""
        now = time.time()
        if bpm < 40:
            return

        if self.streak_bpm_target == 0:
            self.streak_bpm_target = bpm
            self.streak_bpm_start = now
            return

        # Within 5% of target BPM = continuing streak
        if abs(bpm - self.streak_bpm_target) / max(self.streak_bpm_target, 1) < 0.05:
            self.current_streak_secs = now - self.streak_bpm_start
            if self.current_streak_secs > self.best_streak_secs:
                self.best_streak_secs = self.current_streak_secs
        else:
            # Streak broken, start new one
            self.streak_bpm_target = bpm
            self.streak_bpm_start = now
            self.current_streak_secs = 0

    def get_notifications(self):
        """Pop pending notifications for display."""
        notifs = self.pending_notifications[:]
        self.pending_notifications.clear()
        return notifs

    @property
    def xp_to_next(self):
        if self.level < len(self.LEVEL_THRESHOLDS):
            return self.LEVEL_THRESHOLDS[self.level] - self.xp
        return 0

    @property
    def level_progress(self):
        if self.level >= len(self.LEVEL_THRESHOLDS):
            return 1.0
        current_threshold = self.LEVEL_THRESHOLDS[self.level - 1]
        next_threshold = self.LEVEL_THRESHOLDS[self.level] if self.level < len(self.LEVEL_THRESHOLDS) else current_threshold + 1000
        return (self.xp - current_threshold) / max(next_threshold - current_threshold, 1)


# ══════════════════════════════════════════════════════════════
#  COMMAND EXECUTOR - Run real commands (toggled by triple-D1)
# ══════════════════════════════════════════════════════════════
class CommandExecutor:
    """Execute shell commands with a safety toggle."""

    def __init__(self):
        self.live_mode = False  # start in display-only
        self.crash_times = deque(maxlen=5)
        self.triple_crash_window = 1.2  # 3 crashes within this window to toggle
        self.command_history = []  # (command, output, timestamp, was_live)

    def check_triple_crash(self, note, timestamp):
        """Check if we got 3 Drum-1 hits in rapid succession to toggle mode."""
        if note == 1:  # Drum 1 (highest) = toggle key
            self.crash_times.append(timestamp)
            if len(self.crash_times) >= 3:
                times = list(self.crash_times)
                if times[-1] - times[-3] < self.triple_crash_window:
                    self.live_mode = not self.live_mode
                    self.crash_times.clear()
                    return True
        return False

    def execute(self, command, description=""):
        """Execute a command (or just display it if not live)."""
        now = time.time()
        if self.live_mode:
            try:
                result = subprocess.run(
                    command, shell=True, capture_output=True, text=True, timeout=10
                )
                output = result.stdout.strip() or result.stderr.strip() or "(no output)"
                self.command_history.append((command, output, now, True))
                return output
            except subprocess.TimeoutExpired:
                output = "(command timed out after 10s)"
                self.command_history.append((command, output, now, True))
                return output
            except Exception as e:
                output = f"(error: {e})"
                self.command_history.append((command, output, now, True))
                return output
        else:
            self.command_history.append((command, "(display only)", now, False))
            return None


# ══════════════════════════════════════════════════════════════
#  HAWAIIAN WAR CHANT - "Continue to Next Predictable Action"
#
#  The classic drum cadence: tom-tom-SNARE tom-tom-SNARE
#  (Ta-Hu-Wa-Hu-Wai)
#
#  When detected, the system enters AUTOPILOT:
#    1. Looks at Markov chain → what combo is most likely next?
#    2. Looks at combo history → what usually follows?
#    3. Looks at pattern clusters → what's the natural flow?
#    4. Executes the predicted action automatically
#
#  Play it again to chain another predicted action.
#  Any non-chant pattern breaks autopilot.
# ══════════════════════════════════════════════════════════════
class WarChant:
    """Hawaiian War Chant detector and autopilot engine."""

    # Multiple recognized variations of the chant pattern
    # All follow the tom-tom-SNARE cadence structure
    CHANT_PATTERNS = [
        # Classic: right-left-low  right-left-low (3-2-4 cadence)
        [3, 2, 4, 3, 2, 4],
        # Reversed: left-right-low
        [2, 3, 4, 2, 3, 4],
        # Single drum repeated: drum drum LOW drum drum LOW
        [3, 3, 4, 3, 3, 4],
        [2, 2, 4, 2, 2, 4],
        # With accent: HIGH right left LOW right left LOW
        [1, 3, 2, 4, 3, 2, 4],
        [1, 2, 3, 4, 2, 3, 4],
        # Scale cadence: HIGH mid LOW HIGH mid LOW
        [1, 2, 4, 1, 2, 4],
        [1, 3, 4, 1, 3, 4],
        # Short cadence (4-note): right left LOW LOW
        [3, 2, 4, 4],
        [2, 3, 4, 4],
    ]

    # Combo flow predictions: after this combo, these are good next combos
    COMBO_FLOW = {
        "git-status":    ["git-diff", "git-log", "git-branch"],
        "git-log":       ["git-diff", "git-status", "pr-list"],
        "git-diff":      ["git-status", "git-log"],
        "git-branch":    ["git-log", "git-status"],
        "repo-list":     ["pr-list", "issue-list", "br-stats"],
        "pr-list":       ["issue-list", "repo-list", "notifications"],
        "issue-list":    ["pr-list", "repo-list"],
        "notifications": ["pr-list", "issue-list"],
        "health":        ["agent-roster", "disk-usage", "processes"],
        "agent-roster":  ["health", "processes", "system-scan"],
        "disk-usage":    ["processes", "health"],
        "processes":     ["disk-usage", "health"],
        "br-stats":      ["traffic-light", "system-scan", "repo-list"],
        "traffic-light": ["br-stats", "health", "agent-roster"],
        "system-scan":   ["health", "agent-roster", "br-stats"],
        "full-deploy":   ["health", "traffic-light", "system-scan"],
    }

    def __init__(self):
        self.note_buffer = deque(maxlen=10)
        self.time_buffer = deque(maxlen=10)
        self.active = False          # autopilot engaged
        self.chain_count = 0         # how many chained actions
        self.max_chain = 0
        self.total_chants = 0
        self.last_chant_time = 0
        self.chant_cooldown = 1.5
        self.action_queue = []       # predicted actions to execute
        self.chant_history = []      # (timestamp, chain_count, action_taken)

    def add_note(self, note, timestamp):
        self.note_buffer.append(note)
        self.time_buffer.append(timestamp)

    def check_chant(self):
        """Check if recent notes match any war chant pattern."""
        now = time.time()
        if now - self.last_chant_time < self.chant_cooldown:
            return False

        notes = list(self.note_buffer)
        times = list(self.time_buffer)
        if len(notes) < 4:
            return False

        # Only consider notes within last 3 seconds
        recent = [(n, t) for n, t in zip(notes, times) if now - t < 3.0]
        if len(recent) < 4:
            return False
        recent_notes = [n for n, t in recent]

        # Check each chant pattern
        for pattern in self.CHANT_PATTERNS:
            plen = len(pattern)
            if len(recent_notes) >= plen:
                if recent_notes[-plen:] == pattern:
                    self.last_chant_time = now
                    self.total_chants += 1
                    self.active = True
                    self.chain_count += 1
                    self.max_chain = max(self.max_chain, self.chain_count)
                    self.note_buffer.clear()
                    return True

        return False

    def predict_next_action(self, learner, last_combo, session):
        """
        Determine the next action to auto-execute.

        Priority:
        1. Combo flow graph (if we just did a combo, follow the natural next)
        2. Markov chain on combo history (what combo usually follows?)
        3. Most frequent unused combo (try something new)
        4. Default to system-scan
        """
        action = None
        reason = ""

        # Strategy 1: Combo flow graph
        if last_combo and last_combo in self.COMBO_FLOW:
            candidates = self.COMBO_FLOW[last_combo]
            # Pick the first one we haven't done recently
            recent_combos = [name for name, _ in session.combos.combo_history[-5:]]
            for candidate in candidates:
                if candidate not in recent_combos:
                    action = candidate
                    reason = f"flow from {last_combo}"
                    break
            if not action:
                action = candidates[0]
                reason = f"flow cycle from {last_combo}"

        # Strategy 2: Markov on combo history (what combo tends to follow?)
        if not action and len(session.combos.combo_history) >= 2:
            combo_names = [name for name, _ in session.combos.combo_history]
            # Build transition counts from combo history
            combo_transitions = defaultdict(Counter)
            for i in range(len(combo_names) - 1):
                combo_transitions[combo_names[i]][combo_names[i+1]] += 1
            if last_combo and last_combo in combo_transitions:
                best = combo_transitions[last_combo].most_common(1)
                if best:
                    action = best[0][0]
                    reason = f"markov ({best[0][1]} times after {last_combo})"

        # Strategy 3: Least-used combo (explore)
        if not action:
            all_combos = set(ComboSystem.COMBOS.keys())
            used = set(session.combos.combo_counts.keys())
            unused = all_combos - used
            if unused:
                # Pick shortest unused combo (easiest to chain)
                action = min(unused, key=lambda x: len(ComboSystem.COMBOS[x]["seq"]))
                reason = "explore (unused combo)"
            else:
                # Pick least-used
                action = min(all_combos, key=lambda x: session.combos.combo_counts.get(x, 0))
                reason = "explore (least used)"

        # Strategy 4: Fallback
        if not action:
            action = "health"
            reason = "fallback"

        return action, reason

    def break_chain(self):
        """Call when non-chant activity breaks the autopilot."""
        if self.active and self.chain_count > 0:
            self.chant_history.append((time.time(), self.chain_count, "chain_broken"))
        self.active = False
        self.chain_count = 0


# ══════════════════════════════════════════════════════════════
#  LIVE SESSION
# ══════════════════════════════════════════════════════════════
class Session:
    def __init__(self, db):
        self.db = db
        self.session_id = f"s-{int(time.time())}-{os.getpid()}"
        self.start_time = time.time()
        self.hits = []  # (timestamp, note, velocity)
        self.beat_times = deque(maxlen=32)
        self.bpm = 0.0
        self.total_hits = 0
        self.note_counts = Counter()
        self.zone_counts = Counter()
        self.velocity_history = deque(maxlen=50)
        self.phrase_buffer = []  # current phrase being built
        self.phrase_window = 8  # hits per phrase
        self.prev_note = None
        self.prev_time = None
        self.predictions_correct = 0
        self.predictions_total = 0
        self.log_file = open(LOG_PATH, "a")
        self.spatial = SpatialRecognizer()
        self.combos = ComboSystem()
        self.mood = MoodEngine()
        self.rudiments = RudimentDetector()
        self.achievements = AchievementSystem(db)
        self.executor = CommandExecutor()
        self.war_chant = WarChant()

    # Helper methods for achievement badge checks
    def _vel_range(self):
        if len(self.hits) < 10: return 0
        vels = [v for _, _, v in self.hits]
        return max(vels) - min(vels)

    def _combo_count(self):
        return sum(self.combos.combo_counts.values())

    def _rudiment_count(self):
        return sum(self.rudiments.rudiment_counts.values())

    def process_hit(self, note, velocity, learner):
        now = time.time()
        self.total_hits += 1
        info = note_info(note)

        # IOI (inter-onset interval)
        ioi = (now - self.prev_time) if self.prev_time else 0.0

        # BPM
        self.beat_times.append(now)
        if len(self.beat_times) >= 4:
            times = list(self.beat_times)
            intervals = [times[i+1]-times[i] for i in range(len(times)-1)]
            avg = sum(intervals)/len(intervals)
            self.bpm = 60/avg if avg > 0 else 0

        # Counters
        self.note_counts[note] += 1
        self.zone_counts[info["zone"]] += 1
        self.velocity_history.append(velocity)
        self.hits.append((now, note, velocity))

        # ── XP for every hit ──
        self.achievements.add_xp(1)

        # ── Log to JSONL ──
        event = {
            "session": self.session_id,
            "t": round(now - self.start_time, 4),
            "ts": now,
            "note": note,
            "name": info["name"],
            "vel": velocity,
            "zone": info["zone"],
            "ioi": round(ioi, 4),
            "bpm": round(self.bpm, 1),
        }
        self.log_file.write(json.dumps(event) + "\n")
        self.log_file.flush()

        # ── Log to SQLite ──
        try:
            c = self.db.cursor()
            c.execute("""INSERT INTO hits (session_id, timestamp, note, velocity, note_name, zone, ioi, bpm)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                (self.session_id, now, note, velocity, info["name"], info["zone"], ioi, self.bpm))
            self.db.commit()
        except Exception:
            pass

        # ── Markov prediction ──
        prediction_result = None
        if self.prev_note is not None:
            learner.update_transitions(self.prev_note, note)
            predicted, confidence = learner.predict_next(self.prev_note)
            if predicted is not None:
                correct = 1 if predicted == note else 0
                self.predictions_total += 1
                self.predictions_correct += correct
                prediction_result = {
                    "predicted": predicted, "actual": note,
                    "correct": correct, "confidence": confidence
                }
                try:
                    c = self.db.cursor()
                    c.execute("""INSERT INTO predictions (session_id, timestamp, predicted_note, actual_note, correct)
                        VALUES (?, ?, ?, ?, ?)""",
                        (self.session_id, now, predicted, note, correct))
                    self.db.commit()
                except Exception:
                    pass

        # ── Phrase building ──
        self.phrase_buffer.append((note, velocity, ioi))
        phrase_result = None
        if len(self.phrase_buffer) >= self.phrase_window:
            notes = [h[0] for h in self.phrase_buffer]
            vels = [h[1] for h in self.phrase_buffer]
            iois = [h[2] for h in self.phrase_buffer[1:]]  # first has no IOI
            phrase_result = learner.add_phrase(notes, vels, iois, self.session_id)
            self.phrase_buffer = self.phrase_buffer[self.phrase_window//2:]  # 50% overlap

        self.prev_note = note
        self.prev_time = now

        # ── Spatial gesture recognition ──
        self.spatial.add_hit(note, now)
        gesture_result = self.spatial.check_gestures()

        if gesture_result:
            g = SpatialRecognizer.GESTURES.get(gesture_result, {})
            self.achievements.add_xp(15, "gesture")
            gesture_event = {
                "session": self.session_id, "t": round(now - self.start_time, 4),
                "ts": now, "type": "gesture", "gesture": gesture_result,
                "label": g.get("label", gesture_result), "action": g.get("action", ""),
            }
            self.log_file.write(json.dumps(gesture_event) + "\n")
            self.log_file.flush()
            try:
                c = self.db.cursor()
                c.execute("""INSERT INTO gestures (session_id, timestamp, gesture_type, label, action)
                    VALUES (?, ?, ?, ?, ?)""",
                    (self.session_id, now, gesture_result, g.get("label", ""), g.get("action", "")))
                self.db.commit()
            except Exception:
                pass

        # ── Combo system ──
        self.combos.add_note(note, now)
        combo_result = self.combos.check_combos()
        cmd_output = None
        if combo_result:
            combo = ComboSystem.COMBOS[combo_result]
            self.achievements.add_xp(combo["xp"], f"combo:{combo_result}")
            cmd_output = self.executor.execute(combo["cmd"], combo["desc"])
            combo_event = {
                "session": self.session_id, "t": round(now - self.start_time, 4),
                "ts": now, "type": "combo", "combo": combo_result,
                "desc": combo["desc"], "cmd": combo["cmd"],
                "executed": self.executor.live_mode,
            }
            self.log_file.write(json.dumps(combo_event) + "\n")
            self.log_file.flush()

        # ── Triple-crash mode toggle ──
        mode_toggled = self.executor.check_triple_crash(note, now)

        # ── Mood engine ──
        current_mood = self.mood.update(velocity, ioi, note)

        # ── Rudiment detection ──
        self.rudiments.add_hit(note, velocity, now)
        rudiment_result = self.rudiments.check_rudiments()
        if rudiment_result:
            self.achievements.add_xp(rudiment_result["xp"], f"rudiment:{rudiment_result['name']}")
            rud_event = {
                "session": self.session_id, "t": round(now - self.start_time, 4),
                "ts": now, "type": "rudiment", "rudiment": rudiment_result["name"],
                "label": rudiment_result["label"], "tightness": round(rudiment_result["tightness"], 3),
            }
            self.log_file.write(json.dumps(rud_event) + "\n")
            self.log_file.flush()

        # ── Hawaiian War Chant detection ──
        self.war_chant.add_note(note, now)
        war_chant_triggered = self.war_chant.check_chant()
        war_chant_action = None
        war_chant_output = None
        war_chant_reason = None

        if war_chant_triggered:
            # Autopilot: predict and execute the next action
            last_combo = self.combos.combo_history[-1][0] if self.combos.combo_history else None
            action_name, reason = self.war_chant.predict_next_action(learner, last_combo, self)
            war_chant_action = action_name
            war_chant_reason = reason
            self.achievements.add_xp(25, "war_chant")

            if action_name and action_name in ComboSystem.COMBOS:
                combo_def = ComboSystem.COMBOS[action_name]
                war_chant_output = self.executor.execute(combo_def["cmd"], combo_def["desc"])
                # Record it as if a combo was executed
                self.combos.combo_history.append((action_name, now))
                self.combos.combo_counts[action_name] += 1
                self.war_chant.chant_history.append((now, self.war_chant.chain_count, action_name))

                chant_event = {
                    "session": self.session_id, "t": round(now - self.start_time, 4),
                    "ts": now, "type": "war_chant", "action": action_name,
                    "reason": reason, "chain": self.war_chant.chain_count,
                    "executed": self.executor.live_mode,
                }
                self.log_file.write(json.dumps(chant_event) + "\n")
                self.log_file.flush()
        else:
            # If we got a normal combo or non-chant activity, check if we should break chain
            if self.war_chant.active and not combo_result:
                # Give 3 seconds of grace before breaking chain
                if now - self.war_chant.last_chant_time > 3.0:
                    self.war_chant.break_chain()

        # ── Achievement checks (every 5 hits) ──
        if self.total_hits % 5 == 0:
            self.achievements.check_badges(self)
            self.achievements.update_streak(self.bpm)

        return {
            "info": info, "ioi": ioi, "prediction": prediction_result,
            "phrase": phrase_result, "gesture": gesture_result,
            "combo": combo_result, "cmd_output": cmd_output,
            "mood": current_mood, "rudiment": rudiment_result,
            "mode_toggled": mode_toggled,
            "war_chant": war_chant_triggered,
            "war_chant_action": war_chant_action,
            "war_chant_output": war_chant_output,
            "war_chant_reason": war_chant_reason,
        }

    @property
    def prediction_accuracy(self):
        if self.predictions_total == 0: return 0.0
        return self.predictions_correct / self.predictions_total

    @property
    def avg_velocity(self):
        if not self.velocity_history: return 0
        return sum(self.velocity_history) / len(self.velocity_history)

    @property
    def duration(self):
        return time.time() - self.start_time

    def close(self, learner):
        """Finalize session."""
        self.log_file.close()
        try:
            dominant = self.note_counts.most_common(1)[0][0] if self.note_counts else 0
            c = self.db.cursor()
            c.execute("""INSERT OR REPLACE INTO sessions
                (session_id, start_time, end_time, total_hits, avg_velocity, avg_bpm, dominant_note, notes_json)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                (self.session_id, self.start_time, time.time(), self.total_hits,
                 self.avg_velocity, self.bpm, dominant, json.dumps(dict(self.note_counts))))
            self.db.commit()
        except Exception:
            pass


# ══════════════════════════════════════════════════════════════
#  DISPLAY
# ══════════════════════════════════════════════════════════════
def velocity_bar(v, w=20):
    filled = int((v/127)*w)
    if v >= 100: c, ch = RED, "█"
    elif v >= 60: c, ch = AMBER, "▓"
    else: c, ch = GREEN, "░"
    return c + ch*filled + GRAY + "·"*(w-filled) + RESET

def zone_bar(zone_counts, total):
    parts = []
    for z, col in [("C",CYAN),("L",BLUE),("R",VIOLET),("D",PINK),("X",AMBER)]:
        pct = zone_counts.get(z, 0) / max(total, 1)
        w = int(pct * 15)
        parts.append(f"{col}{z}{'█'*w}{'·'*(3-min(w,3))}{RESET}")
    return " ".join(parts)

def print_header():
    os.system("clear")
    print(f"""
{PINK}╔══════════════════════════════════════════════════════════════════╗
║{WHITE}        🥁  BLACKROAD CONDUCTOR ML  🥁                           {PINK}║
║{DIM}     MIDI Intelligence · Combos · Rudiments · ML · Gestures      {PINK}║
╠══════════════════════════════════════════════════════════════════╣{RESET}
{DIM}  🎮 Combos: Note sequences trigger real commands{RESET}
{DIM}  🔥 Mood: Real-time energy classification{RESET}
{DIM}  🥁 Rudiments: Paradiddle, flam, double stroke detection{RESET}
{DIM}  ⭐ Achievements: XP, levels, badges, streaks{RESET}
{DIM}  🎯 Gestures: Draw shapes in the air{RESET}
{DIM}  🪘 War Chant: tom-tom-SNARE cadence = AUTOPILOT next action{RESET}
{DIM}  🧠 ML: Phrase clustering + next-note prediction{RESET}
{DIM}  ⚡ Triple-crash (D1×3) toggles LIVE command execution{RESET}
{PINK}╚══════════════════════════════════════════════════════════════════╝{RESET}
""")

def print_hit_line(result, session):
    """Print a single hit line with all indicators."""
    info = result["info"]
    velocity = session.velocity_history[-1] if session.velocity_history else 0
    ioi = result["ioi"]
    bpm = session.bpm
    prediction = result["prediction"]
    phrase = result["phrase"]
    gesture = result["gesture"]
    combo = result["combo"]
    cmd_output = result["cmd_output"]
    mood = result["mood"]
    rudiment = result["rudiment"]
    mode_toggled = result["mode_toggled"]
    total = session.total_hits

    color = info["color"]
    name = info["name"]
    bar = velocity_bar(velocity)
    mood_info = MoodEngine.MOODS.get(mood, MoodEngine.MOODS["FLOWING"])

    # Prediction indicator
    pred_str = ""
    if prediction:
        pred_info = note_info(prediction["predicted"])
        if prediction["correct"]:
            pred_str = f" {GREEN}✓ {pred_info['short']}{RESET}"
        else:
            pred_str = f" {RED}✗ {pred_info['short']}{RESET}"

    ioi_str = f"{ioi*1000:5.0f}ms" if ioi > 0 else "  ---"
    bpm_str = f"{bpm:5.0f}" if bpm > 0 else "  ---"

    # Main hit line with mood indicator
    print(f"  {mood_info['color']}{mood_info['icon']}{RESET} "
          f"{GRAY}{total:>4}{RESET} {color}{BOLD}{name:>8}{RESET} {bar} "
          f"v={velocity:>3} {GRAY}ioi={ioi_str} bpm={bpm_str}{RESET}{pred_str}")

    # ── Mode toggle notification ──
    if mode_toggled:
        mode = session.executor.live_mode
        if mode:
            print(f"    {RED}{BOLD}⚡⚡⚡ LIVE MODE ACTIVATED ⚡⚡⚡ Commands will execute!{RESET}")
        else:
            print(f"    {GREEN}{BOLD}🛡️🛡️🛡️ SAFE MODE ─ Display only{RESET}")

    # ── Phrase indicator ──
    if phrase:
        label = phrase["label"]
        cid = phrase["cluster_id"]
        if "ANOMALY" in label:
            print(f"    {RED}⚠ {label}{RESET}")
        elif cid >= 0:
            print(f"    {CYAN}◆ Phrase → [{cid}] {label}{RESET}")

    # ── Gesture indicator ──
    if gesture:
        g = SpatialRecognizer.GESTURES.get(gesture, {})
        icon = g.get("icon", "?")
        label = g.get("label", gesture)
        action = g.get("action", "")
        print(f"    {YELLOW}🎯 GESTURE: {icon} {label} → {action}{RESET}")

    # ── Combo indicator ──
    if combo:
        c = ComboSystem.COMBOS[combo]
        streak = session.combos.combo_streak
        streak_str = f" {AMBER}x{streak} STREAK!{RESET}" if streak > 1 else ""
        print(f"    {GREEN}{BOLD}🎮 COMBO: {c['desc']}{RESET}{streak_str}")
        if session.executor.live_mode and cmd_output:
            for line in cmd_output.split("\n")[:5]:
                print(f"    {DIM}  > {line}{RESET}")
        elif not session.executor.live_mode:
            print(f"    {DIM}  $ {c['cmd']} (display only - triple-D1 to go live){RESET}")

    # ── Rudiment indicator ──
    if rudiment:
        tight_bar = "█" * int(rudiment["tightness"] * 10) + "·" * (10 - int(rudiment["tightness"] * 10))
        tight_col = GREEN if rudiment["tightness"] > 0.7 else AMBER if rudiment["tightness"] > 0.4 else RED
        print(f"    {VIOLET}{rudiment['icon']} RUDIMENT: {rudiment['label']} "
              f"{tight_col}[{tight_bar}] {rudiment['tightness']*100:.0f}% tight{RESET} "
              f"{DIM}+{rudiment['xp']}xp{RESET}")

    # ── Hawaiian War Chant / Autopilot ──
    if result.get("war_chant"):
        chain = session.war_chant.chain_count
        action = result.get("war_chant_action", "?")
        reason = result.get("war_chant_reason", "")
        wc_output = result.get("war_chant_output")
        action_desc = ComboSystem.COMBOS.get(action, {}).get("desc", action)

        chain_fire = "🔥" * min(chain, 5)
        print(f"    {PINK}{BOLD}🪘🪘🪘 HAWAIIAN WAR CHANT! {chain_fire} Chain ×{chain}{RESET}")
        print(f"    {PINK}   ➜ AUTOPILOT: {WHITE}{action_desc}{RESET} {DIM}({reason}){RESET}")

        if session.executor.live_mode and wc_output:
            for line in wc_output.split("\n")[:5]:
                print(f"    {DIM}  > {line}{RESET}")
        elif not session.executor.live_mode:
            cmd = ComboSystem.COMBOS.get(action, {}).get("cmd", "")
            print(f"    {DIM}  $ {cmd} (display only){RESET}")

        # Show what's predicted next if they keep chanting
        if action in WarChant.COMBO_FLOW:
            next_candidates = WarChant.COMBO_FLOW[action][:3]
            next_names = [ComboSystem.COMBOS.get(c, {}).get("desc", c) for c in next_candidates]
            print(f"    {DIM}   🪘 chant again → {' | '.join(next_names)}{RESET}")

    elif session.war_chant.active:
        # Autopilot is active but this hit isn't a chant — show status
        print(f"    {DIM}🪘 autopilot active (chain ×{session.war_chant.chain_count}) "
              f"— chant again to continue, or play normally to break{RESET}")

    # ── Achievement notifications ──
    for ntype, msg in session.achievements.get_notifications():
        if ntype == "level_up":
            print(f"    {YELLOW}{BOLD}⬆️  {msg}{RESET}")
        elif ntype == "badge":
            print(f"    {GREEN}{BOLD}🏆 {msg}{RESET}")

def print_status(session, learner):
    dur = session.duration
    mins, secs = int(dur//60), int(dur%60)
    ach = session.achievements

    # ── Status bar ──
    mood_info = session.mood.mood_info
    mode_str = f"{RED}⚡LIVE{RESET}" if session.executor.live_mode else f"{GREEN}🛡️SAFE{RESET}"
    level_bar = "█" * int(ach.level_progress * 10) + "·" * (10 - int(ach.level_progress * 10))

    print(f"\n  {PINK}{'═'*62}{RESET}")
    print(f"  {mood_info['color']}{mood_info['icon']} {mood_info['desc']}{RESET} "
          f"│ {mode_str} "
          f"│ {WHITE}Lv{ach.level}{RESET} {GRAY}[{level_bar}]{RESET} {DIM}{ach.xp}xp{RESET} "
          f"│ {DIM}🏆{len(ach.unlocked)}/{len(AchievementSystem.BADGES)}{RESET}")
    print(f"  {PINK}{'─'*62}{RESET}")

    # Note distribution
    print(f"  {WHITE}Notes:{RESET}", end="")
    for note, count in session.note_counts.most_common(6):
        info = note_info(note)
        pct = count / max(session.total_hits, 1) * 100
        print(f"  {info['color']}{info['short']}:{count}({pct:.0f}%){RESET}", end="")
    print()

    # Zones
    print(f"  {WHITE}Zones:{RESET} {zone_bar(session.zone_counts, session.total_hits)}")

    # Stats
    acc = session.prediction_accuracy * 100
    acc_col = GREEN if acc > 60 else AMBER if acc > 40 else RED
    print(f"  {WHITE}Stats:{RESET} {DIM}hits={session.total_hits} "
          f"time={mins}m{secs}s "
          f"avg_vel={session.avg_velocity:.0f} "
          f"bpm={session.bpm:.0f} "
          f"predict={acc_col}{acc:.0f}%{RESET}")

    # BPM streak
    if session.achievements.current_streak_secs > 5:
        streak_secs = session.achievements.current_streak_secs
        print(f"  {WHITE}Streak:{RESET} {GREEN}🔥 {streak_secs:.0f}s at ~{session.achievements.streak_bpm_target:.0f} BPM{RESET}"
              f" {DIM}(best: {session.achievements.best_streak_secs:.0f}s){RESET}")

    # Mood history
    if len(session.mood.mood_history) > 1:
        print(f"  {WHITE}Mood:{RESET}", end="")
        for m, _ in session.mood.mood_history[-6:]:
            mi = MoodEngine.MOODS.get(m, MoodEngine.MOODS["FLOWING"])
            print(f" {mi['color']}{mi['icon']}{RESET}", end="")
        print(f" {DIM}← {mood_info['color']}{session.mood.current_mood}{RESET}")

    # Combos
    if session.combos.combo_counts:
        print(f"  {WHITE}Combos:{RESET}", end="")
        for name, count in session.combos.combo_counts.most_common(4):
            c = ComboSystem.COMBOS.get(name, {})
            print(f"  {GREEN}{c.get('desc', name)}×{count}{RESET}", end="")
        print(f"  {DIM}(best streak: {session.combos.max_combo_streak}){RESET}")

    # Rudiments
    if session.rudiments.rudiment_counts:
        print(f"  {WHITE}Rudiments:{RESET}", end="")
        for name, count in session.rudiments.rudiment_counts.most_common(4):
            rud = RudimentDetector.RUDIMENTS.get(name, {"icon": "🥁", "label": name})
            if name == "flam": rud = {"icon": "🔨", "label": "Flam"}
            print(f"  {VIOLET}{rud['icon']}{rud['label']}×{count}{RESET}", end="")
        print()

    # War Chant / Autopilot
    wc = session.war_chant
    if wc.total_chants > 0 or wc.active:
        active_str = f"{PINK}🪘 ACTIVE chain ×{wc.chain_count}{RESET}" if wc.active else f"{DIM}idle{RESET}"
        print(f"  {WHITE}War Chant:{RESET} {active_str} "
              f"{DIM}(total: {wc.total_chants} chants, best chain: {wc.max_chain}){RESET}")

    # Clusters
    summary = learner.get_cluster_summary()
    if "not yet" not in summary:
        print(f"  {WHITE}Clusters:{RESET}")
        for line in summary.split("\n"):
            print(f"  {CYAN}{line}{RESET}")

    # Next note prediction
    if session.prev_note is not None:
        pred_note, conf = learner.predict_next(session.prev_note)
        if pred_note is not None:
            pred_info = note_info(pred_note)
            conf_bar = "█" * int(conf * 10) + "·" * (10 - int(conf * 10))
            print(f"  {WHITE}Predict:{RESET} {pred_info['color']}{pred_info['name']}{RESET} "
                  f"{GRAY}[{conf_bar}] {conf*100:.0f}%{RESET}")

    # Gesture history
    recent_gestures = session.spatial.gesture_history[-5:]
    if recent_gestures:
        print(f"  {WHITE}Gestures:{RESET}", end="")
        for gtype, gtime in recent_gestures:
            g = SpatialRecognizer.GESTURES.get(gtype, {})
            icon = g.get("icon", "?")
            ago = time.time() - gtime
            print(f"  {YELLOW}{icon}({ago:.0f}s){RESET}", end="")
        print()

    # Recent badges
    recent_badges = sorted(
        [(k, v) for k, v in AchievementSystem.BADGES.items() if k in ach.unlocked],
        key=lambda x: x[0]
    )[-5:]
    if recent_badges:
        print(f"  {WHITE}Badges:{RESET}", end="")
        for key, badge in recent_badges:
            print(f" {badge['icon']}", end="")
        unearned = len(AchievementSystem.BADGES) - len(ach.unlocked)
        if unearned > 0:
            print(f" {DIM}+{unearned} locked{RESET}", end="")
        print()

    print(f"  {PINK}{'═'*62}{RESET}\n")


# ══════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════
def main():
    global _mixer, _sound_evo, SYNTH_MAP
    print_header()

    # Initialize audio mixer (single persistent stream)
    _mixer = AudioMixer()

    db = init_db()
    brain = Brain(db)
    learner = PatternLearner(db)
    session = Session(db)

    # Brain startup
    brain_info = brain.start_session(session.session_id)
    _sound_evo = brain.sound_level
    SYNTH_MAP = _make_synth_map()

    # Apply learned filter params to MidiFilter defaults
    learned_debounce = brain.get("filter.debounce_ms", 0)
    if learned_debounce > 0:
        MidiFilter.DEBOUNCE_MS = learned_debounce
    learned_vel_floor = brain.get("filter.min_velocity", 0)
    if learned_vel_floor > 0:
        MidiFilter.MIN_VELOCITY = learned_vel_floor

    # Count past sessions
    c = db.cursor()
    c.execute("SELECT COUNT(*) FROM sessions")
    past = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM hits")
    past_hits = c.fetchone()[0]
    c.execute("SELECT COUNT(*) FROM patterns")
    past_patterns = c.fetchone()[0]

    print(f"  {GREEN}✓ Database: {past} past sessions, {past_hits} hits, {past_patterns} patterns{RESET}")
    if learner.fitted:
        print(f"  {GREEN}✓ ML model warm-started from history{RESET}")
    else:
        print(f"  {AMBER}○ ML model needs {learner.min_phrases_to_fit - len(learner.phrases)} more phrases to fit{RESET}")

    # Brain status
    evo_names = ["Basic", "Developing", "Warm", "Rich", "Epic", "Legendary"]
    evo_icons = ["🔵", "🟢", "🟡", "🟠", "🔴", "👑"]
    print(f"  {GREEN}✓ Brain: Session #{brain_info['session_num']} | "
          f"{brain_info['total_hits']} lifetime hits | "
          f"Sound: {evo_icons[_sound_evo]} {evo_names[_sound_evo]}{RESET}")
    if brain.improvements_this_session:
        for key, old, new, reason in brain.improvements_this_session:
            print(f"    {AMBER}🧠 {reason}{RESET}")

    try:
        port = mido.open_input("USB MIDI")
    except Exception as e:
        print(f"\n  {RED}Error: Could not open USB MIDI: {e}{RESET}")
        print(f"  {DIM}Is the Kalezo receiver plugged in?{RESET}")
        sys.exit(1)

    print(f"  {GREEN}✓ Connected to USB MIDI{RESET}")
    print(f"  {DIM}Session: {session.session_id}{RESET}")
    print(f"  {DIM}Level {session.achievements.level} | {session.achievements.xp} XP | "
          f"{len(session.achievements.unlocked)} badges{RESET}")
    print(f"  {DIM}Mode: 🛡️ SAFE (display only) - triple-D1 (D1×3) to toggle LIVE{RESET}")
    bank = VOICE_BANKS[_current_voice]
    print(f"  {DIM}Controls: Sticks → play | Stomp → low note | Double-stomp → cycle voice{RESET}")
    print(f"  {DIM}Voice: {bank['icon']} {bank['name']}{RESET} {DIM}(🎹 Piano → 🥁 Drums → 🔔 Bells → 🎸 Bass){RESET}")
    print(f"  {DIM}Start drumming... (Ctrl+C to stop){RESET}\n")

    # Show available combos
    print(f"  {WHITE}Available Combos:{RESET}")
    for name, combo in sorted(ComboSystem.COMBOS.items(), key=lambda x: len(x[1]["seq"])):
        seq_names = [note_info(n)["short"].strip() for n in combo["seq"]]
        print(f"    {DIM}{combo['cat']:>9}{RESET} {GREEN}{combo['desc']:<18}{RESET} "
              f"{GRAY}{'→'.join(seq_names)}{RESET}")

    # Show war chant patterns
    print(f"\n  {PINK}🪘 Hawaiian War Chant (AUTOPILOT):{RESET}")
    print(f"    {DIM}Play any tom-tom-SNARE cadence to auto-execute the next predicted action{RESET}")
    shown_patterns = [
        ([47, 48, 38, 47, 48, 38], "Classic R-L-Snare"),
        ([48, 47, 38, 48, 47, 38], "Classic L-R-Snare"),
        ([36, 47, 48, 38, 47, 48, 38], "Kick accent"),
        ([42, 47, 38, 42, 47, 38], "Hi-hat variant"),
        ([47, 48, 38, 38], "Short cadence"),
    ]
    for pattern, label in shown_patterns:
        seq_names = [note_info(n)["short"].strip() for n in pattern]
        print(f"    {PINK}{'→'.join(seq_names)}{RESET} {DIM}{label}{RESET}")
    print(f"    {DIM}Chain multiple chants for autopilot combos!{RESET}")
    print()

    status_counter = 0
    last_hit_time = time.time()
    idle_warned = False
    midi_filter = MidiFilter()

    try:
        while True:
            # --- Poll-based MIDI reading (reliable, non-blocking) ---
            msg = port.poll()
            if msg is not None:
                if msg.type == "note_on" and msg.velocity > 0:
                    now = time.time()

                    # Remap raw MIDI to quad drum (1-4)
                    drum = remap_note(msg.note)

                    # Filter ghost hits, double-triggers, cross-talk
                    if not midi_filter.accept(drum, msg.velocity, now):
                        continue

                    # Double-stomp = cycle voice bank (2 stomps within 400ms)
                    if drum == 3:
                        if hasattr(session, '_last_stomp') and (now - session._last_stomp) < 0.4:
                            bank = cycle_voice()
                            print(f"\r  {AMBER}🔄 Voice: {bank['icon']} {bank['name']}{RESET}              ")
                            session._last_stomp = 0
                            continue  # don't play the stomp, just switch
                        session._last_stomp = now

                    last_hit_time = now
                    idle_warned = False

                    # Play sound (non-blocking via mixer)
                    play_sound(drum, msg.velocity)

                    # Process (returns dict with all subsystem results)
                    result = session.process_hit(drum, msg.velocity, learner)

                    # Display
                    print_hit_line(result, session)

                    # Periodic status
                    status_counter += 1
                    if status_counter % 15 == 0:
                        print_status(session, learner)
            else:
                # No message — sleep briefly to avoid CPU spin
                time.sleep(0.001)

                # Idle warning after 30s of no hits
                idle_gap = time.time() - last_hit_time
                if idle_gap > 30 and not idle_warned and session.total_hits > 0:
                    print(f"\r  {DIM}💤 No hits for 30s — sticks asleep? Wave to wake.{RESET}    ")
                    idle_warned = True

                # Auto-reconnect if port goes stale (sticks slept > 60s)
                if idle_gap > 60 and session.total_hits > 0:
                    try:
                        # Test if port is still alive
                        if port.closed:
                            raise IOError("port closed")
                    except Exception:
                        print(f"\r  {AMBER}🔄 Reconnecting to USB MIDI...{RESET}    ")
                        try:
                            port.close()
                        except Exception:
                            pass
                        try:
                            port = mido.open_input("USB MIDI")
                            print(f"\r  {GREEN}✓ Reconnected to USB MIDI{RESET}              ")
                            last_hit_time = time.time()
                            idle_warned = False
                        except Exception:
                            print(f"\r  {RED}✗ USB MIDI not found — waiting...{RESET}    ")
                            time.sleep(3)

    except KeyboardInterrupt:
        pass
    finally:
        try:
            port.close()
        except Exception:
            pass
        if _mixer:
            _mixer.close()
        session.achievements._save()

        # Brain learns from this session
        timestamps = [h[0] for h in session.hits]
        iois = [timestamps[i+1] - timestamps[i] for i in range(len(timestamps)-1)]
        brain.end_session(session.session_id, session.total_hits,
                          session.achievements.xp, iois)
        brain.learn_predictions(session.predictions_correct, session.predictions_total,
                                session.session_id)

        session.close(learner)

        # Final summary
        dur = session.duration
        mins, secs = int(dur//60), int(dur%60)
        ach = session.achievements

        print(f"\n\n{PINK}{'═'*64}{RESET}")
        print(f"  {WHITE}🥁 SESSION COMPLETE{RESET}")
        print(f"{PINK}{'═'*64}{RESET}")

        # Core stats
        print(f"  {DIM}Session:{RESET}      {session.session_id}")
        print(f"  {DIM}Duration:{RESET}     {mins}m {secs}s")
        print(f"  {DIM}Total hits:{RESET}   {session.total_hits}")
        print(f"  {DIM}Avg velocity:{RESET} {session.avg_velocity:.0f}")
        print(f"  {DIM}Avg BPM:{RESET}      {session.bpm:.0f}")
        print(f"  {DIM}Prediction:{RESET}   {session.prediction_accuracy*100:.1f}% "
              f"({session.predictions_correct}/{session.predictions_total})")
        if midi_filter.suppressed > 0:
            total_raw = midi_filter.passed + midi_filter.suppressed
            print(f"  {DIM}MIDI filter:{RESET}  {midi_filter.suppressed} ghosts suppressed "
                  f"({midi_filter.suppressed*100//total_raw}% of {total_raw} raw)")

        # XP & Level
        print(f"\n  {AMBER}{'─'*40}{RESET}")
        level_bar = "█" * int(ach.level_progress * 20) + "·" * (20 - int(ach.level_progress * 20))
        print(f"  {WHITE}⭐ Level {ach.level}{RESET} {GRAY}[{level_bar}]{RESET} {DIM}{ach.xp} XP total{RESET}")
        if ach.xp_to_next > 0:
            print(f"  {DIM}   {ach.xp_to_next} XP to next level{RESET}")

        # Badges
        if ach.unlocked:
            print(f"\n  {WHITE}🏆 Badges ({len(ach.unlocked)}/{len(AchievementSystem.BADGES)}):{RESET}")
            for key in sorted(ach.unlocked):
                badge = AchievementSystem.BADGES.get(key, {})
                print(f"    {badge.get('icon', '?')} {badge.get('name', key)} - {DIM}{badge.get('desc', '')}{RESET}")

        # BPM streak
        if ach.best_streak_secs > 5:
            print(f"\n  {WHITE}🔥 Best BPM Streak:{RESET} {GREEN}{ach.best_streak_secs:.0f}s{RESET}")

        # Notes
        print(f"\n  {DIM}Notes:{RESET}")
        for note, count in session.note_counts.most_common(8):
            info = note_info(note)
            pct = count / max(session.total_hits, 1) * 100
            bar = info["color"] + "█" * int(pct/3) + RESET
            print(f"    {info['color']}{info['name']:>8}{RESET} {bar} {count} ({pct:.1f}%)")

        # Mood journey
        if session.mood.mood_history:
            print(f"\n  {DIM}Mood Journey:{RESET}")
            print(f"    ", end="")
            for m, _ in session.mood.mood_history:
                mi = MoodEngine.MOODS.get(m, MoodEngine.MOODS["FLOWING"])
                print(f"{mi['color']}{mi['icon']}{RESET} ", end="")
            print()
            print(f"  {DIM}Time in each mood:{RESET}")
            session.mood.mood_durations[session.mood.current_mood] += time.time() - session.mood.last_mood_change
            for m, secs in session.mood.mood_durations.most_common():
                mi = MoodEngine.MOODS.get(m, MoodEngine.MOODS["FLOWING"])
                print(f"    {mi['color']}{mi['icon']} {m:<12}{RESET} {secs:.0f}s")

        # Combos
        if session.combos.combo_counts:
            print(f"\n  {DIM}Combos executed:{RESET}")
            for name, count in session.combos.combo_counts.most_common():
                c = ComboSystem.COMBOS.get(name, {})
                print(f"    {GREEN}{c.get('desc', name)}{RESET} x{count}")
            if session.combos.max_combo_streak > 1:
                print(f"    {AMBER}Best combo streak: {session.combos.max_combo_streak}{RESET}")

        # Rudiments
        if session.rudiments.rudiment_counts:
            print(f"\n  {DIM}Rudiments detected:{RESET}")
            for name, count in session.rudiments.rudiment_counts.most_common():
                rud = RudimentDetector.RUDIMENTS.get(name, {"icon": "🥁", "label": name})
                if name == "flam": rud = {"icon": "🔨", "label": "Flam"}
                # Get average tightness
                tights = [t for n, _, t in session.rudiments.detected_history if n == name]
                avg_tight = np.mean(tights) if tights else 0
                print(f"    {VIOLET}{rud['icon']} {rud['label']}{RESET} x{count} "
                      f"{DIM}(avg tightness: {avg_tight*100:.0f}%){RESET}")

        # War Chant summary
        wc = session.war_chant
        if wc.total_chants > 0:
            print(f"\n  {DIM}Hawaiian War Chant:{RESET}")
            print(f"    {PINK}🪘 Total chants:{RESET} {wc.total_chants}")
            print(f"    {PINK}🔥 Best chain:{RESET} {wc.max_chain}")
            if wc.chant_history:
                print(f"    {DIM}Autopilot actions:{RESET}")
                for ts, chain, action in wc.chant_history[-8:]:
                    if action == "chain_broken":
                        print(f"      {DIM}chain broken (×{chain}){RESET}")
                    else:
                        desc = ComboSystem.COMBOS.get(action, {}).get("desc", action)
                        print(f"      {PINK}→{RESET} {desc} {DIM}(chain ×{chain}){RESET}")

        # Gestures
        if session.spatial.gesture_history:
            print(f"\n  {DIM}Gestures detected:{RESET}")
            gesture_counts = Counter(g for g, _ in session.spatial.gesture_history)
            for gtype, count in gesture_counts.most_common():
                g = SpatialRecognizer.GESTURES.get(gtype, {})
                icon = g.get("icon", "?")
                label = g.get("label", gtype)
                print(f"    {YELLOW}{icon} {label}{RESET} x{count}")

        # Cluster summary
        summary = learner.get_cluster_summary()
        if "not yet" not in summary:
            print(f"\n  {DIM}Learned patterns:{RESET}")
            for line in summary.split("\n"):
                print(f"  {CYAN}{line}{RESET}")

        # Commands executed
        live_cmds = [c for c in session.executor.command_history if c[3]]
        if live_cmds:
            print(f"\n  {DIM}Commands executed (live):{RESET}")
            for cmd, output, _, _ in live_cmds[-10:]:
                print(f"    {GREEN}${RESET} {cmd}")

        # Brain improvement report
        improvements = brain.improvement_report()
        if improvements:
            print(f"\n  {AMBER}🧠 SELF-IMPROVEMENTS THIS SESSION:{RESET}")
            for line in improvements:
                print(f"    {AMBER}{line}{RESET}")

        # Sound evolution status
        evo_names = ["Basic", "Developing", "Warm", "Rich", "Epic", "Legendary"]
        evo_icons = ["🔵", "🟢", "🟡", "🟠", "🔴", "👑"]
        new_evo = brain.sound_level
        print(f"\n  {DIM}Sound:{RESET} {evo_icons[new_evo]} {evo_names[new_evo]} (level {new_evo}/5)")
        total_xp_all = brain.get("stats.total_xp", 0)
        next_thresholds = [100, 500, 2000, 5000, 10000]
        if new_evo < 5:
            needed = next_thresholds[new_evo] - total_xp_all
            print(f"  {DIM}       {needed:.0f} XP to next evolution{RESET}")

        lifetime = brain.get("stats.total_hits", 0)
        sessions = brain.get("stats.sessions", 0)
        print(f"  {DIM}Brain:{RESET} {lifetime:.0f} lifetime hits across {sessions:.0f} sessions")

        print(f"\n  {DIM}Data saved to:{RESET}")
        print(f"    {GREEN}{DB_PATH}{RESET}")
        print(f"    {GREEN}{LOG_PATH}{RESET}")
        print(f"{PINK}{'═'*64}{RESET}\n")

        db.close()


if __name__ == "__main__":
    main()
