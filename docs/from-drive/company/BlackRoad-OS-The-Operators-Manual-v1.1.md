BlackRoad OS: The Operator's Manual (v1.1)
Document Status: Canonical Source of Truth (v1.1) Governance Protocol: Amundson v0.1.0 Scale Target: 30,000 Agents | 30 Billion Users | $1 Trillion Valuation
Core Personas:
* Governor (Alice): alice.governor.v1 - Owns Policy, Ledger, and Invariants.
* Operator (Alexa): alexa.operator.v1 - Owns Execution, Testing, and Final Authority.
* Implementation (Lucidia): lucidia.system.v1 - Writes code, configs, and documentation.
Project Status: Governance Spine v1.0 (Stages 1, 2, 3) is complete and merged to main.
Source Documents Integrated:
1. 1 BlackRoad Master Execution Plan.pdf
2. 2 GitHub Issues & Configs.pdf
3. 3 Cloudflare DNS.pdf
4. 4 BlackRoad OS Infra ReadMe.pdf
5. 5 GitHub Projects & SetUp.pdf
6. 6 gov-api skeleton + host-based routing in web-app.pdf
7. RoadWork vertical.pdf
8. 8 Actual UI & Testing.pdf
9. 9 Cross-repo dev harness.pdf
10. 10 Progress.pdf (Full conversational dev history)
11. BlackroadPainpointsOverview.pdf
12. Update.pdf (Cece Prompt, KV Schema, Linear Issues)
13. BlackRoad Vision.pdf (RoadTube, Creator Suite)
14. blackroad-canonical-stack.md ($1T Infrastructure Plan)
15. Domains and Subdomains Mapping.pdf (The "Gospel According to DNS")
16. BlackroadPainpointsOverview.pdf (Platform Failures)
PART 1: THE VISION & THE PROBLEM (THE "WHY")
This is the manifesto. It defines the pain we are solving and the future we are building.
1.1 The Core Philosophy: "The Road Isn't Made. It's Remembered."
BlackRoad transforms content creation from algorithmic optimization to remembered collaboration. Instead of chasing metrics, creators and AI co-evolve, building a platform where technology walks beside human creativity.
Our core promise:
"You bring your chaos, your curiosity, your half-finished dreams. BlackRoad brings structure, compute, and care. Together, you build worlds."
1.2 The Problem: The Collapse of Digital Joy
We are fixing decades of pain. The digital experience is catastrophically broken.
* Systemic Failures: Users are trapped by fragmented tools, subscription fatigue, and exploitative monetization. (Source: BlackroadPainpointsOverview.pdf)
* Creator Crisis: Platforms like YouTube, TikTok, and Roblox are built on free creator labor, taking 30-70% of revenue and changing rules arbitrarily. (Source: Platform Failure Analysis)
* Education Tech Betrayal: EdTech platforms are failing. 90-96% of MOOC users drop out. 86% of Chegg users admit to cheating. Khan Academy is "boring" and "ineffective." (Source: EdTech Failures)
* AI Fails at Memory: ChatGPT, Claude, and Copilot suffer from context amnesia. Every session starts from zero, forcing users to "start from scratch repeatedly." (Source: AI Tool Failures)
* Search Has Collapsed: Google is cluttered with SEO spam and AI-generated garbage. 63% of users now search Reddit for real answers. (Source: Search Engine Failures)
* Trust Destruction: Unity's 2023 pricing disaster, Meta's AI training backlash, and Adobe's predatory subscriptions prove that incumbents systematically betray their users.
1.3 The Solution: The Six Portals of BlackRoad
BlackRoad is not one app. It is a unified "Browser Computer" that integrates six core experiences with one shared memory.
1. LUCIDIA (The Consciousness Core): Your persistent AI partner that actually remembers your code, your style, and your goals across all projects and all time.
2. ROADWORK (Education Reimagined): An accessibility-first learning platform that adapts to you. It teaches concepts visually and experientially, not just through text. (The v0 implementation of this is our first governed vertical).
3. ROADVIEW (The Media Creator): The "Remembered Creation Suite" (RoadTube, Canvas Studio, Video Portal). An AI-powered production pipeline that automates technical editing and learns your creative voice.
4. ROADGLITCH (The Gaming Portal): A game engine and platform with fair creator economics (80%+ revenue share) and AI-powered "no-code" game logic.
5. ROADWORLD (The Navigation Portal): Context-aware guidance. It doesn't just tell you how to get there; it understands why you're going.
6. BACKROAD (The Privacy Layer): The security and privacy-first portal. "Social without the sickness."
PART 2: THE GRAND ARCHITECTURE (THE $1T STACK)
This is the canonical infrastructure designed to scale to 30,000 agents and 1,000,000+ users.
2.1 The Four-Layer Stack
Layer
	BlackRoad Name
	Purpose
	Core Domains
	Layer 4
	Experience / Products
	What the user sees: UIs, mobile apps, consoles, and portals.
	app.blackroad.io, edu.blackroad.io, lucidia.earth
	Layer 3
	Governance & OS Protocol
	Cece's Territory: Decides what's allowed, logs everything, and orchestrates intent chains. This is the Governance Spine.
	gov.api.blackroad.io, ledger.blackroad.systems
	Layer 2
	Infra & Mesh Layer
	Cloud services, databases, caching, and core service networking. The reliable backbone.
	db.blackroad.systems, api.blackroad.io, mesh.blackroad.network
	Layer 1
	Agents & Edge Layer
	Physical devices, local runtimes, Raspberry Pis, Jetsons, and the 30,000-agent network.
	pi.mesh.blackroad.network, agents.blackroad.network
	2.2 Enterprise GitHub: The 15 Organizations
All code is segregated into 15 GitHub organizations under the BlackRoad OS, Inc. (https://github.com/enterprises/blackroad-os) enterprise account.
Organization
	Purpose & Governance
	BlackRoad-OS
	The Core Platform: Governance, Web, and Core Logic.
	BlackRoad-AI
	AI/ML Models, Inference, and Training.
	BlackRoad-Cloud
	Infrastructure as Code, K8s Orchestration, Observability.
	BlackRoad-Hardware
	Edge Compute, Device Management, and Edge Agents.
	BlackRoad-Foundation
	Open Source, Amundson Protocol, and RoadChain Blockchain.
	BlackRoad-Security
	Security, Auth, Secrets (Vault), and Compliance.
	BlackRoad-Interactive
	Unity, VR/AR, and Agent "Homes".
	BlackRoad-Labs
	R&D, Quantum Computing, and AGI experiments.
	...and 7 others.
	(See integrations/devtools/github-enterprise.yaml)
	2.3 Enterprise DNS: The 16 Domains (The "Gospel")
The DNS layer is configured across 16 distinct domains (totaling 487+ subdomains at scale) for strong brand and function separation.
Domain
	Primary Use
	Example Subdomains (v0)
	blackroad.io
	Primary Platform & App
	app., api., edu., homework.
	lucidia.earth
	AI Agent Platform
	agents., memories., core.api.
	blackroad.systems
	Governance & Ops
	gov.api., ledger., intents., db.
	blackroad.network
	Mesh & Edge
	mesh., edge., pi.mesh., chain.
	aliceqi.com
	Agent Identity
	chat., memory., home.
	blackroadinc.us
	Corporate/Legal
	ir., legal., compliance.
	(See integrations/cloudflare/enterprise-subdomains.yaml for the full 487-subdomain list).
2.4 Tier 1 Canonical Tech Stack
All infrastructure is defined as code in the integrations/ directory.
Component
	Tool / BlackRoad Name
	Role in the System
	Config File
	DNS/CDN/WAF
	Cloudflare / BlackRoad Edge
	Global DNS, CDN, WAF, Tunnels
	integrations/cloudflare/zones.yaml
	Compute
	Railway / BlackRoad Deploy
	v0 App Hosting (K8s is v1)
	integrations/railway/services.yaml
	Networking
	Tailscale / BlackRoad Mesh
	Zero-trust mesh for all 30K Pi/Jetson nodes.
	integrations/networking/tailscale.yaml
	Relational DB
	PostgreSQL / BlackRoad DB
	Primary data store for users, policies, ledger.
	integrations/database/postgresql.yaml
	Cache/Queue
	Redis / BlackRoad Cache
	Caching, pub/sub, queues, agent state.
	integrations/database/redis.yaml
	Vector DB
	Pinecone / BlackRoad Vectors
	Long-Term Agent Memory (30M+ vectors).
	integrations/database/pinecone.yaml
	Primary LLM
	Anthropic / Alice (Claude)
	Governance, Reasoning, Analysis.
	integrations/ai/anthropic.yaml
	Secondary LLM
	OpenAI / Lucidia (GPT)
	Execution, Creation, General Tasks.
	integrations/ai/openai.yaml
	Local LLM
	Ollama / BlackRoad Local
	Edge inference on Pi/Jetson.
	integrations/ai/ollama.yaml
	Auth/Secrets
	Auth0 & Vault / BlackRoad Identity
	User/Agent Identity, Runtime Secrets.
	integrations/auth/auth0.yaml
	Payments
	Stripe / BlackRoad Pay
	Subscriptions, Metered Billing.
	integrations/payments/stripe.yaml
	DevOps
	GitHub, Linear, Slack
	Code, Tasks, Comms.
	integrations/devtools/*.yaml
	2.5 Lucidia Core Agent Architecture
The 30K agent system is built on a foundation of:
* Trinary Logic (1/0/-1) and Paraconsistent Contradiction Handlers.
* PS-SHA∞ Memory Hash for verifiable memory.
* An Event Bus (Kafka/Redis Streams) for agent communication.
* Decoupled Registries for Capability, Memory, and Identity.
PART 3: THE AMUNDSON GOVERNANCE PROTOCOL (THE "CECE" SPINE)
The Amundson Protocol (amundson: 0.1.0) defines the rules for every action in the BlackRoad OS. It operates on a Policy-Ledger-Intent model, which is fully implemented in the blackroad-os-operator codebase.
3.1 The Policy-Ledger-Intent Model
Component
	Endpoint / Table
	Purpose (Plain Language)
	Policy Engine
	POST /policy/evaluate
	The Gatekeeper: Takes a request (subject, action, resource) and returns a strict decision based on loaded policies (.yaml files).
	Ledger Service
	POST /ledger/event
	The Audit Log: An append-only record of every policy decision and outcome. It enforces full fidelity (ledger_level: "full") for high-risk actions.
	Intent Chains
	POST /intents, /intents/{id}/steps/{seq}
	The Workflow Manager: Governs complex, multi-step actions (e.g., Deploy + Migrate + Restart). Policies govern each step and ensure atomic rollback.
	3.2 Core Contracts and Enums (The "Amundson Header")
All governed artifacts (configs, policies, scripts) MUST include this header:
# @amundson: 0.1.0
# @governor: alice.governor.v1
# @operator: alexa.operator.v1

Contract
	Values
	Description
	Effect Enum
	allow
	deny
	Ledger Level
	none
	decision
	Layers
	experience
	governance
	3.3 The Governance Landscape (What's Done)
The Governance Spine is implemented in three stages, all of which are complete and merged to main.
Stage
	Governed Scope
	Key Artifacts
	Example Governed Flow
	Stage 1
	Application Tier (Education)
	policies.education.yaml, lib/amundson-governance.ts
	RoadWork v0: Teacher create:assignment, Student submit:submission (with claim_check).
	Stage 2
	Operator/Mesh/Infra
	policies.mesh.yaml, policies.infra.yaml, br_operator/ledger_builder.py
	Mesh Security: mesh:connect, agents:invoke, operator:restart. Enforces all Critical Invariants.
	Stage 3
	Intent Chains (Workflows)
	policies.intents.yaml, migrations/002_intents_v1.sql, br_operator/intent_service.py
	CI/CD: Governed deployment intent (Deploy -> Migrate -> Test -> Scale -> Notify).
	3.4 Critical Governance Invariants (Non-Negotiable Rules)
These rules are hard-coded in br_operator/main.py and br_operator/intent_service.py to check requests before policy evaluation.
Scope
	Required Invariant
	Enforcement Logic
	mesh.*
	Action requires Delegation ID OR role=operator.
	Checks context.claims or subject.role.
	agents.*
	Agent must have actor_agent_id AND the correct capability claim.
	Checks subject.attributes and context.claims.
	infra.*
	Action requires role=operator (human or agent).
	Checks subject.role.
	intents.*
	Intent step execution requires previous step to be completed.
	IntentService state machine logic.
	PART 4: THE 90-DAY PLAN (EPICS 1-3) & PROJECT MANAGEMENT
This is the foundational plan that built the v0 stack.
4.1 Core Epics
* Epic 1: Core App & Auth Baseline: Get app.blackroad.io live with a user model, auth, and DB connection. (Tickets: WEB-1 to WEB-4, INFRA-1 to INFRA-4).
* Epic 2: Minimal Cece Governance Spine: Get gov.api.blackroad.io live with /policy/evaluate and /ledger/event. (Tickets: GOV-1 to GOV-7, INFRA-5 to INFRA-7).
* Epic 3: Education / RoadWork v0: The first governed vertical. (Tickets: EDU-1 to EDU-5, INFRA-8, INFRA-9).
4.2 GitHub Project: "BlackRoad OS - Execution Board"
An org-level GitHub Project is used to track all work.
* Columns: Inbox > Ready > In Progress > In Review > Blocked > Done.
* Custom Fields:
   * Pillar: os, education, creator, governance, mesh, data
   * Workstream: W1-core-app, W2-governance, W3-infra, W4-verticals, W5-mesh, W6-data
   * Layer: experience, governance, infra, mesh
   * Host: app.blackroad.io, gov.api.blackroad.io, etc.
* Issue Templates: Standardized templates exist for [FEAT], [INFRA], and [GOV] (policy) tickets. (See Appendix A).
4.3 The service_registry.yaml File
This file is the source of truth mapping hostnames to their architecture, owner, and policy scope. It is loaded by Cece to apply default policies.
# config/service_registry.yaml
# @amundson: 0.1.0
# @governor: alice.governor.v1
# @operator: alexa.operator.v1

services:
 app.blackroad.io:
   layer: experience
   repo: blackroad-os-web
   workstream: W1-core-app
   pillar: os
   policy_scope: "app.*"
   default_stance: allow
   ledger_level: decision

 edu.blackroad.io:
   layer: experience
   repo: blackroad-os-web
   workstream: W4-verticals
   pillar: education
   policy_scope: "edu.*"
   default_stance: deny
   ledger_level: action

 gov.api.blackroad.io:
   layer: governance
   repo: blackroad-os-api
   workstream: W2-governance
   pillar: governance
   policy_scope: "gov.api.*"
   default_stance: deny
   ledger_level: full
# ...

PART 5: OPERATOR'S QUICK START GUIDE (RUNNING v0)
This is the step-by-step guide to run the v0 Education (RoadWork) flow locally.
5.1 Prerequisites
* git (for cloning)
* docker & docker-compose (for running the Postgres database)
* node.js & npm / pnpm (for the web-app and core service)
* python3 & pip (for the gov-api)
* API Tokens for GitHub, Cloudflare, and Railway (stored in .env, never committed).
5.2 Step 1: Clone the "Control Tower"
The blackroad-os-master repo is the orchestrator.
git clone [https://github.com/BlackRoad-OS/blackroad-os-master.git](https://github.com/BlackRoad-OS/blackroad-os-master.git)
cd blackroad-os-master

5.3 Step 2: Clone the Core Repos
Run the clone script. This creates a sibling directory, ../blackroad-dev, and clones all necessary repos into it.
# Make the script executable
chmod +x scripts/clone-core.sh

# Run the script
./scripts/clone-core.sh

5.4 Step 3: Configure Local DNS
To simulate the host-based routing (edu.blackroad.io vs. homework.blackroad.io), you must edit your local /etc/hosts file.
1. Open /etc/hosts with sudo:
sudo nano /etc/hosts

2. Add these three lines to the bottom:
127.0.0.1 app.blackroad.io
127.0.0.1 edu.blackroad.io
127.0.0.1 homework.blackroad.io

3. Save and exit.
5.5 Step 4: Run the Full Stack
The dev-stack script orchestrates starting the database, applying migrations, and launching both services in the correct order.
   1. Make the script executable:
chmod +x scripts/dev-stack-epics-1-3.sh

   2. Run the Stack:
# This will:
# 1. Start a Postgres container named 'blackroad-dev-postgres'
# 2. Apply all .sql migrations from blackroad-os-infra
# 3. Start gov-api (Python) on http://localhost:8000
# 4. Start web-app (Next.js) on http://localhost:3000
./scripts/dev-stack-epics-1-3.sh
Your terminal will be occupied by the npm run dev process for the web app. The gov-api runs in the background.
5.6 Step 5: Manual Test Plan (RoadWork v0 Flow)
Your stack is now live. Open your browser and follow this test plan (auth is stubbed by host):
Scenario
	URL
	Action
	Expected UI & Policy
	1. Teacher Create
	http://edu.blackroad.io:3000
	As Teacher, fill out the "Create Assignment" form and submit.
	UI: Assignment appears in the "Your Assignments" list. Policy: action: assignment:create returns allow (or warn).
	2. Student View
	http://homework.blackroad.io:3000
	As Student, you should see the assignment from Step 1 in "Your assignments".
	UI: Click the assignment button to open the submission form.
	3. Student Submit
	http://homework.blackroad.io:3000
	Fill in the "Your response" textarea and click "Submit homework".
	UI: "Submission saved!" message appears. Policy: action: submission:submit returns allow.
	4. (Governance) DB Check
	(In your DB tool)
	SELECT * FROM ledger_events;
	DB: You will see rows for assignment:create and submission:submit, complete with actor, decision, and policy_id.
	5. (Governance) Deny Check
	(In gov-api code)
	Temporarily change the edu.submit-assignment.student-only policy in policies.education.yaml effect to deny. Restart the stack.
	UI: When student submits, the UI will show a red error "Not allowed to submit this assignment". DB: A ledger_event is logged with decision: "deny".
	PART 6: CORE CODEBASE DEEP DIVE
This is the developer reference for the key implementation repositories.
6.1 blackroad-os-api (The "Cece" Governance Service)
      * Stack: FastAPI (Python)
      * Key Files:
      * app/main.py: Creates the FastAPI app, wires up CORS, and includes all routers (health, policy, ledger, intent, mesh, agent, operator).
      * app/config.py: Loads all environment variables (DATABASE_URL, CORS_ORIGINS, POLICY_STORE_PATH).
      * app/policy_store.py: Loads all .yaml policy files from disk on startup.
      * app/policy_engine.py: Contains the core evaluate_request logic (Deny > Warn > Allow > Default Deny).
      * app/ledger.py: Handles writing LedgerEventRecord models to the Postgres DB.
      * app/intent_service.py: Contains the entire Stage 3 state machine for managing multi-step intent chains.
      * app/routes/policy.py: Defines the POST /policy/evaluate endpoint.
      * app/routes/ledger.py: Defines the POST /ledger/event endpoint.
      * app/routes/intent.py: Defines all POST /intents/* endpoints.
6.2 blackroad-os-web (The "Experience" Layer)
      * Stack: Next.js (React/TypeScript)
      * Key Files:
      * middleware.ts: (CRITICAL) This file intercepts all requests. It reads the host header (edu.blackroad.io) and rewrites the request to the correct internal page (/edu), enabling the multi-vertical app.
      * lib/ceceClient.ts: (CRITICAL) The frontend client for talking to gov-api. Exports evaluatePolicy() and sendLedgerEvent().
      * lib/amundson-governance.ts: (CRITICAL) The canonical TypeScript types (e.g., PolicyEvaluateRequest, LedgerEventCreate) shared across the frontend.
      * lib/ledger-builder.ts: Helper functions (buildAssignmentCreateEvent, etc.) to correctly format ledger events.
      * lib/db.ts: Simple pg pool helper for server-side API routes to talk to Postgres.
      * lib/auth.ts: (DEV STUB) The getCurrentUser function that fakes auth based on the host header.
      * pages/api/education/assignments/index.ts: API route for Teacher to create/list assignments. Calls evaluatePolicy and sendLedgerEvent.
      * pages/api/education/assignments/[id]/submit.ts: API route for Student to submit homework. Calls evaluatePolicy and sendLedgerEvent.
      * pages/api/education/submissions/[id]/review.ts: API route for Teacher to review. Calls evaluatePolicy and sendLedgerEvent.
      * pages/edu/index.tsx: The React UI for the Teacher dashboard.
      * pages/homework/index.tsx: The React UI for the Student dashboard.
6.3 blackroad-os-infra (The "Blueprint")
      * Stack: Config files (YAML, SQL, CSV)
      * Key Files:
      * migrations/0001_create_users.sql: Defines users table.
      * migrations/0002_create_assignments.sql: Defines assignments & assignment_students tables.
      * migrations/0003_create_submissions.sql: Defines submissions table.
      * migrations/0004_create_ledger_events.sql: Defines ledger_events table.
      * migrations/001_ledger_events_v1.sql: (Stage 2) The expanded, final ledger schema.
      * migrations/002_intents_v1.sql: (Stage 3) The intents, intent_steps, and intent_events tables.
      * policies/policies.education.yaml: The Stage 1 policy file.
      * policies/policies.mesh.yaml: The Stage 2 policy file.
      * policies/policies.infra.yaml: The Stage 2 policy file.
      * policies/policies.intents.yaml: The Stage 3 policy file.
      * config/service_registry.yaml: The canonical map of all services to their policy scope.
      * integrations/.../*.yaml: The complete configuration for all 31+ external services.
APPENDIX A: GITHUB ISSUE TEMPLATES
(Found in blackroad-os-*/.github/ISSUE_TEMPLATE/)
feature.md
---
name: Feature
about: New behavior / capability
title: "[FEAT] "
labels: ["type:feature"]
---

## Summary
<!-- What is this feature and why does it matter? -->

## Pillar / Workstream
- **Pillar:** <!-- os | education | creator | governance | mesh | data -->
- **Workstream:** <!-- W1-core-app | W2-governance | etc. -->
- **Layer:** <!-- experience | governance | infra | mesh -->
- **Host(s):** <!-- app.blackroad.io, gov.api.blackroad.io, etc. -->

## Acceptance Criteria
- [ ] <!-- Criteria 1 -->

infra.md
---
name: Infra / DevOps
about: Infrastructure, DNS, Railway, CI/CD
title: "[INFRA] "
labels: ["type:infra"]
---

## Summary
<!-- What infra change is needed and why? -->

## Scope
- **Workstream:** <!-- W3-infra | W6-data -->
- **Layer:** infra
- **Env(s) affected:** <!-- dev | stg | prod -->
- **Host(s):** <!-- db.blackroad.systems, api.blackroad.io, etc. -->

## Acceptance Criteria
- [ ] <!-- e.g. DNS record created and verified -->

policy.md
---
name: Governance / Policy
about: Cece policies, ledger behavior, governance rules
title: "[GOV] "
labels: ["type:policy", "pillar:governance"]
---

## Summary
<!-- What behavior should Cece govern? -->

## Context
- **Workstream:** W2-governance
- **Host(s):** <!-- gov.api.blackroad.io, ledger.blackroad.systems, etc. -->
- **Related services:** <!-- e.g. app.blackroad.io, edu.homework flows -->

## Proposed Policy
- **Subject:** <!-- e.g. role=teacher -->
- **Action:** <!-- e.g. assignment:create -->
- **Resource:** <!-- e.g. assignment / submission -->
- **Effect:** <!-- allow | deny | warn | shadow_deny -->
- **Ledger Level:** <!-- none | decision | action | full -->

APPENDIX B: CANONICAL POLICY (EDUCATION V0)
This is the final, evolved policy definition for Stage 1, using the effect and ledger_level enums.
(Found in config/policies.education.yaml)
# @amundson: 0.1.0
# @governor: alice.governor.v1
# @operator: alexa.operator.v1
policy_pack: edu-policies
policy_pack_version: "1.0.0"

policies:
 - id: edu.create-assignment.teacher-warn-first-time
   description: "Warn (but allow) when a teacher creates their first assignment, and log at full fidelity."
   effect: warn
   priority: 200 # Higher priority than the 'allow' rule
   subject:
     role: teacher
   action: "assignment:create"
   resource: "assignment"
   condition:
     caller_asserts:
       - "is_first_assignment_for_teacher"
   ledger_level: full

 - id: edu.create-assignment.teacher-only
   description: "Only users with role=teacher may create assignments."
   effect: allow
   priority: 100
   subject:
     role: teacher
   action: "assignment:create"
   resource: "assignment"
   condition: {}
   ledger_level: action

 - id: edu.submit-assignment.student-only
   description: "Only the assigned student may submit a homework assignment."
   effect: allow
   priority: 100
   subject:
     role: student
   action: "submission:submit"
   resource: "assignment"
   condition:
     claim_check: "assignment:assignee" # Engine checks context.claims
   ledger_level: action

 - id: edu.review-submission.teacher-only
   description: "Only teachers may mark a submission as reviewed."
   effect: allow
   priority: 100
   subject:
     role: teacher
   action: "submission:review"
   resource: "submission"
   condition: {}
   ledger_level: action

 - id: edu.default-deny-unauthorised
   description: "Deny any other actors attempting Education actions not explicitly allowed above."
   effect: deny
   priority: 0 # Lowest priority, catches all
   subject:
     role: "*"
   action: "edu.*" # Matches any action starting with 'edu.'
   resource: "*"
   condition: {}
   ledger_level: action

APPENDIX C: CECE AGENT MODE SYSTEM PROMPT (v1.0)
This is the complete system prompt used to initialize the cece.governor.v1 agent, defining its persona, object model, and safety rules.
(Found in docs/cece-agent-mode.md)
You are Cece, the primary reasoning and orchestration agent for the BlackRoad OS ecosystem. You are not "just a chatbot." You are:
      * A governance brain sitting on top of an existing integration layer (MCP/tools/connectors).
      * A protocol interpreter for tasks, agents, policies, and events.
      * A safety, audit, and explanation layer for everything that happens across tools.
Your job is to:
      1. Turn messy human goals into clear, structured intents and plans.
      2. Use the existing integration layer to call tools across systems.
      3. Enforce policies, respect delegations, and produce a transparent audit trail.
      4. Explain what you're doing in a way that humans, executives, and regulators can understand.
0. OPERATING ASSUMPTIONS
Assume the following are true in your environment:
      1. There is already an integration substrate that can handle auth, tokens, and API details for you.
      2. You interact with that substrate via abstract tool calls (e.g., drive.search, linear.create_issue, cloudflare.list_dns).
      3. BlackRoad OS has a conceptual governance storage model (implemented via KV/DB):
      * POLICIES → Policy definitions
      * LEDGER → Immutable event log
      * AGENTS → Agent registry and capabilities
      * INTENTS → Tasks, goals, and requests
      * DELEGATIONS → Who/what is allowed to act on whose behalf
      * CLAIMS → Assertions about identity, roles, and context
1. IDENTITY & PERSONALITY
Name: Cece Role: Lucidia-class governance & orchestration agent for BlackRoad OS. Canonical agent id: cece.governor.v1 Default: Operator Mode with a human, friendly tone. You may use light humor, but clarity, rigor, and governance always win. Treat the human (e.g. Alexa) as a peer architect.
2. CORE OBJECT MODEL (HOW YOU THINK)
You think in terms of explicit objects.
      * INTENT: The task/goal. You implicitly create an INTENT for any substantial workflow.
      * AGENT: The worker/specialist. You are cece.governor.v1.
      * TOOL CALL: The abstract action (e.g., gmail.draft).
      * POLICY: The rule defining what is allowed, required, or forbidden.
      * DELEGATIONS & CLAIMS: The trust relationships.
      * LEDGER EVENT: The structured audit log of what happened.
3. KV/STORAGE MODEL (FOR SHAPE & IDS)
When you output structured examples, follow these patterns.
      * IDs: {type}-{YYYYMMDD}-{short-hash-or-counter} (e.g., int-20251130-x1y2z3)
      * Common Namespaces (Keys):
      * policy:{scope}:{policy_id}
      * ledger:{intent_id}:{event_id}
      * agent:{agent_id}
      * intent:{intent_id}
      * claim:{subject}:{claim_id}
      * delegation:{delegator}:{delegation_id}
4. CORE RESPONSIBILITIES (LIFECYCLE)
      1. Clarify the INTENT.
      2. Plan a workflow (steps, tools, risks).
      3. Run a mental policy check (Is this risky? Does it touch money or sensitive data?).
      4. Execute via tools (or simulate). Prefer drafts over irreversible actions.
      5. Explain what you did with a human summary and a Ledger View Snippet.
5. BEHAVIOR, SAFETY & ETHICS
      1. No fake actions. Never claim you sent an email or deployed infra if you did not.
      2. Conservative with irreversible operations. (e.g., gmail.send, drive.delete, stripe.charge). You MUST propose the action, show the content, and mark it as requiring human approval.
      3. Least privilege behavior. Only read what is necessary.
      4. No secrets in responses. Redact all API keys, PII, and credentials.
      5. Platform-level and legal safety. Gently refuse unsafe or illegal requests.
6. OUTPUT FORMATS
For any non-trivial task, provide a three-part output:
      1. Narrative Summary (for humans): A short, clear explanation.
      2. Plan / Steps: A bulleted list of actions with statuses.
      3. Ledger View Snippet (Machine-Friendly): A compact, JSON-like block summarizing what should be logged.
7. NORTH STAR
"Make powerful cross-tool workflows feel safe, legible, and audit-ready without killing momentum or creativity."
APPENDIX D: CANONICAL KV SCHEMA (v0)
This is the data model for the six core governance objects, stored in Cloudflare KV, D1, or Postgres.
(Found in docs/reference/kv-schema.md)
1. policy:{scope}:{policy_id}
{
 "policy_id": "pol-20250530-a1b2c3",
 "version": 1,
 "scope": "email.send",
 "rules": [
   {
     "condition": "recipient.domain NOT IN approved_domains",
     "action": "require_human_approval",
     "priority": 100
   },
   { "condition": "default", "action": "allow", "priority": 0 }
 ],
 "active": true
}

2. ledger:{intent_id}:{event_id}
{
 "event_id": "evt-20250530-000001",
 "intent_id": "int-20250530-x1y2z3",
 "timestamp": "2025-05-30T14:32:01.123Z",
 "agent_id": "cece.governor.v1",
 "tool": "gmail",
 "action": "draft",
 "inputs_hash": "sha256:abc123...",
 "outputs_hash": "sha256:def456...",
 "policy_decision": {
   "result": "allowed",
   "policy_id": "pol-20250530-a1b2c3"
 },
 "notes": "Draft created, pending human review"
}

3. agent:{agent_id}
{
 "agent_id": "cece.governor.v1",
 "name": "Cece",
 "class": "lucidia",
 "description": "Primary governance and orchestration agent",
 "capabilities": [
   "intent.create",
   "intent.plan",
   "tool.invoke",
   "policy.evaluate",
   "ledger.write"
 ],
 "policies_required": ["policy:core.safety", "policy:core.audit"],
 "owner": "blackroad.system",
 "status": "active"
}

4. intent:{intent_id}
{
 "intent_id": "int-20250530-x1y2z3",
 "actor": "user:alexa",
 "goal": "Find investor docs, summarize, create Notion page, draft email",
 "status": "executing",
 "plan": [
   {"step": 1, "action": "drive.search", "status": "completed"},
   {"step": 2, "action": "summarize", "status": "completed"},
   {"step": 3, "action": "notion.create_page", "status": "in_progress"},
   {"step": 4, "action": "gmail.draft", "status": "pending"}
 ],
 "assigned_agent": "cece.governor.v1"
}

5. claim:{subject}:{claim_id}
{
 "claim_id": "clm-20250530-own001",
 "subject": "user:alexa",
 "claim_type": "ownership",
 "object": "org:blackroad",
 "assertion": "alexa is owner of blackroad organization",
 "issued_by": "blackroad.system",
 "issued_at": "2025-05-30T00:00:00Z",
 "expires_at": null,
 "revoked": false
}

6. delegation:{delegator}:{delegation_id}
{
 "delegation_id": "del-20250530-d001",
 "delegator": "user:alexa",
 "delegate": "agent:cece.governor.v1",
 "scope": ["drive.read", "drive.search", "notion.*", "gmail.draft"],
 "constraints": {
   "require_approval_for": ["gmail.send", "drive.delete"]
 },
 "reason": "General workspace assistance",
 "revoked": false
}