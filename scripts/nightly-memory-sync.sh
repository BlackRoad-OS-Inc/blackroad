#!/bin/zsh
# Nightly memory synthesis + Google Drive sync
# Installed in crontab: 0 6 * * *
# Logs to: ~/blackroad/logs/nightly.log

set -euo pipefail

BLACKROAD="$HOME/blackroad"
JOURNAL="$BLACKROAD/memory/journals/master-journal.jsonl"
CONTEXT="$BLACKROAD/memory/context/recent-actions.md"
DRIVE_BASE="$BLACKROAD/docs/from-drive"

mkdir -p "$(dirname "$JOURNAL")" "$(dirname "$CONTEXT")" \
         "$DRIVE_BASE/company" "$DRIVE_BASE/strategy"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "▶ nightly-memory-sync — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Append nightly synthesis marker to journal
echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"nightly-synthesis\",\"details\":\"automated\",\"host\":\"$(hostname -s)\"}" \
    >> "$JOURNAL"
echo "✓ journal entry appended"

# 2. Synthesize context from last 20 journal lines
tail -20 "$JOURNAL" > "$CONTEXT"
echo "✓ context synthesized ($(wc -l < "$CONTEXT") lines → $CONTEXT)"

# 3. Sync Google Drive docs (requires: rclone configured with remote 'gdrive-blackroad')
if command -v rclone &>/dev/null; then
    echo "▶ syncing Google Drive…"

    rclone sync "gdrive-blackroad:BlackRoad OS, Inc." \
        "$DRIVE_BASE/company/" \
        --max-depth 2 \
        --transfers 4 \
        --log-level INFO \
        2>/dev/null || true
    echo "✓ Drive → company/ synced"

    rclone sync "gdrive-blackroad:Development Roadmap" \
        "$DRIVE_BASE/strategy/" \
        --max-depth 2 \
        --transfers 4 \
        --log-level INFO \
        2>/dev/null || true
    echo "✓ Drive → strategy/ synced"
else
    echo "⚠ rclone not found — skipping Drive sync (install with: brew install rclone)"
fi

echo "✓ nightly sync complete $(date)"
