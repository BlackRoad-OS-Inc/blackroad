"""RoadWorkflow - Enterprise Workflow Engine.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

RoadWorkflow provides a powerful workflow orchestration engine with:
- DAG-based workflow definitions
- Task scheduling and execution
- State management and persistence
- Event-driven triggers
- Retry and error handling
- Workflow history and auditing

Architecture Overview:
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RoadWorkflow Engine                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                      Workflow Definition                               │  │
│  │                                                                        │  │
│  │    Start ──▶ Task A ──┬──▶ Task B ──▶ Task D ──▶ End                  │  │
│  │                       │                                                │  │
│  │                       └──▶ Task C ──────────────┘                      │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │    Workflow     │  │     Tasks       │  │       Scheduler             │ │
│  │                 │  │                 │  │                             │ │
│  │ - Definition    │  │ - Python func   │  │ - Cron triggers            │ │
│  │ - DAG           │  │ - HTTP call     │  │ - Event triggers           │ │
│  │ - Versioning    │  │ - Shell cmd     │  │ - Manual triggers          │ │
│  │ - Parameters    │  │ - Subworkflow   │  │ - Dependency triggers      │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐ │
│  │     State       │  │    Triggers     │  │        Actions              │ │
│  │                 │  │                 │  │                             │ │
│  │ - Persistence   │  │ - Cron          │  │ - Retry                     │ │
│  │ - Checkpoints   │  │ - Webhook       │  │ - Timeout                   │ │
│  │ - Recovery      │  │ - File watch    │  │ - Notification              │ │
│  │ - Variables     │  │ - Queue         │  │ - Branching                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘ │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                          History & Audit                              │  │
│  │  Run logs, task metrics, execution history, compliance auditing      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

Usage:
    from roadworkflow_core import Workflow, Task, Scheduler
    
    # Define workflow
    @workflow("data_pipeline")
    def data_pipeline():
        extract = Task("extract", extract_data)
        transform = Task("transform", transform_data)
        load = Task("load", load_data)
        
        extract >> transform >> load
    
    # Run workflow
    scheduler = Scheduler()
    scheduler.add(data_pipeline, trigger=CronTrigger("0 * * * *"))
    scheduler.start()
"""

__version__ = "0.1.0"
__author__ = "BlackRoad OS, Inc."

# Core workflow
from roadworkflow_core.workflow.definition import (
    Workflow,
    WorkflowConfig,
    WorkflowRun,
    WorkflowStatus,
)
from roadworkflow_core.workflow.dag import DAG, Edge, Node

# Tasks
from roadworkflow_core.tasks.base import Task, TaskConfig, TaskStatus
from roadworkflow_core.tasks.operators import (
    PythonTask,
    HTTPTask,
    ShellTask,
    SubworkflowTask,
)
from roadworkflow_core.tasks.decorators import task, workflow

# Scheduler
from roadworkflow_core.scheduler.scheduler import Scheduler, SchedulerConfig
from roadworkflow_core.scheduler.executor import Executor, ThreadPoolExecutor

# State
from roadworkflow_core.state.store import StateStore, InMemoryStore
from roadworkflow_core.state.checkpoint import Checkpoint, CheckpointManager

# Triggers
from roadworkflow_core.triggers.base import Trigger
from roadworkflow_core.triggers.cron import CronTrigger
from roadworkflow_core.triggers.event import EventTrigger
from roadworkflow_core.triggers.webhook import WebhookTrigger

# Actions
from roadworkflow_core.actions.retry import RetryPolicy, RetryAction
from roadworkflow_core.actions.timeout import TimeoutAction
from roadworkflow_core.actions.notification import NotificationAction

# History
from roadworkflow_core.history.logger import WorkflowLogger, RunLogger
from roadworkflow_core.history.metrics import WorkflowMetrics

__all__ = [
    "__version__",
    # Workflow
    "Workflow",
    "WorkflowConfig",
    "WorkflowRun",
    "WorkflowStatus",
    "DAG",
    "Edge",
    "Node",
    # Tasks
    "Task",
    "TaskConfig",
    "TaskStatus",
    "PythonTask",
    "HTTPTask",
    "ShellTask",
    "SubworkflowTask",
    "task",
    "workflow",
    # Scheduler
    "Scheduler",
    "SchedulerConfig",
    "Executor",
    "ThreadPoolExecutor",
    # State
    "StateStore",
    "InMemoryStore",
    "Checkpoint",
    "CheckpointManager",
    # Triggers
    "Trigger",
    "CronTrigger",
    "EventTrigger",
    "WebhookTrigger",
    # Actions
    "RetryPolicy",
    "RetryAction",
    "TimeoutAction",
    "NotificationAction",
    # History
    "WorkflowLogger",
    "RunLogger",
    "WorkflowMetrics",
]
