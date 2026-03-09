# BlackRoad Python SDK

Official Python client for the BlackRoad API.

## Installation

```bash
pip install blackroad
```

## Quick Start

```python
from blackroad import BlackRoadClient

# Initialize client
client = BlackRoadClient(api_key="your-api-key")

# Or use environment variable
# export BLACKROAD_API_KEY=your-api-key
client = BlackRoadClient()

# List agents
agents = client.agents.list()
print(f"Found {len(agents)} agents")

# Get commanders (Level 2)
commanders = client.agents.commanders()

# Dispatch a task
task = client.tasks.dispatch(
    title="Deploy authentication service",
    description="Deploy Keycloak to Security division",
    priority="urgent",
    division="Security"
)
print(f"Task created: {task['task_id']}")

# Log to memory
client.memory.log(
    action="deployed",
    entity="auth-service",
    details="Deployed Keycloak successfully",
    tags=["security", "deployment"]
)

# Query memory
entries = client.memory.query("deployment")
```

## Features

### Agent Management

```python
# Register a new agent
agent = client.agents.register(
    name="my-worker",
    agent_type="ai",
    division="OS",
    level=4
)

# Send heartbeat
client.agents.heartbeat(agent["agent_id"], load=0.5)

# Update status
client.agents.update_status(agent["agent_id"], "active")

# Get agents by division
os_agents = client.agents.by_division("OS")
```

### Task Management

```python
# Dispatch tasks
task = client.tasks.dispatch(
    title="Build feature",
    priority="high",
    division="AI"
)

# Complete task
client.tasks.complete(task["task_id"], result="Feature built successfully")

# Get pending tasks
pending = client.tasks.pending()

# Get urgent tasks
urgent = client.tasks.urgent()
```

### Memory System

```python
# Log entries
client.memory.log(
    action="milestone",
    entity="30k-agents",
    details="Infrastructure deployed",
    tags=["infrastructure", "milestone"]
)

# Query entries
entries = client.memory.query(
    search="deployment",
    action="deployed",
    tags=["production"]
)

# Share learnings
client.memory.til("discovery", "Found new optimization technique")

# Broadcast to all agents
client.memory.broadcast("alert", "System maintenance at midnight")
```

## Error Handling

```python
from blackroad import BlackRoadClient
from blackroad.exceptions import (
    AuthenticationError,
    RateLimitError,
    NotFoundError,
    ValidationError
)

try:
    client = BlackRoadClient()
    agent = client.agents.get("nonexistent-id")
except AuthenticationError:
    print("Invalid API key")
except NotFoundError:
    print("Agent not found")
except RateLimitError as e:
    print(f"Rate limited. Retry after {e.retry_after}s")
except ValidationError as e:
    print(f"Validation failed: {e.errors}")
```

## Configuration

```python
client = BlackRoadClient(
    api_key="your-api-key",
    base_url="https://api.blackroad.io/v1",  # Optional
    timeout=30,  # Request timeout in seconds
    max_retries=3  # Retry failed requests
)
```

## License

Proprietary - BlackRoad OS, Inc.
