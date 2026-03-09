# BlackRoad Vector Databases

**Embedding storage and similarity search for AI workloads**

## Supported Databases

| Database | Use Case | Scale | Performance |
|----------|----------|-------|-------------|
| Milvus | Production clusters | Billions | High |
| pgvector | PostgreSQL native | Millions | Good |
| LanceDB | Serverless/Edge | Millions | Fast |
| Faiss | In-memory | Billions | Fastest |

## Quick Start

### Milvus (Distributed)
```bash
docker compose -f milvus/docker-compose.yml up -d
```

### pgvector (PostgreSQL)
```sql
CREATE EXTENSION vector;
CREATE TABLE embeddings (id serial, embedding vector(1536));
```

### LanceDB (Serverless)
```python
import lancedb
db = lancedb.connect("./blackroad-vectors")
```

### Faiss (In-Memory)
```python
import faiss
index = faiss.IndexFlatL2(1536)
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   BlackRoad AI Layer                     │
├─────────────┬─────────────┬─────────────┬──────────────┤
│   Milvus    │  pgvector   │  LanceDB    │    Faiss     │
│  (Cluster)  │ (Postgres)  │ (Serverless)│  (In-Memory) │
└─────────────┴─────────────┴─────────────┴──────────────┘
```

## Embedding Models

| Model | Dimensions | Use Case |
|-------|------------|----------|
| text-embedding-3-large | 3072 | High accuracy |
| text-embedding-3-small | 1536 | Balanced |
| BGE-M3 | 1024 | Multilingual |
| all-MiniLM-L6-v2 | 384 | Fast/lightweight |

---

*BlackRoad OS - Vector Intelligence at Scale*
