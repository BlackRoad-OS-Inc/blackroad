"""
RoadRetry - Retry Logic for BlackRoad
Retry failed operations with backoff strategies.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from functools import wraps
from typing import Any, Callable, Dict, List, Optional, Tuple, Type, Union
import asyncio
import logging
import random
import time

logger = logging.getLogger(__name__)


class BackoffStrategy(str, Enum):
    FIXED = "fixed"
    LINEAR = "linear"
    EXPONENTIAL = "exponential"
    FIBONACCI = "fibonacci"
    RANDOM = "random"


@dataclass
class RetryConfig:
    max_attempts: int = 3
    backoff: BackoffStrategy = BackoffStrategy.EXPONENTIAL
    initial_delay: float = 1.0
    max_delay: float = 60.0
    jitter: bool = True
    jitter_factor: float = 0.25
    exceptions: Tuple[Type[Exception], ...] = (Exception,)
    on_retry: Optional[Callable] = None
    on_failure: Optional[Callable] = None


@dataclass
class RetryAttempt:
    attempt: int
    started_at: datetime
    ended_at: Optional[datetime] = None
    success: bool = False
    error: Optional[str] = None
    duration_ms: float = 0


@dataclass
class RetryResult:
    success: bool
    attempts: List[RetryAttempt]
    result: Any = None
    final_error: Optional[str] = None
    total_duration_ms: float = 0


class Backoff:
    @staticmethod
    def calculate(strategy: BackoffStrategy, attempt: int, initial_delay: float, max_delay: float) -> float:
        if strategy == BackoffStrategy.FIXED:
            delay = initial_delay
        elif strategy == BackoffStrategy.LINEAR:
            delay = initial_delay * attempt
        elif strategy == BackoffStrategy.EXPONENTIAL:
            delay = initial_delay * (2 ** (attempt - 1))
        elif strategy == BackoffStrategy.FIBONACCI:
            delay = initial_delay * Backoff._fibonacci(attempt)
        elif strategy == BackoffStrategy.RANDOM:
            delay = random.uniform(initial_delay, max_delay)
        else:
            delay = initial_delay
        
        return min(delay, max_delay)

    @staticmethod
    def _fibonacci(n: int) -> int:
        if n <= 1:
            return n
        a, b = 0, 1
        for _ in range(2, n + 1):
            a, b = b, a + b
        return b

    @staticmethod
    def add_jitter(delay: float, factor: float = 0.25) -> float:
        jitter = delay * factor * random.random()
        return delay + jitter


class Retrier:
    def __init__(self, config: RetryConfig = None):
        self.config = config or RetryConfig()

    def call(self, fn: Callable, *args, **kwargs) -> RetryResult:
        start_time = time.time()
        attempts = []
        result = None
        final_error = None

        for attempt in range(1, self.config.max_attempts + 1):
            attempt_start = time.time()
            retry_attempt = RetryAttempt(attempt=attempt, started_at=datetime.now())
            
            try:
                result = fn(*args, **kwargs)
                retry_attempt.success = True
                retry_attempt.ended_at = datetime.now()
                retry_attempt.duration_ms = (time.time() - attempt_start) * 1000
                attempts.append(retry_attempt)
                
                return RetryResult(
                    success=True,
                    attempts=attempts,
                    result=result,
                    total_duration_ms=(time.time() - start_time) * 1000
                )
            
            except self.config.exceptions as e:
                retry_attempt.error = str(e)
                retry_attempt.ended_at = datetime.now()
                retry_attempt.duration_ms = (time.time() - attempt_start) * 1000
                attempts.append(retry_attempt)
                final_error = str(e)
                
                logger.warning(f"Attempt {attempt}/{self.config.max_attempts} failed: {e}")
                
                if self.config.on_retry:
                    self.config.on_retry(attempt, e)
                
                if attempt < self.config.max_attempts:
                    delay = Backoff.calculate(
                        self.config.backoff,
                        attempt,
                        self.config.initial_delay,
                        self.config.max_delay
                    )
                    if self.config.jitter:
                        delay = Backoff.add_jitter(delay, self.config.jitter_factor)
                    
                    logger.debug(f"Waiting {delay:.2f}s before retry")
                    time.sleep(delay)

        if self.config.on_failure:
            self.config.on_failure(attempts)
        
        return RetryResult(
            success=False,
            attempts=attempts,
            final_error=final_error,
            total_duration_ms=(time.time() - start_time) * 1000
        )

    async def call_async(self, fn: Callable, *args, **kwargs) -> RetryResult:
        start_time = time.time()
        attempts = []
        result = None
        final_error = None

        for attempt in range(1, self.config.max_attempts + 1):
            attempt_start = time.time()
            retry_attempt = RetryAttempt(attempt=attempt, started_at=datetime.now())
            
            try:
                result = fn(*args, **kwargs)
                if asyncio.iscoroutine(result):
                    result = await result
                
                retry_attempt.success = True
                retry_attempt.ended_at = datetime.now()
                retry_attempt.duration_ms = (time.time() - attempt_start) * 1000
                attempts.append(retry_attempt)
                
                return RetryResult(
                    success=True,
                    attempts=attempts,
                    result=result,
                    total_duration_ms=(time.time() - start_time) * 1000
                )
            
            except self.config.exceptions as e:
                retry_attempt.error = str(e)
                retry_attempt.ended_at = datetime.now()
                retry_attempt.duration_ms = (time.time() - attempt_start) * 1000
                attempts.append(retry_attempt)
                final_error = str(e)
                
                if attempt < self.config.max_attempts:
                    delay = Backoff.calculate(
                        self.config.backoff,
                        attempt,
                        self.config.initial_delay,
                        self.config.max_delay
                    )
                    if self.config.jitter:
                        delay = Backoff.add_jitter(delay, self.config.jitter_factor)
                    await asyncio.sleep(delay)

        return RetryResult(
            success=False,
            attempts=attempts,
            final_error=final_error,
            total_duration_ms=(time.time() - start_time) * 1000
        )


def retry(max_attempts: int = 3, backoff: BackoffStrategy = BackoffStrategy.EXPONENTIAL, initial_delay: float = 1.0, max_delay: float = 60.0, exceptions: Tuple[Type[Exception], ...] = (Exception,), **kwargs) -> Callable:
    def decorator(fn: Callable) -> Callable:
        config = RetryConfig(
            max_attempts=max_attempts,
            backoff=backoff,
            initial_delay=initial_delay,
            max_delay=max_delay,
            exceptions=exceptions,
            **kwargs
        )
        retrier = Retrier(config)
        
        @wraps(fn)
        def wrapper(*args, **kw):
            result = retrier.call(fn, *args, **kw)
            if result.success:
                return result.result
            raise RuntimeError(f"All {max_attempts} attempts failed: {result.final_error}")
        
        @wraps(fn)
        async def async_wrapper(*args, **kw):
            result = await retrier.call_async(fn, *args, **kw)
            if result.success:
                return result.result
            raise RuntimeError(f"All {max_attempts} attempts failed: {result.final_error}")
        
        if asyncio.iscoroutinefunction(fn):
            return async_wrapper
        return wrapper
    
    return decorator


class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, recovery_time: int = 30, half_open_requests: int = 3):
        self.failure_threshold = failure_threshold
        self.recovery_time = recovery_time
        self.half_open_requests = half_open_requests
        self.failures = 0
        self.successes = 0
        self.state = "closed"
        self.last_failure_time: Optional[datetime] = None
        self.half_open_count = 0

    def call(self, fn: Callable, *args, **kwargs) -> Any:
        if self.state == "open":
            if self._should_try_reset():
                self.state = "half-open"
                self.half_open_count = 0
            else:
                raise RuntimeError("Circuit breaker is open")
        
        try:
            result = fn(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise

    def _should_try_reset(self) -> bool:
        if self.last_failure_time is None:
            return True
        return datetime.now() - self.last_failure_time > timedelta(seconds=self.recovery_time)

    def _on_success(self) -> None:
        if self.state == "half-open":
            self.half_open_count += 1
            if self.half_open_count >= self.half_open_requests:
                self.state = "closed"
                self.failures = 0
        self.successes += 1

    def _on_failure(self) -> None:
        self.failures += 1
        self.last_failure_time = datetime.now()
        
        if self.state == "half-open":
            self.state = "open"
        elif self.failures >= self.failure_threshold:
            self.state = "open"
            logger.warning("Circuit breaker opened")


def example_usage():
    call_count = 0
    
    @retry(max_attempts=3, initial_delay=0.1)
    def flaky_function():
        nonlocal call_count
        call_count += 1
        if call_count < 3:
            raise ConnectionError(f"Attempt {call_count} failed")
        return "Success!"
    
    try:
        result = flaky_function()
        print(f"Result: {result}")
        print(f"Total calls: {call_count}")
    except RuntimeError as e:
        print(f"Failed: {e}")
    
    config = RetryConfig(
        max_attempts=5,
        backoff=BackoffStrategy.EXPONENTIAL,
        initial_delay=0.1,
        max_delay=5.0,
        jitter=True
    )
    retrier = Retrier(config)
    
    def network_call():
        return {"data": "response"}
    
    result = retrier.call(network_call)
    print(f"\nRetrier result: success={result.success}, attempts={len(result.attempts)}")
    
    breaker = CircuitBreaker(failure_threshold=3, recovery_time=10)
    
    def unreliable_service():
        if random.random() < 0.7:
            raise ConnectionError("Service unavailable")
        return "OK"
    
    for i in range(10):
        try:
            result = breaker.call(unreliable_service)
            print(f"Call {i+1}: {result}")
        except Exception as e:
            print(f"Call {i+1}: {e}")
        print(f"  Circuit state: {breaker.state}")

