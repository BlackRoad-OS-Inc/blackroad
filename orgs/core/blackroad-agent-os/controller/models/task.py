"""
Task Models - Pydantic schemas for tasks and plans
"""
from datetime import datetime
from enum import Enum
from typing import Optional, Any
from pydantic import BaseModel, Field


class TaskStatus(str, Enum):
    PENDING = "pending"
    PLANNING = "planning"
    AWAITING_APPROVAL = "awaiting_approval"
    QUEUED = "queued"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class TargetMode(str, Enum):
    SPECIFIC = "specific"  # Specific agent by ID
    ANY = "any"            # Any available agent
    ALL = "all"            # All matching agents
    ROLE = "role"          # Filter by role


class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class Command(BaseModel):
    """A single command to execute"""
    dir: str = "~"
    run: str
    env: dict[str, str] = Field(default_factory=dict)
    timeout_seconds: int = 300
    continue_on_error: bool = False
    approval_required: bool = False


class TaskPlan(BaseModel):
    """AI-generated execution plan"""
    target_agent: Optional[str] = None
    workspace: Optional[str] = None
    workspace_type: str = "bare"
    steps: list[str] = Field(default_factory=list)
    commands: list[Command] = Field(default_factory=list)
    reasoning: Optional[str] = None
    estimated_duration_seconds: Optional[int] = None
    risk_level: RiskLevel = RiskLevel.LOW
    requires_approval: bool = True


class Task(BaseModel):
    """A task submitted to the system"""
    id: str
    status: TaskStatus = TaskStatus.PENDING

    # User input
    request: str

    # Target selection
    target_mode: TargetMode = TargetMode.SPECIFIC
    target_agent_id: Optional[str] = None
    target_role: Optional[str] = None

    # AI-generated plan
    plan: Optional[TaskPlan] = None

    # Execution
    assigned_agent_id: Optional[str] = None
    workspace_id: Optional[str] = None

    # Results
    exit_code: Optional[int] = None
    output: Optional[str] = None
    error: Optional[str] = None

    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    planned_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    # Metadata
    created_by: str = "user"
    requires_approval: bool = True
    priority: int = Field(default=5, ge=1, le=10)


class TaskRequest(BaseModel):
    """API request to create a new task"""
    request: str
    target_agent_id: Optional[str] = None
    target_role: Optional[str] = None
    workspace: Optional[str] = None
    skip_approval: bool = False
    priority: int = Field(default=5, ge=1, le=10)


class TaskApproval(BaseModel):
    """User approval/rejection of a task plan"""
    task_id: str
    approved: bool
    modified_commands: Optional[list[Command]] = None
    reason: Optional[str] = None


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


class LogEntry(BaseModel):
    """A log entry from task execution"""
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    stream: str = "stdout"  # stdout, stderr, system
    content: str
    command_index: Optional[int] = None
