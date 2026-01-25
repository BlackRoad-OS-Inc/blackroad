"""
Agent Registry - Manages agent inventory and connections
"""
import asyncio
from datetime import datetime, timedelta
from typing import Optional
from fastapi import WebSocket
import structlog

from models import Agent, AgentStatus, AgentRegistration, AgentHeartbeat

logger = structlog.get_logger()


class AgentConnection:
    """Represents an active WebSocket connection to an agent"""
    def __init__(self, agent_id: str, websocket: WebSocket):
        self.agent_id = agent_id
        self.websocket = websocket
        self.connected_at = datetime.utcnow()
        self.last_message = datetime.utcnow()

    async def send(self, message: dict):
        """Send a message to the agent"""
        await self.websocket.send_json(message)

    async def receive(self) -> dict:
        """Receive a message from the agent"""
        data = await self.websocket.receive_json()
        self.last_message = datetime.utcnow()
        return data


class AgentRegistry:
    """
    Central registry for all agent machines.
    Manages agent state, connections, and discovery.
    """

    def __init__(self):
        self._agents: dict[str, Agent] = {}
        self._connections: dict[str, AgentConnection] = {}
        self._offline_threshold = timedelta(seconds=60)
        self._lock = asyncio.Lock()

    async def register(self, registration: AgentRegistration, websocket: WebSocket) -> Agent:
        """Register a new agent or update existing one"""
        async with self._lock:
            agent_id = registration.id

            if agent_id in self._agents:
                # Update existing agent
                agent = self._agents[agent_id]
                agent.hostname = registration.hostname
                agent.display_name = registration.display_name or agent.display_name
                agent.roles = registration.roles or agent.roles
                agent.tags = registration.tags or agent.tags
                agent.capabilities = registration.capabilities
                agent.status = AgentStatus.ONLINE
                agent.last_seen = datetime.utcnow()
                logger.info("agent_reconnected", agent_id=agent_id)
            else:
                # Create new agent
                agent = Agent(
                    id=agent_id,
                    hostname=registration.hostname,
                    display_name=registration.display_name or agent_id,
                    roles=registration.roles,
                    tags=registration.tags,
                    capabilities=registration.capabilities,
                    status=AgentStatus.ONLINE,
                    last_seen=datetime.utcnow(),
                    registered_at=datetime.utcnow(),
                )
                self._agents[agent_id] = agent
                logger.info("agent_registered", agent_id=agent_id, hostname=agent.hostname)

            # Store connection
            self._connections[agent_id] = AgentConnection(agent_id, websocket)

            return agent

    async def unregister(self, agent_id: str):
        """Mark agent as disconnected"""
        async with self._lock:
            if agent_id in self._connections:
                del self._connections[agent_id]

            if agent_id in self._agents:
                self._agents[agent_id].status = AgentStatus.OFFLINE
                logger.info("agent_disconnected", agent_id=agent_id)

    async def heartbeat(self, heartbeat: AgentHeartbeat):
        """Process agent heartbeat"""
        async with self._lock:
            agent_id = heartbeat.agent_id
            if agent_id not in self._agents:
                logger.warning("heartbeat_unknown_agent", agent_id=agent_id)
                return

            agent = self._agents[agent_id]
            agent.telemetry = heartbeat.telemetry
            agent.current_task_id = heartbeat.current_task_id
            agent.workspaces = heartbeat.workspaces
            agent.last_seen = datetime.utcnow()
            agent.status = AgentStatus.BUSY if heartbeat.current_task_id else AgentStatus.ONLINE

    def get(self, agent_id: str) -> Optional[Agent]:
        """Get agent by ID"""
        return self._agents.get(agent_id)

    def get_all(self) -> list[Agent]:
        """Get all registered agents"""
        return list(self._agents.values())

    def get_online(self) -> list[Agent]:
        """Get all online agents"""
        return [a for a in self._agents.values() if a.status == AgentStatus.ONLINE]

    def get_available(self) -> list[Agent]:
        """Get agents that are online and not busy"""
        return [a for a in self._agents.values() if a.is_available]

    def get_by_role(self, role: str) -> list[Agent]:
        """Get agents with a specific role"""
        return [a for a in self._agents.values() if role in a.roles]

    def get_connection(self, agent_id: str) -> Optional[AgentConnection]:
        """Get WebSocket connection for an agent"""
        return self._connections.get(agent_id)

    async def send_to_agent(self, agent_id: str, message: dict) -> bool:
        """Send a message to a specific agent"""
        conn = self._connections.get(agent_id)
        if conn:
            try:
                await conn.send(message)
                return True
            except Exception as e:
                logger.error("send_to_agent_failed", agent_id=agent_id, error=str(e))
                await self.unregister(agent_id)
        return False

    async def broadcast(self, message: dict, filter_roles: Optional[list[str]] = None):
        """Broadcast message to all connected agents"""
        for agent_id, conn in list(self._connections.items()):
            agent = self._agents.get(agent_id)
            if agent and (not filter_roles or any(r in agent.roles for r in filter_roles)):
                try:
                    await conn.send(message)
                except Exception as e:
                    logger.error("broadcast_failed", agent_id=agent_id, error=str(e))

    async def check_health(self):
        """Check for stale agents and mark them offline"""
        now = datetime.utcnow()
        async with self._lock:
            for agent_id, agent in self._agents.items():
                if agent.status == AgentStatus.ONLINE:
                    if agent.last_seen and (now - agent.last_seen) > self._offline_threshold:
                        agent.status = AgentStatus.OFFLINE
                        logger.warning("agent_timed_out", agent_id=agent_id)
                        if agent_id in self._connections:
                            del self._connections[agent_id]


# Global registry instance
registry = AgentRegistry()
