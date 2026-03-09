"""RoadCache Warmup - Cache Warming Strategies.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from abc import ABC, abstractmethod
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Callable, Dict, Iterable, List, Optional, Set, Tuple, TYPE_CHECKING

if TYPE_CHECKING:
    from roadcache_core.cache.cache import Cache

logger = logging.getLogger(__name__)


@dataclass
class WarmupConfig:
    """Configuration for cache warmup.

    Attributes:
        batch_size: Keys to warm per batch
        max_workers: Parallel workers
        delay_between_batches: Seconds between batches
        timeout_per_key: Timeout per key
        retry_failed: Retry failed keys
        max_retries: Maximum retries
    """

    batch_size: int = 100
    max_workers: int = 4
    delay_between_batches: float = 0.1
    timeout_per_key: float = 5.0
    retry_failed: bool = True
    max_retries: int = 3


@dataclass
class WarmupStats:
    """Warmup operation statistics.

    Attributes:
        total_keys: Total keys to warm
        warmed: Successfully warmed
        failed: Failed to warm
        skipped: Skipped (already cached)
        duration_seconds: Total duration
        started_at: Start time
        completed_at: Completion time
    """

    total_keys: int = 0
    warmed: int = 0
    failed: int = 0
    skipped: int = 0
    duration_seconds: float = 0.0
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    @property
    def success_rate(self) -> float:
        """Get success rate."""
        total = self.warmed + self.failed
        return self.warmed / total if total > 0 else 0.0


class WarmupSource(ABC):
    """Abstract source for warmup keys."""

    @abstractmethod
    def get_keys(self) -> Iterable[str]:
        """Get keys to warm.

        Returns:
            Iterable of keys
        """
        pass

    @abstractmethod
    def get_value(self, key: str) -> Optional[Any]:
        """Get value for key.

        Args:
            key: Cache key

        Returns:
            Value or None
        """
        pass


class ListSource(WarmupSource):
    """Warmup from a list of key-value pairs."""

    def __init__(self, data: Dict[str, Any]):
        """Initialize list source.

        Args:
            data: Dict of key -> value
        """
        self._data = data

    def get_keys(self) -> Iterable[str]:
        return self._data.keys()

    def get_value(self, key: str) -> Optional[Any]:
        return self._data.get(key)


class CallableSource(WarmupSource):
    """Warmup using a callable for each key."""

    def __init__(
        self,
        keys: Iterable[str],
        loader: Callable[[str], Any],
    ):
        """Initialize callable source.

        Args:
            keys: Keys to warm
            loader: Function to load value for key
        """
        self._keys = list(keys)
        self._loader = loader

    def get_keys(self) -> Iterable[str]:
        return self._keys

    def get_value(self, key: str) -> Optional[Any]:
        try:
            return self._loader(key)
        except Exception as e:
            logger.error(f"Failed to load {key}: {e}")
            return None


class DatabaseSource(WarmupSource):
    """Warmup from database query."""

    def __init__(
        self,
        query_func: Callable[[], List[Tuple[str, Any]]],
    ):
        """Initialize database source.

        Args:
            query_func: Function returning (key, value) tuples
        """
        self._query_func = query_func
        self._data: Optional[Dict[str, Any]] = None

    def _load(self) -> None:
        """Load data from database."""
        if self._data is None:
            results = self._query_func()
            self._data = {k: v for k, v in results}

    def get_keys(self) -> Iterable[str]:
        self._load()
        return self._data.keys()

    def get_value(self, key: str) -> Optional[Any]:
        self._load()
        return self._data.get(key)


class CacheWarmer:
    """Warms cache from various sources.

    Features:
    - Multiple warmup sources
    - Parallel warming
    - Progress tracking
    - Retry on failure
    - Skip existing keys

    Example:
        warmer = CacheWarmer(cache)

        # From static data
        warmer.warm_from_dict({"key1": "val1", "key2": "val2"})

        # From callable
        warmer.warm_from_loader(
            keys=["user:1", "user:2"],
            loader=lambda k: fetch_user(k),
        )

        # From database
        warmer.warm_from_query(
            lambda: db.execute("SELECT key, value FROM cache_backup")
        )
    """

    def __init__(
        self,
        cache: "Cache",
        config: Optional[WarmupConfig] = None,
    ):
        """Initialize warmer.

        Args:
            cache: Cache to warm
            config: Warmup configuration
        """
        self.cache = cache
        self.config = config or WarmupConfig()
        self._stats = WarmupStats()
        self._lock = threading.Lock()

    def warm(
        self,
        source: WarmupSource,
        ttl: Optional[float] = None,
        skip_existing: bool = True,
        progress_callback: Optional[Callable[[int, int], None]] = None,
    ) -> WarmupStats:
        """Warm cache from source.

        Args:
            source: Warmup source
            ttl: TTL for warmed entries
            skip_existing: Skip already cached keys
            progress_callback: Called with (completed, total)

        Returns:
            Warmup statistics
        """
        keys = list(source.get_keys())
        self._stats = WarmupStats(
            total_keys=len(keys),
            started_at=datetime.now(),
        )

        logger.info(f"Starting warmup of {len(keys)} keys")

        # Batch processing
        batches = [
            keys[i:i + self.config.batch_size]
            for i in range(0, len(keys), self.config.batch_size)
        ]

        completed = 0

        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            for batch in batches:
                futures = {}

                for key in batch:
                    # Skip existing
                    if skip_existing and self.cache.exists(key):
                        with self._lock:
                            self._stats.skipped += 1
                            completed += 1
                        continue

                    future = executor.submit(
                        self._warm_key, source, key, ttl
                    )
                    futures[future] = key

                # Wait for batch
                for future in as_completed(futures.keys()):
                    key = futures[future]
                    try:
                        success = future.result(timeout=self.config.timeout_per_key)
                        with self._lock:
                            if success:
                                self._stats.warmed += 1
                            else:
                                self._stats.failed += 1
                            completed += 1
                    except Exception as e:
                        logger.error(f"Warmup failed for {key}: {e}")
                        with self._lock:
                            self._stats.failed += 1
                            completed += 1

                # Progress callback
                if progress_callback:
                    progress_callback(completed, len(keys))

                # Delay between batches
                if self.config.delay_between_batches > 0:
                    time.sleep(self.config.delay_between_batches)

        self._stats.completed_at = datetime.now()
        self._stats.duration_seconds = (
            self._stats.completed_at - self._stats.started_at
        ).total_seconds()

        logger.info(
            f"Warmup completed: {self._stats.warmed} warmed, "
            f"{self._stats.failed} failed, {self._stats.skipped} skipped"
        )

        return self._stats

    def _warm_key(
        self,
        source: WarmupSource,
        key: str,
        ttl: Optional[float],
    ) -> bool:
        """Warm a single key.

        Args:
            source: Warmup source
            key: Key to warm
            ttl: TTL for entry

        Returns:
            True if successful
        """
        retries = 0
        while retries <= self.config.max_retries:
            try:
                value = source.get_value(key)
                if value is not None:
                    self.cache.set(key, value, ttl=ttl)
                    return True
                return False

            except Exception as e:
                retries += 1
                if retries > self.config.max_retries:
                    logger.error(f"Failed to warm {key} after {retries} retries: {e}")
                    return False
                time.sleep(0.1 * retries)  # Exponential backoff

        return False

    def warm_from_dict(
        self,
        data: Dict[str, Any],
        ttl: Optional[float] = None,
        skip_existing: bool = True,
    ) -> WarmupStats:
        """Warm from dictionary.

        Args:
            data: Key -> value mapping
            ttl: TTL for entries
            skip_existing: Skip existing keys

        Returns:
            Warmup statistics
        """
        return self.warm(ListSource(data), ttl=ttl, skip_existing=skip_existing)

    def warm_from_loader(
        self,
        keys: Iterable[str],
        loader: Callable[[str], Any],
        ttl: Optional[float] = None,
        skip_existing: bool = True,
    ) -> WarmupStats:
        """Warm using loader function.

        Args:
            keys: Keys to warm
            loader: Function to load values
            ttl: TTL for entries
            skip_existing: Skip existing keys

        Returns:
            Warmup statistics
        """
        return self.warm(
            CallableSource(keys, loader),
            ttl=ttl,
            skip_existing=skip_existing,
        )

    def warm_from_query(
        self,
        query_func: Callable[[], List[Tuple[str, Any]]],
        ttl: Optional[float] = None,
        skip_existing: bool = True,
    ) -> WarmupStats:
        """Warm from database query.

        Args:
            query_func: Function returning (key, value) tuples
            ttl: TTL for entries
            skip_existing: Skip existing keys

        Returns:
            Warmup statistics
        """
        return self.warm(
            DatabaseSource(query_func),
            ttl=ttl,
            skip_existing=skip_existing,
        )

    def get_stats(self) -> WarmupStats:
        """Get warmup statistics.

        Returns:
            WarmupStats instance
        """
        return self._stats


__all__ = [
    "CacheWarmer",
    "WarmupConfig",
    "WarmupStats",
    "WarmupSource",
    "ListSource",
    "CallableSource",
    "DatabaseSource",
]
