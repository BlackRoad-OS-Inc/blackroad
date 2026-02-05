# BlackRoad AI Memory Bridge - Planning

> Development planning for agent memory system

## Vision

Build a persistent, intelligent memory system with:
- Semantic search across all memories
- Memory consolidation and summarization
- Cross-agent knowledge sharing
- Privacy-preserving architecture

---

## Current State

### Storage Backends

| Backend | Purpose | Size | Status |
|---------|---------|------|--------|
| Redis | Working memory | 2GB | ✅ Active |
| PostgreSQL | Episodic memory | 50GB | ✅ Active |
| Pinecone | Semantic memory | 1.2M vectors | ✅ Active |
| R2 | Archival memory | 100GB | ✅ Active |

### Memory Stats

| Metric | Value |
|--------|-------|
| Total memories | 1.2M |
| Daily writes | ~50K |
| Daily reads | ~200K |
| Avg retrieval latency | 85ms |

---

## Current Sprint

### Sprint 2026-02

#### Goals
- [ ] Implement memory consolidation v2
- [ ] Add cross-agent memory sharing
- [ ] Improve search relevance
- [ ] Build memory visualization

#### Tasks

| Task | Priority | Status | Est. |
|------|----------|--------|------|
| Consolidation algorithm | P0 | 🔄 In Progress | 4d |
| Sharing permissions | P1 | 📋 Planned | 3d |
| Search ranking | P1 | 📋 Planned | 3d |
| Visualization UI | P2 | 📋 Planned | 5d |

---

## Memory Architecture

### Memory Types

```
┌─────────────────────────────────────────────────────────────┐
│                    MEMORY HIERARCHY                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 WORKING MEMORY                       │   │
│  │                   (Redis)                            │   │
│  │                                                      │   │
│  │  • Current context (session)                         │   │
│  │  • Active task state                                 │   │
│  │  • Recent tool outputs                               │   │
│  │                                                      │   │
│  │  TTL: 24 hours    Latency: <10ms                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                     consolidate                             │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                EPISODIC MEMORY                       │   │
│  │                 (PostgreSQL)                         │   │
│  │                                                      │   │
│  │  • Conversation history                              │   │
│  │  • Task completions                                  │   │
│  │  • User interactions                                 │   │
│  │                                                      │   │
│  │  TTL: 30 days     Latency: <50ms                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                      embed                                  │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                SEMANTIC MEMORY                       │   │
│  │                  (Pinecone)                          │   │
│  │                                                      │   │
│  │  • Knowledge embeddings                              │   │
│  │  • Concept relationships                             │   │
│  │  • Learned patterns                                  │   │
│  │                                                      │   │
│  │  TTL: Forever     Latency: <100ms                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                     archive                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                ARCHIVAL MEMORY                       │   │
│  │                    (R2)                              │   │
│  │                                                      │   │
│  │  • Full conversation logs                            │   │
│  │  • Large documents                                   │   │
│  │  • Historical snapshots                              │   │
│  │                                                      │   │
│  │  TTL: Forever     Latency: <1s                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Memory Consolidation v2

### Current Algorithm
- Simple time-based pruning
- No summarization
- Manual triggers

### New Algorithm

```python
async def consolidate_memories(agent_id: str):
    # 1. Fetch working memories older than threshold
    memories = await redis.get_old_memories(agent_id, hours=12)

    # 2. Group by topic/context
    groups = cluster_memories(memories)

    # 3. Summarize each group
    for group in groups:
        summary = await llm.summarize(group.memories)

        # 4. Store summary in episodic
        await postgres.store_summary(
            agent_id=agent_id,
            summary=summary,
            source_count=len(group.memories),
            time_range=group.time_range
        )

        # 5. Generate embedding
        embedding = await embed(summary.text)

        # 6. Store in semantic
        await pinecone.upsert(
            id=summary.id,
            embedding=embedding,
            metadata=summary.metadata
        )

    # 7. Archive raw memories
    await r2.archive(memories)

    # 8. Clear working memory
    await redis.delete(memories)
```

### Consolidation Schedule

| Frequency | Action | Threshold |
|-----------|--------|-----------|
| Hourly | Working → Episodic | >100 memories |
| Daily | Episodic → Semantic | >1000 memories |
| Weekly | Semantic optimization | Rebalance index |
| Monthly | Archive old data | >30 days |

---

## Cross-Agent Sharing

### Permission Model

```
┌─────────────────────────────────────────────────────────────┐
│                  MEMORY SHARING MODEL                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  OWNER (Agent A)                                            │
│       │                                                     │
│       ├── Private (default)                                 │
│       │   └── Only owner can access                         │
│       │                                                     │
│       ├── Team                                              │
│       │   └── Specific agents can access                    │
│       │       └── [LUCIDIA, ALICE, OCTAVIA]                │
│       │                                                     │
│       ├── Organization                                      │
│       │   └── All agents in org can access                  │
│       │                                                     │
│       └── Public                                            │
│           └── Any agent can access                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Sharing API

```
POST /memory/:id/share
{
  "permission": "team",
  "agents": ["LUCIDIA", "ALICE"],
  "expires_at": "2026-03-01T00:00:00Z"
}

GET /memory/shared
# Returns memories shared with current agent

POST /memory/search
{
  "query": "deployment procedures",
  "include_shared": true,
  "permission_filter": ["team", "organization"]
}
```

---

## Search Improvements

### Current Search
- Basic vector similarity
- No ranking adjustments
- Single index

### New Search Features

1. **Hybrid Search**
   - Vector similarity (semantic)
   - Keyword matching (lexical)
   - Combined scoring

2. **Ranking Factors**
   - Recency boost
   - Access frequency
   - Agent affinity
   - Task relevance

3. **Query Understanding**
   - Intent classification
   - Query expansion
   - Synonym matching

### Search Algorithm

```python
def search_memories(query: str, agent_id: str):
    # 1. Understand query
    intent = classify_intent(query)
    expanded = expand_query(query)

    # 2. Vector search
    vector_results = pinecone.search(
        embedding=embed(query),
        top_k=100
    )

    # 3. Keyword search
    keyword_results = postgres.search(
        query=expanded,
        limit=100
    )

    # 4. Combine and rank
    combined = merge_results(vector_results, keyword_results)

    # 5. Apply ranking
    ranked = apply_ranking(
        results=combined,
        recency_weight=0.3,
        frequency_weight=0.2,
        relevance_weight=0.5
    )

    # 6. Filter by permissions
    filtered = filter_permissions(ranked, agent_id)

    return filtered[:20]
```

---

## Performance Targets

| Metric | Current | Target |
|--------|---------|--------|
| Write latency | 50ms | 20ms |
| Read latency | 85ms | 40ms |
| Search latency | 150ms | 80ms |
| Consolidation time | 5min | 1min |
| Storage efficiency | 60% | 80% |

---

*Last updated: 2026-02-05*
