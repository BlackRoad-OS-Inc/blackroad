"""
RoadPipeline - Data Pipeline System for BlackRoad
ETL pipelines with scheduling, transforms, and monitoring.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Union
import asyncio
import hashlib
import json
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class PipelineStatus(str, Enum):
    """Pipeline run status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    PAUSED = "paused"


class StageStatus(str, Enum):
    """Stage execution status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


@dataclass
class DataRecord:
    """A record in the pipeline."""
    data: Dict[str, Any]
    metadata: Dict[str, Any] = field(default_factory=dict)
    source: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class StageResult:
    """Result of a stage execution."""
    stage_id: str
    status: StageStatus
    records_in: int = 0
    records_out: int = 0
    started_at: datetime = field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    error: Optional[str] = None
    metrics: Dict[str, Any] = field(default_factory=dict)


@dataclass
class PipelineRun:
    """A pipeline execution run."""
    id: str
    pipeline_id: str
    status: PipelineStatus
    stages: List[StageResult] = field(default_factory=list)
    context: Dict[str, Any] = field(default_factory=dict)
    started_at: datetime = field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    records_processed: int = 0
    error: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "pipeline_id": self.pipeline_id,
            "status": self.status.value,
            "started_at": self.started_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "records_processed": self.records_processed,
            "stages": len(self.stages)
        }


class Source:
    """Base data source."""
    
    def read(self) -> Generator[DataRecord, None, None]:
        raise NotImplementedError


class IterableSource(Source):
    """Source from iterable."""
    
    def __init__(self, data: List[Dict[str, Any]], source_name: str = "iterable"):
        self.data = data
        self.source_name = source_name
    
    def read(self) -> Generator[DataRecord, None, None]:
        for item in self.data:
            yield DataRecord(data=item, source=self.source_name)


class Sink:
    """Base data sink."""
    
    def write(self, records: List[DataRecord]) -> int:
        raise NotImplementedError


class ListSink(Sink):
    """Sink to a list."""
    
    def __init__(self):
        self.records: List[DataRecord] = []
    
    def write(self, records: List[DataRecord]) -> int:
        self.records.extend(records)
        return len(records)


class Transform:
    """Base transform."""
    
    def apply(self, record: DataRecord) -> Optional[DataRecord]:
        raise NotImplementedError


class MapTransform(Transform):
    """Map function over records."""
    
    def __init__(self, fn: Callable[[Dict], Dict]):
        self.fn = fn
    
    def apply(self, record: DataRecord) -> Optional[DataRecord]:
        result = self.fn(record.data)
        if result:
            record.data = result
            return record
        return None


class FilterTransform(Transform):
    """Filter records."""
    
    def __init__(self, predicate: Callable[[Dict], bool]):
        self.predicate = predicate
    
    def apply(self, record: DataRecord) -> Optional[DataRecord]:
        if self.predicate(record.data):
            return record
        return None


class FieldTransform(Transform):
    """Transform specific fields."""
    
    def __init__(self, field_transforms: Dict[str, Callable[[Any], Any]]):
        self.field_transforms = field_transforms
    
    def apply(self, record: DataRecord) -> Optional[DataRecord]:
        for field, fn in self.field_transforms.items():
            if field in record.data:
                record.data[field] = fn(record.data[field])
        return record


@dataclass
class Stage:
    """A pipeline stage."""
    id: str
    name: str
    transforms: List[Transform] = field(default_factory=list)
    batch_size: int = 100
    parallel: bool = False
    on_error: str = "fail"  # fail, skip, retry
    retries: int = 3
    condition: Optional[Callable[[Dict], bool]] = None

    def process(self, record: DataRecord) -> Optional[DataRecord]:
        """Process a single record through transforms."""
        for transform in self.transforms:
            record = transform.apply(record)
            if record is None:
                return None
        return record

    def process_batch(self, records: List[DataRecord]) -> List[DataRecord]:
        """Process a batch of records."""
        results = []
        for record in records:
            try:
                result = self.process(record)
                if result:
                    results.append(result)
            except Exception as e:
                if self.on_error == "fail":
                    raise
                elif self.on_error == "skip":
                    logger.warning(f"Skipping record due to error: {e}")
                    continue
        return results


@dataclass
class Pipeline:
    """A data pipeline."""
    id: str
    name: str
    description: str = ""
    source: Optional[Source] = None
    sink: Optional[Sink] = None
    stages: List[Stage] = field(default_factory=list)
    schedule: Optional[str] = None  # Cron expression
    retry_policy: Dict[str, Any] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def add_stage(self, stage: Stage) -> None:
        self.stages.append(stage)

    def add_transform(self, transform: Transform) -> None:
        """Add transform to last stage or create new stage."""
        if not self.stages:
            stage = Stage(id=str(uuid.uuid4())[:8], name="main")
            self.stages.append(stage)
        self.stages[-1].transforms.append(transform)


class PipelineStore:
    """Store for pipelines and runs."""

    def __init__(self):
        self.pipelines: Dict[str, Pipeline] = {}
        self.runs: Dict[str, PipelineRun] = {}
        self._lock = threading.Lock()

    def save_pipeline(self, pipeline: Pipeline) -> None:
        with self._lock:
            self.pipelines[pipeline.id] = pipeline

    def get_pipeline(self, pipeline_id: str) -> Optional[Pipeline]:
        return self.pipelines.get(pipeline_id)

    def save_run(self, run: PipelineRun) -> None:
        with self._lock:
            self.runs[run.id] = run

    def get_run(self, run_id: str) -> Optional[PipelineRun]:
        return self.runs.get(run_id)

    def get_runs(self, pipeline_id: str, limit: int = 100) -> List[PipelineRun]:
        runs = [r for r in self.runs.values() if r.pipeline_id == pipeline_id]
        return sorted(runs, key=lambda r: r.started_at, reverse=True)[:limit]


class PipelineExecutor:
    """Execute pipelines."""

    def __init__(self, store: PipelineStore):
        self.store = store
        self._running_pipelines: Dict[str, bool] = {}

    def _create_run(self, pipeline: Pipeline) -> PipelineRun:
        return PipelineRun(
            id=str(uuid.uuid4()),
            pipeline_id=pipeline.id,
            status=PipelineStatus.PENDING
        )

    async def execute(self, pipeline: Pipeline, context: Dict[str, Any] = None) -> PipelineRun:
        """Execute a pipeline."""
        run = self._create_run(pipeline)
        run.context = context or {}
        run.status = PipelineStatus.RUNNING
        self.store.save_run(run)

        try:
            # Read from source
            records = []
            if pipeline.source:
                for record in pipeline.source.read():
                    records.append(record)

            # Process through stages
            for stage in pipeline.stages:
                stage_result = StageResult(
                    stage_id=stage.id,
                    status=StageStatus.RUNNING,
                    records_in=len(records)
                )

                # Check condition
                if stage.condition and not stage.condition(run.context):
                    stage_result.status = StageStatus.SKIPPED
                    run.stages.append(stage_result)
                    continue

                try:
                    records = stage.process_batch(records)
                    stage_result.records_out = len(records)
                    stage_result.status = StageStatus.COMPLETED
                except Exception as e:
                    stage_result.status = StageStatus.FAILED
                    stage_result.error = str(e)
                    raise

                stage_result.completed_at = datetime.now()
                run.stages.append(stage_result)

            # Write to sink
            if pipeline.sink:
                pipeline.sink.write(records)

            run.records_processed = len(records)
            run.status = PipelineStatus.COMPLETED

        except Exception as e:
            run.status = PipelineStatus.FAILED
            run.error = str(e)
            logger.error(f"Pipeline {pipeline.id} failed: {e}")

        run.completed_at = datetime.now()
        self.store.save_run(run)

        return run


class PipelineBuilder:
    """Builder for creating pipelines."""

    def __init__(self, name: str):
        self.pipeline = Pipeline(
            id=hashlib.md5(f"{name}{datetime.now()}".encode()).hexdigest()[:12],
            name=name
        )
        self._current_stage: Optional[Stage] = None

    def from_source(self, source: Source) -> "PipelineBuilder":
        """Set pipeline source."""
        self.pipeline.source = source
        return self

    def to_sink(self, sink: Sink) -> "PipelineBuilder":
        """Set pipeline sink."""
        self.pipeline.sink = sink
        return self

    def add_stage(self, name: str, **kwargs) -> "PipelineBuilder":
        """Add a new stage."""
        stage = Stage(
            id=hashlib.md5(f"{name}{datetime.now()}".encode()).hexdigest()[:8],
            name=name,
            **kwargs
        )
        self.pipeline.stages.append(stage)
        self._current_stage = stage
        return self

    def map(self, fn: Callable[[Dict], Dict]) -> "PipelineBuilder":
        """Add map transform."""
        self._ensure_stage()
        self._current_stage.transforms.append(MapTransform(fn))
        return self

    def filter(self, predicate: Callable[[Dict], bool]) -> "PipelineBuilder":
        """Add filter transform."""
        self._ensure_stage()
        self._current_stage.transforms.append(FilterTransform(predicate))
        return self

    def transform_field(self, field: str, fn: Callable[[Any], Any]) -> "PipelineBuilder":
        """Add field transform."""
        self._ensure_stage()
        self._current_stage.transforms.append(FieldTransform({field: fn}))
        return self

    def _ensure_stage(self):
        """Ensure we have a current stage."""
        if not self._current_stage:
            self.add_stage("default")

    def build(self) -> Pipeline:
        """Build the pipeline."""
        return self.pipeline


class PipelineManager:
    """High-level pipeline management."""

    def __init__(self):
        self.store = PipelineStore()
        self.executor = PipelineExecutor(self.store)

    def create_pipeline(self, name: str, description: str = "") -> PipelineBuilder:
        """Create a new pipeline builder."""
        builder = PipelineBuilder(name)
        builder.pipeline.description = description
        return builder

    def register(self, pipeline: Pipeline) -> None:
        """Register a pipeline."""
        self.store.save_pipeline(pipeline)
        logger.info(f"Registered pipeline: {pipeline.name}")

    async def run(self, pipeline_id: str, context: Dict[str, Any] = None) -> Optional[PipelineRun]:
        """Run a pipeline."""
        pipeline = self.store.get_pipeline(pipeline_id)
        if not pipeline:
            return None

        return await self.executor.execute(pipeline, context)

    def get_pipeline(self, pipeline_id: str) -> Optional[Pipeline]:
        """Get pipeline by ID."""
        return self.store.get_pipeline(pipeline_id)

    def get_runs(self, pipeline_id: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get pipeline runs."""
        runs = self.store.get_runs(pipeline_id, limit)
        return [r.to_dict() for r in runs]

    def list_pipelines(self) -> List[Dict[str, Any]]:
        """List all pipelines."""
        return [
            {"id": p.id, "name": p.name, "description": p.description}
            for p in self.store.pipelines.values()
        ]


# Example usage
async def example_usage():
    """Example pipeline usage."""
    manager = PipelineManager()

    # Build pipeline
    sink = ListSink()
    
    pipeline = (
        manager.create_pipeline("User Processing", "Process user data")
        .from_source(IterableSource([
            {"name": "Alice", "age": 30, "email": "alice@example.com"},
            {"name": "Bob", "age": 25, "email": "bob@example.com"},
            {"name": "Charlie", "age": 35, "email": "charlie@example.com"}
        ]))
        .to_sink(sink)
        .add_stage("Transform")
        .filter(lambda x: x["age"] >= 28)
        .map(lambda x: {**x, "status": "adult"})
        .transform_field("name", str.upper)
        .build()
    )

    manager.register(pipeline)

    # Run pipeline
    run = await manager.run(pipeline.id)

    print(f"Pipeline run: {run.id}")
    print(f"Status: {run.status.value}")
    print(f"Records processed: {run.records_processed}")
    
    print("\nResults:")
    for record in sink.records:
        print(f"  {record.data}")

    # Get run history
    runs = manager.get_runs(pipeline.id)
    print(f"\nTotal runs: {len(runs)}")
