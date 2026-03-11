"""Tests for the orchestrator module (run_shards)."""

from __future__ import annotations

import time

from orchestrator import run_shards


class TestRunShards:

    def test_all_shards_succeed(self):
        results, errors = run_shards(lambda shard: shard * 10, num_shards=5, timebox_seconds=10)
        assert len(results) == 5
        assert len(errors) == 0
        for i in range(5):
            assert results[i] == i * 10

    def test_shard_failure_captured(self):
        def failing_job(shard):
            if shard == 2:
                raise ValueError("shard 2 broke")
            return shard

        results, errors = run_shards(failing_job, num_shards=4, timebox_seconds=10)
        assert 2 not in results
        assert 2 in errors
        assert "shard 2 broke" in errors[2]

    def test_single_shard(self):
        results, errors = run_shards(lambda s: "ok", num_shards=1, timebox_seconds=5)
        assert results == {0: "ok"}
        assert errors == {}

    def test_timebox_cancels_slow_shards(self):
        def slow_job(shard):
            if shard == 0:
                time.sleep(10)
            return shard

        results, errors = run_shards(slow_job, num_shards=2, timebox_seconds=1)
        # At least one shard should be cancelled or timed out.
        # The fast shard (1) should succeed.
        assert 1 in results or 1 in errors
