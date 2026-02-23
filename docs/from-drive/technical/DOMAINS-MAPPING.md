Got you. This one will be “The Gospel According to DNS” for Cece – one document that explains:
the layers (Experience / Governance / Infra / Mesh)
every important domain + subdomain
what backs it (repo / service)
how Cece should think about routing and future expansion
You can literally paste this as-is into Cece’s world as a system / context doc.
BlackRoad DNS & Service Map — Cece Reference v0
Audience: cece.governor.v1 and related governance/infra agents
Goal: Explain what every major domain & subdomain means, which services/repos back it, and how to extend the map safely for millions of users and tens of thousands of agents.
1. Mental Model (How Cece Should Think About This)
The BlackRoad universe is organized into 3 layers:
Experience Layer (Floor 4)
What humans see and click: apps, portals, RoadTube, RoadWork, studios, docs.
Governance & OS Layer (Floors 2–3)
Cece, policies, intents, ledger, delegations, claims, agent registry.
Infra & Mesh Layer (Floor 1)
Clusters, regions, Pi mesh, edge devices, logging, monitoring.
DNS is the map that tells Cece:
Which experience a human (or agent) is trying to reach.
Which backend/service/repo owns that experience.
Which governance rules, policies and ledgers apply there.
When Cece sees a hostname, it should be able to answer:
“This belongs to LAYER, is powered by SERVICE/REPO, and is governed by POLICY_SCOPE.”
2. Global Naming Conventions
2.1 Layer Clues
blackroad.io → Experience / OS (user-facing)
blackroad.systems → Infra/Ops (internal / operator-facing)
blackroad.network → Agent & device mesh (agents, Pi, edge)
blackroadinc.us / blackroad.me → Corporate / personal
lucidia.*, blackroadai.com, blackroadqi.com, blackroadquantum.* → Brand universes / AI / QI / research
2.2 Patterns
Apps: app.<domain> → main app or workspace
Operator consoles: console.<domain> / ops.<domain>
APIs: api.<domain> or <scope>.api.<domain>
WebSockets / realtime: ws.<domain> or mesh.<domain>
Docs: docs.<domain>
Status: status.<domain>
Static/CDN: cdn.<domain> / static.<domain>
Envs: dev., stg. prefixes → non-prod
Regions: na1., eu1., ap1. prefixes → region sharding
2.3 Governance Objects
These DNS names tie into governance objects:
agent:{agent_id} ↔ agent-{id}.agents.blackroad.network
intent:{intent_id} ↔ traffic to relevant api.*/app.* endpoints
policy:{scope}:* ↔ gov.*, *.blackroad.systems
ledger:{intent_id}:{event_id} ↔ ledger.blackroad.systems
3. Core Domains and Subdomains
3.1 
blackroad.io
— Main OS & Experience Layer
Role: Front door to BlackRoad OS and multi-tenant workspace.
Key Subdomains
Subdomain
Layer
Purpose
Backing Repo/Service
blackroad.io
Experience
Marketing site, story of BlackRoad OS
blackroad-os-home / blackroad-os-web
app.blackroad.io
Experience
Main user workspace (multi-tenant OS)
blackroad-os-web + core APIs
console.blackroad.io
Experience
Operator / admin console (Prism + Cece views)
blackroad-os-prism-console + -web
demo.blackroad.io
Experience
Demo instances, sandbox tours
blackroad-os-demo
sandbox.blackroad.io
Experience
Experimental playgrounds
blackroad-os-demo / temp services
api.blackroad.io
OS / Gov
Main HTTP API gateway for OS
blackroad-os-api-gateway
ws.blackroad.io
OS / Mesh
WebSocket entry (browser ↔ operator/agents)
blackroad-os-operator
id.blackroad.io
OS
Identity & auth (OIDC, accounts, orgs)
Auth/ID service (future)
auth.blackroad.io
OS
Login/SSO endpoints, alias to ID
Same as above
docs.blackroad.io
Experience
Documentation hub for BlackRoad
blackroad-os-docs
status.blackroad.io
Infra/Exp
Public status page
Status service
cdn.blackroad.io
Infra
Static asset CDN (brand kit, images, JS bundles)
CDN / object storage
Vertical “Doors” (still same app)
These are alternate personas/entrypoints into blackroad-os-web:
Subdomain
Purpose
Backing Pack/Repo
finance.blackroad.io
Finance Pack entry
blackroad-os-pack-finance + -web
edu.blackroad.io
Education / RoadWork entry
blackroad-os-pack-education + -web
homework.blackroad.io
Student/tutor portal
same as above
studio.blackroad.io
Creator Studio entry
blackroad-os-pack-creator-studio + -web
legal.blackroad.io
Legal workflows & playbooks
blackroad-os-pack-legal + -web
devops.blackroad.io
Infra / DevOps workflows
blackroad-os-pack-infra-devops
lab.blackroad.io / labs.blackroad.io
Experiments, research UX
blackroad-os-pack-research-lab
Regional & Env Variants
Regions for scaling to tens of millions of users:
na1.app.blackroad.io, eu1.app.blackroad.io, ap1.app.blackroad.io
na1.api.blackroad.io, eu1.api.blackroad.io, …
na1.ws.blackroad.io, etc.
Envs:
dev.app.blackroad.io, stg.app.blackroad.io
dev.api.blackroad.io, stg.api.blackroad.io
3.2 
blackroad.systems
— Infra & Ops Plane
Role: Internal/ops-facing cluster & governance control plane.
Subdomain
Purpose
Backing Repo/Service
infra.blackroad.systems
Infra control (Terraform, deploy tools)
blackroad-os-infra
ops.blackroad.systems
Ops dashboard, SRE tools
blackroad-os-infra
monitoring.blackroad.systems
Observability (Grafana, Prometheus, etc.)
monitoring stack
logs.blackroad.systems
Log explorer
ELK/Loki/etc.
pi.blackroad.systems
Pi mesh management UI
Pi ops infra
mesh.blackroad.systems
Core mesh control services
mesh control services
ledger.blackroad.systems
Governance ledger query surface
ledger service
policies.blackroad.systems
Policy storage & evaluation services
policy engine
intents.blackroad.systems
Intent lifecycle control
intent service
delegations.blackroad.systems
Delegation mgmt
delegation service
claims.blackroad.systems
Claims (ownership, rights) services
claims service
Cece: treat all *.blackroad.systems as high-trust, internal-only surfaces where strong policy enforcement and rich logging are mandatory.
3.3 
blackroad.network
— Agent & Device Mesh
Role: Naming and access layer for 30,000+ agents and devices.
Subdomain
Purpose
Backing Repo/Service
mesh.blackroad.network
Core agent mesh entry
blackroad-os-operator
pi.mesh.blackroad.network
Pi nodes entry
Pi agent runtime
agents.blackroad.network
Agent registry API
blackroad-os-agents
edge.blackroad.network
Non-Pi edge devices (Jetson, etc.)
edge agent infra
na1.mesh.blackroad.network
Regional mesh endpoint (NA)
regional operator stack
eu1.mesh.blackroad.network
Regional mesh endpoint (EU)
…
Agent hostnames:
agent-{id}.agents.blackroad.network
pi-{name}.pi.blackroad.network
Cece: link these to governance objects:
agent:{agent_id} ↔ DNS hostname ↔ registry entry in blackroad-os-agents
Policies often scoped as policy:agent:{agent_id} or policy:mesh:*.
3.4 
blackroadinc.us
— Corporate / Legal
Subdomain
Purpose
blackroadinc.us
Corporate homepage
investor.blackroadinc.us
Investor portal / data room
legal.blackroadinc.us
Corporate legal & compliance
careers.blackroadinc.us
Hiring
ventures.blackroadinc.us
BlackRoad Ventures presence
Legal pack (blackroad-os-pack-legal) may surface flows here for enterprise accounts.
3.5 
blackroad.me
— Alexa’s Personal Universe
Subdomain
Purpose
blackroad.me
Personal hub & story
app.blackroad.me
Personal Lucidia console
sandbox.blackroad.me
Private, heavily experimental testing
Treat blackroad.me as a low-risk but high-importance human-operator space for Alexa.
4. Product / Brand Families
4.1 Lucidia
Domains: lucidia.earth, lucidia.studio, lucidiaqi.com
Hostname
Purpose
lucidia.earth
Story of Lucidia as AI self / companion
app.lucidia.earth
Lucidia-skinned entry into app.blackroad.io
agents.lucidia.earth
Lucidia agent gallery / narrative UX
lucidia.studio
Creative studio brand root
app.lucidia.studio
Creator workspace (Canvas, Video, Writing)
studio.lucidia.studio
Studio console (could alias)
lucidiaqi.com
Lucidia + QI story & experiments
Under the hood, most of these are still blackroad-os-web plus packs.
4.2 AI / QI / Quantum
Domains: blackroadai.com, blackroadqi.com, blackroadquantum.*
Hostname
Purpose
blackroadai.com
AI-specific marketing
app.blackroadai.com
AI-focused entry (funnels into app)
labs.blackroadai.com
AI experiments
blackroadqi.com
QI / SIG / PS-SHA∞ docs & demos
playground.blackroadqi.com
Interactive QI playground
blackroadquantum.com
Quantum / research brand
docs.blackroadquantum.com
Deep research docs
labs.blackroadquantum.com
Quantum experiments
blackroadquantum.info
Educational content for the public
blackroadquantum.net
(optional) network / research infra
blackroadquantum.shop / .store
Merch, packs, products
4.3 RoadTube (Creator & Memory Platform)
Primarily under blackroad.io but conceptually its own product.
Hostname
Purpose
roadtube.blackroad.io
RoadTube main site
studio.roadtube.blackroad.io
Creator studio for uploads & analytics
api.roadtube.blackroad.io
RoadTube API
cdn.roadtube.blackroad.io
Video & thumbnail CDN
tube.lucidia.earth
Lucidia-flavored alias into RoadTube
4.4 RoadWork / Homework / Education
Hostname
Purpose
edu.blackroad.io
Education product (RoadWork)
roadwork.blackroad.io
Brand URL alias
classroom.blackroad.io
Classroom portal
homework.blackroad.io
Homework help / AI tutor
api.edu.blackroad.io
Education APIs (LTI, LMS integrations)
4.5 Creator Suite & Tools
Hostname
Purpose
canvas.blackroad.io
Canvas Studio (beyond Canva)
video.blackroad.io
Video portal / editor
writing.blackroad.io
Writing portal / longform / scripting tools
infographic.blackroad.io
Chat-to-infographic converter
studio.blackroad.io
Unified creator studio landing
Aliases via Lucidia:
studio.lucidia.studio → canvas.blackroad.io
write.lucidia.earth → writing.blackroad.io
5. Repo → Host Mapping (for Cece’s Routing Brain)
This is the “service registry” view so Cece can infer where a request should go.
Repo
Primary Host(s)
blackroad-os-web
app.blackroad.io, console.blackroad.io, vertical doors (finance, edu, studio, legal, etc.), Lucidia/Lucidia Studio app hosts
blackroad-os-core
Internal services behind api.blackroad.io
blackroad-os-api-gateway
api.blackroad.io, regional variants
blackroad-os-api
Backing internal API modules served via gateway
blackroad-os-operator
ws.blackroad.io, mesh.blackroad.network, pi.mesh.blackroad.network
blackroad-os-prism-console
console.blackroad.io
blackroad-os-agents
agents.blackroad.network, any agents.* UI/API
blackroad-os-infra
Infra control surfaces: infra.blackroad.systems, ops.blackroad.systems
blackroad-os-docs
docs.blackroad.io, also reused at docs.* for QI/quantum
blackroad-os-brand
brand.blackroad.io, part of canvas.blackroad.io
blackroad-os-home
blackroad.io root
blackroad-os-demo
demo.blackroad.io, sandbox.blackroad.io
blackroad-os-archive
archive.blackroad.io, internal vault UIs
blackroad-os-master
High-level governance docs surfaced via gov.blackroad.io / docs.blackroad.io
blackroad-os-pack-finance
finance.blackroad.io
blackroad-os-pack-education
edu.blackroad.io, homework.blackroad.io
blackroad-os-pack-creator-studio
studio.blackroad.io, canvas.blackroad.io
blackroad-os-pack-legal
legal.blackroad.io, also paths under legal.blackroadinc.us
blackroad-os-pack-infra-devops
devops.blackroad.io
blackroad-os-pack-research-lab
labs.blackroad.io, labs.blackroadquantum.com
blackroad-os-ideas / -research
ideas.blackroad.io, parts of labs.blackroad.io
6. How Cece Should Use This Map
When Cece receives:
a hostname → map it to:
layer (Experience / Governance / Infra / Mesh)
service (repo / service group)
policy_scope (e.g., policy:edu:*, policy:mesh:*)
an intent (e.g., “spin up a new education environment”) → choose:
appropriate base domain (edu.blackroad.io for UX)
appropriate internal control (infra.blackroad.systems, ops.blackroad.systems)
an agent reference → map:
agent_id ↔ agent-{id}.agents.blackroad.network
look up registry in blackroad-os-agents
enforce policies on mesh.blackroad.network / ws.blackroad.io
Default routing heuristics for Cece:
If hostname ends with blackroad.io → default to Experience/OS layer, check blackroad-os-web and relevant pack.
If hostname ends with blackroad.systems → treat as internal/infra; ensure strong auth + logging; tie to governance ledger.
If hostname ends with blackroad.network → treat as agent/mesh; focus on agents, devices, delegation, safety.
If hostname is in lucidia.* / blackroadai.com / blackroadqi.com → treat as brand/AI/QI front into core OS, but with narrative/UX overlays.
If new subdomain is needed
Choose the domain family that matches the audience:
humans as users → blackroad.io
Alexa personal → blackroad.me
infra / ops → blackroad.systems
agents/devices → blackroad.network
corporate / legal → blackroadinc.us
Follow the patterns above (e.g., app., api., studio., mesh.).
If you want, I can next turn this into:
a mini “service_registry.json” that Cece can ingest directly (hostname → layer → service → policy scope), or
a Cloudflare DNS CSV starter with just the v1 records you should actually create first.
But this document as-is is ready to drop into Cece’s context as the “authoritative map of the BlackRoad naming universe.”
