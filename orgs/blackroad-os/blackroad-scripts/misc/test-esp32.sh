#!/bin/bash
# Test ESP32 continuously

echo "Testing ESP32 at /dev/cu.usbserial-110..."
echo "Press Ctrl+C to stop"
echo ""

while true; do
    echo "=== $(date +%H:%M:%S) ==="

    python3 << 'PYEOF'
import serial
import time

try:
    ser = serial.Serial('/dev/cu.usbserial-110', 115200, timeout=1)

    # Reset
    ser.setDTR(False)
    time.sleep(0.1)
    ser.setDTR(True)
    time.sleep(2)

    # Read
    if ser.in_waiting > 0:
        data = ser.read(ser.in_waiting).decode('utf-8', errors='ignore')
        print(data)
    else:
        print("No data received")

    ser.close()
except Exception as e:
    print(f"Error: {e}")
PYEOF

    sleep 3
done
