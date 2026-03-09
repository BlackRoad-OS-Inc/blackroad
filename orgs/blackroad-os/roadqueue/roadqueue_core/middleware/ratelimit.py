"""RoadQueue Rate Limiter - Rate Limiting Middleware.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
from dataclasses import dataclass
from typing import Dict, Optional

from roadqueue_core.queue.message import Message
from roadqueue_core.middleware.pipeline import BaseMiddleware

logger = logging.getLogger(__name__)


@dataclass
class RateLimitConfig:
    """Rate limit configuration."""

    requests_per_second: float = 100.0
    burst_size: int = 10
    per_queue: bool = True


class TokenBucket:
    """Token bucket rate limiter."""

    def __init__(self, rate: float, capacity: int):
        self.rate = rate
        self.capacity = capacity
        self.tokens = float(capacity)
        self.last_update = time.time()
        self._lock = threading.Lock()

    def acquire(self, tokens: int = 1) -> bool:
        """Try to acquire tokens."""
        with self._lock:
            now = time.time()
            elapsed = now - self.last_update
            self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
            self.last_update = now

            if self.tokens >= tokens:
                self.tokens -= tokens
                return True
            return False

    def wait_for_token(self, timeout: float = 1.0) -> bool:
        """Wait for token availability."""
        start = time.time()
        while time.time() - start < timeout:
            if self.acquire():
                return True
            time.sleep(0.01)
        return False


class RateLimiter(BaseMiddleware):
    """Rate limiting middleware."""

    def __init__(self, config: Optional[RateLimitConfig] = None):
        self.config = config or RateLimitConfig()
        self._global_bucket = TokenBucket(
            self.config.requests_per_second,
            self.config.burst_size,
        )
        self._queue_buckets: Dict[str, TokenBucket] = {}
        self._lock = threading.Lock()

    def _get_bucket(self, queue_name: str) -> TokenBucket:
        """Get rate limit bucket for queue."""
        if not self.config.per_queue:
            return self._global_bucket

        with self._lock:
            if queue_name not in self._queue_buckets:
                self._queue_buckets[queue_name] = TokenBucket(
                    self.config.requests_per_second,
                    self.config.burst_size,
                )
            return self._queue_buckets[queue_name]

    def before_publish(self, message: Message) -> Optional[Message]:
        """Rate limit message publishing."""
        bucket = self._get_bucket(message.queue_name or "default")
        if bucket.acquire():
            return message
        logger.warning(f"Rate limit exceeded for queue {message.queue_name}")
        return None


__all__ = ["RateLimiter", "RateLimitConfig", "TokenBucket"]
