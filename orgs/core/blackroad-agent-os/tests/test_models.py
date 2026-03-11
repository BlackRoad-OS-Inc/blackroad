"""
Tests for controller/models/ (agent and task schemas).
"""
from datetime import datetime

import pytest

from models.agent import (
    Agent,
    AgentCapabilities,
    AgentHeartbeat,
    AgentRegistration,
    AgentStatus,
    AgentTelemetry,
    Workspace,
    WorkspaceStatus,
    WorkspaceType,
)
from models.task import (
    Command,
    CommandResult,
    LogEntry,
    RiskLevel,
    Task,
    TaskApproval,
    TaskPlan,
    TaskRequest,
    TaskStatus,
    TargetMode,
)


# --- Agent models ---


class TestAgentStatus:
    def test_enum_values(self):
        assert AgentStatus.ONLINE == "online"
        assert AgentStatus.OFFLINE == "offline"
        assert AgentStatus.BUSY == "busy"
        assert AgentStatus.ERROR == "error"


class TestAgent:
    def test_defaults(self):
        agent = Agent(id="pi-1", hostname="cecilia")
        assert agent.status == AgentStatus.OFFLINE
        assert agent.roles == []
        assert agent.tags == []
        assert agent.current_task_id is None
        assert agent.is_online is False
        assert agent.is_available is False

    def test_is_online(self):
        agent = Agent(id="pi-1", hostname="cecilia", status=AgentStatus.ONLINE)
        assert agent.is_online is True

    def test_is_available_when_online_no_task(self):
        agent = Agent(id="pi-1", hostname="cecilia", status=AgentStatus.ONLINE)
        assert agent.is_available is True

    def test_not_available_when_busy(self):
        agent = Agent(
            id="pi-1",
            hostname="cecilia",
            status=AgentStatus.ONLINE,
            current_task_id="task-1",
        )
        assert agent.is_available is False

    def test_not_available_when_offline(self):
        agent = Agent(id="pi-1", hostname="cecilia", status=AgentStatus.OFFLINE)
        assert agent.is_available is False

    def test_capabilities_defaults(self):
        caps = AgentCapabilities()
        assert caps.docker is False
        assert caps.python is None
        assert caps.git is True

    def test_telemetry_defaults(self):
        t = AgentTelemetry()
        assert t.cpu_percent == 0.0
        assert t.memory_percent == 0.0


class TestAgentRegistration:
    def test_minimal(self):
        reg = AgentRegistration(id="pi-1", hostname="alice")
        assert reg.id == "pi-1"
        assert reg.roles == []
        assert reg.secret is None

    def test_with_roles_and_capabilities(self):
        reg = AgentRegistration(
            id="pi-1",
            hostname="alice",
            roles=["compute", "inference"],
            capabilities=AgentCapabilities(docker=True, python="3.11.2"),
        )
        assert reg.roles == ["compute", "inference"]
        assert reg.capabilities.docker is True
        assert reg.capabilities.python == "3.11.2"


class TestAgentHeartbeat:
    def test_creation(self):
        hb = AgentHeartbeat(
            agent_id="pi-1",
            telemetry=AgentTelemetry(cpu_percent=42.5, memory_percent=60.0),
        )
        assert hb.agent_id == "pi-1"
        assert hb.telemetry.cpu_percent == 42.5
        assert hb.current_task_id is None


# --- Task models ---


class TestTaskStatus:
    def test_all_statuses(self):
        statuses = [s.value for s in TaskStatus]
        assert "pending" in statuses
        assert "running" in statuses
        assert "completed" in statuses
        assert "failed" in statuses
        assert "cancelled" in statuses
        assert "awaiting_approval" in statuses


class TestCommand:
    def test_defaults(self):
        cmd = Command(run="echo hello")
        assert cmd.dir == "~"
        assert cmd.env == {}
        assert cmd.timeout_seconds == 300
        assert cmd.continue_on_error is False

    def test_custom(self):
        cmd = Command(
            run="npm install",
            dir="/opt/app",
            env={"NODE_ENV": "production"},
            timeout_seconds=60,
            continue_on_error=True,
        )
        assert cmd.dir == "/opt/app"
        assert cmd.env["NODE_ENV"] == "production"


class TestTaskPlan:
    def test_defaults(self):
        plan = TaskPlan()
        assert plan.commands == []
        assert plan.steps == []
        assert plan.workspace_type == "bare"
        assert plan.risk_level == RiskLevel.LOW

    def test_with_commands(self):
        plan = TaskPlan(
            steps=["Install deps", "Run tests"],
            commands=[
                Command(run="pip install -r requirements.txt"),
                Command(run="pytest"),
            ],
            reasoning="Standard Python test workflow",
        )
        assert len(plan.commands) == 2
        assert plan.reasoning == "Standard Python test workflow"


class TestTask:
    def test_defaults(self):
        task = Task(id="abc123", request="deploy app")
        assert task.status == TaskStatus.PENDING
        assert task.priority == 5
        assert task.requires_approval is True
        assert task.plan is None
        assert task.exit_code is None

    def test_priority_bounds(self):
        task = Task(id="t1", request="test", priority=1)
        assert task.priority == 1
        task = Task(id="t2", request="test", priority=10)
        assert task.priority == 10

    def test_priority_out_of_bounds(self):
        with pytest.raises(Exception):
            Task(id="t3", request="test", priority=0)
        with pytest.raises(Exception):
            Task(id="t4", request="test", priority=11)


class TestTaskRequest:
    def test_minimal(self):
        req = TaskRequest(request="run tests")
        assert req.target_agent_id is None
        assert req.skip_approval is False
        assert req.priority == 5

    def test_targeted(self):
        req = TaskRequest(
            request="deploy",
            target_agent_id="pi-1",
            skip_approval=True,
            priority=9,
        )
        assert req.target_agent_id == "pi-1"
        assert req.skip_approval is True


class TestCommandResult:
    def test_creation(self):
        now = datetime.utcnow()
        result = CommandResult(
            command_index=0,
            command="echo hi",
            exit_code=0,
            stdout="hi\n",
            stderr="",
            duration_ms=12.5,
            started_at=now,
            completed_at=now,
        )
        assert result.exit_code == 0
        assert result.stdout == "hi\n"


class TestRiskLevel:
    def test_values(self):
        assert RiskLevel.LOW == "low"
        assert RiskLevel.MEDIUM == "medium"
        assert RiskLevel.HIGH == "high"
