#!/usr/bin/env python3
"""
BlackRoad Terraform Module Registry
Production-grade registry for managing, generating, and validating Terraform modules.
"""

from __future__ import annotations

import json
import os
import re
import sqlite3
import uuid
from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional
import textwrap

try:
    import typer
    from rich.console import Console
    from rich.table import Table
    from rich.syntax import Syntax
    from rich.panel import Panel
    from rich.markdown import Markdown
    HAS_RICH = True
except ImportError:
    HAS_RICH = False

DB_PATH = Path.home() / ".blackroad" / "terraform-modules.db"
console = Console() if HAS_RICH else None

# ──────────────────────────────────────────────────────────────
# Dataclasses
# ──────────────────────────────────────────────────────────────

@dataclass
class TerraformVariable:
    name: str
    type: str  # string | number | bool | list | map | object
    description: str = ""
    default: Optional[Any] = None
    required: bool = True
    sensitive: bool = False

    def to_hcl(self) -> str:
        lines = [f'variable "{self.name}" {{']
        lines.append(f'  type        = {self.type}')
        if self.description:
            lines.append(f'  description = "{self.description}"')
        if self.default is not None:
            val = json.dumps(self.default) if not isinstance(self.default, str) else f'"{self.default}"'
            lines.append(f'  default     = {val}')
        if self.sensitive:
            lines.append('  sensitive   = true')
        lines.append('}')
        return "\n".join(lines)


@dataclass
class TerraformOutput:
    name: str
    description: str = ""
    value_expression: str = ""
    sensitive: bool = False

    def to_hcl(self) -> str:
        lines = [f'output "{self.name}" {{']
        if self.description:
            lines.append(f'  description = "{self.description}"')
        lines.append(f'  value       = {self.value_expression}')
        if self.sensitive:
            lines.append('  sensitive   = true')
        lines.append('}')
        return "\n".join(lines)


@dataclass
class TerraformExample:
    title: str
    description: str = ""
    hcl_code: str = ""


@dataclass
class TerraformModule:
    id: str
    name: str
    provider: str          # aws | gcp | azure | kubernetes | helm | null
    resource_type: str
    version: str           # semver
    description: str
    hcl_template: str      # uses ${var.name} placeholders
    variables: list[TerraformVariable] = field(default_factory=list)
    outputs: list[TerraformOutput] = field(default_factory=list)
    examples: list[TerraformExample] = field(default_factory=list)
    tags: list[str] = field(default_factory=list)
    created_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    download_count: int = 0

    def bump_version(self, part: str = "patch") -> str:
        major, minor, patch = map(int, self.version.split("."))
        if part == "major":
            major += 1; minor = 0; patch = 0
        elif part == "minor":
            minor += 1; patch = 0
        else:
            patch += 1
        self.version = f"{major}.{minor}.{patch}"
        return self.version


@dataclass
class ValidationResult:
    valid: bool
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    def __str__(self) -> str:
        lines = [f"Valid: {self.valid}"]
        for e in self.errors:
            lines.append(f"  ERROR: {e}")
        for w in self.warnings:
            lines.append(f"  WARN:  {w}")
        return "\n".join(lines)


# ──────────────────────────────────────────────────────────────
# Registry
# ──────────────────────────────────────────────────────────────

class TerraformRegistry:
    PROVIDERS = {"aws", "gcp", "azure", "kubernetes", "helm", "null"}
    VAR_TYPES  = {"string", "number", "bool", "list", "map", "object",
                  "list(string)", "list(number)", "map(string)", "map(any)", "any"}

    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()
        self._seed_builtin_modules()

    # ── DB helpers ────────────────────────────────────────────

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self._conn() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS modules (
                    id              TEXT PRIMARY KEY,
                    name            TEXT NOT NULL,
                    provider        TEXT NOT NULL,
                    resource_type   TEXT NOT NULL,
                    version         TEXT NOT NULL,
                    description     TEXT,
                    hcl_template    TEXT NOT NULL,
                    variables       TEXT DEFAULT '[]',
                    outputs         TEXT DEFAULT '[]',
                    examples        TEXT DEFAULT '[]',
                    tags            TEXT DEFAULT '[]',
                    created_at      TEXT,
                    download_count  INTEGER DEFAULT 0
                )
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_provider ON modules(provider)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_resource_type ON modules(resource_type)")
            conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_name ON modules(name)")

    def _row_to_module(self, row: sqlite3.Row) -> TerraformModule:
        def load(key, cls):
            raw = json.loads(row[key] or "[]")
            return [cls(**r) for r in raw]

        return TerraformModule(
            id=row["id"],
            name=row["name"],
            provider=row["provider"],
            resource_type=row["resource_type"],
            version=row["version"],
            description=row["description"] or "",
            hcl_template=row["hcl_template"],
            variables=load("variables", TerraformVariable),
            outputs=load("outputs", TerraformOutput),
            examples=[TerraformExample(**e) for e in json.loads(row["examples"] or "[]")],
            tags=json.loads(row["tags"] or "[]"),
            created_at=row["created_at"] or "",
            download_count=row["download_count"] or 0,
        )

    def _save(self, mod: TerraformModule):
        with self._conn() as conn:
            conn.execute("""
                INSERT INTO modules
                    (id, name, provider, resource_type, version, description,
                     hcl_template, variables, outputs, examples, tags, created_at, download_count)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
                ON CONFLICT(id) DO UPDATE SET
                    name=excluded.name, provider=excluded.provider,
                    resource_type=excluded.resource_type, version=excluded.version,
                    description=excluded.description, hcl_template=excluded.hcl_template,
                    variables=excluded.variables, outputs=excluded.outputs,
                    examples=excluded.examples, tags=excluded.tags,
                    download_count=excluded.download_count
            """, (
                mod.id, mod.name, mod.provider, mod.resource_type, mod.version,
                mod.description, mod.hcl_template,
                json.dumps([asdict(v) for v in mod.variables]),
                json.dumps([asdict(o) for o in mod.outputs]),
                json.dumps([asdict(e) for e in mod.examples]),
                json.dumps(mod.tags),
                mod.created_at, mod.download_count,
            ))

    # ── Public API ────────────────────────────────────────────

    def register_module(
        self,
        name: str,
        provider: str,
        resource_type: str,
        hcl_template: str,
        variables: list[TerraformVariable],
        outputs: list[TerraformOutput],
        description: str = "",
        examples: list[TerraformExample] | None = None,
        tags: list[str] | None = None,
        version: str = "1.0.0",
    ) -> TerraformModule:
        if provider not in self.PROVIDERS:
            raise ValueError(f"Unknown provider '{provider}'. Valid: {self.PROVIDERS}")
        vr = self.validate_hcl(hcl_template)
        if not vr.valid:
            raise ValueError(f"Invalid HCL template:\n{vr}")
        mod = TerraformModule(
            id=str(uuid.uuid4()),
            name=name,
            provider=provider,
            resource_type=resource_type,
            version=version,
            description=description,
            hcl_template=hcl_template,
            variables=variables,
            outputs=outputs or [],
            examples=examples or [],
            tags=tags or [],
        )
        self._save(mod)
        return mod

    def generate_tf(self, module_id_or_name: str, vars: dict) -> str:
        mod = self.get_module(module_id_or_name)
        # Validate required vars
        missing = [
            v.name for v in mod.variables
            if v.required and v.default is None and v.name not in vars
        ]
        if missing:
            raise ValueError(f"Missing required variables: {missing}")
        # Merge defaults then supplied vars
        merged: dict[str, Any] = {}
        for v in mod.variables:
            if v.default is not None:
                merged[v.name] = v.default
        merged.update(vars)
        # Substitute ${var.name}
        result = mod.hcl_template
        for k, val in merged.items():
            placeholder = f"${{var.{k}}}"
            result = result.replace(placeholder, str(val))
        # Increment download count
        with self._conn() as conn:
            conn.execute("UPDATE modules SET download_count = download_count + 1 WHERE id = ?", (mod.id,))
        return result

    def validate_hcl(self, hcl_string: str) -> ValidationResult:
        errors: list[str] = []
        warnings: list[str] = []
        # Balanced braces
        if hcl_string.count("{") != hcl_string.count("}"):
            errors.append("Unbalanced curly braces { }")
        # Balanced brackets
        if hcl_string.count("[") != hcl_string.count("]"):
            errors.append("Unbalanced square brackets [ ]")
        # Balanced parentheses
        if hcl_string.count("(") != hcl_string.count(")"):
            errors.append("Unbalanced parentheses ( )")
        # Must contain at least one resource/data/module block
        block_pattern = re.compile(
            r'\b(resource|data|module|locals|provider|terraform)\s+"[\w-]+"\s*',
            re.MULTILINE,
        )
        if not block_pattern.search(hcl_string):
            warnings.append("No resource/data/module block found — is this intentional?")
        # resource block should have two label strings
        resource_lines = [l.strip() for l in hcl_string.splitlines() if l.strip().startswith("resource")]
        for rl in resource_lines:
            parts = rl.split()
            if len(parts) < 3:
                errors.append(f"resource block missing labels: '{rl}'")
        # Variable references should not be obviously wrong
        bad_refs = re.findall(r'\$\{(?!var\.|local\.|module\.|data\.|each\.|path\.|terraform\.)[^}]+\}', hcl_string)
        for br in bad_refs:
            warnings.append(f"Suspicious interpolation (not var/local/module/data): {br}")
        # Deprecated syntax: check for old-style ${} in non-interpolation contexts
        double_dollar = re.findall(r'\$\$\{', hcl_string)
        if double_dollar:
            warnings.append("Found $${} — use $${ only for literal dollar sign escape")
        # Empty string check
        if not hcl_string.strip():
            errors.append("HCL string is empty")
        return ValidationResult(valid=len(errors) == 0, errors=errors, warnings=warnings)

    def list_modules(
        self,
        provider_filter: str | None = None,
        resource_type_filter: str | None = None,
    ) -> list[TerraformModule]:
        query = "SELECT * FROM modules WHERE 1=1"
        params: list[Any] = []
        if provider_filter:
            query += " AND provider = ?"
            params.append(provider_filter)
        if resource_type_filter:
            query += " AND resource_type = ?"
            params.append(resource_type_filter)
        query += " ORDER BY download_count DESC, name ASC"
        with self._conn() as conn:
            rows = conn.execute(query, params).fetchall()
        return [self._row_to_module(r) for r in rows]

    def get_module(self, module_id_or_name: str) -> TerraformModule:
        with self._conn() as conn:
            row = conn.execute(
                "SELECT * FROM modules WHERE id = ? OR name = ?",
                (module_id_or_name, module_id_or_name),
            ).fetchone()
        if row is None:
            raise KeyError(f"Module not found: '{module_id_or_name}'")
        return self._row_to_module(row)

    def export_plan(self, module_id_or_name: str, vars: dict) -> str:
        mod = self.get_module(module_id_or_name)
        rendered = self.generate_tf(module_id_or_name, vars)
        ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        lines = [
            "# Terraform Plan Export",
            f"# Module  : {mod.name} v{mod.version}",
            f"# Provider : {mod.provider}",
            f"# Generated: {ts}",
            "#",
            "# This plan shows what Terraform would create/modify.",
            "# Review carefully before applying.",
            "",
            f"# ── Resource: {mod.resource_type} ──────────────────────────────",
            "",
        ]
        # Parse resource blocks from rendered HCL
        resource_re = re.compile(
            r'resource\s+"([\w]+)"\s+"([\w-]+)"\s*\{([^}]*)\}',
            re.DOTALL,
        )
        matches = list(resource_re.finditer(rendered))
        if matches:
            lines.append("Changes to be applied:")
            lines.append("")
            for m in matches:
                rtype, rname, rbody = m.group(1), m.group(2), m.group(3)
                lines.append(f"  + resource \"{rtype}\" \"{rname}\" {{")
                for attr_line in rbody.strip().splitlines():
                    lines.append(f"      {attr_line.strip()}")
                lines.append("  }")
                lines.append("")
            lines.append(f"Plan: {len(matches)} to add, 0 to change, 0 to destroy.")
        else:
            lines.append("# (no resource blocks detected in rendered template)")
            lines.append("")
            lines.append(rendered)
        lines += ["", "# ── Rendered HCL ───────────────────────────────────────", "", rendered]
        return "\n".join(lines)

    def delete_module(self, module_id_or_name: str) -> bool:
        try:
            mod = self.get_module(module_id_or_name)
        except KeyError:
            return False
        with self._conn() as conn:
            conn.execute("DELETE FROM modules WHERE id = ?", (mod.id,))
        return True

    def search(self, query: str) -> list[TerraformModule]:
        q = f"%{query.lower()}%"
        with self._conn() as conn:
            rows = conn.execute(
                """SELECT * FROM modules WHERE
                   lower(name) LIKE ? OR lower(description) LIKE ?
                   OR lower(provider) LIKE ? OR lower(resource_type) LIKE ?
                   OR lower(tags) LIKE ?
                   ORDER BY download_count DESC""",
                (q, q, q, q, q),
            ).fetchall()
        return [self._row_to_module(r) for r in rows]

    def get_stats(self) -> dict:
        with self._conn() as conn:
            total = conn.execute("SELECT COUNT(*) FROM modules").fetchone()[0]
            by_provider = conn.execute(
                "SELECT provider, COUNT(*) as cnt FROM modules GROUP BY provider ORDER BY cnt DESC"
            ).fetchall()
            top = conn.execute(
                "SELECT name, provider, download_count FROM modules ORDER BY download_count DESC LIMIT 5"
            ).fetchall()
        return {
            "total_modules": total,
            "by_provider": {r["provider"]: r["cnt"] for r in by_provider},
            "most_downloaded": [
                {"name": r["name"], "provider": r["provider"], "downloads": r["download_count"]}
                for r in top
            ],
        }

    def generate_docs(self, module_id_or_name: str) -> str:
        mod = self.get_module(module_id_or_name)
        lines = [
            f"# {mod.name}",
            "",
            f"> **Provider:** `{mod.provider}` | **Resource:** `{mod.resource_type}` | **Version:** `{mod.version}`",
            "",
            mod.description,
            "",
            "## Variables",
            "",
            "| Name | Type | Required | Sensitive | Default | Description |",
            "| ---- | ---- | :------: | :-------: | ------- | ----------- |",
        ]
        for v in mod.variables:
            default = f"`{v.default}`" if v.default is not None else "—"
            req     = "✅" if v.required else "❌"
            sens    = "🔒" if v.sensitive else "—"
            lines.append(f"| `{v.name}` | `{v.type}` | {req} | {sens} | {default} | {v.description} |")
        lines += ["", "## Outputs", "", "| Name | Sensitive | Description |", "| ---- | :-------: | ----------- |"]
        for o in mod.outputs:
            sens = "🔒" if o.sensitive else "—"
            lines.append(f"| `{o.name}` | {sens} | {o.description} |")
        lines += ["", "## HCL Template", "", "```hcl", mod.hcl_template, "```", ""]
        if mod.examples:
            lines += ["## Examples", ""]
            for ex in mod.examples:
                lines += [f"### {ex.title}", "", ex.description, "", "```hcl", ex.hcl_code, "```", ""]
        if mod.tags:
            lines += ["## Tags", "", ", ".join(f"`{t}`" for t in mod.tags), ""]
        lines += [
            "## Metadata",
            "",
            f"- **ID:** `{mod.id}`",
            f"- **Created:** {mod.created_at}",
            f"- **Downloads:** {mod.download_count}",
        ]
        return "\n".join(lines)

    # ── Seed built-in modules ─────────────────────────────────

    def _seed_builtin_modules(self):
        """Register built-in modules only if the DB is empty."""
        with self._conn() as conn:
            count = conn.execute("SELECT COUNT(*) FROM modules").fetchone()[0]
        if count > 0:
            return

        modules_data = [
            # ── AWS ──────────────────────────────────────────
            dict(
                name="aws_ec2_instance",
                provider="aws",
                resource_type="aws_instance",
                version="2.1.0",
                description="Provision an EC2 instance with configurable size, AMI, and networking.",
                hcl_template=textwrap.dedent("""                    resource "aws_instance" "${var.name}" {
                      ami           = "${var.ami_id}"
                      instance_type = "${var.instance_type}"
                      subnet_id     = "${var.subnet_id}"
                      key_name      = "${var.key_name}"

                      tags = {
                        Name        = "${var.name}"
                        Environment = "${var.environment}"
                        ManagedBy   = "terraform"
                      }

                      root_block_device {
                        volume_size           = ${var.root_volume_size}
                        volume_type           = "gp3"
                        delete_on_termination = true
                        encrypted             = true
                      }

                      lifecycle {
                        ignore_changes = [ami]
                      }
                    }
                """),
                variables=[
                    TerraformVariable("name",            "string",  "Instance name tag"),
                    TerraformVariable("ami_id",          "string",  "AMI ID"),
                    TerraformVariable("instance_type",   "string",  "EC2 instance type",    default="t3.micro",  required=False),
                    TerraformVariable("subnet_id",       "string",  "Subnet ID"),
                    TerraformVariable("key_name",        "string",  "SSH key pair name",    default="",          required=False),
                    TerraformVariable("environment",     "string",  "Deployment environment", default="dev",     required=False),
                    TerraformVariable("root_volume_size","number",  "Root EBS size (GB)",   default=20,          required=False),
                ],
                outputs=[
                    TerraformOutput("instance_id",         "EC2 instance ID",         "aws_instance.${var.name}.id"),
                    TerraformOutput("public_ip",           "Public IP address",       "aws_instance.${var.name}.public_ip"),
                    TerraformOutput("private_ip",          "Private IP address",      "aws_instance.${var.name}.private_ip"),
                ],
                examples=[
                    TerraformExample(
                        title="Basic web server",
                        description="A minimal t3.small web server.",
                        hcl_code='''module "web" {\n  source        = "blackroad/aws_ec2_instance"\n  name          = "web-prod"\n  ami_id        = "ami-0abcdef1234567890"\n  instance_type = "t3.small"\n  subnet_id     = "subnet-12345678"\n}''',
                    )
                ],
                tags=["aws", "ec2", "compute", "vm"],
            ),
            dict(
                name="aws_s3_bucket",
                provider="aws",
                resource_type="aws_s3_bucket",
                version="3.0.1",
                description="Create an S3 bucket with versioning, encryption, and lifecycle rules.",
                hcl_template=textwrap.dedent("""                    resource "aws_s3_bucket" "${var.bucket_name}" {
                      bucket = "${var.bucket_name}"

                      tags = {
                        Name        = "${var.bucket_name}"
                        Environment = "${var.environment}"
                      }
                    }

                    resource "aws_s3_bucket_versioning" "${var.bucket_name}_versioning" {
                      bucket = aws_s3_bucket.${var.bucket_name}.id

                      versioning_configuration {
                        status = "${var.versioning_enabled}"
                      }
                    }

                    resource "aws_s3_bucket_server_side_encryption_configuration" "${var.bucket_name}_sse" {
                      bucket = aws_s3_bucket.${var.bucket_name}.id

                      rule {
                        apply_server_side_encryption_by_default {
                          sse_algorithm = "AES256"
                        }
                      }
                    }
                """),
                variables=[
                    TerraformVariable("bucket_name",          "string", "Globally unique bucket name"),
                    TerraformVariable("environment",          "string", "Environment tag",              default="dev",     required=False),
                    TerraformVariable("versioning_enabled",   "string", "Enable versioning (Enabled/Suspended)", default="Enabled", required=False),
                ],
                outputs=[
                    TerraformOutput("bucket_id",  "S3 bucket ID",  "aws_s3_bucket.${var.bucket_name}.id"),
                    TerraformOutput("bucket_arn", "S3 bucket ARN", "aws_s3_bucket.${var.bucket_name}.arn"),
                ],
                examples=[],
                tags=["aws", "s3", "storage", "object-storage"],
            ),
            dict(
                name="aws_rds_instance",
                provider="aws",
                resource_type="aws_db_instance",
                version="1.4.2",
                description="Provision an RDS instance with automated backups, encryption, and multi-AZ support.",
                hcl_template=textwrap.dedent("""                    resource "aws_db_instance" "${var.identifier}" {
                      identifier              = "${var.identifier}"
                      engine                  = "${var.engine}"
                      engine_version          = "${var.engine_version}"
                      instance_class          = "${var.instance_class}"
                      allocated_storage       = ${var.allocated_storage}
                      db_name                 = "${var.db_name}"
                      username                = "${var.username}"
                      password                = "${var.password}"
                      multi_az                = ${var.multi_az}
                      skip_final_snapshot     = false
                      final_snapshot_identifier = "${var.identifier}-final"
                      storage_encrypted       = true
                      backup_retention_period = ${var.backup_retention_period}

                      tags = {
                        Name        = "${var.identifier}"
                        Environment = "${var.environment}"
                      }
                    }
                """),
                variables=[
                    TerraformVariable("identifier",              "string", "RDS instance identifier"),
                    TerraformVariable("engine",                  "string", "Database engine",              default="postgres",   required=False),
                    TerraformVariable("engine_version",          "string", "Engine version",               default="15.4",       required=False),
                    TerraformVariable("instance_class",          "string", "Instance class",               default="db.t3.micro",required=False),
                    TerraformVariable("allocated_storage",       "number", "Storage in GB",                default=20,           required=False),
                    TerraformVariable("db_name",                 "string", "Initial database name"),
                    TerraformVariable("username",                "string", "Master username"),
                    TerraformVariable("password",                "string", "Master password",              sensitive=True),
                    TerraformVariable("multi_az",                "bool",   "Enable Multi-AZ",              default=False,        required=False),
                    TerraformVariable("backup_retention_period", "number", "Backup retention days",        default=7,            required=False),
                    TerraformVariable("environment",             "string", "Environment tag",              default="dev",        required=False),
                ],
                outputs=[
                    TerraformOutput("endpoint",    "RDS endpoint",    "aws_db_instance.${var.identifier}.endpoint"),
                    TerraformOutput("port",        "RDS port",        "aws_db_instance.${var.identifier}.port"),
                    TerraformOutput("db_name",     "Database name",   "aws_db_instance.${var.identifier}.db_name"),
                ],
                examples=[],
                tags=["aws", "rds", "database", "postgres", "mysql"],
            ),
            dict(
                name="aws_vpc",
                provider="aws",
                resource_type="aws_vpc",
                version="2.0.0",
                description="Create a VPC with public and private subnets, an internet gateway, and route tables.",
                hcl_template=textwrap.dedent("""                    resource "aws_vpc" "${var.name}" {
                      cidr_block           = "${var.cidr_block}"
                      enable_dns_support   = true
                      enable_dns_hostnames = true

                      tags = {
                        Name        = "${var.name}"
                        Environment = "${var.environment}"
                      }
                    }

                    resource "aws_internet_gateway" "${var.name}_igw" {
                      vpc_id = aws_vpc.${var.name}.id

                      tags = {
                        Name = "${var.name}-igw"
                      }
                    }
                """),
                variables=[
                    TerraformVariable("name",        "string", "VPC name"),
                    TerraformVariable("cidr_block",  "string", "CIDR block",    default="10.0.0.0/16", required=False),
                    TerraformVariable("environment", "string", "Environment",   default="dev",         required=False),
                ],
                outputs=[
                    TerraformOutput("vpc_id",  "VPC ID",  "aws_vpc.${var.name}.id"),
                    TerraformOutput("igw_id",  "Internet Gateway ID", "aws_internet_gateway.${var.name}_igw.id"),
                ],
                examples=[],
                tags=["aws", "vpc", "networking"],
            ),
            # ── GCP ──────────────────────────────────────────
            dict(
                name="gcp_gce_instance",
                provider="gcp",
                resource_type="google_compute_instance",
                version="1.2.0",
                description="Create a Google Compute Engine VM instance.",
                hcl_template=textwrap.dedent("""                    resource "google_compute_instance" "${var.name}" {
                      name         = "${var.name}"
                      machine_type = "${var.machine_type}"
                      zone         = "${var.zone}"

                      boot_disk {
                        initialize_params {
                          image = "${var.image}"
                          size  = ${var.disk_size_gb}
                          type  = "pd-ssd"
                        }
                      }

                      network_interface {
                        network    = "${var.network}"
                        subnetwork = "${var.subnetwork}"

                        access_config {}
                      }

                      labels = {
                        environment = "${var.environment}"
                        managed_by  = "terraform"
                      }
                    }
                """),
                variables=[
                    TerraformVariable("name",         "string", "Instance name"),
                    TerraformVariable("machine_type", "string", "Machine type",   default="e2-medium",       required=False),
                    TerraformVariable("zone",         "string", "GCP zone",       default="us-central1-a",   required=False),
                    TerraformVariable("image",        "string", "Boot disk image",default="debian-cloud/debian-11", required=False),
                    TerraformVariable("disk_size_gb", "number", "Boot disk size", default=20,                required=False),
                    TerraformVariable("network",      "string", "VPC network",    default="default",         required=False),
                    TerraformVariable("subnetwork",   "string", "Subnetwork",     default="default",         required=False),
                    TerraformVariable("environment",  "string", "Environment",    default="dev",             required=False),
                ],
                outputs=[
                    TerraformOutput("instance_id",  "GCE instance ID",         "google_compute_instance.${var.name}.id"),
                    TerraformOutput("external_ip",  "External IP address",     "google_compute_instance.${var.name}.network_interface[0].access_config[0].nat_ip"),
                ],
                examples=[],
                tags=["gcp", "gce", "compute", "vm"],
            ),
            dict(
                name="gcp_gcs_bucket",
                provider="gcp",
                resource_type="google_storage_bucket",
                version="1.1.0",
                description="Create a Google Cloud Storage bucket with lifecycle and uniform bucket-level access.",
                hcl_template=textwrap.dedent("""                    resource "google_storage_bucket" "${var.name}" {
                      name                        = "${var.name}"
                      location                    = "${var.location}"
                      storage_class               = "${var.storage_class}"
                      uniform_bucket_level_access = true
                      force_destroy               = ${var.force_destroy}

                      versioning {
                        enabled = ${var.versioning}
                      }

                      labels = {
                        environment = "${var.environment}"
                      }
                    }
                """),
                variables=[
                    TerraformVariable("name",          "string", "Bucket name (globally unique)"),
                    TerraformVariable("location",      "string", "GCS location",     default="US",          required=False),
                    TerraformVariable("storage_class", "string", "Storage class",    default="STANDARD",    required=False),
                    TerraformVariable("versioning",    "bool",   "Enable versioning",default=True,          required=False),
                    TerraformVariable("force_destroy", "bool",   "Force destroy",    default=False,         required=False),
                    TerraformVariable("environment",   "string", "Environment tag",  default="dev",         required=False),
                ],
                outputs=[
                    TerraformOutput("bucket_url",  "GCS bucket URL",  "google_storage_bucket.${var.name}.url"),
                    TerraformOutput("self_link",   "Self link",       "google_storage_bucket.${var.name}.self_link"),
                ],
                examples=[],
                tags=["gcp", "gcs", "storage", "object-storage"],
            ),
            # ── Kubernetes ───────────────────────────────────
            dict(
                name="kubernetes_deployment",
                provider="kubernetes",
                resource_type="kubernetes_deployment",
                version="1.3.0",
                description="Create a Kubernetes Deployment with configurable replicas, image, and resource limits.",
                hcl_template=textwrap.dedent("""                    resource "kubernetes_deployment" "${var.name}" {
                      metadata {
                        name      = "${var.name}"
                        namespace = "${var.namespace}"

                        labels = {
                          app = "${var.name}"
                        }
                      }

                      spec {
                        replicas = ${var.replicas}

                        selector {
                          match_labels = {
                            app = "${var.name}"
                          }
                        }

                        template {
                          metadata {
                            labels = {
                              app = "${var.name}"
                            }
                          }

                          spec {
                            container {
                              name  = "${var.name}"
                              image = "${var.image}"

                              port {
                                container_port = ${var.container_port}
                              }

                              resources {
                                limits = {
                                  cpu    = "${var.cpu_limit}"
                                  memory = "${var.memory_limit}"
                                }
                                requests = {
                                  cpu    = "${var.cpu_request}"
                                  memory = "${var.memory_request}"
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                """),
                variables=[
                    TerraformVariable("name",           "string", "Deployment name"),
                    TerraformVariable("namespace",      "string", "Kubernetes namespace",  default="default",  required=False),
                    TerraformVariable("image",          "string", "Container image"),
                    TerraformVariable("replicas",       "number", "Number of replicas",    default=2,          required=False),
                    TerraformVariable("container_port", "number", "Container port",        default=8080,       required=False),
                    TerraformVariable("cpu_limit",      "string", "CPU limit",             default="500m",     required=False),
                    TerraformVariable("memory_limit",   "string", "Memory limit",          default="256Mi",    required=False),
                    TerraformVariable("cpu_request",    "string", "CPU request",           default="100m",     required=False),
                    TerraformVariable("memory_request", "string", "Memory request",        default="128Mi",    required=False),
                ],
                outputs=[
                    TerraformOutput("deployment_name", "Deployment name",         "kubernetes_deployment.${var.name}.metadata[0].name"),
                    TerraformOutput("replicas",        "Current replica count",   "kubernetes_deployment.${var.name}.spec[0].replicas"),
                ],
                examples=[],
                tags=["kubernetes", "k8s", "deployment", "container"],
            ),
            dict(
                name="kubernetes_service",
                provider="kubernetes",
                resource_type="kubernetes_service",
                version="1.1.0",
                description="Expose a Kubernetes Deployment via a LoadBalancer or ClusterIP Service.",
                hcl_template=textwrap.dedent("""                    resource "kubernetes_service" "${var.name}" {
                      metadata {
                        name      = "${var.name}"
                        namespace = "${var.namespace}"
                      }

                      spec {
                        selector = {
                          app = "${var.selector_app}"
                        }

                        type = "${var.service_type}"

                        port {
                          port        = ${var.port}
                          target_port = ${var.target_port}
                          protocol    = "TCP"
                        }
                      }
                    }
                """),
                variables=[
                    TerraformVariable("name",         "string", "Service name"),
                    TerraformVariable("namespace",    "string", "Kubernetes namespace",  default="default",      required=False),
                    TerraformVariable("selector_app", "string", "App label selector"),
                    TerraformVariable("service_type", "string", "Service type",          default="ClusterIP",    required=False),
                    TerraformVariable("port",         "number", "Service port",          default=80,             required=False),
                    TerraformVariable("target_port",  "number", "Target container port", default=8080,           required=False),
                ],
                outputs=[
                    TerraformOutput("service_name",      "Service name",       "kubernetes_service.${var.name}.metadata[0].name"),
                    TerraformOutput("cluster_ip",        "Cluster IP",         "kubernetes_service.${var.name}.spec[0].cluster_ip"),
                    TerraformOutput("load_balancer_ip",  "Load Balancer IP",   "kubernetes_service.${var.name}.status[0].load_balancer[0].ingress[0].ip"),
                ],
                examples=[],
                tags=["kubernetes", "k8s", "service", "networking"],
            ),
        ]

        for m in modules_data:
            try:
                self.register_module(**m)
            except Exception:
                pass  # silently skip if already seeded


# ──────────────────────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────────────────────

if HAS_RICH:
    app = typer.Typer(help="BlackRoad Terraform Module Registry CLI", rich_markup_mode="rich")
    registry: TerraformRegistry | None = None

    @app.callback()
    def _startup():
        global registry
        registry = TerraformRegistry()

    @app.command()
    def list(
        provider: Optional[str] = typer.Option(None, "--provider", "-p", help="Filter by provider"),
        resource: Optional[str] = typer.Option(None, "--resource", "-r", help="Filter by resource type"),
    ):
        """List all registered modules."""
        mods = registry.list_modules(provider_filter=provider, resource_type_filter=resource)
        table = Table(title="Terraform Module Registry", show_lines=True)
        table.add_column("Name",          style="cyan",  no_wrap=True)
        table.add_column("Provider",      style="green")
        table.add_column("Resource Type", style="yellow")
        table.add_column("Version",       style="magenta")
        table.add_column("Downloads",     justify="right")
        table.add_column("Description")
        for m in mods:
            table.add_row(m.name, m.provider, m.resource_type, m.version,
                          str(m.download_count), m.description[:60])
        console.print(table)

    @app.command()
    def register(
        name:          str = typer.Argument(..., help="Module name"),
        provider:      str = typer.Argument(..., help="Provider"),
        resource_type: str = typer.Argument(..., help="Resource type"),
        template_file: str = typer.Argument(..., help="Path to HCL template file"),
        description:   str = typer.Option("", "--description", "-d"),
        version:       str = typer.Option("1.0.0", "--version", "-v"),
    ):
        """Register a new module from an HCL template file."""
        hcl = Path(template_file).read_text()
        mod = registry.register_module(name, provider, resource_type, hcl, [], [], description=description, version=version)
        console.print(f"[green]✅ Registered[/green] [cyan]{mod.name}[/cyan] ({mod.id})")

    @app.command()
    def generate(
        module:    str = typer.Argument(..., help="Module name or ID"),
        var:       list[str] = typer.Option([], "--var", "-v", help="Variable (key=value)"),
        out:       Optional[str] = typer.Option(None, "--out", "-o", help="Output file"),
    ):
        """Generate Terraform HCL for a module."""
        vars_dict = dict(kv.split("=", 1) for kv in var)
        hcl = registry.generate_tf(module, vars_dict)
        if out:
            Path(out).write_text(hcl)
            console.print(f"[green]Written to {out}[/green]")
        else:
            console.print(Syntax(hcl, "hcl", theme="monokai"))

    @app.command()
    def validate(template_file: str = typer.Argument(..., help="HCL file to validate")):
        """Validate an HCL template file."""
        hcl = Path(template_file).read_text()
        result = registry.validate_hcl(hcl)
        if result.valid:
            console.print("[green]✅ HCL is valid[/green]")
        else:
            console.print("[red]❌ HCL validation failed[/red]")
        for e in result.errors:
            console.print(f"  [red]ERROR:[/red] {e}")
        for w in result.warnings:
            console.print(f"  [yellow]WARN:[/yellow] {w}")

    @app.command()
    def plan(
        module: str = typer.Argument(..., help="Module name or ID"),
        var:    list[str] = typer.Option([], "--var", "-v"),
    ):
        """Export a Terraform plan for a module."""
        vars_dict = dict(kv.split("=", 1) for kv in var)
        output = registry.export_plan(module, vars_dict)
        console.print(Syntax(output, "hcl", theme="monokai"))

    @app.command()
    def search(query: str = typer.Argument(..., help="Search query")):
        """Search modules by name, description, or tags."""
        mods = registry.search(query)
        if not mods:
            console.print(f"[yellow]No modules found for '{query}'[/yellow]")
            return
        table = Table(title=f"Search: {query}")
        table.add_column("Name", style="cyan")
        table.add_column("Provider", style="green")
        table.add_column("Description")
        for m in mods:
            table.add_row(m.name, m.provider, m.description[:80])
        console.print(table)

    @app.command()
    def docs(module: str = typer.Argument(..., help="Module name or ID")):
        """Generate markdown documentation for a module."""
        md = registry.generate_docs(module)
        console.print(Markdown(md))

    @app.command()
    def stats():
        """Show registry statistics."""
        s = registry.get_stats()
        console.print(Panel(
            f"[bold]Total Modules:[/bold] {s['total_modules']}\n\n"
            + "[bold]By Provider:[/bold]\n"
            + "\n".join(f"  {p}: {c}" for p, c in s["by_provider"].items())
            + "\n\n[bold]Most Downloaded:[/bold]\n"
            + "\n".join(f"  {m['name']} ({m['provider']}) — {m['downloads']} downloads"
                         for m in s["most_downloaded"]),
            title="Registry Statistics",
        ))

    if __name__ == "__main__":
        app()
else:
    if __name__ == "__main__":
        print("Install dependencies: pip install typer rich")
