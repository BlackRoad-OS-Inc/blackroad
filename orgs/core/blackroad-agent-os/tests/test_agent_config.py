"""
Tests for agent/config.py (agent configuration and capability detection).

Uses importlib.util to load agent/config.py directly by file path,
avoiding collision with controller modules.
"""
import importlib.util
import os
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

# Load agent/config.py by file path
_agent_config_path = Path(__file__).parent.parent / "agent" / "config.py"
_spec = importlib.util.spec_from_file_location("agent_config", _agent_config_path)
_agent_config = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_agent_config)

AgentConfig = _agent_config.AgentConfig
detect_capabilities = _agent_config.detect_capabilities


class TestAgentConfig:
    def test_defaults(self):
        config = AgentConfig()
        assert config.controller_url == "ws://localhost:8000/ws/agent"
        assert config.reconnect_delay == 5
        assert config.heartbeat_interval == 15
        assert config.roles == []
        assert config.tags == []
        assert config.default_timeout == 300
        assert config.max_timeout == 3600
        assert config.shell == "/bin/bash"
        assert config.docker_enabled is True
        assert config.log_level == "INFO"

    def test_custom_values(self):
        config = AgentConfig(
            agent_id="test-pi",
            controller_url="ws://192.168.4.49:8000/ws/agent",
            roles=["compute", "inference"],
            docker_enabled=False,
        )
        assert config.agent_id == "test-pi"
        assert config.controller_url == "ws://192.168.4.49:8000/ws/agent"
        assert config.roles == ["compute", "inference"]
        assert config.docker_enabled is False

    def test_workspace_root_default(self):
        config = AgentConfig()
        assert config.workspace_root == Path.home() / "blackroad" / "workspaces"

    def test_from_env(self):
        env = {
            "AGENT_ID": "cecilia",
            "HOSTNAME": "cecilia.local",
            "AGENT_DISPLAY_NAME": "Cecilia Pi5",
            "CONTROLLER_URL": "ws://alice:8000/ws/agent",
            "RECONNECT_DELAY": "10",
            "HEARTBEAT_INTERVAL": "30",
            "AGENT_ROLES": "compute,inference",
            "AGENT_TAGS": "hailo,nvme",
            "DOCKER_ENABLED": "false",
            "LOG_LEVEL": "DEBUG",
        }
        with patch.dict(os.environ, env, clear=False):
            config = AgentConfig.from_env()
            assert config.agent_id == "cecilia"
            assert config.hostname == "cecilia.local"
            assert config.display_name == "Cecilia Pi5"
            assert config.controller_url == "ws://alice:8000/ws/agent"
            assert config.reconnect_delay == 10
            assert config.heartbeat_interval == 30
            assert config.roles == ["compute", "inference"]
            assert config.tags == ["hailo", "nvme"]
            assert config.docker_enabled is False
            assert config.log_level == "DEBUG"

    def test_from_env_defaults(self):
        with patch.dict(os.environ, {}, clear=True):
            config = AgentConfig.from_env()
            assert config.controller_url == "ws://localhost:8000/ws/agent"
            assert config.roles == []
            assert config.tags == []

    def test_empty_roles_from_env(self):
        with patch.dict(os.environ, {"AGENT_ROLES": ""}, clear=False):
            config = AgentConfig.from_env()
            assert config.roles == []


class TestDetectCapabilities:
    def test_returns_expected_keys(self):
        caps = detect_capabilities()
        assert "docker" in caps
        assert "python" in caps
        assert "node" in caps
        assert "git" in caps
        assert "ssh" in caps

    def test_types(self):
        caps = detect_capabilities()
        assert isinstance(caps["docker"], bool)
        assert isinstance(caps["git"], bool)
        assert isinstance(caps["ssh"], bool)
        # python and node are either None or str
        assert caps["python"] is None or isinstance(caps["python"], str)
        assert caps["node"] is None or isinstance(caps["node"], str)

    def test_git_available(self):
        """Git should be available on any dev machine."""
        caps = detect_capabilities()
        assert caps["git"] is True

    def test_python_version_format(self):
        """If Python is detected, it should be a version string."""
        caps = detect_capabilities()
        if caps["python"]:
            parts = caps["python"].split(".")
            assert len(parts) >= 2
            assert parts[0].isdigit()
