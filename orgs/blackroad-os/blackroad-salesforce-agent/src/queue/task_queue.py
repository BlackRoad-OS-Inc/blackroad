"""
Task Queue for Autonomous Salesforce Operations

Enables 500+ agents on Octavia to process tasks from a shared queue.
Supports SQLite (local) or Redis (distributed) backends.
"""

import json
import time
import uuid
import sqlite3
from abc import ABC, abstractmethod
from enum import Enum
from dataclasses import dataclass, asdict, field
from typing import Any, Dict, List, Optional, Callable
from datetime import datetime
from pathlib import Path
import structlog

logger = structlog.get_logger()


class TaskStatus(Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    RETRYING = "retrying"


class TaskPriority(Enum):
    LOW = 0
    NORMAL = 1
    HIGH = 2
    URGENT = 3


@dataclass
class Task:
    """A task in the queue"""
    id: str
    operation: str  # create, update, delete, query, bulk_insert, etc.
    sobject: str
    data: Dict[str, Any]
    status: TaskStatus = TaskStatus.PENDING
    priority: TaskPriority = TaskPriority.NORMAL
    created_at: float = field(default_factory=time.time)
    started_at: Optional[float] = None
    completed_at: Optional[float] = None
    result: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    retry_count: int = 0
    max_retries: int = 3
    agent_id: Optional[str] = None

    def to_dict(self) -> dict:
        d = asdict(self)
        d['status'] = self.status.value
        d['priority'] = self.priority.value
        return d

    @classmethod
    def from_dict(cls, d: dict) -> 'Task':
        d['status'] = TaskStatus(d['status'])
        d['priority'] = TaskPriority(d['priority'])
        return cls(**d)


class TaskQueueBackend(ABC):
    """Abstract base for queue backends"""

    @abstractmethod
    def push(self, task: Task) -> None:
        pass

    @abstractmethod
    def pop(self, agent_id: str) -> Optional[Task]:
        pass

    @abstractmethod
    def complete(self, task_id: str, result: Dict[str, Any]) -> None:
        pass

    @abstractmethod
    def fail(self, task_id: str, error: str) -> None:
        pass

    @abstractmethod
    def retry(self, task_id: str) -> bool:
        pass

    @abstractmethod
    def get_stats(self) -> Dict[str, int]:
        pass


class SQLiteBackend(TaskQueueBackend):
    """SQLite-based task queue for local operation"""

    def __init__(self, db_path: str = "~/.blackroad/task_queue.db"):
        self.db_path = Path(db_path).expanduser()
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self):
        """Initialize database schema"""
        conn = sqlite3.connect(str(self.db_path))
        conn.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                operation TEXT NOT NULL,
                sobject TEXT NOT NULL,
                data TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending',
                priority INTEGER NOT NULL DEFAULT 1,
                created_at REAL NOT NULL,
                started_at REAL,
                completed_at REAL,
                result TEXT,
                error TEXT,
                retry_count INTEGER NOT NULL DEFAULT 0,
                max_retries INTEGER NOT NULL DEFAULT 3,
                agent_id TEXT
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_status ON tasks(status)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_priority ON tasks(priority DESC)")
        conn.commit()
        conn.close()

    def push(self, task: Task) -> None:
        """Add task to queue"""
        conn = sqlite3.connect(str(self.db_path))
        conn.execute("""
            INSERT INTO tasks (id, operation, sobject, data, status, priority,
                             created_at, max_retries)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            task.id, task.operation, task.sobject, json.dumps(task.data),
            task.status.value, task.priority.value, task.created_at, task.max_retries
        ))
        conn.commit()
        conn.close()
        logger.debug("task_pushed", task_id=task.id, operation=task.operation)

    def pop(self, agent_id: str) -> Optional[Task]:
        """Get next task from queue"""
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row

        # Get highest priority pending task
        cursor = conn.execute("""
            SELECT * FROM tasks
            WHERE status = 'pending'
            ORDER BY priority DESC, created_at ASC
            LIMIT 1
        """)
        row = cursor.fetchone()

        if not row:
            conn.close()
            return None

        # Mark as processing
        conn.execute("""
            UPDATE tasks SET status = 'processing', started_at = ?, agent_id = ?
            WHERE id = ?
        """, (time.time(), agent_id, row['id']))
        conn.commit()

        task = Task(
            id=row['id'],
            operation=row['operation'],
            sobject=row['sobject'],
            data=json.loads(row['data']),
            status=TaskStatus.PROCESSING,
            priority=TaskPriority(row['priority']),
            created_at=row['created_at'],
            started_at=time.time(),
            retry_count=row['retry_count'],
            max_retries=row['max_retries'],
            agent_id=agent_id
        )

        conn.close()
        logger.debug("task_popped", task_id=task.id, agent_id=agent_id)
        return task

    def complete(self, task_id: str, result: Dict[str, Any]) -> None:
        """Mark task as completed"""
        conn = sqlite3.connect(str(self.db_path))
        conn.execute("""
            UPDATE tasks SET status = 'completed', completed_at = ?, result = ?
            WHERE id = ?
        """, (time.time(), json.dumps(result), task_id))
        conn.commit()
        conn.close()
        logger.info("task_completed", task_id=task_id)

    def fail(self, task_id: str, error: str) -> None:
        """Mark task as failed"""
        conn = sqlite3.connect(str(self.db_path))
        conn.execute("""
            UPDATE tasks SET status = 'failed', completed_at = ?, error = ?
            WHERE id = ?
        """, (time.time(), error, task_id))
        conn.commit()
        conn.close()
        logger.warning("task_failed", task_id=task_id, error=error)

    def retry(self, task_id: str) -> bool:
        """Retry a failed task"""
        conn = sqlite3.connect(str(self.db_path))
        conn.row_factory = sqlite3.Row

        cursor = conn.execute("SELECT retry_count, max_retries FROM tasks WHERE id = ?", (task_id,))
        row = cursor.fetchone()

        if not row or row['retry_count'] >= row['max_retries']:
            conn.close()
            return False

        conn.execute("""
            UPDATE tasks SET status = 'pending', retry_count = retry_count + 1,
                           started_at = NULL, agent_id = NULL
            WHERE id = ?
        """, (task_id,))
        conn.commit()
        conn.close()
        logger.info("task_retrying", task_id=task_id)
        return True

    def get_stats(self) -> Dict[str, int]:
        """Get queue statistics"""
        conn = sqlite3.connect(str(self.db_path))
        cursor = conn.execute("""
            SELECT status, COUNT(*) as count FROM tasks GROUP BY status
        """)

        stats = {
            "pending": 0,
            "processing": 0,
            "completed": 0,
            "failed": 0,
            "total": 0
        }

        for row in cursor:
            stats[row[0]] = row[1]
            stats["total"] += row[1]

        conn.close()
        return stats


class TaskQueue:
    """
    High-level task queue interface.

    Supports multiple backends and provides a clean API for agents.
    """

    def __init__(self, backend: str = "sqlite", **kwargs):
        if backend == "sqlite":
            self._backend = SQLiteBackend(**kwargs)
        elif backend == "redis":
            # TODO: Implement Redis backend for distributed operation
            raise NotImplementedError("Redis backend coming soon")
        else:
            raise ValueError(f"Unknown backend: {backend}")

        self._handlers: Dict[str, Callable] = {}

    def register_handler(self, operation: str, handler: Callable) -> None:
        """Register a handler for an operation type"""
        self._handlers[operation] = handler
        logger.info("handler_registered", operation=operation)

    def submit(
        self,
        operation: str,
        sobject: str,
        data: Dict[str, Any],
        priority: TaskPriority = TaskPriority.NORMAL
    ) -> str:
        """Submit a new task"""
        task = Task(
            id=str(uuid.uuid4()),
            operation=operation,
            sobject=sobject,
            data=data,
            priority=priority
        )
        self._backend.push(task)
        return task.id

    def submit_batch(
        self,
        operation: str,
        sobject: str,
        data_list: List[Dict[str, Any]],
        priority: TaskPriority = TaskPriority.NORMAL
    ) -> List[str]:
        """Submit multiple tasks"""
        task_ids = []
        for data in data_list:
            task_id = self.submit(operation, sobject, data, priority)
            task_ids.append(task_id)
        return task_ids

    def get_next(self, agent_id: str) -> Optional[Task]:
        """Get next task for processing"""
        return self._backend.pop(agent_id)

    def complete(self, task_id: str, result: Dict[str, Any]) -> None:
        """Mark task as completed"""
        self._backend.complete(task_id, result)

    def fail(self, task_id: str, error: str) -> None:
        """Mark task as failed (will retry if possible)"""
        if not self._backend.retry(task_id):
            self._backend.fail(task_id, error)

    def stats(self) -> Dict[str, int]:
        """Get queue statistics"""
        return self._backend.get_stats()
