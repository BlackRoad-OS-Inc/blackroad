#!/bin/bash
# Flash USB-C Operator firmware to device

set -e

DEVICE="/dev/cu.usbserial-110"
SKETCH="/Users/alexa/usbc-operator.ino"

echo "🌌 BlackRoad USB-C Operator Flasher"
echo "===================================="
echo ""

# Common board types with CH340
echo "Select your board type:"
echo "1) Arduino Nano (ATmega328P)"
echo "2) Arduino Uno"
echo "3) ESP8266 (NodeMCU/Wemos)"
echo "4) ESP32"
echo ""
read -p "Choice [1-4]: " CHOICE

case $CHOICE in
    1)
        FQBN="arduino:avr:nano:cpu=atmega328old"
        echo "✓ Arduino Nano selected"
        ;;
    2)
        FQBN="arduino:avr:uno"
        echo "✓ Arduino Uno selected"
        ;;
    3)
        FQBN="esp8266:esp8266:nodemcuv2"
        echo "✓ ESP8266 selected"
        ;;
    4)
        FQBN="esp32:esp32:esp32"
        echo "✓ ESP32 selected"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📦 Installing board support..."
arduino-cli core update-index

if [[ $FQBN == esp8266* ]]; then
    arduino-cli core install esp8266:esp8266 || true
elif [[ $FQBN == esp32* ]]; then
    arduino-cli core install esp32:esp32 || true
else
    arduino-cli core install arduino:avr || true
fi

echo ""
echo "🔧 Compiling firmware..."
arduino-cli compile --fqbn $FQBN $SKETCH

echo ""
echo "📤 Uploading to $DEVICE..."
arduino-cli upload -p $DEVICE --fqbn $FQBN $SKETCH

echo ""
echo "✅ Upload complete!"
echo ""
echo "🧪 Testing connection..."
sleep 2

python3 -c "
import serial
import time

ser = serial.Serial('$DEVICE', 115200, timeout=2)
time.sleep(2)  # Wait for Arduino reset

# Read startup message
if ser.in_waiting > 0:
    print(ser.read(ser.in_waiting).decode('utf-8', errors='ignore'))

# Send PING
ser.write(b'PING\n')
time.sleep(0.5)

if ser.in_waiting > 0:
    print(ser.read(ser.in_waiting).decode('utf-8', errors='ignore'))
    print('✅ Operator is LIVE!')
else:
    print('⚠️  No response - try opening serial monitor')

ser.close()
"

echo ""
echo "🎯 To test manually:"
echo "   python3 ~/usbc-hello-world.py"
echo "   screen $DEVICE 115200"
