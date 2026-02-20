"""DevOps/Infrastructure utility skills for deployment and monitoring.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

This software is proprietary and confidential. Unauthorized copying, transfer,
or reproduction of this file, via any medium, is strictly prohibited.

Licensed for non-commercial testing and evaluation purposes only.
Commercial use requires a separate license agreement with BlackRoad OS, Inc.

For licensing inquiries: legal@blackroad.io
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class HealthCheck:
    """Health check result."""

    service: str
    status: str  # healthy, unhealthy, degraded
    latency_ms: float
    timestamp: str
    details: Optional[Dict[str, Any]] = None


@dataclass
class DeploymentResult:
    """Deployment result."""

    service: str
    version: str
    status: str  # success, failed, pending
    duration_seconds: float
    logs: List[str]


def parse_dockerfile(content: str) -> Dict[str, Any]:
    """Parse a Dockerfile and extract metadata."""
    result = {
        "base_image": None,
        "stages": [],
        "exposed_ports": [],
        "env_vars": {},
        "labels": {},
        "commands": [],
        "entrypoint": None,
        "cmd": None,
        "workdir": None,
        "user": None,
    }

    current_stage = "default"
    lines = content.split("\n")

    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        # Parse instruction
        parts = line.split(None, 1)
        if len(parts) < 1:
            continue

        instruction = parts[0].upper()
        args = parts[1] if len(parts) > 1 else ""

        if instruction == "FROM":
            # Handle multi-stage builds
            if " AS " in args.upper():
                base, stage = re.split(r"\s+AS\s+", args, flags=re.IGNORECASE)
                result["stages"].append(stage)
                current_stage = stage
            else:
                base = args
            if result["base_image"] is None:
                result["base_image"] = base.strip()

        elif instruction == "EXPOSE":
            ports = re.findall(r"\d+", args)
            result["exposed_ports"].extend([int(p) for p in ports])

        elif instruction == "ENV":
            # Handle both ENV KEY=VALUE and ENV KEY VALUE
            if "=" in args:
                for pair in re.findall(r'(\w+)=([^\s]+|"[^"]*")', args):
                    result["env_vars"][pair[0]] = pair[1].strip('"')
            else:
                parts = args.split(None, 1)
                if len(parts) == 2:
                    result["env_vars"][parts[0]] = parts[1]

        elif instruction == "LABEL":
            for pair in re.findall(r'(\w+)=([^\s]+|"[^"]*")', args):
                result["labels"][pair[0]] = pair[1].strip('"')

        elif instruction == "RUN":
            result["commands"].append(args)

        elif instruction == "ENTRYPOINT":
            result["entrypoint"] = args

        elif instruction == "CMD":
            result["cmd"] = args

        elif instruction == "WORKDIR":
            result["workdir"] = args

        elif instruction == "USER":
            result["user"] = args

    return result


def parse_k8s_manifest(content: str) -> Dict[str, Any]:
    """Parse a Kubernetes YAML manifest and extract metadata."""
    import yaml  # type: ignore

    docs = list(yaml.safe_load_all(content))
    result = {
        "resources": [],
        "namespaces": set(),
        "images": set(),
        "services": [],
        "deployments": [],
        "configmaps": [],
        "secrets": [],
    }

    for doc in docs:
        if not doc:
            continue

        kind = doc.get("kind", "Unknown")
        metadata = doc.get("metadata", {})
        name = metadata.get("name", "unnamed")
        namespace = metadata.get("namespace", "default")

        resource = {
            "kind": kind,
            "name": name,
            "namespace": namespace,
            "api_version": doc.get("apiVersion", ""),
        }

        result["resources"].append(resource)
        result["namespaces"].add(namespace)

        # Extract images from pods/deployments
        spec = doc.get("spec", {})
        if kind in ("Deployment", "StatefulSet", "DaemonSet", "Job", "CronJob"):
            template = spec.get("template", {}).get("spec", {})
            containers = template.get("containers", [])
            for container in containers:
                if "image" in container:
                    result["images"].add(container["image"])
            result["deployments"].append(name)

        elif kind == "Pod":
            containers = spec.get("containers", [])
            for container in containers:
                if "image" in container:
                    result["images"].add(container["image"])

        elif kind == "Service":
            result["services"].append({
                "name": name,
                "type": spec.get("type", "ClusterIP"),
                "ports": spec.get("ports", []),
            })

        elif kind == "ConfigMap":
            result["configmaps"].append(name)

        elif kind == "Secret":
            result["secrets"].append(name)

    # Convert sets to lists for JSON serialization
    result["namespaces"] = list(result["namespaces"])
    result["images"] = list(result["images"])

    return result


def generate_docker_compose(
    services: List[Dict[str, Any]],
    version: str = "3.8",
) -> str:
    """Generate a docker-compose.yml from service definitions."""
    compose = {
        "version": version,
        "services": {},
    }

    networks = set()
    volumes = set()

    for svc in services:
        name = svc["name"]
        service_def = {
            "image": svc.get("image", f"{name}:latest"),
        }

        if "build" in svc:
            service_def["build"] = svc["build"]

        if "ports" in svc:
            service_def["ports"] = svc["ports"]

        if "environment" in svc:
            service_def["environment"] = svc["environment"]

        if "volumes" in svc:
            service_def["volumes"] = svc["volumes"]
            for vol in svc["volumes"]:
                if ":" in vol:
                    vol_name = vol.split(":")[0]
                    if not vol_name.startswith((".", "/", "~")):
                        volumes.add(vol_name)

        if "depends_on" in svc:
            service_def["depends_on"] = svc["depends_on"]

        if "networks" in svc:
            service_def["networks"] = svc["networks"]
            networks.update(svc["networks"])

        if "restart" in svc:
            service_def["restart"] = svc["restart"]

        if "healthcheck" in svc:
            service_def["healthcheck"] = svc["healthcheck"]

        compose["services"][name] = service_def

    if networks:
        compose["networks"] = {n: {} for n in networks}

    if volumes:
        compose["volumes"] = {v: {} for v in volumes}

    import yaml
    return yaml.dump(compose, default_flow_style=False, sort_keys=False)


def parse_env_file(content: str) -> Dict[str, str]:
    """Parse a .env file into a dictionary."""
    env = {}
    for line in content.split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            key, value = line.split("=", 1)
            # Remove quotes
            value = value.strip().strip('"').strip("'")
            env[key.strip()] = value
    return env


def generate_env_file(env: Dict[str, str], comments: Optional[Dict[str, str]] = None) -> str:
    """Generate a .env file from a dictionary."""
    lines = []
    comments = comments or {}

    for key, value in env.items():
        if key in comments:
            lines.append(f"# {comments[key]}")
        # Quote values with spaces
        if " " in value or not value:
            value = f'"{value}"'
        lines.append(f"{key}={value}")

    return "\n".join(lines)


def calculate_semver_bump(
    current: str,
    changes: List[str],
) -> Tuple[str, str]:
    """Calculate next semantic version based on change types.

    Returns (new_version, bump_type).
    Change types: 'breaking', 'feature', 'fix', 'docs', 'chore'
    """
    # Parse current version
    match = re.match(r"v?(\d+)\.(\d+)\.(\d+)", current)
    if not match:
        return current, "none"

    major, minor, patch = int(match.group(1)), int(match.group(2)), int(match.group(3))

    change_set = set(changes)

    if "breaking" in change_set:
        major += 1
        minor = 0
        patch = 0
        bump_type = "major"
    elif "feature" in change_set:
        minor += 1
        patch = 0
        bump_type = "minor"
    elif "fix" in change_set or "perf" in change_set:
        patch += 1
        bump_type = "patch"
    else:
        bump_type = "none"

    new_version = f"{major}.{minor}.{patch}"
    return new_version, bump_type


def generate_changelog_entry(
    version: str,
    changes: List[Dict[str, str]],
    date: Optional[str] = None,
) -> str:
    """Generate a changelog entry for a version.

    Each change should have 'type', 'description', and optionally 'scope'.
    """
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")

    lines = [f"## [{version}] - {date}", ""]

    # Group by type
    groups: Dict[str, List[str]] = {}
    type_headers = {
        "breaking": "BREAKING CHANGES",
        "feature": "Features",
        "fix": "Bug Fixes",
        "perf": "Performance",
        "docs": "Documentation",
        "chore": "Chores",
        "refactor": "Refactoring",
        "test": "Tests",
        "style": "Styling",
    }

    for change in changes:
        change_type = change.get("type", "chore")
        desc = change.get("description", "")
        scope = change.get("scope", "")

        if scope:
            entry = f"- **{scope}**: {desc}"
        else:
            entry = f"- {desc}"

        if change_type not in groups:
            groups[change_type] = []
        groups[change_type].append(entry)

    # Output in order
    for type_key in ["breaking", "feature", "fix", "perf", "refactor", "docs", "test", "chore", "style"]:
        if type_key in groups:
            header = type_headers.get(type_key, type_key.title())
            lines.append(f"### {header}")
            lines.append("")
            lines.extend(groups[type_key])
            lines.append("")

    return "\n".join(lines)


def parse_git_log(log_output: str) -> List[Dict[str, str]]:
    """Parse git log output into structured commits.

    Expects format: git log --pretty=format:'%H|%s|%an|%ad' --date=short
    """
    commits = []
    for line in log_output.strip().split("\n"):
        if not line:
            continue
        parts = line.split("|", 3)
        if len(parts) >= 4:
            commits.append({
                "hash": parts[0],
                "message": parts[1],
                "author": parts[2],
                "date": parts[3],
            })
    return commits


def categorize_commit(message: str) -> str:
    """Categorize a commit message by conventional commit type."""
    message = message.lower()

    patterns = [
        (r"^(breaking|break)[:\s]", "breaking"),
        (r"^feat(\(.+\))?[:\s]", "feature"),
        (r"^fix(\(.+\))?[:\s]", "fix"),
        (r"^perf(\(.+\))?[:\s]", "perf"),
        (r"^docs?(\(.+\))?[:\s]", "docs"),
        (r"^test(\(.+\))?[:\s]", "test"),
        (r"^refactor(\(.+\))?[:\s]", "refactor"),
        (r"^style(\(.+\))?[:\s]", "style"),
        (r"^chore(\(.+\))?[:\s]", "chore"),
        (r"^ci(\(.+\))?[:\s]", "chore"),
        (r"^build(\(.+\))?[:\s]", "chore"),
    ]

    for pattern, category in patterns:
        if re.match(pattern, message):
            return category

    # Guess based on keywords
    if "fix" in message or "bug" in message:
        return "fix"
    if "add" in message or "new" in message:
        return "feature"

    return "chore"


def health_check_http(url: str, timeout: float = 5.0) -> HealthCheck:
    """Perform an HTTP health check."""
    import urllib.request
    import urllib.error

    start = time.time()
    service = url.split("//")[-1].split("/")[0]

    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=timeout) as response:
            latency = (time.time() - start) * 1000
            status = "healthy" if response.status == 200 else "degraded"
            return HealthCheck(
                service=service,
                status=status,
                latency_ms=latency,
                timestamp=datetime.now().isoformat(),
                details={"status_code": response.status},
            )
    except urllib.error.URLError as e:
        latency = (time.time() - start) * 1000
        return HealthCheck(
            service=service,
            status="unhealthy",
            latency_ms=latency,
            timestamp=datetime.now().isoformat(),
            details={"error": str(e)},
        )
    except Exception as e:
        latency = (time.time() - start) * 1000
        return HealthCheck(
            service=service,
            status="unhealthy",
            latency_ms=latency,
            timestamp=datetime.now().isoformat(),
            details={"error": str(e)},
        )


def generate_metrics_summary(
    metrics: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """Generate summary statistics from metrics data.

    Each metric should have 'name', 'value', and optionally 'timestamp'.
    """
    import numpy as np

    grouped: Dict[str, List[float]] = {}

    for m in metrics:
        name = m.get("name", "unknown")
        value = m.get("value", 0)
        if name not in grouped:
            grouped[name] = []
        grouped[name].append(float(value))

    summary = {}
    for name, values in grouped.items():
        arr = np.array(values)
        summary[name] = {
            "count": len(values),
            "min": float(np.min(arr)),
            "max": float(np.max(arr)),
            "mean": float(np.mean(arr)),
            "std": float(np.std(arr)),
            "p50": float(np.percentile(arr, 50)),
            "p95": float(np.percentile(arr, 95)),
            "p99": float(np.percentile(arr, 99)),
        }

    return summary


def resource_utilization_score(
    cpu_percent: float,
    memory_percent: float,
    disk_percent: float,
    weights: Optional[Dict[str, float]] = None,
) -> float:
    """Calculate overall resource utilization score (0-100)."""
    weights = weights or {"cpu": 0.4, "memory": 0.4, "disk": 0.2}

    score = (
        cpu_percent * weights.get("cpu", 0.33) +
        memory_percent * weights.get("memory", 0.33) +
        disk_percent * weights.get("disk", 0.33)
    )

    return min(100.0, max(0.0, score))
