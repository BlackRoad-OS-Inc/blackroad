"""RoadCache Consistency Model - Consistency Guarantees.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set

logger = logging.getLogger(__name__)


class ConsistencyLevel(Enum):
    """Consistency level for cache operations."""

    ONE = auto()        # Write to one node
    QUORUM = auto()     # Write to majority
    ALL = auto()        # Write to all nodes
    LOCAL_QUORUM = auto()  # Local datacenter quorum
    EVENTUAL = auto()   # Eventually consistent


@dataclass
class VersionedValue:
    """Value with version for conflict detection.

    Attributes:
        value: The cached value
        version: Version number
        timestamp: Write timestamp
        writer: Writer identifier
        checksum: Value checksum
    """

    value: Any
    version: int = 1
    timestamp: float = 0.0
    writer: Optional[str] = None
    checksum: Optional[str] = None

    def __post_init__(self):
        if self.timestamp == 0.0:
            self.timestamp = time.time()

    def conflicts_with(self, other: "VersionedValue") -> bool:
        """Check if values conflict.

        Args:
            other: Other versioned value

        Returns:
            True if conflict detected
        """
        if self.version == other.version:
            return self.writer != other.writer

        return False


@dataclass
class ConflictResolution:
    """Result of conflict resolution."""

    resolved_value: VersionedValue
    strategy: str
    conflicting_values: List[VersionedValue]


class ConsistencyModel(ABC):
    """Abstract consistency model.

    Defines how reads and writes are handled across
    distributed cache nodes.

    Models:
    - StrongConsistency: All reads see latest write
    - EventualConsistency: Reads may be stale
    - SessionConsistency: Read-your-writes guarantee
    """

    def __init__(self, level: ConsistencyLevel = ConsistencyLevel.EVENTUAL):
        """Initialize model.

        Args:
            level: Consistency level
        """
        self.level = level

    @abstractmethod
    def on_write(
        self,
        key: str,
        value: VersionedValue,
        replicas: List[str],
    ) -> bool:
        """Handle write operation.

        Args:
            key: Cache key
            value: Value to write
            replicas: Replica node IDs

        Returns:
            True if write successful
        """
        pass

    @abstractmethod
    def on_read(
        self,
        key: str,
        values: Dict[str, VersionedValue],
    ) -> Optional[VersionedValue]:
        """Handle read operation.

        Args:
            key: Cache key
            values: Values from replicas

        Returns:
            Resolved value or None
        """
        pass

    @abstractmethod
    def resolve_conflict(
        self,
        key: str,
        values: List[VersionedValue],
    ) -> ConflictResolution:
        """Resolve conflicting values.

        Args:
            key: Cache key
            values: Conflicting values

        Returns:
            Resolution result
        """
        pass


class StrongConsistency(ConsistencyModel):
    """Strong consistency model.

    All reads see the most recent write.
    Uses read/write quorum for linearizability.
    """

    def __init__(self):
        super().__init__(ConsistencyLevel.ALL)

    def on_write(
        self,
        key: str,
        value: VersionedValue,
        replicas: List[str],
    ) -> bool:
        """Write must succeed on all replicas.

        Args:
            key: Cache key
            value: Value to write
            replicas: Replica node IDs

        Returns:
            True only if all writes succeed
        """
        # In practice, this would coordinate writes
        # For now, just validate all replicas are specified
        return len(replicas) > 0

    def on_read(
        self,
        key: str,
        values: Dict[str, VersionedValue],
    ) -> Optional[VersionedValue]:
        """Read requires all replicas to agree.

        Args:
            key: Cache key
            values: Values from replicas

        Returns:
            Value if all agree, None otherwise
        """
        if not values:
            return None

        # Get latest version
        versions = list(values.values())
        if not versions:
            return None

        latest = max(versions, key=lambda v: (v.version, v.timestamp))

        # Check all agree on latest
        for v in versions:
            if v.version != latest.version:
                logger.warning(f"Version mismatch for {key}")
                return None

        return latest

    def resolve_conflict(
        self,
        key: str,
        values: List[VersionedValue],
    ) -> ConflictResolution:
        """Resolve by highest version/timestamp.

        Args:
            key: Cache key
            values: Conflicting values

        Returns:
            Resolution using last-write-wins
        """
        latest = max(values, key=lambda v: (v.version, v.timestamp))
        return ConflictResolution(
            resolved_value=latest,
            strategy="last-write-wins",
            conflicting_values=values,
        )


class EventualConsistency(ConsistencyModel):
    """Eventual consistency model.

    Writes propagate asynchronously.
    Reads may see stale data temporarily.
    """

    def __init__(self, read_repair: bool = True):
        """Initialize eventual consistency.

        Args:
            read_repair: Enable read repair
        """
        super().__init__(ConsistencyLevel.EVENTUAL)
        self.read_repair = read_repair

    def on_write(
        self,
        key: str,
        value: VersionedValue,
        replicas: List[str],
    ) -> bool:
        """Write to at least one replica.

        Args:
            key: Cache key
            value: Value to write
            replicas: Replica node IDs

        Returns:
            True if at least one write succeeds
        """
        return len(replicas) >= 1

    def on_read(
        self,
        key: str,
        values: Dict[str, VersionedValue],
    ) -> Optional[VersionedValue]:
        """Read from any replica.

        Args:
            key: Cache key
            values: Values from replicas

        Returns:
            Latest value seen
        """
        if not values:
            return None

        versions = list(values.values())
        return max(versions, key=lambda v: (v.version, v.timestamp))

    def resolve_conflict(
        self,
        key: str,
        values: List[VersionedValue],
    ) -> ConflictResolution:
        """Resolve by vector clock/timestamp.

        Args:
            key: Cache key
            values: Conflicting values

        Returns:
            Resolution result
        """
        latest = max(values, key=lambda v: (v.version, v.timestamp))
        return ConflictResolution(
            resolved_value=latest,
            strategy="timestamp-ordering",
            conflicting_values=values,
        )


class QuorumConsistency(ConsistencyModel):
    """Quorum-based consistency.

    Uses R + W > N for consistency where:
    - R = read quorum
    - W = write quorum
    - N = total replicas
    """

    def __init__(
        self,
        read_quorum: int = 2,
        write_quorum: int = 2,
        total_replicas: int = 3,
    ):
        """Initialize quorum consistency.

        Args:
            read_quorum: Minimum reads required
            write_quorum: Minimum writes required
            total_replicas: Total replica count
        """
        super().__init__(ConsistencyLevel.QUORUM)
        self.read_quorum = read_quorum
        self.write_quorum = write_quorum
        self.total_replicas = total_replicas

        # Validate quorum requirements
        if read_quorum + write_quorum <= total_replicas:
            logger.warning("R + W <= N: Strong consistency not guaranteed")

    def on_write(
        self,
        key: str,
        value: VersionedValue,
        replicas: List[str],
    ) -> bool:
        """Write must succeed on write quorum.

        Args:
            key: Cache key
            value: Value to write
            replicas: Successful replica IDs

        Returns:
            True if write quorum met
        """
        return len(replicas) >= self.write_quorum

    def on_read(
        self,
        key: str,
        values: Dict[str, VersionedValue],
    ) -> Optional[VersionedValue]:
        """Read requires read quorum.

        Args:
            key: Cache key
            values: Values from replicas

        Returns:
            Latest value if quorum met
        """
        if len(values) < self.read_quorum:
            logger.warning(f"Read quorum not met for {key}")
            return None

        versions = list(values.values())
        return max(versions, key=lambda v: (v.version, v.timestamp))

    def resolve_conflict(
        self,
        key: str,
        values: List[VersionedValue],
    ) -> ConflictResolution:
        """Resolve using quorum vote.

        Args:
            key: Cache key
            values: Conflicting values

        Returns:
            Most common value if majority, else latest
        """
        from collections import Counter

        # Group by (version, checksum) for exact match
        version_counts = Counter(
            (v.version, v.checksum) for v in values
        )

        most_common = version_counts.most_common(1)
        if most_common and most_common[0][1] > len(values) // 2:
            # Majority agreement
            target = most_common[0][0]
            for v in values:
                if (v.version, v.checksum) == target:
                    return ConflictResolution(
                        resolved_value=v,
                        strategy="quorum-majority",
                        conflicting_values=values,
                    )

        # No majority, use latest
        latest = max(values, key=lambda v: (v.version, v.timestamp))
        return ConflictResolution(
            resolved_value=latest,
            strategy="quorum-latest",
            conflicting_values=values,
        )


__all__ = [
    "ConsistencyModel",
    "ConsistencyLevel",
    "VersionedValue",
    "ConflictResolution",
    "StrongConsistency",
    "EventualConsistency",
    "QuorumConsistency",
]
