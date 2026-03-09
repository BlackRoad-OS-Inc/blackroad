"""Scheduler tests."""

import pytest
import time
from datetime import datetime, timedelta
from roadworkflow_core.scheduler.scheduler import (
    Scheduler,
    SchedulerConfig,
    SchedulerState,
    ScheduleType,
    WorkflowSchedule,
)
from roadworkflow_core.scheduler.executor import (
    LocalExecutor,
    ThreadPoolExecutor,
    ExecutorConfig,
)


class TestScheduler:
    """Scheduler tests."""

    def test_create_scheduler(self):
        scheduler = Scheduler()
        assert scheduler.state == SchedulerState.STOPPED

    def test_register_workflow(self):
        scheduler = Scheduler()
        
        schedule = scheduler.register_workflow(
            workflow_id="test_workflow",
            schedule_type=ScheduleType.INTERVAL,
            schedule_interval=timedelta(hours=1),
        )
        
        assert schedule.workflow_id == "test_workflow"
        assert schedule.schedule_type == ScheduleType.INTERVAL

    def test_trigger_workflow(self):
        scheduler = Scheduler()
        
        scheduler.register_workflow(
            workflow_id="test_workflow",
            schedule_type=ScheduleType.MANUAL,
        )
        
        run = scheduler.trigger("test_workflow")
        assert run is not None
        assert run.workflow_id == "test_workflow"

    def test_pause_resume(self):
        scheduler = Scheduler()
        
        scheduler.register_workflow(
            workflow_id="test_workflow",
            schedule_type=ScheduleType.MANUAL,
        )
        
        scheduler.pause_workflow("test_workflow")
        assert scheduler._workflows["test_workflow"].is_paused
        
        scheduler.resume_workflow("test_workflow")
        assert not scheduler._workflows["test_workflow"].is_paused


class TestExecutor:
    """Executor tests."""

    def test_local_executor(self):
        executor = LocalExecutor()
        executor.start()
        
        def task_func():
            return "result"
        
        exec_id = executor.submit("task1", task_func)
        result = executor.get_result(exec_id, timeout=5)
        
        assert result == "result"
        executor.stop()

    def test_thread_pool_executor(self):
        executor = ThreadPoolExecutor()
        executor.start()
        
        def task_func():
            return 42
        
        exec_id = executor.submit("task1", task_func)
        result = executor.get_result(exec_id, timeout=5)
        
        assert result == 42
        executor.stop()
