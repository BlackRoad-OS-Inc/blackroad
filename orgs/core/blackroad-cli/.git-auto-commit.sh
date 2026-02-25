#!/bin/bash
MESSAGE="${1:-Auto-commit: $(date +%Y-%m-%d\ %H:%M:%S)}"
git add -A && git commit -m "$MESSAGE" && git push 2>/dev/null || echo "⚠ Check remote"
echo "✅ Done!"
