"""Workflow tests."""

import pytest
from datetime import datetime
from roadworkflow_core.workflow.definition import Workflow, WorkflowConfig
from roadworkflow_core.workflow.dag import DAG
from roadworkflow_core.workflow.builder import WorkflowBuilder
from roadworkflow_core.tasks.base import Task, TaskContext, TaskStatus


class MockTask(Task):
    """Mock task for testing."""

    def __init__(self, task_id: str, return_value=None, should_fail=False):
        super().__init__(task_id=task_id)
        self.return_value = return_value
        self.should_fail = should_fail
        self.executed = False

    def execute(self, context: TaskContext):
        self.executed = True
        if self.should_fail:
            raise ValueError("Task failed")
        return self.return_value


class TestDAG:
    """DAG tests."""

    def test_add_node(self):
        dag = DAG()
        node = dag.add_node("task1", label="Task 1")
        assert node.node_id == "task1"
        assert "task1" in dag._nodes

    def test_add_edge(self):
        dag = DAG()
        dag.add_node("task1")
        dag.add_node("task2")
        edge = dag.add_edge("task1", "task2")
        assert edge.source == "task1"
        assert edge.target == "task2"

    def test_topological_sort(self):
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
        dag = DAG()
        dag.add_node("a")
        dag.add_node("b")
        dag.add_node("c")
        dag.add_edge("a", "b")
        dag.add_edge("b", "c")
        
        assert not dag.has_cycle()
        
        dag.add_edge("c", "a")
        assert dag.has_cycle()

    def test_parallel_groups(self):
        dag = DAG()
        dag.add_node("a")
        dag.add_node("b")
        dag.add_node("c")
        dag.add_node("d")
        dag.add_edge("a", "c")
        dag.add_edge("b", "c")
        dag.add_edge("c", "d")
        
        groups = dag.get_parallel_groups()
        assert len(groups) >= 1


class TestWorkflow:
    """Workflow tests."""

    def test_create_workflow(self):
        workflow = Workflow("test_workflow")
        assert workflow.workflow_id == "test_workflow"

    def test_add_task(self):
        workflow = Workflow("test_workflow")
        task = MockTask("task1")
        workflow.add_task(task)
        assert "task1" in workflow._tasks

    def test_task_dependencies(self):
        workflow = Workflow("test_workflow")
        task1 = MockTask("task1")
        task2 = MockTask("task2")
        
        workflow.add_task(task1)
        workflow.add_task(task2, depends_on=["task1"])
        
        deps = workflow.get_dependencies("task2")
        assert "task1" in deps

    def test_validate_workflow(self):
        workflow = Workflow("test_workflow")
        task1 = MockTask("task1")
        task2 = MockTask("task2")
        
        workflow.add_task(task1)
        workflow.add_task(task2, depends_on=["task1"])
        
        errors = workflow.validate()
        assert len(errors) == 0


class TestWorkflowBuilder:
    """WorkflowBuilder tests."""

    def test_build_workflow(self):
        builder = WorkflowBuilder("test_workflow")
        
        workflow = (
            builder
            .with_description("Test workflow")
            .with_timeout(3600)
            .build()
        )
        
        assert workflow.workflow_id == "test_workflow"
        assert workflow.config.timeout == 3600

    def test_add_tasks(self):
        builder = WorkflowBuilder("test_workflow")
        task1 = MockTask("task1")
        task2 = MockTask("task2")
        
        workflow = (
            builder
            .add_task(task1)
            .add_task(task2, depends_on=["task1"])
            .build()
        )
        
        assert "task1" in workflow._tasks
        assert "task2" in workflow._tasks
