# 🧠 GreenLight Context Propagation & State Sharing

**Layer 12: Semantic Understanding Between Claudes**

---

## 🧠 Why Context Propagation Matters

**The Problem:** Current memory system logs *events* but not *understanding*.
- You see "deployed API v2.3.0" but not WHY it was deployed
- You see "bug fixed" but not WHAT was learned
- You see "decision made" but not the RATIONALE

**The Solution:** Semantic context sharing between all Claudes.
- Preserve the WHY, not just the WHAT
- Share learnings, not just actions
- Propagate understanding, not just events

---

## 🌟 Context Events as GreenLight Steps

| Context Event | GreenLight Step | Step # | Emoji | State Transition | Scope |
|---------------|-----------------|--------|-------|------------------|-------|
| Context snapshot | 📸 Capture | 3 | 📸🧠 | → inbox | session state |
| Learning discovered | 💡 Insight | 8 | 💡✨ | → queued | knowledge |
| Decision rationale | 🤔 Decide | 9 | 🤔📝 | → queued | architecture |
| User intent captured | 🎯 Clarify | 2 | 🎯💭 | void → inbox | requirements |
| Debugging state | 🐛 Debug | 16 | 🐛🔍 | → blocked | failure context |
| Learning applied | ✅ Apply | 14 | ✅🎓 | wip → wip | knowledge use |
| Context handoff | 🤝 Transfer | 12 | 🤝📦 | → wip | between agents |
| Pattern recognized | 🔍 Discover | 6 | 🔍🎯 | inbox → queued | insight |

---

## 🎨 Context Types

| Type | Emoji | Purpose | Retention | Priority |
|------|-------|---------|-----------|----------|
| Session State | 📸 | Current work context | Session | 📌 Medium |
| Learning | 💡 | New insights/patterns | Permanent | ⭐ High |
| Decision | 🤔 | Why choices were made | Permanent | ⭐ High |
| User Intent | 🎯 | What user actually wants | Permanent | 🔥 Urgent |
| Debugging | 🐛 | Failure reproduction | 7 days | 🔥 Urgent |
| Hypothesis | 🔬 | Unproven theories | Until tested | 📌 Medium |
| Warning | ⚠️ | Gotchas, pitfalls | Permanent | ⭐ High |
| Success Pattern | 🎉 | What worked well | Permanent | ⭐ High |

---

## 🧩 Composite Patterns

### Learning & Discovery
```
💡✨👉⭐ = New learning discovered, micro scale, high priority
🔍🎯🎢📌 = Pattern recognized, macro scale
✅🎓👉📌 = Learning applied successfully
```

### Context Sharing
```
📸🧠👉📌 = Context snapshot captured
🤝📦👉⭐ = Context handoff between Claudes
🎯💭👉🔥 = User intent clarified, urgent
```

### Debugging & Failures
```
🐛🔍👉🔥 = Debugging state captured, urgent
⚠️📝👉⭐ = Warning documented, high priority
🔬🧪👉📌 = Hypothesis being tested
```

### Decisions
```
🤔📝🎢⭐ = Decision rationale, macro, high priority
✅🎯🎢🌍 = Decision validated, global impact
❌🔄👉📌 = Decision reversed, context preserved
```

---

## 📝 NATS Subject Patterns

### Context Events
```
greenlight.context.snapshot.micro.platform.{agent_id}
greenlight.context.handoff.micro.platform.{from_agent}.{to_agent}
greenlight.context.restored.micro.platform.{session_id}
```

### Learning Events
```
greenlight.learning.discovered.macro.platform.{topic}
greenlight.learning.applied.micro.platform.{pattern}
greenlight.learning.validated.macro.platform.{topic}
greenlight.pattern.recognized.micro.platform.{pattern_type}
```

### Decision Events
```
greenlight.decision.made.macro.platform.{decision_id}
greenlight.decision.rationale.macro.platform.{decision_id}
greenlight.decision.reversed.macro.platform.{decision_id}
greenlight.decision.validated.macro.platform.{decision_id}
```

### Intent Events
```
greenlight.intent.captured.micro.platform.{user}
greenlight.intent.clarified.micro.platform.{requirement}
greenlight.intent.fulfilled.macro.platform.{goal}
```

### Debugging Events
```
greenlight.debug.state.critical.platform.{issue_id}
greenlight.debug.reproduced.micro.platform.{issue_id}
greenlight.debug.resolved.macro.platform.{issue_id}
```

---

## 🔨 Context Propagation Templates

### Context Snapshots

```bash
# Capture current working context
gl_context_snapshot() {
    local context_id="$1"
    local summary="$2"
    local key_files="${3:-}"
    local state="${4:-wip}"

    gl_log "📸🧠👉📌" \
        "context_snapshot" \
        "$context_id" \
        "$summary | Files: $key_files | State: $state"
}

# Restore previous context
gl_context_restored() {
    local context_id="$1"
    local restored_from="$2"

    gl_log "🔄🧠👉📌" \
        "context_restored" \
        "$context_id" \
        "Restored from: $restored_from"
}

# Context handoff between agents
gl_context_handoff() {
    local from_agent="$1"
    local to_agent="$2"
    local task="$3"
    local context_summary="$4"

    gl_log "🤝📦👉⭐" \
        "context_handoff" \
        "$task" \
        "From: $from_agent → To: $to_agent | Context: $context_summary"
}
```

### Learning & Discovery

```bash
# New learning discovered
gl_learning_discovered() {
    local topic="$1"
    local insight="$2"
    local evidence="${3:-observation}"

    gl_log "💡✨👉⭐" \
        "learning_discovered" \
        "$topic" \
        "Insight: $insight | Evidence: $evidence"
}

# Learning applied
gl_learning_applied() {
    local pattern="$1"
    local application="$2"
    local result="${3:-applied}"

    gl_log "✅🎓👉📌" \
        "learning_applied" \
        "$pattern" \
        "Applied: $application | Result: $result"
}

# Learning validated
gl_learning_validated() {
    local topic="$1"
    local validation_method="$2"
    local confidence="${3:-high}"

    gl_log "✅💡🎢🌍" \
        "learning_validated" \
        "$topic" \
        "Method: $validation_method | Confidence: $confidence"
}

# Pattern recognized
gl_pattern_recognized() {
    local pattern_type="$1"
    local description="$2"
    local occurrences="${3:-multiple}"

    gl_log "🔍🎯👉📌" \
        "pattern_recognized" \
        "$pattern_type" \
        "$description | Occurrences: $occurrences"
}
```

### Decision Rationale

```bash
# Decision made with rationale
gl_decision_rationale() {
    local decision="$1"
    local rationale="$2"
    local alternatives="${3:-none considered}"
    local impact="${4:-medium}"

    local impact_emoji=""
    case "$impact" in
        critical|high) impact_emoji="🎢" ;;
        medium) impact_emoji="👉" ;;
        low) impact_emoji="👉" ;;
        *) impact_emoji="👉" ;;
    esac

    gl_log "🤔📝${impact_emoji}⭐" \
        "decision_rationale" \
        "$decision" \
        "Why: $rationale | Alternatives: $alternatives | Impact: $impact"
}

# Decision validated
gl_decision_validated() {
    local decision="$1"
    local validation="$2"
    local outcome="${3:-positive}"

    local outcome_emoji=""
    case "$outcome" in
        positive|success) outcome_emoji="✅" ;;
        negative|failure) outcome_emoji="❌" ;;
        mixed) outcome_emoji="⚠️" ;;
        *) outcome_emoji="📊" ;;
    esac

    gl_log "${outcome_emoji}🎯🎢🌍" \
        "decision_validated" \
        "$decision" \
        "Validation: $validation | Outcome: $outcome"
}

# Decision reversed
gl_decision_reversed() {
    local original_decision="$1"
    local reason="$2"
    local new_approach="${3:-TBD}"

    gl_log "❌🔄👉⭐" \
        "decision_reversed" \
        "$original_decision" \
        "Reason: $reason | New approach: $new_approach"
}
```

### User Intent

```bash
# User intent captured
gl_user_intent() {
    local user="$1"
    local goal="$2"
    local context="${3:-}"
    local priority="${4:-medium}"

    local priority_emoji=""
    case "$priority" in
        urgent|critical) priority_emoji="🔥" ;;
        high) priority_emoji="⭐" ;;
        medium) priority_emoji="📌" ;;
        low) priority_emoji="💤" ;;
        *) priority_emoji="📌" ;;
    esac

    gl_log "🎯💭👉${priority_emoji}" \
        "user_intent" \
        "$user" \
        "Goal: $goal | Context: $context"
}

# Intent clarified
gl_intent_clarified() {
    local original_request="$1"
    local clarified_intent="$2"
    local questions_asked="${3:-0}"

    gl_log "🎯✨👉⭐" \
        "intent_clarified" \
        "$original_request" \
        "Clarified: $clarified_intent | Questions: $questions_asked"
}

# Intent fulfilled
gl_intent_fulfilled() {
    local goal="$1"
    local outcome="$2"
    local user_satisfaction="${3:-unknown}"

    gl_log "🎯✅🎢🌍" \
        "intent_fulfilled" \
        "$goal" \
        "Outcome: $outcome | Satisfaction: $user_satisfaction"
}
```

### Debugging State

```bash
# Debugging state captured
gl_debug_state_captured() {
    local issue_id="$1"
    local error_type="$2"
    local reproduction_steps="$3"
    local environment="${4:-production}"

    gl_log "🐛🔍👉🔥" \
        "debug_state_captured" \
        "$issue_id" \
        "Type: $error_type | Env: $environment | Steps: $reproduction_steps"
}

# Issue reproduced
gl_issue_reproduced() {
    local issue_id="$1"
    local success_rate="$2"
    local conditions="${3:-}"

    gl_log "✅🐛👉📌" \
        "issue_reproduced" \
        "$issue_id" \
        "Success rate: $success_rate | Conditions: $conditions"
}

# Root cause identified
gl_root_cause_identified() {
    local issue_id="$1"
    local root_cause="$2"
    local confidence="${3:-high}"

    gl_log "🎯🐛🎢⭐" \
        "root_cause_identified" \
        "$issue_id" \
        "Root cause: $root_cause | Confidence: $confidence"
}

# Issue resolved
gl_debug_resolved() {
    local issue_id="$1"
    local solution="$2"
    local verification="${3:-tested}"

    gl_log "✅🐛🎢🎉" \
        "debug_resolved" \
        "$issue_id" \
        "Solution: $solution | Verification: $verification"
}
```

### Warnings & Gotchas

```bash
# Warning documented
gl_warning_documented() {
    local topic="$1"
    local warning="$2"
    local severity="${3:-medium}"

    local severity_emoji=""
    case "$severity" in
        critical) severity_emoji="🚨" ;;
        high) severity_emoji="⚠️" ;;
        medium) severity_emoji="⚠️" ;;
        low) severity_emoji="ℹ️" ;;
        *) severity_emoji="⚠️" ;;
    esac

    gl_log "${severity_emoji}📝👉⭐" \
        "warning_documented" \
        "$topic" \
        "Warning: $warning | Severity: $severity"
}

# Gotcha encountered
gl_gotcha_encountered() {
    local area="$1"
    local gotcha="$2"
    local workaround="${3:-none}"

    gl_log "⚠️💡👉⭐" \
        "gotcha_encountered" \
        "$area" \
        "Gotcha: $gotcha | Workaround: $workaround"
}
```

### Hypotheses & Experiments

```bash
# Hypothesis formed
gl_hypothesis_formed() {
    local hypothesis="$1"
    local basis="$2"
    local test_plan="${3:-TBD}"

    gl_log "🔬💭👉📌" \
        "hypothesis_formed" \
        "$hypothesis" \
        "Basis: $basis | Test plan: $test_plan"
}

# Hypothesis tested
gl_hypothesis_tested() {
    local hypothesis="$1"
    local result="$2"  # confirmed, refuted, inconclusive
    local data="${3:-}"

    local result_emoji=""
    case "$result" in
        confirmed) result_emoji="✅" ;;
        refuted) result_emoji="❌" ;;
        inconclusive) result_emoji="❓" ;;
        *) result_emoji="📊" ;;
    esac

    gl_log "${result_emoji}🔬🎢📌" \
        "hypothesis_tested" \
        "$hypothesis" \
        "Result: $result | Data: $data"
}
```

### Success Patterns

```bash
# Success pattern identified
gl_success_pattern() {
    local pattern="$1"
    local description="$2"
    local instances="${3:-multiple}"

    gl_log "🎉📋👉⭐" \
        "success_pattern" \
        "$pattern" \
        "$description | Instances: $instances"
}

# Best practice established
gl_best_practice() {
    local practice="$1"
    local rationale="$2"
    local source="${3:-experience}"

    gl_log "⭐📚🎢🌍" \
        "best_practice" \
        "$practice" \
        "Rationale: $rationale | Source: $source"
}
```

---

## 🎯 Example: Complete Context Flow

### Scenario: Performance issue discovered, debugged, and resolved with learning

```bash
# 1. User reports slow API
gl_user_intent "alexa" "Make API faster" "Users complaining about 3s response times" "urgent"
# [🎯💭👉🔥] user_intent: alexa — Goal: Make API faster | Context: Users complaining about 3s response times

# 2. Capture current context before investigating
gl_context_snapshot "api-performance-investigation" "Investigating slow /users endpoint" "api/routes/users.ts, api/db/queries.ts" "investigating"
# [📸🧠👉📌] context_snapshot: api-performance-investigation — Investigating slow /users endpoint | Files: api/routes/users.ts, api/db/queries.ts | State: investigating

# 3. Hypothesis formed
gl_hypothesis_formed "Missing database index causing slow queries" "Query analyzer shows sequential scan on users table" "Add index and measure performance"
# [🔬💭👉📌] hypothesis_formed: Missing database index causing slow queries — Basis: Query analyzer shows sequential scan on users table | Test plan: Add index and measure performance

# 4. Debugging state captured
gl_debug_state_captured "slow-api-001" "N+1 query pattern" "1. Load dashboard 2. Observe network tab 3. See 100+ queries" "production"
# [🐛🔍👉🔥] debug_state_captured: slow-api-001 — Type: N+1 query pattern | Env: production | Steps: 1. Load dashboard 2. Observe network tab 3. See 100+ queries

# 5. Root cause identified
gl_root_cause_identified "slow-api-001" "Missing index on users.email + N+1 query in user lookup" "high"
# [🎯🐛🎢⭐] root_cause_identified: slow-api-001 — Root cause: Missing index on users.email + N+1 query in user lookup | Confidence: high

# 6. Pattern recognized (this is common!)
gl_pattern_recognized "missing-index" "User table queries often missing indexes on email/username columns" "3 occurrences this month"
# [🔍🎯👉📌] pattern_recognized: missing-index — User table queries often missing indexes on email/username columns | Occurrences: 3 occurrences this month

# 7. Learning discovered
gl_learning_discovered "database-performance" "Always add indexes on frequently queried columns (email, username, external_id)" "Reduced query time 95% (3s → 150ms)"
# [💡✨👉⭐] learning_discovered: database-performance — Insight: Always add indexes on frequently queried columns (email, username, external_id) | Evidence: Reduced query time 95% (3s → 150ms)

# 8. Warning documented for future
gl_warning_documented "database-migrations" "New user-related tables MUST include email/username indexes" "high"
# [⚠️📝👉⭐] warning_documented: database-migrations — Warning: New user-related tables MUST include email/username indexes | Severity: high

# 9. Decision made
gl_decision_rationale "Add composite index on (email, created_at)" "Supports both user lookup AND recent user queries" "Separate indexes (more storage but less flexible)" "high"
# [🤔📝🎢⭐] decision_rationale: Add composite index on (email, created_at) — Why: Supports both user lookup AND recent user queries | Alternatives: Separate indexes (more storage but less flexible) | Impact: high

# 10. Hypothesis tested
gl_hypothesis_tested "Missing database index causing slow queries" "confirmed" "Performance improved 95%, load test shows consistent <200ms response times"
# [✅🔬🎢📌] hypothesis_tested: Missing database index causing slow queries — Result: confirmed | Data: Performance improved 95%, load test shows consistent <200ms response times

# 11. Issue resolved
gl_debug_resolved "slow-api-001" "Added composite index (email, created_at), optimized query to use eager loading" "Load tested with 1000 req/s"
# [✅🐛🎢🎉] debug_resolved: slow-api-001 — Solution: Added composite index (email, created_at), optimized query to use eager loading | Verification: Load tested with 1000 req/s

# 12. Intent fulfilled
gl_intent_fulfilled "Make API faster" "API response time: 3s → 150ms (95% improvement)" "User confirmed dashboard loads instantly"
# [🎯✅🎢🌍] intent_fulfilled: Make API faster — Outcome: API response time: 3s → 150ms (95% improvement) | Satisfaction: User confirmed dashboard loads instantly

# 13. Best practice established
gl_best_practice "Database Performance Review Checklist" "Before merging: 1. Check for N+1 queries 2. Verify indexes on queried columns 3. Load test with realistic data" "This incident"
# [⭐📚🎢🌍] best_practice: Database Performance Review Checklist — Rationale: Before merging: 1. Check for N+1 queries 2. Verify indexes on queried columns 3. Load test with realistic data | Source: This incident

# 14. Another Claude applies the learning immediately
gl_learning_applied "database-index-pattern" "Building new user_sessions table, preemptively added indexes on user_id, session_token, created_at" "Table performs well in testing"
# [✅🎓👉📌] learning_applied: database-index-pattern — Applied: Building new user_sessions table, preemptively added indexes on user_id, session_token, created_at | Result: Table performs well in testing
```

**Result:** Complete knowledge transfer. Every Claude now knows:
- The problem (N+1 queries + missing indexes)
- The solution (composite indexes + eager loading)
- The pattern (always check user table queries)
- The best practice (performance review checklist)
- How to prevent it (preemptive indexing)

---

## 📚 Integration Checklist

- [x] Mapped context events to GreenLight workflow
- [x] Created context type categories (8 types)
- [x] Extended NATS subjects for context propagation
- [x] Built 20+ context-specific templates
- [x] Snapshot & restoration support
- [x] Learning discovery & application
- [x] Decision rationale capture
- [x] User intent preservation
- [x] Debugging state management
- [x] Warning & gotcha documentation
- [x] Hypothesis & experimentation tracking
- [x] Success pattern identification
- [x] Best practice establishment
- [x] Cross-Claude knowledge sharing

---

**Created:** December 23, 2025 🌸
**For:** Context Propagation & Semantic Understanding
**Version:** 2.0.0-context
**Status:** 🔨 IMPLEMENTATION
**Built by:** Cece (with love for all Claudes)

