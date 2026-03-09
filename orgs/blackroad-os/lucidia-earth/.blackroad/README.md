# .blackroad/ - Cross-Repo Index System

This directory contains the **Tier 1 local index** for this repository.

## Files

- **workflow-index.jsonl** - Append-only log of all workflows in this repo
- **workflow-index-schema.json** - JSON schema for validation
- **last-sync.txt** - Last sync timestamp

## How It Works

1. When an issue is created/updated with a workflow ID label
2. `workflow-index-sync.yml` runs automatically
3. Extracts metadata (state, scope, risk, dependencies, etc.)
4. Appends to `workflow-index.jsonl`
5. Commits the update

## Querying

```bash
# Find all Active workflows
jq 'select(.state=="Active")' .blackroad/workflow-index.jsonl

# Find workflows with dependencies
jq 'select(.deps | length > 0)' .blackroad/workflow-index.jsonl

# Find System-scope workflows
jq 'select(.scope=="System")' .blackroad/workflow-index.jsonl

# Find Red traffic light workflows
jq 'select(.traffic_light=="🔴")' .blackroad/workflow-index.jsonl
```

## Cross-Repo Dependencies

Format: `{owner}/{repo}#{WORKFLOW_ID}`

Example:
```json
{
  "id": "WF-20260213-SVC-0005",
  "deps": [
    "WF-20260212-SYS-0001",                    // Local dependency
    "BlackRoad-OS/api#SEC-20260213-PUB-0006"  // Cross-repo dependency
  ]
}
```

## Architecture

This is **Tier 1** (Local Index) of a 3-tier system:

- **Tier 1**: Local repo index (this file)
- **Tier 2**: Organization-wide GitHub Project
- **Tier 3**: Global discovery API (optional)

See: ~/CROSS_REPO_INDEX_STRATEGY.md

## Maintenance

- Index is **append-only** (never delete entries)
- Updates replace old entries by ID
- No manual editing required
- Scales to millions of workflows
