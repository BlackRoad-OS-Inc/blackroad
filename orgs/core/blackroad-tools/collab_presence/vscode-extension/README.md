# BlackRoad Presence Bus (VS Code)

This lightweight extension emits editor activity to the collaboration bus so
VS Code sessions show up next to mobile Working Copy commits and autonomous
agents. Key features:

- joins the Socket.IO presence bus on startup
- broadcasts file + branch focus on editor changes
- falls back to REST API heartbeat if WebSockets are blocked

## Getting Started

1. `npm install` inside this directory to install dependencies.
2. Run the VS Code extension host with `F5`.
3. Configure `blackroadPresence.agent` and `blackroadPresence.busUrl` in settings.

The extension will send telemetry every time focus changes or every 45 seconds
while idle.
