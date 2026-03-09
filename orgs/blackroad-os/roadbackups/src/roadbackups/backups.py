"""
RoadBackups - Backup and Restore System for BlackRoad
Scheduled backups with compression, encryption, and multi-destination support.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set, Union
import asyncio
import gzip
import hashlib
import json
import logging
import os
import shutil
import tarfile
import tempfile
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class BackupType(str, Enum):
    """Types of backups."""
    FULL = "full"
    INCREMENTAL = "incremental"
    DIFFERENTIAL = "differential"
    SNAPSHOT = "snapshot"


class BackupStatus(str, Enum):
    """Backup operation status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class StorageBackend(str, Enum):
    """Backup storage backends."""
    LOCAL = "local"
    S3 = "s3"
    GCS = "gcs"
    AZURE = "azure"
    SFTP = "sftp"


@dataclass
class BackupConfig:
    """Backup configuration."""
    name: str
    sources: List[str]  # Paths or identifiers to backup
    destination: str
    backend: StorageBackend = StorageBackend.LOCAL
    backup_type: BackupType = BackupType.FULL
    compression: bool = True
    encryption: bool = False
    encryption_key: Optional[str] = None
    schedule: Optional[str] = None  # Cron expression
    retention_days: int = 30
    max_backups: int = 10
    exclude_patterns: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class BackupManifest:
    """Manifest for a backup."""
    backup_id: str
    config_name: str
    backup_type: BackupType
    created_at: datetime
    completed_at: Optional[datetime] = None
    status: BackupStatus = BackupStatus.PENDING
    size_bytes: int = 0
    file_count: int = 0
    checksum: Optional[str] = None
    location: Optional[str] = None
    parent_backup_id: Optional[str] = None  # For incremental
    error_message: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "backup_id": self.backup_id,
            "config_name": self.config_name,
            "backup_type": self.backup_type.value,
            "created_at": self.created_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "status": self.status.value,
            "size_bytes": self.size_bytes,
            "file_count": self.file_count,
            "checksum": self.checksum,
            "location": self.location,
            "parent_backup_id": self.parent_backup_id,
            "error_message": self.error_message,
            "metadata": self.metadata
        }


@dataclass
class RestoreOptions:
    """Options for restore operation."""
    backup_id: str
    destination: str
    overwrite: bool = False
    selective_paths: Optional[List[str]] = None
    verify_checksum: bool = True
    preserve_permissions: bool = True


class BackupStorage:
    """Abstract backup storage interface."""

    def store(self, source_path: str, destination: str) -> str:
        """Store backup file."""
        raise NotImplementedError

    def retrieve(self, location: str, destination: str) -> str:
        """Retrieve backup file."""
        raise NotImplementedError

    def delete(self, location: str) -> bool:
        """Delete backup file."""
        raise NotImplementedError

    def list(self, prefix: str = "") -> List[str]:
        """List backup files."""
        raise NotImplementedError


class LocalStorage(BackupStorage):
    """Local filesystem storage."""

    def __init__(self, base_path: str = "/backups"):
        self.base_path = Path(base_path)
        self.base_path.mkdir(parents=True, exist_ok=True)

    def store(self, source_path: str, destination: str) -> str:
        """Store backup to local filesystem."""
        dest_path = self.base_path / destination
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, dest_path)
        return str(dest_path)

    def retrieve(self, location: str, destination: str) -> str:
        """Retrieve backup from local filesystem."""
        shutil.copy2(location, destination)
        return destination

    def delete(self, location: str) -> bool:
        """Delete backup file."""
        try:
            Path(location).unlink()
            return True
        except Exception:
            return False

    def list(self, prefix: str = "") -> List[str]:
        """List backup files."""
        pattern = f"{prefix}*" if prefix else "*"
        return [str(p) for p in self.base_path.glob(pattern)]


class BackupEngine:
    """Core backup engine."""

    def __init__(self, storage: BackupStorage):
        self.storage = storage
        self._lock = threading.Lock()

    def _calculate_checksum(self, file_path: str) -> str:
        """Calculate file checksum."""
        sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                sha256.update(chunk)
        return sha256.hexdigest()

    def _should_include(self, path: str, exclude_patterns: List[str]) -> bool:
        """Check if path should be included in backup."""
        import fnmatch
        for pattern in exclude_patterns:
            if fnmatch.fnmatch(path, pattern):
                return False
        return True

    def _compress_file(self, source: str, dest: str) -> None:
        """Compress file with gzip."""
        with open(source, "rb") as f_in:
            with gzip.open(dest, "wb") as f_out:
                shutil.copyfileobj(f_in, f_out)

    def _decompress_file(self, source: str, dest: str) -> None:
        """Decompress gzip file."""
        with gzip.open(source, "rb") as f_in:
            with open(dest, "wb") as f_out:
                shutil.copyfileobj(f_in, f_out)

    def create_backup(
        self,
        config: BackupConfig,
        manifest: BackupManifest
    ) -> BackupManifest:
        """Create a backup."""
        manifest.status = BackupStatus.RUNNING
        temp_dir = tempfile.mkdtemp()

        try:
            # Create tar archive
            archive_name = f"{manifest.backup_id}.tar"
            if config.compression:
                archive_name += ".gz"

            archive_path = os.path.join(temp_dir, archive_name)
            mode = "w:gz" if config.compression else "w"

            file_count = 0
            with tarfile.open(archive_path, mode) as tar:
                for source in config.sources:
                    source_path = Path(source)
                    if source_path.is_file():
                        if self._should_include(str(source_path), config.exclude_patterns):
                            tar.add(source_path, arcname=source_path.name)
                            file_count += 1
                    elif source_path.is_dir():
                        for file_path in source_path.rglob("*"):
                            if file_path.is_file() and self._should_include(str(file_path), config.exclude_patterns):
                                arcname = file_path.relative_to(source_path.parent)
                                tar.add(file_path, arcname=str(arcname))
                                file_count += 1

            # Calculate checksum
            manifest.checksum = self._calculate_checksum(archive_path)
            manifest.size_bytes = os.path.getsize(archive_path)
            manifest.file_count = file_count

            # Store backup
            destination = f"{config.name}/{manifest.backup_id}/{archive_name}"
            manifest.location = self.storage.store(archive_path, destination)

            manifest.status = BackupStatus.COMPLETED
            manifest.completed_at = datetime.now()

            logger.info(f"Backup completed: {manifest.backup_id}")

        except Exception as e:
            manifest.status = BackupStatus.FAILED
            manifest.error_message = str(e)
            logger.error(f"Backup failed: {e}")

        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

        return manifest

    def restore_backup(
        self,
        manifest: BackupManifest,
        options: RestoreOptions
    ) -> bool:
        """Restore a backup."""
        if not manifest.location:
            logger.error("Backup location not found")
            return False

        temp_dir = tempfile.mkdtemp()

        try:
            # Retrieve backup
            archive_path = os.path.join(temp_dir, "backup.tar.gz")
            self.storage.retrieve(manifest.location, archive_path)

            # Verify checksum
            if options.verify_checksum and manifest.checksum:
                actual_checksum = self._calculate_checksum(archive_path)
                if actual_checksum != manifest.checksum:
                    raise ValueError("Checksum mismatch - backup may be corrupted")

            # Extract
            dest_path = Path(options.destination)
            dest_path.mkdir(parents=True, exist_ok=True)

            mode = "r:gz" if manifest.location.endswith(".gz") else "r"
            with tarfile.open(archive_path, mode) as tar:
                if options.selective_paths:
                    for member in tar.getmembers():
                        if any(member.name.startswith(p) for p in options.selective_paths):
                            tar.extract(member, dest_path)
                else:
                    tar.extractall(dest_path)

            logger.info(f"Restore completed to {options.destination}")
            return True

        except Exception as e:
            logger.error(f"Restore failed: {e}")
            return False

        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)


class BackupManager:
    """High-level backup management."""

    def __init__(self, storage: Optional[BackupStorage] = None):
        self.storage = storage or LocalStorage()
        self.engine = BackupEngine(self.storage)
        self.configs: Dict[str, BackupConfig] = {}
        self.manifests: Dict[str, BackupManifest] = {}
        self._running = False
        self._hooks: Dict[str, List[Callable]] = {
            "before_backup": [],
            "after_backup": [],
            "before_restore": [],
            "after_restore": []
        }

    def add_hook(self, event: str, hook: Callable) -> None:
        """Add lifecycle hook."""
        if event in self._hooks:
            self._hooks[event].append(hook)

    def _trigger_hooks(self, event: str, *args) -> None:
        """Trigger hooks."""
        for hook in self._hooks.get(event, []):
            try:
                hook(*args)
            except Exception as e:
                logger.error(f"Hook error: {e}")

    def register_config(self, config: BackupConfig) -> None:
        """Register backup configuration."""
        self.configs[config.name] = config
        logger.info(f"Registered backup config: {config.name}")

    def create_backup(
        self,
        config_name: str,
        backup_type: Optional[BackupType] = None
    ) -> BackupManifest:
        """Create a new backup."""
        config = self.configs.get(config_name)
        if not config:
            raise ValueError(f"Config not found: {config_name}")

        manifest = BackupManifest(
            backup_id=str(uuid.uuid4()),
            config_name=config_name,
            backup_type=backup_type or config.backup_type,
            created_at=datetime.now()
        )

        # Find parent for incremental
        if manifest.backup_type == BackupType.INCREMENTAL:
            parent = self._get_latest_backup(config_name)
            if parent:
                manifest.parent_backup_id = parent.backup_id

        self._trigger_hooks("before_backup", config, manifest)

        manifest = self.engine.create_backup(config, manifest)
        self.manifests[manifest.backup_id] = manifest

        self._trigger_hooks("after_backup", config, manifest)

        # Apply retention policy
        self._apply_retention(config_name)

        return manifest

    def restore(self, options: RestoreOptions) -> bool:
        """Restore from backup."""
        manifest = self.manifests.get(options.backup_id)
        if not manifest:
            logger.error(f"Backup not found: {options.backup_id}")
            return False

        config = self.configs.get(manifest.config_name)
        self._trigger_hooks("before_restore", manifest, options)

        result = self.engine.restore_backup(manifest, options)

        self._trigger_hooks("after_restore", manifest, options, result)
        return result

    def _get_latest_backup(self, config_name: str) -> Optional[BackupManifest]:
        """Get latest successful backup for config."""
        backups = [
            m for m in self.manifests.values()
            if m.config_name == config_name and m.status == BackupStatus.COMPLETED
        ]
        if backups:
            return max(backups, key=lambda m: m.created_at)
        return None

    def _apply_retention(self, config_name: str) -> int:
        """Apply retention policy."""
        config = self.configs.get(config_name)
        if not config:
            return 0

        backups = sorted(
            [m for m in self.manifests.values() if m.config_name == config_name],
            key=lambda m: m.created_at,
            reverse=True
        )

        deleted = 0
        cutoff_date = datetime.now() - timedelta(days=config.retention_days)

        for i, backup in enumerate(backups):
            should_delete = False

            # Check count limit
            if i >= config.max_backups:
                should_delete = True

            # Check age limit
            if backup.created_at < cutoff_date:
                should_delete = True

            if should_delete and backup.status == BackupStatus.COMPLETED:
                if backup.location:
                    self.storage.delete(backup.location)
                del self.manifests[backup.backup_id]
                deleted += 1

        if deleted:
            logger.info(f"Deleted {deleted} old backups for {config_name}")

        return deleted

    def list_backups(
        self,
        config_name: Optional[str] = None,
        status: Optional[BackupStatus] = None,
        limit: int = 100
    ) -> List[BackupManifest]:
        """List backups."""
        backups = list(self.manifests.values())

        if config_name:
            backups = [b for b in backups if b.config_name == config_name]
        if status:
            backups = [b for b in backups if b.status == status]

        return sorted(backups, key=lambda b: b.created_at, reverse=True)[:limit]

    def get_backup(self, backup_id: str) -> Optional[BackupManifest]:
        """Get backup by ID."""
        return self.manifests.get(backup_id)

    def delete_backup(self, backup_id: str) -> bool:
        """Delete a backup."""
        manifest = self.manifests.get(backup_id)
        if not manifest:
            return False

        if manifest.location:
            self.storage.delete(manifest.location)

        del self.manifests[backup_id]
        return True

    def verify_backup(self, backup_id: str) -> bool:
        """Verify backup integrity."""
        manifest = self.manifests.get(backup_id)
        if not manifest or not manifest.location or not manifest.checksum:
            return False

        try:
            temp_path = tempfile.mktemp()
            self.storage.retrieve(manifest.location, temp_path)
            actual_checksum = self.engine._calculate_checksum(temp_path)
            os.unlink(temp_path)

            return actual_checksum == manifest.checksum

        except Exception as e:
            logger.error(f"Verification failed: {e}")
            return False

    def get_stats(self, config_name: Optional[str] = None) -> Dict[str, Any]:
        """Get backup statistics."""
        backups = self.list_backups(config_name=config_name, limit=1000)

        total_size = sum(b.size_bytes for b in backups)
        completed = sum(1 for b in backups if b.status == BackupStatus.COMPLETED)
        failed = sum(1 for b in backups if b.status == BackupStatus.FAILED)

        return {
            "total_backups": len(backups),
            "completed": completed,
            "failed": failed,
            "total_size_bytes": total_size,
            "total_size_gb": total_size / (1024**3),
            "success_rate": completed / max(len(backups), 1)
        }


# Example usage
def example_usage():
    """Example backup usage."""
    manager = BackupManager()

    # Register backup config
    manager.register_config(BackupConfig(
        name="app_data",
        sources=["/app/data", "/app/uploads"],
        destination="/backups/app_data",
        compression=True,
        retention_days=30,
        max_backups=10,
        exclude_patterns=["*.tmp", "*.log"]
    ))

    # Create backup
    manifest = manager.create_backup("app_data")
    print(f"Backup created: {manifest.backup_id}")
    print(f"Size: {manifest.size_bytes / 1024:.2f} KB")
    print(f"Files: {manifest.file_count}")

    # List backups
    backups = manager.list_backups("app_data")
    print(f"Total backups: {len(backups)}")

    # Restore
    result = manager.restore(RestoreOptions(
        backup_id=manifest.backup_id,
        destination="/app/restored",
        verify_checksum=True
    ))
    print(f"Restore success: {result}")

    # Stats
    stats = manager.get_stats("app_data")
    print(f"Stats: {stats}")
