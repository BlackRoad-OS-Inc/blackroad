"""
RoadBackup - Backup and Restore for BlackRoad
Incremental backups, snapshots, and recovery.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple
import asyncio
import hashlib
import json
import logging
import os
import shutil
import threading
import uuid
import gzip

logger = logging.getLogger(__name__)


class BackupType(str, Enum):
    """Backup types."""
    FULL = "full"
    INCREMENTAL = "incremental"
    DIFFERENTIAL = "differential"
    SNAPSHOT = "snapshot"


class BackupStatus(str, Enum):
    """Backup status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class RestoreStatus(str, Enum):
    """Restore status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class BackupMetadata:
    """Backup metadata."""
    id: str
    name: str
    backup_type: BackupType
    source_path: str
    dest_path: str
    parent_id: Optional[str] = None
    size_bytes: int = 0
    file_count: int = 0
    checksum: str = ""
    created_at: datetime = field(default_factory=datetime.now)
    completed_at: Optional[datetime] = None
    status: BackupStatus = BackupStatus.PENDING
    error: Optional[str] = None
    tags: Dict[str, str] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "type": self.backup_type.value,
            "source": self.source_path,
            "dest": self.dest_path,
            "parent_id": self.parent_id,
            "size_bytes": self.size_bytes,
            "file_count": self.file_count,
            "checksum": self.checksum,
            "created_at": self.created_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "status": self.status.value,
            "tags": self.tags
        }


@dataclass
class FileEntry:
    """A file in a backup."""
    path: str
    size: int
    checksum: str
    modified_at: datetime
    is_directory: bool = False
    permissions: int = 0o644


@dataclass
class BackupManifest:
    """Manifest of backup contents."""
    backup_id: str
    files: List[FileEntry] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)

    def add_file(self, entry: FileEntry) -> None:
        self.files.append(entry)

    def get_file(self, path: str) -> Optional[FileEntry]:
        for f in self.files:
            if f.path == path:
                return f
        return None

    def to_json(self) -> str:
        return json.dumps({
            "backup_id": self.backup_id,
            "created_at": self.created_at.isoformat(),
            "files": [
                {
                    "path": f.path,
                    "size": f.size,
                    "checksum": f.checksum,
                    "modified_at": f.modified_at.isoformat(),
                    "is_directory": f.is_directory
                }
                for f in self.files
            ]
        }, indent=2)


class FileHasher:
    """Calculate file checksums."""

    @staticmethod
    def hash_file(path: str, algorithm: str = "sha256") -> str:
        """Calculate file hash."""
        hasher = hashlib.new(algorithm)
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                hasher.update(chunk)
        return hasher.hexdigest()

    @staticmethod
    def hash_data(data: bytes, algorithm: str = "sha256") -> str:
        """Calculate data hash."""
        return hashlib.new(algorithm, data).hexdigest()


class BackupEngine:
    """Core backup engine."""

    def __init__(self, storage_path: str):
        self.storage_path = storage_path
        self.hasher = FileHasher()
        self._lock = threading.Lock()

        os.makedirs(storage_path, exist_ok=True)

    def create_backup(
        self,
        name: str,
        source_path: str,
        backup_type: BackupType = BackupType.FULL,
        parent_id: str = None,
        compress: bool = True
    ) -> BackupMetadata:
        """Create a backup."""
        backup_id = str(uuid.uuid4())[:12]
        dest_path = os.path.join(self.storage_path, backup_id)
        os.makedirs(dest_path, exist_ok=True)

        metadata = BackupMetadata(
            id=backup_id,
            name=name,
            backup_type=backup_type,
            source_path=source_path,
            dest_path=dest_path,
            parent_id=parent_id,
            status=BackupStatus.RUNNING
        )

        try:
            manifest = BackupManifest(backup_id=backup_id)

            if backup_type == BackupType.FULL:
                self._full_backup(source_path, dest_path, manifest, compress)
            elif backup_type == BackupType.INCREMENTAL:
                self._incremental_backup(source_path, dest_path, parent_id, manifest, compress)
            elif backup_type == BackupType.SNAPSHOT:
                self._snapshot_backup(source_path, dest_path, manifest)

            # Save manifest
            manifest_path = os.path.join(dest_path, "manifest.json")
            with open(manifest_path, "w") as f:
                f.write(manifest.to_json())

            # Calculate totals
            metadata.file_count = len(manifest.files)
            metadata.size_bytes = sum(f.size for f in manifest.files)
            metadata.checksum = self.hasher.hash_file(manifest_path)
            metadata.status = BackupStatus.COMPLETED
            metadata.completed_at = datetime.now()

            # Save metadata
            meta_path = os.path.join(dest_path, "metadata.json")
            with open(meta_path, "w") as f:
                json.dump(metadata.to_dict(), f, indent=2)

        except Exception as e:
            metadata.status = BackupStatus.FAILED
            metadata.error = str(e)
            logger.error(f"Backup failed: {e}")

        return metadata

    def _full_backup(
        self,
        source: str,
        dest: str,
        manifest: BackupManifest,
        compress: bool
    ) -> None:
        """Perform full backup."""
        data_dir = os.path.join(dest, "data")
        os.makedirs(data_dir, exist_ok=True)

        for root, dirs, files in os.walk(source):
            rel_root = os.path.relpath(root, source)

            for d in dirs:
                rel_path = os.path.join(rel_root, d) if rel_root != "." else d
                manifest.add_file(FileEntry(
                    path=rel_path,
                    size=0,
                    checksum="",
                    modified_at=datetime.now(),
                    is_directory=True
                ))

            for file in files:
                src_file = os.path.join(root, file)
                rel_path = os.path.join(rel_root, file) if rel_root != "." else file

                # Copy file
                dest_file = os.path.join(data_dir, rel_path)
                os.makedirs(os.path.dirname(dest_file), exist_ok=True)

                if compress:
                    dest_file += ".gz"
                    with open(src_file, "rb") as f_in:
                        with gzip.open(dest_file, "wb") as f_out:
                            shutil.copyfileobj(f_in, f_out)
                else:
                    shutil.copy2(src_file, dest_file)

                stat = os.stat(src_file)
                manifest.add_file(FileEntry(
                    path=rel_path,
                    size=stat.st_size,
                    checksum=self.hasher.hash_file(src_file),
                    modified_at=datetime.fromtimestamp(stat.st_mtime),
                    permissions=stat.st_mode
                ))

    def _incremental_backup(
        self,
        source: str,
        dest: str,
        parent_id: str,
        manifest: BackupManifest,
        compress: bool
    ) -> None:
        """Perform incremental backup."""
        # Load parent manifest
        parent_manifest = self._load_manifest(parent_id)
        if not parent_manifest:
            # Fall back to full
            return self._full_backup(source, dest, manifest, compress)

        parent_files = {f.path: f for f in parent_manifest.files}
        data_dir = os.path.join(dest, "data")
        os.makedirs(data_dir, exist_ok=True)

        for root, dirs, files in os.walk(source):
            rel_root = os.path.relpath(root, source)

            for file in files:
                src_file = os.path.join(root, file)
                rel_path = os.path.join(rel_root, file) if rel_root != "." else file

                stat = os.stat(src_file)
                checksum = self.hasher.hash_file(src_file)

                # Check if changed
                parent_entry = parent_files.get(rel_path)
                if parent_entry and parent_entry.checksum == checksum:
                    # Unchanged, reference parent
                    manifest.add_file(FileEntry(
                        path=rel_path,
                        size=stat.st_size,
                        checksum=checksum,
                        modified_at=datetime.fromtimestamp(stat.st_mtime)
                    ))
                    continue

                # Changed or new, copy
                dest_file = os.path.join(data_dir, rel_path)
                os.makedirs(os.path.dirname(dest_file), exist_ok=True)

                if compress:
                    dest_file += ".gz"
                    with open(src_file, "rb") as f_in:
                        with gzip.open(dest_file, "wb") as f_out:
                            shutil.copyfileobj(f_in, f_out)
                else:
                    shutil.copy2(src_file, dest_file)

                manifest.add_file(FileEntry(
                    path=rel_path,
                    size=stat.st_size,
                    checksum=checksum,
                    modified_at=datetime.fromtimestamp(stat.st_mtime)
                ))

    def _snapshot_backup(
        self,
        source: str,
        dest: str,
        manifest: BackupManifest
    ) -> None:
        """Create a snapshot (lightweight copy)."""
        # For simplicity, just create metadata
        for root, dirs, files in os.walk(source):
            rel_root = os.path.relpath(root, source)

            for file in files:
                src_file = os.path.join(root, file)
                rel_path = os.path.join(rel_root, file) if rel_root != "." else file

                stat = os.stat(src_file)
                manifest.add_file(FileEntry(
                    path=rel_path,
                    size=stat.st_size,
                    checksum=self.hasher.hash_file(src_file),
                    modified_at=datetime.fromtimestamp(stat.st_mtime)
                ))

    def _load_manifest(self, backup_id: str) -> Optional[BackupManifest]:
        """Load a backup manifest."""
        manifest_path = os.path.join(self.storage_path, backup_id, "manifest.json")
        if not os.path.exists(manifest_path):
            return None

        with open(manifest_path, "r") as f:
            data = json.load(f)

        manifest = BackupManifest(backup_id=backup_id)
        for f_data in data.get("files", []):
            manifest.add_file(FileEntry(
                path=f_data["path"],
                size=f_data["size"],
                checksum=f_data["checksum"],
                modified_at=datetime.fromisoformat(f_data["modified_at"]),
                is_directory=f_data.get("is_directory", False)
            ))

        return manifest

    def restore(
        self,
        backup_id: str,
        dest_path: str,
        files: List[str] = None
    ) -> bool:
        """Restore from backup."""
        backup_path = os.path.join(self.storage_path, backup_id)
        if not os.path.exists(backup_path):
            return False

        manifest = self._load_manifest(backup_id)
        if not manifest:
            return False

        os.makedirs(dest_path, exist_ok=True)
        data_dir = os.path.join(backup_path, "data")

        for entry in manifest.files:
            if files and entry.path not in files:
                continue

            if entry.is_directory:
                os.makedirs(os.path.join(dest_path, entry.path), exist_ok=True)
                continue

            src_file = os.path.join(data_dir, entry.path)
            dest_file = os.path.join(dest_path, entry.path)

            os.makedirs(os.path.dirname(dest_file), exist_ok=True)

            # Check for compressed
            if os.path.exists(src_file + ".gz"):
                with gzip.open(src_file + ".gz", "rb") as f_in:
                    with open(dest_file, "wb") as f_out:
                        shutil.copyfileobj(f_in, f_out)
            elif os.path.exists(src_file):
                shutil.copy2(src_file, dest_file)

        return True


class BackupScheduler:
    """Schedule backups."""

    def __init__(self, engine: BackupEngine):
        self.engine = engine
        self.schedules: Dict[str, Dict] = {}
        self._running = False

    def add_schedule(
        self,
        name: str,
        source: str,
        interval_hours: int,
        backup_type: BackupType = BackupType.FULL,
        retention_count: int = 7
    ) -> None:
        """Add a backup schedule."""
        self.schedules[name] = {
            "source": source,
            "interval": interval_hours,
            "type": backup_type,
            "retention": retention_count,
            "last_run": None
        }


class BackupManager:
    """High-level backup management."""

    def __init__(self, storage_path: str = "/tmp/backups"):
        self.engine = BackupEngine(storage_path)
        self.scheduler = BackupScheduler(self.engine)
        self._backups: Dict[str, BackupMetadata] = {}

    def create(
        self,
        name: str,
        source: str,
        backup_type: BackupType = BackupType.FULL,
        **kwargs
    ) -> BackupMetadata:
        """Create a backup."""
        metadata = self.engine.create_backup(name, source, backup_type, **kwargs)
        self._backups[metadata.id] = metadata
        return metadata

    def restore(
        self,
        backup_id: str,
        dest_path: str,
        files: List[str] = None
    ) -> bool:
        """Restore from backup."""
        return self.engine.restore(backup_id, dest_path, files)

    def list_backups(self, name: str = None) -> List[BackupMetadata]:
        """List backups."""
        backups = list(self._backups.values())
        if name:
            backups = [b for b in backups if b.name == name]
        return sorted(backups, key=lambda b: b.created_at, reverse=True)

    def get_backup(self, backup_id: str) -> Optional[BackupMetadata]:
        """Get backup by ID."""
        return self._backups.get(backup_id)

    def delete_backup(self, backup_id: str) -> bool:
        """Delete a backup."""
        if backup_id not in self._backups:
            return False

        backup = self._backups[backup_id]
        if os.path.exists(backup.dest_path):
            shutil.rmtree(backup.dest_path)

        del self._backups[backup_id]
        return True


# Example usage
def example_usage():
    """Example backup usage."""
    import tempfile

    # Create test directory
    source_dir = tempfile.mkdtemp()
    os.makedirs(os.path.join(source_dir, "subdir"))

    with open(os.path.join(source_dir, "file1.txt"), "w") as f:
        f.write("Hello World!")

    with open(os.path.join(source_dir, "subdir", "file2.txt"), "w") as f:
        f.write("Nested file content")

    # Create backup manager
    manager = BackupManager()

    # Full backup
    backup = manager.create(
        name="test_backup",
        source=source_dir,
        backup_type=BackupType.FULL,
        compress=True
    )

    print(f"Created backup: {backup.id}")
    print(f"Status: {backup.status.value}")
    print(f"Size: {backup.size_bytes} bytes")
    print(f"Files: {backup.file_count}")

    # List backups
    backups = manager.list_backups()
    print(f"\nAll backups: {len(backups)}")

    # Restore
    restore_dir = tempfile.mkdtemp()
    success = manager.restore(backup.id, restore_dir)
    print(f"\nRestored to {restore_dir}: {success}")

    # Verify
    restored_file = os.path.join(restore_dir, "file1.txt")
    if os.path.exists(restored_file):
        with open(restored_file) as f:
            print(f"Restored content: {f.read()}")

    # Cleanup
    shutil.rmtree(source_dir)
    shutil.rmtree(restore_dir)

