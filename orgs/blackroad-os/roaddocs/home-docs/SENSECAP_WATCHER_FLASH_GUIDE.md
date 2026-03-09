# 🔓 SenseCAP Watcher - Flash/Hack Guide

## 🔍 What We Discovered

**Device Status:** ✅ ALIVE AND RUNNING!
- **Serial Port:** `/dev/tty.usbmodem56D50202901` (main UART)
- **Baud Rate:** 115200
- **Current State:** Running factory firmware, streaming binary data
- **Binary Output:** Sensor telemetry / display commands (not text console)

## 🎯 To Flash Custom Firmware

### Method 1: Manual Bootloader Mode (WORKS)

**You need to physically interact with the device:**

1. **Locate the BOOT button** on the SenseCAP Watcher
   - It's usually on the side or back
   - Might be labeled "BOOT", "0", or be unmarked

2. **Enter bootloader mode:**
   ```
   Step 1: Hold down the BOOT button
   Step 2: While holding BOOT, press and release RESET (or power cycle)
   Step 3: Release BOOT button
   Step 4: Device is now in bootloader mode!
   ```

3. **Verify bootloader mode:**
   ```bash
   esptool --port /dev/tty.usbmodem56D50202901 chip-id
   ```

   You should see:
   ```
   Chip is ESP32-S3 (revision vX.X)
   Features: WiFi, BLE
   Crystal is 40MHz
   MAC: xx:xx:xx:xx:xx:xx
   ```

4. **Flash firmware:**
   ```bash
   cd ~/sensecap-watcher-sdk/examples/helloworld
   # Build with ESP-IDF (needs ESP-IDF installed)
   idf.py build
   idf.py flash
   ```

### Method 2: Check for BOOT/RESET Buttons

The SenseCAP Watcher might have:
- **Physical buttons** on the device
- **Rotary encoder button** (press and hold = BOOT?)
- **Software method** via USB protocol

**Look for:**
1. Any small buttons on the device
2. Instructions in the box
3. Pin holes for reset

## 🔨 Alternative: Build and Flash via ESP-IDF

### Step 1: Install ESP-IDF v5.2.1

```bash
# Quick install with installer
cd ~
git clone --recursive --branch v5.2.1 https://github.com/espressif/esp-idf.git esp-idf-v5.2.1
cd esp-idf-v5.2.1
./install.sh esp32s3

# Activate ESP-IDF environment
. ./export.sh
```

### Step 2: Build Example Firmware

```bash
cd ~/sensecap-watcher-sdk/examples/helloworld

# Configure for ESP32-S3
idf.py set-target esp32s3

# Build
idf.py build

# Flash (requires bootloader mode!)
idf.py -p /dev/tty.usbmodem56D50202901 flash

# Monitor output
idf.py -p /dev/tty.usbmodem56D50202901 monitor
```

### Step 3: Try Speech Recognition Example

```bash
cd ~/sensecap-watcher-sdk/examples/speech_recognize

idf.py set-target esp32s3
idf.py build
idf.py -p /dev/tty.usbmodem56D50202901 flash monitor
```

## 🎤 Quick Audio Test Without Flashing

If you can access the device's current firmware, you might be able to:

1. **Check if it has a web interface:**
   - Connect to same WiFi
   - Look for mDNS: `dns-sd -B _http._tcp`
   - Try http://sensecap-watcher.local

2. **Check for BLE interface:**
   - Might have BLE control
   - Use iOS/Android app

3. **USB Mass Storage:**
   - Some ESP32 devices appear as USB drives
   - Check if it mounts automatically

## 📊 Current Binary Data Analysis

The device is outputting binary data at 115200 baud:
```
- 173 bytes captured in 5 seconds
- High frequency bytes: 0x86, 0x56 (V), 0xff, 0x77 (w)
- No null bytes, newlines, or text patterns
- Likely: sensor telemetry, display SPI commands, or status data
```

**This means the device is:**
- ✅ Powered on
- ✅ Running firmware
- ✅ Actively processing (sensors/display)
- ❌ Not outputting debug console text

## 🚀 Recommended Next Steps

### Option A: Physical Button Method (5 minutes)
**Find and press BOOT button → Flash immediately**

1. Look for BOOT button on device
2. Enter bootloader mode
3. Flash speech_recognize example
4. Test mic + speaker!

### Option B: Install ESP-IDF First (30 minutes)
**Set up proper development environment**

1. Install ESP-IDF v5.2.1
2. Build helloworld example
3. Wait for your input on BOOT button location
4. Flash when ready

### Option C: Use Existing Firmware (0 minutes)
**Explore what's already on it**

1. Check for WiFi AP mode
2. Check for BLE
3. Check for web interface
4. See if factory firmware has voice features

## 🔍 Questions to Answer

1. **Where is the BOOT button?**
   - Side panel?
   - Back of device?
   - Pin hole?

2. **What's the device doing right now?**
   - Is the screen on?
   - Any LEDs blinking?
   - Can you interact with it?

3. **Do you want to:**
   - A) Flash new firmware immediately (need BOOT button)
   - B) Explore factory firmware first
   - C) Install ESP-IDF and build from source

---

## 💡 Pro Tip: The Device is Ready!

The fact that it's streaming binary data means:
- ✅ ESP32S3 is working
- ✅ USB connection is good
- ✅ Firmware is running
- ✅ All systems operational

**We just need to get it into bootloader mode to flash our custom Operator AI OS!**

**Tell me:**
1. Can you see/access the device physically?
2. Are there any buttons visible?
3. Is the screen showing anything?

Then we can **HACK IT!** 🔓✨
