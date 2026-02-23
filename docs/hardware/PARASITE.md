# Parasite — ESP8285 Hidden Backup

## Overview

Parasite is a covert backup communication module based on the **ESP8285** (ESP8266 with integrated 1MB flash), disguised inside a USB-C cable or power adapter.

## Hardware Specs

| Component | Spec |
|-----------|------|
| MCU | ESP8285 (Tensilica L106 @ 80MHz) |
| Flash | 1MB integrated |
| WiFi | 802.11 b/g/n 2.4GHz |
| Power | ~70mW idle, ~350mW TX |
| Size | 5×5mm (ESP8285 die) |
| Price | ~$1.50 USD |

## Capabilities

- **WiFi beacon**: Broadcasts BlackRoad mesh presence
- **OTA updates**: Self-updates via WiFi
- **Heartbeat**: Periodic ping to gateway (proves system alive)
- **Emergency recovery**: Triggers Pi reboot via GPIO if Pi becomes unresponsive

## Firmware

```cpp
// MicroPython (esp-idf)
import network, urequests, time

wlan = network.WLAN(network.STA_IF)
wlan.active(True)
wlan.connect('BLACKROAD_MESH', 'PASSWORD')

while True:
    if wlan.isconnected():
        urequests.post('https://api.blackroad.io/heartbeat', 
                       json={'node': 'parasite-1', 'ts': time.time()})
    time.sleep(300)  # 5 min heartbeat
```

## Security

- Firmware encrypted with AES-128
- SSID hidden by default (monitor mode only)
- No listening ports — TX only (heartbeat)

## Status: 🔜 Planned (Q4 2026)
