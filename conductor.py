#!/usr/bin/env python3
"""
BlackRoad Conductor v2 - Orchestrate with Aerband Drumsticks

Features:
  - Drum sounds (synthesized)
  - Agent dispatch on hard hits
  - Spatial zone recognition (left/right/center/cross-body)
  - Pattern matching (rudiments → workflows)
  - BPM detection (tempo → urgency)
  - Gesture detection (rolls, flams, sweeps)
  - Dynamic intensity tracking (crescendo/decrescendo)
"""

import mido
import sounddevice as sd
import numpy as np
import sys
import os
import subprocess
import threading
import time
from collections import deque

# ─── Audio Config ───
SAMPLE_RATE = 44100
DEVICE = 2  # MacBook Pro Speakers

# ─── Colors ───
RESET  = "\033[0m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
PINK   = "\033[38;5;205m"
AMBER  = "\033[38;5;214m"
BLUE   = "\033[38;5;69m"
VIOLET = "\033[38;5;135m"
GREEN  = "\033[38;5;82m"
WHITE  = "\033[1;37m"
RED    = "\033[38;5;196m"
CYAN   = "\033[38;5;87m"
GRAY   = "\033[38;5;240m"

# ─── MIDI Mapping (Aerband on channel 9) ───
# Spatial zones: L=left hand, R=right hand, D=down, X=cross
DRUM_MAP = {
    36: {"name": "KICK",  "color": PINK,   "agent": "OCTAVIA", "cmd": "deploy",   "zone": "D", "hand": "L"},
    38: {"name": "SNARE", "color": AMBER,  "agent": "CIPHER",  "cmd": "security", "zone": "X", "hand": "R"},
    47: {"name": "TOM-R", "color": VIOLET, "agent": "LUCIDIA", "cmd": "think",    "zone": "R", "hand": "R"},
    48: {"name": "TOM-L", "color": BLUE,   "agent": "ALICE",   "cmd": "route",    "zone": "L", "hand": "L"},
}

# ─── Thresholds ───
AGENT_VELOCITY = 100
SOFT_MAX = 60
FLAM_WINDOW = 0.04      # seconds - two hits within this = flam
ROLL_WINDOW = 0.12       # seconds - rapid alternating hits
PATTERN_TIMEOUT = 2.0    # seconds - pattern resets after this gap

# ──────────────────────────────────────────────────────────────
#  PATTERN DEFINITIONS
#  Each pattern is a sequence of note values that triggers
#  a specific multi-agent workflow
# ──────────────────────────────────────────────────────────────
PATTERNS = {
    # Rudiment-style patterns → agent workflows
    "paradiddle": {
        "sequence": [47, 48, 47, 47],  # R-L-R-R
        "name": "PARADIDDLE",
        "action": "Full system scan",
        "agents": ["LUCIDIA", "CIPHER", "ALICE"],
        "color": CYAN,
        "icon": "🌀",
    },
    "double_stroke": {
        "sequence": [47, 47, 48, 48],  # R-R-L-L
        "name": "DOUBLE STROKE",
        "action": "Deploy pipeline",
        "agents": ["OCTAVIA", "ALICE"],
        "color": PINK,
        "icon": "🚀",
    },
    "kick_snare_4": {
        "sequence": [36, 38, 36, 38],  # K-S-K-S
        "name": "FOUR ON FLOOR",
        "action": "Health check all services",
        "agents": ["PRISM", "ECHO"],
        "color": GREEN,
        "icon": "💚",
    },
    "fill_descend": {
        "sequence": [48, 47, 38, 36],  # L-R-S-K (descending fill)
        "name": "DESCENDING FILL",
        "action": "Graceful shutdown cascade",
        "agents": ["ALICE", "OCTAVIA", "CIPHER"],
        "color": AMBER,
        "icon": "🌊",
    },
    "fill_ascend": {
        "sequence": [36, 38, 47, 48],  # K-S-R-L (ascending fill)
        "name": "ASCENDING FILL",
        "action": "Scale up all services",
        "agents": ["OCTAVIA", "ALICE", "LUCIDIA"],
        "color": VIOLET,
        "icon": "⬆️",
    },
    "all_toms": {
        "sequence": [48, 47, 48, 47, 48, 47],  # L-R-L-R-L-R
        "name": "TOM ROLL",
        "action": "Broadcast to all agents",
        "agents": ["ALL"],
        "color": RED,
        "icon": "📡",
    },
}

# ──────────────────────────────────────────────────────────────
#  GESTURE DEFINITIONS
# ──────────────────────────────────────────────────────────────
GESTURES = {
    "flam": {
        "description": "Two hands nearly simultaneous",
        "action": "Snapshot system state",
        "icon": "📸",
    },
    "buzz_roll": {
        "description": "Rapid alternating hits (8+ in 1s)",
        "action": "Continuous monitoring mode",
        "icon": "📊",
    },
    "crescendo": {
        "description": "5+ hits with rising velocity",
        "action": "Scale UP - increase resources",
        "icon": "📈",
    },
    "decrescendo": {
        "description": "5+ hits with falling velocity",
        "action": "Scale DOWN - reduce resources",
        "icon": "📉",
    },
    "accent": {
        "description": "Sudden hard hit after soft hits",
        "action": "Priority alert",
        "icon": "❗",
    },
    "silence_break": {
        "description": "Hard hit after 3+ seconds silence",
        "action": "Wake all agents",
        "icon": "⚡",
    },
}


# ══════════════════════════════════════════════════════════════
#  STATE TRACKING
# ══════════════════════════════════════════════════════════════
class ConductorState:
    def __init__(self):
        # Hit tracking
        self.total_hits = 0
        self.agent_dispatches = 0
        self.combo_count = 0
        self.last_hit_time = 0.0

        # Pattern buffer - stores (note, velocity, timestamp)
        self.pattern_buffer = deque(maxlen=12)

        # Velocity history for dynamics detection
        self.velocity_history = deque(maxlen=10)

        # BPM tracking
        self.beat_times = deque(maxlen=16)
        self.current_bpm = 0.0

        # Spatial tracking
        self.zone_counts = {"L": 0, "R": 0, "D": 0, "X": 0}
        self.hand_balance = {"L": 0, "R": 0}

        # Gesture state
        self.roll_hits = deque(maxlen=20)  # timestamps of rapid hits
        self.last_gesture = ""
        self.last_gesture_time = 0.0
        self.gestures_triggered = 0
        self.patterns_matched = 0

        # Session start
        self.session_start = time.time()

        # Intensity tracking (rolling average)
        self.intensity_window = deque(maxlen=20)

    @property
    def session_duration(self):
        return time.time() - self.session_start

    @property
    def avg_velocity(self):
        if not self.velocity_history:
            return 0
        return sum(self.velocity_history) / len(self.velocity_history)

    @property
    def dominant_zone(self):
        if not any(self.zone_counts.values()):
            return "?"
        return max(self.zone_counts, key=self.zone_counts.get)

    @property
    def hand_bias(self):
        l, r = self.hand_balance["L"], self.hand_balance["R"]
        total = l + r
        if total == 0:
            return "balanced"
        ratio = r / total
        if ratio > 0.65:
            return "right-heavy"
        elif ratio < 0.35:
            return "left-heavy"
        return "balanced"

    @property
    def intensity_level(self):
        """0-100 intensity based on recent velocity and frequency."""
        if not self.intensity_window:
            return 0
        avg_vel = sum(v for _, v in self.intensity_window) / len(self.intensity_window)
        # Factor in hit frequency
        if len(self.intensity_window) >= 2:
            time_span = self.intensity_window[-1][0] - self.intensity_window[0][0]
            if time_span > 0:
                freq = len(self.intensity_window) / time_span
                freq_factor = min(freq / 8.0, 1.0)  # 8 hits/sec = max
            else:
                freq_factor = 0.5
        else:
            freq_factor = 0.3
        return min(100, int((avg_vel / 127.0) * 60 + freq_factor * 40))


state = ConductorState()


# ══════════════════════════════════════════════════════════════
#  AUDIO SYNTHESIS
# ══════════════════════════════════════════════════════════════
def synthesize_kick(velocity, duration=0.15):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
    amp = (velocity / 127.0) * 0.8
    freq = np.linspace(150, 40, len(t))
    phase = np.cumsum(freq / SAMPLE_RATE) * 2 * np.pi
    wave = amp * np.sin(phase) * np.exp(-t * 20)
    click = amp * 0.6 * np.random.randn(int(SAMPLE_RATE * 0.005))
    click_env = np.exp(-np.linspace(0, 10, len(click)))
    wave[:len(click)] += click * click_env
    return wave.astype(np.float32)


def synthesize_snare(velocity, duration=0.12):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
    amp = (velocity / 127.0) * 0.7
    body = amp * 0.5 * np.sin(2 * np.pi * 200 * t) * np.exp(-t * 30)
    noise = amp * 0.6 * np.random.randn(len(t)) * np.exp(-t * 25)
    return (body + noise).astype(np.float32)


def synthesize_tom(velocity, pitch_hz=120, duration=0.18):
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
    amp = (velocity / 127.0) * 0.7
    freq = np.linspace(pitch_hz * 1.3, pitch_hz, len(t))
    phase = np.cumsum(freq / SAMPLE_RATE) * 2 * np.pi
    wave = amp * np.sin(phase) * np.exp(-t * 15)
    wave += amp * 0.1 * np.random.randn(len(t)) * np.exp(-t * 40)
    return wave.astype(np.float32)


def synthesize_cymbal(velocity, duration=0.4):
    """Shimmer cymbal for special events."""
    t = np.linspace(0, duration, int(SAMPLE_RATE * duration), False)
    amp = (velocity / 127.0) * 0.3
    noise = amp * np.random.randn(len(t))
    # Bandpass-ish: multiple high sine components
    for f in [3000, 4500, 6000, 8000]:
        noise += amp * 0.15 * np.sin(2 * np.pi * f * t + np.random.rand() * 6.28)
    wave = noise * np.exp(-t * 5)
    return wave.astype(np.float32)


SYNTH_MAP = {
    36: lambda v: synthesize_kick(v),
    38: lambda v: synthesize_snare(v),
    47: lambda v: synthesize_tom(v, pitch_hz=100),
    48: lambda v: synthesize_tom(v, pitch_hz=140),
}


def play_sound(note, velocity):
    if note in SYNTH_MAP:
        wave = SYNTH_MAP[note](velocity)
        try:
            sd.play(wave, SAMPLE_RATE, device=DEVICE)
        except Exception:
            pass


def play_event_sound():
    """Play cymbal shimmer for pattern/gesture events."""
    wave = synthesize_cymbal(90)
    try:
        sd.play(wave, SAMPLE_RATE, device=DEVICE)
    except Exception:
        pass


# ══════════════════════════════════════════════════════════════
#  BPM DETECTION
# ══════════════════════════════════════════════════════════════
def update_bpm(now):
    state.beat_times.append(now)
    if len(state.beat_times) >= 4:
        intervals = []
        times = list(state.beat_times)
        for i in range(1, len(times)):
            intervals.append(times[i] - times[i - 1])
        avg_interval = sum(intervals) / len(intervals)
        if avg_interval > 0:
            state.current_bpm = 60.0 / avg_interval


def bpm_label():
    bpm = state.current_bpm
    if bpm == 0:
        return f"{GRAY}--- BPM{RESET}"
    if bpm < 80:
        return f"{GREEN}{bpm:5.0f} BPM {DIM}(chill){RESET}"
    elif bpm < 120:
        return f"{AMBER}{bpm:5.0f} BPM {DIM}(steady){RESET}"
    elif bpm < 160:
        return f"{PINK}{bpm:5.0f} BPM {DIM}(driving){RESET}"
    else:
        return f"{RED}{bpm:5.0f} BPM {DIM}(fury!){RESET}"


def urgency_from_bpm():
    """Map BPM to urgency level for agent commands."""
    bpm = state.current_bpm
    if bpm < 60:
        return "low"
    elif bpm < 120:
        return "normal"
    elif bpm < 160:
        return "high"
    return "critical"


# ══════════════════════════════════════════════════════════════
#  SPATIAL RECOGNITION
# ══════════════════════════════════════════════════════════════
def update_spatial(note):
    drum = DRUM_MAP.get(note)
    if drum:
        state.zone_counts[drum["zone"]] += 1
        state.hand_balance[drum["hand"]] += 1


def spatial_display():
    """Mini spatial map showing where you're hitting."""
    l = state.zone_counts["L"]
    r = state.zone_counts["R"]
    d = state.zone_counts["D"]
    x = state.zone_counts["X"]
    total = max(l + r + d + x, 1)

    def bar(count, max_w=8):
        pct = count / total
        filled = int(pct * max_w)
        return "█" * filled + "░" * (max_w - filled)

    return (f"{BLUE}L{bar(l)}{RESET} "
            f"{VIOLET}R{bar(r)}{RESET} "
            f"{PINK}D{bar(d)}{RESET} "
            f"{AMBER}X{bar(x)}{RESET}")


# ══════════════════════════════════════════════════════════════
#  PATTERN MATCHING
# ══════════════════════════════════════════════════════════════
def check_patterns(now):
    """Check if recent hits match any defined pattern."""
    # Clean old entries from buffer
    while state.pattern_buffer and (now - state.pattern_buffer[0][2]) > PATTERN_TIMEOUT:
        state.pattern_buffer.popleft()

    if len(state.pattern_buffer) < 4:
        return None

    recent_notes = [h[0] for h in state.pattern_buffer]

    for key, pattern in PATTERNS.items():
        seq = pattern["sequence"]
        seq_len = len(seq)
        if len(recent_notes) >= seq_len:
            # Check if the last N notes match the pattern
            if recent_notes[-seq_len:] == seq:
                state.patterns_matched += 1
                # Clear buffer to prevent re-triggering
                state.pattern_buffer.clear()
                return pattern

    return None


# ══════════════════════════════════════════════════════════════
#  GESTURE DETECTION
# ══════════════════════════════════════════════════════════════
def detect_gestures(note, velocity, now):
    """Detect musical gestures from hit patterns."""
    detected = []

    # ── Flam: two different notes within FLAM_WINDOW ──
    if len(state.pattern_buffer) >= 2:
        prev_note, prev_vel, prev_time = state.pattern_buffer[-2]
        if (now - prev_time) < FLAM_WINDOW and prev_note != note:
            detected.append(("flam", GESTURES["flam"]))

    # ── Silence Break: hard hit after long silence ──
    gap = now - state.last_hit_time if state.last_hit_time > 0 else 0
    if gap > 3.0 and velocity >= 80:
        detected.append(("silence_break", GESTURES["silence_break"]))

    # ── Accent: sudden loud hit after soft streak ──
    if len(state.velocity_history) >= 4:
        recent = list(state.velocity_history)[-4:-1]
        if all(v < SOFT_MAX for v in recent) and velocity >= AGENT_VELOCITY:
            detected.append(("accent", GESTURES["accent"]))

    # ── Buzz Roll: 8+ hits within 1 second ──
    state.roll_hits.append(now)
    # Clean old
    while state.roll_hits and (now - state.roll_hits[0]) > 1.0:
        state.roll_hits.popleft()
    if len(state.roll_hits) >= 8:
        # Only trigger once per roll
        if state.last_gesture != "buzz_roll" or (now - state.last_gesture_time) > 2.0:
            detected.append(("buzz_roll", GESTURES["buzz_roll"]))

    # ── Crescendo / Decrescendo: 5+ hits trending ──
    if len(state.velocity_history) >= 5:
        recent_v = list(state.velocity_history)[-5:]
        diffs = [recent_v[i+1] - recent_v[i] for i in range(len(recent_v)-1)]
        if all(d > 3 for d in diffs):
            detected.append(("crescendo", GESTURES["crescendo"]))
        elif all(d < -3 for d in diffs):
            detected.append(("decrescendo", GESTURES["decrescendo"]))

    return detected


# ══════════════════════════════════════════════════════════════
#  INTENSITY METER
# ══════════════════════════════════════════════════════════════
def intensity_bar(width=30):
    level = state.intensity_level
    filled = int((level / 100) * width)
    if level >= 80:
        color = RED
    elif level >= 50:
        color = AMBER
    elif level >= 25:
        color = GREEN
    else:
        color = GRAY
    return f"{color}{'█' * filled}{GRAY}{'░' * (width - filled)}{RESET} {level}%"


# ══════════════════════════════════════════════════════════════
#  AGENT DISPATCH
# ══════════════════════════════════════════════════════════════
def dispatch_agent(drum_info, velocity):
    state.agent_dispatches += 1
    agent = drum_info["agent"]
    cmd = drum_info["cmd"]
    color = drum_info["color"]
    urgency = urgency_from_bpm()

    print(f"\r{color}  ⚡ AGENT → {agent}.{cmd}() "
          f"[vel={velocity} urgency={urgency}]{RESET}")

    threading.Thread(
        target=_log_dispatch,
        args=(agent, cmd, velocity, urgency),
        daemon=True
    ).start()


def dispatch_pattern(pattern):
    """Trigger multi-agent workflow from pattern match."""
    color = pattern["color"]
    icon = pattern["icon"]
    name = pattern["name"]
    action = pattern["action"]
    agents = pattern["agents"]

    play_event_sound()

    print()
    print(f"  {color}{'━' * 56}{RESET}")
    print(f"  {color}{icon} PATTERN MATCHED: {BOLD}{name}{RESET}")
    print(f"  {color}  Action: {action}{RESET}")
    print(f"  {color}  Agents: {', '.join(agents)}{RESET}")
    print(f"  {color}{'━' * 56}{RESET}")
    print()

    threading.Thread(
        target=_log_pattern,
        args=(name, action, agents),
        daemon=True
    ).start()


def dispatch_gesture(gesture_key, gesture):
    """Trigger action from detected gesture."""
    state.gestures_triggered += 1
    state.last_gesture = gesture_key
    state.last_gesture_time = time.time()
    icon = gesture["icon"]
    desc = gesture["description"]
    action = gesture["action"]

    print(f"  {CYAN}{icon} GESTURE: {desc} → {BOLD}{action}{RESET}")


def _log_dispatch(agent, cmd, velocity, urgency):
    try:
        subprocess.run(
            [os.path.expanduser("~/memory-system.sh"),
             "log", "conductor", agent,
             f"Drumstick dispatch: {cmd} (vel={velocity}, urgency={urgency})",
             "conductor,aerband,midi"],
            capture_output=True, timeout=5
        )
    except Exception:
        pass


def _log_pattern(name, action, agents):
    try:
        subprocess.run(
            [os.path.expanduser("~/memory-system.sh"),
             "log", "conductor-pattern", name,
             f"Pattern workflow: {action} → agents={','.join(agents)}",
             "conductor,pattern,workflow"],
            capture_output=True, timeout=5
        )
    except Exception:
        pass


# ══════════════════════════════════════════════════════════════
#  DISPLAY
# ══════════════════════════════════════════════════════════════
def velocity_bar(velocity, width=16):
    filled = int((velocity / 127) * width)
    if velocity >= AGENT_VELOCITY:
        color = RED
        char = "█"
    elif velocity >= SOFT_MAX:
        color = AMBER
        char = "▓"
    else:
        color = GREEN
        char = "░"
    return color + char * filled + GRAY + "·" * (width - filled) + RESET


def print_header():
    os.system("clear")
    print(f"""
{PINK}╔══════════════════════════════════════════════════════════════════╗
║{WHITE}           🥁  BLACKROAD CONDUCTOR v2  🥁                        {PINK}║
║{DIM}     Spatial Recognition · Pattern Matching · Gesture Control    {PINK}║
╠══════════════════════════════════════════════════════════════════╣
║{RESET}  {GREEN}Soft hit{RESET}  → Drum sound    {RED}HARD HIT{RESET} → Agent dispatch (vel≥{AGENT_VELOCITY})  {PINK}║
║{RESET}  {CYAN}Pattern{RESET}   → Multi-agent workflow   {CYAN}Gesture{RESET} → System action  {PINK}║
╠══════════════════════════════════════════════════════════════════╣{RESET}
{DIM}  KICK  (36) → {PINK}OCTAVIA.deploy(){RESET}   {DIM}SNARE (38) → {AMBER}CIPHER.security(){RESET}
{DIM}  TOM-R (47) → {VIOLET}LUCIDIA.think(){RESET}   {DIM}TOM-L (48) → {BLUE}ALICE.route(){RESET}
{PINK}╠══════════════════════════════════════════════════════════════════╣{RESET}
{DIM}  PATTERNS:{RESET}
{DIM}   R-L-R-R = {CYAN}Paradiddle{RESET} (full scan)    {DIM}R-R-L-L = {PINK}Double Stroke{RESET} (deploy)
{DIM}   K-S-K-S = {GREEN}4-on-Floor{RESET} (health)      {DIM}K-S-R-L = {VIOLET}Ascending{RESET} (scale up)
{DIM}   L-R-S-K = {AMBER}Descending{RESET} (shutdown)    {DIM}L-R-L-R-L-R = {RED}Tom Roll{RESET} (broadcast)
{PINK}╠══════════════════════════════════════════════════════════════════╣{RESET}
{DIM}  GESTURES:{RESET}
{DIM}   📸 Flam (both sticks)         📊 Buzz Roll (8+ rapid hits){RESET}
{DIM}   📈 Crescendo (getting louder)  📉 Decrescendo (getting softer){RESET}
{DIM}   ❗ Accent (sudden hard hit)    ⚡ Silence Break (hit after pause){RESET}
{PINK}╚══════════════════════════════════════════════════════════════════╝{RESET}
""")
    print(f"{DIM}  Ctrl+C to stop{RESET}\n")


def print_status_line():
    """Periodic status line with BPM, spatial, intensity."""
    bpm = bpm_label()
    spatial = spatial_display()
    intensity = intensity_bar(20)
    hand = state.hand_bias
    hand_color = BLUE if "left" in hand else VIOLET if "right" in hand else GREEN

    print(f"\n  {DIM}┌{'─' * 62}┐{RESET}")
    print(f"  {DIM}│{RESET} {bpm}  {DIM}│{RESET} {intensity} {DIM}│{RESET} {hand_color}{hand}{RESET}")
    print(f"  {DIM}│{RESET} {spatial}")
    print(f"  {DIM}│{RESET} {DIM}hits={state.total_hits} agents={state.agent_dispatches} "
          f"patterns={state.patterns_matched} gestures={state.gestures_triggered}{RESET}")
    print(f"  {DIM}└{'─' * 62}┘{RESET}\n")


def print_hit(note, velocity):
    state.total_hits += 1
    now = time.time()

    # Combo tracking
    if now - state.last_hit_time < 0.5:
        state.combo_count += 1
    else:
        state.combo_count = 1

    drum = DRUM_MAP.get(note, {"name": f"N{note}", "color": DIM, "agent": "?", "cmd": "?", "zone": "?", "hand": "?"})
    color = drum["color"]
    name = drum["name"]
    bar = velocity_bar(velocity)

    combo_str = ""
    if state.combo_count >= 3:
        combo_str = f" {AMBER}🔥x{state.combo_count}{RESET}"

    is_agent = velocity >= AGENT_VELOCITY
    mode = f"{RED}⚡AGENT" if is_agent else f"{GREEN}♪ drum"

    print(f"  {color}{BOLD}{name:>6}{RESET} {bar} "
          f"{DIM}v={velocity:>3}{RESET} {mode}{RESET}{combo_str}")

    state.last_hit_time = now


# ══════════════════════════════════════════════════════════════
#  MAIN LOOP
# ══════════════════════════════════════════════════════════════
def main():
    print_header()

    try:
        port = mido.open_input("USB MIDI")
    except Exception as e:
        print(f"{RED}Error: Could not open USB MIDI: {e}{RESET}")
        print(f"{DIM}Is the Kalezo receiver plugged in?{RESET}")
        sys.exit(1)

    print(f"  {GREEN}✓ Connected to Aerband sticks{RESET}")
    print(f"  {DIM}Start drumming...{RESET}\n")

    status_counter = 0

    try:
        for msg in port:
            if msg.type != "note_on" or msg.velocity == 0:
                continue

            note = msg.note
            velocity = msg.velocity
            now = time.time()

            # ── Update all state ──
            state.pattern_buffer.append((note, velocity, now))
            state.velocity_history.append(velocity)
            state.intensity_window.append((now, velocity))
            update_bpm(now)
            update_spatial(note)

            # ── Play drum sound ──
            play_sound(note, velocity)

            # ── Print hit ──
            print_hit(note, velocity)

            # ── Check gestures ──
            gestures = detect_gestures(note, velocity, now)
            for gkey, ginfo in gestures:
                dispatch_gesture(gkey, ginfo)

            # ── Check pattern match ──
            matched = check_patterns(now)
            if matched:
                dispatch_pattern(matched)

            # ── Agent dispatch on hard hit ──
            if velocity >= AGENT_VELOCITY and note in DRUM_MAP:
                dispatch_agent(DRUM_MAP[note], velocity)

            # ── Periodic status line (every 10 hits) ──
            status_counter += 1
            if status_counter % 10 == 0:
                print_status_line()

    except KeyboardInterrupt:
        duration = state.session_duration
        mins = int(duration // 60)
        secs = int(duration % 60)

        print(f"\n\n{PINK}{'═' * 64}{RESET}")
        print(f"  {WHITE}🥁 CONDUCTOR SESSION SUMMARY{RESET}")
        print(f"{PINK}{'═' * 64}{RESET}")
        print(f"  {DIM}Duration:{RESET}        {mins}m {secs}s")
        print(f"  {DIM}Total hits:{RESET}      {state.total_hits}")
        print(f"  {DIM}Agent dispatches:{RESET} {state.agent_dispatches}")
        print(f"  {DIM}Patterns matched:{RESET} {state.patterns_matched}")
        print(f"  {DIM}Gestures:{RESET}        {state.gestures_triggered}")
        print(f"  {DIM}Peak BPM:{RESET}        {state.current_bpm:.0f}")
        print(f"  {DIM}Hand balance:{RESET}    {state.hand_bias}")
        print(f"  {DIM}Dominant zone:{RESET}   {state.dominant_zone}")
        print()
        print(f"  {DIM}Spatial map:{RESET}     {spatial_display()}")
        print(f"{PINK}{'═' * 64}{RESET}\n")
    finally:
        port.close()


if __name__ == "__main__":
    main()
