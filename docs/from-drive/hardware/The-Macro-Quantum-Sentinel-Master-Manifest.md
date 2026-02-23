THE MACRO-QUANTUM SENTINEL: MASTER HARDWARE MANIFEST
This document serves as the final, exhaustive inventory for the Macro-Quantum Sentinel project. It categorizes every component by its role in the distributed AI, industrial sensing, and photonic logic architecture.
1. THE COMPUTE CORE (High-Density Neural Processing)
* 4x Raspberry Pi 5 (8GB): The primary orchestrators for the Hailo-8 tensor engines.
   * Config: 2x in Pironman 5-MAX cases (AI Hubs), 2x in ElectroCookie cases (Neural Nodes).
* 2x Hailo-8 M.2 AI Accelerators: The Tensor Processing Units.
   * Capability: 26 TOPS each (52 TOPS total) for high-speed parallel state evolution.
* 1x Apple M1 Mac: High-level training, visualization, and cloud-bridge orchestration.
* 1x MacBook Pro (Retina, 15-inch, Mid 2014): Legacy dev terminal and secondary visualization node.
* 2x DigitalOcean Droplets: Cloud-side "Digital Twins" for global mesh orchestration.
* 1x Crucial P310 1TB SSD: High-speed NVMe storage for the Master Pi 5 Node.
* 1x Crucial P310 500GB SSD: High-speed storage for the secondary AI Node.
* 1x Samsung EVO Select 256GB MicroSD: High-performance OS storage.
2. THE MISSION CONTROL & INDUSTRIAL HUB (Reliability Layer)
* 1x Raspberry Pi 4B (2GB): Hosting the Remote Control Server.
   * Features: HDMI Capture, ATX Power Control, PoE support, OLED Status Display.
* 1x Raspberry Pi 400: The "Ancient Terminal." Primary console for shell-based cluster management.
* 2x M5Stack Atom Lite (ESP32): The Industrial Commanders.
   * Role: Master controllers for the RS485 bus and IR photonic logic triggers.
* 2x RS485-to-TTL Logic Packs (5pcs each): The Industrial Nervous System.
   * Role: Differential signaling translators for high-reliability wired sensing.
* 1x TP-Link 5-Port Gigabit Switch: The physical backbone for the local Pi cluster.
3. THE QUANTUM OBSERVER ARRAY (Sensing Layer)
* 1x SparkFun Qwiic ToF Imager (VL53L5CX): 8x8 zone Single-Photon Avalanche Diode (SPAD) array.
* 1x LD2410 24GHz Radar: Millimeter-wave human presence and field-disturbance observer.
* 10x Photodiode Modules (4-pin): High-speed detection of directed light paths (mirrors).
* 24x LDR Photoresistors (5mm): Ambient light measurement and shadow-state monitors.
* 2x NEO-6M GPS Modules: Absolute spacetime anchors for the Sentinel satellite.
* 3x INMP441 MEMS Microphones: High-precision I2S acoustic observers.
* Pack DHT22/AM2302 & DHT11: Environmental noise/thermal sensors for measuring "decoherence."
* 1x Raspberry Pi Camera V2 (8MP): Classical optical observation.
4. THE SATELLITE & DISTRIBUTED LOGIC (Reflex Layer)
* 1x Raspberry Pi Zero 2 WH: The satellite orchestrator for the "Blue Machine" stack.
* 1x Raspberry Pi Zero W (Basic Kit): Legacy shell host and low-power beacon.
* 7x ESP32-S3 (Various): 5x Supermini Type-C, 2x N8R8 Development Boards.
   * Quantum Role: Entropy generation via internal Thermal Noise TRNG.
* 2x Raspberry Pi Pico (RP2040): Precision timing and LoRa telemetry management.
* 3x ATTINY88 Micro: Hard-coded discrete logic gates for specific hardware triggers.
* 1x ELEGOO UNO R3: Prototyping bridge for 5V analog/digital sensor integration.
5. PHOTONIC & HAPTIC INTERACTION (Feedback Layer)
* Visual Displays:
   * 1x 10.1" Touchscreen Monitor (FHD 1024x600).
   * 1x 9.3" Wide Capacitive Display (1600x600).
   * 1x 7" Waveshare Touchscreen (1024x600).
   * 1x 4" Waveshare HDMI Touchscreen (720x720).
   * 3x 2.8" ESP32 Touchscreens (240x320).
   * 3x 0.96" OLED Modules (SSD1306 I2C).
   * 1x 2.8" TFT Shield for Arduino UNO.
* Haptics & Light:
   * 1x Walfront Bone Conduction Resonance Speaker (8Ω).
   * 2x MAX98357A I2S 3W Class D Amplifiers (Audio Decoder).
   * 1x 16.4FT WS2812B RGB LED Strip (300 LEDs).
   * EUSTUMA & ZEERSHEE LED Light Bases (for mirror illumination).
* Input:
   * Apple Magic Mouse (Multi-Touch).
   * Apple Magic Keyboard (US English).
   * Logitech H390 USB Headset.
6. CONNECTIVITY & CLUSTER MESH
* 1x RYLR998 LoRa Module (868/915 MHz): Long-range telemetry link.
* 1x Heltec WiFi LoRa 32 (V3): LoRa-to-WiFi gateway/mesh node.
* 4x NRF24L01+ Modules: Short-range, low-latency inter-node communication.
* 1x Si5351A Clock Generator: Global phase-locking master clock (8KHz - 160MHz).
* 1x Archer TX3000E WiFi 6 Card: High-bandwidth PC-to-Cluster link.
* 1x TobenONE 15-in-1 Docking Station: Central hub for M1 Mac integration.
* 1x Dell WD19S 130W Dock: High-power connectivity for the MacBook Pro.
7. POWER, STRUCTURE & PHYSICAL OPTICS
* Optics Lattice:
   * 50x Square Glass Mirror Tiles (4").
   * 5x Beveled Square Glass Mirrors (6").
   * 3x Acrylic Cube Display Stands (Hollow bottom).
   * 100x Natural Bamboo Sticks (15.7") for custom framing.
* Power Grid:
   * 5x 18650 Battery Holders & Charger Modules.
   * 2x Anker 10,000mAh Power Banks (30W PD).
   * Geekworm 27W PD Power Supply for Pi 5.
   * Multiple 5V/4A Power Adapters.
* Cooling:
   * ElectroCookie Pi 5 Mini Tower Cases (RGB).
   * GeeekPi Active Cooler & Armor Lite V5.
   * Pi 4 Radial Power Cooling Tower.
8. LABORATORY & ASSEMBLY (The Crafting Stack)
* Soldering: 60W Soldering Iron Kit, Helping Hands (KOTTO & SainSmart Magnetic), Solder Smoke Absorber.
* Repair: 7pcs Precision Tweezers, Heat Resistant Silicone Mat (17.7" x 11.8").
* Organization: Akro-Mils 16-Drawer Cabinet, Breaker Panel Labels.
* Kits: Freenove Ultimate Starter Kit for Pi 5, ELEGOO UNO Project Super Starter Kit.
* Supplies: 840-piece Jumper Wire Kit, J-B Weld Clear RTV Silicone, Glass Cutter Tool.