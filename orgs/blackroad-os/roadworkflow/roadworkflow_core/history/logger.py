"""Workflow Logger - Execution logging.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import json
import logging
import os
import threading
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class LogLevel(Enum):
    """Log levels."""

    DEBUG = "debug"
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


@dataclass
class LogEntry:
    """A log entry."""

    timestamp: datetime
    level: LogLevel
    message: str
    workflow_id: str
    run_id: str
    task_id: Optional[str] = None
    extra: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "timestamp": self.timestamp.isoformat(),
            "level": self.level.value,
            "message": self.message,
            "workflow_id": self.workflow_id,
            "run_id": self.run_id,
            "task_id": self.task_id,
            "extra": self.extra,
        }

    def to_json(self) -> str:
        """Convert to JSON string."""
        return json.dumps(self.to_dict(), default=str)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "LogEntry":
        """Create from dictionary."""
        return cls(
            timestamp=datetime.fromisoformat(data["timestamp"]),
            level=LogLevel(data["level"]),
            message=data["message"],
            workflow_id=data["workflow_id"],
            run_id=data["run_id"],
            task_id=data.get("task_id"),
            extra=data.get("extra", {}),
        )


class WorkflowLogger:
    """Workflow execution logger.

    Features:
    - Structured logging
    - Multiple outputs (file, database, remote)
    - Log rotation
    - Query capabilities
    """

    def __init__(
        self,
        log_dir: str = ".workflow_logs",
        max_entries: int = 10000,
        rotate_size_mb: float = 100.0,
    ):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self.max_entries = max_entries
        self.rotate_size_mb = rotate_size_mb

        self._entries: List[LogEntry] = []
        self._lock = threading.RLock()
        self._handlers: List[logging.Handler] = []

    def log(
        self,
        level: LogLevel,
        message: str,
        workflow_id: str,
        run_id: str,
        task_id: Optional[str] = None,
        **extra,
    ) -> LogEntry:
        """Log an entry.

        Args:
            level: Log level
            message: Log message
            workflow_id: Workflow identifier
            run_id: Run identifier
            task_id: Task identifier (optional)
            **extra: Additional fields

        Returns:
            Created log entry
        """
        entry = LogEntry(
            timestamp=datetime.utcnow(),
            level=level,
            message=message,
            workflow_id=workflow_id,
            run_id=run_id,
            task_id=task_id,
            extra=extra,
        )

        with self._lock:
            self._entries.append(entry)

            if len(self._entries) > self.max_entries:
                self._entries = self._entries[-self.max_entries:]

        self._write_to_file(entry)
        return entry

    def debug(self, message: str, **kwargs) -> LogEntry:
        """Log debug message."""
        return self.log(LogLevel.DEBUG, message, **kwargs)

    def info(self, message: str, **kwargs) -> LogEntry:
        """Log info message."""
        return self.log(LogLevel.INFO, message, **kwargs)

    def warning(self, message: str, **kwargs) -> LogEntry:
        """Log warning message."""
        return self.log(LogLevel.WARNING, message, **kwargs)

    def error(self, message: str, **kwargs) -> LogEntry:
        """Log error message."""
        return self.log(LogLevel.ERROR, message, **kwargs)

    def critical(self, message: str, **kwargs) -> LogEntry:
        """Log critical message."""
        return self.log(LogLevel.CRITICAL, message, **kwargs)

    def get_logs(
        self,
        workflow_id: Optional[str] = None,
        run_id: Optional[str] = None,
        task_id: Optional[str] = None,
        level: Optional[LogLevel] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        limit: int = 100,
    ) -> List[LogEntry]:
        """Query logs.

        Args:
            workflow_id: Filter by workflow
            run_id: Filter by run
            task_id: Filter by task
            level: Filter by level
            start_time: Start of time range
            end_time: End of time range
            limit: Maximum entries to return

        Returns:
            Matching log entries
        """
        with self._lock:
            results = self._entries.copy()

        if workflow_id:
            results = [e for e in results if e.workflow_id == workflow_id]
        if run_id:
            results = [e for e in results if e.run_id == run_id]
        if task_id:
            results = [e for e in results if e.task_id == task_id]
        if level:
            results = [e for e in results if e.level == level]
        if start_time:
            results = [e for e in results if e.timestamp >= start_time]
        if end_time:
            results = [e for e in results if e.timestamp <= end_time]

        return results[-limit:]

    def _write_to_file(self, entry: LogEntry) -> None:
        """Write entry to log file."""
        log_file = self.log_dir / f"{entry.workflow_id}.log"

        try:
            if log_file.exists():
                size_mb = log_file.stat().st_size / (1024 * 1024)
                if size_mb >= self.rotate_size_mb:
                    self._rotate_file(log_file)

            with open(log_file, "a") as f:
                f.write(entry.to_json() + "\n")

        except Exception as e:
            logger.error(f"Failed to write log: {e}")

    def _rotate_file(self, log_file: Path) -> None:
        """Rotate log file."""
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        rotated = log_file.with_suffix(f".{timestamp}.log")
        log_file.rename(rotated)

    def load_logs(self, workflow_id: str) -> List[LogEntry]:
        """Load logs from file."""
        log_file = self.log_dir / f"{workflow_id}.log"
        entries = []

        if not log_file.exists():
            return entries

        try:
            with open(log_file) as f:
                for line in f:
                    try:
                        data = json.loads(line.strip())
                        entries.append(LogEntry.from_dict(data))
                    except (json.JSONDecodeError, KeyError):
                        continue
        except Exception as e:
            logger.error(f"Failed to load logs: {e}")

        return entries


class TaskLogger:
    """Task-specific logger."""

    def __init__(
        self,
        parent: WorkflowLogger,
        workflow_id: str,
        run_id: str,
        task_id: str,
    ):
        self.parent = parent
        self.workflow_id = workflow_id
        self.run_id = run_id
        self.task_id = task_id

    def debug(self, message: str, **extra) -> LogEntry:
        """Log debug message."""
        return self.parent.log(
            LogLevel.DEBUG,
            message,
            workflow_id=self.workflow_id,
            run_id=self.run_id,
            task_id=self.task_id,
            **extra,
        )

    def info(self, message: str, **extra) -> LogEntry:
        """Log info message."""
        return self.parent.log(
            LogLevel.INFO,
            message,
            workflow_id=self.workflow_id,
            run_id=self.run_id,
            task_id=self.task_id,
            **extra,
        )

    def warning(self, message: str, **extra) -> LogEntry:
        """Log warning message."""
        return self.parent.log(
            LogLevel.WARNING,
            message,
            workflow_id=self.workflow_id,
            run_id=self.run_id,
            task_id=self.task_id,
            **extra,
        )

    def error(self, message: str, **extra) -> LogEntry:
        """Log error message."""
        return self.parent.log(
            LogLevel.ERROR,
            message,
            workflow_id=self.workflow_id,
            run_id=self.run_id,
            task_id=self.task_id,
            **extra,
        )


__all__ = [
    "WorkflowLogger",
    "TaskLogger",
    "LogEntry",
    "LogLevel",
]
