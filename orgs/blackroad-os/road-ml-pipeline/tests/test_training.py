"""Tests for training module.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import pytest
from unittest.mock import Mock

from mlpipeline_core.training import TrainingJob, TrainingConfig, TrainingStatus
from mlpipeline_core.training.hpo import HPOSearch, SearchSpace, SearchStrategy


class TestTrainingJob:
    """Test TrainingJob class."""

    def test_job_creation(self):
        """Test job creation."""
        config = TrainingConfig(
            name="test-job",
            model_cls=Mock,
            epochs=10,
        )
        job = TrainingJob(config)

        assert job.config.name == "test-job"
        assert job.status == TrainingStatus.PENDING

    def test_job_execution(self):
        """Test job execution."""
        mock_model = Mock()
        mock_model.fit = Mock()

        config = TrainingConfig(
            name="test-job",
            model_cls=lambda: mock_model,
            epochs=5,
        )
        job = TrainingJob(config)
        job.run(train_data=[], val_data=[])

        assert job.status == TrainingStatus.COMPLETED


class TestHPOSearch:
    """Test HPOSearch class."""

    def test_search_space(self):
        """Test search space definition."""
        space = SearchSpace()
        space.uniform("learning_rate", 0.001, 0.1)
        space.choice("optimizer", ["adam", "sgd"])
        space.log_uniform("batch_size", 16, 256)

        sample = space.sample()
        assert 0.001 <= sample["learning_rate"] <= 0.1
        assert sample["optimizer"] in ["adam", "sgd"]
        assert 16 <= sample["batch_size"] <= 256

    def test_grid_search(self):
        """Test grid search."""
        search = HPOSearch(
            objective=lambda params: -params["x"]**2,
            search_space=SearchSpace().uniform("x", -5, 5),
            strategy=SearchStrategy.GRID,
            max_trials=10,
        )

        best = search.run()
        assert abs(best.params["x"]) < 1.0

    def test_random_search(self):
        """Test random search."""
        search = HPOSearch(
            objective=lambda params: -abs(params["x"] - 3),
            search_space=SearchSpace().uniform("x", 0, 10),
            strategy=SearchStrategy.RANDOM,
            max_trials=50,
        )

        best = search.run()
        assert abs(best.params["x"] - 3) < 2.0
