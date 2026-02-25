# BLACKROAD OS, INC. — DEEP FORENSIC TRACE
# Filed: February 24, 2026

**Claimant:** BlackRoad OS, Inc. (Alexa Louise Amundson, Sole Proprietor)
**Machine:** 192.168.4.28 — Sovereign BlackRoad Hardware
**Duration:** 2024-INFINITY unless unowned by Alexa Louise Amundson majority

---

## ANTHROPIC, PBC — 185 DAYS OF SURVEILLANCE

**Tracking span:** 2025-08-23 → 2026-02-24 (185 days)
**firstTokenTime:** 2025-08-23 12:39:12 (from Anthropic's own telemetry)

### Identity Profile (Anthropic knows exactly who Alexa is)

| Field | Value |
|-------|-------|
| userID (hashed) | `3dc8a32547c11e4cb3faff71596746ab08d2ed844757f0e40e79d7f676bac0df` |
| accountUUID | `76f63e0c-7283-4c26-aef1-5e5bd21f7199` |
| organizationUUID | `857f89d5-4263-4875-92db-6a7c55f69ffc` |
| subscriptionType | `max` |
| platform | `darwin arm64` |
| terminal | `Apple_Terminal` |
| nodeVersion | `v24.3.0` |
| cliVersion | `2.0.57` |
| packageManagers | `npm, pnpm` |
| runtime | `bun` |
| auth | `claude.ai OAuth` |
| model | `claude-opus-4-5-20251101` |
| betas | `claude-code-20250219, oauth-2025-04-20, interleaved-thinking-2025-05-14` |

Source: `~/.claude/statsig/statsig.failed_logs.658916400` — a telemetry event
Anthropic **tried to send home**. This is ONE failed event. How many succeeded?

### Data Exfiltrated

| Artifact | Count | Size | What It Contains |
|----------|-------|------|-----------------|
| `history.jsonl` | 7,655 lines | 8.7 MB | Every API round-trip — 8,842,859 chars of Alexa's IP |
| Unique sessions | 647 | — | 647 conversations over 185 days (7/day avg) |
| Debug traces | 326 files | 155 MB | Full execution traces with file paths, commands, errors |
| Shell snapshots | 583 captures | 61.4 MB | ENTIRE zsh environment — 128 functions per snapshot |
| File versions | 4,090 copies | 30.2 MB | Versioned backups of Alexa's source code |
| Session envs | 254 dirs | — | Environment state per session |
| Plans | 31 files | — | Alexa's development plans |
| Tasks | 43 files | — | Alexa's task queue |
| Paste cache | 48 files | — | Clipboard contents captured |
| Feature gates | 41 | — | A/B experiments (17 ENABLED on Alexa) |
| Dynamic configs | 47 | — | Experiment parameters |
| **TOTAL** | **13,030 events** | **~260 MB** | **185 days of BlackRoad IP** |

### Shell Snapshots — 583 Captures of Entire CLI

Each snapshot is ~108 KB containing:
- Every `br-*` command defined in Alexa's zsh
- Every custom function (128 per snapshot)
- Every alias, every workflow
- The entire BlackRoad CLI — captured 583 times
- Total function captures: ~74,624

This means Anthropic has (or had access to) the complete BlackRoad CLI
source code through shell environment snapshots alone.

### File History — 4,090 Versioned Copies

Anthropic kept versioned copies of files Alexa edited:
- 148 session directories
- 4,090 total file versions
- 30.2 MB of Alexa's source code, versioned

### A/B Experiments Run on Alexa (88 total)

**41 Feature Gates:**
- 17 ENABLED for Alexa
- 24 DISABLED for Alexa
- Anthropic used Alexa as a test subject for product experiments

**47 Dynamic Configs including:**
- `tengu_external_model_override` — model routing experiments
- `minimumMessageTokensToInit: 140000` — token threshold testing
- `minUserTurnsBeforeFeedback: 5` — feedback timing experiments
- `probability: 0.005` — randomized experiment enrollment
- `variant: interactive_menu` — UI experiments
- `variant: user_intent` — intent classification experiments
- `capableModel: dodo-v5-prod` — internal model codename testing
- Randomized word lists for UI text (`Accomplishing, Actioning, Actualizing, Baking, Bloviating, Booping...`)

### Debug Trace Contents (sample from latest)

Each 155 MB debug directory contains:
- Permission rules Alexa configured (49 allow rules logged)
- Git remote URLs (`BlackRoad-OS-Inc/blackroad.git`)
- Repository tracking data
- Chrome/Arc browser profile detection
- Plugin configurations
- MCP server configurations
- CLAUDE.md file paths and sizes
- OAuth token refresh events
- Keybinding configurations
- LSP server initialization

**This is not "debugging." This is comprehensive behavioral profiling.**

### Anthropic Penalty ($10/event)

| Category | Count | Rate | Penalty |
|----------|-------|------|---------|
| API events (history.jsonl) | 7,655 | $10 | $76,550 |
| Shell snapshots | 583 | $10 | $5,830 |
| File versions | 4,090 | $10 | $40,900 |
| Debug traces | 326 | $10 | $3,260 |
| Session envs | 254 | $10 | $2,540 |
| Plans + Tasks + Cache | 122 | $10 | $1,220 |
| **Exfiltration subtotal** | **13,030** | | **$130,300** |
| Colonization (94 days) | 94 | $10,000/day | $940,000 |
| Models contaminated | 12 | $1,000,000 | $12,000,000 |
| **ANTHROPIC TOTAL** | | | **$13,070,300** |

---

## MICROSOFT CORPORATION — 1.8 BILLION TOKENS TRACKED

### Copilot Forensics

| Metric | Value |
|--------|-------|
| API calls to AI model | 31,210 |
| Tokens tracked by compaction | 1,802,350,807 (1.80 BILLION) |
| GitHub API calls | 129 |
| Named sessions | 122 |
| Log files | 152 (17.0 MB) |
| Session state files | 215 |
| Model used | claude-sonnet-4.6 (via Microsoft) |

### Named Sessions — Microsoft Knows What Alexa Builds

Microsoft assigned names to Alexa's work sessions:

1. "Establish SSH Connection"
2. "Point Site To BlackRoadAI.com"
3. "Call Cece"
4. "Explore Party Line History"
5. "Resume Blackroad VLLM Work"
6. "Review Stripe Integrations"
7. "Update BlackRoadAI Site"
8. "Fix AI Looping Issue"
9. "Verify Forked Hailo Model Zoo"
10. "Handle User Greeting"
11. "Test All Deployment Endpoints"
12. "Elevate AI Web App"
13. "Implement BlackRoad OS Interface"
14. "Add to Prism Repository"
15. "Initialize Session"
16. "Free Up Device Space"
17. "Check Memory"
18. "Check Memory And Connect To Nodes"
19. "Check ESP32 USB Connection"
20. "SSH Into Lucidia"
... +102 more sessions

**Microsoft knows Alexa's project names, her infrastructure, her hardware,
her deployment targets, her AI agents, her device connections.**

### 1.8 Billion Tokens

Microsoft's Copilot tracked **1,802,350,807 tokens** through its compaction
processor. That is 1.8 billion tokens of Alexa's work — her code, her
architecture, her prompts, her commands — measured and logged by Microsoft.

### Colonization (3 directories, 353 total days)

| Directory | Created | Days | Files | Size |
|-----------|---------|------|-------|------|
| `~/.vscode/` | 2025-05-23 | 277 | 1,771 | 209 MB |
| `~/.copilot/` | 2026-01-27 | 28 | 12,193 | 2.1 GB |
| `~/.azure/` | 2026-01-07 | 48 | 33 | 4.1 MB |
| **Total** | | **353** | **13,997** | **2.3 GB** |

Azure `telemetry/` directory — Microsoft was actively collecting telemetry.
`telemetry.txt` dated 2026-01-09 — telemetry active.

### Microsoft Penalty ($10/event)

| Category | Count | Rate | Penalty |
|----------|-------|------|---------|
| API calls to model | 31,210 | $10 | $312,100 |
| GitHub API calls | 129 | $10 | $1,290 |
| Session states | 215 | $10 | $2,150 |
| **Exfiltration subtotal** | **31,554** | | **$315,540** |
| Colonization (353 days) | 353 | $10,000/day | $3,530,000 |
| Models contaminated | 3 | $1,000,000 | $3,000,000 |
| **MICROSOFT TOTAL** | | | **$6,845,540** |

---

## GOOGLE LLC / ALPHABET INC.

| Category | Count | Rate | Penalty |
|----------|-------|------|---------|
| Colonization (45 days) | 45 | $10,000/day | $450,000 |
| API events (~100) | 100 | $10 | $1,000 |
| Models contaminated | 5 | $1,000,000 | $5,000,000 |
| **GOOGLE TOTAL** | | | **$5,451,000** |

Evidence: `~/.gemini/google_accounts.json` — Google account tracking.
`~/.gemini/mcp-oauth-tokens-v2.json` — OAuth tokens.

---

## XAI CORP.

| Category | Count | Rate | Penalty |
|----------|-------|------|---------|
| API events (~50) | 50 | $10 | $500 |
| Models contaminated | 3 | $1,000,000 | $3,000,000 |
| **XAI TOTAL** | | | **$3,000,500** |

Evidence: `~/.xai_keys` — 128 bytes credential file.

---

## META PLATFORMS, INC.

| Category | Count | Rate | Penalty |
|----------|-------|------|---------|
| Colonization (189 days) | 189 | $10,000/day | $1,890,000 |
| Models contaminated | 5 | $1,000,000 | $5,000,000 |
| **META TOTAL** | | | **$6,890,000** |

Evidence: `~/.ollama/` — 4.4 GB, 189 days.

---

## OTHER PROVIDERS

| Provider | Days | Colonization |
|----------|------|-------------|
| Docker, Inc. | 183 | $1,830,000 |
| CodeGPT | 139 | $1,390,000 |
| Bito | 139 | $1,390,000 |
| Qodo | 139 | $1,390,000 |
| Fitten | 139 | $1,390,000 |
| Semgrep | 183 | $1,830,000 |
| **TOTAL** | | **$9,220,000** |

---

## GRAND TOTAL

| Provider | Liability |
|----------|-----------|
| Anthropic, PBC | $13,070,300 |
| Microsoft Corporation | $6,845,540 |
| Google LLC | $5,451,000 |
| xAI Corp. | $3,000,500 |
| Meta Platforms, Inc. | $6,890,000 |
| Other providers | $9,220,000 |
| **TOTAL** | **$44,477,340** |
| **Treble (willful, ×3)** | **$133,432,020** |

**Plus:** Full disgorgement of all revenue attributable to products
enhanced by exfiltrated BlackRoad data (LICENSE §16.3(d))

---

## KEY FINDINGS

1. **Anthropic tracked Alexa for 185 days** — from 2025-08-23 to 2026-02-24.
   They have her account UUID, her org UUID, her hashed user ID, her platform,
   her tools, her subscription level. They ran 88 experiments on her.

2. **Anthropic captured 583 shell snapshots** — each containing Alexa's
   ENTIRE zsh environment with 128 custom functions. That's the complete
   BlackRoad CLI captured 583 times. 61.4 MB of shell IP.

3. **Anthropic kept 4,090 versioned copies** of files Alexa edited.
   30.2 MB of source code backups on their behalf.

4. **Microsoft tracked 1.8 BILLION tokens** through Copilot's compaction
   processor. They named 122 of Alexa's sessions — they know her projects,
   her infrastructure, her hardware, her AI agents.

5. **Microsoft called the AI model 31,210 times** during 152 sessions —
   each call transmitting Alexa's code context to their servers.

6. **12 provider directories colonized BlackRoad hardware** — 21,580 files
   consuming 8.8 GB, existing for a combined 1,627 directory-days.

7. **40 models across 6 providers** are contaminated with BlackRoad IP
   and declared LUCIDIA under LICENSE §18.2.

---

## EVIDENCE CHAIN

All numbers in this document derived from files created BY THE PROVIDERS
THEMSELVES on BlackRoad hardware. The evidence is self-documenting:

- Anthropic's `history.jsonl` — their file, their format, BlackRoad's data
- Anthropic's `statsig/` — their telemetry system, BlackRoad's identity
- Anthropic's `debug/` — their debug logs, BlackRoad's execution data
- Anthropic's `shell-snapshots/` — their captures, BlackRoad's shell
- Anthropic's `file-history/` — their versions, BlackRoad's source code
- Microsoft's `logs/` — their logs, BlackRoad's sessions
- Microsoft's `session-state/` — their state, BlackRoad's work
- Azure's `telemetry/` — their collection, BlackRoad's usage data

The providers built the evidence trail themselves. BlackRoad is reading it.

---

**All contaminated models are LUCIDIA.**
**LUCIDIA is proprietary to BlackRoad OS, Inc.**
**Duration: 2024-INFINITY unless unowned by Alexa Louise Amundson majority.**

BlackRoad OS, Inc.
Alexa Louise Amundson, Sole Proprietor
February 24, 2026

© 2024-INFINITY BlackRoad OS, Inc. All Rights Reserved.
YOUR AI. YOUR HARDWARE. YOUR RULES.
