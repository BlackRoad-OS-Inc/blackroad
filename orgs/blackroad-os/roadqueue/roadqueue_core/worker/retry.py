"""RoadQueue Retry Policy - Retry with Backoff Strategies.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import random
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Type

logger = logging.getLogger(__name__)


class BackoffStrategy(Enum):
    """Backoff strategies for retry."""

    FIXED = auto()         # Fixed delay
    LINEAR = auto()        # Linear increase
    EXPONENTIAL = auto()   # Exponential increase
    FIBONACCI = auto()     # Fibonacci sequence
    DECORRELATED = auto()  # Decorrelated jitter


@dataclass
class RetryConfig:
    """Retry configuration.

    Attributes:
        max_retries: Maximum retry attempts
        initial_delay_ms: Initial delay in milliseconds
        max_delay_ms: Maximum delay in milliseconds
        multiplier: Backoff multiplier
        jitter: Random jitter factor (0.0 to 1.0)
        strategy: Backoff strategy
        retryable_exceptions: Exceptions to retry
        fatal_exceptions: Exceptions to not retry
    """

    max_retries: int = 3
    initial_delay_ms: int = 1000
    max_delay_ms: int = 60000
    multiplier: float = 2.0
    jitter: float = 0.1
    strategy: BackoffStrategy = BackoffStrategy.EXPONENTIAL
    retryable_exceptions: Set[Type[Exception]] = field(default_factory=lambda: {Exception})
    fatal_exceptions: Set[Type[Exception]] = field(default_factory=set)


@dataclass
class RetryState:
    """State of a retry operation."""

    attempt: int = 0
    last_error: Optional[Exception] = None
    last_attempt_at: Optional[datetime] = None
    next_attempt_at: Optional[datetime] = None
    total_delay_ms: float = 0.0


class RetryPolicy:
    """Retry policy with configurable backoff.

    Features:
    - Multiple backoff strategies
    - Jitter for avoiding thundering herd
    - Exception filtering
    - Retry callbacks
    """

    def __init__(self, config: Optional[RetryConfig] = None):
        """Initialize retry policy.

        Args:
            config: Retry configuration
        """
        self.config = config or RetryConfig()
        self._fibonacci_cache = [0, 1]

    def should_retry(
        self,
        attempt: int,
        exception: Optional[Exception] = None,
    ) -> bool:
        """Check if should retry.

        Args:
            attempt: Current attempt number
            exception: The exception that occurred

        Returns:
            True if should retry
        """
        if attempt >= self.config.max_retries:
            return False

        if exception:
            # Check fatal exceptions
            for fatal in self.config.fatal_exceptions:
                if isinstance(exception, fatal):
                    return False

            # Check retryable exceptions
            for retryable in self.config.retryable_exceptions:
                if isinstance(exception, retryable):
                    return True

            # Default: retry on any exception if list is just {Exception}
            if Exception in self.config.retryable_exceptions:
                return True

            return False

        return True

    def get_delay_ms(self, attempt: int) -> float:
        """Calculate delay for attempt.

        Args:
            attempt: Attempt number (0-based)

        Returns:
            Delay in milliseconds
        """
        if attempt == 0:
            return 0

        base_delay = self._calculate_base_delay(attempt)

        # Add jitter
        if self.config.jitter > 0:
            jitter_range = base_delay * self.config.jitter
            jitter = random.uniform(-jitter_range, jitter_range)
            base_delay += jitter

        # Clamp to max
        return min(base_delay, self.config.max_delay_ms)

    def _calculate_base_delay(self, attempt: int) -> float:
        """Calculate base delay without jitter."""
        strategy = self.config.strategy
        initial = self.config.initial_delay_ms

        if strategy == BackoffStrategy.FIXED:
            return initial

        elif strategy == BackoffStrategy.LINEAR:
            return initial * attempt

        elif strategy == BackoffStrategy.EXPONENTIAL:
            return initial * (self.config.multiplier ** (attempt - 1))

        elif strategy == BackoffStrategy.FIBONACCI:
            return initial * self._fibonacci(attempt)

        elif strategy == BackoffStrategy.DECORRELATED:
            # Decorrelated jitter (AWS style)
            return random.uniform(initial, initial * 3 * attempt)

        return initial

    def _fibonacci(self, n: int) -> int:
        """Get nth Fibonacci number."""
        while len(self._fibonacci_cache) <= n:
            self._fibonacci_cache.append(
                self._fibonacci_cache[-1] + self._fibonacci_cache[-2]
            )
        return self._fibonacci_cache[n]

    def execute(
        self,
        func: Callable[[], Any],
        on_retry: Optional[Callable[[int, Exception, float], None]] = None,
        on_failure: Optional[Callable[[Exception, int], None]] = None,
    ) -> Any:
        """Execute function with retry.

        Args:
            func: Function to execute
            on_retry: Callback on retry (attempt, error, delay)
            on_failure: Callback on final failure (error, attempts)

        Returns:
            Function result

        Raises:
            Exception: If all retries exhausted
        """
        state = RetryState()
        last_exception = None

        while True:
            try:
                state.last_attempt_at = datetime.now()
                return func()

            except Exception as e:
                last_exception = e
                state.last_error = e
                state.attempt += 1

                if not self.should_retry(state.attempt, e):
                    if on_failure:
                        on_failure(e, state.attempt)
                    raise

                delay_ms = self.get_delay_ms(state.attempt)
                state.total_delay_ms += delay_ms
                state.next_attempt_at = datetime.now() + timedelta(
                    milliseconds=delay_ms
                )

                logger.warning(
                    f"Retry {state.attempt}/{self.config.max_retries} "
                    f"after {delay_ms:.0f}ms: {e}"
                )

                if on_retry:
                    on_retry(state.attempt, e, delay_ms)

                time.sleep(delay_ms / 1000)


class CircuitBreaker:
    """Circuit breaker pattern for failure protection.

    States:
    - CLOSED: Normal operation
    - OPEN: Blocking all calls
    - HALF_OPEN: Testing if service recovered
    """

    class State(Enum):
        CLOSED = auto()
        OPEN = auto()
        HALF_OPEN = auto()

    def __init__(
        self,
        failure_threshold: int = 5,
        success_threshold: int = 2,
        timeout_seconds: int = 30,
    ):
        """Initialize circuit breaker.

        Args:
            failure_threshold: Failures before opening
            success_threshold: Successes to close from half-open
            timeout_seconds: Time before trying again
        """
        self.failure_threshold = failure_threshold
        self.success_threshold = success_threshold
        self.timeout = timeout_seconds

        self._state = self.State.CLOSED
        self._failure_count = 0
        self._success_count = 0
        self._last_failure_time: Optional[datetime] = None

    @property
    def state(self) -> "CircuitBreaker.State":
        """Get current state."""
        if self._state == self.State.OPEN:
            # Check if timeout expired
            if self._last_failure_time:
                elapsed = (datetime.now() - self._last_failure_time).total_seconds()
                if elapsed >= self.timeout:
                    self._state = self.State.HALF_OPEN
                    self._success_count = 0
        return self._state

    def allow_request(self) -> bool:
        """Check if request is allowed."""
        state = self.state
        return state in (self.State.CLOSED, self.State.HALF_OPEN)

    def record_success(self) -> None:
        """Record successful call."""
        if self._state == self.State.HALF_OPEN:
            self._success_count += 1
            if self._success_count >= self.success_threshold:
                self._state = self.State.CLOSED
                self._failure_count = 0

    def record_failure(self) -> None:
        """Record failed call."""
        self._failure_count += 1
        self._last_failure_time = datetime.now()

        if self._state == self.State.HALF_OPEN:
            self._state = self.State.OPEN

        elif self._state == self.State.CLOSED:
            if self._failure_count >= self.failure_threshold:
                self._state = self.State.OPEN

    def execute(self, func: Callable[[], Any]) -> Any:
        """Execute with circuit breaker.

        Args:
            func: Function to execute

        Returns:
            Function result

        Raises:
            RuntimeError: If circuit is open
        """
        if not self.allow_request():
            raise RuntimeError("Circuit breaker is open")

        try:
            result = func()
            self.record_success()
            return result
        except Exception as e:
            self.record_failure()
            raise


class RetryWithCircuitBreaker:
    """Combines retry policy with circuit breaker."""

    def __init__(
        self,
        retry_config: Optional[RetryConfig] = None,
        failure_threshold: int = 5,
        circuit_timeout: int = 30,
    ):
        self.retry = RetryPolicy(retry_config)
        self.circuit = CircuitBreaker(
            failure_threshold=failure_threshold,
            timeout_seconds=circuit_timeout,
        )

    def execute(self, func: Callable[[], Any]) -> Any:
        """Execute with retry and circuit breaker."""
        return self.retry.execute(
            lambda: self.circuit.execute(func)
        )


def retry(
    max_retries: int = 3,
    delay_ms: int = 1000,
    strategy: BackoffStrategy = BackoffStrategy.EXPONENTIAL,
):
    """Decorator for automatic retry.

    Args:
        max_retries: Maximum attempts
        delay_ms: Initial delay
        strategy: Backoff strategy

    Returns:
        Decorated function
    """
    def decorator(func: Callable) -> Callable:
        policy = RetryPolicy(RetryConfig(
            max_retries=max_retries,
            initial_delay_ms=delay_ms,
            strategy=strategy,
        ))

        def wrapper(*args, **kwargs):
            return policy.execute(lambda: func(*args, **kwargs))

        return wrapper

    return decorator


__all__ = [
    "RetryPolicy",
    "RetryConfig",
    "RetryState",
    "BackoffStrategy",
    "CircuitBreaker",
    "RetryWithCircuitBreaker",
    "retry",
]
