"""
Agent API Routes - Manage and query agents
"""
from typing import Optional
from fastapi import APIRouter, HTTPException

from models import Agent, AgentStatus
from core.registry import registry

router = APIRouter(prefix="/api/agents", tags=["agents"])


@router.get("", response_model=list[Agent])
async def list_agents(
    status: Optional[AgentStatus] = None,
    role: Optional[str] = None,
):
    """List all registered agents with optional filters"""
    agents = registry.get_all()

    if status:
        agents = [a for a in agents if a.status == status]
    if role:
        agents = [a for a in agents if role in a.roles]

    return agents


@router.get("/online", response_model=list[Agent])
async def list_online_agents():
    """List all online agents"""
    return registry.get_online()


@router.get("/available", response_model=list[Agent])
async def list_available_agents():
    """List agents that are online and not busy"""
    return registry.get_available()


@router.get("/{agent_id}", response_model=Agent)
async def get_agent(agent_id: str):
    """Get a specific agent by ID"""
    agent = registry.get(agent_id)
    if not agent:
        raise HTTPException(status_code=404, detail=f"Agent {agent_id} not found")
    return agent


@router.get("/{agent_id}/workspaces")
async def get_agent_workspaces(agent_id: str):
    """Get workspaces on a specific agent"""
    agent = registry.get(agent_id)
    if not agent:
        raise HTTPException(status_code=404, detail=f"Agent {agent_id} not found")
    return agent.workspaces or []


@router.post("/{agent_id}/ping")
async def ping_agent(agent_id: str):
    """Send a ping to an agent"""
    success = await registry.send_to_agent(agent_id, {"type": "ping"})
    if not success:
        raise HTTPException(status_code=503, detail=f"Agent {agent_id} not reachable")
    return {"status": "sent"}


@router.delete("/{agent_id}")
async def remove_agent(agent_id: str):
    """Remove an agent from the registry"""
    agent = registry.get(agent_id)
    if not agent:
        raise HTTPException(status_code=404, detail=f"Agent {agent_id} not found")

    await registry.unregister(agent_id)
    return {"status": "removed", "agent_id": agent_id}
