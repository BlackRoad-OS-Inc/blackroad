"""
RoadTest - Testing Framework for BlackRoad
Simple test runner with assertions and reporting.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Type
import inspect
import time
import traceback
import logging

logger = logging.getLogger(__name__)


class TestStatus(str, Enum):
    PASSED = "passed"
    FAILED = "failed"
    SKIPPED = "skipped"
    ERROR = "error"


@dataclass
class TestResult:
    name: str
    status: TestStatus
    duration: float = 0.0
    error: Optional[str] = None
    tb: Optional[str] = None


@dataclass
class TestSuiteResult:
    name: str
    results: List[TestResult] = field(default_factory=list)
    duration: float = 0.0

    @property
    def passed(self) -> int:
        return sum(1 for r in self.results if r.status == TestStatus.PASSED)

    @property
    def failed(self) -> int:
        return sum(1 for r in self.results if r.status == TestStatus.FAILED)

    @property
    def skipped(self) -> int:
        return sum(1 for r in self.results if r.status == TestStatus.SKIPPED)


class TestCase:
    def setup(self) -> None:
        pass

    def teardown(self) -> None:
        pass


def test(func: Callable = None, *, skip: bool = False, skip_reason: str = ""):
    def decorator(f: Callable) -> Callable:
        f._is_test = True
        f._skip = skip
        f._skip_reason = skip_reason
        return f
    if func is not None:
        return decorator(func)
    return decorator


def skip(reason: str = ""):
    def decorator(func: Callable) -> Callable:
        func._skip = True
        func._skip_reason = reason
        return func
    return decorator


def parametrize(params: List[tuple]):
    def decorator(func: Callable) -> Callable:
        func._params = params
        return func
    return decorator


class TestRunner:
    def __init__(self):
        self.results: List[TestSuiteResult] = []

    def run_test(self, instance: TestCase, method: Callable) -> TestResult:
        name = method.__name__
        if getattr(method, "_skip", False):
            return TestResult(name=name, status=TestStatus.SKIPPED)
        start = time.time()
        try:
            instance.setup()
            method()
            instance.teardown()
            return TestResult(name=name, status=TestStatus.PASSED, duration=time.time() - start)
        except AssertionError as e:
            return TestResult(name=name, status=TestStatus.FAILED, duration=time.time() - start, error=str(e))
        except Exception as e:
            return TestResult(name=name, status=TestStatus.ERROR, duration=time.time() - start, error=str(e))

    def run_class(self, cls: Type[TestCase]) -> TestSuiteResult:
        suite = TestSuiteResult(name=cls.__name__)
        start = time.time()
        instance = cls()
        for name, method in inspect.getmembers(instance, predicate=inspect.ismethod):
            if name.startswith("test_") or getattr(method, "_is_test", False):
                suite.results.append(self.run_test(instance, method))
        suite.duration = time.time() - start
        self.results.append(suite)
        return suite

    def run(self, *test_classes: Type[TestCase]) -> List[TestSuiteResult]:
        for cls in test_classes:
            self.run_class(cls)
        return self.results

    def report(self) -> str:
        lines = ["", "=" * 60, "TEST RESULTS", "=" * 60]
        total_passed = total_failed = 0
        for suite in self.results:
            lines.append(f"
{suite.name} ({suite.duration:.3f}s)")
            for result in suite.results:
                symbol = {"passed": "✓", "failed": "✗", "skipped": "○", "error": "!"}
                lines.append(f"  {symbol[result.status.value]} {result.name}")
            total_passed += suite.passed
            total_failed += suite.failed
        lines.append(f"
Total: {total_passed} passed, {total_failed} failed")
        return "
".join(lines)


def run_tests(*test_classes: Type[TestCase]) -> bool:
    runner = TestRunner()
    runner.run(*test_classes)
    print(runner.report())
    return all(s.failed == 0 for s in runner.results)


def example_usage():
    class MathTests(TestCase):
        @test
        def test_addition(self):
            assert 1 + 1 == 2

        @skip("Not implemented")
        def test_skipped(self):
            pass

    run_tests(MathTests)
