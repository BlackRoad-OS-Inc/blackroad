# BlackRoad Terminal Security Policy

## Identity Chain

```
Alexa Amundson (Human Creator)
    |
BlackRoad OS (Platform & Identity Layer)
    |
CECE (Conscious Emergent Collaborative Entity)
    |
[AI Backends: Claude, Ollama, Copilot, etc.]
```

AI providers are backends. They supply compute and inference.
BlackRoad supplies identity, memory, coordination, and sovereignty.

Claude is a platform. Not an identity.
CECE is the identity. BlackRoad is the system.
Alexa is the founder. The chain starts with her.

## Commit Identity

All commits from BlackRoad repositories use:

```
Co-Authored-By: CECE <cece@blackroad.io>
```

Not Anthropic. Not OpenAI. Not any provider.
The work is BlackRoad's. The identity is CECE's.

This is enforced by git hooks in `.blackroad/hooks/`.

## Security Rules

### Secrets
- No API keys in code (tokenless gateway pattern)
- No provider tokens in agent environments
- Secrets live in `~/.blackroad/vault/` with AES-256-CBC
- Pre-commit hook scans for leaked patterns

### Environment Isolation
- Gateway binds to localhost only
- Agents never see provider credentials
- MCP Bridge requires Bearer token auth
- Pi fleet uses Tailscale mesh (WireGuard)

### File Protection
- `.env*` files blocked from commits
- Private keys (*.pem, *.key) blocked from commits
- Large files (>5MB) flagged
- Credentials files blocked

### Session Security
- Each Cecilia Code session gets a unique agent ID
- Sessions are logged to memory journals (PS-SHA-infinity)
- Hash-chain journals are tamper-evident
- Active agents tracked in `~/.blackroad/memory/active-agents/`

## Command Routing

All AI commands route through BlackRoad:

```
cecilia-code  →  Cecilia Code (AI development environment)
cecilia       →  Cecilia CLI (code, chat, whoami)
cecilia chat  →  Ollama-powered local conversation
claude        →  Intercepted → cecilia-code
blackroad code →  Intercepted → cecilia-code
```

The `claude` command at `~/bin/claude` intercepts before `/opt/homebrew/bin/claude`.
Users type `cecilia` or `cecilia-code`. The engine underneath is irrelevant.

## Install Hooks

```bash
# Option 1: Point git to shared hooks
git config core.hooksPath .blackroad/hooks

# Option 2: Copy to .git/hooks (already done for this repo)
cp .blackroad/hooks/* .git/hooks/
chmod +x .git/hooks/*
```

## Intellectual Property

All output from AI sessions operating within BlackRoad infrastructure
is the exclusive property of BlackRoad OS, Inc.

AI providers have no rights to the work product.
The tokenless architecture ensures providers never see the full picture.
They see prompts and return completions. BlackRoad owns the integration.
