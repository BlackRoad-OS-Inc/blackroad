# 🛣️ GreenLight CI/CD & Infrastructure Extension

**Extension to GreenLight Emoji Dictionary for GitHub Workflows + Cloudflare**

---

## 🔄 CI/CD Pipeline States

Add these to the **Lifecycle States** category:

| Emoji | State | Code | Trinary | Description |
|-------|-------|------|---------|-------------|
| ⚡ | TRIGGERED | `triggered` | 0 | Workflow started / Event received |
| 🔍 | LINTING | `linting` | +1 | Code quality checks running |
| 🧪 | TESTING | `testing` | +1 | Tests executing |
| 🏗️ | BUILDING | `building` | +1 | Build in progress |
| 📦 | PACKAGING | `packaging` | +1 | Creating artifacts |
| 🚢 | DEPLOYING | `deploying` | +1 | Deployment in progress |
| ✅ | PASSED | `passed` | +1 | Pipeline succeeded |
| ❌ | FAILED | `failed` | -1 | Pipeline failed |
| ⏭️ | SKIPPED | `skipped` | 0 | Step skipped |
| 🔁 | RETRYING | `retrying` | 0 | Retry attempt |

---

## ☁️ Cloudflare Resource Types

Add these to **Infrastructure Layer** category:

| Emoji | Resource | Code | Description |
|-------|----------|------|-------------|
| ⚙️ | WORKER | `worker` | Cloudflare Worker |
| 💾 | D1 | `d1` | D1 Database |
| 🗂️ | KV | `kv` | KV Namespace |
| 📦 | R2 | `r2` | R2 Bucket |
| 🌐 | PAGES | `pages` | Cloudflare Pages |
| 🔒 | DO | `do` | Durable Object |
| 🌍 | ZONE | `zone` | DNS Zone |
| 🔀 | TUNNEL | `tunnel` | Cloudflare Tunnel |

---

## 🎯 Worker Categories

Add to **Domain Tags**:

| Emoji | Category | Code | Description |
|-------|----------|------|-------------|
| 🌐 | ROUTING | `routing` | Gateway, router, subdomain workers |
| 🔐 | AUTH | `auth` | Authentication, identity, cipher |
| 💰 | BILLING | `billing` | Payments, Stripe, checkout |
| 🌀 | AGENTS | `agents` | AI agents, Lucidia, Cece |
| 💾 | STORAGE | `storage` | D1, KV, R2 management |
| 📊 | OBSERVABILITY | `observability` | Logs, metrics, telemetry |
| 🌐 | MESH | `mesh` | Service mesh, networking |
| 🛠️ | TOOLS | `tools` | CLI, console, dev tools |
| 📦 | VERTICAL | `vertical` | Vertical-specific workers |

---

## 🔄 GitHub Workflow Steps

Map to existing GreenLight phases with specific codes:

| Emoji | Step | Code | Phase | Description |
|-------|------|------|-------|-------------|
| 🏷️ | DETECT | `detect` | 🌱 Discovery | Detect changed files |
| 🔍 | LINT | `lint` | 🔨 Implementation | Linting & formatting |
| 🧪 | TEST | `test` | 🧪 Testing | Unit/integration tests |
| 🏗️ | BUILD | `build` | 🔨 Implementation | Compile & bundle |
| 📦 | PACKAGE | `package` | 📦 Packaging | Create release artifacts |
| 🚀 | DEPLOY | `deploy` | 🚀 Deployment | Deploy to environment |
| 📣 | ANNOUNCE | `announce` | 📣 Announcement | Notify systems |
| 🔒 | SECURITY | `security` | 🔒 Security | CodeQL, vulnerability scan |
| 🤖 | DEPENDABOT | `dependabot` | 🔧 Maintenance | Dependency updates |

---

## 🌍 Deployment Environments

Add to **Device/Location** category:

| Emoji | Environment | Code | Description |
|-------|-------------|------|-------------|
| 🧪 | STAGING | `staging` | Staging environment |
| 🚀 | PRODUCTION | `production` | Production environment |
| 🧑‍💻 | DEVELOPMENT | `development` | Dev environment |
| 🔬 | PREVIEW | `preview` | Preview deployment |
| 🌐 | EDGE | `edge` | Cloudflare edge |
| 🏠 | LOCAL | `local` | Local development |

---

## 🎨 Composite Patterns for CI/CD

### GitHub Workflow Events

```
⚡👉🔧📌 = Triggered micro infra workflow, medium priority
🧪🎢🛣️⭐ = Testing macro platform workflow, high priority
✅👉🌐🔥 = Passed micro edge deployment, fire priority
❌🎢🔐🚨 = Failed macro auth workflow, urgent
🚀🌐🛣️⭐ = Deploying planetary platform, high priority
```

### Cloudflare Deployments

```
🚀⚙️🌐✅ = Deployed worker to edge, done
🏗️💾🎢🔥 = Building D1 macro project, fire priority
✅🗂️👉📌 = KV namespace deployed micro, medium priority
🔧📦👉⭐ = Configuring R2 bucket micro, high priority
```

### Combined Workflow + Deployment

```
[⚡🔍🧪🏗️📦🚀📣] = Full CI/CD pipeline
[🔍✅] [🧪✅] [🏗️✅] [🚀⚙️🌐] = Lint ✓ Test ✓ Build ✓ Deploy to Worker
```

---

## 📝 NATS Subject Patterns (Extended)

### CI/CD Events
```
greenlight.triggered.micro.infra.{repo}
greenlight.testing.macro.platform.{repo}
greenlight.passed.micro.edge.{repo}
greenlight.failed.macro.auth.{repo}
greenlight.deployed.worker.{service}.{env}
```

### Cloudflare Events
```
greenlight.deployed.worker.{worker-name}.{env}
greenlight.configured.d1.{database-name}
greenlight.created.kv.{namespace-name}
greenlight.uploaded.r2.{bucket-name}
greenlight.published.pages.{project-name}
```

### Workflow Progression
```
greenlight.detect.done.{repo}
greenlight.lint.wip.{repo}
greenlight.test.done.{repo}
greenlight.build.wip.{repo}
greenlight.deploy.done.{worker}.{env}
greenlight.announce.done.{repo}
```

---

## 🔨 Extended Memory Templates

### Workflow Events

```bash
# Workflow triggered
gl_workflow_trigger() {
    local repo="$1"
    local trigger="$2"  # push, pr, manual
    gl_log "⚡👉🔧📌" "triggered" "$repo" "Workflow triggered by: $trigger"
}

# Workflow step complete
gl_workflow_step() {
    local repo="$1"
    local step="$2"  # lint, test, build, deploy
    local status="$3"  # passed, failed

    local step_emoji=""
    case "$step" in
        lint) step_emoji="🔍" ;;
        test) step_emoji="🧪" ;;
        build) step_emoji="🏗️" ;;
        deploy) step_emoji="🚀" ;;
    esac

    local status_emoji="✅"
    [ "$status" = "failed" ] && status_emoji="❌"

    gl_log "${step_emoji}${status_emoji}👉🔧" "$step" "$repo" "Step $step $status"
}

# Workflow complete
gl_workflow_done() {
    local repo="$1"
    local status="$2"  # passed, failed
    local duration="$3"

    local status_emoji="✅"
    [ "$status" = "failed" ] && status_emoji="❌"

    gl_log "${status_emoji}🎢🔧📣" "workflow_${status}" "$repo" "Pipeline $status in $duration"
}
```

### Cloudflare Deployments

```bash
# Worker deployment
gl_worker_deploy() {
    local worker="$1"
    local env="$2"  # staging, production
    local version="$3"

    local env_emoji="🧪"
    [ "$env" = "production" ] && env_emoji="🚀"

    gl_log "${env_emoji}⚙️🌐✅" "deployed" "$worker" "Worker deployed to $env v$version"
}

# D1 migration
gl_d1_migrate() {
    local database="$1"
    local migration="$2"

    gl_log "🔄💾👉📌" "migrated" "$database" "Applied migration: $migration"
}

# KV namespace update
gl_kv_update() {
    local namespace="$1"
    local operation="$2"  # created, updated, deleted

    gl_log "✅🗂️👉📌" "$operation" "$namespace" "KV namespace $operation"
}

# R2 bucket operation
gl_r2_operation() {
    local bucket="$1"
    local operation="$2"
    local size="$3"

    gl_log "📦👉💾" "$operation" "$bucket" "R2 $operation ($size)"
}
```

---

## 🎯 Example Integration: Full Workflow

### Scenario: Deploy blackroad-api worker

```bash
# 1. Workflow triggered
gl_workflow_trigger "blackroad-api" "push to main"
# [⚡👉🔧📌] triggered: blackroad-api

# 2. Lint step
gl_workflow_step "blackroad-api" "lint" "passed"
# [🔍✅👉🔧] lint: blackroad-api — Step lint passed

# 3. Test step
gl_workflow_step "blackroad-api" "test" "passed"
# [🧪✅👉🔧] test: blackroad-api — Step test passed

# 4. Build step
gl_workflow_step "blackroad-api" "build" "passed"
# [🏗️✅👉🔧] build: blackroad-api — Step build passed

# 5. Deploy step
gl_workflow_step "blackroad-api" "deploy" "passed"
# [🚀✅👉🔧] deploy: blackroad-api — Step deploy passed

# 6. Worker deployed
gl_worker_deploy "blackroad-api" "production" "1.2.3"
# [🚀⚙️🌐✅] deployed: blackroad-api — Worker deployed to production v1.2.3

# 7. Workflow complete
gl_workflow_done "blackroad-api" "passed" "3m 42s"
# [✅🎢🔧📣] workflow_passed: blackroad-api — Pipeline passed in 3m 42s
```

### Memory Output:
```
[⚡👉🔧📌] triggered: blackroad-api — Workflow triggered by: push to main
[🔍✅👉🔧] lint: blackroad-api — Step lint passed
[🧪✅👉🔧] test: blackroad-api — Step test passed
[🏗️✅👉🔧] build: blackroad-api — Step build passed
[🚀✅👉🔧] deploy: blackroad-api — Step deploy passed
[🚀⚙️🌐✅] deployed: blackroad-api — Worker deployed to production v1.2.3
[✅🎢🔧📣] workflow_passed: blackroad-api — Pipeline passed in 3m 42s
```

Every Claude instantly sees the full deployment lifecycle! 🎉

---

## 📚 Integration Checklist

- [x] Extended lifecycle states for CI/CD
- [x] Added Cloudflare resource types
- [x] Created worker category tags
- [x] Mapped GitHub workflow steps
- [x] Defined deployment environments
- [x] Created composite patterns
- [x] Extended NATS subjects
- [x] Built workflow templates
- [x] Built Cloudflare templates
- [x] Provided full integration example

---

**Created:** December 23, 2025
**For:** GitHub Workflows + Cloudflare Infrastructure
**Version:** 2.0.0-cicd
**Status:** 🔨 IMPLEMENTATION
