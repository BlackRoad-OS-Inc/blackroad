"""Checkpoint Manager - Workflow state checkpointing.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import logging
import os
import pickle
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, TypeVar

logger = logging.getLogger(__name__)

T = TypeVar("T")


@dataclass
class CheckpointConfig:
    """Checkpoint configuration."""

    storage_path: str = ".checkpoints"
    max_checkpoints: int = 10
    compression: bool = True
    auto_checkpoint_interval: Optional[float] = None
    retention_days: int = 7
    serializer: str = "pickle"


@dataclass
class Checkpoint:
    """A workflow checkpoint."""

    checkpoint_id: str
    workflow_id: str
    run_id: str
    created_at: datetime
    state: Dict[str, Any]
    task_states: Dict[str, str]
    xcom: Dict[str, Any]
    params: Dict[str, Any]
    metadata: Dict[str, Any] = field(default_factory=dict)
    checksum: str = ""

    def __post_init__(self):
        if not self.checksum:
            self.checksum = self._compute_checksum()

    def _compute_checksum(self) -> str:
        """Compute checkpoint checksum."""
        data = {
            "checkpoint_id": self.checkpoint_id,
            "workflow_id": self.workflow_id,
            "run_id": self.run_id,
            "state": str(self.state),
            "task_states": str(self.task_states),
        }
        content = json.dumps(data, sort_keys=True)
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    def validate(self) -> bool:
        """Validate checkpoint integrity."""
        return self.checksum == self._compute_checksum()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "checkpoint_id": self.checkpoint_id,
            "workflow_id": self.workflow_id,
            "run_id": self.run_id,
            "created_at": self.created_at.isoformat(),
            "state": self.state,
            "task_states": self.task_states,
            "xcom": self.xcom,
            "params": self.params,
            "metadata": self.metadata,
            "checksum": self.checksum,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Checkpoint":
        """Create from dictionary."""
        return cls(
            checkpoint_id=data["checkpoint_id"],
            workflow_id=data["workflow_id"],
            run_id=data["run_id"],
            created_at=datetime.fromisoformat(data["created_at"]),
            state=data["state"],
            task_states=data["task_states"],
            xcom=data.get("xcom", {}),
            params=data.get("params", {}),
            metadata=data.get("metadata", {}),
            checksum=data.get("checksum", ""),
        )


class CheckpointManager:
    """Checkpoint Manager for workflow state persistence.

    Features:
    - Automatic checkpointing at intervals
    - Multiple checkpoint retention
    - Compression support
    - Checkpoint validation
    - Recovery from failures

    Architecture:
    ┌─────────────────────────────────────────────────────────────────────┐
    │                      CheckpointManager                               │
    ├─────────────────────────────────────────────────────────────────────┤
    │  ┌───────────────┐  ┌────────────────┐  ┌──────────────────────┐   │
    │  │   Create      │  │    Store       │  │      Restore         │   │
    │  │               │  │                │  │                      │   │
    │  │ - capture     │  │ - serialize    │  │ - load               │   │
    │  │ - validate    │  │ - compress     │  │ - validate           │   │
    │  │ - checksum    │  │ - persist      │  │ - deserialize        │   │
    │  └───────────────┘  └────────────────┘  └──────────────────────┘   │
    ├─────────────────────────────────────────────────────────────────────┤
    │  Storage: File / S3 / Redis / Custom                                │
    └─────────────────────────────────────────────────────────────────────┘
    """

    def __init__(self, config: Optional[CheckpointConfig] = None):
        self.config = config or CheckpointConfig()
        self._storage_path = Path(self.config.storage_path)
        self._storage_path.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()
        self._auto_checkpoint_thread: Optional[threading.Thread] = None
        self._stop_event = threading.Event()

    def create_checkpoint(
        self,
        workflow_id: str,
        run_id: str,
        state: Dict[str, Any],
        task_states: Dict[str, str],
        xcom: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> Checkpoint:
        """Create a new checkpoint.

        Args:
            workflow_id: Workflow identifier
            run_id: Run identifier
            state: Current workflow state
            task_states: Task execution states
            xcom: Cross-communication data
            params: Workflow parameters
            metadata: Additional metadata

        Returns:
            Created checkpoint
        """
        checkpoint_id = f"{run_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

        checkpoint = Checkpoint(
            checkpoint_id=checkpoint_id,
            workflow_id=workflow_id,
            run_id=run_id,
            created_at=datetime.utcnow(),
            state=state,
            task_states=task_states,
            xcom=xcom or {},
            params=params or {},
            metadata=metadata or {},
        )

        self._save_checkpoint(checkpoint)
        self._cleanup_old_checkpoints(workflow_id, run_id)

        logger.info(f"Created checkpoint: {checkpoint_id}")
        return checkpoint

    def get_checkpoint(self, checkpoint_id: str) -> Optional[Checkpoint]:
        """Get checkpoint by ID."""
        file_path = self._get_checkpoint_path(checkpoint_id)

        if not file_path.exists():
            return None

        return self._load_checkpoint(file_path)

    def get_latest_checkpoint(
        self,
        workflow_id: str,
        run_id: Optional[str] = None,
    ) -> Optional[Checkpoint]:
        """Get the latest checkpoint for a workflow.

        Args:
            workflow_id: Workflow identifier
            run_id: Optional run identifier

        Returns:
            Latest checkpoint or None
        """
        checkpoints = self.list_checkpoints(workflow_id, run_id)

        if not checkpoints:
            return None

        latest = max(checkpoints, key=lambda c: c.created_at)
        return latest

    def list_checkpoints(
        self,
        workflow_id: Optional[str] = None,
        run_id: Optional[str] = None,
    ) -> List[Checkpoint]:
        """List checkpoints with optional filtering.

        Args:
            workflow_id: Filter by workflow
            run_id: Filter by run

        Returns:
            List of checkpoints
        """
        checkpoints = []

        pattern = "*.checkpoint" if not self.config.compression else "*.checkpoint.gz"

        for file_path in self._storage_path.glob(pattern):
            try:
                checkpoint = self._load_checkpoint(file_path)
                if checkpoint:
                    if workflow_id and checkpoint.workflow_id != workflow_id:
                        continue
                    if run_id and checkpoint.run_id != run_id:
                        continue
                    checkpoints.append(checkpoint)
            except Exception as e:
                logger.warning(f"Failed to load checkpoint {file_path}: {e}")

        return sorted(checkpoints, key=lambda c: c.created_at, reverse=True)

    def restore_from_checkpoint(
        self,
        checkpoint: Checkpoint,
    ) -> Dict[str, Any]:
        """Restore workflow state from checkpoint.

        Args:
            checkpoint: Checkpoint to restore from

        Returns:
            Restored state dictionary
        """
        if not checkpoint.validate():
            raise ValueError(f"Checkpoint validation failed: {checkpoint.checkpoint_id}")

        logger.info(f"Restoring from checkpoint: {checkpoint.checkpoint_id}")

        return {
            "state": checkpoint.state,
            "task_states": checkpoint.task_states,
            "xcom": checkpoint.xcom,
            "params": checkpoint.params,
            "restored_from": checkpoint.checkpoint_id,
            "restored_at": datetime.utcnow().isoformat(),
        }

    def delete_checkpoint(self, checkpoint_id: str) -> bool:
        """Delete a checkpoint."""
        file_path = self._get_checkpoint_path(checkpoint_id)

        if file_path.exists():
            file_path.unlink()
            logger.info(f"Deleted checkpoint: {checkpoint_id}")
            return True

        return False

    def delete_all_checkpoints(
        self,
        workflow_id: str,
        run_id: Optional[str] = None,
    ) -> int:
        """Delete all checkpoints for a workflow.

        Args:
            workflow_id: Workflow identifier
            run_id: Optional run identifier

        Returns:
            Number of deleted checkpoints
        """
        checkpoints = self.list_checkpoints(workflow_id, run_id)
        count = 0

        for checkpoint in checkpoints:
            if self.delete_checkpoint(checkpoint.checkpoint_id):
                count += 1

        return count

    def start_auto_checkpoint(
        self,
        workflow_id: str,
        run_id: str,
        state_provider: Callable[[], Dict[str, Any]],
        task_states_provider: Callable[[], Dict[str, str]],
        interval: Optional[float] = None,
    ) -> None:
        """Start automatic checkpointing.

        Args:
            workflow_id: Workflow identifier
            run_id: Run identifier
            state_provider: Callable returning current state
            task_states_provider: Callable returning task states
            interval: Checkpoint interval in seconds
        """
        interval = interval or self.config.auto_checkpoint_interval
        if not interval:
            return

        self._stop_event.clear()

        def auto_checkpoint_loop():
            while not self._stop_event.is_set():
                try:
                    state = state_provider()
                    task_states = task_states_provider()

                    self.create_checkpoint(
                        workflow_id=workflow_id,
                        run_id=run_id,
                        state=state,
                        task_states=task_states,
                    )
                except Exception as e:
                    logger.error(f"Auto checkpoint failed: {e}")

                self._stop_event.wait(interval)

        self._auto_checkpoint_thread = threading.Thread(
            target=auto_checkpoint_loop,
            daemon=True,
            name="AutoCheckpoint",
        )
        self._auto_checkpoint_thread.start()
        logger.info(f"Started auto checkpointing (interval={interval}s)")

    def stop_auto_checkpoint(self) -> None:
        """Stop automatic checkpointing."""
        self._stop_event.set()

        if self._auto_checkpoint_thread:
            self._auto_checkpoint_thread.join(timeout=5)
            self._auto_checkpoint_thread = None

        logger.info("Stopped auto checkpointing")

    def _save_checkpoint(self, checkpoint: Checkpoint) -> None:
        """Save checkpoint to storage."""
        file_path = self._get_checkpoint_path(checkpoint.checkpoint_id)

        if self.config.serializer == "pickle":
            data = pickle.dumps(checkpoint.to_dict())
        else:
            data = json.dumps(checkpoint.to_dict(), indent=2).encode()

        if self.config.compression:
            data = gzip.compress(data)

        with self._lock:
            with open(file_path, "wb") as f:
                f.write(data)

    def _load_checkpoint(self, file_path: Path) -> Optional[Checkpoint]:
        """Load checkpoint from storage."""
        try:
            with open(file_path, "rb") as f:
                data = f.read()

            if self.config.compression or str(file_path).endswith(".gz"):
                data = gzip.decompress(data)

            if self.config.serializer == "pickle":
                checkpoint_dict = pickle.loads(data)
            else:
                checkpoint_dict = json.loads(data.decode())

            return Checkpoint.from_dict(checkpoint_dict)

        except Exception as e:
            logger.error(f"Failed to load checkpoint from {file_path}: {e}")
            return None

    def _get_checkpoint_path(self, checkpoint_id: str) -> Path:
        """Get file path for checkpoint."""
        extension = ".checkpoint.gz" if self.config.compression else ".checkpoint"
        return self._storage_path / f"{checkpoint_id}{extension}"

    def _cleanup_old_checkpoints(
        self,
        workflow_id: str,
        run_id: str,
    ) -> None:
        """Clean up old checkpoints beyond retention limit."""
        checkpoints = self.list_checkpoints(workflow_id, run_id)

        if len(checkpoints) > self.config.max_checkpoints:
            to_delete = checkpoints[self.config.max_checkpoints:]
            for checkpoint in to_delete:
                self.delete_checkpoint(checkpoint.checkpoint_id)

        cutoff = datetime.utcnow() - timedelta(days=self.config.retention_days)
        for checkpoint in checkpoints:
            if checkpoint.created_at < cutoff:
                self.delete_checkpoint(checkpoint.checkpoint_id)

    def cleanup_expired(self) -> int:
        """Clean up all expired checkpoints."""
        cutoff = datetime.utcnow() - timedelta(days=self.config.retention_days)
        checkpoints = self.list_checkpoints()
        count = 0

        for checkpoint in checkpoints:
            if checkpoint.created_at < cutoff:
                if self.delete_checkpoint(checkpoint.checkpoint_id):
                    count += 1

        logger.info(f"Cleaned up {count} expired checkpoints")
        return count


__all__ = [
    "Checkpoint",
    "CheckpointManager",
    "CheckpointConfig",
]
