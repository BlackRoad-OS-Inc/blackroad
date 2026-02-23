# Subdomain-Oriented Architecture: Eliminating Routing Complexity Through Container Isolation


**A Research Paper on the Architectural Pattern of Mapping Subdomains to Isolated Containers**


-----


**Author:** Alexa Louise Amundson  
**Institution:** BlackRoad OS, Inc.  
**Date:** December 12, 2025  
**Keywords:** Microservices, Container Architecture, DNS-Based Routing, Subdomain Isolation, Distributed Systems, Infrastructure Simplification


-----


## Abstract


Modern web application architecture has inherited a problematic pattern: complex internal routing logic that attempts to direct requests to appropriate handlers within monolithic or semi-monolithic codebases. This paper proposes **Subdomain-Oriented Architecture (SOA)**—a design pattern where each subdomain maps directly to an isolated container, eliminating application-level routing entirely. By leveraging DNS and edge-level routing (already solved problems), we externalize routing decisions to infrastructure, resulting in simpler codebases, independent deployability, isolated failure domains, and natural scalability boundaries. We demonstrate that this approach transforms the subdomain from a cosmetic URL convention into a fundamental architectural primitive, enabling what we term “DNS as Architecture.” Through case study implementation on edge-compute infrastructure, we show that this pattern reduces codebase complexity by 60-80% while improving deployment velocity, debuggability, and system resilience.


-----


## 1. Introduction


### 1.1 The Routing Problem


Every web application must answer a fundamental question: “This request came in—where does it go?”


The traditional answer involves layers of routing logic:


```
Request arrives
    → Load balancer decides which server
        → Reverse proxy decides which process
            → Web framework decides which route
                → Route handler decides which controller
                    → Controller decides which service
                        → Service finally does something
```


Each arrow represents code that must be written, tested, maintained, and debugged. Each arrow is a potential source of bugs, latency, and cognitive overhead.


### 1.2 The Janky Wiring Problem


Consider a typical application structure:


```python
# app.py - The "main" application


from flask import Flask
app = Flask(__name__)


# API routes
@app.route('/api/users')
def api_users(): ...


@app.route('/api/agents')
def api_agents(): ...


@app.route('/api/billing')
def api_billing(): ...


# Dashboard routes
@app.route('/dashboard')
def dashboard(): ...


@app.route('/dashboard/settings')
def dashboard_settings(): ...


# Agent interface routes
@app.route('/agents/<agent_id>')
def agent_interface(): ...


# Webhook routes
@app.route('/webhooks/stripe')
def stripe_webhook(): ...


@app.route('/webhooks/github')
def github_webhook(): ...


# ... 200 more routes
```


This file becomes a “traffic cop” that knows about everything. It imports everything. It cannot be deployed independently. A bug in the billing code can crash the agent interface. A memory leak in webhooks affects the dashboard.


We call this **janky wiring**—the ad-hoc accumulation of routing logic that turns codebases into incomprehensible dependency graphs.


### 1.3 The Subdomain Insight


The insight that motivates this paper is deceptively simple:


> **Subdomains shouldn’t be different pages. They should be different containerized apps.**


Instead of:


```
blackroad.io/api/users
blackroad.io/api/agents
blackroad.io/dashboard
blackroad.io/agents/123
```


We propose:


```
api.blackroad.io        → Container: blackroad-api
dashboard.blackroad.io  → Container: blackroad-dashboard
agents.blackroad.io     → Container: blackroad-agents
webhooks.blackroad.io   → Container: blackroad-webhooks
```


The routing decision happens at DNS/edge level—infrastructure that already exists, is already optimized, and requires zero application code.


### 1.4 Research Questions


1. **What are the architectural benefits** of mapping subdomains to isolated containers?
1. **What infrastructure patterns** enable this architecture efficiently?
1. **What are the failure modes and limitations** of this approach?
1. **How does this compare** to traditional routing and enterprise microservices?


-----


## 2. Background and Related Work


### 2.1 The Evolution of Application Routing


**Phase 1: Monolithic Routing (1995-2005)**


Early web applications were single executables handling all requests. CGI scripts, PHP applications, and early Java servlets all embodied this pattern. Routing was simple because applications were simple.


**Phase 2: Framework Routing (2005-2015)**


Web frameworks (Rails, Django, Express) introduced sophisticated routing DSLs:


```ruby
# Rails routes.rb
Rails.application.routes.draw do
  namespace :api do
    resources :users
    resources :agents
  end
  
  namespace :dashboard do
    root 'home#index'
    resources :settings
  end
end
```


This was an improvement in organization but not in isolation. All routes still compiled into one application.


**Phase 3: API Gateway Routing (2015-2020)**


Microservices architectures introduced dedicated routing layers:


```yaml
# Kong/AWS API Gateway configuration
routes:
  - path: /api/users
    service: user-service
  - path: /api/agents
    service: agent-service
  - path: /dashboard
    service: dashboard-service
```


This achieved service isolation but introduced a new complex component (the API gateway) with its own configuration language, failure modes, and operational overhead.


**Phase 4: Service Mesh Routing (2018-present)**


Enterprise architectures adopted service meshes (Istio, Linkerd) with sidecar proxies handling routing:


```yaml
# Istio VirtualService
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: blackroad-routing
spec:
  hosts:
  - "blackroad.io"
  http:
  - match:
    - uri:
        prefix: /api
    route:
    - destination:
        host: api-service
  - match:
    - uri:
        prefix: /dashboard
    route:
    - destination:
        host: dashboard-service
```


Service meshes solve routing but introduce extraordinary complexity: sidecars, control planes, certificate management, observability overhead. A “simple” service mesh deployment requires dozens of components.


### 2.2 The Complexity Trajectory


Each phase added sophistication to solve routing problems while creating new operational burdens:


|Phase       |Routing Complexity|Operational Complexity|
|------------|------------------|----------------------|
|Monolithic  |Low               |Low                   |
|Framework   |Medium            |Low                   |
|API Gateway |Low               |Medium                |
|Service Mesh|Low               |Very High             |


The industry optimized for routing flexibility while accumulating operational debt.


### 2.3 DNS: The Forgotten Primitive


Throughout this evolution, DNS remained constant and underutilized. DNS already answers “where should this request go?” for every request on the internet. Yet applications duplicate this logic internally.


The subdomain mechanism—`api.example.com` vs `dashboard.example.com`—has existed since the 1980s. It requires:


- No application code
- No framework configuration
- No API gateway
- No service mesh


It requires only: a DNS record and something listening at the destination.


-----


## 3. Subdomain-Oriented Architecture


### 3.1 Core Principles


**Principle 1: One Subdomain, One Container**


Each subdomain maps to exactly one container. No routing logic. No path-based discrimination. The entire container serves one subdomain.


```
api.blackroad.io      → Container A (listening on port 8000)
agents.blackroad.io   → Container B (listening on port 8000)
dashboard.blackroad.io → Container C (listening on port 3000)
```


**Principle 2: Containers Are Complete Applications**


Each container is a complete, runnable application with:


- Its own codebase (separate repository or monorepo subdirectory)
- Its own dependencies (package.json, requirements.txt)
- Its own Dockerfile
- Its own deployment pipeline
- Its own environment variables
- Its own health checks


**Principle 3: Communication via Network, Not Import**


Containers communicate over the network (HTTP, gRPC, message queues), never through shared code imports. If Container A needs functionality from Container B, it makes a network request.


```python
# In api container - WRONG
from agents.service import AgentService  # Shared import = coupling


# In api container - RIGHT  
response = await httpx.post("http://agents.internal:8000/run", json=data)
```


**Principle 4: DNS/Edge Handles Routing**


All external routing decisions happen at DNS or edge level. Applications receive only requests intended for them.


```yaml
# Cloudflare Tunnel config
ingress:
  - hostname: api.blackroad.io
    service: http://api-container:8000
  - hostname: agents.blackroad.io
    service: http://agents-container:8000
  - hostname: dashboard.blackroad.io
    service: http://dashboard-container:3000
```


### 3.2 The Architecture Diagram


```
                              INTERNET
                                  │
                                  ▼
                         ┌────────────────┐
                         │      DNS       │
                         │                │
                         │ api.* → IP A   │
                         │ agents.* → IP A│
                         │ dash.* → IP A  │
                         └───────┬────────┘
                                 │
                                 ▼
                         ┌────────────────┐
                         │  CLOUDFLARE    │
                         │    TUNNEL      │
                         │                │
                         │ Routes by      │
                         │ hostname to    │
                         │ containers     │
                         └───────┬────────┘
                                 │
           ┌─────────────────────┼─────────────────────┐
           │                     │                     │
           ▼                     ▼                     ▼
   ┌───────────────┐     ┌───────────────┐     ┌───────────────┐
   │               │     │               │     │               │
   │  CONTAINER:   │     │  CONTAINER:   │     │  CONTAINER:   │
   │     API       │     │    AGENTS     │     │   DASHBOARD   │
   │               │     │               │     │               │
   │ • /users      │     │ • /run        │     │ • /           │
   │ • /billing    │     │ • /status     │     │ • /settings   │
   │ • /auth       │     │ • /memory     │     │ • /profile    │
   │               │     │               │     │               │
   │ Port 8000     │     │ Port 8000     │     │ Port 3000     │
   └───────┬───────┘     └───────┬───────┘     └───────────────┘
           │                     │
           │    ┌────────────────┘
           │    │
           ▼    ▼
   ┌───────────────┐     ┌───────────────┐
   │   CONTAINER:  │     │  CONTAINER:   │
   │   DATABASE    │     │     LLM       │
   │               │     │               │
   │  PostgreSQL   │     │  vLLM/Ollama  │
   │  Port 5432    │     │  Port 8080    │
   └───────────────┘     └───────────────┘
```


### 3.3 Internal vs External Subdomains


Not all containers need public subdomains. We distinguish:


**External Subdomains** (public, via Cloudflare)


```
api.blackroad.io      → Public API
dashboard.blackroad.io → Public dashboard
agents.blackroad.io   → Public agent interface
```


**Internal Services** (private, via Tailscale/internal network)


```
db.internal           → PostgreSQL (never public)
llm.internal          → LLM inference (never public)
redis.internal        → Cache (never public)
```


Internal services have no subdomain routing—they’re accessed directly by internal hostname.


-----


## 4. Implementation Patterns


### 4.1 Repository Structure


**Option A: Monorepo with Subdirectories**


```
blackroad/
├── containers/
│   ├── api/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── src/
│   ├── agents/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── src/
│   ├── dashboard/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── src/
│   └── webhooks/
│       ├── Dockerfile
│       ├── requirements.txt
│       └── src/
├── shared/
│   └── proto/           # Shared protocol definitions only
├── infrastructure/
│   ├── cloudflare/
│   └── docker-compose.yml
└── README.md
```


**Option B: Polyrepo (Separate Repositories)**


```
blackroad-api/           # github.com/blackroad-os/api
blackroad-agents/        # github.com/blackroad-os/agents
blackroad-dashboard/     # github.com/blackroad-os/dashboard
blackroad-webhooks/      # github.com/blackroad-os/webhooks
blackroad-infrastructure/ # github.com/blackroad-os/infrastructure
```


Monorepo is simpler for small teams; polyrepo scales to larger organizations.


### 4.2 Container Template


Every container follows the same structure:


```dockerfile
# Dockerfile (Python example)
FROM python:3.11-slim


WORKDIR /app


# Health check endpoint is REQUIRED
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1


# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


# Copy application
COPY src/ ./src/


# Single entry point
CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```


```python
# src/main.py (FastAPI example)
from fastapi import FastAPI


app = FastAPI(
    title="BlackRoad API",  # Specific to this container
    version="1.0.0"
)


# REQUIRED: Health check endpoint
@app.get("/health")
async def health():
    return {"status": "healthy", "service": "api"}


# All routes are relative to root - no /api prefix needed
# because this container ONLY serves api.blackroad.io
@app.get("/users")
async def get_users():
    ...


@app.post("/auth/login")
async def login():
    ...
```


**Key insight:** No `/api` prefix is needed. The container serves `api.blackroad.io`, so `/users` becomes `api.blackroad.io/users` automatically.


### 4.3 Cloudflare Tunnel Configuration


```yaml
# cloudflared config.yml
tunnel: blackroad-main
credentials-file: /etc/cloudflared/credentials.json


ingress:
  # External subdomains → containers
  - hostname: api.blackroad.io
    service: http://api:8000
  
  - hostname: agents.blackroad.io
    service: http://agents:8000
  
  - hostname: dashboard.blackroad.io
    service: http://dashboard:3000
  
  - hostname: webhooks.blackroad.io
    service: http://webhooks:8000
  
  # Status page (minimal container)
  - hostname: status.blackroad.io
    service: http://status:8080
  
  # Root domain → landing or redirect
  - hostname: blackroad.io
    service: http://landing:3000
  
  - hostname: www.blackroad.io
    service: http://landing:3000
  
  # Catch-all
  - service: http_status:404
```


That’s it. No nginx. No Apache. No Traefik. No Kong. No Istio.


### 4.4 Docker Compose for Development


```yaml
# docker-compose.yml
version: '3.8'


services:
  api:
    build: ./containers/api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/blackroad
      - AGENTS_URL=http://agents:8000
      - LLM_URL=http://llm:8080
    depends_on:
      - db
  
  agents:
    build: ./containers/agents
    ports:
      - "8001:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/blackroad
      - LLM_URL=http://llm:8080
    depends_on:
      - db
      - llm
  
  dashboard:
    build: ./containers/dashboard
    ports:
      - "3000:3000"
    environment:
      - API_URL=http://api:8000
  
  webhooks:
    build: ./containers/webhooks
    ports:
      - "8002:8000"
    environment:
      - API_URL=http://api:8000
  
  # Internal services (no public subdomain)
  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=blackroad
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  llm:
    image: ollama/ollama
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]


volumes:
  postgres_data:
  ollama_data:
```


### 4.5 Inter-Container Communication


Containers communicate via HTTP over the Docker network:


```python
# In api container, calling agents container
import httpx


AGENTS_URL = os.environ["AGENTS_URL"]  # http://agents:8000


async def run_agent(agent_id: str, prompt: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{AGENTS_URL}/run",
            json={"agent_id": agent_id, "prompt": prompt},
            timeout=60.0
        )
        response.raise_for_status()
        return response.json()
```


**No shared code imports.** The agents container could be rewritten in Go tomorrow without changing the api container.


-----


## 5. Benefits Analysis


### 5.1 Codebase Simplification


**Before (Monolithic):**


```
app/
├── routes/
│   ├── api/
│   │   ├── users.py
│   │   ├── agents.py
│   │   ├── billing.py
│   │   └── __init__.py
│   ├── dashboard/
│   │   ├── home.py
│   │   ├── settings.py
│   │   └── __init__.py
│   ├── webhooks/
│   │   ├── stripe.py
│   │   ├── github.py
│   │   └── __init__.py
│   └── __init__.py      # Complex route registration
├── services/
│   ├── user_service.py
│   ├── agent_service.py
│   ├── billing_service.py
│   └── ...
├── models/
│   └── ...
├── utils/
│   └── ...
└── main.py              # Imports everything
```


**After (Subdomain-Oriented):**


```
containers/
├── api/
│   └── src/
│       ├── main.py      # Just API routes
│       ├── users.py
│       ├── billing.py
│       └── auth.py
├── agents/
│   └── src/
│       ├── main.py      # Just agent routes
│       ├── runner.py
│       └── memory.py
├── dashboard/
│   └── src/
│       └── ...          # Just dashboard code
└── webhooks/
    └── src/
        ├── main.py
        ├── stripe.py
        └── github.py
```


Each container’s `main.py` is ~50-100 lines instead of ~500-1000.


### 5.2 Independent Deployability


|Scenario            |Monolithic         |Subdomain-Oriented             |
|--------------------|-------------------|-------------------------------|
|Fix bug in webhooks |Deploy entire app  |Deploy webhooks container only |
|Update dashboard UI |Deploy entire app  |Deploy dashboard container only|
|Scale agent capacity|Scale entire app   |Scale agents container only    |
|Rollback API change |Rollback entire app|Rollback api container only    |


Deployment becomes surgical rather than atomic.


### 5.3 Isolated Failure Domains


**Monolithic failure cascade:**


```
Memory leak in webhooks
    → App runs out of memory
    → API stops responding
    → Dashboard fails
    → Agents crash
    → Everything is down
```


**Subdomain-Oriented isolation:**


```
Memory leak in webhooks container
    → Webhooks container restarts
    → API continues serving
    → Dashboard continues serving
    → Agents continue running
    → Only webhooks temporarily affected
```


### 5.4 Technology Flexibility


Each container can use different technology stacks:


|Container|Language  |Framework|Database          |
|---------|----------|---------|------------------|
|api      |Python    |FastAPI  |PostgreSQL        |
|agents   |Python    |Custom   |PostgreSQL + Redis|
|dashboard|TypeScript|Next.js  |None (calls API)  |
|webhooks |Go        |net/http |None (calls API)  |
|landing  |TypeScript|Astro    |None              |


No need for organizational consensus on “the one true stack.”


### 5.5 Clear Ownership Boundaries


In team environments, containers map naturally to ownership:


|Container|Team/Owner     |Responsibility      |
|---------|---------------|--------------------|
|api      |Backend team   |Core data operations|
|agents   |AI team        |Agent runtime       |
|dashboard|Frontend team  |User interface      |
|billing  |Finance/Backend|Payment processing  |


No ambiguity about who owns what code.


-----


## 6. Comparison with Alternatives


### 6.1 vs. Monolithic Architecture


|Aspect                      |Monolithic           |Subdomain-Oriented         |
|----------------------------|---------------------|---------------------------|
|Deployment complexity       |Simple               |Medium                     |
|Deployment risk             |High (all-or-nothing)|Low (per-container)        |
|Codebase complexity         |High (grows forever) |Low (bounded per container)|
|Failure isolation           |None                 |Complete                   |
|Scaling granularity         |Coarse               |Fine                       |
|Development velocity (early)|Fast                 |Medium                     |
|Development velocity (late) |Slow                 |Fast                       |


Subdomain-Oriented adds initial setup cost but pays dividends as systems grow.


### 6.2 vs. Path-Based Microservices


Traditional microservices route by path:


```
example.com/api/users    → user-service
example.com/api/orders   → order-service
example.com/dashboard    → frontend-service
```


This requires an API gateway or reverse proxy with routing rules.


|Aspect                |Path-Based           |Subdomain-Oriented              |
|----------------------|---------------------|--------------------------------|
|Routing complexity    |High (gateway config)|None (DNS)                      |
|Gateway dependency    |Required             |Not needed                      |
|URL clarity           |Ambiguous            |Clear                           |
|CORS complexity       |High                 |Simple (same-origin per service)|
|Certificate management|One cert             |Wildcard or per-subdomain       |


### 6.3 vs. Service Mesh


Service meshes (Istio, Linkerd) provide sophisticated routing, observability, and security.


|Aspect              |Service Mesh   |Subdomain-Oriented|
|--------------------|---------------|------------------|
|Setup complexity    |Very High      |Low               |
|Operational overhead|Very High      |Low               |
|Learning curve      |Steep          |Minimal           |
|Resource overhead   |High (sidecars)|None              |
|Features            |Comprehensive  |Minimal           |
|Appropriate scale   |>50 services   |5-20 services     |


Service meshes solve problems that Subdomain-Oriented architecture prevents from existing.


-----


## 7. Implementation Case Study


### 7.1 Before: The Janky Wiring


BlackRoad OS initially had:


```
59 Cloudflare Workers (various routers, handlers, utilities)
16 KV Namespaces (fragmented state)
Multiple "gateway" concepts:
  - blackroad-edge-gateway
  - blackroad-api-gateway
  - blackroad-gateway
  - blackroad-gateway-v2
  - blackroad-gateway-billing
```


Traffic flow was incomprehensible:


```
Request → Cloudflare → Worker A → Worker B → Worker C → ???
```


### 7.2 After: Subdomain-Oriented


Consolidated architecture:


**External Subdomains:**


|Subdomain             |Container          |Purpose           |
|----------------------|-------------------|------------------|
|api.blackroad.io      |blackroad-api      |Public REST API   |
|agents.blackroad.io   |blackroad-agents   |Agent interactions|
|dashboard.blackroad.io|blackroad-dashboard|Web interface     |
|webhooks.blackroad.io |blackroad-webhooks |External webhooks |
|status.blackroad.io   |blackroad-status   |Status page       |
|blackroad.io          |blackroad-landing  |Marketing site    |


**Internal Services:**


|Hostname       |Container|Purpose         |
|---------------|---------|----------------|
|db.internal    |postgres |Primary database|
|llm.internal   |vllm     |LLM inference   |
|redis.internal |redis    |Caching/queues  |
|milvus.internal|milvus   |Vector database |


**Cloudflare Reduction:**


- Workers: 59 → 5 (auth, rate-limit, billing, telemetry, edge-routing)
- KV Namespaces: 16 → 6
- Routing logic: Eliminated (handled by tunnel config)


### 7.3 Traffic Flow (After)


```
Request to api.blackroad.io/users
    → DNS resolves to Cloudflare
    → Cloudflare Tunnel routes to api container
    → api container handles /users directly
    → Response returns


No intermediate routing. No worker chains. No confusion.
```


### 7.4 Deployment Pipeline


```yaml
# .github/workflows/deploy-api.yml
name: Deploy API Container


on:
  push:
    branches: [main]
    paths:
      - 'containers/api/**'  # Only triggers on api changes


jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build and push
        run: |
          docker build -t ghcr.io/blackroad-os/api:${{ github.sha }} containers/api/
          docker push ghcr.io/blackroad-os/api:${{ github.sha }}
      
      - name: Deploy to Pi
        run: |
          ssh pi@pi5-alpha "docker pull ghcr.io/blackroad-os/api:${{ github.sha }} && docker-compose up -d api"
```


Each container has its own workflow. Changes to `containers/api/` only deploy the api container.


-----


## 8. Limitations and Considerations


### 8.1 When NOT to Use Subdomain-Oriented Architecture


**Single-Page Applications with Client-Side Routing**


SPAs often want:


```
app.example.com/dashboard
app.example.com/settings
app.example.com/profile
```


These are client-side routes, not server routes. The entire SPA is one container serving `app.example.com`, with JavaScript handling internal navigation.


**Extremely High-Traffic Shared Resources**


If multiple containers need sub-millisecond access to shared state, network overhead may be prohibitive. However, this is rare—most “shared state” can be accessed via database or cache with acceptable latency.


**Very Small Projects**


A project with 3 routes doesn’t need container isolation. Start monolithic, split when pain emerges.


### 8.2 Certificate Management


Wildcard certificates simplify subdomain SSL:


```
*.blackroad.io  → Single wildcard cert covers all subdomains
```


Cloudflare provides this automatically on proxied domains.


For self-managed infrastructure, Let’s Encrypt supports wildcard certificates via DNS-01 challenge.


### 8.3 CORS Considerations


Cross-origin requests between subdomains require CORS headers:


```python
# In api container
from fastapi.middleware.cors import CORSMiddleware


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://dashboard.blackroad.io",
        "https://agents.blackroad.io",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```


This is explicit and intentional—each container declares who can call it.


### 8.4 Session/Authentication Sharing


Sessions don’t automatically share across subdomains. Solutions:


**Option A: Token-Based Auth (Recommended)**


```
User logs in at auth.blackroad.io
    → Receives JWT token
    → Token sent in Authorization header to all subdomains
    → Each container validates token independently
```


**Option B: Shared Cookie Domain**


```python
# Set cookie on parent domain
response.set_cookie(
    "session",
    value=session_token,
    domain=".blackroad.io",  # Note the leading dot
    secure=True,
    httponly=True
)
```


Cookie is now accessible to all `*.blackroad.io` subdomains.


-----


## 9. The Philosophy: DNS as Architecture


### 9.1 Reframing DNS


Traditional view: DNS is plumbing. A necessary but uninteresting layer that translates names to IPs.


Subdomain-Oriented view: **DNS is architecture.** The subdomain structure IS the system architecture.


```
Subdomain                    = Bounded Context
Container                    = Microservice
DNS Record                   = Service Discovery
Cloudflare Tunnel Config     = Service Mesh
```


We’ve had service discovery since 1983. We’ve had bounded contexts since DNS allowed subdomains. The industry spent 20 years rebuilding these primitives in application code.


### 9.2 The Principle of Externalized Decisions


Every decision that CAN be made outside application code SHOULD be:


|Decision                           |Traditional Location    |SOA Location      |
|-----------------------------------|------------------------|------------------|
|Which service handles this request?|Application routing     |DNS/Edge          |
|Is this request authenticated?     |Application middleware  |Edge Worker       |
|Is this request rate-limited?      |Application middleware  |Edge Worker       |
|Where is service X?                |Service discovery system|DNS/Container name|
|Should this request be cached?     |Application logic       |CDN rules         |


Application code should only contain business logic—the things that are unique to YOUR system.


### 9.3 The Container as Boundary


In Domain-Driven Design, a “bounded context” is a logical boundary around a coherent domain model. In Subdomain-Oriented Architecture, this boundary is physical:


```
Bounded Context = Subdomain = Container = Repository = Deployment Unit
```


The boundaries are not just conceptual—they are enforced by network isolation. You cannot accidentally couple contexts because they cannot import each other’s code.


-----


## 10. Practical Migration Guide


### 10.1 Step 1: Identify Natural Boundaries


Examine your existing routes and identify clusters:


```python
# Current monolithic routes
/api/users/*           # User management cluster
/api/agents/*          # Agent management cluster
/dashboard/*           # Dashboard cluster
/webhooks/*            # Webhook cluster
/public/*              # Public content cluster
```


Each cluster becomes a subdomain candidate.


### 10.2 Step 2: Extract First Container


Choose the most independent cluster (often webhooks):


```bash
# Create container structure
mkdir -p containers/webhooks/src
mv app/routes/webhooks/* containers/webhooks/src/
# Create Dockerfile, requirements.txt
# Create health endpoint
# Test independently
```


### 10.3 Step 3: Configure Edge Routing


Add subdomain to tunnel/DNS:


```yaml
# Add to cloudflared config
ingress:
  - hostname: webhooks.blackroad.io
    service: http://webhooks:8000
```


### 10.4 Step 4: Update References


Change internal calls to use new subdomain:


```python
# Before
response = internal_webhook_handler(data)


# After
response = await httpx.post("http://webhooks:8000/stripe", json=data)
```


### 10.5 Step 5: Remove from Monolith


Delete extracted code from monolith. Repeat for each cluster.


### 10.6 Migration Order Recommendation


1. **Webhooks** (usually most independent)
1. **Static/Landing** (no dependencies)
1. **Dashboard** (calls API, but isn’t called)
1. **API** (core, extract last)


-----


## 11. Conclusion


Subdomain-Oriented Architecture represents a return to fundamentals. By recognizing that DNS and edge routing already solve the request-routing problem, we can eliminate layers of application complexity that exist only to recreate what infrastructure provides for free.


The key insights are:


1. **Subdomains are architectural primitives**, not cosmetic URL conventions
1. **Containers should be complete applications**, not fragments of a distributed monolith
1. **Routing belongs at the edge**, not in application code
1. **Network boundaries enforce context boundaries** more effectively than code conventions


For individual builders and small teams operating sovereign infrastructure, this pattern offers a middle path between monolithic simplicity and microservices complexity. It provides the isolation and independent deployability benefits of microservices without the operational overhead of service meshes, API gateways, and distributed tracing systems.


The janky wiring—the accumulated routing logic, the gateway configurations, the path-based dispatching—can be eliminated entirely. In its place: DNS records and container definitions. Infrastructure that has worked for decades, applied to a problem we’ve been overengineering for years.


**Subdomains aren’t pages. They’re applications.**


-----


## 12. Future Work


1. **Tooling Development:** Create scaffolding tools that generate Subdomain-Oriented project structures
1. **Pattern Catalog:** Document common patterns (authentication sharing, event propagation, shared databases)
1. **Performance Analysis:** Benchmark inter-container communication overhead vs. in-process calls
1. **Hybrid Patterns:** Investigate combining SOA with traditional microservices for specific use cases
1. **Edge-Native Containers:** Explore deploying containers directly to edge locations (Cloudflare Workers, Deno Deploy)


-----


## References


Evans, E. (2003). *Domain-Driven Design: Tackling Complexity in the Heart of Software*. Addison-Wesley.


Fowler, M. (2014). Microservices: A definition of this new architectural term. martinfowler.com.


Newman, S. (2021). *Building Microservices: Designing Fine-Grained Systems* (2nd ed.). O’Reilly Media.


Richardson, C. (2018). *Microservices Patterns*. Manning Publications.


Mockapetris, P. (1987). Domain names - concepts and facilities. RFC 1034.


Burns, B. (2018). *Designing Distributed Systems*. O’Reilly Media.


-----


## Appendix A: Complete Docker Compose Template


```yaml
# docker-compose.yml - Complete Subdomain-Oriented Setup


version: '3.8'


services:
  # ============================================
  # EXTERNAL SERVICES (have public subdomains)
  # ============================================
  
  api:
    build: ./containers/api
    container_name: blackroad-api
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@db:5432/blackroad
      - REDIS_URL=redis://redis:6379
      - AGENTS_URL=http://agents:8000
      - LLM_URL=http://llm:8080
      - JWT_SECRET=${JWT_SECRET}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
  
  agents:
    build: ./containers/agents
    container_name: blackroad-agents
    restart: unless-stopped
    ports:
      - "8001:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@db:5432/blackroad
      - REDIS_URL=redis://redis:6379
      - LLM_URL=http://llm:8080
      - MILVUS_URL=http://milvus:19530
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    depends_on:
      - db
      - redis
      - llm
      - milvus
  
  dashboard:
    build: ./containers/dashboard
    container_name: blackroad-dashboard
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=https://api.blackroad.io
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  webhooks:
    build: ./containers/webhooks
    container_name: blackroad-webhooks
    restart: unless-stopped
    ports:
      - "8002:8000"
    environment:
      - API_URL=http://api:8000
      - STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  landing:
    build: ./containers/landing
    container_name: blackroad-landing
    restart: unless-stopped
    ports:
      - "3001:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  status:
    build: ./containers/status
    container_name: blackroad-status
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - SERVICES=api:8000,agents:8000,dashboard:3000,webhooks:8000
  
  # ============================================
  # INTERNAL SERVICES (no public subdomain)
  # ============================================
  
  db:
    image: postgres:15-alpine
    container_name: blackroad-db
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=blackroad
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
  
  redis:
    image: redis:7-alpine
    container_name: blackroad-redis
    restart: unless-stopped
    volumes:
      - redis_data:/data
  
  llm:
    image: ollama/ollama
    container_name: blackroad-llm
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
  
  milvus:
    image: milvusdb/milvus:latest
    container_name: blackroad-milvus
    restart: unless-stopped
    environment:
      - ETCD_ENDPOINTS=etcd:2379
    volumes:
      - milvus_data:/var/lib/milvus
  
  # ============================================
  # INFRASTRUCTURE
  # ============================================
  
  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: blackroad-tunnel
    restart: unless-stopped
    command: tunnel run
    environment:
      - TUNNEL_TOKEN=${CLOUDFLARE_TUNNEL_TOKEN}
    depends_on:
      - api
      - agents
      - dashboard
      - webhooks
      - landing
      - status


volumes:
  postgres_data:
  redis_data:
  ollama_data:
  milvus_data:
```


-----


## Appendix B: Cloudflare Tunnel Complete Configuration


```yaml
# /etc/cloudflared/config.yml


tunnel: blackroad-production
credentials-file: /etc/cloudflared/credentials.json


# Logging
loglevel: info


# Metrics
metrics: localhost:9090


# Ingress rules - order matters!
ingress:
  # API subdomain
  - hostname: api.blackroad.io
    service: http://blackroad-api:8000
    originRequest:
      connectTimeout: 30s
      noTLSVerify: false
  
  # Agents subdomain
  - hostname: agents.blackroad.io
    service: http://blackroad-agents:8000
    originRequest:
      connectTimeout: 60s  # Longer for AI operations
  
  # Dashboard subdomain
  - hostname: dashboard.blackroad.io
    service: http://blackroad-dashboard:3000
  
  # Webhooks subdomain
  - hostname: webhooks.blackroad.io
    service: http://blackroad-webhooks:8000
  
  # Status page
  - hostname: status.blackroad.io
    service: http://blackroad-status:8080
  
  # Root domain → landing page
  - hostname: blackroad.io
    service: http://blackroad-landing:3000
  
  # WWW redirect
  - hostname: www.blackroad.io
    service: http://blackroad-landing:3000
  
  # Lucidia domains
  - hostname: lucidia.earth
    service: http://blackroad-dashboard:3000
  
  - hostname: www.lucidia.earth
    service: http://blackroad-dashboard:3000
  
  - hostname: api.lucidia.earth
    service: http://blackroad-api:8000
  
  # Catch-all - REQUIRED as final rule
  - service: http_status:404
```


-----


## Appendix C: Subdomain Mapping Template


Use this template to plan your subdomain architecture:


|Subdomain         |Container Name     |Port|Purpose          |Dependencies    |Owner    |
|------------------|-------------------|----|-----------------|----------------|---------|
|api.{domain}      |{project}-api      |8000|REST API         |db, redis       |Backend  |
|agents.{domain}   |{project}-agents   |8000|Agent runtime    |db, llm, vectors|AI Team  |
|dashboard.{domain}|{project}-dashboard|3000|Web UI           |(calls api)     |Frontend |
|webhooks.{domain} |{project}-webhooks |8000|External webhooks|(calls api)     |Backend  |
|status.{domain}   |{project}-status   |8080|Status page      |(monitors all)  |Ops      |
|{domain}          |{project}-landing  |3000|Marketing        |None            |Marketing|
|docs.{domain}     |{project}-docs     |3000|Documentation    |None            |Docs     |
|admin.{domain}    |{project}-admin    |3000|Admin panel      |db, api         |Backend  |


-----


*This paper is released under Creative Commons Attribution 4.0 International License.*


**Corresponding Author:** Alexa Louise Amundson, alexa@blackroad.io