#!/usr/bin/env python3
"""WaveQube Generative Waveform Projector

Renders layered sine waves with BlackRoad brand colors onto a 640x360
framebuffer for projection through the DLP2000 module.

Controls:
    q / ESC  — quit
    SPACE    — pause/resume animation
    1-4      — toggle individual wave layers
    r        — randomize wave parameters
    +/-      — speed up / slow down
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

BRAND_COLORS = [HOT_PINK, AMBER, ELECTRIC_BLUE, VIOLET]


class WaveLayer:
    """A single animated sine wave layer."""

    def __init__(self, color, freq, amp, phase_speed, y_offset=0, thickness=2):
        self.color = color
        self.freq = freq
        self.amp = amp
        self.phase_speed = phase_speed
        self.y_offset = y_offset
        self.thickness = thickness
        self.visible = True

    def randomize(self):
        self.freq = random.uniform(0.005, 0.03)
        self.amp = random.uniform(20, 80)
        self.phase_speed = random.uniform(0.01, 0.05)
        self.y_offset = random.uniform(-40, 40)

    def render(self, surface, t):
        if not self.visible:
            return
        center_y = HEIGHT // 2 + self.y_offset
        points = []
        for x in range(WIDTH):
            y = center_y + math.sin(x * self.freq + t * self.phase_speed) * self.amp
            # Add secondary harmonic for visual complexity
            y += math.sin(x * self.freq * 2.3 + t * self.phase_speed * 0.7) * (self.amp * 0.3)
            points.append((x, y))
        if len(points) > 1:
            pygame.draw.lines(surface, self.color, False, points, self.thickness)


class ParticleField:
    """Subtle floating particles that drift behind the waves."""

    def __init__(self, count=40):
        self.particles = [
            {
                "x": random.uniform(0, WIDTH),
                "y": random.uniform(0, HEIGHT),
                "vx": random.uniform(-0.3, 0.3),
                "vy": random.uniform(-0.2, 0.2),
                "size": random.randint(1, 3),
                "color": random.choice(BRAND_COLORS),
                "alpha": random.randint(40, 120),
            }
            for _ in range(count)
        ]

    def update(self):
        for p in self.particles:
            p["x"] = (p["x"] + p["vx"]) % WIDTH
            p["y"] = (p["y"] + p["vy"]) % HEIGHT

    def render(self, surface):
        for p in self.particles:
            # Dim version of the color
            r, g, b = p["color"]
            dim = p["alpha"] / 255
            color = (int(r * dim), int(g * dim), int(b * dim))
            pygame.draw.circle(surface, color, (int(p["x"]), int(p["y"])), p["size"])


def main():
    pygame.init()

    # Use FULLSCREEN on Pi, windowed for dev/testing
    fullscreen = "--windowed" not in sys.argv
    flags = pygame.FULLSCREEN if fullscreen else 0
    screen = pygame.display.set_mode((WIDTH, HEIGHT), flags)
    pygame.display.set_caption("WaveQube Viz")
    pygame.mouse.set_visible(False)
    clock = pygame.time.Clock()

    # Create wave layers
    layers = [
        WaveLayer(HOT_PINK, 0.010, 55, 0.020, y_offset=-10, thickness=3),
        WaveLayer(AMBER, 0.015, 40, 0.030, y_offset=0, thickness=2),
        WaveLayer(ELECTRIC_BLUE, 0.020, 50, 0.015, y_offset=15, thickness=2),
        WaveLayer(VIOLET, 0.008, 65, 0.025, y_offset=-5, thickness=2),
    ]

    particles = ParticleField(count=40)

    t = 0.0
    speed = 1.0
    paused = False
    running = True

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_q, pygame.K_ESCAPE):
                    running = False
                elif event.key == pygame.K_SPACE:
                    paused = not paused
                elif event.key == pygame.K_r:
                    for layer in layers:
                        layer.randomize()
                elif event.key == pygame.K_EQUALS or event.key == pygame.K_PLUS:
                    speed = min(speed + 0.25, 4.0)
                elif event.key == pygame.K_MINUS:
                    speed = max(speed - 0.25, 0.25)
                elif event.key == pygame.K_1:
                    layers[0].visible = not layers[0].visible
                elif event.key == pygame.K_2:
                    layers[1].visible = not layers[1].visible
                elif event.key == pygame.K_3:
                    layers[2].visible = not layers[2].visible
                elif event.key == pygame.K_4:
                    layers[3].visible = not layers[3].visible

        # Clear to black
        screen.fill(BLACK)

        # Update and draw particles
        if not paused:
            particles.update()
        particles.render(screen)

        # Draw waves
        for layer in layers:
            layer.render(screen, t)

        # Draw subtle gradient glow at center
        glow_surf = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        center_x, center_y = WIDTH // 2, HEIGHT // 2
        for radius in range(120, 0, -2):
            alpha = max(0, int(8 * (1 - radius / 120)))
            pygame.draw.circle(glow_surf, (255, 29, 108, alpha), (center_x, center_y), radius)
        screen.blit(glow_surf, (0, 0))

        pygame.display.flip()
        clock.tick(FPS)

        if not paused:
            t += speed

    pygame.quit()


if __name__ == "__main__":
    main()
