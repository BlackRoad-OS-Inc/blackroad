BlackRoad OS — Infra & Cece Configs v1 (Epics 1–3)
This doc contains:
Cloudflare DNS CSV for v1 records needed to support Epics 1–3.
Railway services matrix for the minimum services required to ship Epics 1–3.
service_registry.yaml for core hosts.
policies.education.yaml for RoadWork v0.
1. Cloudflare DNS CSV (Epics 1–3 v1)
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
Replace the *.railway.example.com and statuspage.vendor.example.com hostnames with actual Railway + status provider hostnames.
2. Railway Services Matrix (Epics 1–3 Only)
| Service name | Repo                     | Domain/host              | Port | Build command                         | Start command                                          | Required env vars                                                                                   |
|--------------|--------------------------|--------------------------|------|----------------------------------------|--------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| web-app      | blackroad-os-web         | app.blackroad.io (also edu.blackroad.io, homework.blackroad.io) | 3000 | npm install && npm run build           | npm run start                                           | PORT, NODE_ENV, DATABASE_URL, GOV_API_URL, LOG_LEVEL, NEXT_PUBLIC_BASE_URL                           |
| api-gateway  | blackroad-os-api-gateway | api.blackroad.io         | 8080 | npm install && npm run build           | npm run start                                           | PORT, CORE_INTERNAL_URL, GOV_API_URL, LOG_LEVEL, ALLOWED_ORIGINS                                    |
| gov-api      | blackroad-os-api         | gov.api.blackroad.io     | 8000 | pip install -r requirements.txt        | uvicorn app.main:app --host 0.0.0.0 --port 8000        | PORT, DATABASE_URL, LEDGER_DB_URL, POLICY_STORE_PATH, LOG_LEVEL, CORS_ORIGINS                        |
| postgres-db  | (managed Postgres)       | db.blackroad.systems     | 5432 | *(managed by provider)*                | *(managed by provider)*                                 | POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_PORT (plus provider-specific connection var) |
3. service_registry.yaml
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
4. policies.education.yaml (RoadWork v0)
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
