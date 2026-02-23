Lmao ok relentless mode, let’s go. ⚙️
You now have:
Master plan
Epics 1–3 issues
Infra + DNS + Cece configs
Infra README
Next brick that makes all of this actually manageable is:
A GitHub Projects + labels + issue template setup doc…so Future Alexa and Future Cece don’t drown in chaos.
Here’s a drop-in file you can paste into Canvas and/or blackroad-os-master / blackroad-os-infra asGITHUB_PROJECT_SETUP.md.
# BlackRoad OS — GitHub Project & Issue Setup v1
> Goal: One coherent way to see **all work** across BlackRoad-OS repos  
> for Epics 1–3 (and beyond) without losing your mind.
This guide defines:
- The **main GitHub Project board** structure.
- A **label taxonomy** shared across repos.
- **Issue templates** to keep everything structured.
- Example **views/filters** you can set up in the Project.
---
## 1. Project: “BlackRoad OS — Execution Board”
Create a single GitHub Project (beta) at the **org level**:
**Name:** `BlackRoad OS — Execution Board`  
**Type:** Table/Board
This Project will track issues from (at minimum):
- `BlackRoad-OS/blackroad-os-web`
- `BlackRoad-OS/blackroad-os-api`
- `BlackRoad-OS/blackroad-os-api-gateway`
- `BlackRoad-OS/blackroad-os-infra`
- `BlackRoad-OS/blackroad-os-pack-education`
- `BlackRoad-OS/blackroad-os-docs`
- (Later) other packs and operator repos
---
## 2. Project Fields
Add these **custom fields** to the Project.
### 2.1 Single-select fields
1. **Pillar**
- `os`
- `education`
- `creator`
- `governance`
- `mesh`
- `data`
2. **Workstream**
- `W1-core-app`
- `W2-governance`
- `W3-infra`
- `W4-verticals`
- `W5-mesh`
- `W6-data`
3. **Layer**
- `experience`
- `governance`
- `infra`
- `mesh`
4. **Env**
- `local`
- `dev`
- `stg`
- `prod`
5. **Type**
- `feature`
- `bug`
- `infra`
- `policy`
- `docs`
- `chore`
6. **Effort**
- `S`
- `M`
- `L`
### 2.2 Text fields
7. **Host**
- Free-text for main hostname(s).
- Example: `app.blackroad.io`, `gov.api.blackroad.io`, `db.blackroad.systems`.
8. **Epic**
- Name or ID of the epic (e.g., `Epic 1 - Core App & Auth`, `Epic 3 - Education v0`).
---
## 3. Board Columns
Use these **project status columns**:
- `Inbox` — new/untriaged issues
- `Ready` — refined, accepted, ready to work
- `In Progress` — actively being done
- `In Review` — PR open / testing / verification
- `Blocked` — waiting on dependency
- `Done` — shipped & verified
You can use the built-in `Status` field or a custom one; just align column names with the statuses.
---
## 4. Label Schema (for Issues)
On each repo, create labels like this:
### 4.1 Pillar labels
- `pillar:os`
- `pillar:education`
- `pillar:creator`
- `pillar:governance`
- `pillar:mesh`
- `pillar:data`
### 4.2 Workstream labels
- `ws:W1-core-app`
- `ws:W2-governance`
- `ws:W3-infra`
- `ws:W4-verticals`
- `ws:W5-mesh`
- `ws:W6-data`
### 4.3 Layer labels
- `layer:experience`
- `layer:governance`
- `layer:infra`
- `layer:mesh`
### 4.4 Env labels
- `env:local`
- `env:dev`
- `env:stg`
- `env:prod`
### 4.5 Host labels
Optional but useful for searching:
- `host:app.blackroad.io`
- `host:api.blackroad.io`
- `host:gov.api.blackroad.io`
- `host:db.blackroad.systems`
- `host:edu.blackroad.io`
- `host:homework.blackroad.io`
- `host:mesh.blackroad.network`
- etc.
### 4.6 Atom / “what kind of work is this” labels
- `atom:ui`
- `atom:api`
- `atom:db`
- `atom:dns`
- `atom:railway`
- `atom:policy`
- `atom:docs`
- `atom:ai`
- `atom:routing`
You don’t HAVE to use these on every issue, but they make filtering delicious later.
---
## 5. Issue Templates
Create these under each repo in `.github/ISSUE_TEMPLATE/`.
### 5.1 Feature issue template
File: `.github/ISSUE_TEMPLATE/feature.md`
```markdown
---
name: Feature
about: New behavior / capability
title: "[FEAT] "
labels: ["type:feature"]
assignees: []
---
## Summary
<!-- What is this feature and why does it matter? -->
## Pillar / Workstream
- **Pillar:** <!-- os / education / creator / governance / mesh / data -->
- **Workstream:** <!-- W1-core-app / W2-governance / etc. -->
- **Layer:** <!-- experience / governance / infra / mesh -->
- **Env:** <!-- dev / stg / prod (target) -->
- **Host(s):** <!-- app.blackroad.io, gov.api.blackroad.io, etc. -->
## Acceptance Criteria
- [ ] <!-- Criteria 1 -->
- [ ] <!-- Criteria 2 -->
- [ ] <!-- Criteria 3 -->
## Implementation Notes
<!-- Optional: technical sketch, relevant files, endpoints, diagrams -->
## Dependencies
- [ ] <!-- Link to prerequisite issue/PR -->
When you paste the Epics 1–3 issues we generated, you can quickly map each into this template style.
5.2 Infra issue template
File: .github/ISSUE_TEMPLATE/infra.md
---
name: Infra / DevOps
about: Infrastructure, DNS, Railway, CI/CD
title: "[INFRA] "
labels: ["type:infra"]
assignees: []
---
## Summary
<!-- What infra change is needed and why? -->
## Scope
- **Pillar:** <!-- os / education / governance / mesh / data (often data/infra) -->
- **Workstream:** <!-- usually W3-infra or W6-data -->
- **Layer:** infra
- **Env(s) affected:** <!-- dev / stg / prod -->
- **Host(s):** <!-- db.blackroad.systems, api.blackroad.io, etc. -->
## Acceptance Criteria
- [ ] <!-- e.g. DNS record created and verified -->
- [ ] <!-- e.g. Railway service deployed and healthy -->
- [ ] <!-- e.g. logs visible in chosen tool -->
## Implementation Notes
<!-- Commands, dashboards, credentials locations (never put actual secrets here) -->
## Dependencies
- [ ] <!-- Upstream services or config -->
5.3 Governance / Policy issue template
File: .github/ISSUE_TEMPLATE/policy.md
---
name: Governance / Policy
about: Cece policies, ledger behavior, governance rules
title: "[GOV] "
labels: ["type:policy", "pillar:governance"]
assignees: []
---
## Summary
<!-- What behavior should Cece govern? -->
## Context
- **Layer:** governance
- **Workstream:** W2-governance
- **Host(s):** <!-- gov.api.blackroad.io, ledger.blackroad.systems, etc. -->
- **Related services:** <!-- e.g. app.blackroad.io, edu.homework flows -->
## Proposed Policy
- **Subject:** <!-- e.g. role=teacher -->
- **Action:** <!-- e.g. assignment:create -->
- **Resource:** <!-- e.g. assignment / submission -->
- **Effect:** <!-- allow / deny -->
- **Requires ledger event?** <!-- true/false -->
## Acceptance Criteria
- [ ] Policy is documented in `policies.*.yaml`.
- [ ] Policy is loaded and used by `gov-api`.
- [ ] App behavior reflects the policy (blocked/allowed).
- [ ] Ledger events written and visible in DB/logs.
## Dependencies
- [ ] <!-- Domain model exists? (Assignment, Submission, etc.) -->
6. Project Views (so you can actually use this thing)
Set up a few saved views in the Project.
6.1 “Quarter Focus (Epics 1–3)”
Filter:
Epic = Epic 1 - Core App & Auth OR Epic 2 - Cece Spine OR Epic 3 - Education v0
Sort by: Status, then Workstream
Use Board view grouped by Status.
6.2 “Education / RoadWork Only”
Filter:
Pillar = education
Optional extra:
Host contains edu.blackroad.io OR homework.blackroad.io
Use Table or Board view.
6.3 “Governance / Cece Only”
Filter:
Pillar = governance
or
Workstream = W2-governance
Use Table view with columns:
Title
Status
Host
Type
Env
6.4 “Infra Health”
Filter:
Workstream in (W3-infra, W6-data)
View:
Table, show:
Title
Host
Env
Status
Pillar
This becomes your “what infra is broken / in progress” radar.
7. Workflow Recommendations
7.1 Creating new issues
Always set:
Pillar
Workstream
Layer
Env
Type
Host (if known)
Use the Feature, Infra, or Policy template where applicable.
7.2 Weekly
Filter for:
Status != Done
Epic in (1,2,3)
Move:
3–7 issues into Ready → your weekly focus.
Keep “Locked In” work small enough you can move it in 7 days.
7.3 Daily
Start day: open Quarter Focus view.
Pull one issue from Ready to In Progress.
End day: move it to In Review or Done and write a 1–2 sentence comment.
This gives you:
A single pane of glass across repos.
Consistent labels so Cece (and future automation) can filter and reason.
Templates so everything created in a hurry is still structured.
Once this is in GitHub, the next “Next!” can be:we generate small helper scripts (like project_sync.py or label_bootstrap.sh) or we start stubbing actual code for gov-api / blackroad-os-web according to the epics.
If you want the next brick to be actual code skeletons (FastAPI gov-api + Next.js host routing for edu/homework), just say:
“Next: code skeletons for gov-api and host-based routing in web-app”
and I’ll go full builder mode.
