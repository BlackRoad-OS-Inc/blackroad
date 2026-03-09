"""Tests for eviction policies.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import pytest

from roadcache_core.eviction.lru import LRUPolicy
from roadcache_core.eviction.lfu import LFUPolicy
from roadcache_core.eviction.arc import ARCPolicy


class TestLRUPolicy:
    """Tests for LRU eviction policy."""

    def test_basic_eviction(self):
        """Test basic LRU eviction."""
        policy = LRUPolicy(max_size=3)

        policy.on_insert("key1")
        policy.on_insert("key2")
        policy.on_insert("key3")

        # key1 is LRU
        assert policy.choose_eviction() == "key1"

    def test_access_updates_order(self):
        """Test that access updates recency."""
        policy = LRUPolicy(max_size=3)

        policy.on_insert("key1")
        policy.on_insert("key2")
        policy.on_insert("key3")

        # Access key1, making key2 the LRU
        policy.on_access("key1")

        assert policy.choose_eviction() == "key2"

    def test_delete_removes_key(self):
        """Test key deletion."""
        policy = LRUPolicy(max_size=3)

        policy.on_insert("key1")
        policy.on_insert("key2")

        policy.on_delete("key1")

        assert not policy.contains("key1")
        assert policy.contains("key2")

    def test_clear(self):
        """Test clearing policy."""
        policy = LRUPolicy()

        policy.on_insert("key1")
        policy.on_insert("key2")

        policy.clear()
        assert policy.size() == 0


class TestLFUPolicy:
    """Tests for LFU eviction policy."""

    def test_basic_eviction(self):
        """Test basic LFU eviction."""
        policy = LFUPolicy(max_size=3)

        policy.on_insert("key1")  # freq=1
        policy.on_insert("key2")  # freq=1
        policy.on_access("key2")  # freq=2

        # key1 has lower frequency
        assert policy.choose_eviction() == "key1"

    def test_frequency_tracking(self):
        """Test frequency tracking."""
        policy = LFUPolicy()

        policy.on_insert("key1")
        assert policy.get_frequency("key1") == 1

        policy.on_access("key1")
        assert policy.get_frequency("key1") == 2

        policy.on_access("key1")
        assert policy.get_frequency("key1") == 3


class TestARCPolicy:
    """Tests for ARC eviction policy."""

    def test_basic_operations(self):
        """Test basic ARC operations."""
        policy = ARCPolicy(max_size=4)

        policy.on_insert("key1")
        policy.on_insert("key2")

        assert policy.contains("key1")
        assert policy.contains("key2")

    def test_promotion_to_t2(self):
        """Test promotion from T1 to T2 on second access."""
        policy = ARCPolicy(max_size=4)

        policy.on_insert("key1")  # Goes to T1

        # Access promotes to T2
        policy.on_access("key1")

        # Should be in T2 now
        stats = policy.get_stats_detailed()
        assert stats["t2_size"] == 1

    def test_eviction_from_t1(self):
        """Test eviction from T1."""
        policy = ARCPolicy(max_size=2)

        policy.on_insert("key1")
        policy.on_insert("key2")
        policy.on_insert("key3")  # Should evict key1

        assert policy.size() <= 2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
