"""
Agent Configuration - Settings for the Pi agent daemon
"""
import os
import socket
from pathlib import Path
from typing import Optional
from pydantic import BaseModel, Field


class AgentConfig(BaseModel):
    """Configuration for the agent daemon"""

    # Identity
    agent_id: str = Field(default_factory=lambda: socket.gethostname())
    hostname: str = Field(default_factory=socket.gethostname)
    display_name: Optional[str] = None

    # Controller connection
    controller_url: str = "ws://localhost:8000/ws/agent"
    reconnect_delay: int = 5  # Seconds between reconnection attempts
    heartbeat_interval: int = 15  # Seconds between heartbeats

    # Agent roles and tags
    roles: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)

    # Workspace settings
    workspace_root: Path = Field(default_factory=lambda: Path.home() / "blackroad" / "workspaces")
    max_workspaces: int = 5

    # Execution settings
    default_timeout: int = 300  # 5 minutes
    max_timeout: int = 3600  # 1 hour
    shell: str = "/bin/bash"

    # Docker settings
    docker_enabled: bool = True
    docker_default_image: str = "python:3.11-slim"

    # Logging
    log_level: str = "INFO"
    log_file: Optional[Path] = None

    @classmethod
    def from_env(cls) -> "AgentConfig":
        """Create config from environment variables"""
        return cls(
            agent_id=os.environ.get("AGENT_ID", socket.gethostname()),
            hostname=os.environ.get("HOSTNAME", socket.gethostname()),
            display_name=os.environ.get("AGENT_DISPLAY_NAME"),
            controller_url=os.environ.get(
                "CONTROLLER_URL",
                "ws://localhost:8000/ws/agent"
            ),
            reconnect_delay=int(os.environ.get("RECONNECT_DELAY", "5")),
            heartbeat_interval=int(os.environ.get("HEARTBEAT_INTERVAL", "15")),
            roles=os.environ.get("AGENT_ROLES", "").split(",") if os.environ.get("AGENT_ROLES") else [],
            tags=os.environ.get("AGENT_TAGS", "").split(",") if os.environ.get("AGENT_TAGS") else [],
            workspace_root=Path(os.environ.get("WORKSPACE_ROOT", Path.home() / "blackroad" / "workspaces")),
            docker_enabled=os.environ.get("DOCKER_ENABLED", "true").lower() == "true",
            log_level=os.environ.get("LOG_LEVEL", "INFO"),
        )


# Detect capabilities
def detect_capabilities() -> dict:
    """Detect what this machine can do"""
    import shutil
    import subprocess

    capabilities = {
        "docker": False,
        "python": None,
        "node": None,
        "git": False,
        "ssh": False,
    }

    # Check Docker
    if shutil.which("docker"):
        try:
            result = subprocess.run(
                ["docker", "info"],
                capture_output=True,
                timeout=5,
            )
            capabilities["docker"] = result.returncode == 0
        except Exception:
            pass

    # Check Python
    if shutil.which("python3"):
        try:
            result = subprocess.run(
                ["python3", "--version"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode == 0:
                capabilities["python"] = result.stdout.strip().replace("Python ", "")
        except Exception:
            pass

    # Check Node
    if shutil.which("node"):
        try:
            result = subprocess.run(
                ["node", "--version"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            if result.returncode == 0:
                capabilities["node"] = result.stdout.strip().lstrip("v")
        except Exception:
            pass

    # Check Git
    capabilities["git"] = shutil.which("git") is not None

    # Check SSH
    capabilities["ssh"] = shutil.which("ssh") is not None

    return capabilities
