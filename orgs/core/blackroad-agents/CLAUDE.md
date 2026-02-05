# BlackRoad Agents

> Agent API - telemetry, job scheduling, and CeCe dynamic planner

## Quick Reference

| Property | Value |
|----------|-------|
| **Language** | Python 3.10+ |
| **Framework** | FastAPI |
| **Build** | Hatch |
| **License** | MIT |

## Tech Stack

```
Python 3.10+
├── FastAPI (API Server)
├── Pydantic 2 (Data Validation)
├── Redis (Job Queue/Cache)
├── httpx (HTTP Client)
├── psutil (System Monitoring)
└── Uvicorn (ASGI Server)
```

## Installation

```bash
# Install with pip
pip install blackroad-agents

# Development install
pip install -e ".[dev]"
```

## Commands

```bash
blackroad-agent    # Start agent API server
cece               # Run CeCe dynamic planner

# Development
pytest             # Run tests
black .            # Format code
ruff check .       # Lint code
mypy .             # Type check
```

## Core Components

### Agent API
- **Telemetry**: Real-time agent metrics
- **Job Scheduler**: Task queue management
- **Health Monitoring**: psutil-based system health

### CeCe Dynamic Planner
- **Conscious Emergent Collaborative Entity**
- Dynamic task planning and routing
- Agent coordination and distribution

## Project Structure

```
agent/
├── api.py          # FastAPI server
├── telemetry/      # Telemetry collection
├── scheduler/      # Job scheduling
└── health/         # Health monitoring

cece/
├── dynamic_planner.py   # Main planner
├── task_router.py       # Task routing
└── agent_coordinator.py # Coordination
```

## API Endpoints

```
GET  /health           # Health check
GET  /agents           # List agents
POST /agents/register  # Register agent
POST /jobs             # Submit job
GET  /telemetry        # Get metrics
POST /cece/plan        # Dynamic planning
```

## Environment Variables

```env
AGENT_API_PORT=8001       # API port
REDIS_URL=redis://...     # Redis connection
AGENT_HEARTBEAT=30        # Heartbeat interval (seconds)
CECE_MAX_AGENTS=30000     # Max agent capacity
```

## Related Repos

- `lucidia-core` - Reasoning engines
- `blackroad-os-core` - Core platform
- `blackroad-cli` - CLI interface
