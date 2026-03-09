# 🔲 ESP32 LED Matrix Integration

## Hardware Setup

Connect your ESP32 to an LED matrix (WS2812B or similar):

```
ESP32 Pin | LED Matrix
----------|------------
GPIO 16   | DIN (Data)
5V        | VCC
GND       | GND
```

## Arduino Code

```cpp
#include <WiFi.h>
#include <WebSocketsClient.h>
#include <FastLED.h>

#define LED_PIN     16
#define NUM_LEDS    256  // 16x16 matrix
#define BRIGHTNESS  50
#define LED_TYPE    WS2812B
#define COLOR_ORDER GRB

CRGB leds[NUM_LEDS];

const char* ssid = "YOUR_WIFI";
const char* password = "YOUR_PASSWORD";
const char* ws_host = "192.168.4.28";  // Your bridge IP
const uint16_t ws_port = 8765;

WebSocketsClient webSocket;

// BlackRoad Colors
CRGB COLOR_PINK = CRGB(255, 29, 108);
CRGB COLOR_AMBER = CRGB(245, 166, 35);
CRGB COLOR_BLUE = CRGB(41, 121, 255);
CRGB COLOR_VIOLET = CRGB(156, 39, 176);

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_CONNECTED:
      Serial.println("🟢 Connected to BlackRoad Metaverse");
      break;
      
    case WStype_TEXT:
      handleEvent((char*)payload);
      break;
      
    case WStype_DISCONNECTED:
      Serial.println("🔴 Disconnected");
      break;
  }
}

void handleEvent(char* json) {
  // Parse event type and create visual effect
  if (strstr(json, "memory-write")) {
    flashEffect(COLOR_VIOLET);
  } else if (strstr(json, "agent-init")) {
    waveEffect(COLOR_PINK);
  } else if (strstr(json, "session-active")) {
    pulseEffect(COLOR_AMBER);
  } else {
    sparkleEffect(COLOR_BLUE);
  }
}

void flashEffect(CRGB color) {
  fill_solid(leds, NUM_LEDS, color);
  FastLED.show();
  delay(100);
  fadeToBlackBy(leds, NUM_LEDS, 200);
  FastLED.show();
}

void waveEffect(CRGB color) {
  for(int i = 0; i < 16; i++) {
    for(int j = 0; j < 16; j++) {
      leds[i * 16 + j] = color;
    }
    FastLED.show();
    delay(20);
    fadeToBlackBy(leds, NUM_LEDS, 50);
  }
}

void pulseEffect(CRGB color) {
  int center = NUM_LEDS / 2;
  leds[center] = color;
  FastLED.show();
  delay(50);
  blur1d(leds, NUM_LEDS, 50);
  FastLED.show();
}

void sparkleEffect(CRGB color) {
  int pos = random(NUM_LEDS);
  leds[pos] = color;
  FastLED.show();
  fadeToBlackBy(leds, NUM_LEDS, 20);
}

void setup() {
  Serial.begin(115200);
  
  // Initialize LEDs
  FastLED.addLeds<LED_TYPE, LED_PIN, COLOR_ORDER>(leds, NUM_LEDS)
    .setCorrection(TypicalLEDStrip);
  FastLED.setBrightness(BRIGHTNESS);
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✓ WiFi connected");
  
  // Connect to WebSocket
  webSocket.begin(ws_host, ws_port, "/");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
  
  Serial.println("🌌 BlackRoad Pixel Matrix Ready");
}

void loop() {
  webSocket.loop();
  
  // Ambient animation when idle
  fadeToBlackBy(leds, NUM_LEDS, 5);
  FastLED.show();
  delay(20);
}
```

## PlatformIO Config

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
lib_deps = 
    fastled/FastLED@^3.6.0
    links2004/WebSockets@^2.4.1
monitor_speed = 115200
```

## Quick Setup

1. Install PlatformIO: `pip install platformio`
2. Create project: `pio init --board esp32dev`
3. Copy code to `src/main.cpp`
4. Update WiFi credentials
5. Upload: `pio run --target upload`
6. Monitor: `pio device monitor`

## Visual Effects

- **Memory Write**: Violet flash across entire matrix
- **Agent Init**: Pink wave from left to right
- **Session Active**: Amber pulse from center
- **File Change**: Blue sparkle at random position

## Advanced Features

- Map agents to specific LED positions
- Create scrolling text for agent names
- Use color gradients for activity intensity
- Add sound-reactive mode with microphone

---

**Ready to visualize your AI agents on a 16x16 pixel matrix! 🔲**
