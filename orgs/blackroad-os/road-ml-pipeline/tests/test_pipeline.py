"""Tests for pipeline module.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import pytest

from mlpipeline_core.pipeline import Pipeline, PipelineRun, PipelineStatus
from mlpipeline_core.pipeline.step import Step, StepConfig, StepStatus
from mlpipeline_core.pipeline.dag import DAG


class TestPipeline:
    """Test Pipeline class."""

    def test_create_pipeline(self):
        """Test pipeline creation."""
        pipeline = Pipeline(name="test-pipeline")
        assert pipeline.name == "test-pipeline"
        assert len(pipeline.steps) == 0

    def test_add_step(self):
        """Test adding steps."""
        pipeline = Pipeline(name="test-pipeline")

        @pipeline.step(name="step1")
        def step1():
            return {"value": 1}

        assert "step1" in pipeline.steps
        assert len(pipeline.steps) == 1

    def test_step_dependencies(self):
        """Test step dependencies."""
        pipeline = Pipeline(name="test-pipeline")

        @pipeline.step(name="step1")
        def step1():
            return {"value": 1}

        @pipeline.step(name="step2", depends_on=["step1"])
        def step2(value):
            return {"result": value * 2}

        dag = pipeline.dag
        assert "step1" in dag.predecessors("step2")

    def test_pipeline_run(self):
        """Test pipeline execution."""
        pipeline = Pipeline(name="test-pipeline")

        @pipeline.step(name="add")
        def add():
            return {"sum": 5}

        @pipeline.step(name="multiply", depends_on=["add"])
        def multiply(sum):
            return {"product": sum * 2}

        run = pipeline.run()
        assert run.status == PipelineStatus.COMPLETED
        assert "multiply" in run.outputs
        assert run.outputs["multiply"]["product"] == 10


class TestStep:
    """Test Step class."""

    def test_step_creation(self):
        """Test step creation."""
        def fn():
            return {"x": 1}

        config = StepConfig(name="test-step")
        step = Step(config=config, func=fn)
        assert step.name == "test-step"

    def test_step_execution(self):
        """Test step execution."""
        def fn(a, b):
            return {"sum": a + b}

        config = StepConfig(name="test-step")
        step = Step(config=config, func=fn)
        result = step.execute({"a": 1, "b": 2})

        assert result.status == StepStatus.COMPLETED
        assert result.outputs["sum"] == 3

    def test_step_retry(self):
        """Test step retry on failure."""
        call_count = 0

        def fn():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise ValueError("Transient error")
            return {"x": 1}

        config = StepConfig(name="test-step", retries=3)
        step = Step(config=config, func=fn)
        result = step.execute({})

        assert result.status == StepStatus.COMPLETED
        assert call_count == 3


class TestDAG:
    """Test DAG class."""

    def test_dag_creation(self):
        """Test DAG creation."""
        dag = DAG()
        dag.add_node("a")
        dag.add_node("b")
        dag.add_edge("a", "b")

        assert "a" in dag.nodes
        assert "b" in dag.nodes

    def test_topological_sort(self):
        """Test topological sort."""
        dag = DAG()
        dag.add_node("a")
        dag.add_node("b")
        dag.add_node("c")
        dag.add_edge("a", "b")
        dag.add_edge("b", "c")

        order = dag.topological_sort()
        assert order.index("a") < order.index("b")
        assert order.index("b") < order.index("c")

    def test_cycle_detection(self):
        """Test cycle detection."""
        dag = DAG()
        dag.add_node("a")
        dag.add_node("b")
        dag.add_edge("a", "b")
        dag.add_edge("b", "a")

        with pytest.raises(ValueError, match="cycle"):
            dag.topological_sort()

    def test_parallel_levels(self):
        """Test parallel execution levels."""
        dag = DAG()
        dag.add_node("a")
        dag.add_node("b")
        dag.add_node("c")
        dag.add_node("d")
        dag.add_edge("a", "c")
        dag.add_edge("b", "c")
        dag.add_edge("c", "d")

        levels = dag.get_parallel_levels()
        assert len(levels) == 3
        assert set(levels[0]) == {"a", "b"}
        assert levels[1] == ["c"]
        assert levels[2] == ["d"]
