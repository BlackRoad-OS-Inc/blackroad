"""Retry Action - Retry strategies and implementations.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import asyncio
import functools
import logging
import random
import time
from dataclasses import dataclass
from datetime import timedelta
from enum import Enum
from typing import Any, Callable, List, Optional, Tuple, Type, TypeVar

logger = logging.getLogger(__name__)

T = TypeVar("T")


class BackoffStrategy(Enum):
    """Backoff strategies."""

    CONSTANT = "constant"
    LINEAR = "linear"
    EXPONENTIAL = "exponential"
    FIBONACCI = "fibonacci"
    DECORRELATED_JITTER = "decorrelated_jitter"


@dataclass
class RetryStrategy:
    """Retry strategy configuration."""

    max_retries: int = 3
    backoff: BackoffStrategy = BackoffStrategy.EXPONENTIAL
    base_delay: float = 1.0
    max_delay: float = 60.0
    exponential_base: float = 2.0
    jitter: bool = True
    jitter_factor: float = 0.1
    retry_on: Optional[Tuple[Type[Exception], ...]] = None
    ignore_on: Optional[Tuple[Type[Exception], ...]] = None

    def get_delay(self, attempt: int) -> float:
        """Calculate delay for attempt."""
        if self.backoff == BackoffStrategy.CONSTANT:
            delay = self.base_delay
        elif self.backoff == BackoffStrategy.LINEAR:
            delay = self.base_delay * (attempt + 1)
        elif self.backoff == BackoffStrategy.EXPONENTIAL:
            delay = self.base_delay * (self.exponential_base ** attempt)
        elif self.backoff == BackoffStrategy.FIBONACCI:
            delay = self.base_delay * self._fibonacci(attempt + 2)
        elif self.backoff == BackoffStrategy.DECORRELATED_JITTER:
            delay = min(self.max_delay, random.uniform(self.base_delay, self.base_delay * 3 * (2 ** attempt)))
        else:
            delay = self.base_delay

        delay = min(delay, self.max_delay)

        if self.jitter and self.backoff != BackoffStrategy.DECORRELATED_JITTER:
            jitter_range = delay * self.jitter_factor
            delay += random.uniform(-jitter_range, jitter_range)

        return max(0.0, delay)

    def _fibonacci(self, n: int) -> int:
        """Calculate fibonacci number."""
        if n <= 1:
            return n
        a, b = 0, 1
        for _ in range(2, n + 1):
            a, b = b, a + b
        return b

    def should_retry(self, exception: Exception, attempt: int) -> bool:
        """Determine if should retry."""
        if attempt >= self.max_retries:
            return False

        if self.ignore_on:
            for exc_type in self.ignore_on:
                if isinstance(exception, exc_type):
                    return False

        if self.retry_on:
            for exc_type in self.retry_on:
                if isinstance(exception, exc_type):
                    return True
            return False

        return True


class RetryAction:
    """Retry action executor.

    Provides retry capabilities with configurable strategies.
    """

    def __init__(
        self,
        strategy: Optional[RetryStrategy] = None,
        on_retry: Optional[Callable[[Exception, int], None]] = None,
        on_failure: Optional[Callable[[Exception], None]] = None,
    ):
        self.strategy = strategy or RetryStrategy()
        self.on_retry = on_retry
        self.on_failure = on_failure

    def execute(
        self,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> T:
        """Execute function with retry.

        Args:
            func: Function to execute
            *args: Function arguments
            **kwargs: Function keyword arguments

        Returns:
            Function result

        Raises:
            Last exception if all retries fail
        """
        last_exception: Optional[Exception] = None

        for attempt in range(self.strategy.max_retries + 1):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                last_exception = e

                if not self.strategy.should_retry(e, attempt):
                    break

                delay = self.strategy.get_delay(attempt)
                logger.warning(
                    f"Attempt {attempt + 1} failed, retrying in {delay:.2f}s: {e}"
                )

                if self.on_retry:
                    self.on_retry(e, attempt)

                time.sleep(delay)

        if self.on_failure and last_exception:
            self.on_failure(last_exception)

        raise last_exception  # type: ignore

    async def execute_async(
        self,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> T:
        """Execute async function with retry."""
        last_exception: Optional[Exception] = None

        for attempt in range(self.strategy.max_retries + 1):
            try:
                if asyncio.iscoroutinefunction(func):
                    return await func(*args, **kwargs)
                else:
                    return func(*args, **kwargs)
            except Exception as e:
                last_exception = e

                if not self.strategy.should_retry(e, attempt):
                    break

                delay = self.strategy.get_delay(attempt)

                if self.on_retry:
                    self.on_retry(e, attempt)

                await asyncio.sleep(delay)

        if self.on_failure and last_exception:
            self.on_failure(last_exception)

        raise last_exception  # type: ignore


def retry(
    max_retries: int = 3,
    backoff: BackoffStrategy = BackoffStrategy.EXPONENTIAL,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
    retry_on: Optional[Tuple[Type[Exception], ...]] = None,
    ignore_on: Optional[Tuple[Type[Exception], ...]] = None,
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Decorator for retry behavior.

    Usage:
        @retry(max_retries=5, backoff=BackoffStrategy.EXPONENTIAL)
        def flaky_operation():
            ...
    """
    strategy = RetryStrategy(
        max_retries=max_retries,
        backoff=backoff,
        base_delay=base_delay,
        max_delay=max_delay,
        retry_on=retry_on,
        ignore_on=ignore_on,
    )
    action = RetryAction(strategy)

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> T:
            return action.execute(func, *args, **kwargs)

        return wrapper

    return decorator


def retry_async(
    max_retries: int = 3,
    backoff: BackoffStrategy = BackoffStrategy.EXPONENTIAL,
    base_delay: float = 1.0,
    max_delay: float = 60.0,
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Decorator for async retry behavior."""
    strategy = RetryStrategy(
        max_retries=max_retries,
        backoff=backoff,
        base_delay=base_delay,
        max_delay=max_delay,
    )
    action = RetryAction(strategy)

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            return await action.execute_async(func, *args, **kwargs)

        return wrapper

    return decorator


__all__ = [
    "RetryAction",
    "RetryStrategy",
    "BackoffStrategy",
    "retry",
    "retry_async",
]
