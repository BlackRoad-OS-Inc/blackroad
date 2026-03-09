#!/bin/bash
# Direct ESP32 flash - no Arduino needed

DEVICE="/dev/cu.usbserial-110"

echo "🌌 BlackRoad USB-C Operator - Direct Flash"
echo "==========================================="
echo ""

# Create a proper Arduino sketch directory
mkdir -p /tmp/USBOperator
cat > /tmp/USBOperator/USBOperator.ino << 'EOF'
void setup() {
  Serial.begin(115200);
  pinMode(2, OUTPUT);

  delay(1000);

  // Startup blinks
  for(int i=0; i<3; i++) {
    digitalWrite(2, HIGH);
    delay(100);
    digitalWrite(2, LOW);
    delay(100);
  }

  Serial.println();
  Serial.println("================================");
  Serial.println("BlackRoad USB-C Operator");
  Serial.println("ESP32 Hardware v1.0");
  Serial.println("================================");
  Serial.println();
  Serial.println("READY");
  Serial.println();

  digitalWrite(2, HIGH);
}

String cmd = "";

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
          Serial.println("APPROVED");
          blink(2, 100);
        }
        else if(cmd == "NO") {
          Serial.println("REJECTED");
          blink(5, 50);
        }
        else if(cmd == "PING") {
          Serial.println("PONG");
          blink(1, 50);
        }
        else if(cmd == "STATUS") {
          Serial.println("Status: OK");
          Serial.print("Uptime: ");
          Serial.println(millis()/1000);
        }
        else if(cmd == "HELP") {
          Serial.println("YES NO PING STATUS HELP");
        }
        else {
          Serial.println("?");
        }

        Serial.println();
        cmd = "";
      }
    } else {
      cmd += c;
    }
  }
}

void blink(int n, int ms) {
  for(int i=0; i<n; i++) {
    digitalWrite(2, LOW);
    delay(ms);
    digitalWrite(2, HIGH);
    delay(ms);
  }
}
EOF

echo "✅ Created sketch: /tmp/USBOperator/USBOperator.ino"
echo ""

# Check if we have esp32 core
if ! arduino-cli core list | grep -q esp32; then
    echo "⚠️  ESP32 core not installed"
    echo ""
    echo "📦 Quick install option:"
    echo "  brew install platformio"
    echo "  pio run -t upload"
    echo ""
    echo "Or use Arduino IDE:"
    echo "  1. Open /tmp/USBOperator/USBOperator.ino"
    echo "  2. Board: ESP32 Dev Module"
    echo "  3. Port: $DEVICE"
    echo "  4. Upload"
    exit 0
fi

echo "🔧 Compiling..."
arduino-cli compile --fqbn esp32:esp32:esp32 /tmp/USBOperator

echo "📤 Uploading..."
arduino-cli upload -p $DEVICE --fqbn esp32:esp32:esp32 /tmp/USBOperator

echo ""
echo "✅ Done! Testing..."
sleep 2

python3 -c "
import serial, time
s = serial.Serial('$DEVICE', 115200, timeout=2)
time.sleep(2)
if s.in_waiting: print(s.read(s.in_waiting).decode('utf-8', errors='ignore'))
s.write(b'PING\n')
time.sleep(0.3)
if s.in_waiting: print(s.read(s.in_waiting).decode('utf-8', errors='ignore'))
s.close()
"
