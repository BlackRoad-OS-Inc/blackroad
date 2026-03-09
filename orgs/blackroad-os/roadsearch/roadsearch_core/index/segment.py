"""RoadSearch Segment Management - Index Segment Handling.

Segments are immutable chunks of the index that are periodically
merged for optimal query performance.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import heapq
import logging
import os
import threading
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Dict, Generator, List, Optional, Set, Tuple

from roadsearch_core.index.inverted import InvertedIndex, PostingList, Term
from roadsearch_core.index.document import DocumentStore, StoredDocument

logger = logging.getLogger(__name__)


class SegmentState(Enum):
    """Segment state enumeration."""

    BUILDING = auto()  # Accepting new documents
    SEALED = auto()  # No more documents, not yet flushed
    FLUSHING = auto()  # Being written to disk
    COMMITTED = auto()  # Fully persistent
    MERGING = auto()  # Being merged
    DELETED = auto()  # Marked for deletion


@dataclass
class SegmentInfo:
    """Metadata about a segment.

    Attributes:
        segment_id: Unique segment identifier
        name: Human-readable segment name
        generation: Segment generation (increases on merge)
        doc_count: Number of documents
        deleted_count: Number of deleted documents
        size_bytes: Segment size in bytes
        created_at: Creation timestamp
        committed_at: Commit timestamp
        state: Current segment state
        min_version: Minimum document version
        max_version: Maximum document version
        fields: Fields in this segment
    """

    segment_id: str
    name: str = ""
    generation: int = 0
    doc_count: int = 0
    deleted_count: int = 0
    size_bytes: int = 0
    created_at: datetime = field(default_factory=datetime.now)
    committed_at: Optional[datetime] = None
    state: SegmentState = SegmentState.BUILDING
    min_version: int = 0
    max_version: int = 0
    fields: Set[str] = field(default_factory=set)
    source_segments: List[str] = field(default_factory=list)  # For merged segments

    def __post_init__(self):
        """Generate name if not provided."""
        if not self.name:
            self.name = f"seg_{self.segment_id[:8]}"

    @property
    def live_doc_count(self) -> int:
        """Get live (non-deleted) document count."""
        return self.doc_count - self.deleted_count

    @property
    def delete_ratio(self) -> float:
        """Get deletion ratio."""
        return self.deleted_count / self.doc_count if self.doc_count > 0 else 0

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "segment_id": self.segment_id,
            "name": self.name,
            "generation": self.generation,
            "doc_count": self.doc_count,
            "deleted_count": self.deleted_count,
            "size_bytes": self.size_bytes,
            "created_at": self.created_at.isoformat(),
            "committed_at": self.committed_at.isoformat() if self.committed_at else None,
            "state": self.state.name,
            "min_version": self.min_version,
            "max_version": self.max_version,
            "fields": list(self.fields),
            "source_segments": self.source_segments,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "SegmentInfo":
        """Create from dictionary."""
        return cls(
            segment_id=data["segment_id"],
            name=data.get("name", ""),
            generation=data.get("generation", 0),
            doc_count=data.get("doc_count", 0),
            deleted_count=data.get("deleted_count", 0),
            size_bytes=data.get("size_bytes", 0),
            created_at=datetime.fromisoformat(data["created_at"]) if "created_at" in data else datetime.now(),
            committed_at=datetime.fromisoformat(data["committed_at"]) if data.get("committed_at") else None,
            state=SegmentState[data.get("state", "BUILDING")],
            min_version=data.get("min_version", 0),
            max_version=data.get("max_version", 0),
            fields=set(data.get("fields", [])),
            source_segments=data.get("source_segments", []),
        )


class Segment:
    """A segment of the search index.

    Each segment contains a portion of the indexed documents
    and has its own inverted index.
    """

    def __init__(
        self,
        segment_id: Optional[str] = None,
        directory: Optional[str] = None,
    ):
        """Initialize segment.

        Args:
            segment_id: Unique segment ID
            directory: Storage directory
        """
        self.segment_id = segment_id or str(uuid.uuid4())
        self.directory = directory

        self.info = SegmentInfo(segment_id=self.segment_id)
        self._inverted_indices: Dict[str, InvertedIndex] = {}
        self._doc_ids: Set[str] = set()
        self._deleted_docs: Set[str] = set()
        self._lock = threading.RLock()

        # Create storage directory if specified
        if directory:
            os.makedirs(directory, exist_ok=True)

    def add_document(
        self,
        doc_id: str,
        fields: Dict[str, List[Tuple[str, int, int]]],  # field -> tokens
        version: int = 0,
    ) -> bool:
        """Add a document to the segment.

        Args:
            doc_id: Document ID
            fields: Field tokens (field -> list of (token, position, offset))
            version: Document version

        Returns:
            True if added successfully
        """
        with self._lock:
            if self.info.state != SegmentState.BUILDING:
                logger.warning(f"Cannot add to segment in state {self.info.state}")
                return False

            for field_name, tokens in fields.items():
                # Get or create inverted index for field
                if field_name not in self._inverted_indices:
                    self._inverted_indices[field_name] = InvertedIndex(field_name)
                    self.info.fields.add(field_name)

                # Index tokens
                self._inverted_indices[field_name].index_document(doc_id, tokens)

            # Update metadata
            self._doc_ids.add(doc_id)
            self.info.doc_count = len(self._doc_ids)
            self.info.max_version = max(self.info.max_version, version)
            if self.info.min_version == 0:
                self.info.min_version = version

            return True

    def delete_document(self, doc_id: str) -> bool:
        """Mark document as deleted.

        Args:
            doc_id: Document ID

        Returns:
            True if document was in segment
        """
        with self._lock:
            if doc_id not in self._doc_ids:
                return False

            self._deleted_docs.add(doc_id)
            self.info.deleted_count = len(self._deleted_docs)

            # Mark in inverted indices
            for index in self._inverted_indices.values():
                index.delete_document(doc_id)

            return True

    def seal(self) -> None:
        """Seal segment to prevent further modifications."""
        with self._lock:
            if self.info.state == SegmentState.BUILDING:
                self.info.state = SegmentState.SEALED

    def get_inverted_index(self, field: str) -> Optional[InvertedIndex]:
        """Get inverted index for field.

        Args:
            field: Field name

        Returns:
            InvertedIndex or None
        """
        return self._inverted_indices.get(field)

    def get_posting_list(self, field: str, term: str) -> Optional[PostingList]:
        """Get posting list for term in field.

        Args:
            field: Field name
            term: Term text

        Returns:
            PostingList or None
        """
        index = self._inverted_indices.get(field)
        if index:
            return index.get_posting_list(term)
        return None

    def contains(self, doc_id: str) -> bool:
        """Check if segment contains document.

        Args:
            doc_id: Document ID

        Returns:
            True if document is in segment and not deleted
        """
        return doc_id in self._doc_ids and doc_id not in self._deleted_docs

    def doc_ids(self) -> Set[str]:
        """Get all live document IDs."""
        return self._doc_ids - self._deleted_docs

    def get_stats(self) -> Dict[str, Any]:
        """Get segment statistics."""
        return {
            **self.info.to_dict(),
            "fields": {
                field: index.get_stats()
                for field, index in self._inverted_indices.items()
            },
        }


class SegmentMergePolicy:
    """Policy for segment merge decisions.

    Determines when and which segments should be merged.
    """

    def __init__(
        self,
        merge_factor: int = 10,
        max_merge_size_mb: int = 500,
        max_segments: int = 100,
        delete_ratio_threshold: float = 0.3,
    ):
        """Initialize merge policy.

        Args:
            merge_factor: Target segments per level
            max_merge_size_mb: Maximum merged segment size
            max_segments: Maximum total segments
            delete_ratio_threshold: Merge segments above this delete ratio
        """
        self.merge_factor = merge_factor
        self.max_merge_size_bytes = max_merge_size_mb * 1024 * 1024
        self.max_segments = max_segments
        self.delete_ratio_threshold = delete_ratio_threshold

    def find_merges(
        self,
        segments: List[SegmentInfo],
    ) -> List[List[SegmentInfo]]:
        """Find segments that should be merged.

        Args:
            segments: Current segments

        Returns:
            List of segment groups to merge
        """
        merges = []

        # Filter eligible segments
        eligible = [
            s for s in segments
            if s.state == SegmentState.COMMITTED and s.live_doc_count > 0
        ]

        if not eligible:
            return merges

        # Sort by size
        eligible.sort(key=lambda s: s.size_bytes)

        # Group by size tier
        tiers: Dict[int, List[SegmentInfo]] = {}
        for seg in eligible:
            # Calculate tier based on size (log scale)
            tier = 0
            size = seg.size_bytes
            while size > 1024 * 1024:  # 1MB per tier
                size //= self.merge_factor
                tier += 1
            if tier not in tiers:
                tiers[tier] = []
            tiers[tier].append(seg)

        # Find merge candidates in each tier
        for tier, tier_segments in tiers.items():
            if len(tier_segments) >= self.merge_factor:
                # Merge oldest segments in tier
                to_merge = tier_segments[:self.merge_factor]
                total_size = sum(s.size_bytes for s in to_merge)

                if total_size <= self.max_merge_size_bytes:
                    merges.append(to_merge)

        # Also merge segments with high delete ratios
        high_delete = [
            s for s in eligible
            if s.delete_ratio >= self.delete_ratio_threshold
        ]
        if len(high_delete) >= 2:
            merges.append(high_delete[:self.merge_factor])

        return merges

    def should_force_merge(self, segments: List[SegmentInfo]) -> bool:
        """Check if force merge is needed.

        Args:
            segments: Current segments

        Returns:
            True if force merge needed
        """
        live_segments = [
            s for s in segments
            if s.state == SegmentState.COMMITTED
        ]
        return len(live_segments) > self.max_segments


class SegmentMerger:
    """Handles merging of segments.

    Merges multiple segments into a single optimized segment.
    """

    def __init__(
        self,
        policy: Optional[SegmentMergePolicy] = None,
    ):
        """Initialize merger.

        Args:
            policy: Merge policy
        """
        self.policy = policy or SegmentMergePolicy()
        self._running = False
        self._merge_lock = threading.Lock()

    def merge(
        self,
        segments: List[Segment],
        target_directory: Optional[str] = None,
    ) -> Segment:
        """Merge multiple segments into one.

        Args:
            segments: Segments to merge
            target_directory: Directory for merged segment

        Returns:
            Merged segment
        """
        with self._merge_lock:
            if not segments:
                raise ValueError("No segments to merge")

            logger.info(f"Merging {len(segments)} segments")

            # Create new segment
            merged = Segment(directory=target_directory)
            merged.info.generation = max(s.info.generation for s in segments) + 1
            merged.info.source_segments = [s.segment_id for s in segments]

            # Merge inverted indices
            all_fields: Set[str] = set()
            for seg in segments:
                all_fields.update(seg.info.fields)

            for field_name in all_fields:
                merged_index = InvertedIndex(field_name)

                for seg in segments:
                    source_index = seg.get_inverted_index(field_name)
                    if source_index:
                        merged_index.merge(source_index)

                merged._inverted_indices[field_name] = merged_index
                merged.info.fields.add(field_name)

            # Merge document IDs (excluding deleted)
            for seg in segments:
                merged._doc_ids.update(seg.doc_ids())

            # Update metadata
            merged.info.doc_count = len(merged._doc_ids)
            merged.info.deleted_count = 0  # Fresh segment has no deletes
            merged.info.min_version = min(s.info.min_version for s in segments)
            merged.info.max_version = max(s.info.max_version for s in segments)

            # Mark original segments for deletion
            for seg in segments:
                seg.info.state = SegmentState.DELETED

            # Seal and commit merged segment
            merged.seal()
            merged.info.state = SegmentState.COMMITTED
            merged.info.committed_at = datetime.now()

            logger.info(f"Merged segment created: {merged.segment_id} "
                       f"({merged.info.doc_count} docs)")

            return merged

    def optimize(
        self,
        segments: List[Segment],
        target_segments: int = 1,
        target_directory: Optional[str] = None,
    ) -> List[Segment]:
        """Optimize by merging down to target segment count.

        Args:
            segments: Segments to optimize
            target_segments: Target segment count
            target_directory: Directory for merged segments

        Returns:
            Optimized segments
        """
        current = list(segments)

        while len(current) > target_segments:
            # Merge pairs
            batch_size = min(self.policy.merge_factor, len(current))
            to_merge = current[:batch_size]
            remaining = current[batch_size:]

            merged = self.merge(to_merge, target_directory)
            current = [merged] + remaining

        return current


class SegmentReader:
    """Reads from multiple segments as a unified view.

    Provides a unified interface for reading from multiple segments.
    """

    def __init__(self, segments: List[Segment]):
        """Initialize reader.

        Args:
            segments: Segments to read from
        """
        self._segments = [
            s for s in segments
            if s.info.state in (SegmentState.COMMITTED, SegmentState.SEALED)
        ]

    def get_posting_lists(
        self,
        field: str,
        term: str,
    ) -> List[Tuple[Segment, PostingList]]:
        """Get posting lists from all segments.

        Args:
            field: Field name
            term: Term text

        Returns:
            List of (segment, posting_list) tuples
        """
        results = []
        for segment in self._segments:
            pl = segment.get_posting_list(field, term)
            if pl:
                results.append((segment, pl))
        return results

    def get_document_frequency(self, field: str, term: str) -> int:
        """Get total document frequency across segments.

        Args:
            field: Field name
            term: Term text

        Returns:
            Total document frequency
        """
        total = 0
        for segment in self._segments:
            index = segment.get_inverted_index(field)
            if index:
                total += index.get_document_frequency(term)
        return total

    def get_total_documents(self) -> int:
        """Get total document count across segments."""
        return sum(s.info.live_doc_count for s in self._segments)

    def search(
        self,
        field: str,
        terms: List[str],
        conjunction: bool = True,
    ) -> Generator[Tuple[str, float], None, None]:
        """Search across all segments.

        Args:
            field: Field name
            terms: Search terms
            conjunction: True for AND, False for OR

        Yields:
            (doc_id, score) tuples
        """
        # Collect results from all segments
        doc_scores: Dict[str, float] = {}
        doc_term_counts: Dict[str, int] = {}

        for term in terms:
            for segment, pl in self.get_posting_lists(field, term):
                for posting in pl:
                    doc_id = posting.doc_id
                    if segment.contains(doc_id):
                        doc_scores[doc_id] = doc_scores.get(doc_id, 0) + posting.term_freq
                        doc_term_counts[doc_id] = doc_term_counts.get(doc_id, 0) + 1

        # Filter by conjunction
        if conjunction:
            for doc_id, score in doc_scores.items():
                if doc_term_counts.get(doc_id, 0) == len(terms):
                    yield doc_id, score
        else:
            for doc_id, score in doc_scores.items():
                yield doc_id, score


class SegmentWriter:
    """Writes to an active segment.

    Manages the currently active segment for indexing.
    """

    def __init__(
        self,
        directory: Optional[str] = None,
        max_docs_per_segment: int = 100000,
        max_size_mb: int = 100,
    ):
        """Initialize writer.

        Args:
            directory: Storage directory
            max_docs_per_segment: Maximum documents per segment
            max_size_mb: Maximum segment size in MB
        """
        self.directory = directory
        self.max_docs_per_segment = max_docs_per_segment
        self.max_size_bytes = max_size_mb * 1024 * 1024

        self._current_segment: Optional[Segment] = None
        self._segments: List[Segment] = []
        self._lock = threading.RLock()

    def _create_segment(self) -> Segment:
        """Create a new segment."""
        segment = Segment(directory=self.directory)
        self._segments.append(segment)
        return segment

    def get_current_segment(self) -> Segment:
        """Get current active segment."""
        with self._lock:
            if (self._current_segment is None or
                self._should_roll_segment(self._current_segment)):
                # Roll to new segment
                if self._current_segment:
                    self._current_segment.seal()
                self._current_segment = self._create_segment()

            return self._current_segment

    def _should_roll_segment(self, segment: Segment) -> bool:
        """Check if segment should be rolled."""
        if segment.info.doc_count >= self.max_docs_per_segment:
            return True
        if segment.info.size_bytes >= self.max_size_bytes:
            return True
        if segment.info.state != SegmentState.BUILDING:
            return True
        return False

    def add_document(
        self,
        doc_id: str,
        fields: Dict[str, List[Tuple[str, int, int]]],
        version: int = 0,
    ) -> bool:
        """Add document to current segment.

        Args:
            doc_id: Document ID
            fields: Field tokens
            version: Document version

        Returns:
            True if added successfully
        """
        segment = self.get_current_segment()
        return segment.add_document(doc_id, fields, version)

    def flush(self) -> List[Segment]:
        """Flush current segment and return all segments.

        Returns:
            All segments (including flushed current)
        """
        with self._lock:
            if self._current_segment:
                self._current_segment.seal()
                self._current_segment.info.state = SegmentState.COMMITTED
                self._current_segment.info.committed_at = datetime.now()
                self._current_segment = None

            return list(self._segments)

    def get_all_segments(self) -> List[Segment]:
        """Get all segments."""
        return list(self._segments)


__all__ = [
    "Segment",
    "SegmentInfo",
    "SegmentState",
    "SegmentMerger",
    "SegmentMergePolicy",
    "SegmentReader",
    "SegmentWriter",
]
