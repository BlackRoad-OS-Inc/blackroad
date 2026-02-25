# Blackroad CLI (Ollama)

A lightweight multi-agent CLI that streams multiple Ollama agents in parallel with live typing.

## Quick start

```bash
cd /Users/alexa/blackroad-cli/cli-ollama
npm install
npm run build
node dist/index.js run "Design a launch plan for Blackroad"
```

## Usage

```bash
blackroad run "Plan a 2-week sprint for the web team"
blackroad run --config /path/to/blackroad.config.json "Summarize this PR"
blackroad config init
```

If you run from this directory, `blackroad.config.json` is already present and used by default.

## Configuration

By default the CLI looks for `blackroad.config.json` in the current working directory.
You can override it with `--config` or `BLACKROAD_CONFIG`.

Key fields:
- `ollama.host`: Ollama server URL. Default: `http://localhost:11434`.
- `orchestrator.mode`: `parallel` (default) or `round`.
- `agents`: list of agents with `name`, `model`, and optional `system` prompt.

## Environment variables

- `OLLAMA_HOST`: overrides the default Ollama host.
- `BLACKROAD_CONFIG`: path to a config file.

## Notes

- This CLI uses Ollama's `/api/chat` streaming endpoint.
- Output is prefixed per agent, streamed live.
