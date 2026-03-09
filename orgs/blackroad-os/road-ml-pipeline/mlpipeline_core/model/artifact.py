"""RoadML Model Artifact - Artifact Storage.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import json
import logging
import pickle
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from pathlib import Path
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


class ArtifactType(Enum):
    """Types of model artifacts."""

    MODEL = auto()
    WEIGHTS = auto()
    CONFIG = auto()
    TOKENIZER = auto()
    PREPROCESSOR = auto()
    METRICS = auto()
    LOGS = auto()


@dataclass
class ModelArtifact:
    """A model artifact.

    Attributes:
        artifact_id: Unique identifier
        artifact_type: Type of artifact
        path: Storage path
        checksum: Content checksum
        created_at: Creation time
        metadata: Artifact metadata
    """

    artifact_id: str
    artifact_type: ArtifactType
    path: str
    checksum: str
    created_at: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)
    size_bytes: int = 0

    @classmethod
    def from_object(
        cls,
        obj: Any,
        artifact_type: ArtifactType,
        artifact_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> "ModelArtifact":
        """Create artifact from object.

        Args:
            obj: Object to store
            artifact_type: Type of artifact
            artifact_id: Optional ID
            metadata: Optional metadata

        Returns:
            ModelArtifact instance
        """
        data = pickle.dumps(obj)
        checksum = hashlib.sha256(data).hexdigest()[:16]
        artifact_id = artifact_id or checksum

        return cls(
            artifact_id=artifact_id,
            artifact_type=artifact_type,
            path="",
            checksum=checksum,
            metadata=metadata or {},
            size_bytes=len(data),
        )

    def save(self, path: str) -> None:
        """Save artifact to path."""
        self.path = path
        # Would serialize to path

    def load(self) -> Any:
        """Load artifact from path."""
        # Would deserialize from path
        return None


__all__ = ["ModelArtifact", "ArtifactType"]
