"""
RoadThrottle - Rate Limiting for BlackRoad
Token bucket, sliding window, and adaptive rate limiting.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Tuple
import asyncio
import hashlib
import logging
import threading
import time

logger = logging.getLogger(__name__)


class ThrottleResult(str, Enum):
    """Result of throttle check."""
    ALLOWED = "allowed"
    THROTTLED = "throttled"
    BLOCKED = "blocked"


@dataclass
class ThrottleInfo:
    """Information about a throttle check."""
    result: ThrottleResult
    remaining: int
    limit: int
    reset_at: datetime
    retry_after: Optional[float] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class TokenBucket:
    """Token bucket rate limiter."""

    def __init__(
        self,
        capacity: int,
        refill_rate: float,
        refill_interval: float = 1.0
    ):
        self.capacity = capacity
        self.refill_rate = refill_rate
        self.refill_interval = refill_interval
        self.tokens = float(capacity)
        self.last_refill = time.time()
        self._lock = threading.Lock()

    def _refill(self) -> None:
        """Refill tokens based on elapsed time."""
        now = time.time()
        elapsed = now - self.last_refill
        intervals = elapsed / self.refill_interval

        self.tokens = min(
            self.capacity,
            self.tokens + (intervals * self.refill_rate)
        )
        self.last_refill = now

    def acquire(self, tokens: int = 1) -> ThrottleInfo:
        """Try to acquire tokens."""
        with self._lock:
            self._refill()

            if self.tokens >= tokens:
                self.tokens -= tokens
                return ThrottleInfo(
                    result=ThrottleResult.ALLOWED,
                    remaining=int(self.tokens),
                    limit=self.capacity,
                    reset_at=datetime.now() + timedelta(
                        seconds=self.refill_interval
                    )
                )

            # Calculate retry time
            needed = tokens - self.tokens
            retry_after = (needed / self.refill_rate) * self.refill_interval

            return ThrottleInfo(
                result=ThrottleResult.THROTTLED,
                remaining=0,
                limit=self.capacity,
                reset_at=datetime.now() + timedelta(seconds=retry_after),
                retry_after=retry_after
            )

    def get_tokens(self) -> float:
        """Get current token count."""
        with self._lock:
            self._refill()
            return self.tokens


class SlidingWindow:
    """Sliding window rate limiter."""

    def __init__(self, limit: int, window_seconds: float):
        self.limit = limit
        self.window_seconds = window_seconds
        self.requests: List[float] = []
        self._lock = threading.Lock()

    def _cleanup(self) -> None:
        """Remove old requests outside window."""
        cutoff = time.time() - self.window_seconds
        self.requests = [t for t in self.requests if t > cutoff]

    def acquire(self) -> ThrottleInfo:
        """Try to record a request."""
        with self._lock:
            self._cleanup()
            now = time.time()

            if len(self.requests) < self.limit:
                self.requests.append(now)
                return ThrottleInfo(
                    result=ThrottleResult.ALLOWED,
                    remaining=self.limit - len(self.requests),
                    limit=self.limit,
                    reset_at=datetime.now() + timedelta(
                        seconds=self.window_seconds
                    )
                )

            # Calculate when oldest request expires
            oldest = min(self.requests)
            retry_after = oldest + self.window_seconds - now

            return ThrottleInfo(
                result=ThrottleResult.THROTTLED,
                remaining=0,
                limit=self.limit,
                reset_at=datetime.now() + timedelta(seconds=retry_after),
                retry_after=max(0, retry_after)
            )

    def get_count(self) -> int:
        """Get current request count in window."""
        with self._lock:
            self._cleanup()
            return len(self.requests)


class FixedWindow:
    """Fixed window rate limiter."""

    def __init__(self, limit: int, window_seconds: float):
        self.limit = limit
        self.window_seconds = window_seconds
        self.count = 0
        self.window_start = time.time()
        self._lock = threading.Lock()

    def _check_window(self) -> None:
        """Reset window if expired."""
        now = time.time()
        if now - self.window_start >= self.window_seconds:
            self.count = 0
            self.window_start = now

    def acquire(self) -> ThrottleInfo:
        """Try to record a request."""
        with self._lock:
            self._check_window()
            now = time.time()

            if self.count < self.limit:
                self.count += 1
                window_end = self.window_start + self.window_seconds
                return ThrottleInfo(
                    result=ThrottleResult.ALLOWED,
                    remaining=self.limit - self.count,
                    limit=self.limit,
                    reset_at=datetime.fromtimestamp(window_end)
                )

            retry_after = self.window_start + self.window_seconds - now

            return ThrottleInfo(
                result=ThrottleResult.THROTTLED,
                remaining=0,
                limit=self.limit,
                reset_at=datetime.fromtimestamp(
                    self.window_start + self.window_seconds
                ),
                retry_after=max(0, retry_after)
            )


class LeakyBucket:
    """Leaky bucket rate limiter (smooths bursts)."""

    def __init__(self, capacity: int, leak_rate: float):
        self.capacity = capacity
        self.leak_rate = leak_rate  # requests per second
        self.water = 0.0
        self.last_leak = time.time()
        self._lock = threading.Lock()

    def _leak(self) -> None:
        """Leak water based on elapsed time."""
        now = time.time()
        elapsed = now - self.last_leak
        leaked = elapsed * self.leak_rate

        self.water = max(0, self.water - leaked)
        self.last_leak = now

    def acquire(self) -> ThrottleInfo:
        """Try to add a request (water drop)."""
        with self._lock:
            self._leak()

            if self.water < self.capacity:
                self.water += 1
                return ThrottleInfo(
                    result=ThrottleResult.ALLOWED,
                    remaining=int(self.capacity - self.water),
                    limit=self.capacity,
                    reset_at=datetime.now() + timedelta(
                        seconds=1 / self.leak_rate
                    )
                )

            # Calculate retry time
            retry_after = 1 / self.leak_rate

            return ThrottleInfo(
                result=ThrottleResult.THROTTLED,
                remaining=0,
                limit=self.capacity,
                reset_at=datetime.now() + timedelta(seconds=retry_after),
                retry_after=retry_after
            )


@dataclass
class RateLimitConfig:
    """Rate limit configuration."""
    requests_per_second: Optional[float] = None
    requests_per_minute: Optional[float] = None
    requests_per_hour: Optional[float] = None
    burst_limit: Optional[int] = None

    def to_token_bucket(self) -> TokenBucket:
        """Convert to token bucket config."""
        if self.requests_per_second:
            return TokenBucket(
                capacity=self.burst_limit or int(self.requests_per_second * 2),
                refill_rate=self.requests_per_second,
                refill_interval=1.0
            )
        elif self.requests_per_minute:
            return TokenBucket(
                capacity=self.burst_limit or int(self.requests_per_minute / 6),
                refill_rate=self.requests_per_minute / 60,
                refill_interval=1.0
            )
        elif self.requests_per_hour:
            return TokenBucket(
                capacity=self.burst_limit or int(self.requests_per_hour / 60),
                refill_rate=self.requests_per_hour / 3600,
                refill_interval=1.0
            )
        else:
            return TokenBucket(capacity=100, refill_rate=10)


class ThrottleStore:
    """Store throttle state per key."""

    def __init__(self, default_config: RateLimitConfig = None):
        self.default_config = default_config or RateLimitConfig(
            requests_per_minute=60
        )
        self.limiters: Dict[str, TokenBucket] = {}
        self._configs: Dict[str, RateLimitConfig] = {}
        self._lock = threading.Lock()

    def get_limiter(self, key: str) -> TokenBucket:
        """Get or create limiter for key."""
        with self._lock:
            if key not in self.limiters:
                config = self._configs.get(key, self.default_config)
                self.limiters[key] = config.to_token_bucket()
            return self.limiters[key]

    def set_config(self, key: str, config: RateLimitConfig) -> None:
        """Set custom config for a key."""
        with self._lock:
            self._configs[key] = config
            if key in self.limiters:
                del self.limiters[key]

    def acquire(self, key: str, tokens: int = 1) -> ThrottleInfo:
        """Acquire tokens for a key."""
        limiter = self.get_limiter(key)
        return limiter.acquire(tokens)

    def reset(self, key: str) -> None:
        """Reset limiter for a key."""
        with self._lock:
            if key in self.limiters:
                del self.limiters[key]

    def cleanup(self, max_age_seconds: float = 3600) -> int:
        """Remove stale limiters."""
        with self._lock:
            # In a real implementation, track last access time
            # For now, just return 0
            return 0


class AdaptiveThrottle:
    """Adaptive rate limiting based on system load."""

    def __init__(
        self,
        base_config: RateLimitConfig,
        min_rate: float = 0.1,
        max_rate: float = 10.0
    ):
        self.base_config = base_config
        self.min_rate = min_rate
        self.max_rate = max_rate
        self.current_rate = 1.0
        self.store = ThrottleStore(base_config)
        self._error_count = 0
        self._success_count = 0
        self._lock = threading.Lock()

    def record_success(self) -> None:
        """Record a successful request."""
        with self._lock:
            self._success_count += 1
            self._adjust_rate()

    def record_error(self) -> None:
        """Record a failed request."""
        with self._lock:
            self._error_count += 1
            self._adjust_rate()

    def _adjust_rate(self) -> None:
        """Adjust rate based on error ratio."""
        total = self._success_count + self._error_count
        if total < 10:
            return

        error_ratio = self._error_count / total

        if error_ratio > 0.1:
            # Too many errors, reduce rate
            self.current_rate = max(
                self.min_rate,
                self.current_rate * 0.9
            )
        elif error_ratio < 0.01:
            # Low errors, increase rate
            self.current_rate = min(
                self.max_rate,
                self.current_rate * 1.1
            )

        # Reset counters periodically
        if total > 1000:
            self._success_count = 0
            self._error_count = 0

    def acquire(self, key: str) -> ThrottleInfo:
        """Acquire with adaptive rate."""
        adjusted_tokens = max(1, int(1 / self.current_rate))
        return self.store.acquire(key, adjusted_tokens)


class ThrottleMiddleware:
    """Middleware for throttling."""

    def __init__(
        self,
        store: ThrottleStore,
        key_fn: Callable[[Any], str] = None,
        on_throttled: Callable[[ThrottleInfo], Any] = None
    ):
        self.store = store
        self.key_fn = key_fn or (lambda r: "default")
        self.on_throttled = on_throttled

    async def __call__(self, request: Any) -> Optional[ThrottleInfo]:
        """Check if request should be throttled."""
        key = self.key_fn(request)
        info = self.store.acquire(key)

        if info.result == ThrottleResult.THROTTLED:
            if self.on_throttled:
                return self.on_throttled(info)
            return info

        return None


class ThrottleManager:
    """High-level throttle management."""

    def __init__(self, default_config: RateLimitConfig = None):
        self.store = ThrottleStore(default_config)
        self._adaptive: Dict[str, AdaptiveThrottle] = {}

    def configure(
        self,
        key: str,
        requests_per_second: float = None,
        requests_per_minute: float = None,
        requests_per_hour: float = None,
        burst: int = None
    ) -> None:
        """Configure rate limit for a key."""
        config = RateLimitConfig(
            requests_per_second=requests_per_second,
            requests_per_minute=requests_per_minute,
            requests_per_hour=requests_per_hour,
            burst_limit=burst
        )
        self.store.set_config(key, config)

    def check(self, key: str, cost: int = 1) -> ThrottleInfo:
        """Check and consume rate limit."""
        return self.store.acquire(key, cost)

    def is_allowed(self, key: str, cost: int = 1) -> bool:
        """Simple boolean check."""
        info = self.check(key, cost)
        return info.result == ThrottleResult.ALLOWED

    def get_remaining(self, key: str) -> int:
        """Get remaining requests."""
        limiter = self.store.get_limiter(key)
        return int(limiter.get_tokens())

    def reset(self, key: str) -> None:
        """Reset rate limit for a key."""
        self.store.reset(key)

    def create_adaptive(self, name: str, base_config: RateLimitConfig = None) -> AdaptiveThrottle:
        """Create an adaptive throttle."""
        config = base_config or RateLimitConfig(requests_per_minute=60)
        throttle = AdaptiveThrottle(config)
        self._adaptive[name] = throttle
        return throttle

    def middleware(
        self,
        key_fn: Callable[[Any], str] = None,
        on_throttled: Callable[[ThrottleInfo], Any] = None
    ) -> ThrottleMiddleware:
        """Create middleware."""
        return ThrottleMiddleware(self.store, key_fn, on_throttled)

    def decorator(self, key: str = None, cost: int = 1):
        """Decorator for rate-limited functions."""
        def decorator_fn(fn: Callable):
            async def wrapper(*args, **kwargs):
                actual_key = key or fn.__name__
                info = self.check(actual_key, cost)

                if info.result == ThrottleResult.THROTTLED:
                    raise ThrottleError(info)

                return await fn(*args, **kwargs) if asyncio.iscoroutinefunction(fn) else fn(*args, **kwargs)

            return wrapper
        return decorator_fn


class ThrottleError(Exception):
    """Raised when request is throttled."""

    def __init__(self, info: ThrottleInfo):
        self.info = info
        super().__init__(
            f"Rate limit exceeded. Retry after {info.retry_after:.1f}s"
        )


# Example usage
async def example_usage():
    """Example throttle usage."""
    manager = ThrottleManager()

    # Configure different limits
    manager.configure("api", requests_per_minute=60, burst=10)
    manager.configure("search", requests_per_minute=20)
    manager.configure("expensive", requests_per_hour=100)

    # Check rate limits
    for i in range(5):
        info = manager.check("api")
        print(f"Request {i+1}: {info.result.value}, remaining: {info.remaining}")

    # Simple boolean check
    if manager.is_allowed("search"):
        print("Search allowed")

    # Decorator usage
    @manager.decorator(key="my_function", cost=1)
    async def expensive_operation():
        return "result"

    try:
        result = await expensive_operation()
        print(f"Result: {result}")
    except ThrottleError as e:
        print(f"Throttled: {e}")

    # Middleware
    def get_user_id(request):
        return request.get("user_id", "anonymous")

    middleware = manager.middleware(
        key_fn=get_user_id,
        on_throttled=lambda info: {"error": "rate_limited", "retry_after": info.retry_after}
    )

    # Simulate requests
    for user in ["user1", "user2", "user1"]:
        result = await middleware({"user_id": user})
        if result:
            print(f"User {user} throttled: {result}")

    # Adaptive throttling
    adaptive = manager.create_adaptive("external_api")

    for i in range(10):
        info = adaptive.acquire("external_api")
        if info.result == ThrottleResult.ALLOWED:
            # Simulate success/error
            if i % 3 == 0:
                adaptive.record_error()
            else:
                adaptive.record_success()

    print(f"Adaptive rate: {adaptive.current_rate:.2f}")

