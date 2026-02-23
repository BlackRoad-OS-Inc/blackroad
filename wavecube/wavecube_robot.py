#!/usr/bin/env python3
"""WaveQube Robot Projector — Emotional Animated Robot

Projects an animated robot character with a full emotion system.
The robot autonomously cycles through moods, performs actions (wave,
dance, jump, pick up objects, think), and expresses emotions through
eyes, mouth, body language, core color, and floating emotion particles.

Controls:
    q / ESC       — quit
    SPACE         — trigger random action
    1             — set mood: happy
    2             — set mood: curious
    3             — set mood: excited
    4             — set mood: sleepy
    5             — set mood: surprised
    6             — set mood: love
    0             — set mood: neutral
    w             — action: wave
    d             — action: dance
    j             — action: jump
    p             — action: pick up
    t             — action: think
    a             — toggle auto-mood (cycles emotions on its own)
    c             — cycle color scheme
    --windowed    — run in a window instead of fullscreen

Requirements:
    pip install pygame
"""

import math
import random
import sys

import pygame

# --- Display ---
WIDTH, HEIGHT = 640, 360
FPS = 60

# --- BlackRoad Brand Palette ---
BLACK = (0, 0, 0)
HOT_PINK = (255, 29, 108)
AMBER = (245, 166, 35)
ELECTRIC_BLUE = (41, 121, 255)
VIOLET = (156, 39, 176)
WHITE = (255, 255, 255)
DARK_GRAY = (30, 30, 30)
SOFT_RED = (255, 80, 80)
SOFT_GREEN = (80, 255, 120)

COLOR_SCHEMES = [
    {"body": ELECTRIC_BLUE, "accent": HOT_PINK, "eye": AMBER, "glow": VIOLET},
    {"body": HOT_PINK, "accent": AMBER, "eye": ELECTRIC_BLUE, "glow": VIOLET},
    {"body": VIOLET, "accent": ELECTRIC_BLUE, "eye": HOT_PINK, "glow": AMBER},
    {"body": AMBER, "accent": VIOLET, "eye": ELECTRIC_BLUE, "glow": HOT_PINK},
]

# Emotion definitions
EMOTIONS = {
    "neutral":   {"eye": "round",   "mouth": "line",   "blink_rate": 1.0, "breath_rate": 1.0, "core_color_mix": 0.0},
    "happy":     {"eye": "arc",     "mouth": "smile",  "blink_rate": 0.7, "breath_rate": 1.2, "core_color_mix": 0.3},
    "curious":   {"eye": "big",     "mouth": "small_o","blink_rate": 1.5, "breath_rate": 0.8, "core_color_mix": 0.2},
    "excited":   {"eye": "star",    "mouth": "wide",   "blink_rate": 0.5, "breath_rate": 2.0, "core_color_mix": 0.6},
    "sleepy":    {"eye": "half",    "mouth": "line",   "blink_rate": 3.0, "breath_rate": 0.5, "core_color_mix": 0.1},
    "surprised": {"eye": "wide",    "mouth": "big_o",  "blink_rate": 0.3, "breath_rate": 1.5, "core_color_mix": 0.4},
    "love":      {"eye": "heart",   "mouth": "smile",  "blink_rate": 0.8, "breath_rate": 1.0, "core_color_mix": 0.5},
}

# Actions the robot can perform
ACTIONS = ["idle", "wave", "dance", "jump", "pick", "think"]


def dim(color, factor):
    return tuple(max(0, min(255, int(c * factor))) for c in color)


def lerp_color(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


class EmotionParticle:
    """Floating particle that represents the robot's current emotion."""

    SYMBOLS = {
        "happy": "~",
        "curious": "?",
        "excited": "!",
        "sleepy": "z",
        "surprised": "!",
        "love": "<3",
        "neutral": ".",
    }

    def __init__(self, x, y, emotion, color):
        self.x = x + random.uniform(-20, 20)
        self.y = y
        self.vy = random.uniform(-1.5, -0.5)
        self.vx = random.uniform(-0.5, 0.5)
        self.life = 1.0
        self.decay = random.uniform(0.008, 0.015)
        self.text = self.SYMBOLS.get(emotion, ".")
        self.color = color
        self.size = random.randint(14, 22)

    def update(self):
        self.x += self.vx
        self.y += self.vy
        self.life -= self.decay

    def draw(self, screen, font):
        if self.life <= 0:
            return
        alpha = max(0, min(255, int(self.life * 255)))
        surf = font.render(self.text, True, self.color)
        surf.set_alpha(alpha)
        screen.blit(surf, (int(self.x), int(self.y)))


class PickedObject:
    """An object the robot can pick up and hold."""

    OBJECTS = [
        {"name": "star", "color": AMBER},
        {"name": "gem", "color": VIOLET},
        {"name": "orb", "color": ELECTRIC_BLUE},
        {"name": "heart", "color": HOT_PINK},
    ]

    def __init__(self):
        obj = random.choice(self.OBJECTS)
        self.name = obj["name"]
        self.color = obj["color"]
        self.bob_phase = random.uniform(0, math.pi * 2)

    def draw(self, screen, x, y, t):
        bob = math.sin(t * 0.1 + self.bob_phase) * 3
        y = int(y + bob)

        if self.name == "star":
            self._draw_star(screen, x, y)
        elif self.name == "gem":
            self._draw_gem(screen, x, y)
        elif self.name == "orb":
            pygame.draw.circle(screen, self.color, (x, y), 8)
            pygame.draw.circle(screen, WHITE, (x - 2, y - 2), 3)
        elif self.name == "heart":
            self._draw_heart(screen, x, y)

    def _draw_star(self, screen, x, y):
        points = []
        for i in range(10):
            angle = math.pi / 2 + i * math.pi / 5
            r = 10 if i % 2 == 0 else 5
            points.append((x + math.cos(angle) * r, y - math.sin(angle) * r))
        pygame.draw.polygon(screen, self.color, points)

    def _draw_gem(self, screen, x, y):
        points = [(x, y - 10), (x + 8, y - 2), (x + 5, y + 8), (x - 5, y + 8), (x - 8, y - 2)]
        pygame.draw.polygon(screen, self.color, points)
        pygame.draw.polygon(screen, WHITE, points, 1)

    def _draw_heart(self, screen, x, y):
        # Two circles + triangle
        r = 5
        pygame.draw.circle(screen, self.color, (x - 4, y - 3), r)
        pygame.draw.circle(screen, self.color, (x + 4, y - 3), r)
        pygame.draw.polygon(screen, self.color, [(x - 9, y), (x + 9, y), (x, y + 10)])


class Robot:
    """Animated robot with emotions and actions."""

    def __init__(self, cx, cy):
        self.cx = cx
        self.base_cy = cy
        self.cy = cy
        self.scheme_idx = 0
        self.auto_mood = True

        # Emotion state
        self.mood = "neutral"
        self.mood_intensity = 0.0  # 0..1 transition
        self.mood_target = 1.0
        self.mood_timer = 0
        self.mood_duration = random.randint(300, 600)  # frames before auto-switching

        # Action state
        self.action = "idle"
        self.action_timer = 0
        self.action_duration = 0

        # Blink
        self.blink_timer = 0
        self.blink_interval = random.randint(180, 360)
        self.is_blinking = False
        self.blink_frames = 0

        # Animation phases
        self.breath_phase = 0.0
        self.antenna_phase = 0.0
        self.dance_phase = 0.0
        self.jump_offset = 0.0
        self.jump_velocity = 0.0

        # Held object
        self.held_object = None

        # Particles
        self.particles = []

        # Thought bubble
        self.thought_text = ""
        self.thought_timer = 0

    @property
    def colors(self):
        return COLOR_SCHEMES[self.scheme_idx]

    @property
    def emotion_data(self):
        return EMOTIONS.get(self.mood, EMOTIONS["neutral"])

    def set_mood(self, mood):
        if mood in EMOTIONS:
            self.mood = mood
            self.mood_intensity = 0.0
            self.mood_target = 1.0
            self.mood_timer = 0
            self.mood_duration = random.randint(300, 600)

    def trigger_action(self, action):
        if action not in ACTIONS:
            return
        self.action = action
        self.action_timer = 0
        if action == "wave":
            self.action_duration = 120
        elif action == "dance":
            self.action_duration = 180
        elif action == "jump":
            self.action_duration = 60
            self.jump_velocity = -8.0
        elif action == "pick":
            self.action_duration = 90
            self.held_object = PickedObject()
        elif action == "think":
            self.action_duration = 150
            thoughts = [
                "01001...", "hmm...", "beep?", "loading...",
                "eureka!", "recalc...", "*bzzzt*", "why?",
                "yes!", "wow", "zzz...", "<3",
            ]
            self.thought_text = random.choice(thoughts)
            self.thought_timer = 150

    def trigger_random_action(self):
        self.trigger_action(random.choice(ACTIONS[1:]))  # skip idle

    def update(self, t):
        ed = self.emotion_data

        # Smooth mood intensity transition
        if self.mood_intensity < self.mood_target:
            self.mood_intensity = min(self.mood_intensity + 0.02, self.mood_target)

        # Auto mood cycling
        if self.auto_mood:
            self.mood_timer += 1
            if self.mood_timer >= self.mood_duration:
                moods = list(EMOTIONS.keys())
                self.set_mood(random.choice(moods))
                # Occasionally trigger a random action too
                if random.random() < 0.4:
                    self.trigger_random_action()

        # Breathing
        self.breath_phase = math.sin(t * 0.03 * ed["breath_rate"]) * 3

        # Antenna
        self.antenna_phase = t * 0.08

        # Blink (affected by emotion)
        self.blink_timer += 1
        blink_threshold = int(self.blink_interval / ed["blink_rate"])
        if self.is_blinking:
            self.blink_frames += 1
            if self.blink_frames > 8:
                self.is_blinking = False
                self.blink_frames = 0
                self.blink_interval = random.randint(150, 300)
        elif self.blink_timer >= blink_threshold:
            self.is_blinking = True
            self.blink_timer = 0
            self.blink_frames = 0

        # Action updates
        if self.action != "idle":
            self.action_timer += 1
            if self.action_timer >= self.action_duration:
                self.action = "idle"
                self.action_timer = 0

        # Jump physics
        if self.action == "jump":
            self.jump_offset += self.jump_velocity
            self.jump_velocity += 0.5  # gravity
            if self.jump_offset >= 0:
                self.jump_offset = 0
                self.jump_velocity = 0
        else:
            self.jump_offset = 0

        # Dance phase
        if self.action == "dance":
            self.dance_phase = t * 0.15
        else:
            self.dance_phase = 0

        # Emit emotion particles
        if random.random() < 0.03 * self.mood_intensity and self.mood != "neutral":
            self.particles.append(
                EmotionParticle(self.cx, self.cy - 120, self.mood, self.colors["glow"])
            )

        # Update particles
        for p in self.particles:
            p.update()
        self.particles = [p for p in self.particles if p.life > 0]

        # Thought timer
        if self.thought_timer > 0:
            self.thought_timer -= 1

        # Compute final cy with jump
        self.cy = self.base_cy + self.jump_offset

    def draw(self, screen, t, font):
        c = self.colors
        ed = self.emotion_data
        cx = self.cx
        cy = int(self.cy + self.breath_phase)

        # Dance sway
        dance_sway = 0
        if self.action == "dance":
            dance_sway = int(math.sin(self.dance_phase) * 15)
            cx += dance_sway

        # --- Emotion particles ---
        particle_font = pygame.font.Font(None, 20)
        for p in self.particles:
            p.draw(screen, particle_font)

        # --- Antenna ---
        antenna_top_y = cy - 110
        pygame.draw.line(screen, c["body"], (cx, cy - 80), (cx, antenna_top_y), 3)
        glow_size = int(6 + math.sin(self.antenna_phase) * 2)
        glow_color = c["glow"]
        # Glow changes with emotion
        if self.mood == "excited":
            glow_size = int(8 + math.sin(t * 0.2) * 4)
        elif self.mood == "love":
            glow_color = HOT_PINK
        glow_surf = pygame.Surface((glow_size * 6, glow_size * 6), pygame.SRCALPHA)
        pygame.draw.circle(glow_surf, (*glow_color, 50), (glow_size * 3, glow_size * 3), glow_size * 3)
        pygame.draw.circle(glow_surf, (*glow_color, 100), (glow_size * 3, glow_size * 3), glow_size * 2)
        screen.blit(glow_surf, (cx - glow_size * 3, antenna_top_y - glow_size * 3))
        pygame.draw.circle(screen, glow_color, (cx, antenna_top_y), glow_size)

        # --- Head ---
        head_w, head_h = 80, 60
        # Tilt head for curious
        head_rect = pygame.Rect(cx - head_w // 2, cy - 80, head_w, head_h)
        pygame.draw.rect(screen, c["body"], head_rect, border_radius=12)
        inner = head_rect.inflate(-6, -6)
        pygame.draw.rect(screen, DARK_GRAY, inner, border_radius=10)

        # Blush for love/happy
        if self.mood in ("love", "happy"):
            blush_alpha = int(40 * self.mood_intensity)
            blush = pygame.Surface((20, 12), pygame.SRCALPHA)
            pygame.draw.ellipse(blush, (*HOT_PINK, blush_alpha), (0, 0, 20, 12))
            screen.blit(blush, (cx - 35, cy - 50))
            screen.blit(blush, (cx + 15, cy - 50))

        # --- Eyes ---
        eye_y = cy - 60
        left_eye_x = cx - 20
        right_eye_x = cx + 20
        self._draw_eyes(screen, ed, left_eye_x, right_eye_x, eye_y, c, t)

        # --- Mouth ---
        mouth_y = cy - 35
        self._draw_mouth(screen, ed, cx, mouth_y, c, t)

        # --- Neck ---
        pygame.draw.rect(screen, c["body"], (cx - 8, cy - 22, 16, 12))

        # --- Body ---
        body_rect = pygame.Rect(cx - 50, cy - 10, 100, 80)
        pygame.draw.rect(screen, c["body"], body_rect, border_radius=8)
        body_inner = body_rect.inflate(-6, -6)
        pygame.draw.rect(screen, DARK_GRAY, body_inner, border_radius=6)

        # Core — emotion-colored
        core_y = cy + 25
        base_color = c["glow"]
        emotion_colors = {
            "happy": AMBER, "curious": ELECTRIC_BLUE, "excited": HOT_PINK,
            "sleepy": VIOLET, "surprised": WHITE, "love": HOT_PINK, "neutral": c["glow"],
        }
        target_core = emotion_colors.get(self.mood, c["glow"])
        core_color = lerp_color(base_color, target_core, ed["core_color_mix"] * self.mood_intensity)

        speed_mult = 1.0
        if self.mood == "excited":
            speed_mult = 2.0
        elif self.mood == "sleepy":
            speed_mult = 0.4
        core_pulse = int(12 + math.sin(t * 0.06 * speed_mult) * 3)

        pygame.draw.circle(screen, dim(core_color, 0.3), (cx, core_y), core_pulse + 8)
        pygame.draw.circle(screen, core_color, (cx, core_y), core_pulse)
        pygame.draw.circle(screen, WHITE, (cx, core_y), core_pulse // 2)

        # Circuitry lines
        for dy in (-8, 0, 8):
            y = core_y + dy
            pygame.draw.line(screen, dim(c["body"], 0.5), (cx - 40, y), (cx - core_pulse - 8, y), 1)
            pygame.draw.line(screen, dim(c["body"], 0.5), (cx + core_pulse + 8, y), (cx + 40, y), 1)

        # --- Arms ---
        self._draw_arms(screen, cx, cy, c, t)

        # --- Legs ---
        self._draw_legs(screen, cx, cy, c, t)

        # --- Ground shadow ---
        shadow_y = cy + 118
        shadow_w = int(90 + math.sin(t * 0.03) * 5)
        if self.action == "jump" and self.jump_offset < 0:
            # Shadow shrinks when jumping
            shadow_w = max(30, shadow_w + int(self.jump_offset * 1.5))
        shadow_surf = pygame.Surface((shadow_w, 8), pygame.SRCALPHA)
        pygame.draw.ellipse(shadow_surf, (255, 255, 255, 20), (0, 0, shadow_w, 8))
        screen.blit(shadow_surf, (cx - shadow_w // 2, shadow_y))

        # --- Held object ---
        if self.held_object and self.action == "pick":
            # Draw object above left hand
            progress = min(1.0, self.action_timer / 45)
            obj_y = int(cy + 65 - progress * 80)
            self.held_object.draw(screen, cx - 75, obj_y, t)
        elif self.held_object and self.action == "idle":
            # Float object near hand after pick
            self.held_object.draw(screen, cx - 70, cy - 10, t)

        # --- Thought bubble ---
        if self.thought_timer > 0 and self.thought_text:
            self._draw_thought(screen, cx, cy, font)

        # --- Mood label ---
        mood_label = font.render(self.mood.upper(), True, dim(core_color, 0.6))
        screen.blit(mood_label, (cx - mood_label.get_width() // 2, cy + 130))

    def _draw_eyes(self, screen, ed, lx, rx, y, c, t):
        if self.is_blinking:
            pygame.draw.line(screen, c["eye"], (lx - 8, y), (lx + 8, y), 2)
            pygame.draw.line(screen, c["eye"], (rx - 8, y), (rx + 8, y), 2)
            return

        eye_type = ed["eye"]

        for ex in (lx, rx):
            if eye_type == "round":
                pygame.draw.circle(screen, c["eye"], (ex, y), 8)
                pygame.draw.circle(screen, WHITE, (ex + 2, y - 2), 3)

            elif eye_type == "arc":
                # Happy squint
                pygame.draw.arc(screen, c["eye"], (ex - 10, y - 8, 20, 16), 0.3, math.pi - 0.3, 3)

            elif eye_type == "big":
                # Curious — larger
                pygame.draw.circle(screen, c["eye"], (ex, y), 11)
                pygame.draw.circle(screen, WHITE, (ex + 3, y - 3), 4)
                pygame.draw.circle(screen, BLACK, (ex, y), 5)

            elif eye_type == "star":
                # Excited — star-shaped
                for i in range(5):
                    angle = -math.pi / 2 + i * 2 * math.pi / 5
                    px = ex + math.cos(angle) * 10
                    py = y + math.sin(angle) * 10
                    pygame.draw.line(screen, c["eye"], (ex, y), (int(px), int(py)), 2)
                pygame.draw.circle(screen, c["eye"], (ex, y), 4)

            elif eye_type == "half":
                # Sleepy — half-closed
                pygame.draw.arc(screen, c["eye"], (ex - 8, y - 4, 16, 12), 0.2, math.pi - 0.2, 2)
                pygame.draw.line(screen, c["eye"], (ex - 8, y + 1), (ex + 8, y + 1), 2)

            elif eye_type == "wide":
                # Surprised — wide open
                pygame.draw.circle(screen, c["eye"], (ex, y), 12, 2)
                pygame.draw.circle(screen, c["eye"], (ex, y), 5)
                pygame.draw.circle(screen, WHITE, (ex, y), 2)

            elif eye_type == "heart":
                # Love — heart eyes
                r = 5
                pygame.draw.circle(screen, HOT_PINK, (ex - 3, y - 2), r)
                pygame.draw.circle(screen, HOT_PINK, (ex + 3, y - 2), r)
                pygame.draw.polygon(screen, HOT_PINK, [(ex - 8, y), (ex + 8, y), (ex, y + 8)])

    def _draw_mouth(self, screen, ed, cx, y, c, t):
        mouth_type = ed["mouth"]

        if mouth_type == "line":
            pygame.draw.line(screen, c["accent"], (cx - 12, y), (cx + 12, y), 2)

        elif mouth_type == "smile":
            pygame.draw.arc(screen, c["accent"], (cx - 15, y - 10, 30, 20),
                            math.pi + 0.3, 2 * math.pi - 0.3, 2)

        elif mouth_type == "small_o":
            pygame.draw.circle(screen, c["accent"], (cx, y), 5, 2)

        elif mouth_type == "wide":
            # Excited wide grin
            pygame.draw.arc(screen, c["accent"], (cx - 20, y - 12, 40, 24),
                            math.pi + 0.2, 2 * math.pi - 0.2, 3)

        elif mouth_type == "big_o":
            pygame.draw.ellipse(screen, c["accent"], (cx - 10, y - 8, 20, 16), 2)

    def _draw_arms(self, screen, cx, cy, c, t):
        # Left arm
        l_shoulder = (cx - 50, cy + 5)

        if self.action == "pick" and self.action_timer < 45:
            # Reaching down to pick something up
            progress = self.action_timer / 45
            l_elbow = (cx - 65, int(cy + 40 + progress * 20))
            l_hand = (cx - 75, int(cy + 65 + progress * 25))
        elif self.action == "pick" and self.action_timer >= 45:
            # Lifting up
            progress = (self.action_timer - 45) / 45
            l_elbow = (cx - 65, int(cy + 60 - progress * 40))
            l_hand = (cx - 75, int(cy + 90 - progress * 80))
        elif self.action == "dance":
            sway = math.sin(self.dance_phase * 2) * 20
            l_elbow = (cx - 70, int(cy + 20 + sway))
            l_hand = (cx - 80, int(cy + sway))
        else:
            l_elbow = (cx - 70, cy + 40)
            l_hand = (cx - 75, cy + 65)

        pygame.draw.line(screen, c["body"], l_shoulder, l_elbow, 6)
        pygame.draw.line(screen, c["body"], l_elbow, l_hand, 5)
        pygame.draw.circle(screen, c["accent"], l_hand, 6)

        # Right arm
        r_shoulder = (cx + 50, cy + 5)

        if self.action == "wave":
            # Wave animation
            wave_angle = math.sin(t * 0.15) * 0.8
            r_elbow = (cx + 70, cy - 10)
            r_hand = (int(cx + 80 + math.sin(wave_angle) * 15),
                      int(cy - 40 + math.cos(wave_angle) * 10))
        elif self.action == "dance":
            sway = math.sin(self.dance_phase * 2 + math.pi) * 20
            r_elbow = (cx + 70, int(cy + 20 + sway))
            r_hand = (cx + 80, int(cy + sway))
        elif self.action == "think":
            # Hand on chin
            r_elbow = (cx + 50, cy - 20)
            r_hand = (cx + 15, cy - 38)
        else:
            r_elbow = (cx + 70, cy + 40)
            r_hand = (cx + 75, cy + 65)

        pygame.draw.line(screen, c["body"], r_shoulder, r_elbow, 6)
        pygame.draw.line(screen, c["body"], r_elbow, r_hand, 5)
        pygame.draw.circle(screen, c["accent"], r_hand, 6)

    def _draw_legs(self, screen, cx, cy, c, t):
        leg_top = cy + 70

        if self.action == "dance":
            # Alternating leg kicks
            l_offset = int(math.sin(self.dance_phase * 2) * 10)
            r_offset = int(math.sin(self.dance_phase * 2 + math.pi) * 10)
            # Left
            pygame.draw.rect(screen, c["body"], (cx - 30 + l_offset, leg_top, 14, 40))
            pygame.draw.rect(screen, c["accent"], (cx - 34 + l_offset, leg_top + 35, 22, 10), border_radius=3)
            # Right
            pygame.draw.rect(screen, c["body"], (cx + 16 + r_offset, leg_top, 14, 40))
            pygame.draw.rect(screen, c["accent"], (cx + 12 + r_offset, leg_top + 35, 22, 10), border_radius=3)
        else:
            # Static legs
            pygame.draw.rect(screen, c["body"], (cx - 30, leg_top, 14, 40))
            pygame.draw.rect(screen, c["accent"], (cx - 34, leg_top + 35, 22, 10), border_radius=3)
            pygame.draw.rect(screen, c["body"], (cx + 16, leg_top, 14, 40))
            pygame.draw.rect(screen, c["accent"], (cx + 12, leg_top + 35, 22, 10), border_radius=3)

    def _draw_thought(self, screen, cx, cy, font):
        # Thought bubble
        bubble_x = cx + 50
        bubble_y = cy - 130
        # Small circles leading to bubble
        pygame.draw.circle(screen, dim(WHITE, 0.3), (cx + 20, cy - 95), 4)
        pygame.draw.circle(screen, dim(WHITE, 0.3), (cx + 35, cy - 110), 6)
        # Main bubble
        text_surf = font.render(self.thought_text, True, WHITE)
        tw = text_surf.get_width()
        bw = tw + 20
        bh = 28
        pygame.draw.ellipse(screen, dim(WHITE, 0.15), (bubble_x - bw // 2, bubble_y - bh // 2, bw, bh))
        pygame.draw.ellipse(screen, dim(WHITE, 0.3), (bubble_x - bw // 2, bubble_y - bh // 2, bw, bh), 1)
        screen.blit(text_surf, (bubble_x - tw // 2, bubble_y - text_surf.get_height() // 2))


class ScanLines:
    def __init__(self):
        self.surface = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        for y in range(0, HEIGHT, 3):
            pygame.draw.line(self.surface, (0, 0, 0, 15), (0, y), (WIDTH, y))

    def draw(self, screen):
        screen.blit(self.surface, (0, 0))


def main():
    pygame.init()

    fullscreen = "--windowed" not in sys.argv
    flags = pygame.FULLSCREEN if fullscreen else 0
    screen = pygame.display.set_mode((WIDTH, HEIGHT), flags)
    pygame.display.set_caption("WaveQube Robot")
    pygame.mouse.set_visible(False)
    clock = pygame.time.Clock()

    font = pygame.font.Font(None, 22)
    title_font = pygame.font.Font(None, 18)

    robot = Robot(WIDTH // 2, HEIGHT // 2 + 10)
    scanlines = ScanLines()

    t = 0
    running = True

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_q, pygame.K_ESCAPE):
                    running = False
                elif event.key == pygame.K_SPACE:
                    robot.trigger_random_action()
                elif event.key == pygame.K_1:
                    robot.set_mood("happy")
                elif event.key == pygame.K_2:
                    robot.set_mood("curious")
                elif event.key == pygame.K_3:
                    robot.set_mood("excited")
                elif event.key == pygame.K_4:
                    robot.set_mood("sleepy")
                elif event.key == pygame.K_5:
                    robot.set_mood("surprised")
                elif event.key == pygame.K_6:
                    robot.set_mood("love")
                elif event.key == pygame.K_0:
                    robot.set_mood("neutral")
                elif event.key == pygame.K_w:
                    robot.trigger_action("wave")
                elif event.key == pygame.K_d:
                    robot.trigger_action("dance")
                elif event.key == pygame.K_j:
                    robot.trigger_action("jump")
                elif event.key == pygame.K_p:
                    robot.trigger_action("pick")
                elif event.key == pygame.K_t:
                    robot.trigger_action("think")
                elif event.key == pygame.K_a:
                    robot.auto_mood = not robot.auto_mood
                elif event.key == pygame.K_c:
                    robot.scheme_idx = (robot.scheme_idx + 1) % len(COLOR_SCHEMES)

        robot.update(t)

        screen.fill(BLACK)
        robot.draw(screen, t, font)
        scanlines.draw(screen)

        # Status bar
        auto_str = "AUTO" if robot.auto_mood else "MANUAL"
        status = title_font.render(
            f"WAVEQUBE  |  {auto_str}  |  {robot.action.upper()}",
            True, dim(robot.colors["body"], 0.35)
        )
        screen.blit(status, (WIDTH // 2 - status.get_width() // 2, HEIGHT - 18))

        pygame.display.flip()
        clock.tick(FPS)
        t += 1

    pygame.quit()


if __name__ == "__main__":
    main()
