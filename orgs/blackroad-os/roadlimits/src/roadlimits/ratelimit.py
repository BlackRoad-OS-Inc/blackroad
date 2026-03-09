"""
RoadLimits - Rate Limiting & Quotas System for BlackRoad
Token bucket, sliding window, and quota management.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import asyncio
import hashlib
import logging
import threading
import time

logger = logging.getLogger(__name__)


class LimitStrategy(str, Enum):
    """Rate limiting strategies."""
    TOKEN_BUCKET = "token_bucket"
    SLIDING_WINDOW = "sliding_window"
    FIXED_WINDOW = "fixed_window"
    LEAKY_BUCKET = "leaky_bucket"


class LimitScope(str, Enum):
    """Scope for rate limits."""
    GLOBAL = "global"
    USER = "user"
    IP = "ip"
    API_KEY = "api_key"
    ENDPOINT = "endpoint"


@dataclass
class RateLimitConfig:
    """Rate limit configuration."""
    limit: int  # Maximum requests
    window: int  # Time window in seconds
    strategy: LimitStrategy = LimitStrategy.SLIDING_WINDOW
    scope: LimitScope = LimitScope.GLOBAL
    burst: Optional[int] = None  # Burst allowance for token bucket
    cost: int = 1  # Cost per request


@dataclass
class RateLimitResult:
    """Result of rate limit check."""
    allowed: bool
    remaining: int
    reset_at: datetime
    retry_after: Optional[int] = None
    limit: int = 0
    cost: int = 1

    def to_headers(self) -> Dict[str, str]:
        """Convert to HTTP headers."""
        headers = {
            "X-RateLimit-Limit": str(self.limit),
            "X-RateLimit-Remaining": str(max(0, self.remaining)),
            "X-RateLimit-Reset": str(int(self.reset_at.timestamp()))
        }
        if self.retry_after:
            headers["Retry-After"] = str(self.retry_after)
        return headers


class TokenBucket:
    """Token bucket rate limiter."""

    def __init__(self, capacity: int, refill_rate: float, refill_interval: float = 1.0):
        self.capacity = capacity
        self.refill_rate = refill_rate
        self.refill_interval = refill_interval
        self.tokens: Dict[str, float] = {}
        self.last_refill: Dict[str, float] = {}
        self._lock = threading.Lock()

    def _refill(self, key: str) -> None:
        """Refill tokens based on time elapsed."""
        now = time.time()
        last = self.last_refill.get(key, now)
        elapsed = now - last

        if elapsed >= self.refill_interval:
            tokens_to_add = (elapsed / self.refill_interval) * self.refill_rate
            self.tokens[key] = min(self.capacity, self.tokens.get(key, self.capacity) + tokens_to_add)
            self.last_refill[key] = now

    def consume(self, key: str, tokens: int = 1) -> Tuple[bool, int, float]:
        """Consume tokens, returns (allowed, remaining, wait_time)."""
        with self._lock:
            self._refill(key)

            current = self.tokens.get(key, self.capacity)

            if current >= tokens:
                self.tokens[key] = current - tokens
                return True, int(self.tokens[key]), 0

            # Calculate wait time
            needed = tokens - current
            wait_time = (needed / self.refill_rate) * self.refill_interval

            return False, 0, wait_time


class SlidingWindow:
    """Sliding window rate limiter."""

    def __init__(self, limit: int, window: int):
        self.limit = limit
        self.window = window
        self.requests: Dict[str, List[float]] = {}
        self._lock = threading.Lock()

    def _cleanup(self, key: str) -> None:
        """Remove expired requests."""
        now = time.time()
        cutoff = now - self.window

        if key in self.requests:
            self.requests[key] = [t for t in self.requests[key] if t > cutoff]

    def check(self, key: str, cost: int = 1) -> Tuple[bool, int, float]:
        """Check if request is allowed."""
        with self._lock:
            self._cleanup(key)

            current_count = len(self.requests.get(key, []))

            if current_count + cost <= self.limit:
                if key not in self.requests:
                    self.requests[key] = []

                now = time.time()
                for _ in range(cost):
                    self.requests[key].append(now)

                remaining = self.limit - len(self.requests[key])
                return True, remaining, 0

            # Calculate when oldest request expires
            if self.requests.get(key):
                oldest = min(self.requests[key])
                wait_time = (oldest + self.window) - time.time()
                return False, 0, max(0, wait_time)

            return False, 0, self.window


class FixedWindow:
    """Fixed window rate limiter."""

    def __init__(self, limit: int, window: int):
        self.limit = limit
        self.window = window
        self.counts: Dict[str, int] = {}
        self.window_start: Dict[str, float] = {}
        self._lock = threading.Lock()

    def _get_window(self, key: str) -> Tuple[int, float]:
        """Get current count and window start."""
        now = time.time()
        window_start = self.window_start.get(key, 0)

        if now - window_start >= self.window:
            # New window
            self.counts[key] = 0
            self.window_start[key] = now
            return 0, now

        return self.counts.get(key, 0), window_start

    def check(self, key: str, cost: int = 1) -> Tuple[bool, int, float]:
        """Check if request is allowed."""
        with self._lock:
            count, window_start = self._get_window(key)

            if count + cost <= self.limit:
                self.counts[key] = count + cost
                remaining = self.limit - self.counts[key]
                return True, remaining, 0

            # Calculate time until window resets
            wait_time = (window_start + self.window) - time.time()
            return False, 0, max(0, wait_time)


class LeakyBucket:
    """Leaky bucket rate limiter."""

    def __init__(self, capacity: int, leak_rate: float):
        self.capacity = capacity
        self.leak_rate = leak_rate
        self.levels: Dict[str, float] = {}
        self.last_leak: Dict[str, float] = {}
        self._lock = threading.Lock()

    def _leak(self, key: str) -> None:
        """Leak water from bucket."""
        now = time.time()
        last = self.last_leak.get(key, now)
        elapsed = now - last

        if key in self.levels:
            leaked = elapsed * self.leak_rate
            self.levels[key] = max(0, self.levels[key] - leaked)

        self.last_leak[key] = now

    def add(self, key: str, amount: int = 1) -> Tuple[bool, int, float]:
        """Add to bucket."""
        with self._lock:
            self._leak(key)

            current = self.levels.get(key, 0)

            if current + amount <= self.capacity:
                self.levels[key] = current + amount
                remaining = int(self.capacity - self.levels[key])
                return True, remaining, 0

            # Calculate wait time
            overflow = (current + amount) - self.capacity
            wait_time = overflow / self.leak_rate

            return False, 0, wait_time


class RateLimiter:
    """Main rate limiter with multiple strategies."""

    def __init__(self):
        self.configs: Dict[str, RateLimitConfig] = {}
        self.limiters: Dict[str, Union[TokenBucket, SlidingWindow, FixedWindow, LeakyBucket]] = {}
        self._lock = threading.Lock()

    def configure(self, name: str, config: RateLimitConfig) -> None:
        """Configure a rate limit."""
        with self._lock:
            self.configs[name] = config

            if config.strategy == LimitStrategy.TOKEN_BUCKET:
                burst = config.burst or config.limit
                refill_rate = config.limit / config.window
                self.limiters[name] = TokenBucket(burst, refill_rate)

            elif config.strategy == LimitStrategy.SLIDING_WINDOW:
                self.limiters[name] = SlidingWindow(config.limit, config.window)

            elif config.strategy == LimitStrategy.FIXED_WINDOW:
                self.limiters[name] = FixedWindow(config.limit, config.window)

            elif config.strategy == LimitStrategy.LEAKY_BUCKET:
                leak_rate = config.limit / config.window
                self.limiters[name] = LeakyBucket(config.limit, leak_rate)

    def _get_key(self, config: RateLimitConfig, identifier: str) -> str:
        """Generate rate limit key."""
        return f"{config.scope.value}:{identifier}"

    def check(
        self,
        name: str,
        identifier: str,
        cost: int = 1
    ) -> RateLimitResult:
        """Check rate limit."""
        config = self.configs.get(name)
        if not config:
            return RateLimitResult(
                allowed=True,
                remaining=999999,
                reset_at=datetime.now() + timedelta(hours=1),
                limit=999999
            )

        limiter = self.limiters.get(name)
        key = self._get_key(config, identifier)

        actual_cost = cost * config.cost

        if isinstance(limiter, TokenBucket):
            allowed, remaining, wait = limiter.consume(key, actual_cost)
        elif isinstance(limiter, (SlidingWindow, FixedWindow)):
            allowed, remaining, wait = limiter.check(key, actual_cost)
        elif isinstance(limiter, LeakyBucket):
            allowed, remaining, wait = limiter.add(key, actual_cost)
        else:
            return RateLimitResult(
                allowed=True,
                remaining=config.limit,
                reset_at=datetime.now() + timedelta(seconds=config.window),
                limit=config.limit
            )

        return RateLimitResult(
            allowed=allowed,
            remaining=remaining,
            reset_at=datetime.now() + timedelta(seconds=config.window),
            retry_after=int(wait) if wait > 0 else None,
            limit=config.limit,
            cost=actual_cost
        )

    async def check_async(self, name: str, identifier: str, cost: int = 1) -> RateLimitResult:
        """Async rate limit check."""
        return self.check(name, identifier, cost)


@dataclass
class QuotaConfig:
    """Quota configuration."""
    limit: int
    period: str  # "hour", "day", "week", "month"
    resource: str
    soft_limit: Optional[int] = None  # Warning threshold
    rollover: bool = False  # Unused quota rolls over


@dataclass
class QuotaUsage:
    """Current quota usage."""
    used: int
    limit: int
    remaining: int
    period_start: datetime
    period_end: datetime
    soft_limit_reached: bool = False
    hard_limit_reached: bool = False


class QuotaManager:
    """Manage usage quotas."""

    PERIOD_SECONDS = {
        "hour": 3600,
        "day": 86400,
        "week": 604800,
        "month": 2592000
    }

    def __init__(self):
        self.quotas: Dict[str, QuotaConfig] = {}
        self.usage: Dict[str, Dict[str, Tuple[int, datetime]]] = {}  # resource -> {user -> (count, period_start)}
        self._lock = threading.Lock()

    def configure(self, resource: str, config: QuotaConfig) -> None:
        """Configure a quota."""
        self.quotas[resource] = config

    def _get_period_start(self, period: str) -> datetime:
        """Get start of current period."""
        now = datetime.now()

        if period == "hour":
            return now.replace(minute=0, second=0, microsecond=0)
        elif period == "day":
            return now.replace(hour=0, minute=0, second=0, microsecond=0)
        elif period == "week":
            start = now - timedelta(days=now.weekday())
            return start.replace(hour=0, minute=0, second=0, microsecond=0)
        elif period == "month":
            return now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        return now

    def _get_period_end(self, period: str, start: datetime) -> datetime:
        """Get end of period."""
        seconds = self.PERIOD_SECONDS.get(period, 86400)
        return start + timedelta(seconds=seconds)

    def check(self, resource: str, user_id: str) -> QuotaUsage:
        """Check quota usage."""
        config = self.quotas.get(resource)
        if not config:
            return QuotaUsage(
                used=0,
                limit=999999,
                remaining=999999,
                period_start=datetime.now(),
                period_end=datetime.now() + timedelta(days=365)
            )

        with self._lock:
            period_start = self._get_period_start(config.period)
            period_end = self._get_period_end(config.period, period_start)

            if resource not in self.usage:
                self.usage[resource] = {}

            current = self.usage[resource].get(user_id)

            # Reset if new period
            if current is None or current[1] < period_start:
                # Handle rollover
                rollover = 0
                if config.rollover and current:
                    unused = config.limit - current[0]
                    rollover = max(0, unused)

                self.usage[resource][user_id] = (0 - rollover, period_start)
                current = self.usage[resource][user_id]

            used = current[0]
            remaining = config.limit - used
            soft_reached = config.soft_limit is not None and used >= config.soft_limit
            hard_reached = used >= config.limit

            return QuotaUsage(
                used=used,
                limit=config.limit,
                remaining=max(0, remaining),
                period_start=period_start,
                period_end=period_end,
                soft_limit_reached=soft_reached,
                hard_limit_reached=hard_reached
            )

    def consume(self, resource: str, user_id: str, amount: int = 1) -> QuotaUsage:
        """Consume quota."""
        usage = self.check(resource, user_id)

        if usage.hard_limit_reached:
            return usage

        with self._lock:
            current = self.usage[resource][user_id]
            new_used = current[0] + amount
            self.usage[resource][user_id] = (new_used, current[1])

        return self.check(resource, user_id)

    def reset(self, resource: str, user_id: str) -> None:
        """Reset usage for user."""
        with self._lock:
            if resource in self.usage:
                self.usage[resource].pop(user_id, None)


class AdaptiveRateLimiter:
    """Rate limiter that adapts based on system load."""

    def __init__(self, base_limit: int, window: int):
        self.base_limit = base_limit
        self.window = window
        self.current_limit = base_limit
        self.load_factor = 1.0
        self.limiter = SlidingWindow(base_limit, window)

    def set_load_factor(self, factor: float) -> None:
        """Adjust limits based on load (0.0 to 1.0)."""
        self.load_factor = max(0.1, min(1.0, factor))
        self.current_limit = int(self.base_limit * self.load_factor)
        self.limiter = SlidingWindow(self.current_limit, self.window)

    def check(self, key: str) -> RateLimitResult:
        """Check with adaptive limit."""
        allowed, remaining, wait = self.limiter.check(key)

        return RateLimitResult(
            allowed=allowed,
            remaining=remaining,
            reset_at=datetime.now() + timedelta(seconds=self.window),
            retry_after=int(wait) if wait > 0 else None,
            limit=self.current_limit
        )


class RateLimitMiddleware:
    """Middleware for rate limiting."""

    def __init__(self, limiter: RateLimiter):
        self.limiter = limiter
        self.key_extractors: Dict[str, Callable] = {}

    def add_key_extractor(self, scope: LimitScope, extractor: Callable) -> None:
        """Add key extractor for scope."""
        self.key_extractors[scope.value] = extractor

    def check(
        self,
        name: str,
        request: Any,
        scope: LimitScope = LimitScope.IP
    ) -> RateLimitResult:
        """Check rate limit for request."""
        extractor = self.key_extractors.get(scope.value, lambda r: "anonymous")
        identifier = extractor(request)
        return self.limiter.check(name, identifier)


# Decorator
def rate_limit(
    limiter: RateLimiter,
    name: str,
    identifier_fn: Callable[..., str]
):
    """Decorator for rate limiting."""
    def decorator(func: Callable) -> Callable:
        async def async_wrapper(*args, **kwargs):
            identifier = identifier_fn(*args, **kwargs)
            result = limiter.check(name, identifier)

            if not result.allowed:
                raise Exception(f"Rate limit exceeded. Retry after {result.retry_after}s")

            return await func(*args, **kwargs)

        def sync_wrapper(*args, **kwargs):
            identifier = identifier_fn(*args, **kwargs)
            result = limiter.check(name, identifier)

            if not result.allowed:
                raise Exception(f"Rate limit exceeded. Retry after {result.retry_after}s")

            return func(*args, **kwargs)

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator


# Example usage
def example_usage():
    """Example rate limiting usage."""
    limiter = RateLimiter()

    # Configure API rate limit
    limiter.configure("api", RateLimitConfig(
        limit=100,
        window=60,
        strategy=LimitStrategy.SLIDING_WINDOW,
        scope=LimitScope.API_KEY
    ))

    # Configure login rate limit
    limiter.configure("login", RateLimitConfig(
        limit=5,
        window=300,
        strategy=LimitStrategy.FIXED_WINDOW,
        scope=LimitScope.IP
    ))

    # Check limits
    result = limiter.check("api", "api_key_123")
    print(f"API allowed: {result.allowed}, remaining: {result.remaining}")

    result = limiter.check("login", "192.168.1.1")
    print(f"Login allowed: {result.allowed}, remaining: {result.remaining}")

    # Quota management
    quota_mgr = QuotaManager()

    quota_mgr.configure("api_calls", QuotaConfig(
        limit=10000,
        period="day",
        resource="api_calls",
        soft_limit=8000
    ))

    usage = quota_mgr.check("api_calls", "user-123")
    print(f"API quota: {usage.used}/{usage.limit}, remaining: {usage.remaining}")

    # Consume quota
    usage = quota_mgr.consume("api_calls", "user-123", 100)
    print(f"After consume: {usage.used}/{usage.limit}")
