# 📋 GreenLight Linear Integration

**Extension to GreenLight for Linear Project Management**

---

## 📋 Linear Issue States

Map Linear statuses directly to GreenLight workflow:

| Linear Status | Linear Type | GreenLight Step | Emoji | GreenLight State | Trinary |
|---------------|-------------|-----------------|-------|------------------|---------|
| Backlog | backlog | 1 - Impulse | ⚡📋 | void | 0 |
| Todo | unstarted | 3 - Capture | 📥📝 | inbox | 0 |
| In Progress | started | 13 - Execute | ⚙️🔄 | wip | +1 |
| In Review | started | 15 - Checkpoint | ✔️👀 | wip | +1 |
| Done | completed | 19 - Complete | 🎉✅ | done | +1 |
| Canceled | canceled | 27 - Archive | 📦❌ | void | -1 |
| Duplicate | canceled | 27 - Archive | 📦🔁 | void | 0 |

---

## 🏷️ Linear Labels as GreenLight Tags

| Label | Color | GreenLight Emoji | Domain | Description |
|-------|-------|------------------|--------|-------------|
| Feature | #BB87FC | ✨ | FEATURE | New functionality |
| Bug | #EB5757 | 🐛 | BUG | Something broken |
| Improvement | #4EA7FC | 🔧 | IMPROVEMENT | Enhancement |
| Documentation | #8B8B8B | 📚 | DOCS | Documentation |
| Infrastructure | #F5A623 | 🏗️ | INFRA | DevOps/CI/CD |
| Security | #FF6B6B | 🔒 | SECURITY | Security issues |
| Performance | #00D084 | ⚡ | PERFORMANCE | Optimization |
| Design | #E91E63 | 🎨 | DESIGN | UI/UX |
| Research | #9C27B0 | 🔬 | RESEARCH | R&D |
| Tech Debt | #607D8B | 🧹 | TECH_DEBT | Cleanup |
| Blocked | #F44336 | 🔒 | BLOCKED | Dependency wait |
| GreenLight | #10B981 | 🚦 | GREENLIGHT | GreenLight system |

---

## 🎯 Linear Priorities

Map to GreenLight priority tags:

| Linear | Value | GreenLight | Emoji | Use Case |
|--------|-------|------------|-------|----------|
| Urgent | 1 | FIRE | 🔥 | Critical bugs, security |
| High | 2 | HIGH | ⭐ | Important features, blockers |
| Normal | 3 | MEDIUM | 📌 | Standard work |
| Low | 4 | LOW | 💤 | Nice to have |
| No priority | 0 | NONE | ⚪ | Unprioritized |

---

## 📁 Linear Projects

Recommended projects for BlackRoad OS:

| Project | Emoji | GreenLight Domain | Description |
|---------|-------|-------------------|-------------|
| Lucidia | 🧠 | AI (🌀) | Core Lucidia AI system |
| BlackRoad Platform | 🛣️ | Platform (🛣️) | Main platform development |
| Agent Ecosystem | 🤖 | AI (🌀) | 1000 agents project |
| GreenLight | 🚦 | Platform (🛣️) | Workflow & state system |
| Infrastructure | 🏗️ | Infrastructure (🔧) | DevOps, Cloudflare |
| Documentation | 📚 | Documentation (📚) | Docs, guides |
| Research | 🔬 | Research (🔬) | R&D, experiments |

---

## 🎨 Composite Patterns for Linear

### Issue Creation
```
⚡📋👉📌 = New issue in backlog, micro scale
✨📋🎢⭐ = Feature request, macro scale, high priority
🐛📋👉🔥 = Bug report, micro scale, urgent
```

### Issue Workflow
```
📥📝👉📌 = Todo, micro scale, medium priority
⚙️🔄🎢⭐ = In Progress, macro scale, high priority
✔️👀👉📌 = In Review, micro scale
🎉✅🎢🌍 = Completed, macro impact
```

### Labels + Priorities
```
✨🎢⭐📣 = Feature, macro, high priority
🐛👉🔥🚨 = Bug, micro, urgent
🔒🎢🔥⚠️ = Security issue, macro, urgent
⚡👉⭐📊 = Performance, micro, high priority
```

### Full Issue Lifecycle
```
[⚡📋] [📥📝] [⚙️🔄] [✔️👀] [🎉✅] = Backlog → Todo → In Progress → Review → Done
[🐛🔥] [⚙️🔄] [🎉✅] = Bug urgent → Fix → Done
[✨⭐] [📥📝] [⚙️🔄] [🎉✅] = Feature high → Planned → Building → Shipped
```

---

## 📝 NATS Subject Patterns (Linear)

### Issue Events
```
greenlight.issue.created.micro.platform.{identifier}
greenlight.issue.updated.micro.platform.{identifier}
greenlight.issue.completed.macro.platform.{identifier}
greenlight.issue.canceled.micro.platform.{identifier}
```

### State Changes
```
greenlight.issue.todo.micro.platform.{identifier}
greenlight.issue.in_progress.micro.platform.{identifier}
greenlight.issue.in_review.micro.platform.{identifier}
greenlight.issue.done.macro.platform.{identifier}
```

### Label-Specific
```
greenlight.bug.reported.micro.platform.{identifier}
greenlight.feature.requested.macro.platform.{identifier}
greenlight.security.critical.macro.platform.{identifier}
greenlight.blocked.waiting.micro.platform.{identifier}
```

### Project Events
```
greenlight.project.created.macro.platform.{project_name}
greenlight.project.completed.macro.platform.{project_name}
```

### Comment Events
```
greenlight.comment.added.micro.platform.{identifier}
greenlight.command.greenlight.micro.platform.{identifier}
```

---

## 🔨 Linear Memory Templates

### Issue Operations

```bash
# Issue created
gl_issue_created() {
    local identifier="$1"  # BLA-123
    local title="$2"
    local label="${3:-feature}"

    local label_emoji=""
    case "$label" in
        feature) label_emoji="✨" ;;
        bug) label_emoji="🐛" ;;
        improvement) label_emoji="🔧" ;;
        security) label_emoji="🔒" ;;
        performance) label_emoji="⚡" ;;
        *) label_emoji="📋" ;;
    esac

    gl_log "⚡${label_emoji}👉📌" \
        "issue_created" \
        "$identifier" \
        "$title"
}

# Issue state changed
gl_issue_state_changed() {
    local identifier="$1"
    local old_state="$2"
    local new_state="$3"

    local state_emoji=""
    case "$new_state" in
        "Todo") state_emoji="📥📝" ;;
        "In Progress") state_emoji="⚙️🔄" ;;
        "In Review") state_emoji="✔️👀" ;;
        "Done") state_emoji="🎉✅" ;;
        "Canceled") state_emoji="📦❌" ;;
        *) state_emoji="📋" ;;
    esac

    gl_log "${state_emoji}👉📌" \
        "state_changed" \
        "$identifier" \
        "$old_state → $new_state"
}

# Issue completed
gl_issue_completed() {
    local identifier="$1"
    local title="$2"
    local duration="${3:-unknown}"

    gl_log "🎉✅🎢🌍" \
        "issue_completed" \
        "$identifier" \
        "$title (completed in $duration)"
}

# Issue blocked
gl_issue_blocked() {
    local identifier="$1"
    local reason="$2"

    gl_log "🔒⚠️👉🔥" \
        "issue_blocked" \
        "$identifier" \
        "Blocked: $reason"
}

# Issue assigned
gl_issue_assigned() {
    local identifier="$1"
    local assignee="$2"

    gl_log "👤📋👉📌" \
        "issue_assigned" \
        "$identifier" \
        "Assigned to: $assignee"
}

# Issue prioritized
gl_issue_prioritized() {
    local identifier="$1"
    local priority="$2"

    local priority_emoji=""
    case "$priority" in
        1) priority_emoji="🔥" ;;
        2) priority_emoji="⭐" ;;
        3) priority_emoji="📌" ;;
        4) priority_emoji="💤" ;;
        *) priority_emoji="⚪" ;;
    esac

    gl_log "${priority_emoji}📋👉📌" \
        "issue_prioritized" \
        "$identifier" \
        "Priority: $priority"
}
```

### Project Operations

```bash
# Project created
gl_project_created() {
    local project_name="$1"
    local description="$2"

    gl_log "📁🚀🎢✅" \
        "project_created" \
        "$project_name" \
        "$description"
}

# Project completed
gl_project_completed() {
    local project_name="$1"
    local issues_count="$2"

    gl_log "📁🎉🎢🌍" \
        "project_completed" \
        "$project_name" \
        "$issues_count issues completed"
}
```

### Comment Operations

```bash
# Comment added
gl_comment_added() {
    local identifier="$1"
    local user="$2"
    local preview="${3:0:50}"

    gl_log "💬📋👉📌" \
        "comment_added" \
        "$identifier" \
        "$user: $preview..."
}

# GreenLight command detected
gl_command_detected() {
    local identifier="$1"
    local command="$2"

    gl_log "🚦📋👉⭐" \
        "command_detected" \
        "$identifier" \
        "GreenLight command: $command"
}
```

### GitHub Integration

```bash
# PR linked to issue
gl_pr_linked() {
    local identifier="$1"
    local pr_url="$2"

    gl_log "🔗📋🎢📌" \
        "pr_linked" \
        "$identifier" \
        "PR: $pr_url"
}

# PR merged, issue closed
gl_pr_merged() {
    local identifier="$1"
    local pr_number="$2"

    gl_log "✅🔗🎢🎉" \
        "pr_merged" \
        "$identifier" \
        "PR #$pr_number merged, issue completed"
}

# Branch created from issue
gl_branch_created() {
    local identifier="$1"
    local branch_name="$2"

    gl_log "🌿📋👉📌" \
        "branch_created" \
        "$identifier" \
        "Branch: $branch_name"
}
```

### Cycle (Sprint) Operations

```bash
# Cycle started
gl_cycle_started() {
    local cycle_name="$1"
    local duration="$2"

    gl_log "🔄🚀🎢⭐" \
        "cycle_started" \
        "$cycle_name" \
        "Sprint started: $duration"
}

# Cycle completed
gl_cycle_completed() {
    local cycle_name="$1"
    local completed_count="$2"
    local total_count="$3"

    gl_log "🔄🎉🎢🌍" \
        "cycle_completed" \
        "$cycle_name" \
        "Sprint complete: $completed_count/$total_count issues"
}
```

---

## 🎯 Example Integration: Complete Issue Lifecycle

### Scenario: Bug report and fix

```bash
# 1. Bug reported
gl_issue_created "BLA-42" "Login fails with OAuth" "bug"
# [⚡🐛👉📌] issue_created: BLA-42 — Login fails with OAuth

# 2. Prioritized as urgent
gl_issue_prioritized "BLA-42" "1"
# [🔥📋👉📌] issue_prioritized: BLA-42 — Priority: 1

# 3. Assigned
gl_issue_assigned "BLA-42" "alexa"
# [👤📋👉📌] issue_assigned: BLA-42 — Assigned to: alexa

# 4. Moved to In Progress
gl_issue_state_changed "BLA-42" "Todo" "In Progress"
# [⚙️🔄👉📌] state_changed: BLA-42 — Todo → In Progress

# 5. Branch created
gl_branch_created "BLA-42" "bla-42-fix-oauth-login"
# [🌿📋👉📌] branch_created: BLA-42 — Branch: bla-42-fix-oauth-login

# 6. PR opened
gl_pr_linked "BLA-42" "https://github.com/blackroad/api/pull/123"
# [🔗📋🎢📌] pr_linked: BLA-42 — PR: https://github.com/blackroad/api/pull/123

# 7. Moved to In Review
gl_issue_state_changed "BLA-42" "In Progress" "In Review"
# [✔️👀👉📌] state_changed: BLA-42 — In Progress → In Review

# 8. PR merged
gl_pr_merged "BLA-42" "123"
# [✅🔗🎢🎉] pr_merged: BLA-42 — PR #123 merged, issue completed

# 9. Issue completed
gl_issue_completed "BLA-42" "Login fails with OAuth" "3h 24m"
# [🎉✅🎢🌍] issue_completed: BLA-42 — Login fails with OAuth (completed in 3h 24m)
```

### Scenario: Feature request lifecycle

```bash
# 1. Feature requested
gl_issue_created "BLA-100" "Add dark mode toggle" "feature"
# [⚡✨👉📌] issue_created: BLA-100 — Add dark mode toggle

# 2. High priority
gl_issue_prioritized "BLA-100" "2"
# [⭐📋👉📌] issue_prioritized: BLA-100 — Priority: 2

# 3. Added to project
gl_log "📁✅👉📌" "project_added" "BLA-100" "Added to BlackRoad Platform project"

# 4. Start work
gl_issue_state_changed "BLA-100" "Backlog" "In Progress"
# [⚙️🔄👉📌] state_changed: BLA-100 — Backlog → In Progress

# 5. Comment added
gl_comment_added "BLA-100" "designer" "Figma designs ready for implementation"
# [💬📋👉📌] comment_added: BLA-100 — designer: Figma designs ready for implementation...

# 6. Complete
gl_issue_completed "BLA-100" "Add dark mode toggle" "2 days"
# [🎉✅🎢🌍] issue_completed: BLA-100 — Add dark mode toggle (completed in 2 days)
```

### Scenario: Blocked issue

```bash
# 1. Start work
gl_issue_state_changed "BLA-87" "Todo" "In Progress"
# [⚙️🔄👉📌] state_changed: BLA-87 — Todo → In Progress

# 2. Hit blocker
gl_issue_blocked "BLA-87" "Waiting for API authentication endpoint (BLA-88)"
# [🔒⚠️👉🔥] issue_blocked: BLA-87 — Blocked: Waiting for API authentication endpoint (BLA-88)

# 3. Blocker resolved
gl_log "🔓✅👉⭐" "blocker_resolved" "BLA-87" "BLA-88 completed, can proceed"

# 4. Resume work
gl_issue_state_changed "BLA-87" "Blocked" "In Progress"
# [⚙️🔄👉📌] state_changed: BLA-87 — Blocked → In Progress
```

---

## 📊 Linear Workspace Details

**Workspace:** Blackboxprogramming
**URL:** https://linear.app/blackboxprogramming
**Team ID:** c33efc9b-38b7-43f3-bccf-eb93ad2e3f93
**Issue Prefix:** BLA-
**API:** https://api.linear.app/graphql

### Current Setup:
- **Team:** 1 (Blackboxprogramming)
- **Projects:** 1 (Lucidia) + 7 recommended
- **States:** 7 (Backlog, Todo, In Progress, In Review, Done, Canceled, Duplicate)
- **Labels:** 3 (Feature, Bug, Improvement) + 9 recommended
- **Priorities:** 5 (0-4, urgent to no priority)

---

## 📚 Integration Checklist

- [x] Mapped Linear states to GreenLight 27-step workflow
- [x] Created label-to-emoji mappings
- [x] Mapped priorities to GreenLight tags
- [x] Extended NATS subjects for issue/project events
- [x] Built 15+ Linear-specific templates
- [x] Integrated with GitHub (PR linking, branch creation)
- [x] Added mobile integration patterns
- [x] Created D1 schema for sync
- [x] Webhook handler with GreenLight logging

---

**Created:** December 23, 2025
**For:** Linear Project Management Integration
**Version:** 2.0.0-linear
**Status:** 🔨 IMPLEMENTATION
