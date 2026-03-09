#!/bin/bash
# Flash USB-C Operator to ESP32 RIGHT NOW

DEVICE="/dev/cu.usbserial-110"

echo "🌌 BlackRoad USB-C Operator - Hardware Flash"
echo "=============================================="
echo ""
echo "Target: ESP32-D0WD-V3"
echo "Port: $DEVICE"
echo ""

# Create simple Arduino sketch that will work
cat > /tmp/operator.ino << 'EOF'
#define LED 2
String cmd = "";

void setup() {
  Serial.begin(115200);
  pinMode(LED, OUTPUT);

  // Blink 3 times on startup
  for(int i=0; i<3; i++) {
    digitalWrite(LED, HIGH);
    delay(100);
    digitalWrite(LED, LOW);
    delay(100);
  }

  Serial.println("\n=================================");
  Serial.println("BlackRoad USB-C Operator v1.0");
  Serial.println("ESP32 Hardware Interface");
  Serial.println("=================================\n");
  Serial.println("READY\n");

  digitalWrite(LED, HIGH);
}

void loop() {
  while(Serial.available()) {
    char c = Serial.read();

    if(c == '\n' || c == '\r') {
      if(cmd.length() > 0) {
        cmd.trim();
        cmd.toUpperCase();

        Serial.print(">> ");
        Serial.println(cmd);

        if(cmd == "YES") {
          Serial.println("✓ APPROVED");
          for(int i=0; i<2; i++) {
            digitalWrite(LED, LOW);
            delay(100);
            digitalWrite(LED, HIGH);
            delay(100);
          }
        }
        else if(cmd == "NO") {
          Serial.println("✗ REJECTED");
          for(int i=0; i<5; i++) {
            digitalWrite(LED, LOW);
            delay(50);
            digitalWrite(LED, HIGH);
            delay(50);
          }
        }
        else if(cmd == "PING") {
          Serial.println("PONG");
        }
        else if(cmd == "STATUS") {
          Serial.println("Status: OPERATIONAL");
          Serial.print("Uptime: ");
          Serial.print(millis()/1000);
          Serial.println(" sec");
        }
        else {
          Serial.print("Unknown: ");
          Serial.println(cmd);
        }

        Serial.println();
        cmd = "";
      }
    } else {
      cmd += c;
    }
  }
}
EOF

echo "📝 Created firmware sketch"
echo ""
echo "🔧 Compiling with arduino-cli..."

# Try to compile
if arduino-cli compile --fqbn esp32:esp32:esp32 /tmp/operator.ino 2>&1 | grep -q "error"; then
    echo "❌ Compilation failed - ESP32 core not installed"
    echo ""
    echo "📦 Installing ESP32 core (this may take a few minutes)..."
    arduino-cli core update-index
    arduino-cli core install esp32:esp32 --additional-urls https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json

    if [ $? -ne 0 ]; then
        echo ""
        echo "⚠️  Core installation issue. Trying alternative method..."
        echo ""
        echo "📡 You can flash manually:"
        echo "1. Open Arduino IDE"
        echo "2. Copy the code from /tmp/operator.ino"
        echo "3. Tools → Board → ESP32 Dev Module"
        echo "4. Tools → Port → $DEVICE"
        echo "5. Upload"
        exit 1
    fi

    echo "✅ ESP32 core installed!"
    echo "🔧 Compiling..."
    arduino-cli compile --fqbn esp32:esp32:esp32 /tmp/operator.ino
fi

echo ""
echo "📤 Uploading to ESP32..."
arduino-cli upload -p $DEVICE --fqbn esp32:esp32:esp32 /tmp/operator.ino

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ FIRMWARE FLASHED!"
    echo ""
    echo "🧪 Testing connection..."
    sleep 2

    python3 << PYEOF
import serial
import time

ser = serial.Serial('$DEVICE', 115200, timeout=2)
time.sleep(2)

# Read startup messages
if ser.in_waiting > 0:
    print(ser.read(ser.in_waiting).decode('utf-8', errors='ignore'))

# Send PING
ser.write(b'PING\n')
time.sleep(0.5)

if ser.in_waiting > 0:
    print(ser.read(ser.in_waiting).decode('utf-8', errors='ignore'))
    print('\n✅ HARDWARE IS ALIVE!')
    print('\n🎯 Try: python3 ~/usbc-hello-world.py')
    print('🌐 Or open: ~/usbc-operator-webserial.html')
else:
    print('⚠️  No response - device may need manual reset')

ser.close()
PYEOF

else
    echo "❌ Upload failed"
    echo ""
    echo "💡 Troubleshooting:"
    echo "1. Try holding BOOT button while uploading"
    echo "2. Unplug and replug USB"
    echo "3. Check device: ls /dev/cu.usb*"
fi
