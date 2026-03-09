# RoadWorkflow

Enterprise Workflow Orchestration Engine for BlackRoad OS.

## Overview

RoadWorkflow is a powerful workflow orchestration engine that enables building, scheduling, and monitoring complex data pipelines and task workflows.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          RoadWorkflow Engine                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │    Workflow     │  │    Scheduler    │  │         Executor            │  │
│  │   Definition    │  │                 │  │                             │  │
│  │                 │  │ ┌─────────────┐ │  │  ┌─────────────────────────┐│  │
│  │ - DAG Builder   │  │ │ Cron        │ │  │  │  Local / ThreadPool    ││  │
│  │ - Task Config   │  │ │ Interval    │ │  │  │  ProcessPool / Celery  ││  │
│  │ - Dependencies  │  │ │ Event       │ │  │  │  Kubernetes / Dask     ││  │
│  │ - Conditions    │  │ │ Webhook     │ │  │  └─────────────────────────┘│  │
│  └─────────────────┘  │ └─────────────┘ │  └─────────────────────────────┘  │
│                       └─────────────────┘                                    │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                              Task Types                                  ││
│  │  Python | HTTP | Shell | SQL | Docker | Kubernetes | Subworkflow        ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │     State       │  │    History      │  │      Notifications          │  │
│  │   Management    │  │    & Metrics    │  │                             │  │
│  │                 │  │                 │  │  - Email                    │  │
│  │ - Checkpoints   │  │ - Logging       │  │  - Slack                    │  │
│  │ - Recovery      │  │ - Prometheus    │  │  - Webhook                  │  │
│  │ - State Store   │  │ - SLA Monitor   │  │  - Custom                   │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Installation

```bash
pip install roadworkflow

# With optional dependencies
pip install roadworkflow[redis]      # Redis state store
pip install roadworkflow[celery]     # Celery executor
pip install roadworkflow[kubernetes] # Kubernetes executor
pip install roadworkflow[all]        # All dependencies
```

## Quick Start

### Define a Workflow

```python
from roadworkflow_core import Workflow, WorkflowBuilder
from roadworkflow_core.tasks import PythonTask, HTTPTask, ShellTask
from roadworkflow_core.tasks.decorators import task

# Using decorators
@task(retries=3, timeout=300)
def extract_data(context):
    return {"records": 1000}

@task
def transform_data(context):
    data = context.get_upstream_result("extract_data")
    return {"processed": data["records"]}

@task
def load_data(context):
    data = context.get_upstream_result("transform_data")
    print(f"Loaded {data['processed']} records")
    return True

# Build workflow
workflow = (
    WorkflowBuilder("etl_pipeline")
    .add_task(extract_data)
    .add_task(transform_data, depends_on=["extract_data"])
    .add_task(load_data, depends_on=["transform_data"])
    .with_timeout(3600)
    .build()
)

# Run workflow
result = workflow.run()
print(f"Workflow completed: {result.state}")
```

### Using Task Operators

```python
from roadworkflow_core.tasks import HTTPTask, ShellTask, SQLTask

# HTTP Task
fetch_api = HTTPTask(
    task_id="fetch_api",
    endpoint="https://api.example.com/data",
    method="GET",
    headers={"Authorization": "Bearer {token}"},
)

# Shell Task
process = ShellTask(
    task_id="process_data",
    command="python process.py --input {input_file}",
)

# SQL Task
query = SQLTask(
    task_id="run_query",
    sql="SELECT * FROM users WHERE created_at > %(date)s",
    connection_id="postgres_main",
    parameters={"date": "2024-01-01"},
)
```

### Scheduling Workflows

```python
from roadworkflow_core.scheduler import Scheduler, ScheduleType
from roadworkflow_core.triggers import CronTrigger

scheduler = Scheduler()

# Register workflow with cron schedule
scheduler.register_workflow(
    workflow_id="etl_pipeline",
    schedule_type=ScheduleType.CRON,
    cron_expression="0 2 * * *",  # Daily at 2 AM
    catchup=True,
)

# Or use triggers
trigger = CronTrigger("*/15 * * * *")  # Every 15 minutes
trigger.on_trigger(lambda e: workflow.run())
trigger.start()

# Start scheduler
scheduler.start()
```

### State Management & Checkpointing

```python
from roadworkflow_core.state import MemoryStateStore, CheckpointManager

# Configure state store
state_store = MemoryStateStore()

# Setup checkpointing
checkpoint_mgr = CheckpointManager(
    storage_path=".checkpoints",
    max_checkpoints=5,
    compression=True,
)

# Create checkpoint during workflow
checkpoint = checkpoint_mgr.create_checkpoint(
    workflow_id="etl_pipeline",
    run_id="run_123",
    state={"current_step": "transform"},
    task_states={"extract": "success", "transform": "running"},
)

# Restore from checkpoint
restored = checkpoint_mgr.get_latest_checkpoint("etl_pipeline")
```

### Notifications

```python
from roadworkflow_core.actions import SlackNotification, EmailNotification

# Slack notifications
slack = SlackNotification(
    webhook_url="https://hooks.slack.com/...",
    channel="#alerts",
)

# Configure notification events
slack.config.on_failure = True
slack.config.on_success = False

# Attach to workflow
workflow.on_failure(slack.on_workflow_failure)
```

## Features

- **DAG-based Workflows**: Define complex task dependencies with topological execution
- **Multiple Task Types**: Python, HTTP, Shell, SQL, Docker, Kubernetes operators
- **Flexible Scheduling**: Cron, interval, event-based, and webhook triggers
- **Multiple Executors**: Local, ThreadPool, ProcessPool, Celery, Kubernetes
- **State Management**: Memory, file, and Redis state stores
- **Checkpointing**: Automatic and manual workflow state checkpoints
- **Retry & Timeout**: Configurable retry strategies with backoff
- **Metrics & Monitoring**: Prometheus-compatible metrics export
- **Notifications**: Email, Slack, and webhook notifications
- **Branching & Conditions**: Dynamic workflow paths based on results

## License

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
