"""
RoadHealth - Health Check & Readiness System for BlackRoad
Comprehensive health monitoring with liveness, readiness, and startup probes.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Union
import asyncio
import logging
import threading
import time

logger = logging.getLogger(__name__)


class HealthStatus(str, Enum):
    """Health check status."""
    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    DEGRADED = "degraded"
    UNKNOWN = "unknown"


class CheckType(str, Enum):
    """Types of health checks."""
    LIVENESS = "liveness"
    READINESS = "readiness"
    STARTUP = "startup"


@dataclass
class CheckResult:
    """Result of a health check."""
    name: str
    status: HealthStatus
    message: str = ""
    duration_ms: float = 0
    timestamp: datetime = field(default_factory=datetime.now)
    details: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "status": self.status.value,
            "message": self.message,
            "duration_ms": self.duration_ms,
            "timestamp": self.timestamp.isoformat(),
            "details": self.details
        }


@dataclass
class HealthReport:
    """Aggregated health report."""
    status: HealthStatus
    checks: List[CheckResult]
    timestamp: datetime = field(default_factory=datetime.now)
    version: Optional[str] = None
    uptime_seconds: Optional[float] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "status": self.status.value,
            "timestamp": self.timestamp.isoformat(),
            "version": self.version,
            "uptime_seconds": self.uptime_seconds,
            "checks": [c.to_dict() for c in self.checks]
        }


class HealthCheck:
    """A health check definition."""

    def __init__(
        self,
        name: str,
        check_fn: Callable[[], Union[bool, CheckResult]],
        check_type: CheckType = CheckType.READINESS,
        timeout: float = 5.0,
        interval: float = 30.0,
        failure_threshold: int = 3,
        success_threshold: int = 1,
        tags: Optional[Set[str]] = None
    ):
        self.name = name
        self.check_fn = check_fn
        self.check_type = check_type
        self.timeout = timeout
        self.interval = interval
        self.failure_threshold = failure_threshold
        self.success_threshold = success_threshold
        self.tags = tags or set()

        self._consecutive_failures = 0
        self._consecutive_successes = 0
        self._last_result: Optional[CheckResult] = None
        self._last_check_time: Optional[datetime] = None

    def execute(self) -> CheckResult:
        """Execute the health check."""
        start_time = time.time()

        try:
            result = self.check_fn()
            duration_ms = (time.time() - start_time) * 1000

            if isinstance(result, CheckResult):
                result.duration_ms = duration_ms
                check_result = result
            elif result is True:
                check_result = CheckResult(
                    name=self.name,
                    status=HealthStatus.HEALTHY,
                    duration_ms=duration_ms
                )
            else:
                check_result = CheckResult(
                    name=self.name,
                    status=HealthStatus.UNHEALTHY,
                    message=str(result) if result else "Check failed",
                    duration_ms=duration_ms
                )

        except asyncio.TimeoutError:
            check_result = CheckResult(
                name=self.name,
                status=HealthStatus.UNHEALTHY,
                message=f"Timeout after {self.timeout}s",
                duration_ms=self.timeout * 1000
            )

        except Exception as e:
            check_result = CheckResult(
                name=self.name,
                status=HealthStatus.UNHEALTHY,
                message=str(e),
                duration_ms=(time.time() - start_time) * 1000
            )

        # Update thresholds
        if check_result.status == HealthStatus.HEALTHY:
            self._consecutive_successes += 1
            self._consecutive_failures = 0
        else:
            self._consecutive_failures += 1
            self._consecutive_successes = 0

        self._last_result = check_result
        self._last_check_time = datetime.now()

        return check_result

    async def execute_async(self) -> CheckResult:
        """Execute health check asynchronously with timeout."""
        try:
            if asyncio.iscoroutinefunction(self.check_fn):
                result = await asyncio.wait_for(
                    self.check_fn(),
                    timeout=self.timeout
                )
            else:
                loop = asyncio.get_event_loop()
                result = await asyncio.wait_for(
                    loop.run_in_executor(None, self.execute),
                    timeout=self.timeout
                )
            return result if isinstance(result, CheckResult) else self.execute()
        except asyncio.TimeoutError:
            return CheckResult(
                name=self.name,
                status=HealthStatus.UNHEALTHY,
                message=f"Timeout after {self.timeout}s"
            )

    def is_healthy(self) -> bool:
        """Check if considered healthy based on thresholds."""
        if self._consecutive_failures >= self.failure_threshold:
            return False
        if self._consecutive_successes >= self.success_threshold:
            return True
        return self._last_result.status == HealthStatus.HEALTHY if self._last_result else False


class HealthChecker:
    """Manage and execute health checks."""

    def __init__(self, version: Optional[str] = None):
        self.version = version
        self.start_time = datetime.now()
        self._checks: Dict[str, HealthCheck] = {}
        self._lock = threading.Lock()
        self._running = False
        self._background_task: Optional[asyncio.Task] = None

    def register(self, check: HealthCheck) -> None:
        """Register a health check."""
        with self._lock:
            self._checks[check.name] = check
            logger.info(f"Registered health check: {check.name}")

    def register_fn(
        self,
        name: str,
        check_fn: Callable,
        check_type: CheckType = CheckType.READINESS,
        **kwargs
    ) -> HealthCheck:
        """Register a check function."""
        check = HealthCheck(name, check_fn, check_type, **kwargs)
        self.register(check)
        return check

    def unregister(self, name: str) -> bool:
        """Unregister a health check."""
        with self._lock:
            if name in self._checks:
                del self._checks[name]
                return True
            return False

    def _aggregate_status(self, results: List[CheckResult]) -> HealthStatus:
        """Aggregate check results into overall status."""
        if not results:
            return HealthStatus.UNKNOWN

        has_unhealthy = any(r.status == HealthStatus.UNHEALTHY for r in results)
        has_degraded = any(r.status == HealthStatus.DEGRADED for r in results)

        if has_unhealthy:
            return HealthStatus.UNHEALTHY
        if has_degraded:
            return HealthStatus.DEGRADED
        return HealthStatus.HEALTHY

    def check(
        self,
        check_type: Optional[CheckType] = None,
        tags: Optional[Set[str]] = None
    ) -> HealthReport:
        """Execute health checks and return report."""
        results = []

        with self._lock:
            for check in self._checks.values():
                if check_type and check.check_type != check_type:
                    continue
                if tags and not tags.intersection(check.tags):
                    continue

                result = check.execute()
                results.append(result)

        uptime = (datetime.now() - self.start_time).total_seconds()

        return HealthReport(
            status=self._aggregate_status(results),
            checks=results,
            version=self.version,
            uptime_seconds=uptime
        )

    async def check_async(
        self,
        check_type: Optional[CheckType] = None,
        tags: Optional[Set[str]] = None
    ) -> HealthReport:
        """Execute health checks asynchronously."""
        tasks = []

        with self._lock:
            for check in self._checks.values():
                if check_type and check.check_type != check_type:
                    continue
                if tags and not tags.intersection(check.tags):
                    continue

                tasks.append(check.execute_async())

        results = await asyncio.gather(*tasks, return_exceptions=True)

        check_results = []
        for result in results:
            if isinstance(result, CheckResult):
                check_results.append(result)
            elif isinstance(result, Exception):
                check_results.append(CheckResult(
                    name="unknown",
                    status=HealthStatus.UNHEALTHY,
                    message=str(result)
                ))

        uptime = (datetime.now() - self.start_time).total_seconds()

        return HealthReport(
            status=self._aggregate_status(check_results),
            checks=check_results,
            version=self.version,
            uptime_seconds=uptime
        )

    def liveness(self) -> HealthReport:
        """Check liveness probes."""
        return self.check(check_type=CheckType.LIVENESS)

    def readiness(self) -> HealthReport:
        """Check readiness probes."""
        return self.check(check_type=CheckType.READINESS)

    def startup(self) -> HealthReport:
        """Check startup probes."""
        return self.check(check_type=CheckType.STARTUP)

    async def _background_check_loop(self) -> None:
        """Background check loop."""
        while self._running:
            for check in list(self._checks.values()):
                if self._should_run_check(check):
                    await check.execute_async()
            await asyncio.sleep(1)

    def _should_run_check(self, check: HealthCheck) -> bool:
        """Check if a check should run based on interval."""
        if check._last_check_time is None:
            return True
        elapsed = (datetime.now() - check._last_check_time).total_seconds()
        return elapsed >= check.interval

    async def start_background_checks(self) -> None:
        """Start background health checking."""
        self._running = True
        self._background_task = asyncio.create_task(self._background_check_loop())
        logger.info("Started background health checks")

    async def stop_background_checks(self) -> None:
        """Stop background health checking."""
        self._running = False
        if self._background_task:
            self._background_task.cancel()
            try:
                await self._background_task
            except asyncio.CancelledError:
                pass
        logger.info("Stopped background health checks")


# Built-in checks
class CommonChecks:
    """Common health check implementations."""

    @staticmethod
    def memory_check(threshold_mb: int = 1000) -> Callable[[], CheckResult]:
        """Check memory usage."""
        def check() -> CheckResult:
            try:
                import resource
                usage = resource.getrusage(resource.RUSAGE_SELF)
                memory_mb = usage.ru_maxrss / 1024  # macOS returns bytes

                if memory_mb > threshold_mb:
                    return CheckResult(
                        name="memory",
                        status=HealthStatus.DEGRADED,
                        message=f"High memory usage: {memory_mb:.0f}MB",
                        details={"memory_mb": memory_mb, "threshold_mb": threshold_mb}
                    )

                return CheckResult(
                    name="memory",
                    status=HealthStatus.HEALTHY,
                    details={"memory_mb": memory_mb}
                )
            except Exception as e:
                return CheckResult(
                    name="memory",
                    status=HealthStatus.UNKNOWN,
                    message=str(e)
                )

        return check

    @staticmethod
    def disk_check(path: str = "/", threshold_percent: int = 90) -> Callable[[], CheckResult]:
        """Check disk usage."""
        def check() -> CheckResult:
            try:
                import shutil
                usage = shutil.disk_usage(path)
                percent_used = (usage.used / usage.total) * 100

                if percent_used > threshold_percent:
                    return CheckResult(
                        name="disk",
                        status=HealthStatus.DEGRADED,
                        message=f"High disk usage: {percent_used:.1f}%",
                        details={
                            "path": path,
                            "percent_used": percent_used,
                            "free_gb": usage.free / (1024**3)
                        }
                    )

                return CheckResult(
                    name="disk",
                    status=HealthStatus.HEALTHY,
                    details={
                        "path": path,
                        "percent_used": percent_used,
                        "free_gb": usage.free / (1024**3)
                    }
                )
            except Exception as e:
                return CheckResult(
                    name="disk",
                    status=HealthStatus.UNHEALTHY,
                    message=str(e)
                )

        return check

    @staticmethod
    def http_check(url: str, expected_status: int = 200) -> Callable[[], CheckResult]:
        """Check HTTP endpoint."""
        def check() -> CheckResult:
            try:
                import urllib.request
                start = time.time()
                response = urllib.request.urlopen(url, timeout=5)
                duration_ms = (time.time() - start) * 1000

                if response.status == expected_status:
                    return CheckResult(
                        name=f"http:{url}",
                        status=HealthStatus.HEALTHY,
                        duration_ms=duration_ms,
                        details={"status_code": response.status}
                    )
                else:
                    return CheckResult(
                        name=f"http:{url}",
                        status=HealthStatus.UNHEALTHY,
                        message=f"Unexpected status: {response.status}",
                        duration_ms=duration_ms
                    )
            except Exception as e:
                return CheckResult(
                    name=f"http:{url}",
                    status=HealthStatus.UNHEALTHY,
                    message=str(e)
                )

        return check

    @staticmethod
    def tcp_check(host: str, port: int) -> Callable[[], CheckResult]:
        """Check TCP port connectivity."""
        def check() -> CheckResult:
            import socket
            try:
                start = time.time()
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(5)
                result = sock.connect_ex((host, port))
                sock.close()
                duration_ms = (time.time() - start) * 1000

                if result == 0:
                    return CheckResult(
                        name=f"tcp:{host}:{port}",
                        status=HealthStatus.HEALTHY,
                        duration_ms=duration_ms
                    )
                else:
                    return CheckResult(
                        name=f"tcp:{host}:{port}",
                        status=HealthStatus.UNHEALTHY,
                        message=f"Connection failed: {result}"
                    )
            except Exception as e:
                return CheckResult(
                    name=f"tcp:{host}:{port}",
                    status=HealthStatus.UNHEALTHY,
                    message=str(e)
                )

        return check


class HealthEndpoint:
    """HTTP endpoint for health checks."""

    def __init__(self, checker: HealthChecker):
        self.checker = checker

    def liveness_response(self) -> tuple:
        """Get liveness response (status_code, body)."""
        report = self.checker.liveness()
        status_code = 200 if report.status == HealthStatus.HEALTHY else 503
        return status_code, report.to_dict()

    def readiness_response(self) -> tuple:
        """Get readiness response."""
        report = self.checker.readiness()
        status_code = 200 if report.status == HealthStatus.HEALTHY else 503
        return status_code, report.to_dict()

    def startup_response(self) -> tuple:
        """Get startup response."""
        report = self.checker.startup()
        status_code = 200 if report.status == HealthStatus.HEALTHY else 503
        return status_code, report.to_dict()

    def full_response(self) -> tuple:
        """Get full health response."""
        report = self.checker.check()
        status_code = 200 if report.status == HealthStatus.HEALTHY else 503
        return status_code, report.to_dict()


# Example usage
def example_usage():
    """Example health check usage."""
    checker = HealthChecker(version="1.0.0")

    # Register built-in checks
    checker.register_fn(
        "memory",
        CommonChecks.memory_check(threshold_mb=500),
        check_type=CheckType.LIVENESS
    )

    checker.register_fn(
        "disk",
        CommonChecks.disk_check("/", threshold_percent=90),
        check_type=CheckType.READINESS
    )

    # Register custom check
    def database_check() -> CheckResult:
        # Simulate database check
        return CheckResult(
            name="database",
            status=HealthStatus.HEALTHY,
            details={"connections": 5, "pool_size": 10}
        )

    checker.register_fn(
        "database",
        database_check,
        check_type=CheckType.READINESS,
        timeout=10.0
    )

    # Get health report
    report = checker.check()
    print(f"Overall status: {report.status.value}")
    print(f"Uptime: {report.uptime_seconds:.0f}s")

    for check_result in report.checks:
        print(f"  {check_result.name}: {check_result.status.value}")

    # HTTP endpoint
    endpoint = HealthEndpoint(checker)
    status_code, body = endpoint.readiness_response()
    print(f"Readiness: {status_code}")
