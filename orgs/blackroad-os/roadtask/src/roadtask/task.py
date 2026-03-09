"""
RoadTask - Task Management for BlackRoad
Create and manage background tasks with workers.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import asyncio
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class TaskStatus(str, Enum):
    PENDING = "pending"
    QUEUED = "queued"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    RETRYING = "retrying"


class TaskPriority(int, Enum):
    LOW = 1
    NORMAL = 5
    HIGH = 10
    URGENT = 20


@dataclass
class TaskResult:
    success: bool
    data: Any = None
    error: Optional[str] = None
    duration_ms: float = 0


@dataclass
class Task:
    id: str
    name: str
    fn: Callable
    args: tuple = field(default_factory=tuple)
    kwargs: Dict[str, Any] = field(default_factory=dict)
    status: TaskStatus = TaskStatus.PENDING
    priority: TaskPriority = TaskPriority.NORMAL
    max_retries: int = 3
    retry_count: int = 0
    timeout: int = 300
    result: Optional[TaskResult] = None
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    scheduled_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class TaskQueue:
    def __init__(self, max_size: int = 10000):
        self.max_size = max_size
        self.tasks: List[Task] = []
        self._lock = threading.Lock()

    def push(self, task: Task) -> None:
        with self._lock:
            if len(self.tasks) >= self.max_size:
                raise RuntimeError("Queue full")
            task.status = TaskStatus.QUEUED
            self.tasks.append(task)
            self.tasks.sort(key=lambda t: (-t.priority.value, t.created_at))

    def pop(self) -> Optional[Task]:
        with self._lock:
            now = datetime.now()
            for i, task in enumerate(self.tasks):
                if task.status == TaskStatus.QUEUED:
                    if task.scheduled_at is None or task.scheduled_at <= now:
                        task.status = TaskStatus.RUNNING
                        return self.tasks.pop(i)
            return None

    def peek(self) -> Optional[Task]:
        with self._lock:
            for task in self.tasks:
                if task.status == TaskStatus.QUEUED:
                    return task
            return None

    def size(self) -> int:
        return len([t for t in self.tasks if t.status == TaskStatus.QUEUED])

    def cancel(self, task_id: str) -> bool:
        with self._lock:
            for task in self.tasks:
                if task.id == task_id and task.status == TaskStatus.QUEUED:
                    task.status = TaskStatus.CANCELLED
                    return True
            return False


class Worker:
    def __init__(self, worker_id: str, queue: TaskQueue):
        self.id = worker_id
        self.queue = queue
        self.current_task: Optional[Task] = None
        self._running = False
        self.tasks_completed = 0
        self.tasks_failed = 0

    async def process_task(self, task: Task) -> TaskResult:
        start = time.time()
        task.started_at = datetime.now()
        
        try:
            result = task.fn(*task.args, **task.kwargs)
            if asyncio.iscoroutine(result):
                result = await asyncio.wait_for(result, timeout=task.timeout)
            
            duration = (time.time() - start) * 1000
            return TaskResult(success=True, data=result, duration_ms=duration)
        except asyncio.TimeoutError:
            duration = (time.time() - start) * 1000
            return TaskResult(success=False, error="Task timeout", duration_ms=duration)
        except Exception as e:
            duration = (time.time() - start) * 1000
            logger.error(f"Task {task.id} failed: {e}")
            return TaskResult(success=False, error=str(e), duration_ms=duration)

    async def run(self) -> None:
        self._running = True
        logger.info(f"Worker {self.id} started")
        
        while self._running:
            task = self.queue.pop()
            if task:
                self.current_task = task
                result = await self.process_task(task)
                task.result = result
                task.completed_at = datetime.now()
                
                if result.success:
                    task.status = TaskStatus.COMPLETED
                    self.tasks_completed += 1
                elif task.retry_count < task.max_retries:
                    task.retry_count += 1
                    task.status = TaskStatus.RETRYING
                    self.queue.push(task)
                else:
                    task.status = TaskStatus.FAILED
                    self.tasks_failed += 1
                
                self.current_task = None
            else:
                await asyncio.sleep(0.1)

    def stop(self) -> None:
        self._running = False
        logger.info(f"Worker {self.id} stopped")


class TaskManager:
    def __init__(self, num_workers: int = 4):
        self.queue = TaskQueue()
        self.workers: List[Worker] = []
        self.tasks: Dict[str, Task] = {}
        self.hooks: Dict[str, List[Callable]] = {
            "task_created": [], "task_started": [],
            "task_completed": [], "task_failed": []
        }
        self._init_workers(num_workers)

    def _init_workers(self, num_workers: int) -> None:
        for i in range(num_workers):
            worker = Worker(f"worker-{i}", self.queue)
            self.workers.append(worker)

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self.hooks:
            self.hooks[event].append(handler)

    def _emit(self, event: str, data: Any) -> None:
        for handler in self.hooks.get(event, []):
            try:
                handler(data)
            except Exception as e:
                logger.error(f"Hook error: {e}")

    def submit(self, fn: Callable, *args, name: str = None, priority: TaskPriority = TaskPriority.NORMAL, delay: int = 0, **kwargs) -> Task:
        task = Task(
            id=str(uuid.uuid4())[:12],
            name=name or fn.__name__,
            fn=fn,
            args=args,
            kwargs=kwargs,
            priority=priority,
            scheduled_at=datetime.now() + timedelta(seconds=delay) if delay > 0 else None
        )
        
        self.tasks[task.id] = task
        self.queue.push(task)
        self._emit("task_created", task)
        
        return task

    def get(self, task_id: str) -> Optional[Task]:
        return self.tasks.get(task_id)

    def cancel(self, task_id: str) -> bool:
        return self.queue.cancel(task_id)

    async def start(self) -> None:
        tasks = [worker.run() for worker in self.workers]
        await asyncio.gather(*tasks)

    def stop(self) -> None:
        for worker in self.workers:
            worker.stop()

    def stats(self) -> Dict[str, Any]:
        return {
            "queue_size": self.queue.size(),
            "total_tasks": len(self.tasks),
            "pending": len([t for t in self.tasks.values() if t.status == TaskStatus.PENDING]),
            "queued": len([t for t in self.tasks.values() if t.status == TaskStatus.QUEUED]),
            "running": len([t for t in self.tasks.values() if t.status == TaskStatus.RUNNING]),
            "completed": len([t for t in self.tasks.values() if t.status == TaskStatus.COMPLETED]),
            "failed": len([t for t in self.tasks.values() if t.status == TaskStatus.FAILED]),
            "workers": len(self.workers)
        }


def task(manager: TaskManager, priority: TaskPriority = TaskPriority.NORMAL, **kwargs) -> Callable:
    def decorator(fn: Callable) -> Callable:
        def wrapper(*args, **kw):
            return manager.submit(fn, *args, priority=priority, **{**kwargs, **kw})
        return wrapper
    return decorator


def example_usage():
    manager = TaskManager(num_workers=2)
    
    def process_data(data):
        time.sleep(0.1)
        return {"processed": data, "result": len(data)}
    
    def send_email(to, subject):
        time.sleep(0.05)
        return {"sent_to": to, "subject": subject}
    
    task1 = manager.submit(process_data, "Hello World", name="process_hello")
    task2 = manager.submit(send_email, "user@example.com", "Welcome!", priority=TaskPriority.HIGH)
    task3 = manager.submit(process_data, "Delayed task", delay=5)
    
    print(f"Submitted tasks: {task1.id}, {task2.id}, {task3.id}")
    print(f"Stats: {manager.stats()}")
    
    print(f"\nTask {task1.id} status: {task1.status.value}")
    print(f"Task {task2.id} status: {task2.status.value}")

