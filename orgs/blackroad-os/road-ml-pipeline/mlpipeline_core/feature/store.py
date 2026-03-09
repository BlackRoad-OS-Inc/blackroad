"""RoadML Feature Store - Feature Management.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import hashlib
import logging
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union

import numpy as np

logger = logging.getLogger(__name__)


class FeatureType(Enum):
    """Feature data types."""

    INT = auto()
    FLOAT = auto()
    STRING = auto()
    BOOL = auto()
    TIMESTAMP = auto()
    ARRAY = auto()
    EMBEDDING = auto()


class AggregationType(Enum):
    """Aggregation types for time-windowed features."""

    SUM = auto()
    AVG = auto()
    MIN = auto()
    MAX = auto()
    COUNT = auto()
    STDDEV = auto()
    PERCENTILE = auto()
    DISTINCT_COUNT = auto()


@dataclass
class Feature:
    """A single feature definition.

    Attributes:
        name: Feature name
        dtype: Feature data type
        description: Feature description
        default: Default value if missing
        validator: Optional validation function
        transform: Optional transformation function
    """

    name: str
    dtype: FeatureType = FeatureType.FLOAT
    description: str = ""
    default: Any = None
    nullable: bool = True
    validator: Optional[Callable[[Any], bool]] = None
    transform: Optional[Callable[[Any], Any]] = None
    tags: Dict[str, str] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)

    def validate(self, value: Any) -> bool:
        """Validate feature value."""
        if value is None:
            return self.nullable

        if self.validator:
            return self.validator(value)

        return True

    def apply_transform(self, value: Any) -> Any:
        """Apply transformation to value."""
        if value is None:
            return self.default

        if self.transform:
            return self.transform(value)

        return value


@dataclass
class FeatureView:
    """A view of features from a source.

    Feature views define how to retrieve features from a data source
    and can include time-based windowing for point-in-time correctness.
    """

    name: str
    features: List[Feature]
    source: str
    entity_columns: List[str]
    timestamp_column: Optional[str] = None
    ttl: Optional[timedelta] = None
    online: bool = True
    offline: bool = True
    description: str = ""
    tags: Dict[str, str] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)

    def get_feature_names(self) -> List[str]:
        """Get list of feature names."""
        return [f.name for f in self.features]


@dataclass
class FeatureGroup:
    """Group of related features.

    Feature groups organize features by domain or entity type.
    """

    name: str
    features: List[Feature]
    entity_columns: List[str]
    description: str = ""
    owner: str = ""
    tags: Dict[str, str] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.now)


@dataclass
class OnDemandFeature:
    """Feature computed on-demand from request data."""

    name: str
    dtype: FeatureType
    compute_fn: Callable[[Dict[str, Any]], Any]
    dependencies: List[str] = field(default_factory=list)
    description: str = ""


@dataclass
class WindowedAggregation:
    """Time-windowed feature aggregation."""

    feature_name: str
    aggregation: AggregationType
    window_size: timedelta
    slide_interval: Optional[timedelta] = None
    fill_value: Any = None


class FeatureVector:
    """A vector of feature values for serving."""

    def __init__(
        self,
        feature_names: List[str],
        values: List[Any],
        entity_key: Optional[Dict[str, Any]] = None,
        timestamp: Optional[datetime] = None,
    ):
        self.feature_names = feature_names
        self.values = values
        self.entity_key = entity_key or {}
        self.timestamp = timestamp or datetime.now()
        self._feature_map = dict(zip(feature_names, values))

    def get(self, feature_name: str, default: Any = None) -> Any:
        """Get feature value by name."""
        return self._feature_map.get(feature_name, default)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return self._feature_map.copy()

    def to_array(self) -> np.ndarray:
        """Convert to numpy array."""
        return np.array(self.values)


class OnlineStore:
    """Online feature store for low-latency serving.

    Features:
    - In-memory caching
    - TTL-based expiration
    - Batch retrieval
    """

    def __init__(self, ttl_seconds: int = 3600):
        self.ttl_seconds = ttl_seconds
        self._store: Dict[str, Tuple[Any, float]] = {}
        self._lock = threading.RLock()

    def _make_key(self, entity_key: Dict[str, Any], feature_view: str) -> str:
        """Create storage key from entity key."""
        key_str = f"{feature_view}:" + ":".join(
            f"{k}={v}" for k, v in sorted(entity_key.items())
        )
        return hashlib.md5(key_str.encode()).hexdigest()

    def put(
        self,
        entity_key: Dict[str, Any],
        feature_view: str,
        values: Dict[str, Any],
    ) -> None:
        """Store feature values."""
        key = self._make_key(entity_key, feature_view)
        with self._lock:
            self._store[key] = (values, time.time())

    def get(
        self,
        entity_key: Dict[str, Any],
        feature_view: str,
    ) -> Optional[Dict[str, Any]]:
        """Retrieve feature values."""
        key = self._make_key(entity_key, feature_view)
        with self._lock:
            if key not in self._store:
                return None

            values, timestamp = self._store[key]
            if time.time() - timestamp > self.ttl_seconds:
                del self._store[key]
                return None

            return values

    def delete(self, entity_key: Dict[str, Any], feature_view: str) -> None:
        """Delete feature values."""
        key = self._make_key(entity_key, feature_view)
        with self._lock:
            self._store.pop(key, None)

    def clear(self) -> None:
        """Clear all stored features."""
        with self._lock:
            self._store.clear()


class OfflineStore:
    """Offline feature store for batch processing.

    Features:
    - Historical feature retrieval
    - Point-in-time correctness
    - Batch training data generation
    """

    def __init__(self, storage_path: Optional[str] = None):
        self.storage_path = storage_path
        self._data: Dict[str, List[Dict[str, Any]]] = {}
        self._lock = threading.RLock()

    def write(
        self,
        feature_view: str,
        data: List[Dict[str, Any]],
        timestamp_column: str = "timestamp",
    ) -> None:
        """Write feature data to offline store."""
        with self._lock:
            if feature_view not in self._data:
                self._data[feature_view] = []
            self._data[feature_view].extend(data)

    def read(
        self,
        feature_view: str,
        entity_keys: Optional[List[Dict[str, Any]]] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
    ) -> List[Dict[str, Any]]:
        """Read feature data from offline store."""
        with self._lock:
            data = self._data.get(feature_view, [])

            if entity_keys:
                key_set = {
                    tuple(sorted(k.items())) for k in entity_keys
                }
                data = [
                    row for row in data
                    if any(
                        all(row.get(k) == v for k, v in key.items())
                        for key in entity_keys
                    )
                ]

            return data

    def get_historical_features(
        self,
        feature_view: str,
        entity_df: List[Dict[str, Any]],
        feature_names: List[str],
        timestamp_column: str = "timestamp",
    ) -> List[Dict[str, Any]]:
        """Get historical features with point-in-time correctness.

        For each entity in entity_df, retrieves the latest feature values
        that were available at the entity's timestamp.
        """
        result = []
        data = self._data.get(feature_view, [])

        for entity_row in entity_df:
            entity_timestamp = entity_row.get(timestamp_column)
            best_match = None

            for row in data:
                row_timestamp = row.get(timestamp_column)
                if row_timestamp and entity_timestamp:
                    if row_timestamp <= entity_timestamp:
                        if best_match is None or row_timestamp > best_match.get(timestamp_column):
                            best_match = row

            if best_match:
                feature_row = entity_row.copy()
                for name in feature_names:
                    feature_row[name] = best_match.get(name)
                result.append(feature_row)

        return result


class FeatureStore:
    """Enterprise Feature Store.

    Features:
    - Feature registration and discovery
    - Online/offline serving
    - Point-in-time correctness
    - Feature versioning
    - Materialization
    - Feature statistics

    Architecture:
    ┌─────────────────────────────────────────────────────────────┐
    │                      Feature Store                           │
    ├─────────────────────────────────────────────────────────────┤
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
    │  │  Registry   │  │   Online    │  │      Offline        │  │
    │  │             │  │   Store     │  │      Store          │  │
    │  │ - Features  │  │             │  │                     │  │
    │  │ - Views     │  │ - Cache     │  │ - Historical Data   │  │
    │  │ - Groups    │  │ - TTL       │  │ - Point-in-time     │  │
    │  └─────────────┘  └─────────────┘  └─────────────────────┘  │
    ├─────────────────────────────────────────────────────────────┤
    │  ┌─────────────────────────────────────────────────────────┐│
    │  │                Materialization Engine                    ││
    │  │  - Batch materialization                                 ││
    │  │  - Streaming materialization                             ││
    │  │  - On-demand computation                                 ││
    │  └─────────────────────────────────────────────────────────┘│
    └─────────────────────────────────────────────────────────────┘
    """

    def __init__(
        self,
        project: str = "default",
        online_ttl_seconds: int = 3600,
        offline_storage_path: Optional[str] = None,
    ):
        self.project = project
        self._features: Dict[str, Feature] = {}
        self._feature_views: Dict[str, FeatureView] = {}
        self._feature_groups: Dict[str, FeatureGroup] = {}
        self._on_demand_features: Dict[str, OnDemandFeature] = {}

        self._online_store = OnlineStore(ttl_seconds=online_ttl_seconds)
        self._offline_store = OfflineStore(storage_path=offline_storage_path)

        self._lock = threading.RLock()
        self._statistics: Dict[str, Dict[str, Any]] = {}

        logger.info(f"FeatureStore initialized for project: {project}")

    def register_feature(self, feature: Feature) -> None:
        """Register a feature definition."""
        with self._lock:
            self._features[feature.name] = feature
            logger.info(f"Registered feature: {feature.name}")

    def register_feature_view(self, feature_view: FeatureView) -> None:
        """Register a feature view."""
        with self._lock:
            self._feature_views[feature_view.name] = feature_view

            for feature in feature_view.features:
                if feature.name not in self._features:
                    self._features[feature.name] = feature

            logger.info(f"Registered feature view: {feature_view.name}")

    def register_feature_group(self, feature_group: FeatureGroup) -> None:
        """Register a feature group."""
        with self._lock:
            self._feature_groups[feature_group.name] = feature_group

            for feature in feature_group.features:
                if feature.name not in self._features:
                    self._features[feature.name] = feature

            logger.info(f"Registered feature group: {feature_group.name}")

    def register_on_demand_feature(self, feature: OnDemandFeature) -> None:
        """Register an on-demand feature."""
        with self._lock:
            self._on_demand_features[feature.name] = feature
            logger.info(f"Registered on-demand feature: {feature.name}")

    def get_feature(self, name: str) -> Optional[Feature]:
        """Get feature definition by name."""
        return self._features.get(name)

    def get_feature_view(self, name: str) -> Optional[FeatureView]:
        """Get feature view by name."""
        return self._feature_views.get(name)

    def list_features(self) -> List[str]:
        """List all registered features."""
        return list(self._features.keys())

    def list_feature_views(self) -> List[str]:
        """List all feature views."""
        return list(self._feature_views.keys())

    def get_online_features(
        self,
        feature_refs: List[str],
        entity_keys: List[Dict[str, Any]],
    ) -> List[FeatureVector]:
        """Get features from online store.

        Args:
            feature_refs: List of feature references (view:feature or feature)
            entity_keys: List of entity key dictionaries

        Returns:
            List of FeatureVectors for each entity
        """
        results = []

        for entity_key in entity_keys:
            feature_values = []
            feature_names = []

            for ref in feature_refs:
                if ":" in ref:
                    view_name, feature_name = ref.split(":", 1)
                else:
                    view_name = self._find_view_for_feature(ref)
                    feature_name = ref

                if view_name:
                    stored = self._online_store.get(entity_key, view_name)
                    if stored:
                        value = stored.get(feature_name)
                    else:
                        value = None
                else:
                    value = None

                feature_names.append(feature_name)
                feature_values.append(value)

            results.append(FeatureVector(
                feature_names=feature_names,
                values=feature_values,
                entity_key=entity_key,
            ))

        return results

    def _find_view_for_feature(self, feature_name: str) -> Optional[str]:
        """Find feature view containing a feature."""
        for view_name, view in self._feature_views.items():
            if feature_name in view.get_feature_names():
                return view_name
        return None

    def materialize(
        self,
        feature_view: str,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
    ) -> int:
        """Materialize features to online store.

        Reads from offline store and writes to online store
        for low-latency serving.

        Returns:
            Number of rows materialized
        """
        view = self._feature_views.get(feature_view)
        if not view:
            raise ValueError(f"Feature view not found: {feature_view}")

        data = self._offline_store.read(
            feature_view,
            start_time=start_time,
            end_time=end_time,
        )

        count = 0
        for row in data:
            entity_key = {col: row[col] for col in view.entity_columns if col in row}
            feature_values = {
                f.name: row.get(f.name)
                for f in view.features
                if f.name in row
            }

            self._online_store.put(entity_key, feature_view, feature_values)
            count += 1

        logger.info(f"Materialized {count} rows for {feature_view}")
        return count

    def get_historical_features(
        self,
        feature_refs: List[str],
        entity_df: List[Dict[str, Any]],
        timestamp_column: str = "timestamp",
    ) -> List[Dict[str, Any]]:
        """Get historical features with point-in-time correctness.

        Args:
            feature_refs: List of feature references
            entity_df: List of entity records with timestamps
            timestamp_column: Name of timestamp column

        Returns:
            Entity records enriched with historical features
        """
        view_features: Dict[str, List[str]] = {}
        for ref in feature_refs:
            if ":" in ref:
                view_name, feature_name = ref.split(":", 1)
            else:
                view_name = self._find_view_for_feature(ref)
                feature_name = ref

            if view_name:
                if view_name not in view_features:
                    view_features[view_name] = []
                view_features[view_name].append(feature_name)

        result = entity_df.copy()

        for view_name, feature_names in view_features.items():
            result = self._offline_store.get_historical_features(
                view_name,
                result,
                feature_names,
                timestamp_column,
            )

        return result

    def ingest(
        self,
        feature_view: str,
        data: List[Dict[str, Any]],
        online: bool = True,
        offline: bool = True,
    ) -> None:
        """Ingest feature data.

        Args:
            feature_view: Target feature view
            data: Feature data to ingest
            online: Whether to write to online store
            offline: Whether to write to offline store
        """
        view = self._feature_views.get(feature_view)
        if not view:
            raise ValueError(f"Feature view not found: {feature_view}")

        for row in data:
            for feature in view.features:
                if feature.name in row:
                    value = row[feature.name]
                    if not feature.validate(value):
                        raise ValueError(
                            f"Validation failed for {feature.name}: {value}"
                        )
                    row[feature.name] = feature.apply_transform(value)

        if offline:
            self._offline_store.write(feature_view, data)

        if online:
            for row in data:
                entity_key = {
                    col: row[col]
                    for col in view.entity_columns
                    if col in row
                }
                feature_values = {
                    f.name: row.get(f.name)
                    for f in view.features
                }
                self._online_store.put(entity_key, feature_view, feature_values)

        logger.info(f"Ingested {len(data)} rows to {feature_view}")

    def compute_statistics(self, feature_view: str) -> Dict[str, Dict[str, Any]]:
        """Compute feature statistics.

        Returns statistics like mean, std, min, max for numerical features
        and cardinality for categorical features.
        """
        data = self._offline_store.read(feature_view)
        view = self._feature_views.get(feature_view)
        if not view:
            return {}

        stats = {}
        for feature in view.features:
            values = [row.get(feature.name) for row in data if row.get(feature.name) is not None]

            if not values:
                continue

            if feature.dtype in (FeatureType.INT, FeatureType.FLOAT):
                numeric_values = [float(v) for v in values]
                stats[feature.name] = {
                    "count": len(numeric_values),
                    "mean": sum(numeric_values) / len(numeric_values),
                    "min": min(numeric_values),
                    "max": max(numeric_values),
                    "null_count": len(data) - len(values),
                }
            elif feature.dtype == FeatureType.STRING:
                stats[feature.name] = {
                    "count": len(values),
                    "cardinality": len(set(values)),
                    "null_count": len(data) - len(values),
                }

        self._statistics[feature_view] = stats
        return stats

    def get_feature_freshness(self, feature_view: str) -> Optional[timedelta]:
        """Get time since last feature update."""
        view = self._feature_views.get(feature_view)
        if not view:
            return None

        data = self._offline_store.read(feature_view)
        if not data:
            return None

        if view.timestamp_column:
            timestamps = [
                row.get(view.timestamp_column)
                for row in data
                if row.get(view.timestamp_column)
            ]
            if timestamps:
                latest = max(timestamps)
                if isinstance(latest, datetime):
                    return datetime.now() - latest

        return None


__all__ = [
    "FeatureStore",
    "Feature",
    "FeatureView",
    "FeatureGroup",
    "FeatureType",
    "FeatureVector",
    "OnDemandFeature",
    "WindowedAggregation",
    "AggregationType",
    "OnlineStore",
    "OfflineStore",
]
