"""RoadSearch Vector Index - Approximate Nearest Neighbor Search.

Implements HNSW (Hierarchical Navigable Small World) for efficient
vector similarity search.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import heapq
import logging
import math
import random
import threading
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, Generator, List, Optional, Set, Tuple

logger = logging.getLogger(__name__)


class SimilarityMetric(Enum):
    """Vector similarity metrics."""

    COSINE = "cosine"
    DOT_PRODUCT = "dot_product"
    EUCLIDEAN = "euclidean"
    MANHATTAN = "manhattan"


@dataclass
class Vector:
    """A vector with associated metadata.

    Attributes:
        id: Vector identifier
        data: Vector data
        metadata: Associated metadata
    """

    id: str
    data: List[float]
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __len__(self) -> int:
        """Return vector dimension."""
        return len(self.data)

    def __getitem__(self, index: int) -> float:
        """Get element by index."""
        return self.data[index]

    def norm(self) -> float:
        """Calculate L2 norm."""
        return math.sqrt(sum(x * x for x in self.data))

    def normalize(self) -> "Vector":
        """Return normalized vector."""
        n = self.norm()
        if n == 0:
            return self
        return Vector(
            id=self.id,
            data=[x / n for x in self.data],
            metadata=self.metadata,
        )


@dataclass
class VectorSearchResult:
    """Result from vector search.

    Attributes:
        id: Vector ID
        score: Similarity score
        vector: Original vector
        distance: Distance value
    """

    id: str
    score: float
    vector: Optional[Vector] = None
    distance: float = 0.0

    def __lt__(self, other: "VectorSearchResult") -> bool:
        """Compare by score for heap operations."""
        return self.score < other.score


class VectorIndex:
    """Base class for vector indices.

    Provides efficient nearest neighbor search in high-dimensional space.
    """

    def __init__(
        self,
        dimensions: int,
        metric: SimilarityMetric = SimilarityMetric.COSINE,
    ):
        """Initialize vector index.

        Args:
            dimensions: Vector dimensions
            metric: Similarity metric
        """
        self.dimensions = dimensions
        self.metric = metric
        self._vectors: Dict[str, Vector] = {}
        self._lock = threading.RLock()

    def add(self, vector: Vector) -> bool:
        """Add vector to index.

        Args:
            vector: Vector to add

        Returns:
            True if added
        """
        if len(vector.data) != self.dimensions:
            logger.error(f"Dimension mismatch: {len(vector.data)} != {self.dimensions}")
            return False

        with self._lock:
            self._vectors[vector.id] = vector
            return True

    def remove(self, vector_id: str) -> bool:
        """Remove vector from index.

        Args:
            vector_id: Vector ID

        Returns:
            True if removed
        """
        with self._lock:
            if vector_id in self._vectors:
                del self._vectors[vector_id]
                return True
            return False

    def get(self, vector_id: str) -> Optional[Vector]:
        """Get vector by ID.

        Args:
            vector_id: Vector ID

        Returns:
            Vector or None
        """
        return self._vectors.get(vector_id)

    def search(
        self,
        query: List[float],
        k: int = 10,
        filter_fn: Optional[Callable[[Vector], bool]] = None,
    ) -> List[VectorSearchResult]:
        """Search for nearest neighbors.

        Args:
            query: Query vector
            k: Number of results
            filter_fn: Optional filter function

        Returns:
            List of search results
        """
        if len(query) != self.dimensions:
            logger.error(f"Query dimension mismatch: {len(query)} != {self.dimensions}")
            return []

        results = []
        for vector in self._vectors.values():
            if filter_fn and not filter_fn(vector):
                continue

            distance = self._calculate_distance(query, vector.data)
            score = self._distance_to_score(distance)

            results.append(VectorSearchResult(
                id=vector.id,
                score=score,
                vector=vector,
                distance=distance,
            ))

        # Sort by score descending
        results.sort(key=lambda x: x.score, reverse=True)
        return results[:k]

    def _calculate_distance(
        self,
        a: List[float],
        b: List[float],
    ) -> float:
        """Calculate distance between vectors."""
        if self.metric == SimilarityMetric.COSINE:
            return self._cosine_distance(a, b)
        elif self.metric == SimilarityMetric.DOT_PRODUCT:
            return -self._dot_product(a, b)  # Negative for distance
        elif self.metric == SimilarityMetric.EUCLIDEAN:
            return self._euclidean_distance(a, b)
        elif self.metric == SimilarityMetric.MANHATTAN:
            return self._manhattan_distance(a, b)
        return 0.0

    def _cosine_distance(self, a: List[float], b: List[float]) -> float:
        """Calculate cosine distance."""
        dot = sum(x * y for x, y in zip(a, b))
        norm_a = math.sqrt(sum(x * x for x in a))
        norm_b = math.sqrt(sum(x * x for x in b))
        if norm_a == 0 or norm_b == 0:
            return 1.0
        similarity = dot / (norm_a * norm_b)
        return 1.0 - similarity

    def _dot_product(self, a: List[float], b: List[float]) -> float:
        """Calculate dot product."""
        return sum(x * y for x, y in zip(a, b))

    def _euclidean_distance(self, a: List[float], b: List[float]) -> float:
        """Calculate Euclidean distance."""
        return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))

    def _manhattan_distance(self, a: List[float], b: List[float]) -> float:
        """Calculate Manhattan distance."""
        return sum(abs(x - y) for x, y in zip(a, b))

    def _distance_to_score(self, distance: float) -> float:
        """Convert distance to similarity score."""
        if self.metric in (SimilarityMetric.COSINE, SimilarityMetric.EUCLIDEAN, SimilarityMetric.MANHATTAN):
            return 1.0 / (1.0 + distance)
        elif self.metric == SimilarityMetric.DOT_PRODUCT:
            return -distance  # Was negated in distance calculation
        return 0.0

    def __len__(self) -> int:
        """Return number of vectors."""
        return len(self._vectors)


class HNSWNode:
    """Node in HNSW graph."""

    def __init__(
        self,
        vector_id: str,
        max_level: int,
    ):
        """Initialize node.

        Args:
            vector_id: Associated vector ID
            max_level: Maximum level in graph
        """
        self.vector_id = vector_id
        self.max_level = max_level
        # Neighbors at each level: level -> [neighbor_ids]
        self.neighbors: Dict[int, List[str]] = {i: [] for i in range(max_level + 1)}


class HNSWIndex(VectorIndex):
    """HNSW (Hierarchical Navigable Small World) index.

    Efficient approximate nearest neighbor search using a hierarchical
    graph structure for O(log N) search complexity.
    """

    def __init__(
        self,
        dimensions: int,
        metric: SimilarityMetric = SimilarityMetric.COSINE,
        M: int = 16,  # Maximum connections per layer
        ef_construction: int = 200,  # Construction beam width
        ef_search: int = 50,  # Search beam width
        ml: float = 1.0 / math.log(16),  # Level multiplier
    ):
        """Initialize HNSW index.

        Args:
            dimensions: Vector dimensions
            metric: Similarity metric
            M: Maximum connections per layer
            ef_construction: Construction beam width
            ef_search: Search beam width
            ml: Level multiplier
        """
        super().__init__(dimensions, metric)
        self.M = M
        self.M0 = M * 2  # Max connections at level 0
        self.ef_construction = ef_construction
        self.ef_search = ef_search
        self.ml = ml

        self._nodes: Dict[str, HNSWNode] = {}
        self._entry_point: Optional[str] = None
        self._max_level = 0

    def _get_random_level(self) -> int:
        """Generate random level for new node."""
        level = 0
        while random.random() < self.ml and level < 32:
            level += 1
        return level

    def add(self, vector: Vector) -> bool:
        """Add vector to HNSW index."""
        if len(vector.data) != self.dimensions:
            logger.error(f"Dimension mismatch: {len(vector.data)} != {self.dimensions}")
            return False

        with self._lock:
            # Store vector
            self._vectors[vector.id] = vector

            # Get random level
            level = self._get_random_level()

            # Create node
            node = HNSWNode(vector.id, level)
            self._nodes[vector.id] = node

            # First vector
            if self._entry_point is None:
                self._entry_point = vector.id
                self._max_level = level
                return True

            # Find entry point at top level
            curr = self._entry_point
            curr_dist = self._calculate_distance(
                vector.data,
                self._vectors[curr].data,
            )

            # Descend from top level to level+1
            for lev in range(self._max_level, level, -1):
                changed = True
                while changed:
                    changed = False
                    curr_node = self._nodes[curr]
                    for neighbor_id in curr_node.neighbors.get(lev, []):
                        neighbor_dist = self._calculate_distance(
                            vector.data,
                            self._vectors[neighbor_id].data,
                        )
                        if neighbor_dist < curr_dist:
                            curr = neighbor_id
                            curr_dist = neighbor_dist
                            changed = True

            # Insert at each level
            for lev in range(min(level, self._max_level), -1, -1):
                # Find neighbors at this level
                neighbors = self._search_layer(vector.data, curr, self.ef_construction, lev)

                # Select M best neighbors
                max_neighbors = self.M if lev > 0 else self.M0
                selected = neighbors[:max_neighbors]

                # Add bidirectional edges
                node.neighbors[lev] = [n.id for n in selected]
                for neighbor in selected:
                    neighbor_node = self._nodes[neighbor.id]
                    if len(neighbor_node.neighbors[lev]) < max_neighbors:
                        neighbor_node.neighbors[lev].append(vector.id)
                    else:
                        # Prune neighbors
                        all_neighbors = neighbor_node.neighbors[lev] + [vector.id]
                        neighbor_node.neighbors[lev] = self._select_neighbors(
                            neighbor.id,
                            all_neighbors,
                            max_neighbors,
                        )

                if selected:
                    curr = selected[0].id
                    curr_dist = self._calculate_distance(
                        vector.data,
                        self._vectors[curr].data,
                    )

            # Update entry point if needed
            if level > self._max_level:
                self._entry_point = vector.id
                self._max_level = level

            return True

    def _search_layer(
        self,
        query: List[float],
        entry_id: str,
        ef: int,
        level: int,
    ) -> List[VectorSearchResult]:
        """Search at a single layer."""
        visited: Set[str] = {entry_id}
        candidates: List[Tuple[float, str]] = []  # (distance, id)
        results: List[Tuple[float, str]] = []  # (distance, id)

        entry_dist = self._calculate_distance(query, self._vectors[entry_id].data)
        heapq.heappush(candidates, (entry_dist, entry_id))
        heapq.heappush(results, (-entry_dist, entry_id))

        while candidates:
            dist, curr = heapq.heappop(candidates)

            # Check if we can stop
            if results and dist > -results[0][0]:
                break

            # Explore neighbors
            curr_node = self._nodes.get(curr)
            if not curr_node:
                continue

            for neighbor_id in curr_node.neighbors.get(level, []):
                if neighbor_id in visited:
                    continue
                visited.add(neighbor_id)

                neighbor_vec = self._vectors.get(neighbor_id)
                if not neighbor_vec:
                    continue

                neighbor_dist = self._calculate_distance(query, neighbor_vec.data)

                if len(results) < ef or neighbor_dist < -results[0][0]:
                    heapq.heappush(candidates, (neighbor_dist, neighbor_id))
                    heapq.heappush(results, (-neighbor_dist, neighbor_id))

                    if len(results) > ef:
                        heapq.heappop(results)

        # Convert to results
        return [
            VectorSearchResult(
                id=vid,
                score=self._distance_to_score(-dist),
                distance=-dist,
            )
            for dist, vid in sorted(results, reverse=True)
        ]

    def _select_neighbors(
        self,
        vector_id: str,
        neighbor_ids: List[str],
        max_neighbors: int,
    ) -> List[str]:
        """Select best neighbors."""
        vector = self._vectors[vector_id]
        scored = []

        for neighbor_id in neighbor_ids:
            if neighbor_id == vector_id:
                continue
            neighbor = self._vectors.get(neighbor_id)
            if neighbor:
                dist = self._calculate_distance(vector.data, neighbor.data)
                scored.append((dist, neighbor_id))

        scored.sort(key=lambda x: x[0])
        return [n[1] for n in scored[:max_neighbors]]

    def search(
        self,
        query: List[float],
        k: int = 10,
        filter_fn: Optional[Callable[[Vector], bool]] = None,
    ) -> List[VectorSearchResult]:
        """Search for nearest neighbors using HNSW."""
        if len(query) != self.dimensions:
            logger.error(f"Query dimension mismatch: {len(query)} != {self.dimensions}")
            return []

        if not self._entry_point:
            return []

        with self._lock:
            # Start from entry point
            curr = self._entry_point
            curr_dist = self._calculate_distance(query, self._vectors[curr].data)

            # Descend through layers
            for level in range(self._max_level, 0, -1):
                changed = True
                while changed:
                    changed = False
                    curr_node = self._nodes[curr]
                    for neighbor_id in curr_node.neighbors.get(level, []):
                        neighbor_dist = self._calculate_distance(
                            query,
                            self._vectors[neighbor_id].data,
                        )
                        if neighbor_dist < curr_dist:
                            curr = neighbor_id
                            curr_dist = neighbor_dist
                            changed = True

            # Search at level 0
            results = self._search_layer(query, curr, max(self.ef_search, k), 0)

            # Apply filter if provided
            if filter_fn:
                results = [
                    r for r in results
                    if filter_fn(self._vectors[r.id])
                ]

            # Add vectors to results
            for result in results:
                result.vector = self._vectors.get(result.id)

            return results[:k]

    def get_stats(self) -> Dict[str, Any]:
        """Get index statistics."""
        level_counts = {}
        for node in self._nodes.values():
            level = node.max_level
            level_counts[level] = level_counts.get(level, 0) + 1

        return {
            "vectors": len(self._vectors),
            "nodes": len(self._nodes),
            "max_level": self._max_level,
            "entry_point": self._entry_point,
            "M": self.M,
            "ef_construction": self.ef_construction,
            "ef_search": self.ef_search,
            "level_distribution": level_counts,
        }


__all__ = [
    "VectorIndex",
    "HNSWIndex",
    "Vector",
    "VectorSearchResult",
    "SimilarityMetric",
]
