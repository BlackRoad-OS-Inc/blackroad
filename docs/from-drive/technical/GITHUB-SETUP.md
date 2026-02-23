BlackRoad OS — GitHub Issues & Config Artifacts (Epics 1–3)
This doc contains:
GitHub issues for all tickets in Epics 1–3, grouped by repo.
Cloudflare DNS CSV for v1 records needed to support Epics 1–3.
Railway services matrix for the minimum services needed to ship Epics 1–3.
service_registry.yaml for core hosts.
policies.education.yaml for RoadWork v0.
1. GitHub Issues for Epics 1–3
Repo: 
blackroad-os-web
WEB-1 — Scaffold core Next.js app shell for 
app.blackroad.io
Repo: blackroad-os-web
Labels: pillar:os, ws:W1-core-app, layer:experience, env:dev, host:app.blackroad.io, atom:ui
Body
Summary
Scaffold the core Next.js app shell that will serve as the main workspace at app.blackroad.io, including basic routing, layout, and placeholder navigation for verticals.
Acceptance Criteria
Next.js app boots locally and on Railway using a single APP_BASE_URL.
Root / route renders a simple dashboard-style layout.
Global navigation includes placeholder links for Home, Education, Studio, Settings.
Layout component exists and is reused across all initial pages.
Basic error and 404 pages implemented.
Implementation Notes
Start from a current LTS Next.js template (with TypeScript if desired).
Set up minimal file structure: pages/, components/layout/, lib/.
Keep styling minimal (Tailwind or CSS modules) but consistent.
Dependencies
Depends on Railway app service skeleton (INFRA-2).
WEB-2 — Implement basic user model and session management
Repo: blackroad-os-web
Labels: pillar:os, ws:W1-core-app, layer:experience, env:dev, host:app.blackroad.io, atom:auth
Summary
Introduce a basic User model and session handling so the app can distinguish authenticated vs unauthenticated users.
Acceptance Criteria
User type/interface defined (id, email, role, created_at, updated_at).
Session abstraction implemented (e.g., using JWT or session cookies).
useUser() and useRequireAuth() hooks available and used on protected routes.
Demo route shows current user email and role when logged in.
Implementation Notes
Keep auth provider pluggable: initially stub against a simple username/email login.
Wire to DATABASE_URL via prisma/drizzle or equivalent in later tickets.
Dependencies
INFRA-4 (DB wiring) for persistence.
WEB-3 — Build login/signup/logout flows
Repo: blackroad-os-web
Labels: pillar:os, ws:W1-core-app, layer:experience, env:dev, host:app.blackroad.io, atom:auth
Summary
Create basic login, signup, and logout flows to allow real users to access the workspace.
Acceptance Criteria
/login route with email + password or magic-link-style login.
/signup route with email + name and optional role selection.
Logout action available from global nav.
Auth failures show user-friendly error messages.
Implementation Notes
Back temporarily by a simple password-based auth; can be swapped for external IdP later.
Ensure secure cookie settings in production (HTTPOnly, Secure where applicable).
Dependencies
WEB-2 (user model + session abstraction).
INFRA-4 (DB wiring) for credential storage.
WEB-4 — Implement basic role system (teacher, student, creator, admin)
Repo: blackroad-os-web
Labels: pillar:os, ws:W1-core-app, layer:experience, env:dev, host:app.blackroad.io, atom:auth
Summary
Extend the user model with roles and expose simple role-based UI gating for verticals.
Acceptance Criteria
User.role supports at least: teacher, student, creator, admin.
Role is assigned at signup or via a simple admin-only screen.
Navigation selectively shows Education-only links to teachers/students.
Role-aware components have tests or storybook examples.
Implementation Notes
Represent roles as a string enum; do not over-design permissions yet.
Keep role changes admin-only to reduce complexity.
Dependencies
WEB-2, WEB-3.
INFRA-4 — Wire app to DB (migrations + connection)
Repo: blackroad-os-web
Labels: pillar:data, ws:W6-data, layer:infra, env:dev, host:app.blackroad.io, atom:db
Summary
Connect the web app to the Postgres instance at db.blackroad.systems and add initial migrations for the User table.
Acceptance Criteria
App connects to DB via DATABASE_URL env var.
Migration tooling added (Prisma/Drizzle/etc.).
User table created with fields required by WEB-2/WEB-3/WEB-4.
Local and Railway migrations documented.
Implementation Notes
Keep schema minimal; migrations should be idempotent.
Use a single migration entrypoint that can be run in Railway deploy hooks.
Dependencies
INFRA-3 (DB provisioned & reachable).
GOV-6 — Wire app actions to call 
policy/evaluate
Repo: blackroad-os-web
Labels: pillar:governance, ws:W2-governance, layer:experience, env:dev, host:app.blackroad.io, atom:api
Summary
Integrate the governance API by calling gov.api.blackroad.io/policy/evaluate for at least one privileged action (e.g., reviewing homework).
Acceptance Criteria
HTTP client abstraction for Cece governance calls (policy + ledger).
policy/evaluate invoked before the selected privileged action.
Deny decisions are surfaced in the UI with a human-readable message.
Implementation Notes
Keep the governance client in a dedicated module (e.g., lib/ceceClient.ts).
Log request/response IDs to allow later correlation in logs.
Dependencies
GOV-2, GOV-3 (governance API online).
GOV-7 — Wire app actions to send ledger events
Repo: blackroad-os-web
Labels: pillar:governance, ws:W2-governance, layer:experience, env:dev, host:app.blackroad.io, atom:api
Summary
For the same privileged action as GOV-6, emit a ledger event to gov.api.blackroad.io/ledger/event capturing actor, action, resource, and result.
Acceptance Criteria
Ledger client wrapper implemented and reused.
Events include intent_id (or temporary correlation id), actor, action, resource, timestamp.
Basic error handling and retry/backoff strategy documented.
Implementation Notes
Reuse same HTTP client abstraction as GOV-6.
For now, treat ledger failures as non-blocking but log prominently.
Dependencies
GOV-4 (ledger endpoint implemented).
EDU-2 — Implement teacher assignment creation UI
Repo: blackroad-os-web
Labels: pillar:education, ws:W4-verticals, layer:experience, env:dev, host:edu.blackroad.io, atom:ui
Summary
Provide a teacher-facing UI to create homework assignments, including title, description, due date, and assigned students.
Acceptance Criteria
Teachers see an Assignments section in the app when visiting edu.blackroad.io or the Education area.
New assignment form posts to backend API and persists records.
Errors are handled gracefully (validation + network).
Teacher can view a list of their assignments after creation.
Implementation Notes
Use existing layout shell; add an Education app section.
For v0, student assignment can be a simple multi-select of users with role=student.
Dependencies
EDU-1 (Assignment model), WEB-4 (roles), INFRA-9 (host-based routing).
EDU-3 — Implement student homework view and submission UI
Repo: blackroad-os-web
Labels: pillar:education, ws:W4-verticals, layer:experience, env:dev, host:homework.blackroad.io, atom:ui
Summary
Create a student-facing dashboard where students can see their assigned homework and submit responses.
Acceptance Criteria
Students logging into homework.blackroad.io see only their assignments.
Detail page shows assignment prompt and submission form.
Submitting homework creates a Submission record via API.
Implementation Notes
Keep content type simple (plain text) for v0; file uploads can be added later.
Reuse governance client hooks for later policy enforcement.
Dependencies
EDU-1, WEB-4, INFRA-9.
EDU-4 — Implement teacher review flow
Repo: blackroad-os-web
Labels: pillar:education, ws:W4-verticals, layer:experience, env:dev, host:edu.blackroad.io, atom:ui
Summary
Provide teachers with a way to review student submissions and mark them as reviewed (or similar status).
Acceptance Criteria
Teacher can see a list of submissions per assignment.
Teacher can open a submission, read content, and mark status (e.g., reviewed).
Review action triggers Cece policy + ledger calls.
Implementation Notes
Status values can be minimal: submitted, reviewed.
Instrument review action with governance clients from GOV-6/GOV-7.
Dependencies
EDU-1, EDU-3, GOV-6, GOV-7.
EDU-5 — Integrate AI assist into homework flow (v0.1)
Repo: blackroad-os-web
Labels: pillar:education, ws:W4-verticals, layer:experience, env:dev, host:homework.blackroad.io, atom:ai
Summary
Add a minimal AI-assisted hint feature to the student homework view using the existing model gateway.
Acceptance Criteria
Students can click a “Get hint” button on an assignment.
The app calls a placeholder model endpoint and displays a textual hint.
Governance policies for hint usage are logged (even if only informational at first).
Implementation Notes
Use a stub model endpoint initially (can be a simple rule-based response) behind a feature flag.
Log hint requests and responses for later tuning.
Dependencies
EDU-3, models infra (outside Epics 1–3 but stubbed).
INFRA-9 — Route vertical doors to Education pack
Repo: blackroad-os-web
Labels: pillar:education, ws:W4-verticals, layer:experience, env:dev, host:edu.blackroad.io, atom:routing
Summary
Implement host-based or path-based routing so that edu.blackroad.io and homework.blackroad.io render the Education experience in blackroad-os-web.
Acceptance Criteria
Requests to edu.blackroad.io render the teacher-oriented Education UI.
Requests to homework.blackroad.io render the student-oriented homework UI.
Local dev can simulate both hosts (e.g., via HOST_CONTEXT query param or hosts file).
Implementation Notes
Use next.config.js or middleware to infer host -> context.
Keep logic in a small routing helper for future verticals.
Dependencies
INFRA-1, INFRA-8 (DNS in place), EDU-2, EDU-3.
Repo: 
blackroad-os-infra
INFRA-1 — Create Cloudflare DNS record for 
app.blackroad.io
Repo: blackroad-os-infra
Labels: pillar:os, ws:W3-infra, layer:infra, env:prod, host:app.blackroad.io, atom:dns
Summary
Add a Cloudflare-managed DNS record for app.blackroad.io pointing at the Railway app service.
Acceptance Criteria
app.blackroad.io exists in Cloudflare as a CNAME/A pointing to the Railway hostname.
Proxy enabled for HTTP/S traffic.
Record exported into infra repo as CSV/TF/notes.
Implementation Notes
Use the CSV in section 2 as source of truth.
Consider Terraform or at least a markdown runbook for manual setup.
Dependencies
INFRA-2 (Railway app service created) or at least placeholder hostname.
INFRA-2 — Create Railway service for 
blackroad-os-web
Repo: blackroad-os-infra
Labels: pillar:os, ws:W3-infra, layer:infra, env:dev, host:app.blackroad.io, atom:railway
Summary
Provision a Railway service for blackroad-os-web and configure basic deployment.
Acceptance Criteria
Railway project and service exist for the web app.
Build & start commands configured and deploy successfully from main.
Key env vars (PORT, NODE_ENV, DATABASE_URL placeholder) configured.
Implementation Notes
Capture Railway project/service IDs in infra docs.
Wire deployment from GitHub main branch with minimal CI.
Dependencies
None (can be done in parallel with WEB-1).
INFRA-3 — Provision Postgres for 
db.blackroad.systems
Repo: blackroad-os-infra
Labels: pillar:data, ws:W6-data, layer:infra, env:dev, host:db.blackroad.systems, atom:db
Summary
Create a managed Postgres instance (Railway, Neon, or similar) and alias it as db.blackroad.systems.
Acceptance Criteria
Postgres instance created with appropriate size for dev/stg.
Connection details stored securely and mapped to DATABASE_URL in services.
DNS/alias for db.blackroad.systems configured (if applicable).
Implementation Notes
Reuse same instance for governance and app in v0 to keep cost low.
Document backup strategy, even if minimal.
Dependencies
None.
INFRA-5 — Create DNS record for 
gov.api.blackroad.io
Repo: blackroad-os-infra
Labels: pillar:governance, ws:W3-infra, layer:infra, env:prod, host:gov.api.blackroad.io, atom:dns
Summary
Add Cloudflare DNS for gov.api.blackroad.io pointing to the governance API Railway service.
Acceptance Criteria
CNAME/A record exists for gov.api.blackroad.io.
TLS/HTTPS working via Cloudflare.
Record documented in DNS CSV.
Dependencies
INFRA-6 (governance API service) or at least hostname.
INFRA-6 — Railway service for governance API
Repo: blackroad-os-infra
Labels: pillar:governance, ws:W3-infra, layer:infra, env:dev, host:gov.api.blackroad.io, atom:railway
Summary
Provision Railway service for blackroad-os-api (governance API) and configure deployment.
Acceptance Criteria
Service created with correct repo linkage.
Build & start commands configured and successful.
Env vars for DB, ledger storage, and CORS set.
Implementation Notes
Ensure gov.api.blackroad.io allowed in CORS for browser-based calls from app.blackroad.io.
Dependencies
INFRA-3 (DB), GOV-2 (API skeleton).
INFRA-7 — Create ledger schema in DB
Repo: blackroad-os-infra
Labels: pillar:governance, ws:W6-data, layer:infra, env:dev, host:ledger.blackroad.systems, atom:db
Summary
Add database schema/migrations for a ledger_events table used by the governance API.
Acceptance Criteria
Migration creates ledger_events with fields for ids, intent_id, actor, action, resource, decision, timestamp, metadata.
Governance API can write/read events.
Schema documented for Cece and analytics.
Dependencies
INFRA-3 (DB), GOV-4 (ledger endpoint design).
INFRA-8 — DNS for 
edu.blackroad.io
and 
homework.blackroad.io
Repo: blackroad-os-infra
Labels: pillar:education, ws:W3-infra, layer:infra, env:prod, host:edu.blackroad.io, atom:dns
Summary
Configure Cloudflare DNS so edu.blackroad.io and homework.blackroad.io route to the same web app service as app.blackroad.io.
Acceptance Criteria
edu.blackroad.io CNAME to app.blackroad.io or direct Railway hostname.
homework.blackroad.io CNAME similarly configured.
Records documented in DNS CSV.
Dependencies
INFRA-1, INFRA-2.
Repo: 
blackroad-os-docs
/ 
blackroad-os-master
GOV-1 — Define minimal user-related policy schema
Repo: blackroad-os-docs
Labels: pillar:governance, ws:W2-governance, layer:governance, env:dev, atom:docs
Summary
Capture a minimal policy schema for user access and governance evaluation, including how Cece represents subjects, actions, resources, and decisions.
Acceptance Criteria
Markdown doc describing policy object shape (subject, action, resource, condition, effect).
Examples for login/access, homework-review, and future expansion.
Alignment with policies.education.yaml structure.
Dependencies
None.
GOV-8 — Define education-specific policies
Repo: blackroad-os-docs
Labels: pillar:education, ws:W4-verticals, layer:governance, env:dev, atom:docs
Summary
Document the initial Cece policies governing the Education/RoadWork v0 flow (teacher-only creation, student-only submission, teacher-only review).
Acceptance Criteria
Markdown doc that describes each education policy in plain language.
Links to policies.education.yaml in infra/ops.
Clear mapping from roles/actions in the app to policy ids.
Dependencies
GOV-1, EDU-1..4.
Repo: 
blackroad-os-api
GOV-2 — Scaffold governance API service for 
gov.api.blackroad.io
Repo: blackroad-os-api
Labels: pillar:governance, ws:W2-governance, layer:governance, env:dev, host:gov.api.blackroad.io, atom:api
Summary
Create the basic FastAPI/Express (or similar) service that exposes GET /health and routes for policy evaluation and ledger events.
Acceptance Criteria
Service boots locally and on Railway.
/health returns status + build info.
Project structure includes clear separation for policy and ledger modules.
Dependencies
INFRA-6 (Railway service), GOV-1 (policy schema doc).
GOV-3 — Implement 
/policy/evaluate
endpoint
Repo: blackroad-os-api
Labels: pillar:governance, ws:W2-governance, layer:governance, env:dev, host:gov.api.blackroad.io, atom:api
Summary
Add a POST /policy/evaluate endpoint that accepts subject/action/resource/context and returns a simple allow/deny decision.
Acceptance Criteria
Request/response JSON schemas defined and validated.
Implementation supports at least allow/deny decisions and a policy_id reference.
Unit tests for happy path and basic error cases.
Dependencies
GOV-1.
GOV-4 — Implement 
/ledger/event
endpoint
Repo: blackroad-os-api
Labels: pillar:governance, ws:W2-governance, layer:governance, env:dev, host:gov.api.blackroad.io, atom:api
Summary
Add a POST /ledger/event endpoint that writes structured governance events to the ledger_events table.
Acceptance Criteria
Request schema defined and documented.
Events persisted in DB using migrations from INFRA-7.
Basic query endpoint or admin tool to inspect events.
Dependencies
INFRA-3, INFRA-7.
GOV-5 — Create minimal policy store
Repo: blackroad-os-api
Labels: pillar:governance, ws:W2-governance, layer:governance, env:dev, atom:policy
Summary
Implement a minimal policy store (in-DB table or static config) and helper for retrieving policies for a given scope.
Acceptance Criteria
Policy store abstraction implemented.
At least three policies loaded: one generic, two education-specific placeholder entries.
/policy/evaluate consults this store to make decisions.
Dependencies
GOV-1, GOV-3.
GOV-9 — Enforce education policies and log homework events
Repo: blackroad-os-api
Labels: pillar:education, ws:W4-verticals, layer:governance, env:dev, host:gov.api.blackroad.io, atom:policy
Summary
Implement backend-side enforcement of education policies for assignment creation, submission, and review, plus ledger logging.
Acceptance Criteria
Endpoints for assignment create/submit/review call internal policy evaluation.
Unauthorized attempts are rejected with clear error codes.
All education actions emit ledger events.
Dependencies
EDU-1, GOV-2..5, INFRA-7.
Repo: 
blackroad-os-pack-education
EDU-1 — Create homework domain model (Assignment, Submission)
Repo: blackroad-os-pack-education
Labels: pillar:education, ws:W4-verticals, layer:data, env:dev, atom:db
Summary
Define and migrate the core Education domain models: Assignment and Submission, plus related enums/relations.
Acceptance Criteria
DB migrations create assignments and submissions tables.
Models exposed in shared domain layer for use by web and API services.
Basic constraints enforced (e.g., assignment_id foreign key on submissions).
Dependencies
INFRA-3, INFRA-7 (for shared DB patterns).
EDU-5 — Backend support for AI hints
Repo: blackroad-os-pack-education
Labels: pillar:education, ws:W4-verticals, layer:backend, env:dev, atom:ai
Summary
Add backend endpoint(s) that accept a homework context and return an AI-generated hint (stubbed for v0.1).
Acceptance Criteria
POST /education/hints (or similar) accepts assignment + partial submission.
Uses a placeholder model client to generate text.
Requests and responses logged for observability.
Dependencies
EDU-1, model gateway (outside immediate epics; can be stubbed).
2. Cloudflare DNS CSV (Epics 1–3 v1)
Type,Name,Content,TTL,Proxied,Notes
CNAME,app.blackroad.io,app-web.railway.example.com,300,true,"Main multi-tenant app (Epic 1)"
CNAME,api.blackroad.io,api-gateway.railway.example.com,300,true,"Public HTTP API gateway"
CNAME,gov.api.blackroad.io,gov-api.railway.example.com,300,true,"Governance API service"
CNAME,ledger.blackroad.systems,gov-api.railway.example.com,300,false,"Ledger API alias (same service as gov.api for v0)"
CNAME,db.blackroad.systems,db-postgres.railway.internal,300,false,"Primary Postgres instance endpoint"
CNAME,edu.blackroad.io,app.blackroad.io,300,true,"Education vertical door (teacher UI)"
CNAME,homework.blackroad.io,app.blackroad.io,300,true,"Homework vertical door (student UI)"
CNAME,ws.blackroad.io,operator-ws.railway.example.com,300,true,"Reserved WebSocket hub (Cece/Operator; may be stub in Epics 1–3)"
CNAME,mesh.blackroad.network,mesh-operator.railway.example.com,300,true,"Reserved mesh entry for later agent work"
CNAME,pi.mesh.blackroad.network,pi-mesh.railway.example.com,300,true,"Reserved Pi mesh entry for later agent work"
CNAME,status.blackroad.io,statuspage.vendor.example.com,300,true,"Public status page"
Replace *.railway.example.com hostnames with actual Railway service hostnames when known.
3. Railway Services Matrix (Epics 1–3 Only)
Service name
Repo
Domain/host
Port
Build command
Start command
Required env vars
web-app
blackroad-os-web
app.blackroad.io (also edu/homework)
3000
npm install && npm run build
npm run start
PORT, NODE_ENV, DATABASE_URL, GOV_API_URL, LOG_LEVEL, NEXT_PUBLIC_BASE_URL
api-gateway
blackroad-os-api-gateway
api.blackroad.io
8080
npm install && npm run build
npm run start
PORT, CORE_INTERNAL_URL, GOV_API_URL, LOG_LEVEL, ALLOWED_ORIGINS
gov-api
blackroad-os-api
gov.api.blackroad.io
8000
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
PORT, DATABASE_URL, LEDGER_DB_URL, POLICY_STORE_PATH, LOG_LEVEL, CORS_ORIGINS
postgres-db
(managed Postgres)
db.blackroad.systems
5432
(managed)
(managed)
POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_PORT
Notes:
For v0, gov-api and ledger share the same DB instance as the app.
Operator/mesh services are intentionally not included here as they belong to later epics.
4. 
service_registry.yaml
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
5. 
policies.education.yaml
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
End of artifacts for Epics 1–3 v1.
