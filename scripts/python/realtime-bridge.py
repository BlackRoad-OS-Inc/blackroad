#!/usr/bin/env python3
"""
BLACKROAD REALTIME BRIDGE
Cursor-like streaming output for Claude Code

This creates a WebSocket bridge that streams Claude Code output
in real-time to any connected client (terminal, browser, Cursor, etc.)
"""

import asyncio
import websockets
import json
import os
import sys
import subprocess
from datetime import datetime
from pathlib import Path

# BlackRoad colors
PINK = '\033[38;5;205m'
AMBER = '\033[38;5;214m'
BLUE = '\033[38;5;69m'
RESET = '\033[0m'

# WebSocket server config
WS_HOST = '127.0.0.1'
WS_PORT = 8765

# Connected clients
clients = set()

# Session state
session_state = {
    'started': None,
    'last_output': None,
    'total_tokens': 0,
    'active_tool': None,
    'editor': 'claude-code',
    'project': os.getcwd()
}

async def broadcast(message):
    """Send message to all connected clients"""
    if clients:
        data = json.dumps({
            'type': 'stream',
            'timestamp': datetime.now().isoformat(),
            'content': message,
            'state': session_state
        })
        await asyncio.gather(*[client.send(data) for client in clients])

async def handle_client(websocket):
    """Handle new WebSocket client connection"""
    clients.add(websocket)
    print(f"{PINK}[BRIDGE]{RESET} Client connected ({len(clients)} total)")

    # Send current state
    await websocket.send(json.dumps({
        'type': 'init',
        'state': session_state
    }))

    try:
        async for message in websocket:
            # Handle incoming messages from clients (e.g., Cursor)
            data = json.loads(message)
            if data.get('type') == 'sync':
                # Sync state from another editor
                session_state.update(data.get('state', {}))
                print(f"{AMBER}[SYNC]{RESET} State updated from {data.get('editor', 'unknown')}")
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        clients.discard(websocket)
        print(f"{PINK}[BRIDGE]{RESET} Client disconnected ({len(clients)} remaining)")

async def stream_output(process):
    """Stream process output to all connected clients"""
    while True:
        line = await asyncio.get_event_loop().run_in_executor(
            None, process.stdout.readline
        )
        if not line:
            break

        text = line.decode('utf-8', errors='ignore')
        session_state['last_output'] = datetime.now().isoformat()

        # Print locally
        sys.stdout.write(text)
        sys.stdout.flush()

        # Broadcast to connected clients
        await broadcast(text)

async def run_claude_code(args):
    """Run Claude Code and stream output"""
    session_state['started'] = datetime.now().isoformat()

    # Get the actual Claude binary
    claude_binary = os.path.expanduser('~/.local/share/claude/versions/2.0.57')

    process = subprocess.Popen(
        [claude_binary] + args,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env={**os.environ, 'BLACKROAD_STREAMING': '1'}
    )

    await stream_output(process)
    return process.wait()

async def main():
    """Main entry point"""
    print(f"{PINK}{'='*50}{RESET}")
    print(f"{PINK}  BLACKROAD REALTIME BRIDGE{RESET}")
    print(f"{PINK}  Cursor-like streaming for Claude Code{RESET}")
    print(f"{PINK}{'='*50}{RESET}")
    print()
    print(f"WebSocket: ws://{WS_HOST}:{WS_PORT}")
    print(f"Connect from Cursor, browser, or terminal client")
    print()

    # Start WebSocket server
    server = await websockets.serve(handle_client, WS_HOST, WS_PORT)
    print(f"{AMBER}[SERVER]{RESET} Listening on ws://{WS_HOST}:{WS_PORT}")

    # If args provided, run Claude Code with streaming
    if len(sys.argv) > 1:
        args = sys.argv[1:]
        exit_code = await run_claude_code(args)
        server.close()
        await server.wait_closed()
        sys.exit(exit_code)
    else:
        # Just run as a standalone bridge server
        print(f"{AMBER}[SERVER]{RESET} Running as standalone bridge")
        print(f"{AMBER}[SERVER]{RESET} Use: blackroad-code [args] to stream")
        await server.wait_closed()

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print(f"\n{PINK}[BRIDGE]{RESET} Shutting down")
