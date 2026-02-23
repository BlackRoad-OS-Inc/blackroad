#!/usr/bin/env python3
"""
BlackRoad OS - Brady Bunch Native Display Grid
Renders all Pi devices in a Brady Bunch style grid on native framebuffer

Usage: python3 blackroad-brady-bunch-native.py [--fullscreen] [--kiosk]
"""

import os
import sys
import time
import json
import socket
import subprocess
import threading
from datetime import datetime
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

# Try pygame, fall back to curses
try:
    os.environ['SDL_VIDEODRIVER'] = 'fbcon'  # Use framebuffer
    os.environ['SDL_FBDEV'] = '/dev/fb0'
    import pygame
    HAS_PYGAME = True
except ImportError:
    HAS_PYGAME = False

# BlackRoad Brand Colors
COLORS = {
    'black': (0, 0, 0),
    'white': (255, 255, 255),
    'hot_pink': (255, 29, 108),      # #FF1D6C
    'amber': (245, 166, 35),         # #F5A623
    'electric_blue': (41, 121, 255), # #2979FF
    'violet': (156, 39, 176),        # #9C27B0
    'green': (46, 204, 113),         # Success
    'red': (231, 76, 60),            # Error
    'dark_gray': (30, 30, 30),
    'mid_gray': (60, 60, 60),
}

@dataclass
class DeviceInfo:
    name: str
    ip: str
    ssh_user: str
    hardware: str
    role: str
    tailscale_ip: Optional[str] = None
    status: str = "unknown"
    cpu_temp: float = 0.0
    cpu_usage: float = 0.0
    memory_pct: float = 0.0
    disk_pct: float = 0.0
    uptime: str = ""
    last_update: float = 0.0

# Device Fleet Configuration
DEVICE_FLEET: List[DeviceInfo] = [
    DeviceInfo("cecilia", "192.168.4.89", "cecilia", "Pi 5 + Hailo-8", "Primary AI", "100.72.180.98"),
    DeviceInfo("lucidia", "192.168.4.81", "lucidia", "Pi 5 + Pironman", "AI Brain", "100.83.149.86"),
    DeviceInfo("octavia", "192.168.4.38", "octavia", "Pi 5", "Processing", "100.66.235.47"),
    DeviceInfo("alice", "192.168.4.49", "alice", "Pi 400", "Worker", "100.77.210.18"),
    DeviceInfo("aria", "192.168.4.82", "aria", "Pi 5", "Harmony", "100.109.14.17"),
    DeviceInfo("shellfish", "174.138.44.45", "shellfish", "DigitalOcean", "Edge", "100.94.33.37"),
]

class DeviceMonitor:
    """Monitors device status in background thread"""

    def __init__(self, devices: List[DeviceInfo]):
        self.devices = {d.name: d for d in devices}
        self.running = True
        self._lock = threading.Lock()

    def start(self):
        """Start monitoring thread"""
        self.thread = threading.Thread(target=self._monitor_loop, daemon=True)
        self.thread.start()

    def stop(self):
        """Stop monitoring"""
        self.running = False

    def get_devices(self) -> Dict[str, DeviceInfo]:
        """Get current device states"""
        with self._lock:
            return dict(self.devices)

    def _monitor_loop(self):
        """Background monitoring loop"""
        while self.running:
            for name in list(self.devices.keys()):
                self._update_device(name)
            time.sleep(5)  # Update every 5 seconds

    def _update_device(self, name: str):
        """Update single device status via SSH"""
        device = self.devices[name]

        try:
            # Quick connectivity check
            result = subprocess.run(
                ['ssh', '-o', 'ConnectTimeout=2', '-o', 'BatchMode=yes',
                 f'{device.ssh_user}@{device.ip}',
                 'cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null; '
                 'grep -o "^[0-9.]*" /proc/loadavg; '
                 'free | awk "/Mem:/{print int($3/$2*100)}"; '
                 'df / | awk "NR==2{print int($5)}"; '
                 'uptime -p 2>/dev/null || uptime | sed "s/.*up/up/"'],
                capture_output=True, text=True, timeout=5
            )

            if result.returncode == 0:
                lines = result.stdout.strip().split('\n')
                with self._lock:
                    device.status = "online"
                    device.last_update = time.time()
                    if len(lines) >= 4:
                        try:
                            device.cpu_temp = float(lines[0]) / 1000 if lines[0].isdigit() else 0
                            device.cpu_usage = float(lines[1]) * 100 / 4 if lines[1] else 0  # Normalize to %
                            device.memory_pct = float(lines[2]) if lines[2].isdigit() else 0
                            device.disk_pct = float(lines[3].replace('%', '')) if lines[3] else 0
                        except (ValueError, IndexError):
                            pass
                    if len(lines) >= 5:
                        device.uptime = lines[4][:20]
            else:
                with self._lock:
                    device.status = "offline"

        except (subprocess.TimeoutExpired, Exception) as e:
            with self._lock:
                device.status = "error"


class BradyBunchDisplay:
    """Native framebuffer display for Brady Bunch grid"""

    def __init__(self, fullscreen: bool = True):
        self.fullscreen = fullscreen
        self.monitor = DeviceMonitor(DEVICE_FLEET)
        self.running = True

        # Initialize pygame
        if not HAS_PYGAME:
            print("pygame not available - run: pip3 install pygame")
            sys.exit(1)

        # Try different video drivers
        drivers = ['fbcon', 'directfb', 'svgalib', 'x11', 'dga', 'ggi', 'dummy']
        initialized = False

        for driver in drivers:
            os.environ['SDL_VIDEODRIVER'] = driver
            try:
                pygame.display.init()
                pygame.font.init()
                initialized = True
                print(f"Initialized with driver: {driver}")
                break
            except pygame.error:
                continue

        if not initialized:
            print("Warning: Could not initialize display, using dummy driver")
            os.environ['SDL_VIDEODRIVER'] = 'dummy'
            pygame.display.init()
            pygame.font.init()

        try:
            pygame.mouse.set_visible(False)
        except:
            pass  # May fail on some drivers

        # Get display info with fallbacks
        try:
            info = pygame.display.Info()
            self.width = info.current_w if (fullscreen and info.current_w > 0) else 800
            self.height = info.current_h if (fullscreen and info.current_h > 0) else 600
        except:
            self.width = 800
            self.height = 600

        # Create display
        flags = pygame.FULLSCREEN if fullscreen else 0
        try:
            self.screen = pygame.display.set_mode((self.width, self.height), flags)
        except:
            # Fallback to window mode
            self.screen = pygame.display.set_mode((800, 600), 0)
            self.width, self.height = 800, 600

        pygame.display.set_caption("BlackRoad Brady Bunch")

        # Load fonts
        try:
            self.font_large = pygame.font.Font(None, 48)
            self.font_medium = pygame.font.Font(None, 32)
            self.font_small = pygame.font.Font(None, 24)
            self.font_tiny = pygame.font.Font(None, 18)
        except:
            self.font_large = pygame.font.SysFont('monospace', 48)
            self.font_medium = pygame.font.SysFont('monospace', 32)
            self.font_small = pygame.font.SysFont('monospace', 24)
            self.font_tiny = pygame.font.SysFont('monospace', 18)

        # Grid layout - 3x2 for 6 devices
        self.cols = 3
        self.rows = 2
        self.margin = 10
        self.header_height = 60

        # Calculate cell dimensions
        usable_height = self.height - self.header_height
        self.cell_width = (self.width - (self.cols + 1) * self.margin) // self.cols
        self.cell_height = (usable_height - (self.rows + 1) * self.margin) // self.rows

    def run(self):
        """Main display loop"""
        self.monitor.start()
        clock = pygame.time.Clock()

        try:
            while self.running:
                for event in pygame.event.get():
                    if event.type == pygame.QUIT:
                        self.running = False
                    elif event.type == pygame.KEYDOWN:
                        if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                            self.running = False

                self._draw_frame()
                pygame.display.flip()
                clock.tick(10)  # 10 FPS

        finally:
            self.monitor.stop()
            pygame.quit()

    def _draw_frame(self):
        """Draw complete frame"""
        # Clear screen
        self.screen.fill(COLORS['black'])

        # Draw header
        self._draw_header()

        # Draw device grid
        devices = self.monitor.get_devices()
        device_list = list(devices.values())

        for idx, device in enumerate(device_list[:6]):
            row = idx // self.cols
            col = idx % self.cols

            x = self.margin + col * (self.cell_width + self.margin)
            y = self.header_height + self.margin + row * (self.cell_height + self.margin)

            self._draw_device_cell(device, x, y, self.cell_width, self.cell_height)

    def _draw_header(self):
        """Draw header bar"""
        # Background
        pygame.draw.rect(self.screen, COLORS['dark_gray'],
                        (0, 0, self.width, self.header_height))

        # Title
        title = self.font_large.render("BlackRoad OS - Brady Bunch", True, COLORS['hot_pink'])
        self.screen.blit(title, (20, 10))

        # Time
        now = datetime.now().strftime("%H:%M:%S")
        time_text = self.font_medium.render(now, True, COLORS['amber'])
        self.screen.blit(time_text, (self.width - 150, 15))

        # Status summary
        devices = self.monitor.get_devices()
        online = sum(1 for d in devices.values() if d.status == "online")
        status = f"{online}/{len(devices)} online"
        status_text = self.font_small.render(status, True, COLORS['green'] if online == len(devices) else COLORS['amber'])
        self.screen.blit(status_text, (self.width - 350, 20))

    def _draw_device_cell(self, device: DeviceInfo, x: int, y: int, w: int, h: int):
        """Draw a single device cell"""
        # Background
        bg_color = COLORS['mid_gray'] if device.status == "online" else COLORS['dark_gray']
        pygame.draw.rect(self.screen, bg_color, (x, y, w, h), border_radius=8)

        # Border color based on status
        if device.status == "online":
            border_color = COLORS['green']
        elif device.status == "offline":
            border_color = COLORS['red']
        else:
            border_color = COLORS['amber']

        pygame.draw.rect(self.screen, border_color, (x, y, w, h), 3, border_radius=8)

        # Content
        padding = 15
        cy = y + padding

        # Device name (large)
        name_color = COLORS['hot_pink'] if device.name == "cecilia" else COLORS['electric_blue']
        name_text = self.font_medium.render(device.name.upper(), True, name_color)
        self.screen.blit(name_text, (x + padding, cy))
        cy += 35

        # IP and hardware
        ip_text = self.font_tiny.render(f"{device.ip}", True, COLORS['white'])
        self.screen.blit(ip_text, (x + padding, cy))
        cy += 20

        hw_text = self.font_tiny.render(device.hardware[:20], True, COLORS['amber'])
        self.screen.blit(hw_text, (x + padding, cy))
        cy += 25

        if device.status == "online":
            # Stats bars
            bar_width = w - 2 * padding - 60
            bar_height = 14

            # CPU
            self._draw_stat_bar(x + padding, cy, bar_width, bar_height,
                              "CPU", device.cpu_usage, COLORS['hot_pink'])
            cy += bar_height + 8

            # Memory
            self._draw_stat_bar(x + padding, cy, bar_width, bar_height,
                              "MEM", device.memory_pct, COLORS['violet'])
            cy += bar_height + 8

            # Disk
            self._draw_stat_bar(x + padding, cy, bar_width, bar_height,
                              "DSK", device.disk_pct, COLORS['electric_blue'])
            cy += bar_height + 8

            # Temperature
            if device.cpu_temp > 0:
                temp_color = COLORS['green'] if device.cpu_temp < 60 else (
                    COLORS['amber'] if device.cpu_temp < 70 else COLORS['red'])
                temp_text = self.font_small.render(f"{device.cpu_temp:.1f}C", True, temp_color)
                self.screen.blit(temp_text, (x + padding, cy))

            # Uptime
            if device.uptime:
                uptime_text = self.font_tiny.render(device.uptime, True, COLORS['white'])
                self.screen.blit(uptime_text, (x + padding + 80, cy))
        else:
            # Offline message
            status_text = self.font_medium.render(device.status.upper(), True, COLORS['red'])
            self.screen.blit(status_text, (x + w//2 - 40, y + h//2 - 10))

    def _draw_stat_bar(self, x: int, y: int, w: int, h: int,
                       label: str, value: float, color: Tuple[int, int, int]):
        """Draw a status bar with label"""
        # Label
        label_text = self.font_tiny.render(label, True, COLORS['white'])
        self.screen.blit(label_text, (x, y))

        # Bar background
        bar_x = x + 45
        bar_w = w - 45
        pygame.draw.rect(self.screen, COLORS['dark_gray'], (bar_x, y, bar_w, h), border_radius=3)

        # Bar fill
        fill_w = int(bar_w * min(value, 100) / 100)
        if fill_w > 0:
            pygame.draw.rect(self.screen, color, (bar_x, y, fill_w, h), border_radius=3)

        # Value
        value_text = self.font_tiny.render(f"{value:.0f}%", True, COLORS['white'])
        self.screen.blit(value_text, (bar_x + bar_w + 5, y))


def main():
    """Main entry point"""
    fullscreen = '--fullscreen' in sys.argv or '--kiosk' in sys.argv

    print(f"""
╔════════════════════════════════════════════════════════════╗
║  BlackRoad OS - Brady Bunch Native Display                 ║
║  Monitoring {len(DEVICE_FLEET)} devices in grid layout                       ║
╚════════════════════════════════════════════════════════════╝

Fullscreen: {fullscreen}
Press ESC or Q to exit
""")

    display = BradyBunchDisplay(fullscreen=fullscreen)
    display.run()


if __name__ == "__main__":
    main()
