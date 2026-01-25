"""
Agent Models - Pydantic schemas for agent machines
"""
from datetime import datetime
from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class AgentStatus(str, Enum):
    ONLINE = "online"
    OFFLINE = "offline"
    BUSY = "busy"
    ERROR = "error"


class WorkspaceType(str, Enum):
    DOCKER = "docker"
    VENV = "venv"
    BARE = "bare"


class WorkspaceStatus(str, Enum):
    READY = "ready"
    BUILDING = "building"
    RUNNING = "running"
    STOPPED = "stopped"
    ERROR = "error"


class AgentCapabilities(BaseModel):
    docker: bool = False
    python: Optional[str] = None
    node: Optional[str] = None
    git: bool = True
    disk_gb: Optional[float] = None
    memory_mb: Optional[int] = None


class AgentTelemetry(BaseModel):
    cpu_percent: float = 0.0
    memory_percent: float = 0.0
    disk_percent: float = 0.0
    uptime_seconds: float = 0.0
    load_average: list[float] = Field(default_factory=list)


class Workspace(BaseModel):
    id: str
    name: str
    type: WorkspaceType = WorkspaceType.BARE
    path: str
    container_id: Optional[str] = None
    status: WorkspaceStatus = WorkspaceStatus.READY
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_used: Optional[datetime] = None


class Agent(BaseModel):
    id: str
    hostname: str
    display_name: Optional[str] = None
    status: AgentStatus = AgentStatus.OFFLINE
    roles: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    capabilities: AgentCapabilities = Field(default_factory=AgentCapabilities)
    workspaces: list[Workspace] = Field(default_factory=list)
    telemetry: AgentTelemetry = Field(default_factory=AgentTelemetry)
    last_seen: Optional[datetime] = None
    registered_at: datetime = Field(default_factory=datetime.utcnow)
    current_task_id: Optional[str] = None

    @property
    def is_online(self) -> bool:
        return self.status == AgentStatus.ONLINE

    @property
    def is_available(self) -> bool:
        return self.status == AgentStatus.ONLINE and self.current_task_id is None


class AgentRegistration(BaseModel):
    """Sent by agent daemon on connection"""
    id: str
    hostname: str
    display_name: Optional[str] = None
    roles: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    capabilities: AgentCapabilities = Field(default_factory=AgentCapabilities)
    secret: Optional[str] = None  # Pre-shared secret for auth


class AgentHeartbeat(BaseModel):
    """Sent by agent every 30 seconds"""
    agent_id: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    telemetry: AgentTelemetry
    current_task_id: Optional[str] = None
    workspaces: list[Workspace] = Field(default_factory=list)
