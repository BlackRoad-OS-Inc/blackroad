# WaveQube — Hologram Projector Hack

Gutted WaveQube wave lamp turned into a DLP projector driven by a Raspberry Pi. Projects generative art, audio-reactive visuals, and an animated robot with emotions onto your wall.

## Hardware

### Bill of Materials

| Component | Cost | Source |
|-----------|------|--------|
| TI DLP LightCrafter 2000 EVM (DLP2000) | ~$99 | TI Store / Mouser / Digikey |
| MickMake Pi Projector PCB adapter | ~$4 | mickmake.com |
| Raspberry Pi Zero 2W (or Pi 4) | $15-55 | Already in fleet |
| 5V 3A USB-C power supply | ~$10 | Amazon / existing |
| Micro HDMI ribbon / GPIO header | ~$5 | Amazon |
| 30mm fan (optional cooling) | ~$3 | Amazon |
| **Total** | **~$130** | |

### DLP2000 Specs
- **Resolution**: 640 x 360 (nHD)
- **Brightness**: ~20 lumens (dim/dark rooms)
- **Board size**: 54mm x 76mm
- **Power**: 5V @ 3A (shared rail with Pi)
- **Interface**: RGB666 18-bit DPI via GPIO
- **Throw**: ~1:1 to 1.5:1 (4-7 ft for ~50" image)

### Build Steps

1. **Gut the WaveQube** — Remove motor disc, LED board, IR receiver, control PCB. Keep cube shell and lens aperture.
2. **Mount DLP2000** — Align projection lens with aperture opening. Secure with standoffs.
3. **Mount Pi** — Solder MickMake PCB adapter to GPIO. Stack: Pi → adapter → DLP2000 (~25mm total height).
4. **Power** — Single 5V 3A supply to both Pi and DLP. Route through existing USB port hole.
5. **Cooling** — Optional 30mm fan against a vent hole.
6. **Focus** — Manual focus ring on DLP2000 lens. Position 3-6 ft from wall.

## Software Setup

### Quick Install (on the Pi)

```bash
git clone <this-repo> ~/wavecube
cd ~/wavecube
chmod +x install.sh
./install.sh
sudo reboot
```

### Manual Install

```bash
# 1. Install dependencies
sudo apt-get install -y python3-pip python3-pygame fbi portaudio19-dev
pip3 install pygame numpy pyaudio

# 2. Configure DPI output (add to /boot/config.txt)
# See config/boot-config.txt for the exact lines

# 3. Reboot
sudo reboot

# 4. Test
./wavecube-launcher.sh robot --windowed
```

## Modes

### Robot (default)
Animated robot character with full emotion system.

```bash
./wavecube-launcher.sh robot
```

**Emotions**: neutral, happy, curious, excited, sleepy, surprised, love
**Actions**: wave, dance, jump, pick (grabs floating objects), think

| Key | Action |
|-----|--------|
| 1-6 | Set emotion (happy/curious/excited/sleepy/surprised/love) |
| 0 | Reset to neutral |
| w/d/j/p/t | Wave / Dance / Jump / Pick / Think |
| SPACE | Random action |
| a | Toggle auto-mood (cycles emotions autonomously) |
| c | Cycle color scheme |
| q/ESC | Quit |

### Waves
Layered generative sine waves in BlackRoad brand colors.

```bash
./wavecube-launcher.sh waves
```

| Key | Action |
|-----|--------|
| 1-4 | Toggle wave layers |
| r | Randomize wave parameters |
| +/- | Speed up / slow down |
| SPACE | Pause/resume |

### Audio
Real-time FFT frequency visualization from microphone input. Falls back to simulated audio if no mic.

```bash
./wavecube-launcher.sh audio
```

| Key | Action |
|-----|--------|
| s | Cycle style (bars / wave / circle) |
| m | Toggle mic / simulated |
| +/- | Adjust sensitivity |

### Slideshow
Rotate through images in the `images/` directory.

```bash
./wavecube-launcher.sh slideshow
```

### Logo
Static single-image projection.

```bash
./wavecube-launcher.sh logo
# Requires images/blackroad-logo.png
```

## Auto-Start

The installer sets up a systemd service that starts in robot mode on boot.

```bash
# Check status
sudo systemctl status wavecube

# Change mode (edit ExecStart line)
sudo nano /etc/systemd/system/wavecube.service
sudo systemctl daemon-reload
sudo systemctl restart wavecube

# Disable auto-start
sudo systemctl disable wavecube
```

## Testing on Desktop

All Python modes accept `--windowed` to run on a regular display:

```bash
python3 wavecube_robot.py --windowed
python3 wavecube_viz.py --windowed
python3 wavecube_audio.py --windowed
```

## File Structure

```
wavecube/
├── wavecube_robot.py       # Animated robot with emotions
├── wavecube_viz.py         # Generative waveform art
├── wavecube_audio.py       # Audio reactive FFT visuals
├── wavecube-launcher.sh    # Mode switcher
├── install.sh              # Pi installer
├── requirements.txt        # Python dependencies
├── config/
│   └── boot-config.txt     # DPI config for /boot/config.txt
├── systemd/
│   └── wavecube.service    # Auto-start service
└── images/                 # Images for slideshow/logo modes
```
