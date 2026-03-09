"""RoadSearch - Enterprise Search Engine for BlackRoad OS.

A comprehensive full-text, vector, and faceted search engine with
AI-powered relevance optimization and query understanding.

Architecture:
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RoadSearch Engine                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        Query Pipeline                               │   │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│   │  │   Parse    │→ │  Analyze   │→ │  Optimize  │→ │  Execute   │    │   │
│   │  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        Index Layer                                  │   │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│   │  │  Inverted  │  │   Vector   │  │   Facet    │  │  Document  │    │   │
│   │  │   Index    │  │   Index    │  │   Index    │  │   Store    │    │   │
│   │  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        Ranking Engine                               │   │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│   │  │   BM25     │  │  TF-IDF    │  │  Vector    │  │   Custom   │    │   │
│   │  │  Scorer    │  │  Scorer    │  │ Similarity │  │   Scorer   │    │   │
│   │  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         AI Agents                                   │   │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐    │   │
│   │  │ Relevance  │  │   Query    │  │   Index    │  │  Analytics │    │   │
│   │  │   Tuner    │  │ Optimizer  │  │  Guardian  │  │   Agent    │    │   │
│   │  └────────────┘  └────────────┘  └────────────┘  └────────────┘    │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Key Features:
- Full-text search with BM25 and TF-IDF scoring
- Vector/semantic search with HNSW index
- Faceted search with aggregations
- Powerful query DSL with boolean operators
- Text analysis pipeline (tokenization, stemming, synonyms)
- AI-powered relevance tuning and query optimization
- Real-time indexing with near-instant visibility
- Distributed index sharding and replication

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

__version__ = "1.0.0"
__author__ = "BlackRoad OS"
__license__ = "Proprietary"

# Core engine
from roadsearch_core.engine import (
    SearchEngine,
    SearchConfig,
    Document,
    SearchResult,
    SearchHit,
)

# Index components
from roadsearch_core.index.inverted import (
    InvertedIndex,
    Posting,
    PostingList,
    Term,
)
from roadsearch_core.index.document import (
    DocumentStore,
    StoredDocument,
    DocumentMetadata,
)
from roadsearch_core.index.segment import (
    Segment,
    SegmentInfo,
    SegmentMerger,
)

# Query components
from roadsearch_core.query.parser import (
    QueryParser,
    ParsedQuery,
    QueryNode,
    BooleanQuery,
    TermQuery,
    PhraseQuery,
    RangeQuery,
    WildcardQuery,
    FuzzyQuery,
)
from roadsearch_core.query.executor import (
    QueryExecutor,
    ExecutionPlan,
    QueryContext,
)

# Analyzers
from roadsearch_core.analyzers.base import (
    Analyzer,
    Token,
    TokenStream,
)
from roadsearch_core.analyzers.standard import (
    StandardAnalyzer,
    SimpleAnalyzer,
    WhitespaceAnalyzer,
    KeywordAnalyzer,
)
from roadsearch_core.analyzers.filters import (
    TokenFilter,
    LowercaseFilter,
    StopwordFilter,
    StemmerFilter,
    SynonymFilter,
    NGramFilter,
    EdgeNGramFilter,
)
from roadsearch_core.analyzers.tokenizers import (
    Tokenizer,
    StandardTokenizer,
    WhitespaceTokenizer,
    LetterTokenizer,
    PatternTokenizer,
)

# Vector search
from roadsearch_core.vector.index import (
    VectorIndex,
    HNSWIndex,
    Vector,
    VectorSearchResult,
)
from roadsearch_core.vector.embeddings import (
    Embedder,
    EmbeddingModel,
    EmbeddingConfig,
)

# Faceted search
from roadsearch_core.facets.builder import (
    FacetBuilder,
    Facet,
    FacetValue,
    FacetResult,
)
from roadsearch_core.facets.aggregations import (
    Aggregation,
    TermsAggregation,
    RangeAggregation,
    HistogramAggregation,
    DateHistogramAggregation,
    StatsAggregation,
)

# Ranking
from roadsearch_core.ranking.scorer import (
    Scorer,
    ScoringContext,
)
from roadsearch_core.ranking.bm25 import (
    BM25Scorer,
    BM25Parameters,
)
from roadsearch_core.ranking.tfidf import (
    TFIDFScorer,
    TFIDFConfig,
)
from roadsearch_core.ranking.boosting import (
    FieldBooster,
    FunctionScorer,
    DecayFunction,
)

# Storage
from roadsearch_core.storage.backend import (
    StorageBackend,
    StorageConfig,
)
from roadsearch_core.storage.memory import MemoryStorage
from roadsearch_core.storage.file import FileStorage
from roadsearch_core.storage.distributed import DistributedStorage

# AI Agents
from roadsearch_core.agents import (
    RelevanceTuner,
    QueryOptimizer,
    IndexGuardian,
    AnalyticsAgent,
)

__all__ = [
    # Version
    "__version__",
    "__author__",
    "__license__",
    # Core
    "SearchEngine",
    "SearchConfig",
    "Document",
    "SearchResult",
    "SearchHit",
    # Index
    "InvertedIndex",
    "Posting",
    "PostingList",
    "Term",
    "DocumentStore",
    "StoredDocument",
    "DocumentMetadata",
    "Segment",
    "SegmentInfo",
    "SegmentMerger",
    # Query
    "QueryParser",
    "ParsedQuery",
    "QueryNode",
    "BooleanQuery",
    "TermQuery",
    "PhraseQuery",
    "RangeQuery",
    "WildcardQuery",
    "FuzzyQuery",
    "QueryExecutor",
    "ExecutionPlan",
    "QueryContext",
    # Analyzers
    "Analyzer",
    "Token",
    "TokenStream",
    "StandardAnalyzer",
    "SimpleAnalyzer",
    "WhitespaceAnalyzer",
    "KeywordAnalyzer",
    "TokenFilter",
    "LowercaseFilter",
    "StopwordFilter",
    "StemmerFilter",
    "SynonymFilter",
    "NGramFilter",
    "EdgeNGramFilter",
    "Tokenizer",
    "StandardTokenizer",
    "WhitespaceTokenizer",
    "LetterTokenizer",
    "PatternTokenizer",
    # Vector
    "VectorIndex",
    "HNSWIndex",
    "Vector",
    "VectorSearchResult",
    "Embedder",
    "EmbeddingModel",
    "EmbeddingConfig",
    # Facets
    "FacetBuilder",
    "Facet",
    "FacetValue",
    "FacetResult",
    "Aggregation",
    "TermsAggregation",
    "RangeAggregation",
    "HistogramAggregation",
    "DateHistogramAggregation",
    "StatsAggregation",
    # Ranking
    "Scorer",
    "ScoringContext",
    "BM25Scorer",
    "BM25Parameters",
    "TFIDFScorer",
    "TFIDFConfig",
    "FieldBooster",
    "FunctionScorer",
    "DecayFunction",
    # Storage
    "StorageBackend",
    "StorageConfig",
    "MemoryStorage",
    "FileStorage",
    "DistributedStorage",
    # Agents
    "RelevanceTuner",
    "QueryOptimizer",
    "IndexGuardian",
    "AnalyticsAgent",
]
