Heh, you’re in “just keep feeding me bricks” mode. I love it. 🧱
You’ve got:
Epics 1–3 + issues,
Infra + Cece configs (DNS CSV, Railway matrix, service_registry, policies),
So the next super-useful artifact is a blackroad-os-infra README that explains how all of this hangs together and the exact steps Future You should follow.
Here it is, ready to drop into Canvas or blackroad-os-infra/README.md:
# BlackRoad OS Infra v1 — Epics 1–3 Setup Guide
> Scope: Enough infra to ship **Epics 1–3** from  
> **BlackRoad OS — Master Execution Plan v1.0**
This guide explains:
- What services exist in v1.
- Which domains/subdomains must be configured.
- Which config files are authoritative.
- The exact sequence to bring up **app + API + Cece + Education v0**.
---
## 0. Overview
For Epics 1–3 we are wiring up:
- `app.blackroad.io` — main app (also fronts `edu.` and `homework.`)
- `api.blackroad.io` — HTTP API gateway (stub/early)
- `gov.api.blackroad.io` — governance API (Cece spine)
- `db.blackroad.systems` — shared Postgres
- `ledger.blackroad.systems` — alias for ledger API (v0)
- `edu.blackroad.io` — teacher door into Education / RoadWork
- `homework.blackroad.io` — student door into Education
- reserved: `ws.blackroad.io`, `mesh.blackroad.network`, `pi.mesh.blackroad.network` (for later mesh/agent work)
Everything is fronted by **Cloudflare DNS**, with app/API/Gov running on **Railway**.
---
## 1. Files in This Folder
This infra pack assumes the following files live under `blackroad-os-infra/`:
- `dns/blackroad-epics-1-3.csv`  
→ Cloudflare DNS records for v1.
- `railway/services-epics-1-3.md`  
→ Matrix of Railway services, repos, ports, commands, envs.
- `config/service_registry.yaml`  
→ Mapping: hostname → layer → repo → workstream → pillar → policy_scope.
- `policies/policies.education.yaml`  
→ Education (RoadWork v0) governance policies for Cece.
Feel free to rename paths, but keep the **filenames** the same for consistency.
---
## 2. Cloudflare DNS — What to Create
Source: `dns/blackroad-epics-1-3.csv`
```csv
Type,Name,Content,TTL,Proxied,Notes
CNAME,app.blackroad.io,web-app.railway.example.com,300,true,"Main multi-tenant app (app.blackroad.io, also hosts edu/homework verticals)"
CNAME,api.blackroad.io,api-gateway.railway.example.com,300,true,"Public HTTP API gateway"
CNAME,gov.api.blackroad.io,gov-api.railway.example.com,300,true,"Governance API service"
CNAME,ledger.blackroad.systems,gov-api.railway.example.com,300,false,"Ledger API alias (same service as gov.api for v0)"
CNAME,db.blackroad.systems,postgres-db.railway.internal,300,false,"Primary Postgres instance endpoint / connection alias"
CNAME,edu.blackroad.io,app.blackroad.io,300,true,"Education vertical door (teacher UI)"
CNAME,homework.blackroad.io,app.blackroad.io,300,true,"Homework vertical door (student UI)"
CNAME,ws.blackroad.io,operator-ws.railway.example.com,300,true,"Reserved WebSocket hub (Cece/Operator; may be stubbed in Epics 1–3)"
CNAME,mesh.blackroad.network,mesh-operator.railway.example.com,300,true,"Reserved mesh entry for later agent work (not required to be functional in Epics 1–3)"
CNAME,pi.mesh.blackroad.network,pi-mesh.railway.example.com,300,true,"Reserved Pi mesh entry for later agent work"
CNAME,status.blackroad.io,statuspage.vendor.example.com,300,true,"Public status page (optional but recommended)"
2.1 Steps (manual setup)
Log into Cloudflare for the relevant zones (blackroad.io, blackroad.systems, blackroad.network).
For each line in the CSV:
Create the record with the same Type, Name, and TTL.
Replace *.railway.example.com with the real Railway hostname for that service.
Decide if Proxied should be orange cloud (true) or DNS-only (false).
Verify:
dig app.blackroad.io, dig gov.api.blackroad.io, dig db.blackroad.systems all resolve.
Optional: later, convert this CSV into Terraform or another IaC format.
3. Railway Services — What to Create
Source: railway/services-epics-1-3.md
| Service name | Repo                     | Domain/host              | Port | Build command                         | Start command                                          | Required env vars                                                                                   |
|--------------|--------------------------|--------------------------|------|----------------------------------------|--------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| web-app      | blackroad-os-web         | app.blackroad.io (also edu.blackroad.io, homework.blackroad.io) | 3000 | npm install && npm run build           | npm run start                                           | PORT, NODE_ENV, DATABASE_URL, GOV_API_URL, LOG_LEVEL, NEXT_PUBLIC_BASE_URL                           |
| api-gateway  | blackroad-os-api-gateway | api.blackroad.io         | 8080 | npm install && npm run build           | npm run start                                           | PORT, CORE_INTERNAL_URL, GOV_API_URL, LOG_LEVEL, ALLOWED_ORIGINS                                    |
| gov-api      | blackroad-os-api         | gov.api.blackroad.io     | 8000 | pip install -r requirements.txt        | uvicorn app.main:app --host 0.0.0.0 --port 8000        | PORT, DATABASE_URL, LEDGER_DB_URL, POLICY_STORE_PATH, LOG_LEVEL, CORS_ORIGINS                        |
| postgres-db  | (managed Postgres)       | db.blackroad.systems     | 5432 | *(managed by provider)*                | *(managed by provider)*                                 | POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_PORT (plus provider-specific connection var) |
3.1 Setup order
Create Postgres instance
Provision a managed Postgres DB.
Save connection URL as a secret (e.g., DATABASE_URL) to reuse.
Create gov-api service
New Railway service from blackroad-os-api repo.
Build: pip install -r requirements.txt
Start: uvicorn app.main:app --host 0.0.0.0 --port 8000
Env vars:
PORT=8000
DATABASE_URL=<same as app DB for v0>
LEDGER_DB_URL=<same or separate>
POLICY_STORE_PATH=policies/policies.education.yaml (or similar)
LOG_LEVEL=info
CORS_ORIGINS=https://app.blackroad.io,https://edu.blackroad.io,https://homework.blackroad.io
Create web-app service
New Railway service from blackroad-os-web.
Build: npm install && npm run build
Start: npm run start
Env vars:
PORT=3000
NODE_ENV=production
DATABASE_URL=<same Postgres>
GOV_API_URL=https://gov.api.blackroad.io
LOG_LEVEL=info
NEXT_PUBLIC_BASE_URL=https://app.blackroad.io
Create api-gateway (optional for v0)
New Railway service from blackroad-os-api-gateway (can be stubbed to just proxy to core).
Wire api.blackroad.io as a front door, even if logic is minimal.
Update Cloudflare DNS
Once Railway gives you hostnames, update Content in the CSV & Cloudflare records.
4. Service Registry — How Cece & Infra See the World
File: config/service_registry.yaml
services:
app.blackroad.io:
layer: experience
repo: blackroad-os-web
workstream: W1-core-app
pillar: os
policy_scope: "app.*"
edu.blackroad.io:
layer: experience
repo: blackroad-os-web
workstream: W4-verticals
pillar: education
policy_scope: "edu.*"
homework.blackroad.io:
layer: experience
repo: blackroad-os-web
workstream: W4-verticals
pillar: education
policy_scope: "homework.*"
api.blackroad.io:
layer: gateway
repo: blackroad-os-api-gateway
workstream: W3-infra
pillar: os
policy_scope: "api.*"
gov.api.blackroad.io:
layer: governance
repo: blackroad-os-api
workstream: W2-governance
pillar: governance
policy_scope: "gov.api.*"
mesh.blackroad.network:
layer: mesh
repo: blackroad-os-operator
workstream: W5-mesh
pillar: mesh
policy_scope: "mesh.*"
db.blackroad.systems:
layer: infra
repo: blackroad-os-infra
workstream: W6-data
pillar: data
policy_scope: "data.db.*"
ledger.blackroad.systems:
layer: governance
repo: blackroad-os-api
workstream: W2-governance
pillar: governance
policy_scope: "gov.ledger.*"
4.1 How to use it
Infra tooling can read this file to:
Display service inventory.
Cross-check DNS records vs expected hosts.
Cece can load this to:
Infer layer, pillar, and policy_scope from the host alone.
Apply default policies (app.*, edu.*, mesh.*, etc.) consistently.
5. Education Policies — RoadWork v0
File: policies/policies.education.yaml
policies:
- id: edu.create-assignment.teacher-only
description: "Only users with role=teacher may create assignments."
effect: allow
subject:
role: teacher
action: "assignment:create"
resource: "assignment"
condition: {}
requires_ledger_event: true
- id: edu.submit-assignment.student-only
description: "Only the assigned student may submit a homework assignment."
effect: allow
subject:
role: student
action: "submission:submit"
resource: "assignment"
condition:
matches_assignment_assignee: true
requires_ledger_event: true
- id: edu.review-submission.teacher-only
description: "Only teachers may mark a submission as reviewed."
effect: allow
subject:
role: teacher
action: "submission:review"
resource: "submission"
condition: {}
requires_ledger_event: true
- id: edu.default-deny-unauthorised
description: "Deny any other actors attempting Education actions not explicitly allowed above."
effect: deny
subject:
role: "*"
action: "edu.*"
resource: "*"
condition: {}
requires_ledger_event: true
5.1 Wiring into gov-api
Inside blackroad-os-api:
On startup:
Load policies.education.yaml from disk (path via POLICY_STORE_PATH env var).
Parse into policy objects keyed by id and/or action.
In POST /policy/evaluate:
Map the incoming action + subject.role to one or more policies.
Evaluate conditions (matches_assignment_assignee etc.).
Return decision and policy_id.
In POST /ledger/event:
Persist events with policy_id and requires_ledger_event.
6. Boot Sequence Checklist (Epics 1–3)
Follow this order for a clean bring-up:
Postgres
Provision DB.
Set DATABASE_URL for web-app and gov-api.
Governance API
Deploy gov-api service (blackroad-os-api).
Configure POLICY_STORE_PATH and CORS_ORIGINS.
Verify https://gov.api.blackroad.io/health.
Web App
Deploy web-app service (blackroad-os-web).
Configure GOV_API_URL and DB connection.
Verify https://app.blackroad.io.
Education
Confirm host-based routing for edu.blackroad.io and homework.blackroad.io.
Run migrations for Assignment and Submission models.
Walk through teacher ↔ student flow on dev accounts.
Governance Integration
Confirm assignment:create, submission:submit, submission:review all:
Call policy/evaluate.
Emit ledger events.
7. Future Extensions (Beyond Epics 1–3)
Reserved but not required to fully work yet:
ws.blackroad.io → WebSocket hub for operator.
mesh.blackroad.network, pi.mesh.blackroad.network → Pi/agent mesh.
Additional entries in service_registry.yaml for RoadTube, Studio, etc.
For now, keep focus on:
One working vertical (Education)
One working governance flow (review homework)
Stable, boring infra underneath
That’s enough to get to “a real person can log in, do homework, and be governed by Cece.”
---
If you want the next “brick” after this, we can:
- Generate a tiny **Python or TS loader** that reads `service_registry.yaml` and `policies.education.yaml` and exposes them as Cece-ready objects, or
- A script/checklist for **GitHub Project board + labels** so the backlog you just generated matches the infra state.
