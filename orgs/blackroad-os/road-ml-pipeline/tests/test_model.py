"""Tests for model module.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import pytest
from unittest.mock import Mock

from mlpipeline_core.model import ModelRegistry, ModelVersion, ModelStage


class TestModelRegistry:
    """Test ModelRegistry class."""

    def test_create_registry(self):
        """Test registry creation."""
        registry = ModelRegistry()
        assert registry is not None

    def test_register_model(self):
        """Test model registration."""
        registry = ModelRegistry()
        model = Mock()
        model.predict = Mock(return_value=[1, 2, 3])

        version = registry.register(
            name="test-model",
            model=model,
            metrics={"accuracy": 0.95},
            parameters={"lr": 0.01},
        )

        assert version.name == "test-model"
        assert version.version == "1"
        assert version.stage == ModelStage.NONE
        assert version.metrics["accuracy"] == 0.95

    def test_get_model(self):
        """Test model retrieval."""
        registry = ModelRegistry()
        model = Mock()

        registry.register(name="test-model", model=model)
        loaded = registry.load("test-model")

        assert loaded is model

    def test_promote_model(self):
        """Test model promotion."""
        registry = ModelRegistry()
        model = Mock()

        registry.register(name="test-model", model=model)
        success = registry.promote("test-model", "1", ModelStage.STAGING)

        assert success
        version = registry.get_version("test-model", "1")
        assert version.stage == ModelStage.STAGING

    def test_promote_to_production(self):
        """Test promoting to production."""
        registry = ModelRegistry()
        model1 = Mock()
        model2 = Mock()

        registry.register(name="test-model", model=model1)
        registry.register(name="test-model", model=model2)

        registry.promote("test-model", "1", ModelStage.PRODUCTION)
        registry.promote("test-model", "2", ModelStage.PRODUCTION)

        v1 = registry.get_version("test-model", "1")
        v2 = registry.get_version("test-model", "2")

        assert v1.stage == ModelStage.ARCHIVED
        assert v2.stage == ModelStage.PRODUCTION

    def test_list_models(self):
        """Test listing models."""
        registry = ModelRegistry()
        registry.register(name="model-a", model=Mock())
        registry.register(name="model-b", model=Mock())

        models = registry.list_models()
        assert "model-a" in models
        assert "model-b" in models

    def test_get_latest_version(self):
        """Test getting latest version."""
        registry = ModelRegistry()
        registry.register(name="test-model", model=Mock())
        registry.register(name="test-model", model=Mock())
        registry.register(name="test-model", model=Mock())

        latest = registry.get_latest_version("test-model")
        assert latest == "3"


class TestModelVersion:
    """Test ModelVersion class."""

    def test_version_creation(self):
        """Test version creation."""
        version = ModelVersion(
            name="test",
            version="1",
            stage=ModelStage.STAGING,
            metrics={"f1": 0.9},
        )

        assert version.name == "test"
        assert version.version == "1"
        assert version.stage == ModelStage.STAGING
        assert version.metrics["f1"] == 0.9

    def test_version_tags(self):
        """Test version tags."""
        version = ModelVersion(
            name="test",
            version="1",
            tags={"team": "ml", "type": "classifier"},
        )

        assert version.tags["team"] == "ml"
        assert version.tags["type"] == "classifier"
