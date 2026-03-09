"""RoadCache Decorators - Caching Decorators.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import functools
import hashlib
import inspect
import logging
import threading
import time
from typing import Any, Callable, Dict, List, Optional, TypeVar, Union

logger = logging.getLogger(__name__)

F = TypeVar("F", bound=Callable[..., Any])


def _make_key(
    func: Callable,
    args: tuple,
    kwargs: dict,
    key_prefix: Optional[str] = None,
    key_builder: Optional[Callable[..., str]] = None,
    typed: bool = False,
) -> str:
    """Build cache key from function call.

    Args:
        func: Function being cached
        args: Positional arguments
        kwargs: Keyword arguments
        key_prefix: Optional prefix
        key_builder: Custom key builder
        typed: Include types in key

    Returns:
        Cache key string
    """
    if key_builder:
        return key_builder(*args, **kwargs)

    # Build key from function name and arguments
    parts = [key_prefix or func.__module__, func.__qualname__]

    # Add args
    for arg in args:
        if typed:
            parts.append(f"{type(arg).__name__}:{arg}")
        else:
            parts.append(str(arg))

    # Add kwargs (sorted for consistency)
    for k in sorted(kwargs.keys()):
        v = kwargs[k]
        if typed:
            parts.append(f"{k}={type(v).__name__}:{v}")
        else:
            parts.append(f"{k}={v}")

    key = ":".join(parts)

    # Hash if too long
    if len(key) > 250:
        key = hashlib.sha256(key.encode()).hexdigest()

    return key


def cached(
    ttl: Optional[float] = None,
    key_prefix: Optional[str] = None,
    key_builder: Optional[Callable[..., str]] = None,
    typed: bool = False,
    lock: bool = True,
    namespace: Optional[str] = None,
) -> Callable[[F], F]:
    """Decorator to cache function results.

    Args:
        ttl: Cache TTL in seconds
        key_prefix: Key prefix
        key_builder: Custom key builder
        typed: Include argument types in key
        lock: Use locking for cache stampede prevention
        namespace: Cache namespace

    Returns:
        Decorated function

    Example:
        @cached(ttl=300)
        def get_user(user_id: int) -> User:
            return db.get_user(user_id)

        @cached(key_builder=lambda id: f"user:{id}")
        def get_user_v2(user_id: int) -> User:
            return db.get_user(user_id)
    """
    def decorator(func: F) -> F:
        # Import here to avoid circular imports
        from roadcache_core.cache.cache import Cache

        # Create per-function cache
        func_cache = Cache()
        func_lock = threading.Lock() if lock else None

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = _make_key(
                func, args, kwargs,
                key_prefix=key_prefix,
                key_builder=key_builder,
                typed=typed,
            )

            if namespace:
                cache_key = f"{namespace}:{cache_key}"

            # Try cache
            cached_value = func_cache.get(cache_key)
            if cached_value is not None:
                return cached_value

            # Lock for stampede prevention
            if func_lock:
                with func_lock:
                    # Double-check after acquiring lock
                    cached_value = func_cache.get(cache_key)
                    if cached_value is not None:
                        return cached_value

                    result = func(*args, **kwargs)
                    func_cache.set(cache_key, result, ttl=ttl)
                    return result
            else:
                result = func(*args, **kwargs)
                func_cache.set(cache_key, result, ttl=ttl)
                return result

        # Add cache management methods
        def cache_clear():
            """Clear all cached results."""
            func_cache.clear()

        def cache_info() -> Dict[str, Any]:
            """Get cache statistics."""
            stats = func_cache.get_stats()
            return {
                "hits": stats.hits,
                "misses": stats.misses,
                "size": stats.entry_count,
                "hit_rate": stats.hit_rate,
            }

        def cache_key(*args, **kwargs) -> str:
            """Get cache key for arguments."""
            return _make_key(
                func, args, kwargs,
                key_prefix=key_prefix,
                key_builder=key_builder,
                typed=typed,
            )

        wrapper.cache_clear = cache_clear
        wrapper.cache_info = cache_info
        wrapper.cache_key = cache_key
        wrapper.__wrapped__ = func

        return wrapper  # type: ignore

    return decorator


def cached_property(ttl: Optional[float] = None) -> Callable[[F], F]:
    """Decorator for cached properties.

    Args:
        ttl: Cache TTL in seconds (None = forever)

    Returns:
        Decorated property

    Example:
        class User:
            @cached_property(ttl=60)
            def expensive_computation(self) -> int:
                return heavy_calc()
    """
    def decorator(func: F) -> F:
        attr_name = f"_cached_{func.__name__}"
        time_attr = f"_cached_{func.__name__}_time"

        @functools.wraps(func)
        def wrapper(self):
            now = time.time()

            # Check if cached and not expired
            if hasattr(self, attr_name):
                if ttl is None:
                    return getattr(self, attr_name)

                cached_time = getattr(self, time_attr, 0)
                if now - cached_time < ttl:
                    return getattr(self, attr_name)

            # Compute and cache
            result = func(self)
            setattr(self, attr_name, result)
            setattr(self, time_attr, now)
            return result

        # Make it work as a property
        wrapper.fget = func
        wrapper.cache_clear = lambda self: (
            delattr(self, attr_name) if hasattr(self, attr_name) else None,
            delattr(self, time_attr) if hasattr(self, time_attr) else None,
        )

        return property(wrapper)  # type: ignore

    return decorator


def memoize(maxsize: int = 128, typed: bool = False) -> Callable[[F], F]:
    """Simple memoization decorator.

    Uses LRU eviction when maxsize is reached.

    Args:
        maxsize: Maximum cached results
        typed: Consider argument types

    Returns:
        Decorated function

    Example:
        @memoize(maxsize=100)
        def fibonacci(n: int) -> int:
            if n < 2:
                return n
            return fibonacci(n-1) + fibonacci(n-2)
    """
    def decorator(func: F) -> F:
        from collections import OrderedDict

        cache: OrderedDict[str, Any] = OrderedDict()
        lock = threading.Lock()
        hits = 0
        misses = 0

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            nonlocal hits, misses

            key = _make_key(func, args, kwargs, typed=typed)

            with lock:
                if key in cache:
                    hits += 1
                    cache.move_to_end(key)
                    return cache[key]

            result = func(*args, **kwargs)

            with lock:
                misses += 1
                cache[key] = result
                cache.move_to_end(key)

                # Evict oldest if over size
                while len(cache) > maxsize:
                    cache.popitem(last=False)

            return result

        def cache_info() -> Dict[str, Any]:
            return {
                "hits": hits,
                "misses": misses,
                "size": len(cache),
                "maxsize": maxsize,
                "hit_rate": hits / (hits + misses) if (hits + misses) > 0 else 0,
            }

        def cache_clear():
            nonlocal hits, misses
            with lock:
                cache.clear()
                hits = 0
                misses = 0

        wrapper.cache_info = cache_info
        wrapper.cache_clear = cache_clear
        wrapper.__wrapped__ = func

        return wrapper  # type: ignore

    return decorator


def invalidate_on(
    *triggers: str,
    cache: Optional[Any] = None,
) -> Callable[[F], F]:
    """Decorator to invalidate cache on certain function calls.

    Args:
        *triggers: Function names that trigger invalidation
        cache: Cache instance to invalidate

    Returns:
        Decorated function
    """
    def decorator(func: F) -> F:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            result = func(*args, **kwargs)

            # Clear related caches
            if cache is not None:
                for trigger in triggers:
                    pattern = f"*{trigger}*"
                    keys = cache.keys(pattern)
                    cache.delete_many(keys)

            return result

        return wrapper  # type: ignore

    return decorator


__all__ = [
    "cached",
    "cached_property",
    "memoize",
    "invalidate_on",
]
