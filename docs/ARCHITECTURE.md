# BlackRoad Agent OS - Architecture

## Overview

BlackRoad Agent OS is a distributed agent orchestration system that turns your Raspberry Pi fleet into a controllable "computer within a computer." One central brain orchestrates multiple Pi agents, with an AI-powered planning layer that converts natural language into safe, auditable operations.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         BROWSER UI                                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │ Agent Grid  │ │   Console   │ │ Task Queue  │ │  Audit Log  │   │
│  │  (Pi Cards) │ │ (NL Input)  │ │  (History)  │ │  (Timeline) │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
└────────────────────────────┬────────────────────────────────────────┘
                             │ WebSocket + REST
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      CONTROLLER SERVICE                              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    FastAPI Application                        │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │   │
│  │  │   Agent     │ │    Task     │ │     LLM     │             │   │
│  │  │  Registry   │ │  Scheduler  │ │   Planner   │             │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘             │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │   │
│  │  │   Safety    │ │   Audit     │ │  Workspace  │             │   │
│  │  │  Validator  │ │   Logger    │ │   Manager   │             │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘             │   │
│  └──────────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────────┘
                             │ WebSocket (outbound from agents)
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  BLACKROAD-PI   │ │   ALICE-PI      │ │   FUTURE-PI     │
│  ┌───────────┐  │ │  ┌───────────┐  │ │  ┌───────────┐  │
│  │  Agent    │  │ │  │  Agent    │  │ │  │  Agent    │  │
│  │  Daemon   │  │ │  │  Daemon   │  │ │  │  Daemon   │  │
│  └───────────┘  │ │  └───────────┘  │ │  └───────────┘  │
│  ┌───────────┐  │ │  ┌───────────┐  │ │  ┌───────────┐  │
│  │ Workspace │  │ │  │ Workspace │  │ │  │ Workspace │  │
│  │  Manager  │  │ │  │  Manager  │  │ │  │  Manager  │  │
│  └───────────┘  │ │  └───────────┘  │ │  └───────────┘  │
│  ┌───────────┐  │ │  ┌───────────┐  │ │  ┌───────────┐  │
│  │  Docker/  │  │ │  │  Docker/  │  │ │  │  Docker/  │  │
│  │   venv    │  │ │  │   venv    │  │ │  │   venv    │  │
│  └───────────┘  │ │  └───────────┘  │ │  └───────────┘  │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

## Technology Choices

### Controller Service: Python + FastAPI
**Why:**
- Excellent async support for handling multiple agent connections
- Native WebSocket support for real-time log streaming
- Pydantic for strong schema validation
- Easy LLM integration (langchain, anthropic SDK)
- You already have Python expertise in your stack

### Agent Daemon: Python + asyncio
**Why:**
- Same language as controller (code sharing)
- Lightweight enough for Raspberry Pi
- Good subprocess management
- Easy venv/container orchestration

### Browser UI: React + TypeScript + Tailwind
**Why:**
- Modern, responsive UI
- Real-time updates via WebSocket
- Component-based architecture fits the "tiles/cards" design
- Vite for fast development

### Communication: WebSocket (agent-initiated)
**Why:**
- Agents connect OUT to controller (no port forwarding needed)
- Works through NAT/firewalls
- Bi-directional real-time streaming
- Automatic reconnection handling

### Task Isolation: Docker (primary) + venv (fallback)
**Why:**
- Docker provides true isolation
- venv for lightweight Python tasks
- Workspace = container or venv with unique ID

## Component Details

### 1. Controller Service

**Responsibilities:**
- Agent registry (discovery, health, capabilities)
- Task queue and scheduling
- LLM integration for planning
- Safety validation
- Audit logging
- WebSocket hub for UI and agents

**Key Modules:**
```
controller/
├── main.py              # FastAPI app entry
├── api/
│   ├── agents.py        # Agent CRUD + status
│   ├── tasks.py         # Task submission + history
│   ├── websocket.py     # WS handlers
│   └── health.py        # Health checks
├── core/
│   ├── registry.py      # Agent inventory
│   ├── scheduler.py     # Task distribution
│   ├── planner.py       # LLM planning
│   └── safety.py        # Command validation
├── models/
│   ├── agent.py         # Agent schema
│   ├── task.py          # Task schema
│   └── plan.py          # Plan schema
└── services/
    ├── llm.py           # LLM client
    ├── audit.py         # Audit logging
    └── workspace.py     # Workspace tracking
```

### 2. Agent Daemon

**Responsibilities:**
- Connect to controller via WebSocket
- Execute approved commands
- Manage local workspaces (Docker/venv)
- Stream logs back in real-time
- Report telemetry (CPU, RAM, disk, repos)

**Key Modules:**
```
agent/
├── main.py              # Daemon entry
├── connection.py        # WebSocket client
├── executor.py          # Command execution
├── workspace.py         # Docker/venv management
├── telemetry.py         # System metrics
└── safety.py            # Local command filtering
```

### 3. Browser UI

**Key Views:**
- **Agent Grid:** Cards showing each Pi's status, role, last task
- **Console:** Natural language input + plan preview
- **Task Queue:** Running and pending tasks
- **Task History:** Completed tasks with logs
- **Audit Timeline:** Chronological event log

**Key Components:**
```
ui/src/
├── App.tsx
├── components/
│   ├── AgentCard.tsx
│   ├── AgentGrid.tsx
│   ├── Console.tsx
│   ├── TaskQueue.tsx
│   ├── TaskHistory.tsx
│   ├── LogViewer.tsx
│   └── PlanApproval.tsx
├── hooks/
│   ├── useWebSocket.ts
│   ├── useAgents.ts
│   └── useTasks.ts
└── api/
    └── client.ts
```

## Data Flow

### Task Submission Flow
```
1. User types: "Deploy web service to blackroad-pi"
           ↓
2. UI sends to Controller API: POST /api/tasks
           ↓
3. Controller calls LLM with:
   - User request
   - Agent inventory
   - Available workspaces
   - Safety constraints
           ↓
4. LLM returns structured plan:
   {
     "target_agent": "blackroad-pi",
     "workspace": "blackroad-os-web",
     "plan": ["Pull latest", "Build", "Deploy"],
     "commands": [...]
   }
           ↓
5. Controller validates:
   - Agent exists and is online
   - Commands pass safety checks
   - Workspace is valid
           ↓
6. Controller sends to UI for approval (if required)
           ↓
7. User approves → Controller queues task
           ↓
8. Controller sends commands to agent via WebSocket
           ↓
9. Agent executes in workspace, streams logs back
           ↓
10. Controller updates task status, stores audit log
           ↓
11. UI shows real-time progress and completion
```

### Agent Connection Flow
```
1. Agent daemon starts on Pi
           ↓
2. Agent connects to Controller: ws://controller:8000/ws/agent/{agent_id}
           ↓
3. Controller registers agent, marks online
           ↓
4. Agent sends heartbeat every 30s with telemetry
           ↓
5. Controller can send commands anytime
           ↓
6. If connection drops, agent auto-reconnects
           ↓
7. Controller marks agent offline after 60s no heartbeat
```

## Security Model

### Network Security
- Agents connect OUTBOUND only (no exposed ports)
- All traffic over Tailscale/LAN (private network)
- WebSocket connections authenticated with tokens
- HTTPS for production deployment

### Command Safety
1. **Allowlist:** Only pre-approved command patterns
2. **Blocklist:** Explicit deny for dangerous patterns
3. **Workspace isolation:** Commands run in containers/venvs
4. **Approval gates:** Destructive operations require UI confirmation
5. **Audit trail:** Every command logged with timestamp, agent, user

### Safety Layers
```
Layer 1: LLM Prompt Engineering
  → System prompt instructs safe command generation

Layer 2: Controller Validation
  → Regex-based allowlist/blocklist
  → Schema validation

Layer 3: Agent Validation
  → Local safety checks before execution
  → Workspace boundaries enforced

Layer 4: Human Approval
  → UI gate for sensitive operations
```

## Deployment Topology

```
Your Mac (Development)
├── Controller Service (localhost:8000)
├── Browser UI (localhost:3000)
└── Can also run agent daemon for testing

blackroad-pi (Production Agent)
├── Agent Daemon (connects to controller)
├── Docker for workspaces
└── Git repos in ~/blackroad/

alice-pi (Production Agent)
├── Agent Daemon (connects to controller)
├── Docker for workspaces
└── Git repos in ~/blackroad/

Future: Controller on cloud/always-on machine
└── Agents connect from anywhere via Tailscale
```

## Scaling Considerations

- **More agents:** Just run daemon on new Pi, it auto-registers
- **More tasks:** Scheduler distributes across available agents
- **High availability:** Run multiple controllers behind load balancer
- **Persistence:** SQLite for v1, PostgreSQL for production
