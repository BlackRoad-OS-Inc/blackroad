"""
Controller Connection - WebSocket client for controller communication
"""
import asyncio
import json
from typing import Optional, Callable, Awaitable
import websockets
from websockets.client import WebSocketClientProtocol
import structlog

from config import AgentConfig, detect_capabilities
from models import Telemetry, Workspace

logger = structlog.get_logger()


class ControllerConnection:
    """
    Manages the WebSocket connection to the controller.
    Handles reconnection, heartbeats, and message routing.
    """

    def __init__(self, config: AgentConfig):
        self.config = config
        self._ws: Optional[WebSocketClientProtocol] = None
        self._running = False
        self._handlers: dict[str, Callable[[dict], Awaitable[None]]] = {}
        self._workspaces: list[Workspace] = []
        self._current_task_id: Optional[str] = None
        self._telemetry = Telemetry()

    def on(self, message_type: str, handler: Callable[[dict], Awaitable[None]]):
        """Register a handler for a message type"""
        self._handlers[message_type] = handler

    def set_workspaces(self, workspaces: list[Workspace]):
        """Update workspace list"""
        self._workspaces = workspaces

    def set_current_task(self, task_id: Optional[str]):
        """Update current task ID"""
        self._current_task_id = task_id

    def set_telemetry(self, telemetry: Telemetry):
        """Update telemetry data"""
        self._telemetry = telemetry

    async def send(self, message_type: str, payload: dict = None):
        """Send a message to the controller"""
        if not self._ws:
            logger.warning("not_connected", message_type=message_type)
            return False

        try:
            await self._ws.send(json.dumps({
                "type": message_type,
                "payload": payload or {},
            }))
            return True
        except Exception as e:
            logger.error("send_failed", message_type=message_type, error=str(e))
            return False

    async def connect(self):
        """Connect to the controller"""
        self._running = True

        while self._running:
            try:
                logger.info("connecting", url=self.config.controller_url)

                async with websockets.connect(
                    self.config.controller_url,
                    ping_interval=30,
                    ping_timeout=10,
                ) as ws:
                    self._ws = ws
                    logger.info("connected")

                    # Send registration
                    await self._register()

                    # Start heartbeat task
                    heartbeat_task = asyncio.create_task(self._heartbeat_loop())

                    try:
                        # Message receive loop
                        async for message in ws:
                            await self._handle_message(message)
                    finally:
                        heartbeat_task.cancel()
                        try:
                            await heartbeat_task
                        except asyncio.CancelledError:
                            pass

            except websockets.ConnectionClosed as e:
                logger.warning("connection_closed", code=e.code, reason=e.reason)
            except Exception as e:
                logger.error("connection_error", error=str(e))
            finally:
                self._ws = None

            if self._running:
                logger.info("reconnecting", delay=self.config.reconnect_delay)
                await asyncio.sleep(self.config.reconnect_delay)

    async def disconnect(self):
        """Disconnect from the controller"""
        self._running = False
        if self._ws:
            await self._ws.close()

    async def _register(self):
        """Send registration message"""
        capabilities = detect_capabilities()

        await self.send("register", {
            "id": self.config.agent_id,
            "hostname": self.config.hostname,
            "display_name": self.config.display_name or self.config.agent_id,
            "roles": self.config.roles,
            "tags": self.config.tags,
            "capabilities": capabilities,
        })

    async def _heartbeat_loop(self):
        """Send periodic heartbeats"""
        while True:
            await asyncio.sleep(self.config.heartbeat_interval)
            try:
                await self.send("heartbeat", {
                    "agent_id": self.config.agent_id,
                    "telemetry": self._telemetry.model_dump(),
                    "current_task_id": self._current_task_id,
                    "workspaces": [w.model_dump() for w in self._workspaces],
                })
            except Exception as e:
                logger.error("heartbeat_failed", error=str(e))

    async def _handle_message(self, raw_message: str):
        """Handle an incoming message"""
        try:
            message = json.loads(raw_message)
            msg_type = message.get("type")
            payload = message.get("payload", {})

            logger.info("message_received", type=msg_type, has_payload=bool(payload))

            # Check for registered handler
            if msg_type in self._handlers:
                await self._handlers[msg_type](payload)
            elif msg_type == "registered":
                logger.info("registration_confirmed", message=payload.get("message"))
            elif msg_type == "ping":
                await self.send("pong")
            elif msg_type == "error":
                logger.error("controller_error", message=payload.get("message"))
            else:
                logger.warning("unknown_message_type", type=msg_type)

        except json.JSONDecodeError as e:
            logger.error("message_parse_error", error=str(e))
        except Exception as e:
            logger.error("message_handler_error", error=str(e))
