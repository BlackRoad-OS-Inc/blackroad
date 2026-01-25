"""Job execution helpers for the BlackRoad API service."""
"""Helpers for executing shell jobs and streaming their output."""
"""Utilities for running remote jobs on Jetson hosts."""

"""Remote job execution helpers for the dashboard."""
from __future__ import annotations

import subprocess
from dataclasses import dataclass
from typing import Any, Dict, Optional


class JobError(RuntimeError):
    """Raised when a job cannot be executed."""


@dataclass(slots=True)
class JobResult:
    """Container for remote job execution results."""

    host: str
from typing import Optional


class RemoteJobError(RuntimeError):
    """Raised when a remote job fails to execute successfully."""

    def __init__(self, message: str, *, stderr: str = "", returncode: Optional[int] = None):
        super().__init__(message)
        self.stderr = stderr
        self.returncode = returncode


@dataclass
class RemoteJobResult:
    """Encapsulate stdout/stderr from a remote job."""

    command: str
    returncode: int
    stdout: str
    stderr: str

    @property
    def status(self) -> str:
        return "ok" if self.returncode == 0 else "error"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "host": self.host,
            "command": self.command,
            "returncode": self.returncode,
            "stdout": self.stdout,
            "stderr": self.stderr,
            "status": self.status,
        }


def run_remote(
    host: str,
    command: str,
    *,
    user: Optional[str] = None,
    timeout: int = 60,
) -> Dict[str, Any]:
    """Execute a command on a remote host via SSH."""
    if not command or not command.strip():
        raise JobError("Command must not be empty")

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
                "bash",
                "-lc",
                command,
            ],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError as exc:  # pragma: no cover - environment guard
        raise JobError("ssh executable not found") from exc
    except subprocess.TimeoutExpired as exc:
        raise JobError(f"Timed out running command on {target}") from exc

    result = JobResult(
        host=target,
        command=command,
        returncode=completed.returncode,
        stdout=completed.stdout,
        stderr=completed.stderr,
    )

    payload = result.to_dict()
    if result.returncode != 0:
        payload["error"] = f"Command exited with status {result.returncode}"

    return payload


__all__ = ["run_remote", "JobError", "JobResult"]
"""Utilities to run jobs on remote Jetson devices."""
from __future__ import annotations

import subprocess


def run_remote(host: str, command: str, user: str = "jetson") -> None:
    """Run an arbitrary command on the Jetson via SSH."""
    full_host = f"{user}@{host}"
    try:
        subprocess.run(["ssh", "-t", full_host, command], check=True)
    except subprocess.CalledProcessError as exc:
        print(f"[BlackRoad] Job failed with exit {exc.returncode}")
"""Remote job helpers for the Jetson runner."""

from __future__ import annotations

import shlex
import subprocess
from typing import Dict, Optional

from . import _host_user


def start_remote_logged(jid: int, command: str, host: str | None = None, user: str | None = None) -> Dict[str, str]:
    """Launch ``command`` on the remote host and capture output to a log file."""
"""Remote job execution helpers for Jetson hosts."""
"""Helpers for orchestrating Jetson-hosted jobs over SSH."""

from __future__ import annotations

import os
import shlex
import subprocess
from typing import Dict, Generator
import re
import shlex
import subprocess
from typing import Dict, Generator, Optional
import os
import subprocess

JETSON_HOST = os.getenv("JETSON_HOST", "jetson.local")
JETSON_USER = os.getenv("JETSON_USER", "jetson")


def _host_user(host: str | None = None, user: str | None = None) -> tuple[str, str]:
    """Resolve the host and user, falling back to defaults."""

    return (host or JETSON_HOST, user or JETSON_USER)


def run_remote_stream(
    host: str | None = None,
    command: str = "",
    user: str | None = None,
) -> Generator[str, None, None]:
    """Legacy helper that streams a one-shot remote command."""
def _host_user(host: Optional[str] = None, user: Optional[str] = None) -> tuple[str, str]:
    """Return the resolved ``(host, user)`` pair for SSH commands."""

    return host or JETSON_HOST, user or JETSON_USER


def run_remote_stream(host: Optional[str] = None, command: str = "", user: Optional[str] = None):
    """Legacy helper: stream a one-shot remote command over SSH."""

    host, user = _host_user(host, user)
def run_remote(host: str = None, command: str = "", user: str = None):
    host = host or JETSON_HOST
    user = user or JETSON_USER
    subprocess.run(["ssh", "-t", f"{user}@{host}", command], check=True)


def run_remote_stream(host: str = None, command: str = "", user: str = None):
    host = host or JETSON_HOST
    user = user or JETSON_USER
    proc = subprocess.Popen(
        ["ssh", f"{user}@{host}", command],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    try:
        if proc.stdout is None:  # pragma: no cover - defensive guard
        if proc.stdout is None:  # pragma: no cover - defensive
            return
        for line in proc.stdout:
            yield line.rstrip("\n")
    finally:
        if proc.stdout is not None:
            proc.stdout.close()
        proc.wait()


def start_remote_logged(
    jid: int,
    command: str,
    host: str | None = None,
    user: str | None = None,
) -> Dict[str, object]:
    """Start a remote job detached from SSH and capture PID/log paths."""
    host: Optional[str] = None,
    user: Optional[str] = None,
) -> Dict[str, int | str]:
    """Start a detached remote job and return metadata about the process."""

    host, user = _host_user(host, user)
    log = f"/tmp/blackroad_job_{jid}.log"
    pidf = f"/tmp/blackroad_job_{jid}.pid"
    exitf = f"/tmp/blackroad_job_{jid}.exit"
    inner = f"( exec setsid bash -lc '{command}'; echo $? > {shlex.quote(exitf)} )"
    remote = (
        "bash -lc 'set -m; "
        f"rm -f {shlex.quote(log)} {shlex.quote(pidf)} {shlex.quote(exitf)}; "
        f"nohup bash -lc {shlex.quote(inner)} "
    quoted_cmd = shlex.quote(f"exec setsid bash -lc '{command}'")
    remote = (
        "bash -lc 'set -m; "
        f"rm -f {shlex.quote(log)} {shlex.quote(pidf)}; "
        f"nohup bash -lc {quoted_cmd} "
        f"> {shlex.quote(log)} 2>&1 & echo $! > {shlex.quote(pidf)}; "
        f"disown; sleep 0.2; cat {shlex.quote(pidf)}'"
    )
    pid = subprocess.check_output(["ssh", f"{user}@{host}", remote], text=True).strip()
    return {"pid": int(pid), "log": log, "pidfile": pidf, "exitfile": exitf}


def remote_exit_code(jid: int, host: str | None = None, user: str | None = None) -> Optional[int]:
    """Fetch the exit code for ``jid`` from the remote sidecar file."""

    host, user = _host_user(host, user)
    exitf = f"/tmp/blackroad_job_{jid}.exit"
    try:
        out = subprocess.check_output(
            [
                "ssh",
                f"{user}@{host}",
                "bash",
                "-lc",
                f"cat {shlex.quote(exitf)} 2>/dev/null || true",
            ],
            text=True,
        ).strip()
        return int(out) if out != "" else None
    except Exception:
        return None
from typing import Iterable


def _prepare_command(command: str) -> str:
    if not command:
        raise ValueError("command must be non-empty")
    return command


def run_remote_stream(command: str) -> Iterable[str]:
    """Run *command* locally and yield stdout/stderr lines as they arrive."""

    cmd = _prepare_command(command)
    proc = subprocess.Popen(
        cmd,
        shell=True,
from typing import Iterator


def run_remote(host: str, command: str, user: str = "jetson") -> None:
    """Execute a remote command over SSH and wait for completion."""
    full = ["ssh", "-t", f"{user}@{host}", command]
    subprocess.run(full, check=True)


def run_remote_stream(host: str, command: str, user: str = "jetson") -> Iterator[str]:
    """Yield stdout lines live from a remote command over SSH."""
    full = ["ssh", f"{user}@{host}", command]
    proc = subprocess.Popen(
        full,
    return {"pid": int(pid), "log": log, "pidfile": pidf}

    quoted_command = shlex.quote(f"exec setsid bash -lc '{command}'")
    remote_cmd = (
        "bash -lc 'set -m; "
        f"rm -f {shlex.quote(log)} {shlex.quote(pidf)}; "
        f"nohup bash -lc {quoted_command} > {shlex.quote(log)} 2>&1 & "
        f"echo $! > {shlex.quote(pidf)}; disown; sleep 0.2; "
        f"cat {shlex.quote(pidf)}'"
    )
    pid_txt = subprocess.check_output(["ssh", f"{user}@{host}", remote_cmd], text=True).strip()
    pid = int(pid_txt)
    return {"pid": pid, "log": log, "pidfile": pidf}


def tail_remote_log(
    log_path: str,
    host: str | None = None,
    user: str | None = None,
) -> Generator[str, None, None]:
    """Stream a remote logfile until EOF (caller decides when to stop)."""
    host: Optional[str] = None,
    user: Optional[str] = None,
) -> Generator[str, None, None]:
    """Yield log lines from the remote ``log_path`` using ``tail -F``."""

    host, user = _host_user(host, user)
    cmd = [
        "ssh",
        f"{user}@{host}",
        "bash",
        "-lc",
        f"tail -n +1 -F {shlex.quote(log_path)}",
    ]
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
        executable="/bin/bash",
    )

    assert proc.stdout is not None
    try:
        for line in proc.stdout:
            yield line.rstrip("\n")
        return_code = proc.wait()
        if return_code != 0:
            raise RuntimeError(f"command exited with code {return_code}")
    finally:
        try:
            proc.stdout.close()
        except Exception:
            pass
        if proc.poll() is None:
            proc.kill()
    )
    try:
        if proc.stdout is None:
            return
        for line in proc.stdout:
            yield line.rstrip("\n")
    finally:
        if proc.stdout is not None:
            proc.stdout.close()
        proc.wait()
    )
    try:
        if proc.stdout is None:  # pragma: no cover - defensive guard
    )
    try:
        if proc.stdout is None:  # pragma: no cover - defensive
            return
        for line in proc.stdout:
            yield line.rstrip("\n")
    finally:
        if proc.stdout is not None:
            proc.stdout.close()
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except Exception:
            proc.kill()


def remote_is_running(
    jid: int,
    host: str | None = None,
    user: str | None = None,
) -> bool:
    """Return True if the PID recorded for ``jid`` is still alive."""
        except Exception:  # pragma: no cover - best-effort cleanup
            proc.kill()


def remote_is_running(jid: int, host: Optional[str] = None, user: Optional[str] = None) -> bool:
    """Check whether the remote PID recorded for ``jid`` is still alive."""

    host, user = _host_user(host, user)
    pidf = f"/tmp/blackroad_job_{jid}.pid"
    try:
        out = subprocess.check_output(
            [
                "ssh",
                f"{user}@{host}",
                "bash",
                "-lc",
                "pid=$(cat {pid} 2>/dev/null || echo); "
                'test -n "$pid" && kill -0 $pid 2>/dev/null && echo RUN || echo DEAD'
                .format(pid=shlex.quote(pidf)),
            ],
            text=True,
        ).strip()
        script = (
            f"bash -lc \"pid=$(cat {shlex.quote(pidf)} 2>/dev/null || echo); "
            "test -n \"$pid\" && kill -0 $pid 2>/dev/null && echo RUN || echo DEAD\""
        )
        out = subprocess.check_output(["ssh", f"{user}@{host}", script], text=True).strip()
        return out == "RUN"
    except Exception:
        return False


def remote_kill(
    jid: int,
    host: str | None = None,
    user: str | None = None,
    sig: str = "TERM",
) -> bool:
    """Send ``sig`` to the remote process associated with ``jid``."""

    host, user = _host_user(host, user)
    pidf = f"/tmp/blackroad_job_{jid}.pid"
    try:
        subprocess.check_call(
            [
                "ssh",
                f"{user}@{host}",
                "bash",
                "-lc",
                "pid=$(cat {pid} 2>/dev/null || echo); "
                'test -n "$pid" && kill -s {sig} $pid 2>/dev/null || true'.format(
                    pid=shlex.quote(pidf), sig=shlex.quote(sig)
                ),
            ]
        )
    host: Optional[str] = None,
    user: Optional[str] = None,
    sig: str = "TERM",
) -> bool:
    """Send ``sig`` to the remote PID registered for ``jid``."""

    host, user = _host_user(host, user)
    pidf = f"/tmp/blackroad_job_{jid}.pid"
    signal = sig if re.fullmatch(r"[A-Za-z0-9_+-]+", sig) else "TERM"
    try:
        script = (
            f"bash -lc \"pid=$(cat {shlex.quote(pidf)} 2>/dev/null || echo); "
            f"test -n \"$pid\" && kill -s {signal} $pid 2>/dev/null || true\""
        )
        subprocess.check_call(["ssh", f"{user}@{host}", script])
        return True
    except Exception:
        return False
"""Helpers for executing jobs on the Jetson target over SSH."""
from __future__ import annotations

import os
import subprocess
from typing import Iterator, Mapping, Sequence

from agent.config import active_target


def _target() -> tuple[str, str]:
    env_host = os.getenv("JETSON_HOST")
    env_user = os.getenv("JETSON_USER")
    host, user = active_target()
    if env_host or env_user:
        return env_host or host, env_user or user
    return host, user


def _resolve(host: str | None, user: str | None) -> tuple[str, str]:
    default_host, default_user = _target()
    return host or default_host, user or default_user


def _ssh_command(host: str, user: str, command: Sequence[str] | str) -> list[str]:
    if isinstance(command, str):
        remote = ["bash", "-lc", command]
    else:
        remote = list(command)
    return [

def _ssh_target(host: str, user: Optional[str]) -> str:
    return f"{user}@{host}" if user else host


def run_remote(host: str, command: str, *, user: Optional[str] = None, timeout: int = 60) -> RemoteJobResult:
    """Execute ``command`` on a remote host via SSH.

    The command is executed without invoking a shell on the local machine to avoid
    injection vulnerabilities. The remote host will still interpret the command
    string using its default shell, so callers should only pass vetted commands.
    """

    if not command.strip():
        raise ValueError("command must be a non-empty string")

    target = _ssh_target(host, user)
    ssh_command = [
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


def run_remote(
    command: Sequence[str] | str,
    *,
    host: str | None = None,
    user: str | None = None,
    check: bool = False,
    timeout: int | None = None,
    env: Mapping[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    """Run a command on the Jetson via SSH."""
    host, user = _resolve(host, user)
    ssh_cmd = _ssh_command(host, user, command)
    return subprocess.run(
        ssh_cmd,
        check=check,
        text=True,
        capture_output=True,
        timeout=timeout,
        env=env,
    )


def stream_remote(
    command: Sequence[str] | str,
    *,
    host: str | None = None,
    user: str | None = None,
    timeout: int | None = None,
) -> Iterator[str]:
    """Yield lines from a remote command, useful for long-running jobs."""
    host, user = _resolve(host, user)
    ssh_cmd = _ssh_command(host, user, command)
    with subprocess.Popen(
        ssh_cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    ) as proc:
        try:
            while True:
                line = proc.stdout.readline()
                if not line:
                    break
                yield line.rstrip("\n")
            proc.wait(timeout=timeout)
        finally:
            if proc.poll() is None:
                proc.terminate()


def copy_to_remote(
    local_path: str,
    remote_path: str,
    *,
    host: str | None = None,
    user: str | None = None,
    recursive: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Copy a local file or directory to the Jetson target using scp."""
    host, user = _resolve(host, user)
    cmd = [
        "scp",
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "ConnectTimeout=5",
    ]
    if recursive:
        cmd.append("-r")
    cmd.extend([local_path, f"{user}@{host}:{remote_path}"])
    return subprocess.run(cmd, text=True, capture_output=True)


def copy_from_remote(
    remote_path: str,
    local_path: str,
    *,
    host: str | None = None,
    user: str | None = None,
    recursive: bool = False,
) -> subprocess.CompletedProcess[str]:
    """Copy a remote file or directory from the Jetson target."""
    host, user = _resolve(host, user)
    cmd = [
        "scp",
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "ConnectTimeout=5",
    ]
    if recursive:
        cmd.append("-r")
    cmd.extend([f"{user}@{host}:{remote_path}", local_path])
    return subprocess.run(cmd, text=True, capture_output=True)


__all__ = [
    "run_remote",
    "stream_remote",
    "copy_to_remote",
    "copy_from_remote",
]
        bufsize=1
    )
    try:
        for line in proc.stdout:  # type: ignore
            yield line.rstrip("\n")
    finally:
        proc.stdout and proc.stdout.close()  # type: ignore
        proc.wait()
        f"ConnectTimeout={timeout}",
        target,
        command,
    ]

    result = subprocess.run(
        ssh_command,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
    )

    if result.returncode != 0:
        raise RemoteJobError(
            f"remote command failed with exit code {result.returncode}",
            stderr=result.stderr,
            returncode=result.returncode,
        )

    return RemoteJobResult(
        command=command,
        returncode=result.returncode,
        stdout=result.stdout,
        stderr=result.stderr,
    )


__all__ = ["RemoteJobError", "RemoteJobResult", "run_remote"]
