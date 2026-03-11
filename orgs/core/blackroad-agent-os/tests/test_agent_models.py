"""
Tests for agent/models.py (agent-side Pydantic schemas).

Uses importlib.util to load agent/models.py directly by file path,
avoiding collision with controller/models/ package.
"""
import importlib.util
import sys
from datetime import datetime
from pathlib import Path

import pytest

# Load agent/models.py by file path to avoid collision with controller/models/
_agent_models_path = Path(__file__).parent.parent / "agent" / "models.py"
_spec = importlib.util.spec_from_file_location("agent_models", _agent_models_path)
_agent_models = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_agent_models)

Command = _agent_models.Command
CommandResult = _agent_models.CommandResult
TaskPlan = _agent_models.TaskPlan
Telemetry = _agent_models.Telemetry
Workspace = _agent_models.Workspace
WorkspaceStatus = _agent_models.WorkspaceStatus
WorkspaceType = _agent_models.WorkspaceType


class TestWorkspace:
    def test_defaults(self):
        ws = Workspace(name="default", path="/tmp/ws")
        assert ws.type == WorkspaceType.BARE
        assert ws.status == WorkspaceStatus.READY
        assert ws.container_id is None
        assert ws.last_used is None

    def test_docker_workspace(self):
        ws = Workspace(
            name="docker-ws",
            type=WorkspaceType.DOCKER,
            path="/tmp/docker-ws",
            container_id="abc123",
        )
        assert ws.type == WorkspaceType.DOCKER
        assert ws.container_id == "abc123"


class TestAgentCommand:
    def test_defaults(self):
        cmd = Command(run="pytest")
        assert cmd.dir == "~"
        assert cmd.env == {}
        assert cmd.timeout_seconds == 300
        assert cmd.continue_on_error is False

    def test_with_env(self):
        cmd = Command(
            run="npm test",
            dir="/app",
            env={"CI": "true"},
            timeout_seconds=60,
        )
        assert cmd.env["CI"] == "true"


class TestAgentTaskPlan:
    def test_empty_plan(self):
        plan = TaskPlan()
        assert plan.commands == []
        assert plan.steps == []
        assert plan.workspace_type == "bare"

    def test_plan_with_commands(self):
        plan = TaskPlan(
            steps=["Build", "Test"],
            commands=[
                Command(run="make build"),
                Command(run="make test"),
            ],
            reasoning="Standard build-test cycle",
        )
        assert len(plan.commands) == 2
        assert plan.steps[0] == "Build"


class TestAgentCommandResult:
    def test_success(self):
        now = datetime.utcnow()
        result = CommandResult(
            command_index=0,
            command="echo ok",
            exit_code=0,
            stdout="ok\n",
            stderr="",
            duration_ms=5.0,
            started_at=now,
            completed_at=now,
        )
        assert result.exit_code == 0

    def test_failure(self):
        now = datetime.utcnow()
        result = CommandResult(
            command_index=1,
            command="false",
            exit_code=1,
            stdout="",
            stderr="error\n",
            duration_ms=2.0,
            started_at=now,
            completed_at=now,
        )
        assert result.exit_code == 1
        assert result.stderr == "error\n"


class TestTelemetry:
    def test_defaults(self):
        t = Telemetry()
        assert t.cpu_percent == 0
        assert t.memory_percent == 0
        assert t.disk_percent == 0
        assert t.load_avg == [0, 0, 0]
        assert t.uptime_seconds == 0

    def test_custom(self):
        t = Telemetry(
            cpu_percent=45.2,
            memory_percent=62.1,
            disk_percent=77.0,
            load_avg=[1.5, 2.0, 1.8],
            uptime_seconds=86400.0,
        )
        assert t.cpu_percent == 45.2
        assert t.load_avg[0] == 1.5
