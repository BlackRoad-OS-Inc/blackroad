"""RoadCache Entry - Cache Entry with TTL and State Management.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Dict, Optional


class EntryState(Enum):
    """Cache entry states."""

    VALID = auto()       # Entry is valid
    EXPIRED = auto()     # Entry has expired
    STALE = auto()       # Entry is stale but usable
    LOADING = auto()     # Entry is being loaded
    INVALID = auto()     # Entry is invalid


@dataclass
class EntryMetadata:
    """Metadata for a cache entry.

    Attributes:
        created_at: When entry was created
        accessed_at: Last access time
        modified_at: Last modification time
        access_count: Number of accesses
        size_bytes: Size of value in bytes
        checksum: Value checksum for integrity
        tags: Entry tags for grouping
        source: Where value came from
        version: Entry version for CAS
    """

    created_at: float = field(default_factory=time.time)
    accessed_at: float = field(default_factory=time.time)
    modified_at: float = field(default_factory=time.time)
    access_count: int = 0
    size_bytes: int = 0
    checksum: Optional[str] = None
    tags: Dict[str, str] = field(default_factory=dict)
    source: Optional[str] = None
    version: int = 1

    def touch(self) -> None:
        """Update access time and count."""
        self.accessed_at = time.time()
        self.access_count += 1

    def update(self) -> None:
        """Update modification time and version."""
        self.modified_at = time.time()
        self.version += 1

    @property
    def age_seconds(self) -> float:
        """Get entry age in seconds."""
        return time.time() - self.created_at

    @property
    def idle_seconds(self) -> float:
        """Get time since last access."""
        return time.time() - self.accessed_at


@dataclass
class CacheEntry:
    """A cache entry with value, TTL, and metadata.

    Attributes:
        key: Cache key
        value: Cached value
        ttl_seconds: Time to live in seconds
        state: Entry state
        metadata: Entry metadata
        namespace: Entry namespace
    """

    key: str
    value: Any
    ttl_seconds: Optional[float] = None
    state: EntryState = EntryState.VALID
    metadata: EntryMetadata = field(default_factory=EntryMetadata)
    namespace: str = "default"

    def __post_init__(self):
        """Initialize after creation."""
        if self.metadata.size_bytes == 0:
            self.metadata.size_bytes = self._calculate_size()
        if self.metadata.checksum is None:
            self.metadata.checksum = self._calculate_checksum()

    @property
    def is_valid(self) -> bool:
        """Check if entry is valid."""
        return self.state == EntryState.VALID and not self.is_expired

    @property
    def is_expired(self) -> bool:
        """Check if entry has expired."""
        if self.ttl_seconds is None:
            return False
        return time.time() > (self.metadata.created_at + self.ttl_seconds)

    @property
    def expires_at(self) -> Optional[float]:
        """Get expiration timestamp."""
        if self.ttl_seconds is None:
            return None
        return self.metadata.created_at + self.ttl_seconds

    @property
    def remaining_ttl(self) -> Optional[float]:
        """Get remaining TTL in seconds."""
        if self.ttl_seconds is None:
            return None
        remaining = self.expires_at - time.time()
        return max(0, remaining)

    def touch(self) -> None:
        """Update access time."""
        self.metadata.touch()

    def update_value(self, value: Any, ttl: Optional[float] = None) -> None:
        """Update the cached value.

        Args:
            value: New value
            ttl: New TTL (optional)
        """
        self.value = value
        if ttl is not None:
            self.ttl_seconds = ttl
        self.metadata.update()
        self.metadata.size_bytes = self._calculate_size()
        self.metadata.checksum = self._calculate_checksum()
        self.state = EntryState.VALID

    def expire(self) -> None:
        """Mark entry as expired."""
        self.state = EntryState.EXPIRED

    def invalidate(self) -> None:
        """Mark entry as invalid."""
        self.state = EntryState.INVALID

    def mark_stale(self) -> None:
        """Mark entry as stale."""
        self.state = EntryState.STALE

    def extend_ttl(self, seconds: float) -> None:
        """Extend TTL by given seconds.

        Args:
            seconds: Seconds to add
        """
        if self.ttl_seconds is not None:
            self.ttl_seconds += seconds
        else:
            self.ttl_seconds = seconds

    def refresh_ttl(self, ttl: Optional[float] = None) -> None:
        """Refresh TTL from current time.

        Args:
            ttl: New TTL or use existing
        """
        if ttl is not None:
            self.ttl_seconds = ttl
        self.metadata.created_at = time.time()
        self.state = EntryState.VALID

    def _calculate_size(self) -> int:
        """Calculate value size in bytes."""
        return sys.getsizeof(self.value)

    def _calculate_checksum(self) -> str:
        """Calculate value checksum."""
        try:
            return hashlib.md5(str(self.value).encode()).hexdigest()[:16]
        except Exception:
            return ""

    def verify_integrity(self) -> bool:
        """Verify entry integrity via checksum.

        Returns:
            True if integrity check passes
        """
        current = self._calculate_checksum()
        return current == self.metadata.checksum

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary.

        Returns:
            Dictionary representation
        """
        return {
            "key": self.key,
            "value": self.value,
            "ttl_seconds": self.ttl_seconds,
            "state": self.state.name,
            "namespace": self.namespace,
            "metadata": {
                "created_at": self.metadata.created_at,
                "accessed_at": self.metadata.accessed_at,
                "modified_at": self.metadata.modified_at,
                "access_count": self.metadata.access_count,
                "size_bytes": self.metadata.size_bytes,
                "checksum": self.metadata.checksum,
                "tags": self.metadata.tags,
                "version": self.metadata.version,
            },
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "CacheEntry":
        """Create from dictionary.

        Args:
            data: Dictionary data

        Returns:
            CacheEntry instance
        """
        metadata = EntryMetadata(
            created_at=data.get("metadata", {}).get("created_at", time.time()),
            accessed_at=data.get("metadata", {}).get("accessed_at", time.time()),
            modified_at=data.get("metadata", {}).get("modified_at", time.time()),
            access_count=data.get("metadata", {}).get("access_count", 0),
            size_bytes=data.get("metadata", {}).get("size_bytes", 0),
            checksum=data.get("metadata", {}).get("checksum"),
            tags=data.get("metadata", {}).get("tags", {}),
            version=data.get("metadata", {}).get("version", 1),
        )

        return cls(
            key=data["key"],
            value=data["value"],
            ttl_seconds=data.get("ttl_seconds"),
            state=EntryState[data.get("state", "VALID")],
            metadata=metadata,
            namespace=data.get("namespace", "default"),
        )

    def __repr__(self) -> str:
        return (
            f"CacheEntry(key={self.key!r}, state={self.state.name}, "
            f"ttl={self.remaining_ttl:.1f}s)" if self.ttl_seconds else
            f"CacheEntry(key={self.key!r}, state={self.state.name})"
        )


class EntryBuilder:
    """Fluent builder for cache entries."""

    def __init__(self, key: str):
        self._key = key
        self._value: Any = None
        self._ttl: Optional[float] = None
        self._namespace = "default"
        self._tags: Dict[str, str] = {}
        self._source: Optional[str] = None

    def value(self, value: Any) -> "EntryBuilder":
        """Set value."""
        self._value = value
        return self

    def ttl(self, seconds: float) -> "EntryBuilder":
        """Set TTL."""
        self._ttl = seconds
        return self

    def namespace(self, ns: str) -> "EntryBuilder":
        """Set namespace."""
        self._namespace = ns
        return self

    def tag(self, key: str, value: str) -> "EntryBuilder":
        """Add tag."""
        self._tags[key] = value
        return self

    def tags(self, tags: Dict[str, str]) -> "EntryBuilder":
        """Set all tags."""
        self._tags = tags
        return self

    def source(self, source: str) -> "EntryBuilder":
        """Set source."""
        self._source = source
        return self

    def build(self) -> CacheEntry:
        """Build the entry."""
        metadata = EntryMetadata(tags=self._tags, source=self._source)
        return CacheEntry(
            key=self._key,
            value=self._value,
            ttl_seconds=self._ttl,
            namespace=self._namespace,
            metadata=metadata,
        )


__all__ = ["CacheEntry", "EntryState", "EntryMetadata", "EntryBuilder"]
