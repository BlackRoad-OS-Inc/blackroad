#!/usr/bin/env python3
"""WaveQube Serial Controller

Talk to the WaveQube ESP32 (BLACKROAD OS ENHANCED v2.0) over USB serial.
Launch apps, read events, send commands, monitor touch input, and
interact with the cube from your Mac or Pi.

Usage:
    python3 wavecube_controller.py                  # Interactive mode
    python3 wavecube_controller.py --app dashboard   # Launch app directly
    python3 wavecube_controller.py --monitor         # Monitor all events
    python3 wavecube_controller.py --reboot          # Reboot the ESP32
    python3 wavecube_controller.py --info            # Show device info
    python3 wavecube_controller.py --port /dev/XXX   # Custom serial port

Requirements:
    pip install pyserial
"""

import argparse
import sys
import time

import serial
import serial.tools.list_ports

# --- Config ---
DEFAULT_BAUD = 115200

# Known signatures for auto-detection
WAVECUBE_SIGNATURES = {
    "ch340": {"vid": 0x1A86, "pid": 0x7523},  # QinHeng CH340
}
BOUFFALO_SIGNATURES = {
    "bl808": {"vid": 0xFFFF, "pid": 0xFFFF, "manufacturer": "Bouffalo"},
}

# --- App Map ---
APPS = {
    "dashboard": "1",
    "weather": "2",
    "crypto": "3",
    "browser": "4",
    "snake": "5",
    "network": "6",
    "settings": "7",
    "portfolio": "8",
}

APP_NAMES = {v: k for k, v in APPS.items()}

# --- Colors ---
PINK = "\033[38;5;205m"
CYAN = "\033[0;36m"
GREEN = "\033[38;5;82m"
YELLOW = "\033[1;33m"
RED = "\033[0;31m"
DIM = "\033[2m"
RESET = "\033[0m"
BOLD = "\033[1m"


def find_port_by_signature(signatures):
    """Find a serial port matching any of the given VID/PID/manufacturer signatures."""
    for port in serial.tools.list_ports.comports():
        for name, sig in signatures.items():
            vid_match = port.vid == sig.get("vid") if "vid" in sig else True
            pid_match = port.pid == sig.get("pid") if "pid" in sig else True
            mfg_match = (sig.get("manufacturer", "").lower() in (port.manufacturer or "").lower()
                         if "manufacturer" in sig else True)
            if vid_match and pid_match and mfg_match:
                return port.device
    return None


def find_wavecube_port():
    """Auto-detect the WaveQube ESP32 serial port.

    Tries in order:
    1. Known CH340 VID:PID
    2. Any port with 'usbserial' or 'CH340' in name/description
    3. Probe unknown USB serial ports for the BLACKROAD OS signature
    """
    # 1. Known VID:PID
    found = find_port_by_signature(WAVECUBE_SIGNATURES)
    if found:
        return found

    # 2. Name-based matching
    for port in serial.tools.list_ports.comports():
        desc = (port.description or "").lower()
        dev = (port.device or "").lower()
        if "ch340" in desc or "usbserial" in dev:
            return port.device

    # 3. Probe USB serial ports for BLACKROAD OS response
    candidates = []
    for port in serial.tools.list_ports.comports():
        if port.vid and port.device not in _known_bouffalo_ports():
            candidates.append(port.device)

    for dev in candidates:
        if _probe_for_wavecube(dev):
            return dev

    return None


def find_bouffalo_port():
    """Auto-detect the Bouffalo BL808 shell port (command port at 2Mbaud)."""
    ports = []
    for port in serial.tools.list_ports.comports():
        if (port.manufacturer or "").lower() == "bouffalo":
            ports.append(port.device)
        elif port.vid == 0xFFFF and port.pid == 0xFFFF:
            ports.append(port.device)

    # The command shell is typically the lower-numbered modem port
    # Probe each to find the one that responds to 'help'
    for dev in sorted(ports):
        try:
            s = serial.Serial(dev, 2000000, timeout=1)
            s.reset_input_buffer()
            s.write(b'\r\n')
            time.sleep(0.3)
            data = s.read(256)
            s.close()
            if data and b'#' in data:
                return dev
        except Exception:
            continue
    return ports[0] if ports else None


def _known_bouffalo_ports():
    """Return device paths for known Bouffalo ports (to exclude from WaveQube probe)."""
    result = []
    for port in serial.tools.list_ports.comports():
        if (port.manufacturer or "").lower() == "bouffalo":
            result.append(port.device)
        elif port.vid == 0xFFFF and port.pid == 0xFFFF:
            result.append(port.device)
    return result


def _probe_for_wavecube(device, timeout=3):
    """Open a serial port and check if it speaks WaveQube protocol."""
    try:
        s = serial.Serial(device, DEFAULT_BAUD, timeout=0.5)
        s.reset_input_buffer()
        # Send '7' then '1' (Settings > reboot) — too destructive
        # Instead just listen for [TOUCH] or [BACK] or [LAUNCH]
        start = time.time()
        while time.time() - start < timeout:
            data = s.read(512)
            if data:
                text = data.decode("utf-8", errors="replace")
                if "[TOUCH]" in text or "[BACK]" in text or "[LAUNCH]" in text or "BLACKROAD" in text:
                    s.close()
                    return True
        s.close()
    except Exception:
        pass
    return False


def list_all_devices():
    """List all detected USB serial devices with identification."""
    devices = []
    for port in serial.tools.list_ports.comports():
        if not port.vid:
            continue  # skip bluetooth/system ports
        vid = f"0x{port.vid:04x}" if port.vid else "----"
        pid = f"0x{port.pid:04x}" if port.pid else "----"
        devices.append({
            "device": port.device,
            "product": port.product or port.description or "Unknown",
            "manufacturer": port.manufacturer or "Unknown",
            "vid_pid": f"{vid}:{pid}",
            "serial": port.serial_number or "n/a",
        })
    return devices


class WaveQube:
    """Interface to the WaveQube ESP32 over serial."""

    def __init__(self, port=None, baud=DEFAULT_BAUD):
        self.port = port or find_wavecube_port()
        self.baud = baud
        self.serial = None
        self.current_app = None
        self._monitor_thread = None
        self._monitoring = False

    def connect(self):
        if not self.port:
            print(f"{RED}No WaveQube port detected. Is it plugged in?{RESET}")
            return False
        try:
            self.serial = serial.Serial(self.port, self.baud, timeout=0.3)
            time.sleep(0.5)
            self.serial.reset_input_buffer()
            return True
        except serial.SerialException as e:
            print(f"{RED}Connection failed: {e}{RESET}")
            return False

    def disconnect(self):
        if self.serial and self.serial.is_open:
            self.serial.close()

    def send(self, cmd):
        """Send a command and return response lines (filtered)."""
        if not self.serial or not self.serial.is_open:
            return []
        self.serial.reset_input_buffer()
        if isinstance(cmd, str):
            cmd = cmd.encode()
        self.serial.write(cmd)
        time.sleep(0.8)
        return self._read_lines()

    def _read_lines(self, timeout=1.5):
        """Read and parse response lines, filtering touch spam."""
        lines = []
        start = time.time()
        while time.time() - start < timeout:
            try:
                raw = self.serial.readline()
                if raw:
                    text = raw.decode("utf-8", errors="replace").strip()
                    if text:
                        lines.append(text)
                else:
                    if lines:
                        break
            except Exception:
                break
        return lines

    def launch_app(self, name):
        """Launch an app by name or number."""
        if name in APPS:
            cmd = APPS[name]
        elif name in APP_NAMES:
            cmd = name
        else:
            print(f"{RED}Unknown app: {name}{RESET}")
            print(f"Available: {', '.join(APPS.keys())}")
            return []

        lines = self.send(cmd)
        for line in lines:
            if line.startswith("[LAUNCH]"):
                self.current_app = name
        return lines

    def back(self):
        """Go back to the menu."""
        lines = self.send(b"b")
        self.current_app = None
        return lines

    def reboot(self):
        """Reboot the ESP32 by navigating to Settings and triggering reset."""
        print(f"{YELLOW}Rebooting WaveQube...{RESET}")
        self.send(b"b")
        time.sleep(0.3)
        self.send(b"7")  # Settings
        time.sleep(0.3)
        lines = self.send(b"1")  # Triggers reboot
        return lines

    def get_boot_info(self):
        """Reboot and capture the boot log."""
        lines = self.reboot()
        boot_lines = []
        for line in lines:
            if not line.startswith("[TOUCH]"):
                boot_lines.append(line)
        return boot_lines

    def monitor(self, callback=None, filter_touch=True):
        """Monitor serial output continuously."""
        if not self.serial or not self.serial.is_open:
            return

        self._monitoring = True
        while self._monitoring:
            try:
                raw = self.serial.readline()
                if raw:
                    text = raw.decode("utf-8", errors="replace").strip()
                    if text:
                        if filter_touch and text.startswith("[TOUCH]"):
                            continue
                        if callback:
                            callback(text)
                        else:
                            self._default_print(text)
            except Exception:
                if self._monitoring:
                    time.sleep(0.1)

    def stop_monitor(self):
        self._monitoring = False

    @staticmethod
    def _default_print(text):
        if text.startswith("[LAUNCH]"):
            print(f"{GREEN}{text}{RESET}")
        elif text.startswith("[BACK]"):
            print(f"{CYAN}{text}{RESET}")
        elif text.startswith("[WARN]"):
            print(f"{YELLOW}{text}{RESET}")
        elif text.startswith("[SNAKE]"):
            print(f"{PINK}{text}{RESET}")
        elif text.startswith("[READY]"):
            print(f"{GREEN}{text}{RESET}")
        elif text.startswith("[OK]"):
            print(f"{GREEN}{text}{RESET}")
        elif "BLACKROAD" in text:
            print(f"{PINK}{BOLD}{text}{RESET}")
        else:
            print(f"{DIM}{text}{RESET}")


def interactive_mode(cube):
    """Interactive REPL for controlling the WaveQube."""
    print(f"""
{PINK}╔══════════════════════════════════════════╗
║       WaveQube Controller v1.0           ║
║    BLACKROAD OS ENHANCED v2.0            ║
╠══════════════════════════════════════════╣
║  {CYAN}Apps:{PINK}                                    ║
║    1=Dashboard  2=Weather  3=Crypto      ║
║    4=Browser    5=Snake    6=Network     ║
║    7=Settings   8=Portfolio              ║
║  {CYAN}Commands:{PINK}                                ║
║    b=Back  r=Reboot  m=Monitor  q=Quit   ║
║    Type app name or number to launch     ║
╚══════════════════════════════════════════╝{RESET}
""")

    while True:
        try:
            app_str = f" [{cube.current_app}]" if cube.current_app else ""
            cmd = input(f"{PINK}wavecube{CYAN}{app_str}{RESET}> ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print()
            break

        if not cmd:
            continue
        elif cmd in ("q", "quit", "exit"):
            break
        elif cmd == "b" or cmd == "back":
            lines = cube.back()
            for l in lines:
                if not l.startswith("[TOUCH]"):
                    cube._default_print(l)
        elif cmd in ("r", "reboot"):
            lines = cube.reboot()
            for l in lines:
                cube._default_print(l)
        elif cmd in ("m", "monitor"):
            print(f"{DIM}Monitoring... press Ctrl+C to stop{RESET}")
            try:
                cube.monitor(filter_touch=True)
            except KeyboardInterrupt:
                cube.stop_monitor()
                print(f"\n{CYAN}Monitor stopped.{RESET}")
        elif cmd in ("mt", "monitor-touch"):
            print(f"{DIM}Monitoring with touch... press Ctrl+C to stop{RESET}")
            try:
                cube.monitor(filter_touch=False)
            except KeyboardInterrupt:
                cube.stop_monitor()
                print(f"\n{CYAN}Monitor stopped.{RESET}")
        elif cmd in ("i", "info"):
            print(f"  Port: {cube.port}")
            print(f"  Baud: {cube.baud}")
            print(f"  App:  {cube.current_app or 'menu'}")
        elif cmd in ("?", "help"):
            print(f"  {GREEN}1-8{RESET}       Launch app by number")
            print(f"  {GREEN}<name>{RESET}    Launch app by name (dashboard, snake, etc)")
            print(f"  {CYAN}b/back{RESET}    Return to menu")
            print(f"  {CYAN}r/reboot{RESET}  Reboot the ESP32")
            print(f"  {CYAN}m/monitor{RESET} Watch serial output (Ctrl+C to stop)")
            print(f"  {CYAN}mt{RESET}        Monitor including touch events")
            print(f"  {CYAN}i/info{RESET}    Show connection info")
            print(f"  {CYAN}q/quit{RESET}    Exit")
        elif cmd in APPS:
            lines = cube.launch_app(cmd)
            for l in lines:
                if not l.startswith("[TOUCH]"):
                    cube._default_print(l)
        elif cmd in APP_NAMES:
            lines = cube.launch_app(cmd)
            for l in lines:
                if not l.startswith("[TOUCH]"):
                    cube._default_print(l)
        elif len(cmd) == 1 and cmd in "12345678":
            lines = cube.send(cmd.encode())
            for l in lines:
                if not l.startswith("[TOUCH]"):
                    cube._default_print(l)
        else:
            # Try sending raw
            lines = cube.send(cmd.encode() + b"\r\n")
            printed = False
            for l in lines:
                if not l.startswith("[TOUCH]"):
                    cube._default_print(l)
                    printed = True
            if not printed:
                print(f"{DIM}(no response){RESET}")


def main():
    parser = argparse.ArgumentParser(description="WaveQube Serial Controller")
    parser.add_argument("--port", default=None, help="Serial port (auto-detects CH340)")
    parser.add_argument("--baud", type=int, default=DEFAULT_BAUD, help="Baud rate")
    parser.add_argument("--app", choices=list(APPS.keys()), help="Launch app directly")
    parser.add_argument("--monitor", action="store_true", help="Monitor serial output")
    parser.add_argument("--reboot", action="store_true", help="Reboot the ESP32")
    parser.add_argument("--info", action="store_true", help="Show boot info")
    parser.add_argument("--list-ports", action="store_true", help="List serial ports")
    args = parser.parse_args()

    if args.list_ports:
        print("Available serial ports:")
        for port in serial.tools.list_ports.comports():
            vid = f"0x{port.vid:04x}" if port.vid else "----"
            pid = f"0x{port.pid:04x}" if port.pid else "----"
            print(f"  {port.device}  [{vid}:{pid}]  {port.description}")
        return

    cube = WaveQube(port=args.port, baud=args.baud)

    if cube.port:
        print(f"{CYAN}Connecting to WaveQube on {cube.port}...{RESET}")
    else:
        print(f"{RED}No WaveQube detected.{RESET}")
        devices = list_all_devices()
        if devices:
            print(f"{YELLOW}USB serial devices found:{RESET}")
            for d in devices:
                print(f"  {d['device']}  [{d['vid_pid']}]  {d['product']} ({d['manufacturer']})")
            print(f"{YELLOW}Try: --port <device>{RESET}")
        else:
            print(f"{RED}No USB serial devices found. Is the WaveQube plugged in?{RESET}")
        sys.exit(1)

    if not cube.connect():
        sys.exit(1)

    print(f"{GREEN}Connected to {cube.port}!{RESET}")

    try:
        if args.reboot:
            lines = cube.reboot()
            for l in lines:
                cube._default_print(l)
        elif args.info:
            lines = cube.get_boot_info()
            for l in lines:
                cube._default_print(l)
        elif args.app:
            lines = cube.launch_app(args.app)
            for l in lines:
                cube._default_print(l)
        elif args.monitor:
            print(f"{DIM}Monitoring... press Ctrl+C to stop{RESET}")
            try:
                cube.monitor(filter_touch=True)
            except KeyboardInterrupt:
                cube.stop_monitor()
                print()
        else:
            interactive_mode(cube)
    finally:
        cube.disconnect()
        print(f"{DIM}Disconnected.{RESET}")


if __name__ == "__main__":
    main()
