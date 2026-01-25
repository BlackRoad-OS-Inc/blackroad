"""Telemetry helpers for the BlackRoad API service."""
"""Telemetry helpers for the BlackRoad device agent."""

"""Utilities for collecting local and remote telemetry for the dashboard."""
"""Utility helpers for collecting local and remote telemetry data."""
from __future__ import annotations

import json
import os
import platform
import shutil
import socket
import subprocess
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict


class TelemetryError(RuntimeError):
    """Raised when telemetry information cannot be collected."""


@dataclass(slots=True)
class TelemetryResult:
    """Structured telemetry payload returned by collectors."""

    status: str
    payload: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        data = {"status": self.status, **self.payload}
        return data


def _load_average() -> list[float] | None:
    try:
        one, five, fifteen = os.getloadavg()
        return [float(one), float(five), float(fifteen)]
    except (AttributeError, OSError):
        return None


def _memory_info() -> Dict[str, Any]:
    info: Dict[str, Any] = {}
    try:
        with open("/proc/meminfo", encoding="utf-8") as handle:
            for line in handle:
                if ":" not in line:
                    continue
                key, value = line.split(":", 1)
                info[key.strip()] = value.strip()
    except (FileNotFoundError, OSError):
        # /proc/meminfo is not available on all systems; fall back to an empty payload.
        return info
    return info


def _disk_usage(path: str = "/") -> Dict[str, int] | None:
    try:
        usage = shutil.disk_usage(path)
    except (FileNotFoundError, OSError):
        return None
    return {"total": usage.total, "used": usage.used, "free": usage.free}


def _base_payload() -> Dict[str, Any]:
    timestamp = time.time()
    return {
        "hostname": socket.gethostname(),
        "platform": platform.platform(),
        "timestamp": timestamp,
        "iso_timestamp": datetime.fromtimestamp(timestamp, tz=timezone.utc).isoformat().replace("+00:00", "Z"),
        "load_average": _load_average(),
        "memory": _memory_info(),
        "disk": _disk_usage(),
    }


def collect_local() -> Dict[str, Any]:
    """Collect telemetry for the local host."""
    try:
        result = TelemetryResult(status="ok", payload=_base_payload())
    except Exception as exc:  # pragma: no cover - defensive guard
        raise TelemetryError("Failed to collect local telemetry") from exc
    return result.to_dict()


_REMOTE_SNIPPET = " ".join(
    line.strip()
    for line in (
        "import json, os, platform, shutil, socket, time",
        "from datetime import datetime",
        "def load_average():",
        "    try:",
        "        return list(os.getloadavg())",
        "    except (OSError, AttributeError):",
        "        return None",
        "def memory_info():",
        "    info = {}",
        "    try:",
        "        with open('/proc/meminfo', encoding='utf-8') as handle:",
        "            for line in handle:",
        "                if ':' not in line:",
        "                    continue",
        "                key, value = line.split(':', 1)",
        "                info[key.strip()] = value.strip()",
        "    except (FileNotFoundError, OSError):",
        "        pass",
        "    return info",
        "def disk_usage(path='/'):",
        "    try:",
        "        usage = shutil.disk_usage(path)",
        "    except (FileNotFoundError, OSError):",
        "        return None",
        "    return {'total': usage.total, 'used': usage.used, 'free': usage.free}",
        "timestamp = time.time()",
        "payload = {",
        "    'hostname': socket.gethostname(),",
        "    'platform': platform.platform(),",
        "    'timestamp': timestamp,",
        "    'iso_timestamp': datetime.utcfromtimestamp(timestamp).isoformat() + 'Z',",
        "    'load_average': load_average(),",
        "    'memory': memory_info(),",
        "    'disk': disk_usage(),",
        "}",
        "print(json.dumps({'status': 'ok', **payload}))",
    )
)


def collect_remote(host: str, *, user: str | None = None, timeout: int = 10) -> Dict[str, Any]:
    """Collect telemetry from a remote host via SSH."""
    target = f"{user}@{host}" if user else host
    try:
        completed = subprocess.run(
            [
                "ssh",
                "-o",
                "BatchMode=yes",
                "-o",
                "ConnectTimeout=5",
                target,
                "python3",
                "-c",
                _REMOTE_SNIPPET,
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError as exc:  # pragma: no cover - environment guard
        raise TelemetryError("ssh executable not found") from exc
    except subprocess.TimeoutExpired as exc:
        raise TelemetryError(f"Timed out collecting telemetry from {target}") from exc
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or "").strip()
        message = stderr or f"Failed to collect telemetry from {target}"
        raise TelemetryError(message) from exc

    output = completed.stdout.strip()
    if not output:
        raise TelemetryError(f"No telemetry returned from {target}")

    try:
        data = json.loads(output)
    except json.JSONDecodeError as exc:
        raise TelemetryError(f"Invalid telemetry payload from {target}") from exc

    if not isinstance(data, dict):
        raise TelemetryError(f"Unexpected telemetry format from {target}")

    return data


__all__ = ["collect_local", "collect_remote", "TelemetryError", "TelemetryResult"]
"""Helpers for collecting system telemetry for the dashboard."""

from __future__ import annotations

import platform
import shutil
import subprocess
from typing import Any, Dict, Iterable, Mapping, Sequence

DEFAULT_COMMANDS: Mapping[str, Sequence[str]] = {
    "uname": ["uname", "-a"],
    "uptime": ["uptime"],
    "disk": ["df", "-h"],
}


def collect_local(commands: Mapping[str, Sequence[str]] | None = None) -> Dict[str, Any]:
    """Collect telemetry information from the local machine."""

    return _collect(commands or DEFAULT_COMMANDS)


def collect_remote(
    host: str,
    *,
    user: str | None = None,
    commands: Mapping[str, Sequence[str]] | None = None,
) -> Dict[str, Any]:
    """Collect telemetry from a remote host via SSH."""

    if not host:
        raise ValueError("host must be provided")

    return _collect(commands or DEFAULT_COMMANDS, ssh_target=_format_ssh_target(host, user))


def _format_ssh_target(host: str, user: str | None) -> str:
    return f"{user}@{host}" if user else host


def _collect(
    commands: Mapping[str, Sequence[str]],
    *,
    ssh_target: str | None = None,
) -> Dict[str, Any]:
    telemetry: Dict[str, Any] = {
        "hostname": platform.node() if ssh_target is None else ssh_target,
    }

    for label, command in commands.items():
        telemetry[label] = _run_command(command, ssh_target=ssh_target)

    return telemetry


def _run_command(command: Sequence[str], *, ssh_target: str | None = None) -> Dict[str, Any]:
    if ssh_target:
        if shutil.which("ssh") is None:
            return {"error": "ssh executable not found"}
        full_command: Iterable[str] = ("ssh", ssh_target, *command)
    else:
        full_command = command

    try:
        completed = subprocess.run(
            list(full_command),
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except subprocess.CalledProcessError as exc:
        return {"error": exc.stderr.strip() or str(exc)}
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return {"error": str(exc)}

    return {"stdout": completed.stdout.strip()}
from dataclasses import dataclass
from typing import Any, Mapping, Optional

DEFAULT_DISK_PATH = "/"
THERMAL_PATHS = (
    "/sys/class/thermal/thermal_zone0/temp",
    "/sys/class/thermal/thermal_zone1/temp",
)


@dataclass(frozen=True)
class TelemetrySnapshot:
    """Structured telemetry metrics."""

    hostname: str
    load_1m: Optional[float]
    load_5m: Optional[float]
    load_15m: Optional[float]
    uptime_seconds: Optional[float]
    mem_total_kb: Optional[int]
    mem_available_kb: Optional[int]
    disk_total_gb: Optional[float]
    disk_free_gb: Optional[float]
    cpu_temp_c: Optional[float]

    def as_dict(self) -> dict[str, Any]:
        return {
            "hostname": self.hostname,
            "load_1m": self.load_1m,
            "load_5m": self.load_5m,
            "load_15m": self.load_15m,
            "uptime_seconds": self.uptime_seconds,
            "mem_total_kb": self.mem_total_kb,
            "mem_available_kb": self.mem_available_kb,
            "disk_total_gb": self.disk_total_gb,
            "disk_free_gb": self.disk_free_gb,
            "cpu_temp_c": self.cpu_temp_c,
        }


def _read_loadavg() -> tuple[Optional[float], Optional[float], Optional[float]]:
    try:
        return os.getloadavg()
    except OSError:
        return (None, None, None)


def _read_uptime() -> Optional[float]:
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as fh:
            return float(fh.read().split()[0])
    except (OSError, ValueError, IndexError):
        return None


def _read_meminfo() -> Mapping[str, int]:
    info: dict[str, int] = {}
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as fh:
            for line in fh:
                parts = line.split()
                if len(parts) >= 2:
                    key = parts[0].rstrip(":")
                    try:
                        info[key] = int(parts[1])
                    except ValueError:
                        continue
    except OSError:
        return {}
    return info


def _read_disk_usage(path: str = DEFAULT_DISK_PATH) -> tuple[Optional[float], Optional[float]]:
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        return (None, None)
    total_gb = round(usage.total / (1024**3), 2)
    free_gb = round(usage.free / (1024**3), 2)
    return (total_gb, free_gb)


def _read_temperature() -> Optional[float]:
    for candidate in THERMAL_PATHS:
        try:
            with open(candidate, "r", encoding="utf-8") as fh:
                raw = fh.read().strip()
        except OSError:
            continue
        try:
            value = float(raw) / 1000.0 if len(raw) > 3 else float(raw)
        except ValueError:
            continue
        return round(value, 2)
    return None


def collect_local() -> dict[str, Any]:
    hostname = platform.node() or socket.gethostname()
    load_1m, load_5m, load_15m = _read_loadavg()
    uptime_seconds = _read_uptime()
    meminfo = _read_meminfo()
    disk_total_gb, disk_free_gb = _read_disk_usage()
    cpu_temp_c = _read_temperature()

    snapshot = TelemetrySnapshot(
        hostname=hostname,
        load_1m=load_1m,
        load_5m=load_5m,
        load_15m=load_15m,
        uptime_seconds=uptime_seconds,
        mem_total_kb=meminfo.get("MemTotal"),
        mem_available_kb=meminfo.get("MemAvailable"),
        disk_total_gb=disk_total_gb,
        disk_free_gb=disk_free_gb,
        cpu_temp_c=cpu_temp_c,
    )
    return snapshot.as_dict()


REMOTE_COLLECT_SCRIPT = """python3 - <<'PY'
from dataclasses import dataclass
from typing import Any, Dict, Optional


@dataclass
class Telemetry:
    """Structured representation of host telemetry for easier rendering."""

    hostname: str
    platform: str
    uptime_seconds: Optional[float]
    load_average: Optional[Dict[str, float]]
    disk: Optional[Dict[str, int]]
    raw: Dict[str, Any]

    def as_dict(self) -> Dict[str, Any]:
        """Return a representation that can be fed to templates directly."""
        return {
            "hostname": self.hostname,
            "platform": self.platform,
            "uptime_seconds": self.uptime_seconds,
            "load_average": self.load_average,
            "disk": self.disk,
            "raw": self.raw,
        }
import subprocess
import textwrap
from pathlib import Path
from typing import Any, Dict, Optional

REMOTE_TIMEOUT_SECONDS = 15
THERMAL_PATHS = (
    "/sys/class/thermal/thermal_zone0/temp",
    "/sys/devices/virtual/thermal/thermal_zone0/temp",
    "/sys/class/hwmon/hwmon0/temp1_input",
)


def _read_load() -> Optional[Dict[str, float]]:
    try:
        load1, load5, load15 = os.getloadavg()
    except OSError:
        return None
    return {"1m": load1, "5m": load5, "15m": load15}


def _parse_meminfo() -> Optional[Dict[str, float]]:
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except OSError:
        return None

    stats: Dict[str, int] = {}
    for line in lines:
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        parts = value.strip().split()
        if not parts:
            continue
        try:
            stats[key.strip()] = int(parts[0])
        except ValueError:
            continue

    total = stats.get("MemTotal")
    available = stats.get("MemAvailable")
    free = stats.get("MemFree")

    if total is None:
        return None

    mem: Dict[str, float] = {"total_mb": total / 1024}
    if available is not None:
        mem["available_mb"] = available / 1024
    if free is not None:
        mem["free_mb"] = free / 1024
    return mem


def _read_uptime() -> Optional[float]:
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as fh:
            first, *_ = fh.readline().split()
            return float(first)
    except (FileNotFoundError, OSError, ValueError):
        return None


def _collect_base_stats() -> Dict[str, Any]:
    data: Dict[str, Any] = {
        "hostname": socket.gethostname(),
        "platform": platform.platform(),
        "uptime_seconds": _read_uptime(),
    }

    if hasattr(os, "getloadavg"):
        try:
            load1, load5, load15 = os.getloadavg()
            data["load_average"] = {
                "1m": float(load1),
                "5m": float(load5),
                "15m": float(load15),
            }
        except OSError:
            data["load_average"] = None
    else:
        data["load_average"] = None

    try:
        usage = shutil.disk_usage("/")
        data["disk"] = {
            "total": usage.total,
            "used": usage.used,
            "free": usage.free,
        }
    except OSError:
        data["disk"] = None

    return data


def collect_local() -> Telemetry:
    """Gather telemetry information for the host running the dashboard."""
    stats = _collect_base_stats()
    return Telemetry(
        hostname=stats.get("hostname", "unknown"),
        platform=stats.get("platform", "unknown"),
        uptime_seconds=stats.get("uptime_seconds"),
        load_average=stats.get("load_average"),
        disk=stats.get("disk"),
        raw=stats,
    )


_REMOTE_SCRIPT = """
import json
import os
import platform
import shutil
import socket

THERMAL_PATHS = (
    "/sys/class/thermal/thermal_zone0/temp",
    "/sys/class/thermal/thermal_zone1/temp",
)


def read_loadavg():
    try:
        return os.getloadavg()
    except OSError:
        return (None, None, None)


def read_uptime():
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as fh:
            return float(fh.read().split()[0])
    except (OSError, ValueError, IndexError):
        return None


def read_meminfo():
    info = {}
    try:
        with open("/proc/meminfo", "r", encoding="utf-8") as fh:
            for line in fh:
                parts = line.split()
                if len(parts) >= 2:
                    key = parts[0].rstrip(":")
                    try:
                        info[key] = int(parts[1])
                    except ValueError:
                        continue
    except OSError:
        return {}
    return info


def read_disk_usage(path="/"):
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        return (None, None)
    total_gb = round(usage.total / (1024**3), 2)
    free_gb = round(usage.free / (1024**3), 2)
    return (total_gb, free_gb)


def read_temperature():
    for candidate in THERMAL_PATHS:
        try:
            with open(candidate, "r", encoding="utf-8") as fh:
                raw = fh.read().strip()
        except OSError:
            continue
        try:
            value = float(raw) / 1000.0 if len(raw) > 3 else float(raw)
        except ValueError:
            continue
        return round(value, 2)
    return None


def collect():
    load_1m, load_5m, load_15m = read_loadavg()
    meminfo = read_meminfo()
    disk_total_gb, disk_free_gb = read_disk_usage()
    payload = {
        "hostname": platform.node() or socket.gethostname(),
        "load_1m": load_1m,
        "load_5m": load_5m,
        "load_15m": load_15m,
        "uptime_seconds": read_uptime(),
        "mem_total_kb": meminfo.get("MemTotal"),
        "mem_available_kb": meminfo.get("MemAvailable"),
        "disk_total_gb": disk_total_gb,
        "disk_free_gb": disk_free_gb,
        "cpu_temp_c": read_temperature(),
    }
    print(json.dumps(payload))


collect()
PY"""


def collect_remote(host: str, *, user: Optional[str] = None, timeout: int = 15) -> dict[str, Any]:
    target = f"{user}@{host}" if user else host
    try:
        result = subprocess.run(
            [
                "ssh",
                "-o",
                "BatchMode=yes",
                "-o",
                "ConnectTimeout=5",
                target,
                REMOTE_COLLECT_SCRIPT,
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError:
        return {"error": "ssh_not_found", "host": host, "user": user}
    except subprocess.TimeoutExpired:
        return {"error": "ssh_timeout", "host": host, "user": user}

    if result.returncode != 0:
        return {
            "error": "ssh_failed",
            "host": host,
            "user": user,
            "stderr": result.stderr.strip(),
        }

    stdout = result.stdout.strip()
    if not stdout:
        return {"error": "no_data", "host": host, "user": user}

    try:
        return json.loads(stdout)
    except json.JSONDecodeError:
        return {
            "error": "invalid_json",
            "host": host,
            "user": user,
            "raw": stdout,
        }
"""Telemetry collection utilities for local hosts and remote Jetson devices."""
from __future__ import annotations

import shlex
import subprocess
from typing import Dict


def _run(cmd: str) -> str:
    """Run a shell command and return its stripped output or ``"n/a"`` on failure."""
    try:
        return subprocess.check_output(shlex.split(cmd), text=True).strip()
    except Exception:
        return "n/a"


def collect_local() -> Dict[str, str]:
    """Collect telemetry from the local machine (e.g. Raspberry Pi)."""
    return {
        "uptime": _run("uptime -p"),
        "temp": _run("vcgencmd measure_temp"),
        "load": _run("uptime | awk -F'load average:' '{print $2}'"),
    }


def collect_remote(host: str, user: str = "jetson") -> Dict[str, str]:
    """Collect telemetry from a remote Jetson device over SSH."""

import os
import subprocess
import shlex

JETSON_HOST = os.getenv("JETSON_HOST", "jetson.local")
JETSON_USER = os.getenv("JETSON_USER", "jetson")

def _run(cmd: str) -> str:
    try:
        return subprocess.check_output(shlex.split(cmd), text=True).strip()
    except Exception as e:
        return f"error: {e}"


def collect_local() -> dict:
    return {
        "hostname": _run("hostname"),
        "uname": _run("uname -a"),
        "uptime": _run("uptime -p"),
        "disk": _run("df -h /etc/hosts"),  # quick visible disk line
    }


def collect_remote(host: str = None, user: str = None) -> dict:
    host = host or JETSON_HOST
    user = user or JETSON_USER
    base = f"{user}@{host}"

    def ssh(cmd: str) -> str:
        try:
            return subprocess.check_output(
                ["ssh", "-o", "ConnectTimeout=3", base, cmd],
                text=True,
            ).strip()
        except Exception:
            return "n/a"

    return {
        "uptime": ssh("uptime -p"),
        "load": ssh("uptime | awk -F'load average:' '{print $2}'"),
        "tegrastats": ssh("tegrastats --interval 1000 --count 1 || echo 'no tegrastats'"),
    }
"""Lightweight telemetry helpers for the BlackRoad dashboard."""

from __future__ import annotations

import asyncio
import random
import time
from collections import deque
from typing import Any, AsyncIterator, Deque, Dict, Iterable, List

_TIMELINE: Deque[Dict[str, Any]] = deque(
    [
        {
            "id": 1,
            "title": "Deployment complete",
            "desc": "Prism console deployed to staging",
            "ts": time.time() - 1800,
        },
        {
            "id": 2,
            "title": "Notebook synced",
            "desc": "Jetson telemetry heartbeat registered",
            "ts": time.time() - 1200,
        },
        {
            "id": 3,
            "title": "Code review finished",
            "desc": "Merged agent orchestrator patch",
            "ts": time.time() - 600,
        },
    ],
    maxlen=200,
)
_TASKS: List[Dict[str, Any]] = [
    {"id": 1, "title": "Wire Jetson metrics", "status": "in-progress"},
    {"id": 2, "title": "Audit API keys", "status": "pending"},
]
_COMMITS: List[Dict[str, Any]] = [
    {
        "id": "f9a3c21",
        "author": "codex",
        "title": "Improve agent resilience",
        "ts": time.time() - 2600,
    }
]
_STATE: Dict[str, Any] = {
    "wallet": 1.20,
    "agents": {"Phi": True, "GPT": True, "Mistral": True},
    "build": 63,
}


def timeline() -> List[Dict[str, Any]]:
    return list(_TIMELINE)


def tasks() -> List[Dict[str, Any]]:
    return list(_TASKS)


def commits() -> List[Dict[str, Any]]:
    return list(_COMMITS)


def state() -> Dict[str, Any]:
    return dict(_STATE)


def record_activity(title: str, desc: str) -> Dict[str, Any]:
    entry = {
        "id": int(time.time() * 1000),
        "title": title,
        "desc": desc,
        "ts": time.time(),
    }
    _TIMELINE.appendleft(entry)
    return entry


async def stream() -> AsyncIterator[Dict[str, Any]]:
    rng = random.Random()
    wallet = float(_STATE.get("wallet", 0))
    build = float(_STATE.get("build", 0))
    while True:
        cpu = rng.uniform(20, 90)
        mem = rng.uniform(30, 80)
        gpu = rng.uniform(10, 95)
        yield {"type": "metrics", "cpu": cpu, "mem": mem, "gpu": gpu}

        if _TIMELINE and rng.random() < 0.35:
            item = rng.choice(list(_TIMELINE))
            yield {"type": "activity", "item": item}

        if rng.random() < 0.25:
            build = min(100.0, build + rng.uniform(0.5, 2.5))
            _STATE["build"] = build
            yield {"type": "build", "progress": build}

        if rng.random() < 0.2:
            delta = rng.uniform(-0.05, 0.08)
            wallet = max(0.0, wallet + delta)
            _STATE["wallet"] = round(wallet, 2)
            yield {"type": "wallet", "balance": _STATE["wallet"]}

        await asyncio.sleep(1.5)
"""Telemetry helpers for the BlackRoad dashboard."""

from __future__ import annotations

from typing import Any, Dict


def collect_local() -> Dict[str, Any]:
    """Collect telemetry for the local device.

    Placeholder implementation returning an empty payload when telemetry
    commands are unavailable in the development environment.
    """

    return {}


def collect_remote(host: str, user: str = "jetson") -> Dict[str, Any]:
    """Collect telemetry for a remote device via SSH.

    Placeholder implementation returning an empty payload.
    """

    return {}
"""Telemetry helpers for Raspberry Pi and Jetson targets."""
from __future__ import annotations

import os
import shlex
import subprocess
from pathlib import Path
from typing import Dict, Mapping, Sequence

from agent.config import active_target

CommandMap = Mapping[str, Sequence[str] | str]


def _target() -> tuple[str, str]:
    """Return the preferred Jetson target considering environment overrides."""
    env_host = os.getenv("JETSON_HOST")
    env_user = os.getenv("JETSON_USER")
    host, user = active_target()
    if env_host or env_user:
        return env_host or host, env_user or user
    return host, user


def _run_command(cmd: Sequence[str], timeout: int = 10) -> str:
    """Execute a command and return stripped stdout or an error prefix."""
    try:
        out = subprocess.check_output(
            cmd,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
        )
        return out.strip()
    except FileNotFoundError:
        return f"error: command not found: {cmd[0]}"
    except subprocess.TimeoutExpired:
        return "error: timeout"
    except subprocess.CalledProcessError as exc:
        output = exc.output.strip() if exc.output else str(exc)
        return f"error: {output or exc.returncode}"


def _collect(commands: CommandMap) -> Dict[str, str]:
    return {name: _run_command(_ensure_sequence(cmd)) for name, cmd in commands.items()}


def _ensure_sequence(cmd: Sequence[str] | str) -> Sequence[str]:
    if isinstance(cmd, str):
        return shlex.split(cmd)
    return list(cmd)


def _ssh_command(host: str, user: str, command: Sequence[str] | str) -> Sequence[str]:
    if isinstance(command, str):
        remote = ["bash", "-lc", command]
    else:
        remote = list(command)
    return [

def read_uptime():
    try:
        with open('/proc/uptime', 'r', encoding='utf-8') as fh:
            first, *_ = fh.readline().split()
            return float(first)
    except Exception:  # pragma: no cover - defensive
        return None


def collect():
    data = {
        'hostname': socket.gethostname(),
        'platform': platform.platform(),
        'uptime_seconds': read_uptime(),
        'load_average': None,
        'disk': None,
    }

    if hasattr(os, 'getloadavg'):
        try:
            load1, load5, load15 = os.getloadavg()
            data['load_average'] = {
                '1m': float(load1),
                '5m': float(load5),
                '15m': float(load15),
            }
        except OSError:
            data['load_average'] = None

    try:
        usage = shutil.disk_usage('/')
        data['disk'] = {
            'total': usage.total,
            'used': usage.used,
            'free': usage.free,
        }
    except OSError:
        data['disk'] = None

    return data

print(json.dumps(collect()))
""".strip()


def _run_ssh_command(
    host: str,
    user: Optional[str],
    args: list[str],
    *,
    timeout: int,
    input_data: Optional[str] = None,
) -> subprocess.CompletedProcess:
    target = f"{user}@{host}" if user else host
    base_cmd = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "ConnectTimeout=5",
        f"{user}@{host}",
        *remote,
    ]


LOCAL_COMMANDS: Dict[str, Sequence[str] | str] = {
    "hostname": ["hostname"],
    "uptime": ["uptime", "-p"],
    "loadavg": ["cat", "/proc/loadavg"],
    "disk_root": ["df", "-h", "/"],
    "memory": ["free", "-m"],
}

REMOTE_COMMANDS: Dict[str, Sequence[str] | str] = {
    "hostname": "hostname",
    "uptime": "uptime -p",
    "loadavg": "cat /proc/loadavg",
    "disk_root": "df -h /",
    "memory": "free -m",
    "gpu": "command -v tegrastats >/dev/null 2>&1 && tegrastats --interval 1000 --count 1 | head -n 1 || echo 'tegrastats unavailable'",
}


def collect_local(extra_commands: CommandMap | None = None) -> Dict[str, str]:
    """Return a dictionary of local telemetry data."""
    commands: Dict[str, Sequence[str] | str] = dict(LOCAL_COMMANDS)
    if extra_commands:
        commands.update(extra_commands)

    results = _collect(commands)

    # Attach CPU temperature if available via sysfs (common on Pi)
    thermal_path = Path("/sys/class/thermal/thermal_zone0/temp")
    if thermal_path.exists():
        try:
            raw = thermal_path.read_text().strip()
            if raw:
                results.setdefault("cpu_temp_c", f"{float(raw) / 1000.0:.1f}")
        except Exception:
            results.setdefault("cpu_temp_c", "error: read failure")
    else:
        temp_result = _run_command(["vcgencmd", "measure_temp"])
        if not temp_result.startswith("error"):
            results.setdefault("cpu_temp", temp_result)
    return results


def collect_remote(
    host: str | None = None,
    user: str | None = None,
    commands: CommandMap | None = None,
) -> Dict[str, str]:
    """Gather telemetry from the remote Jetson via SSH."""
    default_host, default_user = _target()
    host = host or default_host
    user = user or default_user
    command_map: Dict[str, Sequence[str] | str] = dict(REMOTE_COMMANDS)
    if commands:
        command_map.update(commands)

    results: Dict[str, str] = {}
    for name, command in command_map.items():
        ssh_cmd = _ssh_command(host, user, command)
        results[name] = _run_command(ssh_cmd, timeout=20)
    return results


__all__ = [
    "collect_local",
    "collect_remote",
]
                text=True
            ).strip()
        except Exception as e:
            return f"error: {e}"

    return {
        "hostname": ssh("hostname"),
        "uname": ssh("uname -a"),
        "uptime": ssh("uptime -p"),
        "disk": ssh("df -h /etc/hosts"),
    }
        f"ConnectTimeout={timeout}",
        target,
    ]
    return subprocess.run(
        base_cmd + args,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
        input=input_data,
    )


def collect_remote(host: str, *, user: Optional[str] = None, timeout: int = 10) -> Telemetry:
    """Collect telemetry from a remote host over SSH.

    Errors are captured and surfaced via the ``raw`` payload to keep the
    dashboard functional even when the remote host is unreachable.
    """

    result = _run_ssh_command(
        host,
        user,
        ["python3", "-"],
        timeout=timeout,
        input_data=_REMOTE_SCRIPT,
    )

    if result.returncode != 0:
        raw: Dict[str, Any] = {
            "error": "ssh_failed",
            "returncode": result.returncode,
            "stderr": result.stderr.strip(),
        }
        return Telemetry(
            hostname=host,
            platform="unknown",
            uptime_seconds=None,
            load_average=None,
            disk=None,
            raw=raw,
        )

    try:
        stats = json.loads(result.stdout)
    except json.JSONDecodeError:
        stats = {"error": "invalid_json", "stdout": result.stdout.strip()}

    if not isinstance(stats, dict):
        stats = {"error": "invalid_payload", "payload": stats}

    return Telemetry(
        hostname=stats.get("hostname", host),
        platform=stats.get("platform", "unknown"),
        uptime_seconds=stats.get("uptime_seconds"),
        load_average=stats.get("load_average"),
        disk=stats.get("disk"),
        raw=stats,
    )


__all__ = ["Telemetry", "collect_local", "collect_remote"]
            content = fh.read().strip().split()
    except OSError:
        return None

    if not content:
        return None

    try:
        return float(content[0])
    except ValueError:
        return None


def _read_temperature() -> Optional[float]:
    for path in THERMAL_PATHS:
        try:
            raw = Path(path).read_text(encoding="utf-8").strip()
        except OSError:
            continue

        if not raw:
            continue

        try:
            value = float(raw)
        except ValueError:
            continue

        if value > 1000:
            value /= 1000.0
        return value
    return None


def _build_payload() -> Dict[str, Any]:
    payload: Dict[str, Any] = {
        "host": os.uname().nodename if hasattr(os, "uname") else None,
        "load": _read_load(),
        "memory": _parse_meminfo(),
        "uptime_s": _read_uptime(),
        "temp_c": _read_temperature(),
    }
    return payload


def collect_local() -> Dict[str, Any]:
    """Collect telemetry from the local machine."""
    return _build_payload()


_REMOTE_SCRIPT = textwrap.dedent(
    """
    import json
    import os
    from pathlib import Path


    THERMAL_PATHS = (
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/devices/virtual/thermal/thermal_zone0/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
    )


    def read_load():
        try:
            load1, load5, load15 = os.getloadavg()
        except OSError:
            return None
        return {"1m": load1, "5m": load5, "15m": load15}


    def parse_meminfo():
        try:
            with open("/proc/meminfo", "r", encoding="utf-8") as fh:
                lines = fh.readlines()
        except OSError:
            return None

        stats = {}
        for line in lines:
            if ":" not in line:
                continue
            key, value = line.split(":", 1)
            parts = value.strip().split()
            if not parts:
                continue
            try:
                stats[key.strip()] = int(parts[0])
            except ValueError:
                continue

        total = stats.get("MemTotal")
        available = stats.get("MemAvailable")
        free = stats.get("MemFree")

        if total is None:
            return None

        mem = {"total_mb": total / 1024}
        if available is not None:
            mem["available_mb"] = available / 1024
        if free is not None:
            mem["free_mb"] = free / 1024
        return mem


    def read_uptime():
        try:
            with open("/proc/uptime", "r", encoding="utf-8") as fh:
                content = fh.read().strip().split()
        except OSError:
            return None
        if not content:
            return None
        try:
            return float(content[0])
        except ValueError:
            return None


    def read_temperature():
        for path in THERMAL_PATHS:
            try:
                raw = Path(path).read_text(encoding="utf-8").strip()
            except OSError:
                continue
            if not raw:
                continue
            try:
                value = float(raw)
            except ValueError:
                continue
            if value > 1000:
                value /= 1000.0
            return value
        return None


    payload = {
        "host": os.uname().nodename if hasattr(os, "uname") else None,
        "load": read_load(),
        "memory": parse_meminfo(),
        "uptime_s": read_uptime(),
        "temp_c": read_temperature(),
    }

    print(json.dumps(payload))
    """
)


def collect_remote(host: str, user: Optional[str] = None) -> Dict[str, Any]:
    """Collect telemetry from a remote host via SSH."""
    remote = f"{user}@{host}" if user else host
    try:
        proc = subprocess.run(
            ["ssh", remote, "python3", "-"],
            input=_REMOTE_SCRIPT,
            capture_output=True,
            text=True,
            timeout=REMOTE_TIMEOUT_SECONDS,
            check=True,
        )
    except FileNotFoundError:
        return {"error": "ssh executable not found"}
    except subprocess.TimeoutExpired:
        return {"error": f"timeout collecting telemetry from {remote}"}
    except subprocess.CalledProcessError as exc:
        stderr = exc.stderr.strip() if exc.stderr else str(exc)
        return {"error": f"ssh failed: {stderr}"}

    output = proc.stdout.strip()
    if not output:
        return {"error": "no telemetry returned"}

    try:
        return json.loads(output)
    except json.JSONDecodeError:
        return {"error": "invalid telemetry payload", "raw": output}


__all__ = ["collect_local", "collect_remote"]
