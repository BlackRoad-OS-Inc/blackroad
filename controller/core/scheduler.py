"""
Task Scheduler - Manages task queue and dispatching
"""
import asyncio
from collections import deque
from datetime import datetime
from typing import Optional, Callable, Awaitable
import uuid
import structlog

from models import Task, TaskStatus, TaskRequest, TaskPlan, RiskLevel
from core.registry import registry
from core.safety import safety

logger = structlog.get_logger()


class TaskScheduler:
    """
    Manages task lifecycle from creation to completion.
    Handles queuing, prioritization, and dispatch.
    """

    def __init__(self):
        self._tasks: dict[str, Task] = {}
        self._queue: deque[str] = deque()  # Task IDs in priority order
        self._running: dict[str, str] = {}  # agent_id -> task_id
        self._listeners: list[Callable[[Task], Awaitable[None]]] = []
        self._lock = asyncio.Lock()

    def add_listener(self, callback: Callable[[Task], Awaitable[None]]):
        """Add a callback for task state changes"""
        self._listeners.append(callback)

    async def _notify_listeners(self, task: Task):
        """Notify all listeners of a task update"""
        for listener in self._listeners:
            try:
                await listener(task)
            except Exception as e:
                logger.error("listener_error", error=str(e))

    async def create_task(self, request: TaskRequest) -> Task:
        """Create a new task from a request"""
        task_id = str(uuid.uuid4())[:8]

        task = Task(
            id=task_id,
            status=TaskStatus.PENDING,
            request=request.request,
            target_agent_id=request.target_agent_id,
            target_role=request.target_role,
            requires_approval=not request.skip_approval,
            priority=request.priority,
        )

        async with self._lock:
            self._tasks[task_id] = task

        logger.info("task_created", task_id=task_id, request=request.request[:100])
        await self._notify_listeners(task)
        return task

    async def set_plan(self, task_id: str, plan: TaskPlan) -> Task:
        """Attach an LLM-generated plan to a task"""
        async with self._lock:
            if task_id not in self._tasks:
                raise ValueError(f"Task {task_id} not found")

            task = self._tasks[task_id]
            task.plan = plan
            task.planned_at = datetime.utcnow()

            # Validate commands through safety layer
            all_valid, results = safety.validate_commands(plan.commands)

            if not all_valid:
                # Some commands blocked
                blocked = [r for r in results if r.blocked]
                task.status = TaskStatus.FAILED
                task.error = f"Blocked commands: {[r.reason for r in blocked]}"
                logger.warning("task_blocked", task_id=task_id, blocked=len(blocked))
            elif task.requires_approval or safety.should_require_approval(plan.commands):
                task.status = TaskStatus.AWAITING_APPROVAL
                task.requires_approval = True
            else:
                task.status = TaskStatus.QUEUED
                self._enqueue(task)

        await self._notify_listeners(task)
        return task

    def _enqueue(self, task: Task):
        """Add task to queue in priority order"""
        # Simple priority queue - higher priority = earlier in queue
        insert_idx = 0
        for i, queued_id in enumerate(self._queue):
            queued_task = self._tasks.get(queued_id)
            if queued_task and queued_task.priority < task.priority:
                insert_idx = i
                break
            insert_idx = i + 1
        self._queue.insert(insert_idx, task.id)
        logger.info("task_queued", task_id=task.id, position=insert_idx)

    async def approve_task(self, task_id: str, approved: bool, reason: Optional[str] = None) -> Task:
        """Approve or reject a task"""
        async with self._lock:
            if task_id not in self._tasks:
                raise ValueError(f"Task {task_id} not found")

            task = self._tasks[task_id]

            if task.status != TaskStatus.AWAITING_APPROVAL:
                raise ValueError(f"Task {task_id} is not awaiting approval")

            if approved:
                task.status = TaskStatus.QUEUED
                task.approved_at = datetime.utcnow()
                self._enqueue(task)
                logger.info("task_approved", task_id=task_id)
            else:
                task.status = TaskStatus.CANCELLED
                task.error = reason or "Rejected by user"
                logger.info("task_rejected", task_id=task_id, reason=reason)

        await self._notify_listeners(task)
        return task

    async def dispatch_next(self) -> Optional[Task]:
        """Try to dispatch the next queued task to an available agent"""
        async with self._lock:
            if not self._queue:
                return None

            # Find available agent
            for task_id in list(self._queue):
                task = self._tasks.get(task_id)
                if not task or not task.plan:
                    continue

                # Find matching agent
                target_agent_id = task.plan.target_agent or task.target_agent_id
                if target_agent_id:
                    agent = registry.get(target_agent_id)
                    if agent and agent.is_available:
                        return await self._dispatch(task, target_agent_id)
                else:
                    # Find any available agent matching criteria
                    available = registry.get_available()
                    if task.target_role:
                        available = [a for a in available if task.target_role in a.roles]
                    if available:
                        return await self._dispatch(task, available[0].id)

            return None

    async def _dispatch(self, task: Task, agent_id: str) -> Task:
        """Dispatch a task to a specific agent"""
        self._queue.remove(task.id)
        task.status = TaskStatus.RUNNING
        task.assigned_agent_id = agent_id
        task.started_at = datetime.utcnow()
        self._running[agent_id] = task.id

        logger.info("task_dispatched", task_id=task.id, agent_id=agent_id)
        await self._notify_listeners(task)
        return task

    async def complete_task(
        self,
        task_id: str,
        success: bool,
        exit_code: int = 0,
        output: Optional[str] = None,
        error: Optional[str] = None,
    ) -> Task:
        """Mark a task as completed"""
        async with self._lock:
            if task_id not in self._tasks:
                raise ValueError(f"Task {task_id} not found")

            task = self._tasks[task_id]
            task.status = TaskStatus.COMPLETED if success else TaskStatus.FAILED
            task.exit_code = exit_code
            task.output = output
            task.error = error
            task.completed_at = datetime.utcnow()

            # Free up the agent
            if task.assigned_agent_id and task.assigned_agent_id in self._running:
                del self._running[task.assigned_agent_id]

            logger.info(
                "task_completed",
                task_id=task_id,
                success=success,
                exit_code=exit_code,
            )

        await self._notify_listeners(task)
        return task

    async def cancel_task(self, task_id: str, reason: Optional[str] = None) -> Task:
        """Cancel a task"""
        async with self._lock:
            if task_id not in self._tasks:
                raise ValueError(f"Task {task_id} not found")

            task = self._tasks[task_id]

            if task.status in (TaskStatus.COMPLETED, TaskStatus.FAILED):
                raise ValueError(f"Task {task_id} already finished")

            # Remove from queue if queued
            if task.id in self._queue:
                self._queue.remove(task.id)

            task.status = TaskStatus.CANCELLED
            task.error = reason or "Cancelled by user"
            task.completed_at = datetime.utcnow()

            # Free up the agent if running
            if task.assigned_agent_id and task.assigned_agent_id in self._running:
                del self._running[task.assigned_agent_id]

            logger.info("task_cancelled", task_id=task_id, reason=reason)

        await self._notify_listeners(task)
        return task

    def get_task(self, task_id: str) -> Optional[Task]:
        """Get a task by ID"""
        return self._tasks.get(task_id)

    def get_all_tasks(self) -> list[Task]:
        """Get all tasks"""
        return list(self._tasks.values())

    def get_queued_tasks(self) -> list[Task]:
        """Get all queued tasks"""
        return [self._tasks[tid] for tid in self._queue if tid in self._tasks]

    def get_running_tasks(self) -> list[Task]:
        """Get all running tasks"""
        return [
            self._tasks[tid]
            for tid in self._running.values()
            if tid in self._tasks
        ]

    def get_agent_task(self, agent_id: str) -> Optional[Task]:
        """Get the task currently running on an agent"""
        task_id = self._running.get(agent_id)
        return self._tasks.get(task_id) if task_id else None


# Global scheduler instance
scheduler = TaskScheduler()
