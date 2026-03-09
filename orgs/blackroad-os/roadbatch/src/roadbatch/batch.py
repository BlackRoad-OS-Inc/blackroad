"""
RoadBatch - Batch Processing for BlackRoad
Batch jobs, scheduling, checkpointing, and parallel execution.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Tuple
import asyncio
import hashlib
import json
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class JobStatus(str, Enum):
    """Job status."""
    PENDING = "pending"
    RUNNING = "running"
    PAUSED = "paused"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class StepStatus(str, Enum):
    """Step status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


@dataclass
class JobMetrics:
    """Job execution metrics."""
    items_processed: int = 0
    items_failed: int = 0
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration_ms: float = 0

    @property
    def items_per_second(self) -> float:
        if self.duration_ms == 0:
            return 0
        return self.items_processed / (self.duration_ms / 1000)


@dataclass
class Checkpoint:
    """Job checkpoint for recovery."""
    job_id: str
    step_index: int
    position: int
    data: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)


@dataclass
class StepResult:
    """Result of a batch step."""
    status: StepStatus
    items_processed: int = 0
    items_failed: int = 0
    output: Any = None
    error: Optional[str] = None
    duration_ms: float = 0


class BatchReader:
    """Base batch reader."""

    def open(self) -> None:
        pass

    def read(self, chunk_size: int = 1000) -> Generator[List[Any], None, None]:
        raise NotImplementedError

    def close(self) -> None:
        pass


class ListReader(BatchReader):
    """Read from a list."""

    def __init__(self, items: List[Any]):
        self.items = items
        self._position = 0

    def read(self, chunk_size: int = 1000) -> Generator[List[Any], None, None]:
        while self._position < len(self.items):
            chunk = self.items[self._position:self._position + chunk_size]
            self._position += len(chunk)
            yield chunk


class GeneratorReader(BatchReader):
    """Read from a generator."""

    def __init__(self, generator_fn: Callable[[], Generator]):
        self.generator_fn = generator_fn
        self._generator = None

    def open(self) -> None:
        self._generator = self.generator_fn()

    def read(self, chunk_size: int = 1000) -> Generator[List[Any], None, None]:
        chunk = []
        for item in self._generator:
            chunk.append(item)
            if len(chunk) >= chunk_size:
                yield chunk
                chunk = []
        if chunk:
            yield chunk


class BatchWriter:
    """Base batch writer."""

    def open(self) -> None:
        pass

    def write(self, items: List[Any]) -> int:
        raise NotImplementedError

    def flush(self) -> None:
        pass

    def close(self) -> None:
        pass


class ListWriter(BatchWriter):
    """Write to a list."""

    def __init__(self):
        self.items: List[Any] = []

    def write(self, items: List[Any]) -> int:
        self.items.extend(items)
        return len(items)


class CallbackWriter(BatchWriter):
    """Write using a callback."""

    def __init__(self, callback: Callable[[List[Any]], int]):
        self.callback = callback

    def write(self, items: List[Any]) -> int:
        return self.callback(items)


class BatchProcessor:
    """Process batch items."""

    def process(self, items: List[Any]) -> Tuple[List[Any], List[Any]]:
        """Process items, return (processed, failed)."""
        raise NotImplementedError


class MapProcessor(BatchProcessor):
    """Map items using a function."""

    def __init__(self, fn: Callable[[Any], Any]):
        self.fn = fn

    def process(self, items: List[Any]) -> Tuple[List[Any], List[Any]]:
        processed = []
        failed = []

        for item in items:
            try:
                result = self.fn(item)
                processed.append(result)
            except Exception as e:
                failed.append({"item": item, "error": str(e)})

        return processed, failed


class FilterProcessor(BatchProcessor):
    """Filter items using a predicate."""

    def __init__(self, predicate: Callable[[Any], bool]):
        self.predicate = predicate

    def process(self, items: List[Any]) -> Tuple[List[Any], List[Any]]:
        processed = [item for item in items if self.predicate(item)]
        return processed, []


class ChainProcessor(BatchProcessor):
    """Chain multiple processors."""

    def __init__(self, processors: List[BatchProcessor]):
        self.processors = processors

    def process(self, items: List[Any]) -> Tuple[List[Any], List[Any]]:
        current = items
        all_failed = []

        for processor in self.processors:
            current, failed = processor.process(current)
            all_failed.extend(failed)

        return current, all_failed


@dataclass
class BatchStep:
    """A step in a batch job."""
    name: str
    reader: Optional[BatchReader] = None
    processor: Optional[BatchProcessor] = None
    writer: Optional[BatchWriter] = None
    chunk_size: int = 1000
    skip_on_error: bool = False
    status: StepStatus = StepStatus.PENDING
    result: Optional[StepResult] = None


@dataclass
class BatchJob:
    """A batch job."""
    id: str
    name: str
    steps: List[BatchStep] = field(default_factory=list)
    status: JobStatus = JobStatus.PENDING
    metrics: JobMetrics = field(default_factory=JobMetrics)
    checkpoint: Optional[Checkpoint] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class CheckpointStore:
    """Store checkpoints for recovery."""

    def __init__(self):
        self.checkpoints: Dict[str, Checkpoint] = {}
        self._lock = threading.Lock()

    def save(self, checkpoint: Checkpoint) -> None:
        with self._lock:
            self.checkpoints[checkpoint.job_id] = checkpoint

    def load(self, job_id: str) -> Optional[Checkpoint]:
        return self.checkpoints.get(job_id)

    def delete(self, job_id: str) -> bool:
        with self._lock:
            if job_id in self.checkpoints:
                del self.checkpoints[job_id]
                return True
            return False


class BatchExecutor:
    """Execute batch jobs."""

    def __init__(self, checkpoint_store: CheckpointStore = None):
        self.checkpoint_store = checkpoint_store or CheckpointStore()
        self._running_jobs: Dict[str, BatchJob] = {}
        self._lock = threading.Lock()

    async def execute(self, job: BatchJob, resume: bool = False) -> BatchJob:
        """Execute a batch job."""
        job.status = JobStatus.RUNNING
        job.started_at = datetime.now()
        job.metrics.start_time = job.started_at

        with self._lock:
            self._running_jobs[job.id] = job

        # Check for checkpoint to resume
        start_step = 0
        if resume:
            checkpoint = self.checkpoint_store.load(job.id)
            if checkpoint:
                start_step = checkpoint.step_index
                logger.info(f"Resuming job {job.id} from step {start_step}")

        try:
            for i, step in enumerate(job.steps[start_step:], start_step):
                if job.status == JobStatus.CANCELLED:
                    break

                step_result = await self._execute_step(job, step, i)
                step.result = step_result
                step.status = step_result.status

                job.metrics.items_processed += step_result.items_processed
                job.metrics.items_failed += step_result.items_failed

                if step_result.status == StepStatus.FAILED and not step.skip_on_error:
                    job.status = JobStatus.FAILED
                    break

            if job.status == JobStatus.RUNNING:
                job.status = JobStatus.COMPLETED

        except Exception as e:
            logger.error(f"Job {job.id} failed: {e}")
            job.status = JobStatus.FAILED

        finally:
            job.completed_at = datetime.now()
            job.metrics.end_time = job.completed_at
            job.metrics.duration_ms = (
                job.completed_at - job.started_at
            ).total_seconds() * 1000

            self.checkpoint_store.delete(job.id)

            with self._lock:
                del self._running_jobs[job.id]

        return job

    async def _execute_step(
        self,
        job: BatchJob,
        step: BatchStep,
        step_index: int
    ) -> StepResult:
        """Execute a single step."""
        import time
        start = time.time()

        step.status = StepStatus.RUNNING
        items_processed = 0
        items_failed = 0

        try:
            # Open reader
            if step.reader:
                step.reader.open()

            # Open writer
            if step.writer:
                step.writer.open()

            # Process chunks
            if step.reader:
                for chunk_num, chunk in enumerate(step.reader.read(step.chunk_size)):
                    # Process
                    if step.processor:
                        processed, failed = step.processor.process(chunk)
                        items_failed += len(failed)
                    else:
                        processed = chunk

                    # Write
                    if step.writer and processed:
                        step.writer.write(processed)

                    items_processed += len(processed)

                    # Save checkpoint
                    checkpoint = Checkpoint(
                        job_id=job.id,
                        step_index=step_index,
                        position=chunk_num,
                        data={"items_processed": items_processed}
                    )
                    self.checkpoint_store.save(checkpoint)

                    # Allow cancellation between chunks
                    await asyncio.sleep(0)

            # Flush and close
            if step.writer:
                step.writer.flush()
                step.writer.close()

            if step.reader:
                step.reader.close()

            status = StepStatus.COMPLETED

        except Exception as e:
            logger.error(f"Step {step.name} failed: {e}")
            status = StepStatus.FAILED
            error = str(e)
        else:
            error = None

        duration = (time.time() - start) * 1000

        return StepResult(
            status=status,
            items_processed=items_processed,
            items_failed=items_failed,
            error=error,
            duration_ms=duration
        )

    def cancel(self, job_id: str) -> bool:
        """Cancel a running job."""
        with self._lock:
            if job_id in self._running_jobs:
                self._running_jobs[job_id].status = JobStatus.CANCELLED
                return True
            return False


class BatchJobBuilder:
    """Builder for batch jobs."""

    def __init__(self, name: str):
        self.name = name
        self.steps: List[BatchStep] = []
        self._current_reader: Optional[BatchReader] = None
        self._current_processors: List[BatchProcessor] = []

    def read_from(self, reader: BatchReader) -> "BatchJobBuilder":
        """Set reader for current step."""
        self._current_reader = reader
        return self

    def read_list(self, items: List[Any]) -> "BatchJobBuilder":
        """Read from a list."""
        return self.read_from(ListReader(items))

    def map(self, fn: Callable[[Any], Any]) -> "BatchJobBuilder":
        """Add map processor."""
        self._current_processors.append(MapProcessor(fn))
        return self

    def filter(self, predicate: Callable[[Any], bool]) -> "BatchJobBuilder":
        """Add filter processor."""
        self._current_processors.append(FilterProcessor(predicate))
        return self

    def write_to(self, writer: BatchWriter) -> "BatchJobBuilder":
        """Add write step."""
        processor = None
        if self._current_processors:
            processor = ChainProcessor(self._current_processors)

        step = BatchStep(
            name=f"step_{len(self.steps) + 1}",
            reader=self._current_reader,
            processor=processor,
            writer=writer
        )

        self.steps.append(step)
        self._current_reader = None
        self._current_processors = []

        return self

    def write_list(self) -> Tuple["BatchJobBuilder", ListWriter]:
        """Write to a list."""
        writer = ListWriter()
        self.write_to(writer)
        return self, writer

    def chunk_size(self, size: int) -> "BatchJobBuilder":
        """Set chunk size for last step."""
        if self.steps:
            self.steps[-1].chunk_size = size
        return self

    def build(self) -> BatchJob:
        """Build the job."""
        return BatchJob(
            id=str(uuid.uuid4()),
            name=self.name,
            steps=self.steps
        )


class BatchManager:
    """High-level batch management."""

    def __init__(self):
        self.executor = BatchExecutor()
        self.jobs: Dict[str, BatchJob] = {}

    def create_job(self, name: str) -> BatchJobBuilder:
        """Create a new job builder."""
        return BatchJobBuilder(name)

    async def run(self, job: BatchJob, resume: bool = False) -> BatchJob:
        """Run a job."""
        self.jobs[job.id] = job
        return await self.executor.execute(job, resume)

    def cancel(self, job_id: str) -> bool:
        """Cancel a job."""
        return self.executor.cancel(job_id)

    def get_job(self, job_id: str) -> Optional[BatchJob]:
        """Get job by ID."""
        return self.jobs.get(job_id)

    def list_jobs(self, status: JobStatus = None) -> List[Dict[str, Any]]:
        """List jobs."""
        jobs = list(self.jobs.values())
        if status:
            jobs = [j for j in jobs if j.status == status]

        return [
            {
                "id": j.id,
                "name": j.name,
                "status": j.status.value,
                "items_processed": j.metrics.items_processed,
                "duration_ms": j.metrics.duration_ms
            }
            for j in jobs
        ]


# Example usage
async def example_usage():
    """Example batch processing usage."""
    manager = BatchManager()

    # Create sample data
    data = [
        {"id": i, "value": i * 10, "category": "A" if i % 2 == 0 else "B"}
        for i in range(100)
    ]

    # Build job with fluent API
    builder, output = (
        manager.create_job("process_data")
        .read_list(data)
        .filter(lambda x: x["category"] == "A")
        .map(lambda x: {"id": x["id"], "doubled": x["value"] * 2})
        .write_list()
    )

    job = builder.build()

    # Run the job
    result = await manager.run(job)

    print(f"Job {result.name}: {result.status.value}")
    print(f"Items processed: {result.metrics.items_processed}")
    print(f"Duration: {result.metrics.duration_ms:.2f}ms")
    print(f"Throughput: {result.metrics.items_per_second:.2f} items/sec")
    print(f"Output count: {len(output.items)}")

    # List jobs
    jobs = manager.list_jobs()
    print(f"\nAll jobs: {jobs}")

