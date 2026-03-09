"""RoadSearch Inverted Index - Core Full-Text Index Implementation.

The inverted index maps terms to their occurrences in documents,
enabling efficient full-text search operations.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import bisect
import hashlib
import logging
import mmap
import os
import pickle
import struct
import threading
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import (
    Any,
    BinaryIO,
    Callable,
    Dict,
    Generator,
    Iterator,
    List,
    Optional,
    Set,
    Tuple,
    Union,
)

logger = logging.getLogger(__name__)


class TermType(Enum):
    """Term type classification."""

    TEXT = auto()
    NUMERIC = auto()
    DATE = auto()
    GEO = auto()
    BINARY = auto()


class TermFlags(Enum):
    """Term metadata flags."""

    POSITIONS = 0x01  # Store positions
    OFFSETS = 0x02  # Store character offsets
    PAYLOADS = 0x04  # Store custom payloads
    FREQUENCIES = 0x08  # Store term frequencies


@dataclass
class Term:
    """A term in the index.

    Attributes:
        text: Term text
        field: Field name
        doc_freq: Document frequency
        total_freq: Total term frequency across all docs
        term_type: Type of term
    """

    text: str
    field: str = ""
    doc_freq: int = 0
    total_freq: int = 0
    term_type: TermType = TermType.TEXT

    def __hash__(self) -> int:
        """Hash based on text and field."""
        return hash((self.text, self.field))

    def __eq__(self, other: object) -> bool:
        """Equality based on text and field."""
        if not isinstance(other, Term):
            return False
        return self.text == other.text and self.field == other.field

    def __lt__(self, other: "Term") -> bool:
        """Comparison for sorting."""
        if self.field != other.field:
            return self.field < other.field
        return self.text < other.text

    def to_bytes(self) -> bytes:
        """Serialize to bytes."""
        data = {
            "text": self.text,
            "field": self.field,
            "doc_freq": self.doc_freq,
            "total_freq": self.total_freq,
            "term_type": self.term_type.value,
        }
        return pickle.dumps(data)

    @classmethod
    def from_bytes(cls, data: bytes) -> "Term":
        """Deserialize from bytes."""
        obj = pickle.loads(data)
        return cls(
            text=obj["text"],
            field=obj["field"],
            doc_freq=obj["doc_freq"],
            total_freq=obj["total_freq"],
            term_type=TermType(obj["term_type"]),
        )


@dataclass
class Posting:
    """A posting (term occurrence) in a document.

    Attributes:
        doc_id: Document ID
        term_freq: Term frequency in document
        positions: List of term positions
        offsets: List of (start, end) character offsets
        payload: Custom payload data
        field_norm: Field length normalization
    """

    doc_id: str
    term_freq: int = 1
    positions: List[int] = field(default_factory=list)
    offsets: List[Tuple[int, int]] = field(default_factory=list)
    payload: Optional[bytes] = None
    field_norm: float = 1.0

    def __lt__(self, other: "Posting") -> bool:
        """Compare by doc_id for sorting."""
        return self.doc_id < other.doc_id

    def merge_with(self, other: "Posting") -> None:
        """Merge another posting into this one."""
        if self.doc_id != other.doc_id:
            raise ValueError("Cannot merge postings from different documents")
        self.term_freq += other.term_freq
        self.positions.extend(other.positions)
        self.positions.sort()
        self.offsets.extend(other.offsets)
        self.offsets.sort()

    def to_bytes(self) -> bytes:
        """Serialize to bytes."""
        return pickle.dumps({
            "doc_id": self.doc_id,
            "term_freq": self.term_freq,
            "positions": self.positions,
            "offsets": self.offsets,
            "payload": self.payload,
            "field_norm": self.field_norm,
        })

    @classmethod
    def from_bytes(cls, data: bytes) -> "Posting":
        """Deserialize from bytes."""
        obj = pickle.loads(data)
        return cls(**obj)


class PostingList:
    """A list of postings for a term.

    Optimized for both sequential and random access patterns.
    """

    def __init__(
        self,
        term: Term,
        postings: Optional[List[Posting]] = None,
    ):
        """Initialize posting list.

        Args:
            term: The term
            postings: Initial postings
        """
        self.term = term
        self._postings: List[Posting] = postings or []
        self._doc_index: Dict[str, int] = {}
        self._sorted = True
        self._rebuild_index()

    def _rebuild_index(self) -> None:
        """Rebuild document ID index."""
        self._doc_index = {p.doc_id: i for i, p in enumerate(self._postings)}

    def add(self, posting: Posting) -> None:
        """Add a posting.

        Args:
            posting: Posting to add
        """
        if posting.doc_id in self._doc_index:
            # Merge with existing posting
            idx = self._doc_index[posting.doc_id]
            self._postings[idx].merge_with(posting)
        else:
            self._postings.append(posting)
            self._doc_index[posting.doc_id] = len(self._postings) - 1
            self._sorted = False

        # Update term stats
        self.term.doc_freq = len(self._doc_index)
        self.term.total_freq = sum(p.term_freq for p in self._postings)

    def remove(self, doc_id: str) -> bool:
        """Remove posting for document.

        Args:
            doc_id: Document ID

        Returns:
            True if removed
        """
        if doc_id not in self._doc_index:
            return False

        idx = self._doc_index[doc_id]
        del self._postings[idx]
        self._rebuild_index()

        # Update term stats
        self.term.doc_freq = len(self._doc_index)
        self.term.total_freq = sum(p.term_freq for p in self._postings)

        return True

    def get(self, doc_id: str) -> Optional[Posting]:
        """Get posting for document.

        Args:
            doc_id: Document ID

        Returns:
            Posting or None
        """
        idx = self._doc_index.get(doc_id)
        if idx is not None:
            return self._postings[idx]
        return None

    def contains(self, doc_id: str) -> bool:
        """Check if document is in posting list.

        Args:
            doc_id: Document ID

        Returns:
            True if present
        """
        return doc_id in self._doc_index

    def sort(self) -> None:
        """Sort postings by document ID."""
        if not self._sorted:
            self._postings.sort()
            self._rebuild_index()
            self._sorted = True

    def __len__(self) -> int:
        """Return number of postings."""
        return len(self._postings)

    def __iter__(self) -> Iterator[Posting]:
        """Iterate over postings."""
        return iter(self._postings)

    def __getitem__(self, index: int) -> Posting:
        """Get posting by index."""
        return self._postings[index]

    def doc_ids(self) -> Set[str]:
        """Get all document IDs."""
        return set(self._doc_index.keys())

    def intersect(self, other: "PostingList") -> "PostingList":
        """Intersect with another posting list.

        Args:
            other: Other posting list

        Returns:
            New posting list with intersection
        """
        common_docs = self.doc_ids() & other.doc_ids()
        new_postings = [p for p in self._postings if p.doc_id in common_docs]

        # Create new term for intersection
        new_term = Term(
            text=f"({self.term.text} AND {other.term.text})",
            field=self.term.field,
        )
        return PostingList(new_term, new_postings)

    def union(self, other: "PostingList") -> "PostingList":
        """Union with another posting list.

        Args:
            other: Other posting list

        Returns:
            New posting list with union
        """
        result = PostingList(
            Term(
                text=f"({self.term.text} OR {other.term.text})",
                field=self.term.field,
            )
        )

        # Add all from self
        for posting in self._postings:
            result.add(posting)

        # Add all from other (will merge duplicates)
        for posting in other._postings:
            result.add(posting)

        return result

    def to_bytes(self) -> bytes:
        """Serialize to bytes."""
        return pickle.dumps({
            "term": self.term.to_bytes(),
            "postings": [p.to_bytes() for p in self._postings],
        })

    @classmethod
    def from_bytes(cls, data: bytes) -> "PostingList":
        """Deserialize from bytes."""
        obj = pickle.loads(data)
        term = Term.from_bytes(obj["term"])
        postings = [Posting.from_bytes(p) for p in obj["postings"]]
        return cls(term, postings)


class SkipList:
    """Skip list for fast posting list traversal.

    Enables O(sqrt(n)) access instead of O(n) for posting lists.
    """

    def __init__(
        self,
        posting_list: PostingList,
        skip_interval: int = 16,
    ):
        """Initialize skip list.

        Args:
            posting_list: Source posting list
            skip_interval: Interval between skip pointers
        """
        self._posting_list = posting_list
        self._skip_interval = skip_interval
        self._skip_pointers: List[Tuple[str, int]] = []  # (doc_id, index)
        self._build()

    def _build(self) -> None:
        """Build skip pointers."""
        self._skip_pointers = []
        for i in range(0, len(self._posting_list), self._skip_interval):
            doc_id = self._posting_list[i].doc_id
            self._skip_pointers.append((doc_id, i))

    def advance_to(self, target_doc_id: str) -> Optional[Posting]:
        """Advance to document >= target.

        Args:
            target_doc_id: Target document ID

        Returns:
            Posting or None
        """
        # Binary search skip pointers
        start_idx = 0
        for doc_id, idx in self._skip_pointers:
            if doc_id > target_doc_id:
                break
            start_idx = idx

        # Linear search from start position
        for i in range(start_idx, len(self._posting_list)):
            posting = self._posting_list[i]
            if posting.doc_id >= target_doc_id:
                return posting

        return None


class PostingListIterator:
    """Iterator over multiple posting lists with skip support."""

    def __init__(
        self,
        posting_lists: List[PostingList],
        conjunction: bool = True,
    ):
        """Initialize iterator.

        Args:
            posting_lists: Posting lists to iterate
            conjunction: True for AND, False for OR
        """
        self._lists = posting_lists
        self._conjunction = conjunction
        self._skip_lists = [SkipList(pl) for pl in posting_lists]
        self._positions = [0] * len(posting_lists)
        self._current: Optional[str] = None
        self._done = False

    def __iter__(self) -> "PostingListIterator":
        """Return iterator."""
        return self

    def __next__(self) -> Tuple[str, List[Posting]]:
        """Get next matching document.

        Returns:
            (doc_id, matching_postings)
        """
        if self._done:
            raise StopIteration

        if self._conjunction:
            return self._next_and()
        else:
            return self._next_or()

    def _next_and(self) -> Tuple[str, List[Posting]]:
        """Next document matching all terms (AND)."""
        if not self._lists:
            self._done = True
            raise StopIteration

        while True:
            # Find maximum current doc_id
            max_doc_id = None
            all_match = True

            for i, pos in enumerate(self._positions):
                if pos >= len(self._lists[i]):
                    self._done = True
                    raise StopIteration

                doc_id = self._lists[i][pos].doc_id
                if max_doc_id is None or doc_id > max_doc_id:
                    max_doc_id = doc_id

            # Advance all to max_doc_id
            for i in range(len(self._lists)):
                while (
                    self._positions[i] < len(self._lists[i]) and
                    self._lists[i][self._positions[i]].doc_id < max_doc_id
                ):
                    self._positions[i] += 1

                if self._positions[i] >= len(self._lists[i]):
                    self._done = True
                    raise StopIteration

                if self._lists[i][self._positions[i]].doc_id != max_doc_id:
                    all_match = False
                    break

            if all_match:
                # All lists at same doc_id
                postings = [
                    self._lists[i][self._positions[i]]
                    for i in range(len(self._lists))
                ]
                # Advance all positions
                for i in range(len(self._lists)):
                    self._positions[i] += 1
                return max_doc_id, postings

    def _next_or(self) -> Tuple[str, List[Posting]]:
        """Next document matching any term (OR)."""
        if not self._lists:
            self._done = True
            raise StopIteration

        # Find minimum current doc_id
        min_doc_id = None
        min_positions = []

        for i, pos in enumerate(self._positions):
            if pos >= len(self._lists[i]):
                continue

            doc_id = self._lists[i][pos].doc_id
            if min_doc_id is None or doc_id < min_doc_id:
                min_doc_id = doc_id
                min_positions = [i]
            elif doc_id == min_doc_id:
                min_positions.append(i)

        if min_doc_id is None:
            self._done = True
            raise StopIteration

        # Collect postings and advance
        postings = []
        for i in min_positions:
            postings.append(self._lists[i][self._positions[i]])
            self._positions[i] += 1

        return min_doc_id, postings


class TermDictionary:
    """Term dictionary with FST-like structure.

    Maps terms to posting list metadata for efficient lookup.
    """

    def __init__(self):
        """Initialize term dictionary."""
        self._terms: Dict[str, Dict[str, int]] = {}  # field -> term -> offset
        self._term_info: Dict[Tuple[str, str], Term] = {}  # (field, term) -> Term
        self._lock = threading.RLock()

    def add(self, term: Term, offset: int) -> None:
        """Add term to dictionary.

        Args:
            term: Term to add
            offset: Offset in posting data
        """
        with self._lock:
            if term.field not in self._terms:
                self._terms[term.field] = {}
            self._terms[term.field][term.text] = offset
            self._term_info[(term.field, term.text)] = term

    def get(self, field: str, text: str) -> Optional[Tuple[Term, int]]:
        """Get term and offset.

        Args:
            field: Field name
            text: Term text

        Returns:
            (Term, offset) or None
        """
        with self._lock:
            if field not in self._terms or text not in self._terms[field]:
                return None
            offset = self._terms[field][text]
            term = self._term_info.get((field, text))
            return (term, offset) if term else None

    def prefix_search(
        self,
        field: str,
        prefix: str,
        limit: int = 100,
    ) -> List[Term]:
        """Search for terms by prefix.

        Args:
            field: Field name
            prefix: Term prefix
            limit: Maximum results

        Returns:
            Matching terms
        """
        with self._lock:
            if field not in self._terms:
                return []

            results = []
            for term_text in sorted(self._terms[field].keys()):
                if term_text.startswith(prefix):
                    term = self._term_info.get((field, term_text))
                    if term:
                        results.append(term)
                        if len(results) >= limit:
                            break
                elif term_text > prefix + "~":  # Past possible matches
                    break

            return results

    def wildcard_search(
        self,
        field: str,
        pattern: str,
        limit: int = 100,
    ) -> List[Term]:
        """Search for terms by wildcard pattern.

        Args:
            field: Field name
            pattern: Pattern with * and ? wildcards
            limit: Maximum results

        Returns:
            Matching terms
        """
        import fnmatch

        with self._lock:
            if field not in self._terms:
                return []

            results = []
            for term_text in self._terms[field].keys():
                if fnmatch.fnmatch(term_text, pattern):
                    term = self._term_info.get((field, term_text))
                    if term:
                        results.append(term)
                        if len(results) >= limit:
                            break

            return results

    def fuzzy_search(
        self,
        field: str,
        text: str,
        max_distance: int = 2,
        limit: int = 100,
    ) -> List[Tuple[Term, int]]:
        """Search for terms by edit distance.

        Args:
            field: Field name
            text: Target text
            max_distance: Maximum edit distance
            limit: Maximum results

        Returns:
            List of (term, distance) tuples
        """
        with self._lock:
            if field not in self._terms:
                return []

            results = []
            for term_text in self._terms[field].keys():
                distance = self._edit_distance(text, term_text)
                if distance <= max_distance:
                    term = self._term_info.get((field, term_text))
                    if term:
                        results.append((term, distance))

            # Sort by distance
            results.sort(key=lambda x: x[1])
            return results[:limit]

    def _edit_distance(self, s1: str, s2: str) -> int:
        """Calculate Levenshtein edit distance."""
        if len(s1) < len(s2):
            return self._edit_distance(s2, s1)

        if len(s2) == 0:
            return len(s1)

        previous_row = range(len(s2) + 1)
        for i, c1 in enumerate(s1):
            current_row = [i + 1]
            for j, c2 in enumerate(s2):
                insertions = previous_row[j + 1] + 1
                deletions = current_row[j] + 1
                substitutions = previous_row[j] + (c1 != c2)
                current_row.append(min(insertions, deletions, substitutions))
            previous_row = current_row

        return previous_row[-1]

    def all_terms(self, field: Optional[str] = None) -> List[Term]:
        """Get all terms.

        Args:
            field: Optional field filter

        Returns:
            List of terms
        """
        with self._lock:
            if field:
                if field not in self._terms:
                    return []
                return [
                    self._term_info[(field, t)]
                    for t in self._terms[field].keys()
                    if (field, t) in self._term_info
                ]
            else:
                return list(self._term_info.values())

    def term_count(self, field: Optional[str] = None) -> int:
        """Get term count.

        Args:
            field: Optional field filter

        Returns:
            Number of terms
        """
        with self._lock:
            if field:
                return len(self._terms.get(field, {}))
            return sum(len(terms) for terms in self._terms.values())


class InvertedIndex:
    """Inverted index for full-text search.

    The inverted index is the core data structure enabling efficient
    term-to-document lookups.
    """

    def __init__(
        self,
        field_name: str = "_all",
        store_positions: bool = True,
        store_offsets: bool = False,
    ):
        """Initialize inverted index.

        Args:
            field_name: Field name for this index
            store_positions: Store term positions
            store_offsets: Store character offsets
        """
        self.field_name = field_name
        self.store_positions = store_positions
        self.store_offsets = store_offsets

        self._posting_lists: Dict[str, PostingList] = {}
        self._term_dictionary = TermDictionary()
        self._doc_count = 0
        self._deleted_docs: Set[str] = set()
        self._field_lengths: Dict[str, int] = {}  # doc_id -> field length
        self._lock = threading.RLock()

        # Statistics
        self._total_terms = 0
        self._unique_terms = 0
        self._avg_field_length = 0.0

    def index_document(
        self,
        doc_id: str,
        tokens: List[Tuple[str, int, int]],  # (token, position, offset)
    ) -> None:
        """Index tokens from a document.

        Args:
            doc_id: Document ID
            tokens: List of (token, position, offset) tuples
        """
        with self._lock:
            if not tokens:
                return

            # Calculate term frequencies
            term_freqs: Dict[str, List[Tuple[int, int]]] = defaultdict(list)
            for token, position, offset in tokens:
                term_freqs[token].append((position, offset))

            # Add to posting lists
            for term_text, occurrences in term_freqs.items():
                positions = [pos for pos, _ in occurrences]
                offsets = [(off, off + len(term_text)) for _, off in occurrences]

                posting = Posting(
                    doc_id=doc_id,
                    term_freq=len(occurrences),
                    positions=positions if self.store_positions else [],
                    offsets=offsets if self.store_offsets else [],
                )

                # Get or create posting list
                if term_text not in self._posting_lists:
                    term = Term(text=term_text, field=self.field_name)
                    self._posting_lists[term_text] = PostingList(term)
                    self._unique_terms += 1

                self._posting_lists[term_text].add(posting)

            # Update statistics
            self._field_lengths[doc_id] = len(tokens)
            self._total_terms += len(tokens)
            self._doc_count += 1
            self._avg_field_length = self._total_terms / max(1, self._doc_count)

    def delete_document(self, doc_id: str) -> bool:
        """Mark document as deleted.

        Args:
            doc_id: Document ID

        Returns:
            True if document was indexed
        """
        with self._lock:
            if doc_id in self._field_lengths:
                self._deleted_docs.add(doc_id)
                return True
            return False

    def purge_deleted(self) -> int:
        """Remove deleted documents from index.

        Returns:
            Number of documents purged
        """
        with self._lock:
            if not self._deleted_docs:
                return 0

            count = len(self._deleted_docs)

            for doc_id in self._deleted_docs:
                # Remove from all posting lists
                for posting_list in self._posting_lists.values():
                    posting_list.remove(doc_id)

                # Remove field length
                if doc_id in self._field_lengths:
                    self._total_terms -= self._field_lengths[doc_id]
                    del self._field_lengths[doc_id]
                    self._doc_count -= 1

            # Remove empty posting lists
            empty = [t for t, pl in self._posting_lists.items() if len(pl) == 0]
            for term in empty:
                del self._posting_lists[term]
                self._unique_terms -= 1

            # Update average
            self._avg_field_length = (
                self._total_terms / max(1, self._doc_count)
            )

            self._deleted_docs.clear()
            return count

    def get_posting_list(self, term: str) -> Optional[PostingList]:
        """Get posting list for term.

        Args:
            term: Term text

        Returns:
            PostingList or None
        """
        return self._posting_lists.get(term)

    def get_document_frequency(self, term: str) -> int:
        """Get document frequency for term.

        Args:
            term: Term text

        Returns:
            Document frequency
        """
        pl = self._posting_lists.get(term)
        return len(pl) if pl else 0

    def get_total_frequency(self, term: str) -> int:
        """Get total term frequency.

        Args:
            term: Term text

        Returns:
            Total frequency across all documents
        """
        pl = self._posting_lists.get(term)
        return pl.term.total_freq if pl else 0

    def get_field_length(self, doc_id: str) -> int:
        """Get field length for document.

        Args:
            doc_id: Document ID

        Returns:
            Field length (token count)
        """
        return self._field_lengths.get(doc_id, 0)

    def search(
        self,
        terms: List[str],
        conjunction: bool = True,
    ) -> PostingListIterator:
        """Search for documents matching terms.

        Args:
            terms: Search terms
            conjunction: True for AND, False for OR

        Returns:
            Iterator over matching documents
        """
        posting_lists = []
        for term in terms:
            pl = self._posting_lists.get(term)
            if pl:
                posting_lists.append(pl)
            elif conjunction:
                # Term not found, AND search yields nothing
                return PostingListIterator([], True)

        return PostingListIterator(posting_lists, conjunction)

    def phrase_search(
        self,
        terms: List[str],
        slop: int = 0,
    ) -> List[Tuple[str, List[int]]]:
        """Search for phrase with position matching.

        Args:
            terms: Phrase terms in order
            slop: Maximum position gap

        Returns:
            List of (doc_id, match_positions)
        """
        if not terms:
            return []

        # Get posting lists
        posting_lists = []
        for term in terms:
            pl = self._posting_lists.get(term)
            if not pl:
                return []
            posting_lists.append(pl)

        # Find documents containing all terms
        common_docs = posting_lists[0].doc_ids()
        for pl in posting_lists[1:]:
            common_docs &= pl.doc_ids()

        results = []

        # Check position sequences
        for doc_id in common_docs:
            postings = [pl.get(doc_id) for pl in posting_lists]
            if not all(postings):
                continue

            # Find valid phrase positions
            matches = self._find_phrase_matches(
                [p.positions for p in postings],
                slop,
            )

            if matches:
                results.append((doc_id, matches))

        return results

    def _find_phrase_matches(
        self,
        position_lists: List[List[int]],
        slop: int,
    ) -> List[int]:
        """Find phrase matches in position lists.

        Args:
            position_lists: List of position lists for each term
            slop: Maximum position gap

        Returns:
            List of match start positions
        """
        if not position_lists:
            return []

        matches = []
        first_positions = position_lists[0]

        for start_pos in first_positions:
            current_pos = start_pos
            matched = True

            for i in range(1, len(position_lists)):
                expected_pos = current_pos + 1
                found = False

                for pos in position_lists[i]:
                    if pos >= expected_pos and pos <= expected_pos + slop:
                        current_pos = pos
                        found = True
                        break
                    elif pos > expected_pos + slop:
                        break

                if not found:
                    matched = False
                    break

            if matched:
                matches.append(start_pos)

        return matches

    def prefix_terms(self, prefix: str, limit: int = 100) -> List[str]:
        """Get terms starting with prefix.

        Args:
            prefix: Term prefix
            limit: Maximum results

        Returns:
            List of matching terms
        """
        with self._lock:
            results = []
            for term in sorted(self._posting_lists.keys()):
                if term.startswith(prefix):
                    results.append(term)
                    if len(results) >= limit:
                        break
                elif term > prefix + "~":
                    break
            return results

    @property
    def document_count(self) -> int:
        """Get total document count."""
        return self._doc_count - len(self._deleted_docs)

    @property
    def term_count(self) -> int:
        """Get unique term count."""
        return self._unique_terms

    @property
    def average_field_length(self) -> float:
        """Get average field length."""
        return self._avg_field_length

    def get_stats(self) -> Dict[str, Any]:
        """Get index statistics."""
        return {
            "field_name": self.field_name,
            "document_count": self.document_count,
            "deleted_count": len(self._deleted_docs),
            "term_count": self._unique_terms,
            "total_terms": self._total_terms,
            "avg_field_length": self._avg_field_length,
            "store_positions": self.store_positions,
            "store_offsets": self.store_offsets,
        }

    def merge(self, other: "InvertedIndex") -> None:
        """Merge another index into this one.

        Args:
            other: Index to merge
        """
        with self._lock:
            for term, other_pl in other._posting_lists.items():
                if term in self._posting_lists:
                    # Merge posting lists
                    for posting in other_pl:
                        self._posting_lists[term].add(posting)
                else:
                    # Copy posting list
                    self._posting_lists[term] = PostingList(
                        other_pl.term,
                        list(other_pl),
                    )
                    self._unique_terms += 1

            # Merge field lengths
            for doc_id, length in other._field_lengths.items():
                self._field_lengths[doc_id] = length
                self._total_terms += length
                self._doc_count += 1

            self._avg_field_length = (
                self._total_terms / max(1, self._doc_count)
            )


__all__ = [
    "InvertedIndex",
    "Posting",
    "PostingList",
    "PostingListIterator",
    "Term",
    "TermType",
    "TermFlags",
    "TermDictionary",
    "SkipList",
]
