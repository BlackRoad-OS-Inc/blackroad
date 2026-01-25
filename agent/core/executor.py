"""
Command Executor - Safely execute commands in workspaces
"""
import asyncio
import os
import subprocess
import time
from datetime import datetime
from pathlib import Path
from typing import Optional, Callable, Awaitable
import structlog

from config import AgentConfig
from models import Command, CommandResult, TaskPlan, Workspace, WorkspaceType, WorkspaceStatus

logger = structlog.get_logger()


class CommandExecutor:
    """
    Executes commands in isolated workspaces.
    Supports bare shell, Docker, and venv environments.
    """

    def __init__(self, config: AgentConfig):
        self.config = config
        self._workspaces: dict[str, Workspace] = {}
        self._ensure_workspace_root()

    def _ensure_workspace_root(self):
        """Ensure workspace root directory exists"""
        self.config.workspace_root.mkdir(parents=True, exist_ok=True)

    def get_workspaces(self) -> list[Workspace]:
        """Get all workspaces"""
        return list(self._workspaces.values())

    async def get_or_create_workspace(
        self,
        name: str,
        workspace_type: WorkspaceType = WorkspaceType.BARE,
    ) -> Workspace:
        """Get an existing workspace or create a new one"""
        if name in self._workspaces:
            return self._workspaces[name]

        workspace_path = self.config.workspace_root / name
        workspace_path.mkdir(parents=True, exist_ok=True)

        workspace = Workspace(
            name=name,
            type=workspace_type,
            path=str(workspace_path),
            status=WorkspaceStatus.READY,
        )

        # Initialize based on type
        if workspace_type == WorkspaceType.DOCKER and self.config.docker_enabled:
            await self._init_docker_workspace(workspace)
        elif workspace_type == WorkspaceType.VENV:
            await self._init_venv_workspace(workspace)

        self._workspaces[name] = workspace
        logger.info("workspace_created", name=name, type=workspace_type.value)
        return workspace

    async def _init_docker_workspace(self, workspace: Workspace):
        """Initialize a Docker workspace"""
        # For now, we'll use docker run per command
        # A more advanced implementation would maintain a persistent container
        pass

    async def _init_venv_workspace(self, workspace: Workspace):
        """Initialize a Python venv workspace"""
        venv_path = Path(workspace.path) / "venv"
        if not venv_path.exists():
            proc = await asyncio.create_subprocess_exec(
                "python3", "-m", "venv", str(venv_path),
                cwd=workspace.path,
            )
            await proc.wait()

    async def execute_plan(
        self,
        task_id: str,
        plan: TaskPlan,
        output_callback: Optional[Callable[[str, str, int], Awaitable[None]]] = None,
        result_callback: Optional[Callable[[CommandResult], Awaitable[None]]] = None,
    ) -> tuple[bool, list[CommandResult]]:
        """
        Execute a full task plan.

        Args:
            task_id: The task ID for tracking
            plan: The execution plan
            output_callback: Async callback for streaming output (stream, content, cmd_idx)
            result_callback: Async callback for command results

        Returns:
            Tuple of (success, results)
        """
        workspace_type = WorkspaceType(plan.workspace_type) if plan.workspace_type else WorkspaceType.BARE
        workspace = await self.get_or_create_workspace(
            plan.workspace or "default",
            workspace_type,
        )

        workspace.status = WorkspaceStatus.BUSY
        workspace.last_used = datetime.utcnow()

        results = []
        success = True

        try:
            for i, command in enumerate(plan.commands):
                logger.info("executing_command", task_id=task_id, index=i, command=command.run[:100])

                result = await self.execute_command(
                    command=command,
                    workspace=workspace,
                    command_index=i,
                    output_callback=output_callback,
                )

                results.append(result)

                if result_callback:
                    await result_callback(result)

                if result.exit_code != 0:
                    if not command.continue_on_error:
                        success = False
                        logger.warning(
                            "command_failed",
                            task_id=task_id,
                            index=i,
                            exit_code=result.exit_code,
                        )
                        break
                    else:
                        logger.warning(
                            "command_failed_continuing",
                            task_id=task_id,
                            index=i,
                            exit_code=result.exit_code,
                        )

            logger.info("plan_completed", task_id=task_id, success=success, commands=len(results))

        finally:
            workspace.status = WorkspaceStatus.READY

        return success, results

    async def execute_command(
        self,
        command: Command,
        workspace: Workspace,
        command_index: int = 0,
        output_callback: Optional[Callable[[str, str, int], Awaitable[None]]] = None,
    ) -> CommandResult:
        """
        Execute a single command.

        Args:
            command: The command to execute
            workspace: The workspace to execute in
            command_index: Index for tracking
            output_callback: Callback for streaming output
        """
        started_at = datetime.utcnow()
        start_time = time.time()

        # Determine working directory
        if command.dir.startswith("~"):
            work_dir = Path.home() / command.dir[2:]
        elif command.dir.startswith("/"):
            work_dir = Path(command.dir)
        else:
            work_dir = Path(workspace.path) / command.dir

        work_dir = work_dir.resolve()

        # Build environment
        env = os.environ.copy()
        env.update(command.env)

        # Execute based on workspace type
        if workspace.type == WorkspaceType.DOCKER and self.config.docker_enabled:
            result = await self._execute_docker(
                command, workspace, work_dir, env, command_index, output_callback
            )
        elif workspace.type == WorkspaceType.VENV:
            result = await self._execute_venv(
                command, workspace, work_dir, env, command_index, output_callback
            )
        else:
            result = await self._execute_bare(
                command, work_dir, env, command_index, output_callback
            )

        duration_ms = (time.time() - start_time) * 1000
        completed_at = datetime.utcnow()

        return CommandResult(
            command_index=command_index,
            command=command.run,
            exit_code=result["exit_code"],
            stdout=result["stdout"],
            stderr=result["stderr"],
            duration_ms=duration_ms,
            started_at=started_at,
            completed_at=completed_at,
        )

    async def _execute_bare(
        self,
        command: Command,
        work_dir: Path,
        env: dict,
        command_index: int,
        output_callback: Optional[Callable[[str, str, int], Awaitable[None]]] = None,
    ) -> dict:
        """Execute command in bare shell"""
        proc = await asyncio.create_subprocess_shell(
            command.run,
            cwd=str(work_dir),
            env=env,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        stdout_chunks = []
        stderr_chunks = []

        async def read_stream(stream, name: str, chunks: list):
            while True:
                line = await stream.readline()
                if not line:
                    break
                decoded = line.decode("utf-8", errors="replace")
                chunks.append(decoded)
                if output_callback:
                    await output_callback(name, decoded, command_index)

        # Read stdout and stderr concurrently
        await asyncio.gather(
            read_stream(proc.stdout, "stdout", stdout_chunks),
            read_stream(proc.stderr, "stderr", stderr_chunks),
        )

        try:
            await asyncio.wait_for(proc.wait(), timeout=command.timeout_seconds)
        except asyncio.TimeoutError:
            proc.kill()
            return {
                "exit_code": -1,
                "stdout": "".join(stdout_chunks),
                "stderr": "".join(stderr_chunks) + "\n[TIMEOUT]",
            }

        return {
            "exit_code": proc.returncode or 0,
            "stdout": "".join(stdout_chunks),
            "stderr": "".join(stderr_chunks),
        }

    async def _execute_docker(
        self,
        command: Command,
        workspace: Workspace,
        work_dir: Path,
        env: dict,
        command_index: int,
        output_callback: Optional[Callable[[str, str, int], Awaitable[None]]] = None,
    ) -> dict:
        """Execute command in Docker container"""
        # Build docker run command
        docker_cmd = [
            "docker", "run", "--rm",
            "-v", f"{workspace.path}:/workspace",
            "-w", "/workspace",
        ]

        # Add environment variables
        for key, value in env.items():
            docker_cmd.extend(["-e", f"{key}={value}"])

        docker_cmd.extend([
            self.config.docker_default_image,
            "sh", "-c", command.run,
        ])

        proc = await asyncio.create_subprocess_exec(
            *docker_cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        stdout_chunks = []
        stderr_chunks = []

        async def read_stream(stream, name: str, chunks: list):
            while True:
                line = await stream.readline()
                if not line:
                    break
                decoded = line.decode("utf-8", errors="replace")
                chunks.append(decoded)
                if output_callback:
                    await output_callback(name, decoded, command_index)

        await asyncio.gather(
            read_stream(proc.stdout, "stdout", stdout_chunks),
            read_stream(proc.stderr, "stderr", stderr_chunks),
        )

        try:
            await asyncio.wait_for(proc.wait(), timeout=command.timeout_seconds)
        except asyncio.TimeoutError:
            proc.kill()
            return {
                "exit_code": -1,
                "stdout": "".join(stdout_chunks),
                "stderr": "".join(stderr_chunks) + "\n[TIMEOUT]",
            }

        return {
            "exit_code": proc.returncode or 0,
            "stdout": "".join(stdout_chunks),
            "stderr": "".join(stderr_chunks),
        }

    async def _execute_venv(
        self,
        command: Command,
        workspace: Workspace,
        work_dir: Path,
        env: dict,
        command_index: int,
        output_callback: Optional[Callable[[str, str, int], Awaitable[None]]] = None,
    ) -> dict:
        """Execute command in Python venv"""
        venv_path = Path(workspace.path) / "venv"
        venv_bin = venv_path / "bin"

        # Activate venv by modifying PATH
        env["VIRTUAL_ENV"] = str(venv_path)
        env["PATH"] = f"{venv_bin}:{env.get('PATH', '')}"

        return await self._execute_bare(
            command, work_dir, env, command_index, output_callback
        )
