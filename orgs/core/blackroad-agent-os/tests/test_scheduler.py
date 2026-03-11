"""
Tests for controller/core/scheduler.py (task lifecycle).
"""
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from core.scheduler import TaskScheduler
from models.task import Command, RiskLevel, Task, TaskPlan, TaskRequest, TaskStatus


@pytest.fixture
def scheduler():
    return TaskScheduler()


class TestCreateTask:
    async def test_creates_task_with_id(self, scheduler):
        request = TaskRequest(request="run tests")
        task = await scheduler.create_task(request)
        assert task.id is not None
        assert len(task.id) == 8
        assert task.status == TaskStatus.PENDING
        assert task.request == "run tests"

    async def test_creates_task_with_priority(self, scheduler):
        request = TaskRequest(request="urgent fix", priority=9)
        task = await scheduler.create_task(request)
        assert task.priority == 9

    async def test_creates_task_with_target(self, scheduler):
        request = TaskRequest(request="deploy", target_agent_id="pi-1")
        task = await scheduler.create_task(request)
        assert task.target_agent_id == "pi-1"

    async def test_task_stored(self, scheduler):
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        assert scheduler.get_task(task.id) is task

    async def test_requires_approval_by_default(self, scheduler):
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        assert task.requires_approval is True

    async def test_skip_approval(self, scheduler):
        request = TaskRequest(request="test", skip_approval=True)
        task = await scheduler.create_task(request)
        assert task.requires_approval is False


class TestSetPlan:
    async def test_attaches_plan(self, scheduler):
        request = TaskRequest(request="test", skip_approval=True)
        task = await scheduler.create_task(request)

        plan = TaskPlan(
            commands=[Command(run="ls -la")],
            steps=["List files"],
        )

        with patch("core.scheduler.safety") as mock_safety:
            mock_safety.validate_commands.return_value = (True, [])
            mock_safety.should_require_approval.return_value = False
            updated = await scheduler.set_plan(task.id, plan)

        assert updated.plan is plan
        assert updated.planned_at is not None
        assert updated.status == TaskStatus.QUEUED

    async def test_blocked_command_fails_task(self, scheduler):
        request = TaskRequest(request="destroy", skip_approval=True)
        task = await scheduler.create_task(request)

        plan = TaskPlan(commands=[Command(run="rm -rf /")])

        blocked_result = MagicMock()
        blocked_result.blocked = True
        blocked_result.reason = "Blocked"

        with patch("core.scheduler.safety") as mock_safety:
            mock_safety.validate_commands.return_value = (False, [blocked_result])
            updated = await scheduler.set_plan(task.id, plan)

        assert updated.status == TaskStatus.FAILED
        assert "Blocked" in updated.error

    async def test_plan_requires_approval(self, scheduler):
        request = TaskRequest(request="install stuff")
        task = await scheduler.create_task(request)

        plan = TaskPlan(commands=[Command(run="apt install vim")])

        with patch("core.scheduler.safety") as mock_safety:
            mock_safety.validate_commands.return_value = (True, [])
            mock_safety.should_require_approval.return_value = True
            updated = await scheduler.set_plan(task.id, plan)

        assert updated.status == TaskStatus.AWAITING_APPROVAL

    async def test_unknown_task_raises(self, scheduler):
        plan = TaskPlan(commands=[])
        with pytest.raises(ValueError, match="not found"):
            await scheduler.set_plan("nonexistent", plan)


class TestApproveTask:
    async def test_approve(self, scheduler):
        request = TaskRequest(request="deploy")
        task = await scheduler.create_task(request)

        plan = TaskPlan(commands=[Command(run="apt install vim")])
        with patch("core.scheduler.safety") as mock_safety:
            mock_safety.validate_commands.return_value = (True, [])
            mock_safety.should_require_approval.return_value = True
            await scheduler.set_plan(task.id, plan)

        approved = await scheduler.approve_task(task.id, approved=True)
        assert approved.status == TaskStatus.QUEUED
        assert approved.approved_at is not None

    async def test_reject(self, scheduler):
        request = TaskRequest(request="deploy")
        task = await scheduler.create_task(request)

        plan = TaskPlan(commands=[Command(run="reboot")])
        with patch("core.scheduler.safety") as mock_safety:
            mock_safety.validate_commands.return_value = (True, [])
            mock_safety.should_require_approval.return_value = True
            await scheduler.set_plan(task.id, plan)

        rejected = await scheduler.approve_task(task.id, approved=False, reason="Not now")
        assert rejected.status == TaskStatus.CANCELLED
        assert rejected.error == "Not now"

    async def test_approve_wrong_status_raises(self, scheduler):
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        with pytest.raises(ValueError, match="not awaiting approval"):
            await scheduler.approve_task(task.id, approved=True)


class TestCompleteTask:
    async def test_complete_success(self, scheduler):
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        completed = await scheduler.complete_task(task.id, success=True, exit_code=0, output="ok")
        assert completed.status == TaskStatus.COMPLETED
        assert completed.exit_code == 0
        assert completed.output == "ok"
        assert completed.completed_at is not None

    async def test_complete_failure(self, scheduler):
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        completed = await scheduler.complete_task(
            task.id, success=False, exit_code=1, error="segfault"
        )
        assert completed.status == TaskStatus.FAILED
        assert completed.exit_code == 1
        assert completed.error == "segfault"


class TestCancelTask:
    async def test_cancel(self, scheduler):
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        cancelled = await scheduler.cancel_task(task.id, reason="changed mind")
        assert cancelled.status == TaskStatus.CANCELLED
        assert cancelled.error == "changed mind"

    async def test_cancel_completed_raises(self, scheduler):
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        await scheduler.complete_task(task.id, success=True)
        with pytest.raises(ValueError, match="already finished"):
            await scheduler.cancel_task(task.id)


class TestGetters:
    async def test_get_all_tasks(self, scheduler):
        await scheduler.create_task(TaskRequest(request="a"))
        await scheduler.create_task(TaskRequest(request="b"))
        assert len(scheduler.get_all_tasks()) == 2

    async def test_get_task_none(self, scheduler):
        assert scheduler.get_task("nonexistent") is None

    async def test_get_running_tasks(self, scheduler):
        assert scheduler.get_running_tasks() == []


class TestListeners:
    async def test_listener_called(self, scheduler):
        listener = AsyncMock()
        scheduler.add_listener(listener)
        request = TaskRequest(request="test")
        task = await scheduler.create_task(request)
        listener.assert_called_once_with(task)
