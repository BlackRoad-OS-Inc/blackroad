#!/usr/bin/env python3
"""Tests for BlackRoad Serverless Deploy."""

import os
import sys
import json
import sqlite3
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))
import serverless_deploy as sd


def _make_tmp_db():
    f = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    f.close()
    return f.name


class TestFunctionDataclass(unittest.TestCase):
    def test_defaults(self):
        f = sd.Function(name="fn", runtime="python3.11", handler="main.handler")
        self.assertEqual(f.memory_mb, 128)
        self.assertEqual(f.timeout_s, 30)
        self.assertEqual(f.provider, "aws-lambda")
        self.assertEqual(f.status, "registered")
        self.assertIsNone(f.id)

    def test_deployment_log_fields(self):
        log = sd.DeploymentLog(
            function_name="fn", provider="aws-lambda", status="success",
            version="abc123", duration_s=2.5, error_msg=None,
            deployed_at="2024-01-01",
        )
        self.assertEqual(log.status, "success")
        self.assertIsNone(log.error_msg)


class TestInitDb(unittest.TestCase):
    def test_all_tables_created(self):
        path = _make_tmp_db()
        try:
            sd.DB_PATH = path
            sd.init_db()
            conn = sqlite3.connect(path)
            tables = {r[0] for r in conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            ).fetchall()}
            conn.close()
            self.assertIn("functions", tables)
            self.assertIn("deployment_logs", tables)
            self.assertIn("env_vars", tables)
        finally:
            os.unlink(path)

    def test_init_idempotent(self):
        path = _make_tmp_db()
        try:
            sd.DB_PATH = path
            sd.init_db()
            sd.init_db()
        finally:
            os.unlink(path)


class TestServerlessDeployer(unittest.TestCase):
    def setUp(self):
        self.path = _make_tmp_db()
        sd.DB_PATH = self.path
        self.deployer = sd.ServerlessDeployer()

    def tearDown(self):
        self.deployer.close()
        os.unlink(self.path)

    def _fn(self, name="my-func", provider="aws-lambda"):
        return sd.Function(
            name=name, runtime="python3.11",
            handler="main.handler", provider=provider,
        )

    def test_register_function_assigns_id(self):
        f = self.deployer.register_function(self._fn())
        self.assertIsNotNone(f.id)

    def test_register_sets_created_at(self):
        f = self.deployer.register_function(self._fn())
        self.assertIsNotNone(f.created_at)

    def test_register_duplicate_no_exception(self):
        self.deployer.register_function(self._fn("dup"))
        self.deployer.register_function(self._fn("dup"))

    def test_invalid_provider_rejected(self):
        f = sd.Function(
            name="bad-fn", runtime="python3.11",
            handler="main.handler", provider="fake-provider",
        )
        result = self.deployer.register_function(f)
        # id should be None because it was rejected
        self.assertIsNone(result.id)

    def test_list_functions_empty(self):
        self.assertEqual(self.deployer.list_functions(), [])

    def test_list_after_register(self):
        self.deployer.register_function(self._fn("fn1"))
        self.deployer.register_function(self._fn("fn2"))
        funcs = self.deployer.list_functions()
        self.assertEqual(len(funcs), 2)

    def test_deploy_nonexistent_returns_none(self):
        result = self.deployer.deploy_function("ghost")
        self.assertIsNone(result)

    def test_deploy_dry_run_returns_log(self):
        self.deployer.register_function(self._fn("dry-fn"))
        log = self.deployer.deploy_function("dry-fn", dry_run=True)
        self.assertIsNotNone(log)
        self.assertEqual(log.status, "dry_run")

    def test_deploy_dry_run_does_not_update_status_to_deployed(self):
        self.deployer.register_function(self._fn("dry2"))
        self.deployer.deploy_function("dry2", dry_run=True)
        funcs = self.deployer.list_functions()
        fn = next(f for f in funcs if f.name == "dry2")
        self.assertNotEqual(fn.status, "deployed")

    def test_deploy_generates_version_hash(self):
        self.deployer.register_function(self._fn("hfn"))
        log = self.deployer.deploy_function("hfn", dry_run=True)
        self.assertIsNotNone(log.version)
        self.assertEqual(len(log.version), 12)

    def test_get_logs_empty(self):
        self.assertEqual(self.deployer.get_logs(), [])

    def test_get_logs_after_deploy(self):
        self.deployer.register_function(self._fn("log-fn"))
        self.deployer.deploy_function("log-fn", dry_run=True)
        logs = self.deployer.get_logs("log-fn")
        self.assertEqual(len(logs), 1)

    def test_export_manifest_structure(self):
        self.deployer.register_function(self._fn("exp-fn"))
        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            path = f.name
        try:
            self.deployer.export_manifest(path)
            with open(path) as f:
                data = json.load(f)
            self.assertIn("functions", data)
            self.assertIn("summary", data)
            self.assertEqual(data["summary"]["total_functions"], 1)
        finally:
            os.unlink(path)

    def test_build_deploy_command_aws(self):
        row = {
            "provider": "aws-lambda", "name": "fn",
            "runtime": "python3.11", "handler": "main.handler",
            "memory_mb": 128, "timeout_s": 30, "region": "us-east-1",
        }
        cmd = self.deployer._build_deploy_command(row)
        self.assertIn("aws", cmd["cmd"])

    def test_build_deploy_command_cloudflare(self):
        row = {
            "provider": "cloudflare-workers", "name": "fn",
            "runtime": "nodejs18", "handler": "index.handler",
            "memory_mb": 128, "timeout_s": 30, "region": "global",
        }
        cmd = self.deployer._build_deploy_command(row)
        self.assertIn("wrangler", cmd["cmd"])


if __name__ == "__main__":
    unittest.main()
