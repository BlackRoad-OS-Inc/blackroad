# 💬 GreenLight Slack Integration

**Extension to GreenLight for Slack Team Communication**

---

## 💬 Slack Events as GreenLight Steps

Map Slack events directly to GreenLight workflow:

| Slack Event | GreenLight Step | Step # | Emoji | State Transition | Channel |
|-------------|-----------------|--------|-------|------------------|---------|
| Message received | ⚡ Impulse | 1 | ⚡📥 | void → inbox | any |
| /issue created | 📥 Capture | 3 | 📥📋 | → inbox | #linear-updates |
| Reaction ✅ | ✅ Approve | 7 | ✅👍 | → queued | any |
| /deploy started | 🎬 Mobilize | 10 | 🎬🚀 | queued → wip | #ops-deployments |
| Deploy running | ⚙️ Execute | 13 | ⚙️⚡ | → wip | #ops-deployments |
| Deploy success | 🎉 Complete | 19 | 🎉✅ | wip → done | #ops-deployments |
| Alert: error | 🚨 Detect | 16 | 🚨⚠️ | → blocked | #ops-alerts |

---

## 🏷️ Slack Channel Categories

Recommended channel structure with GreenLight mappings:

| Emoji | Channel | Purpose | GreenLight Domain | Notification Type |
|-------|---------|---------|-------------------|-------------------|
| 📢 | #general | Company announcements | Platform (🛣️) | General |
| ⚙️ | #engineering | Engineering discussions | Infrastructure (🔧) | Technical |
| 🚨 | #ops-alerts | System alerts & monitoring | Infrastructure (🔧) | Critical |
| 🚀 | #ops-deployments | Deployment notifications | Infrastructure (🔧) | Deploy |
| 🚦 | #ops-greenlight | GreenLight state changes | Platform (🛣️) | State |
| 📋 | #linear-updates | Linear issue notifications | Platform (🛣️) | Issues |
| 🐙 | #github-activity | GitHub PRs, commits | Infrastructure (🔧) | Code |
| 💳 | #stripe-billing | Payment & subscriptions | Platform (🛣️) | Billing |
| 🤖 | #ai-logs | AI agent activity logs | AI (🌀) | AI |
| 🧠 | #lucidia | Lucidia system updates | AI (🌀) | Lucidia |
| ☀️ | #standup | Daily standups | Platform (🛣️) | Team |
| 🎲 | #random | Non-work banter | Platform (🛣️) | Social |

---

## ⚡ Slash Commands

| Command | GreenLight Action | Description | Priority |
|---------|-------------------|-------------|----------|
| /issue | Create Issue | Create Linear issue | 📌 |
| /deploy | Deploy Service | Trigger deployment | 🔥 |
| /status | Check Status | Check system status | 📌 |
| /greenlight | Query State | Query GreenLight state | ⭐ |
| /agent | Query AI | Query AI agent | ⭐ |
| /oncall | Show Schedule | Show on-call schedule | 📌 |
| /remind | Set Reminder | Set reminder | 💤 |
| /standup | Post Standup | Post standup update | 📌 |

---

## 🎨 Composite Patterns for Slack

### Message Events
```
⚡📥💬👉 = Message received, micro scale
💬✅👉📌 = Message acknowledged
🔔💬🎢⭐ = Mention notification, macro, high priority
```

### Command Events
```
📋💬👉📌 = Issue command, micro
🚀💬🎢🔥 = Deploy command, macro, urgent
🚦💬👉⭐ = GreenLight query, high priority
```

### Notification Events
```
🚨⚠️💬🔥 = Critical alert in Slack
🎉✅💬🎢 = Deployment success notification
💰✅💬📌 = Payment success notification
🐙📥💬👉 = GitHub activity notification
```

### Reaction Events
```
✅💬👉📌 = Approval reaction
❌💬👉📌 = Rejection reaction
🚀💬👉⭐ = Deploy ready reaction
```

### Full Slack Flow
```
[⚡📥] [💬📋] [✅👍] [🚀🎬] [⚙️⚡] [🎉✅] = Message → Issue → Approve → Deploy → Execute → Complete
[🚨⚠️] [💬🔔] [👤📌] = Alert → Notify → Assigned
```

---

## 📝 NATS Subject Patterns (Slack)

### Message Events
```
greenlight.slack.message.received.micro.comms.{channel}
greenlight.slack.message.sent.micro.comms.{channel}
greenlight.slack.mention.received.micro.comms.{user}
```

### Command Events
```
greenlight.slack.command.issue.micro.comms.{user}
greenlight.slack.command.deploy.macro.comms.{service}
greenlight.slack.command.status.micro.comms.{service}
greenlight.slack.command.greenlight.micro.comms.{id}
```

### Webhook Events
```
greenlight.slack.webhook.alert.critical.comms
greenlight.slack.webhook.deployment.macro.comms.{service}
greenlight.slack.webhook.github.micro.comms.{repo}
greenlight.slack.webhook.stripe.macro.comms.{event}
```

### Reaction Events
```
greenlight.slack.reaction.added.micro.comms.{emoji}
greenlight.slack.reaction.approve.micro.comms.{message}
greenlight.slack.reaction.reject.micro.comms.{message}
```

---

## 🔨 Slack Memory Templates

### Message Operations

```bash
# Slash command executed
gl_slack_command() {
    local command="$1"
    local user="$2"
    local args="${3:-}"

    gl_log "💬⚡👉📌" \
        "slack_command" \
        "$command" \
        "Executed by: $user, args: $args"
}

# Message sent to channel
gl_slack_message_sent() {
    local channel="$1"
    local message_type="${2:-notification}"

    gl_log "💬📤👉📌" \
        "message_sent" \
        "$channel" \
        "Type: $message_type"
}

# Mention received
gl_slack_mention() {
    local user="$1"
    local channel="$2"

    gl_log "🔔💬👉⭐" \
        "mention_received" \
        "$user" \
        "In channel: $channel"
}
```

### Webhook Notifications

```bash
# Alert sent to Slack
gl_slack_alert() {
    local severity="$1"  # critical, warning, info
    local title="$2"
    local channel="${3:-ops-alerts}"

    local severity_emoji=""
    case "$severity" in
        critical) severity_emoji="🚨" ;;
        warning) severity_emoji="⚠️" ;;
        info) severity_emoji="ℹ️" ;;
        *) severity_emoji="📢" ;;
    esac

    gl_log "${severity_emoji}💬🎢🔥" \
        "slack_alert" \
        "$title" \
        "Severity: $severity, Channel: #$channel"
}

# Deployment notification sent
gl_slack_deployment_notification() {
    local status="$1"  # started, success, failed
    local service="$2"
    local environment="$3"

    local status_emoji=""
    case "$status" in
        started) status_emoji="🚀" ;;
        success) status_emoji="✅" ;;
        failed) status_emoji="❌" ;;
        *) status_emoji="⚙️" ;;
    esac

    gl_log "${status_emoji}💬🎢📌" \
        "slack_deployment" \
        "$service" \
        "Status: $status, Env: $environment"
}

# GreenLight update posted
gl_slack_greenlight_update() {
    local item_id="$1"
    local from_state="$2"
    local to_state="$3"

    gl_log "🚦💬👉📌" \
        "slack_greenlight" \
        "$item_id" \
        "$from_state → $to_state"
}

# Linear notification sent
gl_slack_linear_notification() {
    local action="$1"  # created, updated, completed
    local identifier="$2"

    local action_emoji=""
    case "$action" in
        created) action_emoji="🆕" ;;
        updated) action_emoji="📝" ;;
        completed) action_emoji="✅" ;;
        *) action_emoji="📋" ;;
    esac

    gl_log "${action_emoji}💬👉📌" \
        "slack_linear" \
        "$identifier" \
        "Action: $action"
}

# GitHub notification sent
gl_slack_github_notification() {
    local type="$1"  # pr_opened, pr_merged, push, issue
    local repo="$2"
    local title="${3:-}"

    local type_emoji=""
    case "$type" in
        pr_opened) type_emoji="🔀" ;;
        pr_merged) type_emoji="🎉" ;;
        push) type_emoji="📤" ;;
        issue) type_emoji="🐛" ;;
        *) type_emoji="🐙" ;;
    esac

    gl_log "${type_emoji}💬👉📌" \
        "slack_github" \
        "$repo" \
        "Type: $type, $title"
}

# Stripe notification sent
gl_slack_stripe_notification() {
    local event="$1"  # payment_success, payment_failed, subscription_created, etc.
    local customer="$2"
    local amount="${3:-}"

    local event_emoji=""
    case "$event" in
        payment_success) event_emoji="💰" ;;
        payment_failed) event_emoji="❌" ;;
        subscription_created) event_emoji="🎉" ;;
        subscription_canceled) event_emoji="👋" ;;
        *) event_emoji="💳" ;;
    esac

    gl_log "${event_emoji}💬👉📌" \
        "slack_stripe" \
        "$customer" \
        "Event: $event, Amount: $amount"
}
```

### Approval & Interaction

```bash
# Approval request sent
gl_slack_approval_request() {
    local type="$1"  # deployment, access, expense, other
    local requester="$2"
    local title="${3:-}"

    gl_log "🔔💬👉⭐" \
        "approval_request" \
        "$requester" \
        "Type: $type, $title"
}

# Approval decision
gl_slack_approval_decision() {
    local decision="$1"  # approved, rejected
    local approver="$2"
    local request_id="$3"

    local decision_emoji=""
    case "$decision" in
        approved) decision_emoji="✅" ;;
        rejected) decision_emoji="❌" ;;
        *) decision_emoji="💬" ;;
    esac

    gl_log "${decision_emoji}💬👉📌" \
        "approval_decision" \
        "$request_id" \
        "Decision: $decision by $approver"
}

# Reaction added
gl_slack_reaction() {
    local emoji="$1"
    local message_id="$2"
    local user="$3"

    gl_log "👍💬👉📌" \
        "reaction_added" \
        "$message_id" \
        "Emoji: $emoji by $user"
}
```

### Standup & Team

```bash
# Standup posted
gl_slack_standup() {
    local user="$1"
    local date="$2"

    gl_log "☀️💬👉📌" \
        "standup_posted" \
        "$user" \
        "Date: $date"
}

# Modal opened
gl_slack_modal_opened() {
    local modal_type="$1"
    local user="$2"

    gl_log "📋💬👉📌" \
        "modal_opened" \
        "$modal_type" \
        "User: $user"
}
```

---

## 🎯 Example Integration: Complete Slack Flow

### Scenario: Deploy command to completion

```bash
# 1. User runs /deploy command
gl_slack_command "/deploy" "alexa" "production blackroad-api"
# [💬⚡👉📌] slack_command: /deploy — Executed by: alexa, args: production blackroad-api

# 2. Deployment started notification
gl_slack_deployment_notification "started" "blackroad-api" "production"
# [🚀💬🎢📌] slack_deployment: blackroad-api — Status: started, Env: production

# 3. Deployment running (from workflow)
gl_workflow_step "blackroad-api" "deploy" "passed"
# [🚀✅👉🔧] deploy: blackroad-api — Step deploy passed

# 4. Deployment success notification
gl_slack_deployment_notification "success" "blackroad-api" "production"
# [✅💬🎢📌] slack_deployment: blackroad-api — Status: success, Env: production

# 5. GreenLight update notification
gl_slack_greenlight_update "blackroad-api-deploy-123" "wip" "done"
# [🚦💬👉📌] slack_greenlight: blackroad-api-deploy-123 — wip → done
```

### Scenario: Critical alert flow

```bash
# 1. Critical error detected
gl_log "🚨⚠️🔧🔥" "error_detected" "database" "Connection pool exhausted"

# 2. Alert sent to Slack
gl_slack_alert "critical" "Database Connection Pool Exhausted" "ops-alerts"
# [🚨💬🎢🔥] slack_alert: Database Connection Pool Exhausted — Severity: critical, Channel: #ops-alerts

# 3. User mentions on-call engineer
gl_slack_mention "oncall-engineer" "ops-alerts"
# [🔔💬👉⭐] mention_received: oncall-engineer — In channel: ops-alerts

# 4. Issue created from Slack
gl_slack_command "/issue" "oncall-engineer" "Database connection pool exhausted"
# [💬⚡👉📌] slack_command: /issue — Executed by: oncall-engineer

# 5. Linear issue created
gl_issue_created "BLA-150" "Database connection pool exhausted" "bug"
# [⚡🐛👉📌] issue_created: BLA-150 — Database connection pool exhausted

# 6. Notification to Linear channel
gl_slack_linear_notification "created" "BLA-150"
# [🆕💬👉📌] slack_linear: BLA-150 — Action: created
```

### Scenario: Payment received notification

```bash
# 1. Stripe webhook received
gl_webhook_received "invoice.paid" "evt_abc123"
# [⚡📥💳👉] webhook_received: invoice.paid — Stripe webhook: evt_abc123

# 2. Payment processed
gl_invoice_paid "customer@example.com" "58" "usd"
# [💰✅🎢🌍] invoice_paid: customer@example.com — Payment successful: $58 usd

# 3. Notification to Slack
gl_slack_stripe_notification "payment_success" "customer@example.com" "$58"
# [💰💬👉📌] slack_stripe: customer@example.com — Event: payment_success, Amount: $58
```

### Scenario: Approval request

```bash
# 1. Approval request created
gl_slack_approval_request "deployment" "developer" "Production deploy of v2.0.0"
# [🔔💬👉⭐] approval_request: developer — Type: deployment, Production deploy of v2.0.0

# 2. Approver reacts
gl_slack_reaction "white_check_mark" "msg_123" "tech-lead"
# [👍💬👉📌] reaction_added: msg_123 — Emoji: white_check_mark by tech-lead

# 3. Approval decision recorded
gl_slack_approval_decision "approved" "tech-lead" "approve_req_123"
# [✅💬👉📌] approval_decision: approve_req_123 — Decision: approved by tech-lead

# 4. Deploy triggered
gl_slack_command "/deploy" "tech-lead" "production app-v2"
# [💬⚡👉📌] slack_command: /deploy — Executed by: tech-lead, args: production app-v2
```

---

## 📊 Slack App Configuration

**App Name:** BlackRoad OS
**Workspace:** Your Slack workspace
**Request URLs:**
- Events: https://slack.blackroad.io/slack/events
- Commands: https://slack.blackroad.io/slack/commands
- Interactive: https://slack.blackroad.io/slack/interactive

### Bot Scopes (16):
- chat:write (send messages)
- chat:write.public (send to public channels)
- commands (slash commands)
- channels:read & channels:history
- users:read & users:read.email
- reactions:write & reactions:read
- files:write & files:read
- im:write & im:read
- app_mentions:read

### Slash Commands (8):
- /issue - Create Linear issue
- /deploy - Trigger deployment
- /status - Check system status
- /greenlight - Query GreenLight state
- /agent - Query AI agent
- /oncall - Show on-call schedule
- /remind - Set reminder
- /standup - Post standup update

---

## 📚 Integration Checklist

- [x] Mapped Slack events to GreenLight 27-step workflow
- [x] Created channel-to-domain mappings
- [x] Defined slash commands
- [x] Extended NATS subjects for Slack events
- [x] Built 15+ Slack-specific templates
- [x] Webhook notification functions (6 channels)
- [x] Block Kit UI templates (5 types)
- [x] D1 schema for Slack sync
- [x] Event handler with signature verification

---

**Created:** December 23, 2025
**For:** Slack Team Communication Integration
**Version:** 2.0.0-slack
**Status:** 🔨 IMPLEMENTATION
