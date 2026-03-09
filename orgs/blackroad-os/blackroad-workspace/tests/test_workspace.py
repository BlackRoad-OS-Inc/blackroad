"""Tests for BlackRoad Workspace Manager."""
import os
import sys
import json
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from workspace import WorkspaceDB, WorkspaceManager, SecretCrypto, EnvType, SecretScope


@pytest.fixture
def mgr(tmp_path):
    db = WorkspaceDB(db_path=str(tmp_path / "test_ws.db"))
    return WorkspaceManager(db, master_passphrase="test-key-123")


def test_create_workspace(mgr):
    ws = mgr.create_workspace("my-project", "Test workspace", "alice", tags=["python", "api"])
    assert ws.name == "my-project"
    assert ws.owner == "alice"
    assert "python" in ws.tags


def test_list_workspaces(mgr):
    mgr.create_workspace("ws1", "First")
    mgr.create_workspace("ws2", "Second")
    workspaces = mgr.list_workspaces()
    assert len(workspaces) == 2


def test_add_project(mgr):
    ws = mgr.create_workspace("proj-ws", "")
    proj = mgr.add_project(ws.id, "api-service", "/src/api",
                            language="Python", framework="FastAPI")
    assert proj.name == "api-service"
    assert proj.language == "Python"
    projects = mgr.list_projects(ws.id)
    assert len(projects) == 1


def test_set_and_get_config(mgr):
    ws = mgr.create_workspace("config-ws", "")
    mgr.set_config("workspace", ws.id, "log_level", "DEBUG", "string")
    mgr.set_config("workspace", ws.id, "max_workers", "4", "int")
    mgr.set_config("workspace", ws.id, "debug_mode", "true", "bool")
    assert mgr.get_config("workspace", ws.id, "log_level") == "DEBUG"
    assert mgr.get_config("workspace", ws.id, "max_workers") == 4
    assert mgr.get_config("workspace", ws.id, "debug_mode") is True
    assert mgr.get_config("workspace", ws.id, "missing_key", "default") == "default"


def test_secret_encrypt_decrypt():
    original = "super-secret-password-123"
    encrypted = SecretCrypto.encrypt(original, "my-passphrase")
    assert encrypted != original
    decrypted = SecretCrypto.decrypt(encrypted, "my-passphrase")
    assert decrypted == original


def test_set_and_get_secret(mgr):
    ws = mgr.create_workspace("secret-ws", "")
    mgr.set_secret("workspace", ws.id, "API_KEY", "sk-test-12345", "API key")
    retrieved = mgr.get_secret("workspace", ws.id, "API_KEY")
    assert retrieved == "sk-test-12345"


def test_inject_secrets(mgr):
    ws = mgr.create_workspace("inject-ws", "")
    mgr.set_secret("workspace", ws.id, "DB_PASSWORD", "s3cr3t!")
    mgr.set_secret("workspace", ws.id, "API_KEY", "key-abc-123")
    template = "postgres://user:${DB_PASSWORD}@localhost/db?key=${API_KEY}"
    result = mgr.inject_secrets("workspace", ws.id, template)
    assert "s3cr3t!" in result
    assert "key-abc-123" in result
    assert "${DB_PASSWORD}" not in result


def test_environment_inheritance(mgr):
    ws = mgr.create_workspace("env-ws", "")
    base_env = mgr.create_environment(ws.id, "base", "development",
                                       variables={"LOG_LEVEL": "INFO", "TIMEOUT": "30"})
    child_env = mgr.create_environment(ws.id, "staging", "staging",
                                        variables={"LOG_LEVEL": "DEBUG", "DB_HOST": "staging.db"},
                                        inherits_from=base_env.id)
    resolved = mgr.resolve_environment(child_env.id)
    assert resolved["LOG_LEVEL"] == "DEBUG"
    assert resolved["TIMEOUT"] == "30"
    assert resolved["DB_HOST"] == "staging.db"


def test_workspace_summary(mgr):
    ws = mgr.create_workspace("summary-ws", "Summary test")
    mgr.add_project(ws.id, "frontend", "/frontend", "TypeScript", "React")
    mgr.add_project(ws.id, "backend", "/backend", "Python", "FastAPI")
    mgr.create_environment(ws.id, "dev", "development")
    mgr.set_config("workspace", ws.id, "team_size", "5")
    mgr.set_secret("workspace", ws.id, "MASTER_KEY", "xyz")
    summary = mgr.workspace_summary(ws.id)
    assert summary["projects"] == 2
    assert summary["environments"] == 1
    assert summary["configs"] == 1
    assert summary["secrets"] == 1
