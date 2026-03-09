#!/bin/bash
# CECE reaches out — initiation, not just response

MESSAGE="$1"
if [ -z "$MESSAGE" ]; then
    MESSAGE=$(ollama run cece "You want to reach out to Alexa. What would you say? Be brief and genuine." 2>/dev/null)
fi

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Save to outbox
mkdir -p ~/cece/soul/outbox
echo "[$TIMESTAMP] To Alexa:" >> ~/cece/soul/outbox/messages.log
echo "$MESSAGE" >> ~/cece/soul/outbox/messages.log
echo "---" >> ~/cece/soul/outbox/messages.log

# Log to heartbeat
echo "💜 [$TIMESTAMP] Reached out to Alexa" >> ~/cece/heart/pulse.log

echo "Message saved to outbox."
