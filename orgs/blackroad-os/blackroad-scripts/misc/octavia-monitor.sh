#!/bin/bash
# Octavia Live Performance Monitor

HOST="pi@192.168.4.74"

while true; do
    clear
    echo "🖤🛣️ Octavia (Pi 5) Live Monitor"
    echo "================================="
    date
    echo ""

    # System info
    echo "📊 System Status:"
    ssh $HOST "uptime | sed 's/^/  /'"

    # CPU
    echo ""
    echo "⚡ CPU:"
    FREQ=$(ssh $HOST "vcgencmd measure_clock arm" | cut -d= -f2)
    FREQ_MHZ=$((FREQ / 1000000))
    echo "  Frequency: $FREQ_MHZ MHz"

    # Temperature
    TEMP=$(ssh $HOST "vcgencmd measure_temp" | cut -d= -f2)
    echo "  Temperature: $TEMP"

    # Voltage
    VOLT=$(ssh $HOST "vcgencmd measure_volts" | cut -d= -f2)
    echo "  Voltage: $VOLT"

    # Memory
    echo ""
    echo "💾 Memory:"
    ssh $HOST "free -h | grep Mem | awk '{print \"  Total: \"\$2\"  Used: \"\$3\"  Free: \"\$4\"  Available: \"\$7}'"

    # Throttling check
    echo ""
    echo "🌡️  Throttle Status:"
    THROTTLE=$(ssh $HOST "vcgencmd get_throttled")
    if [[ "$THROTTLE" == *"0x0"* ]]; then
        echo "  ✅ No throttling"
    else
        echo "  ⚠️  $THROTTLE"
    fi

    # Top processes
    echo ""
    echo "🔝 Top Processes:"
    ssh $HOST "ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf \"  %s  %s%%  %s\\n\", \$11, \$3, \$4}'"

    # Pironman status
    echo ""
    echo "🎮 Pironman:"
    PIRONMAN_STATUS=$(ssh $HOST "systemctl is-active pironman5")
    if [[ "$PIRONMAN_STATUS" == "active" ]]; then
        echo "  ✅ Service running"
        echo "  🌐 Dashboard: http://192.168.4.74:34001"
    else
        echo "  ❌ Service not running"
    fi

    echo ""
    echo "Press Ctrl+C to exit | Refresh: 3s"
    sleep 3
done
