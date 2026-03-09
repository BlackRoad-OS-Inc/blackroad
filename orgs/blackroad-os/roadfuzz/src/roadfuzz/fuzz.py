"""
RoadFuzz - Fuzz Testing for BlackRoad
Generate random inputs to find edge cases.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Type, Union
import random
import string
import logging

logger = logging.getLogger(__name__)


class FuzzError(Exception):
    pass


@dataclass
class FuzzResult:
    success: bool
    iterations: int
    failures: List[tuple] = field(default_factory=list)
    duration: float = 0.0

    @property
    def failure_rate(self) -> float:
        if self.iterations == 0:
            return 0.0
        return len(self.failures) / self.iterations


@dataclass
class FuzzCase:
    input: Any
    output: Any = None
    error: Optional[Exception] = None
    success: bool = True


class Generator:
    @staticmethod
    def integers(min_val: int = -1000, max_val: int = 1000) -> Generator[int, None, None]:
        while True:
            yield random.randint(min_val, max_val)

    @staticmethod
    def floats(min_val: float = -1000.0, max_val: float = 1000.0) -> Generator[float, None, None]:
        while True:
            yield random.uniform(min_val, max_val)

    @staticmethod
    def strings(min_len: int = 0, max_len: int = 100, charset: str = None) -> Generator[str, None, None]:
        charset = charset or string.printable
        while True:
            length = random.randint(min_len, max_len)
            yield "".join(random.choice(charset) for _ in range(length))

    @staticmethod
    def bytes_(min_len: int = 0, max_len: int = 100) -> Generator[bytes, None, None]:
        while True:
            length = random.randint(min_len, max_len)
            yield bytes(random.randint(0, 255) for _ in range(length))

    @staticmethod
    def lists(item_gen: Generator, min_len: int = 0, max_len: int = 20) -> Generator[List, None, None]:
        while True:
            length = random.randint(min_len, max_len)
            yield [next(item_gen) for _ in range(length)]

    @staticmethod
    def dicts(key_gen: Generator, val_gen: Generator, min_len: int = 0, max_len: int = 10) -> Generator[Dict, None, None]:
        while True:
            length = random.randint(min_len, max_len)
            yield {next(key_gen): next(val_gen) for _ in range(length)}

    @staticmethod
    def choice(items: List[Any]) -> Generator[Any, None, None]:
        while True:
            yield random.choice(items)

    @staticmethod
    def one_of(*generators: Generator) -> Generator[Any, None, None]:
        while True:
            yield next(random.choice(generators))

    @staticmethod
    def none_or(gen: Generator, none_prob: float = 0.1) -> Generator[Any, None, None]:
        while True:
            if random.random() < none_prob:
                yield None
            else:
                yield next(gen)


class EdgeCases:
    INTEGERS = [0, 1, -1, 2**31 - 1, -2**31, 2**63 - 1, -2**63]
    FLOATS = [0.0, -0.0, 1.0, -1.0, float("inf"), float("-inf"), float("nan")]
    STRINGS = ["", " ", "\n", "\t", "\0", "null", "None", "undefined", "<script>", "'; DROP TABLE"]
    BYTES = [b"", b"\x00", b"\xff", b"\x00\x00\x00\x00"]

    @classmethod
    def for_type(cls, typ: Type) -> List[Any]:
        if typ == int:
            return cls.INTEGERS
        if typ == float:
            return cls.FLOATS
        if typ == str:
            return cls.STRINGS
        if typ == bytes:
            return cls.BYTES
        return [None]


class Fuzzer:
    def __init__(self, func: Callable):
        self.func = func
        self.iterations = 1000
        self.include_edge_cases = True
        self._generators: List[Generator] = []
        self._validator: Optional[Callable] = None

    def with_generator(self, *generators: Generator) -> "Fuzzer":
        self._generators.extend(generators)
        return self

    def with_validator(self, validator: Callable[[Any, Any], bool]) -> "Fuzzer":
        self._validator = validator
        return self

    def configure(self, iterations: int = None, include_edge_cases: bool = None) -> "Fuzzer":
        if iterations is not None:
            self.iterations = iterations
        if include_edge_cases is not None:
            self.include_edge_cases = include_edge_cases
        return self

    def run(self) -> FuzzResult:
        import time
        start = time.time()
        failures = []
        total = 0

        if self.include_edge_cases:
            for edge_cases in self._get_edge_cases():
                case = self._run_case(edge_cases)
                total += 1
                if not case.success:
                    failures.append((edge_cases, case.error))

        for _ in range(self.iterations):
            inputs = tuple(next(g) for g in self._generators)
            case = self._run_case(inputs)
            total += 1
            if not case.success:
                failures.append((inputs, case.error))

        return FuzzResult(
            success=len(failures) == 0,
            iterations=total,
            failures=failures,
            duration=time.time() - start
        )

    def _run_case(self, inputs: tuple) -> FuzzCase:
        try:
            output = self.func(*inputs)
            if self._validator and not self._validator(inputs, output):
                return FuzzCase(input=inputs, output=output, success=False,
                              error=ValueError("Validation failed"))
            return FuzzCase(input=inputs, output=output, success=True)
        except Exception as e:
            return FuzzCase(input=inputs, error=e, success=False)

    def _get_edge_cases(self) -> Generator[tuple, None, None]:
        if not self._generators:
            return
        yield tuple(EdgeCases.INTEGERS[0] for _ in self._generators)


class PropertyTest:
    def __init__(self, name: str = "property"):
        self.name = name
        self.iterations = 100

    def for_all(self, *generators: Generator) -> Callable:
        def decorator(prop: Callable) -> Callable:
            def test():
                for _ in range(self.iterations):
                    args = tuple(next(g) for g in generators)
                    try:
                        result = prop(*args)
                        if result is False:
                            raise AssertionError(f"Property failed for {args}")
                    except Exception as e:
                        raise AssertionError(f"Property failed for {args}: {e}")
            return test
        return decorator


def fuzz(func: Callable, *generators: Generator, iterations: int = 1000) -> FuzzResult:
    fuzzer = Fuzzer(func)
    fuzzer.with_generator(*generators)
    fuzzer.configure(iterations=iterations)
    return fuzzer.run()


def example_usage():
    def parse_int(s: str) -> int:
        return int(s)

    result = fuzz(
        parse_int,
        Generator.strings(min_len=1, max_len=10, charset=string.digits),
        iterations=100
    )
    print(f"Parse int fuzz: {result.success}, {result.iterations} iterations")
    if result.failures:
        print(f"  Failures: {len(result.failures)}")

    def safe_divide(a: int, b: int) -> float:
        if b == 0:
            return float("inf")
        return a / b

    def division_validator(inputs, output):
        a, b = inputs
        if b == 0:
            return output == float("inf")
        return abs(output * b - a) < 0.0001

    fuzzer = Fuzzer(safe_divide)
    fuzzer.with_generator(Generator.integers(-100, 100), Generator.integers(-100, 100))
    fuzzer.with_validator(division_validator)
    fuzzer.configure(iterations=500)

    result = fuzzer.run()
    print(f"\nDivision fuzz: {result.success}")
    print(f"  Iterations: {result.iterations}")
    print(f"  Duration: {result.duration:.3f}s")

    prop = PropertyTest()

    @prop.for_all(Generator.integers(), Generator.integers())
    def addition_commutative(a, b):
        return a + b == b + a

    addition_commutative()
    print("\nProperty test passed: addition is commutative")
