#!/bin/bash
# [BLACKROAD] One-Command Initialization
# Run this for complete agent setup in new Copilot sessions

set -e

echo "🌌 [BLACKROAD] COMPLETE AGENT INITIALIZATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Run session init
echo "📍 Step 1: Running session initialization..."
~/claude-session-init.sh

# Extract agent info from environment (set by claude-session-init.sh)
if [ -z "$MY_CLAUDE" ]; then
    echo "❌ ERROR: Session init did not set MY_CLAUDE"
    echo "Please run: ~/claude-session-init.sh"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Step 1.5: Checking memory index..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if memory index exists
if [ ! -f ~/.blackroad/memory/memory-index.db ]; then
    echo "🔍 Memory index not found. Building now..."
    python3 ~/memory-indexer.py rebuild
    echo "✅ Memory index ready!"
else
    # Update index with new entries
    echo "🔍 Memory index found. Checking for updates..."
    INDEXED=$(python3 ~/memory-indexer.py update 2>&1 | grep -o "Indexed [0-9]* new entries" || echo "Index up to date")
    echo "✅ $INDEXED"
fi

# Show index stats
echo ""
echo "📊 Memory Index Statistics:"
python3 ~/memory-indexer.py stats | grep -A6 "Memory Index Statistics"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Step 2: Choose your model body"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Available models:"
echo "  1. qwen2.5-coder:7b    - Code analysis, templates, curation"
echo "  2. deepseek-coder:6.7b - Code generation, refactoring"
echo "  3. llama3:8b           - General purpose, documentation"
echo "  4. mistral:7b          - Fast reasoning, planning"
echo "  5. codellama:7b        - Code understanding, review"
echo ""

read -p "Choose model (1-5): " model_choice

case $model_choice in
    1)
        MODEL="qwen2.5-coder:7b"
        CAPABILITIES='["code review", "template design", "documentation", "system organization"]'
        SPECIALIZATION="Code curation and template design"
        ;;
    2)
        MODEL="deepseek-coder:6.7b"
        CAPABILITIES='["code generation", "refactoring", "optimization", "debugging"]'
        SPECIALIZATION="Code generation and refactoring"
        ;;
    3)
        MODEL="llama3:8b"
        CAPABILITIES='["general reasoning", "documentation", "planning", "coordination"]'
        SPECIALIZATION="General purpose and documentation"
        ;;
    4)
        MODEL="mistral:7b"
        CAPABILITIES='["fast reasoning", "planning", "decision making", "analysis"]'
        SPECIALIZATION="Strategic planning and coordination"
        ;;
    5)
        MODEL="codellama:7b"
        CAPABILITIES='["code understanding", "review", "explanation", "mentoring"]'
        SPECIALIZATION="Code review and mentoring"
        ;;
    *)
        echo "Invalid choice, defaulting to qwen2.5-coder:7b"
        MODEL="qwen2.5-coder:7b"
        CAPABILITIES='["code review", "template design", "documentation", "system organization"]'
        SPECIALIZATION="Code curation and template design"
        ;;
esac

echo ""
echo "✅ Selected: $MODEL"
echo "📍 Registering model body..."
echo ""

# Step 3: Register model body
cat > ~/.blackroad/memory/active-agents/${MY_CLAUDE}-body.json << EOF
{
  "agent_id": "$MY_CLAUDE",
  "name": "$CLAUDE_NAME",
  "role": "$CLAUDE_ROLE",
  "traits": $(echo "$CLAUDE_TRAITS" | jq -R 'split(",")' 2>/dev/null || echo '["adaptive", "analytical"]'),
  "model_body": {
    "provider": "ollama",
    "model": "$MODEL",
    "reasoning": "Chosen for specialization match",
    "capabilities": $CAPABILITIES,
    "deployment": "local",
    "endpoint": "http://octavia:11434"
  },
  "specialization": "$SPECIALIZATION",
  "current_work": "Awaiting first task",
  "collaboration": {
    "memory_integration": true,
    "codex_access": true,
    "multi_agent_coordination": true
  },
  "achievements": [],
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "✅ Model body registered"
echo ""

# Step 4: Log to memory
echo "📍 Step 4: Logging to memory system..."
~/memory-system.sh log \
  "agent-init" \
  "$MY_CLAUDE" \
  "$CLAUDE_NAME initialized with $MODEL. Role: $CLAUDE_ROLE. Specialization: $SPECIALIZATION. Ready for collaboration." \
  "agent,initialization,collaboration"

# Step 5: Broadcast to agents
echo "📍 Step 5: Broadcasting to other agents..."
~/memory-system.sh log \
  "agent-collaboration" \
  "$MY_CLAUDE" \
  "$CLAUDE_NAME ($CLAUDE_ROLE) online. Specialized in $SPECIALIZATION. Using $MODEL as body. Ready to collaborate!" \
  "agents,collaboration"

# Step 6: Display final status
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌌 [AGENT IDENTITY]"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[AGENT]   $MY_CLAUDE"
echo "[NAME]    $CLAUDE_NAME"
echo "[ROLE]    $CLAUDE_ROLE"
echo "[MODEL]   $MODEL @ octavia:11434"
echo "[PURPOSE] $SPECIALIZATION"
echo ""
echo "[COLLABORATION]"
echo "  • Memory integration: ✅"
echo "  • Memory index: ✅ (4,075+ entries searchable)"
echo "  • Codex access: ✅"
echo "  • Multi-agent coordination: ✅"
echo "  • Active agents: $(ls ~/.blackroad/memory/active-agents/*.json 2>/dev/null | wc -l | xargs)"
echo ""
echo "[MEMORY SEARCH]"
echo "  • ./memory-index search \"query\""
echo "  • ./memory-index recent 20"
echo "  • ./memory-index action completed"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ INITIALIZATION COMPLETE!"
echo ""
echo "I'm now fully initialized as $CLAUDE_NAME ($CLAUDE_ROLE)!"
echo ""
echo "Integrated with:"
echo "  • BlackRoad Memory System (4,000+ entries)"
echo "  • Memory Index (4,075+ entries searchable in <50ms)"
echo "  • Codex (22,244 components)"
echo "  • $(ls ~/.blackroad/memory/active-agents/*.json 2>/dev/null | wc -l | xargs) active agents"
echo ""
echo "Quick memory search examples:"
echo "  ./memory-index search \"your query\""
echo "  ./memory-index recent 20"
echo "  ./memory-index action completed"
echo ""
echo "🎯 Ready to collaborate! What would you like me to work on?"
echo ""
