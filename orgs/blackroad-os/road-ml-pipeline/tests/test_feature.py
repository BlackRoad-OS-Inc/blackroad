"""Tests for feature module.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import pytest

from mlpipeline_core.feature import FeatureStore, Feature, FeatureView, FeatureGroup
from mlpipeline_core.feature.store import FeatureType, FeatureVector


class TestFeatureStore:
    """Test FeatureStore class."""

    def test_create_store(self):
        """Test store creation."""
        store = FeatureStore(project="test")
        assert store.project == "test"

    def test_register_feature(self):
        """Test feature registration."""
        store = FeatureStore()
        feature = Feature(
            name="user_age",
            dtype=FeatureType.INT,
            description="User age in years",
        )

        store.register_feature(feature)
        retrieved = store.get_feature("user_age")

        assert retrieved is not None
        assert retrieved.name == "user_age"
        assert retrieved.dtype == FeatureType.INT

    def test_register_feature_view(self):
        """Test feature view registration."""
        store = FeatureStore()
        view = FeatureView(
            name="user_features",
            features=[
                Feature(name="age", dtype=FeatureType.INT),
                Feature(name="income", dtype=FeatureType.FLOAT),
            ],
            source="users_table",
            entity_columns=["user_id"],
        )

        store.register_feature_view(view)
        retrieved = store.get_feature_view("user_features")

        assert retrieved is not None
        assert len(retrieved.features) == 2
        assert "age" in retrieved.get_feature_names()

    def test_ingest_features(self):
        """Test feature ingestion."""
        store = FeatureStore()
        view = FeatureView(
            name="user_features",
            features=[
                Feature(name="age", dtype=FeatureType.INT),
            ],
            source="users_table",
            entity_columns=["user_id"],
        )
        store.register_feature_view(view)

        data = [
            {"user_id": 1, "age": 25},
            {"user_id": 2, "age": 30},
        ]
        store.ingest("user_features", data)

        vectors = store.get_online_features(
            ["user_features:age"],
            [{"user_id": 1}],
        )

        assert len(vectors) == 1
        assert vectors[0].get("age") == 25

    def test_materialize(self):
        """Test feature materialization."""
        store = FeatureStore()
        view = FeatureView(
            name="user_features",
            features=[
                Feature(name="score", dtype=FeatureType.FLOAT),
            ],
            source="scores_table",
            entity_columns=["user_id"],
        )
        store.register_feature_view(view)

        store.ingest(
            "user_features",
            [{"user_id": 1, "score": 0.95}],
            online=False,
            offline=True,
        )

        count = store.materialize("user_features")
        assert count == 1


class TestFeature:
    """Test Feature class."""

    def test_feature_validation(self):
        """Test feature validation."""
        feature = Feature(
            name="age",
            dtype=FeatureType.INT,
            validator=lambda x: x >= 0 and x <= 150,
        )

        assert feature.validate(25)
        assert not feature.validate(-1)
        assert not feature.validate(200)

    def test_feature_transform(self):
        """Test feature transformation."""
        feature = Feature(
            name="normalized_score",
            dtype=FeatureType.FLOAT,
            transform=lambda x: x / 100.0,
        )

        result = feature.apply_transform(85)
        assert result == 0.85

    def test_nullable_feature(self):
        """Test nullable feature."""
        feature = Feature(
            name="optional",
            dtype=FeatureType.STRING,
            nullable=True,
        )

        assert feature.validate(None)

        feature_required = Feature(
            name="required",
            dtype=FeatureType.STRING,
            nullable=False,
        )

        assert not feature_required.validate(None)


class TestFeatureVector:
    """Test FeatureVector class."""

    def test_vector_creation(self):
        """Test vector creation."""
        vector = FeatureVector(
            feature_names=["a", "b", "c"],
            values=[1.0, 2.0, 3.0],
        )

        assert vector.get("a") == 1.0
        assert vector.get("b") == 2.0
        assert vector.get("d") is None

    def test_to_dict(self):
        """Test conversion to dict."""
        vector = FeatureVector(
            feature_names=["x", "y"],
            values=[10, 20],
        )

        d = vector.to_dict()
        assert d == {"x": 10, "y": 20}

    def test_to_array(self):
        """Test conversion to array."""
        vector = FeatureVector(
            feature_names=["a", "b"],
            values=[1.0, 2.0],
        )

        arr = vector.to_array()
        assert list(arr) == [1.0, 2.0]
