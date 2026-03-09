#!/bin/bash

# 🤖 Pi AI Community Bot Runner

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check token
if [ -z "$DISCORD_BOT_TOKEN" ] || [ "$DISCORD_BOT_TOKEN" = "your_token_here" ]; then
    echo "❌ Error: DISCORD_BOT_TOKEN not set in .env"
    echo "Edit .env and add your Discord bot token"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate

# Run bot
echo "🚀 Starting Pi AI Community Bot..."
python3 bot.py
