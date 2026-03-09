"""Timing and profiling utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import functools
import logging
import statistics
import threading
import time
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional, TypeVar

logger = logging.getLogger(__name__)

F = TypeVar("F", bound=Callable[..., Any])


@dataclass
class TimingStats:
    """Statistics for timed operations."""

    count: int = 0
    total_seconds: float = 0.0
    min_seconds: float = float("inf")
    max_seconds: float = 0.0
    durations: List[float] = field(default_factory=list)

    @property
    def avg_seconds(self) -> float:
        """Average duration."""
        return self.total_seconds / self.count if self.count > 0 else 0.0

    @property
    def std_seconds(self) -> float:
        """Standard deviation."""
        if len(self.durations) < 2:
            return 0.0
        return statistics.stdev(self.durations)

    @property
    def median_seconds(self) -> float:
        """Median duration."""
        if not self.durations:
            return 0.0
        return statistics.median(self.durations)

    def record(self, duration: float) -> None:
        """Record a duration."""
        self.count += 1
        self.total_seconds += duration
        self.min_seconds = min(self.min_seconds, duration)
        self.max_seconds = max(self.max_seconds, duration)
        self.durations.append(duration)

        if len(self.durations) > 1000:
            self.durations = self.durations[-500:]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "count": self.count,
            "total_seconds": self.total_seconds,
            "avg_seconds": self.avg_seconds,
            "min_seconds": self.min_seconds if self.count > 0 else 0,
            "max_seconds": self.max_seconds,
            "std_seconds": self.std_seconds,
            "median_seconds": self.median_seconds,
        }


class Timer:
    """Context manager for timing code blocks.

    Usage:
        with Timer() as t:
            do_something()
        print(f"Took {t.elapsed:.3f}s")

        # Or with name for logging
        with Timer("my_operation"):
            do_something()
    """

    def __init__(self, name: Optional[str] = None, log: bool = True):
        self.name = name
        self.log = log
        self.start_time: Optional[float] = None
        self.end_time: Optional[float] = None

    def __enter__(self) -> "Timer":
        self.start_time = time.perf_counter()
        return self

    def __exit__(self, *args) -> None:
        self.end_time = time.perf_counter()

        if self.log and self.name:
            logger.info(f"{self.name} took {self.elapsed:.3f}s")

    @property
    def elapsed(self) -> float:
        """Elapsed time in seconds."""
        if self.start_time is None:
            return 0.0

        end = self.end_time or time.perf_counter()
        return end - self.start_time

    @property
    def elapsed_ms(self) -> float:
        """Elapsed time in milliseconds."""
        return self.elapsed * 1000


@contextmanager
def timer(name: Optional[str] = None):
    """Context manager shorthand for Timer.

    Usage:
        with timer("operation"):
            do_something()
    """
    t = Timer(name)
    try:
        t.__enter__()
        yield t
    finally:
        t.__exit__(None, None, None)


def timed(
    name: Optional[str] = None,
    log: bool = True,
) -> Callable[[F], F]:
    """Decorator to time function execution.

    Usage:
        @timed("my_function")
        def my_function():
            ...
    """
    def decorator(func: F) -> F:
        func_name = name or func.__qualname__

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            with Timer(func_name, log=log):
                return func(*args, **kwargs)

        return wrapper  # type: ignore

    return decorator


class Profiler:
    """Simple profiler for tracking multiple operations.

    Usage:
        profiler = Profiler()

        with profiler.track("load_data"):
            load_data()

        with profiler.track("process"):
            process()

        print(profiler.report())
    """

    def __init__(self):
        self._stats: Dict[str, TimingStats] = {}
        self._lock = threading.RLock()

    @contextmanager
    def track(self, name: str):
        """Track duration of code block."""
        start = time.perf_counter()
        try:
            yield
        finally:
            duration = time.perf_counter() - start
            with self._lock:
                if name not in self._stats:
                    self._stats[name] = TimingStats()
                self._stats[name].record(duration)

    def record(self, name: str, duration: float) -> None:
        """Manually record a duration."""
        with self._lock:
            if name not in self._stats:
                self._stats[name] = TimingStats()
            self._stats[name].record(duration)

    def get_stats(self, name: str) -> Optional[TimingStats]:
        """Get stats for an operation."""
        return self._stats.get(name)

    def reset(self, name: Optional[str] = None) -> None:
        """Reset stats."""
        with self._lock:
            if name:
                self._stats.pop(name, None)
            else:
                self._stats.clear()

    def report(self) -> str:
        """Generate profiling report."""
        lines = ["Profiling Report", "=" * 60]

        with self._lock:
            for name, stats in sorted(self._stats.items()):
                lines.append(f"\n{name}:")
                lines.append(f"  Count: {stats.count}")
                lines.append(f"  Total: {stats.total_seconds:.3f}s")
                lines.append(f"  Avg: {stats.avg_seconds:.3f}s")
                lines.append(f"  Min: {stats.min_seconds:.3f}s")
                lines.append(f"  Max: {stats.max_seconds:.3f}s")
                lines.append(f"  Std: {stats.std_seconds:.3f}s")

        return "\n".join(lines)

    def to_dict(self) -> Dict[str, Dict[str, Any]]:
        """Convert all stats to dictionary."""
        with self._lock:
            return {
                name: stats.to_dict()
                for name, stats in self._stats.items()
            }


_global_profiler = Profiler()


def profile(name: Optional[str] = None) -> Callable[[F], F]:
    """Decorator to profile function using global profiler.

    Usage:
        @profile("my_function")
        def my_function():
            ...

        # Later
        print(_global_profiler.report())
    """
    def decorator(func: F) -> F:
        func_name = name or func.__qualname__

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            with _global_profiler.track(func_name):
                return func(*args, **kwargs)

        return wrapper  # type: ignore

    return decorator


def get_global_profiler() -> Profiler:
    """Get the global profiler instance."""
    return _global_profiler


class RateLimiter:
    """Rate limiter for controlling operation frequency."""

    def __init__(
        self,
        rate: float,
        per_seconds: float = 1.0,
    ):
        self.rate = rate
        self.per_seconds = per_seconds
        self._interval = per_seconds / rate
        self._last_call: Optional[float] = None
        self._lock = threading.Lock()

    def wait(self) -> None:
        """Wait until next operation is allowed."""
        with self._lock:
            if self._last_call is not None:
                elapsed = time.time() - self._last_call
                wait_time = self._interval - elapsed

                if wait_time > 0:
                    time.sleep(wait_time)

            self._last_call = time.time()

    def try_acquire(self) -> bool:
        """Try to acquire rate limit slot without waiting."""
        with self._lock:
            if self._last_call is None:
                self._last_call = time.time()
                return True

            elapsed = time.time() - self._last_call
            if elapsed >= self._interval:
                self._last_call = time.time()
                return True

            return False


__all__ = [
    "Timer",
    "timer",
    "timed",
    "profile",
    "Profiler",
    "TimingStats",
    "RateLimiter",
    "get_global_profiler",
]
