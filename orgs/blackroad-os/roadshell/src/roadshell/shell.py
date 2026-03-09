"""
RoadShell - Shell Command Execution for BlackRoad
Execute shell commands with streaming and process management.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, Generator, List, Optional, Tuple
import asyncio
import logging
import os
import shlex
import signal
import subprocess
import threading
import time

logger = logging.getLogger(__name__)


class ProcessStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    KILLED = "killed"
    TIMEOUT = "timeout"


@dataclass
class CommandResult:
    command: str
    exit_code: int
    stdout: str
    stderr: str
    status: ProcessStatus
    started_at: datetime
    ended_at: datetime
    duration_ms: float
    pid: Optional[int] = None


@dataclass
class ProcessInfo:
    pid: int
    command: str
    status: ProcessStatus
    started_at: datetime
    process: Optional[subprocess.Popen] = None


class Shell:
    def __init__(self, cwd: str = None, env: Dict[str, str] = None, timeout: int = 300):
        self.cwd = cwd or os.getcwd()
        self.env = {**os.environ, **(env or {})}
        self.timeout = timeout
        self.processes: Dict[int, ProcessInfo] = {}
        self.history: List[CommandResult] = []

    def run(self, command: str, capture: bool = True, timeout: int = None) -> CommandResult:
        timeout = timeout or self.timeout
        started_at = datetime.now()
        status = ProcessStatus.RUNNING
        
        try:
            proc = subprocess.Popen(
                command,
                shell=True,
                stdout=subprocess.PIPE if capture else None,
                stderr=subprocess.PIPE if capture else None,
                cwd=self.cwd,
                env=self.env
            )
            
            self.processes[proc.pid] = ProcessInfo(
                pid=proc.pid,
                command=command,
                status=ProcessStatus.RUNNING,
                started_at=started_at,
                process=proc
            )
            
            stdout, stderr = proc.communicate(timeout=timeout)
            
            if proc.returncode == 0:
                status = ProcessStatus.COMPLETED
            else:
                status = ProcessStatus.FAILED
                
        except subprocess.TimeoutExpired:
            proc.kill()
            stdout, stderr = proc.communicate()
            status = ProcessStatus.TIMEOUT
        except Exception as e:
            logger.error(f"Command failed: {e}")
            stdout, stderr = b"", str(e).encode()
            status = ProcessStatus.FAILED
            proc = type("FakeProc", (), {"returncode": 1, "pid": None})()
        
        ended_at = datetime.now()
        result = CommandResult(
            command=command,
            exit_code=proc.returncode,
            stdout=stdout.decode("utf-8", errors="replace") if stdout else "",
            stderr=stderr.decode("utf-8", errors="replace") if stderr else "",
            status=status,
            started_at=started_at,
            ended_at=ended_at,
            duration_ms=(ended_at - started_at).total_seconds() * 1000,
            pid=proc.pid
        )
        
        if proc.pid in self.processes:
            self.processes[proc.pid].status = status
        
        self.history.append(result)
        return result

    def run_async(self, command: str) -> ProcessInfo:
        started_at = datetime.now()
        
        proc = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=self.cwd,
            env=self.env
        )
        
        info = ProcessInfo(
            pid=proc.pid,
            command=command,
            status=ProcessStatus.RUNNING,
            started_at=started_at,
            process=proc
        )
        
        self.processes[proc.pid] = info
        return info

    def stream(self, command: str) -> Generator[str, None, int]:
        proc = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            cwd=self.cwd,
            env=self.env,
            bufsize=1,
            universal_newlines=True
        )
        
        for line in iter(proc.stdout.readline, ""):
            yield line.rstrip()
        
        proc.wait()
        return proc.returncode

    def pipe(self, *commands: str) -> CommandResult:
        procs = []
        started_at = datetime.now()
        
        for i, cmd in enumerate(commands):
            stdin = procs[-1].stdout if procs else None
            proc = subprocess.Popen(
                cmd,
                shell=True,
                stdin=stdin,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=self.cwd,
                env=self.env
            )
            procs.append(proc)
        
        for proc in procs[:-1]:
            proc.stdout.close()
        
        stdout, stderr = procs[-1].communicate()
        
        for proc in procs:
            proc.wait()
        
        ended_at = datetime.now()
        return CommandResult(
            command=" | ".join(commands),
            exit_code=procs[-1].returncode,
            stdout=stdout.decode("utf-8", errors="replace"),
            stderr=stderr.decode("utf-8", errors="replace"),
            status=ProcessStatus.COMPLETED if procs[-1].returncode == 0 else ProcessStatus.FAILED,
            started_at=started_at,
            ended_at=ended_at,
            duration_ms=(ended_at - started_at).total_seconds() * 1000
        )

    def kill(self, pid: int, sig: int = signal.SIGTERM) -> bool:
        info = self.processes.get(pid)
        if info and info.process:
            try:
                info.process.send_signal(sig)
                info.status = ProcessStatus.KILLED
                return True
            except ProcessLookupError:
                return False
        return False

    def wait(self, pid: int, timeout: int = None) -> Optional[int]:
        info = self.processes.get(pid)
        if info and info.process:
            try:
                return info.process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                return None
        return None

    def is_running(self, pid: int) -> bool:
        info = self.processes.get(pid)
        if info and info.process:
            return info.process.poll() is None
        return False

    def which(self, program: str) -> Optional[str]:
        result = self.run(f"which {shlex.quote(program)}", capture=True)
        if result.exit_code == 0:
            return result.stdout.strip()
        return None

    def cd(self, path: str) -> bool:
        new_path = os.path.join(self.cwd, path)
        if os.path.isdir(new_path):
            self.cwd = os.path.abspath(new_path)
            return True
        return False

    def env_set(self, key: str, value: str) -> None:
        self.env[key] = value

    def env_get(self, key: str, default: str = None) -> Optional[str]:
        return self.env.get(key, default)

    def get_history(self, limit: int = 10) -> List[CommandResult]:
        return list(reversed(self.history[-limit:]))


class CommandBuilder:
    def __init__(self):
        self._parts: List[str] = []
        self._env: Dict[str, str] = {}
        self._cwd: Optional[str] = None

    def cmd(self, command: str) -> "CommandBuilder":
        self._parts.append(command)
        return self

    def arg(self, *args: str) -> "CommandBuilder":
        self._parts.extend(shlex.quote(a) for a in args)
        return self

    def opt(self, name: str, value: str = None) -> "CommandBuilder":
        if value is not None:
            self._parts.append(f"--{name}={shlex.quote(value)}")
        else:
            self._parts.append(f"--{name}")
        return self

    def flag(self, name: str) -> "CommandBuilder":
        self._parts.append(f"-{name}")
        return self

    def pipe(self, command: str) -> "CommandBuilder":
        self._parts.append("|")
        self._parts.append(command)
        return self

    def redirect(self, file: str, append: bool = False) -> "CommandBuilder":
        op = ">>" if append else ">"
        self._parts.append(f"{op} {shlex.quote(file)}")
        return self

    def env(self, key: str, value: str) -> "CommandBuilder":
        self._env[key] = value
        return self

    def cwd(self, path: str) -> "CommandBuilder":
        self._cwd = path
        return self

    def build(self) -> str:
        env_str = " ".join(f"{k}={shlex.quote(v)}" for k, v in self._env.items())
        cmd_str = " ".join(self._parts)
        if env_str:
            return f"{env_str} {cmd_str}"
        return cmd_str

    def run(self, shell: Shell = None) -> CommandResult:
        shell = shell or Shell(cwd=self._cwd)
        return shell.run(self.build())


def example_usage():
    shell = Shell()
    
    result = shell.run("echo 'Hello, World!'")
    print(f"Exit: {result.exit_code}, Output: {result.stdout.strip()}")
    
    result = shell.run("ls -la | head -5")
    print(f"\nListing:\n{result.stdout}")
    
    result = shell.pipe("echo 'hello world'", "tr 'a-z' 'A-Z'", "rev")
    print(f"Piped result: {result.stdout.strip()}")
    
    cmd = (CommandBuilder()
        .cmd("curl")
        .flag("s")
        .opt("max-time", "5")
        .arg("https://example.com")
        .pipe("head -3"))
    print(f"\nBuilt command: {cmd.build()}")
    
    print("\nStreaming output:")
    for line in shell.stream("for i in 1 2 3; do echo Line $i; sleep 0.1; done"):
        print(f"  > {line}")
    
    print(f"\nHistory: {len(shell.history)} commands")

