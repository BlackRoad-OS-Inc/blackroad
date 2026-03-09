#!/usr/bin/env python3
"""Tests for BlackRoad Status Board."""

import os
import sys
import json
import sqlite3
import tempfile
import unittest
from unittest.mock import patch, MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))
import status_board as sb


def _make_tmp_db():
    f = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    f.close()
    return f.name


class TestServiceDataclass(unittest.TestCase):
    def test_defaults(self):
        s = sb.Service(name="api", url="https://example.com")
        self.assertEqual(s.status, "unknown")
        self.assertEqual(s.expected_status_code, 200)
        self.assertIsNone(s.id)

    def test_alert_dataclass(self):
        a = sb.StatusAlert(
            service_name="api", alert_type="down",
            message="gone", response_time_ms=0.0,
            status_code=0, created_at="2024-01-01",
        )
        self.assertEqual(a.alert_type, "down")


class TestInitDb(unittest.TestCase):
    def test_all_tables_exist(self):
        path = _make_tmp_db()
        try:
            sb.DB_PATH = path
            sb.init_db()
            conn = sqlite3.connect(path)
            tables = {r[0] for r in conn.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            ).fetchall()}
            conn.close()
            self.assertIn("services", tables)
            self.assertIn("checks", tables)
            self.assertIn("alerts", tables)
        finally:
            os.unlink(path)

    def test_init_idempotent(self):
        path = _make_tmp_db()
        try:
            sb.DB_PATH = path
            sb.init_db()
            sb.init_db()
        finally:
            os.unlink(path)


class TestStatusBoardManager(unittest.TestCase):
    def setUp(self):
        self.path = _make_tmp_db()
        sb.DB_PATH = self.path
        self.mgr = sb.StatusBoardManager()

    def tearDown(self):
        self.mgr.close()
        os.unlink(self.path)

    def _svc(self, name="api", url="https://example.com"):
        return sb.Service(name=name, url=url)

    def test_add_service_assigns_id(self):
        s = self.mgr.add_service(self._svc())
        self.assertIsNotNone(s.id)
        self.assertGreater(s.id, 0)

    def test_add_service_sets_created_at(self):
        s = self.mgr.add_service(self._svc())
        self.assertIsNotNone(s.created_at)

    def test_add_duplicate_no_exception(self):
        self.mgr.add_service(self._svc("dup"))
        self.mgr.add_service(self._svc("dup"))  # should warn, not raise

    def test_get_status_empty(self):
        self.assertEqual(self.mgr.get_status(), [])

    def test_get_status_returns_added_services(self):
        self.mgr.add_service(self._svc("svc1"))
        self.mgr.add_service(self._svc("svc2", "https://b.com"))
        services = self.mgr.get_status()
        self.assertEqual(len(services), 2)
        names = {s.name for s in services}
        self.assertIn("svc1", names)
        self.assertIn("svc2", names)

    def test_check_nonexistent_service_returns_none(self):
        result = self.mgr.check_service("ghost")
        self.assertIsNone(result)

    def test_check_service_operational_on_200(self):
        self.mgr.add_service(self._svc("healthy"))
        mock_resp = MagicMock()
        mock_resp.status = 200
        mock_resp.__enter__ = lambda s: s
        mock_resp.__exit__ = MagicMock(return_value=False)
        with patch("urllib.request.urlopen", return_value=mock_resp):
            svc = self.mgr.check_service("healthy")
        self.assertEqual(svc.status, "operational")

    def test_check_service_down_on_network_error(self):
        self.mgr.add_service(self._svc("flaky"))
        with patch("urllib.request.urlopen", side_effect=Exception("timeout")):
            svc = self.mgr.check_service("flaky")
        self.assertEqual(svc.status, "down")

    def test_check_service_degraded_on_5xx(self):
        import urllib.error
        self.mgr.add_service(self._svc("bad"))
        err = urllib.error.HTTPError(url="", code=503, msg="err", hdrs=None, fp=None)
        with patch("urllib.request.urlopen", side_effect=err):
            svc = self.mgr.check_service("bad")
        self.assertEqual(svc.status, "down")

    def test_uptime_tracked_after_checks(self):
        self.mgr.add_service(self._svc("uptest"))
        mock_resp = MagicMock()
        mock_resp.status = 200
        mock_resp.__enter__ = lambda s: s
        mock_resp.__exit__ = MagicMock(return_value=False)
        with patch("urllib.request.urlopen", return_value=mock_resp):
            svc = self.mgr.check_service("uptest")
        self.assertGreaterEqual(svc.uptime_pct, 0.0)
        self.assertLessEqual(svc.uptime_pct, 100.0)

    def test_export_report_json_structure(self):
        self.mgr.add_service(self._svc("export-svc"))
        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            path = f.name
        try:
            self.mgr.export_report(path)
            with open(path) as f:
                data = json.load(f)
            self.assertIn("services", data)
            self.assertIn("summary", data)
            self.assertIn("exported_at", data)
        finally:
            os.unlink(path)

    def test_status_color_helper(self):
        self.assertEqual(sb.status_color("operational"), sb.GREEN)
        self.assertEqual(sb.status_color("degraded"), sb.YELLOW)
        self.assertEqual(sb.status_color("down"), sb.RED)


if __name__ == "__main__":
    unittest.main()
