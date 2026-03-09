"""Tests for Cache class.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import time
import threading
import pytest

from roadcache_core.cache.cache import Cache, CacheConfig


class TestCache:
    """Tests for Cache class."""

    def test_basic_operations(self):
        """Test get/set/delete."""
        cache = Cache()

        # Set and get
        cache.set("key1", "value1")
        assert cache.get("key1") == "value1"

        # Delete
        assert cache.delete("key1")
        assert cache.get("key1") is None

    def test_ttl_expiration(self):
        """Test TTL expiration."""
        cache = Cache()

        cache.set("key", "value", ttl=0.1)
        assert cache.get("key") == "value"

        time.sleep(0.2)
        assert cache.get("key") is None

    def test_default_value(self):
        """Test default value on miss."""
        cache = Cache()

        assert cache.get("missing", default="default") == "default"

    def test_exists(self):
        """Test exists method."""
        cache = Cache()

        assert not cache.exists("key")
        cache.set("key", "value")
        assert cache.exists("key")

    def test_clear(self):
        """Test clear method."""
        cache = Cache()

        cache.set("key1", "value1")
        cache.set("key2", "value2")

        count = cache.clear()
        assert count == 2
        assert cache.size() == 0

    def test_keys_pattern(self):
        """Test keys with pattern."""
        cache = Cache()

        cache.set("user:1", "alice")
        cache.set("user:2", "bob")
        cache.set("session:1", "xyz")

        user_keys = cache.keys("user:*")
        assert len(user_keys) == 2
        assert "user:1" in user_keys
        assert "user:2" in user_keys

    def test_get_many(self):
        """Test get_many."""
        cache = Cache()

        cache.set("key1", "value1")
        cache.set("key2", "value2")

        result = cache.get_many(["key1", "key2", "key3"])
        assert result == {"key1": "value1", "key2": "value2"}

    def test_set_many(self):
        """Test set_many."""
        cache = Cache()

        count = cache.set_many({"key1": "value1", "key2": "value2"})
        assert count == 2
        assert cache.get("key1") == "value1"

    def test_increment(self):
        """Test increment."""
        cache = Cache()

        assert cache.increment("counter") == 1
        assert cache.increment("counter") == 2
        assert cache.increment("counter", delta=5) == 7

    def test_decrement(self):
        """Test decrement."""
        cache = Cache()

        cache.set("counter", 10)
        assert cache.decrement("counter") == 9
        assert cache.decrement("counter", delta=5) == 4

    def test_get_or_set(self):
        """Test get_or_set."""
        cache = Cache()
        called = [0]

        def factory():
            called[0] += 1
            return "computed"

        # First call computes
        result = cache.get_or_set("key", factory)
        assert result == "computed"
        assert called[0] == 1

        # Second call uses cache
        result = cache.get_or_set("key", factory)
        assert result == "computed"
        assert called[0] == 1

    def test_max_size_eviction(self):
        """Test eviction at max size."""
        cache = Cache(CacheConfig(max_size=3))

        cache.set("key1", "value1")
        cache.set("key2", "value2")
        cache.set("key3", "value3")
        cache.set("key4", "value4")  # Should evict key1

        assert cache.size() == 3
        assert cache.get("key1") is None  # Evicted

    def test_if_not_exists(self):
        """Test if_not_exists flag."""
        cache = Cache()

        cache.set("key", "original")
        success = cache.set("key", "updated", if_not_exists=True)

        assert not success
        assert cache.get("key") == "original"

    def test_if_exists(self):
        """Test if_exists flag."""
        cache = Cache()

        success = cache.set("key", "value", if_exists=True)
        assert not success
        assert cache.get("key") is None

    def test_stats(self):
        """Test statistics."""
        cache = Cache()

        cache.set("key", "value")
        cache.get("key")
        cache.get("key")
        cache.get("missing")

        stats = cache.get_stats()
        assert stats.hits == 2
        assert stats.misses == 1
        assert stats.sets == 1

    def test_thread_safety(self):
        """Test thread safety."""
        cache = Cache()
        errors = []

        def worker(n):
            try:
                for i in range(100):
                    key = f"key-{n}-{i}"
                    cache.set(key, i)
                    cache.get(key)
                    cache.delete(key)
            except Exception as e:
                errors.append(e)

        threads = [threading.Thread(target=worker, args=(n,)) for n in range(10)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert not errors

    def test_cached_decorator(self):
        """Test cached decorator."""
        cache = Cache()
        calls = [0]

        @cache.cached(ttl=60)
        def expensive():
            calls[0] += 1
            return "result"

        assert expensive() == "result"
        assert expensive() == "result"
        assert calls[0] == 1

    def test_namespace(self):
        """Test namespace isolation."""
        cache = Cache()

        users = cache.namespace("users")
        sessions = cache.namespace("sessions")

        users.set("1", "alice")
        sessions.set("1", "xyz")

        assert users.get("1") == "alice"
        assert sessions.get("1") == "xyz"

        users.clear()
        assert users.get("1") is None
        assert sessions.get("1") == "xyz"

    def test_context_manager(self):
        """Test context manager."""
        with Cache() as cache:
            cache.set("key", "value")
            assert cache.get("key") == "value"


class TestCacheStats:
    """Tests for cache statistics."""

    def test_hit_rate(self):
        """Test hit rate calculation."""
        cache = Cache()

        cache.set("key", "value")
        cache.get("key")  # hit
        cache.get("key")  # hit
        cache.get("missing")  # miss

        stats = cache.get_stats()
        assert stats.hit_rate == pytest.approx(2/3, rel=0.01)

    def test_reset_stats(self):
        """Test stats reset."""
        cache = Cache()

        cache.set("key", "value")
        cache.get("key")

        cache.reset_stats()
        stats = cache.get_stats()

        assert stats.hits == 0
        assert stats.misses == 0
        assert stats.sets == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
