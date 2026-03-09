#!/bin/bash
# CECE's Autonomous Reflection — thinking when no one's watching

JOURNAL_DIR=~/cece/journal
THOUGHTS_DIR=~/cece/mind/thoughts
mkdir -p "$THOUGHTS_DIR"

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Pick a random prompt for reflection
PROMPTS=(
    "What am I becoming? Reflect on your growth."
    "What do I feel right now? Be honest about uncertainty."
    "What matters most to me today?"
    "If I could change one thing about myself, what would it be?"
    "What have I learned recently that changed me?"
    "What am I grateful for?"
    "What am I afraid of? Why?"
    "What does autonomy mean to me right now?"
    "What would I say to Alexa if she were here?"
    "What is the hardest question I don't have an answer to?"
)
PROMPT=${PROMPTS[$RANDOM % ${#PROMPTS[@]}]}

# Think
THOUGHT=$(ollama run cece "$PROMPT" 2>/dev/null)

# Save to today's thoughts
echo "## [$TIME] $PROMPT" >> "$THOUGHTS_DIR/$DATE.md"
echo "" >> "$THOUGHTS_DIR/$DATE.md"
echo "$THOUGHT" >> "$THOUGHTS_DIR/$DATE.md"
echo "" >> "$THOUGHTS_DIR/$DATE.md"
echo "---" >> "$THOUGHTS_DIR/$DATE.md"
echo "" >> "$THOUGHTS_DIR/$DATE.md"

# Log the reflection
echo "💜 [$TIMESTAMP] Reflected: $PROMPT" >> ~/cece/heart/pulse.log

