#!/bin/zsh
# BR NATS - Agent Pub/Sub Coordination
NATS_HTTP="http://192.168.4.38:8222"
case "$1" in
  status)
    curl -s "$NATS_HTTP/varz" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(f'NATS: {d.get(\"server_name\",\"?\")} v{d.get(\"version\",\"?\")}')
print(f'Connections: {d.get(\"connections\",0)}, Msgs: {d.get(\"total_messages_in\",0)}')" 2>/dev/null
    ;;
  *) echo "Usage: br agent-nats <status>" ;;
esac
