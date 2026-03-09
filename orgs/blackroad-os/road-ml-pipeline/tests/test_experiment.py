"""Tests for experiment module.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import pytest

from mlpipeline_core.experiment import ExperimentTracker, Experiment, Run


class TestExperimentTracker:
    """Test ExperimentTracker class."""

    def test_create_experiment(self):
        """Test experiment creation."""
        tracker = ExperimentTracker()
        exp = tracker.create_experiment(
            name="test-experiment",
            description="Testing experiment tracking",
        )

        assert exp.name == "test-experiment"
        assert exp.description == "Testing experiment tracking"
        assert exp.experiment_id is not None

    def test_start_run(self):
        """Test starting a run."""
        tracker = ExperimentTracker()
        exp = tracker.create_experiment(name="test")
        run = tracker.start_run(exp.experiment_id)

        assert run.status == "running"
        assert run.experiment_id == exp.experiment_id
        assert tracker.active_run == run

    def test_log_params(self):
        """Test parameter logging."""
        tracker = ExperimentTracker()
        exp = tracker.create_experiment(name="test")
        tracker.start_run(exp.experiment_id)

        tracker.log_param("learning_rate", 0.01)
        tracker.log_params({"batch_size": 32, "epochs": 10})

        run = tracker.active_run
        assert run.parameters["learning_rate"] == 0.01
        assert run.parameters["batch_size"] == 32
        assert run.parameters["epochs"] == 10

    def test_log_metrics(self):
        """Test metric logging."""
        tracker = ExperimentTracker()
        exp = tracker.create_experiment(name="test")
        tracker.start_run(exp.experiment_id)

        tracker.log_metric("accuracy", 0.95)
        tracker.log_metrics({"loss": 0.05, "f1": 0.93})

        run = tracker.active_run
        assert run.metrics["accuracy"] == 0.95
        assert run.metrics["loss"] == 0.05

    def test_end_run(self):
        """Test ending a run."""
        tracker = ExperimentTracker()
        exp = tracker.create_experiment(name="test")
        run = tracker.start_run(exp.experiment_id)
        run_id = run.run_id

        tracker.end_run()

        assert tracker.active_run is None
        ended_run = tracker.get_run(run_id)
        assert ended_run.status == "completed"
        assert ended_run.completed_at is not None

    def test_search_runs(self):
        """Test searching runs."""
        tracker = ExperimentTracker()
        exp = tracker.create_experiment(name="test")

        tracker.start_run(exp.experiment_id)
        tracker.log_metric("accuracy", 0.90)
        tracker.end_run()

        tracker.start_run(exp.experiment_id)
        tracker.log_metric("accuracy", 0.95)
        tracker.end_run()

        runs = tracker.search_runs(exp.experiment_id)
        assert len(runs) == 2


class TestRun:
    """Test Run class."""

    def test_run_creation(self):
        """Test run creation."""
        run = Run(
            run_id="abc123",
            experiment_id="exp001",
        )

        assert run.run_id == "abc123"
        assert run.experiment_id == "exp001"
        assert run.status == "running"

    def test_run_with_data(self):
        """Test run with data."""
        run = Run(
            run_id="abc123",
            experiment_id="exp001",
            parameters={"lr": 0.01},
            metrics={"acc": 0.95},
            tags={"team": "ml"},
        )

        assert run.parameters["lr"] == 0.01
        assert run.metrics["acc"] == 0.95
        assert run.tags["team"] == "ml"
