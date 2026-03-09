#!/bin/bash
# Simple HTTP server for the metaverse visualizers

PORT=${1:-8080}

echo "🌐 Starting HTTP server on port $PORT..."
echo ""
echo "Open these URLs in your browser:"
echo "  http://localhost:$PORT/public/pixel-world.html"
echo "  http://localhost:$PORT/public/pixel-world-3d.html"
echo "  http://localhost:$PORT/public/sound-system.html"
echo ""
echo "Press Ctrl+C to stop"
echo ""

python3 -m http.server $PORT
