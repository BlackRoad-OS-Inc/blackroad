#!/bin/bash
# Watch GitHub integration progress

while true; do
  clear
  echo "🔄 GitHub Integration Progress"
  echo "=============================="
  echo ""
  
  # Count integrated repos
  INTEGRATED=$(grep -c "✅ Integrated" ~/github-integration-log.txt 2>/dev/null || echo "0")
  SKIPPED=$(grep -c "→ No changes to commit" ~/github-integration-log.txt 2>/dev/null || echo "0")
  
  echo "📊 Status:"
  echo "  ✅ Integrated: $INTEGRATED repos"
  echo "  ⏭️  Skipped: $SKIPPED repos"
  echo "  📦 Total: 100 repos"
  echo ""
  
  # Show last few lines
  echo "📝 Recent activity:"
  tail -10 ~/github-integration-log.txt | grep -E "(Integrating|Integrated|Skipped)" || echo "  Processing..."
  
  echo ""
  echo "Press Ctrl+C to stop watching"
  
  # Check if complete
  if grep -q "GITHUB INTEGRATION COMPLETE" ~/github-integration-log.txt 2>/dev/null; then
    echo ""
    echo "✅ COMPLETE!"
    tail -20 ~/github-integration-log.txt
    break
  fi
  
  sleep 5
done
