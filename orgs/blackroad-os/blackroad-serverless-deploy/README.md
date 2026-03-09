# blackroad-serverless-deploy

A multi-cloud serverless deployment manager that tracks function registrations, generates deployment version hashes, records deployment history, and builds provider-specific CLI commands for AWS Lambda, Cloudflare Workers, and Vercel Functions — all from a single local SQLite registry.

The deployer abstracts away provider differences: register a function once with runtime, handler, memory, and timeout settings, then deploy to any supported provider. A dry-run mode prints the exact command that would execute without touching any cloud resources, making it safe to integrate into CI pipelines.

Part of the **BlackRoad OS** developer toolchain — combine with `br deploy` for a unified serverless workflow across all your cloud accounts.

## Features

- **Provider-agnostic registry** — AWS Lambda, Cloudflare Workers, Vercel Functions
- **Supported runtimes** — Python 3.10/3.11, Node.js 18/20, Go 1.21, Rust
- **Deployment versioning** — SHA-256 hash per deployment for traceability
- **Dry-run mode** — preview deploy commands without executing them
- **Deployment log** — full history with status, duration, version, and errors
- **Environment variable management** — per-function env var storage
- **JSON manifest export** — snapshot of all functions and recent deployments
- **SQLite persistence** — `~/.blackroad/serverless_deploy.db`
- **CLI interface** — `list`, `add`, `deploy [--dry-run]`, `logs`, `export`

## Installation

```bash
git clone https://github.com/BlackRoad-OS/blackroad-serverless-deploy.git
cd blackroad-serverless-deploy
python3 src/serverless_deploy.py
```

Run the test suite:

```bash
pip install pytest
pytest tests/ -v
```

## Usage

```bash
# Register a function: name runtime handler [memory_mb timeout_s region provider]
python3 src/serverless_deploy.py add "image-resizer" "python3.11" "main.handler"
python3 src/serverless_deploy.py add "edge-router" "nodejs20" "index.default" \
    128 10 global cloudflare-workers

# List all registered functions
python3 src/serverless_deploy.py list

# Dry-run a deployment (shows CLI command, no cloud calls)
python3 src/serverless_deploy.py deploy image-resizer --dry-run

# Deploy for real
python3 src/serverless_deploy.py deploy image-resizer

# View deployment history
python3 src/serverless_deploy.py logs
python3 src/serverless_deploy.py logs image-resizer   # filter by function

# Export manifest
python3 src/serverless_deploy.py export /tmp/manifest.json
```

### Example output

```
=== Serverless Functions (2) ===
  ● image-resizer | aws-lambda      | python3.11 | 128MB | Last: 2024-07-15 12:34:56
  ○ edge-router   | cloudflare-workers | nodejs20 | 128MB | Last: never
```

## API

### `Function`

| Field | Type | Description |
|---|---|---|
| `name` | `str` | Unique function name |
| `runtime` | `str` | Language runtime identifier |
| `handler` | `str` | Entry-point (e.g. `main.handler`) |
| `memory_mb` | `int` | Memory allocation in MB |
| `timeout_s` | `int` | Execution timeout in seconds |
| `provider` | `str` | Cloud provider identifier |
| `status` | `str` | `registered` or `deployed` |

### `ServerlessDeployer`

| Method | Description |
|---|---|
| `register_function(f)` | Add a function to the registry |
| `deploy_function(name, dry_run)` | Deploy (or preview) a function |
| `list_functions()` | All registered functions |
| `get_logs(name, limit)` | Deployment history |
| `export_manifest(path)` | Write JSON snapshot |

## License

MIT © BlackRoad OS, Inc.
