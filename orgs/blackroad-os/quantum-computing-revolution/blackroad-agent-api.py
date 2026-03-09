#!/usr/bin/env python3
"""
BlackRoad Agent API - REST API for the multi-agent system
Production-ready API for accessing distributed quantum intelligence
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime
import uvicorn
import asyncio
import json

# Import our agent system
import sys
sys.path.append('/Users/alexa')
from blackroad_agent_system import BlackRoadAgentSystem, AgentRole, Task

# Initialize FastAPI
app = FastAPI(
    title="BlackRoad Agent API",
    description="Distributed Quantum Intelligence API - Unmatched multi-model AI system",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize agent system
agent_system = BlackRoadAgentSystem()

# ===== REQUEST MODELS =====

class QueryRequest(BaseModel):
    prompt: str
    agent_name: Optional[str] = None
    context: Optional[str] = None

class CollaborativeRequest(BaseModel):
    problem: str
    agents: Optional[List[str]] = None

class TaskRequest(BaseModel):
    description: str
    required_roles: List[str]
    priority: str = "medium"
    context: Dict[str, Any] = {}

class SwarmRequest(BaseModel):
    query: str
    num_agents: int = 5

# ===== API ENDPOINTS =====

@app.get("/")
async def root():
    """API status and info"""
    return {
        "name": "BlackRoad Agent API",
        "version": "1.0.0",
        "status": "operational",
        "agents": len(agent_system.agents),
        "active_agents": sum(1 for a in agent_system.agents.values() if a.active),
        "timestamp": datetime.now().isoformat()
    }

@app.get("/agents")
async def list_agents():
    """List all available agents"""
    agents = []
    for agent in agent_system.agents.values():
        agents.append({
            "name": agent.name,
            "role": agent.role.value,
            "model": agent.model,
            "node": agent.node,
            "qcs_position": agent.qcs_position,
            "specialization": agent.specialization,
            "capabilities": agent.capabilities,
            "active": agent.active
        })
    return {
        "agents": agents,
        "total": len(agents),
        "active": sum(1 for a in agents if a["active"])
    }

@app.get("/agents/{agent_name}")
async def get_agent(agent_name: str):
    """Get details for a specific agent"""
    agent = agent_system.agents.get(agent_name)
    if not agent:
        raise HTTPException(status_code=404, detail=f"Agent {agent_name} not found")

    return {
        "name": agent.name,
        "role": agent.role.value,
        "model": agent.model,
        "node": agent.node,
        "qcs_position": agent.qcs_position,
        "specialization": agent.specialization,
        "capabilities": agent.capabilities,
        "temperature": agent.temperature,
        "max_tokens": agent.max_tokens,
        "active": agent.active
    }

@app.post("/query")
async def query_agent(request: QueryRequest):
    """Query a specific agent or auto-select best agent"""
    if request.agent_name:
        agent = agent_system.agents.get(request.agent_name)
        if not agent:
            raise HTTPException(status_code=404, detail=f"Agent {request.agent_name} not found")
    else:
        # Auto-select coordinator for general queries
        agent = agent_system.agents.get("Gemma-Coordinator")

    result = await agent_system.query_agent(agent, request.prompt, request.context)

    return {
        "agent": result["agent"],
        "role": result["role"],
        "qcs_position": result["qcs_position"],
        "response": result["response"],
        "duration": result["duration"],
        "timestamp": result["timestamp"],
        "success": result["success"]
    }

@app.post("/collaborate")
async def collaborative_reasoning(request: CollaborativeRequest):
    """Multi-agent collaborative reasoning"""
    result = await agent_system.collaborative_reasoning(
        request.problem,
        request.agents
    )

    return {
        "problem": result["problem"],
        "individual_results": [
            {
                "agent": r["agent"],
                "qcs_position": r["qcs_position"],
                "response": r["response"],
                "duration": r["duration"]
            }
            for r in result["individual_results"]
        ],
        "synthesis": {
            "agent": result["synthesis"]["agent"],
            "response": result["synthesis"]["response"],
            "duration": result["synthesis"]["duration"]
        },
        "total_agents": result["total_agents"],
        "timestamp": result["timestamp"]
    }

@app.post("/task")
async def distributed_task(request: TaskRequest):
    """Distribute a task across multiple specialized agents"""
    # Convert string roles to AgentRole enums
    try:
        required_roles = [AgentRole(role) for role in request.required_roles]
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid role: {str(e)}")

    task = Task(
        id=f"task-{datetime.now().timestamp()}",
        description=request.description,
        required_roles=required_roles,
        priority=request.priority,
        context=request.context
    )

    result = await agent_system.distributed_task(task)

    return {
        "task_id": result["task_id"],
        "description": result["description"],
        "agents_used": result["agents_used"],
        "results": [
            {
                "agent": r["agent"],
                "role": r["role"],
                "response": r["response"],
                "duration": r["duration"]
            }
            for r in result["results"]
        ],
        "status": result["status"]
    }

@app.post("/swarm")
async def quantum_swarm(request: SwarmRequest):
    """Quantum swarm intelligence - query multiple agents simultaneously"""
    result = await agent_system.quantum_swarm_intelligence(
        request.query,
        request.num_agents
    )

    return {
        "query": result["query"],
        "responses": [
            {
                "agent": r["agent"],
                "qcs_position": r["qcs_position"],
                "response": r["response"],
                "duration": r["duration"]
            }
            for r in result["responses"]
        ],
        "consensus_score": result["consensus_score"],
        "perspectives": result["perspectives"],
        "qcs_range": result["qcs_range"]
    }

@app.get("/roles")
async def list_roles():
    """List all available agent roles"""
    return {
        "roles": [
            {
                "name": role.value,
                "description": role.name,
                "agents": [a.name for a in agent_system.get_agents_by_role(role)]
            }
            for role in AgentRole
        ]
    }

@app.get("/qcs/{position}")
async def agents_by_qcs(position: float, range: float = 0.1):
    """Get agents within a QCS range"""
    agents = agent_system.get_agents_by_qcs(position - range, position + range)

    return {
        "qcs_position": position,
        "range": range,
        "agents": [
            {
                "name": a.name,
                "role": a.role.value,
                "qcs_position": a.qcs_position,
                "specialization": a.specialization
            }
            for a in agents
        ]
    }

@app.get("/history")
async def conversation_history(limit: int = 50):
    """Get recent conversation history"""
    history = agent_system.conversation_history[-limit:]

    return {
        "history": history,
        "total_conversations": len(agent_system.conversation_history),
        "showing": len(history)
    }

@app.post("/reset")
async def reset_system():
    """Reset the agent system (clears history and memory)"""
    agent_system.conversation_history = []
    agent_system.shared_memory = {}

    return {
        "status": "reset",
        "message": "Agent system reset successfully"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    active_agents = sum(1 for a in agent_system.agents.values() if a.active)

    return {
        "status": "healthy" if active_agents > 0 else "degraded",
        "total_agents": len(agent_system.agents),
        "active_agents": active_agents,
        "timestamp": datetime.now().isoformat()
    }

# ===== RUN SERVER =====

if __name__ == "__main__":
    print("""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                     🔱 BLACKROAD AGENT API 🔱                                 ║
║                                                                               ║
║              Production-Ready Distributed Intelligence API                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Starting API server...
Agents initialized: {len(agent_system.agents)}
Active agents: {sum(1 for a in agent_system.agents.values() if a.active)}

API Endpoints:
  GET  /              - API status
  GET  /agents        - List all agents
  GET  /agents/<name> - Get agent details
  POST /query         - Query an agent
  POST /collaborate   - Collaborative reasoning
  POST /task          - Distributed task
  POST /swarm         - Quantum swarm intelligence
  GET  /roles         - List roles
  GET  /qcs/<pos>     - Agents by QCS position
  GET  /history       - Conversation history
  GET  /health        - Health check

Server starting on http://localhost:8000
Documentation: http://localhost:8000/docs

""")

    uvicorn.run(app, host="0.0.0.0", port=8000)
