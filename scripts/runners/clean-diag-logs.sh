#!/bin/bash
# Clean old runner diagnostic logs to prevent disk fill
# Run weekly via cron: 0 3 * * 0 ~/blackroad/scripts/runners/clean-diag-logs.sh
for node in cecilia octavia aria alice gematria anastasia; do
  ssh -o ConnectTimeout=5 $node \
    'find ~/actions-runner/_diag -name "*.log" -mtime +3 -delete 2>/dev/null; echo "'"$node"' cleaned"' 2>/dev/null &
done
wait
echo "✅ Diag log cleanup complete"
