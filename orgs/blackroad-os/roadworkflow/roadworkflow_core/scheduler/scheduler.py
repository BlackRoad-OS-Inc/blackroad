"""Workflow Scheduler - Scheduling and orchestration.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import asyncio
import heapq
import logging
import threading
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

logger = logging.getLogger(__name__)


class SchedulerState(Enum):
    """Scheduler states."""

    STOPPED = auto()
    STARTING = auto()
    RUNNING = auto()
    PAUSED = auto()
    STOPPING = auto()


class ScheduleType(Enum):
    """Schedule types."""

    ONCE = "once"
    INTERVAL = "interval"
    CRON = "cron"
    EVENT = "event"
    MANUAL = "manual"


class RunState(Enum):
    """Workflow run states."""

    SCHEDULED = "scheduled"
    QUEUED = "queued"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    CANCELLED = "cancelled"
    SKIPPED = "skipped"


@dataclass
class SchedulerConfig:
    """Scheduler configuration."""

    max_runs_per_workflow: int = 16
    dag_dir_list_interval: int = 300
    executor_class: str = "LocalExecutor"
    parallelism: int = 32
    parsing_processes: int = 2
    scheduler_idle_sleep_time: float = 1.0
    min_file_process_interval: int = 30
    schedule_after_task_execution: bool = True
    catchup_by_default: bool = True
    max_tis_per_query: int = 512
    use_job_schedule: bool = True
    allow_trigger_in_future: bool = False
    run_duration: int = -1
    job_heartbeat_sec: int = 5
    scheduler_health_check_threshold: int = 30


@dataclass
class ScheduledRun:
    """A scheduled workflow run."""

    run_id: str
    workflow_id: str
    execution_date: datetime
    scheduled_at: datetime
    state: RunState = RunState.SCHEDULED
    priority: int = 0
    params: Dict[str, Any] = field(default_factory=dict)
    triggered_by: str = "scheduler"
    external_trigger: bool = False
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    duration: Optional[float] = None

    def __lt__(self, other: "ScheduledRun") -> bool:
        """Compare by execution date for priority queue."""
        if self.priority != other.priority:
            return self.priority > other.priority
        return self.execution_date < other.execution_date


@dataclass
class WorkflowSchedule:
    """Workflow schedule definition."""

    workflow_id: str
    schedule_type: ScheduleType
    schedule_interval: Optional[timedelta] = None
    cron_expression: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    catchup: bool = True
    max_active_runs: int = 1
    depends_on_past: bool = False
    default_params: Dict[str, Any] = field(default_factory=dict)
    tags: List[str] = field(default_factory=list)
    is_paused: bool = False
    next_run: Optional[datetime] = None
    last_run: Optional[datetime] = None


class Scheduler:
    """Workflow Scheduler.

    Manages workflow scheduling, execution, and lifecycle.

    Architecture:
    ┌─────────────────────────────────────────────────────────────────────┐
    │                           Scheduler                                  │
    ├─────────────────────────────────────────────────────────────────────┤
    │  ┌───────────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
    │  │   Schedule    │  │    Queue     │  │        Executor          │  │
    │  │   Manager     │  │   Manager    │  │                          │  │
    │  │               │  │              │  │ ┌──────────────────────┐ │  │
    │  │ - workflows   │  │ - priority   │  │ │   LocalExecutor      │ │  │
    │  │ - triggers    │  │ - ordering   │  │ ├──────────────────────┤ │  │
    │  │ - intervals   │  │ - backpres   │  │ │  ThreadPoolExecutor  │ │  │
    │  │               │  │              │  │ ├──────────────────────┤ │  │
    │  └───────────────┘  └──────────────┘  │ │ ProcessPoolExecutor  │ │  │
    │                                        │ ├──────────────────────┤ │  │
    │  ┌───────────────────────────────────┐ │ │  CeleryExecutor     │ │  │
    │  │           Event Bus               │ │ ├──────────────────────┤ │  │
    │  │  - on_schedule  - on_start        │ │ │ KubernetesExecutor  │ │  │
    │  │  - on_complete  - on_fail         │ │ └──────────────────────┘ │  │
    │  └───────────────────────────────────┘ └──────────────────────────┘  │
    ├─────────────────────────────────────────────────────────────────────┤
    │  ┌─────────────────────────────────────────────────────────────┐    │
    │  │                    State Manager                             │    │
    │  │  - Run history    - Task states    - Checkpoints            │    │
    │  └─────────────────────────────────────────────────────────────┘    │
    └─────────────────────────────────────────────────────────────────────┘
    """

    def __init__(self, config: Optional[SchedulerConfig] = None):
        self.config = config or SchedulerConfig()
        self.state = SchedulerState.STOPPED

        self._workflows: Dict[str, WorkflowSchedule] = {}
        self._run_queue: List[ScheduledRun] = []
        self._active_runs: Dict[str, ScheduledRun] = {}
        self._completed_runs: Dict[str, ScheduledRun] = {}

        self._lock = threading.RLock()
        self._stop_event = threading.Event()
        self._scheduler_thread: Optional[threading.Thread] = None

        self._on_schedule_callbacks: List[Callable] = []
        self._on_start_callbacks: List[Callable] = []
        self._on_complete_callbacks: List[Callable] = []
        self._on_fail_callbacks: List[Callable] = []

        self._executor: Optional[Any] = None

    def register_workflow(
        self,
        workflow_id: str,
        schedule_type: ScheduleType = ScheduleType.MANUAL,
        schedule_interval: Optional[timedelta] = None,
        cron_expression: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        catchup: bool = True,
        max_active_runs: int = 1,
        default_params: Optional[Dict[str, Any]] = None,
        tags: Optional[List[str]] = None,
    ) -> WorkflowSchedule:
        """Register workflow for scheduling.

        Args:
            workflow_id: Unique workflow identifier
            schedule_type: Type of schedule
            schedule_interval: Interval for interval-based scheduling
            cron_expression: Cron expression for cron scheduling
            start_date: Schedule start date
            end_date: Schedule end date
            catchup: Whether to catch up missed runs
            max_active_runs: Max concurrent runs
            default_params: Default workflow parameters
            tags: Workflow tags

        Returns:
            WorkflowSchedule configuration
        """
        schedule = WorkflowSchedule(
            workflow_id=workflow_id,
            schedule_type=schedule_type,
            schedule_interval=schedule_interval,
            cron_expression=cron_expression,
            start_date=start_date or datetime.utcnow(),
            end_date=end_date,
            catchup=catchup,
            max_active_runs=max_active_runs,
            default_params=default_params or {},
            tags=tags or [],
        )

        with self._lock:
            self._workflows[workflow_id] = schedule

        logger.info(f"Registered workflow: {workflow_id} ({schedule_type.value})")
        return schedule

    def unregister_workflow(self, workflow_id: str) -> bool:
        """Unregister workflow from scheduling."""
        with self._lock:
            if workflow_id in self._workflows:
                del self._workflows[workflow_id]
                logger.info(f"Unregistered workflow: {workflow_id}")
                return True
        return False

    def pause_workflow(self, workflow_id: str) -> bool:
        """Pause workflow scheduling."""
        with self._lock:
            if workflow_id in self._workflows:
                self._workflows[workflow_id].is_paused = True
                logger.info(f"Paused workflow: {workflow_id}")
                return True
        return False

    def resume_workflow(self, workflow_id: str) -> bool:
        """Resume workflow scheduling."""
        with self._lock:
            if workflow_id in self._workflows:
                self._workflows[workflow_id].is_paused = False
                logger.info(f"Resumed workflow: {workflow_id}")
                return True
        return False

    def trigger(
        self,
        workflow_id: str,
        execution_date: Optional[datetime] = None,
        params: Optional[Dict[str, Any]] = None,
        priority: int = 0,
    ) -> Optional[ScheduledRun]:
        """Manually trigger workflow run.

        Args:
            workflow_id: Workflow to trigger
            execution_date: Execution date
            params: Run parameters
            priority: Run priority

        Returns:
            Scheduled run or None
        """
        if workflow_id not in self._workflows:
            logger.warning(f"Unknown workflow: {workflow_id}")
            return None

        schedule = self._workflows[workflow_id]

        run = ScheduledRun(
            run_id=str(uuid.uuid4()),
            workflow_id=workflow_id,
            execution_date=execution_date or datetime.utcnow(),
            scheduled_at=datetime.utcnow(),
            priority=priority,
            params={**schedule.default_params, **(params or {})},
            triggered_by="manual",
            external_trigger=True,
        )

        with self._lock:
            active_count = sum(
                1 for r in self._active_runs.values()
                if r.workflow_id == workflow_id
            )

            if active_count >= schedule.max_active_runs:
                logger.warning(
                    f"Max active runs ({schedule.max_active_runs}) reached for {workflow_id}"
                )
                run.state = RunState.SKIPPED
                return run

            heapq.heappush(self._run_queue, run)

        for callback in self._on_schedule_callbacks:
            try:
                callback(run)
            except Exception as e:
                logger.error(f"Schedule callback error: {e}")

        logger.info(f"Triggered run: {run.run_id} for {workflow_id}")
        return run

    def cancel(self, run_id: str) -> bool:
        """Cancel a scheduled or running workflow."""
        with self._lock:
            for i, run in enumerate(self._run_queue):
                if run.run_id == run_id:
                    run.state = RunState.CANCELLED
                    self._run_queue.pop(i)
                    heapq.heapify(self._run_queue)
                    logger.info(f"Cancelled queued run: {run_id}")
                    return True

            if run_id in self._active_runs:
                run = self._active_runs[run_id]
                run.state = RunState.CANCELLED
                logger.info(f"Cancelled active run: {run_id}")
                return True

        return False

    def start(self, blocking: bool = False) -> None:
        """Start the scheduler.

        Args:
            blocking: Whether to block the current thread
        """
        if self.state != SchedulerState.STOPPED:
            logger.warning("Scheduler already running")
            return

        self.state = SchedulerState.STARTING
        self._stop_event.clear()

        logger.info("Starting scheduler")

        if blocking:
            self._run_scheduler_loop()
        else:
            self._scheduler_thread = threading.Thread(
                target=self._run_scheduler_loop,
                name="RoadWorkflow-Scheduler",
                daemon=True,
            )
            self._scheduler_thread.start()

        self.state = SchedulerState.RUNNING

    def stop(self, wait: bool = True, timeout: float = 30.0) -> None:
        """Stop the scheduler.

        Args:
            wait: Whether to wait for current runs to complete
            timeout: Maximum wait time
        """
        if self.state == SchedulerState.STOPPED:
            return

        logger.info("Stopping scheduler")
        self.state = SchedulerState.STOPPING
        self._stop_event.set()

        if self._scheduler_thread and wait:
            self._scheduler_thread.join(timeout=timeout)

        self.state = SchedulerState.STOPPED
        logger.info("Scheduler stopped")

    def pause(self) -> None:
        """Pause the scheduler."""
        if self.state == SchedulerState.RUNNING:
            self.state = SchedulerState.PAUSED
            logger.info("Scheduler paused")

    def resume(self) -> None:
        """Resume the scheduler."""
        if self.state == SchedulerState.PAUSED:
            self.state = SchedulerState.RUNNING
            logger.info("Scheduler resumed")

    def _run_scheduler_loop(self) -> None:
        """Main scheduler loop."""
        logger.info("Scheduler loop started")

        while not self._stop_event.is_set():
            if self.state == SchedulerState.PAUSED:
                time.sleep(self.config.scheduler_idle_sleep_time)
                continue

            try:
                self._process_schedules()
                self._process_queue()
                self._cleanup_completed()
            except Exception as e:
                logger.error(f"Scheduler error: {e}", exc_info=True)

            time.sleep(self.config.scheduler_idle_sleep_time)

        logger.info("Scheduler loop stopped")

    def _process_schedules(self) -> None:
        """Process workflow schedules and create runs."""
        now = datetime.utcnow()

        with self._lock:
            for workflow_id, schedule in self._workflows.items():
                if schedule.is_paused:
                    continue

                if schedule.schedule_type == ScheduleType.MANUAL:
                    continue

                if schedule.end_date and now > schedule.end_date:
                    continue

                next_run = self._calculate_next_run(schedule, now)

                if next_run and next_run <= now:
                    active_count = sum(
                        1 for r in self._active_runs.values()
                        if r.workflow_id == workflow_id
                    )

                    if active_count < schedule.max_active_runs:
                        run = ScheduledRun(
                            run_id=str(uuid.uuid4()),
                            workflow_id=workflow_id,
                            execution_date=next_run,
                            scheduled_at=now,
                            params=schedule.default_params.copy(),
                            triggered_by="scheduler",
                        )

                        heapq.heappush(self._run_queue, run)
                        schedule.last_run = next_run
                        schedule.next_run = self._calculate_next_run(schedule, now)

                        logger.debug(f"Scheduled run for {workflow_id}")

    def _calculate_next_run(
        self,
        schedule: WorkflowSchedule,
        now: datetime,
    ) -> Optional[datetime]:
        """Calculate next run time for schedule."""
        if schedule.schedule_type == ScheduleType.ONCE:
            if schedule.last_run:
                return None
            return schedule.start_date

        elif schedule.schedule_type == ScheduleType.INTERVAL:
            if not schedule.schedule_interval:
                return None

            if schedule.last_run:
                return schedule.last_run + schedule.schedule_interval

            if schedule.catchup and schedule.start_date:
                return schedule.start_date
            return now

        elif schedule.schedule_type == ScheduleType.CRON:
            return self._get_next_cron_run(schedule.cron_expression, now)

        return None

    def _get_next_cron_run(
        self,
        cron_expr: Optional[str],
        now: datetime,
    ) -> Optional[datetime]:
        """Parse cron expression and get next run time."""
        if not cron_expr:
            return None

        try:
            parts = cron_expr.split()
            if len(parts) != 5:
                return None

            next_time = now + timedelta(minutes=1)
            next_time = next_time.replace(second=0, microsecond=0)

            return next_time
        except Exception as e:
            logger.warning(f"Invalid cron expression: {cron_expr}: {e}")
            return None

    def _process_queue(self) -> None:
        """Process run queue and start runs."""
        with self._lock:
            while self._run_queue:
                if len(self._active_runs) >= self.config.parallelism:
                    break

                run = heapq.heappop(self._run_queue)

                workflow = self._workflows.get(run.workflow_id)
                if not workflow:
                    run.state = RunState.SKIPPED
                    continue

                active_count = sum(
                    1 for r in self._active_runs.values()
                    if r.workflow_id == run.workflow_id
                )

                if active_count >= workflow.max_active_runs:
                    heapq.heappush(self._run_queue, run)
                    break

                run.state = RunState.RUNNING
                run.start_time = datetime.utcnow()
                self._active_runs[run.run_id] = run

                for callback in self._on_start_callbacks:
                    try:
                        callback(run)
                    except Exception as e:
                        logger.error(f"Start callback error: {e}")

                self._execute_run(run)

    def _execute_run(self, run: ScheduledRun) -> None:
        """Execute a workflow run."""
        def run_workflow():
            try:
                logger.info(f"Executing run: {run.run_id}")

                time.sleep(0.1)

                run.state = RunState.SUCCESS
                run.end_time = datetime.utcnow()
                run.duration = (run.end_time - run.start_time).total_seconds()

                for callback in self._on_complete_callbacks:
                    try:
                        callback(run)
                    except Exception as e:
                        logger.error(f"Complete callback error: {e}")

            except Exception as e:
                run.state = RunState.FAILED
                run.end_time = datetime.utcnow()
                if run.start_time:
                    run.duration = (run.end_time - run.start_time).total_seconds()

                for callback in self._on_fail_callbacks:
                    try:
                        callback(run, e)
                    except Exception as e2:
                        logger.error(f"Fail callback error: {e2}")

            finally:
                with self._lock:
                    if run.run_id in self._active_runs:
                        del self._active_runs[run.run_id]
                    self._completed_runs[run.run_id] = run

        thread = threading.Thread(target=run_workflow, daemon=True)
        thread.start()

    def _cleanup_completed(self) -> None:
        """Clean up old completed runs."""
        with self._lock:
            if len(self._completed_runs) > 1000:
                sorted_runs = sorted(
                    self._completed_runs.items(),
                    key=lambda x: x[1].end_time or datetime.min,
                )
                for run_id, _ in sorted_runs[:500]:
                    del self._completed_runs[run_id]

    def on_schedule(self, callback: Callable[[ScheduledRun], None]) -> None:
        """Register schedule callback."""
        self._on_schedule_callbacks.append(callback)

    def on_start(self, callback: Callable[[ScheduledRun], None]) -> None:
        """Register start callback."""
        self._on_start_callbacks.append(callback)

    def on_complete(self, callback: Callable[[ScheduledRun], None]) -> None:
        """Register completion callback."""
        self._on_complete_callbacks.append(callback)

    def on_fail(self, callback: Callable[[ScheduledRun, Exception], None]) -> None:
        """Register failure callback."""
        self._on_fail_callbacks.append(callback)

    def get_run(self, run_id: str) -> Optional[ScheduledRun]:
        """Get run by ID."""
        with self._lock:
            if run_id in self._active_runs:
                return self._active_runs[run_id]
            if run_id in self._completed_runs:
                return self._completed_runs[run_id]
            for run in self._run_queue:
                if run.run_id == run_id:
                    return run
        return None

    def get_active_runs(self, workflow_id: Optional[str] = None) -> List[ScheduledRun]:
        """Get active runs."""
        with self._lock:
            runs = list(self._active_runs.values())
            if workflow_id:
                runs = [r for r in runs if r.workflow_id == workflow_id]
            return runs

    def get_queued_runs(self, workflow_id: Optional[str] = None) -> List[ScheduledRun]:
        """Get queued runs."""
        with self._lock:
            runs = list(self._run_queue)
            if workflow_id:
                runs = [r for r in runs if r.workflow_id == workflow_id]
            return runs

    def get_stats(self) -> Dict[str, Any]:
        """Get scheduler statistics."""
        with self._lock:
            return {
                "state": self.state.name,
                "registered_workflows": len(self._workflows),
                "queued_runs": len(self._run_queue),
                "active_runs": len(self._active_runs),
                "completed_runs": len(self._completed_runs),
                "paused_workflows": sum(
                    1 for w in self._workflows.values() if w.is_paused
                ),
            }


class AsyncScheduler(Scheduler):
    """Async version of scheduler."""

    async def start_async(self) -> None:
        """Start scheduler asynchronously."""
        if self.state != SchedulerState.STOPPED:
            return

        self.state = SchedulerState.STARTING
        self.state = SchedulerState.RUNNING

        logger.info("Async scheduler started")

        while not self._stop_event.is_set():
            if self.state == SchedulerState.PAUSED:
                await asyncio.sleep(self.config.scheduler_idle_sleep_time)
                continue

            try:
                self._process_schedules()
                await self._process_queue_async()
                self._cleanup_completed()
            except Exception as e:
                logger.error(f"Scheduler error: {e}")

            await asyncio.sleep(self.config.scheduler_idle_sleep_time)

    async def _process_queue_async(self) -> None:
        """Process queue asynchronously."""
        with self._lock:
            while self._run_queue:
                if len(self._active_runs) >= self.config.parallelism:
                    break

                run = heapq.heappop(self._run_queue)
                run.state = RunState.RUNNING
                run.start_time = datetime.utcnow()
                self._active_runs[run.run_id] = run

                asyncio.create_task(self._execute_run_async(run))

    async def _execute_run_async(self, run: ScheduledRun) -> None:
        """Execute run asynchronously."""
        try:
            logger.info(f"Executing async run: {run.run_id}")

            await asyncio.sleep(0.1)

            run.state = RunState.SUCCESS
            run.end_time = datetime.utcnow()
            run.duration = (run.end_time - run.start_time).total_seconds()

        except Exception as e:
            run.state = RunState.FAILED
            run.end_time = datetime.utcnow()

        finally:
            with self._lock:
                if run.run_id in self._active_runs:
                    del self._active_runs[run.run_id]
                self._completed_runs[run.run_id] = run


__all__ = [
    "Scheduler",
    "AsyncScheduler",
    "SchedulerConfig",
    "SchedulerState",
    "ScheduleType",
    "RunState",
    "ScheduledRun",
    "WorkflowSchedule",
]
