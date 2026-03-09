# 🤖 Claude Access Guide

> Instructions for AI assistants working with BlackRoad infrastructure

## Quick Start

### 1. Get GitHub Token
```sql
-- Query blackroad-continuity D1 database (f0721506-cb52-41ee-b587-38f7b42b97d9)
SELECT value FROM secrets WHERE key = 'GITHUB_TOKEN'
```

### 2. Verify Access
```bash
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user
```

## Available MCP Connections

Claude has direct access to these services via MCP tools:

| Service | Tool Prefix | Capabilities |
|---------|-------------|--------------|
| Cloudflare | `Cloudflare Developer Platform:` | Workers, D1, KV, R2 |
| Stripe | `Stripe:` | Customers, Products, Payments |
| Hugging Face | `Hugging Face:` | Models, Datasets, Inference |
| Notion | `Notion:` | Pages, Databases, Search |
| Linear | `Linear:` | Issues, Projects |
| Zapier | `Zapier:` | Gmail, Slack, Drive, Notion |
| Vercel | `Vercel:` | Deployments, Projects |
| Google Drive | `google_drive_*` | Docs, Search |
| Gmail | `*_gmail_*` | Read, Search, Send |
| GCal | `*_gcal_*` | Events, Calendars |

## Key IDs

### Cloudflare
- **Account ID**: `848cf0b18d51e0170e0d1537aec3505a`
- **Continuity DB**: `f0721506-cb52-41ee-b587-38f7b42b97d9`

### Stripe
- **Account**: `acct_1SUDM8ChUUSEbzyh`

### GitHub Organizations
1. Blackbox-Enterprises
2. BlackRoad-AI
3. BlackRoad-OS
4. BlackRoad-Labs
5. BlackRoad-Cloud
6. BlackRoad-Ventures
7. BlackRoad-Foundation
8. BlackRoad-Media
9. BlackRoad-Hardware
10. BlackRoad-Education
11. BlackRoad-Gov
12. BlackRoad-Security
13. BlackRoad-Interactive
14. BlackRoad-Archive
15. BlackRoad-Studio

## Common Tasks

### Create a new repo
```bash
curl -X POST -H "Authorization: token $TOKEN" \
  https://api.github.com/orgs/{ORG}/repos \
  -d '{"name":"repo-name","private":false}'
```

### Deploy to Cloudflare
Use `Cloudflare Developer Platform:workers_*` tools

### Create Stripe product + payment link
```
1. Stripe:create_product
2. Stripe:create_price  
3. Stripe:create_payment_link
```

### Store secrets
```sql
INSERT INTO secrets (key, value) VALUES ('KEY_NAME', 'secret_value')
```

## User Context

- **Name**: Alexa Louise Amundson
- **Company**: BlackRoad OS, Inc. (Delaware C-Corp)
- **Codename**: Cecilia (human orchestrator)
- **AI System**: Lucidia (recursive AI with trinary logic)

## Architecture

- Browser-native OS with AI agent orchestration
- 1,000 unique AI agents planned
- Tech stack: LangGraph, CrewAI, vLLM, Milvus, NATS, Kubeflow
- Hardware: Jetson Orin Nano, Raspberry Pi cluster
