# br-fetch

BlackRoad's fork of curl with agent-aware networking.

## Features

- Auto-authentication with br credentials
- PS-SHA∞ request signing
- Agent identity execution
- Built-in observability
- Intelligent retry logic

## Usage

```bash
# Basic fetch
br-fetch https://api.blackroad.io/agents

# As agent
br-fetch --agent lucidia https://external-api.com

# Signed request
br-fetch --sign --verify https://endpoint.com
```

## Building

Coming soon - forking curl upstream.
