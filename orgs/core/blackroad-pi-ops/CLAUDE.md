# BlackRoad Pi Ops

> Edge device management for Raspberry Pi and Jetson - LED control, screen rendering, and hardware interfaces

## Quick Reference

| Property | Value |
|----------|-------|
| **Language** | Python 3.9+ |
| **Framework** | Flask |
| **Platform** | Raspberry Pi, Jetson |
| **License** | MIT |

## Supported Devices

| Device | IP Address | Role |
|--------|------------|------|
| **lucidia** | 192.168.4.38 | Primary Pi |
| **blackroad-pi** | 192.168.4.64 | Secondary |
| **lucidia-alt** | 192.168.4.99 | Alternate |

## Tech Stack

```
Python 3.9+
├── Flask (Web Server)
├── Pillow (Image Processing)
├── RPi.GPIO (GPIO Control)
├── rpi_ws281x (LED Strips)
└── spidev (SPI Interface)
```

## Installation

```bash
# Standard install
pip install blackroad-pi-ops

# With Raspberry Pi support
pip install blackroad-pi-ops[rpi]

# Development
pip install -e ".[dev,rpi]"
```

## Commands

```bash
pi-ops             # Start Pi operations server
led-bridge         # Start LED bridge service

# Development
pytest             # Run tests
black .            # Format code
```

## Hardware Interfaces

### LED Control
- WS2812B LED strips via rpi_ws281x
- Custom patterns and animations
- Remote control via REST API

### GPIO
- Digital I/O control
- PWM output
- Event-driven input handling

### SPI
- High-speed data transfer
- Display interfaces
- Sensor communication

## Project Structure

```
app.py              # Main Flask application
led_bridge.py       # LED control bridge
gpio/
├── pins.py         # Pin mappings
├── output.py       # Output control
└── input.py        # Input handling
display/
├── screen.py       # Screen rendering
└── patterns.py     # LED patterns
```

## API Endpoints

```
GET  /health           # Health check
POST /led/pattern      # Set LED pattern
POST /led/color        # Set LED color
GET  /gpio/status      # GPIO pin status
POST /gpio/set         # Set GPIO output
POST /display/render   # Render to display
```

## Environment Variables

```env
PI_OPS_PORT=5000       # Server port
LED_PIN=18             # LED data pin
LED_COUNT=60           # Number of LEDs
LED_BRIGHTNESS=128     # Brightness (0-255)
```

## Related Repos

- `blackroad-pi-holo` - Holographic display
- `blackroad-tools` - DevOps utilities
- `blackroad-agents` - Agent API
