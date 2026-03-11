╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮
│ 🛣 <CTX_EMOJI> BLACKROAD OS · <SYSTEM / ARCH NAME>         │
╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯

🧭 Overview
────────────────────────────────────────────────────────────
<2–5 lines: What this system is, who it serves, and why it exists.>
Example:
- Serves: <who> (👤 / 👥)
- Core job: <what it does>
- Scope: <boundaries / what it is NOT>


🏗 High-Level System Diagram
────────────────────────────────────────────────────────────

                  👤 Users / Clients
                       │  (https)
                       ▼
╭────────────────────────────────────────────────────────────╮
│  ⛅️ Edge / Gateway (Cloudflare Workers / Router)           │
│  - Routing, auth checks, rate limiting                     │
╰───────────────┬─────────────────────────────┬──────────────╯
                │                             │
                ▼                             ▼
        🛰 Service A                     🛰 Service B
    (API / Unified API)             (Web / Pages / UI)
                │                             │
                └──────────────┬──────────────┘
                               ▼
                         🧱 Databases
                         📨 Queues
                         🗂 Storage (R2 / KV)

<Adjust the boxes/lines to match your exact topology.>


📦 Component Breakdown
────────────────────────────────────────────────────────────

⛅️ Edge / Gateway
- Type: <Worker / Router / CDN>
- Responsibilities:
  - <bullet 1>
  - <bullet 2>
- Key resources:
  - 📦 <artifact name>
  - 🔑 <secret / binding>
  - 🌐 <domains / routes>

🛰 Core Services
- Service A (🛰 <name>)
  - Purpose: <short description>
  - Interfaces: <HTTP/WS/queues/etc.>
  - Talks to: <DBs, queues, other services>
- Service B (🛰 <name>)
  - Purpose: ...
  - Interfaces: ...

🧱 Data Layer
- Databases (🧱)
  - <DB name> – <what it stores>, <scale expectations>
- Queues (📨)
  - <Queue name> – <what flows through it>
- Storage (🗂 / R2 / KV)
  - <Bucket / KV namespace> – <what lives here>

🧩 External Integrations
- Stripe (💳)
  - Used for: <billing/payments>
- Auth provider (🔐)
  - Used for: <authN/authZ>
- Other (🧩)
  - <Integration> – <role>


👉 Request / Data Flows
────────────────────────────────────────────────────────────

Flow 1 – User Request
1. 👤 User → 🌐 <domain> (e.g. https://...)
2. 🌐 DNS → ⛅️ Edge (Cloudflare)
3. ⛅️ Edge → 🛰 Service A (unified API)
4. 🛰 Service A → 🧱 DB / 📨 Queue / 🗂 Storage
5. Response travels back ⛅️ → 👤

Flow 2 – Background Processing
1. 🧱 DB / 📨 Queue event occurs
2. 🛰 Worker / cron picks it up
3. 🧠 Optional 🤖 AI/LLM processing
4. Results written to 🧱 / 🗂 / 📊

Flow 3 – Admin / Dashboards
1. 👩‍💻 Operator → 🖥 Dashboard
2. Dashboard calls ⛅️ Edge → 🛰 Admin API
3. Observability from 📊 Metrics / 🧾 Logs


🔐 Reliability, Security & Limits
────────────────────────────────────────────────────────────

Reliability
- Target: <e.g. 99.9% uptime>
- Single points of failure: <where and how mitigated>
- 🧯 Fallback / degradation strategy: <how it fails gracefully>

Security
- Auth (🔐): <how users/clients authenticate>
- Secrets (🔑): <where secrets are stored>
- Data protection: <encryption at rest / in transit>

Limits & Quotas
- Request limits: <Cloudflare free tier, etc.>
- Storage limits: <R2 / KV / D1 limits>
- Scaling behavior:
  - ⛅️ Edge: <auto / manual>
  - 🛰 Services: <horizontal/vertical>

(Reference to specific Cloudflare docs / constraints if relevant.)


🧰 Operations: Deploy, Observe, Debug
────────────────────────────────────────────────────────────

Deploy (🚀)
- Primary script / command:
  - `./<deploy-script>.sh`
- Manual steps (if any):
  - ☐ <step 1>
  - ☐ <step 2>

Observe (📊 / 🧾)
- Metrics (📊):
  - <link / command> – e.g. dashboard URL
- Logs (🧾):
  - `wrangler tail <worker-name>`
  - `<other log sources>`

Debug (🔍 / 🕵️)
- Common failure modes:
  - <symptom> → <likely cause> → <fix>
- Incident severity mapping (🚨):
  - <what counts as Sev1 / Sev2, etc.>


📚 Documentation & References
────────────────────────────────────────────────────────────

📚 System Docs
- Overview: <FILE_OR_URL>
- API Reference: <FILE_OR_URL>
- Runbooks: <FILE_OR_URL>

🗒 Checklists
- Deploy checklist: <FILE_OR_URL>
- Onboarding checklist: <FILE_OR_URL>

🎯 Next Steps
- <Step 1: what reader should do first>
- <Step 2: where to go deeper>
- <Step 3: optional advanced topic>

💡 Tips
- <Tip 1: e.g. "If X happens, check Y first">
- <Tip 2: e.g. "Prefer Z pattern when adding new services">
