"""
RoadPipe - Data Pipeline for BlackRoad
Build and execute data transformation pipelines.
"""

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, Generator, Generic, Iterable, List, Optional, TypeVar, Union
import functools
import itertools
import logging

logger = logging.getLogger(__name__)

T = TypeVar("T")
U = TypeVar("U")


class PipeError(Exception):
    pass


@dataclass
class StepResult:
    success: bool
    value: Any
    error: Optional[Exception] = None
    step_name: str = ""


class Step(Generic[T, U]):
    def __init__(self, fn: Callable[[T], U], name: str = ""):
        self.fn = fn
        self.name = name or fn.__name__

    def __call__(self, value: T) -> U:
        return self.fn(value)

    def __repr__(self) -> str:
        return f"Step({self.name})"


class Pipe(Generic[T]):
    def __init__(self, source: Union[T, Iterable[T], Callable[[], T]] = None):
        self._source = source
        self._steps: List[Step] = []
        self._error_handler: Optional[Callable] = None

    @classmethod
    def of(cls, *items: T) -> "Pipe[T]":
        return cls(items)

    @classmethod
    def from_iterable(cls, items: Iterable[T]) -> "Pipe[T]":
        return cls(items)

    @classmethod
    def generate(cls, fn: Callable[[], Generator[T, None, None]]) -> "Pipe[T]":
        return cls(fn)

    def map(self, fn: Callable[[T], U], name: str = "") -> "Pipe[U]":
        self._steps.append(Step(lambda items: (fn(x) for x in items), name or "map"))
        return self

    def filter(self, fn: Callable[[T], bool], name: str = "") -> "Pipe[T]":
        self._steps.append(Step(lambda items: (x for x in items if fn(x)), name or "filter"))
        return self

    def flatmap(self, fn: Callable[[T], Iterable[U]], name: str = "") -> "Pipe[U]":
        def _flatmap(items):
            for item in items:
                yield from fn(item)
        self._steps.append(Step(_flatmap, name or "flatmap"))
        return self

    def take(self, n: int) -> "Pipe[T]":
        self._steps.append(Step(lambda items: itertools.islice(items, n), f"take({n})"))
        return self

    def skip(self, n: int) -> "Pipe[T]":
        self._steps.append(Step(lambda items: itertools.islice(items, n, None), f"skip({n})"))
        return self

    def distinct(self) -> "Pipe[T]":
        def _distinct(items):
            seen = set()
            for item in items:
                key = hash(item) if not isinstance(item, dict) else str(item)
                if key not in seen:
                    seen.add(key)
                    yield item
        self._steps.append(Step(_distinct, "distinct"))
        return self

    def sort(self, key: Callable = None, reverse: bool = False) -> "Pipe[T]":
        self._steps.append(Step(lambda items: sorted(items, key=key, reverse=reverse), "sort"))
        return self

    def group_by(self, key: Callable[[T], Any]) -> "Pipe[tuple]":
        def _group(items):
            groups: Dict[Any, List] = {}
            for item in items:
                k = key(item)
                if k not in groups:
                    groups[k] = []
                groups[k].append(item)
            for k, v in groups.items():
                yield (k, v)
        self._steps.append(Step(_group, "group_by"))
        return self

    def batch(self, size: int) -> "Pipe[List[T]]":
        def _batch(items):
            batch = []
            for item in items:
                batch.append(item)
                if len(batch) >= size:
                    yield batch
                    batch = []
            if batch:
                yield batch
        self._steps.append(Step(_batch, f"batch({size})"))
        return self

    def tap(self, fn: Callable[[T], None]) -> "Pipe[T]":
        def _tap(items):
            for item in items:
                fn(item)
                yield item
        self._steps.append(Step(_tap, "tap"))
        return self

    def on_error(self, handler: Callable[[Exception, Any], Optional[Any]]) -> "Pipe[T]":
        self._error_handler = handler
        return self

    def _get_source(self) -> Iterable:
        if callable(self._source) and not isinstance(self._source, (list, tuple)):
            return self._source()
        if isinstance(self._source, (list, tuple)):
            return iter(self._source)
        return self._source

    def run(self) -> Generator[T, None, None]:
        current = self._get_source()
        for step in self._steps:
            try:
                current = step(current)
            except Exception as e:
                if self._error_handler:
                    result = self._error_handler(e, current)
                    if result is not None:
                        current = result
                    else:
                        raise
                else:
                    raise
        yield from current

    def collect(self) -> List[T]:
        return list(self.run())

    def first(self) -> Optional[T]:
        for item in self.run():
            return item
        return None

    def count(self) -> int:
        return sum(1 for _ in self.run())

    def reduce(self, fn: Callable[[U, T], U], initial: U = None) -> U:
        return functools.reduce(fn, self.run(), initial)

    def foreach(self, fn: Callable[[T], None]) -> None:
        for item in self.run():
            fn(item)

    def any(self, fn: Callable[[T], bool] = bool) -> bool:
        return any(fn(x) for x in self.run())

    def all(self, fn: Callable[[T], bool] = bool) -> bool:
        return all(fn(x) for x in self.run())

    def __iter__(self):
        return self.run()


class Pipeline:
    def __init__(self, name: str = "pipeline"):
        self.name = name
        self._steps: List[tuple] = []

    def step(self, name: str) -> Callable:
        def decorator(fn: Callable) -> Callable:
            self._steps.append((name, fn))
            return fn
        return decorator

    def add_step(self, name: str, fn: Callable) -> "Pipeline":
        self._steps.append((name, fn))
        return self

    def run(self, data: Any) -> Any:
        current = data
        for name, fn in self._steps:
            try:
                current = fn(current)
                logger.debug(f"Step '{name}' completed")
            except Exception as e:
                logger.error(f"Step '{name}' failed: {e}")
                raise PipeError(f"Pipeline failed at step '{name}': {e}")
        return current


def pipe(*fns: Callable) -> Callable:
    def piped(value):
        for fn in fns:
            value = fn(value)
        return value
    return piped


def compose(*fns: Callable) -> Callable:
    return pipe(*reversed(fns))


def example_usage():
    result = (Pipe.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        .filter(lambda x: x % 2 == 0)
        .map(lambda x: x * 2)
        .take(3)
        .collect())
    print(f"Result: {result}")

    data = [
        {"name": "Alice", "age": 30},
        {"name": "Bob", "age": 25},
        {"name": "Charlie", "age": 30},
    ]
    groups = (Pipe.from_iterable(data)
        .group_by(lambda x: x["age"])
        .collect())
    print(f"\nGrouped: {groups}")

    batches = (Pipe.of(*range(10))
        .batch(3)
        .collect())
    print(f"\nBatches: {batches}")

    pipeline = Pipeline("data_processor")
    pipeline.add_step("double", lambda x: [i * 2 for i in x])
    pipeline.add_step("filter", lambda x: [i for i in x if i > 5])
    pipeline.add_step("sum", sum)
    result = pipeline.run([1, 2, 3, 4, 5])
    print(f"\nPipeline result: {result}")

    add_one = lambda x: x + 1
    double = lambda x: x * 2
    composed = pipe(add_one, double, add_one)
    print(f"\nComposed: {composed(5)}")

