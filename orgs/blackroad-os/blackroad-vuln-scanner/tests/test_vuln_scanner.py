"""Tests for BlackRoad Vulnerability Scanner."""

import json
import os
import tempfile

import pytest

from src.vuln_scanner import (
    SEVERITY_SCORES,
    ScanResult,
    Vulnerability,
    VulnerabilityScanner,
)


def make_scanner(tmp_path):
    return VulnerabilityScanner(db_path=str(tmp_path / "test.db"))


# ---------------------------------------------------------------------------
# Dependency scanning
# ---------------------------------------------------------------------------

def test_scan_dependencies_finds_vuln(tmp_path):
    req = tmp_path / "requirements.txt"
    req.write_text("requests==2.27.0\npillow==9.0.0\n")
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dependencies(str(req))
    assert isinstance(result, ScanResult)
    assert result.total >= 1
    cves = [v.cve for v in result.vulnerabilities]
    assert any("CVE" in c for c in cves)


def test_scan_dependencies_no_vulns(tmp_path):
    req = tmp_path / "requirements.txt"
    req.write_text("requests==2.31.0\n")
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dependencies(str(req))
    assert result.total == 0


def test_scan_dependencies_multiple_packages(tmp_path):
    req = tmp_path / "requirements.txt"
    req.write_text(
        "flask==2.2.0\n"
        "werkzeug==2.1.0\n"
        "pyyaml==5.4.1\n"
        "requests==2.31.0\n"
    )
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dependencies(str(req))
    assert result.total >= 3


def test_scan_dependencies_skips_comments(tmp_path):
    req = tmp_path / "requirements.txt"
    req.write_text(
        "# This is a comment\n"
        "requests==2.31.0\n"
        "# flask==2.2.0  (commented out)\n"
    )
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dependencies(str(req))
    assert result.total == 0


def test_scan_dependencies_file_not_found(tmp_path):
    scanner = make_scanner(tmp_path)
    with pytest.raises(FileNotFoundError):
        scanner.scan_dependencies(str(tmp_path / "nonexistent.txt"))


# ---------------------------------------------------------------------------
# Dockerfile scanning
# ---------------------------------------------------------------------------

def test_scan_dockerfile_detects_latest(tmp_path):
    df = tmp_path / "Dockerfile"
    df.write_text("FROM python:latest\nRUN pip install flask\n")
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dockerfile(str(df))
    assert result.total >= 1


def test_scan_dockerfile_detects_curl_pipe(tmp_path):
    df = tmp_path / "Dockerfile"
    df.write_text(
        "FROM python:3.11\n"
        "RUN curl https://example.com/install.sh | bash\n"
    )
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dockerfile(str(df))
    descriptions = [v.description for v in result.vulnerabilities]
    assert any("curl" in d.lower() or "supply" in d.lower() for d in descriptions)


def test_scan_dockerfile_detects_root_user(tmp_path):
    df = tmp_path / "Dockerfile"
    df.write_text("FROM ubuntu:20.04\nUSER root\nRUN apt-get update\n")
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dockerfile(str(df))
    assert result.total >= 1


def test_scan_dockerfile_clean(tmp_path):
    df = tmp_path / "Dockerfile"
    df.write_text(
        "FROM python:3.11-slim\n"
        "WORKDIR /app\n"
        "COPY requirements.txt .\n"
        "RUN pip install -r requirements.txt\n"
        "USER nobody\n"
        "CMD [\"python\", \"app.py\"]\n"
    )
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dockerfile(str(df))
    # Clean Dockerfile should have no CRITICAL or HIGH findings
    assert result.critical == 0


def test_scan_dockerfile_file_not_found(tmp_path):
    scanner = make_scanner(tmp_path)
    with pytest.raises(FileNotFoundError):
        scanner.scan_dockerfile(str(tmp_path / "NoDockerfile"))


# ---------------------------------------------------------------------------
# Env file scanning
# ---------------------------------------------------------------------------

def test_scan_env_files_detects_secret(tmp_path):
    env_file = tmp_path / ".env"
    env_file.write_text(
        "DATABASE_URL=postgres://user:pass@host/db\n"
        "API_KEY=supersecret123\n"
    )
    scanner = make_scanner(tmp_path)
    result = scanner.scan_env_files(str(tmp_path))
    assert result.total >= 1


def test_scan_env_files_detects_aws_key(tmp_path):
    env_file = tmp_path / ".env"
    env_file.write_text("AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE\n")
    scanner = make_scanner(tmp_path)
    result = scanner.scan_env_files(str(tmp_path))
    assert result.total >= 1


def test_scan_env_files_no_secrets(tmp_path):
    env_file = tmp_path / ".env"
    env_file.write_text("DEBUG=true\nPORT=8080\nNODE_ENV=production\n")
    scanner = make_scanner(tmp_path)
    result = scanner.scan_env_files(str(tmp_path))
    assert result.total == 0


def test_scan_env_files_directory_not_found(tmp_path):
    scanner = make_scanner(tmp_path)
    with pytest.raises(FileNotFoundError):
        scanner.scan_env_files(str(tmp_path / "nonexistent_dir"))


# ---------------------------------------------------------------------------
# Severity scoring
# ---------------------------------------------------------------------------

def test_severity_score_critical_higher(tmp_path):
    scanner = make_scanner(tmp_path)
    crit = Vulnerability("id1", "CVE-2023-0001", "CRITICAL", "desc", "pkg", "1.0", "", "", 0)
    low = Vulnerability("id2", "CVE-2023-0002", "LOW", "desc", "pkg", "1.0", "", "", 0)
    assert scanner.severity_score(crit) > scanner.severity_score(low)


def test_severity_score_real_cve_bonus(tmp_path):
    scanner = make_scanner(tmp_path)
    real_cve = Vulnerability("id1", "CVE-2023-0001", "HIGH", "d", "p", "1.0", "", "", 0)
    fake_cve = Vulnerability("id2", "DOCKER-ABCD", "HIGH", "d", "p", "1.0", "", "", 0)
    assert scanner.severity_score(real_cve) > scanner.severity_score(fake_cve)


def test_severity_scores_dict_keys():
    assert set(SEVERITY_SCORES.keys()) == {"CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"}
    assert SEVERITY_SCORES["CRITICAL"] > SEVERITY_SCORES["HIGH"]
    assert SEVERITY_SCORES["HIGH"] > SEVERITY_SCORES["MEDIUM"]


# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------

def test_generate_report_json(tmp_path):
    scanner = make_scanner(tmp_path)
    v = Vulnerability("id1", "CVE-2023-0001", "HIGH", "test", "pkg", "1.0", "2.0", "f.py", 5)
    report = scanner.generate_report([v], format="json")
    data = json.loads(report)
    assert len(data) == 1
    assert data[0]["cve"] == "CVE-2023-0001"


def test_generate_report_csv(tmp_path):
    scanner = make_scanner(tmp_path)
    v = Vulnerability("id1", "CVE-2023-0001", "HIGH", "test", "pkg", "1.0", "2.0", "f.py", 5)
    report = scanner.generate_report([v], format="csv")
    assert "CVE-2023-0001" in report
    assert "cve" in report  # header row


def test_generate_report_text_empty(tmp_path):
    scanner = make_scanner(tmp_path)
    report = scanner.generate_report([], format="text")
    assert "No vulnerabilities found" in report


def test_generate_report_text_with_vulns(tmp_path):
    scanner = make_scanner(tmp_path)
    v = Vulnerability("id1", "CVE-2023-0001", "CRITICAL", "test desc", "mypkg", "1.0", "2.0")
    report = scanner.generate_report([v], format="text")
    assert "CRITICAL" in report
    assert "CVE-2023-0001" in report
    assert "mypkg" in report


# ---------------------------------------------------------------------------
# Database persistence
# ---------------------------------------------------------------------------

def test_get_stats_returns_dict(tmp_path):
    scanner = make_scanner(tmp_path)
    stats = scanner.get_stats()
    assert "total_scans" in stats
    assert "total_vulns" in stats
    assert "critical" in stats
    assert "high" in stats


def test_get_scan_history_after_scan(tmp_path):
    req = tmp_path / "requirements.txt"
    req.write_text("requests==2.27.0\n")
    scanner = make_scanner(tmp_path)
    scanner.scan_dependencies(str(req))
    history = scanner.get_scan_history()
    assert len(history) >= 1
    assert history[0]["scan_type"] == "dependency"


def test_get_vulns_by_scan(tmp_path):
    req = tmp_path / "requirements.txt"
    req.write_text("requests==2.27.0\n")
    scanner = make_scanner(tmp_path)
    result = scanner.scan_dependencies(str(req))
    vulns = scanner.get_vulns_by_scan(result.scan_id)
    assert len(vulns) == result.total
    for v in vulns:
        assert isinstance(v, Vulnerability)


def test_stats_increment_after_scans(tmp_path):
    scanner = make_scanner(tmp_path)

    # Initially empty
    stats_before = scanner.get_stats()
    assert stats_before["total_scans"] == 0

    # Run a scan
    req = tmp_path / "requirements.txt"
    req.write_text("cryptography==40.0.0\n")
    scanner.scan_dependencies(str(req))

    stats_after = scanner.get_stats()
    assert stats_after["total_scans"] == 1
    assert stats_after["total_vulns"] >= 1


# ---------------------------------------------------------------------------
# ScanResult data class
# ---------------------------------------------------------------------------

def test_scan_result_counts_are_correct():
    vulns = [
        Vulnerability("v1", "CVE-1", "CRITICAL", "d", "p", "1"),
        Vulnerability("v2", "CVE-2", "HIGH", "d", "p", "1"),
        Vulnerability("v3", "CVE-3", "HIGH", "d", "p", "1"),
        Vulnerability("v4", "CVE-4", "MEDIUM", "d", "p", "1"),
        Vulnerability("v5", "CVE-5", "LOW", "d", "p", "1"),
    ]
    result = ScanResult(
        scan_id="test-scan",
        timestamp="2024-01-01T00:00:00+00:00",
        scan_type="dependency",
        target="test",
        vulnerabilities=vulns,
    )
    assert result.total == 5
    assert result.critical == 1
    assert result.high == 2
    assert result.medium == 1
    assert result.low == 1
