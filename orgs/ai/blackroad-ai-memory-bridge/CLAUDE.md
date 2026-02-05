# BlackRoad AI Memory Bridge

> Persistent memory and context management for AI agents

## Quick Reference

| Property | Value |
|----------|-------|
| **Type** | Memory System |
| **Backend** | Vector DB + KV |
| **Purpose** | Agent Memory |

## Features

- **Long-term Memory**: Persistent storage across sessions
- **Vector Search**: Semantic similarity retrieval
- **Context Windows**: Manage token limits
- **Memory Consolidation**: Summarization and compression

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   Agent API     │────▶│  Memory Bridge  │
└─────────────────┘     └────────┬────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
       ┌───────────┐      ┌───────────┐      ┌───────────┐
       │ Vector DB │      │ KV Store  │      │ File Store│
       │ (Pinecone)│      │ (Redis)   │      │ (R2/S3)   │
       └───────────┘      └───────────┘      └───────────┘
```

## API Endpoints

```
POST /memory/store       # Store memory
POST /memory/search      # Semantic search
GET  /memory/:id         # Retrieve specific
POST /memory/consolidate # Summarize memories
DELETE /memory/:id       # Delete memory
```

## Memory Types

| Type | TTL | Usage |
|------|-----|-------|
| **Short-term** | 24h | Current session |
| **Working** | 7d | Active project |
| **Long-term** | Forever | Core knowledge |
| **Episodic** | 30d | Event memories |

## PS-SHA∞ Integration

Memories are hashed with PS-SHA∞ for:
- Integrity verification
- Deduplication
- Chain-of-thought tracking

## Environment Variables

```env
VECTOR_DB_URL=          # Pinecone/Weaviate URL
REDIS_URL=              # Redis connection
R2_BUCKET=              # Cloudflare R2 bucket
EMBEDDING_MODEL=        # Embedding model name
```

## Related Repos

- `blackroad-agents` - Agent API
- `lucidia-core` - Reasoning engines
- `blackroad-os-core` - Core platform
