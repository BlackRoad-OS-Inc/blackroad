# blackroad-search-engine

Full-text search engine with TF-IDF scoring and SQLite FTS5 for BlackRoad OS.

## Features

- **TF-IDF ranking** — log-normalised TF × smoothed IDF with document-length normalisation
- **Inverted index** — term → document posting lists with position tracking
- **SQLite FTS5** — virtual table kept in sync for fast candidate retrieval
- **Stemming** — Porter-lite suffix stripping (`running` → `runn`)
- **Stop-word filtering** — common English words excluded from indexing
- **Prefix suggestions** — autocomplete from indexed terms, sorted by document frequency
- **Context highlights** — snippets surrounding matched terms
- **Full reindex** — rebuild all index structures from raw document table
- **Index export** — JSON snapshot of documents and postings

## Quick Start

```python
from src.module import Document, index_document, search

index_document(Document(id="d1", title="Python Guide", content="Python programming basics"))
results = search("python programming")
for r in results:
    print(r.score, r.document.title)
```

## CLI

```bash
python src/module.py index d1 "Python Guide" "Python programming basics"
python src/module.py search "python programming" --limit 5
python src/module.py get d1
python src/module.py delete d1
python src/module.py suggest "pyth"
python src/module.py reindex
python src/module.py stats
python src/module.py export
```

## Scoring

```
score(q, d) = Σ TF(t,d) × IDF(t) / √|d|

TF(t,d)  = 1 + log(freq(t,d))          # log-normalised
IDF(t)   = log((N+1)/(df(t)+1)) + 1    # smoothed
|d|      = total token count in d       # length normalisation
```

## Schema

```sql
documents          -- raw document store
documents_fts      -- FTS5 virtual table (title + content)
inverted_index     -- (term, doc_id, frequency, positions)
doc_stats          -- per-document token count for TF normalisation
```

## Tests

```bash
pytest tests/ -v
```
