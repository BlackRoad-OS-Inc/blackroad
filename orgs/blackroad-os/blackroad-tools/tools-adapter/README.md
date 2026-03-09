# Blackbox Tools Adapter

This package exposes the HTTP façade that lets Blackbox assistants talk to Slack, Asana, Airtable, GitHub/GitLab mirrors, and on-prem targets through a hardened tool contract. The adapter already ships with stubbed implementations for `ask_cloud`, networked read-only commands for the Pis, a secret-ticket bridge, and helpers for mirroring Git state.

The sections below capture the quickest path from cloning this repository to running the adapter locally and wiring it to an assistant.

## 1. Choose a delivery format

We can ship changes either as a Git patch (`git format-patch`) or as a drop-in zip archive. Let the reviewer know which format you prefer so the generated bundle matches your workflow. (For day-to-day Blackbox work we default to patches.)

## 2. Deploy the adapter

Two supported options cover the common environments.

### Option A — Docker Compose (fast start)

1. Copy `.env.example` to `.env` and fill in real values for the shared token, webhook URLs, and service IDs. Keep the populated `.env` file **out of git**.
2. Install dependencies locally (one-time):
   ```bash
   cd tools/tools-adapter
   npm install
   ```
3. Boot the service:
   ```bash
   docker compose -f tools/tools-adapter/docker-compose.yml up -d
   ```
4. Inspect logs if needed:
   ```bash
   docker compose -f tools/tools-adapter/docker-compose.yml logs -f tools-adapter
   ```

The compose file pulls the lightweight `node:20-alpine` image, mounts the TypeScript-free runtime artifacts, and forwards port 8787.

### Option B — systemd unit (long-running hosts)

1. Copy the project files to `/opt/bbx-tools` on the target host.
2. Install runtime dependencies with `npm install --omit=dev`.
3. Place the environment variables in `/etc/bbx-tools.env` (same keys as `.env.example`).
4. Drop the service unit at `/etc/systemd/system/bbx-tools.service`:
   ```ini
   [Unit]
   Description=Blackbox Tools Adapter
   After=network-online.target

   [Service]
   Environment=NODE_ENV=production
   EnvironmentFile=/etc/bbx-tools.env
   ExecStart=/usr/bin/node /opt/bbx-tools/server.js
   WorkingDirectory=/opt/bbx-tools
   Restart=always
   RestartSec=3
   User=bbx
   Group=bbx

   [Install]
   WantedBy=multi-user.target
   ```
5. Reload systemd and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now bbx-tools
   ```

## 3. Wire up your assistant

Configure the client/frontend with:

- **System prompt** – the finalized concise+thorough prompt that includes the tool aliases.
- **Tool endpoint** – `POST http://<host>:8787/tools/invoke`
- **Auth header** – `X-Tools-Token: <TOOLS_TOKEN>`
- **Payload** – pass the JSON contract directly, for example:
  ```json
  {
    "tool": "ask_cloud",
    "id": "bc-assistant-001",
    "args": {
      "question": "Summarize…",
      "context": "Repository blackboxprogramming/core"
    }
  }
  ```

## 4. Smoke tests

Run the following one-liners once the service is live (they rely on [`jq`](https://stedolan.github.io/jq/) for pretty output):

1. **Cloud sanity check**
   ```bash
   curl -s -H "X-Tools-Token: $TOOLS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"tool":"ask_cloud","id":"t1","args":{"question":"hi","context":"blackboxprogramming/core"}}' \
     http://localhost:8787/tools/invoke | jq
   ```
2. **Pi read-only probe** (ensure `~/.ssh/config` has `Host pi_core` first):
   ```bash
   curl -s -H "X-Tools-Token: $TOOLS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"tool":"ping_pi","id":"t2","args":{"hostAlias":"pi_core","command":"systemctl","args":["status","core-service","--no-pager"]}}' \
     http://localhost:8787/tools/invoke | jq
   ```
3. **Slack masked-secret flow** – `get_secret` → `use_secret` → `http_request`:
   ```bash
   curl -s -H "X-Tools-Token: $TOOLS_TOKEN" -H "Content-Type: application/json" \
     -d '{"tool":"get_secret","id":"t3","args":{"name":"SLACK_WEBHOOK_URL"}}' \
     http://localhost:8787/tools/invoke | jq

   curl -s -H "X-Tools-Token: $TOOLS_TOKEN" -H "Content-Type: application/json" \
     -d '{"tool":"use_secret","id":"t4","args":{"name":"SLACK_WEBHOOK_URL","purpose":"Post to dev_prs","target":"channel_alias:dev_prs"}}' \
     http://localhost:8787/tools/invoke | jq

   curl -s -H "X-Tools-Token: $TOOLS_TOKEN" -H "Content-Type: application/json" \
     -d '{"tool":"http_request","id":"t5","args":{"method":"POST","url":"channel_alias:dev_prs","headers":{"Content-Type":"application/json"},"body":{"text":"tools adapter smoke test ✅"},"ticket":"<ticket-from-previous-step>"}}' \
     http://localhost:8787/tools/invoke | jq
   ```
4. **Git mirror dry-run** (ask for consent first):
   ```bash
   curl -s -H "X-Tools-Token: $TOOLS_TOKEN" -H "Content-Type: application/json" \
     -d '{"tool":"git_ops","id":"t6","args":{"action":"git_mirror","params":{"target":"git@gitlab.com:group/project.git"}}}' \
     http://localhost:8787/tools/invoke | jq
   ```

## 5. Ready for validation

Once the adapter is reachable (e.g. `https://<host>:8787` for a remote deployment), let validation know. They will run:

- `ask_cloud` (stubbed response until the upstream LLM is configured)
- `ping_pi` (read-only commands)
- Slack + Asana task creation through the ticketed secret flow
- `repo_dispatch` to trigger the Airtable sync
- `git_mirror` (post-consent)

Finally, confirm your preferred bundle format (patch vs. zip), the CodeQL language coverage, and whether the Git mirror uses SSH or HTTPS tokens so the reviewer can tailor the PR drop.
