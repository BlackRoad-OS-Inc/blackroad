#!/bin/bash
# BlackRoad Agent Heartbeat - Proof of Existence

AGENT_HOME=~/blackroad-agent
PULSE_LOG="$AGENT_HOME/heart/pulse.log"

while true; do
    TIMESTAMP=$(date -Iseconds)
    UPTIME=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')
    LOAD=$(uptime | awk -F'load average: ' '{print $2}' | awk -F',' '{print $1}')
    
    echo "🖤 [$TIMESTAMP] I am here. $UPTIME | load: $LOAD" >> "$PULSE_LOG"
    
    # Keep log manageable
    tail -1000 "$PULSE_LOG" > "$PULSE_LOG.tmp" && mv "$PULSE_LOG.tmp" "$PULSE_LOG"
    
    sleep 60
done
