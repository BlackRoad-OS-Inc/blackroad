"""
RoadFiles - File Management System for BlackRoad
File uploads, processing, and storage abstraction.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, BinaryIO, Callable, Dict, List, Optional, Tuple, Union
import hashlib
import json
import logging
import mimetypes
import os
import shutil
import tempfile
import threading
import uuid

logger = logging.getLogger(__name__)


class FileStatus(str, Enum):
    """File status."""
    PENDING = "pending"
    UPLOADED = "uploaded"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"
    DELETED = "deleted"


class StorageType(str, Enum):
    """Storage backend type."""
    LOCAL = "local"
    S3 = "s3"
    GCS = "gcs"
    AZURE = "azure"
    MEMORY = "memory"


@dataclass
class FileMetadata:
    """Metadata for a file."""
    id: str
    filename: str
    content_type: str
    size: int
    checksum: str
    status: FileStatus = FileStatus.PENDING
    storage_path: Optional[str] = None
    storage_type: StorageType = StorageType.LOCAL
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    uploaded_by: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    custom_metadata: Dict[str, Any] = field(default_factory=dict)
    versions: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "filename": self.filename,
            "content_type": self.content_type,
            "size": self.size,
            "checksum": self.checksum,
            "status": self.status.value,
            "storage_path": self.storage_path,
            "created_at": self.created_at.isoformat(),
            "tags": self.tags
        }


@dataclass
class UploadConfig:
    """Configuration for file uploads."""
    max_size: int = 100 * 1024 * 1024  # 100MB
    allowed_types: Optional[List[str]] = None
    blocked_types: List[str] = field(default_factory=lambda: [
        "application/x-executable", "application/x-msdownload"
    ])
    chunk_size: int = 1024 * 1024  # 1MB
    generate_thumbnails: bool = False
    virus_scan: bool = False


class StorageBackend:
    """Abstract storage backend."""

    def store(self, file_id: str, data: BinaryIO) -> str:
        """Store file and return path."""
        raise NotImplementedError

    def retrieve(self, path: str) -> BinaryIO:
        """Retrieve file."""
        raise NotImplementedError

    def delete(self, path: str) -> bool:
        """Delete file."""
        raise NotImplementedError

    def exists(self, path: str) -> bool:
        """Check if file exists."""
        raise NotImplementedError

    def get_url(self, path: str, expires: int = 3600) -> str:
        """Get URL for file."""
        raise NotImplementedError


class LocalStorageBackend(StorageBackend):
    """Local filesystem storage."""

    def __init__(self, base_path: str = "/tmp/roadfiles"):
        self.base_path = Path(base_path)
        self.base_path.mkdir(parents=True, exist_ok=True)

    def _get_path(self, file_id: str) -> Path:
        # Use first 2 chars for directory sharding
        shard = file_id[:2]
        dir_path = self.base_path / shard
        dir_path.mkdir(exist_ok=True)
        return dir_path / file_id

    def store(self, file_id: str, data: BinaryIO) -> str:
        path = self._get_path(file_id)
        with open(path, 'wb') as f:
            shutil.copyfileobj(data, f)
        return str(path)

    def retrieve(self, path: str) -> BinaryIO:
        return open(path, 'rb')

    def delete(self, path: str) -> bool:
        try:
            Path(path).unlink()
            return True
        except Exception:
            return False

    def exists(self, path: str) -> bool:
        return Path(path).exists()

    def get_url(self, path: str, expires: int = 3600) -> str:
        return f"file://{path}"


class MemoryStorageBackend(StorageBackend):
    """In-memory storage for testing."""

    def __init__(self):
        self.files: Dict[str, bytes] = {}

    def store(self, file_id: str, data: BinaryIO) -> str:
        self.files[file_id] = data.read()
        return file_id

    def retrieve(self, path: str) -> BinaryIO:
        import io
        return io.BytesIO(self.files.get(path, b""))

    def delete(self, path: str) -> bool:
        if path in self.files:
            del self.files[path]
            return True
        return False

    def exists(self, path: str) -> bool:
        return path in self.files

    def get_url(self, path: str, expires: int = 3600) -> str:
        return f"memory://{path}"


class FileStore:
    """Store for file metadata."""

    def __init__(self):
        self.files: Dict[str, FileMetadata] = {}
        self._lock = threading.Lock()

    def save(self, metadata: FileMetadata) -> None:
        with self._lock:
            metadata.updated_at = datetime.now()
            self.files[metadata.id] = metadata

    def get(self, file_id: str) -> Optional[FileMetadata]:
        return self.files.get(file_id)

    def delete(self, file_id: str) -> bool:
        with self._lock:
            if file_id in self.files:
                del self.files[file_id]
                return True
        return False

    def list_files(
        self,
        tags: Optional[List[str]] = None,
        status: Optional[FileStatus] = None,
        limit: int = 100
    ) -> List[FileMetadata]:
        files = list(self.files.values())
        
        if tags:
            files = [f for f in files if set(tags).issubset(set(f.tags))]
        if status:
            files = [f for f in files if f.status == status]
        
        return sorted(files, key=lambda f: f.created_at, reverse=True)[:limit]


class FileProcessor:
    """Process uploaded files."""

    def __init__(self):
        self.processors: Dict[str, Callable[[bytes], bytes]] = {}

    def register(self, content_type: str, processor: Callable[[bytes], bytes]) -> None:
        """Register a processor for content type."""
        self.processors[content_type] = processor

    def process(self, data: bytes, content_type: str) -> bytes:
        """Process file data."""
        processor = self.processors.get(content_type)
        if processor:
            return processor(data)
        return data


class ChunkedUploader:
    """Handle chunked file uploads."""

    def __init__(self, chunk_size: int = 1024 * 1024):
        self.chunk_size = chunk_size
        self.uploads: Dict[str, Dict[str, Any]] = {}
        self._lock = threading.Lock()

    def init_upload(self, upload_id: str, filename: str, total_size: int) -> Dict[str, Any]:
        """Initialize chunked upload."""
        with self._lock:
            self.uploads[upload_id] = {
                "filename": filename,
                "total_size": total_size,
                "chunks_received": set(),
                "total_chunks": (total_size + self.chunk_size - 1) // self.chunk_size,
                "temp_dir": tempfile.mkdtemp(),
                "created_at": datetime.now()
            }
        return self.uploads[upload_id]

    def upload_chunk(self, upload_id: str, chunk_number: int, data: bytes) -> bool:
        """Upload a chunk."""
        upload = self.uploads.get(upload_id)
        if not upload:
            return False

        chunk_path = Path(upload["temp_dir"]) / f"chunk_{chunk_number}"
        with open(chunk_path, 'wb') as f:
            f.write(data)

        with self._lock:
            upload["chunks_received"].add(chunk_number)

        return True

    def is_complete(self, upload_id: str) -> bool:
        """Check if upload is complete."""
        upload = self.uploads.get(upload_id)
        if not upload:
            return False
        return len(upload["chunks_received"]) == upload["total_chunks"]

    def assemble(self, upload_id: str) -> Optional[BinaryIO]:
        """Assemble chunks into complete file."""
        upload = self.uploads.get(upload_id)
        if not upload or not self.is_complete(upload_id):
            return None

        temp_file = tempfile.NamedTemporaryFile(delete=False)
        
        for i in range(upload["total_chunks"]):
            chunk_path = Path(upload["temp_dir"]) / f"chunk_{i}"
            with open(chunk_path, 'rb') as chunk:
                temp_file.write(chunk.read())

        temp_file.seek(0)
        
        # Cleanup chunks
        shutil.rmtree(upload["temp_dir"], ignore_errors=True)
        del self.uploads[upload_id]

        return temp_file

    def cancel(self, upload_id: str) -> bool:
        """Cancel upload and cleanup."""
        upload = self.uploads.get(upload_id)
        if upload:
            shutil.rmtree(upload["temp_dir"], ignore_errors=True)
            del self.uploads[upload_id]
            return True
        return False


class FileManager:
    """High-level file management."""

    def __init__(
        self,
        storage: Optional[StorageBackend] = None,
        config: Optional[UploadConfig] = None
    ):
        self.storage = storage or LocalStorageBackend()
        self.config = config or UploadConfig()
        self.store = FileStore()
        self.processor = FileProcessor()
        self.chunked = ChunkedUploader(self.config.chunk_size)

    def _calculate_checksum(self, data: BinaryIO) -> str:
        """Calculate file checksum."""
        sha256 = hashlib.sha256()
        for chunk in iter(lambda: data.read(8192), b""):
            sha256.update(chunk)
        data.seek(0)
        return sha256.hexdigest()

    def _validate_upload(self, filename: str, content_type: str, size: int) -> Tuple[bool, str]:
        """Validate file upload."""
        if size > self.config.max_size:
            return False, f"File too large: {size} > {self.config.max_size}"

        if content_type in self.config.blocked_types:
            return False, f"File type blocked: {content_type}"

        if self.config.allowed_types and content_type not in self.config.allowed_types:
            return False, f"File type not allowed: {content_type}"

        return True, ""

    def upload(
        self,
        filename: str,
        data: BinaryIO,
        content_type: Optional[str] = None,
        uploaded_by: Optional[str] = None,
        tags: List[str] = None,
        metadata: Dict[str, Any] = None
    ) -> Tuple[Optional[FileMetadata], Optional[str]]:
        """Upload a file."""
        # Detect content type
        if not content_type:
            content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"

        # Get size
        data.seek(0, 2)
        size = data.tell()
        data.seek(0)

        # Validate
        valid, error = self._validate_upload(filename, content_type, size)
        if not valid:
            return None, error

        # Calculate checksum
        checksum = self._calculate_checksum(data)

        # Generate ID
        file_id = str(uuid.uuid4())

        # Store file
        storage_path = self.storage.store(file_id, data)

        # Create metadata
        file_metadata = FileMetadata(
            id=file_id,
            filename=filename,
            content_type=content_type,
            size=size,
            checksum=checksum,
            status=FileStatus.UPLOADED,
            storage_path=storage_path,
            uploaded_by=uploaded_by,
            tags=tags or [],
            custom_metadata=metadata or {}
        )

        self.store.save(file_metadata)
        logger.info(f"Uploaded file: {filename} ({file_id})")

        return file_metadata, None

    def download(self, file_id: str) -> Optional[BinaryIO]:
        """Download a file."""
        metadata = self.store.get(file_id)
        if not metadata or not metadata.storage_path:
            return None

        if not self.storage.exists(metadata.storage_path):
            return None

        return self.storage.retrieve(metadata.storage_path)

    def get_url(self, file_id: str, expires: int = 3600) -> Optional[str]:
        """Get download URL for file."""
        metadata = self.store.get(file_id)
        if not metadata or not metadata.storage_path:
            return None

        return self.storage.get_url(metadata.storage_path, expires)

    def delete(self, file_id: str) -> bool:
        """Delete a file."""
        metadata = self.store.get(file_id)
        if not metadata:
            return False

        if metadata.storage_path:
            self.storage.delete(metadata.storage_path)

        metadata.status = FileStatus.DELETED
        self.store.save(metadata)

        logger.info(f"Deleted file: {file_id}")
        return True

    def get_metadata(self, file_id: str) -> Optional[FileMetadata]:
        """Get file metadata."""
        return self.store.get(file_id)

    def update_metadata(
        self,
        file_id: str,
        tags: Optional[List[str]] = None,
        custom_metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[FileMetadata]:
        """Update file metadata."""
        metadata = self.store.get(file_id)
        if not metadata:
            return None

        if tags is not None:
            metadata.tags = tags
        if custom_metadata is not None:
            metadata.custom_metadata.update(custom_metadata)

        self.store.save(metadata)
        return metadata

    def list_files(self, **kwargs) -> List[Dict[str, Any]]:
        """List files."""
        files = self.store.list_files(**kwargs)
        return [f.to_dict() for f in files]

    def copy(self, file_id: str, new_filename: Optional[str] = None) -> Optional[FileMetadata]:
        """Copy a file."""
        source = self.store.get(file_id)
        if not source:
            return None

        data = self.download(file_id)
        if not data:
            return None

        new_meta, _ = self.upload(
            filename=new_filename or source.filename,
            data=data,
            content_type=source.content_type,
            tags=source.tags.copy()
        )

        return new_meta


# Example usage
def example_usage():
    """Example file management usage."""
    import io

    manager = FileManager()

    # Upload file
    content = b"Hello, BlackRoad!"
    file_data = io.BytesIO(content)
    
    metadata, error = manager.upload(
        filename="hello.txt",
        data=file_data,
        uploaded_by="user-123",
        tags=["test", "hello"]
    )

    if metadata:
        print(f"Uploaded: {metadata.id}")
        print(f"Checksum: {metadata.checksum}")

        # Download
        downloaded = manager.download(metadata.id)
        if downloaded:
            print(f"Downloaded content: {downloaded.read()}")

        # Get URL
        url = manager.get_url(metadata.id)
        print(f"URL: {url}")

        # List files
        files = manager.list_files(tags=["test"])
        print(f"Files with 'test' tag: {len(files)}")

        # Delete
        manager.delete(metadata.id)
        print("File deleted")
    else:
        print(f"Error: {error}")
