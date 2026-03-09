"""RoadSearch Document Store - Stored Document Management.

The document store manages the storage and retrieval of original
document content for display in search results.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import gzip
import hashlib
import json
import logging
import os
import pickle
import struct
import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, BinaryIO, Dict, Generator, List, Optional, Set, Tuple, Union

logger = logging.getLogger(__name__)


class CompressionType(Enum):
    """Document compression types."""

    NONE = auto()
    GZIP = auto()
    LZ4 = auto()
    ZSTD = auto()


class StorageStatus(Enum):
    """Document storage status."""

    STORED = auto()
    DELETED = auto()
    COMPRESSED = auto()
    EXTERNAL = auto()  # Stored externally


@dataclass
class DocumentMetadata:
    """Metadata for stored document.

    Attributes:
        doc_id: Document ID
        version: Document version
        size_bytes: Original size in bytes
        compressed_size: Compressed size (if applicable)
        checksum: Content checksum
        created_at: Creation timestamp
        updated_at: Last update timestamp
        status: Storage status
        compression: Compression type used
        fields_stored: List of stored field names
        source: Document source identifier
        parent_id: Parent document ID (for nested docs)
    """

    doc_id: str
    version: int = 1
    size_bytes: int = 0
    compressed_size: int = 0
    checksum: str = ""
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    status: StorageStatus = StorageStatus.STORED
    compression: CompressionType = CompressionType.NONE
    fields_stored: List[str] = field(default_factory=list)
    source: str = ""
    parent_id: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "doc_id": self.doc_id,
            "version": self.version,
            "size_bytes": self.size_bytes,
            "compressed_size": self.compressed_size,
            "checksum": self.checksum,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "status": self.status.name,
            "compression": self.compression.name,
            "fields_stored": self.fields_stored,
            "source": self.source,
            "parent_id": self.parent_id,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "DocumentMetadata":
        """Create from dictionary."""
        return cls(
            doc_id=data["doc_id"],
            version=data.get("version", 1),
            size_bytes=data.get("size_bytes", 0),
            compressed_size=data.get("compressed_size", 0),
            checksum=data.get("checksum", ""),
            created_at=datetime.fromisoformat(data["created_at"]) if "created_at" in data else datetime.now(),
            updated_at=datetime.fromisoformat(data["updated_at"]) if "updated_at" in data else datetime.now(),
            status=StorageStatus[data.get("status", "STORED")],
            compression=CompressionType[data.get("compression", "NONE")],
            fields_stored=data.get("fields_stored", []),
            source=data.get("source", ""),
            parent_id=data.get("parent_id"),
        )


@dataclass
class StoredDocument:
    """A document stored in the document store.

    Attributes:
        doc_id: Document identifier
        content: Document content/fields
        metadata: Document metadata
        vectors: Vector embeddings
    """

    doc_id: str
    content: Dict[str, Any] = field(default_factory=dict)
    metadata: DocumentMetadata = field(default_factory=lambda: DocumentMetadata(doc_id=""))
    vectors: Dict[str, List[float]] = field(default_factory=dict)

    def __post_init__(self):
        """Initialize metadata if needed."""
        if not self.metadata.doc_id:
            self.metadata = DocumentMetadata(doc_id=self.doc_id)

    def get_field(self, field_name: str, default: Any = None) -> Any:
        """Get field value.

        Args:
            field_name: Field name
            default: Default value

        Returns:
            Field value or default
        """
        return self.content.get(field_name, default)

    def set_field(self, field_name: str, value: Any) -> None:
        """Set field value.

        Args:
            field_name: Field name
            value: Field value
        """
        self.content[field_name] = value
        if field_name not in self.metadata.fields_stored:
            self.metadata.fields_stored.append(field_name)

    def get_vector(self, vector_name: str) -> Optional[List[float]]:
        """Get vector embedding.

        Args:
            vector_name: Vector field name

        Returns:
            Vector or None
        """
        return self.vectors.get(vector_name)

    def set_vector(self, vector_name: str, vector: List[float]) -> None:
        """Set vector embedding.

        Args:
            vector_name: Vector field name
            vector: Vector data
        """
        self.vectors[vector_name] = vector

    def calculate_checksum(self) -> str:
        """Calculate content checksum.

        Returns:
            MD5 checksum
        """
        content_bytes = json.dumps(self.content, sort_keys=True).encode()
        return hashlib.md5(content_bytes).hexdigest()

    def to_bytes(self, compress: bool = False) -> bytes:
        """Serialize to bytes.

        Args:
            compress: Apply gzip compression

        Returns:
            Serialized bytes
        """
        data = pickle.dumps({
            "doc_id": self.doc_id,
            "content": self.content,
            "metadata": self.metadata.to_dict(),
            "vectors": self.vectors,
        })

        if compress:
            data = gzip.compress(data)
            self.metadata.compression = CompressionType.GZIP
            self.metadata.compressed_size = len(data)

        self.metadata.size_bytes = len(data)
        return data

    @classmethod
    def from_bytes(cls, data: bytes, decompress: bool = False) -> "StoredDocument":
        """Deserialize from bytes.

        Args:
            data: Serialized bytes
            decompress: Apply gzip decompression

        Returns:
            StoredDocument instance
        """
        if decompress:
            data = gzip.decompress(data)

        obj = pickle.loads(data)
        return cls(
            doc_id=obj["doc_id"],
            content=obj["content"],
            metadata=DocumentMetadata.from_dict(obj["metadata"]),
            vectors=obj.get("vectors", {}),
        )


class DocumentStore(ABC):
    """Abstract base class for document storage.

    Implementations provide different storage backends for documents.
    """

    @abstractmethod
    def store(self, document: StoredDocument) -> bool:
        """Store a document.

        Args:
            document: Document to store

        Returns:
            True if stored successfully
        """
        pass

    @abstractmethod
    def get(self, doc_id: str) -> Optional[StoredDocument]:
        """Get a document by ID.

        Args:
            doc_id: Document ID

        Returns:
            Document or None
        """
        pass

    @abstractmethod
    def delete(self, doc_id: str) -> bool:
        """Delete a document.

        Args:
            doc_id: Document ID

        Returns:
            True if deleted
        """
        pass

    @abstractmethod
    def exists(self, doc_id: str) -> bool:
        """Check if document exists.

        Args:
            doc_id: Document ID

        Returns:
            True if exists
        """
        pass

    @abstractmethod
    def count(self) -> int:
        """Get document count.

        Returns:
            Number of documents
        """
        pass

    @abstractmethod
    def all_ids(self) -> Generator[str, None, None]:
        """Iterate over all document IDs.

        Yields:
            Document IDs
        """
        pass

    def get_fields(
        self,
        doc_id: str,
        fields: List[str],
    ) -> Optional[Dict[str, Any]]:
        """Get specific fields from document.

        Args:
            doc_id: Document ID
            fields: Field names to retrieve

        Returns:
            Field values or None
        """
        doc = self.get(doc_id)
        if not doc:
            return None
        return {f: doc.get_field(f) for f in fields if f in doc.content}

    def bulk_get(self, doc_ids: List[str]) -> Dict[str, StoredDocument]:
        """Get multiple documents.

        Args:
            doc_ids: Document IDs

        Returns:
            Dictionary of doc_id -> document
        """
        result = {}
        for doc_id in doc_ids:
            doc = self.get(doc_id)
            if doc:
                result[doc_id] = doc
        return result

    def bulk_store(
        self,
        documents: List[StoredDocument],
    ) -> Dict[str, bool]:
        """Store multiple documents.

        Args:
            documents: Documents to store

        Returns:
            Dictionary of doc_id -> success
        """
        result = {}
        for doc in documents:
            result[doc.doc_id] = self.store(doc)
        return result


class InMemoryDocumentStore(DocumentStore):
    """In-memory document store implementation.

    Fast but not persistent. Suitable for testing and small datasets.
    """

    def __init__(
        self,
        compress: bool = False,
        max_size_mb: Optional[int] = None,
    ):
        """Initialize in-memory store.

        Args:
            compress: Compress stored documents
            max_size_mb: Maximum storage size in MB
        """
        self._documents: Dict[str, StoredDocument] = {}
        self._compress = compress
        self._max_size_bytes = max_size_mb * 1024 * 1024 if max_size_mb else None
        self._current_size = 0
        self._lock = threading.RLock()

    def store(self, document: StoredDocument) -> bool:
        """Store a document."""
        with self._lock:
            # Update checksum and metadata
            document.metadata.checksum = document.calculate_checksum()
            document.metadata.updated_at = datetime.now()

            # Check size limit
            doc_size = len(document.to_bytes(self._compress))
            if self._max_size_bytes:
                # Remove old version size if exists
                if document.doc_id in self._documents:
                    old_size = self._documents[document.doc_id].metadata.size_bytes
                    self._current_size -= old_size

                if self._current_size + doc_size > self._max_size_bytes:
                    logger.warning("Document store size limit exceeded")
                    return False

            self._documents[document.doc_id] = document
            self._current_size += doc_size
            return True

    def get(self, doc_id: str) -> Optional[StoredDocument]:
        """Get a document by ID."""
        return self._documents.get(doc_id)

    def delete(self, doc_id: str) -> bool:
        """Delete a document."""
        with self._lock:
            if doc_id in self._documents:
                self._current_size -= self._documents[doc_id].metadata.size_bytes
                del self._documents[doc_id]
                return True
            return False

    def exists(self, doc_id: str) -> bool:
        """Check if document exists."""
        return doc_id in self._documents

    def count(self) -> int:
        """Get document count."""
        return len(self._documents)

    def all_ids(self) -> Generator[str, None, None]:
        """Iterate over all document IDs."""
        yield from self._documents.keys()

    def clear(self) -> None:
        """Clear all documents."""
        with self._lock:
            self._documents.clear()
            self._current_size = 0

    def size_bytes(self) -> int:
        """Get current storage size."""
        return self._current_size


class FileDocumentStore(DocumentStore):
    """File-based document store implementation.

    Persistent storage using individual files per document.
    """

    def __init__(
        self,
        directory: str,
        compress: bool = True,
        shards: int = 256,
    ):
        """Initialize file-based store.

        Args:
            directory: Storage directory
            compress: Compress stored documents
            shards: Number of shard directories
        """
        self._directory = directory
        self._compress = compress
        self._shards = shards
        self._lock = threading.RLock()
        self._metadata_cache: Dict[str, DocumentMetadata] = {}

        # Create directory structure
        os.makedirs(directory, exist_ok=True)
        for i in range(shards):
            os.makedirs(os.path.join(directory, f"{i:02x}"), exist_ok=True)

    def _get_path(self, doc_id: str) -> str:
        """Get file path for document.

        Args:
            doc_id: Document ID

        Returns:
            File path
        """
        shard = int(hashlib.md5(doc_id.encode()).hexdigest()[:2], 16) % self._shards
        return os.path.join(
            self._directory,
            f"{shard:02x}",
            f"{doc_id}.doc",
        )

    def store(self, document: StoredDocument) -> bool:
        """Store a document."""
        with self._lock:
            try:
                # Update metadata
                document.metadata.checksum = document.calculate_checksum()
                document.metadata.updated_at = datetime.now()
                document.metadata.compression = (
                    CompressionType.GZIP if self._compress else CompressionType.NONE
                )

                # Serialize and write
                path = self._get_path(document.doc_id)
                data = document.to_bytes(self._compress)

                with open(path, "wb") as f:
                    f.write(data)

                # Update metadata cache
                self._metadata_cache[document.doc_id] = document.metadata

                return True

            except Exception as e:
                logger.error(f"Failed to store document {document.doc_id}: {e}")
                return False

    def get(self, doc_id: str) -> Optional[StoredDocument]:
        """Get a document by ID."""
        path = self._get_path(doc_id)

        if not os.path.exists(path):
            return None

        try:
            with open(path, "rb") as f:
                data = f.read()

            return StoredDocument.from_bytes(data, self._compress)

        except Exception as e:
            logger.error(f"Failed to read document {doc_id}: {e}")
            return None

    def delete(self, doc_id: str) -> bool:
        """Delete a document."""
        with self._lock:
            path = self._get_path(doc_id)

            if os.path.exists(path):
                try:
                    os.remove(path)
                    self._metadata_cache.pop(doc_id, None)
                    return True
                except Exception as e:
                    logger.error(f"Failed to delete document {doc_id}: {e}")
                    return False

            return False

    def exists(self, doc_id: str) -> bool:
        """Check if document exists."""
        return os.path.exists(self._get_path(doc_id))

    def count(self) -> int:
        """Get document count."""
        count = 0
        for shard in range(self._shards):
            shard_dir = os.path.join(self._directory, f"{shard:02x}")
            if os.path.exists(shard_dir):
                count += len([f for f in os.listdir(shard_dir) if f.endswith(".doc")])
        return count

    def all_ids(self) -> Generator[str, None, None]:
        """Iterate over all document IDs."""
        for shard in range(self._shards):
            shard_dir = os.path.join(self._directory, f"{shard:02x}")
            if os.path.exists(shard_dir):
                for filename in os.listdir(shard_dir):
                    if filename.endswith(".doc"):
                        yield filename[:-4]  # Remove .doc extension

    def get_metadata(self, doc_id: str) -> Optional[DocumentMetadata]:
        """Get document metadata without loading full document.

        Args:
            doc_id: Document ID

        Returns:
            Document metadata or None
        """
        if doc_id in self._metadata_cache:
            return self._metadata_cache[doc_id]

        doc = self.get(doc_id)
        if doc:
            self._metadata_cache[doc_id] = doc.metadata
            return doc.metadata

        return None


class FieldCache:
    """Cache for frequently accessed fields.

    Provides fast access to commonly retrieved fields without
    loading full documents.
    """

    def __init__(
        self,
        max_entries: int = 10000,
        ttl_seconds: int = 300,
    ):
        """Initialize field cache.

        Args:
            max_entries: Maximum cached entries
            ttl_seconds: Cache entry TTL
        """
        self._cache: Dict[str, Tuple[Dict[str, Any], datetime]] = {}
        self._max_entries = max_entries
        self._ttl = ttl_seconds
        self._lock = threading.RLock()
        self._hits = 0
        self._misses = 0

    def get(
        self,
        doc_id: str,
        fields: List[str],
    ) -> Optional[Dict[str, Any]]:
        """Get cached fields.

        Args:
            doc_id: Document ID
            fields: Fields to retrieve

        Returns:
            Cached fields or None
        """
        with self._lock:
            if doc_id not in self._cache:
                self._misses += 1
                return None

            cached_fields, cached_at = self._cache[doc_id]

            # Check TTL
            if (datetime.now() - cached_at).seconds > self._ttl:
                del self._cache[doc_id]
                self._misses += 1
                return None

            # Check if all requested fields are cached
            result = {}
            for field in fields:
                if field in cached_fields:
                    result[field] = cached_fields[field]
                else:
                    self._misses += 1
                    return None  # Missing field

            self._hits += 1
            return result

    def put(
        self,
        doc_id: str,
        fields: Dict[str, Any],
    ) -> None:
        """Cache fields.

        Args:
            doc_id: Document ID
            fields: Fields to cache
        """
        with self._lock:
            # Evict if at capacity
            if len(self._cache) >= self._max_entries:
                # Remove oldest entry
                oldest = min(self._cache.items(), key=lambda x: x[1][1])
                del self._cache[oldest[0]]

            # Merge with existing cached fields
            if doc_id in self._cache:
                existing = self._cache[doc_id][0]
                existing.update(fields)
                self._cache[doc_id] = (existing, datetime.now())
            else:
                self._cache[doc_id] = (fields, datetime.now())

    def invalidate(self, doc_id: str) -> None:
        """Invalidate cached entry.

        Args:
            doc_id: Document ID
        """
        with self._lock:
            self._cache.pop(doc_id, None)

    def clear(self) -> None:
        """Clear all cached entries."""
        with self._lock:
            self._cache.clear()

    def stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        total = self._hits + self._misses
        hit_rate = self._hits / total if total > 0 else 0
        return {
            "entries": len(self._cache),
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": hit_rate,
        }


class CachedDocumentStore(DocumentStore):
    """Document store wrapper with field caching.

    Wraps any DocumentStore implementation and adds field caching
    for improved read performance.
    """

    def __init__(
        self,
        backend: DocumentStore,
        cache_fields: Optional[List[str]] = None,
        cache_size: int = 10000,
    ):
        """Initialize cached store.

        Args:
            backend: Backend document store
            cache_fields: Fields to cache (None = all)
            cache_size: Maximum cache size
        """
        self._backend = backend
        self._cache_fields = cache_fields
        self._cache = FieldCache(max_entries=cache_size)

    def store(self, document: StoredDocument) -> bool:
        """Store a document."""
        success = self._backend.store(document)

        if success:
            # Update cache
            if self._cache_fields:
                fields = {
                    f: document.get_field(f)
                    for f in self._cache_fields
                    if f in document.content
                }
            else:
                fields = document.content.copy()

            self._cache.put(document.doc_id, fields)

        return success

    def get(self, doc_id: str) -> Optional[StoredDocument]:
        """Get a document by ID."""
        return self._backend.get(doc_id)

    def delete(self, doc_id: str) -> bool:
        """Delete a document."""
        success = self._backend.delete(doc_id)
        if success:
            self._cache.invalidate(doc_id)
        return success

    def exists(self, doc_id: str) -> bool:
        """Check if document exists."""
        return self._backend.exists(doc_id)

    def count(self) -> int:
        """Get document count."""
        return self._backend.count()

    def all_ids(self) -> Generator[str, None, None]:
        """Iterate over all document IDs."""
        return self._backend.all_ids()

    def get_fields(
        self,
        doc_id: str,
        fields: List[str],
    ) -> Optional[Dict[str, Any]]:
        """Get specific fields, using cache if available."""
        # Try cache first
        cached = self._cache.get(doc_id, fields)
        if cached is not None:
            return cached

        # Fall back to backend
        result = self._backend.get_fields(doc_id, fields)

        # Update cache
        if result:
            self._cache.put(doc_id, result)

        return result

    def cache_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        return self._cache.stats()


__all__ = [
    "DocumentStore",
    "StoredDocument",
    "DocumentMetadata",
    "InMemoryDocumentStore",
    "FileDocumentStore",
    "CachedDocumentStore",
    "FieldCache",
    "CompressionType",
    "StorageStatus",
]
