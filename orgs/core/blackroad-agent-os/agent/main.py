"""
BlackRoad Agent Daemon

Runs on each Raspberry Pi to execute tasks from the controller.
"""
import asyncio
import signal
import sys
import structlog

from config import AgentConfig
from core.connection import ControllerConnection
from core.executor import CommandExecutor
from services.telemetry import TelemetryService
from models import TaskPlan, CommandResult

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.dev.ConsoleRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()


class AgentDaemon:
    """
    Main agent daemon that orchestrates all components.
    """

    def __init__(self, config: AgentConfig):
        self.config = config
        self.connection = ControllerConnection(config)
        self.executor = CommandExecutor(config)
        self.telemetry = TelemetryService()
        self._running = False
        self._current_task_id: str | None = None

        # Register message handlers
        self.connection.on("execute_task", self._handle_execute_task)

    async def start(self):
        """Start the agent daemon"""
        logger.info("agent_starting", agent_id=self.config.agent_id)
        self._running = True

        # Start telemetry collection
        telemetry_task = asyncio.create_task(self.telemetry.start())

        # Update connection with telemetry
        async def telemetry_updater():
            while self._running:
                self.connection.set_telemetry(self.telemetry.current)
                self.connection.set_workspaces(self.executor.get_workspaces())
                await asyncio.sleep(5)

        updater_task = asyncio.create_task(telemetry_updater())

        try:
            # Connect to controller (will reconnect on failure)
            await self.connection.connect()
        finally:
            self._running = False
            telemetry_task.cancel()
            updater_task.cancel()
            await self.telemetry.stop()

    async def stop(self):
        """Stop the agent daemon"""
        logger.info("agent_stopping")
        self._running = False
        await self.connection.disconnect()

    async def _handle_execute_task(self, payload: dict):
        """Handle task execution request from controller"""
        logger.info("execute_task_received", payload_keys=list(payload.keys()))

        task_id = payload.get("task_id")
        plan_data = payload.get("plan")

        if not task_id or not plan_data:
            logger.error("invalid_execute_task", payload=payload, task_id=task_id, has_plan=bool(plan_data))
            return

        logger.info("executing_task", task_id=task_id, commands=len(plan_data.get("commands", [])))
        self._current_task_id = task_id
        self.connection.set_current_task(task_id)

        try:
            # Parse plan
            plan = TaskPlan(**plan_data)

            # Execute with streaming output
            async def output_callback(stream: str, content: str, cmd_idx: int):
                await self.connection.send("task_output", {
                    "task_id": task_id,
                    "stream": stream,
                    "content": content,
                    "command_index": cmd_idx,
                })

            async def result_callback(result: CommandResult):
                await self.connection.send("command_result", {
                    "task_id": task_id,
                    "command_index": result.command_index,
                    "command": result.command,
                    "exit_code": result.exit_code,
                    "duration_ms": result.duration_ms,
                })

            success, results = await self.executor.execute_plan(
                task_id=task_id,
                plan=plan,
                output_callback=output_callback,
                result_callback=result_callback,
            )

            # Send completion
            final_output = "\n".join(r.stdout for r in results)
            final_error = "\n".join(r.stderr for r in results if r.stderr)
            final_exit_code = results[-1].exit_code if results else 0

            logger.info("sending_task_complete", task_id=task_id, success=success, exit_code=final_exit_code)
            await self.connection.send("task_complete", {
                "task_id": task_id,
                "success": success,
                "exit_code": final_exit_code,
                "output": final_output[-10000:],  # Truncate if too long
                "error": final_error[-5000:] if final_error else None,
            })

            logger.info("task_executed", task_id=task_id, success=success)

        except Exception as e:
            logger.error("task_execution_error", task_id=task_id, error=str(e))
            await self.connection.send("task_complete", {
                "task_id": task_id,
                "success": False,
                "exit_code": -1,
                "error": str(e),
            })

        finally:
            self._current_task_id = None
            self.connection.set_current_task(None)


async def main():
    """Main entry point"""
    config = AgentConfig.from_env()

    logger.info(
        "agent_config",
        agent_id=config.agent_id,
        controller_url=config.controller_url,
        roles=config.roles,
    )

    daemon = AgentDaemon(config)

    # Handle shutdown signals
    loop = asyncio.get_event_loop()

    def signal_handler():
        logger.info("shutdown_signal_received")
        asyncio.create_task(daemon.stop())

    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, signal_handler)

    try:
        await daemon.start()
    except KeyboardInterrupt:
        await daemon.stop()


if __name__ == "__main__":
    asyncio.run(main())
