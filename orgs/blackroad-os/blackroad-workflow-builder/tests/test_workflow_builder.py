"""Tests for BlackRoad Workflow Builder."""
import json
import tempfile
import os
import pytest
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from workflow_builder import (
    WorkflowDB, WorkflowEngine, DAGValidator,
    Condition, RunStatus, StepType
)


@pytest.fixture
def tmp_engine(tmp_path):
    db_path = str(tmp_path / "test_workflow.db")
    db = WorkflowDB(db_path=db_path)
    return WorkflowEngine(db)


def test_create_workflow(tmp_engine):
    wf = tmp_engine.create_workflow("deploy-pipeline", "Deployment workflow", ["ci", "cd"])
    assert wf.name == "deploy-pipeline"
    assert "ci" in wf.tags
    assert wf.id is not None


def test_add_step(tmp_engine):
    wf = tmp_engine.create_workflow("test-wf", "Test")
    step = tmp_engine.add_step(wf.id, "checkout", "task",
                               {"command": "git checkout main"}, timeout=60)
    assert step.name == "checkout"
    assert step.step_type == StepType.TASK
    assert step.timeout_seconds == 60


def test_dag_validation_no_cycle(tmp_engine):
    wf = tmp_engine.create_workflow("linear-wf", "Linear")
    s1 = tmp_engine.add_step(wf.id, "fetch", "task", {})
    s2 = tmp_engine.add_step(wf.id, "build", "task", {}, depends_on=[s1.id])
    s3 = tmp_engine.add_step(wf.id, "test", "task", {}, depends_on=[s2.id])
    result = tmp_engine.validate_dag(wf.id)
    assert result["valid"] is True
    assert result["cycle_detected"] is False
    assert result["step_count"] == 3


def test_dag_validation_cycle_detection():
    graph = {"A": ["B"], "B": ["C"], "C": ["A"]}
    validator = DAGValidator(graph)
    has_cycle, path = validator.detect_cycle()
    assert has_cycle is True
    assert len(path) > 0


def test_dag_topological_sort():
    graph = {"build": ["test"], "test": ["deploy"], "deploy": []}
    validator = DAGValidator(graph)
    order = validator.topological_sort()
    assert order.index("deploy") < order.index("test")
    assert order.index("test") < order.index("build")


def test_condition_evaluate():
    cond = Condition(id="c1", step_id="s1",
                     expression="status eq success",
                     true_next="notify", false_next="rollback",
                     operator="eq", negate=False)
    assert cond.evaluate({"status": "success"}) is True
    assert cond.evaluate({"status": "failure"}) is False


def test_condition_evaluate_negated():
    cond = Condition(id="c2", step_id="s1",
                     expression="env eq prod",
                     true_next=None, false_next=None,
                     operator="eq", negate=True)
    assert cond.evaluate({"env": "prod"}) is False
    assert cond.evaluate({"env": "staging"}) is True


def test_execute_workflow_success(tmp_engine):
    wf = tmp_engine.create_workflow("exec-wf", "Execution test")
    s1 = tmp_engine.add_step(wf.id, "init", "task", {"command": "echo start"})
    s2 = tmp_engine.add_step(wf.id, "transform", "transform",
                             {"mapping": {"out_key": "init_val"}}, depends_on=[s1.id])
    run = tmp_engine.execute_workflow(wf.id, {"init_val": "hello"})
    assert run.status == RunStatus.SUCCESS
    assert len(run.step_results) == 2


def test_run_history(tmp_engine):
    wf = tmp_engine.create_workflow("history-wf", "History test")
    tmp_engine.add_step(wf.id, "step1", "task", {})
    tmp_engine.execute_workflow(wf.id)
    tmp_engine.execute_workflow(wf.id)
    history = tmp_engine.get_run_history(wf.id, limit=5)
    assert len(history) == 2
    assert history[0]["status"] in ("success", "failed")


def test_delete_workflow(tmp_engine):
    wf = tmp_engine.create_workflow("del-wf", "To delete")
    tmp_engine.add_step(wf.id, "s1", "task", {})
    tmp_engine.delete_workflow(wf.id)
    result = tmp_engine.db.conn.execute(
        "SELECT COUNT(*) as c FROM workflows WHERE id=?", (wf.id,)
    ).fetchone()
    assert result["c"] == 0


def test_export_workflow(tmp_engine):
    wf = tmp_engine.create_workflow("export-wf", "Export test", ["tag1"])
    tmp_engine.add_step(wf.id, "step1", "notify", {"channel": "slack"})
    data = tmp_engine.export_workflow(wf.id)
    assert "workflow" in data
    assert "steps" in data
    assert len(data["steps"]) == 1
    assert data["steps"][0]["name"] == "step1"


def test_critical_path():
    graph = {"a": [], "b": ["a"], "c": ["a"], "d": ["b", "c"]}
    validator = DAGValidator(graph)
    path = validator.critical_path()
    assert isinstance(path, list)
    assert len(path) >= 1
