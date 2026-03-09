"""RoadQueue Scheduler - Cron-like Job Scheduling.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import threading
import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional

from roadqueue_core.queue.message import Message
from roadqueue_core.broker.broker import Broker

logger = logging.getLogger(__name__)


@dataclass
class SchedulerConfig:
    """Scheduler configuration."""

    name: str = "scheduler"
    check_interval_ms: int = 1000
    max_concurrent_jobs: int = 10
    timezone: str = "UTC"


@dataclass
class ScheduledJob:
    """A scheduled job."""

    job_id: str
    name: str
    func: Callable[[], Any]
    schedule: str  # Cron expression or interval
    enabled: bool = True
    last_run: Optional[datetime] = None
    next_run: Optional[datetime] = None
    run_count: int = 0
    max_runs: Optional[int] = None
    timeout_seconds: int = 300
    queue_name: Optional[str] = None


class Scheduler:
    """Cron-like job scheduler.

    Features:
    - Cron expression scheduling
    - Interval-based scheduling
    - Job lifecycle management
    - Concurrent execution limits
    - Integration with message queues
    """

    def __init__(
        self,
        config: Optional[SchedulerConfig] = None,
        broker: Optional[Broker] = None,
    ):
        self.config = config or SchedulerConfig()
        self.broker = broker

        self._jobs: Dict[str, ScheduledJob] = {}
        self._running_jobs: Dict[str, threading.Thread] = {}
        self._lock = threading.RLock()
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

    def add_job(
        self,
        func: Callable[[], Any],
        schedule: str,
        name: Optional[str] = None,
        job_id: Optional[str] = None,
        queue_name: Optional[str] = None,
        max_runs: Optional[int] = None,
        timeout: int = 300,
    ) -> str:
        """Add a scheduled job.

        Args:
            func: Job function
            schedule: Cron expression or interval (e.g., "every 5m")
            name: Job name
            job_id: Job identifier
            queue_name: Queue to publish to instead of direct execution
            max_runs: Maximum executions
            timeout: Execution timeout

        Returns:
            Job ID
        """
        job_id = job_id or str(uuid.uuid4())
        name = name or f"job-{job_id[:8]}"

        job = ScheduledJob(
            job_id=job_id,
            name=name,
            func=func,
            schedule=schedule,
            queue_name=queue_name,
            max_runs=max_runs,
            timeout_seconds=timeout,
        )

        # Calculate first run
        job.next_run = self._calculate_next_run(schedule)

        with self._lock:
            self._jobs[job_id] = job

        logger.info(f"Added job {name} ({job_id}), next run: {job.next_run}")
        return job_id

    def remove_job(self, job_id: str) -> bool:
        """Remove a job."""
        with self._lock:
            if job_id in self._jobs:
                del self._jobs[job_id]
                logger.info(f"Removed job {job_id}")
                return True
        return False

    def enable_job(self, job_id: str) -> bool:
        """Enable a job."""
        with self._lock:
            if job_id in self._jobs:
                self._jobs[job_id].enabled = True
                return True
        return False

    def disable_job(self, job_id: str) -> bool:
        """Disable a job."""
        with self._lock:
            if job_id in self._jobs:
                self._jobs[job_id].enabled = False
                return True
        return False

    def _calculate_next_run(
        self,
        schedule: str,
        from_time: Optional[datetime] = None,
    ) -> datetime:
        """Calculate next run time from schedule."""
        from_time = from_time or datetime.now()

        # Parse interval syntax: "every Nm" or "every Nh" or "every Ns"
        if schedule.startswith("every "):
            interval_str = schedule[6:].strip()
            unit = interval_str[-1].lower()
            value = int(interval_str[:-1])

            if unit == "s":
                delta = timedelta(seconds=value)
            elif unit == "m":
                delta = timedelta(minutes=value)
            elif unit == "h":
                delta = timedelta(hours=value)
            elif unit == "d":
                delta = timedelta(days=value)
            else:
                delta = timedelta(minutes=value)

            return from_time + delta

        # For cron expressions, use CronParser
        from roadqueue_core.scheduler.cron import CronParser
        parser = CronParser(schedule)
        return parser.next_run(from_time)

    def start(self) -> None:
        """Start the scheduler."""
        if self._running:
            return

        self._running = True
        self._stop_event.clear()

        self._thread = threading.Thread(
            target=self._scheduler_loop,
            daemon=True,
            name=f"Scheduler-{self.config.name}",
        )
        self._thread.start()
        logger.info(f"Scheduler {self.config.name} started")

    def stop(self, wait: bool = True) -> None:
        """Stop the scheduler."""
        self._running = False
        self._stop_event.set()

        if wait and self._thread:
            self._thread.join(timeout=5.0)

        # Wait for running jobs
        if wait:
            for thread in list(self._running_jobs.values()):
                thread.join(timeout=5.0)

        logger.info(f"Scheduler {self.config.name} stopped")

    def _scheduler_loop(self) -> None:
        """Main scheduler loop."""
        while self._running and not self._stop_event.is_set():
            try:
                self._check_jobs()
            except Exception as e:
                logger.error(f"Scheduler error: {e}")

            time.sleep(self.config.check_interval_ms / 1000)

    def _check_jobs(self) -> None:
        """Check and execute due jobs."""
        now = datetime.now()

        with self._lock:
            for job in list(self._jobs.values()):
                if not job.enabled:
                    continue

                if job.max_runs and job.run_count >= job.max_runs:
                    job.enabled = False
                    continue

                if job.next_run and now >= job.next_run:
                    if len(self._running_jobs) < self.config.max_concurrent_jobs:
                        self._execute_job(job)

    def _execute_job(self, job: ScheduledJob) -> None:
        """Execute a job."""
        def run():
            try:
                logger.debug(f"Executing job {job.name}")

                if job.queue_name and self.broker:
                    # Publish to queue
                    message = Message.create(
                        body={"job_id": job.job_id, "name": job.name},
                        queue_name=job.queue_name,
                    )
                    self.broker.publish_to_queue(message, job.queue_name)
                else:
                    # Direct execution
                    job.func()

                job.run_count += 1
                job.last_run = datetime.now()

                logger.info(f"Job {job.name} completed (run #{job.run_count})")

            except Exception as e:
                logger.error(f"Job {job.name} failed: {e}")

            finally:
                with self._lock:
                    self._running_jobs.pop(job.job_id, None)

        # Calculate next run before starting
        job.next_run = self._calculate_next_run(job.schedule, datetime.now())

        thread = threading.Thread(target=run, daemon=True, name=f"Job-{job.name}")
        self._running_jobs[job.job_id] = thread
        thread.start()

    def run_now(self, job_id: str) -> bool:
        """Trigger immediate job execution."""
        with self._lock:
            job = self._jobs.get(job_id)
            if job and len(self._running_jobs) < self.config.max_concurrent_jobs:
                self._execute_job(job)
                return True
        return False

    def get_jobs(self) -> List[ScheduledJob]:
        """Get all jobs."""
        with self._lock:
            return list(self._jobs.values())

    def get_job(self, job_id: str) -> Optional[ScheduledJob]:
        """Get a job by ID."""
        return self._jobs.get(job_id)

    def get_stats(self) -> Dict[str, Any]:
        """Get scheduler statistics."""
        with self._lock:
            return {
                "running": self._running,
                "total_jobs": len(self._jobs),
                "enabled_jobs": sum(1 for j in self._jobs.values() if j.enabled),
                "running_jobs": len(self._running_jobs),
            }

    def __enter__(self) -> "Scheduler":
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        self.stop()


# Convenience decorators
def scheduled(schedule: str, name: Optional[str] = None):
    """Decorator to mark function as scheduled."""
    def decorator(func: Callable) -> Callable:
        func._schedule = schedule
        func._schedule_name = name
        return func
    return decorator


__all__ = ["Scheduler", "SchedulerConfig", "ScheduledJob", "scheduled"]
