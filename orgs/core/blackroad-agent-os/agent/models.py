"""
Agent Models - Pydantic schemas for agent-side operations
"""
from datetime import datetime
from enum import Enum
from typing import Optional, Any
from pydantic import BaseModel, Field


class WorkspaceType(str, Enum):
    BARE = "bare"
    DOCKER = "docker"
    VENV = "venv"


class WorkspaceStatus(str, Enum):
    CREATING = "creating"
    READY = "ready"
    BUSY = "busy"
    ERROR = "error"


class Workspace(BaseModel):
    """A workspace for task execution"""
    name: str
    type: WorkspaceType = WorkspaceType.BARE
    path: str
    status: WorkspaceStatus = WorkspaceStatus.READY
    container_id: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_used: Optional[datetime] = None


class Command(BaseModel):
    """A command to execute"""
    dir: str = "~"
    run: str
    env: dict[str, str] = Field(default_factory=dict)
    timeout_seconds: int = 300
    continue_on_error: bool = False


class TaskPlan(BaseModel):
    """Execution plan received from controller"""
    target_agent: Optional[str] = None
    workspace: Optional[str] = None
    workspace_type: str = "bare"
    steps: list[str] = Field(default_factory=list)
    commands: list[Command] = Field(default_factory=list)
    reasoning: Optional[str] = None


class CommandResult(BaseModel):
    """Result of executing a single command"""
    command_index: int
    command: str
    exit_code: int
    stdout: str
    stderr: str
    duration_ms: float
    started_at: datetime
    completed_at: datetime


class Telemetry(BaseModel):
    """System telemetry data"""
    cpu_percent: float = 0
    memory_percent: float = 0
    disk_percent: float = 0
    load_avg: list[float] = Field(default_factory=lambda: [0, 0, 0])
    uptime_seconds: float = 0
