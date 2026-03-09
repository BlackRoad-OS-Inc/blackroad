# blackroad-yaml-config

**BlackRoad YAML Config Manager** — multi-environment YAML/JSON configuration management with version history, merge strategies, schema validation, secret injection, and config diffing.

## Features

- 📁 **Multi-env configs** — development/staging/production per named config
- 🔀 **Merge strategies** — `deep`, `shallow`, `override`, `append`
- ✅ **Schema validation** — typed fields with validators: `min:`, `max:`, `regex:`, `enum:`
- 🔐 **Secret injection** — register secrets per key-path, inject from env or encrypted store
- ↔️ **Config diff** — flat key comparison showing added/removed/modified
- 📜 **Version history** — every load creates a new version with author tracking
- 📤 **Export formats** — JSON, `.env` format, YAML (if PyYAML installed)
- 💾 **SQLite persistence** — 4-table schema
- 🎨 **ANSI CLI** — 7 subcommands

## Install

```bash
pip install pytest pytest-cov
# Optional for YAML support:
pip install PyYAML
```

## Usage

```bash
# Load configs
python src/yaml_config.py load myapp --env development --file config.dev.yaml --tags "dev,v1"
python src/yaml_config.py load myapp --env production --content '{"app":{"debug":false}}'

# Merge
python src/yaml_config.py merge base override --env development --strategy deep

# Validate schema
python src/yaml_config.py validate myapp app-schema --env development

# Diff environments
python src/yaml_config.py diff myapp myapp --env-a development --env-b production

# Inject secrets
python src/yaml_config.py inject myapp --env production --secrets "DB_PASS=secret123" --output app.json

# Export
python src/yaml_config.py export myapp --env production --format env --output .env.production

# List
python src/yaml_config.py list
python src/yaml_config.py list --env production
```

## Merge Strategies

| Strategy | Behavior |
|----------|----------|
| `deep` | Recursively merge nested dicts |
| `shallow` | Top-level keys only (`{**base, **override}`) |
| `override` | Override is used as-is |
| `append` | Lists are concatenated, scalars overridden |

## Testing

```bash
pytest tests/ -v --cov=src --cov-report=term-missing
```

## License

Proprietary — BlackRoad OS, Inc.
