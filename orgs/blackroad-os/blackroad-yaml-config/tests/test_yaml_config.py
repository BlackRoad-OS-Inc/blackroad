"""Tests for BlackRoad YAML Config Manager."""
import os
import sys
import json
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from yaml_config import (
    YAMLConfigDB, YAMLConfigManager, MergeStrategy,
    _flatten_dict, _get_nested, _set_nested,
    _simple_encrypt, _simple_decrypt, _parse_yaml_or_json
)


@pytest.fixture
def mgr(tmp_path):
    db = YAMLConfigDB(db_path=str(tmp_path / "test_yaml.db"))
    return YAMLConfigManager(db, secret_key="test-secret-key")


BASE_CONFIG = {
    "app": {"name": "myapp", "version": "1.0", "debug": False},
    "database": {"host": "localhost", "port": 5432, "name": "mydb"},
    "logging": {"level": "INFO", "format": "json"},
}

OVERRIDE_CONFIG = {
    "app": {"debug": True, "workers": 4},
    "database": {"host": "prod.db.example.com", "ssl": True},
    "cache": {"enabled": True, "ttl": 300},
}


def test_load_config(mgr):
    cfg = mgr.load_config("base", "development", BASE_CONFIG,
                           description="Base config", tags=["base", "dev"])
    assert cfg.name == "base"
    assert cfg.environment == "development"
    assert cfg.version == 1
    assert cfg.content_hash is not None


def test_load_config_versioning(mgr):
    cfg_v1 = mgr.load_config("versioned", "development", {"key": "value1"})
    cfg_v2 = mgr.load_config("versioned", "development", {"key": "value2"})
    assert cfg_v2.version == 2
    assert cfg_v1.version == 1


def test_get_config(mgr):
    mgr.load_config("get-test", "staging", BASE_CONFIG)
    cfg = mgr.get_config("get-test", "staging")
    assert cfg is not None
    assert cfg["content"]["app"]["name"] == "myapp"


def test_merge_deep(mgr):
    mgr.load_config("base", "development", BASE_CONFIG)
    mgr.load_config("override", "development", OVERRIDE_CONFIG)
    result = mgr.merge_configs("base", "override", "development", "deep", "merged-deep")
    assert result.content["app"]["name"] == "myapp"
    assert result.content["app"]["debug"] is True
    assert result.content["app"]["workers"] == 4
    assert result.content["database"]["host"] == "prod.db.example.com"
    assert result.content["database"]["port"] == 5432
    assert "cache" in result.content


def test_merge_override(mgr):
    mgr.load_config("base", "development", BASE_CONFIG)
    mgr.load_config("override", "development", OVERRIDE_CONFIG)
    result = mgr.merge_configs("base", "override", "development", "override", "merged-override")
    assert result.content == OVERRIDE_CONFIG


def test_flatten_dict():
    d = {"a": {"b": {"c": 1}}, "d": 2}
    flat = _flatten_dict(d)
    assert flat["a.b.c"] == 1
    assert flat["d"] == 2


def test_get_set_nested():
    d = {"app": {"name": "test", "db": {"host": "localhost"}}}
    assert _get_nested(d, "app.name") == "test"
    assert _get_nested(d, "app.db.host") == "localhost"
    assert _get_nested(d, "app.missing") is None
    _set_nested(d, "app.db.port", 5432)
    assert d["app"]["db"]["port"] == 5432


def test_encrypt_decrypt():
    value = "my-super-secret-password!"
    enc = _simple_encrypt(value, "test-key")
    assert enc.startswith("ENC:")
    assert enc != value
    dec = _simple_decrypt(enc, "test-key")
    assert dec == value


def test_register_and_inject_secret(mgr):
    cfg = mgr.load_config("secret-test", "development",
                           {"db": {"password": "PLACEHOLDER", "host": "localhost"}})
    mgr.register_secret(cfg.id, "db.password", "DB_PASSWORD", "real-secret-value")
    result = mgr.inject_secrets("secret-test", "development", {"DB_PASSWORD": "injected-value"})
    assert result["injected"] == 1
    assert result["content"]["db"]["password"] == "injected-value"


def test_schema_validation_pass(mgr):
    mgr.load_config("schema-test", "development", BASE_CONFIG)
    mgr.add_schema_field("app-schema", "app.name", "string", required=True)
    mgr.add_schema_field("app-schema", "database.port", "integer", required=True,
                          validators=["min:1", "max:65535"])
    result = mgr.validate_schema("schema-test", "development", "app-schema")
    assert result["valid"] is True
    assert result["fields_passed"] == 2


def test_schema_validation_fail(mgr):
    mgr.load_config("schema-fail", "development", {"app": {"debug": True}})
    mgr.add_schema_field("strict-schema", "app.name", "string", required=True)
    mgr.add_schema_field("strict-schema", "database.host", "string", required=True)
    result = mgr.validate_schema("schema-fail", "development", "strict-schema")
    assert result["valid"] is False
    assert len(result["errors"]) >= 2


def test_diff_configs(mgr):
    mgr.load_config("cfg-a", "development", {"a": 1, "b": 2, "c": 3})
    mgr.load_config("cfg-b", "development", {"a": 1, "b": 99, "d": 4})
    diffs = mgr.diff_configs("cfg-a", "development", "cfg-b", "development")
    types = {d.change_type for d in diffs}
    assert "added" in types
    assert "removed" in types
    assert "modified" in types


def test_export_env_format(mgr):
    mgr.load_config("export-test", "production", {"db": {"host": "prod", "port": 5432}})
    output = mgr.export_config("export-test", "production", fmt="env")
    assert "DB_HOST=prod" in output or "DB.HOST=prod" in output.upper() or "prod" in output


def test_list_configs(mgr):
    mgr.load_config("list-1", "development", {"x": 1})
    mgr.load_config("list-2", "production", {"y": 2})
    all_cfgs = mgr.list_configs()
    assert len(all_cfgs) == 2
    dev_cfgs = mgr.list_configs("development")
    assert len(dev_cfgs) == 1
