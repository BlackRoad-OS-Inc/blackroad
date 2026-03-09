"""
BlackRoad Vulnerability Scanner
================================
Production-quality dependency, Dockerfile, and environment-file
vulnerability scanner with SQLite persistence and multi-format reporting.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import sqlite3
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# CVE Database
# ---------------------------------------------------------------------------

CVE_DB: List[Dict] = [
    {
        "cve": "CVE-2023-32681",
        "package": "requests",
        "version_pattern": r"^(?:[01]\.|2\.(?:[0-2]\d?\.|30\.|[0-9]\.|[1-2][0-9]\.))",
        "severity": "HIGH",
        "description": "requests before 2.31.0 leaks Proxy-Authorization headers to destination "
                        "servers when following redirects to a different host.",
        "fix_version": "2.31.0",
    },
    {
        "cve": "CVE-2023-44271",
        "package": "pillow",
        "version_pattern": r"^(?:[0-9]\.|10\.0\.0)",
        "severity": "HIGH",
        "description": "Pillow before 10.0.1 is vulnerable to uncontrolled resource consumption "
                        "when parsing specially crafted image files.",
        "fix_version": "10.0.1",
    },
    {
        "cve": "CVE-2023-30861",
        "package": "flask",
        "version_pattern": r"^(?:[01]\.|2\.(?:[0-2]\.|3\.[01]))",
        "severity": "HIGH",
        "description": "Flask before 2.3.2 may allow session cookie re-use when using a "
                        "caching proxy, leaking session data.",
        "fix_version": "2.3.2",
    },
    {
        "cve": "CVE-2023-25577",
        "package": "werkzeug",
        "version_pattern": r"^(?:[01]\.|2\.(?:[01]\.|2\.[0-2]))",
        "severity": "HIGH",
        "description": "Werkzeug before 2.2.3 allows a denial of service via specially "
                        "crafted multipart form data with many fields.",
        "fix_version": "2.2.3",
    },
    {
        "cve": "CVE-2023-6395",
        "package": "pyyaml",
        "version_pattern": r"^(?:[0-5]\.|6\.0(?:\.0)?$)",
        "severity": "CRITICAL",
        "description": "PyYAML before 6.0.1 is vulnerable to arbitrary code execution "
                        "when loading untrusted YAML with the default Loader.",
        "fix_version": "6.0.1",
    },
    {
        "cve": "CVE-2023-43804",
        "package": "urllib3",
        "version_pattern": r"^(?:1\.|2\.0\.[0-6])",
        "severity": "HIGH",
        "description": "urllib3 before 2.0.7 does not strip the Cookie header on cross-origin "
                        "redirects, potentially exposing credentials.",
        "fix_version": "2.0.7",
    },
    {
        "cve": "CVE-2023-28370",
        "package": "tornado",
        "version_pattern": r"^(?:[0-5]\.|6\.[0-2]\.|6\.3\.[01])",
        "severity": "MEDIUM",
        "description": "Tornado before 6.3.2 has an open redirect vulnerability in "
                        "StaticFileHandler.",
        "fix_version": "6.3.2",
    },
    {
        "cve": "CVE-2021-43818",
        "package": "lxml",
        "version_pattern": r"^(?:[0-3]\.|4\.[0-6]\.)",
        "severity": "HIGH",
        "description": "lxml before 4.7.1 has a Cross-Site Scripting (XSS) vulnerability "
                        "in the HTML5 serializer.",
        "fix_version": "4.7.1",
    },
    {
        "cve": "CVE-2022-40897",
        "package": "setuptools",
        "version_pattern": r"^(?:[0-9]\.|[1-5]\d\.|6[0-5]\.)",
        "severity": "HIGH",
        "description": "setuptools before 65.5.1 allows remote code execution via a "
                        "crafted HTML file in the package_index module.",
        "fix_version": "65.5.1",
    },
    {
        "cve": "CVE-2024-23334",
        "package": "aiohttp",
        "version_pattern": r"^(?:[0-2]\.|3\.[0-8]\.|3\.9\.[01])",
        "severity": "HIGH",
        "description": "aiohttp before 3.9.2 allows directory traversal via a crafted "
                        "URL path in the static file handler.",
        "fix_version": "3.9.2",
    },
    {
        "cve": "CVE-2023-29483",
        "package": "dnspython",
        "version_pattern": r"^(?:[01]\.|2\.[0-3]\.|2\.4\.[01])",
        "severity": "MEDIUM",
        "description": "dnspython before 2.4.2 allows a Denial-of-Service attack via "
                        "CPU exhaustion when processing specially crafted DNS responses.",
        "fix_version": "2.4.2",
    },
    {
        "cve": "CVE-2022-42969",
        "package": "py",
        "version_pattern": r"^(?:0\.|1\.(?:[0-9]\.|10\.|11\.0))",
        "severity": "HIGH",
        "description": "py before 1.11.0 allows ReDoS (Regular Expression Denial of "
                        "Service) via crafted arguments to the py.path.svnwc module.",
        "fix_version": "1.11.0",
    },
    {
        "cve": "CVE-2023-24816",
        "package": "ipython",
        "version_pattern": r"^(?:[0-7]\.|8\.[0-9]\b)",
        "severity": "HIGH",
        "description": "IPython before 8.10 allows command injection via crafted "
                        "filenames passed to the %run magic command.",
        "fix_version": "8.10.0",
    },
    {
        "cve": "CVE-2022-35737",
        "package": "starlette",
        "version_pattern": r"^(?:0\.[0-9]\.|0\.1[0-9]\.|0\.20\.[0-3])",
        "severity": "HIGH",
        "description": "Starlette before 0.20.4 allows Path Traversal via a crafted "
                        "URL in its StaticFiles handler.",
        "fix_version": "0.20.4",
    },
    {
        "cve": "CVE-2023-49083",
        "package": "cryptography",
        "version_pattern": r"^(?:[0-9]\.|[1-3]\d\.|40\.|41\.0\.0)",
        "severity": "CRITICAL",
        "description": "cryptography before 41.0.0 is vulnerable to NULL pointer "
                        "dereference when loading PKCS12 files with a NULL password.",
        "fix_version": "41.0.0",
    },
]

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

SEVERITY_SCORES: Dict[str, float] = {
    "CRITICAL": 10.0,
    "HIGH": 7.0,
    "MEDIUM": 4.0,
    "LOW": 2.0,
    "INFO": 1.0,
}

SENSITIVE_ENV_PATTERNS: List[Tuple[str, str]] = [
    (r"(?i)password\s*=\s*\S+", "Plaintext password detected"),
    (r"(?i)passwd\s*=\s*\S+", "Plaintext password detected"),
    (r"(?i)secret\s*=\s*\S+", "Plaintext secret detected"),
    (r"(?i)api[_-]?key\s*=\s*\S+", "API key detected"),
    (r"(?i)auth[_-]?token\s*=\s*\S+", "Auth token detected"),
    (r"(?i)access[_-]?token\s*=\s*\S+", "Access token detected"),
    (r"(?i)private[_-]?key\s*=\s*\S+", "Private key detected"),
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key ID detected"),
    (r"(?i)aws[_-]?secret[_-]?access[_-]?key\s*=\s*\S+", "AWS Secret Access Key detected"),
    (r"(?i)database[_-]?url\s*=\s*\S+", "Database URL (may contain credentials)"),
    (r"(?i)db[_-]?password\s*=\s*\S+", "Database password detected"),
    (r"(?i)jwt[_-]?secret\s*=\s*\S+", "JWT secret detected"),
    (r"(?i)encryption[_-]?key\s*=\s*\S+", "Encryption key detected"),
    (r"(?i)stripe[_-]?(?:secret|api)[_-]?key\s*=\s*\S+", "Stripe API key detected"),
    (r"(?i)github[_-]?token\s*=\s*\S+", "GitHub token detected"),
    (r"(?i)slack[_-]?(?:token|webhook)\s*=\s*\S+", "Slack token/webhook detected"),
    (r"(?i)twilio[_-]?auth[_-]?token\s*=\s*\S+", "Twilio auth token detected"),
    (r"(?i)sendgrid[_-]?api[_-]?key\s*=\s*\S+", "SendGrid API key detected"),
]

DOCKERFILE_ISSUES: List[Tuple[str, str, str]] = [
    (
        r"FROM\s+\S+:latest",
        "HIGH",
        "Using ':latest' tag is non-deterministic and may pull untested images",
    ),
    (
        r"curl\s+.*\|\s*(?:bash|sh)",
        "CRITICAL",
        "Piping curl output directly into shell is a supply-chain attack vector",
    ),
    (
        r"wget\s+.*\|\s*(?:bash|sh)",
        "CRITICAL",
        "Piping wget output directly into shell is a supply-chain attack vector",
    ),
    (
        r"chmod\s+777",
        "HIGH",
        "chmod 777 grants world-writable permissions — least-privilege violation",
    ),
    (
        r"USER\s+root",
        "HIGH",
        "Running container as root increases blast radius on container escape",
    ),
    (
        r"ENV\s+\S*(?:PASSWORD|SECRET|TOKEN|KEY|PASS)\S*\s*=\s*\S+",
        "CRITICAL",
        "Secrets embedded in ENV statements are visible in image metadata",
    ),
    (
        r"ARG\s+\S*(?:PASSWORD|SECRET|TOKEN|KEY|PASS)\S*",
        "HIGH",
        "Secrets passed as ARG are stored in image build history",
    ),
    (
        r"ADD\s+https?://",
        "MEDIUM",
        "ADD with a remote URL skips integrity checks; prefer COPY + verified download",
    ),
    (
        r"RUN\s+.*--no-check-certificate",
        "HIGH",
        "Disabling certificate validation opens MITM attack surface",
    ),
    (
        r"RUN\s+.*apt-get install\s+(?!-y)(?!.*-y)",
        "LOW",
        "apt-get install without -y may hang in non-interactive builds",
    ),
    (
        r"EXPOSE\s+22\b",
        "MEDIUM",
        "Exposing SSH port 22 in a container is a security anti-pattern",
    ),
]


# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class Vulnerability:
    """Represents a single detected vulnerability."""

    id: str
    cve: str
    severity: str
    description: str
    package: str
    version_affected: str
    fix_version: str = ""
    file_path: str = ""
    line_number: int = 0
    source: str = "dependency"

    def to_dict(self) -> Dict:
        return {
            "id": self.id,
            "cve": self.cve,
            "severity": self.severity,
            "description": self.description,
            "package": self.package,
            "version_affected": self.version_affected,
            "fix_version": self.fix_version,
            "file_path": self.file_path,
            "line_number": self.line_number,
            "source": self.source,
        }


@dataclass
class ScanResult:
    """Aggregated result of a single scan operation."""

    scan_id: str
    timestamp: str
    scan_type: str
    target: str
    vulnerabilities: List[Vulnerability] = field(default_factory=list)
    total: int = 0
    critical: int = 0
    high: int = 0
    medium: int = 0
    low: int = 0

    def __post_init__(self) -> None:
        self._update_counts()

    def _update_counts(self) -> None:
        self.total = len(self.vulnerabilities)
        self.critical = sum(1 for v in self.vulnerabilities if v.severity == "CRITICAL")
        self.high = sum(1 for v in self.vulnerabilities if v.severity == "HIGH")
        self.medium = sum(1 for v in self.vulnerabilities if v.severity == "MEDIUM")
        self.low = sum(
            1 for v in self.vulnerabilities if v.severity in ("LOW", "INFO")
        )

    def to_dict(self) -> Dict:
        return {
            "scan_id": self.scan_id,
            "timestamp": self.timestamp,
            "scan_type": self.scan_type,
            "target": self.target,
            "total": self.total,
            "critical": self.critical,
            "high": self.high,
            "medium": self.medium,
            "low": self.low,
            "vulnerabilities": [v.to_dict() for v in self.vulnerabilities],
        }


# ---------------------------------------------------------------------------
# Scanner
# ---------------------------------------------------------------------------

class VulnerabilityScanner:
    """
    Main scanner class that performs vulnerability detection across
    Python dependencies, Dockerfiles, and environment files.
    """

    def __init__(self, db_path: str = "vuln_scanner.db") -> None:
        self.db_path = db_path
        self._conn: Optional[sqlite3.Connection] = None
        self._init_db()

    # ------------------------------------------------------------------
    # Database helpers
    # ------------------------------------------------------------------

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(self.db_path)
            self._conn.row_factory = sqlite3.Row
        return self._conn

    def _init_db(self) -> None:
        conn = self._get_conn()
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS scans (
                scan_id   TEXT PRIMARY KEY,
                timestamp TEXT NOT NULL,
                scan_type TEXT NOT NULL,
                target    TEXT NOT NULL,
                total     INTEGER DEFAULT 0,
                critical  INTEGER DEFAULT 0,
                high      INTEGER DEFAULT 0,
                medium    INTEGER DEFAULT 0,
                low       INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS vulnerabilities (
                id              TEXT PRIMARY KEY,
                scan_id         TEXT NOT NULL REFERENCES scans(scan_id),
                cve             TEXT,
                severity        TEXT,
                description     TEXT,
                package         TEXT,
                version_affected TEXT,
                fix_version     TEXT,
                file_path       TEXT,
                line_number     INTEGER,
                source          TEXT,
                created_at      TEXT NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_vulns_scan_id
                ON vulnerabilities(scan_id);
            CREATE INDEX IF NOT EXISTS idx_vulns_severity
                ON vulnerabilities(severity);
            CREATE INDEX IF NOT EXISTS idx_scans_timestamp
                ON scans(timestamp);
            """
        )
        conn.commit()

    # ------------------------------------------------------------------
    # Utility helpers
    # ------------------------------------------------------------------

    def _generate_id(self, prefix: str = "vuln") -> str:
        raw = f"{prefix}-{datetime.now(timezone.utc).isoformat()}"
        digest = hashlib.sha256(raw.encode()).hexdigest()[:12]
        return f"{prefix}-{digest}"

    def _parse_version(self, version_str: str) -> str:
        """
        Strip pip specifiers (==, >=, ~=, etc.) and return the bare version
        string, e.g. '==2.27.0' -> '2.27.0'.
        """
        match = re.search(r"[\d]+(?:\.[\d]+)*(?:[._-][a-zA-Z0-9]+)*", version_str)
        return match.group(0) if match else version_str.strip()

    # ------------------------------------------------------------------
    # Scan: Python dependencies
    # ------------------------------------------------------------------

    def scan_dependencies(self, requirements_file: str) -> ScanResult:
        """
        Parse a requirements.txt file and check each pinned dependency
        against the built-in CVE database.
        """
        req_path = Path(requirements_file)
        if not req_path.exists():
            raise FileNotFoundError(f"Requirements file not found: {requirements_file}")

        scan_id = self._generate_id("scan")
        timestamp = datetime.now(timezone.utc).isoformat()
        vulnerabilities: List[Vulnerability] = []

        lines = req_path.read_text(encoding="utf-8").splitlines()
        for line_no, raw_line in enumerate(lines, start=1):
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue

            # Remove inline comments and extras like [security]
            line = re.sub(r"\s*#.*", "", line)
            line = re.sub(r"\[.*?\]", "", line)

            # Split on common specifiers
            parts = re.split(r"[><=!~;]", line, maxsplit=1)
            package_name = parts[0].strip().lower()
            version_raw = line[len(parts[0]):].strip() if len(parts) > 1 else ""
            version = self._parse_version(version_raw) if version_raw else ""

            for entry in CVE_DB:
                if entry["package"].lower() != package_name:
                    continue
                if not version:
                    # No version pinned — flag conservatively as INFO
                    vuln = Vulnerability(
                        id=self._generate_id("vuln"),
                        cve=entry["cve"],
                        severity="INFO",
                        description=f"No version pinned for {package_name}; "
                                    f"potentially vulnerable. {entry['description']}",
                        package=package_name,
                        version_affected="unpinned",
                        fix_version=entry["fix_version"],
                        file_path=str(req_path),
                        line_number=line_no,
                        source="dependency",
                    )
                    vulnerabilities.append(vuln)
                    continue

                try:
                    if re.match(entry["version_pattern"], version):
                        vuln = Vulnerability(
                            id=self._generate_id("vuln"),
                            cve=entry["cve"],
                            severity=entry["severity"],
                            description=entry["description"],
                            package=package_name,
                            version_affected=version,
                            fix_version=entry["fix_version"],
                            file_path=str(req_path),
                            line_number=line_no,
                            source="dependency",
                        )
                        vulnerabilities.append(vuln)
                except re.error:
                    # Malformed pattern in CVE_DB — skip gracefully
                    pass

        result = ScanResult(
            scan_id=scan_id,
            timestamp=timestamp,
            scan_type="dependency",
            target=str(req_path),
            vulnerabilities=vulnerabilities,
        )
        self._save_scan(result)
        return result

    # ------------------------------------------------------------------
    # Scan: Dockerfile
    # ------------------------------------------------------------------

    def scan_dockerfile(self, path: str) -> ScanResult:
        """
        Inspect a Dockerfile line-by-line for common security anti-patterns.
        """
        df_path = Path(path)
        if not df_path.exists():
            raise FileNotFoundError(f"Dockerfile not found: {path}")

        scan_id = self._generate_id("scan")
        timestamp = datetime.now(timezone.utc).isoformat()
        vulnerabilities: List[Vulnerability] = []

        lines = df_path.read_text(encoding="utf-8").splitlines()
        for line_no, line in enumerate(lines, start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue

            for pattern, severity, description in DOCKERFILE_ISSUES:
                if re.search(pattern, stripped, re.IGNORECASE):
                    vuln = Vulnerability(
                        id=self._generate_id("vuln"),
                        cve=f"DOCKER-{hashlib.md5(pattern.encode()).hexdigest()[:8].upper()}",
                        severity=severity,
                        description=description,
                        package="dockerfile",
                        version_affected=stripped[:80],
                        fix_version="",
                        file_path=str(df_path),
                        line_number=line_no,
                        source="dockerfile",
                    )
                    vulnerabilities.append(vuln)

        result = ScanResult(
            scan_id=scan_id,
            timestamp=timestamp,
            scan_type="dockerfile",
            target=str(df_path),
            vulnerabilities=vulnerabilities,
        )
        self._save_scan(result)
        return result

    # ------------------------------------------------------------------
    # Scan: Environment files
    # ------------------------------------------------------------------

    def scan_env_files(self, directory: str) -> ScanResult:
        """
        Recursively search a directory for .env files and flag secrets
        that match known sensitive-value patterns.
        """
        dir_path = Path(directory)
        if not dir_path.exists():
            raise FileNotFoundError(f"Directory not found: {directory}")

        scan_id = self._generate_id("scan")
        timestamp = datetime.now(timezone.utc).isoformat()
        vulnerabilities: List[Vulnerability] = []

        env_files = list(dir_path.rglob("*.env")) + list(dir_path.rglob(".env"))

        for env_file in env_files:
            try:
                lines = env_file.read_text(encoding="utf-8", errors="replace").splitlines()
            except OSError:
                continue

            for line_no, line in enumerate(lines, start=1):
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue

                for pattern, description in SENSITIVE_ENV_PATTERNS:
                    if re.search(pattern, stripped):
                        vuln = Vulnerability(
                            id=self._generate_id("vuln"),
                            cve=f"ENV-SECRET-{hashlib.md5(pattern.encode()).hexdigest()[:8].upper()}",
                            severity="HIGH",
                            description=description,
                            package="env-file",
                            version_affected=re.sub(r"=.*", "=***REDACTED***", stripped)[:100],
                            fix_version="",
                            file_path=str(env_file),
                            line_number=line_no,
                            source="env-file",
                        )
                        vulnerabilities.append(vuln)
                        break  # One finding per line is sufficient

        result = ScanResult(
            scan_id=scan_id,
            timestamp=timestamp,
            scan_type="env",
            target=str(dir_path),
            vulnerabilities=vulnerabilities,
        )
        self._save_scan(result)
        return result

    # ------------------------------------------------------------------
    # Scoring & reporting
    # ------------------------------------------------------------------

    def severity_score(self, vuln: Vulnerability) -> float:
        """Return a numeric severity score, with a small boost for real CVEs."""
        base = SEVERITY_SCORES.get(vuln.severity.upper(), 1.0)
        bonus = 1.0 if vuln.cve.upper().startswith("CVE-") else 0.0
        return base + bonus

    def generate_report(self, vulns: List[Vulnerability], format: str = "text") -> str:
        """Generate a formatted vulnerability report (text | json | csv)."""
        fmt = format.lower()
        if fmt == "json":
            return json.dumps([v.to_dict() for v in vulns], indent=2, default=str)
        if fmt == "csv":
            return self._csv_report(vulns)
        return self._text_report(vulns)

    def _text_report(self, vulns: List[Vulnerability]) -> str:
        if not vulns:
            return "✅  No vulnerabilities found.\n"

        sorted_vulns = sorted(vulns, key=self.severity_score, reverse=True)

        counts: Dict[str, int] = {}
        for v in sorted_vulns:
            counts[v.severity] = counts.get(v.severity, 0) + 1

        lines = [
            "=" * 72,
            "  BLACKROAD VULNERABILITY SCAN REPORT",
            "=" * 72,
            f"  Generated : {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}",
            f"  Total     : {len(vulns)}",
        ]
        for sev in ("CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"):
            if counts.get(sev, 0):
                lines.append(f"  {sev:<9}: {counts[sev]}")
        lines.append("=" * 72)
        lines.append("")

        for idx, v in enumerate(sorted_vulns, start=1):
            badge = {
                "CRITICAL": "🔴",
                "HIGH": "🟠",
                "MEDIUM": "🟡",
                "LOW": "🔵",
                "INFO": "⚪",
            }.get(v.severity, "❓")
            lines.append(f"[{idx:03d}] {badge} {v.severity:<8}  {v.cve}")
            lines.append(f"       Package  : {v.package}")
            lines.append(f"       Affected : {v.version_affected}")
            if v.fix_version:
                lines.append(f"       Fix      : >= {v.fix_version}")
            if v.file_path:
                loc = f"{v.file_path}"
                if v.line_number:
                    loc += f":{v.line_number}"
                lines.append(f"       Location : {loc}")
            lines.append(f"       Detail   : {v.description}")
            lines.append("")

        lines.append("=" * 72)
        return "\n".join(lines) + "\n"

    def _csv_report(self, vulns: List[Vulnerability]) -> str:
        buf = io.StringIO()
        fieldnames = [
            "id", "cve", "severity", "package", "version_affected",
            "fix_version", "file_path", "line_number", "description", "source",
        ]
        writer = csv.DictWriter(buf, fieldnames=fieldnames)
        writer.writeheader()
        for v in sorted(vulns, key=self.severity_score, reverse=True):
            d = v.to_dict()
            writer.writerow({k: d[k] for k in fieldnames})
        return buf.getvalue()

    # ------------------------------------------------------------------
    # Persistence helpers
    # ------------------------------------------------------------------

    def _save_scan(self, scan: ScanResult) -> None:
        conn = self._get_conn()
        conn.execute(
            """
            INSERT OR REPLACE INTO scans
                (scan_id, timestamp, scan_type, target, total, critical, high, medium, low)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                scan.scan_id,
                scan.timestamp,
                scan.scan_type,
                scan.target,
                scan.total,
                scan.critical,
                scan.high,
                scan.medium,
                scan.low,
            ),
        )
        now = datetime.now(timezone.utc).isoformat()
        for v in scan.vulnerabilities:
            conn.execute(
                """
                INSERT OR REPLACE INTO vulnerabilities
                    (id, scan_id, cve, severity, description, package,
                     version_affected, fix_version, file_path, line_number, source, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    v.id,
                    scan.scan_id,
                    v.cve,
                    v.severity,
                    v.description,
                    v.package,
                    v.version_affected,
                    v.fix_version,
                    v.file_path,
                    v.line_number,
                    v.source,
                    now,
                ),
            )
        conn.commit()

    def get_scan_history(self, limit: int = 20) -> List[Dict]:
        conn = self._get_conn()
        rows = conn.execute(
            """
            SELECT scan_id, timestamp, scan_type, target, total, critical, high, medium, low
            FROM scans
            ORDER BY timestamp DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()
        return [dict(row) for row in rows]

    def get_vulns_by_scan(self, scan_id: str) -> List[Vulnerability]:
        conn = self._get_conn()
        rows = conn.execute(
            "SELECT * FROM vulnerabilities WHERE scan_id = ?", (scan_id,)
        ).fetchall()
        result = []
        for row in rows:
            r = dict(row)
            result.append(
                Vulnerability(
                    id=r["id"],
                    cve=r["cve"] or "",
                    severity=r["severity"] or "INFO",
                    description=r["description"] or "",
                    package=r["package"] or "",
                    version_affected=r["version_affected"] or "",
                    fix_version=r["fix_version"] or "",
                    file_path=r["file_path"] or "",
                    line_number=r["line_number"] or 0,
                    source=r["source"] or "unknown",
                )
            )
        return result

    def get_stats(self) -> Dict:
        conn = self._get_conn()
        row = conn.execute(
            """
            SELECT
                COUNT(DISTINCT s.scan_id)                        AS total_scans,
                COUNT(v.id)                                      AS total_vulns,
                SUM(CASE WHEN v.severity='CRITICAL' THEN 1 ELSE 0 END) AS critical,
                SUM(CASE WHEN v.severity='HIGH'     THEN 1 ELSE 0 END) AS high,
                SUM(CASE WHEN v.severity='MEDIUM'   THEN 1 ELSE 0 END) AS medium,
                SUM(CASE WHEN v.severity='LOW'      THEN 1 ELSE 0 END) AS low
            FROM scans s
            LEFT JOIN vulnerabilities v ON s.scan_id = v.scan_id
            """
        ).fetchone()
        d = dict(row) if row else {}
        return {
            "total_scans": d.get("total_scans") or 0,
            "total_vulns": d.get("total_vulns") or 0,
            "critical": d.get("critical") or 0,
            "high": d.get("high") or 0,
            "medium": d.get("medium") or 0,
            "low": d.get("low") or 0,
        }

    def close(self) -> None:
        if self._conn:
            self._conn.close()
            self._conn = None


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="vuln-scanner",
        description="BlackRoad Vulnerability Scanner — detect CVEs, Dockerfile "
                    "issues, and leaked secrets.",
    )
    parser.add_argument(
        "--db",
        default="vuln_scanner.db",
        metavar="PATH",
        help="Path to the SQLite database (default: vuln_scanner.db)",
    )

    subs = parser.add_subparsers(dest="command", required=True)

    # deps
    p_deps = subs.add_parser("deps", help="Scan a requirements.txt for CVEs")
    p_deps.add_argument("file", help="Path to requirements.txt")
    p_deps.add_argument(
        "--format",
        choices=["text", "json", "csv"],
        default="text",
        help="Output format (default: text)",
    )

    # docker
    p_docker = subs.add_parser("docker", help="Scan a Dockerfile for security issues")
    p_docker.add_argument("file", help="Path to Dockerfile")
    p_docker.add_argument(
        "--format",
        choices=["text", "json", "csv"],
        default="text",
        help="Output format (default: text)",
    )

    # env
    p_env = subs.add_parser("env", help="Scan a directory for .env file secrets")
    p_env.add_argument("directory", help="Directory to search recursively")
    p_env.add_argument(
        "--format",
        choices=["text", "json", "csv"],
        default="text",
        help="Output format (default: text)",
    )

    # history
    subs.add_parser("history", help="Show recent scan history")

    # stats
    subs.add_parser("stats", help="Show aggregate vulnerability statistics")

    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    scanner = VulnerabilityScanner(db_path=args.db)

    try:
        if args.command == "deps":
            result = scanner.scan_dependencies(args.file)
            print(scanner.generate_report(result.vulnerabilities, format=args.format))
            return 1 if result.total > 0 else 0

        elif args.command == "docker":
            result = scanner.scan_dockerfile(args.file)
            print(scanner.generate_report(result.vulnerabilities, format=args.format))
            return 1 if result.total > 0 else 0

        elif args.command == "env":
            result = scanner.scan_env_files(args.directory)
            print(scanner.generate_report(result.vulnerabilities, format=args.format))
            return 1 if result.total > 0 else 0

        elif args.command == "history":
            history = scanner.get_scan_history()
            if not history:
                print("No scans recorded yet.")
                return 0
            print(f"{'SCAN ID':<20} {'TIMESTAMP':<28} {'TYPE':<12} {'TOTAL':>5} "
                  f"{'CRIT':>5} {'HIGH':>5} {'MED':>5} {'LOW':>5}")
            print("-" * 90)
            for row in history:
                print(
                    f"{row['scan_id']:<20} {row['timestamp']:<28} "
                    f"{row['scan_type']:<12} {row['total']:>5} {row['critical']:>5} "
                    f"{row['high']:>5} {row['medium']:>5} {row['low']:>5}"
                )
            return 0

        elif args.command == "stats":
            stats = scanner.get_stats()
            print(f"Total scans       : {stats['total_scans']}")
            print(f"Total findings    : {stats['total_vulns']}")
            print(f"  CRITICAL        : {stats['critical']}")
            print(f"  HIGH            : {stats['high']}")
            print(f"  MEDIUM          : {stats['medium']}")
            print(f"  LOW             : {stats['low']}")
            return 0

    except FileNotFoundError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2
    finally:
        scanner.close()

    return 0


if __name__ == "__main__":
    sys.exit(main())
