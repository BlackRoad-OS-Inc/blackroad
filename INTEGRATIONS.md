# BlackRoad OS Integrations

> Connect BlackRoad OS with your favorite tools and services

---

## Table of Contents

- [Overview](#overview)
- [Cloud Providers](#cloud-providers)
- [Version Control](#version-control)
- [CI/CD Platforms](#cicd-platforms)
- [Communication](#communication)
- [Databases](#databases)
- [Monitoring](#monitoring)
- [AI/ML Services](#aiml-services)
- [Custom Integrations](#custom-integrations)
- [Webhooks](#webhooks)

---

## Overview

BlackRoad OS integrates with a wide ecosystem of tools and services. Integrations enable agents to interact with external systems, trigger workflows, and extend capabilities.

### Integration Types

| Type | Description | Examples |
|------|-------------|----------|
| **Native** | Built into BlackRoad | Cloudflare, Railway, Vercel |
| **Plugin** | Installable extensions | Slack, Discord, GitHub |
| **API** | Direct API connections | Any REST/GraphQL API |
| **Webhook** | Event-driven | GitHub, Stripe, Twilio |
| **MCP** | Model Context Protocol | Claude, custom tools |

### Configuration Location

```
integrations/
├── cloudflare/
│   └── config.yaml
├── github/
│   └── config.yaml
├── slack/
│   └── config.yaml
└── custom/
    └── my-integration.yaml
```

---

## Cloud Providers

### Cloudflare

**Native integration for edge computing, DNS, and storage.**

```yaml
# integrations/cloudflare/config.yaml
cloudflare:
  enabled: true
  account_id: ${CF_ACCOUNT_ID}
  api_token: ${CF_API_TOKEN}

  # Workers
  workers:
    enabled: true
    routes:
      - pattern: "api.blackroad.io/*"
        worker: blackroad-api

  # KV Storage
  kv:
    namespaces:
      - name: CACHE
        id: ${KV_CACHE_ID}
      - name: CONFIG
        id: ${KV_CONFIG_ID}

  # D1 Database
  d1:
    databases:
      - name: blackroad-db
        id: ${D1_DATABASE_ID}

  # R2 Storage
  r2:
    buckets:
      - name: blackroad-archive
        public: false

  # Tunnel
  tunnel:
    enabled: true
    tunnel_id: ${CF_TUNNEL_ID}
```

**Usage:**

```python
from blackroad.integrations import Cloudflare

cf = Cloudflare()

# Deploy worker
await cf.workers.deploy("my-worker", code)

# Store in KV
await cf.kv.put("CACHE", "key", "value")

# Query D1
results = await cf.d1.query("SELECT * FROM users")

# Upload to R2
await cf.r2.upload("blackroad-archive", "file.txt", data)
```

### Railway

**GPU inference and application hosting.**

```yaml
# integrations/railway/config.yaml
railway:
  enabled: true
  api_token: ${RAILWAY_TOKEN}

  projects:
    - name: blackroad-api
      environment: production
      services:
        - name: api
          dockerfile: Dockerfile.api
        - name: worker
          dockerfile: Dockerfile.worker

    - name: blackroad-gpu
      environment: production
      services:
        - name: vllm
          gpu: true
          image: vllm/vllm-openai
```

**Usage:**

```python
from blackroad.integrations import Railway

railway = Railway()

# Deploy service
await railway.deploy("blackroad-api", {
    "service": "api",
    "image": "blackroad/api:latest"
})

# Get logs
logs = await railway.logs("blackroad-api", "api", lines=100)

# Scale service
await railway.scale("blackroad-api", "worker", replicas=3)
```

### Vercel

**Frontend hosting and serverless functions.**

```yaml
# integrations/vercel/config.yaml
vercel:
  enabled: true
  token: ${VERCEL_TOKEN}
  team_id: ${VERCEL_TEAM_ID}

  projects:
    - name: blackroad-web
      framework: nextjs
      env:
        NEXT_PUBLIC_API_URL: https://api.blackroad.io
```

**Usage:**

```python
from blackroad.integrations import Vercel

vercel = Vercel()

# Deploy
deployment = await vercel.deploy("blackroad-web")
print(f"Deployed to: {deployment.url}")

# Get deployment status
status = await vercel.status("blackroad-web", deployment.id)
```

### DigitalOcean

**Virtual machines and managed services.**

```yaml
# integrations/digitalocean/config.yaml
digitalocean:
  enabled: true
  token: ${DO_TOKEN}

  droplets:
    - name: blackroad os-infinity
      ip: 159.65.43.12
      size: s-4vcpu-8gb
      region: nyc1

  spaces:
    - name: blackroad-backup
      region: nyc3
```

**Usage:**

```python
from blackroad.integrations import DigitalOcean

do = DigitalOcean()

# Create droplet
droplet = await do.droplets.create({
    "name": "new-server",
    "size": "s-2vcpu-4gb",
    "image": "ubuntu-22-04-x64",
    "region": "nyc1"
})

# Upload to Spaces
await do.spaces.upload("blackroad-backup", "backup.tar.gz", data)
```

---

## Version Control

### GitHub

**Full integration for repositories, issues, PRs, and actions.**

```yaml
# integrations/github/config.yaml
github:
  enabled: true
  token: ${GITHUB_TOKEN}
  app:
    id: ${GITHUB_APP_ID}
    private_key: ${GITHUB_APP_KEY}

  organizations:
    - blackboxprogramming
    - blackroad-os

  webhooks:
    - events: [push, pull_request, issues]
      url: https://api.blackroad.io/webhooks/github
      secret: ${GITHUB_WEBHOOK_SECRET}
```

**Usage:**

```python
from blackroad.integrations import GitHub

gh = GitHub()

# Create issue
issue = await gh.issues.create(
    repo="blackroad-os/blackroad",
    title="Bug: Memory leak",
    body="Description...",
    labels=["bug", "memory"]
)

# Create PR
pr = await gh.pulls.create(
    repo="blackroad-os/blackroad",
    title="Fix memory leak",
    head="fix/memory-leak",
    base="main"
)

# Get repository info
repo = await gh.repos.get("blackroad-os/blackroad")

# List workflows
workflows = await gh.actions.list_workflows("blackroad-os/blackroad")
```

**Webhook Events:**

```python
@agent.on_event("github.push")
async def handle_push(event):
    repo = event.repository.full_name
    branch = event.ref.split("/")[-1]
    await agent.run_workflow("ci-pipeline", {
        "repo": repo,
        "branch": branch
    })

@agent.on_event("github.pull_request.opened")
async def handle_pr(event):
    pr = event.pull_request
    await agent.use_skill("code-review", {
        "repo": pr.base.repo.full_name,
        "pr_number": pr.number
    })
```

### GitLab

```yaml
# integrations/gitlab/config.yaml
gitlab:
  enabled: true
  token: ${GITLAB_TOKEN}
  url: https://gitlab.com
```

### Bitbucket

```yaml
# integrations/bitbucket/config.yaml
bitbucket:
  enabled: true
  username: ${BITBUCKET_USER}
  app_password: ${BITBUCKET_APP_PASSWORD}
```

---

## CI/CD Platforms

### GitHub Actions

```yaml
# .github/workflows/blackroad.yml
name: BlackRoad CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Notify BlackRoad
        uses: blackroad-os/notify-action@v1
        with:
          api_key: ${{ secrets.BLACKROAD_API_KEY }}
          event: ci_started
          workflow: ${{ github.workflow }}
```

### Linear

**Issue tracking and project management.**

```yaml
# integrations/linear/config.yaml
linear:
  enabled: true
  api_key: ${LINEAR_API_KEY}

  sync:
    - team: ENG
      labels: [blackroad, agents]
```

**Usage:**

```python
from blackroad.integrations import Linear

linear = Linear()

# Create issue
issue = await linear.issues.create({
    "title": "Implement new feature",
    "description": "...",
    "teamId": "ENG",
    "priority": 2
})

# Update issue status
await linear.issues.update(issue.id, {
    "stateId": "in-progress"
})
```

---

## Communication

### Slack

**Team messaging and notifications.**

```yaml
# integrations/slack/config.yaml
slack:
  enabled: true
  bot_token: ${SLACK_BOT_TOKEN}
  app_token: ${SLACK_APP_TOKEN}

  channels:
    alerts: C01234567
    deployments: C01234568
    general: C01234569

  commands:
    - command: /blackroad
      description: Interact with BlackRoad agents
```

**Usage:**

```python
from blackroad.integrations import Slack

slack = Slack()

# Send message
await slack.send(
    channel="#deployments",
    text="Deployment complete!",
    blocks=[
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": "*Deployment Complete* :rocket:"}
        }
    ]
)

# Send file
await slack.upload_file(
    channels=["#reports"],
    file="report.pdf",
    title="Weekly Report"
)
```

**Slash Commands:**

```python
@agent.on_slack_command("/blackroad")
async def handle_command(command, respond):
    args = command.text.split()

    if args[0] == "status":
        status = await get_system_status()
        await respond(f"System Status: {status}")

    elif args[0] == "deploy":
        await agent.run_workflow("deploy", {"env": args[1]})
        await respond(f"Deployment started for {args[1]}")
```

### Discord

**Community and team communication.**

```yaml
# integrations/discord/config.yaml
discord:
  enabled: true
  bot_token: ${DISCORD_BOT_TOKEN}

  guilds:
    - id: 123456789
      channels:
        alerts: 987654321
        general: 987654322

  commands:
    - name: status
      description: Get system status
    - name: ask
      description: Ask an agent
```

**Usage:**

```python
from blackroad.integrations import Discord

discord = Discord()

# Send message
await discord.send(
    channel_id=987654321,
    content="Alert: High CPU usage detected!"
)

# Send embed
await discord.send_embed(
    channel_id=987654321,
    title="Deployment Complete",
    description="Version 1.2.3 deployed to production",
    color=0x00FF00
)
```

### Email

**Email notifications and communication.**

```yaml
# integrations/email/config.yaml
email:
  enabled: true
  provider: sendgrid
  api_key: ${SENDGRID_API_KEY}
  from: noreply@blackroad.io
  reply_to: support@blackroad.io
```

**Usage:**

```python
from blackroad.integrations import Email

email = Email()

await email.send(
    to="user@example.com",
    subject="Your deployment is complete",
    html="<h1>Deployment Complete</h1><p>...</p>",
    template="deployment-complete",
    variables={"version": "1.2.3"}
)
```

### Microsoft Teams

```yaml
# integrations/teams/config.yaml
teams:
  enabled: true
  webhook_url: ${TEAMS_WEBHOOK_URL}
```

---

## Databases

### PostgreSQL

```yaml
# integrations/postgresql/config.yaml
postgresql:
  enabled: true
  host: ${POSTGRES_HOST}
  port: 5432
  database: blackroad
  user: ${POSTGRES_USER}
  password: ${POSTGRES_PASSWORD}
  ssl: true
  pool_size: 20
```

**Usage:**

```python
from blackroad.integrations import PostgreSQL

db = PostgreSQL()

# Query
users = await db.query("SELECT * FROM users WHERE active = $1", [True])

# Insert
await db.execute(
    "INSERT INTO events (type, data) VALUES ($1, $2)",
    ["deployment", {"version": "1.2.3"}]
)

# Transaction
async with db.transaction():
    await db.execute("UPDATE accounts SET balance = balance - $1 WHERE id = $2", [100, 1])
    await db.execute("UPDATE accounts SET balance = balance + $1 WHERE id = $2", [100, 2])
```

### Redis

```yaml
# integrations/redis/config.yaml
redis:
  enabled: true
  host: ${REDIS_HOST}
  port: 6379
  password: ${REDIS_PASSWORD}
  db: 0
  ssl: true
```

**Usage:**

```python
from blackroad.integrations import Redis

redis = Redis()

# String operations
await redis.set("key", "value", ex=3600)
value = await redis.get("key")

# List operations
await redis.lpush("queue", "item")
item = await redis.rpop("queue")

# Pub/Sub
await redis.publish("channel", "message")

@redis.subscribe("channel")
async def handle_message(message):
    print(f"Received: {message}")
```

### Pinecone

```yaml
# integrations/pinecone/config.yaml
pinecone:
  enabled: true
  api_key: ${PINECONE_API_KEY}
  environment: ${PINECONE_ENV}
  index: blackroad-semantic
```

**Usage:**

```python
from blackroad.integrations import Pinecone

pinecone = Pinecone()

# Upsert vectors
await pinecone.upsert([
    {"id": "doc1", "values": embedding1, "metadata": {"type": "document"}},
    {"id": "doc2", "values": embedding2, "metadata": {"type": "document"}}
])

# Query
results = await pinecone.query(
    vector=query_embedding,
    top_k=10,
    filter={"type": "document"}
)
```

---

## Monitoring

### Grafana

```yaml
# integrations/grafana/config.yaml
grafana:
  enabled: true
  url: https://grafana.blackroad.io
  api_key: ${GRAFANA_API_KEY}

  dashboards:
    - name: blackroad-overview
      uid: abc123
```

### Prometheus

```yaml
# integrations/prometheus/config.yaml
prometheus:
  enabled: true
  url: http://prometheus:9090

  metrics:
    - name: blackroad_agents_active
      type: gauge
    - name: blackroad_tasks_total
      type: counter
```

### Sentry

```yaml
# integrations/sentry/config.yaml
sentry:
  enabled: true
  dsn: ${SENTRY_DSN}
  environment: production
  traces_sample_rate: 0.1
```

**Usage:**

```python
from blackroad.integrations import Sentry

sentry = Sentry()

# Capture exception
try:
    risky_operation()
except Exception as e:
    sentry.capture_exception(e)

# Capture message
sentry.capture_message("Important event occurred", level="info")

# Add context
sentry.set_context("agent", {"name": "ALICE", "status": "busy"})
```

### PagerDuty

```yaml
# integrations/pagerduty/config.yaml
pagerduty:
  enabled: true
  routing_key: ${PAGERDUTY_ROUTING_KEY}
```

**Usage:**

```python
from blackroad.integrations import PagerDuty

pd = PagerDuty()

# Trigger alert
await pd.trigger(
    summary="High error rate detected",
    severity="critical",
    source="blackroad-api",
    custom_details={"error_rate": "15%"}
)

# Resolve alert
await pd.resolve(dedup_key="alert-123")
```

---

## AI/ML Services

### OpenAI

```yaml
# integrations/openai/config.yaml
openai:
  enabled: true
  api_key: ${OPENAI_API_KEY}
  organization: ${OPENAI_ORG}

  defaults:
    model: gpt-4-turbo
    temperature: 0.7
```

**Usage:**

```python
from blackroad.integrations import OpenAI

openai = OpenAI()

# Chat completion
response = await openai.chat([
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
])

# Embeddings
embedding = await openai.embed("Text to embed")

# Image generation
image = await openai.image_generate("A futuristic city")
```

### Anthropic

```yaml
# integrations/anthropic/config.yaml
anthropic:
  enabled: true
  api_key: ${ANTHROPIC_API_KEY}

  defaults:
    model: claude-3-opus
    max_tokens: 4096
```

### Ollama (Local)

```yaml
# integrations/ollama/config.yaml
ollama:
  enabled: true
  host: http://localhost:11434

  models:
    - llama3.2
    - mistral
    - codellama
```

**Usage:**

```python
from blackroad.integrations import Ollama

ollama = Ollama()

# Generate
response = await ollama.generate(
    model="llama3.2",
    prompt="Explain quantum computing"
)

# Chat
response = await ollama.chat(
    model="llama3.2",
    messages=[{"role": "user", "content": "Hello!"}]
)

# List models
models = await ollama.list()
```

### HuggingFace

```yaml
# integrations/huggingface/config.yaml
huggingface:
  enabled: true
  token: ${HF_TOKEN}
```

---

## Custom Integrations

### Creating Custom Integration

```python
# integrations/custom/my_service.py
from blackroad.integrations import Integration, IntegrationConfig

class MyServiceConfig(IntegrationConfig):
    api_key: str
    base_url: str = "https://api.myservice.com"

class MyServiceIntegration(Integration):
    name = "my-service"
    config_class = MyServiceConfig

    async def setup(self):
        self.client = MyServiceClient(
            api_key=self.config.api_key,
            base_url=self.config.base_url
        )

    async def teardown(self):
        await self.client.close()

    async def get_data(self, id: str):
        return await self.client.get(f"/data/{id}")

    async def send_data(self, data: dict):
        return await self.client.post("/data", json=data)
```

### Registering Integration

```python
from blackroad import BlackRoad
from integrations.custom.my_service import MyServiceIntegration

app = BlackRoad()
app.register_integration(MyServiceIntegration())
```

### Using Custom Integration

```python
my_service = app.integrations.get("my-service")

data = await my_service.get_data("123")
await my_service.send_data({"key": "value"})
```

---

## Webhooks

### Incoming Webhooks

```yaml
# config/webhooks.yaml
webhooks:
  incoming:
    - path: /webhooks/github
      secret: ${GITHUB_WEBHOOK_SECRET}
      handler: github_handler

    - path: /webhooks/stripe
      secret: ${STRIPE_WEBHOOK_SECRET}
      handler: stripe_handler

    - path: /webhooks/custom
      auth: api_key
      handler: custom_handler
```

**Handler:**

```python
@app.webhook("/webhooks/github")
async def github_handler(request, payload):
    event = request.headers.get("X-GitHub-Event")

    if event == "push":
        await handle_push(payload)
    elif event == "pull_request":
        await handle_pr(payload)

    return {"status": "ok"}
```

### Outgoing Webhooks

```python
from blackroad.webhooks import WebhookClient

client = WebhookClient()

# Send webhook
await client.send(
    url="https://api.example.com/webhook",
    event="deployment.completed",
    data={"version": "1.2.3"},
    secret="webhook-secret"
)

# With retry
await client.send(
    url="https://api.example.com/webhook",
    event="alert",
    data={"message": "Error detected"},
    retry={"max_attempts": 3, "delay": 5}
)
```

### Webhook Security

```python
import hmac
import hashlib

def verify_webhook(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(f"sha256={expected}", signature)
```

---

## Integration Status

### Check Integration Health

```bash
# Check all integrations
./status.sh integrations

# Check specific integration
./status.sh integration github
```

### Integration Dashboard

```
Integrations Status
├── cloudflare [CONNECTED] ✓
├── github [CONNECTED] ✓
├── railway [CONNECTED] ✓
├── slack [CONNECTED] ✓
├── postgresql [CONNECTED] ✓
├── redis [CONNECTED] ✓
├── pinecone [CONNECTED] ✓
└── ollama [CONNECTED] ✓
```

---

*Last updated: 2026-02-05*
