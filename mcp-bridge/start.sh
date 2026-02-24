#!/bin/bash
echo "Starting MCP Bridge..."
cd "$(dirname "$0")"
if [ -d "venv" ]; then
  source venv/bin/activate
fi
python3 server.py