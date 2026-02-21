#!/bin/bash

# Git push instructions for Session 2
# Run this script to commit and push all changes

cd /Users/alexa/blackroad

echo "🚀 Committing Session 2 changes..."
echo ""

# Make sure we're staged
git add br tools/ BR_FEATURES.md PI_TASKS_GUIDE.md

# Commit with the message file
git commit -F COMMIT_MESSAGE.txt

# Show the commit
echo ""
echo "✓ Commit created! Here's what was committed:"
git log -1 --stat

echo ""
echo "Ready to push! Run:"
echo "  git push origin master"
echo ""
echo "Or push to a new branch:"
echo "  git checkout -b session-2-features"
echo "  git push origin session-2-features"
