"""Timeout Action - Timeout handling.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import asyncio
import concurrent.futures
import functools
import logging
import signal
import threading
from dataclasses import dataclass
from datetime import timedelta
from typing import Any, Callable, Optional, TypeVar

logger = logging.getLogger(__name__)

T = TypeVar("T")


class TimeoutError(Exception):
    """Timeout exceeded error."""

    def __init__(self, message: str, timeout: float):
        super().__init__(message)
        self.timeout = timeout


@dataclass
class TimeoutHandler:
    """Timeout handler configuration."""

    timeout: float
    on_timeout: Optional[Callable[[float], None]] = None
    raise_on_timeout: bool = True
    default_value: Optional[Any] = None


class TimeoutAction:
    """Timeout action executor.

    Provides timeout capabilities for operations.
    """

    def __init__(self, handler: Optional[TimeoutHandler] = None, timeout: float = 30.0):
        self.handler = handler or TimeoutHandler(timeout=timeout)

    def execute(
        self,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> Optional[T]:
        """Execute function with timeout.

        Args:
            func: Function to execute
            *args: Function arguments
            **kwargs: Function keyword arguments

        Returns:
            Function result or default value on timeout
        """
        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(func, *args, **kwargs)

            try:
                return future.result(timeout=self.handler.timeout)
            except concurrent.futures.TimeoutError:
                if self.handler.on_timeout:
                    self.handler.on_timeout(self.handler.timeout)

                if self.handler.raise_on_timeout:
                    raise TimeoutError(
                        f"Operation timed out after {self.handler.timeout}s",
                        self.handler.timeout,
                    )

                return self.handler.default_value

    async def execute_async(
        self,
        func: Callable[..., T],
        *args,
        **kwargs,
    ) -> Optional[T]:
        """Execute async function with timeout."""
        try:
            if asyncio.iscoroutinefunction(func):
                return await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=self.handler.timeout,
                )
            else:
                loop = asyncio.get_event_loop()
                return await asyncio.wait_for(
                    loop.run_in_executor(None, lambda: func(*args, **kwargs)),
                    timeout=self.handler.timeout,
                )
        except asyncio.TimeoutError:
            if self.handler.on_timeout:
                self.handler.on_timeout(self.handler.timeout)

            if self.handler.raise_on_timeout:
                raise TimeoutError(
                    f"Operation timed out after {self.handler.timeout}s",
                    self.handler.timeout,
                )

            return self.handler.default_value


def timeout(
    seconds: float,
    on_timeout: Optional[Callable[[float], None]] = None,
    default: Optional[Any] = None,
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Decorator for timeout behavior.

    Usage:
        @timeout(30)
        def slow_operation():
            ...
    """
    handler = TimeoutHandler(
        timeout=seconds,
        on_timeout=on_timeout,
        raise_on_timeout=default is None,
        default_value=default,
    )
    action = TimeoutAction(handler)

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> T:
            return action.execute(func, *args, **kwargs)

        return wrapper

    return decorator


def timeout_async(
    seconds: float,
    default: Optional[Any] = None,
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Decorator for async timeout behavior."""
    handler = TimeoutHandler(
        timeout=seconds,
        raise_on_timeout=default is None,
        default_value=default,
    )
    action = TimeoutAction(handler)

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs) -> T:
            return await action.execute_async(func, *args, **kwargs)

        return wrapper

    return decorator


__all__ = [
    "TimeoutAction",
    "TimeoutHandler",
    "TimeoutError",
    "timeout",
    "timeout_async",
]
