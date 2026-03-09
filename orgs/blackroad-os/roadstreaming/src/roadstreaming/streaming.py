"""
RoadStreaming - Data Streaming for BlackRoad
Stream processing with windowing, aggregations, and event time handling.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Tuple, TypeVar
import asyncio
import heapq
import json
import logging
import statistics
import threading
import time
import uuid

logger = logging.getLogger(__name__)

T = TypeVar('T')


class WindowType(str, Enum):
    """Window types."""
    TUMBLING = "tumbling"
    SLIDING = "sliding"
    SESSION = "session"


@dataclass
class StreamEvent:
    """A stream event."""
    id: str
    key: Optional[str]
    value: Any
    event_time: datetime = field(default_factory=datetime.now)
    processing_time: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __lt__(self, other):
        return self.event_time < other.event_time


@dataclass
class Window:
    """A time window."""
    start: datetime
    end: datetime
    events: List[StreamEvent] = field(default_factory=list)

    @property
    def duration(self) -> timedelta:
        return self.end - self.start

    def contains(self, event: StreamEvent) -> bool:
        return self.start <= event.event_time < self.end

    def add(self, event: StreamEvent) -> None:
        self.events.append(event)


@dataclass
class AggregatedResult:
    """Result of window aggregation."""
    window_start: datetime
    window_end: datetime
    key: Optional[str]
    value: Any
    count: int


class StreamSource:
    """Base stream source."""

    def __init__(self):
        self._running = False

    async def start(self) -> None:
        self._running = True

    async def stop(self) -> None:
        self._running = False

    async def read(self) -> Optional[StreamEvent]:
        raise NotImplementedError


class CollectionSource(StreamSource):
    """Source from a collection."""

    def __init__(self, items: List[Any], key_fn: Callable[[Any], str] = None):
        super().__init__()
        self.items = items
        self.key_fn = key_fn
        self._index = 0

    async def read(self) -> Optional[StreamEvent]:
        if self._index >= len(self.items):
            return None

        item = self.items[self._index]
        self._index += 1

        return StreamEvent(
            id=str(uuid.uuid4())[:8],
            key=self.key_fn(item) if self.key_fn else None,
            value=item
        )


class GeneratorSource(StreamSource):
    """Source from a generator function."""

    def __init__(self, generator_fn: Callable[[], Generator], interval: float = 0.1):
        super().__init__()
        self.generator_fn = generator_fn
        self.interval = interval
        self._generator = None

    async def start(self) -> None:
        await super().start()
        self._generator = self.generator_fn()

    async def read(self) -> Optional[StreamEvent]:
        if not self._running:
            return None

        await asyncio.sleep(self.interval)

        try:
            value = next(self._generator)
            return StreamEvent(
                id=str(uuid.uuid4())[:8],
                key=None,
                value=value
            )
        except StopIteration:
            self._running = False
            return None


class StreamSink:
    """Base stream sink."""

    async def write(self, event: StreamEvent) -> None:
        raise NotImplementedError

    async def flush(self) -> None:
        pass

    async def close(self) -> None:
        pass


class PrintSink(StreamSink):
    """Sink that prints events."""

    async def write(self, event: StreamEvent) -> None:
        print(f"[{event.event_time}] {event.key}: {event.value}")


class CollectorSink(StreamSink):
    """Sink that collects events."""

    def __init__(self):
        self.events: List[StreamEvent] = []

    async def write(self, event: StreamEvent) -> None:
        self.events.append(event)

    def get_values(self) -> List[Any]:
        return [e.value for e in self.events]


class CallbackSink(StreamSink):
    """Sink with callback function."""

    def __init__(self, callback: Callable[[StreamEvent], None]):
        self.callback = callback

    async def write(self, event: StreamEvent) -> None:
        result = self.callback(event)
        if asyncio.iscoroutine(result):
            await result


class WindowAssigner:
    """Assign events to windows."""

    def __init__(self, window_type: WindowType, size: timedelta, slide: timedelta = None):
        self.window_type = window_type
        self.size = size
        self.slide = slide or size

    def assign(self, event: StreamEvent) -> List[Window]:
        """Assign event to windows."""
        if self.window_type == WindowType.TUMBLING:
            return self._assign_tumbling(event)
        elif self.window_type == WindowType.SLIDING:
            return self._assign_sliding(event)
        return []

    def _assign_tumbling(self, event: StreamEvent) -> List[Window]:
        """Assign to tumbling window."""
        timestamp = event.event_time.timestamp()
        window_size = self.size.total_seconds()

        window_start = datetime.fromtimestamp(
            (timestamp // window_size) * window_size
        )
        window_end = window_start + self.size

        return [Window(start=window_start, end=window_end)]

    def _assign_sliding(self, event: StreamEvent) -> List[Window]:
        """Assign to sliding windows."""
        windows = []
        timestamp = event.event_time.timestamp()
        window_size = self.size.total_seconds()
        slide_size = self.slide.total_seconds()

        # Find all windows that contain this event
        earliest_start = timestamp - window_size + slide_size
        start = (earliest_start // slide_size) * slide_size

        while start <= timestamp:
            window_start = datetime.fromtimestamp(start)
            window_end = window_start + self.size

            if window_start <= event.event_time < window_end:
                windows.append(Window(start=window_start, end=window_end))

            start += slide_size

        return windows


class WindowAggregator:
    """Aggregate events in windows."""

    def __init__(self):
        self.windows: Dict[Tuple[datetime, datetime, str], Window] = {}
        self._lock = threading.Lock()

    def add(self, event: StreamEvent, window: Window) -> None:
        """Add event to window."""
        key = (window.start, window.end, event.key or "")

        with self._lock:
            if key not in self.windows:
                self.windows[key] = Window(start=window.start, end=window.end)
            self.windows[key].add(event)

    def trigger(self, now: datetime) -> List[AggregatedResult]:
        """Trigger windows that have ended."""
        results = []

        with self._lock:
            for key in list(self.windows.keys()):
                window = self.windows[key]
                if window.end <= now:
                    # Window has ended, aggregate
                    values = [e.value for e in window.events]

                    results.append(AggregatedResult(
                        window_start=window.start,
                        window_end=window.end,
                        key=key[2] or None,
                        value=values,
                        count=len(values)
                    ))

                    del self.windows[key]

        return results


class StreamOperator:
    """Base stream operator."""

    async def process(self, event: StreamEvent) -> Optional[StreamEvent]:
        raise NotImplementedError


class MapOperator(StreamOperator):
    """Map operator."""

    def __init__(self, fn: Callable[[Any], Any]):
        self.fn = fn

    async def process(self, event: StreamEvent) -> Optional[StreamEvent]:
        result = self.fn(event.value)
        if asyncio.iscoroutine(result):
            result = await result

        return StreamEvent(
            id=event.id,
            key=event.key,
            value=result,
            event_time=event.event_time,
            processing_time=datetime.now()
        )


class FilterOperator(StreamOperator):
    """Filter operator."""

    def __init__(self, predicate: Callable[[Any], bool]):
        self.predicate = predicate

    async def process(self, event: StreamEvent) -> Optional[StreamEvent]:
        if self.predicate(event.value):
            return event
        return None


class FlatMapOperator(StreamOperator):
    """FlatMap operator."""

    def __init__(self, fn: Callable[[Any], List[Any]]):
        self.fn = fn
        self._pending: List[StreamEvent] = []

    async def process(self, event: StreamEvent) -> Optional[StreamEvent]:
        results = self.fn(event.value)

        for value in results:
            self._pending.append(StreamEvent(
                id=str(uuid.uuid4())[:8],
                key=event.key,
                value=value,
                event_time=event.event_time
            ))

        if self._pending:
            return self._pending.pop(0)
        return None


class KeyByOperator(StreamOperator):
    """Key-by operator."""

    def __init__(self, key_fn: Callable[[Any], str]):
        self.key_fn = key_fn

    async def process(self, event: StreamEvent) -> Optional[StreamEvent]:
        event.key = self.key_fn(event.value)
        return event


class StreamPipeline:
    """Stream processing pipeline."""

    def __init__(self, source: StreamSource):
        self.source = source
        self.operators: List[StreamOperator] = []
        self.sinks: List[StreamSink] = []
        self.window_assigner: Optional[WindowAssigner] = None
        self.aggregator: Optional[WindowAggregator] = None
        self._running = False

    def map(self, fn: Callable[[Any], Any]) -> "StreamPipeline":
        """Add map operator."""
        self.operators.append(MapOperator(fn))
        return self

    def filter(self, predicate: Callable[[Any], bool]) -> "StreamPipeline":
        """Add filter operator."""
        self.operators.append(FilterOperator(predicate))
        return self

    def flat_map(self, fn: Callable[[Any], List[Any]]) -> "StreamPipeline":
        """Add flatmap operator."""
        self.operators.append(FlatMapOperator(fn))
        return self

    def key_by(self, key_fn: Callable[[Any], str]) -> "StreamPipeline":
        """Key the stream."""
        self.operators.append(KeyByOperator(key_fn))
        return self

    def window(
        self,
        window_type: WindowType,
        size: timedelta,
        slide: timedelta = None
    ) -> "StreamPipeline":
        """Apply windowing."""
        self.window_assigner = WindowAssigner(window_type, size, slide)
        self.aggregator = WindowAggregator()
        return self

    def tumbling_window(self, size: timedelta) -> "StreamPipeline":
        """Apply tumbling window."""
        return self.window(WindowType.TUMBLING, size)

    def sliding_window(self, size: timedelta, slide: timedelta) -> "StreamPipeline":
        """Apply sliding window."""
        return self.window(WindowType.SLIDING, size, slide)

    def sink(self, sink: StreamSink) -> "StreamPipeline":
        """Add a sink."""
        self.sinks.append(sink)
        return self

    async def execute(self) -> None:
        """Execute the pipeline."""
        self._running = True
        await self.source.start()

        while self._running:
            event = await self.source.read()
            if event is None:
                break

            await self._process_event(event)

            # Check for window triggers
            if self.aggregator:
                results = self.aggregator.trigger(datetime.now())
                for result in results:
                    await self._emit_result(result)

        # Final flush
        for sink in self.sinks:
            await sink.flush()
            await sink.close()

    async def _process_event(self, event: StreamEvent) -> None:
        """Process a single event through operators."""
        current = event

        for operator in self.operators:
            if current is None:
                break
            current = await operator.process(current)

        if current is None:
            return

        # Handle windowing
        if self.window_assigner and self.aggregator:
            windows = self.window_assigner.assign(current)
            for window in windows:
                self.aggregator.add(current, window)
        else:
            # No windowing, emit directly
            for sink in self.sinks:
                await sink.write(current)

    async def _emit_result(self, result: AggregatedResult) -> None:
        """Emit aggregated result to sinks."""
        event = StreamEvent(
            id=str(uuid.uuid4())[:8],
            key=result.key,
            value={
                "window_start": result.window_start.isoformat(),
                "window_end": result.window_end.isoformat(),
                "values": result.value,
                "count": result.count
            }
        )

        for sink in self.sinks:
            await sink.write(event)

    def stop(self) -> None:
        """Stop the pipeline."""
        self._running = False


class StreamManager:
    """High-level stream management."""

    def __init__(self):
        self.pipelines: Dict[str, StreamPipeline] = {}

    def from_collection(self, items: List[Any], key_fn: Callable = None) -> StreamPipeline:
        """Create pipeline from collection."""
        source = CollectionSource(items, key_fn)
        return StreamPipeline(source)

    def from_generator(self, generator_fn: Callable, interval: float = 0.1) -> StreamPipeline:
        """Create pipeline from generator."""
        source = GeneratorSource(generator_fn, interval)
        return StreamPipeline(source)

    async def run(self, name: str, pipeline: StreamPipeline) -> None:
        """Run a named pipeline."""
        self.pipelines[name] = pipeline
        await pipeline.execute()

    def stop(self, name: str) -> bool:
        """Stop a named pipeline."""
        if name in self.pipelines:
            self.pipelines[name].stop()
            return True
        return False


# Example usage
async def example_usage():
    """Example streaming usage."""
    manager = StreamManager()

    # Create pipeline from collection
    data = [
        {"user": "alice", "action": "click", "value": 10},
        {"user": "bob", "action": "view", "value": 5},
        {"user": "alice", "action": "purchase", "value": 100},
        {"user": "charlie", "action": "click", "value": 15},
        {"user": "bob", "action": "purchase", "value": 50},
    ]

    collector = CollectorSink()

    pipeline = (
        manager.from_collection(data)
        .filter(lambda x: x["action"] in ["click", "purchase"])
        .map(lambda x: {"user": x["user"], "value": x["value"]})
        .key_by(lambda x: x["user"])
        .sink(PrintSink())
        .sink(collector)
    )

    await pipeline.execute()

    print(f"\nCollected {len(collector.events)} events")

    # Windowed example
    numbers = list(range(20))

    windowed_collector = CollectorSink()

    windowed_pipeline = (
        manager.from_collection(numbers)
        .map(lambda x: x * 2)
        .tumbling_window(timedelta(seconds=1))
        .sink(windowed_collector)
    )

    await windowed_pipeline.execute()

    print(f"\nWindowed results: {len(windowed_collector.events)}")

