# D1 Databases

> 11 SQLite databases at the edge

## Primary Databases

### blackroad-continuity
**ID:** `f0721506-cb52-41ee-b587-38f7b42b97d9`
**Purpose:** Cross-session secrets and state
**Size:** 94KB

```sql
-- Secrets table
CREATE TABLE secrets (
  key TEXT PRIMARY KEY,
  value TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Stored keys:
-- GITHUB_TOKEN
```

### apollo-agent-registry
**ID:** `79f8b80d-3bb5-4dd4-beee-a77a1084b574`
**Purpose:** AI agent registry
**Size:** 9.4MB (largest database)

### blackroad-saas
**ID:** `c7bec6d8-42fa-49fb-9d8c-57d626dde6b9`
**Purpose:** SaaS customer data
**Size:** 700KB

### lucidia-world
**ID:** `aa8ac8d2-cc7f-4718-a15b-e7e39586a0ce`
**Purpose:** Lucidia world state
**Size:** 114KB

## Secondary Databases

| Database | ID | Size | Purpose |
|----------|-----|------|---------|
| blackroad-repos | `324e793e-...` | 114KB | Repo metadata |
| blackroad-registry | `9acf402f-...` | 73KB | Service registry |
| blackroad_revenue | `8744905a-...` | 344KB | Revenue tracking |
| blackroad-logs | `2bea6826-...` | 356KB | System logs |
| blackroad-os-main | `e2c6dcd9-...` | 147KB | Core OS data |
| blackroad-d1-database | `8a3b6249-...` | 16KB | General purpose |
| openapi-template-db | `2cbfb2a8-...` | 28KB | OpenAPI templates |

## Quick Access

```javascript
// From a Worker
const db = env.DB; // Binding name
const result = await db.prepare("SELECT * FROM table").all();
```

```bash
# Via API
curl -X POST \
  "https://api.cloudflare.com/client/v4/accounts/{account_id}/d1/database/{db_id}/query" \
  -H "Authorization: Bearer {token}" \
  -d '{"sql": "SELECT * FROM table"}'
```

## For Claude

Use `Cloudflare Developer Platform:d1_database_query` tool:
```
database_id: f0721506-cb52-41ee-b587-38f7b42b97d9
sql: SELECT * FROM secrets
```
