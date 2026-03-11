╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮
│ 🌐🛣 DOMAIN CARD · <DOMAIN_NAME>                           │
╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯

🧭 Overview
────────────────────────────────────────────────────────────
- Domain: `<DOMAIN_NAME>`
- Purpose: <what this domain is for>
- Owners (👥): <team / person>
- Environment(s): <env_prod / env_staging / etc.>


📡 Routing & Services
────────────────────────────────────────────────────────────

Primary Entry
- 🌐 Hostname: `<host or wildcard>` (e.g. `*.blackroad.io`)
- ⛅️ Edge: `<Cloudflare zone / worker>` (e.g. `blackroad-edge-router`)

Services Behind This Domain
- 🛰 <service_name_1> – <description>
  - Path(s): `/api/...`, `/auth/...`
  - Env: <env>
- 🛰 <service_name_2> – <description>
  - Path(s): `/`, `/dashboard`

Traffic Rules (🔀)
- Rule 1: `<condition>` → `<target>`
- Rule 2: `<condition>` → `<target>`


🧱 DNS Records
────────────────────────────────────────────────────────────

Code-ish view:

TYPE   NAME                 VALUE / TARGET                  TTL   NOTES
A      <name>               <ip or proxy>                   auto  <note>
AAAA   <name>               <ipv6 or proxy>                 auto  <note>
CNAME  <name>               <target.domain.com>             auto  <note>
TXT    <name>               <value>                         auto  <SPF/verification/etc.>

Human view:
- 🌐 Root (<DOMAIN_NAME>) → <target> (e.g. Cloudflare worker/pages)
- 🌐 *.subdomain → <target>
- 🔏 TLS: <Full/Strict/Flexible>

🧪 Verification & Health
────────────────────────────────────────────────────────────

Status
- DNS Resolution (🌐): ✅ / ⚠️ / ❌
- HTTPS (🔐): ✅ / ⚠️ / ❌
- Latency (⏱): ~<ms> global

How to Verify (🔍)
- DNS: dig <domain> / nslookup <domain>
- HTTPS: visit https://<domain> and check cert
- Worker: wrangler tail <worker> or health endpoint

Common Issues (🚨)
- Symptom: <issue> → Likely: <cause> → Fix: <action>

📚 Links
────────────────────────────────────────────────────────────
- Cloudflare zone: <URL>
- Worker / Pages config: <FILE>
- Related project: projects/<proj_name>/project.md
- Runbook: projects/<proj_name>/runbook.md

🎯 Next Steps
- <Step 1: e.g. "Enable HTTPS on staging subdomain">
- <Step 2: e.g. "Migrate root domain to new router">

💡 Tips
- <keep this domain's use narrow / don't mix X with Y>
- <DNS changes can take up to N minutes to propagate>
