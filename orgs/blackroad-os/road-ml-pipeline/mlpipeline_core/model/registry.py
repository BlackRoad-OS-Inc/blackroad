"""RoadML Model Registry - Model Version Management.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import logging
import pickle
import threading
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class ModelStage(Enum):
    """Model deployment stage."""

    NONE = auto()
    STAGING = auto()
    PRODUCTION = auto()
    ARCHIVED = auto()


@dataclass
class ModelVersion:
    """A model version.

    Attributes:
        version: Version string
        model_name: Model name
        stage: Deployment stage
        created_at: Creation time
        metrics: Model metrics
        parameters: Training parameters
        tags: Version tags
        description: Version description
    """

    version: str
    model_name: str
    stage: ModelStage = ModelStage.NONE
    created_at: datetime = field(default_factory=datetime.now)
    metrics: Dict[str, float] = field(default_factory=dict)
    parameters: Dict[str, Any] = field(default_factory=dict)
    tags: Dict[str, str] = field(default_factory=dict)
    description: str = ""
    artifact_path: Optional[str] = None


class ModelRegistry:
    """Model registry for version and lifecycle management.

    Features:
    - Model versioning
    - Stage transitions
    - Metrics tracking
    - Artifact storage
    - Model lineage

    Example:
        registry = ModelRegistry()

        # Register model
        registry.register("my-model", model,
            metrics={"accuracy": 0.95, "f1": 0.93},
            parameters={"lr": 0.01},
        )

        # Promote to production
        registry.promote("my-model", "1", ModelStage.PRODUCTION)

        # Load production model
        model = registry.load("my-model", stage=ModelStage.PRODUCTION)
    """

    def __init__(self, storage_path: Optional[str] = None):
        """Initialize registry.

        Args:
            storage_path: Path for artifact storage
        """
        self.storage_path = Path(storage_path) if storage_path else Path("./mlmodels")
        self._models: Dict[str, Dict[str, ModelVersion]] = {}
        self._artifacts: Dict[str, Any] = {}
        self._lock = threading.RLock()

    def register(
        self,
        name: str,
        model: Any,
        metrics: Optional[Dict[str, float]] = None,
        parameters: Optional[Dict[str, Any]] = None,
        tags: Optional[Dict[str, str]] = None,
        description: str = "",
    ) -> ModelVersion:
        """Register a new model version.

        Args:
            name: Model name
            model: Model object
            metrics: Model metrics
            parameters: Training parameters
            tags: Model tags
            description: Version description

        Returns:
            ModelVersion
        """
        with self._lock:
            if name not in self._models:
                self._models[name] = {}

            # Generate version
            version = str(len(self._models[name]) + 1)

            # Store artifact
            artifact_key = f"{name}/{version}"
            self._artifacts[artifact_key] = model

            model_version = ModelVersion(
                version=version,
                model_name=name,
                metrics=metrics or {},
                parameters=parameters or {},
                tags=tags or {},
                description=description,
                artifact_path=artifact_key,
            )

            self._models[name][version] = model_version

            logger.info(f"Registered model {name} version {version}")
            return model_version

    def get_version(self, name: str, version: str) -> Optional[ModelVersion]:
        """Get model version.

        Args:
            name: Model name
            version: Version string

        Returns:
            ModelVersion or None
        """
        if name in self._models:
            return self._models[name].get(version)
        return None

    def get_latest_version(self, name: str) -> Optional[ModelVersion]:
        """Get latest model version.

        Args:
            name: Model name

        Returns:
            Latest ModelVersion or None
        """
        if name not in self._models:
            return None

        versions = self._models[name]
        if not versions:
            return None

        latest = max(versions.keys(), key=lambda v: int(v))
        return versions[latest]

    def get_production_version(self, name: str) -> Optional[ModelVersion]:
        """Get production model version.

        Args:
            name: Model name

        Returns:
            Production ModelVersion or None
        """
        if name not in self._models:
            return None

        for version in self._models[name].values():
            if version.stage == ModelStage.PRODUCTION:
                return version

        return None

    def list_versions(self, name: str) -> List[ModelVersion]:
        """List all versions of a model.

        Args:
            name: Model name

        Returns:
            List of ModelVersion
        """
        if name not in self._models:
            return []
        return list(self._models[name].values())

    def list_models(self) -> List[str]:
        """List all registered models.

        Returns:
            List of model names
        """
        return list(self._models.keys())

    def promote(self, name: str, version: str, stage: ModelStage) -> bool:
        """Promote model version to stage.

        Args:
            name: Model name
            version: Version string
            stage: Target stage

        Returns:
            True if successful
        """
        model_version = self.get_version(name, version)
        if model_version is None:
            return False

        with self._lock:
            # Demote current production if promoting to production
            if stage == ModelStage.PRODUCTION:
                current_prod = self.get_production_version(name)
                if current_prod and current_prod.version != version:
                    current_prod.stage = ModelStage.ARCHIVED

            model_version.stage = stage
            logger.info(f"Promoted {name}/{version} to {stage.name}")

        return True

    def load(
        self,
        name: str,
        version: Optional[str] = None,
        stage: Optional[ModelStage] = None,
    ) -> Any:
        """Load model artifact.

        Args:
            name: Model name
            version: Version string (optional)
            stage: Stage to load from (optional)

        Returns:
            Model object

        Raises:
            ValueError: If model not found
        """
        model_version = None

        if version:
            model_version = self.get_version(name, version)
        elif stage == ModelStage.PRODUCTION:
            model_version = self.get_production_version(name)
        else:
            model_version = self.get_latest_version(name)

        if model_version is None:
            raise ValueError(f"Model {name} not found")

        artifact_key = model_version.artifact_path
        if artifact_key not in self._artifacts:
            raise ValueError(f"Artifact not found for {name}/{model_version.version}")

        return self._artifacts[artifact_key]

    def delete_version(self, name: str, version: str) -> bool:
        """Delete model version.

        Args:
            name: Model name
            version: Version string

        Returns:
            True if deleted
        """
        with self._lock:
            if name in self._models and version in self._models[name]:
                model_version = self._models[name][version]

                # Remove artifact
                if model_version.artifact_path in self._artifacts:
                    del self._artifacts[model_version.artifact_path]

                del self._models[name][version]
                return True

        return False

    def update_metrics(
        self,
        name: str,
        version: str,
        metrics: Dict[str, float],
    ) -> bool:
        """Update version metrics.

        Args:
            name: Model name
            version: Version string
            metrics: Metrics to add/update

        Returns:
            True if successful
        """
        model_version = self.get_version(name, version)
        if model_version is None:
            return False

        model_version.metrics.update(metrics)
        return True

    def search(
        self,
        name_pattern: Optional[str] = None,
        stage: Optional[ModelStage] = None,
        min_metric: Optional[Dict[str, float]] = None,
    ) -> List[ModelVersion]:
        """Search for models.

        Args:
            name_pattern: Name pattern to match
            stage: Filter by stage
            min_metric: Minimum metric values

        Returns:
            List of matching ModelVersion
        """
        results = []

        for model_name, versions in self._models.items():
            if name_pattern and name_pattern not in model_name:
                continue

            for version in versions.values():
                if stage and version.stage != stage:
                    continue

                if min_metric:
                    meets_criteria = all(
                        version.metrics.get(k, 0) >= v
                        for k, v in min_metric.items()
                    )
                    if not meets_criteria:
                        continue

                results.append(version)

        return results

    def __repr__(self) -> str:
        return f"ModelRegistry(models={len(self._models)})"


__all__ = ["ModelRegistry", "ModelVersion", "ModelStage"]
