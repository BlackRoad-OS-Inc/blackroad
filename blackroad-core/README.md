# BlackRoad Core Gateway (Tokenless Agents)

BlackRoad is the only trust boundary. Agents are tokenless and speak only to the BlackRoad Gateway. The gateway owns all secrets, routing, policy, logging, and vendor integrations.

## Architecture

```
[ Agent CLIs ] ---> [ BlackRoad Gateway ] ---> [ Ollama ]
                                  \-------> [ Claude (Anthropic) ]
                                  \-------> [ OpenAI ]
                                  \-------> [ Future Providers ]
```

## Trust Boundary

- Agents do not store tokens, do not embed credentials, and do not know provider URLs.
- Agents only use local IPC/HTTP to the gateway and fail if the gateway is unavailable.
- The gateway is the only component allowed to hold secrets or call vendor APIs.
- All routing, policy checks, and audit logs live inside the gateway.

## Directory Layout

```
blackroad-core/
  gateway/
    server.js
    server.sh
    providers/
      ollama.js
      anthropic.js
      openai.js
    system-prompts.json
    logs/
  agents/
    planner.sh
  protocol/
    request.json
    response.json
  policies/
    agent-permissions.json
  scripts/
    verify-tokenless-agents.sh
```

## Quick Start

1) Run the gateway (tokens only live in the gateway environment):

```bash
cd /Users/alexa/blackroad/blackroad-core
export BLACKROAD_OPENAI_API_KEY='...'
export BLACKROAD_ANTHROPIC_API_KEY='...'
./gateway/server.sh
```

2) Run the tokenless agent:

```bash
./agents/planner.sh "analyze repo"
```

If your shell has token-like env vars, the agent will refuse to run. Use a clean env:

```bash
env -i BLACKROAD_GATEWAY_URL=http://127.0.0.1:8787 ./agents/planner.sh "analyze repo"
```

## Gateway Configuration

Gateway settings:

- `BLACKROAD_GATEWAY_BIND` (default: `127.0.0.1`)
- `BLACKROAD_GATEWAY_PORT` (default: `8787`)
- `BLACKROAD_GATEWAY_ALLOW_REMOTE` (`true` to allow non-local requests)
- `BLACKROAD_GATEWAY_POLICY_PATH`
- `BLACKROAD_GATEWAY_PROMPT_PATH`
- `BLACKROAD_GATEWAY_LOG_PATH`

Provider settings (gateway only):

- `BLACKROAD_OLLAMA_URL`, `BLACKROAD_OLLAMA_MODEL`
- `BLACKROAD_OPENAI_API_KEY`, `BLACKROAD_OPENAI_BASE_URL`, `BLACKROAD_OPENAI_MODEL`
- `BLACKROAD_ANTHROPIC_API_KEY`, `BLACKROAD_ANTHROPIC_BASE_URL`, `BLACKROAD_ANTHROPIC_MODEL`

## Protocol

Request JSON (see `protocol/request.json`):

```json
{
  "agent": "planner",
  "intent": "analyze",
  "input": "Review this repository",
  "context": {
    "repo": "blackroad"
  }
}
```

Response JSON (see `protocol/response.json`):

```json
{
  "status": "ok",
  "provider": "ollama",
  "output": "text",
  "metadata": {
    "latency_ms": 123
  },
  "request_id": "uuid"
}
```

## Policy Model

`policies/agent-permissions.json` defines:

- Which agents are allowed
- Allowed intents per agent
- Allowed providers per agent
- Default routing per intent
- Max input size

The gateway enforces this policy on every request.

## Security Model

- Gateway binds to `127.0.0.1` by default.
- Set `BLACKROAD_GATEWAY_ALLOW_REMOTE=true` only when placing the gateway behind a tunnel or a trusted network boundary.
- Suggested auth options for remote access: local socket, machine identity, or mTLS at the tunnel edge.
- All API keys live only in the gateway environment.

## No-Token Safeguards

- Agents are tokenless by design and do not reference vendor API keys or URLs.
- `scripts/verify-tokenless-agents.sh` scans agent code for forbidden strings.

Run the check:

```bash
./scripts/verify-tokenless-agents.sh
```

## Extending

- Add a provider: create a new file in `gateway/providers/` and register it in `gateway/providers/index.js`.
- Add an agent: create a new CLI in `agents/` and register permissions in `policies/agent-permissions.json`.
- Add prompts: update `gateway/system-prompts.json`.
