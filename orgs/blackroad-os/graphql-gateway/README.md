# BlackRoad GraphQL Gateway

**Unified GraphQL API gateway for all 40+ BlackRoad products**

## Overview

Single endpoint aggregating all BlackRoad services into one unified GraphQL schema.

## Quick Start

```bash
npm install @blackroad/graphql-gateway
npm start
```

## Endpoint

```
https://api.blackroad.io/graphql
```

## Features

- **Unified Schema**: All 40+ products in one schema
- **Subscriptions**: Real-time updates via WebSocket
- **Optimized Queries**: DataLoader batching, query caching
- **GraphQL Playground**: Interactive API explorer
- **Federation Ready**: Apollo Federation support

## Example Query

```graphql
query {
  user(id: "123") {
    id
    name
    products {
      id
      name
      status
    }
    agents {
      id
      type
      health
    }
  }
}
```

## Schema Modules

| Module | Products |
|--------|----------|
| Users | Auth, profiles, permissions |
| Products | All 40+ product APIs |
| Agents | AI agent management |
| Infrastructure | Deployments, status |
| Analytics | Metrics, usage |

## Performance

- 50% faster frontend development
- Query batching reduces API calls
- Response caching (Redis)
- CDN edge caching

---

*BlackRoad OS - Unified API*
