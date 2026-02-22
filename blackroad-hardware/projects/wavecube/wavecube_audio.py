#!/usr/bin/env python3
"""WaveQube Audio Reactive Projector

Captures microphone input and renders real-time FFT frequency bars
with BlackRoad brand gradient coloring. Falls back to a simulated
audio mode if no microphone is available (useful for testing).

Controls:
    q / ESC  — quit
    m        — toggle between mic and simulated audio
    s        — cycle visualization style (bars / wave / circle)
    +/-      — adjust sensitivity

Requirements:
    pip install pygame numpy pyaudio
"""

import math
import struct
import sys

import numpy as np
import pygame

# --- Display ---
WIDTH, HEIGHT = 640, 360
FPS = 60
NUM_BARS = 64

# --- BlackRoad Brand Palette ---
BLACK = (0, 0, 0)
HOT_PINK = (255, 29, 108)
AMBER = (245, 166, 35)
ELECTRIC_BLUE = (41, 121, 255)
VIOLET = (156, 39, 176)

# Try to import PyAudio
try:
    import pyaudio
    AUDIO_AVAILABLE = True
except ImportError:
    AUDIO_AVAILABLE = False


def gradient_color(t):
    """Interpolate across the brand gradient based on t (0.0 to 1.0)."""
    colors = [AMBER, HOT_PINK, VIOLET, ELECTRIC_BLUE]
    n = len(colors) - 1
    idx = t * n
    i = int(idx)
    frac = idx - i
    if i >= n:
        return colors[-1]
    c1, c2 = colors[i], colors[i + 1]
    return (
        int(c1[0] + (c2[0] - c1[0]) * frac),
        int(c1[1] + (c2[1] - c1[1]) * frac),
        int(c1[2] + (c2[2] - c1[2]) * frac),
    )


def simulated_fft(t, num_bars):
    """Generate fake FFT data for testing without a microphone."""
    bars = np.zeros(num_bars)
    for i in range(num_bars):
        freq = i / num_bars
        bars[i] = (
            0.5 * math.sin(t * 0.05 + freq * 6) +
            0.3 * math.sin(t * 0.08 + freq * 12) +
            0.2 * math.sin(t * 0.03 + i * 0.5) +
            0.1 * np.random.random()
        )
    bars = np.abs(bars)
    mx = bars.max()
    if mx > 0:
        bars /= mx
    return bars


class AudioCapture:
    """Wraps PyAudio for real-time microphone capture."""

    CHUNK = 1024
    RATE = 44100

    def __init__(self):
        self.pa = pyaudio.PyAudio()
        self.stream = self.pa.open(
            format=pyaudio.paInt16,
            channels=1,
            rate=self.RATE,
            input=True,
            frames_per_buffer=self.CHUNK,
        )

    def read_fft(self, num_bars):
        """Read a chunk and return normalized FFT magnitudes."""
        try:
            data = self.stream.read(self.CHUNK, exception_on_overflow=False)
        except OSError:
            return np.zeros(num_bars)
        samples = np.array(struct.unpack(f"{self.CHUNK}h", data), dtype=np.float64)
        # Apply Hann window to reduce spectral leakage
        window = np.hanning(len(samples))
        samples *= window
        fft = np.abs(np.fft.rfft(samples))[:num_bars]
        mx = fft.max()
        if mx > 0:
            fft /= mx
        return fft

    def close(self):
        self.stream.stop_stream()
        self.stream.close()
        self.pa.terminate()


def draw_bars(screen, fft_data, sensitivity):
    """Classic vertical frequency bars."""
    bar_w = WIDTH // NUM_BARS
    for i, val in enumerate(fft_data):
        h = int(val * sensitivity * (HEIGHT - 20))
        h = min(h, HEIGHT)
        color = gradient_color(i / NUM_BARS)
        x = i * bar_w
        # Main bar
        pygame.draw.rect(screen, color, (x, HEIGHT - h, bar_w - 1, h))
        # Reflection (dimmed)
        if h > 5:
            ref_h = min(h // 4, 30)
            dim = tuple(c // 4 for c in color)
            pygame.draw.rect(screen, dim, (x, HEIGHT, bar_w - 1, ref_h))


def draw_wave(screen, fft_data, sensitivity, t):
    """Smooth waveform visualization."""
    points = []
    for i, val in enumerate(fft_data):
        x = int(i / NUM_BARS * WIDTH)
        y = HEIGHT // 2 - int(val * sensitivity * (HEIGHT // 2 - 10))
        points.append((x, y))

    if len(points) > 2:
        # Draw filled area under curve
        filled = points + [(WIDTH, HEIGHT // 2), (0, HEIGHT // 2)]
        glow = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        pygame.draw.polygon(glow, (*HOT_PINK, 30), filled)
        screen.blit(glow, (0, 0))
        # Draw the line
        pygame.draw.lines(screen, HOT_PINK, False, points, 3)

    # Mirror below center
    mirror_points = [(x, HEIGHT - (y - HEIGHT // 2) + HEIGHT // 2) for x, y in points]
    if len(mirror_points) > 2:
        pygame.draw.lines(screen, ELECTRIC_BLUE, False, mirror_points, 2)


def draw_circle(screen, fft_data, sensitivity, t):
    """Circular FFT visualization."""
    cx, cy = WIDTH // 2, HEIGHT // 2
    base_radius = 60

    for i, val in enumerate(fft_data):
        angle = (i / NUM_BARS) * 2 * math.pi - math.pi / 2
        r = base_radius + val * sensitivity * 100
        x = cx + math.cos(angle) * r
        y = cy + math.sin(angle) * r
        color = gradient_color(i / NUM_BARS)

        # Line from center circle to point
        inner_x = cx + math.cos(angle) * base_radius
        inner_y = cy + math.sin(angle) * base_radius
        pygame.draw.line(screen, color, (int(inner_x), int(inner_y)), (int(x), int(y)), 2)

    # Draw center circle
    pygame.draw.circle(screen, HOT_PINK, (cx, cy), base_radius, 1)

    # Rotating accent
    accent_angle = t * 0.02
    ax = cx + math.cos(accent_angle) * (base_radius + 10)
    ay = cy + math.sin(accent_angle) * (base_radius + 10)
    pygame.draw.circle(screen, AMBER, (int(ax), int(ay)), 4)


def main():
    pygame.init()

    fullscreen = "--windowed" not in sys.argv
    flags = pygame.FULLSCREEN if fullscreen else 0
    screen = pygame.display.set_mode((WIDTH, HEIGHT), flags)
    pygame.display.set_caption("WaveQube Audio")
    pygame.mouse.set_visible(False)
    clock = pygame.time.Clock()

    # Audio setup
    audio = None
    use_mic = AUDIO_AVAILABLE
    if use_mic:
        try:
            audio = AudioCapture()
        except Exception:
            use_mic = False

    styles = ["bars", "wave", "circle"]
    style_idx = 0
    sensitivity = 1.0
    # Smoothed FFT data for visual continuity
    smooth_fft = np.zeros(NUM_BARS)
    smoothing = 0.3  # Lower = smoother

    t = 0
    running = True

    # Font for status overlay
    font = pygame.font.Font(None, 20)

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_q, pygame.K_ESCAPE):
                    running = False
                elif event.key == pygame.K_m:
                    if AUDIO_AVAILABLE:
                        use_mic = not use_mic
                        if use_mic and audio is None:
                            try:
                                audio = AudioCapture()
                            except Exception:
                                use_mic = False
                elif event.key == pygame.K_s:
                    style_idx = (style_idx + 1) % len(styles)
                elif event.key == pygame.K_EQUALS or event.key == pygame.K_PLUS:
                    sensitivity = min(sensitivity + 0.2, 3.0)
                elif event.key == pygame.K_MINUS:
                    sensitivity = max(sensitivity - 0.2, 0.2)

        # Get FFT data
        if use_mic and audio:
            raw_fft = audio.read_fft(NUM_BARS)
        else:
            raw_fft = simulated_fft(t, NUM_BARS)

        # Smooth the data
        smooth_fft = smooth_fft * (1 - smoothing) + raw_fft * smoothing

        # Clear
        screen.fill(BLACK)

        # Draw selected style
        style = styles[style_idx]
        if style == "bars":
            draw_bars(screen, smooth_fft, sensitivity)
        elif style == "wave":
            draw_wave(screen, smooth_fft, sensitivity, t)
        elif style == "circle":
            draw_circle(screen, smooth_fft, sensitivity, t)

        # Status indicator (small, top-left)
        src = "MIC" if use_mic else "SIM"
        status_text = font.render(f"{src} | {style} | sens:{sensitivity:.1f}", True, (80, 80, 80))
        screen.blit(status_text, (5, 5))

        pygame.display.flip()
        clock.tick(FPS)
        t += 1

    # Cleanup
    if audio:
        audio.close()
    pygame.quit()


if __name__ == "__main__":
    main()
