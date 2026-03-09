"""RoadSearch Query Executor - Query Execution Engine.

Executes parsed queries against the index, handling optimization,
scoring, and result assembly.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import heapq
import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, Generator, List, Optional, Set, Tuple

from roadsearch_core.query.parser import (
    QueryNode,
    BooleanQuery,
    TermQuery,
    PhraseQuery,
    RangeQuery,
    WildcardQuery,
    FuzzyQuery,
    MatchAllQuery,
    MatchNoneQuery,
    ParsedQuery,
    QueryType,
)

logger = logging.getLogger(__name__)


class ExecutionPhase(Enum):
    """Query execution phases."""

    REWRITE = auto()  # Query rewriting
    OPTIMIZE = auto()  # Query optimization
    COLLECT = auto()  # Document collection
    SCORE = auto()  # Scoring
    SORT = auto()  # Sorting
    PAGINATE = auto()  # Pagination


@dataclass
class QueryContext:
    """Context for query execution.

    Attributes:
        start_time: Execution start time
        timeout_ms: Query timeout in milliseconds
        fields: Fields to return
        highlight_fields: Fields to highlight
        sort_fields: Sort specification
        offset: Pagination offset
        limit: Maximum results
        min_score: Minimum score threshold
        explain: Include score explanation
        track_scores: Track document scores
        track_total_hits: Track exact total hits
        search_after: Cursor for deep pagination
    """

    start_time: datetime = field(default_factory=datetime.now)
    timeout_ms: int = 30000
    fields: List[str] = field(default_factory=list)
    highlight_fields: List[str] = field(default_factory=list)
    sort_fields: List[Dict[str, str]] = field(default_factory=list)
    offset: int = 0
    limit: int = 10
    min_score: Optional[float] = None
    explain: bool = False
    track_scores: bool = True
    track_total_hits: bool = True
    search_after: Optional[List[Any]] = None

    def elapsed_ms(self) -> float:
        """Get elapsed time in milliseconds."""
        return (datetime.now() - self.start_time).total_seconds() * 1000

    def is_timed_out(self) -> bool:
        """Check if query has timed out."""
        return self.elapsed_ms() > self.timeout_ms


@dataclass
class ExecutionStats:
    """Statistics about query execution.

    Attributes:
        total_hits: Total matching documents
        collected_hits: Documents collected
        scored_hits: Documents scored
        filtered_hits: Documents filtered
        phase_times: Time spent in each phase
        segments_searched: Number of segments searched
        terms_matched: Number of terms matched
    """

    total_hits: int = 0
    collected_hits: int = 0
    scored_hits: int = 0
    filtered_hits: int = 0
    phase_times: Dict[str, float] = field(default_factory=dict)
    segments_searched: int = 0
    terms_matched: int = 0

    def add_phase_time(self, phase: ExecutionPhase, time_ms: float) -> None:
        """Record time for execution phase."""
        self.phase_times[phase.name] = time_ms


@dataclass
class ScoredDocument:
    """A document with its score.

    Attributes:
        doc_id: Document ID
        score: Relevance score
        sort_values: Values for sorting
        explanation: Score explanation
        highlights: Highlighted snippets
    """

    doc_id: str
    score: float
    sort_values: List[Any] = field(default_factory=list)
    explanation: Optional[Dict[str, Any]] = None
    highlights: Dict[str, List[str]] = field(default_factory=dict)

    def __lt__(self, other: "ScoredDocument") -> bool:
        """Compare by score for heap operations."""
        return self.score < other.score


class ExecutionPlan:
    """Query execution plan.

    Represents the planned execution of a query, including
    optimizations and execution strategy.
    """

    def __init__(self, query: ParsedQuery):
        """Initialize execution plan.

        Args:
            query: Parsed query
        """
        self.original_query = query
        self.rewritten_query: Optional[QueryNode] = None
        self.optimizations: List[str] = []
        self.estimated_cost: float = 0.0
        self.use_cache: bool = False
        self.parallel_execution: bool = False
        self.early_termination: bool = False
        self.filter_first: bool = False

    def explain(self) -> Dict[str, Any]:
        """Get execution plan explanation."""
        return {
            "original_query": self.original_query.original,
            "rewritten": self.rewritten_query.to_string() if self.rewritten_query else None,
            "optimizations": self.optimizations,
            "estimated_cost": self.estimated_cost,
            "use_cache": self.use_cache,
            "parallel_execution": self.parallel_execution,
            "early_termination": self.early_termination,
            "filter_first": self.filter_first,
        }


class QueryRewriter:
    """Rewrites queries for optimization.

    Applies various transformations to improve query performance.
    """

    def rewrite(self, query: QueryNode) -> QueryNode:
        """Rewrite query for optimization.

        Args:
            query: Original query

        Returns:
            Rewritten query
        """
        # Flatten nested boolean queries
        if isinstance(query, BooleanQuery):
            query = self._flatten_boolean(query)

        # Simplify single-clause booleans
        if isinstance(query, BooleanQuery):
            query = self._simplify_boolean(query)

        # Expand fuzzy queries (optional)
        # query = self._expand_fuzzy(query)

        return query

    def _flatten_boolean(self, query: BooleanQuery) -> BooleanQuery:
        """Flatten nested boolean queries of same type."""
        new_must = []
        new_should = []
        new_must_not = []

        for clause in query.must:
            if isinstance(clause, BooleanQuery) and clause.should == [] and clause.must_not == []:
                # Flatten nested AND
                new_must.extend(clause.must)
            else:
                new_must.append(clause)

        for clause in query.should:
            if isinstance(clause, BooleanQuery) and clause.must == [] and clause.must_not == []:
                # Flatten nested OR
                new_should.extend(clause.should)
            else:
                new_should.append(clause)

        new_must_not.extend(query.must_not)

        return BooleanQuery(
            must=new_must,
            should=new_should,
            must_not=new_must_not,
            minimum_should_match=query.minimum_should_match,
        )

    def _simplify_boolean(self, query: BooleanQuery) -> QueryNode:
        """Simplify single-clause boolean queries."""
        total_clauses = len(query.must) + len(query.should) + len(query.must_not)

        if total_clauses == 1:
            if query.must:
                return query.must[0]
            if query.should:
                return query.should[0]

        return query


class QueryOptimizer:
    """Optimizes query execution.

    Analyzes queries and applies optimizations for better performance.
    """

    def __init__(
        self,
        enable_caching: bool = True,
        enable_early_termination: bool = True,
    ):
        """Initialize optimizer.

        Args:
            enable_caching: Enable result caching
            enable_early_termination: Enable early termination
        """
        self.enable_caching = enable_caching
        self.enable_early_termination = enable_early_termination
        self._rewriter = QueryRewriter()

    def create_plan(
        self,
        query: ParsedQuery,
        context: QueryContext,
    ) -> ExecutionPlan:
        """Create execution plan for query.

        Args:
            query: Parsed query
            context: Execution context

        Returns:
            Execution plan
        """
        plan = ExecutionPlan(query)

        # Rewrite query
        plan.rewritten_query = self._rewriter.rewrite(query.root)
        if plan.rewritten_query != query.root:
            plan.optimizations.append("query_rewrite")

        # Check for cacheable query
        if self.enable_caching and self._is_cacheable(query):
            plan.use_cache = True
            plan.optimizations.append("use_cache")

        # Check for early termination
        if self.enable_early_termination and not context.track_total_hits:
            if context.limit < 100:
                plan.early_termination = True
                plan.optimizations.append("early_termination")

        # Estimate cost
        plan.estimated_cost = self._estimate_cost(query)

        # Check for parallel execution
        if isinstance(query.root, BooleanQuery):
            if len(query.root.should) > 2:
                plan.parallel_execution = True
                plan.optimizations.append("parallel_execution")

        return plan

    def _is_cacheable(self, query: ParsedQuery) -> bool:
        """Check if query results can be cached."""
        # Don't cache wildcard or fuzzy queries
        return not (query.has_wildcard or query.has_fuzzy)

    def _estimate_cost(self, query: ParsedQuery) -> float:
        """Estimate query execution cost."""
        cost = 1.0

        # Phrase queries are more expensive
        if query.has_phrase:
            cost *= 2.0

        # Wildcard queries are expensive
        if query.has_wildcard:
            cost *= 5.0

        # Fuzzy queries are expensive
        if query.has_fuzzy:
            cost *= 3.0

        # Boolean queries scale with clauses
        if query.has_boolean:
            cost *= 1.5

        return cost


class DocumentCollector:
    """Collects matching documents.

    Efficiently collects documents matching a query with optional
    early termination and score tracking.
    """

    def __init__(
        self,
        context: QueryContext,
        capacity: int = 10000,
    ):
        """Initialize collector.

        Args:
            context: Query context
            capacity: Maximum documents to collect
        """
        self.context = context
        self.capacity = capacity
        self._heap: List[ScoredDocument] = []
        self._total_hits = 0
        self._min_score = float("-inf")

    def collect(self, doc_id: str, score: float) -> bool:
        """Collect a document.

        Args:
            doc_id: Document ID
            score: Document score

        Returns:
            True if collected
        """
        self._total_hits += 1

        # Check min score
        if self.context.min_score and score < self.context.min_score:
            return False

        # Check if we should add to heap
        if len(self._heap) < self.capacity:
            heapq.heappush(self._heap, ScoredDocument(doc_id, score))
            if len(self._heap) == self.capacity:
                self._min_score = self._heap[0].score
            return True
        elif score > self._min_score:
            heapq.heapreplace(self._heap, ScoredDocument(doc_id, score))
            self._min_score = self._heap[0].score
            return True

        return False

    def get_results(self) -> List[ScoredDocument]:
        """Get collected results sorted by score."""
        # Sort by score descending
        results = sorted(self._heap, key=lambda x: x.score, reverse=True)

        # Apply pagination
        start = self.context.offset
        end = start + self.context.limit
        return results[start:end]

    @property
    def total_hits(self) -> int:
        """Get total hits."""
        return self._total_hits


class QueryExecutor:
    """Executes queries against the index.

    The main query execution engine that coordinates all aspects
    of query processing.
    """

    def __init__(
        self,
        index_reader: Any = None,
        scorer: Any = None,
    ):
        """Initialize executor.

        Args:
            index_reader: Index reader for accessing index
            scorer: Scorer for relevance scoring
        """
        self._index_reader = index_reader
        self._scorer = scorer
        self._optimizer = QueryOptimizer()
        self._cache: Dict[str, List[ScoredDocument]] = {}
        self._cache_lock = threading.RLock()

    def execute(
        self,
        query: ParsedQuery,
        context: Optional[QueryContext] = None,
    ) -> Tuple[List[ScoredDocument], ExecutionStats]:
        """Execute a query.

        Args:
            query: Parsed query
            context: Execution context

        Returns:
            (results, stats)
        """
        context = context or QueryContext()
        stats = ExecutionStats()

        # Create execution plan
        plan_start = time.time()
        plan = self._optimizer.create_plan(query, context)
        stats.add_phase_time(ExecutionPhase.OPTIMIZE, (time.time() - plan_start) * 1000)

        # Check cache
        if plan.use_cache:
            cache_key = query.original
            with self._cache_lock:
                if cache_key in self._cache:
                    logger.debug(f"Cache hit for query: {query.original}")
                    return self._cache[cache_key], stats

        # Execute query
        collect_start = time.time()
        collector = DocumentCollector(context)

        try:
            self._execute_node(
                plan.rewritten_query or query.root,
                collector,
                context,
                stats,
            )
        except TimeoutError:
            logger.warning(f"Query timed out: {query.original}")

        stats.add_phase_time(ExecutionPhase.COLLECT, (time.time() - collect_start) * 1000)
        stats.total_hits = collector.total_hits
        stats.collected_hits = len(collector._heap)

        # Get results
        results = collector.get_results()
        stats.scored_hits = len(results)

        # Cache results
        if plan.use_cache:
            with self._cache_lock:
                self._cache[query.original] = results

        return results, stats

    def _execute_node(
        self,
        node: QueryNode,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute a query node.

        Args:
            node: Query node
            collector: Document collector
            context: Execution context
            stats: Execution stats
        """
        if context.is_timed_out():
            raise TimeoutError("Query timeout")

        if isinstance(node, MatchAllQuery):
            self._execute_match_all(collector, context, stats)
        elif isinstance(node, MatchNoneQuery):
            pass  # No documents match
        elif isinstance(node, TermQuery):
            self._execute_term(node, collector, context, stats)
        elif isinstance(node, PhraseQuery):
            self._execute_phrase(node, collector, context, stats)
        elif isinstance(node, BooleanQuery):
            self._execute_boolean(node, collector, context, stats)
        elif isinstance(node, RangeQuery):
            self._execute_range(node, collector, context, stats)
        elif isinstance(node, WildcardQuery):
            self._execute_wildcard(node, collector, context, stats)
        elif isinstance(node, FuzzyQuery):
            self._execute_fuzzy(node, collector, context, stats)
        else:
            logger.warning(f"Unknown query type: {type(node)}")

    def _execute_match_all(
        self,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute match all query."""
        if not self._index_reader:
            return

        # Iterate all documents
        # In real implementation, iterate through all doc IDs
        pass

    def _execute_term(
        self,
        query: TermQuery,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute term query."""
        if not self._index_reader:
            return

        field = query.field or "_all"
        term = query.term

        # Get posting list and score documents
        # In real implementation, get postings from index
        stats.terms_matched += 1

    def _execute_phrase(
        self,
        query: PhraseQuery,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute phrase query."""
        if not self._index_reader:
            return

        field = query.field or "_all"
        terms = query.terms
        slop = query.slop

        # Find documents containing phrase
        # In real implementation, use positional matching
        stats.terms_matched += len(terms)

    def _execute_boolean(
        self,
        query: BooleanQuery,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute boolean query."""
        # Collect from must clauses (AND)
        must_docs: Optional[Set[str]] = None
        for clause in query.must:
            clause_collector = DocumentCollector(context)
            self._execute_node(clause, clause_collector, context, stats)

            clause_docs = {d.doc_id for d in clause_collector._heap}
            if must_docs is None:
                must_docs = clause_docs
            else:
                must_docs &= clause_docs

        # Collect from should clauses (OR)
        should_docs: Dict[str, float] = {}
        for clause in query.should:
            clause_collector = DocumentCollector(context)
            self._execute_node(clause, clause_collector, context, stats)

            for doc in clause_collector._heap:
                if doc.doc_id in should_docs:
                    should_docs[doc.doc_id] += doc.score
                else:
                    should_docs[doc.doc_id] = doc.score

        # Collect from must_not clauses (NOT)
        must_not_docs: Set[str] = set()
        for clause in query.must_not:
            clause_collector = DocumentCollector(context)
            self._execute_node(clause, clause_collector, context, stats)
            must_not_docs.update(d.doc_id for d in clause_collector._heap)

        # Combine results
        if must_docs is not None:
            # AND semantics
            for doc_id in must_docs:
                if doc_id not in must_not_docs:
                    score = should_docs.get(doc_id, 0) + 1.0
                    collector.collect(doc_id, score * query.boost)
        elif should_docs:
            # OR semantics
            matched = 0
            for doc_id, score in should_docs.items():
                matched += 1
                if doc_id not in must_not_docs:
                    if matched >= query.minimum_should_match:
                        collector.collect(doc_id, score * query.boost)

    def _execute_range(
        self,
        query: RangeQuery,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute range query."""
        if not self._index_reader:
            return

        field = query.field or "_all"
        # In real implementation, iterate through range in index

    def _execute_wildcard(
        self,
        query: WildcardQuery,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute wildcard query."""
        if not self._index_reader:
            return

        field = query.field or "_all"
        pattern = query.pattern

        # In real implementation, match pattern against terms

    def _execute_fuzzy(
        self,
        query: FuzzyQuery,
        collector: DocumentCollector,
        context: QueryContext,
        stats: ExecutionStats,
    ) -> None:
        """Execute fuzzy query."""
        if not self._index_reader:
            return

        field = query.field or "_all"
        term = query.term
        fuzziness = query.fuzziness

        # In real implementation, find terms within edit distance

    def clear_cache(self) -> None:
        """Clear query result cache."""
        with self._cache_lock:
            self._cache.clear()

    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        with self._cache_lock:
            return {
                "entries": len(self._cache),
                "keys": list(self._cache.keys())[:10],  # First 10 keys
            }


__all__ = [
    "QueryExecutor",
    "ExecutionPlan",
    "QueryContext",
    "ExecutionStats",
    "ScoredDocument",
    "DocumentCollector",
    "QueryOptimizer",
    "QueryRewriter",
    "ExecutionPhase",
]
