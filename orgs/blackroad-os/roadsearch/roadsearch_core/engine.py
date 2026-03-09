"""RoadSearch Core Engine - Main Search Engine Implementation.

The SearchEngine class is the primary interface for all search operations,
coordinating indexing, querying, and result ranking.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import logging
import threading
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, Generator, List, Optional, Set, Tuple, Union

logger = logging.getLogger(__name__)


class IndexState(Enum):
    """Index state enumeration."""

    INITIALIZING = auto()
    READY = auto()
    INDEXING = auto()
    MERGING = auto()
    OPTIMIZING = auto()
    ERROR = auto()
    CLOSED = auto()


class SearchMode(Enum):
    """Search mode options."""

    FULLTEXT = "fulltext"
    VECTOR = "vector"
    HYBRID = "hybrid"  # Combine fulltext and vector


class HighlightStyle(Enum):
    """Highlight style options."""

    SIMPLE = "simple"
    UNIFIED = "unified"
    FVH = "fvh"  # Fast Vector Highlighter


@dataclass
class SearchConfig:
    """Search engine configuration.

    Attributes:
        index_name: Name of the search index
        default_field: Default search field
        default_operator: Default boolean operator (AND/OR)
        max_results: Maximum results per query
        highlight_enabled: Enable result highlighting
        highlight_style: Highlighting style
        fuzzy_enabled: Enable fuzzy matching by default
        fuzzy_distance: Maximum edit distance for fuzzy matching
        phrase_slop: Maximum positions between terms in phrase
        vector_dimensions: Vector embedding dimensions
        vector_similarity: Vector similarity metric
        analyzer: Default analyzer name
        shards: Number of index shards
        replicas: Number of replicas per shard
    """

    index_name: str = "default"
    default_field: str = "content"
    default_operator: str = "OR"
    max_results: int = 1000
    highlight_enabled: bool = True
    highlight_style: HighlightStyle = HighlightStyle.UNIFIED
    fuzzy_enabled: bool = False
    fuzzy_distance: int = 2
    phrase_slop: int = 0
    vector_dimensions: int = 768
    vector_similarity: str = "cosine"
    analyzer: str = "standard"
    shards: int = 5
    replicas: int = 1
    refresh_interval: float = 1.0  # seconds
    merge_factor: int = 10
    max_merged_segment_mb: int = 500
    auto_commit: bool = True
    commit_interval: float = 5.0
    cache_enabled: bool = True
    cache_size_mb: int = 100


@dataclass
class FieldMapping:
    """Field mapping definition.

    Attributes:
        name: Field name
        type: Field type (text, keyword, integer, float, date, boolean, vector)
        analyzer: Analyzer for text fields
        index: Whether to index this field
        store: Whether to store original value
        boost: Field boost factor
        vector_dimensions: Dimensions for vector fields
        date_format: Format for date fields
    """

    name: str
    type: str = "text"
    analyzer: str = "standard"
    index: bool = True
    store: bool = False
    boost: float = 1.0
    vector_dimensions: Optional[int] = None
    date_format: str = "iso"
    multi_valued: bool = False
    copy_to: Optional[List[str]] = None


@dataclass
class Document:
    """Document for indexing.

    Attributes:
        id: Unique document identifier
        fields: Document fields and values
        vectors: Named vector embeddings
        routing: Routing value for sharding
        parent: Parent document ID
        version: Document version
    """

    id: str
    fields: Dict[str, Any] = field(default_factory=dict)
    vectors: Dict[str, List[float]] = field(default_factory=dict)
    routing: Optional[str] = None
    parent: Optional[str] = None
    version: Optional[int] = None
    timestamp: datetime = field(default_factory=datetime.now)

    def __post_init__(self):
        """Generate ID if not provided."""
        if not self.id:
            self.id = str(uuid.uuid4())

    def get(self, field_name: str, default: Any = None) -> Any:
        """Get field value."""
        return self.fields.get(field_name, default)

    def set(self, field_name: str, value: Any) -> None:
        """Set field value."""
        self.fields[field_name] = value

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "id": self.id,
            "fields": self.fields,
            "vectors": self.vectors,
            "routing": self.routing,
            "parent": self.parent,
            "version": self.version,
            "timestamp": self.timestamp.isoformat(),
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Document":
        """Create from dictionary."""
        timestamp = data.get("timestamp")
        if isinstance(timestamp, str):
            timestamp = datetime.fromisoformat(timestamp)
        return cls(
            id=data["id"],
            fields=data.get("fields", {}),
            vectors=data.get("vectors", {}),
            routing=data.get("routing"),
            parent=data.get("parent"),
            version=data.get("version"),
            timestamp=timestamp or datetime.now(),
        )


@dataclass
class SearchHit:
    """Single search result hit.

    Attributes:
        id: Document ID
        score: Relevance score
        fields: Retrieved fields
        highlights: Highlighted field snippets
        inner_hits: Nested/child hits
        sort_values: Values used for sorting
        explanation: Score explanation
    """

    id: str
    score: float
    fields: Dict[str, Any] = field(default_factory=dict)
    highlights: Dict[str, List[str]] = field(default_factory=dict)
    inner_hits: Dict[str, List["SearchHit"]] = field(default_factory=dict)
    sort_values: List[Any] = field(default_factory=list)
    explanation: Optional[Dict[str, Any]] = None
    matched_queries: List[str] = field(default_factory=list)

    def get(self, field_name: str, default: Any = None) -> Any:
        """Get field value."""
        return self.fields.get(field_name, default)

    def get_highlight(self, field_name: str) -> List[str]:
        """Get highlight snippets for field."""
        return self.highlights.get(field_name, [])


@dataclass
class FacetResult:
    """Facet/aggregation result.

    Attributes:
        name: Facet name
        values: List of (value, count) tuples
        other_count: Count of values not in top N
        missing_count: Count of documents without this field
    """

    name: str
    values: List[Tuple[str, int]] = field(default_factory=list)
    other_count: int = 0
    missing_count: int = 0
    stats: Optional[Dict[str, float]] = None


@dataclass
class SearchResult:
    """Search result container.

    Attributes:
        hits: List of search hits
        total_hits: Total number of matching documents
        took_ms: Query execution time in milliseconds
        max_score: Maximum relevance score
        facets: Facet/aggregation results
        suggestions: Query suggestions
        timed_out: Whether query timed out
        shard_info: Shard execution info
    """

    hits: List[SearchHit] = field(default_factory=list)
    total_hits: int = 0
    took_ms: float = 0.0
    max_score: float = 0.0
    facets: Dict[str, FacetResult] = field(default_factory=dict)
    suggestions: List[str] = field(default_factory=list)
    timed_out: bool = False
    shard_info: Dict[str, Any] = field(default_factory=dict)
    scroll_id: Optional[str] = None

    def __len__(self) -> int:
        """Return number of hits."""
        return len(self.hits)

    def __iter__(self) -> Generator[SearchHit, None, None]:
        """Iterate over hits."""
        yield from self.hits

    def __getitem__(self, index: int) -> SearchHit:
        """Get hit by index."""
        return self.hits[index]


@dataclass
class IndexStats:
    """Index statistics.

    Attributes:
        doc_count: Total indexed documents
        deleted_count: Deleted documents
        size_bytes: Index size in bytes
        segment_count: Number of segments
        term_count: Unique terms
        field_count: Number of fields
    """

    doc_count: int = 0
    deleted_count: int = 0
    size_bytes: int = 0
    segment_count: int = 0
    term_count: int = 0
    field_count: int = 0
    last_modified: Optional[datetime] = None


class QueryBuilder:
    """Fluent query builder.

    Provides a convenient interface for building complex queries.
    """

    def __init__(self, engine: "SearchEngine"):
        """Initialize query builder.

        Args:
            engine: SearchEngine instance
        """
        self._engine = engine
        self._query: Optional[str] = None
        self._filters: List[Dict[str, Any]] = []
        self._fields: List[str] = []
        self._facets: List[str] = []
        self._sort: List[Dict[str, str]] = []
        self._from: int = 0
        self._size: int = 10
        self._highlight_fields: List[str] = []
        self._min_score: Optional[float] = None
        self._timeout_ms: Optional[int] = None
        self._explain: bool = False
        self._vector_query: Optional[Dict[str, Any]] = None

    def query(self, query_string: str) -> "QueryBuilder":
        """Set query string.

        Args:
            query_string: Query in query DSL

        Returns:
            Self for chaining
        """
        self._query = query_string
        return self

    def filter(self, field: str, value: Any) -> "QueryBuilder":
        """Add filter clause.

        Args:
            field: Field name
            value: Filter value

        Returns:
            Self for chaining
        """
        self._filters.append({"field": field, "value": value})
        return self

    def range_filter(
        self,
        field: str,
        gte: Optional[Any] = None,
        lte: Optional[Any] = None,
    ) -> "QueryBuilder":
        """Add range filter.

        Args:
            field: Field name
            gte: Greater than or equal
            lte: Less than or equal

        Returns:
            Self for chaining
        """
        self._filters.append({
            "field": field,
            "range": {"gte": gte, "lte": lte},
        })
        return self

    def select(self, *fields: str) -> "QueryBuilder":
        """Select fields to return.

        Args:
            *fields: Field names

        Returns:
            Self for chaining
        """
        self._fields.extend(fields)
        return self

    def facet(self, field: str) -> "QueryBuilder":
        """Add facet.

        Args:
            field: Field to aggregate

        Returns:
            Self for chaining
        """
        self._facets.append(field)
        return self

    def sort_by(self, field: str, order: str = "asc") -> "QueryBuilder":
        """Add sort clause.

        Args:
            field: Field to sort by
            order: Sort order (asc/desc)

        Returns:
            Self for chaining
        """
        self._sort.append({field: order})
        return self

    def page(self, offset: int, limit: int) -> "QueryBuilder":
        """Set pagination.

        Args:
            offset: Starting offset
            limit: Number of results

        Returns:
            Self for chaining
        """
        self._from = offset
        self._size = limit
        return self

    def highlight(self, *fields: str) -> "QueryBuilder":
        """Enable highlighting for fields.

        Args:
            *fields: Fields to highlight

        Returns:
            Self for chaining
        """
        self._highlight_fields.extend(fields)
        return self

    def min_score(self, score: float) -> "QueryBuilder":
        """Set minimum score threshold.

        Args:
            score: Minimum score

        Returns:
            Self for chaining
        """
        self._min_score = score
        return self

    def timeout(self, ms: int) -> "QueryBuilder":
        """Set query timeout.

        Args:
            ms: Timeout in milliseconds

        Returns:
            Self for chaining
        """
        self._timeout_ms = ms
        return self

    def explain(self, enabled: bool = True) -> "QueryBuilder":
        """Enable score explanation.

        Args:
            enabled: Enable explanation

        Returns:
            Self for chaining
        """
        self._explain = enabled
        return self

    def vector_search(
        self,
        field: str,
        vector: List[float],
        k: int = 10,
    ) -> "QueryBuilder":
        """Add vector similarity search.

        Args:
            field: Vector field name
            vector: Query vector
            k: Number of nearest neighbors

        Returns:
            Self for chaining
        """
        self._vector_query = {"field": field, "vector": vector, "k": k}
        return self

    def execute(self) -> SearchResult:
        """Execute the query.

        Returns:
            Search results
        """
        return self._engine.search(
            query=self._query or "*",
            filters=self._filters,
            fields=self._fields,
            facets=self._facets,
            sort=self._sort,
            offset=self._from,
            limit=self._size,
            highlight_fields=self._highlight_fields,
            min_score=self._min_score,
            timeout_ms=self._timeout_ms,
            explain=self._explain,
            vector_query=self._vector_query,
        )


class SearchEngine:
    """Main search engine class.

    The SearchEngine coordinates all search operations including
    indexing, querying, and ranking.
    """

    def __init__(
        self,
        config: Optional[SearchConfig] = None,
    ):
        """Initialize search engine.

        Args:
            config: Engine configuration
        """
        self.config = config or SearchConfig()
        self._state = IndexState.INITIALIZING
        self._lock = threading.RLock()

        # Internal components (lazily initialized)
        self._inverted_index: Dict[str, Dict[str, List[Tuple[str, int]]]] = {}
        self._document_store: Dict[str, Document] = {}
        self._field_mappings: Dict[str, FieldMapping] = {}
        self._vector_index: Optional[Any] = None  # HNSW index

        # Statistics
        self._stats = IndexStats()
        self._query_count = 0
        self._index_count = 0

        # Caches
        self._query_cache: Dict[str, SearchResult] = {}
        self._filter_cache: Dict[str, Set[str]] = {}

        # Background thread for commits
        self._commit_thread: Optional[threading.Thread] = None
        self._running = False

        # Initialize
        self._initialize()

    def _initialize(self) -> None:
        """Initialize engine components."""
        logger.info(f"Initializing search engine: {self.config.index_name}")

        # Set default field mapping
        self._field_mappings["_all"] = FieldMapping(
            name="_all",
            type="text",
            analyzer=self.config.analyzer,
        )

        # Start background commit thread if auto-commit enabled
        if self.config.auto_commit:
            self._running = True
            self._commit_thread = threading.Thread(
                target=self._background_commit,
                daemon=True,
            )
            self._commit_thread.start()

        self._state = IndexState.READY
        logger.info("Search engine initialized")

    def _background_commit(self) -> None:
        """Background commit thread."""
        while self._running:
            time.sleep(self.config.commit_interval)
            try:
                self.commit()
            except Exception as e:
                logger.error(f"Background commit error: {e}")

    def close(self) -> None:
        """Close the search engine."""
        self._running = False
        if self._commit_thread:
            self._commit_thread.join(timeout=5.0)
        self._state = IndexState.CLOSED
        logger.info("Search engine closed")

    def define_field(self, mapping: FieldMapping) -> None:
        """Define a field mapping.

        Args:
            mapping: Field mapping definition
        """
        with self._lock:
            self._field_mappings[mapping.name] = mapping
            self._stats.field_count = len(self._field_mappings)

    def index(
        self,
        document: Document,
        refresh: bool = False,
    ) -> str:
        """Index a document.

        Args:
            document: Document to index
            refresh: Immediately refresh index

        Returns:
            Document ID
        """
        with self._lock:
            self._state = IndexState.INDEXING

            # Store document
            self._document_store[document.id] = document
            self._stats.doc_count = len(self._document_store)

            # Index all fields
            for field_name, value in document.fields.items():
                self._index_field(document.id, field_name, value)

            # Index vectors if present
            for vector_name, vector in document.vectors.items():
                self._index_vector(document.id, vector_name, vector)

            self._index_count += 1
            self._stats.last_modified = datetime.now()
            self._state = IndexState.READY

            # Invalidate caches
            if self.config.cache_enabled:
                self._query_cache.clear()

            logger.debug(f"Indexed document: {document.id}")
            return document.id

    def _index_field(
        self,
        doc_id: str,
        field_name: str,
        value: Any,
    ) -> None:
        """Index a single field.

        Args:
            doc_id: Document ID
            field_name: Field name
            value: Field value
        """
        if value is None:
            return

        # Get or create field index
        if field_name not in self._inverted_index:
            self._inverted_index[field_name] = {}

        field_index = self._inverted_index[field_name]

        # Analyze and index based on type
        if isinstance(value, str):
            # Tokenize text
            tokens = self._analyze(field_name, value)
            for position, token in enumerate(tokens):
                if token not in field_index:
                    field_index[token] = []
                field_index[token].append((doc_id, position))
                self._stats.term_count = sum(
                    len(terms) for terms in self._inverted_index.values()
                )
        elif isinstance(value, (int, float)):
            # Store numeric as string for now
            str_value = str(value)
            if str_value not in field_index:
                field_index[str_value] = []
            field_index[str_value].append((doc_id, 0))
        elif isinstance(value, list):
            # Multi-valued field
            for item in value:
                self._index_field(doc_id, field_name, item)

    def _analyze(self, field_name: str, text: str) -> List[str]:
        """Analyze text into tokens.

        Args:
            field_name: Field name for analyzer selection
            text: Text to analyze

        Returns:
            List of tokens
        """
        # Simple whitespace tokenization with lowercasing
        # In real implementation, use configured analyzer
        tokens = []
        for word in text.lower().split():
            # Remove punctuation
            word = "".join(c for c in word if c.isalnum())
            if word:
                tokens.append(word)
        return tokens

    def _index_vector(
        self,
        doc_id: str,
        vector_name: str,
        vector: List[float],
    ) -> None:
        """Index a vector embedding.

        Args:
            doc_id: Document ID
            vector_name: Vector field name
            vector: Vector data
        """
        # Store in vector index
        # In real implementation, use HNSW or similar
        pass

    def bulk_index(
        self,
        documents: List[Document],
        batch_size: int = 1000,
    ) -> Dict[str, int]:
        """Bulk index documents.

        Args:
            documents: Documents to index
            batch_size: Batch size

        Returns:
            Indexing statistics
        """
        indexed = 0
        failed = 0

        for i in range(0, len(documents), batch_size):
            batch = documents[i:i + batch_size]
            for doc in batch:
                try:
                    self.index(doc)
                    indexed += 1
                except Exception as e:
                    logger.error(f"Failed to index {doc.id}: {e}")
                    failed += 1

        return {"indexed": indexed, "failed": failed}

    def delete(self, doc_id: str) -> bool:
        """Delete a document.

        Args:
            doc_id: Document ID

        Returns:
            True if deleted
        """
        with self._lock:
            if doc_id not in self._document_store:
                return False

            # Remove from document store
            del self._document_store[doc_id]

            # Remove from inverted index
            for field_index in self._inverted_index.values():
                for term, postings in list(field_index.items()):
                    field_index[term] = [
                        (d, p) for d, p in postings if d != doc_id
                    ]
                    if not field_index[term]:
                        del field_index[term]

            self._stats.doc_count = len(self._document_store)
            self._stats.deleted_count += 1

            # Invalidate caches
            if self.config.cache_enabled:
                self._query_cache.clear()

            return True

    def delete_by_query(self, query: str) -> int:
        """Delete documents matching query.

        Args:
            query: Query string

        Returns:
            Number of deleted documents
        """
        result = self.search(query, limit=10000)
        deleted = 0
        for hit in result.hits:
            if self.delete(hit.id):
                deleted += 1
        return deleted

    def get(self, doc_id: str) -> Optional[Document]:
        """Get document by ID.

        Args:
            doc_id: Document ID

        Returns:
            Document or None
        """
        return self._document_store.get(doc_id)

    def exists(self, doc_id: str) -> bool:
        """Check if document exists.

        Args:
            doc_id: Document ID

        Returns:
            True if exists
        """
        return doc_id in self._document_store

    def search(
        self,
        query: str,
        filters: Optional[List[Dict[str, Any]]] = None,
        fields: Optional[List[str]] = None,
        facets: Optional[List[str]] = None,
        sort: Optional[List[Dict[str, str]]] = None,
        offset: int = 0,
        limit: int = 10,
        highlight_fields: Optional[List[str]] = None,
        min_score: Optional[float] = None,
        timeout_ms: Optional[int] = None,
        explain: bool = False,
        vector_query: Optional[Dict[str, Any]] = None,
    ) -> SearchResult:
        """Execute a search query.

        Args:
            query: Query string
            filters: Filter clauses
            fields: Fields to return
            facets: Fields to aggregate
            sort: Sort clauses
            offset: Starting offset
            limit: Maximum results
            highlight_fields: Fields to highlight
            min_score: Minimum score threshold
            timeout_ms: Query timeout
            explain: Include score explanation
            vector_query: Vector similarity query

        Returns:
            Search results
        """
        start_time = time.time()
        self._query_count += 1

        # Check cache
        cache_key = self._make_cache_key(query, filters, sort, offset, limit)
        if self.config.cache_enabled and cache_key in self._query_cache:
            cached = self._query_cache[cache_key]
            logger.debug(f"Cache hit for query: {query}")
            return cached

        # Parse query
        terms = self._analyze("_query", query)

        # Find matching documents
        matching_docs: Dict[str, float] = {}

        if query == "*":
            # Match all
            for doc_id in self._document_store:
                matching_docs[doc_id] = 1.0
        else:
            # Term matching with BM25-like scoring
            for term in terms:
                for field_name, field_index in self._inverted_index.items():
                    if term in field_index:
                        postings = field_index[term]
                        # Calculate IDF
                        idf = self._calculate_idf(len(postings))

                        for doc_id, position in postings:
                            score = idf * self._calculate_tf(len(postings))
                            matching_docs[doc_id] = matching_docs.get(doc_id, 0) + score

        # Apply filters
        if filters:
            matching_docs = self._apply_filters(matching_docs, filters)

        # Apply min score
        if min_score is not None:
            matching_docs = {
                d: s for d, s in matching_docs.items() if s >= min_score
            }

        # Sort results
        if sort:
            sorted_docs = self._apply_sort(matching_docs, sort)
        else:
            # Sort by score descending
            sorted_docs = sorted(
                matching_docs.items(),
                key=lambda x: x[1],
                reverse=True,
            )

        # Paginate
        total_hits = len(sorted_docs)
        sorted_docs = sorted_docs[offset:offset + limit]

        # Build hits
        hits = []
        max_score = 0.0
        for doc_id, score in sorted_docs:
            if score > max_score:
                max_score = score

            doc = self._document_store.get(doc_id)
            if not doc:
                continue

            # Select fields
            if fields:
                hit_fields = {f: doc.fields.get(f) for f in fields if f in doc.fields}
            else:
                hit_fields = doc.fields.copy()

            # Generate highlights
            highlights = {}
            if highlight_fields and self.config.highlight_enabled:
                for field_name in highlight_fields:
                    if field_name in doc.fields:
                        highlights[field_name] = self._highlight(
                            doc.fields[field_name],
                            terms,
                        )

            hit = SearchHit(
                id=doc_id,
                score=score,
                fields=hit_fields,
                highlights=highlights,
            )

            if explain:
                hit.explanation = self._explain_score(doc_id, terms, score)

            hits.append(hit)

        # Build facets
        facet_results = {}
        if facets:
            for facet_field in facets:
                facet_results[facet_field] = self._compute_facet(
                    matching_docs.keys(),
                    facet_field,
                )

        # Calculate time
        took_ms = (time.time() - start_time) * 1000

        result = SearchResult(
            hits=hits,
            total_hits=total_hits,
            took_ms=took_ms,
            max_score=max_score,
            facets=facet_results,
        )

        # Cache result
        if self.config.cache_enabled:
            self._query_cache[cache_key] = result

        return result

    def _calculate_tf(self, term_freq: int) -> float:
        """Calculate term frequency score."""
        return 1.0 + (term_freq ** 0.5) if term_freq > 0 else 0.0

    def _calculate_idf(self, doc_freq: int) -> float:
        """Calculate inverse document frequency."""
        import math
        total_docs = len(self._document_store) or 1
        return math.log(1.0 + (total_docs - doc_freq + 0.5) / (doc_freq + 0.5))

    def _apply_filters(
        self,
        docs: Dict[str, float],
        filters: List[Dict[str, Any]],
    ) -> Dict[str, float]:
        """Apply filters to matching documents."""
        filtered = docs.copy()

        for f in filters:
            field = f.get("field")
            value = f.get("value")
            range_filter = f.get("range")

            for doc_id in list(filtered.keys()):
                doc = self._document_store.get(doc_id)
                if not doc:
                    del filtered[doc_id]
                    continue

                field_value = doc.fields.get(field)

                if range_filter:
                    gte = range_filter.get("gte")
                    lte = range_filter.get("lte")
                    if gte is not None and field_value < gte:
                        del filtered[doc_id]
                    elif lte is not None and field_value > lte:
                        del filtered[doc_id]
                elif value is not None and field_value != value:
                    del filtered[doc_id]

        return filtered

    def _apply_sort(
        self,
        docs: Dict[str, float],
        sort: List[Dict[str, str]],
    ) -> List[Tuple[str, float]]:
        """Apply sort to documents."""
        doc_list = list(docs.items())

        for sort_clause in reversed(sort):
            for field, order in sort_clause.items():
                reverse = order.lower() == "desc"

                if field == "_score":
                    doc_list.sort(key=lambda x: x[1], reverse=reverse)
                else:
                    doc_list.sort(
                        key=lambda x: self._document_store.get(x[0], Document(id="")).fields.get(field, ""),
                        reverse=reverse,
                    )

        return doc_list

    def _highlight(self, text: str, terms: List[str]) -> List[str]:
        """Generate highlighted snippets."""
        if not isinstance(text, str):
            return []

        snippets = []
        text_lower = text.lower()

        for term in terms:
            pos = text_lower.find(term)
            if pos >= 0:
                # Get surrounding context
                start = max(0, pos - 50)
                end = min(len(text), pos + len(term) + 50)
                snippet = text[start:end]

                # Wrap match in tags
                term_start = snippet.lower().find(term)
                if term_start >= 0:
                    highlighted = (
                        snippet[:term_start] +
                        "<em>" +
                        snippet[term_start:term_start + len(term)] +
                        "</em>" +
                        snippet[term_start + len(term):]
                    )
                    snippets.append(highlighted)

        return snippets or [text[:100] + "..." if len(text) > 100 else text]

    def _explain_score(
        self,
        doc_id: str,
        terms: List[str],
        score: float,
    ) -> Dict[str, Any]:
        """Generate score explanation."""
        return {
            "value": score,
            "description": f"sum of term scores for {len(terms)} terms",
            "details": [
                {"term": term, "contribution": score / len(terms)}
                for term in terms
            ],
        }

    def _compute_facet(
        self,
        doc_ids: Set[str],
        field: str,
    ) -> FacetResult:
        """Compute facet for field."""
        value_counts: Dict[str, int] = {}
        missing = 0

        for doc_id in doc_ids:
            doc = self._document_store.get(doc_id)
            if not doc:
                continue

            value = doc.fields.get(field)
            if value is None:
                missing += 1
            elif isinstance(value, list):
                for v in value:
                    value_counts[str(v)] = value_counts.get(str(v), 0) + 1
            else:
                value_counts[str(value)] = value_counts.get(str(value), 0) + 1

        # Sort by count descending
        sorted_values = sorted(
            value_counts.items(),
            key=lambda x: x[1],
            reverse=True,
        )[:10]

        return FacetResult(
            name=field,
            values=sorted_values,
            missing_count=missing,
        )

    def _make_cache_key(
        self,
        query: str,
        filters: Optional[List[Dict[str, Any]]],
        sort: Optional[List[Dict[str, str]]],
        offset: int,
        limit: int,
    ) -> str:
        """Generate cache key for query."""
        key_data = f"{query}:{filters}:{sort}:{offset}:{limit}"
        return hashlib.md5(key_data.encode()).hexdigest()

    def query_builder(self) -> QueryBuilder:
        """Create a query builder.

        Returns:
            QueryBuilder instance
        """
        return QueryBuilder(self)

    def suggest(
        self,
        text: str,
        field: str = "content",
        max_suggestions: int = 5,
    ) -> List[str]:
        """Get query suggestions.

        Args:
            text: Input text
            field: Field to suggest from
            max_suggestions: Maximum suggestions

        Returns:
            List of suggestions
        """
        suggestions = []
        text_lower = text.lower()

        if field in self._inverted_index:
            for term in self._inverted_index[field].keys():
                if term.startswith(text_lower):
                    suggestions.append(term)
                    if len(suggestions) >= max_suggestions:
                        break

        return suggestions

    def commit(self) -> None:
        """Commit pending changes."""
        with self._lock:
            # In real implementation, flush segments to disk
            logger.debug("Committed index changes")

    def refresh(self) -> None:
        """Refresh index for near real-time search."""
        with self._lock:
            # Make recent changes visible
            pass

    def optimize(self, max_segments: int = 1) -> None:
        """Optimize index by merging segments.

        Args:
            max_segments: Target number of segments
        """
        with self._lock:
            self._state = IndexState.OPTIMIZING
            # In real implementation, merge segments
            self._state = IndexState.READY
            logger.info("Index optimization complete")

    def get_stats(self) -> IndexStats:
        """Get index statistics.

        Returns:
            Index statistics
        """
        self._stats.size_bytes = sum(
            len(str(doc.to_dict())) for doc in self._document_store.values()
        )
        return self._stats

    @property
    def state(self) -> IndexState:
        """Get current engine state."""
        return self._state

    def __enter__(self) -> "SearchEngine":
        """Context manager entry."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Context manager exit."""
        self.close()


__all__ = [
    "SearchEngine",
    "SearchConfig",
    "Document",
    "SearchResult",
    "SearchHit",
    "FacetResult",
    "FieldMapping",
    "IndexStats",
    "QueryBuilder",
    "IndexState",
    "SearchMode",
    "HighlightStyle",
]
