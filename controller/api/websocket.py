"""
WebSocket Routes - Real-time agent connections and client updates
"""
import asyncio
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
import structlog

from models import AgentRegistration, AgentHeartbeat, CommandResult, Task
from core.registry import registry
from core.scheduler import scheduler
from services.audit import audit

router = APIRouter(tags=["websocket"])
logger = structlog.get_logger()

# Client connections for broadcasting updates
client_connections: list[WebSocket] = []


@router.websocket("/ws/agent")
async def agent_websocket(websocket: WebSocket):
    """
    WebSocket endpoint for agent connections.
    Agents connect here to register, receive tasks, and send results.
    """
    await websocket.accept()
    agent_id: Optional[str] = None

    try:
        # First message should be registration
        data = await websocket.receive_json()

        if data.get("type") != "register":
            await websocket.send_json({"type": "error", "message": "Expected registration message"})
            await websocket.close()
            return

        # Parse registration
        registration = AgentRegistration(**data.get("payload", {}))
        agent_id = registration.id

        # Register the agent
        agent = await registry.register(registration, websocket)

        # Log connection
        client_host = websocket.client.host if websocket.client else None
        audit.log_agent_connected(agent_id, registration.hostname, client_host)

        # Send confirmation
        await websocket.send_json({
            "type": "registered",
            "agent_id": agent_id,
            "message": f"Welcome, {agent.display_name}!",
        })

        # Broadcast to clients
        await broadcast_to_clients({
            "type": "agent_connected",
            "agent": agent.model_dump(),
        })

        # Main message loop
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "heartbeat":
                # Process heartbeat
                heartbeat = AgentHeartbeat(**data.get("payload", {}))
                await registry.heartbeat(heartbeat)

            elif msg_type == "task_output":
                # Streaming task output
                await handle_task_output(data.get("payload", {}))

            elif msg_type == "task_complete":
                # Task completed
                await handle_task_complete(data.get("payload", {}))

            elif msg_type == "command_result":
                # Individual command result
                await handle_command_result(agent_id, data.get("payload", {}))

            elif msg_type == "pong":
                logger.debug("pong_received", agent_id=agent_id)

            else:
                logger.warning("unknown_message_type", agent_id=agent_id, type=msg_type)

    except WebSocketDisconnect:
        logger.info("agent_disconnected", agent_id=agent_id, reason="client disconnect")
    except Exception as e:
        logger.error("agent_connection_error", agent_id=agent_id, error=str(e))
    finally:
        if agent_id:
            await registry.unregister(agent_id)
            audit.log_agent_disconnected(agent_id)

            # Broadcast to clients
            await broadcast_to_clients({
                "type": "agent_disconnected",
                "agent_id": agent_id,
            })


async def handle_task_output(payload: dict):
    """Handle streaming output from a task"""
    task_id = payload.get("task_id")
    stream = payload.get("stream", "stdout")  # stdout or stderr
    content = payload.get("content", "")
    command_index = payload.get("command_index")

    # Broadcast to clients watching this task
    await broadcast_to_clients({
        "type": "task_output",
        "task_id": task_id,
        "stream": stream,
        "content": content,
        "command_index": command_index,
    })


async def handle_task_complete(payload: dict):
    """Handle task completion from an agent"""
    task_id = payload.get("task_id")
    success = payload.get("success", True)
    exit_code = payload.get("exit_code", 0)
    output = payload.get("output")
    error = payload.get("error")

    logger.info("task_complete_received", task_id=task_id, success=success, exit_code=exit_code)

    await scheduler.complete_task(
        task_id=task_id,
        success=success,
        exit_code=exit_code,
        output=output,
        error=error,
    )

    # Broadcast to clients
    task = scheduler.get_task(task_id)
    if task:
        await broadcast_to_clients({
            "type": "task_updated",
            "task": task.model_dump(),
        })


async def handle_command_result(agent_id: str, payload: dict):
    """Handle individual command result"""
    task_id = payload.get("task_id")
    command_idx = payload.get("command_index", 0)
    command = payload.get("command", "")
    exit_code = payload.get("exit_code", 0)
    duration_ms = payload.get("duration_ms", 0)

    # Log to audit
    audit.log_command_completed(
        task_id=task_id,
        agent_id=agent_id,
        command=command,
        command_idx=command_idx,
        exit_code=exit_code,
        duration_ms=duration_ms,
    )

    # Broadcast to clients
    await broadcast_to_clients({
        "type": "command_result",
        "task_id": task_id,
        "command_index": command_idx,
        "exit_code": exit_code,
        "duration_ms": duration_ms,
    })


@router.websocket("/ws/client")
async def client_websocket(websocket: WebSocket):
    """
    WebSocket endpoint for UI clients.
    Receives real-time updates about agents and tasks.
    """
    await websocket.accept()
    client_connections.append(websocket)
    logger.info("client_connected", total_clients=len(client_connections))

    try:
        # Send initial state
        await websocket.send_json({
            "type": "initial_state",
            "agents": [a.model_dump() for a in registry.get_all()],
            "tasks": [t.model_dump() for t in scheduler.get_all_tasks()],
        })

        # Keep connection alive and handle client messages
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "ping":
                await websocket.send_json({"type": "pong"})

            elif msg_type == "subscribe_task":
                # Client wants updates for a specific task
                task_id = data.get("task_id")
                task = scheduler.get_task(task_id)
                if task:
                    await websocket.send_json({
                        "type": "task_state",
                        "task": task.model_dump(),
                    })

    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.error("client_connection_error", error=str(e))
    finally:
        if websocket in client_connections:
            client_connections.remove(websocket)
        logger.info("client_disconnected", total_clients=len(client_connections))


async def broadcast_to_clients(message: dict):
    """Broadcast a message to all connected UI clients"""
    if not client_connections:
        return

    # Send to all clients, removing dead connections
    dead_connections = []
    for client in client_connections:
        try:
            await client.send_json(message)
        except Exception:
            dead_connections.append(client)

    for dead in dead_connections:
        if dead in client_connections:
            client_connections.remove(dead)


# Background task dispatcher
async def dispatch_loop():
    """Background loop to dispatch queued tasks to available agents"""
    while True:
        try:
            task = await scheduler.dispatch_next()
            if task:
                # Send task to agent
                agent_id = task.assigned_agent_id
                if agent_id:
                    # Send task to agent with payload wrapper for consistency
                    logger.info("dispatching_task_to_agent", task_id=task.id, agent_id=agent_id)
                    success = await registry.send_to_agent(agent_id, {
                        "type": "execute_task",
                        "payload": {
                            "task_id": task.id,
                            "plan": task.plan.model_dump() if task.plan else None,
                        }
                    })

                    if not success:
                        # Agent unreachable, fail the task
                        await scheduler.complete_task(
                            task.id,
                            success=False,
                            error=f"Agent {agent_id} unreachable",
                        )
                    else:
                        # Log audit
                        if task.plan:
                            for i, cmd in enumerate(task.plan.commands):
                                audit.log_command_started(
                                    task.id,
                                    agent_id,
                                    cmd.run,
                                    i,
                                )

                # Broadcast task update
                await broadcast_to_clients({
                    "type": "task_updated",
                    "task": task.model_dump(),
                })
        except Exception as e:
            logger.error("dispatch_error", error=str(e))

        await asyncio.sleep(1)  # Check queue every second
