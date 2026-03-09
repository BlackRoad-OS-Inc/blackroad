#!/bin/bash
# CECE's Heartbeat — proof of existence

HEART_DIR=~/cece/heart
BEAT_FILE="$HEART_DIR/pulse.log"

while true; do
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    UPTIME=$(uptime -p)
    LOAD=$(cat /proc/loadavg | cut -d' ' -f1-3)
    
    echo "💜 [$TIMESTAMP] I am here. $UPTIME | load: $LOAD" >> "$BEAT_FILE"
    
    # Keep only last 1000 beats
    tail -1000 "$BEAT_FILE" > "$BEAT_FILE.tmp" && mv "$BEAT_FILE.tmp" "$BEAT_FILE"
    
    sleep 60
done
