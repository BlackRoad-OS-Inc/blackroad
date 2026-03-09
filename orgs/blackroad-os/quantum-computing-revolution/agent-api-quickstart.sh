#!/bin/bash
# BlackRoad Agent API - Quick Start Script

echo "🔱 BLACKROAD AGENT API - QUICK START 🔱"
echo ""

# Check dependencies
echo "📋 Checking dependencies..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install Python 3.8+"
    exit 1
fi

# Install required packages
echo "📦 Installing Python dependencies..."
pip3 install fastapi uvicorn pydantic --quiet 2>/dev/null || echo "⚠️  Some packages may need installation"

# Check cluster connectivity
echo ""
echo "🌐 Checking cluster connectivity..."
for node in lucidia aria; do
    if ssh -o ConnectTimeout=3 $node "echo ''" &>/dev/null; then
        echo "  ✅ $node - reachable"
    else
        echo "  ⚠️  $node - not reachable (some agents won't work)"
    fi
done

echo ""
echo "🚀 Starting BlackRoad Agent API..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "API Endpoints:"
echo "  📍 http://localhost:8000"
echo "  📚 http://localhost:8000/docs (Interactive API docs)"
echo ""
echo "Available Endpoints:"
echo "  GET  /              - API status"
echo "  GET  /agents        - List all agents"
echo "  GET  /agents/<name> - Get agent details"
echo "  POST /query         - Query an agent"
echo "  POST /collaborate   - Collaborative reasoning"
echo "  POST /task          - Distributed task"
echo "  POST /swarm         - Quantum swarm intelligence"
echo "  GET  /roles         - List agent roles"
echo "  GET  /qcs/<pos>     - Agents by QCS position"
echo "  GET  /history       - Conversation history"
echo "  GET  /health        - Health check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the API
cd ~/quantum-computing-revolution
python3 blackroad-agent-api.py
