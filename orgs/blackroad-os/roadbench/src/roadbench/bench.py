"""
RoadBench - Benchmarking for BlackRoad
Measure and compare performance of functions.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Callable, Dict, List, Optional, Tuple
import gc
import statistics
import time
import logging

logger = logging.getLogger(__name__)


@dataclass
class BenchmarkResult:
    name: str
    iterations: int
    total_time: float
    min_time: float
    max_time: float
    mean_time: float
    median_time: float
    std_dev: float
    ops_per_sec: float
    times: List[float] = field(default_factory=list)

    def __str__(self) -> str:
        return (
            f"{self.name}: {self.mean_time*1000:.3f}ms mean "
            f"(±{self.std_dev*1000:.3f}ms) [{self.iterations} iterations]"
        )


@dataclass
class ComparisonResult:
    baseline: BenchmarkResult
    contender: BenchmarkResult
    speedup: float

    def __str__(self) -> str:
        if self.speedup > 1:
            return f"{self.contender.name} is {self.speedup:.2f}x faster than {self.baseline.name}"
        else:
            return f"{self.contender.name} is {1/self.speedup:.2f}x slower than {self.baseline.name}"


class Timer:
    def __init__(self):
        self._start: Optional[float] = None
        self._end: Optional[float] = None

    def start(self) -> "Timer":
        self._start = time.perf_counter()
        return self

    def stop(self) -> float:
        self._end = time.perf_counter()
        return self.elapsed

    @property
    def elapsed(self) -> float:
        if self._start is None:
            return 0.0
        end = self._end or time.perf_counter()
        return end - self._start

    def __enter__(self) -> "Timer":
        return self.start()

    def __exit__(self, *args) -> None:
        self.stop()


class Benchmark:
    def __init__(self, name: str = "benchmark"):
        self.name = name
        self.iterations = 1000
        self.warmup = 10
        self.gc_collect = True

    def configure(self, iterations: int = None, warmup: int = None, gc_collect: bool = None) -> "Benchmark":
        if iterations is not None:
            self.iterations = iterations
        if warmup is not None:
            self.warmup = warmup
        if gc_collect is not None:
            self.gc_collect = gc_collect
        return self

    def run(self, func: Callable, *args, **kwargs) -> BenchmarkResult:
        for _ in range(self.warmup):
            func(*args, **kwargs)

        if self.gc_collect:
            gc.collect()

        times = []
        for _ in range(self.iterations):
            start = time.perf_counter()
            func(*args, **kwargs)
            end = time.perf_counter()
            times.append(end - start)

        total_time = sum(times)
        mean_time = statistics.mean(times)

        return BenchmarkResult(
            name=self.name,
            iterations=self.iterations,
            total_time=total_time,
            min_time=min(times),
            max_time=max(times),
            mean_time=mean_time,
            median_time=statistics.median(times),
            std_dev=statistics.stdev(times) if len(times) > 1 else 0,
            ops_per_sec=1.0 / mean_time if mean_time > 0 else 0,
            times=times
        )


class BenchmarkSuite:
    def __init__(self, name: str = "suite"):
        self.name = name
        self.benchmarks: Dict[str, Callable] = {}
        self.results: Dict[str, BenchmarkResult] = {}
        self.iterations = 1000
        self.warmup = 10

    def add(self, name: str, func: Callable) -> "BenchmarkSuite":
        self.benchmarks[name] = func
        return self

    def bench(self, name: str) -> Callable:
        def decorator(func: Callable) -> Callable:
            self.benchmarks[name] = func
            return func
        return decorator

    def run(self) -> Dict[str, BenchmarkResult]:
        for name, func in self.benchmarks.items():
            bench = Benchmark(name).configure(self.iterations, self.warmup)
            self.results[name] = bench.run(func)
        return self.results

    def compare(self, baseline: str, contender: str) -> ComparisonResult:
        if baseline not in self.results or contender not in self.results:
            raise ValueError("Run benchmarks first")

        baseline_result = self.results[baseline]
        contender_result = self.results[contender]
        speedup = baseline_result.mean_time / contender_result.mean_time

        return ComparisonResult(
            baseline=baseline_result,
            contender=contender_result,
            speedup=speedup
        )

    def report(self) -> str:
        lines = [f"\n{'=' * 60}", f"Benchmark Suite: {self.name}", "=" * 60]

        sorted_results = sorted(self.results.values(), key=lambda r: r.mean_time)

        for result in sorted_results:
            lines.append(f"\n{result.name}")
            lines.append(f"  Mean:     {result.mean_time*1000:.4f} ms")
            lines.append(f"  Min:      {result.min_time*1000:.4f} ms")
            lines.append(f"  Max:      {result.max_time*1000:.4f} ms")
            lines.append(f"  Std Dev:  {result.std_dev*1000:.4f} ms")
            lines.append(f"  Ops/sec:  {result.ops_per_sec:.2f}")

        if len(sorted_results) > 1:
            lines.append(f"\n{'-' * 40}")
            lines.append("Ranking (fastest to slowest):")
            for i, result in enumerate(sorted_results, 1):
                lines.append(f"  {i}. {result.name}")

        lines.append("=" * 60)
        return "\n".join(lines)


def timeit(func: Callable, *args, iterations: int = 1000, **kwargs) -> float:
    bench = Benchmark().configure(iterations=iterations)
    result = bench.run(func, *args, **kwargs)
    return result.mean_time


def compare(funcs: Dict[str, Callable], iterations: int = 1000) -> Dict[str, BenchmarkResult]:
    suite = BenchmarkSuite()
    suite.iterations = iterations
    for name, func in funcs.items():
        suite.add(name, func)
    return suite.run()


def example_usage():
    def list_comprehension():
        return [x * 2 for x in range(1000)]

    def map_function():
        return list(map(lambda x: x * 2, range(1000)))

    def for_loop():
        result = []
        for x in range(1000):
            result.append(x * 2)
        return result

    suite = BenchmarkSuite("List Operations")
    suite.iterations = 1000
    suite.add("list_comprehension", list_comprehension)
    suite.add("map_function", map_function)
    suite.add("for_loop", for_loop)

    suite.run()
    print(suite.report())

    comparison = suite.compare("for_loop", "list_comprehension")
    print(f"\n{comparison}")

    with Timer() as t:
        sum(range(1000000))
    print(f"\nTimer: {t.elapsed*1000:.2f}ms")
