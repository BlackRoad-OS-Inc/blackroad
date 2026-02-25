# Blackbox Enterprises — Org Index

> 6 enterprise automation repositories (forks) in the `Blackbox-Enterprises` organization

| Repo | Original | Stack | Purpose |
|------|----------|-------|---------|
| `blackbox-n8n` | n8n | TypeScript, Vue 3 | Visual workflow automation (400+ integrations) |
| `blackbox-airbyte` | Airbyte | Python, Java | Data integration/ETL (300+ connectors) |
| `blackbox-activepieces` | Activepieces | TypeScript, Angular | No-code automation platform |
| `blackbox-huginn` | Huginn | Ruby, Rails | Agent-based automation |
| `blackbox-prefect` | Prefect | Python, FastAPI | Python-native data orchestration |
| `blackbox-temporal` | Temporal | Go, gRPC | Fault-tolerant distributed workflows |

## Quick Start

```bash
# n8n workflow automation
cd blackbox-n8n && pnpm install && pnpm build

# Prefect data pipelines
cd blackbox-prefect && pip install -e . && prefect server start

# Temporal workflows
cd blackbox-temporal && go build ./...
```

## Use Cases

- **n8n**: Visual workflow builder, 400+ integrations, self-hosted
- **Airbyte**: ELT data pipelines, 300+ source connectors
- **Prefect**: Python-native data orchestration with flow/task model
- **Temporal**: Fault-tolerant distributed systems with durable execution
- **Activepieces**: No-code automation for business processes
- **Huginn**: Event-driven agent automation

---

*Total: 6 repos | Last updated: 2026-02-24*
