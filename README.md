# @blackroad/operator

The `br` CLI for BlackRoad OS. Talks to the gateway, manages agents, and deploys services.

## Install

```bash
npm install
npm run build
npm link    # Makes `br` available globally
```

## Commands

| Command | Description |
|---------|-------------|
| `br status` | Show system status |
| `br agents` | List all agents |
| `br invoke <agent> <task>` | Invoke an agent |
| `br gateway health` | Check gateway health |
| `br deploy [service]` | Trigger deployment |
| `br logs` | Tail gateway logs |
| `br config [key] [value]` | View/set config |
| `br init [name]` | Initialize a project |

## Development

```bash
npm run dev         # Watch mode (tsx)
npm run typecheck   # Type-check
npm test            # Run tests
npm run format      # Prettier
```

## Structure

```
src/
  bin/            # Entry point (br.ts)
  cli/commands/   # Commander subcommands
  core/           # HTTP client, config, logger, spinner
  bootstrap/      # Pre-flight checks, setup wizard, templates
  formatters/     # Table, JSON, brand colors
test/             # Vitest test suites
```

## License

Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
