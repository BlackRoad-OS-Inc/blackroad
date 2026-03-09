"""
RoadScheduler - Job Scheduling & Cron System for BlackRoad
Distributed task scheduling with cron expressions, retries, and monitoring.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import asyncio
import hashlib
import heapq
import json
import logging
import re
import time
import uuid

logger = logging.getLogger(__name__)


class JobStatus(str, Enum):
    """Job execution status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    RETRYING = "retrying"


class JobPriority(int, Enum):
    """Job priority levels."""
    LOW = 0
    NORMAL = 5
    HIGH = 10
    CRITICAL = 20


@dataclass
class CronExpression:
    """Parse and evaluate cron expressions."""
    minute: str = "*"
    hour: str = "*"
    day_of_month: str = "*"
    month: str = "*"
    day_of_week: str = "*"

    @classmethod
    def parse(cls, expression: str) -> "CronExpression":
        """Parse cron expression string."""
        parts = expression.strip().split()
        if len(parts) != 5:
            raise ValueError(f"Invalid cron expression: {expression}")
        return cls(
            minute=parts[0],
            hour=parts[1],
            day_of_month=parts[2],
            month=parts[3],
            day_of_week=parts[4]
        )

    @classmethod
    def every_minute(cls) -> "CronExpression":
        return cls()

    @classmethod
    def every_hour(cls) -> "CronExpression":
        return cls(minute="0")

    @classmethod
    def daily(cls, hour: int = 0, minute: int = 0) -> "CronExpression":
        return cls(minute=str(minute), hour=str(hour))

    @classmethod
    def weekly(cls, day: int = 0, hour: int = 0) -> "CronExpression":
        return cls(minute="0", hour=str(hour), day_of_week=str(day))

    def _matches_field(self, field: str, value: int, max_val: int) -> bool:
        """Check if a value matches a cron field."""
        if field == "*":
            return True

        for part in field.split(","):
            if "-" in part:
                start, end = map(int, part.split("-"))
                if start <= value <= end:
                    return True
            elif "/" in part:
                base, step = part.split("/")
                step = int(step)
                if base == "*":
                    if value % step == 0:
                        return True
                else:
                    base = int(base)
                    if value >= base and (value - base) % step == 0:
                        return True
            else:
                if int(part) == value:
                    return True
        return False

    def matches(self, dt: datetime) -> bool:
        """Check if datetime matches this cron expression."""
        return (
            self._matches_field(self.minute, dt.minute, 59) and
            self._matches_field(self.hour, dt.hour, 23) and
            self._matches_field(self.day_of_month, dt.day, 31) and
            self._matches_field(self.month, dt.month, 12) and
            self._matches_field(self.day_of_week, dt.weekday(), 6)
        )

    def next_run(self, after: datetime) -> datetime:
        """Calculate next run time after given datetime."""
        candidate = after.replace(second=0, microsecond=0) + timedelta(minutes=1)
        for _ in range(525600):  # Max 1 year of minutes
            if self.matches(candidate):
                return candidate
            candidate += timedelta(minutes=1)
        raise ValueError("Could not find next run time within 1 year")


@dataclass
class RetryPolicy:
    """Retry configuration for failed jobs."""
    max_retries: int = 3
    initial_delay: float = 1.0
    max_delay: float = 300.0
    exponential_base: float = 2.0
    retryable_exceptions: Set[type] = field(default_factory=set)

    def get_delay(self, attempt: int) -> float:
        """Calculate delay for retry attempt."""
        delay = self.initial_delay * (self.exponential_base ** attempt)
        return min(delay, self.max_delay)

    def should_retry(self, exception: Exception, attempt: int) -> bool:
        """Check if job should be retried."""
        if attempt >= self.max_retries:
            return False
        if self.retryable_exceptions:
            return type(exception) in self.retryable_exceptions
        return True


@dataclass
class Job:
    """A scheduled job definition."""
    id: str
    name: str
    func: Callable
    args: tuple = field(default_factory=tuple)
    kwargs: Dict[str, Any] = field(default_factory=dict)
    schedule: Optional[CronExpression] = None
    run_at: Optional[datetime] = None
    priority: JobPriority = JobPriority.NORMAL
    timeout: Optional[float] = None
    retry_policy: RetryPolicy = field(default_factory=RetryPolicy)
    tags: Set[str] = field(default_factory=set)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __lt__(self, other: "Job") -> bool:
        """Compare jobs for priority queue."""
        return (self.priority.value, self.run_at or datetime.min) > (
            other.priority.value, other.run_at or datetime.min
        )


@dataclass
class JobExecution:
    """Record of a job execution."""
    id: str
    job_id: str
    job_name: str
    status: JobStatus
    started_at: datetime
    finished_at: Optional[datetime] = None
    result: Any = None
    error: Optional[str] = None
    attempt: int = 1
    duration_ms: Optional[float] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "job_id": self.job_id,
            "job_name": self.job_name,
            "status": self.status.value,
            "started_at": self.started_at.isoformat(),
            "finished_at": self.finished_at.isoformat() if self.finished_at else None,
            "result": str(self.result) if self.result else None,
            "error": self.error,
            "attempt": self.attempt,
            "duration_ms": self.duration_ms
        }


class JobStore:
    """Store and retrieve job definitions and executions."""

    def __init__(self):
        self.jobs: Dict[str, Job] = {}
        self.executions: List[JobExecution] = []
        self.execution_limit = 10000

    def add_job(self, job: Job) -> None:
        """Add a job to the store."""
        self.jobs[job.id] = job
        logger.info(f"Added job: {job.name} ({job.id})")

    def remove_job(self, job_id: str) -> Optional[Job]:
        """Remove a job from the store."""
        return self.jobs.pop(job_id, None)

    def get_job(self, job_id: str) -> Optional[Job]:
        """Get a job by ID."""
        return self.jobs.get(job_id)

    def get_jobs_by_tag(self, tag: str) -> List[Job]:
        """Get all jobs with a specific tag."""
        return [j for j in self.jobs.values() if tag in j.tags]

    def record_execution(self, execution: JobExecution) -> None:
        """Record a job execution."""
        self.executions.append(execution)
        if len(self.executions) > self.execution_limit:
            self.executions = self.executions[-self.execution_limit:]

    def get_executions(
        self,
        job_id: Optional[str] = None,
        status: Optional[JobStatus] = None,
        limit: int = 100
    ) -> List[JobExecution]:
        """Get job executions with optional filters."""
        results = self.executions
        if job_id:
            results = [e for e in results if e.job_id == job_id]
        if status:
            results = [e for e in results if e.status == status]
        return results[-limit:]


class Scheduler:
    """Main job scheduler with cron support."""

    def __init__(self, max_workers: int = 10):
        self.store = JobStore()
        self.max_workers = max_workers
        self.running = False
        self.pending_jobs: List[tuple] = []  # Priority queue
        self.active_tasks: Dict[str, asyncio.Task] = {}
        self._lock = asyncio.Lock()

    def add_job(
        self,
        func: Callable,
        name: Optional[str] = None,
        schedule: Optional[str] = None,
        run_at: Optional[datetime] = None,
        priority: JobPriority = JobPriority.NORMAL,
        timeout: Optional[float] = None,
        retry_policy: Optional[RetryPolicy] = None,
        tags: Optional[Set[str]] = None,
        args: tuple = (),
        kwargs: Optional[Dict[str, Any]] = None
    ) -> Job:
        """Add a new job to the scheduler."""
        job = Job(
            id=str(uuid.uuid4()),
            name=name or func.__name__,
            func=func,
            args=args,
            kwargs=kwargs or {},
            schedule=CronExpression.parse(schedule) if schedule else None,
            run_at=run_at,
            priority=priority,
            timeout=timeout,
            retry_policy=retry_policy or RetryPolicy(),
            tags=tags or set()
        )
        self.store.add_job(job)

        if job.run_at:
            self._schedule_job(job, job.run_at)
        elif job.schedule:
            next_run = job.schedule.next_run(datetime.now())
            self._schedule_job(job, next_run)

        return job

    def _schedule_job(self, job: Job, run_at: datetime) -> None:
        """Add job to priority queue."""
        heapq.heappush(self.pending_jobs, (run_at, job.priority.value, job.id))

    def remove_job(self, job_id: str) -> bool:
        """Remove a job from the scheduler."""
        job = self.store.remove_job(job_id)
        if job:
            if job_id in self.active_tasks:
                self.active_tasks[job_id].cancel()
            return True
        return False

    def pause_job(self, job_id: str) -> bool:
        """Pause a scheduled job."""
        job = self.store.get_job(job_id)
        if job:
            job.metadata["paused"] = True
            return True
        return False

    def resume_job(self, job_id: str) -> bool:
        """Resume a paused job."""
        job = self.store.get_job(job_id)
        if job:
            job.metadata.pop("paused", None)
            if job.schedule:
                next_run = job.schedule.next_run(datetime.now())
                self._schedule_job(job, next_run)
            return True
        return False

    async def _execute_job(self, job: Job, attempt: int = 1) -> JobExecution:
        """Execute a single job."""
        execution = JobExecution(
            id=str(uuid.uuid4()),
            job_id=job.id,
            job_name=job.name,
            status=JobStatus.RUNNING,
            started_at=datetime.now(),
            attempt=attempt
        )

        try:
            logger.info(f"Executing job: {job.name} (attempt {attempt})")

            if asyncio.iscoroutinefunction(job.func):
                if job.timeout:
                    result = await asyncio.wait_for(
                        job.func(*job.args, **job.kwargs),
                        timeout=job.timeout
                    )
                else:
                    result = await job.func(*job.args, **job.kwargs)
            else:
                loop = asyncio.get_event_loop()
                if job.timeout:
                    result = await asyncio.wait_for(
                        loop.run_in_executor(None, lambda: job.func(*job.args, **job.kwargs)),
                        timeout=job.timeout
                    )
                else:
                    result = await loop.run_in_executor(
                        None, lambda: job.func(*job.args, **job.kwargs)
                    )

            execution.status = JobStatus.COMPLETED
            execution.result = result
            logger.info(f"Job completed: {job.name}")

        except asyncio.TimeoutError:
            execution.status = JobStatus.FAILED
            execution.error = f"Job timed out after {job.timeout}s"
            logger.error(f"Job timeout: {job.name}")

        except Exception as e:
            if job.retry_policy.should_retry(e, attempt):
                execution.status = JobStatus.RETRYING
                execution.error = str(e)
                delay = job.retry_policy.get_delay(attempt)
                logger.warning(f"Job failed, retrying in {delay}s: {job.name}")
                await asyncio.sleep(delay)
                return await self._execute_job(job, attempt + 1)
            else:
                execution.status = JobStatus.FAILED
                execution.error = str(e)
                logger.error(f"Job failed: {job.name} - {e}")

        finally:
            execution.finished_at = datetime.now()
            execution.duration_ms = (
                execution.finished_at - execution.started_at
            ).total_seconds() * 1000
            self.store.record_execution(execution)
            self.active_tasks.pop(job.id, None)

        return execution

    async def run_job_now(self, job_id: str) -> Optional[JobExecution]:
        """Execute a job immediately."""
        job = self.store.get_job(job_id)
        if not job:
            return None
        return await self._execute_job(job)

    async def _scheduler_loop(self) -> None:
        """Main scheduler loop."""
        while self.running:
            now = datetime.now()

            while self.pending_jobs:
                run_at, _, job_id = self.pending_jobs[0]

                if run_at > now:
                    break

                heapq.heappop(self.pending_jobs)
                job = self.store.get_job(job_id)

                if not job or job.metadata.get("paused"):
                    continue

                if len(self.active_tasks) >= self.max_workers:
                    self._schedule_job(job, now + timedelta(seconds=1))
                    continue

                task = asyncio.create_task(self._execute_job(job))
                self.active_tasks[job.id] = task

                if job.schedule:
                    next_run = job.schedule.next_run(now)
                    self._schedule_job(job, next_run)

            await asyncio.sleep(0.1)

    async def start(self) -> None:
        """Start the scheduler."""
        self.running = True
        logger.info("Scheduler started")
        await self._scheduler_loop()

    async def stop(self, wait: bool = True) -> None:
        """Stop the scheduler."""
        self.running = False
        if wait and self.active_tasks:
            await asyncio.gather(*self.active_tasks.values(), return_exceptions=True)
        logger.info("Scheduler stopped")

    def get_stats(self) -> Dict[str, Any]:
        """Get scheduler statistics."""
        executions = self.store.executions
        completed = sum(1 for e in executions if e.status == JobStatus.COMPLETED)
        failed = sum(1 for e in executions if e.status == JobStatus.FAILED)

        return {
            "total_jobs": len(self.store.jobs),
            "pending_jobs": len(self.pending_jobs),
            "active_jobs": len(self.active_tasks),
            "total_executions": len(executions),
            "completed_executions": completed,
            "failed_executions": failed,
            "success_rate": completed / len(executions) if executions else 0
        }


class DistributedScheduler(Scheduler):
    """Distributed scheduler with leader election and job locking."""

    def __init__(
        self,
        node_id: str,
        redis_url: Optional[str] = None,
        max_workers: int = 10
    ):
        super().__init__(max_workers)
        self.node_id = node_id
        self.redis_url = redis_url
        self.is_leader = False
        self.job_locks: Dict[str, str] = {}

    async def acquire_lock(self, job_id: str, ttl: int = 300) -> bool:
        """Acquire distributed lock for job execution."""
        lock_key = f"job_lock:{job_id}"
        lock_value = f"{self.node_id}:{time.time()}"

        # In production, use Redis SETNX
        if job_id not in self.job_locks:
            self.job_locks[job_id] = lock_value
            return True
        return False

    async def release_lock(self, job_id: str) -> None:
        """Release distributed lock."""
        self.job_locks.pop(job_id, None)

    async def _execute_job(self, job: Job, attempt: int = 1) -> JobExecution:
        """Execute job with distributed locking."""
        if not await self.acquire_lock(job.id):
            logger.info(f"Job {job.name} locked by another node")
            return JobExecution(
                id=str(uuid.uuid4()),
                job_id=job.id,
                job_name=job.name,
                status=JobStatus.CANCELLED,
                started_at=datetime.now(),
                error="Job locked by another node"
            )

        try:
            return await super()._execute_job(job, attempt)
        finally:
            await self.release_lock(job.id)


# Decorator for easy job registration
def job(
    scheduler: Scheduler,
    schedule: Optional[str] = None,
    name: Optional[str] = None,
    **kwargs
):
    """Decorator to register a function as a scheduled job."""
    def decorator(func: Callable):
        scheduler.add_job(func, name=name, schedule=schedule, **kwargs)
        return func
    return decorator


# Convenience functions
def every(interval: str) -> str:
    """Create cron expression for common intervals."""
    intervals = {
        "minute": "* * * * *",
        "hour": "0 * * * *",
        "day": "0 0 * * *",
        "week": "0 0 * * 0",
        "month": "0 0 1 * *",
    }
    return intervals.get(interval, interval)


# Example usage
async def example_usage():
    """Example scheduler usage."""
    scheduler = Scheduler(max_workers=5)

    # Add a one-time job
    def send_email(to: str, subject: str):
        print(f"Sending email to {to}: {subject}")
        return True

    scheduler.add_job(
        send_email,
        name="welcome_email",
        run_at=datetime.now() + timedelta(seconds=5),
        args=("user@example.com", "Welcome!"),
        priority=JobPriority.HIGH
    )

    # Add a recurring job
    async def cleanup_temp_files():
        print("Cleaning up temp files...")
        return {"deleted": 42}

    scheduler.add_job(
        cleanup_temp_files,
        name="cleanup",
        schedule="0 * * * *",  # Every hour
        tags={"maintenance", "cleanup"}
    )

    # Start scheduler
    await scheduler.start()
