"""RoadML Pipeline - Pipeline Orchestration.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Union

from mlpipeline_core.pipeline.step import Step, StepResult, StepStatus
from mlpipeline_core.pipeline.dag import DAG, DAGNode

logger = logging.getLogger(__name__)


class PipelineStatus(Enum):
    """Pipeline execution status."""

    PENDING = auto()
    RUNNING = auto()
    COMPLETED = auto()
    FAILED = auto()
    CANCELLED = auto()
    PAUSED = auto()


@dataclass
class PipelineConfig:
    """Pipeline configuration.

    Attributes:
        name: Pipeline name
        description: Pipeline description
        max_parallelism: Maximum parallel steps
        timeout_seconds: Pipeline timeout
        retry_failed_steps: Retry failed steps
        max_retries: Maximum retries per step
        fail_fast: Stop on first failure
        cache_results: Cache step results
    """

    name: str = "pipeline"
    description: str = ""
    max_parallelism: int = 4
    timeout_seconds: Optional[int] = None
    retry_failed_steps: bool = True
    max_retries: int = 3
    fail_fast: bool = True
    cache_results: bool = True


@dataclass
class PipelineRun:
    """A pipeline execution run.

    Attributes:
        run_id: Unique run identifier
        pipeline_name: Pipeline name
        status: Run status
        started_at: When run started
        completed_at: When run completed
        duration_seconds: Run duration
        step_results: Results from each step
        parameters: Run parameters
        metrics: Run metrics
        error: Error message if failed
    """

    run_id: str
    pipeline_name: str
    status: PipelineStatus = PipelineStatus.PENDING
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    duration_seconds: float = 0.0
    step_results: Dict[str, StepResult] = field(default_factory=dict)
    parameters: Dict[str, Any] = field(default_factory=dict)
    metrics: Dict[str, float] = field(default_factory=dict)
    error: Optional[str] = None

    @property
    def success(self) -> bool:
        """Check if run succeeded."""
        return self.status == PipelineStatus.COMPLETED


class Pipeline:
    """ML pipeline orchestrator.

    Manages end-to-end ML pipelines with features like:
    - DAG-based step orchestration
    - Parallel step execution
    - Automatic retry
    - Result caching
    - Progress tracking

    Example:
        pipeline = Pipeline("training-pipeline")

        @pipeline.step()
        def load_data():
            return pd.read_csv("data.csv")

        @pipeline.step(depends_on=["load_data"])
        def preprocess(load_data):
            return transform(load_data)

        @pipeline.step(depends_on=["preprocess"])
        def train(preprocess):
            return model.fit(preprocess)

        run = pipeline.run()
    """

    def __init__(self, name: str, config: Optional[PipelineConfig] = None):
        """Initialize pipeline.

        Args:
            name: Pipeline name
            config: Pipeline configuration
        """
        self.name = name
        self.config = config or PipelineConfig(name=name)

        self._steps: Dict[str, Step] = {}
        self._dag = DAG()
        self._runs: Dict[str, PipelineRun] = {}
        self._lock = threading.RLock()

        # Current run state
        self._current_run: Optional[PipelineRun] = None
        self._results_cache: Dict[str, Any] = {}

        # Callbacks
        self._on_step_start: Optional[Callable[[str], None]] = None
        self._on_step_complete: Optional[Callable[[str, StepResult], None]] = None
        self._on_pipeline_complete: Optional[Callable[[PipelineRun], None]] = None

    def step(
        self,
        name: Optional[str] = None,
        depends_on: Optional[List[str]] = None,
        retries: int = 0,
        timeout: Optional[int] = None,
        cache: bool = True,
    ) -> Callable:
        """Decorator to register a pipeline step.

        Args:
            name: Step name
            depends_on: Dependency step names
            retries: Retry count
            timeout: Step timeout
            cache: Cache results

        Returns:
            Decorator function
        """
        def decorator(func: Callable) -> Callable:
            step_name = name or func.__name__

            step = Step(
                name=step_name,
                func=func,
                depends_on=depends_on or [],
                retries=retries,
                timeout=timeout,
                cache=cache,
            )

            self.add_step(step)
            return func

        return decorator

    def add_step(self, step: Step) -> None:
        """Add a step to the pipeline.

        Args:
            step: Step to add
        """
        with self._lock:
            self._steps[step.name] = step
            self._dag.add_node(step.name, step.depends_on)

    def remove_step(self, name: str) -> None:
        """Remove a step from the pipeline.

        Args:
            name: Step name to remove
        """
        with self._lock:
            if name in self._steps:
                del self._steps[name]
                self._dag.remove_node(name)

    def run(
        self,
        parameters: Optional[Dict[str, Any]] = None,
        run_id: Optional[str] = None,
    ) -> PipelineRun:
        """Execute the pipeline.

        Args:
            parameters: Run parameters
            run_id: Optional run ID

        Returns:
            PipelineRun result
        """
        run_id = run_id or str(uuid.uuid4())
        pipeline_run = PipelineRun(
            run_id=run_id,
            pipeline_name=self.name,
            parameters=parameters or {},
            started_at=datetime.now(),
        )

        self._current_run = pipeline_run
        self._runs[run_id] = pipeline_run

        logger.info(f"Starting pipeline '{self.name}' run {run_id}")

        try:
            pipeline_run.status = PipelineStatus.RUNNING

            # Get execution order
            execution_order = self._dag.topological_sort()

            if not execution_order:
                raise ValueError("Pipeline has no steps or has cycles")

            # Execute steps
            self._execute_steps(execution_order, pipeline_run)

            # Check for failures
            failed_steps = [
                name for name, result in pipeline_run.step_results.items()
                if result.status == StepStatus.FAILED
            ]

            if failed_steps:
                pipeline_run.status = PipelineStatus.FAILED
                pipeline_run.error = f"Steps failed: {', '.join(failed_steps)}"
            else:
                pipeline_run.status = PipelineStatus.COMPLETED

        except Exception as e:
            pipeline_run.status = PipelineStatus.FAILED
            pipeline_run.error = str(e)
            logger.error(f"Pipeline failed: {e}")

        finally:
            pipeline_run.completed_at = datetime.now()
            pipeline_run.duration_seconds = (
                pipeline_run.completed_at - pipeline_run.started_at
            ).total_seconds()

            if self._on_pipeline_complete:
                self._on_pipeline_complete(pipeline_run)

            logger.info(
                f"Pipeline '{self.name}' completed: {pipeline_run.status.name} "
                f"in {pipeline_run.duration_seconds:.2f}s"
            )

        return pipeline_run

    def _execute_steps(
        self,
        execution_order: List[str],
        pipeline_run: PipelineRun,
    ) -> None:
        """Execute steps in order with parallelism.

        Args:
            execution_order: Step execution order
            pipeline_run: Current run
        """
        completed: Set[str] = set()
        results: Dict[str, Any] = {}

        # Group steps by their dependencies for parallel execution
        with ThreadPoolExecutor(max_workers=self.config.max_parallelism) as executor:
            while len(completed) < len(execution_order):
                # Find steps that can run
                ready = [
                    name for name in execution_order
                    if name not in completed
                    and all(dep in completed for dep in self._steps[name].depends_on)
                ]

                if not ready:
                    if len(completed) < len(execution_order):
                        raise RuntimeError("Pipeline stalled - possible cycle")
                    break

                # Execute ready steps in parallel
                futures = {}
                for step_name in ready:
                    step = self._steps[step_name]

                    # Gather inputs from dependencies
                    inputs = {
                        dep: results[dep]
                        for dep in step.depends_on
                        if dep in results
                    }

                    future = executor.submit(
                        self._execute_step, step, inputs, pipeline_run
                    )
                    futures[future] = step_name

                # Wait for batch
                for future in as_completed(futures.keys()):
                    step_name = futures[future]
                    try:
                        result = future.result()
                        results[step_name] = result.output
                        completed.add(step_name)

                        if result.status == StepStatus.FAILED and self.config.fail_fast:
                            raise RuntimeError(f"Step {step_name} failed")

                    except Exception as e:
                        completed.add(step_name)
                        if self.config.fail_fast:
                            raise

    def _execute_step(
        self,
        step: Step,
        inputs: Dict[str, Any],
        pipeline_run: PipelineRun,
    ) -> StepResult:
        """Execute a single step.

        Args:
            step: Step to execute
            inputs: Input values from dependencies
            pipeline_run: Current run

        Returns:
            Step result
        """
        if self._on_step_start:
            self._on_step_start(step.name)

        # Check cache
        if step.cache and step.name in self._results_cache:
            logger.info(f"Step '{step.name}' using cached result")
            cached_result = self._results_cache[step.name]
            result = StepResult(
                step_name=step.name,
                status=StepStatus.COMPLETED,
                output=cached_result,
            )
            pipeline_run.step_results[step.name] = result
            return result

        # Execute with retry
        result = step.execute(inputs)
        pipeline_run.step_results[step.name] = result

        # Cache result
        if step.cache and result.status == StepStatus.COMPLETED:
            self._results_cache[step.name] = result.output

        if self._on_step_complete:
            self._on_step_complete(step.name, result)

        return result

    def get_run(self, run_id: str) -> Optional[PipelineRun]:
        """Get a pipeline run.

        Args:
            run_id: Run ID

        Returns:
            PipelineRun or None
        """
        return self._runs.get(run_id)

    def list_runs(self) -> List[PipelineRun]:
        """List all runs.

        Returns:
            List of PipelineRun
        """
        return list(self._runs.values())

    def clear_cache(self) -> None:
        """Clear results cache."""
        self._results_cache.clear()

    def visualize(self) -> str:
        """Generate ASCII visualization of pipeline.

        Returns:
            ASCII diagram
        """
        return self._dag.visualize()

    def on_step_start(self, callback: Callable[[str], None]) -> "Pipeline":
        """Set step start callback."""
        self._on_step_start = callback
        return self

    def on_step_complete(
        self,
        callback: Callable[[str, StepResult], None],
    ) -> "Pipeline":
        """Set step complete callback."""
        self._on_step_complete = callback
        return self

    def on_pipeline_complete(
        self,
        callback: Callable[[PipelineRun], None],
    ) -> "Pipeline":
        """Set pipeline complete callback."""
        self._on_pipeline_complete = callback
        return self

    def __repr__(self) -> str:
        return f"Pipeline(name={self.name!r}, steps={len(self._steps)})"


def pipeline(name: str, **config_kwargs) -> Callable:
    """Decorator to create a pipeline from a function.

    Args:
        name: Pipeline name
        **config_kwargs: PipelineConfig arguments

    Returns:
        Decorator function
    """
    config = PipelineConfig(name=name, **config_kwargs)
    pipe = Pipeline(name=name, config=config)

    def decorator(func: Callable) -> Pipeline:
        # The function becomes the final step
        pipe.step(name="main")(func)
        return pipe

    return decorator


__all__ = [
    "Pipeline",
    "PipelineConfig",
    "PipelineRun",
    "PipelineStatus",
    "pipeline",
]
