"""
Task API Routes - Create, manage, and monitor tasks
"""
from typing import Optional
from fastapi import APIRouter, HTTPException, BackgroundTasks
import structlog

from models import Task, TaskStatus, TaskRequest, TaskApproval, TaskPlan
from core.scheduler import scheduler
from core.registry import registry
from services.planner import create_planner
from services.planner_config import PlannerConfig
from services.audit import audit
import os

router = APIRouter(prefix="/api/tasks", tags=["tasks"])
logger = structlog.get_logger()


@router.get("", response_model=list[Task])
async def list_tasks(
    status: Optional[TaskStatus] = None,
    agent_id: Optional[str] = None,
    limit: int = 50,
):
    """List all tasks with optional filters"""
    tasks = scheduler.get_all_tasks()

    if status:
        tasks = [t for t in tasks if t.status == status]
    if agent_id:
        tasks = [t for t in tasks if t.assigned_agent_id == agent_id]

    # Sort by creation time, newest first
    tasks.sort(key=lambda t: t.created_at, reverse=True)
    return tasks[:limit]


@router.get("/queue", response_model=list[Task])
async def get_queue():
    """Get tasks currently in the queue"""
    return scheduler.get_queued_tasks()


@router.get("/running", response_model=list[Task])
async def get_running():
    """Get currently running tasks"""
    return scheduler.get_running_tasks()


@router.get("/awaiting-approval", response_model=list[Task])
async def get_awaiting_approval():
    """Get tasks awaiting user approval"""
    tasks = scheduler.get_all_tasks()
    return [t for t in tasks if t.status == TaskStatus.AWAITING_APPROVAL]


@router.get("/{task_id}", response_model=Task)
async def get_task(task_id: str):
    """Get a specific task by ID"""
    task = scheduler.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
    return task


@router.post("", response_model=Task)
async def create_task(request: TaskRequest, background_tasks: BackgroundTasks):
    """
    Create a new task from a natural language request.
    The task will be planned by the LLM and then queued for approval.
    """
    # Create the task
    task = await scheduler.create_task(request)

    # Log audit event
    audit.log_task_created(task.id, request.request)

    # Start LLM planning in background
    background_tasks.add_task(plan_task, task.id, request)

    return task


async def plan_task(task_id: str, request: TaskRequest):
    """Background task to plan a task using LLM"""
    try:
        # Get available agents
        agents = registry.get_all()

        if not agents:
            # No agents, fail the task
            await scheduler.complete_task(
                task_id,
                success=False,
                error="No agents registered",
            )
            return

        # Create planner with auto-detected provider
        planner = create_planner()
        logger.info("planning_with_provider", provider=planner.provider, task_id=task_id)

        # Generate plan
        plan = await planner.create_plan(
            request=request.request,
            agents=agents,
            target_agent_id=request.target_agent_id,
            target_role=request.target_role,
        )

        # Attach plan to task
        await scheduler.set_plan(task_id, plan)

        # Log audit event
        audit.log_task_planned(task_id, {
            "target_agent": plan.target_agent,
            "commands": len(plan.commands),
            "risk_level": plan.risk_level.value,
        })

    except Exception as e:
        logger.error("plan_task_failed", task_id=task_id, error=str(e))
        await scheduler.complete_task(
            task_id,
            success=False,
            error=f"Planning failed: {str(e)}",
        )


@router.post("/{task_id}/approve", response_model=Task)
async def approve_task(task_id: str, approval: TaskApproval):
    """Approve or reject a task plan"""
    try:
        task = await scheduler.approve_task(
            task_id,
            approved=approval.approved,
            reason=approval.reason,
        )

        # Log audit
        if approval.approved:
            audit.log_task_approved(task_id)
        else:
            audit.log_task_rejected(task_id, approval.reason or "No reason provided")

        return task
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{task_id}/cancel", response_model=Task)
async def cancel_task(task_id: str, reason: Optional[str] = None):
    """Cancel a task"""
    try:
        return await scheduler.cancel_task(task_id, reason)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{task_id}/retry", response_model=Task)
async def retry_task(task_id: str, background_tasks: BackgroundTasks):
    """Retry a failed task"""
    task = scheduler.get_task(task_id)
    if not task:
        raise HTTPException(status_code=404, detail=f"Task {task_id} not found")

    if task.status not in (TaskStatus.FAILED, TaskStatus.CANCELLED):
        raise HTTPException(status_code=400, detail="Can only retry failed or cancelled tasks")

    # Create a new task with the same request
    new_request = TaskRequest(
        request=task.request,
        target_agent_id=task.target_agent_id,
        target_role=task.target_role,
        skip_approval=not task.requires_approval,
        priority=task.priority,
    )

    new_task = await scheduler.create_task(new_request)
    background_tasks.add_task(plan_task, new_task.id, new_request)

    return new_task
